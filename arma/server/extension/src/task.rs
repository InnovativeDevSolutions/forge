//! Task hot-state operations for the Arma 3 server extension.
//!
//! The extension owns portable task metadata while SQF keeps Arma-only runtime
//! state such as entity references and participant tracking.
//!
//! This state is intentionally transient and is reset during server task-store
//! initialization so tasks start clean for each server or mission lifecycle.

use arma_rs::Group;
use forge_repositories::InMemoryTaskRepository;
use forge_services::TaskStateService;
use serde::Serialize;
use std::sync::LazyLock;

static TASK_SERVICE: LazyLock<TaskStateService<InMemoryTaskRepository>> =
    LazyLock::new(|| TaskStateService::new(InMemoryTaskRepository::new()));

pub fn group() -> Group {
    Group::new()
        .command("reset", reset)
        .group(
            "catalog",
            Group::new()
                .command("active", list_active_catalog)
                .command("get", get_catalog_entry)
                .command("upsert", upsert_catalog_entry)
                .command("delete", delete_catalog_entry),
        )
        .group(
            "ownership",
            Group::new()
                .command("bind", bind_ownership)
                .command("release", release_ownership)
                .command("accept", accept_task)
                .command("reward_context", reward_context),
        )
        .group(
            "status",
            Group::new()
                .command("set", set_status)
                .command("get", get_status)
                .command("clear", clear_status),
        )
        .group(
            "defuse",
            Group::new()
                .command("increment", increment_defuse_count)
                .command("get", get_defuse_count),
        )
        .command("clear", clear_task)
}

pub(crate) fn list_active_catalog() -> String {
    serialize_json(TASK_SERVICE.list_active_catalog())
}

pub(crate) fn reset() -> String {
    serialize_json(TASK_SERVICE.reset())
}

pub(crate) fn get_catalog_entry(entry_id: String) -> String {
    serialize_json(TASK_SERVICE.get_catalog_entry(entry_id))
}

pub(crate) fn upsert_catalog_entry(entry_id: String, json_data: String) -> String {
    serialize_json(TASK_SERVICE.upsert_catalog_entry(entry_id, json_data))
}

pub(crate) fn delete_catalog_entry(entry_id: String) -> String {
    serialize_ok(TASK_SERVICE.delete_catalog_entry(entry_id))
}

pub(crate) fn bind_ownership(entry_id: String, json_data: String) -> String {
    serialize_json(TASK_SERVICE.bind_ownership(entry_id, json_data))
}

pub(crate) fn release_ownership(entry_id: String) -> String {
    serialize_json(TASK_SERVICE.release_ownership(entry_id))
}

pub(crate) fn accept_task(entry_id: String, json_data: String) -> String {
    serialize_json(TASK_SERVICE.accept_task(entry_id, json_data))
}

pub(crate) fn reward_context(entry_id: String) -> String {
    serialize_json(TASK_SERVICE.get_reward_context(entry_id))
}

pub(crate) fn set_status(entry_id: String, status: String) -> String {
    serialize_json(TASK_SERVICE.set_status(entry_id, status))
}

pub(crate) fn get_status(entry_id: String) -> String {
    serialize_json(TASK_SERVICE.get_status(entry_id))
}

pub(crate) fn clear_status(entry_id: String) -> String {
    serialize_json(TASK_SERVICE.clear_status(entry_id))
}

pub(crate) fn increment_defuse_count(entry_id: String) -> String {
    serialize_json(TASK_SERVICE.increment_defuse_count(entry_id))
}

pub(crate) fn get_defuse_count(entry_id: String) -> String {
    serialize_json(TASK_SERVICE.get_defuse_count(entry_id))
}

pub(crate) fn clear_task(entry_id: String) -> String {
    serialize_json(TASK_SERVICE.clear_task(entry_id))
}

fn serialize_json<T: Serialize>(result: Result<T, String>) -> String {
    match result {
        Ok(value) => serde_json::to_string(&value)
            .unwrap_or_else(|error| format!("Error: Failed to serialize task state: {error}")),
        Err(error) => format!("Error: {error}"),
    }
}

fn serialize_ok(result: Result<(), String>) -> String {
    match result {
        Ok(()) => "true".to_string(),
        Err(error) => format!("Error: {error}"),
    }
}
