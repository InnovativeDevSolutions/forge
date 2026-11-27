use super::*;
use crate::api::{
    ApiClient, encode_segment, garage_from_api_record, garage_to_api_body, require_success,
    vgarage_from_api_record,
};

/// Garage persistence through forge-webapi (`POST/GET/PUT/DELETE
/// /players/{uid}/garage`).
///
/// `create` keeps the original's upsert semantics: the API's create
/// makes an empty garage, so a non-empty create is followed by a full
/// replace, and a 409 (already exists) falls through to the replace.
pub struct ApiGarageRepository {
    client: ApiClient,
}

impl ApiGarageRepository {
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
                    "garage",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, garage persistence disabled: {error}"
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
        format!("/players/{}/garage", encode_segment(uid))
    }
}

impl GarageRepository for ApiGarageRepository {
    fn create(&self, uid: &str, garage: &Garage) -> Result<(), String> {
        let path = Self::path(uid);
        let (status, body) = self.client.post(&path, None)?;
        if status != reqwest::StatusCode::CONFLICT {
            require_success("POST", &path, status, body)?;
        }
        if !garage.vehicles.is_empty() {
            self.update(uid, garage)?;
        }
        Ok(())
    }

    fn update(&self, uid: &str, garage: &Garage) -> Result<(), String> {
        let path = Self::path(uid);
        let body = garage_to_api_body(garage)?;
        let (status, response) = self.client.put(&path, Some(body))?;
        require_success("PUT", &path, status, response)?;
        Ok(())
    }

    fn get(&self, uid: &str) -> Result<Option<Garage>, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(None);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(garage_from_api_record(body)?))
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

/// Virtual-garage persistence through forge-webapi.
///
/// The API has no full-replace endpoint for a virtual garage, so
/// `update` is emulated with the covered endpoints: read the current
/// record, then add the missing classnames per category (`POST
/// /players/{uid}/vgarage/{category}`) and remove the stale ones
/// (`DELETE /players/{uid}/vgarage/{category}/{classname}`). Adds
/// auto-create the record, so this works for a missing record too.
pub struct ApiVGarageRepository {
    client: ApiClient,
}

/// The six virtual-garage categories, in the model's field order.
const VGARAGE_CATEGORIES: [&str; 6] = ["cars", "armor", "helis", "planes", "naval", "other"];

fn vgarage_category<'a>(garage: &'a VGarage, category: &str) -> &'a [String] {
    match category {
        "cars" => &garage.cars,
        "armor" => &garage.armor,
        "helis" => &garage.helis,
        "planes" => &garage.planes,
        "naval" => &garage.naval,
        _ => &garage.other,
    }
}

impl ApiVGarageRepository {
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
                    "garage",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, virtual garage persistence disabled: {error}"
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
        format!("/players/{}/vgarage", encode_segment(uid))
    }

    fn category_path(uid: &str, category: &str) -> String {
        format!(
            "/players/{}/vgarage/{}",
            encode_segment(uid),
            encode_segment(category)
        )
    }
}

impl VGarageRepository for ApiVGarageRepository {
    fn create(&self, uid: &str, garage: &VGarage) -> Result<(), String> {
        let path = Self::path(uid);
        let (status, body) = self.client.post(&path, None)?;
        if status != reqwest::StatusCode::CONFLICT {
            require_success("POST", &path, status, body)?;
        }
        if VGARAGE_CATEGORIES
            .iter()
            .any(|category| !vgarage_category(garage, category).is_empty())
        {
            self.update(uid, garage)?;
        }
        Ok(())
    }

    fn update(&self, uid: &str, garage: &VGarage) -> Result<(), String> {
        let current = self.fetch(uid)?.unwrap_or_else(VGarage::new);
        for category in VGARAGE_CATEGORIES {
            let wanted = vgarage_category(garage, category);
            let have = vgarage_category(&current, category);
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

    fn fetch(&self, uid: &str) -> Result<Option<VGarage>, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(None);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(vgarage_from_api_record(body)?))
    }

    fn get(&self, uid: &str, field: &str) -> Result<Vec<String>, String> {
        if !VGARAGE_CATEGORIES.contains(&field) {
            return Err(format!("Unknown virtual garage field '{field}'"));
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
            .ok_or_else(|| "forge-webapi virtual garage decode failed".to_string())
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
