use forge_models::{
    Bank, BankCheckoutContext, BankMutationResult, EquipmentCategory, HotOrgRecord, Item, Locker,
    OrgFleetEntry, StoreCheckoutContext, StoreCheckoutResult, StoreGrantedItem,
    StoreGrantedVehicle, VGarage, VLocker, VehicleCategory,
};
use forge_repositories::{
    BankHotRepository, BankRepository, LockerHotRepository, LockerRepository, OrgHotRepository,
    OrgRepository, VGarageHotRepository, VGarageRepository, VLockerHotRepository,
    VLockerRepository,
};
use serde_json::json;
use std::collections::HashMap;

use crate::{
    BankHotStateService, LockerHotStateService, OrgHotStateService, VGarageHotStateService,
    VLockerHotStateService,
};

pub trait StoreBankBackend {
    fn get_bank(&self, uid: &str) -> Result<Bank, String>;
    fn preview_checkout(
        &self,
        uid: &str,
        amount: f64,
        source: &str,
    ) -> Result<BankMutationResult, String>;
    fn override_bank(&self, uid: &str, bank: &Bank) -> Result<Bank, String>;
}

pub trait StoreOrgBackend {
    fn get_org(&self, org_id: &str) -> Result<HotOrgRecord, String>;
    fn override_org(&self, org_id: &str, org: HotOrgRecord) -> Result<HotOrgRecord, String>;
}

pub trait StoreLockerBackend {
    fn get_locker(&self, uid: &str) -> Result<Locker, String>;
    fn override_locker(&self, uid: &str, items: HashMap<String, Item>) -> Result<Locker, String>;
}

pub trait StoreVLockerBackend {
    fn fetch_locker(&self, uid: &str) -> Result<VLocker, String>;
    fn override_locker(&self, uid: &str, locker: VLocker) -> Result<VLocker, String>;
}

pub trait StoreVGarageBackend {
    fn fetch_garage(&self, uid: &str) -> Result<VGarage, String>;
    fn override_garage(&self, uid: &str, garage: VGarage) -> Result<VGarage, String>;
}

impl<R: BankRepository, H: BankHotRepository> StoreBankBackend for BankHotStateService<R, H> {
    fn get_bank(&self, uid: &str) -> Result<Bank, String> {
        BankHotStateService::get_bank(self, uid.to_string())
    }

    fn preview_checkout(
        &self,
        uid: &str,
        amount: f64,
        source: &str,
    ) -> Result<BankMutationResult, String> {
        BankHotStateService::charge_checkout(
            self,
            uid.to_string(),
            amount,
            BankCheckoutContext {
                source_field: source.to_string(),
                commit: false,
            },
        )
    }

    fn override_bank(&self, uid: &str, bank: &Bank) -> Result<Bank, String> {
        let json = serde_json::to_string(bank)
            .map_err(|error| format!("Invalid bank override JSON: {}", error))?;
        BankHotStateService::override_bank(self, uid.to_string(), json)
    }
}

impl<R: BankRepository, H: BankHotRepository> StoreBankBackend for &BankHotStateService<R, H> {
    fn get_bank(&self, uid: &str) -> Result<Bank, String> {
        BankHotStateService::get_bank(self, uid.to_string())
    }

    fn preview_checkout(
        &self,
        uid: &str,
        amount: f64,
        source: &str,
    ) -> Result<BankMutationResult, String> {
        BankHotStateService::charge_checkout(
            self,
            uid.to_string(),
            amount,
            BankCheckoutContext {
                source_field: source.to_string(),
                commit: false,
            },
        )
    }

    fn override_bank(&self, uid: &str, bank: &Bank) -> Result<Bank, String> {
        let json = serde_json::to_string(bank)
            .map_err(|error| format!("Invalid bank override JSON: {}", error))?;
        BankHotStateService::override_bank(self, uid.to_string(), json)
    }
}

impl<R: OrgRepository, H: OrgHotRepository> StoreOrgBackend for OrgHotStateService<R, H> {
    fn get_org(&self, org_id: &str) -> Result<HotOrgRecord, String> {
        OrgHotStateService::get_org(self, org_id.to_string())
    }

    fn override_org(&self, org_id: &str, org: HotOrgRecord) -> Result<HotOrgRecord, String> {
        OrgHotStateService::override_org(self, org_id.to_string(), org)
    }
}

impl<R: OrgRepository, H: OrgHotRepository> StoreOrgBackend for &OrgHotStateService<R, H> {
    fn get_org(&self, org_id: &str) -> Result<HotOrgRecord, String> {
        OrgHotStateService::get_org(self, org_id.to_string())
    }

    fn override_org(&self, org_id: &str, org: HotOrgRecord) -> Result<HotOrgRecord, String> {
        OrgHotStateService::override_org(self, org_id.to_string(), org)
    }
}

impl<R: LockerRepository, H: LockerHotRepository> StoreLockerBackend
    for LockerHotStateService<R, H>
{
    fn get_locker(&self, uid: &str) -> Result<Locker, String> {
        LockerHotStateService::get_locker(self, uid.to_string())
    }

    fn override_locker(&self, uid: &str, items: HashMap<String, Item>) -> Result<Locker, String> {
        LockerHotStateService::override_locker(self, uid.to_string(), items)
    }
}

impl<R: LockerRepository, H: LockerHotRepository> StoreLockerBackend
    for &LockerHotStateService<R, H>
{
    fn get_locker(&self, uid: &str) -> Result<Locker, String> {
        LockerHotStateService::get_locker(self, uid.to_string())
    }

    fn override_locker(&self, uid: &str, items: HashMap<String, Item>) -> Result<Locker, String> {
        LockerHotStateService::override_locker(self, uid.to_string(), items)
    }
}

impl<R: VLockerRepository, H: VLockerHotRepository> StoreVLockerBackend
    for VLockerHotStateService<R, H>
{
    fn fetch_locker(&self, uid: &str) -> Result<VLocker, String> {
        VLockerHotStateService::fetch_locker(self, uid)
    }

    fn override_locker(&self, uid: &str, locker: VLocker) -> Result<VLocker, String> {
        VLockerHotStateService::override_locker(self, uid, locker)
    }
}

impl<R: VLockerRepository, H: VLockerHotRepository> StoreVLockerBackend
    for &VLockerHotStateService<R, H>
{
    fn fetch_locker(&self, uid: &str) -> Result<VLocker, String> {
        VLockerHotStateService::fetch_locker(self, uid)
    }

    fn override_locker(&self, uid: &str, locker: VLocker) -> Result<VLocker, String> {
        VLockerHotStateService::override_locker(self, uid, locker)
    }
}

impl<R: VGarageRepository, H: VGarageHotRepository> StoreVGarageBackend
    for VGarageHotStateService<R, H>
{
    fn fetch_garage(&self, uid: &str) -> Result<VGarage, String> {
        VGarageHotStateService::fetch_garage(self, uid)
    }

    fn override_garage(&self, uid: &str, garage: VGarage) -> Result<VGarage, String> {
        VGarageHotStateService::override_garage(self, uid, garage)
    }
}

impl<R: VGarageRepository, H: VGarageHotRepository> StoreVGarageBackend
    for &VGarageHotStateService<R, H>
{
    fn fetch_garage(&self, uid: &str) -> Result<VGarage, String> {
        VGarageHotStateService::fetch_garage(self, uid)
    }

    fn override_garage(&self, uid: &str, garage: VGarage) -> Result<VGarage, String> {
        VGarageHotStateService::override_garage(self, uid, garage)
    }
}

pub struct StoreService<B, O, L, VL, VG> {
    bank: B,
    org: O,
    locker: L,
    vlocker: VL,
    vgarage: VG,
}

impl<B, O, L, VL, VG> StoreService<B, O, L, VL, VG> {
    pub fn new(bank: B, org: O, locker: L, vlocker: VL, vgarage: VG) -> Self {
        Self {
            bank,
            org,
            locker,
            vlocker,
            vgarage,
        }
    }
}

impl<B, O, L, VL, VG> StoreService<B, O, L, VL, VG>
where
    B: StoreBankBackend,
    O: StoreOrgBackend,
    L: StoreLockerBackend,
    VL: StoreVLockerBackend,
    VG: StoreVGarageBackend,
{
    pub fn checkout(&self, context: StoreCheckoutContext) -> Result<StoreCheckoutResult, String> {
        if context.requester_uid.trim().is_empty() {
            return Err("A valid requester UID is required.".to_string());
        }
        if context.items.is_empty() && context.vehicles.is_empty() {
            return Err("Add at least one item before checkout.".to_string());
        }

        let charged_total = checkout_total(&context);
        if charged_total <= 0.0 {
            return Err("Checkout total must be greater than zero.".to_string());
        }

        let requester_uid = context.requester_uid.trim();
        let payment_method = context.payment_method.trim().to_ascii_lowercase();

        let original_locker = self.locker.get_locker(requester_uid)?;
        let original_vlocker = self.vlocker.fetch_locker(requester_uid)?;
        let original_vgarage = self.vgarage.fetch_garage(requester_uid)?;

        let mut next_locker = original_locker.clone();
        let mut next_vlocker = original_vlocker.clone();
        let mut next_vgarage = original_vgarage.clone();

        let mut locker_patch = HashMap::new();
        let mut va_patch = HashMap::new();
        let mut vgarage_patch = HashMap::new();
        let mut locker_granted = Vec::new();
        let mut vehicle_granted = Vec::new();
        let mut va_categories_changed: Vec<&str> = Vec::new();
        let mut vgarage_categories_changed: Vec<&str> = Vec::new();

        for item_seed in &context.items {
            if item_seed.classname.trim().is_empty() || item_seed.quantity == 0 {
                return Err("Checkout contains an invalid item entry.".to_string());
            }

            let locker_category = resolve_locker_category(&item_seed.category)?;
            let arsenal_category = resolve_arsenal_category(&item_seed.category)?;

            let existing_amount = next_locker
                .items
                .get(&item_seed.classname)
                .map(|entry| entry.amount)
                .unwrap_or(0);
            let updated_item = Item {
                category: locker_category.to_string(),
                classname: item_seed.classname.clone(),
                amount: existing_amount.saturating_add(item_seed.quantity),
            };

            next_locker
                .items
                .insert(item_seed.classname.clone(), updated_item.clone());
            locker_patch.insert(
                item_seed.classname.clone(),
                serde_json::to_value(&updated_item)
                    .map_err(|error| format!("Failed to serialize locker patch: {}", error))?,
            );
            locker_granted.push(StoreGrantedItem {
                classname: item_seed.classname.clone(),
                category: locker_category.to_string(),
                quantity: item_seed.quantity,
            });

            match arsenal_category {
                EquipmentCategory::Items => {
                    push_unique(&mut next_vlocker.items, &item_seed.classname);
                    push_unique_str(&mut va_categories_changed, "items");
                }
                EquipmentCategory::Weapons => {
                    push_unique(&mut next_vlocker.weapons, &item_seed.classname);
                    push_unique_str(&mut va_categories_changed, "weapons");
                }
                EquipmentCategory::Magazines => {
                    push_unique(&mut next_vlocker.magazines, &item_seed.classname);
                    push_unique_str(&mut va_categories_changed, "magazines");
                }
                EquipmentCategory::Backpacks => {
                    push_unique(&mut next_vlocker.backpacks, &item_seed.classname);
                    push_unique_str(&mut va_categories_changed, "backpacks");
                }
            }
        }

        if next_locker.items.len() > 25 {
            return Err(
                "Locker capacity would exceed 25 unique items. Clear space before checkout."
                    .to_string(),
            );
        }

        for category in va_categories_changed {
            match category {
                "items" => {
                    va_patch.insert(category.to_string(), json!(next_vlocker.items));
                }
                "weapons" => {
                    va_patch.insert(category.to_string(), json!(next_vlocker.weapons));
                }
                "magazines" => {
                    va_patch.insert(category.to_string(), json!(next_vlocker.magazines));
                }
                "backpacks" => {
                    va_patch.insert(category.to_string(), json!(next_vlocker.backpacks));
                }
                _ => {}
            }
        }

        for vehicle_seed in &context.vehicles {
            if vehicle_seed.classname.trim().is_empty() {
                return Err("Vehicle checkout entry was missing a classname.".to_string());
            }

            let vehicle_category = resolve_vehicle_category(&vehicle_seed.category)?;
            match vehicle_category {
                VehicleCategory::Cars => {
                    push_unique(&mut next_vgarage.cars, &vehicle_seed.classname);
                    push_unique_str(&mut vgarage_categories_changed, "cars");
                }
                VehicleCategory::Armor => {
                    push_unique(&mut next_vgarage.armor, &vehicle_seed.classname);
                    push_unique_str(&mut vgarage_categories_changed, "armor");
                }
                VehicleCategory::Helis => {
                    push_unique(&mut next_vgarage.helis, &vehicle_seed.classname);
                    push_unique_str(&mut vgarage_categories_changed, "helis");
                }
                VehicleCategory::Planes => {
                    push_unique(&mut next_vgarage.planes, &vehicle_seed.classname);
                    push_unique_str(&mut vgarage_categories_changed, "planes");
                }
                VehicleCategory::Naval => {
                    push_unique(&mut next_vgarage.naval, &vehicle_seed.classname);
                    push_unique_str(&mut vgarage_categories_changed, "naval");
                }
                VehicleCategory::Other => {
                    push_unique(&mut next_vgarage.other, &vehicle_seed.classname);
                    push_unique_str(&mut vgarage_categories_changed, "other");
                }
            }

            vehicle_granted.push(StoreGrantedVehicle {
                classname: vehicle_seed.classname.clone(),
                category: vehicle_seed.category.clone(),
            });
        }

        for category in vgarage_categories_changed {
            match category {
                "cars" => {
                    vgarage_patch.insert(category.to_string(), json!(next_vgarage.cars));
                }
                "armor" => {
                    vgarage_patch.insert(category.to_string(), json!(next_vgarage.armor));
                }
                "helis" => {
                    vgarage_patch.insert(category.to_string(), json!(next_vgarage.helis));
                }
                "planes" => {
                    vgarage_patch.insert(category.to_string(), json!(next_vgarage.planes));
                }
                "naval" => {
                    vgarage_patch.insert(category.to_string(), json!(next_vgarage.naval));
                }
                "other" => {
                    vgarage_patch.insert(category.to_string(), json!(next_vgarage.other));
                }
                _ => {}
            }
        }

        let mut bank_patch = HashMap::new();
        let mut final_bank = None;
        let mut original_bank = None;

        let mut org_patch = HashMap::new();
        let mut org_target_uids = Vec::new();
        let mut final_org = None;
        let mut original_org = None;

        match payment_method.as_str() {
            "cash" | "bank" => {
                original_bank = Some(self.bank.get_bank(requester_uid)?);
                let preview = self.bank.preview_checkout(
                    requester_uid,
                    charged_total,
                    payment_method.as_str(),
                )?;
                bank_patch = preview.patch.clone();
                final_bank = Some(preview.account);
            }
            "org_funds" | "credit_line" => {
                if context.org_id.trim().is_empty() {
                    return Err("A valid organization is required for this checkout.".to_string());
                }

                let mut org = self.org.get_org(&context.org_id)?;
                original_org = Some(org.clone());

                match payment_method.as_str() {
                    "org_funds" => {
                        if !can_manage_treasury(
                            &org,
                            requester_uid,
                            context.requester_is_default_org_ceo,
                        ) {
                            return Err(
                                "Only the organization leader or CEO can charge org funds."
                                    .to_string(),
                            );
                        }
                        if org.funds < charged_total {
                            return Err(
                                "Organization funds cannot cover this checkout.".to_string()
                            );
                        }
                        org.funds -= charged_total;
                        org_patch.insert("funds".to_string(), json!(org.funds));
                    }
                    "credit_line" => {
                        let credit_line =
                            org.credit_lines.get_mut(requester_uid).ok_or_else(|| {
                                "Assigned credit line cannot cover this checkout.".to_string()
                            })?;
                        credit_line.normalize();
                        if credit_line.available_amount < charged_total {
                            return Err(
                                "Assigned credit line cannot cover this checkout.".to_string()
                            );
                        }

                        credit_line.available_amount =
                            round_currency(credit_line.available_amount - charged_total);
                        credit_line.approved_amount = credit_line.available_amount;
                        credit_line.outstanding_principal =
                            round_currency(credit_line.outstanding_principal + charged_total);
                        credit_line.amount_due = round_currency(
                            credit_line.amount_due
                                + (charged_total * (1.0 + credit_line.interest_rate)),
                        );
                        credit_line.amount = credit_line.available_amount;
                        org_patch.insert("credit_lines".to_string(), json!(org.credit_lines));
                    }
                    _ => unreachable!(),
                }

                if payment_method == "org_funds" && !context.vehicles.is_empty() {
                    add_org_fleet_vehicles(&mut org, &context.vehicles);
                    org_patch.insert("fleet".to_string(), json!(org.fleet));
                }

                org_target_uids = resolve_member_uids(&org, Some(requester_uid));
                final_org = Some(org);
            }
            _ => return Err("Selected payment source is unsupported.".to_string()),
        }

        let mut locker_saved = false;
        let mut vlocker_saved = false;
        let mut vgarage_saved = false;
        let mut org_saved = false;

        let commit_result = (|| -> Result<(), String> {
            if !locker_patch.is_empty() {
                self.locker
                    .override_locker(requester_uid, next_locker.items.clone())?;
                locker_saved = true;
            }

            if !va_patch.is_empty() {
                self.vlocker
                    .override_locker(requester_uid, next_vlocker.clone())?;
                vlocker_saved = true;
            }

            if !vgarage_patch.is_empty() {
                self.vgarage
                    .override_garage(requester_uid, next_vgarage.clone())?;
                vgarage_saved = true;
            }

            if let Some(org) = final_org.clone() {
                self.org.override_org(&context.org_id, org)?;
                org_saved = true;
            }

            if let Some(bank) = final_bank.as_ref() {
                self.bank.override_bank(requester_uid, bank)?;
            }

            Ok(())
        })();

        if let Err(error) = commit_result {
            if org_saved && let Some(org) = original_org {
                let org_id = org.id.clone();
                let _ = self.org.override_org(&org_id, org);
            }
            if vgarage_saved {
                let _ = self
                    .vgarage
                    .override_garage(requester_uid, original_vgarage);
            }
            if vlocker_saved {
                let _ = self
                    .vlocker
                    .override_locker(requester_uid, original_vlocker);
            }
            if locker_saved {
                let _ = self
                    .locker
                    .override_locker(requester_uid, original_locker.items);
            }
            if let Some(bank) = original_bank {
                let _ = self.bank.override_bank(requester_uid, &bank);
            }
            return Err(error);
        }

        Ok(StoreCheckoutResult {
            charged_total,
            payment_method,
            message: format!(
                "Checkout completed. {} charged, {} locker grant(s), {} vehicle unlock(s).",
                format_currency(charged_total),
                locker_granted.len(),
                vehicle_granted.len()
            ),
            locker_granted,
            vehicle_granted,
            locker_patch,
            va_patch,
            vgarage_patch,
            bank_patch,
            org_patch,
            org_target_uids,
        })
    }
}

fn checkout_total(context: &StoreCheckoutContext) -> f64 {
    let item_total = context
        .items
        .iter()
        .map(|entry| entry.price_value.max(0.0) * f64::from(entry.quantity))
        .sum::<f64>();
    let vehicle_total = context
        .vehicles
        .iter()
        .map(|entry| entry.price_value.max(0.0))
        .sum::<f64>();

    (item_total + vehicle_total).floor()
}

fn resolve_locker_category(category: &str) -> Result<&'static str, String> {
    match category.trim().to_ascii_lowercase().as_str() {
        "item" | "attachment" => Ok("item"),
        "weapon" => Ok("weapon"),
        "magazine" => Ok("magazine"),
        "backpack" => Ok("backpack"),
        other => Err(format!("Store item category '{}' is unsupported.", other)),
    }
}

fn resolve_arsenal_category(category: &str) -> Result<EquipmentCategory, String> {
    match category.trim().to_ascii_lowercase().as_str() {
        "item" | "attachment" => Ok(EquipmentCategory::Items),
        "weapon" => Ok(EquipmentCategory::Weapons),
        "magazine" => Ok(EquipmentCategory::Magazines),
        "backpack" => Ok(EquipmentCategory::Backpacks),
        other => Err(format!("Store item category '{}' is unsupported.", other)),
    }
}

fn resolve_vehicle_category(category: &str) -> Result<VehicleCategory, String> {
    match category.trim().to_ascii_lowercase().as_str() {
        "cars" => Ok(VehicleCategory::Cars),
        "armor" => Ok(VehicleCategory::Armor),
        "helis" | "heli" => Ok(VehicleCategory::Helis),
        "planes" => Ok(VehicleCategory::Planes),
        "naval" => Ok(VehicleCategory::Naval),
        "other" => Ok(VehicleCategory::Other),
        other => Err(format!("Vehicle category '{}' is unsupported.", other)),
    }
}

fn push_unique(values: &mut Vec<String>, value: &str) {
    if !values.iter().any(|entry| entry == value) {
        values.push(value.to_string());
    }
}

fn push_unique_str<'a>(values: &mut Vec<&'a str>, value: &'a str) {
    if !values.contains(&value) {
        values.push(value);
    }
}

fn can_manage_treasury(
    org: &HotOrgRecord,
    requester_uid: &str,
    requester_is_default_org_ceo: bool,
) -> bool {
    org.owner == requester_uid
        || ((org.id.eq_ignore_ascii_case("default") || org.owner.eq_ignore_ascii_case("server"))
            && requester_is_default_org_ceo)
}

fn resolve_member_uids(org: &HotOrgRecord, requester_uid: Option<&str>) -> Vec<String> {
    let mut member_uids = org.members.keys().cloned().collect::<Vec<_>>();
    if let Some(uid) = requester_uid
        && !uid.is_empty()
        && !member_uids.iter().any(|member_uid| member_uid == uid)
    {
        member_uids.push(uid.to_string());
    }
    member_uids
}

fn add_org_fleet_vehicles(
    org: &mut HotOrgRecord,
    vehicles: &[forge_models::StoreCheckoutVehicleSeed],
) {
    let mut fleet_index = org.fleet.len();
    for vehicle in vehicles {
        if vehicle.classname.trim().is_empty() {
            continue;
        }

        let fleet_type = vehicle.category.trim().to_ascii_lowercase();
        let mut fleet_key = format!("{}_{}", vehicle.classname, fleet_index);
        while org.fleet.contains_key(&fleet_key) {
            fleet_index += 1;
            fleet_key = format!("{}_{}", vehicle.classname, fleet_index);
        }

        org.fleet.insert(
            fleet_key,
            OrgFleetEntry {
                classname: vehicle.classname.clone(),
                name: vehicle.classname.clone(),
                fleet_type,
                status: "Ready".to_string(),
                damage: "0%".to_string(),
            },
        );
        fleet_index += 1;
    }
}

fn format_currency(amount: f64) -> String {
    let rounded = amount.max(0.0).round() as i64;
    let digits = rounded.to_string();
    let mut formatted = String::new();

    for (index, character) in digits.chars().rev().enumerate() {
        if index > 0 && index % 3 == 0 {
            formatted.push(',');
        }
        formatted.push(character);
    }

    format!("${}", formatted.chars().rev().collect::<String>())
}

fn round_currency(amount: f64) -> f64 {
    (amount.max(0.0) * 100.0).round() / 100.0
}
