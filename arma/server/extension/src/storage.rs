//! Durable repository selection for the extension.
//!
//! The forge-webapi is the only persistence backend: every service
//! uses an `Api*Repository`. There is no fallback.

mod actor;
mod bank;
mod garage;
mod locker;
mod org;
mod phone;

pub use actor::ApiActorRepository;
pub use bank::ApiBankRepository;
pub use garage::{ApiGarageRepository, ApiVGarageRepository};
pub use locker::{ApiLockerRepository, ApiVLockerRepository};
pub use org::ApiOrgRepository;
pub use phone::ApiPhoneRepository;

use forge_models::{
    Actor, Bank, Garage, Locker, MemberSummary, Org, OrgAssetEntry, OrgFleetEntry, PhoneEmail,
    PhoneMessage, VGarage, VLocker,
};
use forge_repositories::{
    ActorRepository, BankRepository, GarageRepository, LockerRepository, OrgRepository,
    PhoneRepository, VGarageRepository, VLockerRepository,
};
use std::collections::HashMap;
