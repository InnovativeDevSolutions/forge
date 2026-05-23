//! Virtual locker service layer providing business logic for locker management operations.
//!
//! Implements the service layer of the virtual locker system, handling business logic,
//! validation, and orchestration.

use forge_models::{EquipmentCategory, VLocker};
use forge_repositories::{VLockerHotRepository, VLockerRepository};

/// Service layer implementation for virtual locker business logic and operations.
///
/// Orchestrates virtual locker management operations, handling business logic, validation,
/// and data transformation. Manages equipment storage across four categories: items,
/// weapons, magazines, and backpacks.
///
/// # Thread Safety
/// Thread-safe when used with a thread-safe repository.
pub struct VLockerService<R: VLockerRepository> {
    /// The repository instance used for all data persistence operations.
    ///
    /// This repository handles the actual storage and retrieval of locker data,
    /// abstracting away the specific database implementation details.
    repository: R,
}

pub struct VLockerHotStateService<R: VLockerRepository, H: VLockerHotRepository> {
    service: VLockerService<R>,
    repository: H,
}

impl<R: VLockerRepository> VLockerService<R> {
    /// Creates a new locker service with the provided repository.
    ///
    /// The repository must be initialized and ready for use.
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    /// Creates a new empty locker for a player.
    ///
    /// Handles duplicate checking and persistence.
    pub fn create_locker(&self, uid: &str) -> Result<VLocker, String> {
        // Business rule: Check if locker already exists
        if self.repository.exists(uid)? {
            return Err(format!("Locker for '{}' already exists", uid));
        }

        // Create empty locker (no items)
        let locker = VLocker::new();
        self.repository.create(uid, &locker)?;

        Ok(locker)
    }

    /// Retrieves a player's virtual locker.
    pub fn fetch_locker(&self, uid: &str) -> Result<VLocker, String> {
        match self.repository.fetch(uid)? {
            Some(locker) => Ok(locker),
            None => Err(format!("No locker found for player '{}'", uid)),
        }
    }

    pub fn update_locker(&self, uid: &str, locker: &VLocker) -> Result<VLocker, String> {
        self.repository.update(uid, locker)?;
        Ok(locker.clone())
    }

    /// Retrieves a specific field from a player's virtual locker.
    ///
    /// Fields: "items", "weapons", "magazines", "backpacks"
    pub fn get_locker(&self, uid: &str, field: &str) -> Result<Vec<String>, String> {
        self.repository.get(uid, field)
    }

    /// Generic method to add items to any category.
    pub fn add_locker(
        &self,
        uid: &str,
        category: EquipmentCategory,
        classnames: Vec<String>,
    ) -> Result<VLocker, String> {
        let mut locker = match self.repository.fetch(uid)? {
            Some(l) => l,
            None => VLocker::new(),
        };

        locker.add(category, classnames);
        self.repository.update(uid, &locker)?;

        Ok(locker)
    }

    /// Generic method to remove an item from any category.
    pub fn remove_locker(
        &self,
        uid: &str,
        category: EquipmentCategory,
        classname: &str,
    ) -> Result<VLocker, String> {
        let mut locker = match self.repository.fetch(uid)? {
            Some(l) => l,
            None => return Err(format!("No locker found for player '{}'", uid)),
        };

        if locker.remove(category, classname).is_none() {
            return Err(format!("Item '{}' not found in locker", classname));
        }

        self.repository.update(uid, &locker)?;

        Ok(locker)
    }

    /// Permanently deletes a player's virtual locker.
    ///
    /// Irreversible operation. Delegates to repository.
    pub fn delete_locker(&self, uid: &str) -> Result<(), String> {
        // Business rule: Check if locker exists
        if !self.repository.exists(uid)? {
            return Err(format!("No locker found for player '{}'", uid));
        }

        // Delete locker
        self.repository.delete(uid)?;

        Ok(())
    }

    /// Checks if a player has a virtual locker.
    ///
    /// Lightweight check without data retrieval.
    pub fn locker_exists(&self, uid: &str) -> Result<bool, String> {
        self.repository.exists(uid)
    }
}

impl<R: VLockerRepository, H: VLockerHotRepository> VLockerHotStateService<R, H> {
    pub fn new(repository: R, hot_repository: H) -> Self {
        Self {
            service: VLockerService::new(repository),
            repository: hot_repository,
        }
    }

    pub fn init_locker(&self, uid: &str) -> Result<VLocker, String> {
        if let Some(locker) = self.repository.get(uid)? {
            return Ok(locker);
        }

        let locker = match self.service.fetch_locker(uid) {
            Ok(locker) => locker,
            Err(_) => self.service.create_locker(uid)?,
        };
        self.repository.save(&locker, uid)?;
        Ok(locker)
    }

    pub fn fetch_locker(&self, uid: &str) -> Result<VLocker, String> {
        self.init_locker(uid)
    }

    pub fn get_locker(&self, uid: &str, field: &str) -> Result<Vec<String>, String> {
        let locker = self.init_locker(uid)?;
        Ok(match field.to_lowercase().as_str() {
            "items" => locker.items,
            "weapons" => locker.weapons,
            "magazines" => locker.magazines,
            "backpacks" => locker.backpacks,
            _ => Vec::new(),
        })
    }

    pub fn override_locker(&self, uid: &str, locker: VLocker) -> Result<VLocker, String> {
        self.repository.save(&locker, uid)?;
        Ok(locker)
    }

    pub fn save_locker(&self, uid: &str) -> Result<VLocker, String> {
        let locker = self
            .repository
            .get(uid)?
            .ok_or_else(|| format!("No locker found for player '{}'", uid))?;
        let saved = if self.service.locker_exists(uid)? {
            self.service.update_locker(uid, &locker)?
        } else {
            self.service.create_locker(uid)?
        };
        self.repository.save(&saved, uid)?;
        Ok(saved)
    }

    pub fn remove_locker(&self, uid: &str) -> Result<(), String> {
        self.repository.delete(uid)
    }
}
