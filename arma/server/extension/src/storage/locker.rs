use super::*;
use crate::api::{
    ApiClient, encode_segment, locker_from_api_record, locker_to_api_body, require_success,
    vlocker_from_api_record,
};

/// Locker persistence through forge-webapi (`POST/GET/PUT/DELETE
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
    /// operation fails with the construction error.
    pub fn configured() -> Self {
        match Self::new() {
            Ok(repository) => repository,
            Err(error) => {
                crate::log::log(
                    "locker",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, locker persistence disabled: {error}"
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
            return Ok(false);
        }
        require_success("GET", &path, status, body)?;
        Ok(true)
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
    /// operation fails with the construction error.
    pub fn configured() -> Self {
        match Self::new() {
            Ok(repository) => repository,
            Err(error) => {
                crate::log::log(
                    "locker",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, virtual locker persistence disabled: {error}"
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
            return Ok(false);
        }
        require_success("GET", &path, status, body)?;
        Ok(true)
    }
}
