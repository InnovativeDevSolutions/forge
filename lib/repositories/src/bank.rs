//! Bank repository implementation for data persistence operations.
//!
//! This module provides the data access layer for bank account management,
//! implementing the repository pattern to abstract database operations.
//!
//! For full documentation and examples, see the [crate README](../README.md).

use forge_models::Bank;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

/// Repository trait defining the contract for bank data operations.
///
/// This trait abstracts the data persistence layer, allowing different
/// implementations while maintaining a consistent
/// interface for the service layer. All implementations must be thread-safe.
pub trait BankRepository: Send + Sync {
    /// Creates a new bank in the repository.
    fn create(&self, bank: &Bank) -> Result<(), String>;

    /// Retrieves an bank by their unique identifier.
    fn get_by_id(&self, id: &str) -> Result<Option<Bank>, String>;

    /// Updates an existing bank with new data.
    fn update(&self, bank: &Bank) -> Result<(), String>;

    /// Permanently removes an bank from the repository.
    fn delete(&self, id: &str) -> Result<(), String>;

    /// Checks if an bank exists in the repository.
    fn exists(&self, id: &str) -> Result<bool, String>;
}

pub trait BankHotRepository: Send + Sync {
    fn get(&self, id: &str) -> Result<Option<Bank>, String>;
    fn save(&self, bank: &Bank) -> Result<(), String>;
    fn delete(&self, id: &str) -> Result<(), String>;
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryBankHotRepository {
    state: Arc<RwLock<HashMap<String, Bank>>>,
}

impl InMemoryBankHotRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

impl BankHotRepository for InMemoryBankHotRepository {
    fn get(&self, id: &str) -> Result<Option<Bank>, String> {
        self.state
            .read()
            .map(|state| state.get(id).cloned())
            .map_err(|_| "Bank hot state lock poisoned.".to_string())
    }

    fn save(&self, bank: &Bank) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Bank hot state lock poisoned.".to_string())?
            .insert(bank.uid.clone(), bank.clone());
        Ok(())
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Bank hot state lock poisoned.".to_string())?
            .remove(id);
        Ok(())
    }
}
