//! Organization management operations for the Arma 3 server extension.
//!
//! Provides Arma 3 extension commands for organization data storage, retrieval, and updates.
//! Handles SQF command mapping and parameter validation.

use arma_rs::Group;
use forge_models::{
    HotOrgRecord, OrgAssetGrantSeed, OrgCheckoutContext, OrgCreditLineContext,
    OrgCreditLineRepaymentContext, OrgCreditLineRepaymentResult, OrgDisbandResult,
    OrgEnsureMemberContext, OrgFleetGrantSeed, OrgGrantContext, OrgInviteContext,
    OrgInviteDecisionContext, OrgInviteDecisionResult, OrgInviteRecord, OrgInviteResult,
    OrgLeaveContext, OrgLeaveResult, OrgRegisterContext,
};
use forge_repositories::InMemoryOrgHotRepository;
use forge_services::{OrgHotStateService, OrgService};
use std::sync::LazyLock;

use crate::enqueue_persistence_task;
use crate::log::log;
use crate::storage::OrgStorageRepository;

/// Global organization service instance.
///
/// Lazily initialized singleton combining repository and service layers.
static ORG_SERVICE: LazyLock<OrgService<OrgStorageRepository>> =
    LazyLock::new(|| OrgService::new(OrgStorageRepository::configured()));
static HOT_ORG_SERVICE: LazyLock<
    OrgHotStateService<OrgStorageRepository, InMemoryOrgHotRepository>,
> = LazyLock::new(|| {
    let repository = OrgStorageRepository::configured();
    let hot_repository = InMemoryOrgHotRepository::new();
    OrgHotStateService::new(repository, hot_repository)
});

pub(crate) fn hot_service()
-> &'static OrgHotStateService<OrgStorageRepository, InMemoryOrgHotRepository> {
    &HOT_ORG_SERVICE
}

/// Creates the Arma 3 command group for organization operations.
///
/// Registers commands: `get`, `exists`, `create`, `update`, `delete`.
pub fn group() -> Group {
    Group::new()
        .command("get", get_org)
        .command("create", create_org)
        .command("update", update_org)
        .command("exists", org_exists)
        .command("delete", delete_org)
        .group(
            "hot",
            Group::new()
                .command("init", init_hot_org)
                .command("get", get_hot_org)
                .command("override", override_hot_org)
                .command("ensure_member", ensure_hot_org_member)
                .command("member_invites", get_hot_org_member_invites)
                .command("register", register_hot_org)
                .command("invite_member", invite_hot_org_member)
                .command("accept_invite", accept_hot_org_invite)
                .command("decline_invite", decline_hot_org_invite)
                .command("assign_credit_line", assign_credit_line_hot_org)
                .command("repay_credit_line", repay_credit_line_hot_org)
                .command("charge_checkout", charge_checkout_hot_org)
                .command("add_assets", add_assets_hot_org)
                .command("add_fleet", add_fleet_hot_org)
                .command("leave", leave_hot_org)
                .command("disband", disband_hot_org)
                .command("save", save_hot_org)
                .command("remove", remove_hot_org),
        )
        .group(
            "assets",
            Group::new()
                .command("get", get_assets)
                .command("update", update_assets),
        )
        .group(
            "fleet",
            Group::new()
                .command("get", get_fleet)
                .command("update", update_fleet),
        )
        .group(
            "members",
            Group::new()
                .command("get", get_members)
                .command("add", add_member)
                .command("remove", remove_member),
        )
}

fn serialize_hot_org(org: HotOrgRecord) -> String {
    match serde_json::to_string(&org) {
        Ok(json) => json,
        Err(error) => format!("Error: Failed to serialize hot org: {}", error),
    }
}

fn serialize_result<T: serde::Serialize>(value: &T, label: &str) -> String {
    match serde_json::to_string(value) {
        Ok(json) => json,
        Err(error) => format!("Error: Failed to serialize {}: {}", label, error),
    }
}

pub(crate) fn init_hot_org(org_id: String) -> String {
    match HOT_ORG_SERVICE.init_org(org_id) {
        Ok(org) => serialize_hot_org(org),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn get_hot_org(org_id: String) -> String {
    match HOT_ORG_SERVICE.get_org(org_id) {
        Ok(org) => serialize_hot_org(org),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn override_hot_org(org_id: String, json_data: String) -> String {
    let hot_org: HotOrgRecord = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org JSON: {}", error),
    };

    match HOT_ORG_SERVICE.override_org(org_id, hot_org) {
        Ok(org) => serialize_hot_org(org),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn ensure_hot_org_member(json_data: String) -> String {
    let context: OrgEnsureMemberContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid ensure-member JSON: {}", error),
    };

    match HOT_ORG_SERVICE.ensure_member(context) {
        Ok(org) => serialize_hot_org(org),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn get_hot_org_member_invites(member_uid: String) -> String {
    match HOT_ORG_SERVICE.get_member_invites(member_uid) {
        Ok(invites) => serialize_result::<Vec<OrgInviteRecord>>(&invites, "org invite list"),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn register_hot_org(json_data: String) -> String {
    let context: OrgRegisterContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid register org JSON: {}", error),
    };

    match HOT_ORG_SERVICE.register_org(context) {
        Ok(result) => serialize_result(&result, "org register result"),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn invite_hot_org_member(json_data: String) -> String {
    let context: OrgInviteContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org invite JSON: {}", error),
    };

    match HOT_ORG_SERVICE.invite_member(context) {
        Ok(result) => serialize_result::<OrgInviteResult>(&result, "org invite result"),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn accept_hot_org_invite(json_data: String) -> String {
    let context: OrgInviteDecisionContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org invite decision JSON: {}", error),
    };

    match HOT_ORG_SERVICE.accept_invite(context) {
        Ok(result) => {
            serialize_result::<OrgInviteDecisionResult>(&result, "org invite decision result")
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn decline_hot_org_invite(json_data: String) -> String {
    let context: OrgInviteDecisionContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org invite decision JSON: {}", error),
    };

    match HOT_ORG_SERVICE.decline_invite(context) {
        Ok(result) => {
            serialize_result::<OrgInviteDecisionResult>(&result, "org invite decision result")
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn assign_credit_line_hot_org(json_data: String) -> String {
    let context: OrgCreditLineContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org credit-line JSON: {}", error),
    };

    match HOT_ORG_SERVICE.assign_credit_line(context) {
        Ok(result) => serialize_result(&result, "org mutation result"),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn charge_checkout_hot_org(json_data: String) -> String {
    let context: OrgCheckoutContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org checkout JSON: {}", error),
    };

    match HOT_ORG_SERVICE.charge_checkout(context) {
        Ok(result) => serialize_result(&result, "org mutation result"),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn repay_credit_line_hot_org(json_data: String) -> String {
    let context: OrgCreditLineRepaymentContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org credit repayment JSON: {}", error),
    };

    match HOT_ORG_SERVICE.repay_credit_line(context) {
        Ok(result) => {
            serialize_result::<OrgCreditLineRepaymentResult>(&result, "org credit repayment result")
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn add_assets_hot_org(context_json: String, assets_json: String) -> String {
    let context: OrgGrantContext = match serde_json::from_str(&context_json) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org asset context JSON: {}", error),
    };
    let assets: Vec<OrgAssetGrantSeed> = match serde_json::from_str(&assets_json) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org asset seed JSON: {}", error),
    };

    match HOT_ORG_SERVICE.add_assets(context, assets) {
        Ok(result) => serialize_result(&result, "org mutation result"),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn add_fleet_hot_org(context_json: String, fleet_json: String) -> String {
    let context: OrgGrantContext = match serde_json::from_str(&context_json) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org fleet context JSON: {}", error),
    };
    let fleet: Vec<OrgFleetGrantSeed> = match serde_json::from_str(&fleet_json) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org fleet seed JSON: {}", error),
    };

    match HOT_ORG_SERVICE.add_fleet_vehicles(context, fleet) {
        Ok(result) => serialize_result(&result, "org mutation result"),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn leave_hot_org(json_data: String) -> String {
    let context: OrgLeaveContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org leave JSON: {}", error),
    };

    match HOT_ORG_SERVICE.leave_org(context) {
        Ok(result) => serialize_result::<OrgLeaveResult>(&result, "org leave result"),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn disband_hot_org(json_data: String) -> String {
    let context: OrgLeaveContext = match serde_json::from_str(&json_data) {
        Ok(data) => data,
        Err(error) => return format!("Error: Invalid org disband JSON: {}", error),
    };

    match HOT_ORG_SERVICE.disband_org(context) {
        Ok(result) => serialize_result::<OrgDisbandResult>(&result, "org disband result"),
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn save_hot_org(org_id: String) -> String {
    match HOT_ORG_SERVICE.get_org(org_id.clone()) {
        Ok(org) => {
            enqueue_persistence_task("org", move || HOT_ORG_SERVICE.save_org(org_id).map(|_| ()));
            serialize_hot_org(org)
        }
        Err(error) => format!("Error: {}", error),
    }
}

pub(crate) fn remove_hot_org(org_id: String) -> String {
    match HOT_ORG_SERVICE.remove_org(org_id) {
        Ok(_) => "OK".to_string(),
        Err(error) => format!("Error: {}", error),
    }
}

// ============================================================================
// Organization Asset Operations
// ============================================================================

/// Retrieves an organization by key/ID.
///
/// Returns the organization as JSON or an error message if not found.
pub fn get_org(key: String) -> String {
    log(
        "org",
        "DEBUG",
        &format!("Getting organization for key: {}", key),
    );

    match ORG_SERVICE.get_org(key.clone()) {
        Ok(org) => {
            log(
                "org",
                "INFO",
                &format!("Successfully retrieved organization: {}", key),
            );
            match serde_json::to_string(&org) {
                Ok(json) => {
                    log("org", "DEBUG", &format!("Serialized org to JSON: {}", json));
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize org: {}", e);
                    log("org", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "org",
                "ERROR",
                &format!("Failed to get organization '{}': {}", key, e),
            );
            error_msg
        }
    }
}

/// Checks if an organization exists in the database.
///
/// Returns "true" if the organization exists, "false" otherwise.
pub fn org_exists(key: String) -> String {
    match ORG_SERVICE.org_exists(key) {
        Ok(exists) => if exists { "true" } else { "false" }.to_string(),
        Err(_) => "false".to_string(),
    }
}

/// Creates a new organization with the provided JSON data.
///
/// Resolves key to ID, validates JSON data, and persists the new organization.
pub fn create_org(key: String, json_data: String) -> String {
    log(
        "org",
        "DEBUG",
        &format!(
            "Creating organization for key: {} with data: {}",
            key, json_data
        ),
    );

    match ORG_SERVICE.create_org(key.clone(), json_data) {
        Ok(org) => {
            log(
                "org",
                "INFO",
                &format!("Successfully created organization: {}", key),
            );
            match serde_json::to_string(&org) {
                Ok(json) => {
                    log("org", "DEBUG", &format!("Serialized org to JSON: {}", json));
                    json
                }
                Err(e) => {
                    let error_msg = format!("Error: Failed to serialize org: {}", e);
                    log("org", "ERROR", &error_msg);
                    error_msg
                }
            }
        }
        Err(e) => {
            let error_msg = format!("Error: {}", e);
            log(
                "org",
                "ERROR",
                &format!("Failed to create organization '{}': {}", key, e),
            );
            error_msg
        }
    }
}

/// Updates an existing organization with JSON data.
///
/// Resolves key to ID, applies partial updates from JSON, and persists changes.
pub fn update_org(key: String, json_update: String) -> String {
    match ORG_SERVICE.update_org(key, json_update) {
        Ok(org) => match serde_json::to_string(&org) {
            Ok(json) => json,
            Err(e) => format!("Error: Failed to serialize org: {}", e),
        },
        Err(e) => format!("Error: {}", e),
    }
}

/// Permanently deletes an organization.
///
/// Resolves key to ID and removes the organization and associated data.
pub fn delete_org(key: String) -> String {
    match ORG_SERVICE.delete_org(key) {
        Ok(_) => "OK".to_string(),
        Err(e) => format!("Error: {}", e),
    }
}

pub fn get_assets(key: String) -> String {
    match ORG_SERVICE.get_assets(key) {
        Ok(assets) => match serde_json::to_string(&assets) {
            Ok(json) => json,
            Err(e) => format!("Error: Failed to serialize org assets: {}", e),
        },
        Err(e) => format!("Error: {}", e),
    }
}

pub fn update_assets(key: String, json_update: String) -> String {
    let assets_value: serde_json::Value = match serde_json::from_str(&json_update) {
        Ok(value) => value,
        Err(e) => return format!("Error: Invalid JSON: {}", e),
    };

    match ORG_SERVICE.update_assets(key, assets_value) {
        Ok(assets) => match serde_json::to_string(&assets) {
            Ok(json) => json,
            Err(e) => format!("Error: Failed to serialize org assets: {}", e),
        },
        Err(e) => format!("Error: {}", e),
    }
}

pub fn get_fleet(key: String) -> String {
    match ORG_SERVICE.get_fleet(key) {
        Ok(fleet) => match serde_json::to_string(&fleet) {
            Ok(json) => json,
            Err(e) => format!("Error: Failed to serialize org fleet: {}", e),
        },
        Err(e) => format!("Error: {}", e),
    }
}

pub fn update_fleet(key: String, json_update: String) -> String {
    let fleet_value: serde_json::Value = match serde_json::from_str(&json_update) {
        Ok(value) => value,
        Err(e) => return format!("Error: Invalid JSON: {}", e),
    };

    match ORG_SERVICE.update_fleet(key, fleet_value) {
        Ok(fleet) => match serde_json::to_string(&fleet) {
            Ok(json) => json,
            Err(e) => format!("Error: Failed to serialize org fleet: {}", e),
        },
        Err(e) => format!("Error: {}", e),
    }
}

// ============================================================================
// Member Operations
// ============================================================================

/// Retrieves organization members as a JSON object.
///
/// Returns a map of member UIDs to names. Returns empty object if not found.
pub fn get_members(key: String) -> String {
    match ORG_SERVICE.get_members(key) {
        Ok(members) => match serde_json::to_string(&members) {
            Ok(json) => json,
            Err(_) => "{}".to_string(),
        },
        Err(_) => "{}".to_string(),
    }
}

/// Adds a new member to an organization by their UID.
///
/// Resolves organization key to ID and adds the member UID.
/// Member collections automatically prevent duplicate members.
pub fn add_member(key: String, member_uid: String) -> String {
    match ORG_SERVICE.add_member(key, member_uid) {
        Ok(_) => "OK".to_string(),
        Err(e) => format!("Error: {}", e),
    }
}

/// Removes a member from an organization by their UID.
///
/// Resolves organization key to ID and removes the member UID.
pub fn remove_member(key: String, member_uid: String) -> String {
    match ORG_SERVICE.remove_member(key, member_uid) {
        Ok(_) => "OK".to_string(),
        Err(e) => format!("Error: {}", e),
    }
}
