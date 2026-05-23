use super::common::*;
use super::*;

pub enum OrgStorageRepository {
    Surreal(SurrealOrgRepository),
}

impl OrgStorageRepository {
    pub fn configured() -> Self {
        Self::Surreal(SurrealOrgRepository)
    }
}

impl OrgRepository for OrgStorageRepository {
    fn create(&self, org: &Org) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(org),
        }
    }

    fn get_by_id(&self, id: &str) -> Result<Option<Org>, String> {
        match self {
            Self::Surreal(repository) => repository.get_by_id(id),
        }
    }

    fn update(&self, org: &Org) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(org),
        }
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.delete(id),
        }
    }

    fn exists(&self, id: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.exists(id),
        }
    }

    fn add_member(&self, org_id: &str, member_uid: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.add_member(org_id, member_uid),
        }
    }

    fn get_members(&self, org_id: &str) -> Result<Vec<MemberSummary>, String> {
        match self {
            Self::Surreal(repository) => repository.get_members(org_id),
        }
    }

    fn remove_member(&self, org_id: &str, member_uid: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.remove_member(org_id, member_uid),
        }
    }

    fn get_assets(
        &self,
        org_id: &str,
    ) -> Result<HashMap<String, HashMap<String, OrgAssetEntry>>, String> {
        match self {
            Self::Surreal(repository) => repository.get_assets(org_id),
        }
    }

    fn update_assets(
        &self,
        org_id: &str,
        assets: &HashMap<String, HashMap<String, OrgAssetEntry>>,
    ) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update_assets(org_id, assets),
        }
    }

    fn get_fleet(&self, org_id: &str) -> Result<HashMap<String, OrgFleetEntry>, String> {
        match self {
            Self::Surreal(repository) => repository.get_fleet(org_id),
        }
    }

    fn update_fleet(
        &self,
        org_id: &str,
        fleet: &HashMap<String, OrgFleetEntry>,
    ) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update_fleet(org_id, fleet),
        }
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

pub struct SurrealOrgRepository;

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

impl OrgRepository for SurrealOrgRepository {
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
        let actor_repository = SurrealActorRepository;

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
