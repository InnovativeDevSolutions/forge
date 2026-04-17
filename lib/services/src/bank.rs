//! Bank service layer providing business logic for bank management operations.
//!
//! Implements the service layer of the bank management system, handling business logic,
//! validation, and orchestration.
//!
//! For full documentation, architecture, and examples, see the [crate README](../README.md).

use forge_models::{
    Bank, BankCheckoutContext, BankMutationResult, BankOperationContext, BankPinContext,
    BankTransferContext, BankTransferResult,
};
use forge_repositories::{BankHotRepository, BankRepository};
use serde_json::{Value, json};
use std::collections::HashMap;

/// Service layer implementation for bank business logic and operations.
///
/// Orchestrates bank management operations, handling business logic, validation,
/// and data transformation. See [crate README](../README.md) for details.
///
/// # Thread Safety
/// Thread-safe when used with a thread-safe repository.
pub struct BankService<R: BankRepository> {
    /// The repository instance used for all data persistence operations.
    ///
    /// This repository handles the actual storage and retrieval of bank data,
    /// abstracting away the specific database implementation details.
    repository: R,
}

pub struct BankHotStateService<R: BankRepository, H: BankHotRepository> {
    service: BankService<R>,
    repository: H,
}

impl<R: BankRepository, H: BankHotRepository> BankHotStateService<R, H> {
    pub fn new(repository: R, hot_repository: H) -> Self {
        Self {
            service: BankService::new(repository),
            repository: hot_repository,
        }
    }

    pub fn init_bank(&self, key: String) -> Result<Bank, String> {
        if let Some(bank) = self.repository.get(&key)? {
            return Ok(bank);
        }

        let bank = self.service.get_bank(key)?;
        self.repository.save(&bank)?;
        Ok(bank)
    }

    pub fn get_bank(&self, key: String) -> Result<Bank, String> {
        self.init_bank(key)
    }

    pub fn override_bank(&self, key: String, json_data: String) -> Result<Bank, String> {
        let mut bank: Bank =
            serde_json::from_str(&json_data).map_err(|e| format!("Invalid Bank JSON: {}", e))?;

        bank.uid = key;
        bank.validate()
            .map_err(|e| format!("Validation failed: {}", e))?;

        self.repository.save(&bank)?;
        Ok(bank)
    }

    pub fn patch_bank(
        &self,
        key: String,
        json_patch: String,
    ) -> Result<BankMutationResult, String> {
        let patch_value: Value =
            serde_json::from_str(&json_patch).map_err(|e| format!("Invalid patch JSON: {}", e))?;
        let patch_object = patch_value
            .as_object()
            .ok_or_else(|| "Patch data must be a JSON object".to_string())?;

        let mut bank = self.get_bank(key.clone())?;
        let mut patch = HashMap::new();

        for (field, value) in patch_object {
            apply_bank_field(&mut bank, field, value)?;
            patch.insert(field.clone(), current_bank_field_value(&bank, field)?);
        }

        bank.validate()
            .map_err(|e| format!("Validation failed: {}", e))?;
        self.repository.save(&bank)?;

        Ok(BankMutationResult {
            account: bank,
            patch,
        })
    }

    pub fn charge_checkout(
        &self,
        key: String,
        amount: f64,
        context: BankCheckoutContext,
    ) -> Result<BankMutationResult, String> {
        if amount <= 0.0 {
            return Err("Checkout amount must be greater than zero".to_string());
        }

        let mut bank = self.get_bank(key)?;
        let source_field = match context.source_field.trim().to_ascii_lowercase().as_str() {
            "cash" => "cash",
            "bank" => "bank",
            _ => return Err("Selected bank payment source is unsupported.".to_string()),
        };

        let source_balance = match source_field {
            "cash" => bank.cash,
            _ => bank.bank,
        };
        if source_balance < amount {
            return Err(match source_field {
                "cash" => "Cash on hand cannot cover this checkout.".to_string(),
                _ => "Bank balance cannot cover this checkout.".to_string(),
            });
        }

        match source_field {
            "cash" => bank.cash -= amount,
            _ => bank.bank -= amount,
        }

        bank.validate()
            .map_err(|e| format!("Validation failed: {}", e))?;
        if context.commit {
            self.repository.save(&bank)?;
        }

        Ok(BankMutationResult {
            account: bank.clone(),
            patch: build_patch(&bank, &[source_field])?,
        })
    }

    pub fn deposit(
        &self,
        key: String,
        amount: f64,
        context: BankOperationContext,
    ) -> Result<BankMutationResult, String> {
        if amount <= 0.0 {
            return Err("Deposit amount must be greater than zero".to_string());
        }
        validate_atm_access(&context, "deposit")?;

        let mut bank = self.get_bank(key)?;
        if bank.cash < amount {
            return Err("Cash on hand cannot cover that deposit.".to_string());
        }

        bank.cash -= amount;
        bank.bank += amount;
        bank.validate()
            .map_err(|e| format!("Validation failed: {}", e))?;
        self.repository.save(&bank)?;

        Ok(BankMutationResult {
            account: bank.clone(),
            patch: build_patch(&bank, &["bank", "cash"])?,
        })
    }

    pub fn withdraw(
        &self,
        key: String,
        amount: f64,
        context: BankOperationContext,
    ) -> Result<BankMutationResult, String> {
        if amount <= 0.0 {
            return Err("Withdrawal amount must be greater than zero".to_string());
        }
        validate_atm_access(&context, "withdrawal")?;

        let mut bank = self.get_bank(key)?;
        if bank.bank < amount {
            return Err("Bank balance cannot cover that withdrawal.".to_string());
        }

        bank.bank -= amount;
        bank.cash += amount;
        bank.validate()
            .map_err(|e| format!("Validation failed: {}", e))?;
        self.repository.save(&bank)?;

        Ok(BankMutationResult {
            account: bank.clone(),
            patch: build_patch(&bank, &["bank", "cash"])?,
        })
    }

    pub fn deposit_earnings(
        &self,
        key: String,
        amount: f64,
        context: BankOperationContext,
    ) -> Result<BankMutationResult, String> {
        if amount <= 0.0 {
            return Err("Deposit earnings amount must be greater than zero".to_string());
        }
        validate_bank_mode(&context, "Earnings deposits")?;

        let mut bank = self.get_bank(key)?;
        if bank.earnings < amount {
            return Err("Pending earnings cannot cover that deposit request.".to_string());
        }

        bank.bank += amount;
        bank.earnings -= amount;
        bank.validate()
            .map_err(|e| format!("Validation failed: {}", e))?;
        self.repository.save(&bank)?;

        Ok(BankMutationResult {
            account: bank.clone(),
            patch: build_patch(&bank, &["bank", "earnings"])?,
        })
    }

    pub fn transfer(
        &self,
        source_key: String,
        target_key: String,
        context: BankTransferContext,
        amount: f64,
    ) -> Result<BankTransferResult, String> {
        if amount <= 0.0 {
            return Err("Transfer amount must be greater than zero".to_string());
        }
        validate_bank_mode(
            &BankOperationContext {
                mode: context.mode.clone(),
                atm_authorized: context.atm_authorized,
            },
            "Transfers",
        )?;
        if source_key == target_key {
            return Err("You cannot transfer funds to yourself.".to_string());
        }

        let mut source_account = self.get_bank(source_key)?;
        let mut target_account = self.get_bank(target_key)?;
        let source_field = match context.from_field.trim().to_ascii_lowercase().as_str() {
            "cash" => "cash",
            _ => "bank",
        };

        let source_balance = match source_field {
            "cash" => source_account.cash,
            _ => source_account.bank,
        };
        if source_balance < amount {
            return Err(match source_field {
                "cash" => "Cash on hand cannot cover that transfer.".to_string(),
                _ => "Bank balance cannot cover that transfer.".to_string(),
            });
        }

        match source_field {
            "cash" => source_account.cash -= amount,
            _ => source_account.bank -= amount,
        }
        target_account.bank += amount;

        source_account
            .validate()
            .map_err(|e| format!("Validation failed: {}", e))?;
        target_account
            .validate()
            .map_err(|e| format!("Validation failed: {}", e))?;

        self.repository.save(&source_account)?;
        self.repository.save(&target_account)?;

        Ok(BankTransferResult {
            source_patch: build_patch(&source_account, &[source_field])?,
            source_account,
            target_patch: build_patch(&target_account, &["bank"])?,
            target_account,
        })
    }

    pub fn validate_pin(
        &self,
        key: String,
        pin: String,
        context: BankPinContext,
    ) -> Result<(), String> {
        if !context.mode.eq_ignore_ascii_case("atm") {
            return Err("PIN entry is only available from an ATM session.".to_string());
        }

        if pin.len() != 4 || !pin.chars().all(|character| character.is_ascii_digit()) {
            return Err("Enter your four-digit access PIN.".to_string());
        }

        let bank = self.get_bank(key)?;
        if pin != bank.pin.to_string() {
            return Err("Incorrect PIN.".to_string());
        }

        Ok(())
    }

    pub fn save_bank(&self, key: String) -> Result<Bank, String> {
        let bank = self
            .repository
            .get(&key)?
            .ok_or_else(|| format!("Bank with UID '{}' not found in hot state", key))?;
        let bank_json =
            serde_json::to_string(&bank).map_err(|e| format!("Failed to serialize bank: {}", e))?;

        let saved_bank = self.service.update_bank(key, bank_json)?;
        self.repository.save(&saved_bank)?;
        Ok(saved_bank)
    }

    pub fn remove_bank(&self, key: String) -> Result<(), String> {
        self.repository.delete(&key)
    }
}

fn apply_bank_field(bank: &mut Bank, field: &str, value: &Value) -> Result<(), String> {
    match field {
        "uid" => Ok(()),
        "name" => {
            bank.name = value
                .as_str()
                .ok_or_else(|| "Name must be a string".to_string())?
                .to_string();
            Ok(())
        }
        "bank" => {
            bank.bank = value
                .as_f64()
                .ok_or_else(|| "Bank balance must be a number".to_string())?;
            Ok(())
        }
        "cash" => {
            bank.cash = value
                .as_f64()
                .ok_or_else(|| "Cash must be a number".to_string())?;
            Ok(())
        }
        "earnings" => {
            bank.earnings = value
                .as_f64()
                .ok_or_else(|| "Earnings must be a number".to_string())?;
            Ok(())
        }
        "pin" => {
            bank.pin = value
                .as_u64()
                .ok_or_else(|| "PIN must be a number".to_string())?;
            Ok(())
        }
        "transactions" => {
            let values = value
                .as_array()
                .ok_or_else(|| "Transactions must be an array".to_string())?;
            bank.transactions = values
                .iter()
                .map(|entry| {
                    entry
                        .as_str()
                        .map(|item| item.to_string())
                        .ok_or_else(|| "Transactions must contain strings".to_string())
                })
                .collect::<Result<Vec<_>, _>>()?;
            Ok(())
        }
        _ => Err(format!("Unknown field: {}", field)),
    }
}

fn current_bank_field_value(bank: &Bank, field: &str) -> Result<Value, String> {
    match field {
        "uid" => Ok(json!(bank.uid)),
        "name" => Ok(json!(bank.name)),
        "bank" => Ok(json!(bank.bank)),
        "cash" => Ok(json!(bank.cash)),
        "earnings" => Ok(json!(bank.earnings)),
        "pin" => Ok(json!(bank.pin)),
        "transactions" => Ok(json!(bank.transactions)),
        _ => Err(format!("Unknown field: {}", field)),
    }
}

fn build_patch(bank: &Bank, fields: &[&str]) -> Result<HashMap<String, Value>, String> {
    let mut patch = HashMap::new();
    for field in fields {
        patch.insert((*field).to_string(), current_bank_field_value(bank, field)?);
    }
    Ok(patch)
}

fn validate_atm_access(context: &BankOperationContext, action: &str) -> Result<(), String> {
    if context.mode.eq_ignore_ascii_case("atm") && !context.atm_authorized {
        return Err(format!("ATM authorization is required before {}.", action));
    }

    Ok(())
}

fn validate_bank_mode(context: &BankOperationContext, action: &str) -> Result<(), String> {
    if !context.mode.eq_ignore_ascii_case("bank") {
        return Err(format!(
            "{} are only available from the full bank interface.",
            action
        ));
    }

    Ok(())
}

impl<R: BankRepository> BankService<R> {
    /// Creates a new bank service with the provided repository.
    ///
    /// The repository must be initialized and ready for use.
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    /// Creates a new bank with the provided ID and JSON data.
    ///
    /// Handles validation, duplicate checking, and persistence.
    /// See [crate README](../README.md) for JSON format and business rules.
    pub fn create(&self, key: String, json_data: String) -> Result<Bank, String> {
        // Parse JSON data to Bank struct
        let mut bank: Bank =
            serde_json::from_str(&json_data).map_err(|e| format!("Invalid Bank JSON: {}", e))?;

        // Set UID from parameter (authoritative source)
        bank.uid = key;

        // Check if bank already exists to prevent duplicates
        if self.repository.exists(&bank.uid)? {
            return Err(format!("Bank with uid '{}' already exists", bank.uid));
        }

        if let Err(e) = bank.validate() {
            return Err(format!("Invalid Bank JSON: {}", e));
        }

        self.repository.create(&bank)?;

        Ok(bank)
    }

    /// Retrieves an bank by their unique identifier with automatic fallback creation.
    ///
    /// Implements a "get-or-create" pattern: if the bank doesn't exist, a new one
    /// with default values is returned (but not persisted).
    pub fn get_bank(&self, key: String) -> Result<Bank, String> {
        // Attempt to retrieve bank from repository
        match self.repository.get_by_id(&key)? {
            // Bank found - return it
            Some(bank) => Ok(bank),
            // Bank not found - create fallback bank with default values
            None => Err(format!("Bank with UID '{}' not found", key)),
        }
    }

    /// Updates an existing bank with new data from JSON.
    ///
    /// Handles partial updates, validation, and persistence.
    /// See [crate README](../README.md) for JSON format and concurrency details.
    pub fn update_bank(&self, key: String, json_update: String) -> Result<Bank, String> {
        // Retrieve existing bank from repository
        let mut bank = match self.repository.get_by_id(&key)? {
            Some(bank) => bank,
            None => return Err(format!("Bank with UID '{}' not found", key)),
        };

        // Parse and validate JSON update data
        let update_data: serde_json::Value =
            serde_json::from_str(&json_update).map_err(|e| format!("Invalid JSON: {}", e))?;

        // Ensure update data is a JSON object
        if !update_data.is_object() {
            return Err("Update data must be a JSON object".to_string());
        }

        // Create a temporary copy to safely apply updates with validation
        let mut updated_bank = bank.clone();

        // Apply updates field by field
        if let Some(obj) = update_data.as_object() {
            for (field, value) in obj {
                match field.as_str() {
                    "uid" => {
                        // Skip UID - it's immutable and set by the system
                        continue;
                    }
                    "name" => {
                        if let Some(name) = value.as_str() {
                            updated_bank.name = name.to_string();
                        } else {
                            return Err("Name must be a string".to_string());
                        }
                    }
                    "bank" => {
                        if let Some(bank_val) = value.as_f64() {
                            updated_bank.bank = bank_val;
                        } else {
                            return Err("Bank balance must be a number".to_string());
                        }
                    }
                    "cash" => {
                        if let Some(cash_val) = value.as_f64() {
                            updated_bank.cash = cash_val;
                        } else {
                            return Err("Cash must be a number".to_string());
                        }
                    }
                    "earnings" => {
                        if let Some(earnings_val) = value.as_f64() {
                            updated_bank.earnings = earnings_val;
                        } else {
                            return Err("Earnings must be a number".to_string());
                        }
                    }
                    "pin" => {
                        if let Some(pin_val) = value.as_u64() {
                            updated_bank.pin = pin_val;
                        } else {
                            return Err("PIN must be a number".to_string());
                        }
                    }
                    "transactions" => {
                        if let Some(arr) = value.as_array() {
                            updated_bank.transactions = arr
                                .iter()
                                .filter_map(|v| v.as_str().map(|s| s.to_string()))
                                .collect();
                        } else {
                            return Err("Transactions must be an array".to_string());
                        }
                    }
                    _ => {
                        return Err(format!("Unknown field: {}", field));
                    }
                }
            }
        }

        // Validate the updated bank before committing changes
        updated_bank
            .validate()
            .map_err(|e| format!("Validation failed: {}", e))?;

        // Only commit changes after validation passes
        bank = updated_bank;

        // Persist the updated bank to repository
        self.repository.update(&bank)?;

        Ok(bank)
    }

    /// Permanently deletes an bank from the system.
    ///
    /// Irreversible operation. Delegates to repository.
    pub fn delete_bank(&self, key: String) -> Result<(), String> {
        // Delegate deletion to repository layer
        // Future enhancements could add business logic here:
        // - Authorization checks
        // - Audit logging
        // - Cascade deletion
        // - Soft deletion
        self.repository.delete(&key)
    }

    /// Checks if an bank exists in the system.
    ///
    /// Lightweight check without data retrieval.
    pub fn bank_exists(&self, key: String) -> Result<bool, String> {
        // Delegate existence check to repository layer
        // This is a lightweight operation that doesn't retrieve data
        self.repository.exists(&key)
    }
}
