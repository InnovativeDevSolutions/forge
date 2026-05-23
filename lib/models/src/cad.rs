use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

pub type CadJsonMap = Map<String, Value>;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(transparent)]
pub struct CadRecord {
    pub fields: CadJsonMap,
}

impl CadRecord {
    pub fn into_value(self) -> Value {
        Value::Object(self.fields)
    }

    pub fn to_value(&self) -> Value {
        Value::Object(self.fields.clone())
    }

    pub fn is_empty(&self) -> bool {
        self.fields.is_empty()
    }

    pub fn merge(mut self, patch: CadRecord) -> Self {
        for (key, value) in patch.fields {
            self.fields.insert(key, value);
        }

        self
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadDispatchOrderCreateSeed {
    #[serde(default)]
    pub order: CadRecord,
    #[serde(default)]
    pub assignment: CadRecord,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadDispatchOrderContextSeed {
    #[serde(default)]
    pub assignee_group_id: String,
    #[serde(default)]
    pub assignee_group_callsign: String,
    #[serde(default)]
    pub target_group_id: String,
    #[serde(default)]
    pub target_group_callsign: String,
    #[serde(default)]
    pub target_position: Value,
    #[serde(default)]
    pub created_by_uid: String,
    #[serde(default)]
    pub created_by_name: String,
    #[serde(default)]
    pub request_id: String,
    #[serde(default)]
    pub request_type: String,
    #[serde(default)]
    pub request_title: String,
    #[serde(default)]
    pub request_summary: String,
    #[serde(default)]
    pub request_fields: CadRecord,
    #[serde(default)]
    pub note: String,
    #[serde(default)]
    pub priority: String,
    #[serde(default)]
    pub created_at: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadDispatchOrderMutationResult {
    #[serde(default)]
    pub task_id: String,
    #[serde(default)]
    pub order: Value,
    #[serde(default)]
    pub assignment: Value,
    #[serde(default)]
    pub message: String,
    #[serde(default)]
    pub activity: CadActivityEntry,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadActivityEntry {
    #[serde(default)]
    #[serde(rename = "type")]
    pub entry_type: String,
    #[serde(default)]
    pub message: String,
    #[serde(default)]
    pub task_id: String,
    #[serde(default)]
    pub group_id: String,
    #[serde(default)]
    pub actor_uid: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadAssignmentMutationResult {
    #[serde(default)]
    pub assignment: Value,
    #[serde(default)]
    pub message: String,
    #[serde(default)]
    pub activity: CadActivityEntry,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadRequestMutationResult {
    #[serde(default)]
    pub request: Value,
    #[serde(default)]
    pub message: String,
    #[serde(default)]
    pub activity: CadActivityEntry,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadGroupProfileUpdateSeed {
    #[serde(default)]
    pub group_id: String,
    #[serde(default)]
    pub group_callsign: String,
    #[serde(default)]
    pub requester_uid: String,
    #[serde(default)]
    pub current_role: String,
    #[serde(default)]
    pub current_status: String,
    #[serde(default)]
    pub role: String,
    #[serde(default)]
    pub status: String,
    #[serde(default)]
    pub mode: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadGroupProfileMutationResult {
    #[serde(default)]
    pub profile: Value,
    #[serde(default)]
    pub message: String,
    #[serde(default)]
    pub activity: CadActivityEntry,
    #[serde(default)]
    pub changed: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadSupportRequestSubmitSeed {
    #[serde(rename = "type")]
    #[serde(default)]
    pub request_type: String,
    #[serde(default)]
    pub fields: CadRecord,
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
pub struct CadGroupBuildSeed {
    #[serde(default)]
    pub live_groups: Vec<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadSession {
    #[serde(default)]
    pub uid: String,
    #[serde(default)]
    pub org_id: String,
    #[serde(default)]
    pub is_dispatcher: bool,
    #[serde(default)]
    pub group_id: String,
    #[serde(default)]
    pub is_leader: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadHydrateSeed {
    #[serde(default)]
    pub groups: Vec<Value>,
    #[serde(default)]
    pub active_tasks: Vec<Value>,
    #[serde(default)]
    pub session: CadSession,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct CadHydratePayload {
    #[serde(default)]
    pub groups: Vec<Value>,
    #[serde(default)]
    pub contracts: Vec<Value>,
    #[serde(default)]
    pub requests: Vec<Value>,
    #[serde(default)]
    pub assignments: Vec<Value>,
    #[serde(default)]
    pub activity: Vec<Value>,
    #[serde(default)]
    pub session: CadSession,
}
