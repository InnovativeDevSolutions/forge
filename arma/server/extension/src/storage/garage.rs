use super::common::*;
use super::*;

pub enum GarageStorageRepository {
    Surreal(SurrealGarageRepository),
}

impl GarageStorageRepository {
    pub fn configured() -> Self {
        Self::Surreal(SurrealGarageRepository)
    }
}

impl GarageRepository for GarageStorageRepository {
    fn create(&self, uid: &str, garage: &Garage) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(uid, garage),
        }
    }

    fn update(&self, uid: &str, garage: &Garage) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(uid, garage),
        }
    }

    fn get(&self, uid: &str) -> Result<Option<Garage>, String> {
        match self {
            Self::Surreal(repository) => repository.get(uid),
        }
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.delete(uid),
        }
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.exists(uid),
        }
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
}

impl VGarageStorageRepository {
    pub fn configured() -> Self {
        Self::Surreal(SurrealVGarageRepository)
    }
}

impl VGarageRepository for VGarageStorageRepository {
    fn create(&self, uid: &str, garage: &VGarage) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(uid, garage),
        }
    }

    fn update(&self, uid: &str, garage: &VGarage) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(uid, garage),
        }
    }

    fn fetch(&self, uid: &str) -> Result<Option<VGarage>, String> {
        match self {
            Self::Surreal(repository) => repository.fetch(uid),
        }
    }

    fn get(&self, uid: &str, field: &str) -> Result<Vec<String>, String> {
        match self {
            Self::Surreal(repository) => repository.get(uid, field),
        }
    }

    fn delete(&self, uid: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.delete(uid),
        }
    }

    fn exists(&self, uid: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.exists(uid),
        }
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
