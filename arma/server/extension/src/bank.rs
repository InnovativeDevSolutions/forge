//! Bank management operations for the Arma 3 server extension.
//!
//! Provides Arma 3 extension commands for player data storage, retrieval, and updates.
//! Handles SQF command mapping and parameter validation.

use arma_rs::{CallContext, Group};
use forge_models::{
    BankCheckoutContext, BankMutationResult, BankOperationContext, BankPinContext,
    BankTransferContext, BankTransferResult,
};
use forge_repositories::InMemoryBankHotRepository;
use forge_services::{BankHotStateService, BankService};
use std::sync::LazyLock;

use crate::enqueue_persistence_task;
use crate::helpers::resolve_uid;
use crate::log::log;
use crate::storage::BankStorageRepository;

/// Global bank service instance.
///
/// Lazily initialized singleton combining repository and service layers.
static BANK_SERVICE: LazyLock<BankService<BankStorageRepository>> =
    LazyLock::new(|| BankService::new(BankStorageRepository::configured()));
static HOT_BANK_SERVICE: LazyLock<
    BankHotStateService<BankStorageRepository, InMemoryBankHotRepository>,
> = LazyLock::new(|| {
    let repository = BankStorageRepository::configured();
    let hot_repository = InMemoryBankHotRepository::new();
    BankHotStateService::new(repository, hot_repository)
});

pub(crate) fn hot_service()
-> &'static BankHotStateService<BankStorageRepository, InMemoryBankHotRepository> {
    &HOT_BANK_SERVICE
}

/// Creates the Arma 3 command group for bank operations.
///
/// Registers commands: `get`, `exists`, `create`, `update`, `delete`.
pub fn group() -> Group {
    Group::new()
        .command("get", get_bank)
        .command("create", create_bank)
        .command("update", update_bank)
        .command("exists", bank_exists)
        .command("delete", delete_bank)
        .group(
            "hot",
            Group::new()
                .command("init", init_hot_bank)
                .command("get", get_hot_bank)
                .command("override", override_hot_bank)
                .command("patch", patch_hot_bank)
                .command("charge_checkout", charge_checkout_hot_bank)
                .command("deposit", deposit_hot_bank)
                .command("withdraw", withdraw_hot_bank)
                .command("deposit_earnings", deposit_earnings_hot_bank)
                .command("transfer", transfer_hot_bank)
                .command("validate_pin", validate_pin_hot_bank)
                .command("change_pin", change_pin_hot_bank)
                .command("save", save_hot_bank)
                .command("remove", remove_hot_bank),
        )
}

fn serialize_hot_bank(bank: forge_models::Bank) -> String {
    match serde_json::to_string(&bank) {
        Ok(json) => json,
        Err(error) => format!("Error: Failed to serialize hot bank: {}", error),
    }
}

fn serialize_hot_bank_mutation(result: BankMutationResult) -> String {
    match serde_json::to_string(&result) {
        Ok(json) => json,
        Err(error) => format!("Error: Failed to serialize hot bank mutation: {}", error),
    }
}

fn serialize_hot_bank_transfer(result: BankTransferResult) -> String {
    match serde_json::to_string(&result) {
        Ok(json) => json,
        Err(error) => format!("Error: Failed to serialize hot bank transfer: {}", error),
    }
}

fn parse_amount(amount: String, label: &str) -> Result<f64, String> {
    amount
        .parse::<f64>()
        .map_err(|error| format!("Invalid {} amount '{}': {}", label, amount, error))
}

fn parse_operation_context(json_context: String) -> Result<BankOperationContext, String> {
    serde_json::from_str(&json_context)
        .map_err(|error| format!("Invalid bank operation context: {}", error))
}

fn parse_transfer_context(json_context: String) -> Result<BankTransferContext, String> {
    serde_json::from_str(&json_context)
        .map_err(|error| format!("Invalid bank transfer context: {}", error))
}

fn parse_checkout_context(json_context: String) -> Result<BankCheckoutContext, String> {
    serde_json::from_str(&json_context)
        .map_err(|error| format!("Invalid bank checkout context: {}", error))
}

fn parse_pin_context(json_context: String) -> Result<BankPinContext, String> {
    serde_json::from_str(&json_context)
        .map_err(|error| format!("Invalid bank PIN context: {}", error))
}

pub(crate) fn init_hot_bank(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_BANK_SERVICE.init_bank(resolved_uid) {
        Ok(bank) => serialize_hot_bank(bank),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn get_hot_bank(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_BANK_SERVICE.get_bank(resolved_uid) {
        Ok(bank) => serialize_hot_bank(bank),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn override_hot_bank(
    call_context: CallContext,
    key: String,
    json_data: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_BANK_SERVICE.override_bank(resolved_uid.clone(), json_data) {
        Ok(bank) => serialize_hot_bank(bank),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn patch_hot_bank(call_context: CallContext, key: String, json_patch: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_BANK_SERVICE.patch_bank(resolved_uid, json_patch) {
        Ok(result) => serialize_hot_bank_mutation(result),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn charge_checkout_hot_bank(
    call_context: CallContext,
    key: String,
    amount: String,
    json_context: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let amount = match parse_amount(amount, "checkout") {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };
    let context = match parse_checkout_context(json_context) {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };

    match HOT_BANK_SERVICE.charge_checkout(resolved_uid, amount, context) {
        Ok(result) => serialize_hot_bank_mutation(result),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn deposit_hot_bank(
    call_context: CallContext,
    key: String,
    amount: String,
    json_context: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let amount = match parse_amount(amount, "deposit") {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };
    let context = match parse_operation_context(json_context) {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };

    match HOT_BANK_SERVICE.deposit(resolved_uid, amount, context) {
        Ok(result) => serialize_hot_bank_mutation(result),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn withdraw_hot_bank(
    call_context: CallContext,
    key: String,
    amount: String,
    json_context: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let amount = match parse_amount(amount, "withdraw") {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };
    let context = match parse_operation_context(json_context) {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };

    match HOT_BANK_SERVICE.withdraw(resolved_uid, amount, context) {
        Ok(result) => serialize_hot_bank_mutation(result),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn deposit_earnings_hot_bank(
    call_context: CallContext,
    key: String,
    amount: String,
    json_context: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    let amount = match parse_amount(amount, "deposit earnings") {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };
    let context = match parse_operation_context(json_context) {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };

    match HOT_BANK_SERVICE.deposit_earnings(resolved_uid, amount, context) {
        Ok(result) => serialize_hot_bank_mutation(result),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn transfer_hot_bank(
    call_context: CallContext,
    source_key: String,
    target_key: String,
    amount: String,
    json_context: String,
) -> String {
    let resolved_source_uid = match resolve_uid(&source_key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", source_key),
    };
    let resolved_target_uid = match resolve_uid(&target_key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", target_key),
    };
    let amount = match parse_amount(amount, "transfer") {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };
    let context = match parse_transfer_context(json_context) {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };

    match HOT_BANK_SERVICE.transfer(resolved_source_uid, resolved_target_uid, context, amount) {
        Ok(result) => serialize_hot_bank_transfer(result),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn validate_pin_hot_bank(
    call_context: CallContext,
    key: String,
    pin: String,
    json_context: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };
    let context = match parse_pin_context(json_context) {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };

    match HOT_BANK_SERVICE.validate_pin(resolved_uid, pin, context) {
        Ok(_) => "{}".to_string(),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn change_pin_hot_bank(
    call_context: CallContext,
    key: String,
    current_pin: String,
    new_pin: String,
    json_context: String,
) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };
    let context = match parse_pin_context(json_context) {
        Ok(value) => value,
        Err(error) => return format!("Error: {}", error),
    };

    match HOT_BANK_SERVICE.change_pin(resolved_uid, current_pin, new_pin, context) {
        Ok(result) => serialize_hot_bank_mutation(result),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn save_hot_bank(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_BANK_SERVICE.get_bank(resolved_uid.clone()) {
        Ok(bank) => {
            enqueue_persistence_task("bank", move || {
                HOT_BANK_SERVICE.save_bank(resolved_uid).map(|_| ())
            });
            serialize_hot_bank(bank)
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn remove_hot_bank(call_context: CallContext, key: String) -> String {
    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => uid,
        None => return format!("Error: Failed to resolve UID for key: {}", key),
    };

    match HOT_BANK_SERVICE.remove_bank(resolved_uid) {
        Ok(_) => "OK".to_string(),
        Err(error) => format!("Error: {}", error),
    }
}

/// Retrieves an bank by key/UID.
///
/// Resolves the key to a Steam UID and returns the bank as JSON.
/// Returns an error message if resolution fails or retrieval fails.
pub fn get_bank(call_context: CallContext, key: String) -> String {
    log("bank", "DEBUG", &format!("Getting bank for key: {}", key));

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("bank", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("bank", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match BANK_SERVICE.get_bank(resolved_uid.clone()) {
        Ok(bank) => {
            log(
                "bank",
                "INFO",
                &format!("Successfully retrieved bank: {}", resolved_uid),
            );
            match serde_json::to_string(&bank) {
                Ok(json) => {
                    log(
                        "bank",
                        "DEBUG",
                        &format!("Serialized bank to JSON: {}", json),
                    );
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize bank: {}", e);
                    log("bank", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "bank",
                "ERROR",
                &format!("Failed to get bank '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Creates a new bank with the provided JSON data.
///
/// Resolves key to UID, validates JSON data, and persists the new bank.
pub fn create_bank(call_context: CallContext, key: String, json_data: String) -> String {
    log(
        "bank",
        "DEBUG",
        &format!("Creating bank for key: {} with data: {}", key, json_data),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log(
                "bank",
                "DEBUG",
                &format!("Resolved UID for creation: {}", uid),
            );
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("bank", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match BANK_SERVICE.create(resolved_uid.clone(), json_data) {
        Ok(bank) => {
            log(
                "bank",
                "INFO",
                &format!("Successfully created bank: {}", resolved_uid),
            );
            match serde_json::to_string(&bank) {
                Ok(json) => {
                    log(
                        "bank",
                        "DEBUG",
                        &format!("Serialized bank to JSON: {}", json),
                    );
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize bank: {}", e);
                    log("bank", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "bank",
                "ERROR",
                &format!("Failed to create bank '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Updates an existing bank with JSON data.
///
/// Resolves key to UID, applies partial updates from JSON, and persists changes.
pub fn update_bank(call_context: CallContext, key: String, json_update: String) -> String {
    log(
        "bank",
        "DEBUG",
        &format!("Updating bank for key: {} with data: {}", key, json_update),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log(
                "bank",
                "DEBUG",
                &format!("Resolved UID for update: {}", uid),
            );
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("bank", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match BANK_SERVICE.update_bank(resolved_uid.clone(), json_update) {
        Ok(bank) => {
            log(
                "bank",
                "INFO",
                &format!("Successfully updated bank: {}", resolved_uid),
            );
            match serde_json::to_string(&bank) {
                Ok(json) => {
                    log(
                        "bank",
                        "DEBUG",
                        &format!("Serialized updated bank to JSON: {}", json),
                    );
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize bank: {}", e);
                    log("bank", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "bank",
                "ERROR",
                &format!("Failed to update bank '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Checks if an bank exists in the database.
///
/// Returns "true" if the bank exists, "false" otherwise.
/// Backend failures are returned as errors so callers do not confuse a failed
/// lookup with a missing account and create duplicate/default records.
pub fn bank_exists(call_context: CallContext, key: String) -> String {
    log(
        "bank",
        "DEBUG",
        &format!("Checking if bank exists for key: {}", key),
    );

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log("bank", "DEBUG", &format!("Resolved UID: {}", uid));
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("bank", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match BANK_SERVICE.bank_exists(resolved_uid.clone()) {
        Ok(exists) => {
            log(
                "bank",
                "DEBUG",
                &format!("Bank '{}' exists: {}", resolved_uid, exists),
            );
            exists.to_string()
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "bank",
                "ERROR",
                &format!("Failed to check if bank '{}' exists: {}", resolved_uid, e),
            );
            error_msg
        }
    }
}

/// Permanently deletes an bank.
///
/// Resolves key to UID and removes the bank and associated data.
pub fn delete_bank(call_context: CallContext, key: String) -> String {
    log("bank", "DEBUG", &format!("Deleting bank for key: {}", key));

    let resolved_uid = match resolve_uid(&key, &call_context) {
        Some(uid) => {
            log(
                "bank",
                "DEBUG",
                &format!("Resolved UID for deletion: {}", uid),
            );
            uid
        }
        None => {
            let error_msg = format!("Error: Failed to resolve UID for key: {}", key);
            log("bank", "ERROR", &error_msg);
            return error_msg;
        }
    };

    match BANK_SERVICE.delete_bank(resolved_uid.clone()) {
        Ok(_) => {
            log(
                "bank",
                "INFO",
                &format!("Successfully deleted bank: {}", resolved_uid),
            );
            "OK".to_string()
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "bank",
                "ERROR",
                &format!("Failed to delete bank '{}': {}", resolved_uid, e),
            );
            error_msg
        }
    }
}
