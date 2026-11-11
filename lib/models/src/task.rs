use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

pub type TaskJsonMap = Map<String, Value>;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(transparent)]
pub struct TaskRecord {
    pub fields: TaskJsonMap,
}

impl TaskRecord {
    pub fn into_value(self) -> Value {
        Value::Object(self.fields)
    }

    pub fn to_value(&self) -> Value {
        Value::Object(self.fields.clone())
    }

    pub fn is_empty(&self) -> bool {
        self.fields.is_empty()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct TaskOwnershipContext {
    #[serde(default)]
    pub requester_uid: String,
    #[serde(default)]
    pub org_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct TaskOwnershipMutationResult {
    #[serde(default)]
    pub task_id: String,
    #[serde(default)]
    pub requester_uid: String,
    #[serde(default)]
    pub org_id: String,
    #[serde(default)]
    pub entry: Value,
    #[serde(default)]
    pub message: String,
}

/// Context for assigning a task to a group, or for a group accepting or
/// declining the task it was assigned.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct TaskGroupContext {
    #[serde(default)]
    pub group_id: String,
    #[serde(default)]
    pub group_callsign: String,
    /// Dispatcher (assign) or group leader (accept/decline) performing the action.
    #[serde(default)]
    pub requester_uid: String,
    #[serde(default)]
    pub requester_name: String,
    /// Organization of the accepting leader. Only used on accept.
    #[serde(default)]
    pub org_id: String,
    #[serde(default)]
    pub note: String,
    #[serde(default)]
    pub timestamp: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct TaskGroupMutationResult {
    #[serde(default)]
    pub task_id: String,
    #[serde(default)]
    pub status: String,
    #[serde(default)]
    pub entry: Value,
    #[serde(default)]
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct TaskRewardContext {
    #[serde(default)]
    pub requester_uid: String,
    #[serde(default)]
    pub org_id: String,
}
