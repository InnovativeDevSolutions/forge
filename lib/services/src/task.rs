use forge_models::{
    TaskOwnershipContext, TaskOwnershipMutationResult, TaskRecord, TaskRewardContext,
};
use forge_repositories::TaskRepository;
use serde_json::Value;

pub struct TaskStateService<R: TaskRepository> {
    repository: R,
}

impl<R: TaskRepository> TaskStateService<R> {
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    pub fn reset(&self) -> Result<bool, String> {
        self.repository.reset()?;
        Ok(true)
    }

    pub fn upsert_catalog_entry(
        &self,
        entry_id: String,
        json_data: String,
    ) -> Result<TaskRecord, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let mut entry = Self::parse_record(&json_data)?;
        Self::normalize_catalog_entry(&mut entry, &entry_id);
        self.repository
            .save_catalog_entry(entry_id, entry.clone())?;
        Ok(entry)
    }

    pub fn get_catalog_entry(&self, entry_id: String) -> Result<Option<Value>, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        self.repository
            .get_catalog_entry(&entry_id)
            .map(|entry| entry.map(TaskRecord::into_value))
    }

    pub fn delete_catalog_entry(&self, entry_id: String) -> Result<(), String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        self.repository.delete_catalog_entry(&entry_id)
    }

    pub fn list_active_catalog(&self) -> Result<Vec<Value>, String> {
        let catalog = self.repository.list_catalog()?;
        let active_statuses = self.repository.list_active_statuses()?;
        let mut active_entries = Vec::new();

        for (task_id, status) in active_statuses {
            if !matches!(status.as_str(), "available" | "assigned" | "active") {
                continue;
            }

            let Some(entry) = catalog.get(&task_id) else {
                continue;
            };

            let mut entry = entry.fields.clone();
            entry.insert("taskId".to_string(), Value::String(task_id.clone()));
            entry.insert("taskID".to_string(), Value::String(task_id));
            entry.insert("status".to_string(), Value::String(status));
            active_entries.push(Value::Object(entry));
        }

        Ok(active_entries)
    }

    pub fn bind_ownership(
        &self,
        entry_id: String,
        json_data: String,
    ) -> Result<TaskOwnershipMutationResult, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let mut ownership = Self::parse_ownership_context(&json_data)?;
        if ownership.org_id.trim().is_empty() {
            ownership.org_id = "default".to_string();
        }

        self.repository
            .save_ownership(entry_id.clone(), ownership.clone())?;
        let accepted = !ownership.requester_uid.trim().is_empty();
        let entry = self.patch_catalog_ownership(
            &entry_id,
            accepted,
            &ownership.requester_uid,
            &ownership.org_id,
        )?;

        Ok(TaskOwnershipMutationResult {
            task_id: entry_id,
            requester_uid: ownership.requester_uid,
            org_id: ownership.org_id,
            entry,
            message: "Task ownership updated.".to_string(),
        })
    }

    pub fn release_ownership(
        &self,
        entry_id: String,
    ) -> Result<TaskOwnershipMutationResult, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let ownership = self
            .repository
            .get_ownership(&entry_id)?
            .unwrap_or_default();
        self.repository.delete_ownership(&entry_id)?;
        let entry = self.patch_catalog_ownership(&entry_id, false, "", "default")?;

        Ok(TaskOwnershipMutationResult {
            task_id: entry_id,
            requester_uid: ownership.requester_uid,
            org_id: ownership.org_id,
            entry,
            message: "Task ownership released.".to_string(),
        })
    }

    pub fn accept_task(
        &self,
        entry_id: String,
        json_data: String,
    ) -> Result<TaskOwnershipMutationResult, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let ownership = Self::parse_ownership_context(&json_data)?;
        if ownership.requester_uid.trim().is_empty() {
            return Err("Missing task ID or requester UID.".to_string());
        }

        if !matches!(
            self.get_status(entry_id.clone())?.as_str(),
            "assigned" | "active"
        ) {
            return Err("Task is not assigned or active.".to_string());
        }

        if let Some(existing) = self.repository.get_ownership(&entry_id)?
            && !existing.requester_uid.trim().is_empty()
            && existing.requester_uid != ownership.requester_uid
        {
            return Err("Task has already been accepted.".to_string());
        }

        let mut result = self.bind_ownership(
            entry_id,
            serde_json::to_string(&ownership)
                .map_err(|error| format!("Failed to serialize task ownership: {error}"))?,
        )?;
        result.message = "Task accepted.".to_string();
        Ok(result)
    }

    pub fn set_status(&self, entry_id: String, status: String) -> Result<bool, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let final_status = Self::validate_status(status)?;
        self.repository
            .set_active_status(entry_id.clone(), final_status.clone())?;
        if matches!(final_status.as_str(), "succeeded" | "failed") {
            self.repository
                .set_completed_status(entry_id, final_status)?;
        } else {
            self.repository.delete_completed_status(&entry_id)?;
        }

        Ok(true)
    }

    pub fn get_status(&self, entry_id: String) -> Result<String, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        if let Some(status) = self.repository.get_active_status(&entry_id)? {
            return Ok(status);
        }

        Ok(self
            .repository
            .get_completed_status(&entry_id)?
            .unwrap_or_default())
    }

    pub fn clear_status(&self, entry_id: String) -> Result<bool, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        self.repository.delete_active_status(&entry_id)?;
        self.repository.delete_completed_status(&entry_id)?;
        Ok(true)
    }

    pub fn get_reward_context(&self, entry_id: String) -> Result<TaskRewardContext, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        let ownership = self
            .repository
            .get_ownership(&entry_id)?
            .unwrap_or_default();
        Ok(TaskRewardContext {
            requester_uid: ownership.requester_uid,
            org_id: ownership.org_id,
        })
    }

    pub fn increment_defuse_count(&self, entry_id: String) -> Result<u64, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        self.repository.increment_defuse_count(&entry_id)
    }

    pub fn get_defuse_count(&self, entry_id: String) -> Result<u64, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        self.repository.get_defuse_count(&entry_id)
    }

    pub fn clear_task(&self, entry_id: String) -> Result<bool, String> {
        let entry_id = Self::validate_entry_id(entry_id)?;
        self.repository.delete_catalog_entry(&entry_id)?;
        self.repository.delete_ownership(&entry_id)?;
        self.repository.delete_active_status(&entry_id)?;
        self.repository.delete_completed_status(&entry_id)?;
        self.repository.clear_defuse_count(&entry_id)?;
        Ok(true)
    }

    fn patch_catalog_ownership(
        &self,
        entry_id: &str,
        accepted: bool,
        requester_uid: &str,
        org_id: &str,
    ) -> Result<Value, String> {
        let Some(mut entry) = self.repository.get_catalog_entry(entry_id)? else {
            return Ok(Value::Null);
        };

        entry
            .fields
            .insert("accepted".to_string(), Value::Bool(accepted));
        entry.fields.insert(
            "requesterUid".to_string(),
            Value::String(requester_uid.to_string()),
        );
        entry
            .fields
            .insert("orgID".to_string(), Value::String(org_id.to_string()));
        Self::normalize_catalog_entry(&mut entry, entry_id);
        self.repository
            .save_catalog_entry(entry_id.to_string(), entry.clone())?;
        Ok(entry.into_value())
    }

    fn normalize_catalog_entry(entry: &mut TaskRecord, entry_id: &str) {
        let fields = &mut entry.fields;
        fields
            .entry("accepted".to_string())
            .or_insert(Value::Bool(false));
        fields
            .entry("requesterUid".to_string())
            .or_insert(Value::String(String::new()));
        fields
            .entry("orgID".to_string())
            .or_insert(Value::String("default".to_string()));
        fields
            .entry("taskId".to_string())
            .or_insert(Value::String(entry_id.to_string()));
        fields
            .entry("taskID".to_string())
            .or_insert(Value::String(entry_id.to_string()));
    }

    fn validate_entry_id(entry_id: String) -> Result<String, String> {
        if entry_id.trim().is_empty() {
            return Err("Task ID is required.".to_string());
        }

        Ok(entry_id)
    }

    fn validate_status(status: String) -> Result<String, String> {
        if status.trim().is_empty() {
            return Err("Task status is required.".to_string());
        }

        Ok(status)
    }

    fn parse_record(json_data: &str) -> Result<TaskRecord, String> {
        serde_json::from_str::<TaskRecord>(json_data)
            .map_err(|error| format!("Invalid task JSON: {error}"))
    }

    fn parse_ownership_context(json_data: &str) -> Result<TaskOwnershipContext, String> {
        serde_json::from_str::<TaskOwnershipContext>(json_data)
            .map_err(|error| format!("Invalid task ownership JSON: {error}"))
    }
}

#[cfg(test)]
mod tests {
    use super::TaskStateService;
    use forge_repositories::{InMemoryTaskRepository, TaskRepository};
    use serde_json::Value;

    #[test]
    fn bind_ownership_updates_catalog_entry() {
        let repository = InMemoryTaskRepository::new();
        let service = TaskStateService::new(repository.clone());

        service
            .upsert_catalog_entry("task-1".to_string(), r#"{"title":"Attack"}"#.to_string())
            .expect("catalog upsert should succeed");

        let result = service
            .bind_ownership(
                "task-1".to_string(),
                r#"{"requesterUid":"uid-1","orgId":"org-1"}"#.to_string(),
            )
            .expect("bind should succeed");

        assert_eq!(result.requester_uid, "uid-1");
        assert_eq!(result.org_id, "org-1");
        assert_eq!(
            result.entry.get("accepted").and_then(Value::as_bool),
            Some(true)
        );

        let stored = repository
            .get_catalog_entry("task-1")
            .expect("catalog lookup should succeed")
            .expect("catalog entry should exist");
        assert_eq!(
            stored.fields.get("requesterUid").and_then(Value::as_str),
            Some("uid-1")
        );
    }

    #[test]
    fn bind_ownership_without_requester_does_not_accept_task() {
        let repository = InMemoryTaskRepository::new();
        let service = TaskStateService::new(repository.clone());

        service
            .upsert_catalog_entry("task-1".to_string(), r#"{"title":"Hostage"}"#.to_string())
            .expect("catalog upsert should succeed");

        let result = service
            .bind_ownership(
                "task-1".to_string(),
                r#"{"requesterUid":"","orgId":"default"}"#.to_string(),
            )
            .expect("bind should succeed");

        assert_eq!(result.requester_uid, "");
        assert_eq!(result.org_id, "default");
        assert_eq!(
            result.entry.get("accepted").and_then(Value::as_bool),
            Some(false)
        );

        let stored = repository
            .get_catalog_entry("task-1")
            .expect("catalog lookup should succeed")
            .expect("catalog entry should exist");
        assert_eq!(
            stored.fields.get("requesterUid").and_then(Value::as_str),
            Some("")
        );
    }

    #[test]
    fn get_status_falls_back_to_completed_status() {
        let repository = InMemoryTaskRepository::new();
        let service = TaskStateService::new(repository.clone());

        service
            .set_status("task-1".to_string(), "failed".to_string())
            .expect("status update should succeed");
        repository
            .delete_active_status("task-1")
            .expect("active status delete should succeed");

        assert_eq!(
            service
                .get_status("task-1".to_string())
                .expect("status lookup should succeed"),
            "failed"
        );
    }

    #[test]
    fn list_active_catalog_returns_assignable_and_active_entries() {
        let service = TaskStateService::new(InMemoryTaskRepository::new());

        service
            .upsert_catalog_entry(
                "task-available".to_string(),
                r#"{"title":"Available"}"#.to_string(),
            )
            .expect("available catalog upsert should succeed");
        service
            .upsert_catalog_entry(
                "task-assigned".to_string(),
                r#"{"title":"Assigned"}"#.to_string(),
            )
            .expect("assigned catalog upsert should succeed");
        service
            .upsert_catalog_entry(
                "task-active".to_string(),
                r#"{"title":"Active"}"#.to_string(),
            )
            .expect("active catalog upsert should succeed");
        service
            .upsert_catalog_entry("task-done".to_string(), r#"{"title":"Done"}"#.to_string())
            .expect("done catalog upsert should succeed");
        service
            .set_status("task-available".to_string(), "available".to_string())
            .expect("available status update should succeed");
        service
            .set_status("task-assigned".to_string(), "assigned".to_string())
            .expect("assigned status update should succeed");
        service
            .set_status("task-active".to_string(), "active".to_string())
            .expect("active status update should succeed");
        service
            .set_status("task-done".to_string(), "succeeded".to_string())
            .expect("done status update should succeed");

        let active_catalog = service
            .list_active_catalog()
            .expect("active catalog should build");

        let task_ids: Vec<_> = active_catalog
            .iter()
            .filter_map(|entry| entry.get("taskId").and_then(Value::as_str))
            .collect();

        assert_eq!(active_catalog.len(), 3);
        assert!(task_ids.contains(&"task-available"));
        assert!(task_ids.contains(&"task-assigned"));
        assert!(task_ids.contains(&"task-active"));
    }
}
