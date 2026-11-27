//! HTTP client for the forge-webapi standalone API.
//!
//! The API is the extension's only persistence backend: the
//! repository implementations in `storage/` talk to it. There is no
//! fallback: if the API client cannot be built, repositories fail
//! loudly on every operation.
//!
//! It is a native HTTP client (reqwest) running on the extension's
//! global Tokio runtime — no browser-style CORS preflight applies
//! here, so the API's `arma://` Origin echo is irrelevant on this
//! path; SQF's own `webRequest` calls are the ones that go through
//! preflight.
//!
//! Requests are synchronous from the caller's point of view (the
//! repository traits are sync): each method blocks on the runtime.
//! Persistence writes run in background tasks
//! (`enqueue_persistence_task`), so this does not block the game.
//!
//! ## Auth (parked)
//!
//! Auth is parked (Jacob, 2026-11-19): the API is unauthenticated for
//! now, so the bridge sends no credentials. When the API issues
//! tokens, [`ApiClient::auth_token`] is the single place that needs to
//! change — it will return the token and every request will carry
//! `Authorization: Bearer <token>`.

use arma_rs::Group;
use forge_models::{
    Actor, Bank, CreditLineSummary, Garage, Locker, MemberSummary, Org, OrgAssetEntry,
    OrgFleetEntry, OrgInviteRecord, PhonePayload, VGarage, VLocker,
};
use reqwest::StatusCode;
use serde_json::Value as JsonValue;
use std::collections::HashMap;
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

/// Serialize a model [`Bank`] into the API's `PUT /players/{uid}/bank`
/// body. Field names are single words on both sides; no renaming.
pub(crate) fn bank_to_api_body(bank: &Bank) -> Result<JsonValue, String> {
    serde_json::to_value(bank)
        .map_err(|error| format!("Failed to serialize bank for forge-webapi: {error}"))
}

/// Deserialize an API bank record into the model [`Bank`].
pub(crate) fn bank_from_api_record(record: JsonValue) -> Result<Bank, String> {
    serde_json::from_value(record)
        .map_err(|error| format!("forge-webapi bank decode failed: {error}"))
}

/// Serialize a model [`Actor`] into the API's actor body: the API is
/// camelCase, so the model's `phone_number` becomes `phoneNumber`.
pub(crate) fn actor_to_api_body(actor: &Actor) -> Result<JsonValue, String> {
    let mut value = serde_json::to_value(actor)
        .map_err(|error| format!("Failed to serialize actor for forge-webapi: {error}"))?;
    rename_key(&mut value, "phone_number", "phoneNumber");
    Ok(value)
}

/// Deserialize an API actor record (`phoneNumber`) into the model
/// [`Actor`] (`phone_number`).
pub(crate) fn actor_from_api_record(mut record: JsonValue) -> Result<Actor, String> {
    rename_key(&mut record, "phoneNumber", "phone_number");
    serde_json::from_value(record)
        .map_err(|error| format!("forge-webapi actor decode failed: {error}"))
}

/// Rename the snake_case fields of one credit line to the API's
/// camelCase (`approved_amount` → `approvedAmount`, and so on).
/// `uid`, `name` and `amount` are already identical.
fn credit_line_to_api(value: &mut JsonValue) {
    rename_key(value, "approved_amount", "approvedAmount");
    rename_key(value, "available_amount", "availableAmount");
    rename_key(value, "outstanding_principal", "outstandingPrincipal");
    rename_key(value, "interest_rate", "interestRate");
    rename_key(value, "amount_due", "amountDue");
}

/// Inverse of [`credit_line_to_api`].
fn credit_line_from_api(value: &mut JsonValue) {
    rename_key(value, "approvedAmount", "approved_amount");
    rename_key(value, "availableAmount", "available_amount");
    rename_key(value, "outstandingPrincipal", "outstanding_principal");
    rename_key(value, "interestRate", "interest_rate");
    rename_key(value, "amountDue", "amount_due");
}

/// Apply [`credit_line_to_api`] to every entry of a `creditLines` map.
fn credit_lines_to_api(map: &mut JsonValue) {
    if let Some(object) = map.as_object_mut() {
        for value in object.values_mut() {
            credit_line_to_api(value);
        }
    }
}

/// Apply [`credit_line_from_api`] to every entry of a `creditLines` map.
fn credit_lines_from_api(map: &mut JsonValue) {
    if let Some(object) = map.as_object_mut() {
        for value in object.values_mut() {
            credit_line_from_api(value);
        }
    }
}

/// An API org record split back into the extension's shapes: the core
/// [`Org`] plus the collections the API persists alongside it.
pub(crate) struct ApiOrgRecord {
    pub org: Org,
    pub members: HashMap<String, MemberSummary>,
    pub assets: HashMap<String, HashMap<String, OrgAssetEntry>>,
    pub fleet: HashMap<String, OrgFleetEntry>,
    pub pending_invites: HashMap<String, OrgInviteRecord>,
}

fn object_or_empty(value: Option<&JsonValue>) -> JsonValue {
    value
        .cloned()
        .unwrap_or_else(|| JsonValue::Object(serde_json::Map::new()))
}

/// Serialize a whole org record for the API's `PUT /orgs/{id}`: the
/// core [`Org`] plus members, assets, fleet, credit lines (translated
/// to camelCase) and pending invites. `PUT` is full-replace, so callers
/// that only change one collection must read the current record first
/// and pass the rest back unchanged.
pub(crate) fn org_to_api_body(
    org: &Org,
    members: &HashMap<String, MemberSummary>,
    assets: &HashMap<String, HashMap<String, OrgAssetEntry>>,
    fleet: &HashMap<String, OrgFleetEntry>,
    pending_invites: &HashMap<String, OrgInviteRecord>,
) -> Result<JsonValue, String> {
    let mut credit_lines = serde_json::to_value(&org.credit_lines).map_err(|error| {
        format!("Failed to serialize org credit lines for forge-webapi: {error}")
    })?;
    credit_lines_to_api(&mut credit_lines);
    Ok(serde_json::json!({
        "orgId": org.id,
        "owner": org.owner,
        "name": org.name,
        "funds": org.funds,
        "reputation": org.reputation,
        "creditLines": credit_lines,
        "assets": assets,
        "fleet": fleet,
        "members": members,
        "pendingInvites": pending_invites,
    }))
}

/// Deserialize an API org record into an [`ApiOrgRecord`]: `orgId`
/// back to the core [`Org`]'s `id`, camelCase `creditLines` back to
/// snake_case, and the collections as the model types.
pub(crate) fn org_from_api_record(record: JsonValue) -> Result<ApiOrgRecord, String> {
    let decode_error =
        |error: serde_json::Error| format!("forge-webapi org decode failed: {error}");
    let mut credit_lines = object_or_empty(record.get("creditLines"));
    credit_lines_from_api(&mut credit_lines);
    let credit_lines: HashMap<String, CreditLineSummary> =
        serde_json::from_value(credit_lines).map_err(decode_error)?;
    let mut org = Org {
        id: record
            .get("orgId")
            .and_then(|value| value.as_str())
            .unwrap_or_default()
            .to_string(),
        owner: record
            .get("owner")
            .and_then(|value| value.as_str())
            .unwrap_or_default()
            .to_string(),
        name: record
            .get("name")
            .and_then(|value| value.as_str())
            .unwrap_or_default()
            .to_string(),
        funds: record
            .get("funds")
            .and_then(|value| value.as_f64())
            .unwrap_or_default(),
        reputation: record
            .get("reputation")
            .and_then(|value| value.as_i64())
            .unwrap_or_default(),
        credit_lines,
    };
    org.normalize_credit_lines();
    let members: HashMap<String, MemberSummary> =
        serde_json::from_value(object_or_empty(record.get("members"))).map_err(decode_error)?;
    let assets: HashMap<String, HashMap<String, OrgAssetEntry>> =
        serde_json::from_value(object_or_empty(record.get("assets"))).map_err(decode_error)?;
    let fleet: HashMap<String, OrgFleetEntry> =
        serde_json::from_value(object_or_empty(record.get("fleet"))).map_err(decode_error)?;
    let pending_invites: HashMap<String, OrgInviteRecord> =
        serde_json::from_value(object_or_empty(record.get("pendingInvites")))
            .map_err(decode_error)?;
    Ok(ApiOrgRecord {
        org,
        members,
        assets,
        fleet,
        pending_invites,
    })
}

/// Deserialize an API phone payload (`{ uid, contacts, messages,
/// emails }`) into the model [`PhonePayload`]. The `uid` field is
/// ignored — the model carries none.
pub(crate) fn phone_from_api_record(record: JsonValue) -> Result<PhonePayload, String> {
    serde_json::from_value(record)
        .map_err(|error| format!("forge-webapi phone decode failed: {error}"))
}

/// Blocking HTTP client for forge-webapi.
///
/// Cheap to clone (the underlying reqwest client is reference-counted);
/// one instance is held per API repository.
///
/// A client built by [`ApiClient::unavailable`] carries a construction
/// error instead of a working connection: every request fails with
/// that error. Repositories use it when the client cannot be built, so
/// the failure is loud on every operation instead of silently falling
/// back to another backend. There is no fallback.
#[derive(Debug, Clone)]
pub struct ApiClient {
    client: reqwest::Client,
    base_url: String,
    init_error: Option<String>,
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
            init_error: None,
        })
    }

    /// Build a client from the loaded extension config (`[api]`).
    pub fn configured() -> Result<Self, String> {
        Self::from_config(&crate::config::load().api)
    }

    /// A client that fails every request with `error`: used when the
    /// real client could not be built. The inner reqwest client is
    /// never used — requests short-circuit on `init_error` first.
    pub fn unavailable(error: String) -> Self {
        Self {
            client: reqwest::Client::new(),
            base_url: String::new(),
            init_error: Some(error),
        }
    }

    /// The construction error, if this client was built unavailable.
    fn init_error(&self) -> Option<String> {
        self.init_error.clone()
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
        if let Some(error) = self.init_error() {
            return Err(format!("forge-webapi client unavailable: {error}"));
        }
        let request = self.with_auth(self.client.get(self.url(path)));
        RUNTIME.block_on(async move { Self::execute(request).await })
    }

    /// `POST <path>` with an optional JSON body.
    pub fn post(
        &self,
        path: &str,
        body: Option<JsonValue>,
    ) -> Result<(StatusCode, JsonValue), String> {
        if let Some(error) = self.init_error() {
            return Err(format!("forge-webapi client unavailable: {error}"));
        }
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
        if let Some(error) = self.init_error() {
            return Err(format!("forge-webapi client unavailable: {error}"));
        }
        let mut request = self.with_auth(self.client.put(self.url(path)));
        if let Some(body) = body {
            request = request.json(&body);
        }
        RUNTIME.block_on(async move { Self::execute(request).await })
    }

    /// `DELETE <path>`.
    pub fn delete(&self, path: &str) -> Result<(StatusCode, JsonValue), String> {
        if let Some(error) = self.init_error() {
            return Err(format!("forge-webapi client unavailable: {error}"));
        }
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

/// `api status` — reports the API's view of itself: `connected
/// (database: …)` or `unavailable: <reason>`. The API is the only
/// persistence backend, so this is the persistence status. Intended
/// for SQF polling before issuing operations that need the API.
pub fn status() -> String {
    let config = crate::config::load();
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

/// Creates the Arma 3 command group for forge-webapi operations.
///
/// Registers commands: `status`.
pub fn group() -> Group {
    Group::new().command("status", status)
}
