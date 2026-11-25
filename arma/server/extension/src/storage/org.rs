use super::common::*;
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
/// `create` checks `exists()` first — which migrates a legacy org —
/// so it can never register over legacy data.
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
    /// operation fails with the construction error. There is no
    /// fallback to SurrealDB.
    pub fn configured() -> Self {
        match Self::new() {
            Ok(repository) => repository,
            Err(error) => {
                crate::log::log(
                    "org",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, org persistence disabled (no SurrealDB fallback): {error}"
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
    /// API renders an empty name as `"Unknown"`, matching the legacy
    /// repository's fallback.
    fn actor_name(uid: &str) -> String {
        let repository = ApiActorRepository::configured();
        match repository.get_by_id(uid) {
            Ok(Some(actor)) => actor.name.unwrap_or_default(),
            _ => String::new(),
        }
    }

    /// GET the API record, `None` on 404. Does not migrate.
    fn fetch_record(&self, id: &str) -> Result<Option<JsonValue>, String> {
        let path = Self::path(id);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(None);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(body))
    }

    /// GET the API record, migrating a legacy one on 404.
    fn fetch_or_migrate_record(&self, id: &str) -> Result<Option<JsonValue>, String> {
        if let Some(record) = self.fetch_record(id)? {
            return Ok(Some(record));
        }
        if self.migrate(id)?.is_some() {
            return self.fetch_record(id);
        }
        Ok(None)
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
    /// are replaced. When no API record exists yet, a legacy one is
    /// migrated first; when there is no legacy record either, the PUT
    /// creates the org from the core plus empty collections.
    fn put_merged(&self, org: &Org) -> Result<(), String> {
        let current = match self.fetch_or_migrate_record(&org.id)? {
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

    /// Move a legacy org into the API: the core record plus its side
    /// tables (members, assets, fleet, credit lines) are assembled
    /// into one `OrgRecord` and PUT. Returns the migrated core when
    /// one existed, `None` when there was no legacy record. A
    /// legacy-core read error fails open (warn, `None` — the legacy
    /// rows are left alone); a side-table read error warns and
    /// migrates that collection empty; an API-write error propagates.
    /// The legacy rows (core + all side tables) are deleted
    /// best-effort after a successful PUT, via
    /// `LegacyOrgRepository::delete`. Pending invites are hot-only in
    /// the original — no legacy invite table exists — so migration
    /// seeds them empty.
    fn migrate(&self, id: &str) -> Result<Option<Org>, String> {
        let legacy = match LegacyOrgRepository.get_by_id(id) {
            Ok(legacy) => legacy,
            Err(error) => {
                crate::log::log(
                    "org",
                    "WARN",
                    &format!(
                        "forge-webapi org migration: legacy org read failed for {id}, proceeding without it: {error}"
                    ),
                );
                return Ok(None);
            }
        };
        let Some(org) = legacy else {
            return Ok(None);
        };
        let members = match LegacyOrgRepository.get_members(id) {
            Ok(members) => members,
            Err(error) => {
                crate::log::log(
                    "org",
                    "WARN",
                    &format!(
                        "forge-webapi org migration: legacy org members read failed for {id}, migrating without them: {error}"
                    ),
                );
                Vec::new()
            }
        };
        let assets = match LegacyOrgRepository.get_assets(id) {
            Ok(assets) => assets,
            Err(error) => {
                crate::log::log(
                    "org",
                    "WARN",
                    &format!(
                        "forge-webapi org migration: legacy org assets read failed for {id}, migrating without them: {error}"
                    ),
                );
                HashMap::new()
            }
        };
        let fleet = match LegacyOrgRepository.get_fleet(id) {
            Ok(fleet) => fleet,
            Err(error) => {
                crate::log::log(
                    "org",
                    "WARN",
                    &format!(
                        "forge-webapi org migration: legacy org fleet read failed for {id}, migrating without it: {error}"
                    ),
                );
                HashMap::new()
            }
        };
        let members_map: HashMap<String, MemberSummary> = members
            .into_iter()
            .map(|member| (member.uid.clone(), member))
            .collect();
        let body = org_to_api_body(&org, &members_map, &assets, &fleet, &HashMap::new())?;
        self.put_record(body)?;
        if let Err(error) = LegacyOrgRepository.delete(id) {
            crate::log::log(
                "org",
                "WARN",
                &format!(
                    "forge-webapi org migration: legacy org delete failed for {id} after migration: {error}"
                ),
            );
        }
        Ok(Some(org))
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
        if self.exists(&org.id)? {
            if Self::is_non_default(org) {
                self.put_merged(org)?;
            }
            return Ok(());
        }
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
        match self.fetch_or_migrate_record(id)? {
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
        Ok(self.fetch_or_migrate_record(id)?.is_some())
    }

    fn add_member(&self, org_id: &str, member_uid: &str) -> Result<(), String> {
        let path = format!("{}/members", Self::path(org_id));
        let body = serde_json::json!({
            "memberUid": member_uid,
            "memberName": Self::actor_name(member_uid),
        });
        let (status, response) = self.client.post(&path, Some(body.clone()))?;
        if status == reqwest::StatusCode::NOT_FOUND && self.migrate(org_id)?.is_some() {
            // A legacy-only org: migrate, then retry once.
            let (status, response) = self.client.post(&path, Some(body))?;
            require_success("POST", &path, status, response)?;
            return Ok(());
        }
        require_success("POST", &path, status, response)?;
        Ok(())
    }

    fn get_members(&self, org_id: &str) -> Result<Vec<MemberSummary>, String> {
        let path = format!("{}/members", Self::path(org_id));
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            if self.migrate(org_id)?.is_some() {
                let (status, body) = self.client.get(&path)?;
                let body = require_success("GET", &path, status, body)?;
                return Self::parse_members(body);
            }
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
            if self.migrate(org_id)?.is_some() {
                let (status, body) = self.client.get(&path)?;
                let body = require_success("GET", &path, status, body)?;
                return Self::parse_assets(body);
            }
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
        let Some(record) = self.fetch_or_migrate_record(org_id)? else {
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
            if self.migrate(org_id)?.is_some() {
                let (status, body) = self.client.get(&path)?;
                let body = require_success("GET", &path, status, body)?;
                return Self::parse_fleet(body);
            }
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
        let Some(record) = self.fetch_or_migrate_record(org_id)? else {
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

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
struct SurrealOrgRecord {
    #[serde(default)]
    org_id: String,
    #[serde(default)]
    owner: String,
    #[serde(default)]
    name: String,
    #[serde(default)]
    funds: f64,
    #[serde(default)]
    reputation: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct OrgMemberRow {
    org_id: String,
    member_uid: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct OrgCreditLineRow {
    org_id: String,
    uid: String,
    name: String,
    approved_amount: f64,
    available_amount: f64,
    outstanding_principal: f64,
    interest_rate: f64,
    amount_due: f64,
    amount: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct OrgAssetRow {
    org_id: String,
    category: String,
    classname: String,
    asset_type: String,
    quantity: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct OrgFleetRow {
    org_id: String,
    fleet_key: String,
    classname: String,
    name: String,
    fleet_type: String,
    status: String,
    damage: String,
}

impl SurrealOrgRecord {
    fn into_org(self, fallback_id: &str, credit_lines: HashMap<String, CreditLineSummary>) -> Org {
        let id = if self.org_id.trim().is_empty() {
            fallback_id.to_string()
        } else {
            self.org_id
        };

        let mut org = Org {
            id,
            owner: self.owner,
            name: self.name,
            funds: self.funds,
            reputation: self.reputation,
            credit_lines,
        };
        org.normalize_credit_lines();
        org
    }
}

impl From<&Org> for SurrealOrgRecord {
    fn from(org: &Org) -> Self {
        Self {
            org_id: org.id.clone(),
            owner: org.owner.clone(),
            name: org.name.clone(),
            funds: org.funds,
            reputation: org.reputation,
        }
    }
}

/// Legacy org rows in SurrealDB (`org`, `org_member`, `org_asset`,
/// `org_fleet_vehicle`, `org_credit_line`).
///
/// Migration-only: read once by [`ApiOrgRepository::migrate`] so a
/// legacy org can be moved into the API, then deleted. Never used
/// as a live backend — there is no fallback.
pub struct LegacyOrgRepository;

fn org_member_id(org_id: &str, member_uid: &str) -> String {
    format!("{}:{}", org_id, member_uid)
}

fn org_credit_line_id(org_id: &str, uid: &str) -> String {
    format!("{}:{}", org_id, uid)
}

fn org_asset_id(org_id: &str, category: &str, classname: &str) -> String {
    format!("{}:{}:{}", org_id, category, classname)
}

fn org_fleet_id(org_id: &str, fleet_key: &str) -> String {
    format!("{}:{}", org_id, fleet_key)
}

fn org_credit_lines_from_rows(rows: Vec<OrgCreditLineRow>) -> HashMap<String, CreditLineSummary> {
    rows.into_iter()
        .map(|row| {
            let mut credit_line = CreditLineSummary {
                uid: row.uid.clone(),
                name: row.name,
                approved_amount: row.approved_amount,
                available_amount: row.available_amount,
                outstanding_principal: row.outstanding_principal,
                interest_rate: row.interest_rate,
                amount_due: row.amount_due,
                amount: row.amount,
            };
            credit_line.normalize();
            (row.uid, credit_line)
        })
        .collect()
}

fn org_member_uids(org_id: &str) -> Result<Vec<String>, String> {
    let rows =
        surreal_select_by_field::<OrgMemberRow>("org_member", "org members", "org_id", org_id)?;
    let mut uids = rows
        .into_iter()
        .map(|row| row.member_uid)
        .filter(|uid| !uid.trim().is_empty())
        .collect::<Vec<_>>();
    uids.sort();
    uids.dedup();
    Ok(uids)
}

fn upsert_org_member(org_id: &str, member_uid: &str) -> Result<(), String> {
    let row = OrgMemberRow {
        org_id: org_id.to_string(),
        member_uid: member_uid.to_string(),
    };
    surreal_upsert(
        "org_member",
        &org_member_id(org_id, member_uid),
        "org member",
        &row,
    )
}

fn org_assets_from_rows(rows: Vec<OrgAssetRow>) -> HashMap<String, HashMap<String, OrgAssetEntry>> {
    let mut assets = HashMap::new();
    for row in rows {
        let category_assets = assets
            .entry(row.category.clone())
            .or_insert_with(HashMap::new);
        category_assets.insert(
            row.classname.clone(),
            OrgAssetEntry {
                classname: row.classname,
                asset_type: row.asset_type,
                quantity: row.quantity,
            },
        );
    }
    assets
}

fn org_fleet_from_rows(rows: Vec<OrgFleetRow>) -> HashMap<String, OrgFleetEntry> {
    rows.into_iter()
        .map(|row| {
            (
                row.fleet_key,
                OrgFleetEntry {
                    classname: row.classname,
                    name: row.name,
                    fleet_type: row.fleet_type,
                    status: row.status,
                    damage: row.damage,
                },
            )
        })
        .collect()
}

impl OrgRepository for LegacyOrgRepository {
    fn create(&self, org: &Org) -> Result<(), String> {
        self.update(org)
    }

    fn get_by_id(&self, id: &str) -> Result<Option<Org>, String> {
        let Some(record) = surreal_select::<SurrealOrgRecord>("org", id, "org")? else {
            return Ok(None);
        };

        let credit_line_rows = surreal_select_by_field::<OrgCreditLineRow>(
            "org_credit_line",
            "org credit lines",
            "org_id",
            id,
        )?;
        let credit_lines = org_credit_lines_from_rows(credit_line_rows);

        Ok(Some(record.into_org(id, credit_lines)))
    }

    fn update(&self, org: &Org) -> Result<(), String> {
        let record = SurrealOrgRecord::from(org);
        surreal_upsert("org", org.id.as_str(), "org", &record)?;
        surreal_delete_by_field("org_credit_line", "org credit lines", "org_id", &org.id)?;

        for (uid, credit_line) in &org.credit_lines {
            let resolved_uid = if credit_line.uid.trim().is_empty() {
                uid.clone()
            } else {
                credit_line.uid.clone()
            };
            let mut normalized = credit_line.clone();
            normalized.uid = resolved_uid.clone();
            normalized.normalize();
            let row = OrgCreditLineRow {
                org_id: org.id.clone(),
                uid: resolved_uid.clone(),
                name: normalized.name,
                approved_amount: normalized.approved_amount,
                available_amount: normalized.available_amount,
                outstanding_principal: normalized.outstanding_principal,
                interest_rate: normalized.interest_rate,
                amount_due: normalized.amount_due,
                amount: normalized.amount,
            };
            surreal_upsert(
                "org_credit_line",
                &org_credit_line_id(&org.id, &resolved_uid),
                "org credit line",
                &row,
            )?;
        }

        Ok(())
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        surreal_delete::<SurrealOrgRecord>("org", id, "org")?;
        surreal_delete_by_field("org_member", "org members", "org_id", id)?;
        surreal_delete_by_field("org_credit_line", "org credit lines", "org_id", id)?;
        surreal_delete_by_field("org_asset", "org assets", "org_id", id)?;
        surreal_delete_by_field("org_fleet_vehicle", "org fleet", "org_id", id)
    }

    fn exists(&self, id: &str) -> Result<bool, String> {
        self.get_by_id(id).map(|org| org.is_some())
    }

    fn add_member(&self, org_id: &str, member_uid: &str) -> Result<(), String> {
        if !self.exists(org_id)? {
            return Err(format!("Organization {} does not exist", org_id));
        }

        let mut member_uids = org_member_uids(org_id)?;
        if !member_uids.iter().any(|uid| uid == member_uid) {
            member_uids.push(member_uid.to_string());
        }
        surreal_delete_by_field("org_member", "org members", "org_id", org_id)?;
        for uid in member_uids {
            upsert_org_member(org_id, &uid)?;
        }
        Ok(())
    }

    fn get_members(&self, org_id: &str) -> Result<Vec<MemberSummary>, String> {
        let member_uids = org_member_uids(org_id)?;
        let mut members = Vec::with_capacity(member_uids.len());
        let actor_repository = LegacyActorRepository;

        for uid in member_uids {
            if uid.trim().is_empty() {
                continue;
            }

            let name = match actor_repository.get_by_id(&uid)? {
                Some(actor) => actor
                    .name
                    .filter(|name| !name.trim().is_empty())
                    .unwrap_or_else(|| "Unknown".to_string()),
                None => "Unknown".to_string(),
            };

            members.push(MemberSummary { uid, name });
        }

        Ok(members)
    }

    fn remove_member(&self, org_id: &str, member_uid: &str) -> Result<(), String> {
        let mut member_uids = org_member_uids(org_id)?;
        member_uids.retain(|uid| uid != member_uid);
        surreal_delete_by_field("org_member", "org members", "org_id", org_id)?;
        for uid in member_uids {
            upsert_org_member(org_id, &uid)?;
        }
        Ok(())
    }

    fn get_assets(
        &self,
        org_id: &str,
    ) -> Result<HashMap<String, HashMap<String, OrgAssetEntry>>, String> {
        let rows =
            surreal_select_by_field::<OrgAssetRow>("org_asset", "org assets", "org_id", org_id)?;
        Ok(org_assets_from_rows(rows))
    }

    fn update_assets(
        &self,
        org_id: &str,
        assets: &HashMap<String, HashMap<String, OrgAssetEntry>>,
    ) -> Result<(), String> {
        surreal_delete_by_field("org_asset", "org assets", "org_id", org_id)?;

        for (category, category_assets) in assets {
            for (classname, asset) in category_assets {
                let row = OrgAssetRow {
                    org_id: org_id.to_string(),
                    category: category.clone(),
                    classname: if asset.classname.trim().is_empty() {
                        classname.clone()
                    } else {
                        asset.classname.clone()
                    },
                    asset_type: asset.asset_type.clone(),
                    quantity: asset.quantity,
                };
                surreal_upsert(
                    "org_asset",
                    &org_asset_id(org_id, category, &row.classname),
                    "org asset",
                    &row,
                )?;
            }
        }

        Ok(())
    }

    fn get_fleet(&self, org_id: &str) -> Result<HashMap<String, OrgFleetEntry>, String> {
        let rows = surreal_select_by_field::<OrgFleetRow>(
            "org_fleet_vehicle",
            "org fleet",
            "org_id",
            org_id,
        )?;
        if !rows.is_empty() {
            return Ok(org_fleet_from_rows(rows));
        }
        Ok(HashMap::new())
    }

    fn update_fleet(
        &self,
        org_id: &str,
        fleet: &HashMap<String, OrgFleetEntry>,
    ) -> Result<(), String> {
        surreal_delete_by_field("org_fleet_vehicle", "org fleet", "org_id", org_id)?;

        for (fleet_key, entry) in fleet {
            let row = OrgFleetRow {
                org_id: org_id.to_string(),
                fleet_key: fleet_key.clone(),
                classname: entry.classname.clone(),
                name: entry.name.clone(),
                fleet_type: entry.fleet_type.clone(),
                status: entry.status.clone(),
                damage: entry.damage.clone(),
            };
            surreal_upsert(
                "org_fleet_vehicle",
                &org_fleet_id(org_id, fleet_key),
                "org fleet",
                &row,
            )?;
        }

        Ok(())
    }
}
