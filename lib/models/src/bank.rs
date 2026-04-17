use arma_rs::{FromArma, IntoArma};
use forge_shared::BankValidationError;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bank {
    pub uid: String,
    pub name: String,
    pub bank: f64,
    pub cash: f64,
    pub earnings: f64,
    pub pin: u64,
    pub transactions: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BankMutationResult {
    pub account: Bank,
    pub patch: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BankTransferResult {
    pub source_account: Bank,
    pub source_patch: HashMap<String, serde_json::Value>,
    pub target_account: Bank,
    pub target_patch: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BankOperationContext {
    pub mode: String,
    pub atm_authorized: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BankTransferContext {
    pub mode: String,
    pub atm_authorized: bool,
    pub from_field: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BankCheckoutContext {
    pub source_field: String,
    pub commit: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BankPinContext {
    pub mode: String,
}

impl Bank {
    pub fn new<S: Into<String>>(uid: S, name: S, pin: u64) -> Result<Self, BankValidationError> {
        let bank = Self {
            uid: uid.into(),
            name: name.into(),
            bank: 0.0,
            cash: 0.0,
            earnings: 0.0,
            pin,
            transactions: Vec::new(),
        };

        bank.validate()?;
        Ok(bank)
    }

    pub fn validate(&self) -> Result<(), BankValidationError> {
        if self.uid.trim().is_empty() {
            return Err(BankValidationError::UidEmpty);
        }

        if self.name.trim().is_empty() {
            return Err(BankValidationError::NameEmpty);
        }

        if self.bank < 0.0 {
            return Err(BankValidationError::BankNegative);
        }

        if self.cash < 0.0 {
            return Err(BankValidationError::CashNegative);
        }

        if self.pin < 1000 || self.pin > 9999 {
            return Err(BankValidationError::InvalidPin(self.pin));
        }

        Ok(())
    }

    pub fn uid(&self) -> &str {
        &self.uid
    }
}

impl FromArma for Bank {
    fn from_arma(s: String) -> Result<Self, arma_rs::FromArmaError> {
        serde_json::from_str(&s)
            .map_err(|e| arma_rs::FromArmaError::InvalidPrimitive(format!("Invalid JSON: {}", e)))
    }
}

impl IntoArma for Bank {
    fn to_arma(&self) -> arma_rs::Value {
        let json_str = serde_json::to_string(self).unwrap_or_default();
        arma_rs::Value::String(json_str)
    }
}
