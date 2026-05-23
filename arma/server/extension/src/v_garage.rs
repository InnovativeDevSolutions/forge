use arma_rs::{CallContext, Group};
use forge_models::{VGarage, VehicleCategory};
use forge_repositories::InMemoryVGarageHotRepository;
use forge_services::{VGarageHotStateService, VGarageService};
use std::sync::LazyLock;

use crate::enqueue_persistence_task;
use crate::helpers::resolve_uid;
use crate::log::log;
use crate::storage::VGarageStorageRepository;

static VGARAGE_SERVICE: LazyLock<VGarageService<VGarageStorageRepository>> =
    LazyLock::new(|| VGarageService::new(VGarageStorageRepository::configured()));
static HOT_VGARAGE_SERVICE: LazyLock<
    VGarageHotStateService<VGarageStorageRepository, InMemoryVGarageHotRepository>,
> = LazyLock::new(|| {
    let repository = VGarageStorageRepository::configured();
    let hot_repository = InMemoryVGarageHotRepository::new();
    VGarageHotStateService::new(repository, hot_repository)
});

pub(crate) fn hot_service()
-> &'static VGarageHotStateService<VGarageStorageRepository, InMemoryVGarageHotRepository> {
    &HOT_VGARAGE_SERVICE
}

/// Creates the Arma 3 command group for virtual garage operations.
///
/// Registers commands: `create`, `fetch`, `get`, `add`, `remove`, `delete`, `exists`.
pub fn group() -> Group {
    Group::new()
        .command("create", create_vgarage)
        .command("fetch", fetch_vgarage)
        .command("get", get_vgarage)
        .command("add", add_vgarage)
        .command("remove", remove_vgarage)
        .command("delete", delete_vgarage)
        .command("exists", vgarage_exists)
        .group(
            "hot",
            Group::new()
                .command("init", init_hot_vgarage)
                .command("fetch", fetch_hot_vgarage)
                .command("get", get_hot_vgarage)
                .command("override", override_hot_vgarage)
                .command("save", save_hot_vgarage)
                .command("remove", remove_hot_vgarage)
                .command("add", add_hot_vgarage)
                .command("remove_item", remove_hot_vgarage_item),
        )
}

fn serialize_hot_vgarage(garage: VGarage) -> String {
    match serde_json::to_string(&garage) {
        Ok(json) => json,
        Err(error) => format!("Error: Failed to serialize hot virtual garage: {}", error),
    }
}

pub(crate) fn init_hot_vgarage(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_VGARAGE_SERVICE.init_garage(&resolved_uid) {
        Ok(garage) => serialize_hot_vgarage(garage),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn fetch_hot_vgarage(call_context: CallContext, key: String) -> String {
    init_hot_vgarage(call_context, key)
}

pub(crate) fn get_hot_vgarage(call_context: CallContext, key: String, field: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let items = match HOT_VGARAGE_SERVICE.get_garage(&resolved_uid, &field) {
        Ok(items) => items,
        Err(error) => return format!("Error: {}", error),
    };
    match serde_json::to_string(&items) {
        Ok(json) => json,
        Err(error) => format!(
            "Error: Failed to serialize hot virtual garage field: {}",
            error
        ),
    }
}

pub(crate) fn override_hot_vgarage(
    call_context: CallContext,
    key: String,
    json_data: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let garage: VGarage = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid virtual garage JSON: {}", error),
    };

    match HOT_VGARAGE_SERVICE.override_garage(&resolved_uid, garage) {
        Ok(garage) => serialize_hot_vgarage(garage),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn save_hot_vgarage(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_VGARAGE_SERVICE.fetch_garage(&resolved_uid) {
        Ok(garage) => {
            enqueue_persistence_task("owned_garage", move || {
                HOT_VGARAGE_SERVICE.save_garage(&resolved_uid).map(|_| ())
            });
            serialize_hot_vgarage(garage)
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn remove_hot_vgarage(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_VGARAGE_SERVICE.remove_hot_garage(&resolved_uid) {
        Ok(_) => "OK".to_string(),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn add_hot_vgarage(
    call_context: CallContext,
    key: String,
    category: String,
    classnames_json: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let category_enum = match category.to_lowercase().as_str() {
        "cars" => VehicleCategory::Cars,
        "armor" => VehicleCategory::Armor,
        "helis" => VehicleCategory::Helis,
        "planes" => VehicleCategory::Planes,
        "naval" => VehicleCategory::Naval,
        "other" => VehicleCategory::Other,
        _ => {
            return format!(
                "Error: Invalid category '{}'. Valid options: cars, armor, helis, planes, naval, other",
                category
            );
        }
    };

    let classnames: Vec<String> = match serde_json::from_str(&classnames_json) {
        Ok(names) => names,
        Err(error) => return format!("Error: Invalid JSON array: {}", error),
    };

    match HOT_VGARAGE_SERVICE.add_garage(&resolved_uid, category_enum, classnames) {
        Ok(garage) => match serde_json::to_string(&garage.get(category_enum)) {
            Ok(json) => json,
            Err(error) => format!("Error: Failed to serialize category: {}", error),
        },
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn remove_hot_vgarage_item(
    call_context: CallContext,
    key: String,
    category: String,
    classname: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let category_enum = match category.to_lowercase().as_str() {
        "cars" => VehicleCategory::Cars,
        "armor" => VehicleCategory::Armor,
        "heli" | "helis" => VehicleCategory::Helis,
        "planes" => VehicleCategory::Planes,
        "naval" => VehicleCategory::Naval,
        "other" => VehicleCategory::Other,
        _ => {
            return format!(
                "Error: Invalid category '{}'. Valid options: cars, armor, helis, planes, naval, other",
                category
            );
        }
    };

    match HOT_VGARAGE_SERVICE.remove_garage(&resolved_uid, category_enum, &classname) {
        Ok(garage) => match serde_json::to_string(&garage.get(category_enum)) {
            Ok(json) => json,
            Err(error) => format!("Error: Failed to serialize category: {}", error),
        },
        Err(error) => format!("Error: {}", error),
    }
}

/// Creates a new empty virtual garage for a player.
///
/// Parameters: key
pub fn create_vgarage(call_context: CallContext, key: String) -> String {
    log(
        "v_garage",
        "DEBUG",
        &format!("Creating virtual garage for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VGARAGE_SERVICE.create_garage(&resolved_uid) {
        Ok(garage) => {
            log(
                "v_garage",
                "INFO",
                &format!("Successfully created virtual garage for: {}", resolved_uid),
            );
            match serde_json::to_string(&garage) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize garage: {}", e);
                    log("v_garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_garage",
                "ERROR",
                &format!("Failed to create virtual garage '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Retrieves a player's complete virtual garage.
///
/// Returns JSON object with all six vehicle arrays.
pub fn fetch_vgarage(call_context: CallContext, key: String) -> String {
    log(
        "v_garage",
        "DEBUG",
        &format!("Getting virtual garage for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VGARAGE_SERVICE.fetch_garage(&resolved_uid) {
        Ok(garage) => {
            log(
                "v_garage",
                "INFO",
                &format!("Successfully got virtual garage for: {}", resolved_uid),
            );
            match serde_json::to_string(&garage) {
                Ok(json) => {
                    log(
                        "v_garage",
                        "DEBUG",
                        &format!("Serialized garage to JSON: {}", json),
                    );
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize garage: {}", e);
                    log("v_garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_garage",
                "ERROR",
                &format!("Failed to get virtual garage '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Retrieves a specific field from a player's virtual garage.
///
/// Parameters: key, field (cars, armor, helis, planes, naval, or other)
pub fn get_vgarage(call_context: CallContext, key: String, field: String) -> String {
    log(
        "v_garage",
        "DEBUG",
        &format!(
            "Getting field '{}' from virtual garage for key: {}",
            field, key
        ),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VGARAGE_SERVICE.get_garage(&resolved_uid, &field) {
        Ok(items) => {
            log(
                "v_garage",
                "INFO",
                &format!(
                    "Successfully got field '{}' from virtual garage for: {}",
                    field, resolved_uid
                ),
            );
            match serde_json::to_string(&items) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize field: {}", e);
                    log("v_garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_garage",
                "ERROR",
                &format!(
                    "Failed to get field '{}' from virtual garage '{}': {}",
                    field, resolved_uid, e
                ),
            );
            error_msg
        }
    }
}

/// Adds cars/armor/helis/planes/naval/other to a player's virtual garage.
///
/// Parameters: key, category (cars, armor, helis, planes, naval, or other), classnames_json (JSON array string)
pub fn add_vgarage(
    call_context: CallContext,
    key: String,
    category: String,
    classnames_json: String,
) -> String {
    log(
        "v_garage",
        "DEBUG",
        &format!(
            "Adding to category '{}' in virtual garage for key: {}",
            category, key
        ),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Parse category string to enum
    let category_enum = match category.to_lowercase().as_str() {
        "cars" => VehicleCategory::Cars,
        "armor" => VehicleCategory::Armor,
        "helis" => VehicleCategory::Helis,
        "planes" => VehicleCategory::Planes,
        "naval" => VehicleCategory::Naval,
        "other" => VehicleCategory::Other,
        _ => {
            let error_msg = format!(
                "Error: Invalid category '{}'. Valid options: cars, armor, helis, planes, naval, other",
                category
            );
            log("v_garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Parse classnames JSON
    let classnames: Vec<String> = match serde_json::from_str(&classnames_json) {
        Ok(names) => names,
        Err(e) => {
            let error_msg = format!("Error: Invalid JSON array: {}", e);
            log("v_garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VGARAGE_SERVICE.add_garage(&resolved_uid, category_enum, classnames) {
        Ok(garage) => {
            log(
                "v_garage",
                "INFO",
                &format!(
                    "Successfully added items to category '{}' for: {}",
                    category, resolved_uid
                ),
            );
            match serde_json::to_string(&garage.get(category_enum)) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize category: {}", e);
                    log("v_garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_garage",
                "ERROR",
                &format!(
                    "Failed to add items to category '{}' for virtual garage '{}': {}",
                    category, resolved_uid, e
                ),
            );
            error_msg
        }
    }
}

/// Removes an item from a player's virtual garage category.
///
/// Parameters: key, category (cars, armor, helis, planes, naval, or other), classname
pub fn remove_vgarage(
    call_context: CallContext,
    key: String,
    category: String,
    classname: String,
) -> String {
    log(
        "v_garage",
        "DEBUG",
        &format!(
            "Removing '{}' from category '{}' in virtual garage for key: {}",
            classname, category, key
        ),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Parse category string to enum
    let category_enum = match category.to_lowercase().as_str() {
        "cars" => VehicleCategory::Cars,
        "armor" => VehicleCategory::Armor,
        "heli" => VehicleCategory::Helis,
        "planes" => VehicleCategory::Planes,
        "naval" => VehicleCategory::Naval,
        "other" => VehicleCategory::Other,
        _ => {
            let error_msg = format!(
                "Error: Invalid category '{}'. Valid options: cars, armor, helis, planes, naval, other",
                category
            );
            log("v_garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VGARAGE_SERVICE.remove_garage(&resolved_uid, category_enum, &classname) {
        Ok(garage) => {
            log(
                "v_garage",
                "INFO",
                &format!(
                    "Successfully removed item from category '{}' for: {}",
                    category, resolved_uid
                ),
            );
            match serde_json::to_string(&garage.get(category_enum)) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize category: {}", e);
                    log("v_garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_garage",
                "ERROR",
                &format!(
                    "Failed to remove item from category '{}' for virtual garage '{}': {}",
                    category, resolved_uid, e
                ),
            );
            error_msg
        }
    }
}

/// Permanently deletes a player's virtual garage.
///
/// Parameters: key
pub fn delete_vgarage(call_context: CallContext, key: String) -> String {
    log(
        "v_garage",
        "DEBUG",
        &format!("Deleting virtual garage for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("v_garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match VGARAGE_SERVICE.delete_garage(&resolved_uid) {
        Ok(()) => {
            log(
                "v_garage",
                "INFO",
                &format!("Successfully deleted virtual garage for: {}", resolved_uid),
            );
            "OK".to_string()
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "v_garage",
                "ERROR",
                &format!("Failed to delete virtual garage '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Checks if a player has a virtual garage (even if empty)
///
/// Parameters: key
pub fn vgarage_exists(call_context: CallContext, key: String) -> String {
    log(
        "v_garage",
        "DEBUG",
        &format!("Checking if virtual garage exists for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("v_garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            log(
                "v_garage",
                "WARN",
                &format!("Failed to resolve UID for key: {}", key),
            );
            return "false".to_string();
        }
    };

    match VGARAGE_SERVICE.garage_exists(&resolved_uid) {
        Ok(exists) => {
            log(
                "v_garage",
                "DEBUG",
                &format!("Virtual garage '{}' exists: {}", resolved_uid, exists),
            );
            exists.to_string()
        }
        Err(e) => {
            log(
                "v_garage",
                "ERROR",
                &format!(
                    "Failed to check if virtual garage '{}' exists: {}",
                    resolved_uid, e
                ),
            );
            "false".to_string()
        }
    }
}
