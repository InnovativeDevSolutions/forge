//! Garage management operations for the Arma 3 server extension.
//!
//! Provides Arma 3 extension commands for vehicle storage, retrieval, and updates.

use arma_rs::{CallContext, Group};
use forge_models::Vehicle;
use forge_repositories::InMemoryGarageHotRepository;
use forge_services::{GarageHotStateService, GarageService};
use std::collections::HashMap;
use std::sync::LazyLock;

use crate::enqueue_persistence_task;
use crate::helpers::resolve_uid;
use crate::log::log;
use crate::storage::GarageStorageRepository;

/// Global garage service instance.
static GARAGE_SERVICE: LazyLock<GarageService<GarageStorageRepository>> =
    LazyLock::new(|| GarageService::new(GarageStorageRepository::configured()));
static HOT_GARAGE_SERVICE: LazyLock<
    GarageHotStateService<GarageStorageRepository, InMemoryGarageHotRepository>,
> = LazyLock::new(|| {
    let repository = GarageStorageRepository::configured();
    let hot_repository = InMemoryGarageHotRepository::new();
    GarageHotStateService::new(repository, hot_repository)
});

#[allow(dead_code)]
pub(crate) fn hot_service()
-> &'static GarageHotStateService<GarageStorageRepository, InMemoryGarageHotRepository> {
    &HOT_GARAGE_SERVICE
}

/// Creates the Arma 3 command group for garage operations.
///
/// Registers commands: `create`, `get`, `add`, `update`, `remove`, `delete`, `exists`.
pub fn group() -> Group {
    Group::new()
        .command("create", create_garage)
        .command("get", get_garage)
        .command("add", add_vehicle)
        .command("update", update_garage)
        .command("patch", patch_vehicle)
        .command("remove", remove_vehicle)
        .command("delete", delete_garage)
        .command("exists", garage_exists)
        .group(
            "hot",
            Group::new()
                .command("init", init_hot_garage)
                .command("get", get_hot_garage)
                .command("override", override_hot_garage)
                .command("save", save_hot_garage)
                .command("remove", remove_hot_garage)
                .command("add", add_hot_vehicle)
                .command("remove_vehicle", remove_hot_vehicle),
        )
}

fn serialize_hot_vehicles(garage: forge_models::garage::Garage) -> String {
    match serde_json::to_string(&garage.vehicles) {
        Ok(json) => json,
        Err(error) => format!("Error: Failed to serialize hot garage: {}", error),
    }
}

pub(crate) fn init_hot_garage(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_GARAGE_SERVICE.init_garage(resolved_uid) {
        Ok(garage) => serialize_hot_vehicles(garage),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn get_hot_garage(call_context: CallContext, key: String) -> String {
    init_hot_garage(call_context, key)
}

pub(crate) fn override_hot_garage(
    call_context: CallContext,
    key: String,
    json_data: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let vehicles: HashMap<String, Vehicle> = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid JSON data: {}", error),
    };

    match HOT_GARAGE_SERVICE.override_garage(resolved_uid, vehicles) {
        Ok(garage) => serialize_hot_vehicles(garage),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn save_hot_garage(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_GARAGE_SERVICE.get_garage(resolved_uid.clone()) {
        Ok(garage) => {
            enqueue_persistence_task("garage", move || {
                HOT_GARAGE_SERVICE.save_garage(resolved_uid).map(|_| ())
            });
            serialize_hot_vehicles(garage)
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn remove_hot_garage(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_GARAGE_SERVICE.remove_garage(resolved_uid) {
        Ok(_) => "OK".to_string(),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn add_hot_vehicle(call_context: CallContext, key: String, json_data: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let data: serde_json::Value = match serde_json::from_str(&json_data) {
        Ok(d) => d,
        Err(error) => return format!("Error: Invalid JSON data: {}", error),
    };

    let classname = match data.get("classname").and_then(|v| v.as_str()) {
        Some(c) => c.to_string(),
        None => return "Error: Missing or invalid classname".to_string(),
    };
    let fuel = match data.get("fuel").and_then(|v| v.as_f64()) {
        Some(f) => f,
        None => return "Error: Missing or invalid fuel".to_string(),
    };
    let damage = match data.get("damage").and_then(|v| v.as_f64()) {
        Some(d) => d,
        None => return "Error: Missing or invalid damage".to_string(),
    };
    let hit_points_json = match data.get("hit_points") {
        Some(hp) => match serde_json::to_string(hp) {
            Ok(s) => s,
            Err(error) => return format!("Error: Failed to serialize hit_points: {}", error),
        },
        None => return "Error: Missing hit_points".to_string(),
    };

    match HOT_GARAGE_SERVICE.add_vehicle(
        resolved_uid.clone(),
        classname,
        fuel,
        damage,
        hit_points_json,
    ) {
        Ok(garage) => {
            enqueue_persistence_task("garage", move || {
                HOT_GARAGE_SERVICE.save_garage(resolved_uid).map(|_| ())
            });
            serialize_hot_vehicles(garage)
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn remove_hot_vehicle(
    call_context: CallContext,
    key: String,
    json_data: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let data: serde_json::Value = match serde_json::from_str(&json_data) {
        Ok(d) => d,
        Err(error) => return format!("Error: Invalid JSON data: {}", error),
    };

    let plate = match data.get("plate").and_then(|v| v.as_str()) {
        Some(p) => p.to_string(),
        None => return "Error: Missing or invalid plate".to_string(),
    };

    match HOT_GARAGE_SERVICE.remove_vehicle(resolved_uid.clone(), plate) {
        Ok(garage) => {
            enqueue_persistence_task("garage", move || {
                HOT_GARAGE_SERVICE.save_garage(resolved_uid).map(|_| ())
            });
            serialize_hot_vehicles(garage)
        }
        Err(error) => format!("Error: {}", error),
    }
}

/// Creates a new empty garage for a player.
///
/// Parameters: key
pub fn create_garage(call_context: CallContext, key: String) -> String {
    log(
        "garage",
        "DEBUG",
        &format!("Creating garage for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match GARAGE_SERVICE.create_garage(resolved_uid.clone()) {
        Ok(empty_garage) => {
            log(
                "garage",
                "INFO",
                &format!("Successfully created garage for: {}", resolved_uid),
            );
            match serde_json::to_string(&empty_garage.vehicles) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize garage: {}", e);
                    log("garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "garage",
                "ERROR",
                &format!("Failed to create garage '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Retrieves a player's garage by key/UID.
///
/// Returns JSON object with garage data including all vehicles.
pub fn get_garage(call_context: CallContext, key: String) -> String {
    log(
        "garage",
        "DEBUG",
        &format!("Getting garage for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match GARAGE_SERVICE.get_garage(resolved_uid.clone()) {
        Ok(garage) => {
            log(
                "garage",
                "INFO",
                &format!(
                    "Successfully retrieved garage with {} vehicles",
                    garage.vehicles.len()
                ),
            );
            match serde_json::to_string(&garage.vehicles) {
                Ok(json) => {
                    log(
                        "garage",
                        "DEBUG",
                        &format!("Serialized garage to JSON: {}", json),
                    );
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize garage: {}", e);
                    log("garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "garage",
                "ERROR",
                &format!("Failed to get garage '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Adds a new vehicle to a player's garage.
///
/// Parameters: key, json_data
pub fn add_vehicle(call_context: CallContext, key: String, json_data: String) -> String {
    log(
        "garage",
        "DEBUG",
        &format!("Adding vehicle for key: {} with data: {}", key, json_data),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Parse JSON data
    let data: serde_json::Value = match serde_json::from_str(&json_data) {
        Ok(d) => d,
        Err(e) => {
            let error_msg = format!("Error: Invalid JSON data: {}", e);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Extract fields
    let classname = match data.get("classname").and_then(|v| v.as_str()) {
        Some(c) => c.to_string(),
        None => {
            let error_msg = "Error: Missing or invalid classname".to_string();
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let fuel = match data.get("fuel").and_then(|v| v.as_f64()) {
        Some(f) => f,
        None => {
            let error_msg = "Error: Missing or invalid fuel".to_string();
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let damage = match data.get("damage").and_then(|v| v.as_f64()) {
        Some(d) => d,
        None => {
            let error_msg = "Error: Missing or invalid damage".to_string();
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let hit_points_json = match data.get("hit_points") {
        Some(hp) => match serde_json::to_string(hp) {
            Ok(s) => s,
            Err(e) => {
                let error_msg = format!("Error: Failed to serialize hit_points: {}", e);
                log("garage", "ERROR", &error_msg);
                return error_msg;
            }
        },
        None => {
            let error_msg = "Error: Missing hit_points".to_string();
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match GARAGE_SERVICE.add_vehicle(
        resolved_uid.clone(),
        classname,
        fuel,
        damage,
        hit_points_json,
    ) {
        Ok(garage) => {
            log(
                "garage",
                "INFO",
                &format!("Successfully added vehicle to garage: {}", resolved_uid),
            );
            match serde_json::to_string(&garage.vehicles) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize garage: {}", e);
                    log("garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "garage",
                "ERROR",
                &format!("Failed to add vehicle '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Updates the entire garage state.
///
/// Parameters: key, json_data (Map of vehicles)
pub fn update_garage(call_context: CallContext, key: String, json_data: String) -> String {
    log(
        "garage",
        "DEBUG",
        &format!("Updating garage for key: {} with data: {}", key, json_data),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Parse JSON data
    let vehicles: HashMap<String, Vehicle> = match serde_json::from_str(&json_data) {
        Ok(d) => d,
        Err(e) => {
            let error_msg = format!("Error: Invalid JSON data: {}", e);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match GARAGE_SERVICE.update_garage(resolved_uid.clone(), vehicles) {
        Ok(garage) => {
            log(
                "garage",
                "INFO",
                &format!("Successfully updated garage for: {}", resolved_uid),
            );
            match serde_json::to_string(&garage.vehicles) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize garage: {}", e);
                    log("garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "garage",
                "ERROR",
                &format!("Failed to update garage '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Patches a specific vehicle in the garage.
///
/// Parameters: key, json_data (Map with plate and optional fields)
pub fn patch_vehicle(call_context: CallContext, key: String, json_data: String) -> String {
    log(
        "garage",
        "DEBUG",
        &format!("Patching vehicle for key: {} with data: {}", key, json_data),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let data: serde_json::Value = match serde_json::from_str(&json_data) {
        Ok(d) => d,
        Err(e) => {
            let error_msg = format!("Error: Invalid JSON data: {}", e);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let plate = match data.get("plate").and_then(|v| v.as_str()) {
        Some(s) => s.to_string(),
        None => {
            let error_msg = "Error: Missing plate".to_string();
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    let fuel = data.get("fuel").and_then(|v| v.as_f64());
    let damage = data.get("damage").and_then(|v| v.as_f64());
    let hit_points_json = data
        .get("hit_points")
        .and_then(|v| serde_json::to_string(v).ok());

    match GARAGE_SERVICE.patch_vehicle(resolved_uid.clone(), plate, damage, fuel, hit_points_json) {
        Ok(garage) => {
            log(
                "garage",
                "INFO",
                &format!("Successfully patched vehicle for: {}", resolved_uid),
            );
            match serde_json::to_string(&garage.vehicles) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize garage: {}", e);
                    log("garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "garage",
                "ERROR",
                &format!("Failed to patch vehicle '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Removes a vehicle from the garage.
///
/// Parameters: key, json_data
pub fn remove_vehicle(call_context: CallContext, key: String, json_data: String) -> String {
    log(
        "garage",
        "DEBUG",
        &format!(
            "Removing vehicle from garage for key: {} with data: {}",
            key, json_data
        ),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Parse JSON data
    let data: serde_json::Value = match serde_json::from_str(&json_data) {
        Ok(d) => d,
        Err(e) => {
            let error_msg = format!("Error: Invalid JSON data: {}", e);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    // Extract plate
    let plate = match data.get("plate").and_then(|v| v.as_str()) {
        Some(p) => p.to_string(),
        None => {
            let error_msg = "Error: Missing or invalid plate".to_string();
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match GARAGE_SERVICE.remove_vehicle(resolved_uid.clone(), plate) {
        Ok(garage) => {
            log(
                "garage",
                "INFO",
                &format!("Successfully removed vehicle from garage: {}", resolved_uid),
            );
            match serde_json::to_string(&garage.vehicles) {
                Ok(json) => json,
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize garage: {}", e);
                    log("garage", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "garage",
                "ERROR",
                &format!("Failed to remove vehicle '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Permanently deletes a player's garage.
pub fn delete_garage(call_context: CallContext, key: String) -> String {
    log(
        "garage",
        "DEBUG",
        &format!("Deleting garage for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("garage", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match GARAGE_SERVICE.delete_garage(resolved_uid.clone()) {
        Ok(_) => {
            log(
                "garage",
                "INFO",
                &format!("Successfully deleted garage: {}", resolved_uid),
            );
            "OK".to_string()
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "garage",
                "ERROR",
                &format!("Failed to delete garage '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Checks if a player has a garage.
pub fn garage_exists(call_context: CallContext, key: String) -> String {
    log(
        "garage",
        "DEBUG",
        &format!("Checking garage existence for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("garage", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            log(
                "garage",
                "ERROR",
                &format!("Failed to resolve UID for key: {}", key),
            );
            return "false".to_string();
        }
    };

    match GARAGE_SERVICE.garage_exists(resolved_uid.clone()) {
        Ok(exists) => {
            log(
                "garage",
                "DEBUG",
                &format!("Garage '{}' exists: {}", resolved_uid, exists),
            );
            exists.to_string()
        }
        Err(e) => {
            log(
                "garage",
                "ERROR",
                &format!("Failed to check if garage '{}' exists: {}", resolved_uid, e),
            );
            "false".to_string()
        }
    }
}
