use forge_models::{TaskOwnershipContext, TaskRecord};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

pub trait TaskRepository: Send + Sync {
    fn reset(&self) -> Result<(), String>;

    fn list_catalog(&self) -> Result<HashMap<String, TaskRecord>, String>;
    fn get_catalog_entry(&self, id: &str) -> Result<Option<TaskRecord>, String>;
    fn save_catalog_entry(&self, id: String, entry: TaskRecord) -> Result<(), String>;
    fn delete_catalog_entry(&self, id: &str) -> Result<(), String>;

    fn get_ownership(&self, id: &str) -> Result<Option<TaskOwnershipContext>, String>;
    fn save_ownership(&self, id: String, ownership: TaskOwnershipContext) -> Result<(), String>;
    fn delete_ownership(&self, id: &str) -> Result<(), String>;

    fn list_active_statuses(&self) -> Result<HashMap<String, String>, String>;
    fn get_active_status(&self, id: &str) -> Result<Option<String>, String>;
    fn set_active_status(&self, id: String, status: String) -> Result<(), String>;
    fn delete_active_status(&self, id: &str) -> Result<(), String>;

    fn get_completed_status(&self, id: &str) -> Result<Option<String>, String>;
    fn set_completed_status(&self, id: String, status: String) -> Result<(), String>;
    fn delete_completed_status(&self, id: &str) -> Result<(), String>;

    fn increment_defuse_count(&self, id: &str) -> Result<u64, String>;
    fn get_defuse_count(&self, id: &str) -> Result<u64, String>;
    fn clear_defuse_count(&self, id: &str) -> Result<(), String>;
}

#[derive(Debug, Default)]
struct TaskState {
    catalog: HashMap<String, TaskRecord>,
    ownership: HashMap<String, TaskOwnershipContext>,
    active_statuses: HashMap<String, String>,
    completed_statuses: HashMap<String, String>,
    defuse_counts: HashMap<String, u64>,
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryTaskRepository {
    state: Arc<RwLock<TaskState>>,
}

impl InMemoryTaskRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

impl TaskRepository for InMemoryTaskRepository {
    fn reset(&self) -> Result<(), String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Task state lock poisoned.".to_string())?;
        state.catalog.clear();
        state.ownership.clear();
        state.active_statuses.clear();
        state.completed_statuses.clear();
        state.defuse_counts.clear();
        Ok(())
    }

    fn list_catalog(&self) -> Result<HashMap<String, TaskRecord>, String> {
        self.state
            .read()
            .map(|state| state.catalog.clone())
            .map_err(|_| "Task catalog state lock poisoned.".to_string())
    }

    fn get_catalog_entry(&self, id: &str) -> Result<Option<TaskRecord>, String> {
        self.state
            .read()
            .map(|state| state.catalog.get(id).cloned())
            .map_err(|_| "Task catalog state lock poisoned.".to_string())
    }

    fn save_catalog_entry(&self, id: String, entry: TaskRecord) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Task catalog state lock poisoned.".to_string())?
            .catalog
            .insert(id, entry);
        Ok(())
    }

    fn delete_catalog_entry(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Task catalog state lock poisoned.".to_string())?
            .catalog
            .remove(id);
        Ok(())
    }

    fn get_ownership(&self, id: &str) -> Result<Option<TaskOwnershipContext>, String> {
        self.state
            .read()
            .map(|state| state.ownership.get(id).cloned())
            .map_err(|_| "Task ownership state lock poisoned.".to_string())
    }

    fn save_ownership(&self, id: String, ownership: TaskOwnershipContext) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Task ownership state lock poisoned.".to_string())?
            .ownership
            .insert(id, ownership);
        Ok(())
    }

    fn delete_ownership(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Task ownership state lock poisoned.".to_string())?
            .ownership
            .remove(id);
        Ok(())
    }

    fn list_active_statuses(&self) -> Result<HashMap<String, String>, String> {
        self.state
            .read()
            .map(|state| state.active_statuses.clone())
            .map_err(|_| "Task status state lock poisoned.".to_string())
    }

    fn get_active_status(&self, id: &str) -> Result<Option<String>, String> {
        self.state
            .read()
            .map(|state| state.active_statuses.get(id).cloned())
            .map_err(|_| "Task status state lock poisoned.".to_string())
    }

    fn set_active_status(&self, id: String, status: String) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Task status state lock poisoned.".to_string())?
            .active_statuses
            .insert(id, status);
        Ok(())
    }

    fn delete_active_status(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Task status state lock poisoned.".to_string())?
            .active_statuses
            .remove(id);
        Ok(())
    }

    fn get_completed_status(&self, id: &str) -> Result<Option<String>, String> {
        self.state
            .read()
            .map(|state| state.completed_statuses.get(id).cloned())
            .map_err(|_| "Task completed status state lock poisoned.".to_string())
    }

    fn set_completed_status(&self, id: String, status: String) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Task completed status state lock poisoned.".to_string())?
            .completed_statuses
            .insert(id, status);
        Ok(())
    }

    fn delete_completed_status(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Task completed status state lock poisoned.".to_string())?
            .completed_statuses
            .remove(id);
        Ok(())
    }

    fn increment_defuse_count(&self, id: &str) -> Result<u64, String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "Task defuse state lock poisoned.".to_string())?;
        let next_count = 1 + state.defuse_counts.get(id).copied().unwrap_or_default();
        state.defuse_counts.insert(id.to_string(), next_count);
        Ok(next_count)
    }

    fn get_defuse_count(&self, id: &str) -> Result<u64, String> {
        self.state
            .read()
            .map(|state| state.defuse_counts.get(id).copied().unwrap_or_default())
            .map_err(|_| "Task defuse state lock poisoned.".to_string())
    }

    fn clear_defuse_count(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "Task defuse state lock poisoned.".to_string())?
            .defuse_counts
            .remove(id);
        Ok(())
    }
}
