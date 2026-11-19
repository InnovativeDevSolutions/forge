//! HTTP client for the forge-webapi standalone API.
//!
//! The bridge: repository implementations in `storage/` that talk to
//! the API instead of SurrealDB use this client. It is a native HTTP
//! client (reqwest) running on the extension's global Tokio runtime —
//! no browser-style CORS preflight applies here, so the API's
//! `arma://` Origin echo is irrelevant on this path; SQF's own
//! `webRequest` calls are the ones that go through preflight.
//!
//! Requests are synchronous from the caller's point of view (the
//! repository traits are sync): each method blocks on the runtime,
//! exactly like the SurrealDB helpers in `storage/common.rs`.
//!
//! ## Auth (parked)
//!
//! Auth is parked (Jacob, 2026-11-19): the API is unauthenticated for
//! now, so the bridge sends no credentials. When the API issues
//! tokens, [`ApiClient::auth_token`] is the single place that needs to
//! change — it will return the token and every request will carry
//! `Authorization: Bearer <token>`.

use arma_rs::Group;
use forge_models::{Garage, Locker, VGarage, VLocker};
use reqwest::StatusCode;
use serde_json::Value as JsonValue;
use std::time::Duration;

use crate::RUNTIME;
use crate::config::ApiConfig;
use crate::log::log;

/// The API's error body shape: `{ "error": "<message>" }`.
fn api_error_message(body: &JsonValue) -> String {
    body.get("error")
        .and_then(|value| value.as_str())
        .map(|message| message.to_string())
        .unwrap_or_else(|| "unknown API error".to_string())
}

/// Require a 2xx status; otherwise report the API's own error message.
pub(crate) fn require_success(
    method: &str,
    path: &str,
    status: StatusCode,
    body: JsonValue,
) -> Result<JsonValue, String> {
    if status.is_success() {
        Ok(body)
    } else {
        Err(format!(
            "forge-webapi {} {} failed ({}): {}",
            method,
            path,
            status.as_u16(),
            api_error_message(&body)
        ))
    }
}

/// Percent-encode one URL path segment (everything outside the
/// unreserved set). UIDs are Steam IDs and classnames are usually
/// plain ASCII, but encoding keeps odd classnames from breaking the
/// request line.
pub(crate) fn encode_segment(segment: &str) -> String {
    let mut encoded = String::with_capacity(segment.len());
    for byte in segment.as_bytes() {
        match byte {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' => {
                encoded.push(*byte as char)
            }
            _ => encoded.push_str(&format!("%{:02X}", byte)),
        }
    }
    encoded
}

/// Rename `hit_points` to `hitPoints` in every vehicle of a garage
/// `vehicles` map (the API's `Vehicle` is camelCase, the model's is
/// snake_case). Operates in place; non-object input is left alone.
fn vehicles_to_api(vehicles: &mut JsonValue) {
    if let Some(map) = vehicles.as_object_mut() {
        for vehicle in map.values_mut() {
            rename_key(vehicle, "hit_points", "hitPoints");
        }
    }
}

/// Inverse of [`vehicles_to_api`]: `hitPoints` back to `hit_points`.
fn vehicles_from_api(vehicles: &mut JsonValue) {
    if let Some(map) = vehicles.as_object_mut() {
        for vehicle in map.values_mut() {
            rename_key(vehicle, "hitPoints", "hit_points");
        }
    }
}

fn rename_key(value: &mut JsonValue, from: &str, to: &str) {
    if let Some(object) = value.as_object_mut()
        && let Some(field) = object.remove(from)
    {
        object.insert(to.to_string(), field);
    }
}

/// Serialize a model [`Garage`] into the API's `PUT /players/{uid}/garage`
/// body (`{ "vehicles": ... }` with camelCase `hitPoints`).
pub(crate) fn garage_to_api_body(garage: &Garage) -> Result<JsonValue, String> {
    let mut value = serde_json::to_value(garage)
        .map_err(|error| format!("Failed to serialize garage for forge-webapi: {error}"))?;
    if let Some(vehicles) = value.get_mut("vehicles") {
        vehicles_to_api(vehicles);
    }
    Ok(value)
}

/// Deserialize an API garage record (`{ uid, vehicles }`) into the model
/// [`Garage`].
pub(crate) fn garage_from_api_record(mut record: JsonValue) -> Result<Garage, String> {
    if let Some(vehicles) = record.get_mut("vehicles") {
        vehicles_from_api(vehicles);
    }
    if let Some(object) = record.as_object_mut() {
        object.remove("uid");
    }
    serde_json::from_value(record)
        .map_err(|error| format!("forge-webapi garage decode failed: {error}"))
}

/// Serialize a model [`Locker`] into the API's `PUT /players/{uid}/locker`
/// body (`{ "items": ... }`). Field names already match; no renaming.
pub(crate) fn locker_to_api_body(locker: &Locker) -> Result<JsonValue, String> {
    serde_json::to_value(locker)
        .map_err(|error| format!("Failed to serialize locker for forge-webapi: {error}"))
}

/// Deserialize an API locker record (`{ uid, items }`) into the model
/// [`Locker`].
pub(crate) fn locker_from_api_record(mut record: JsonValue) -> Result<Locker, String> {
    if let Some(object) = record.as_object_mut() {
        object.remove("uid");
    }
    serde_json::from_value(record)
        .map_err(|error| format!("forge-webapi locker decode failed: {error}"))
}

/// Deserialize an API virtual-garage record (`{ uid, cars, armor, ... }`)
/// into the model [`VGarage`]. Field names already match.
pub(crate) fn vgarage_from_api_record(mut record: JsonValue) -> Result<VGarage, String> {
    if let Some(object) = record.as_object_mut() {
        object.remove("uid");
    }
    serde_json::from_value(record)
        .map_err(|error| format!("forge-webapi virtual garage decode failed: {error}"))
}

/// Deserialize an API virtual-locker record (`{ uid, items, ... }`) into
/// the model [`VLocker`]. Field names already match.
pub(crate) fn vlocker_from_api_record(mut record: JsonValue) -> Result<VLocker, String> {
    if let Some(object) = record.as_object_mut() {
        object.remove("uid");
    }
    serde_json::from_value(record)
        .map_err(|error| format!("forge-webapi virtual locker decode failed: {error}"))
}

/// Blocking HTTP client for forge-webapi.
///
/// Cheap to clone (the underlying reqwest client is reference-counted);
/// one instance is held per API repository.
#[derive(Debug, Clone)]
pub struct ApiClient {
    client: reqwest::Client,
    base_url: String,
}

impl ApiClient {
    /// Build a client from explicit API config.
    pub fn from_config(config: &ApiConfig) -> Result<Self, String> {
        let timeout = Duration::from_millis(config.timeout_ms.unwrap_or(5000));
        let client = reqwest::Client::builder()
            .timeout(timeout)
            .build()
            .map_err(|error| format!("Failed to build forge-webapi HTTP client: {error}"))?;
        Ok(Self {
            client,
            base_url: config.base_url.trim_end_matches('/').to_string(),
        })
    }

    /// Build a client from the loaded extension config (`[api]`).
    pub fn configured() -> Result<Self, String> {
        Self::from_config(&crate::config::load().api)
    }

    fn url(&self, path: &str) -> String {
        format!("{}{}", self.base_url, path)
    }

    /// Bearer token for the API, once auth exists. Auth is parked, so
    /// this is `None` today and requests go out unauthenticated,
    /// exactly like the API's own endpoints.
    ///
    /// TODO(auth): return the player/server token here (issued by the
    /// API after the in-game login screen lands) so every bridge
    /// request carries `Authorization: Bearer <token>`.
    fn auth_token(&self) -> Option<String> {
        None
    }

    fn with_auth(&self, request: reqwest::RequestBuilder) -> reqwest::RequestBuilder {
        match self.auth_token() {
            Some(token) => request.header("Authorization", format!("Bearer {token}")),
            None => request,
        }
    }

    async fn execute(request: reqwest::RequestBuilder) -> Result<(StatusCode, JsonValue), String> {
        let response = request
            .send()
            .await
            .map_err(|error| format!("forge-webapi request failed: {error}"))?;
        let status = response.status();
        let text = response
            .text()
            .await
            .map_err(|error| format!("forge-webapi response read failed: {error}"))?;
        let trimmed = text.trim();
        if trimmed.is_empty() {
            return Ok((status, JsonValue::Null));
        }
        serde_json::from_str(trimmed)
            .map(|value| (status, value))
            .map_err(|error| format!("forge-webapi returned invalid JSON: {error}"))
    }

    /// `GET <path>` → `(status, parsed JSON body)`.
    pub fn get(&self, path: &str) -> Result<(StatusCode, JsonValue), String> {
        let request = self.with_auth(self.client.get(self.url(path)));
        RUNTIME.block_on(async move { Self::execute(request).await })
    }

    /// `POST <path>` with an optional JSON body.
    pub fn post(
        &self,
        path: &str,
        body: Option<JsonValue>,
    ) -> Result<(StatusCode, JsonValue), String> {
        let mut request = self.with_auth(self.client.post(self.url(path)));
        if let Some(body) = body {
            request = request.json(&body);
        }
        RUNTIME.block_on(async move { Self::execute(request).await })
    }

    /// `PUT <path>` with an optional JSON body.
    pub fn put(
        &self,
        path: &str,
        body: Option<JsonValue>,
    ) -> Result<(StatusCode, JsonValue), String> {
        let mut request = self.with_auth(self.client.put(self.url(path)));
        if let Some(body) = body {
            request = request.json(&body);
        }
        RUNTIME.block_on(async move { Self::execute(request).await })
    }

    /// `DELETE <path>`.
    pub fn delete(&self, path: &str) -> Result<(StatusCode, JsonValue), String> {
        let request = self.with_auth(self.client.delete(self.url(path)));
        RUNTIME.block_on(async move { Self::execute(request).await })
    }

    /// `GET /health` — the API's liveness probe. The body is
    /// `{ "status": "ok", "database": "connected" | "unavailable" }`.
    pub fn health(&self) -> Result<JsonValue, String> {
        let (status, body) = self.get("/health")?;
        require_success("GET", "/health", status, body)
    }
}

/// `api status` — reports the bridge's view of the API: `disabled`
/// (bridge off), `connected (database: …)`, or `unavailable: <reason>`.
/// Intended for SQF polling before issuing operations that need the API.
pub fn status() -> String {
    let config = crate::config::load();
    if !config.api.enabled {
        return "disabled".to_string();
    }
    match ApiClient::from_config(&config.api).and_then(|client| client.health()) {
        Ok(body) => {
            let database = body
                .get("database")
                .and_then(|value| value.as_str())
                .unwrap_or("?");
            log("api", "DEBUG", &format!("forge-webapi health: {body}"));
            format!("connected (database: {database})")
        }
        Err(error) => format!("unavailable: {error}"),
    }
}

/// Creates the Arma 3 command group for forge-webapi bridge operations.
///
/// Registers commands: `status`.
pub fn group() -> Group {
    Group::new().command("status", status)
}
