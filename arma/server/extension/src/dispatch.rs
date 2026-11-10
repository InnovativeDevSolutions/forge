//! Dispatch hot-state operations for the Arma 3 server extension.
//!
//! Holds support requests and the recent dispatch activity feed for the
//! `forge_server_dispatch` addon. Dispatch orders are task catalog entries and
//! live in the task module. State is transient and follows the server or
//! mission lifecycle.

use arma_rs::Group;
use forge_repositories::InMemoryDispatchRepository;
use forge_services::DispatchStateService;
use serde::Serialize;
use std::sync::LazyLock;

static DISPATCH_SERVICE: LazyLock<DispatchStateService<InMemoryDispatchRepository>> =
    LazyLock::new(|| DispatchStateService::new(InMemoryDispatchRepository::new()));

pub fn group() -> Group {
    Group::new()
        .group(
            "activity",
            Group::new()
                .command("append", append_activity)
                .command("recent", recent_activity),
        )
        .group(
            "requests",
            Group::new()
                .command("list", list_requests)
                .command("get", get_request)
                .command("submit", submit_request)
                .command("close", close_request),
        )
}

pub(crate) fn append_activity(json_data: String) -> String {
    match DISPATCH_SERVICE.append_activity(json_data) {
        Ok(()) => "OK".to_string(),
        Err(error) => format!("Error: {error}"),
    }
}

pub(crate) fn recent_activity(limit: String) -> String {
    serialize_json(DISPATCH_SERVICE.recent_activity(limit))
}

pub(crate) fn list_requests() -> String {
    serialize_json(DISPATCH_SERVICE.list_requests())
}

pub(crate) fn get_request(entry_id: String) -> String {
    serialize_json(DISPATCH_SERVICE.get_request(entry_id))
}

pub(crate) fn submit_request(json_data: String) -> String {
    serialize_json(DISPATCH_SERVICE.submit_request(json_data))
}

pub(crate) fn close_request(entry_id: String) -> String {
    serialize_json(DISPATCH_SERVICE.close_request(entry_id))
}

fn serialize_json<T: Serialize>(result: Result<T, String>) -> String {
    match result {
        Ok(value) => serde_json::to_string(&value)
            .unwrap_or_else(|error| format!("Error: Failed to serialize dispatch state: {error}")),
        Err(error) => format!("Error: {error}"),
    }
}
