//! Locker service layer providing business logic for item locker management.
//!
//! Handles validation, storage, and retrieval of player item lockers.

use forge_models::locker::{Item, Locker};
use forge_repositories::{LockerHotRepository, LockerRepository};
use std::collections::HashMap;

/// Service layer implementation for locker business logic and operations.
pub struct LockerService<R: LockerRepository> {
    repository: R,
}

pub struct LockerHotStateService<R: LockerRepository, H: LockerHotRepository> {
    service: LockerService<R>,
    repository: H,
}

impl<R: LockerRepository> LockerService<R> {
    /// Creates a new locker service with the provided repository.
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    /// Creates a new empty locker for a player
    pub fn create_locker(&self, uid: String) -> Result<Locker, String> {
        // Business rule: Check if locker already exists
        if self.repository.exists(&uid)? {
            return Err(format!("Locker for '{}' already exists", uid));
        }

        // Create empty locker (no items)
        let locker = Locker::new().map_err(|e| format!("Validation failed: {}", e))?;
        self.repository.create(&uid, &locker)?;

        Ok(locker)
    }

    /// Replaces the entire locker with new data (Bulk Sync).
    pub fn update_locker(
        &self,
        key: String,
        items: HashMap<String, Item>,
    ) -> Result<Locker, String> {
        let locker = Locker { items };

        // Business rule: Check if locker has reached maximum capacity (25 items)
        if locker.items.len() > 25 {
            return Err("Locker exceeds maximum capacity of 25 items.".to_string());
        }

        self.repository.update(&key, &locker)?;
        Ok(locker)
    }

    /// Adds a new item to a player's locker
    pub fn add_item(&self, uid: String, item: Item) -> Result<Locker, String> {
        // Get existing locker or create new one
        let mut locker = match self.repository.get(&uid)? {
            Some(l) => l,
            None => Locker::new().map_err(|e| format!("Failed to create locker: {}", e))?,
        };

        // Business rule: Check if locker has reached maximum capacity (25 items)
        // Only check if we are adding a NEW item (not updating existing)
        if !locker.items.contains_key(&item.classname) && locker.items.len() >= 25 {
            return Err("Locker is full. Maximum of 25 items allowed.".to_string());
        }

        // Add new item to locker (or overwrite existing)
        locker
            .add_item(item)
            .map_err(|e| format!("Failed to add item: {}", e))?;

        // Update locker with new item
        self.repository.update(&uid, &locker)?;

        Ok(locker)
    }

    /// Retrieves a player's locker
    pub fn get_locker(&self, uid: String) -> Result<Locker, String> {
        match self.repository.get(&uid)? {
            Some(locker) => Ok(locker),
            None => Err(format!("No locker found for player '{}'", uid)),
        }
    }

    /// Patches an existing item in the locker
    pub fn patch_item(
        &self,
        uid: String,
        classname: String,
        amount: Option<u32>,
    ) -> Result<Locker, String> {
        // Get existing locker
        let mut locker = match self.repository.get(&uid)? {
            Some(l) => l,
            None => return Err(format!("No locker found for player '{}'", uid)),
        };

        // Find the item to update by classname
        let existing_item = locker
            .get_item_mut(&classname)
            .ok_or_else(|| format!("Item with classname '{}' not found in locker", classname))?;

        if let Some(a) = amount {
            if a == 0 {
                return Err("Amount cannot be zero".to_string());
            }
            existing_item.amount = a;
        }

        // Update locker with modified item
        self.repository.update(&uid, &locker)?;

        Ok(locker)
    }

    /// Removes an item from the locker
    pub fn remove_item(&self, uid: String, classname: String) -> Result<Locker, String> {
        // Get existing locker
        let mut locker = match self.repository.get(&uid)? {
            Some(l) => l,
            None => return Err(format!("No locker found for player '{}'", uid)),
        };

        // Remove the item by classname
        locker
            .remove_item(&classname)
            .ok_or_else(|| format!("Item with classname '{}' not found in locker", classname))?;

        // Update locker after removing item
        self.repository.update(&uid, &locker)?;

        Ok(locker)
    }

    /// Deletes a player's locker (all items)
    pub fn delete_locker(&self, uid: String) -> Result<(), String> {
        self.repository.delete(&uid)
    }

    /// Checks if a player has a locker (even if empty)
    pub fn locker_exists(&self, uid: String) -> Result<bool, String> {
        self.repository.exists(&uid)
    }
}

impl<R: LockerRepository, H: LockerHotRepository> LockerHotStateService<R, H> {
    pub fn new(repository: R, hot_repository: H) -> Self {
        Self {
            service: LockerService::new(repository),
            repository: hot_repository,
        }
    }

    pub fn init_locker(&self, uid: String) -> Result<Locker, String> {
        if let Some(locker) = self.repository.get(&uid)? {
            return Ok(locker);
        }

        let locker = match self.service.get_locker(uid.clone()) {
            Ok(locker) => locker,
            Err(_) => self.service.create_locker(uid.clone())?,
        };
        self.repository.save(&locker, &uid)?;
        Ok(locker)
    }

    pub fn get_locker(&self, uid: String) -> Result<Locker, String> {
        self.init_locker(uid)
    }

    pub fn override_locker(
        &self,
        uid: String,
        items: HashMap<String, Item>,
    ) -> Result<Locker, String> {
        let locker = Locker { items };
        if locker.items.len() > 25 {
            return Err("Locker exceeds maximum capacity of 25 items.".to_string());
        }

        self.repository.save(&locker, &uid)?;
        Ok(locker)
    }

    pub fn save_locker(&self, uid: String) -> Result<Locker, String> {
        let locker = self
            .repository
            .get(&uid)?
            .ok_or_else(|| format!("No locker found for player '{}'", uid))?;
        let saved = self
            .service
            .update_locker(uid.clone(), locker.items.clone())?;
        self.repository.save(&saved, &uid)?;
        Ok(saved)
    }

    pub fn remove_locker(&self, uid: String) -> Result<(), String> {
        self.repository.delete(&uid)
    }
}
