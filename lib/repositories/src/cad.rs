use forge_models::CadRecord;
use serde_json::Value;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

const CAD_ACTIVITY_LIMIT: usize = 200;

pub trait CadRepository: Send + Sync {
    fn append_activity(&self, entry: Value) -> Result<(), String>;
    fn recent_activity(&self, limit: usize) -> Result<Vec<Value>, String>;
    fn snapshot_activity(&self) -> Result<Vec<Value>, String>;

    fn list_assignments(&self) -> Result<HashMap<String, CadRecord>, String>;
    fn get_assignment(&self, id: &str) -> Result<Option<CadRecord>, String>;
    fn save_assignment(&self, id: String, entry: CadRecord) -> Result<(), String>;
    fn delete_assignment(&self, id: &str) -> Result<(), String>;

    fn list_orders(&self) -> Result<HashMap<String, CadRecord>, String>;
    fn get_order(&self, id: &str) -> Result<Option<CadRecord>, String>;
    fn save_order(&self, id: String, entry: CadRecord) -> Result<(), String>;
    fn delete_order(&self, id: &str) -> Result<(), String>;

    fn list_requests(&self) -> Result<HashMap<String, CadRecord>, String>;
    fn get_request(&self, id: &str) -> Result<Option<CadRecord>, String>;
    fn save_request(&self, id: String, entry: CadRecord) -> Result<(), String>;
    fn delete_request(&self, id: &str) -> Result<(), String>;

    fn list_profiles(&self) -> Result<HashMap<String, CadRecord>, String>;
    fn get_profile(&self, id: &str) -> Result<Option<CadRecord>, String>;
    fn save_profile(&self, id: String, entry: CadRecord) -> Result<(), String>;
    fn delete_profile(&self, id: &str) -> Result<(), String>;

    fn next_order_id(&self) -> Result<String, String>;
    fn next_request_id(&self) -> Result<String, String>;
}

#[derive(Debug, Default)]
struct CadState {
    activity: Vec<Value>,
    assignments: HashMap<String, CadRecord>,
    orders: HashMap<String, CadRecord>,
    requests: HashMap<String, CadRecord>,
    profiles: HashMap<String, CadRecord>,
    order_sequence: u64,
    request_sequence: u64,
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryCadRepository {
    state: Arc<RwLock<CadState>>,
}

impl InMemoryCadRepository {
    pub fn new() -> Self {
        Self::default()
    }
}

impl CadRepository for InMemoryCadRepository {
    fn append_activity(&self, entry: Value) -> Result<(), String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "CAD activity state lock poisoned.".to_string())?;

        state.activity.push(entry);
        if state.activity.len() > CAD_ACTIVITY_LIMIT {
            let overflow = state.activity.len() - CAD_ACTIVITY_LIMIT;
            state.activity.drain(0..overflow);
        }

        Ok(())
    }

    fn recent_activity(&self, limit: usize) -> Result<Vec<Value>, String> {
        let state = self
            .state
            .read()
            .map_err(|_| "CAD activity state lock poisoned.".to_string())?;
        let start = state.activity.len().saturating_sub(limit);
        Ok(state.activity[start..].to_vec())
    }

    fn snapshot_activity(&self) -> Result<Vec<Value>, String> {
        self.state
            .read()
            .map(|state| state.activity.clone())
            .map_err(|_| "CAD activity state lock poisoned.".to_string())
    }

    fn list_assignments(&self) -> Result<HashMap<String, CadRecord>, String> {
        self.state
            .read()
            .map(|state| state.assignments.clone())
            .map_err(|_| "CAD assignments state lock poisoned.".to_string())
    }

    fn get_assignment(&self, id: &str) -> Result<Option<CadRecord>, String> {
        self.state
            .read()
            .map(|state| state.assignments.get(id).cloned())
            .map_err(|_| "CAD assignments state lock poisoned.".to_string())
    }

    fn save_assignment(&self, id: String, entry: CadRecord) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "CAD assignments state lock poisoned.".to_string())?
            .assignments
            .insert(id, entry);
        Ok(())
    }

    fn delete_assignment(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "CAD assignments state lock poisoned.".to_string())?
            .assignments
            .remove(id);
        Ok(())
    }

    fn list_orders(&self) -> Result<HashMap<String, CadRecord>, String> {
        self.state
            .read()
            .map(|state| state.orders.clone())
            .map_err(|_| "CAD orders state lock poisoned.".to_string())
    }

    fn get_order(&self, id: &str) -> Result<Option<CadRecord>, String> {
        self.state
            .read()
            .map(|state| state.orders.get(id).cloned())
            .map_err(|_| "CAD orders state lock poisoned.".to_string())
    }

    fn save_order(&self, id: String, entry: CadRecord) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "CAD orders state lock poisoned.".to_string())?
            .orders
            .insert(id, entry);
        Ok(())
    }

    fn delete_order(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "CAD orders state lock poisoned.".to_string())?
            .orders
            .remove(id);
        Ok(())
    }

    fn list_requests(&self) -> Result<HashMap<String, CadRecord>, String> {
        self.state
            .read()
            .map(|state| state.requests.clone())
            .map_err(|_| "CAD requests state lock poisoned.".to_string())
    }

    fn get_request(&self, id: &str) -> Result<Option<CadRecord>, String> {
        self.state
            .read()
            .map(|state| state.requests.get(id).cloned())
            .map_err(|_| "CAD requests state lock poisoned.".to_string())
    }

    fn save_request(&self, id: String, entry: CadRecord) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "CAD requests state lock poisoned.".to_string())?
            .requests
            .insert(id, entry);
        Ok(())
    }

    fn delete_request(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "CAD requests state lock poisoned.".to_string())?
            .requests
            .remove(id);
        Ok(())
    }

    fn list_profiles(&self) -> Result<HashMap<String, CadRecord>, String> {
        self.state
            .read()
            .map(|state| state.profiles.clone())
            .map_err(|_| "CAD profiles state lock poisoned.".to_string())
    }

    fn get_profile(&self, id: &str) -> Result<Option<CadRecord>, String> {
        self.state
            .read()
            .map(|state| state.profiles.get(id).cloned())
            .map_err(|_| "CAD profiles state lock poisoned.".to_string())
    }

    fn save_profile(&self, id: String, entry: CadRecord) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "CAD profiles state lock poisoned.".to_string())?
            .profiles
            .insert(id, entry);
        Ok(())
    }

    fn delete_profile(&self, id: &str) -> Result<(), String> {
        self.state
            .write()
            .map_err(|_| "CAD profiles state lock poisoned.".to_string())?
            .profiles
            .remove(id);
        Ok(())
    }

    fn next_order_id(&self) -> Result<String, String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "CAD order sequence lock poisoned.".to_string())?;
        state.order_sequence += 1;
        Ok(format!("cad-order:{}", state.order_sequence))
    }

    fn next_request_id(&self) -> Result<String, String> {
        let mut state = self
            .state
            .write()
            .map_err(|_| "CAD request sequence lock poisoned.".to_string())?;
        state.request_sequence += 1;
        Ok(format!("cad-request:{}", state.request_sequence))
    }
}
