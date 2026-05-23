use arma_rs::{FromArma, IntoArma};
use forge_shared::OrgValidationError;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

pub const DEFAULT_CREDIT_LINE_INTEREST_RATE: f64 = 0.10;

fn round_currency(value: f64) -> f64 {
    (value.max(0.0) * 100.0).round() / 100.0
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreditLineSummary {
    pub uid: String,
    pub name: String,
    #[serde(default)]
    pub approved_amount: f64,
    #[serde(default)]
    pub available_amount: f64,
    #[serde(default)]
    pub outstanding_principal: f64,
    #[serde(default = "default_credit_line_interest_rate")]
    pub interest_rate: f64,
    #[serde(default)]
    pub amount_due: f64,
    #[serde(default)]
    pub amount: f64,
}

fn default_credit_line_interest_rate() -> f64 {
    DEFAULT_CREDIT_LINE_INTEREST_RATE
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrgAssetEntry {
    pub classname: String,
    #[serde(rename = "type")]
    pub asset_type: String,
    pub quantity: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrgFleetEntry {
    pub classname: String,
    pub name: String,
    #[serde(rename = "type")]
    pub fleet_type: String,
    pub status: String,
    pub damage: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Org {
    pub id: String,
    pub owner: String,
    pub name: String,

    #[serde(default)]
    pub funds: f64,
    #[serde(default)]
    pub reputation: i64,
    #[serde(default)]
    pub credit_lines: HashMap<String, CreditLineSummary>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemberSummary {
    pub uid: String,
    pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgInviteRecord {
    pub org_id: String,
    pub org_name: String,
    pub inviter_uid: String,
    pub inviter_name: String,
    pub target_uid: String,
    pub target_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HotOrgRecord {
    pub id: String,
    pub owner: String,
    pub name: String,
    pub funds: f64,
    pub reputation: i64,
    #[serde(default)]
    pub credit_lines: HashMap<String, CreditLineSummary>,
    #[serde(default)]
    pub assets: HashMap<String, HashMap<String, OrgAssetEntry>>,
    #[serde(default)]
    pub fleet: HashMap<String, OrgFleetEntry>,
    #[serde(default)]
    pub members: HashMap<String, MemberSummary>,
    #[serde(default)]
    pub pending_invites: HashMap<String, OrgInviteRecord>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgEnsureMemberContext {
    pub org_id: String,
    pub member_uid: String,
    pub member_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgRegisterContext {
    pub requester_uid: String,
    pub requester_name: String,
    pub org_id: String,
    pub org_name: String,
    pub existing_org_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgRegisterResult {
    pub org: HotOrgRecord,
    pub actor_organization: String,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgInviteContext {
    pub requester_uid: String,
    pub requester_name: String,
    pub org_id: String,
    pub requester_is_default_org_ceo: bool,
    pub target_uid: String,
    pub target_name: String,
    pub target_org_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgInviteDecisionContext {
    pub requester_uid: String,
    pub requester_name: String,
    pub org_id: String,
    pub existing_org_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgInviteResult {
    pub org: HotOrgRecord,
    pub target_uid: String,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgInviteDecisionResult {
    pub invited_org: HotOrgRecord,
    pub previous_org: Option<HotOrgRecord>,
    pub actor_organization: String,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgCreditLineContext {
    pub requester_uid: String,
    pub org_id: String,
    pub requester_is_default_org_ceo: bool,
    pub member_uid: String,
    pub member_name: String,
    pub amount: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgCheckoutContext {
    pub requester_uid: String,
    pub org_id: String,
    pub requester_is_default_org_ceo: bool,
    #[serde(default)]
    pub allow_member_charge: bool,
    #[serde(default)]
    pub record_member_debt: bool,
    pub source: String,
    pub amount: f64,
    pub commit: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgCreditLineRepaymentContext {
    pub requester_uid: String,
    pub org_id: String,
    pub amount: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgAssetGrantSeed {
    pub classname: String,
    pub category: String,
    pub quantity: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgFleetGrantSeed {
    pub classname: String,
    pub category: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgGrantContext {
    pub requester_uid: String,
    pub org_id: String,
    pub commit: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgMutationResult {
    pub org: HotOrgRecord,
    pub patch: HashMap<String, serde_json::Value>,
    pub member_uids: Vec<String>,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgCreditLineRepaymentResult {
    pub org: HotOrgRecord,
    pub patch: HashMap<String, serde_json::Value>,
    pub member_uids: Vec<String>,
    pub paid_amount: f64,
    pub principal_paid: f64,
    pub interest_paid: f64,
    pub remaining_amount_due: f64,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgLeaveContext {
    pub requester_uid: String,
    pub requester_name: String,
    pub org_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgLeaveResult {
    pub actor_organization: String,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgDisbandMemberResult {
    pub uid: String,
    pub requester: bool,
    pub actor_organization: String,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OrgDisbandResult {
    pub message: String,
    pub members: Vec<OrgDisbandMemberResult>,
}

impl Org {
    pub fn new<S: Into<String>>(id: S, owner: S, name: S) -> Result<Self, OrgValidationError> {
        let org = Self {
            id: id.into(),
            owner: owner.into(),
            name: name.into(),
            funds: 0.0,
            reputation: 0,
            credit_lines: HashMap::new(),
        };

        org.validate()?;
        Ok(org)
    }

    pub fn validate(&self) -> Result<(), OrgValidationError> {
        if self.id.trim().is_empty() {
            return Err(OrgValidationError::EmptyId);
        }

        if self.owner.trim().is_empty() {
            return Err(OrgValidationError::EmptyOwner);
        }

        if self.name.trim().is_empty() {
            return Err(OrgValidationError::EmptyName);
        }

        if self.funds < 0.0 {
            return Err(OrgValidationError::NegativeFunds);
        }

        if self.reputation < 0 {
            return Err(OrgValidationError::InvalidName(
                "Organization reputation cannot be negative".to_string(),
            ));
        }

        if !self.id.chars().all(|c| c.is_alphanumeric() || c == '_') {
            return Err(OrgValidationError::InvalidId(self.id.clone()));
        }

        if self.owner != "server"
            && (!self.owner.chars().all(|c| c.is_numeric()) || self.owner.len() != 17)
        {
            return Err(OrgValidationError::InvalidOwner(self.owner.clone()));
        }

        if self.name.len() > 100 || self.name.chars().any(|c| c.is_control()) {
            return Err(OrgValidationError::InvalidName(self.name.clone()));
        }

        for (uid, credit_line) in &self.credit_lines {
            let resolved_uid = if credit_line.uid.trim().is_empty() {
                uid
            } else {
                &credit_line.uid
            };

            if !resolved_uid.chars().all(|c| c.is_numeric()) || resolved_uid.len() != 17 {
                return Err(OrgValidationError::InvalidCreditLineUid(
                    resolved_uid.to_string(),
                ));
            }

            if credit_line.approved_amount < 0.0
                || credit_line.available_amount < 0.0
                || credit_line.outstanding_principal < 0.0
                || credit_line.amount_due < 0.0
                || credit_line.amount < 0.0
            {
                return Err(OrgValidationError::NegativeCreditLine(
                    resolved_uid.to_string(),
                ));
            }
        }

        Ok(())
    }

    pub fn id(&self) -> &str {
        &self.id
    }

    pub fn normalize_credit_lines(&mut self) {
        for credit_line in self.credit_lines.values_mut() {
            credit_line.normalize();
        }
    }
}

impl HotOrgRecord {
    pub fn from_parts(
        org: Org,
        assets: HashMap<String, HashMap<String, OrgAssetEntry>>,
        fleet: HashMap<String, OrgFleetEntry>,
        members: Vec<MemberSummary>,
    ) -> Self {
        Self {
            id: org.id,
            owner: org.owner,
            name: org.name,
            funds: org.funds,
            reputation: org.reputation,
            credit_lines: org.credit_lines,
            assets,
            fleet,
            members: members
                .into_iter()
                .map(|member| (member.uid.clone(), member))
                .collect(),
            pending_invites: HashMap::new(),
        }
    }

    pub fn into_org(self) -> Org {
        let mut org = Org {
            id: self.id,
            owner: self.owner,
            name: self.name,
            funds: self.funds,
            reputation: self.reputation,
            credit_lines: self.credit_lines,
        };
        org.normalize_credit_lines();
        org
    }
}

impl CreditLineSummary {
    pub fn normalize(&mut self) {
        let legacy_amount = round_currency(self.amount);

        self.approved_amount = round_currency(self.approved_amount);
        self.available_amount = round_currency(self.available_amount);
        self.outstanding_principal = round_currency(self.outstanding_principal);
        self.amount_due = round_currency(self.amount_due);

        if self.approved_amount <= 0.0 && self.available_amount <= 0.0 && legacy_amount > 0.0 {
            self.approved_amount = legacy_amount;
            self.available_amount = legacy_amount;
        } else if self.approved_amount <= 0.0 && self.available_amount > 0.0 {
            self.approved_amount = self.available_amount;
        } else if self.available_amount <= 0.0 && self.approved_amount > 0.0 {
            self.available_amount = self.approved_amount;
        }

        if self.interest_rate <= 0.0 {
            self.interest_rate = DEFAULT_CREDIT_LINE_INTEREST_RATE;
        }

        if self.amount_due <= 0.0 && self.outstanding_principal > 0.0 {
            self.amount_due =
                round_currency(self.outstanding_principal * (1.0 + self.interest_rate));
        }

        self.amount = self.available_amount;
    }
}

impl FromArma for Org {
    fn from_arma(s: String) -> Result<Self, arma_rs::FromArmaError> {
        serde_json::from_str(&s)
            .map_err(|e| arma_rs::FromArmaError::InvalidPrimitive(format!("Invalid JSON: {}", e)))
    }
}

impl IntoArma for Org {
    fn to_arma(&self) -> arma_rs::Value {
        let json_str = serde_json::to_string(self).unwrap_or_default();
        arma_rs::Value::String(json_str)
    }
}
