use forge_models::DispatchRecord;
use serde_json::Value;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

const DISPATCH_ACTIVITY_LIMIT: usize = 200;

pub trait DispatchRepository: Send + Sync {
    fn append_activity(&self, entry: Value) -> Result<(), String>;
    fn recent_activity(&self, limit: usize) -> Result<Vec<Value>, String>;

    fn list_requests(&self) -> Result<HashMap<String, DispatchRecord>, String>;
    fn get_request(&self, id: &str) -> Result<Option<DispatchRecord>, String>;
    fn save_request(&self, id: String, entry: DispatchRecord) -> Result<(), String>;
    fn delete_request(&self, id: &str) -> Result<(), String>;
    fn next_request_id(&self) -> Result<String, String>;
}

#[derive(Debug, Default)]
struct DispatchState {
    activity: Vec<Value>,
    requests: HashMap<String, DispatchRecord>,
    request_sequence: u64,
}

#[derive(Clone, Debug, Default)]
pub struct InMemoryDispatchRepository {
    state: Arc<RwLock<DispatchState>>,
}

impl InMemoryDispatchRepository {
    pub fn new() -> Self {
        Self::default()
    }

    fn read(&self) -> Result<std::sync::RwLockReadGuard<'_, DispatchState>, String> {
        self.state
            .read()
            .map_err(|_| "Dispatch state lock poisoned.".to_string())
    }

    fn write(&self) -> Result<std::sync::RwLockWriteGuard<'_, DispatchState>, String> {
        self.state
            .write()
            .map_err(|_| "Dispatch state lock poisoned.".to_string())
    }
}

impl DispatchRepository for InMemoryDispatchRepository {
    fn append_activity(&self, entry: Value) -> Result<(), String> {
        let mut state = self.write()?;
        state.activity.push(entry);
        if state.activity.len() > DISPATCH_ACTIVITY_LIMIT {
            let overflow = state.activity.len() - DISPATCH_ACTIVITY_LIMIT;
            state.activity.drain(0..overflow);
        }
        Ok(())
    }

    fn recent_activity(&self, limit: usize) -> Result<Vec<Value>, String> {
        let state = self.read()?;
        let start = state.activity.len().saturating_sub(limit);
        Ok(state.activity[start..].to_vec())
    }

    fn list_requests(&self) -> Result<HashMap<String, DispatchRecord>, String> {
        Ok(self.read()?.requests.clone())
    }

    fn get_request(&self, id: &str) -> Result<Option<DispatchRecord>, String> {
        Ok(self.read()?.requests.get(id).cloned())
    }

    fn save_request(&self, id: String, entry: DispatchRecord) -> Result<(), String> {
        self.write()?.requests.insert(id, entry);
        Ok(())
    }

    fn delete_request(&self, id: &str) -> Result<(), String> {
        self.write()?.requests.remove(id);
        Ok(())
    }

    fn next_request_id(&self) -> Result<String, String> {
        let mut state = self.write()?;
        state.request_sequence += 1;
        Ok(format!("dispatch-request:{}", state.request_sequence))
    }
}
