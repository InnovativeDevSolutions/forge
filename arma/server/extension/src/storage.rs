//! Durable repository selection for the extension.
//!
//! The forge-webapi is the only persistence backend: every service
//! uses an `Api*Repository`. The `Legacy*Repository` types are
//! migration-only — they read a legacy SurrealDB row once so it can
//! be moved into the API, then delete it. There is no fallback.

mod actor;
mod bank;
mod common;
mod garage;
mod locker;
mod org;
mod phone;

pub use actor::{ApiActorRepository, LegacyActorRepository};
pub use bank::{ApiBankRepository, LegacyBankRepository};
pub use garage::{
    ApiGarageRepository, ApiVGarageRepository, LegacyGarageRepository, LegacyVGarageRepository,
};
pub use locker::{
    ApiLockerRepository, ApiVLockerRepository, LegacyLockerRepository, LegacyVLockerRepository,
};
pub use org::{ApiOrgRepository, LegacyOrgRepository};
pub use phone::{ApiPhoneRepository, LegacyPhoneRepository};

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
