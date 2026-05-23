use arma_rs::{CallContext, Group};
use forge_models::{EquipmentCategory, VLocker};
use forge_repositories::InMemoryVLockerHotRepository;
use forge_services::{VLockerHotStateService, VLockerService};
use std::sync::LazyLock;

use crate::enqueue_persistence_task;
use crate::helpers::resolve_uid;
use crate::log::log;
use crate::storage::VLockerStorageRepository;

static VLOCKER_SERVICE: LazyLock<VLockerService<VLockerStorageRepository>> =
    LazyLock::new(|| VLockerService::new(VLockerStorageRepository::configured()));
static HOT_VLOCKER_SERVICE: LazyLock<
    VLockerHotStateService<VLockerStorageRepository, InMemoryVLockerHotRepository>,
> = LazyLock::new(|| {
    let repository = VLockerStorageRepository::configured();
    let hot_repository = InMemoryVLockerHotRepository::new();
    VLockerHotStateService::new(repository, hot_repository)
});

pub(crate) fn hot_service()
-> &'static VLockerHotStateService<VLockerStorageRepository, InMemoryVLockerHotRepository> {
    &HOT_VLOCKER_SERVICE
}

/// Creates the Arma 3 command group for virtual locker operations.
///
/// Registers commands: `create`, `fetch`, `get`, `add`, `remove`, `delete`, `exists`.
pub fn group() -> Group {
    Group::new()
        .command("create", create_vlocker)
        .command("fetch", fetch_vlocker)
        .command("get", get_vlocker)
        .command("add", add_vlocker)
        .command("remove", remove_vlocker)
        .command("delete", delete_vlocker)
        .command("exists", vlocker_exists)
        .group(
            "hot",
            Group::new()
                .command("init", init_hot_vlocker)
                .command("fetch", fetch_hot_vlocker)
                .command("get", get_hot_vlocker)
                .command("override", override_hot_vlocker)
                .command("save", save_hot_vlocker)
                .command("remove", remove_hot_vlocker),
        )
}

fn serialize_hot_vlocker(locker: VLocker) -> String {
    match serde_json::to_string(&locker) {
        Ok(json) => json,
        Err(error) => format!("Error: Failed to serialize hot virtual locker: {}", error),
    }
}

pub(crate) fn init_hot_vlocker(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_VLOCKER_SERVICE.init_locker(&resolved_uid) {
        Ok(locker) => serialize_hot_vlocker(locker),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn fetch_hot_vlocker(call_context: CallContext, key: String) -> String {
    init_hot_vlocker(call_context, key)
}

pub(crate) fn get_hot_vlocker(call_context: CallContext, key: String, field: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let items = match HOT_VLOCKER_SERVICE.get_locker(&resolved_uid, &field) {
        Ok(items) => items,
        Err(error) => return format!("Error: {}", error),
    };

    match serde_json::to_string(&items) {
        Ok(json) => json,
        Err(error) => format!(
            "Error: Failed to serialize hot virtual locker field: {}",
            error
        ),
    }
}

pub(crate) fn override_hot_vlocker(
    call_context: CallContext,
    key: String,
    json_data: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let locker: VLocker = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid virtual locker JSON: {}", error),
    };

    match HOT_VLOCKER_SERVICE.override_locker(&resolved_uid, locker) {
        Ok(locker) => serialize_hot_vlocker(locker),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn save_hot_vlocker(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_VLOCKER_SERVICE.fetch_locker(&resolved_uid) {
        Ok(locker) => {
            enqueue_persistence_task("owned_locker", move || {
                HOT_VLOCKER_SERVICE.save_locker(&resolved_uid).map(|_| ())
            });
            serialize_hot_vlocker(locker)
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn remove_hot_vlocker(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_VLOCKER_SERVICE.remove_locker(&resolved_uid) {
        Ok(_) => "OK".to_string(),
        Err(error) => format!("Error: {}", error),
    }
}

/// Creates a new empty virtual locker for a player.
///
/// Parameters: key
pub fn create_vlocker(call_context: CallContext, key: String) -> String {
    log(
        "v_locker",
        "DEBUG",
        &format!("Creating virtual locker for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VLOCKER_SERVICE.create_locker(&resolved_uid) {
        Ok(locker) => {
            log(
                "v_locker",
                "INFO",
                &format!("Successfully created virtual locker for: {}", resolved_uid),
            );
            match serde_json::to_string(&locker) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize locker: {}", e);
                    log("v_locker", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_locker",
                "ERROR",
                &format!("Failed to create virtual locker '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Retrieves a player's complete virtual locker.
///
/// Returns JSON object with all four equipment arrays.
pub fn fetch_vlocker(call_context: CallContext, key: String) -> String {
    log(
        "v_locker",
        "DEBUG",
        &format!("Getting virtual locker for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VLOCKER_SERVICE.fetch_locker(&resolved_uid) {
        Ok(locker) => {
            log(
                "v_locker",
                "INFO",
                &format!("Successfully got virtual locker for: {}", resolved_uid),
            );
            match serde_json::to_string(&locker) {
                Ok(json) => {
                    log(
                        "v_locker",
                        "DEBUG",
                        &format!("Serialized locker to JSON: {}", json),
                    );
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize locker: {}", e);
                    log("v_locker", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_locker",
                "ERROR",
                &format!("Failed to get virtual locker '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Retrieves a specific field from a player's virtual locker.
///
/// Parameters: key, field (items, weapons, magazines, or backpacks)
pub fn get_vlocker(call_context: CallContext, key: String, field: String) -> String {
    log(
        "v_locker",
        "DEBUG",
        &format!(
            "Getting field '{}' from virtual locker for key: {}",
            field, key
        ),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VLOCKER_SERVICE.get_locker(&resolved_uid, &field) {
        Ok(items) => {
            log(
                "v_locker",
                "INFO",
                &format!(
                    "Successfully got field '{}' from virtual locker for: {}",
                    field, resolved_uid
                ),
            );
            match serde_json::to_string(&items) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize field: {}", e);
                    log("v_locker", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_locker",
                "ERROR",
                &format!(
                    "Failed to get field '{}' from virtual locker '{}': {}",
                    field, resolved_uid, e
                ),
            );
            error_msg
        }
    }
}

/// Adds items/weapons/magazines/backpacks to a player's virtual locker.
///
/// Parameters: key, category (items/weapons/magazines/backpacks), classnames_json (JSON array string)
pub fn add_vlocker(
    call_context: CallContext,
    key: String,
    category: String,
    classnames_json: String,
) -> String {
    log(
        "v_locker",
        "DEBUG",
        &format!(
            "Adding to category '{}' in virtual locker for key: {}",
            category, key
        ),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Parse category string to enum
    let category_enum = match category.to_lowercase().as_str() {
        "items" => EquipmentCategory::Items,
        "weapons" => EquipmentCategory::Weapons,
        "magazines" => EquipmentCategory::Magazines,
        "backpacks" => EquipmentCategory::Backpacks,
        _ => {
            let error_msg = format!(
                "Error: Invalid category '{}'. Valid options: items, weapons, magazines, backpacks",
                category
            );
            log("v_locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Parse classnames JSON
    let classnames: Vec<String> = match serde_json::from_str(&classnames_json) {
        Ok(names) => names,
        Err(e) => {
            let error_msg = format!("Error: Invalid JSON array: {}", e);
            log("v_locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VLOCKER_SERVICE.add_locker(&resolved_uid, category_enum, classnames) {
        Ok(locker) => {
            log(
                "v_locker",
                "INFO",
                &format!(
                    "Successfully added items to category '{}' for: {}",
                    category, resolved_uid
                ),
            );
            match serde_json::to_string(&locker.get(category_enum)) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize category: {}", e);
                    log("v_locker", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_locker",
                "ERROR",
                &format!(
                    "Failed to add items to category '{}' for virtual locker '{}': {}",
                    category, resolved_uid, e
                ),
            );
            error_msg
        }
    }
}

/// Removes an item from a player's virtual locker category.
///
/// Parameters: key, category (items/weapons/magazines/backpacks), classname
pub fn remove_vlocker(
    call_context: CallContext,
    key: String,
    category: String,
    classname: String,
) -> String {
    log(
        "v_locker",
        "DEBUG",
        &format!(
            "Removing '{}' from category '{}' in virtual locker for key: {}",
            classname, category, key
        ),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Parse category string to enum
    let category_enum = match category.to_lowercase().as_str() {
        "items" => EquipmentCategory::Items,
        "weapons" => EquipmentCategory::Weapons,
        "magazines" => EquipmentCategory::Magazines,
        "backpacks" => EquipmentCategory::Backpacks,
        _ => {
            let error_msg = format!(
                "Error: Invalid category '{}'. Valid options: items, weapons, magazines, backpacks",
                category
            );
            log("v_locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VLOCKER_SERVICE.remove_locker(&resolved_uid, category_enum, &classname) {
        Ok(locker) => {
            log(
                "v_locker",
                "INFO",
                &format!(
                    "Successfully removed item from category '{}' for: {}",
                    category, resolved_uid
                ),
            );
            match serde_json::to_string(&locker.get(category_enum)) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize category: {}", e);
                    log("v_locker", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_locker",
                "ERROR",
                &format!(
                    "Failed to remove item from category '{}' for virtual locker '{}': {}",
                    category, resolved_uid, e
                ),
            );
            error_msg
        }
    }
}

/// Permanently deletes a player's virtual locker.
///
/// Parameters: key
pub fn delete_vlocker(call_context: CallContext, key: String) -> String {
    log(
        "v_locker",
        "DEBUG",
        &format!("Deleting virtual locker for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VLOCKER_SERVICE.delete_locker(&resolved_uid) {
        Ok(()) => {
            log(
                "v_locker",
                "INFO",
                &format!("Successfully deleted virtual locker for: {}", resolved_uid),
            );
            "OK".to_string()
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_locker",
                "ERROR",
                &format!("Failed to delete virtual locker '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Checks if a player has a virtual locker (even if empty)
///
/// Parameters: key
pub fn vlocker_exists(call_context: CallContext, key: String) -> String {
    log(
        "v_locker",
        "DEBUG",
        &format!("Checking if virtual locker exists for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            log(
                "v_locker",
                "WARN",
                &format!("Failed to resolve UID for key: {}", key),
            );
            return "false".to_string();
        }
    };

    match VLOCKER_SERVICE.locker_exists(&resolved_uid) {
        Ok(exists) => {
            log(
                "v_locker",
                "DEBUG",
                &format!("Virtual locker '{}' exists: {}", resolved_uid, exists),
            );
            exists.to_string()
        }
        Err(e) => {
            log(
                "v_locker",
                "ERROR",
                &format!(
                    "Failed to check if virtual locker '{}' exists: {}",
                    resolved_uid, e
                ),
            );
            "false".to_string()
        }
    }
}
