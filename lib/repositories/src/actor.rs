//! Actor repository implementation for data persistence operations.
//!
//! This module provides the data access layer for actor (player) management,
//! implementing the repository pattern to abstract database operations.
//!
//! For full documentation and examples, see the [crate README](../README.md).

use forge_models::Actor;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

/// Repository trait defining the contract for actor data operations.
///
/// This trait abstracts the data persistence layer, allowing different
/// implementations while maintaining a consistent
/// interface for the service layer. All implementations must be thread-safe.
pub trait ActorRepository: Send + Sync {
    /// Creates a new actor in the repository.
    fn create(&self, actor: &Actor) -> Result<(), String>;

    /// Retrieves an actor by their unique identifier.
    fn get_by_id(&self, id: &str) -> Result<Option<Actor>, String>;

    /// Updates an existing actor with new data.
    fn update(&self, actor: &Actor) -> Result<(), String>;

    /// Permanently removes an actor from the repository.
    fn delete(&self, id: &str) -> Result<(), String>;

    /// Checks if an actor exists in the repository.
    fn exists(&self, id: &str) -> Result<bool, String>;
}

pub trait ActorHotRepository: Send + Sync {
    fn get(&self, id: &str) -> Result<Option<Actor>, String>;
    fn keys(&self) -> Result<Vec<String>, String>;
    fn save(&self, actor: &Actor) -> Result<(), String>;
    fn delete(&self, id: &str) -> Result<(), String>;
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryActorHotRepository {
    state: Arc<RwLock<HashMap<String, Actor>>>,
}

impl InMemoryActorHotRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

impl ActorHotRepository for InMemoryActorHotRepository {
    fn get(&self, id: &str) -> Result<Option<Actor>, String> {
        self.state
            .read()
            .map(|state| state.get(id).cloned())
            .map_err(|_| "Actor hot state lock poisoned.".to_string())
    }

    fn keys(&self) -> Result<Vec<String>, String> {
        self.state
            .read()
            .map(|state| state.keys().cloned().collect())
            .map_err(|_| "Actor hot state lock poisoned.".to_string())
    }

    fn save(&self, actor: &Actor) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Actor hot state lock poisoned.".to_string())?
            .insert(actor.uid.clone(), actor.clone());
        Ok(())
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Actor hot state lock poisoned.".to_string())?
            .remove(id);
        Ok(())
    }
}
