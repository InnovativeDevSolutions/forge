//! Store checkout command for the Arma 3 server extension.
//!
//! TODO(bridge): checkout stays local. It is a hot-state transaction
//! over the in-memory bank/org/locker/vlocker/vgarage services, and
//! the API's `POST /store/checkout` is a separate server-side flow
//! that charges and grants against API-side records — which requires
//! the bank and org domains to be bridged first. Durability of a
//! checkout still flows through the bridged repositories when the
//! individual hot states are saved (`save` on each domain).

use arma_rs::Group;
use forge_models::{StoreCheckoutContext, StoreCheckoutResult};
use forge_services::StoreService;

pub fn group() -> Group {
    Group::new().command("checkout", checkout)
}

fn serialize_result(result: &StoreCheckoutResult) -> String {
    match serde_json::to_string(result) {
        Ok(json) => json,
        Err(error) => format!(
            "Error: Failed to serialize store checkout result: {}",
            error
        ),
    }
}

pub fn checkout(json_data: String) -> String {
    let context: StoreCheckoutContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid store checkout JSON: {}", error),
    };

    let service = StoreService::new(
        crate::bank::hot_service(),
        crate::org::hot_service(),
        crate::locker::hot_service(),
        crate::v_locker::hot_service(),
        crate::v_garage::hot_service(),
    );

    match service.checkout(context) {
        Ok(result) => serialize_result(&result),
        Err(error) => format!("Error: {}", error),
    }
}
