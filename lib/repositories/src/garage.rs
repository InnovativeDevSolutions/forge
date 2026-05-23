//! Garage repository implementation for vehicle data persistence operations.
//!
//! This module provides the data access layer for vehicle garage management.
//! Each player's garage is stored as a single JSON string containing all their vehicles.

use forge_models::Garage;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

/// Repository trait defining the contract for garage data operations.
pub trait GarageRepository: Send + Sync {
    /// Creates a new garage for a player
    fn create(&self, uid: &str, garage: &Garage) -> Result<(), String>;

    /// Updates an existing garage with new vehicle data
    fn update(&self, uid: &str, garage: &Garage) -> Result<(), String>;

    /// Retrieves a player's garage
    fn get(&self, uid: &str) -> Result<Option<Garage>, String>;

    /// Deletes a player's garage (all vehicles)
    fn delete(&self, uid: &str) -> Result<(), String>;

    /// Checks if a player has a garage
    fn exists(&self, uid: &str) -> Result<bool, String>;
}

pub trait GarageHotRepository: Send + Sync {
    fn get(&self, uid: &str) -> Result<Option<Garage>, String>;
    fn save(&self, garage: &Garage, uid: &str) -> Result<(), String>;
    fn delete(&self, uid: &str) -> Result<(), String>;
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryGarageHotRepository {
    state: Arc<RwLock<HashMap<String, Garage>>>,
}

impl InMemoryGarageHotRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

impl GarageHotRepository for InMemoryGarageHotRepository {
    fn get(&self, uid: &str) -> Result<Option<Garage>, String> {
        self.state
            .read()
            .map(|state| state.get(uid).cloned())
            .map_err(|_| "Garage hot state lock poisoned.".to_string())
    }

    fn save(&self, garage: &Garage, uid: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Garage hot state lock poisoned.".to_string())?
            .insert(uid.to_string(), garage.clone());
        Ok(())
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Garage hot state lock poisoned.".to_string())?
            .remove(uid);
        Ok(())
    }
}
