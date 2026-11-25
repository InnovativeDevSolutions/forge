use super::common::*;
use super::*;
use crate::api::{
    ApiClient, encode_segment, locker_from_api_record, locker_to_api_body, require_success,
    vlocker_from_api_record,
};

/// Locker persistence through forge-webapi (`POST/GET/PUT
/// /players/{uid}/locker`). Same upsert-on-create semantics as the
/// API garage repository: a 409 on create falls through to a full
/// replace.
pub struct ApiLockerRepository {
    client: ApiClient,
}

impl ApiLockerRepository {
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
                    "locker",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, locker persistence disabled (no SurrealDB fallback): {error}"
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

    fn path(uid: &str) -> String {
        format!("/players/{}/locker", encode_segment(uid))
    }

    /// Move a legacy locker into the API. Returns the migrated locker
    /// when one existed, `None` when there was no legacy record. A
    /// legacy-read error fails open (warn, `None` — the legacy rows
    /// are left alone); an API-write error propagates. The legacy rows
    /// are deleted best-effort after a successful PUT, so the locker
    /// lives in exactly one place.
    fn migrate(&self, uid: &str) -> Result<Option<Locker>, String> {
        let legacy = match LegacyLockerRepository.get(uid) {
            Ok(legacy) => legacy,
            Err(error) => {
                crate::log::log(
                    "locker",
                    "WARN",
                    &format!(
                        "forge-webapi locker migration: legacy locker read failed for {uid}, proceeding without it: {error}"
                    ),
                );
                return Ok(None);
            }
        };
        let Some(locker) = legacy else {
            return Ok(None);
        };
        self.update(uid, &locker)?;
        if let Err(error) = LegacyLockerRepository.delete(uid) {
            crate::log::log(
                "locker",
                "WARN",
                &format!(
                    "forge-webapi locker migration: legacy locker delete failed for {uid} after migration: {error}"
                ),
            );
        }
        Ok(Some(locker))
    }
}

impl LockerRepository for ApiLockerRepository {
    fn create(&self, uid: &str, locker: &Locker) -> Result<(), String> {
        // Migrate first: a POST would otherwise create an empty API
        // record that shadows the legacy one.
        if self.exists(uid)? {
            if !locker.items.is_empty() {
                self.update(uid, locker)?;
            }
            return Ok(());
        }
        let path = Self::path(uid);
        let (status, body) = self.client.post(&path, None)?;
        if status != reqwest::StatusCode::CONFLICT {
            require_success("POST", &path, status, body)?;
        }
        if !locker.items.is_empty() {
            self.update(uid, locker)?;
        }
        Ok(())
    }

    fn update(&self, uid: &str, locker: &Locker) -> Result<(), String> {
        let path = Self::path(uid);
        let body = locker_to_api_body(locker)?;
        let (status, response) = self.client.put(&path, Some(body))?;
        require_success("PUT", &path, status, response)?;
        Ok(())
    }

    fn get(&self, uid: &str) -> Result<Option<Locker>, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return self.migrate(uid);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(locker_from_api_record(body)?))
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        let path = Self::path(uid);
        let (status, body) = self.client.delete(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(());
        }
        require_success("DELETE", &path, status, body)?;
        Ok(())
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(self.migrate(uid)?.is_some());
        }
        if status.is_success() {
            return Ok(true);
        }
        Err(format!(
            "forge-webapi GET {} failed ({}): {}",
            path,
            status.as_u16(),
            body.get("error")
                .and_then(|value| value.as_str())
                .unwrap_or("unknown API error")
        ))
    }
}

/// Legacy locker rows in SurrealDB (`locker`, `locker_item`).
///
/// Migration-only: read once by [`ApiLockerRepository::migrate`] so a
/// legacy locker can be moved into the API, then deleted. Never used
/// as a live backend — there is no fallback.
pub struct LegacyLockerRepository;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct LockerOwnerRecord {
    uid: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct LockerItemRecord {
    uid: String,
    category: String,
    classname: String,
    amount: u32,
}

fn locker_item_id(uid: &str, classname: &str) -> String {
    format!("{}:{}", uid, classname)
}

fn locker_from_item_records(records: Vec<LockerItemRecord>) -> Locker {
    let items = records
        .into_iter()
        .map(|record| {
            let item = Item {
                category: record.category,
                classname: record.classname.clone(),
                amount: record.amount,
            };
            (record.classname, item)
        })
        .collect();

    Locker { items }
}

impl LockerRepository for LegacyLockerRepository {
    fn create(&self, uid: &str, locker: &Locker) -> Result<(), String> {
        self.update(uid, locker)
    }

    fn update(&self, uid: &str, locker: &Locker) -> Result<(), String> {
        let owner = LockerOwnerRecord {
            uid: uid.to_string(),
        };
        surreal_upsert("locker", uid, "locker owner", &owner)?;
        surreal_delete_by_uid("locker_item", "locker items", uid)?;

        for item in locker.items.values() {
            let record = LockerItemRecord {
                uid: uid.to_string(),
                category: item.category.clone(),
                classname: item.classname.clone(),
                amount: item.amount,
            };
            surreal_upsert(
                "locker_item",
                &locker_item_id(uid, &item.classname),
                "locker item",
                &record,
            )?;
        }

        Ok(())
    }

    fn get(&self, uid: &str) -> Result<Option<Locker>, String> {
        if surreal_select::<LockerOwnerRecord>("locker", uid, "locker owner")?.is_none() {
            return Ok(None);
        }

        let item_records =
            surreal_select_by_uid::<LockerItemRecord>("locker_item", "locker items", uid)?;
        Ok(Some(locker_from_item_records(item_records)))
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        surreal_delete_by_uid("locker_item", "locker items", uid)?;
        surreal_delete::<LockerOwnerRecord>("locker", uid, "locker owner")
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        surreal_select::<LockerOwnerRecord>("locker", uid, "locker owner")
            .map(|locker| locker.is_some())
    }
}

/// Virtual-locker persistence through forge-webapi.
///
/// Same shape as the virtual-garage bridge: no full-replace endpoint,
/// so `update` is emulated by reading the current record and adding
/// the missing classnames per category (`POST
/// /players/{uid}/vlocker/{category}`) and removing the stale ones
/// (`DELETE /players/{uid}/vlocker/{category}/{classname}`).
pub struct ApiVLockerRepository {
    client: ApiClient,
}

/// The four virtual-locker categories, in the model's field order.
const VLOCKER_CATEGORIES: [&str; 4] = ["items", "weapons", "magazines", "backpacks"];

fn vlocker_category<'a>(locker: &'a VLocker, category: &str) -> &'a [String] {
    match category {
        "items" => &locker.items,
        "weapons" => &locker.weapons,
        "magazines" => &locker.magazines,
        _ => &locker.backpacks,
    }
}

impl ApiVLockerRepository {
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
                    "locker",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, virtual locker persistence disabled (no SurrealDB fallback): {error}"
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

    fn path(uid: &str) -> String {
        format!("/players/{}/vlocker", encode_segment(uid))
    }

    fn category_path(uid: &str, category: &str) -> String {
        format!(
            "/players/{}/vlocker/{}",
            encode_segment(uid),
            encode_segment(category)
        )
    }

    /// Write a whole virtual locker with direct category adds (no
    /// fetch/update round-trip), so this is safe to call from the
    /// migration path inside `fetch()`. Adds auto-create the record.
    fn write_full(&self, uid: &str, locker: &VLocker) -> Result<(), String> {
        for category in VLOCKER_CATEGORIES {
            let classnames = vlocker_category(locker, category);
            if classnames.is_empty() {
                continue;
            }
            let path = Self::category_path(uid, category);
            let (status, body) = self
                .client
                .post(&path, Some(serde_json::json!({ "classnames": classnames })))?;
            require_success("POST", &path, status, body)?;
        }
        Ok(())
    }

    /// Move a legacy virtual locker into the API. Returns the migrated
    /// locker when one existed, `None` when there was no legacy
    /// record. A legacy-read error fails open (warn, `None` — the
    /// legacy rows are left alone); an API-write error propagates.
    /// The legacy rows are deleted best-effort after a successful
    /// write, so the locker lives in exactly one place.
    fn migrate(&self, uid: &str) -> Result<Option<VLocker>, String> {
        let legacy = match LegacyVLockerRepository.fetch(uid) {
            Ok(legacy) => legacy,
            Err(error) => {
                crate::log::log(
                    "locker",
                    "WARN",
                    &format!(
                        "forge-webapi virtual locker migration: legacy locker read failed for {uid}, proceeding without it: {error}"
                    ),
                );
                return Ok(None);
            }
        };
        let Some(locker) = legacy else {
            return Ok(None);
        };
        self.write_full(uid, &locker)?;
        if let Err(error) = LegacyVLockerRepository.delete(uid) {
            crate::log::log(
                "locker",
                "WARN",
                &format!(
                    "forge-webapi virtual locker migration: legacy locker delete failed for {uid} after migration: {error}"
                ),
            );
        }
        Ok(Some(locker))
    }
}

impl VLockerRepository for ApiVLockerRepository {
    fn create(&self, uid: &str, locker: &VLocker) -> Result<(), String> {
        // Migrate first: a POST would otherwise create an empty API
        // record that shadows the legacy one.
        if self.exists(uid)? {
            if VLOCKER_CATEGORIES
                .iter()
                .any(|category| !vlocker_category(locker, category).is_empty())
            {
                self.update(uid, locker)?;
            }
            return Ok(());
        }
        let path = Self::path(uid);
        let (status, body) = self.client.post(&path, None)?;
        if status != reqwest::StatusCode::CONFLICT {
            require_success("POST", &path, status, body)?;
        }
        if VLOCKER_CATEGORIES
            .iter()
            .any(|category| !vlocker_category(locker, category).is_empty())
        {
            self.update(uid, locker)?;
        }
        Ok(())
    }

    fn update(&self, uid: &str, locker: &VLocker) -> Result<(), String> {
        let current = self.fetch(uid)?.unwrap_or_else(VLocker::new);
        for category in VLOCKER_CATEGORIES {
            let wanted = vlocker_category(locker, category);
            let have = vlocker_category(&current, category);
            let additions: Vec<String> = wanted
                .iter()
                .filter(|classname| !have.contains(classname))
                .cloned()
                .collect();
            if !additions.is_empty() {
                let path = Self::category_path(uid, category);
                let (status, body) = self
                    .client
                    .post(&path, Some(serde_json::json!({ "classnames": additions })))?;
                require_success("POST", &path, status, body)?;
            }
            for classname in have.iter().filter(|entry| !wanted.contains(entry)) {
                let path = format!(
                    "{}/{}",
                    Self::category_path(uid, category),
                    encode_segment(classname)
                );
                let (status, body) = self.client.delete(&path)?;
                if status != reqwest::StatusCode::NOT_FOUND {
                    require_success("DELETE", &path, status, body)?;
                }
            }
        }
        Ok(())
    }

    fn fetch(&self, uid: &str) -> Result<Option<VLocker>, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return self.migrate(uid);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(vlocker_from_api_record(body)?))
    }

    fn get(&self, uid: &str, field: &str) -> Result<Vec<String>, String> {
        if !VLOCKER_CATEGORIES.contains(&field) {
            return Err(format!("Unknown virtual locker field '{field}'"));
        }
        let path = Self::category_path(uid, field);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            // No API record yet: a legacy one may hold the unlocks.
            if self.migrate(uid)?.is_some() {
                let (status, body) = self.client.get(&path)?;
                if status == reqwest::StatusCode::NOT_FOUND {
                    return Ok(Vec::new());
                }
                let body = require_success("GET", &path, status, body)?;
                return body
                    .get("classnames")
                    .and_then(|value| serde_json::from_value(value.clone()).ok())
                    .ok_or_else(|| "forge-webapi virtual locker decode failed".to_string());
            }
            // No record yet: the original returns the empty list.
            return Ok(Vec::new());
        }
        let body = require_success("GET", &path, status, body)?;
        body.get("classnames")
            .and_then(|value| serde_json::from_value(value.clone()).ok())
            .ok_or_else(|| "forge-webapi virtual locker decode failed".to_string())
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        let path = Self::path(uid);
        let (status, body) = self.client.delete(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(());
        }
        require_success("DELETE", &path, status, body)?;
        Ok(())
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(self.migrate(uid)?.is_some());
        }
        if status.is_success() {
            return Ok(true);
        }
        Err(format!(
            "forge-webapi GET {} failed ({}): {}",
            path,
            status.as_u16(),
            body.get("error")
                .and_then(|value| value.as_str())
                .unwrap_or("unknown API error")
        ))
    }
}

/// Legacy virtual-locker rows in SurrealDB (`owned_locker`,
/// `locker_unlock`).
///
/// Migration-only: read once by [`ApiVLockerRepository::migrate`] so a
/// legacy virtual locker can be moved into the API, then deleted.
/// Never used as a live backend — there is no fallback.
pub struct LegacyVLockerRepository;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct VLockerOwnerRecord {
    uid: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct LockerUnlockRecord {
    uid: String,
    category: String,
    classname: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    source: Option<String>,
}

fn locker_unlock_id(uid: &str, category: &str, classname: &str) -> String {
    format!("{}:{}:{}", uid, category, classname)
}

fn push_locker_unlock(locker: &mut VLocker, category: &str, classname: String) {
    let target = match category {
        "items" => &mut locker.items,
        "weapons" => &mut locker.weapons,
        "magazines" => &mut locker.magazines,
        "backpacks" => &mut locker.backpacks,
        _ => return,
    };

    if !target.contains(&classname) {
        target.push(classname);
    }
}

fn vlocker_from_unlock_records(records: Vec<LockerUnlockRecord>) -> VLocker {
    let mut locker = VLocker {
        items: Vec::new(),
        weapons: Vec::new(),
        magazines: Vec::new(),
        backpacks: Vec::new(),
    };

    for record in records {
        push_locker_unlock(&mut locker, &record.category, record.classname);
    }

    locker
}

fn upsert_locker_unlocks(uid: &str, category: &str, classnames: &[String]) -> Result<(), String> {
    for classname in classnames {
        let record = LockerUnlockRecord {
            uid: uid.to_string(),
            category: category.to_string(),
            classname: classname.clone(),
            source: None,
        };
        surreal_upsert(
            "locker_unlock",
            &locker_unlock_id(uid, category, classname),
            "locker unlock",
            &record,
        )?;
    }

    Ok(())
}

impl VLockerRepository for LegacyVLockerRepository {
    fn create(&self, uid: &str, locker: &VLocker) -> Result<(), String> {
        self.update(uid, locker)
    }

    fn update(&self, uid: &str, locker: &VLocker) -> Result<(), String> {
        let owner = VLockerOwnerRecord {
            uid: uid.to_string(),
        };
        surreal_upsert("owned_locker", uid, "virtual locker owner", &owner)?;
        surreal_delete_by_uid("locker_unlock", "locker unlocks", uid)?;
        upsert_locker_unlocks(uid, "items", &locker.items)?;
        upsert_locker_unlocks(uid, "weapons", &locker.weapons)?;
        upsert_locker_unlocks(uid, "magazines", &locker.magazines)?;
        upsert_locker_unlocks(uid, "backpacks", &locker.backpacks)?;
        Ok(())
    }

    fn fetch(&self, uid: &str) -> Result<Option<VLocker>, String> {
        if surreal_select::<VLockerOwnerRecord>("owned_locker", uid, "virtual locker owner")?
            .is_none()
        {
            return Ok(None);
        }

        let unlock_records =
            surreal_select_by_uid::<LockerUnlockRecord>("locker_unlock", "locker unlocks", uid)?;
        Ok(Some(vlocker_from_unlock_records(unlock_records)))
    }

    fn get(&self, uid: &str, field: &str) -> Result<Vec<String>, String> {
        let locker = self.fetch(uid)?.unwrap_or_else(VLocker::new);
        match field {
            "items" => Ok(locker.items),
            "weapons" => Ok(locker.weapons),
            "magazines" => Ok(locker.magazines),
            "backpacks" => Ok(locker.backpacks),
            _ => Err(format!("Unknown virtual locker field '{}'", field)),
        }
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        surreal_delete_by_uid("locker_unlock", "locker unlocks", uid)?;
        surreal_delete::<VLockerOwnerRecord>("owned_locker", uid, "virtual locker owner")
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        surreal_select::<VLockerOwnerRecord>("owned_locker", uid, "virtual locker owner")
            .map(|locker| locker.is_some())
    }
}
