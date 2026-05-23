use forge_models::{
    CadActivityEntry, CadAssignmentMutationResult, CadDispatchOrderContextSeed,
    CadDispatchOrderCreateSeed, CadDispatchOrderMutationResult, CadGroupBuildSeed,
    CadGroupProfileMutationResult, CadGroupProfileUpdateSeed, CadHydratePayload, CadHydrateSeed,
    CadRecord, CadRequestMutationResult, CadSession, CadSupportRequestSubmitSeed,
};
use forge_repositories::CadRepository;
use serde_json::{Map, Value};
use std::collections::HashMap;

const CAD_ACTIVITY_LIMIT: usize = 200;
const CAD_RECENT_ACTIVITY_LIMIT: usize = 50;

pub struct CadStateService<R: CadRepository> {
    repository: R,
}

impl<R: CadRepository> CadStateService<R> {
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    pub fn append_activity(&self, json_data: String) -> Result<(), String> {
        let entry = Self::parse_value(&json_data)?;
        self.repository.append_activity(entry)
    }

    pub fn recent_activity(&self, limit: String) -> Result<Vec<Value>, String> {
        let parsed_limit = limit
            .trim()
            .parse::<usize>()
            .ok()
            .filter(|value| *value > 0)
            .unwrap_or(CAD_RECENT_ACTIVITY_LIMIT)
            .min(CAD_ACTIVITY_LIMIT);

        self.repository.recent_activity(parsed_limit)
    }

    pub fn list_assignments(&self) -> Result<Vec<Value>, String> {
        Ok(Self::records_to_values(self.repository.list_assignments()?))
    }

    pub fn assign_assignment(
        &self,
        entry_id: String,
        json_data: String,
    ) -> Result<CadAssignmentMutationResult, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let mut assignment = Self::parse_record(&json_data)?;
        Self::set_task_id(&mut assignment, &entry_id);
        self.repository
            .save_assignment(entry_id.clone(), assignment.clone())?;

        let assignee = Self::display_group_name(&assignment.fields);
        let assigned_by = Self::string_field(&assignment.fields, "assignedByName")
            .unwrap_or_else(|| "Dispatcher".to_string());
        let group_id = Self::string_field(&assignment.fields, "groupId").unwrap_or_default();
        let actor_uid = Self::string_field(&assignment.fields, "assignedByUid").unwrap_or_default();
        Ok(CadAssignmentMutationResult {
            assignment: assignment.into_value(),
            message: "Task assigned.".to_string(),
            activity: Self::build_activity(
                "task_assigned",
                format!("{assigned_by} assigned {entry_id} to {assignee}."),
                entry_id,
                group_id,
                actor_uid,
            ),
        })
    }

    pub fn acknowledge_assignment(
        &self,
        entry_id: String,
        json_data: String,
    ) -> Result<CadAssignmentMutationResult, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let patch = Self::parse_record(&json_data)?;
        let existing = self
            .repository
            .get_assignment(&entry_id)?
            .ok_or_else(|| "CAD assignment could not be resolved.".to_string())?;
        let merged = existing.merge(patch);
        self.repository.save_assignment(entry_id, merged.clone())?;
        Ok(CadAssignmentMutationResult {
            assignment: merged.to_value(),
            message: "Task acknowledged.".to_string(),
            activity: Self::build_activity(
                "task_acknowledged",
                format!(
                    "{} acknowledged {}.",
                    Self::string_field(&merged.fields, "acknowledgedByUid").unwrap_or_default(),
                    Self::string_field(&merged.fields, "taskId").unwrap_or_default()
                ),
                Self::string_field(&merged.fields, "taskId").unwrap_or_default(),
                Self::string_field(&merged.fields, "groupId").unwrap_or_default(),
                Self::string_field(&merged.fields, "acknowledgedByUid").unwrap_or_default(),
            ),
        })
    }

    pub fn decline_assignment(
        &self,
        entry_id: String,
        json_data: String,
    ) -> Result<CadAssignmentMutationResult, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let patch = Self::parse_record(&json_data)?;
        let existing = self
            .repository
            .get_assignment(&entry_id)?
            .ok_or_else(|| "CAD assignment could not be resolved.".to_string())?;
        let merged = existing.merge(patch);
        self.repository.delete_assignment(&entry_id)?;
        Ok(CadAssignmentMutationResult {
            assignment: merged.to_value(),
            message: "Task declined and returned to the contract board.".to_string(),
            activity: Self::build_activity(
                "task_declined",
                format!(
                    "{} declined {}.",
                    Self::string_field(&merged.fields, "declinedByUid").unwrap_or_default(),
                    Self::string_field(&merged.fields, "taskId").unwrap_or_default()
                ),
                Self::string_field(&merged.fields, "taskId").unwrap_or_default(),
                Self::string_field(&merged.fields, "groupId").unwrap_or_default(),
                Self::string_field(&merged.fields, "declinedByUid").unwrap_or_default(),
            ),
        })
    }

    pub fn upsert_assignment(&self, entry_id: String, json_data: String) -> Result<(), String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let entry = Self::parse_record(&json_data)?;
        self.repository.save_assignment(entry_id, entry)
    }

    pub fn delete_assignment(&self, entry_id: String) -> Result<(), String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        self.repository.delete_assignment(&entry_id)
    }

    pub fn list_orders(&self) -> Result<Vec<Value>, String> {
        Ok(Self::records_to_values(self.repository.list_orders()?))
    }

    pub fn create_order(
        &self,
        json_data: String,
    ) -> Result<CadDispatchOrderMutationResult, String> {
        let payload = serde_json::from_str::<CadDispatchOrderCreateSeed>(&json_data)
            .map_err(|error| format!("Invalid CAD order payload: {error}"))?;

        if payload.order.is_empty() {
            return Err("Order payload is required.".to_string());
        }
        if payload.assignment.is_empty() {
            return Err("Assignment payload is required.".to_string());
        }

        let task_id = self.repository.next_order_id()?;
        let mut order = payload.order;
        let mut assignment = payload.assignment;

        Self::set_task_id(&mut order, &task_id);
        order
            .fields
            .insert("isDispatchOrder".to_string(), Value::Bool(true));

        Self::set_task_id(&mut assignment, &task_id);

        self.repository.save_order(task_id.clone(), order.clone())?;
        self.repository
            .save_assignment(task_id.clone(), assignment.clone())?;

        Ok(CadDispatchOrderMutationResult {
            task_id: task_id.clone(),
            order: order.to_value(),
            assignment: assignment.to_value(),
            message: "Dispatch order created.".to_string(),
            activity: Self::build_activity(
                "dispatch_order_created",
                format!(
                    "{} created backup order {task_id} for {} to support {}.",
                    Self::string_field(&order.fields, "createdByName")
                        .unwrap_or_else(|| "Dispatcher".to_string()),
                    Self::display_group_name(&assignment.fields),
                    Self::string_field(&order.fields, "targetGroupCallsign")
                        .unwrap_or_else(|| Self::string_field(&order.fields, "targetGroupId")
                            .unwrap_or_else(|| "target group".to_string()))
                ),
                task_id,
                Self::string_field(&assignment.fields, "groupId").unwrap_or_default(),
                Self::string_field(&order.fields, "createdByUid").unwrap_or_default(),
            ),
        })
    }

    pub fn create_order_from_context(
        &self,
        json_data: String,
    ) -> Result<CadDispatchOrderMutationResult, String> {
        let seed = serde_json::from_str::<CadDispatchOrderContextSeed>(&json_data)
            .map_err(|error| format!("Invalid CAD order context: {error}"))?;

        if seed.assignee_group_id.trim().is_empty() || seed.target_group_id.trim().is_empty() {
            return Err("Assignee and target groups are required.".to_string());
        }

        let final_priority = Self::normalize_priority(&seed.priority);
        let target_callsign =
            Self::fallback_string(&seed.target_group_callsign, &seed.target_group_id);
        let created_by_name = Self::fallback_string(&seed.created_by_name, "Dispatcher");
        let assignee_callsign =
            Self::fallback_string(&seed.assignee_group_callsign, &seed.assignee_group_id);

        let order = CadRecord {
            fields: Map::from_iter([
                (
                    "title".to_string(),
                    Value::String(format!("Backup {target_callsign}")),
                ),
                (
                    "description".to_string(),
                    Value::String(if seed.note.trim().is_empty() {
                        format!(
                            "Dispatch order to back up {target_callsign} at its current position."
                        )
                    } else {
                        seed.note.clone()
                    }),
                ),
                (
                    "type".to_string(),
                    Value::String("dispatch_order".to_string()),
                ),
                ("priority".to_string(), Value::String(final_priority)),
                ("position".to_string(), seed.target_position.clone()),
                (
                    "targetGroupId".to_string(),
                    Value::String(seed.target_group_id.clone()),
                ),
                (
                    "targetGroupCallsign".to_string(),
                    Value::String(target_callsign.clone()),
                ),
                (
                    "createdByUid".to_string(),
                    Value::String(seed.created_by_uid.clone()),
                ),
                (
                    "createdByName".to_string(),
                    Value::String(created_by_name.clone()),
                ),
                (
                    "sourceRequestId".to_string(),
                    Value::String(seed.request_id.clone()),
                ),
                (
                    "sourceRequestType".to_string(),
                    Value::String(seed.request_type.clone()),
                ),
                (
                    "sourceRequestTitle".to_string(),
                    Value::String(seed.request_title.clone()),
                ),
                (
                    "sourceRequestSummary".to_string(),
                    Value::String(seed.request_summary.clone()),
                ),
                (
                    "sourceRequestFields".to_string(),
                    seed.request_fields.to_value(),
                ),
                ("createdAt".to_string(), Value::from(seed.created_at)),
                ("note".to_string(), Value::String(seed.note.clone())),
                ("isDispatchOrder".to_string(), Value::Bool(true)),
            ]),
        };

        let assignment = CadRecord {
            fields: Map::from_iter([
                (
                    "groupId".to_string(),
                    Value::String(seed.assignee_group_id.clone()),
                ),
                (
                    "assigneeGroupCallsign".to_string(),
                    Value::String(assignee_callsign.clone()),
                ),
                (
                    "assignedByUid".to_string(),
                    Value::String(seed.created_by_uid.clone()),
                ),
                (
                    "assignedByName".to_string(),
                    Value::String(created_by_name.clone()),
                ),
                ("assignedAt".to_string(), Value::from(seed.created_at)),
                ("state".to_string(), Value::String("assigned".to_string())),
                ("note".to_string(), Value::String(seed.note)),
            ]),
        };

        let payload = CadDispatchOrderCreateSeed { order, assignment };
        self.create_order(
            serde_json::to_string(&payload)
                .map_err(|error| format!("Failed to serialize CAD order payload: {error}"))?,
        )
    }

    pub fn close_order(&self, entry_id: String) -> Result<CadDispatchOrderMutationResult, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let order = self
            .repository
            .get_order(&entry_id)?
            .ok_or_else(|| "CAD order could not be resolved.".to_string())?;
        let assignment = self.repository.get_assignment(&entry_id)?;

        self.repository.delete_order(&entry_id)?;
        self.repository.delete_assignment(&entry_id)?;

        Ok(CadDispatchOrderMutationResult {
            task_id: entry_id.clone(),
            order: order.to_value(),
            assignment: assignment.map_or(Value::Null, CadRecord::into_value),
            message: "Dispatch order closed.".to_string(),
            activity: Self::build_activity(
                "dispatch_order_closed",
                format!("{entry_id} was closed."),
                entry_id,
                Self::string_field(&order.fields, "groupId").unwrap_or_default(),
                String::new(),
            ),
        })
    }

    pub fn upsert_order(&self, entry_id: String, json_data: String) -> Result<(), String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let entry = Self::parse_record(&json_data)?;
        self.repository.save_order(entry_id, entry)
    }

    pub fn delete_order(&self, entry_id: String) -> Result<(), String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        self.repository.delete_order(&entry_id)
    }

    pub fn list_requests(&self) -> Result<Vec<Value>, String> {
        Ok(Self::records_to_values(self.repository.list_requests()?))
    }

    pub fn submit_request(&self, json_data: String) -> Result<CadRequestMutationResult, String> {
        let mut request = Self::parse_record(&json_data)?;
        let request_id = self.repository.next_request_id()?;
        request
            .fields
            .insert("requestId".to_string(), Value::String(request_id.clone()));
        self.repository.save_request(request_id, request.clone())?;
        Ok(CadRequestMutationResult {
            request: request.to_value(),
            message: "Support request submitted.".to_string(),
            activity: Self::build_activity(
                "support_request_submitted",
                format!(
                    "{} submitted {}.",
                    Self::string_field(&request.fields, "groupCallsign")
                        .unwrap_or_else(|| "Unknown Group".to_string()),
                    Self::string_field(&request.fields, "title")
                        .unwrap_or_else(|| "support request".to_string())
                ),
                Self::string_field(&request.fields, "requestId").unwrap_or_default(),
                Self::string_field(&request.fields, "groupId").unwrap_or_default(),
                Self::string_field(&request.fields, "submittedByUid").unwrap_or_default(),
            ),
        })
    }

    pub fn submit_request_from_context(
        &self,
        json_data: String,
    ) -> Result<CadRequestMutationResult, String> {
        let seed = serde_json::from_str::<CadSupportRequestSubmitSeed>(&json_data)
            .map_err(|error| format!("Invalid CAD support request context: {error}"))?;

        if seed.request_type.trim().is_empty() {
            return Err("Support request type is required.".to_string());
        }
        if seed.group_id.trim().is_empty() {
            return Err("Group ID is required.".to_string());
        }

        let request_type = seed.request_type.to_lowercase();
        let group_callsign = Self::fallback_string(&seed.group_callsign, &seed.group_id);
        let request = CadRecord {
            fields: Map::from_iter([
                ("type".to_string(), Value::String(request_type.clone())),
                (
                    "title".to_string(),
                    Value::String(Self::build_request_title(&request_type, &group_callsign)),
                ),
                (
                    "summary".to_string(),
                    Value::String(Self::build_request_summary(
                        &request_type,
                        &seed.fields.fields,
                        &group_callsign,
                    )),
                ),
                ("groupId".to_string(), Value::String(seed.group_id)),
                (
                    "groupCallsign".to_string(),
                    Value::String(group_callsign.clone()),
                ),
                (
                    "submittedByUid".to_string(),
                    Value::String(seed.submitted_by_uid),
                ),
                (
                    "submittedByName".to_string(),
                    Value::String(Self::fallback_string(
                        &seed.submitted_by_name,
                        &group_callsign,
                    )),
                ),
                ("fields".to_string(), seed.fields.into_value()),
                (
                    "priority".to_string(),
                    Value::String(Self::normalize_priority(&seed.priority)),
                ),
                ("position".to_string(), seed.position),
                ("createdAt".to_string(), Value::from(seed.created_at)),
            ]),
        };

        self.submit_request(
            serde_json::to_string(&request)
                .map_err(|error| format!("Failed to serialize CAD request payload: {error}"))?,
        )
    }

    pub fn close_request(&self, entry_id: String) -> Result<CadRequestMutationResult, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let request = self
            .repository
            .get_request(&entry_id)?
            .ok_or_else(|| "CAD request could not be resolved.".to_string())?;
        self.repository.delete_request(&entry_id)?;
        Ok(CadRequestMutationResult {
            request: request.to_value(),
            message: "Support request closed.".to_string(),
            activity: Self::build_activity(
                "support_request_closed",
                format!(
                    "{} was closed.",
                    Self::string_field(&request.fields, "title").unwrap_or(entry_id.clone())
                ),
                entry_id,
                Self::string_field(&request.fields, "groupId").unwrap_or_default(),
                String::new(),
            ),
        })
    }

    pub fn upsert_request(&self, entry_id: String, json_data: String) -> Result<(), String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let entry = Self::parse_record(&json_data)?;
        self.repository.save_request(entry_id, entry)
    }

    pub fn delete_request(&self, entry_id: String) -> Result<(), String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        self.repository.delete_request(&entry_id)
    }

    pub fn list_profiles(&self) -> Result<Vec<Value>, String> {
        Ok(Self::records_to_values(self.repository.list_profiles()?))
    }

    pub fn update_profile_from_context(
        &self,
        json_data: String,
    ) -> Result<CadGroupProfileMutationResult, String> {
        let seed = serde_json::from_str::<CadGroupProfileUpdateSeed>(&json_data)
            .map_err(|error| format!("Invalid CAD group profile context: {error}"))?;

        let group_id = Self::validate_entry_id(seed.group_id)?;
        let mode = if seed.mode.trim().is_empty() {
            "profile".to_string()
        } else {
            seed.mode.to_lowercase()
        };

        let current_role = Self::fallback_string(&seed.current_role, "infantry");
        let current_status = Self::fallback_string(&seed.current_status, "available");
        let final_role = if seed.role.trim().is_empty() {
            current_role.clone()
        } else {
            seed.role.to_lowercase()
        };
        let final_status = if seed.status.trim().is_empty() {
            current_status.clone()
        } else {
            seed.status.to_lowercase()
        };

        let changed = current_role != final_role || current_status != final_status;
        let callsign = Self::fallback_string(&seed.group_callsign, &group_id);

        let profile = if changed {
            let patch = CadRecord {
                fields: Map::from_iter([
                    ("groupId".to_string(), Value::String(group_id.clone())),
                    ("role".to_string(), Value::String(final_role.clone())),
                    ("status".to_string(), Value::String(final_status.clone())),
                ]),
            };
            let existing = self.repository.get_profile(&group_id)?.unwrap_or_default();
            let merged = existing.merge(patch);
            self.repository
                .save_profile(group_id.clone(), merged.clone())?;
            merged
        } else {
            CadRecord {
                fields: Map::from_iter([
                    ("groupId".to_string(), Value::String(group_id.clone())),
                    ("role".to_string(), Value::String(current_role.clone())),
                    ("status".to_string(), Value::String(current_status.clone())),
                ]),
            }
        };

        let message = if changed {
            match mode.as_str() {
                "status" => "Group status updated.".to_string(),
                "role" => "Group role updated.".to_string(),
                _ => "Group profile updated.".to_string(),
            }
        } else {
            match mode.as_str() {
                "status" => "Group status already up to date.".to_string(),
                "role" => "Group role already up to date.".to_string(),
                _ => "Group profile already up to date.".to_string(),
            }
        };

        let activity = if changed {
            match mode.as_str() {
                "status" => Self::build_activity(
                    "group_status",
                    format!(
                        "{} updated {} to {}.",
                        seed.requester_uid, callsign, final_status
                    ),
                    String::new(),
                    group_id.clone(),
                    seed.requester_uid.clone(),
                ),
                "role" => Self::build_activity(
                    "group_role",
                    format!(
                        "{} updated {} role to {}.",
                        seed.requester_uid, callsign, final_role
                    ),
                    String::new(),
                    group_id.clone(),
                    seed.requester_uid.clone(),
                ),
                _ => {
                    let mut parts = Vec::new();
                    if current_role != final_role {
                        parts.push(format!("role to {}", final_role));
                    }
                    if current_status != final_status {
                        parts.push(format!("status to {}", final_status));
                    }
                    Self::build_activity(
                        "group_profile",
                        format!(
                            "{} updated {} {}.",
                            seed.requester_uid,
                            callsign,
                            parts.join(" and ")
                        ),
                        String::new(),
                        group_id.clone(),
                        seed.requester_uid.clone(),
                    )
                }
            }
        } else {
            CadActivityEntry::default()
        };

        Ok(CadGroupProfileMutationResult {
            profile: profile.into_value(),
            message,
            activity,
            changed,
        })
    }

    pub fn build_groups(&self, json_data: String) -> Result<Vec<Value>, String> {
        let seed: CadGroupBuildSeed = serde_json::from_str(&json_data)
            .map_err(|error| format!("Invalid CAD group seed: {error}"))?;
        let profiles = self.repository.list_profiles()?;

        let mut groups = Vec::with_capacity(seed.live_groups.len());
        for group in seed.live_groups {
            let Some(mut entry) = Self::as_object_clone(&group) else {
                continue;
            };

            let group_id = Self::string_field(&entry, "groupId").unwrap_or_default();
            if group_id.is_empty() {
                continue;
            }

            if let Some(profile) = profiles.get(&group_id) {
                if let Some(role) = Self::string_field(&profile.fields, "role") {
                    entry.insert("role".to_string(), Value::String(role));
                }
                if let Some(status) = Self::string_field(&profile.fields, "status") {
                    entry.insert("status".to_string(), Value::String(status));
                }
            }

            groups.push(Value::Object(entry));
        }

        Ok(groups)
    }

    pub fn upsert_profile(&self, entry_id: String, json_data: String) -> Result<(), String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let entry = Self::parse_record(&json_data)?;
        self.repository.save_profile(entry_id, entry)
    }

    pub fn delete_profile(&self, entry_id: String) -> Result<(), String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        self.repository.delete_profile(&entry_id)
    }

    pub fn build_hydrate_payload(&self, json_data: String) -> Result<CadHydratePayload, String> {
        let seed: CadHydrateSeed = serde_json::from_str(&json_data)
            .map_err(|error| format!("Invalid CAD hydrate seed: {error}"))?;

        let assignments = self.repository.list_assignments()?;
        let dispatch_orders = self.repository.list_orders()?;
        let requests = self.repository.list_requests()?;
        let activity = self.repository.snapshot_activity()?;

        Ok(CadViewService::build_hydrate_payload(
            seed,
            assignments,
            dispatch_orders,
            requests,
            activity,
        ))
    }

    fn validate_entry_id(entry_id: String) -> Result<String, String> {
        if entry_id.trim().is_empty() {
            return Err("Entry ID is required.".to_string());
        }

        Ok(entry_id)
    }

    fn parse_value(json_data: &str) -> Result<Value, String> {
        serde_json::from_str::<Value>(json_data).map_err(|error| format!("Invalid JSON: {error}"))
    }

    fn parse_record(json_data: &str) -> Result<CadRecord, String> {
        serde_json::from_str::<CadRecord>(json_data)
            .map_err(|error| format!("Invalid CAD JSON: {error}"))
    }

    fn records_to_values(records: HashMap<String, CadRecord>) -> Vec<Value> {
        records.into_values().map(CadRecord::into_value).collect()
    }

    fn set_task_id(record: &mut CadRecord, task_id: &str) {
        let task_id_value = Value::String(task_id.to_string());
        record
            .fields
            .insert("taskId".to_string(), task_id_value.clone());
        record.fields.insert("taskID".to_string(), task_id_value);
    }

    fn build_activity(
        entry_type: &str,
        message: String,
        task_id: String,
        group_id: String,
        actor_uid: String,
    ) -> CadActivityEntry {
        CadActivityEntry {
            entry_type: entry_type.to_string(),
            message,
            task_id,
            group_id,
            actor_uid,
        }
    }

    fn display_group_name(record: &Map<String, Value>) -> String {
        Self::string_field(record, "groupCallsign")
            .or_else(|| Self::string_field(record, "assigneeGroupCallsign"))
            .or_else(|| Self::string_field(record, "groupId"))
            .unwrap_or_else(|| "assigned group".to_string())
    }

    fn normalize_priority(priority: &str) -> String {
        let normalized = priority.to_lowercase();
        if ["routine", "priority", "emergency"].contains(&normalized.as_str()) {
            normalized
        } else {
            "priority".to_string()
        }
    }

    fn fallback_string(value: &str, fallback: &str) -> String {
        if value.trim().is_empty() {
            fallback.to_string()
        } else {
            value.to_string()
        }
    }

    fn build_request_title(request_type: &str, group_callsign: &str) -> String {
        format!(
            "{} | {}",
            Self::format_request_type(request_type),
            group_callsign
        )
    }

    fn build_request_summary(
        request_type: &str,
        fields: &Map<String, Value>,
        group_callsign: &str,
    ) -> String {
        match request_type {
            "medevac_9line" => format!(
                "Pickup {} | Precedence {} | Security {}",
                Self::string_field(fields, "pickup_location")
                    .unwrap_or_else(|| "Unknown".to_string()),
                Self::string_field(fields, "precedence").unwrap_or_else(|| "unknown".to_string()),
                Self::string_field(fields, "security").unwrap_or_else(|| "unknown".to_string())
            ),
            "ace_lace" => format!(
                "Ammo {} | Casualties {} | Equipment {}",
                Self::string_field(fields, "ammo").unwrap_or_else(|| "unknown".to_string()),
                Self::string_field(fields, "casualties").unwrap_or_else(|| "unknown".to_string()),
                Self::string_field(fields, "equipment").unwrap_or_else(|| "unknown".to_string())
            ),
            "fire_support" => format!(
                "Target {} | Effect {} | Danger Close {}",
                Self::string_field(fields, "target_location")
                    .unwrap_or_else(|| "Unknown".to_string()),
                Self::string_field(fields, "requested_effect")
                    .unwrap_or_else(|| "unknown".to_string()),
                Self::string_field(fields, "danger_close").unwrap_or_else(|| "no".to_string())
            ),
            "air_support" => format!(
                "Target {} | Marking {} | Effect {}",
                Self::string_field(fields, "target_location")
                    .unwrap_or_else(|| "Unknown".to_string()),
                Self::string_field(fields, "target_marking")
                    .unwrap_or_else(|| "unknown".to_string()),
                Self::string_field(fields, "requested_effect")
                    .unwrap_or_else(|| "unknown".to_string())
            ),
            "logreq" => format!(
                "Category {} | Requested {} | Quantity {} | Delivery {} | Location {}",
                Self::string_field(fields, "category").unwrap_or_else(|| "mixed".to_string()),
                Self::string_field(fields, "requested_items")
                    .unwrap_or_else(|| "unspecified".to_string()),
                Self::string_field(fields, "quantity").unwrap_or_else(|| "unspecified".to_string()),
                Self::string_field(fields, "delivery_method")
                    .unwrap_or_else(|| "dispatch discretion".to_string()),
                Self::string_field(fields, "delivery_location")
                    .unwrap_or_else(|| "Unknown".to_string())
            ),
            _ => format!(
                "{} request from {}.",
                Self::format_request_type(request_type),
                group_callsign
            ),
        }
    }

    fn format_request_type(request_type: &str) -> String {
        match request_type {
            "medevac_9line" => "9-Line MEDEVAC".to_string(),
            "ace_lace" => "ACE/LACE".to_string(),
            "fire_support" => "Fire Support".to_string(),
            "air_support" => "Air Support".to_string(),
            "logreq" => "LOGREQ".to_string(),
            _ => request_type.to_string(),
        }
    }

    fn as_object_clone(value: &Value) -> Option<Map<String, Value>> {
        value.as_object().cloned()
    }

    fn string_field(object: &Map<String, Value>, key: &str) -> Option<String> {
        object.get(key)?.as_str().map(ToString::to_string)
    }
}

pub struct CadViewService;

impl CadViewService {
    pub fn build_hydrate_payload(
        seed: CadHydrateSeed,
        assignments: HashMap<String, CadRecord>,
        dispatch_orders: HashMap<String, CadRecord>,
        requests: HashMap<String, CadRecord>,
        activity: Vec<Value>,
    ) -> CadHydratePayload {
        let groups = seed.groups.clone();
        let contracts = Self::build_contracts(
            &seed.active_tasks,
            &groups,
            &seed.session,
            &assignments,
            &dispatch_orders,
        );
        let requests = Self::build_requests(&seed.session, &requests);
        let assignments = assignments
            .into_values()
            .map(CadRecord::into_value)
            .collect();
        let activity = Self::build_activity(activity);

        CadHydratePayload {
            groups,
            contracts,
            requests,
            assignments,
            activity,
            session: seed.session,
        }
    }

    fn build_contracts(
        active_tasks: &[Value],
        groups: &[Value],
        session: &CadSession,
        assignments: &HashMap<String, CadRecord>,
        dispatch_orders: &HashMap<String, CadRecord>,
    ) -> Vec<Value> {
        let mut contracts = Vec::new();

        for task in active_tasks {
            let Some(mut entry) = Self::as_object_clone(task) else {
                continue;
            };

            let task_id = Self::string_field(&entry, "taskID")
                .or_else(|| Self::string_field(&entry, "taskId"))
                .unwrap_or_default();
            if task_id.is_empty() {
                continue;
            }

            let assignment = assignments.get(&task_id).map(|value| &value.fields);
            let assigned_group_id = assignment
                .and_then(|value| Self::string_field(value, "groupId"))
                .unwrap_or_default();
            let assignment_state = assignment
                .and_then(|value| Self::string_field(value, "state"))
                .unwrap_or_else(|| "unassigned".to_string());

            if !session.is_dispatcher
                && (assigned_group_id.is_empty() || assigned_group_id != session.group_id)
            {
                continue;
            }

            entry.insert("taskId".to_string(), Value::String(task_id));
            entry.insert(
                "assignedGroupId".to_string(),
                Value::String(assigned_group_id),
            );
            entry.insert(
                "assignmentState".to_string(),
                Value::String(assignment_state),
            );
            contracts.push(Value::Object(entry));
        }

        for (task_id, order) in dispatch_orders {
            let assignment = assignments.get(task_id).map(|value| &value.fields);
            let assigned_group_id = assignment
                .and_then(|value| Self::string_field(value, "groupId"))
                .unwrap_or_default();
            let assignment_state = assignment
                .and_then(|value| Self::string_field(value, "state"))
                .unwrap_or_else(|| "unassigned".to_string());

            if !session.is_dispatcher
                && (assigned_group_id.is_empty() || assigned_group_id != session.group_id)
            {
                continue;
            }

            let mut entry = order.fields.clone();
            if let Some(target_group_id) = Self::string_field(&entry, "targetGroupId")
                && let Some(target_group) = groups.iter().find_map(|group| {
                    let object = Self::as_object_ref(group)?;
                    (Self::string_field(object, "groupId").unwrap_or_default() == target_group_id)
                        .then_some(object)
                })
            {
                if let Some(callsign) = Self::string_field(target_group, "callsign") {
                    entry.insert(
                        "targetGroupCallsign".to_string(),
                        Value::String(callsign.clone()),
                    );
                    entry.insert(
                        "title".to_string(),
                        Value::String(format!("Backup {callsign}")),
                    );
                }

                if let Some(position) = target_group.get("position") {
                    entry.insert("position".to_string(), position.clone());
                }

                if Self::string_field(&entry, "note")
                    .unwrap_or_default()
                    .is_empty()
                    && let Some(callsign) = Self::string_field(&entry, "targetGroupCallsign")
                {
                    entry.insert(
                        "description".to_string(),
                        Value::String(format!(
                            "Dispatch order to back up {callsign} at its current position."
                        )),
                    );
                }
            }

            entry.insert("taskId".to_string(), Value::String(task_id.clone()));
            entry.insert("taskID".to_string(), Value::String(task_id.clone()));
            entry.insert("isDispatchOrder".to_string(), Value::Bool(true));
            entry.insert(
                "assignedGroupId".to_string(),
                Value::String(assigned_group_id),
            );
            entry.insert(
                "assignmentState".to_string(),
                Value::String(assignment_state),
            );
            contracts.push(Value::Object(entry));
        }

        contracts
    }

    fn build_requests(session: &CadSession, requests: &HashMap<String, CadRecord>) -> Vec<Value> {
        let mut filtered: Vec<(f64, Value)> = requests
            .values()
            .filter_map(|request| {
                let object = &request.fields;
                let group_id = Self::string_field(object, "groupId").unwrap_or_default();
                if !session.is_dispatcher && group_id != session.group_id {
                    return None;
                }

                let created_at = Self::number_field(object, "createdAt").unwrap_or_default();
                Some((created_at, request.to_value()))
            })
            .collect();

        filtered.sort_by(|(left, _), (right, _)| {
            right.partial_cmp(left).unwrap_or(std::cmp::Ordering::Equal)
        });
        filtered.into_iter().map(|(_, value)| value).collect()
    }

    fn build_activity(mut activity: Vec<Value>) -> Vec<Value> {
        if activity.len() > CAD_RECENT_ACTIVITY_LIMIT {
            let drain_count = activity.len() - CAD_RECENT_ACTIVITY_LIMIT;
            activity.drain(0..drain_count);
        }

        activity
    }

    fn as_object_ref(value: &Value) -> Option<&Map<String, Value>> {
        value.as_object()
    }

    fn as_object_clone(value: &Value) -> Option<Map<String, Value>> {
        value.as_object().cloned()
    }

    fn string_field(object: &Map<String, Value>, key: &str) -> Option<String> {
        object.get(key)?.as_str().map(ToString::to_string)
    }

    fn number_field(object: &Map<String, Value>, key: &str) -> Option<f64> {
        object.get(key)?.as_f64()
    }
}

#[cfg(test)]
mod tests {
    use super::CadStateService;
    use forge_repositories::{CadRepository, InMemoryCadRepository};
    use serde_json::Value;

    #[test]
    fn create_order_assigns_shared_task_id() {
        let repository = InMemoryCadRepository::new();
        let service = CadStateService::new(repository.clone());

        let result = service
            .create_order(
                r#"{
                    "order": {"type":"dispatch_order","targetGroupId":"alpha"},
                    "assignment": {"groupId":"bravo","state":"assigned"}
                }"#
                .to_string(),
            )
            .expect("create order should succeed");

        assert_eq!(result.task_id, "cad-order:1");

        let stored_order = repository
            .get_order(&result.task_id)
            .expect("get order should succeed")
            .expect("order should exist");
        let stored_assignment = repository
            .get_assignment(&result.task_id)
            .expect("get assignment should succeed")
            .expect("assignment should exist");

        assert_eq!(
            stored_order.fields.get("taskId"),
            Some(&Value::String(result.task_id.clone()))
        );
        assert_eq!(
            stored_assignment.fields.get("taskId"),
            Some(&Value::String(result.task_id))
        );
    }

    #[test]
    fn create_order_from_context_persists_source_request_metadata() {
        let repository = InMemoryCadRepository::new();
        let service = CadStateService::new(repository.clone());

        let result = service
            .create_order_from_context(
                r#"{
                    "assigneeGroupId": "bravo",
                    "assigneeGroupCallsign": "Bravo 1-1",
                    "targetGroupId": "alpha",
                    "targetGroupCallsign": "Alpha 1-1",
                    "targetPosition": [1000, 2000, 0],
                    "createdByUid": "dispatcher-1",
                    "createdByName": "Dispatch",
                    "requestId": "cad-request:7",
                    "requestType": "logreq",
                    "requestTitle": "LOGREQ | Alpha 1-1",
                    "requestSummary": "Category ammo | Requested MX rifle ammo",
                    "requestFields": {
                        "category": "ammo",
                        "requested_items": "MX rifle ammo",
                        "quantity": "4 crates"
                    },
                    "note": "LOGREQ requested by Alpha 1-1. Requested Items MX rifle ammo | Quantity 4 crates",
                    "priority": "priority",
                    "createdAt": 123.45
                }"#
                .to_string(),
            )
            .expect("create order from context should succeed");

        let stored_order = repository
            .get_order(&result.task_id)
            .expect("get order should succeed")
            .expect("order should exist");

        assert_eq!(
            stored_order.fields.get("sourceRequestId"),
            Some(&Value::String("cad-request:7".to_string()))
        );
        assert_eq!(
            stored_order.fields.get("sourceRequestType"),
            Some(&Value::String("logreq".to_string()))
        );
        assert_eq!(
            stored_order.fields.get("sourceRequestFields"),
            Some(&serde_json::json!({
                "category": "ammo",
                "requested_items": "MX rifle ammo",
                "quantity": "4 crates"
            }))
        );
    }

    #[test]
    fn decline_assignment_returns_record_and_removes_state() {
        let repository = InMemoryCadRepository::new();
        let service = CadStateService::new(repository.clone());

        service
            .assign_assignment(
                "task-1".to_string(),
                r#"{"groupId":"alpha","state":"assigned"}"#.to_string(),
            )
            .expect("assign should succeed");

        let declined = service
            .decline_assignment(
                "task-1".to_string(),
                r#"{"state":"declined","declinedAt":123}"#.to_string(),
            )
            .expect("decline should succeed");

        assert_eq!(
            declined.assignment.get("state").and_then(Value::as_str),
            Some("declined")
        );
        assert!(
            repository
                .get_assignment("task-1")
                .expect("get assignment should succeed")
                .is_none()
        );
    }

    #[test]
    fn submit_request_from_context_accepts_scalar_created_at() {
        let repository = InMemoryCadRepository::new();
        let service = CadStateService::new(repository);

        let result = service
            .submit_request_from_context(
                r#"{
                    "type": "medevac_9line",
                    "fields": {"pickup_location":"1000 2000"},
                    "groupId": "alpha",
                    "groupCallsign": "Alpha 1-1",
                    "submittedByUid": "uid-1",
                    "submittedByName": "Leader",
                    "priority": "emergency",
                    "position": [1000, 2000, 0],
                    "createdAt": 123.45
                }"#
                .to_string(),
            )
            .expect("submit request should accept scalar createdAt");

        assert_eq!(
            result.request.get("createdAt").and_then(Value::as_f64),
            Some(123.45)
        );
    }
}
