//! Durable repository selection for the extension.

mod actor;
mod bank;
mod common;
mod garage;
mod locker;
mod org;
mod phone;

pub use actor::{ActorStorageRepository, SurrealActorRepository};
pub use bank::{BankStorageRepository, SurrealBankRepository};
pub use garage::{
    GarageStorageRepository, SurrealGarageRepository, SurrealVGarageRepository,
    VGarageStorageRepository,
};
pub use locker::{
    LockerStorageRepository, SurrealLockerRepository, SurrealVLockerRepository,
    VLockerStorageRepository,
};
pub use org::{OrgStorageRepository, SurrealOrgRepository};
pub use phone::{PhoneStorageRepository, SurrealPhoneRepository};

use forge_models::{
    Actor, Bank, CreditLineSummary, Garage, HitPoints, Item, Locker, MemberSummary, Org,
    OrgAssetEntry, OrgFleetEntry, PhoneEmail, PhoneMessage, VGarage, VLocker, Vehicle,
};
use forge_repositories::{
    ActorRepository, BankRepository, GarageRepository, LockerRepository, OrgRepository,
    PhoneRepository, VGarageRepository, VLockerRepository,
};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};

use crate::RUNTIME;
use crate::surreal;
