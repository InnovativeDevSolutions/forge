//! Virtual locker repository implementation for item data persistence operations.
//!
//! This module provides the data access layer for virtual locker management.
//! Each player's virtual locker is represented by four category fields:
//! - items: JSON array of item classnames
//! - weapons: JSON array of weapon classnames
//! - magazines: JSON array of magazine classnames
//! - backpacks: JSON array of backpack classnames

use forge_models::VLocker;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

/// Repository trait defining the contract for virtual locker data operations.
pub trait VLockerRepository: Send + Sync {
    /// Creates a new virtual locker for a player
    fn create(&self, uid: &str, locker: &VLocker) -> Result<(), String>;

    /// Updates an existing virtual locker with new item data
    fn update(&self, uid: &str, locker: &VLocker) -> Result<(), String>;

    /// Retrieves a player's virtual locker
    fn fetch(&self, uid: &str) -> Result<Option<VLocker>, String>;

    /// Retrieves a specific field from a player's virtual locker
    /// Fields: "items", "weapons", "magazines", "backpacks"
    fn get(&self, uid: &str, field: &str) -> Result<Vec<String>, String>;

    /// Deletes a player's virtual locker (all items)
    fn delete(&self, uid: &str) -> Result<(), String>;

    /// Checks if a player has a virtual locker
    fn exists(&self, uid: &str) -> Result<bool, String>;
}

pub trait VLockerHotRepository: Send + Sync {
    fn get(&self, uid: &str) -> Result<Option<VLocker>, String>;
    fn save(&self, locker: &VLocker, uid: &str) -> Result<(), String>;
    fn delete(&self, uid: &str) -> Result<(), String>;
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryVLockerHotRepository {
    state: Arc<RwLock<HashMap<String, VLocker>>>,
}

impl InMemoryVLockerHotRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

impl VLockerHotRepository for InMemoryVLockerHotRepository {
    fn get(&self, uid: &str) -> Result<Option<VLocker>, String> {
        self.state
            .read()
            .map(|state| state.get(uid).cloned())
            .map_err(|_| "Virtual locker hot state lock poisoned.".to_string())
    }

    fn save(&self, locker: &VLocker, uid: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Virtual locker hot state lock poisoned.".to_string())?
            .insert(uid.to_string(), locker.clone());
        Ok(())
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Virtual locker hot state lock poisoned.".to_string())?
            .remove(uid);
        Ok(())
    }
}
