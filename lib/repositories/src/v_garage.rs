//! Virtual garage repository implementation for item data persistence operations.
//!
//! This module provides the data access layer for virtual garage management.
//! Each player's virtual garage is represented by six category fields:
//! - cars: JSON array of car classnames
//! - armor: JSON array of armor classnames
//! - helis: JSON array of helis classnames
//! - planes: JSON array of plane classnames
//! - naval: JSON array of naval classnames
//! - other: JSON array of other classnames

use forge_models::VGarage;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

/// Repository trait defining the contract for virtual garage data operations.
pub trait VGarageRepository: Send + Sync {
    /// Creates a new virtual garage for a player
    fn create(&self, uid: &str, garage: &VGarage) -> Result<(), String>;

    /// Updates an existing virtual garage with new item data
    fn update(&self, uid: &str, garage: &VGarage) -> Result<(), String>;

    /// Retrieves a player's virtual garage
    fn fetch(&self, uid: &str) -> Result<Option<VGarage>, String>;

    /// Retrieves a specific field from a player's virtual garage
    /// Fields: "cars", "armor", "helis", "planes", "naval", "other"
    fn get(&self, uid: &str, field: &str) -> Result<Vec<String>, String>;

    /// Deletes a player's virtual garage (all items)
    fn delete(&self, uid: &str) -> Result<(), String>;

    /// Checks if a player has a virtual garage
    fn exists(&self, uid: &str) -> Result<bool, String>;
}

pub trait VGarageHotRepository: Send + Sync {
    fn get(&self, uid: &str) -> Result<Option<VGarage>, String>;
    fn save(&self, garage: &VGarage, uid: &str) -> Result<(), String>;
    fn delete(&self, uid: &str) -> Result<(), String>;
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryVGarageHotRepository {
    state: Arc<RwLock<HashMap<String, VGarage>>>,
}

impl InMemoryVGarageHotRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

impl VGarageHotRepository for InMemoryVGarageHotRepository {
    fn get(&self, uid: &str) -> Result<Option<VGarage>, String> {
        self.state
            .read()
            .map(|state| state.get(uid).cloned())
            .map_err(|_| "Virtual garage hot state lock poisoned.".to_string())
    }

    fn save(&self, garage: &VGarage, uid: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Virtual garage hot state lock poisoned.".to_string())?
            .insert(uid.to_string(), garage.clone());
        Ok(())
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Virtual garage hot state lock poisoned.".to_string())?
            .remove(uid);
        Ok(())
    }
}
