use forge_models::{DispatchRecord, DispatchRequestMutationResult, DispatchRequestSubmitSeed};
use forge_repositories::DispatchRepository;
use serde_json::{Map, Value};

const DISPATCH_ACTIVITY_LIMIT: usize = 200;
const DISPATCH_RECENT_ACTIVITY_DEFAULT: usize = 50;
const VALID_REQUEST_TYPES: [&str; 5] = [
    "medevac_9line",
    "ace_lace",
    "fire_support",
    "air_support",
    "logreq",
];

/// Hot state for the dispatch addon: support requests submitted by groups and
/// the recent dispatch activity feed. Dispatch orders are task catalog entries
/// and live in the task service, not here.
pub struct DispatchStateService<R: DispatchRepository> {
    repository: R,
}

impl<R: DispatchRepository> DispatchStateService<R> {
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    pub fn append_activity(&self, json_data: String) -> Result<(), String> {
        let entry = serde_json::from_str::<Value>(&json_data)
            .map_err(|error| format!("Invalid dispatch activity JSON: {error}"))?;
        if !entry.is_object() {
            return Err("Dispatch activity entry must be an object.".to_string());
        }
        self.repository.append_activity(entry)
    }

    pub fn recent_activity(&self, limit: String) -> Result<Vec<Value>, String> {
        let limit = limit
            .trim()
            .parse::<usize>()
            .ok()
            .filter(|value| *value > 0)
            .unwrap_or(DISPATCH_RECENT_ACTIVITY_DEFAULT)
            .min(DISPATCH_ACTIVITY_LIMIT);
        self.repository.recent_activity(limit)
    }

    /// Open requests, newest first.
    pub fn list_requests(&self) -> Result<Vec<Value>, String> {
        let mut requests: Vec<(f64, Value)> = self
            .repository
            .list_requests()?
            .into_values()
            .map(|request| {
                let created_at = request
                    .fields
                    .get("createdAt")
                    .and_then(Value::as_f64)
                    .unwrap_or_default();
                (created_at, request.into_value())
            })
            .collect();
        requests.sort_by(|(left, _), (right, _)| {
            right.partial_cmp(left).unwrap_or(std::cmp::Ordering::Equal)
        });
        Ok(requests.into_iter().map(|(_, value)| value).collect())
    }

    pub fn get_request(&self, entry_id: String) -> Result<Option<Value>, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        Ok(self
            .repository
            .get_request(&entry_id)?
            .map(DispatchRecord::into_value))
    }

    pub fn submit_request(
        &self,
        json_data: String,
    ) -> Result<DispatchRequestMutationResult, String> {
        let seed = serde_json::from_str::<DispatchRequestSubmitSeed>(&json_data)
            .map_err(|error| format!("Invalid dispatch request JSON: {error}"))?;

        let request_type = seed.request_type.trim().to_lowercase();
        if !VALID_REQUEST_TYPES.contains(&request_type.as_str()) {
            return Err("Invalid support request type.".to_string());
        }
        if seed.group_id.trim().is_empty() {
            return Err("Group ID is required.".to_string());
        }

        let request_id = self.repository.next_request_id()?;
        let callsign = Self::fallback(&seed.group_callsign, &seed.group_id);
        let request = DispatchRecord {
            fields: Map::from_iter([
                ("requestId".to_string(), Value::String(request_id.clone())),
                ("type".to_string(), Value::String(request_type.clone())),
                (
                    "title".to_string(),
                    Value::String(format!(
                        "{} | {callsign}",
                        Self::format_request_type(&request_type)
                    )),
                ),
                (
                    "summary".to_string(),
                    Value::String(Self::build_request_summary(
                        &request_type,
                        &seed.fields.fields,
                        &callsign,
                    )),
                ),
                ("groupId".to_string(), Value::String(seed.group_id)),
                ("groupCallsign".to_string(), Value::String(callsign.clone())),
                (
                    "submittedByUid".to_string(),
                    Value::String(seed.submitted_by_uid),
                ),
                (
                    "submittedByName".to_string(),
                    Value::String(Self::fallback(&seed.submitted_by_name, &callsign)),
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

        self.repository.save_request(request_id, request.clone())?;
        Ok(DispatchRequestMutationResult {
            request: request.into_value(),
            message: "Support request submitted.".to_string(),
        })
    }

    pub fn close_request(&self, entry_id: String) -> Result<DispatchRequestMutationResult, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let request = self
            .repository
            .get_request(&entry_id)?
            .ok_or_else(|| "Support request could not be resolved.".to_string())?;
        self.repository.delete_request(&entry_id)?;
        Ok(DispatchRequestMutationResult {
            request: request.into_value(),
            message: "Support request closed.".to_string(),
        })
    }

    fn validate_entry_id(entry_id: String) -> Result<String, String> {
        if entry_id.trim().is_empty() {
            return Err("Entry ID is required.".to_string());
        }
        Ok(entry_id)
    }

    fn fallback(value: &str, fallback: &str) -> String {
        if value.trim().is_empty() {
            fallback.to_string()
        } else {
            value.to_string()
        }
    }

    fn normalize_priority(priority: &str) -> String {
        let normalized = priority.to_lowercase();
        if ["routine", "priority", "emergency"].contains(&normalized.as_str()) {
            normalized
        } else {
            "priority".to_string()
        }
    }

    fn field(fields: &Map<String, Value>, key: &str, fallback: &str) -> String {
        fields
            .get(key)
            .and_then(Value::as_str)
            .unwrap_or(fallback)
            .to_string()
    }

    fn build_request_summary(
        request_type: &str,
        fields: &Map<String, Value>,
        group_callsign: &str,
    ) -> String {
        let f = |key: &str, fallback: &str| Self::field(fields, key, fallback);
        match request_type {
            "medevac_9line" => format!(
                "Pickup {} | Precedence {} | Security {}",
                f("pickup_location", "Unknown"),
                f("precedence", "unknown"),
                f("security", "unknown")
            ),
            "ace_lace" => format!(
                "Ammo {} | Casualties {} | Equipment {}",
                f("ammo", "unknown"),
                f("casualties", "unknown"),
                f("equipment", "unknown")
            ),
            "fire_support" => format!(
                "Target {} | Effect {} | Danger Close {}",
                f("target_location", "Unknown"),
                f("requested_effect", "unknown"),
                f("danger_close", "no")
            ),
            "air_support" => format!(
                "Target {} | Marking {} | Effect {}",
                f("target_location", "Unknown"),
                f("target_marking", "unknown"),
                f("requested_effect", "unknown")
            ),
            "logreq" => format!(
                "Category {} | Requested {} | Quantity {} | Delivery {} | Location {}",
                f("category", "mixed"),
                f("requested_items", "unspecified"),
                f("quantity", "unspecified"),
                f("delivery_method", "dispatch discretion"),
                f("delivery_location", "Unknown")
            ),
            _ => format!(
                "{} request from {group_callsign}.",
                Self::format_request_type(request_type)
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
}

#[cfg(test)]
mod tests {
    use super::DispatchStateService;
    use forge_repositories::InMemoryDispatchRepository;
    use serde_json::Value;

    fn service() -> DispatchStateService<InMemoryDispatchRepository> {
        DispatchStateService::new(InMemoryDispatchRepository::new())
    }

    #[test]
    fn submit_request_builds_title_and_summary() {
        let service = service();
        let result = service
            .submit_request(
                r#"{"type":"medevac_9line","groupId":"grp:1","groupCallsign":"Alpha","fields":{"pickup_location":"123456","precedence":"urgent"},"priority":"EMERGENCY","createdAt":12.5}"#
                    .to_string(),
            )
            .expect("submit should succeed");

        assert_eq!(
            result.request.get("title").and_then(Value::as_str),
            Some("9-Line MEDEVAC | Alpha")
        );
        assert_eq!(
            result.request.get("priority").and_then(Value::as_str),
            Some("emergency")
        );
        assert!(
            result
                .request
                .get("summary")
                .and_then(Value::as_str)
                .unwrap_or_default()
                .contains("Pickup 123456")
        );
    }

    #[test]
    fn submit_request_rejects_unknown_type() {
        let result = service().submit_request(r#"{"type":"pizza","groupId":"grp:1"}"#.to_string());
        assert!(result.is_err());
    }

    #[test]
    fn close_request_removes_it() {
        let service = service();
        let request = service
            .submit_request(r#"{"type":"logreq","groupId":"grp:1"}"#.to_string())
            .expect("submit should succeed")
            .request;
        let request_id = request
            .get("requestId")
            .and_then(Value::as_str)
            .unwrap()
            .to_string();

        service
            .close_request(request_id.clone())
            .expect("close should succeed");
        assert!(service.list_requests().unwrap().is_empty());
        assert!(service.close_request(request_id).is_err());
    }

    #[test]
    fn list_requests_is_newest_first() {
        let service = service();
        service
            .submit_request(r#"{"type":"logreq","groupId":"grp:1","createdAt":1}"#.to_string())
            .unwrap();
        service
            .submit_request(r#"{"type":"logreq","groupId":"grp:2","createdAt":5}"#.to_string())
            .unwrap();

        let requests = service.list_requests().unwrap();
        assert_eq!(
            requests[0].get("groupId").and_then(Value::as_str),
            Some("grp:2")
        );
    }

    #[test]
    fn recent_activity_is_capped_to_limit() {
        let service = service();
        for index in 0..5 {
            service
                .append_activity(format!(r#"{{"message":"entry {index}"}}"#))
                .unwrap();
        }

        let recent = service.recent_activity("2".to_string()).unwrap();
        assert_eq!(recent.len(), 2);
        assert_eq!(
            recent[1].get("message").and_then(Value::as_str),
            Some("entry 4")
        );
    }
}
