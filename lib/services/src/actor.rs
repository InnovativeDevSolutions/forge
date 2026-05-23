//! Actor service layer providing business logic for actor management operations.
//!
//! Implements the service layer of the actor management system, handling business logic,
//! validation, and orchestration.
//!
//! For full documentation, architecture, and examples, see the [crate README](../README.md).

use forge_models::Actor;
use forge_repositories::{ActorHotRepository, ActorRepository};
use forge_shared::{generate_email, generate_phone_number};

/// Service layer implementation for actor business logic and operations.
///
/// Orchestrates actor management operations, handling business logic, validation,
/// and data transformation. See [crate README](../README.md) for details.
///
/// # Thread Safety
/// Thread-safe when used with a thread-safe repository.
pub struct ActorService<R: ActorRepository> {
    /// The repository instance used for all data persistence operations.
    ///
    /// This repository handles the actual storage and retrieval of actor data,
    /// abstracting away the specific database implementation details.
    repository: R,
}

pub struct ActorHotStateService<R: ActorRepository, H: ActorHotRepository> {
    service: ActorService<R>,
    repository: H,
}

impl<R: ActorRepository, H: ActorHotRepository> ActorHotStateService<R, H> {
    pub fn new(repository: R, hot_repository: H) -> Self {
        Self {
            service: ActorService::new(repository),
            repository: hot_repository,
        }
    }

    pub fn init_actor(&self, key: String) -> Result<Actor, String> {
        if let Some(actor) = self.repository.get(&key)? {
            return Ok(actor);
        }

        let actor = self
            .service
            .repository
            .get_by_id(&key)?
            .ok_or_else(|| format!("Actor with UID '{}' was not found", key))?;
        self.repository.save(&actor)?;
        Ok(actor)
    }

    pub fn get_actor(&self, key: String) -> Result<Actor, String> {
        if let Some(actor) = self.repository.get(&key)? {
            return Ok(actor);
        }

        let actor = self
            .service
            .repository
            .get_by_id(&key)?
            .ok_or_else(|| format!("Actor with UID '{}' was not found", key))?;
        self.repository.save(&actor)?;
        Ok(actor)
    }

    pub fn override_actor(&self, key: String, json_data: String) -> Result<Actor, String> {
        let mut actor: Actor =
            serde_json::from_str(&json_data).map_err(|e| format!("Invalid Actor JSON: {}", e))?;

        actor.uid = key;
        actor
            .validate()
            .map_err(|e| format!("Validation failed: {}", e))?;

        self.repository.save(&actor)?;
        Ok(actor)
    }

    pub fn save_actor(&self, key: String) -> Result<Actor, String> {
        let actor = self
            .repository
            .get(&key)?
            .ok_or_else(|| format!("Actor with UID '{}' not found in hot state", key))?;
        let actor_json = serde_json::to_string(&actor)
            .map_err(|e| format!("Failed to serialize actor: {}", e))?;

        let saved_actor = self.service.update_actor(key, actor_json)?;
        self.repository.save(&saved_actor)?;
        Ok(saved_actor)
    }

    pub fn list_actor_keys(&self) -> Result<Vec<String>, String> {
        self.repository.keys()
    }

    pub fn remove_actor(&self, key: String) -> Result<(), String> {
        self.repository.delete(&key)
    }
}

impl<R: ActorRepository> ActorService<R> {
    /// Creates a new actor service with the provided repository.
    ///
    /// The repository must be initialized and ready for use.
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    /// Creates a new actor with the provided ID and JSON data.
    ///
    /// Handles validation, duplicate checking, and persistence.
    /// See [crate README](../README.md) for JSON format and business rules.
    pub fn create_actor(&self, key: String, json_data: String) -> Result<Actor, String> {
        // Parse JSON data to Actor struct
        let mut actor: Actor =
            serde_json::from_str(&json_data).map_err(|e| format!("Invalid Actor JSON: {}", e))?;

        // Set UID from parameter (authoritative source)
        actor.uid = key;

        // Check if actor already exists to prevent duplicates
        if self.repository.exists(&actor.uid)? {
            return Err(format!("Actor with UID '{}' already exists", actor.uid));
        }

        // Generate phone number and email if they're empty (for new actors)
        if actor.phone_number.is_empty() {
            actor.phone_number = generate_phone_number(&actor.uid);
        }
        if actor.email.is_empty() {
            actor.email = generate_email(&actor.phone_number);
        }
        if actor.organization.trim().is_empty() {
            actor.organization = "default".to_string();
        }

        // Validate before persisting
        actor
            .validate()
            .map_err(|e| format!("Validation failed: {}", e))?;

        // Store the actor in the repository
        self.repository.create(&actor)?;
        Ok(actor)
    }

    /// Retrieves an actor by their unique identifier with automatic fallback creation.
    ///
    /// Implements a "get-or-create" pattern: if the actor doesn't exist, a new one
    /// with default values is returned (but not persisted).
    pub fn get_actor(&self, key: String) -> Result<Actor, String> {
        // Attempt to retrieve actor from repository
        match self.repository.get_by_id(&key)? {
            // Actor found - return it
            Some(actor) => Ok(actor),
            // Actor not found - create fallback actor with default values
            None => Actor::new(key).map_err(|e| e.to_string()),
        }
    }

    /// Updates an existing actor with new data from JSON.
    ///
    /// Handles partial updates, validation, and persistence.
    /// See [crate README](../README.md) for JSON format and concurrency details.
    pub fn update_actor(&self, key: String, json_update: String) -> Result<Actor, String> {
        // Retrieve existing actor from repository
        let mut actor = match self.repository.get_by_id(&key)? {
            Some(actor) => actor,
            None => return Err(format!("Actor with UID '{}' not found", key)),
        };

        // Parse and validate JSON update data
        let update_data: serde_json::Value =
            serde_json::from_str(&json_update).map_err(|e| format!("Invalid JSON: {}", e))?;

        // Ensure update data is a JSON object
        if !update_data.is_object() {
            return Err("Update data must be a JSON object".to_string());
        }

        // Create a temporary copy to safely apply updates with validation
        let mut updated_actor = actor.clone();

        // Apply updates field by field
        if let Some(obj) = update_data.as_object() {
            for (field, value) in obj {
                match field.as_str() {
                    "uid" => {
                        // Skip UID - it's immutable and set by the system
                        continue;
                    }
                    "name" => {
                        updated_actor.name = if value.is_null() {
                            None
                        } else {
                            value.as_str().map(|s| s.to_string())
                        };
                    }
                    "position" => {
                        updated_actor.position = if value.is_null() {
                            None
                        } else if let Some(arr) = value.as_array() {
                            let coords: Result<Vec<f64>, _> = arr
                                .iter()
                                .map(|v| v.as_f64().ok_or("Invalid coordinate"))
                                .collect();
                            match coords {
                                Ok(pos) if pos.len() == 3 => Some(pos),
                                _ => return Err("Position must be [x, y, z] array".to_string()),
                            }
                        } else {
                            return Err("Position must be an array".to_string());
                        };
                    }
                    "direction" => {
                        if let Some(dir_val) = value.as_f64() {
                            updated_actor.direction = dir_val % 360.0;
                            if updated_actor.direction < 0.0 {
                                updated_actor.direction += 360.0;
                            }
                        } else {
                            return Err("Direction must be a number".to_string());
                        }
                    }
                    "stance" => {
                        updated_actor.stance = if value.is_null() {
                            None
                        } else {
                            value.as_str().map(|s| s.to_string())
                        };
                    }
                    "email" => {
                        if let Some(email_str) = value.as_str() {
                            updated_actor.email = email_str.to_string();
                        } else {
                            return Err("Email must be a string".to_string());
                        }
                    }
                    "phone_number" => {
                        if let Some(phone_str) = value.as_str() {
                            updated_actor.phone_number = phone_str.to_string();
                        } else {
                            return Err("Phone number must be a string".to_string());
                        }
                    }
                    "state" => {
                        if let Some(state_str) = value.as_str() {
                            updated_actor.state = state_str.to_uppercase();
                        } else {
                            return Err("State must be a string".to_string());
                        }
                    }
                    "holster" => {
                        if let Some(holster_val) = value.as_bool() {
                            updated_actor.holster = holster_val;
                        } else {
                            return Err("Holster must be a boolean".to_string());
                        }
                    }
                    "rank" => {
                        updated_actor.rank = if value.is_null() {
                            None
                        } else if let Some(rank_str) = value.as_str() {
                            Some(rank_str.to_string())
                        } else {
                            return Err("Rank must be a string or null".to_string());
                        };
                    }
                    "organization" => {
                        updated_actor.organization = if value.is_null() {
                            String::new()
                        } else if let Some(org_str) = value.as_str() {
                            org_str.to_string()
                        } else {
                            return Err("Organization must be a string or null".to_string());
                        };
                    }
                    "loadout" => {
                        updated_actor.loadout = value.clone();
                    }
                    _ => {
                        return Err(format!("Unknown field: {}", field));
                    }
                }
            }
        }

        // Validate the updated actor before committing changes
        updated_actor
            .validate()
            .map_err(|e| format!("Validation failed: {}", e))?;

        // Only commit changes after validation passes
        actor = updated_actor;

        // Persist the updated actor to repository
        self.repository.update(&actor)?;

        Ok(actor)
    }

    /// Permanently deletes an actor from the system.
    ///
    /// Irreversible operation. Delegates to repository.
    pub fn delete_actor(&self, key: String) -> Result<(), String> {
        // Delegate deletion to repository layer
        // Future enhancements could add business logic here:
        // - Authorization checks
        // - Audit logging
        // - Cascade deletion
        // - Soft deletion
        self.repository.delete(&key)
    }

    /// Checks if an actor exists in the system.
    ///
    /// Lightweight check without data retrieval.
    pub fn actor_exists(&self, key: String) -> Result<bool, String> {
        // Delegate existence check to repository layer
        // This is a lightweight operation that doesn't retrieve data
        self.repository.exists(&key)
    }
}
