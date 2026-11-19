use super::common::*;
use super::*;
use crate::api::{
    ApiClient, encode_segment, garage_from_api_record, garage_to_api_body, require_success,
    vgarage_from_api_record,
};

pub enum GarageStorageRepository {
    Surreal(SurrealGarageRepository),
    Api(ApiGarageRepository),
}

impl GarageStorageRepository {
    pub fn configured() -> Self {
        if crate::config::load().api.enabled {
            match ApiGarageRepository::new() {
                Ok(repository) => Self::Api(repository),
                Err(error) => {
                    crate::log::log(
                        "garage",
                        "ERROR",
                        &format!(
                            "forge-webapi bridge unavailable, falling back to SurrealDB: {error}"
                        ),
                    );
                    Self::Surreal(SurrealGarageRepository)
                }
            }
        } else {
            Self::Surreal(SurrealGarageRepository)
        }
    }
}

impl GarageRepository for GarageStorageRepository {
    fn create(&self, uid: &str, garage: &Garage) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(uid, garage),
            Self::Api(repository) => repository.create(uid, garage),
        }
    }

    fn update(&self, uid: &str, garage: &Garage) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(uid, garage),
            Self::Api(repository) => repository.update(uid, garage),
        }
    }

    fn get(&self, uid: &str) -> Result<Option<Garage>, String> {
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

/// Garage persistence through forge-webapi (`POST/GET/PUT
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
        // TODO(bridge): the API has no DELETE /players/{uid}/garage yet,
        // so deletes still target the legacy SurrealDB tables. Once the
        // API gains the endpoint, delete the API record here instead —
        // until then an API-owned garage is NOT removed by this call
        // (the legacy record deleted here is the pre-bridge one, if any).
        SurrealGarageRepository.delete(uid)
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

pub struct SurrealGarageRepository;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct GarageOwnerRecord {
    uid: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct GarageVehicleRecord {
    uid: String,
    plate: String,
    classname: String,
    fuel: f64,
    damage: f64,
    hit_points: HitPoints,
}

fn garage_vehicle_id(uid: &str, plate: &str) -> String {
    format!("{}:{}", uid, plate)
}

fn garage_from_vehicle_records(records: Vec<GarageVehicleRecord>) -> Garage {
    let vehicles = records
        .into_iter()
        .map(|record| {
            let vehicle = Vehicle {
                plate: record.plate.clone(),
                classname: record.classname,
                fuel: record.fuel,
                damage: record.damage,
                hit_points: record.hit_points,
            };
            (record.plate, vehicle)
        })
        .collect();

    Garage { vehicles }
}

impl GarageRepository for SurrealGarageRepository {
    fn create(&self, uid: &str, garage: &Garage) -> Result<(), String> {
        self.update(uid, garage)
    }

    fn update(&self, uid: &str, garage: &Garage) -> Result<(), String> {
        let owner = GarageOwnerRecord {
            uid: uid.to_string(),
        };
        surreal_upsert("garage", uid, "garage owner", &owner)?;
        surreal_delete_by_uid("garage_vehicle", "garage vehicles", uid)?;

        for (plate_key, vehicle) in &garage.vehicles {
            let plate = if vehicle.plate.trim().is_empty() {
                plate_key.clone()
            } else {
                vehicle.plate.clone()
            };
            let record = GarageVehicleRecord {
                uid: uid.to_string(),
                plate: plate.clone(),
                classname: vehicle.classname.clone(),
                fuel: vehicle.fuel,
                damage: vehicle.damage,
                hit_points: vehicle.hit_points.clone(),
            };
            surreal_upsert(
                "garage_vehicle",
                &garage_vehicle_id(uid, &plate),
                "garage vehicle",
                &record,
            )?;
        }

        Ok(())
    }

    fn get(&self, uid: &str) -> Result<Option<Garage>, String> {
        if surreal_select::<GarageOwnerRecord>("garage", uid, "garage owner")?.is_none() {
            return Ok(None);
        }

        let vehicle_records =
            surreal_select_by_uid::<GarageVehicleRecord>("garage_vehicle", "garage vehicles", uid)?;
        Ok(Some(garage_from_vehicle_records(vehicle_records)))
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        surreal_delete_by_uid("garage_vehicle", "garage vehicles", uid)?;
        surreal_delete::<GarageOwnerRecord>("garage", uid, "garage owner")
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        surreal_select::<GarageOwnerRecord>("garage", uid, "garage owner")
            .map(|garage| garage.is_some())
    }
}

pub enum VGarageStorageRepository {
    Surreal(SurrealVGarageRepository),
    Api(ApiVGarageRepository),
}

impl VGarageStorageRepository {
    pub fn configured() -> Self {
        if crate::config::load().api.enabled {
            match ApiVGarageRepository::new() {
                Ok(repository) => Self::Api(repository),
                Err(error) => {
                    crate::log::log(
                        "garage",
                        "ERROR",
                        &format!(
                            "forge-webapi bridge unavailable, falling back to SurrealDB: {error}"
                        ),
                    );
                    Self::Surreal(SurrealVGarageRepository)
                }
            }
        } else {
            Self::Surreal(SurrealVGarageRepository)
        }
    }
}

impl VGarageRepository for VGarageStorageRepository {
    fn create(&self, uid: &str, garage: &VGarage) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(uid, garage),
            Self::Api(repository) => repository.create(uid, garage),
        }
    }

    fn update(&self, uid: &str, garage: &VGarage) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(uid, garage),
            Self::Api(repository) => repository.update(uid, garage),
        }
    }

    fn fetch(&self, uid: &str) -> Result<Option<VGarage>, String> {
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
        // TODO(bridge): the API has no DELETE /players/{uid}/vgarage yet,
        // so deletes still target the legacy SurrealDB tables (see the
        // note on `ApiGarageRepository::delete`).
        SurrealVGarageRepository.delete(uid)
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

pub struct SurrealVGarageRepository;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct VGarageOwnerRecord {
    uid: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct GarageUnlockRecord {
    uid: String,
    category: String,
    classname: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    source: Option<String>,
}

fn garage_unlock_id(uid: &str, category: &str, classname: &str) -> String {
    format!("{}:{}:{}", uid, category, classname)
}

fn push_garage_unlock(garage: &mut VGarage, category: &str, classname: String) {
    let target = match category {
        "cars" => &mut garage.cars,
        "armor" => &mut garage.armor,
        "helis" => &mut garage.helis,
        "planes" => &mut garage.planes,
        "naval" => &mut garage.naval,
        "other" => &mut garage.other,
        _ => return,
    };

    if !target.contains(&classname) {
        target.push(classname);
    }
}

fn vgarage_from_unlock_records(records: Vec<GarageUnlockRecord>) -> VGarage {
    let mut garage = VGarage {
        cars: Vec::new(),
        armor: Vec::new(),
        helis: Vec::new(),
        planes: Vec::new(),
        naval: Vec::new(),
        other: Vec::new(),
    };

    for record in records {
        push_garage_unlock(&mut garage, &record.category, record.classname);
    }

    garage
}

fn upsert_garage_unlocks(uid: &str, category: &str, classnames: &[String]) -> Result<(), String> {
    for classname in classnames {
        let record = GarageUnlockRecord {
            uid: uid.to_string(),
            category: category.to_string(),
            classname: classname.clone(),
            source: None,
        };
        surreal_upsert(
            "garage_unlock",
            &garage_unlock_id(uid, category, classname),
            "garage unlock",
            &record,
        )?;
    }

    Ok(())
}

impl VGarageRepository for SurrealVGarageRepository {
    fn create(&self, uid: &str, garage: &VGarage) -> Result<(), String> {
        self.update(uid, garage)
    }

    fn update(&self, uid: &str, garage: &VGarage) -> Result<(), String> {
        let owner = VGarageOwnerRecord {
            uid: uid.to_string(),
        };
        surreal_upsert("owned_garage", uid, "virtual garage owner", &owner)?;
        surreal_delete_by_uid("garage_unlock", "garage unlocks", uid)?;
        upsert_garage_unlocks(uid, "cars", &garage.cars)?;
        upsert_garage_unlocks(uid, "armor", &garage.armor)?;
        upsert_garage_unlocks(uid, "helis", &garage.helis)?;
        upsert_garage_unlocks(uid, "planes", &garage.planes)?;
        upsert_garage_unlocks(uid, "naval", &garage.naval)?;
        upsert_garage_unlocks(uid, "other", &garage.other)?;
        Ok(())
    }

    fn fetch(&self, uid: &str) -> Result<Option<VGarage>, String> {
        if surreal_select::<VGarageOwnerRecord>("owned_garage", uid, "virtual garage owner")?
            .is_none()
        {
            return Ok(None);
        }

        let unlock_records =
            surreal_select_by_uid::<GarageUnlockRecord>("garage_unlock", "garage unlocks", uid)?;
        Ok(Some(vgarage_from_unlock_records(unlock_records)))
    }

    fn get(&self, uid: &str, field: &str) -> Result<Vec<String>, String> {
        let garage = self.fetch(uid)?.unwrap_or_else(VGarage::new);
        match field {
            "cars" => Ok(garage.cars),
            "armor" => Ok(garage.armor),
            "helis" => Ok(garage.helis),
            "planes" => Ok(garage.planes),
            "naval" => Ok(garage.naval),
            "other" => Ok(garage.other),
            _ => Err(format!("Unknown virtual garage field '{}'", field)),
        }
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        surreal_delete_by_uid("garage_unlock", "garage unlocks", uid)?;
        surreal_delete::<VGarageOwnerRecord>("owned_garage", uid, "virtual garage owner")
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        surreal_select::<VGarageOwnerRecord>("owned_garage", uid, "virtual garage owner")
            .map(|garage| garage.is_some())
    }
}
