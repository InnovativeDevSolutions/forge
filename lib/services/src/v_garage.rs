//! Virtual garage service layer providing business logic for garage management operations.
//!
//! Implements the service layer of the virtual garage system, handling business logic,
//! validation, and orchestration.

use forge_models::{VGarage, VehicleCategory};
use forge_repositories::{VGarageHotRepository, VGarageRepository};

/// Service layer implementation for virtual garage business logic and operations.
///
/// Orchestrates virtual garage management operations, handling business logic, validation,
/// and data transformation. Manages equipment storage across four categories: items,
/// weapons, magazines, and backpacks.
///
/// # Thread Safety
/// Thread-safe when used with a thread-safe repository.
pub struct VGarageService<R: VGarageRepository> {
    /// The repository instance used for all data persistence operations.
    ///
    /// This repository handles the actual storage and retrieval of garage data,
    /// abstracting away the specific database implementation details.
    repository: R,
}

pub struct VGarageHotStateService<R: VGarageRepository, H: VGarageHotRepository> {
    service: VGarageService<R>,
    repository: H,
}

impl<R: VGarageRepository> VGarageService<R> {
    /// Creates a new garage service with the provided repository.
    ///
    /// The repository must be initialized and ready for use.
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    /// Creates a new empty virtual garage for a player.
    ///
    /// Handles duplicate checking and persistence.
    pub fn create_garage(&self, uid: &str) -> Result<VGarage, String> {
        // Business rule: Check if garage already exists
        if self.repository.exists(uid)? {
            return Err(format!("Garage for '{}' already exists", uid));
        }

        // Create empty garage (no items)
        let garage = VGarage::new();
        self.repository.create(uid, &garage)?;

        Ok(garage)
    }

    /// Retrieves a player's virtual garage.
    pub fn fetch_garage(&self, uid: &str) -> Result<VGarage, String> {
        match self.repository.fetch(uid)? {
            Some(garage) => Ok(garage),
            None => Err(format!("No garage found for player '{}'", uid)),
        }
    }

    pub fn update_garage(&self, uid: &str, garage: &VGarage) -> Result<VGarage, String> {
        self.repository.update(uid, garage)?;
        Ok(garage.clone())
    }

    /// Retrieves a specific field from a player's virtual garage.
    ///
    /// Fields: "cars", "armor", "heli", "planes", "naval", "other"
    pub fn get_garage(&self, uid: &str, field: &str) -> Result<Vec<String>, String> {
        self.repository.get(uid, field)
    }

    /// Adds classnames to a player's virtual garage.
    pub fn add_garage(
        &self,
        uid: &str,
        category: VehicleCategory,
        classnames: Vec<String>,
    ) -> Result<VGarage, String> {
        let mut garage = match self.repository.fetch(uid)? {
            Some(g) => g,
            None => VGarage::new(),
        };

        garage.add(category, classnames);
        self.repository.update(uid, &garage)?;

        Ok(garage)
    }

    /// Removes a classname from a player's virtual garage.
    pub fn remove_garage(
        &self,
        uid: &str,
        category: VehicleCategory,
        classname: &str,
    ) -> Result<VGarage, String> {
        let mut garage = match self.repository.fetch(uid)? {
            Some(g) => g,
            None => return Err(format!("No garage found for player '{}'", uid)),
        };

        if garage.remove(category, classname).is_none() {
            return Err(format!("Item '{}' not found in garage", classname));
        }

        self.repository.update(uid, &garage)?;

        Ok(garage)
    }

    /// Permanently deletes a player's virtual garage.
    ///
    /// Irreversible operation. Delegates to repository.
    pub fn delete_garage(&self, uid: &str) -> Result<(), String> {
        // Business rule: Check if garage exists
        if !self.repository.exists(uid)? {
            return Err(format!("No garage found for player '{}'", uid));
        }

        // Delete garage
        self.repository.delete(uid)?;

        Ok(())
    }

    /// Checks if a player has a virtual garage.
    ///
    /// Lightweight check without data retrieval.
    pub fn garage_exists(&self, uid: &str) -> Result<bool, String> {
        self.repository.exists(uid)
    }
}

impl<R: VGarageRepository, H: VGarageHotRepository> VGarageHotStateService<R, H> {
    pub fn new(repository: R, hot_repository: H) -> Self {
        Self {
            service: VGarageService::new(repository),
            repository: hot_repository,
        }
    }

    pub fn init_garage(&self, uid: &str) -> Result<VGarage, String> {
        if let Some(garage) = self.repository.get(uid)? {
            return Ok(garage);
        }

        let garage = match self.service.fetch_garage(uid) {
            Ok(garage) => garage,
            Err(_) => self.service.create_garage(uid)?,
        };
        self.repository.save(&garage, uid)?;
        Ok(garage)
    }

    pub fn fetch_garage(&self, uid: &str) -> Result<VGarage, String> {
        self.init_garage(uid)
    }

    pub fn get_garage(&self, uid: &str, field: &str) -> Result<Vec<String>, String> {
        let garage = self.init_garage(uid)?;
        Ok(match field.to_lowercase().as_str() {
            "cars" => garage.cars,
            "armor" => garage.armor,
            "helis" | "heli" => garage.helis,
            "planes" => garage.planes,
            "naval" => garage.naval,
            "other" => garage.other,
            _ => Vec::new(),
        })
    }

    pub fn override_garage(&self, uid: &str, garage: VGarage) -> Result<VGarage, String> {
        self.repository.save(&garage, uid)?;
        Ok(garage)
    }

    pub fn save_garage(&self, uid: &str) -> Result<VGarage, String> {
        let garage = self
            .repository
            .get(uid)?
            .ok_or_else(|| format!("No garage found for player '{}'", uid))?;
        let saved = if self.service.garage_exists(uid)? {
            self.service.update_garage(uid, &garage)?
        } else {
            self.service.create_garage(uid)?
        };
        self.repository.save(&saved, uid)?;
        Ok(saved)
    }

    pub fn add_garage(
        &self,
        uid: &str,
        category: VehicleCategory,
        classnames: Vec<String>,
    ) -> Result<VGarage, String> {
        let garage = self.service.add_garage(uid, category, classnames)?;
        self.repository.save(&garage, uid)?;
        Ok(garage)
    }

    pub fn remove_garage(
        &self,
        uid: &str,
        category: VehicleCategory,
        classname: &str,
    ) -> Result<VGarage, String> {
        let garage = self.service.remove_garage(uid, category, classname)?;
        self.repository.save(&garage, uid)?;
        Ok(garage)
    }

    pub fn remove_hot_garage(&self, uid: &str) -> Result<(), String> {
        self.repository.delete(uid)
    }
}
