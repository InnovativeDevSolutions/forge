//! CAD hot-state operations for the Arma 3 server extension.
//!
//! The extension owns the in-memory CAD state store, while the shared service
//! layer handles mutation rules and hydrate shaping. This keeps the extension
//! surface thin and aligned with the workspace architecture.
//!
//! CAD state is intentionally transient operational state. It follows the
//! active server or mission lifecycle and is not treated as durable player or
//! organization persistence.

use arma_rs::Group;
use forge_repositories::InMemoryCadRepository;
use forge_services::CadStateService;
use serde::Serialize;
use std::sync::LazyLock;

static CAD_SERVICE: LazyLock<CadStateService<InMemoryCadRepository>> =
    LazyLock::new(|| CadStateService::new(InMemoryCadRepository::new()));

pub fn group() -> Group {
    Group::new()
        .group(
            "activity",
            Group::new()
                .command("append", append_activity)
                .command("recent", recent_activity),
        )
        .group(
            "assignments",
            Group::new()
                .command("list", list_assignments)
                .command("assign", assign_assignment)
                .command("acknowledge", acknowledge_assignment)
                .command("decline", decline_assignment)
                .command("upsert", upsert_assignment)
                .command("delete", delete_assignment),
        )
        .group(
            "orders",
            Group::new()
                .command("list", list_orders)
                .command("create", create_order)
                .command("create_from_context", create_order_from_context)
                .command("close", close_order)
                .command("upsert", upsert_order)
                .command("delete", delete_order),
        )
        .group(
            "requests",
            Group::new()
                .command("list", list_requests)
                .command("submit", submit_request)
                .command("submit_from_context", submit_request_from_context)
                .command("close", close_request)
                .command("upsert", upsert_request)
                .command("delete", delete_request),
        )
        .group(
            "profiles",
            Group::new()
                .command("list", list_profiles)
                .command("update_from_context", update_profile_from_context)
                .command("upsert", upsert_profile)
                .command("delete", delete_profile),
        )
        .group("groups", Group::new().command("build", build_groups))
        .group("view", Group::new().command("hydrate", hydrate_view))
}

pub(crate) fn append_activity(json_data: String) -> String {
    serialize_ok(CAD_SERVICE.append_activity(json_data))
}

pub(crate) fn recent_activity(limit: String) -> String {
    serialize_json(CAD_SERVICE.recent_activity(limit))
}

pub(crate) fn list_assignments() -> String {
    serialize_json(CAD_SERVICE.list_assignments())
}

pub(crate) fn assign_assignment(entry_id: String, json_data: String) -> String {
    serialize_json(CAD_SERVICE.assign_assignment(entry_id, json_data))
}

pub(crate) fn acknowledge_assignment(entry_id: String, json_data: String) -> String {
    serialize_json(CAD_SERVICE.acknowledge_assignment(entry_id, json_data))
}

pub(crate) fn decline_assignment(entry_id: String, json_data: String) -> String {
    serialize_json(CAD_SERVICE.decline_assignment(entry_id, json_data))
}

pub(crate) fn upsert_assignment(entry_id: String, json_data: String) -> String {
    serialize_ok(CAD_SERVICE.upsert_assignment(entry_id, json_data))
}

pub(crate) fn delete_assignment(entry_id: String) -> String {
    serialize_ok(CAD_SERVICE.delete_assignment(entry_id))
}

pub(crate) fn list_orders() -> String {
    serialize_json(CAD_SERVICE.list_orders())
}

pub(crate) fn create_order(json_data: String) -> String {
    serialize_json(CAD_SERVICE.create_order(json_data))
}

pub(crate) fn create_order_from_context(json_data: String) -> String {
    serialize_json(CAD_SERVICE.create_order_from_context(json_data))
}

pub(crate) fn close_order(entry_id: String) -> String {
    serialize_json(CAD_SERVICE.close_order(entry_id))
}

pub(crate) fn upsert_order(entry_id: String, json_data: String) -> String {
    serialize_ok(CAD_SERVICE.upsert_order(entry_id, json_data))
}

pub(crate) fn delete_order(entry_id: String) -> String {
    serialize_ok(CAD_SERVICE.delete_order(entry_id))
}

pub(crate) fn list_requests() -> String {
    serialize_json(CAD_SERVICE.list_requests())
}

pub(crate) fn submit_request(json_data: String) -> String {
    serialize_json(CAD_SERVICE.submit_request(json_data))
}

pub(crate) fn submit_request_from_context(json_data: String) -> String {
    serialize_json(CAD_SERVICE.submit_request_from_context(json_data))
}

pub(crate) fn close_request(entry_id: String) -> String {
    serialize_json(CAD_SERVICE.close_request(entry_id))
}

pub(crate) fn upsert_request(entry_id: String, json_data: String) -> String {
    serialize_ok(CAD_SERVICE.upsert_request(entry_id, json_data))
}

pub(crate) fn delete_request(entry_id: String) -> String {
    serialize_ok(CAD_SERVICE.delete_request(entry_id))
}

pub(crate) fn list_profiles() -> String {
    serialize_json(CAD_SERVICE.list_profiles())
}

pub(crate) fn update_profile_from_context(json_data: String) -> String {
    serialize_json(CAD_SERVICE.update_profile_from_context(json_data))
}

pub(crate) fn upsert_profile(entry_id: String, json_data: String) -> String {
    serialize_ok(CAD_SERVICE.upsert_profile(entry_id, json_data))
}

pub(crate) fn delete_profile(entry_id: String) -> String {
    serialize_ok(CAD_SERVICE.delete_profile(entry_id))
}

pub(crate) fn build_groups(json_data: String) -> String {
    serialize_json(CAD_SERVICE.build_groups(json_data))
}

pub(crate) fn hydrate_view(json_data: String) -> String {
    serialize_json(CAD_SERVICE.build_hydrate_payload(json_data))
}

fn serialize_ok(result: Result<(), String>) -> String {
    match result {
        Ok(()) => "OK".to_string(),
        Err(error) => format!("Error: {error}"),
    }
}

fn serialize_json<T: Serialize>(result: Result<T, String>) -> String {
    match result {
        Ok(value) => serde_json::to_string(&value)
            .unwrap_or_else(|error| format!("Error: Failed to serialize CAD state: {error}")),
        Err(error) => format!("Error: {error}"),
    }
}
