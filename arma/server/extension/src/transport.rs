//! Shared transport helpers for oversized extension requests and responses.
//!
//! This module provides a routed invoke path that accepts JSON-encoded string
//! arguments, supports request staging for large payloads, and stores oversized
//! responses in memory for chunked retrieval by SQF.

use arma_rs::{CallContext, Group};
use serde::Serialize;
use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{LazyLock, Mutex as StdMutex};

mod routes;

use routes::route_command;

const CHUNK_PREFIX: &str = "FORGE_TRANSPORT_CHUNK:";
const RESPONSE_CHUNK_SIZE: usize = 12_000;

static REQUEST_STORE: LazyLock<StdMutex<HashMap<String, String>>> =
    LazyLock::new(|| StdMutex::new(HashMap::new()));
static RESPONSE_STORE: LazyLock<StdMutex<HashMap<String, Vec<String>>>> =
    LazyLock::new(|| StdMutex::new(HashMap::new()));
static TRANSFER_SEQUENCE: AtomicU64 = AtomicU64::new(1);

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct ChunkEnvelope {
    transfer_id: String,
    chunk_count: usize,
    total_size: usize,
}

pub fn group() -> Group {
    Group::new()
        .command("invoke", invoke)
        .command("invoke_stored", invoke_stored)
        .group(
            "request",
            Group::new()
                .command("append", append_request_chunk)
                .command("clear", clear_request_chunks),
        )
        .group(
            "response",
            Group::new()
                .command("get", get_response_chunk)
                .command("clear", clear_response_chunks),
        )
}

fn append_request_chunk(transfer_id: String, chunk: String) -> String {
    let mut store = REQUEST_STORE.lock().unwrap();
    store.entry(transfer_id).or_default().push_str(&chunk);
    "OK".to_string()
}

fn clear_request_chunks(transfer_id: String) -> String {
    REQUEST_STORE.lock().unwrap().remove(&transfer_id);
    "OK".to_string()
}

fn get_response_chunk(transfer_id: String, index: String) -> String {
    let chunk_index = match index.parse::<usize>() {
        Ok(value) => value,
        Err(error) => return format!("Error: Invalid response chunk index: {error}"),
    };

    let store = RESPONSE_STORE.lock().unwrap();
    let Some(chunks) = store.get(&transfer_id) else {
        return format!("Error: Response transfer '{transfer_id}' was not found");
    };

    chunks.get(chunk_index).cloned().unwrap_or_else(|| {
        format!(
            "Error: Response chunk {} was not found for '{}'",
            chunk_index, transfer_id
        )
    })
}

fn clear_response_chunks(transfer_id: String) -> String {
    RESPONSE_STORE.lock().unwrap().remove(&transfer_id);
    "OK".to_string()
}

fn invoke(call_context: CallContext, function_name: String, arguments_json: String) -> String {
    invoke_internal(call_context, function_name, arguments_json)
}

fn invoke_stored(call_context: CallContext, function_name: String, transfer_id: String) -> String {
    let Some(arguments_json) = REQUEST_STORE.lock().unwrap().remove(&transfer_id) else {
        return format!("Error: Request transfer '{transfer_id}' was not found");
    };

    invoke_internal(call_context, function_name, arguments_json)
}

fn invoke_internal(
    call_context: CallContext,
    function_name: String,
    arguments_json: String,
) -> String {
    let arguments: Vec<String> = match parse_transport_arguments(&arguments_json) {
        Ok(value) => value,
        Err(error) => return format!("Error: Invalid transport arguments JSON: {error}"),
    };

    let result = match route_command(call_context, &function_name, arguments) {
        Ok(value) => value,
        Err(error) => format!("Error: {error}"),
    };

    chunk_response_if_needed(result)
}

fn parse_transport_arguments(arguments_json: &str) -> Result<Vec<String>, String> {
    let value: serde_json::Value =
        serde_json::from_str(arguments_json).map_err(|error| error.to_string())?;
    parse_transport_argument_value(value)
}

fn parse_transport_argument_value(value: serde_json::Value) -> Result<Vec<String>, String> {
    match value {
        serde_json::Value::Array(values) => Ok(values
            .into_iter()
            .map(|entry| match entry {
                serde_json::Value::String(string_value) => string_value,
                other => other.to_string(),
            })
            .collect()),
        serde_json::Value::String(value) => {
            let trimmed = value.trim();
            if (trimmed.starts_with('[') || trimmed.starts_with('{') || trimmed.eq("null"))
                && let Ok(nested_value) = serde_json::from_str::<serde_json::Value>(trimmed)
            {
                return parse_transport_argument_value(nested_value);
            }

            Ok(vec![value])
        }
        serde_json::Value::Null => Ok(Vec::new()),
        other => Err(format!("expected string or array but received {}", other)),
    }
}

fn chunk_response_if_needed(result: String) -> String {
    if result.len() <= RESPONSE_CHUNK_SIZE {
        return result;
    }

    let transfer_id = next_transfer_id("rsp");
    let chunks = split_string_chunks(&result, RESPONSE_CHUNK_SIZE);
    let envelope = ChunkEnvelope {
        transfer_id: transfer_id.clone(),
        chunk_count: chunks.len(),
        total_size: result.len(),
    };

    RESPONSE_STORE.lock().unwrap().insert(transfer_id, chunks);

    format!(
        "{CHUNK_PREFIX}{}",
        serde_json::to_string(&envelope)
            .unwrap_or_else(|error| format!("{{\"error\":\"{error}\"}}"))
    )
}

fn next_transfer_id(prefix: &str) -> String {
    let sequence = TRANSFER_SEQUENCE.fetch_add(1, Ordering::Relaxed);
    format!("{prefix}_{sequence}")
}

fn split_string_chunks(input: &str, max_bytes: usize) -> Vec<String> {
    if input.is_empty() {
        return vec![String::new()];
    }

    let mut chunks = Vec::new();
    let mut chunk_start = 0usize;
    let mut chunk_len = 0usize;

    for (index, character) in input.char_indices() {
        let char_len = character.len_utf8();
        if chunk_len > 0 && chunk_len + char_len > max_bytes {
            chunks.push(input[chunk_start..index].to_string());
            chunk_start = index;
            chunk_len = 0;
        }

        chunk_len += char_len;
    }

    chunks.push(input[chunk_start..].to_string());
    chunks
}
