use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

pub type DispatchJsonMap = Map<String, Value>;

/// Loosely-typed dispatch record (support request), stored as a JSON object.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(transparent)]
pub struct DispatchRecord {
    pub fields: DispatchJsonMap,
}

impl DispatchRecord {
    pub fn into_value(self) -> Value {
        Value::Object(self.fields)
    }

    pub fn to_value(&self) -> Value {
        Value::Object(self.fields.clone())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct DispatchRequestSubmitSeed {
    #[serde(rename = "type")]
    #[serde(default)]
    pub request_type: String,
    #[serde(default)]
    pub fields: DispatchRecord,
    #[serde(default)]
    pub group_id: String,
    #[serde(default)]
    pub group_callsign: String,
    #[serde(default)]
    pub submitted_by_uid: String,
    #[serde(default)]
    pub submitted_by_name: String,
    #[serde(default)]
    pub priority: String,
    #[serde(default)]
    pub position: Value,
    #[serde(default)]
    pub created_at: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct DispatchRequestMutationResult {
    #[serde(default)]
    pub request: Value,
    #[serde(default)]
    pub message: String,
}
