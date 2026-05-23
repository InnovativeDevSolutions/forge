use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StoreCheckoutItemSeed {
    pub classname: String,
    pub category: String,
    pub price_value: f64,
    pub quantity: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StoreCheckoutVehicleSeed {
    pub classname: String,
    pub category: String,
    pub price_value: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StoreCheckoutContext {
    pub requester_uid: String,
    pub requester_name: String,
    pub org_id: String,
    pub requester_is_default_org_ceo: bool,
    pub payment_method: String,
    #[serde(default)]
    pub items: Vec<StoreCheckoutItemSeed>,
    #[serde(default)]
    pub vehicles: Vec<StoreCheckoutVehicleSeed>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StoreGrantedItem {
    pub classname: String,
    pub category: String,
    pub quantity: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StoreGrantedVehicle {
    pub classname: String,
    pub category: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct StoreCheckoutResult {
    pub charged_total: f64,
    pub payment_method: String,
    pub message: String,
    #[serde(default)]
    pub locker_granted: Vec<StoreGrantedItem>,
    #[serde(default)]
    pub vehicle_granted: Vec<StoreGrantedVehicle>,
    #[serde(default)]
    pub locker_patch: HashMap<String, serde_json::Value>,
    #[serde(default)]
    pub va_patch: HashMap<String, serde_json::Value>,
    #[serde(default)]
    pub vgarage_patch: HashMap<String, serde_json::Value>,
    #[serde(default)]
    pub bank_patch: HashMap<String, serde_json::Value>,
    #[serde(default)]
    pub org_patch: HashMap<String, serde_json::Value>,
    #[serde(default)]
    pub org_target_uids: Vec<String>,
}
