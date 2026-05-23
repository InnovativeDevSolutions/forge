//! Locker repository implementation for item data persistence operations.
//!
//! This module provides the data access layer for locker management.
//! Each player's locker is stored as a single JSON string containing all their items.

use forge_models::Locker;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

/// Repository trait defining the contract for locker data operations.
pub trait LockerRepository: Send + Sync {
    /// Creates a new locker for a player
    fn create(&self, uid: &str, locker: &Locker) -> Result<(), String>;

    /// Updates an existing locker with new item data
    fn update(&self, uid: &str, locker: &Locker) -> Result<(), String>;

    /// Retrieves a player's locker
    fn get(&self, uid: &str) -> Result<Option<Locker>, String>;

    /// Deletes a player's locker (all items)
    fn delete(&self, uid: &str) -> Result<(), String>;

    /// Checks if a player has a locker
    fn exists(&self, uid: &str) -> Result<bool, String>;
}

pub trait LockerHotRepository: Send + Sync {
    fn get(&self, uid: &str) -> Result<Option<Locker>, String>;
    fn save(&self, locker: &Locker, uid: &str) -> Result<(), String>;
    fn delete(&self, uid: &str) -> Result<(), String>;
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryLockerHotRepository {
    state: Arc<RwLock<HashMap<String, Locker>>>,
}

impl InMemoryLockerHotRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

impl LockerHotRepository for InMemoryLockerHotRepository {
    fn get(&self, uid: &str) -> Result<Option<Locker>, String> {
        self.state
            .read()
            .map(|state| state.get(uid).cloned())
            .map_err(|_| "Locker hot state lock poisoned.".to_string())
    }

    fn save(&self, locker: &Locker, uid: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Locker hot state lock poisoned.".to_string())?
            .insert(uid.to_string(), locker.clone());
        Ok(())
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Locker hot state lock poisoned.".to_string())?
            .remove(uid);
        Ok(())
    }
}
