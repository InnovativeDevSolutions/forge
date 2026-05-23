//! Organization service layer providing business logic for organization management operations.
//!
//! Implements the service layer of the organization management system, handling business logic,
//! validation, and orchestration.
//!
//! For full documentation, architecture, and examples, see the [crate README](../README.md).

use forge_models::{
    CreditLineSummary, DEFAULT_CREDIT_LINE_INTEREST_RATE, HotOrgRecord, MemberSummary, Org,
    OrgAssetEntry, OrgAssetGrantSeed, OrgCheckoutContext, OrgCreditLineContext,
    OrgCreditLineRepaymentContext, OrgCreditLineRepaymentResult, OrgDisbandMemberResult,
    OrgDisbandResult, OrgEnsureMemberContext, OrgFleetEntry, OrgFleetGrantSeed, OrgGrantContext,
    OrgInviteContext, OrgInviteDecisionContext, OrgInviteDecisionResult, OrgInviteRecord,
    OrgInviteResult, OrgLeaveContext, OrgLeaveResult, OrgMutationResult, OrgRegisterContext,
    OrgRegisterResult,
};
use forge_repositories::{OrgHotRepository, OrgRepository};
use serde_json::{Value, json};
use std::collections::{HashMap, HashSet};

/// Service layer implementation for organization business logic and operations.
///
/// Orchestrates organization management operations, handling business logic, validation,
/// and data transformation. See [crate README](../README.md) for details.
///
/// # Thread Safety
/// Thread-safe when used with a thread-safe repository.
pub struct OrgService<R: OrgRepository> {
    /// The repository instance used for all data persistence operations.
    ///
    /// This repository handles the actual storage and retrieval of organization
    /// and member data, abstracting away the specific database implementation details.
    repository: R,
}

pub struct OrgHotStateService<R: OrgRepository, H: OrgHotRepository> {
    service: OrgService<R>,
    repository: H,
}

impl<R: OrgRepository> OrgService<R> {
    fn normalize_org_value(
        mut org_value: serde_json::Value,
        key_override: Option<String>,
    ) -> Result<Org, String> {
        let org_object = org_value
            .as_object_mut()
            .ok_or_else(|| "Org payload must be a JSON object".to_string())?;

        if let Some(key) = key_override {
            org_object.insert("id".to_string(), serde_json::Value::String(key));
        }

        if matches!(
            org_object.get("credit_lines"),
            Some(serde_json::Value::Array(lines)) if lines.is_empty()
        ) {
            org_object.insert(
                "credit_lines".to_string(),
                serde_json::Value::Object(serde_json::Map::new()),
            );
        }

        let mut org = serde_json::from_value::<Org>(org_value)
            .map_err(|e| format!("Invalid Org JSON: {}", e))?;
        org.normalize_credit_lines();
        Ok(org)
    }

    /// Creates a new organization service with the provided repository.
    ///
    /// The repository must be initialized and ready for use.
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    /// Creates a new organization with the provided ID and JSON data.
    ///
    /// Handles validation, duplicate checking, and persistence.
    /// See [crate README](../README.md) for JSON format and business rules.
    pub fn create_org(&self, key: String, json_data: String) -> Result<Org, String> {
        let org_value: serde_json::Value =
            serde_json::from_str(&json_data).map_err(|e| format!("Invalid Org JSON: {}", e))?;
        let org = Self::normalize_org_value(org_value, Some(key))?;

        // Validate organization name is not empty
        if org.name.trim().is_empty() {
            return Err("Organization name cannot be empty".to_string());
        }

        // Check if organization already exists to prevent duplicates
        if self.repository.exists(&org.id)? {
            return Err(format!("Organization with ID '{}' already exists", org.id));
        }

        // Store the organization in the repository
        self.repository.create(&org)?;

        Ok(org)
    }

    pub fn get_org(&self, key: String) -> Result<Org, String> {
        let mut org = self
            .repository
            .get_by_id(&key)?
            .ok_or_else(|| format!("Organization with ID '{}' not found", key))?;
        org.normalize_credit_lines();
        Ok(org)
    }

    /// Updates an existing organization with new data from JSON.
    ///
    /// Handles partial updates, validation, and persistence.
    /// See [crate README](../README.md) for JSON format and concurrency details.
    pub fn update_org(&self, key: String, json_update: String) -> Result<Org, String> {
        // Retrieve existing organization from repository
        let mut org = match self.repository.get_by_id(&key)? {
            Some(org) => org,
            None => return Err(format!("Organization with ID '{}' not found", key)),
        };

        // Parse and validate JSON update data
        let mut update_data: serde_json::Value =
            serde_json::from_str(&json_update).map_err(|e| format!("Invalid JSON: {}", e))?;

        // Ensure update data is a JSON object
        if !update_data.is_object() {
            return Err("Update data must be a JSON object".to_string());
        }

        if matches!(
            update_data.get("credit_lines"),
            Some(serde_json::Value::Array(lines)) if lines.is_empty()
        ) {
            update_data["credit_lines"] = serde_json::Value::Object(serde_json::Map::new());
        }

        // Create a temporary copy to safely apply updates with validation
        let mut updated_org = org.clone();

        // Apply updates field by field
        if let Some(obj) = update_data.as_object() {
            for (field, value) in obj {
                match field.as_str() {
                    "id" => {
                        if let Some(id_str) = value.as_str() {
                            updated_org.id = id_str.to_string();
                        } else {
                            return Err("ID must be a string".to_string());
                        }
                    }
                    "owner" => {
                        if let Some(owner_str) = value.as_str() {
                            updated_org.owner = owner_str.to_string();
                        } else {
                            return Err("Owner must be a string".to_string());
                        }
                    }
                    "name" => {
                        if let Some(name_str) = value.as_str() {
                            updated_org.name = name_str.to_string();
                        } else {
                            return Err("Name must be a string".to_string());
                        }
                    }
                    "funds" => {
                        if let Some(funds_val) = value.as_f64() {
                            updated_org.funds = funds_val;
                        } else {
                            return Err("Funds must be a number".to_string());
                        }
                    }
                    "reputation" => {
                        if let Some(rep_val) = value.as_i64() {
                            updated_org.reputation = rep_val;
                        } else {
                            return Err("Reputation must be an integer".to_string());
                        }
                    }
                    "credit_lines" => {
                        if value.is_null() {
                            updated_org.credit_lines = HashMap::new();
                        } else {
                            updated_org.credit_lines = serde_json::from_value::<
                                HashMap<String, CreditLineSummary>,
                            >(value.clone())
                            .map_err(|e| {
                                format!(
                                    "Credit lines must be an object of member credit entries: {}",
                                    e
                                )
                            })?;
                        }
                    }
                    _ => {
                        return Err(format!("Unknown field: {}", field));
                    }
                }
            }
        }

        // Validate the updated organization before committing changes
        updated_org.normalize_credit_lines();
        updated_org
            .validate()
            .map_err(|e| format!("Validation failed: {}", e))?;

        // Only commit changes after validation passes
        org = updated_org;

        // Persist the updated organization to repository
        self.repository.update(&org)?;

        Ok(org)
    }

    /// Permanently deletes an organization from the system.
    ///
    /// Irreversible operation. Delegates to repository.
    pub fn delete_org(&self, key: String) -> Result<(), String> {
        self.repository.delete(&key)
    }

    /// Checks if an organization exists in the system.
    ///
    /// Lightweight check without data retrieval.
    pub fn org_exists(&self, key: String) -> Result<bool, String> {
        // Delegate existence check to repository layer
        self.repository.exists(&key)
    }

    /// Adds a new member UID to an organization with validation.
    pub fn add_member(&self, key: String, member_uid: String) -> Result<(), String> {
        // Verify organization exists before adding member
        if !self.repository.exists(&key)? {
            return Err(format!("Organization with ID '{}' not found", key));
        }

        // Add member UID to organization through repository
        self.repository.add_member(&key, &member_uid)
    }

    /// Retrieves all members of an organization as a UID to name mapping.
    pub fn get_members(&self, key: String) -> Result<Vec<MemberSummary>, String> {
        // Delegate member retrieval to repository layer
        self.repository.get_members(&key)
    }

    /// Permanently removes a specific member from an organization.
    ///
    /// Irreversible operation. Delegates to repository.
    pub fn remove_member(&self, key: String, member_uid: String) -> Result<(), String> {
        // Verify organization exists before attempting member removal
        if !self.repository.exists(&key)? {
            return Err(format!("Organization with ID '{}' not found", key));
        }

        // Delegate member removal to repository layer
        self.repository.remove_member(&key, &member_uid)
    }

    pub fn get_assets(
        &self,
        key: String,
    ) -> Result<HashMap<String, HashMap<String, OrgAssetEntry>>, String> {
        if !self.repository.exists(&key)? {
            return Err(format!("Organization with ID '{}' not found", key));
        }

        self.repository.get_assets(&key)
    }

    pub fn update_assets(
        &self,
        key: String,
        mut assets_update: serde_json::Value,
    ) -> Result<HashMap<String, HashMap<String, OrgAssetEntry>>, String> {
        if !self.repository.exists(&key)? {
            return Err(format!("Organization with ID '{}' not found", key));
        }

        if matches!(&assets_update, serde_json::Value::Array(lines) if lines.is_empty()) {
            assets_update = serde_json::Value::Object(serde_json::Map::new());
        }

        let assets = if assets_update.is_null() {
            HashMap::new()
        } else {
            serde_json::from_value::<HashMap<String, HashMap<String, OrgAssetEntry>>>(assets_update)
                .map_err(|e| {
                    format!(
                        "Assets must be an object of category maps keyed by classname: {}",
                        e
                    )
                })?
        };

        self.repository.update_assets(&key, &assets)?;
        Ok(assets)
    }

    pub fn get_fleet(&self, key: String) -> Result<HashMap<String, OrgFleetEntry>, String> {
        if !self.repository.exists(&key)? {
            return Err(format!("Organization with ID '{}' not found", key));
        }

        self.repository.get_fleet(&key)
    }

    pub fn update_fleet(
        &self,
        key: String,
        mut fleet_update: serde_json::Value,
    ) -> Result<HashMap<String, OrgFleetEntry>, String> {
        if !self.repository.exists(&key)? {
            return Err(format!("Organization with ID '{}' not found", key));
        }

        if matches!(&fleet_update, serde_json::Value::Array(lines) if lines.is_empty()) {
            fleet_update = serde_json::Value::Object(serde_json::Map::new());
        }

        let fleet = if fleet_update.is_null() {
            HashMap::new()
        } else {
            serde_json::from_value::<HashMap<String, OrgFleetEntry>>(fleet_update)
                .map_err(|e| format!("Fleet must be an object of fleet entries: {}", e))?
        };

        self.repository.update_fleet(&key, &fleet)?;
        Ok(fleet)
    }
}

impl<R: OrgRepository, H: OrgHotRepository> OrgHotStateService<R, H> {
    pub fn new(repository: R, hot_repository: H) -> Self {
        Self {
            service: OrgService::new(repository),
            repository: hot_repository,
        }
    }

    pub fn init_org(&self, id: String) -> Result<HotOrgRecord, String> {
        if let Some(org) = self.repository.get(&id)? {
            if !org.members.is_empty() || !org.assets.is_empty() || !org.fleet.is_empty() {
                return Ok(org);
            }

            let hydrated_org = self.hydrate_org(&id)?;
            if !hydrated_org.members.is_empty()
                || !hydrated_org.assets.is_empty()
                || !hydrated_org.fleet.is_empty()
            {
                self.repository.save(&hydrated_org)?;
                return Ok(hydrated_org);
            }

            return Ok(org);
        }

        let hot_org = self.hydrate_org(&id)?;
        self.repository.save(&hot_org)?;
        Ok(hot_org)
    }

    pub fn get_org(&self, id: String) -> Result<HotOrgRecord, String> {
        self.init_org(id)
    }

    pub fn get_member_invites(&self, member_uid: String) -> Result<Vec<OrgInviteRecord>, String> {
        if member_uid.trim().is_empty() {
            return Ok(Vec::new());
        }

        let mut invites = Vec::new();
        for org_id in self.repository.keys()? {
            let Some(org) = self.repository.get(&org_id)? else {
                continue;
            };

            if let Some(invite) = org.pending_invites.get(&member_uid) {
                invites.push(invite.clone());
            }
        }

        invites.sort_by(|left, right| left.org_name.cmp(&right.org_name));
        Ok(invites)
    }

    pub fn override_org(
        &self,
        id: String,
        mut hot_org: HotOrgRecord,
    ) -> Result<HotOrgRecord, String> {
        hot_org.id = id;
        self.repository.save(&hot_org)?;
        Ok(hot_org)
    }

    pub fn save_org(&self, id: String) -> Result<HotOrgRecord, String> {
        let hot_org = self
            .repository
            .get(&id)?
            .ok_or_else(|| format!("Organization with ID '{}' not found", id))?;

        let core_org = hot_org.clone().into_org();
        let current_members = self
            .service
            .get_members(id.clone())?
            .into_iter()
            .map(|member| member.uid)
            .collect::<HashSet<_>>();
        let target_members = hot_org.members.keys().cloned().collect::<HashSet<_>>();

        if self.service.org_exists(id.clone())? {
            self.service.repository.update(&core_org)?;
        } else {
            self.service.repository.create(&core_org)?;
        }

        self.service
            .repository
            .update_assets(&id, &hot_org.assets)?;
        self.service.repository.update_fleet(&id, &hot_org.fleet)?;

        for member_uid in target_members.difference(&current_members) {
            self.service.repository.add_member(&id, member_uid)?;
        }

        for member_uid in current_members.difference(&target_members) {
            self.service.repository.remove_member(&id, member_uid)?;
        }

        self.repository.save(&hot_org)?;
        Ok(hot_org)
    }

    pub fn remove_org(&self, id: String) -> Result<(), String> {
        self.repository.delete(&id)
    }

    pub fn ensure_member(&self, context: OrgEnsureMemberContext) -> Result<HotOrgRecord, String> {
        if context.org_id.trim().is_empty() || context.member_uid.trim().is_empty() {
            return Err("A valid organization and member UID are required.".to_string());
        }

        let mut org = self.get_org(context.org_id)?;
        let member_name = if context.member_name.trim().is_empty() {
            "Unknown".to_string()
        } else {
            context.member_name
        };
        let should_refresh_member_name = org
            .members
            .get(&context.member_uid)
            .map(|member| {
                let existing_name = member.name.trim();
                !member_name.eq_ignore_ascii_case("unknown")
                    && (existing_name.is_empty() || existing_name.eq_ignore_ascii_case("unknown"))
            })
            .unwrap_or(false);

        if !org.members.contains_key(&context.member_uid) || should_refresh_member_name {
            org.members.insert(
                context.member_uid.clone(),
                MemberSummary {
                    uid: context.member_uid,
                    name: member_name,
                },
            );
            self.repository.save(&org)?;
        }

        Ok(org)
    }

    pub fn register_org(&self, context: OrgRegisterContext) -> Result<OrgRegisterResult, String> {
        if context.requester_uid.trim().is_empty() || context.org_id.trim().is_empty() {
            return Err("A valid requester and organization ID are required.".to_string());
        }
        if context.org_name.trim().is_empty() {
            return Err("Organization name cannot be empty.".to_string());
        }
        if !context.existing_org_id.trim().is_empty()
            && !context.existing_org_id.eq_ignore_ascii_case("default")
        {
            return Err("Player already belongs to an organization.".to_string());
        }
        if self.service.org_exists(context.org_id.clone())?
            || self.repository.get(&context.org_id)?.is_some()
        {
            return Err("An organization already exists for this phone number.".to_string());
        }

        let org = Org {
            id: context.org_id.clone(),
            owner: context.requester_uid.clone(),
            name: context.org_name,
            funds: 0.0,
            reputation: 0,
            credit_lines: HashMap::new(),
        };
        org.validate()
            .map_err(|error| format!("Validation failed: {}", error))?;

        let json_data = serde_json::to_string(&org)
            .map_err(|error| format!("Failed to serialize org: {}", error))?;
        let persisted_org = self.service.create_org(context.org_id.clone(), json_data)?;
        let mut hot_org =
            HotOrgRecord::from_parts(persisted_org, HashMap::new(), HashMap::new(), Vec::new());
        hot_org.members.insert(
            context.requester_uid.clone(),
            MemberSummary {
                uid: context.requester_uid.clone(),
                name: if context.requester_name.trim().is_empty() {
                    "Unknown".to_string()
                } else {
                    context.requester_name
                },
            },
        );
        self.repository.save(&hot_org)?;

        if context.existing_org_id.eq_ignore_ascii_case("default") {
            let mut default_org = self.init_org("default".to_string())?;
            default_org.members.remove(&context.requester_uid);
            self.repository.save(&default_org)?;
        }

        Ok(OrgRegisterResult {
            org: hot_org,
            actor_organization: context.org_id,
            message: String::new(),
        })
    }

    pub fn invite_member(&self, context: OrgInviteContext) -> Result<OrgInviteResult, String> {
        if context.requester_uid.trim().is_empty()
            || context.target_uid.trim().is_empty()
            || context.org_id.trim().is_empty()
        {
            return Err("A valid organization invite request is required.".to_string());
        }

        let mut org = self.get_org(context.org_id.clone())?;
        if !can_manage_treasury(
            &org,
            &context.requester_uid,
            context.requester_is_default_org_ceo,
        ) {
            return Err(
                "Only the organization leader or CEO can send organization invites.".to_string(),
            );
        }
        if context.target_uid == context.requester_uid {
            return Err("You cannot invite yourself to the organization.".to_string());
        }
        if org.members.contains_key(&context.target_uid) {
            return Err("Selected player is already a member of this organization.".to_string());
        }
        if !context.target_org_id.trim().is_empty()
            && !context.target_org_id.eq_ignore_ascii_case("default")
        {
            return Err(
                "Selected player must leave their current organization before joining another."
                    .to_string(),
            );
        }

        let target_name = if context.target_name.trim().is_empty() {
            "Unknown".to_string()
        } else {
            context.target_name.clone()
        };
        let inviter_name = if context.requester_name.trim().is_empty() {
            "Unknown".to_string()
        } else {
            context.requester_name.clone()
        };

        org.pending_invites.insert(
            context.target_uid.clone(),
            OrgInviteRecord {
                org_id: org.id.clone(),
                org_name: org.name.clone(),
                inviter_uid: context.requester_uid,
                inviter_name,
                target_uid: context.target_uid.clone(),
                target_name: target_name.clone(),
            },
        );
        self.repository.save(&org)?;

        Ok(OrgInviteResult {
            org,
            target_uid: context.target_uid,
            message: format!("Invitation sent to {}.", target_name),
        })
    }

    pub fn accept_invite(
        &self,
        context: OrgInviteDecisionContext,
    ) -> Result<OrgInviteDecisionResult, String> {
        if context.requester_uid.trim().is_empty() || context.org_id.trim().is_empty() {
            return Err("A valid organization invite acceptance is required.".to_string());
        }
        if !context.existing_org_id.trim().is_empty()
            && !context.existing_org_id.eq_ignore_ascii_case("default")
            && !context
                .existing_org_id
                .eq_ignore_ascii_case(&context.org_id)
        {
            return Err(
                "Leave your current organization before accepting another invite.".to_string(),
            );
        }

        let mut invited_org = self.get_org(context.org_id.clone())?;
        let invite = invited_org
            .pending_invites
            .remove(&context.requester_uid)
            .ok_or_else(|| "That organization invite is no longer available.".to_string())?;

        if invited_org.members.contains_key(&context.requester_uid) {
            self.repository.save(&invited_org)?;
            return Ok(OrgInviteDecisionResult {
                previous_org: None,
                actor_organization: invited_org.id.clone(),
                message: "You are already a member of that organization.".to_string(),
                invited_org,
            });
        }

        let requester_name = if context.requester_name.trim().is_empty() {
            invite.target_name
        } else {
            context.requester_name
        };

        let mut previous_org = None;
        if !context.existing_org_id.trim().is_empty()
            && !context
                .existing_org_id
                .eq_ignore_ascii_case(&invited_org.id)
        {
            let mut current_org = self.init_org(context.existing_org_id.clone())?;
            current_org.members.remove(&context.requester_uid);
            self.repository.save(&current_org)?;
            previous_org = Some(current_org);
        }

        invited_org.members.insert(
            context.requester_uid.clone(),
            MemberSummary {
                uid: context.requester_uid,
                name: requester_name,
            },
        );
        self.repository.save(&invited_org)?;

        Ok(OrgInviteDecisionResult {
            previous_org,
            actor_organization: invited_org.id.clone(),
            message: format!("You joined {}.", invited_org.name),
            invited_org,
        })
    }

    pub fn decline_invite(
        &self,
        context: OrgInviteDecisionContext,
    ) -> Result<OrgInviteDecisionResult, String> {
        if context.requester_uid.trim().is_empty() || context.org_id.trim().is_empty() {
            return Err("A valid organization invite decline is required.".to_string());
        }

        let mut invited_org = self.get_org(context.org_id.clone())?;
        let invite = invited_org
            .pending_invites
            .remove(&context.requester_uid)
            .ok_or_else(|| "That organization invite is no longer available.".to_string())?;
        self.repository.save(&invited_org)?;

        Ok(OrgInviteDecisionResult {
            previous_org: None,
            actor_organization: context.existing_org_id,
            message: format!("Invitation from {} declined.", invite.org_name),
            invited_org,
        })
    }

    pub fn assign_credit_line(
        &self,
        context: OrgCreditLineContext,
    ) -> Result<OrgMutationResult, String> {
        if context.requester_uid.trim().is_empty()
            || context.member_uid.trim().is_empty()
            || context.org_id.trim().is_empty()
        {
            return Err("A valid requester, member, and organization are required.".to_string());
        }
        if context.amount <= 0.0 {
            return Err("A valid credit amount is required.".to_string());
        }

        let mut org = self.get_org(context.org_id)?;
        if !can_manage_treasury(
            &org,
            &context.requester_uid,
            context.requester_is_default_org_ceo,
        ) {
            return Err(
                "Only the organization leader or CEO can manage treasury actions.".to_string(),
            );
        }

        let member_record = org
            .members
            .get(&context.member_uid)
            .cloned()
            .ok_or_else(|| {
                "Selected member was not found in the organization roster.".to_string()
            })?;
        let member_name = if context.member_name.trim().is_empty() {
            member_record.name
        } else {
            context.member_name
        };

        let mut credit_line = org
            .credit_lines
            .get(&context.member_uid)
            .cloned()
            .unwrap_or_else(|| CreditLineSummary {
                uid: context.member_uid.clone(),
                name: member_name.clone(),
                approved_amount: 0.0,
                available_amount: 0.0,
                outstanding_principal: 0.0,
                interest_rate: DEFAULT_CREDIT_LINE_INTEREST_RATE,
                amount_due: 0.0,
                amount: 0.0,
            });
        credit_line.normalize();

        let next_reserved_amount = round_currency(context.amount);
        let previous_reserved_amount = round_currency(credit_line.available_amount);
        let treasury_delta = round_currency(next_reserved_amount - previous_reserved_amount);
        if treasury_delta > 0.0 && org.funds < treasury_delta {
            return Err("Organization funds cannot cover that credit assignment.".to_string());
        }

        org.funds = round_currency(org.funds - treasury_delta);
        credit_line.uid = context.member_uid.clone();
        credit_line.name = member_name.clone();
        credit_line.approved_amount = next_reserved_amount;
        credit_line.available_amount = next_reserved_amount;
        credit_line.amount = next_reserved_amount;
        if credit_line.interest_rate <= 0.0 {
            credit_line.interest_rate = DEFAULT_CREDIT_LINE_INTEREST_RATE;
        }

        org.credit_lines
            .insert(context.member_uid.clone(), credit_line);
        self.repository.save(&org)?;

        Ok(OrgMutationResult {
            patch: build_org_patch(&org, &["funds", "credit_lines"])?,
            member_uids: resolve_member_uids(&org, Some(&context.requester_uid)),
            message: format!(
                "Credit line for {} set to ${}.",
                member_name,
                format_currency(next_reserved_amount)
            ),
            org,
        })
    }

    pub fn charge_checkout(
        &self,
        context: OrgCheckoutContext,
    ) -> Result<OrgMutationResult, String> {
        if context.requester_uid.trim().is_empty() || context.org_id.trim().is_empty() {
            return Err("A valid requester and organization are required.".to_string());
        }
        if context.amount <= 0.0 {
            return Err("Checkout amount must be greater than zero.".to_string());
        }

        let mut org = self.get_org(context.org_id)?;
        let member_uids = resolve_member_uids(&org, Some(&context.requester_uid));

        match context.source.trim().to_ascii_lowercase().as_str() {
            "org_funds" => {
                let charged_amount = round_currency(context.amount);
                let can_charge_org_funds = can_manage_treasury(
                    &org,
                    &context.requester_uid,
                    context.requester_is_default_org_ceo,
                ) || (context.allow_member_charge
                    && org.members.contains_key(&context.requester_uid));

                if !can_charge_org_funds {
                    return Err(
                        "Only the organization leader or CEO can charge org funds.".to_string()
                    );
                }
                if org.funds < charged_amount {
                    return Err("Organization funds cannot cover this checkout.".to_string());
                }

                org.funds = round_currency(org.funds - charged_amount);
                if context.record_member_debt {
                    let member_name = org
                        .members
                        .get(&context.requester_uid)
                        .map(|member| member.name.clone())
                        .filter(|name| !name.trim().is_empty())
                        .unwrap_or_else(|| "Unknown".to_string());
                    let mut credit_line = org
                        .credit_lines
                        .get(&context.requester_uid)
                        .cloned()
                        .unwrap_or_else(|| CreditLineSummary {
                            uid: context.requester_uid.clone(),
                            name: member_name.clone(),
                            approved_amount: 0.0,
                            available_amount: 0.0,
                            outstanding_principal: 0.0,
                            interest_rate: DEFAULT_CREDIT_LINE_INTEREST_RATE,
                            amount_due: 0.0,
                            amount: 0.0,
                        });
                    credit_line.normalize();
                    credit_line.uid = context.requester_uid.clone();
                    credit_line.name = member_name;
                    if credit_line.interest_rate <= 0.0 {
                        credit_line.interest_rate = DEFAULT_CREDIT_LINE_INTEREST_RATE;
                    }
                    credit_line.outstanding_principal =
                        round_currency(credit_line.outstanding_principal + charged_amount);
                    credit_line.amount_due =
                        round_currency(credit_line.amount_due + charged_amount);
                    credit_line.amount = credit_line.available_amount;
                    org.credit_lines
                        .insert(context.requester_uid.clone(), credit_line);
                }
                self.repository.save(&org)?;

                let patch_fields = if context.record_member_debt {
                    vec!["funds", "credit_lines"]
                } else {
                    vec!["funds"]
                };

                Ok(OrgMutationResult {
                    patch: build_org_patch(&org, &patch_fields)?,
                    member_uids,
                    message: String::new(),
                    org,
                })
            }
            "credit_line" => {
                let mut credit_line = org
                    .credit_lines
                    .get(&context.requester_uid)
                    .cloned()
                    .ok_or_else(|| {
                        "Assigned credit line cannot cover this checkout.".to_string()
                    })?;

                credit_line.normalize();

                if credit_line.available_amount < context.amount {
                    return Err("Assigned credit line cannot cover this checkout.".to_string());
                }

                let charged_amount = round_currency(context.amount);
                credit_line.available_amount =
                    round_currency(credit_line.available_amount - charged_amount);
                credit_line.approved_amount = credit_line.available_amount;
                credit_line.outstanding_principal =
                    round_currency(credit_line.outstanding_principal + charged_amount);
                credit_line.amount_due = round_currency(
                    credit_line.amount_due + (charged_amount * (1.0 + credit_line.interest_rate)),
                );
                credit_line.amount = credit_line.available_amount;
                org.credit_lines
                    .insert(context.requester_uid.clone(), credit_line);
                self.repository.save(&org)?;

                Ok(OrgMutationResult {
                    patch: build_org_patch(&org, &["credit_lines"])?,
                    member_uids,
                    message: String::new(),
                    org,
                })
            }
            _ => Err("Selected organization payment source is unsupported.".to_string()),
        }
    }

    pub fn repay_credit_line(
        &self,
        context: OrgCreditLineRepaymentContext,
    ) -> Result<OrgCreditLineRepaymentResult, String> {
        if context.requester_uid.trim().is_empty() || context.org_id.trim().is_empty() {
            return Err("A valid requester and organization are required.".to_string());
        }
        if context.amount <= 0.0 {
            return Err("Repayment amount must be greater than zero.".to_string());
        }

        let mut org = self.get_org(context.org_id)?;
        let member_uids = resolve_member_uids(&org, Some(&context.requester_uid));
        let mut credit_line = org
            .credit_lines
            .get(&context.requester_uid)
            .cloned()
            .ok_or_else(|| "No active credit line is assigned to this member.".to_string())?;
        credit_line.normalize();

        if credit_line.amount_due <= 0.0 {
            return Err("This credit line has no outstanding balance.".to_string());
        }

        let paid_amount = round_currency(context.amount.min(credit_line.amount_due));
        let principal_paid = if paid_amount >= credit_line.amount_due {
            credit_line.outstanding_principal
        } else {
            round_currency(
                paid_amount * (credit_line.outstanding_principal / credit_line.amount_due),
            )
            .min(credit_line.outstanding_principal)
            .min(paid_amount)
        };
        let interest_paid = round_currency(paid_amount - principal_paid);

        credit_line.outstanding_principal =
            round_currency(credit_line.outstanding_principal - principal_paid);
        credit_line.amount_due = round_currency(credit_line.amount_due - paid_amount);
        if credit_line.outstanding_principal <= 0.0 {
            credit_line.outstanding_principal = 0.0;
        }
        if credit_line.amount_due <= 0.0 {
            credit_line.amount_due = 0.0;
        }
        credit_line.amount = credit_line.available_amount;

        org.funds = round_currency(org.funds + paid_amount);
        org.credit_lines
            .insert(context.requester_uid.clone(), credit_line.clone());
        self.repository.save(&org)?;

        Ok(OrgCreditLineRepaymentResult {
            patch: build_org_patch(&org, &["funds", "credit_lines"])?,
            member_uids,
            paid_amount,
            principal_paid,
            interest_paid,
            remaining_amount_due: credit_line.amount_due,
            message: if credit_line.amount_due > 0.0 {
                format!(
                    "Credit repayment posted. ${} paid with ${} still due.",
                    format_currency(paid_amount),
                    format_currency(credit_line.amount_due)
                )
            } else {
                format!(
                    "Credit repayment posted. ${} cleared the outstanding balance.",
                    format_currency(paid_amount)
                )
            },
            org,
        })
    }

    pub fn add_assets(
        &self,
        context: OrgGrantContext,
        assets: Vec<OrgAssetGrantSeed>,
    ) -> Result<OrgMutationResult, String> {
        if context.org_id.trim().is_empty() {
            return Err("A valid organization is required for asset updates.".to_string());
        }
        if assets.is_empty() {
            let org = self.get_org(context.org_id)?;
            return Ok(OrgMutationResult {
                org,
                patch: HashMap::new(),
                member_uids: Vec::new(),
                message: String::new(),
            });
        }

        let mut org = self.get_org(context.org_id)?;
        for asset in assets {
            if asset.classname.trim().is_empty() || asset.quantity <= 0 {
                continue;
            }
            let category = asset.category.trim().to_ascii_lowercase();
            let category_assets = org.assets.entry(category.clone()).or_default();
            let entry = category_assets
                .entry(asset.classname.clone())
                .or_insert_with(|| OrgAssetEntry {
                    classname: asset.classname.clone(),
                    asset_type: category.clone(),
                    quantity: 0,
                });
            entry.quantity += asset.quantity;
        }

        self.repository.save(&org)?;

        Ok(OrgMutationResult {
            patch: build_org_patch(&org, &["assets"])?,
            member_uids: resolve_member_uids(&org, Some(&context.requester_uid)),
            message: String::new(),
            org,
        })
    }

    pub fn add_fleet_vehicles(
        &self,
        context: OrgGrantContext,
        vehicles: Vec<OrgFleetGrantSeed>,
    ) -> Result<OrgMutationResult, String> {
        if context.org_id.trim().is_empty() {
            return Err("A valid organization is required for fleet updates.".to_string());
        }
        if vehicles.is_empty() {
            let org = self.get_org(context.org_id)?;
            return Ok(OrgMutationResult {
                org,
                patch: HashMap::new(),
                member_uids: Vec::new(),
                message: String::new(),
            });
        }

        let mut org = self.get_org(context.org_id)?;
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
                    name: vehicle.classname,
                    fleet_type,
                    status: "Ready".to_string(),
                    damage: "0%".to_string(),
                },
            );
            fleet_index += 1;
        }

        self.repository.save(&org)?;

        Ok(OrgMutationResult {
            patch: build_org_patch(&org, &["fleet"])?,
            member_uids: resolve_member_uids(&org, Some(&context.requester_uid)),
            message: String::new(),
            org,
        })
    }

    pub fn leave_org(&self, context: OrgLeaveContext) -> Result<OrgLeaveResult, String> {
        if context.requester_uid.trim().is_empty() {
            return Err("A valid player UID is required.".to_string());
        }
        if context.org_id.trim().is_empty() || context.org_id.eq_ignore_ascii_case("default") {
            return Err("You are already assigned to the default organization.".to_string());
        }

        let mut org = self.get_org(context.org_id)?;
        if org.owner == context.requester_uid {
            return Err(
                "Organization owners must disband the organization instead of leaving it."
                    .to_string(),
            );
        }

        let org_name = org.name.clone();
        org.members.remove(&context.requester_uid);
        self.repository.save(&org)?;

        let mut default_org = self.init_org("default".to_string())?;
        let requester_uid = context.requester_uid.clone();
        default_org.members.insert(
            requester_uid.clone(),
            MemberSummary {
                uid: requester_uid,
                name: if context.requester_name.trim().is_empty() {
                    "Unknown".to_string()
                } else {
                    context.requester_name
                },
            },
        );
        self.repository.save(&default_org)?;

        Ok(OrgLeaveResult {
            actor_organization: "default".to_string(),
            message: format!(
                "You left {} and returned to the default organization.",
                org_name
            ),
        })
    }

    pub fn disband_org(&self, context: OrgLeaveContext) -> Result<OrgDisbandResult, String> {
        if context.requester_uid.trim().is_empty() {
            return Err("A valid player UID is required.".to_string());
        }
        if context.org_id.trim().is_empty() || context.org_id.eq_ignore_ascii_case("default") {
            return Err("Only active player organizations can be disbanded.".to_string());
        }

        let org = self.get_org(context.org_id.clone())?;
        if org.owner != context.requester_uid {
            return Err("Only the organization owner can disband this organization.".to_string());
        }

        let org_name = org.name.clone();
        let mut default_org = self.init_org("default".to_string())?;
        let mut member_results = Vec::new();
        let mut seen = HashSet::new();

        for (member_uid, member) in &org.members {
            if seen.insert(member_uid.clone()) {
                default_org
                    .members
                    .insert(member_uid.clone(), member.clone());
                member_results.push(OrgDisbandMemberResult {
                    uid: member_uid.clone(),
                    requester: member_uid == &context.requester_uid,
                    actor_organization: "default".to_string(),
                    message: if member_uid == &context.requester_uid {
                        format!("Your organization, {}, has been disbanded.", org_name)
                    } else {
                        format!("{} has been disbanded.", org_name)
                    },
                });
            }
        }

        if seen.insert(context.requester_uid.clone()) {
            default_org.members.insert(
                context.requester_uid.clone(),
                MemberSummary {
                    uid: context.requester_uid.clone(),
                    name: if context.requester_name.trim().is_empty() {
                        "Unknown".to_string()
                    } else {
                        context.requester_name
                    },
                },
            );
            member_results.push(OrgDisbandMemberResult {
                uid: context.requester_uid,
                requester: true,
                actor_organization: "default".to_string(),
                message: format!("Your organization, {}, has been disbanded.", org_name),
            });
        }

        self.repository.save(&default_org)?;
        self.service.delete_org(context.org_id.clone())?;
        self.repository.delete(&context.org_id)?;

        Ok(OrgDisbandResult {
            message: format!("{} has been disbanded.", org_name),
            members: member_results,
        })
    }

    fn hydrate_org(&self, id: &str) -> Result<HotOrgRecord, String> {
        let org = self
            .service
            .get_org(id.to_string())
            .map_err(|error| format!("Organization with ID '{}' not found: {}", id, error))?;
        let assets = self.service.get_assets(id.to_string())?;
        let fleet = self.service.get_fleet(id.to_string())?;
        let members = self.service.get_members(id.to_string())?;
        Ok(HotOrgRecord::from_parts(org, assets, fleet, members))
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

fn build_org_patch(org: &HotOrgRecord, fields: &[&str]) -> Result<HashMap<String, Value>, String> {
    let mut patch = HashMap::new();
    for field in fields {
        patch.insert((*field).to_string(), current_org_field_value(org, field)?);
    }
    Ok(patch)
}

fn current_org_field_value(org: &HotOrgRecord, field: &str) -> Result<Value, String> {
    match field {
        "id" => Ok(json!(org.id)),
        "owner" => Ok(json!(org.owner)),
        "name" => Ok(json!(org.name)),
        "funds" => Ok(json!(org.funds)),
        "reputation" => Ok(json!(org.reputation)),
        "credit_lines" => serde_json::to_value(&org.credit_lines)
            .map_err(|error| format!("Failed to serialize org credit lines: {}", error)),
        "assets" => serde_json::to_value(&org.assets)
            .map_err(|error| format!("Failed to serialize org assets: {}", error)),
        "fleet" => serde_json::to_value(&org.fleet)
            .map_err(|error| format!("Failed to serialize org fleet: {}", error)),
        "members" => serde_json::to_value(&org.members)
            .map_err(|error| format!("Failed to serialize org members: {}", error)),
        "pending_invites" => serde_json::to_value(&org.pending_invites)
            .map_err(|error| format!("Failed to serialize org invites: {}", error)),
        _ => Err(format!("Unknown field: {}", field)),
    }
}

fn format_currency(amount: f64) -> String {
    let rounded = round_currency(amount).round() as i64;
    let digits = rounded.to_string();
    let mut formatted = String::new();

    for (index, character) in digits.chars().rev().enumerate() {
        if index > 0 && index % 3 == 0 {
            formatted.push(',');
        }
        formatted.push(character);
    }

    formatted.chars().rev().collect()
}

fn round_currency(amount: f64) -> f64 {
    (amount.max(0.0) * 100.0).round() / 100.0
}

#[cfg(test)]
mod tests {
    use super::*;
    use forge_repositories::InMemoryOrgHotRepository;

    #[derive(Clone, Default)]
    struct TestOrgRepository;

    impl OrgRepository for TestOrgRepository {
        fn create(&self, _org: &Org) -> Result<(), String> {
            Ok(())
        }

        fn get_by_id(&self, _id: &str) -> Result<Option<Org>, String> {
            Ok(None)
        }

        fn update(&self, _org: &Org) -> Result<(), String> {
            Ok(())
        }

        fn delete(&self, _id: &str) -> Result<(), String> {
            Ok(())
        }

        fn exists(&self, _id: &str) -> Result<bool, String> {
            Ok(false)
        }

        fn add_member(&self, _org_id: &str, _member_uid: &str) -> Result<(), String> {
            Ok(())
        }

        fn get_members(&self, _org_id: &str) -> Result<Vec<MemberSummary>, String> {
            Ok(Vec::new())
        }

        fn remove_member(&self, _org_id: &str, _member_uid: &str) -> Result<(), String> {
            Ok(())
        }

        fn get_assets(
            &self,
            _org_id: &str,
        ) -> Result<HashMap<String, HashMap<String, OrgAssetEntry>>, String> {
            Ok(HashMap::new())
        }

        fn update_assets(
            &self,
            _org_id: &str,
            _assets: &HashMap<String, HashMap<String, OrgAssetEntry>>,
        ) -> Result<(), String> {
            Ok(())
        }

        fn get_fleet(&self, _org_id: &str) -> Result<HashMap<String, OrgFleetEntry>, String> {
            Ok(HashMap::new())
        }

        fn update_fleet(
            &self,
            _org_id: &str,
            _fleet: &HashMap<String, OrgFleetEntry>,
        ) -> Result<(), String> {
            Ok(())
        }
    }

    fn test_hot_org() -> HotOrgRecord {
        let mut members = HashMap::new();
        members.insert(
            "member".to_string(),
            MemberSummary {
                uid: "member".to_string(),
                name: "Medic Patient".to_string(),
            },
        );

        HotOrgRecord {
            id: "org".to_string(),
            owner: "owner".to_string(),
            name: "Test Org".to_string(),
            funds: 500.0,
            reputation: 0,
            credit_lines: HashMap::new(),
            assets: HashMap::new(),
            fleet: HashMap::new(),
            members,
            pending_invites: HashMap::new(),
        }
    }

    fn test_service(
        hot_repository: InMemoryOrgHotRepository,
    ) -> OrgHotStateService<TestOrgRepository, InMemoryOrgHotRepository> {
        OrgHotStateService::new(TestOrgRepository, hot_repository)
    }

    #[test]
    fn org_funds_checkout_without_member_debt_only_reduces_funds() {
        let hot_repository = InMemoryOrgHotRepository::new();
        hot_repository.save(&test_hot_org()).unwrap();
        let service = test_service(hot_repository);

        let result = service
            .charge_checkout(OrgCheckoutContext {
                requester_uid: "member".to_string(),
                org_id: "org".to_string(),
                requester_is_default_org_ceo: false,
                allow_member_charge: true,
                record_member_debt: false,
                source: "org_funds".to_string(),
                amount: 125.0,
                commit: true,
            })
            .unwrap();

        assert_eq!(result.org.funds, 375.0);
        assert!(result.org.credit_lines.is_empty());
        assert!(result.patch.contains_key("funds"));
        assert!(!result.patch.contains_key("credit_lines"));
    }

    #[test]
    fn org_funds_checkout_can_record_member_debt() {
        let hot_repository = InMemoryOrgHotRepository::new();
        hot_repository.save(&test_hot_org()).unwrap();
        let service = test_service(hot_repository);

        let result = service
            .charge_checkout(OrgCheckoutContext {
                requester_uid: "member".to_string(),
                org_id: "org".to_string(),
                requester_is_default_org_ceo: false,
                allow_member_charge: true,
                record_member_debt: true,
                source: "org_funds".to_string(),
                amount: 100.0,
                commit: true,
            })
            .unwrap();

        let credit_line = result.org.credit_lines.get("member").unwrap();
        assert_eq!(result.org.funds, 400.0);
        assert_eq!(credit_line.uid, "member");
        assert_eq!(credit_line.name, "Medic Patient");
        assert_eq!(credit_line.outstanding_principal, 100.0);
        assert_eq!(credit_line.amount_due, 100.0);
        assert_eq!(credit_line.available_amount, 0.0);
        assert!(result.patch.contains_key("funds"));
        assert!(result.patch.contains_key("credit_lines"));
    }
}
