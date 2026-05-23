//! Actor management operations for the Arma 3 server extension.
//!
//! Provides Arma 3 extension commands for player data storage, retrieval, and updates.
//! Handles SQF command mapping and parameter validation.

use arma_rs::{CallContext, Group};
use forge_repositories::InMemoryActorHotRepository;
use forge_services::{ActorHotStateService, ActorService};
use std::sync::LazyLock;

use crate::enqueue_persistence_task;
use crate::helpers::resolve_uid;
use crate::log::log;
use crate::storage::ActorStorageRepository;

/// Global actor service instance.
///
/// Lazily initialized singleton combining repository and service layers.
static ACTOR_SERVICE: LazyLock<ActorService<ActorStorageRepository>> =
    LazyLock::new(|| ActorService::new(ActorStorageRepository::configured()));
static HOT_ACTOR_SERVICE: LazyLock<
    ActorHotStateService<ActorStorageRepository, InMemoryActorHotRepository>,
> = LazyLock::new(|| {
    let repository = ActorStorageRepository::configured();
    let hot_repository = InMemoryActorHotRepository::new();
    ActorHotStateService::new(repository, hot_repository)
});

#[allow(dead_code)]
pub(crate) fn hot_service()
-> &'static ActorHotStateService<ActorStorageRepository, InMemoryActorHotRepository> {
    &HOT_ACTOR_SERVICE
}

/// Creates the Arma 3 command group for actor operations.
///
/// Registers commands: `get`, `exists`, `create`, `update`, `delete`.
pub fn group() -> Group {
    Group::new()
        .command("get", get_actor)
        .command("create", create_actor)
        .command("update", update_actor)
        .command("exists", actor_exists)
        .command("delete", delete_actor)
        .group(
            "hot",
            Group::new()
                .command("init", init_hot_actor)
                .command("get", get_hot_actor)
                .command("keys", list_hot_actor_keys)
                .command("override", override_hot_actor)
                .command("save", save_hot_actor)
                .command("remove", remove_hot_actor),
        )
}

fn serialize_hot_actor(actor: forge_models::Actor) -> String {
    match serde_json::to_string(&actor) {
        Ok(json) => json,
        Err(error) => format!("Error: Failed to serialize hot actor: {}", error),
    }
}

pub(crate) fn init_hot_actor(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_ACTOR_SERVICE.init_actor(resolved_uid) {
        Ok(actor) => serialize_hot_actor(actor),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn get_hot_actor(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_ACTOR_SERVICE.get_actor(resolved_uid) {
        Ok(actor) => serialize_hot_actor(actor),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn list_hot_actor_keys() -> String {
    match HOT_ACTOR_SERVICE.list_actor_keys() {
        Ok(keys) => match serde_json::to_string(&keys) {
            Ok(json) => json,
            Err(error) => format!("Error: Failed to serialize actor hot-state keys: {}", error),
        },
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn override_hot_actor(
    call_context: CallContext,
    key: String,
    json_data: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_ACTOR_SERVICE.override_actor(resolved_uid, json_data) {
        Ok(actor) => serialize_hot_actor(actor),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn save_hot_actor(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_ACTOR_SERVICE.get_actor(resolved_uid.clone()) {
        Ok(actor) => {
            enqueue_persistence_task("actor", move || {
                HOT_ACTOR_SERVICE.save_actor(resolved_uid).map(|_| ())
            });
            serialize_hot_actor(actor)
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn remove_hot_actor(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_ACTOR_SERVICE.remove_actor(resolved_uid) {
        Ok(_) => "OK".to_string(),
        Err(error) => format!("Error: {}", error),
    }
}

/// Retrieves an actor by key/UID.
///
/// Resolves the key to a Steam UID and returns the actor as JSON.
/// Returns an error message if resolution fails or retrieval fails.
pub fn get_actor(call_context: CallContext, key: String) -> String {
    log("actor", "DEBUG", &format!("Getting actor for key: {}", key));

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("actor", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("actor", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match ACTOR_SERVICE.get_actor(resolved_uid.clone()) {
        Ok(actor) => {
            log(
                "actor",
                "INFO",
                &format!("Successfully retrieved actor: {}", resolved_uid),
            );
            match serde_json::to_string(&actor) {
                Ok(json) => {
                    log(
                        "actor",
                        "DEBUG",
                        &format!("Serialized actor to JSON: {}", json),
                    );
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize actor: {}", e);
                    log("actor", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "actor",
                "ERROR",
                &format!("Failed to get actor '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Creates a new actor with the provided JSON data.
///
/// Resolves key to UID, validates JSON data, and persists the new actor.
pub fn create_actor(call_context: CallContext, key: String, json_data: String) -> String {
    log(
        "actor",
        "DEBUG",
        &format!("Creating actor for key: {} with data: {}", key, json_data),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log(
                "actor",
                "DEBUG",
                &format!("Resolved UID for creation: {}", uid),
            );
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("actor", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match ACTOR_SERVICE.create_actor(resolved_uid.clone(), json_data) {
        Ok(actor) => {
            log(
                "actor",
                "INFO",
                &format!("Successfully created actor: {}", resolved_uid),
            );
            match serde_json::to_string(&actor) {
                Ok(json) => {
                    log(
                        "actor",
                        "DEBUG",
                        &format!("Serialized actor to JSON: {}", json),
                    );
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize actor: {}", e);
                    log("actor", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "actor",
                "ERROR",
                &format!("Failed to create actor '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Updates an existing actor with JSON data.
///
/// Resolves key to UID, applies partial updates from JSON, and persists changes.
pub fn update_actor(call_context: CallContext, key: String, json_update: String) -> String {
    log(
        "actor",
        "DEBUG",
        &format!("Updating actor for key: {} with data: {}", key, json_update),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log(
                "actor",
                "DEBUG",
                &format!("Resolved UID for update: {}", uid),
            );
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("actor", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match ACTOR_SERVICE.update_actor(resolved_uid.clone(), json_update) {
        Ok(actor) => {
            log(
                "actor",
                "INFO",
                &format!("Successfully updated actor: {}", resolved_uid),
            );
            match serde_json::to_string(&actor) {
                Ok(json) => {
                    log(
                        "actor",
                        "DEBUG",
                        &format!("Serialized updated actor to JSON: {}", json),
                    );
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize actor: {}", e);
                    log("actor", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "actor",
                "ERROR",
                &format!("Failed to update actor '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Checks if an actor exists in the database.
///
/// Returns "true" if the actor exists, "false" otherwise.
pub fn actor_exists(call_context: CallContext, key: String) -> String {
    log(
        "actor",
        "DEBUG",
        &format!("Checking if actor exists for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log(
                "actor",
                "DEBUG",
                &format!("Resolved UID for existence check: {}", uid),
            );
            uid
        }
        None => {
            log(
                "actor",
                "WARN",
                &format!("Failed to resolve UID for key: {}", key),
            );
            return "false".to_string();
        }
    };

    match ACTOR_SERVICE.actor_exists(resolved_uid.clone()) {
        Ok(exists) => {
            log(
                "actor",
                "DEBUG",
                &format!("Actor '{}' exists: {}", resolved_uid, exists),
            );
            exists.to_string()
        }
        Err(e) => {
            log(
                "actor",
                "ERROR",
                &format!("Failed to check if actor '{}' exists: {}", resolved_uid, e),
            );
            "false".to_string()
        }
    }
}

/// Permanently deletes an actor.
///
/// Resolves key to UID and removes the actor and associated data.
pub fn delete_actor(call_context: CallContext, key: String) -> String {
    log(
        "actor",
        "DEBUG",
        &format!("Deleting actor for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log(
                "actor",
                "DEBUG",
                &format!("Resolved UID for deletion: {}", uid),
            );
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("actor", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match ACTOR_SERVICE.delete_actor(resolved_uid.clone()) {
        Ok(_) => {
            log(
                "actor",
                "INFO",
                &format!("Successfully deleted actor: {}", resolved_uid),
            );
            "OK".to_string()
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "actor",
                "ERROR",
                &format!("Failed to delete actor '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}
