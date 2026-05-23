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

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct TaskRewardContext {
    #[serde(default)]
    pub requester_uid: String,
    #[serde(default)]
    pub org_id: String,
}
