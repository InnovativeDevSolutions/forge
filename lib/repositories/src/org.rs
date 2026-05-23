//! Organization repository implementation for data persistence operations.
//!
//! This module provides the data access layer for organization (guild/clan) management,
//! implementing the repository pattern to abstract database operations.
//!
//! For full documentation and examples, see the [crate README](../README.md).

use forge_models::{HotOrgRecord, MemberSummary, Org, OrgAssetEntry, OrgFleetEntry};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

/// Repository trait defining the contract for organization data operations.
///
/// This trait abstracts the data persistence layer, allowing different
/// implementations while maintaining a consistent
/// interface for the service layer. All implementations must be thread-safe.
pub trait OrgRepository: Send + Sync {
    /// Creates a new organization in the repository.
    fn create(&self, org: &Org) -> Result<(), String>;

    /// Retrieves an organization by its unique identifier.
    fn get_by_id(&self, id: &str) -> Result<Option<Org>, String>;

    /// Updates an existing organization with new data.
    fn update(&self, org: &Org) -> Result<(), String>;

    /// Permanently removes an organization from the repository.
    fn delete(&self, id: &str) -> Result<(), String>;

    /// Checks if an organization exists in the repository.
    fn exists(&self, id: &str) -> Result<bool, String>;

    /// Adds a new member UID to an organization.
    fn add_member(&self, org_id: &str, member_uid: &str) -> Result<(), String>;

    /// Retrieves all members of an organization as a list of MemberSummary objects.
    fn get_members(&self, org_id: &str) -> Result<Vec<MemberSummary>, String>;

    /// Removes a specific member from an organization.
    fn remove_member(&self, org_id: &str, member_uid: &str) -> Result<(), String>;

    /// Retrieves all organization assets grouped by category and classname.
    fn get_assets(
        &self,
        org_id: &str,
    ) -> Result<HashMap<String, HashMap<String, OrgAssetEntry>>, String>;

    /// Replaces the organization asset hash with the provided grouped assets.
    fn update_assets(
        &self,
        org_id: &str,
        assets: &HashMap<String, HashMap<String, OrgAssetEntry>>,
    ) -> Result<(), String>;

    /// Retrieves all organization fleet entries.
    fn get_fleet(&self, org_id: &str) -> Result<HashMap<String, OrgFleetEntry>, String>;

    /// Replaces the organization fleet hash with the provided fleet entries.
    fn update_fleet(
        &self,
        org_id: &str,
        fleet: &HashMap<String, OrgFleetEntry>,
    ) -> Result<(), String>;
}

pub trait OrgHotRepository: Send + Sync {
    fn get(&self, id: &str) -> Result<Option<HotOrgRecord>, String>;
    fn keys(&self) -> Result<Vec<String>, String>;
    fn save(&self, org: &HotOrgRecord) -> Result<(), String>;
    fn delete(&self, id: &str) -> Result<(), String>;
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryOrgHotRepository {
    state: Arc<RwLock<HashMap<String, HotOrgRecord>>>,
}

impl InMemoryOrgHotRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

impl OrgHotRepository for InMemoryOrgHotRepository {
    fn get(&self, id: &str) -> Result<Option<HotOrgRecord>, String> {
        self.state
            .read()
            .map(|state| state.get(id).cloned())
            .map_err(|_| "Org hot state lock poisoned.".to_string())
    }

    fn keys(&self) -> Result<Vec<String>, String> {
        self.state
            .read()
            .map(|state| state.keys().cloned().collect())
            .map_err(|_| "Org hot state lock poisoned.".to_string())
    }

    fn save(&self, org: &HotOrgRecord) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Org hot state lock poisoned.".to_string())?
            .insert(org.id.clone(), org.clone());
        Ok(())
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Org hot state lock poisoned.".to_string())?
            .remove(id);
        Ok(())
    }
}
