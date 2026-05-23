use super::common::*;
use super::*;

pub enum LockerStorageRepository {
    Surreal(SurrealLockerRepository),
}

impl LockerStorageRepository {
    pub fn configured() -> Self {
        Self::Surreal(SurrealLockerRepository)
    }
}

impl LockerRepository for LockerStorageRepository {
    fn create(&self, uid: &str, locker: &Locker) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(uid, locker),
        }
    }

    fn update(&self, uid: &str, locker: &Locker) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(uid, locker),
        }
    }

    fn get(&self, uid: &str) -> Result<Option<Locker>, String> {
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
}

impl VLockerStorageRepository {
    pub fn configured() -> Self {
        Self::Surreal(SurrealVLockerRepository)
    }
}

impl VLockerRepository for VLockerStorageRepository {
    fn create(&self, uid: &str, locker: &VLocker) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(uid, locker),
        }
    }

    fn update(&self, uid: &str, locker: &VLocker) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(uid, locker),
        }
    }

    fn fetch(&self, uid: &str) -> Result<Option<VLocker>, String> {
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
