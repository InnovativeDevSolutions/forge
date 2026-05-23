use arma_rs::{CallContext, Group};
use forge_models::locker::Item;
use forge_repositories::InMemoryLockerHotRepository;
use forge_services::{LockerHotStateService, LockerService};
use std::collections::HashMap;
use std::sync::LazyLock;

use crate::enqueue_persistence_task;
use crate::helpers::resolve_uid;
use crate::log::log;
use crate::storage::LockerStorageRepository;

static LOCKER_SERVICE: LazyLock<LockerService<LockerStorageRepository>> =
    LazyLock::new(|| LockerService::new(LockerStorageRepository::configured()));
static HOT_LOCKER_SERVICE: LazyLock<
    LockerHotStateService<LockerStorageRepository, InMemoryLockerHotRepository>,
> = LazyLock::new(|| {
    let repository = LockerStorageRepository::configured();
    let hot_repository = InMemoryLockerHotRepository::new();
    LockerHotStateService::new(repository, hot_repository)
});

pub(crate) fn hot_service()
-> &'static LockerHotStateService<LockerStorageRepository, InMemoryLockerHotRepository> {
    &HOT_LOCKER_SERVICE
}

/// Creates the Arma 3 command group for locker operations.
///
/// Registers commands: `create`, `get`, `add`, `update`, `remove`, `delete`, `exists`.
pub fn group() -> Group {
    Group::new()
        .command("create", create_locker)
        .command("get", get_locker)
        .command("add", add_item)
        .command("update", update_locker)
        .command("patch", patch_item)
        .command("remove", remove_item)
        .command("delete", delete_locker)
        .command("exists", locker_exists)
        .group(
            "hot",
            Group::new()
                .command("init", init_hot_locker)
                .command("get", get_hot_locker)
                .command("override", override_hot_locker)
                .command("save", save_hot_locker)
                .command("remove", remove_hot_locker),
        )
}

fn serialize_hot_items(locker: forge_models::locker::Locker) -> String {
    match serde_json::to_string(&locker.items) {
        Ok(json) => json,
        Err(error) => format!("Error: Failed to serialize hot locker: {}", error),
    }
}

pub(crate) fn init_hot_locker(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_LOCKER_SERVICE.init_locker(resolved_uid) {
        Ok(locker) => serialize_hot_items(locker),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn get_hot_locker(call_context: CallContext, key: String) -> String {
    init_hot_locker(call_context, key)
}

pub(crate) fn override_hot_locker(
    call_context: CallContext,
    key: String,
    json_data: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let items: std::collections::HashMap<String, Item> = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid JSON data: {}", error),
    };

    match HOT_LOCKER_SERVICE.override_locker(resolved_uid, items) {
        Ok(locker) => serialize_hot_items(locker),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn save_hot_locker(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_LOCKER_SERVICE.get_locker(resolved_uid.clone()) {
        Ok(locker) => {
            enqueue_persistence_task("locker", move || {
                HOT_LOCKER_SERVICE.save_locker(resolved_uid).map(|_| ())
            });
            serialize_hot_items(locker)
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn remove_hot_locker(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_LOCKER_SERVICE.remove_locker(resolved_uid) {
        Ok(_) => "OK".to_string(),
        Err(error) => format!("Error: {}", error),
    }
}

/// Creates a new empty locker for a player.
///
/// Parameters: key
pub fn create_locker(call_context: CallContext, key: String) -> String {
    log(
        "locker",
        "DEBUG",
        &format!("Creating locker for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match LOCKER_SERVICE.create_locker(resolved_uid.clone()) {
        Ok(locker) => {
            log(
                "locker",
                "INFO",
                &format!("Successfully created locker for: {}", resolved_uid),
            );
            match serde_json::to_string(&locker.items) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize locker: {}", e);
                    log("locker", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "locker",
                "ERROR",
                &format!("Failed to create locker '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Retrieves a player's locker by key/UID.
///
/// Returns JSON object with locker data including all items.
pub fn get_locker(call_context: CallContext, key: String) -> String {
    log(
        "locker",
        "DEBUG",
        &format!("Getting locker for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match LOCKER_SERVICE.get_locker(resolved_uid.clone()) {
        Ok(locker) => {
            log(
                "locker",
                "INFO",
                &format!("Successfully got locker for: {}", resolved_uid),
            );
            match serde_json::to_string(&locker.items) {
                Ok(json) => {
                    log(
                        "locker",
                        "DEBUG",
                        &format!("Serialized locker to JSON: {}", json),
                    );
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize locker: {}", e);
                    log("locker", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "locker",
                "ERROR",
                &format!("Failed to get locker '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Adds a new item to a player's locker.
///
/// Parameters: key, json_data
pub fn add_item(call_context: CallContext, key: String, json_data: String) -> String {
    log(
        "locker",
        "DEBUG",
        &format!(
            "Adding item to locker for key: {} with data: {}",
            key, json_data
        ),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Parse JSON data
    let data: serde_json::Value = match serde_json::from_str(&json_data) {
        Ok(d) => d,
        Err(e) => {
            let error_msg = format!("Error: Invalid JSON data: {}", e);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Extract fields
    let category = match data.get("category").and_then(|v| v.as_str()) {
        Some(c) => c.to_string(),
        None => {
            let error_msg = "Error: Missing or invalid category".to_string();
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let classname = match data.get("classname").and_then(|v| v.as_str()) {
        Some(c) => c.to_string(),
        None => {
            let error_msg = "Error: Missing or invalid classname".to_string();
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let amount = match data.get("amount").and_then(|v| v.as_u64()) {
        Some(a) => a as u32,
        None => {
            let error_msg = "Error: Missing or invalid amount".to_string();
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Create item with validation
    let item = match Item::new(category, classname, amount) {
        Ok(i) => i,
        Err(e) => {
            let error_msg = format!("Error: Validation failed: {}", e);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match LOCKER_SERVICE.add_item(resolved_uid.clone(), item) {
        Ok(locker) => {
            log(
                "locker",
                "INFO",
                &format!("Successfully added item to locker for: {}", resolved_uid),
            );
            match serde_json::to_string(&locker.items) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize locker: {}", e);
                    log("locker", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "locker",
                "ERROR",
                &format!("Failed to add item to locker '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Updates the entire locker state (Bulk Sync).
///
/// Parameters: key, json_data (Map of items)
pub fn update_locker(call_context: CallContext, key: String, json_data: String) -> String {
    log(
        "locker",
        "DEBUG",
        &format!("Updating locker for key: {} with data: {}", key, json_data),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let items: HashMap<String, Item> = match serde_json::from_str(&json_data) {
        Ok(d) => d,
        Err(e) => {
            let error_msg = format!("Error: Invalid JSON data: {}", e);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match LOCKER_SERVICE.update_locker(resolved_uid.clone(), items) {
        Ok(locker) => {
            log(
                "locker",
                "INFO",
                &format!("Locker updated successfully for key: {}", resolved_uid),
            );
            match serde_json::to_string(&locker.items) {
                Ok(s) => s,
                Err(e) => format!("Error serializing locker: {}", e),
            }
        }
        Err(e) => {
            log("locker", "ERROR", &format!("Error updating locker: {}", e));
            format!("Error: {}", e)
        }
    }
}

/// Patches a specific item in the locker.
///
/// Parameters: key, json_data (Map with classname and optional amount)
pub fn patch_item(call_context: CallContext, key: String, json_data: String) -> String {
    log(
        "locker",
        "DEBUG",
        &format!("Patching item for key: {} with data: {}", key, json_data),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let data: serde_json::Value = match serde_json::from_str(&json_data) {
        Ok(d) => d,
        Err(e) => {
            let error_msg = format!("Error: Invalid JSON data: {}", e);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let classname = match data.get("classname").and_then(|v| v.as_str()) {
        Some(s) => s.to_string(),
        None => {
            let error_msg = "Error: Missing classname".to_string();
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let amount = data
        .get("amount")
        .and_then(|v| v.as_u64())
        .map(|v| v as u32);

    match LOCKER_SERVICE.patch_item(resolved_uid.clone(), classname, amount) {
        Ok(locker) => {
            log(
                "locker",
                "INFO",
                &format!("Successfully patched item for: {}", resolved_uid),
            );
            match serde_json::to_string(&locker.items) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize locker: {}", e);
                    log("locker", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "locker",
                "ERROR",
                &format!("Failed to patch item '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Removes an item from the locker.
///
/// Parameters: key, classname
pub fn remove_item(call_context: CallContext, key: String, classname: String) -> String {
    log(
        "locker",
        "DEBUG",
        &format!("Removing item from locker for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match LOCKER_SERVICE.remove_item(resolved_uid.clone(), classname) {
        Ok(locker) => {
            log(
                "locker",
                "INFO",
                &format!(
                    "Successfully removed item from locker for: {}",
                    resolved_uid
                ),
            );
            match serde_json::to_string(&locker.items) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize locker: {}", e);
                    log("locker", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "locker",
                "ERROR",
                &format!(
                    "Failed to remove item from locker '{}': {}",
                    resolved_uid, e
                ),
            );
            error_msg
        }
    }
}

/// Permanently deletes a player's locker.
pub fn delete_locker(call_context: CallContext, key: String) -> String {
    log(
        "locker",
        "DEBUG",
        &format!("Deleting locker for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("locker", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match LOCKER_SERVICE.delete_locker(resolved_uid.clone()) {
        Ok(()) => {
            log(
                "locker",
                "INFO",
                &format!("Successfully deleted locker for: {}", resolved_uid),
            );
            "OK".to_string()
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "locker",
                "ERROR",
                &format!("Failed to delete locker '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Checks if a player has a locker (even if empty)
pub fn locker_exists(call_context: CallContext, key: String) -> String {
    log(
        "locker",
        "DEBUG",
        &format!("Checking if locker exists for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("locker", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            log(
                "locker",
                "ERROR",
                &format!("Failed to resolve UID for key: {}", key),
            );
            return "false".to_string();
        }
    };

    match LOCKER_SERVICE.locker_exists(resolved_uid.clone()) {
        Ok(exists) => {
            log(
                "locker",
                "DEBUG",
                &format!("Locker '{}' exists: {}", resolved_uid, exists),
            );
            exists.to_string()
        }
        Err(e) => {
            log(
                "locker",
                "ERROR",
                &format!(
                    "Failed to check if locker exists for '{}': {}",
                    resolved_uid, e
                ),
            );
            "false".to_string()
        }
    }
}
