use super::*;
use crate::api::{
    ApiClient, ApiOrgRecord, encode_segment, org_from_api_record, org_to_api_body, require_success,
};
use serde_json::Value as JsonValue;

/// Org persistence through forge-webapi (`POST /orgs`, `GET/PUT/DELETE
/// /orgs/{id}`, plus the member/asset/fleet sub-endpoints).
///
/// The API persists one whole `OrgRecord` per org (core + members +
/// assets + fleet + credit lines + pending invites), and `PUT
/// /orgs/{id}` is full-replace — so every partial update here is
/// read-merge-write: fetch the current record, replace only the
/// collection the caller changed, and PUT the merged whole back. A
/// caller that sent an empty collection would clear it, which is why
/// `update_assets` / `update_fleet` never build a record from the
/// caller's collection alone.
///
/// `create` registers through `POST /orgs` (the owner becomes the
/// first member); a non-default org is then followed by a merged PUT.
/// A 409 (already exists) falls through to the merged PUT.
pub struct ApiOrgRepository {
    client: ApiClient,
}

impl ApiOrgRepository {
    pub fn new() -> Result<Self, String> {
        Ok(Self {
            client: ApiClient::configured()?,
        })
    }

    /// The API is the only persistence backend: build the client, and
    /// if that fails log loudly and return a repository whose every
    /// operation fails with the construction error.
    pub fn configured() -> Self {
        match Self::new() {
            Ok(repository) => repository,
            Err(error) => {
                crate::log::log(
                    "org",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, org persistence disabled: {error}"
                    ),
                );
                Self::unavailable(error)
            }
        }
    }

    /// A repository that fails every operation with `error`: used when
    /// the API client could not be built.
    pub fn unavailable(error: String) -> Self {
        Self {
            client: ApiClient::unavailable(error),
        }
    }

    fn path(id: &str) -> String {
        format!("/orgs/{}", encode_segment(id))
    }

    /// An org whose core differs from a freshly registered one: only
    /// those need a merged PUT after create.
    fn is_non_default(org: &Org) -> bool {
        org.funds != 0.0 || org.reputation != 0 || !org.credit_lines.is_empty()
    }

    /// A player's display name from the configured actor repository,
    /// best-effort: `""` when the actor is unknown or unreadable. The
    /// API renders an empty name as `"Unknown"`.
    fn actor_name(uid: &str) -> String {
        let repository = ApiActorRepository::configured();
        match repository.get_by_id(uid) {
            Ok(Some(actor)) => actor.name.unwrap_or_default(),
            _ => String::new(),
        }
    }

    /// GET the API record, `None` on 404.
    fn fetch_record(&self, id: &str) -> Result<Option<JsonValue>, String> {
        let path = Self::path(id);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(None);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(body))
    }

    fn put_record(&self, body: JsonValue) -> Result<(), String> {
        let id = body
            .get("orgId")
            .and_then(|value| value.as_str())
            .unwrap_or_default()
            .to_string();
        let path = Self::path(&id);
        let (status, response) = self.client.put(&path, Some(body))?;
        require_success("PUT", &path, status, response)?;
        Ok(())
    }

    /// Read-merge-write of a core [`Org`]: the current record's
    /// members, assets, fleet and pending invites survive, only the
    /// core fields (id, owner, name, funds, reputation, credit lines)
    /// are replaced. When no API record exists yet, the PUT creates the
    /// org from the core plus empty collections.
    fn put_merged(&self, org: &Org) -> Result<(), String> {
        let current = match self.fetch_record(&org.id)? {
            Some(record) => org_from_api_record(record)?,
            None => ApiOrgRecord {
                org: org.clone(),
                members: HashMap::new(),
                assets: HashMap::new(),
                fleet: HashMap::new(),
                pending_invites: HashMap::new(),
            },
        };
        let body = org_to_api_body(
            org,
            &current.members,
            &current.assets,
            &current.fleet,
            &current.pending_invites,
        )?;
        self.put_record(body)
    }

    fn parse_members(body: JsonValue) -> Result<Vec<MemberSummary>, String> {
        let members = body.get("members").cloned().unwrap_or(JsonValue::Null);
        serde_json::from_value(members)
            .map_err(|error| format!("forge-webapi org members decode failed: {error}"))
    }

    fn parse_assets(
        body: JsonValue,
    ) -> Result<HashMap<String, HashMap<String, OrgAssetEntry>>, String> {
        let assets = body.get("assets").cloned().unwrap_or(JsonValue::Null);
        serde_json::from_value(assets)
            .map_err(|error| format!("forge-webapi org assets decode failed: {error}"))
    }

    fn parse_fleet(body: JsonValue) -> Result<HashMap<String, OrgFleetEntry>, String> {
        let fleet = body.get("fleet").cloned().unwrap_or(JsonValue::Null);
        serde_json::from_value(fleet)
            .map_err(|error| format!("forge-webapi org fleet decode failed: {error}"))
    }
}

impl OrgRepository for ApiOrgRepository {
    fn create(&self, org: &Org) -> Result<(), String> {
        // No `existingOrgId`: the repository must not move the
        // requester out of another org — the hot service owns that.
        let path = "/orgs".to_string();
        let (status, body) = self.client.post(
            &path,
            Some(serde_json::json!({
                "orgId": org.id,
                "orgName": org.name,
                "requesterUid": org.owner,
                "requesterName": Self::actor_name(&org.owner),
            })),
        )?;
        if status != reqwest::StatusCode::CONFLICT {
            require_success("POST", &path, status, body)?;
        }
        if Self::is_non_default(org) {
            self.put_merged(org)?;
        }
        Ok(())
    }

    fn get_by_id(&self, id: &str) -> Result<Option<Org>, String> {
        match self.fetch_record(id)? {
            Some(record) => Ok(Some(org_from_api_record(record)?.org)),
            None => Ok(None),
        }
    }

    fn update(&self, org: &Org) -> Result<(), String> {
        self.put_merged(org)
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        let path = Self::path(id);
        let (status, body) = self.client.delete(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(());
        }
        require_success("DELETE", &path, status, body)?;
        Ok(())
    }

    fn exists(&self, id: &str) -> Result<bool, String> {
        Ok(self.fetch_record(id)?.is_some())
    }

    fn add_member(&self, org_id: &str, member_uid: &str) -> Result<(), String> {
        let path = format!("{}/members", Self::path(org_id));
        let body = serde_json::json!({
            "memberUid": member_uid,
            "memberName": Self::actor_name(member_uid),
        });
        let (status, response) = self.client.post(&path, Some(body))?;
        require_success("POST", &path, status, response)?;
        Ok(())
    }

    fn get_members(&self, org_id: &str) -> Result<Vec<MemberSummary>, String> {
        let path = format!("{}/members", Self::path(org_id));
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(Vec::new());
        }
        let body = require_success("GET", &path, status, body)?;
        Self::parse_members(body)
    }

    fn remove_member(&self, org_id: &str, member_uid: &str) -> Result<(), String> {
        let path = format!(
            "{}/members/{}",
            Self::path(org_id),
            encode_segment(member_uid)
        );
        let (status, body) = self.client.delete(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(());
        }
        require_success("DELETE", &path, status, body)?;
        Ok(())
    }

    fn get_assets(
        &self,
        org_id: &str,
    ) -> Result<HashMap<String, HashMap<String, OrgAssetEntry>>, String> {
        let path = format!("{}/assets", Self::path(org_id));
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(HashMap::new());
        }
        let body = require_success("GET", &path, status, body)?;
        Self::parse_assets(body)
    }

    fn update_assets(
        &self,
        org_id: &str,
        assets: &HashMap<String, HashMap<String, OrgAssetEntry>>,
    ) -> Result<(), String> {
        let Some(record) = self.fetch_record(org_id)? else {
            return Err(format!("Organization {org_id} not found"));
        };
        let mut current = org_from_api_record(record)?;
        current.assets = assets.clone();
        let body = org_to_api_body(
            &current.org,
            &current.members,
            &current.assets,
            &current.fleet,
            &current.pending_invites,
        )?;
        self.put_record(body)
    }

    fn get_fleet(&self, org_id: &str) -> Result<HashMap<String, OrgFleetEntry>, String> {
        let path = format!("{}/fleet", Self::path(org_id));
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(HashMap::new());
        }
        let body = require_success("GET", &path, status, body)?;
        Self::parse_fleet(body)
    }

    fn update_fleet(
        &self,
        org_id: &str,
        fleet: &HashMap<String, OrgFleetEntry>,
    ) -> Result<(), String> {
        let Some(record) = self.fetch_record(org_id)? else {
            return Err(format!("Organization {org_id} not found"));
        };
        let mut current = org_from_api_record(record)?;
        current.fleet = fleet.clone();
        let body = org_to_api_body(
            &current.org,
            &current.members,
            &current.assets,
            &current.fleet,
            &current.pending_invites,
        )?;
        self.put_record(body)
    }
}
