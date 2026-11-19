use super::common::*;
use super::*;
use crate::api::{
    ApiClient, encode_segment, locker_from_api_record, locker_to_api_body, require_success,
    vlocker_from_api_record,
};

pub enum LockerStorageRepository {
    Surreal(SurrealLockerRepository),
    Api(ApiLockerRepository),
}

impl LockerStorageRepository {
    pub fn configured() -> Self {
        if crate::config::load().api.enabled {
            match ApiLockerRepository::new() {
                Ok(repository) => Self::Api(repository),
                Err(error) => {
                    crate::log::log(
                        "locker",
                        "ERROR",
                        &format!(
                            "forge-webapi bridge unavailable, falling back to SurrealDB: {error}"
                        ),
                    );
                    Self::Surreal(SurrealLockerRepository)
                }
            }
        } else {
            Self::Surreal(SurrealLockerRepository)
        }
    }
}

impl LockerRepository for LockerStorageRepository {
    fn create(&self, uid: &str, locker: &Locker) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(uid, locker),
            Self::Api(repository) => repository.create(uid, locker),
        }
    }

    fn update(&self, uid: &str, locker: &Locker) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(uid, locker),
            Self::Api(repository) => repository.update(uid, locker),
        }
    }

    fn get(&self, uid: &str) -> Result<Option<Locker>, String> {
        match self {
            Self::Surreal(repository) => repository.get(uid),
            Self::Api(repository) => repository.get(uid),
        }
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.delete(uid),
            Self::Api(repository) => repository.delete(uid),
        }
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.exists(uid),
            Self::Api(repository) => repository.exists(uid),
        }
    }
}

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

    fn path(uid: &str) -> String {
        format!("/players/{}/locker", encode_segment(uid))
    }
}

impl LockerRepository for ApiLockerRepository {
    fn create(&self, uid: &str, locker: &Locker) -> Result<(), String> {
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
            return Ok(None);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(locker_from_api_record(body)?))
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        // TODO(bridge): the API has no DELETE /players/{uid}/locker yet,
        // so deletes still target the legacy SurrealDB tables (see the
        // note on `ApiGarageRepository::delete`).
        SurrealLockerRepository.delete(uid)
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(false);
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

pub struct SurrealLockerRepository;

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

impl LockerRepository for SurrealLockerRepository {
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

pub enum VLockerStorageRepository {
    Surreal(SurrealVLockerRepository),
    Api(ApiVLockerRepository),
}

impl VLockerStorageRepository {
    pub fn configured() -> Self {
        if crate::config::load().api.enabled {
            match ApiVLockerRepository::new() {
                Ok(repository) => Self::Api(repository),
                Err(error) => {
                    crate::log::log(
                        "locker",
                        "ERROR",
                        &format!(
                            "forge-webapi bridge unavailable, falling back to SurrealDB: {error}"
                        ),
                    );
                    Self::Surreal(SurrealVLockerRepository)
                }
            }
        } else {
            Self::Surreal(SurrealVLockerRepository)
        }
    }
}

impl VLockerRepository for VLockerStorageRepository {
    fn create(&self, uid: &str, locker: &VLocker) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(uid, locker),
            Self::Api(repository) => repository.create(uid, locker),
        }
    }

    fn update(&self, uid: &str, locker: &VLocker) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(uid, locker),
            Self::Api(repository) => repository.update(uid, locker),
        }
    }

    fn fetch(&self, uid: &str) -> Result<Option<VLocker>, String> {
        match self {
            Self::Surreal(repository) => repository.fetch(uid),
            Self::Api(repository) => repository.fetch(uid),
        }
    }

    fn get(&self, uid: &str, field: &str) -> Result<Vec<String>, String> {
        match self {
            Self::Surreal(repository) => repository.get(uid, field),
            Self::Api(repository) => repository.get(uid, field),
        }
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.delete(uid),
            Self::Api(repository) => repository.delete(uid),
        }
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.exists(uid),
            Self::Api(repository) => repository.exists(uid),
        }
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
}

impl VLockerRepository for ApiVLockerRepository {
    fn create(&self, uid: &str, locker: &VLocker) -> Result<(), String> {
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
            return Ok(None);
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
            // No record yet: the original returns the empty list.
            return Ok(Vec::new());
        }
        let body = require_success("GET", &path, status, body)?;
        body.get("classnames")
            .and_then(|value| serde_json::from_value(value.clone()).ok())
            .ok_or_else(|| "forge-webapi virtual locker decode failed".to_string())
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        // TODO(bridge): the API has no DELETE /players/{uid}/vlocker yet,
        // so deletes still target the legacy SurrealDB tables (see the
        // note on the garage delete).
        SurrealVLockerRepository.delete(uid)
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(false);
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

pub struct SurrealVLockerRepository;

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

impl VLockerRepository for SurrealVLockerRepository {
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
