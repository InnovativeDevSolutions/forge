//! Garage service layer providing business logic for vehicle garage management.
//!
//! Handles validation, storage, and retrieval of player vehicle garages.

use forge_models::garage::{Garage, HitPoints, Vehicle};
use forge_repositories::{GarageHotRepository, GarageRepository};
use std::collections::HashMap;
use uuid::Uuid;

/// Service layer implementation for garage business logic and operations.
pub struct GarageService<R: GarageRepository> {
    repository: R,
}

pub struct GarageHotStateService<R: GarageRepository, H: GarageHotRepository> {
    service: GarageService<R>,
    repository: H,
}

impl<R: GarageRepository> GarageService<R> {
    /// Creates a new garage service with the provided repository.
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    /// Creates a new empty garage for a player
    pub fn create_garage(&self, key: String) -> Result<Garage, String> {
        // Business rule: Check if garage already exists
        if self.repository.exists(&key)? {
            return Err(format!("Garage for '{}' already exists", key));
        }

        // Create empty garage (no vehicles)
        let garage = Garage::new().map_err(|e| format!("Validation failed: {}", e))?;
        self.repository.create(&key, &garage)?;

        Ok(garage)
    }

    /// Replaces the entire garage content with the provided vehicles map
    pub fn update_garage(
        &self,
        key: String,
        vehicles: HashMap<String, Vehicle>,
    ) -> Result<Garage, String> {
        // Validate all vehicles
        for vehicle in vehicles.values() {
            vehicle
                .validate()
                .map_err(|e| format!("Validation failed for vehicle {}: {}", vehicle.plate, e))?;
        }

        // Create garage object
        let garage = Garage { vehicles };

        // Validate garage (capacity, etc.)
        // Business rule: Check if garage has reached maximum capacity
        if garage.vehicles.len() > 5 {
            return Err("Garage exceeds maximum capacity of 5 vehicles.".to_string());
        }

        // Update repository
        self.repository.update(&key, &garage)?;

        Ok(garage)
    }

    pub fn patch_vehicle(
        &self,
        key: String,
        plate: String,
        damage: Option<f64>,
        fuel: Option<f64>,
        hit_points_json: Option<String>,
    ) -> Result<Garage, String> {
        let mut garage = self.repository.get(&key)?.unwrap_or(Garage {
            vehicles: HashMap::new(),
        });

        if let Some(vehicle) = garage.vehicles.get_mut(&plate) {
            if let Some(d) = damage {
                vehicle.damage = d;
            }
            if let Some(f) = fuel {
                vehicle.fuel = f;
            }
            if let Some(hp_json) = hit_points_json
                && let Ok(hp) = HitPoints::from_json_str(&hp_json)
            {
                vehicle.hit_points = hp;
            }
        } else {
            return Err(format!("Vehicle with plate {} not found", plate));
        }

        self.repository.update(&key, &garage)?;
        Ok(garage)
    }

    /// Adds a new vehicle to a player's garage
    pub fn add_vehicle(
        &self,
        key: String,
        classname: String,
        fuel: f64,
        damage: f64,
        hit_points_json: String,
    ) -> Result<Garage, String> {
        // Get existing garage or create new one
        let mut garage = match self.repository.get(&key)? {
            Some(g) => g,
            None => Garage::new().map_err(|e| format!("Failed to create garage: {}", e))?,
        };

        // Business rule: Check if garage has reached maximum capacity (5 vehicles)
        if garage.vehicles.len() >= 5 {
            return Err("Garage is full. Maximum of 5 vehicles allowed.".to_string());
        }

        // Generate a unique plate (vehicle ID) using UUID
        let plate = Uuid::new_v4().to_string();

        // Parse hit points from Arma 3 JSON
        let hit_points = HitPoints::from_json_str(&hit_points_json)?;

        // Create new vehicle entry with validation
        let new_vehicle = Vehicle::new(plate, classname, fuel, damage, hit_points)
            .map_err(|e| format!("Validation failed: {}", e))?;

        // Add new vehicle to garage
        garage
            .add_vehicle(new_vehicle)
            .map_err(|e| format!("Failed to add vehicle: {}", e))?;

        // Update garage with new vehicle
        self.repository.update(&key, &garage)?;

        Ok(garage)
    }

    /// Retrieves a player's garage
    pub fn get_garage(&self, key: String) -> Result<Garage, String> {
        match self.repository.get(&key)? {
            Some(garage) => Ok(garage),
            None => Err(format!("No garage found for player '{}'", key)),
        }
    }

    /// Removes a vehicle from the garage by plate number
    pub fn remove_vehicle(&self, key: String, plate: String) -> Result<Garage, String> {
        // Get existing garage
        let mut garage = match self.repository.get(&key)? {
            Some(g) => g,
            None => return Err(format!("No garage found for player '{}'", key)),
        };

        // Remove the vehicle by plate
        garage
            .remove_vehicle(&plate)
            .ok_or_else(|| format!("Vehicle with plate '{}' not found in garage", plate))?;

        // Update garage after removing vehicle
        self.repository.update(&key, &garage)?;

        Ok(garage)
    }

    /// Deletes all vehicles from a player's garage
    pub fn delete_garage(&self, key: String) -> Result<(), String> {
        self.repository.delete(&key)
    }

    /// Checks if a player has a garage (even if empty)
    pub fn garage_exists(&self, key: String) -> Result<bool, String> {
        self.repository.exists(&key)
    }
}

impl<R: GarageRepository, H: GarageHotRepository> GarageHotStateService<R, H> {
    pub fn new(repository: R, hot_repository: H) -> Self {
        Self {
            service: GarageService::new(repository),
            repository: hot_repository,
        }
    }

    pub fn init_garage(&self, uid: String) -> Result<Garage, String> {
        if let Some(garage) = self.repository.get(&uid)? {
            return Ok(garage);
        }

        let garage = match self.service.get_garage(uid.clone()) {
            Ok(garage) => garage,
            Err(_) => self.service.create_garage(uid.clone())?,
        };
        self.repository.save(&garage, &uid)?;
        Ok(garage)
    }

    pub fn get_garage(&self, uid: String) -> Result<Garage, String> {
        self.init_garage(uid)
    }

    pub fn override_garage(
        &self,
        uid: String,
        vehicles: HashMap<String, Vehicle>,
    ) -> Result<Garage, String> {
        for vehicle in vehicles.values() {
            vehicle
                .validate()
                .map_err(|e| format!("Validation failed for vehicle {}: {}", vehicle.plate, e))?;
        }

        let garage = Garage { vehicles };
        if garage.vehicles.len() > 5 {
            return Err("Garage exceeds maximum capacity of 5 vehicles.".to_string());
        }

        self.repository.save(&garage, &uid)?;
        Ok(garage)
    }

    pub fn save_garage(&self, uid: String) -> Result<Garage, String> {
        let garage = self
            .repository
            .get(&uid)?
            .ok_or_else(|| format!("No garage found for player '{}'", uid))?;
        let saved = self
            .service
            .update_garage(uid.clone(), garage.vehicles.clone())?;
        self.repository.save(&saved, &uid)?;
        Ok(saved)
    }

    pub fn add_vehicle(
        &self,
        uid: String,
        classname: String,
        fuel: f64,
        damage: f64,
        hit_points_json: String,
    ) -> Result<Garage, String> {
        let mut garage = match self.repository.get(&uid)? {
            Some(garage) => garage,
            None => match self.service.get_garage(uid.clone()) {
                Ok(garage) => garage,
                Err(_) => Garage::new().map_err(|e| format!("Failed to create garage: {}", e))?,
            },
        };

        if garage.vehicles.len() >= 5 {
            return Err("Garage is full. Maximum of 5 vehicles allowed.".to_string());
        }

        let plate = Uuid::new_v4().to_string();
        let hit_points = HitPoints::from_json_str(&hit_points_json)?;
        let new_vehicle = Vehicle::new(plate, classname, fuel, damage, hit_points)
            .map_err(|e| format!("Validation failed: {}", e))?;

        garage
            .add_vehicle(new_vehicle)
            .map_err(|e| format!("Failed to add vehicle: {}", e))?;

        self.repository.save(&garage, &uid)?;
        Ok(garage)
    }

    pub fn remove_vehicle(&self, uid: String, plate: String) -> Result<Garage, String> {
        let mut garage = match self.repository.get(&uid)? {
            Some(garage) => garage,
            None => self
                .service
                .get_garage(uid.clone())
                .map_err(|_| format!("No garage found for player '{}'", uid))?,
        };

        garage
            .remove_vehicle(&plate)
            .ok_or_else(|| format!("Vehicle with plate '{}' not found in garage", plate))?;

        self.repository.save(&garage, &uid)?;
        Ok(garage)
    }

    pub fn remove_garage(&self, uid: String) -> Result<(), String> {
        self.repository.delete(&uid)
    }
}
