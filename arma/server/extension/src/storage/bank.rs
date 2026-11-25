use super::common::*;
use super::*;
use crate::api::{
    ApiClient, bank_from_api_record, bank_to_api_body, encode_segment, require_success,
};

/// Bank persistence through forge-webapi (`POST/GET/PUT/DELETE
/// /players/{uid}/bank`).
///
/// `create` keeps the original's upsert semantics: the API's create
/// only takes `{ name, pin }` and starts every balance at zero, so a
/// non-default create is followed by a full replace, and a 409
/// (already exists) falls through to the replace when there is
/// anything to write. `create` checks `exists()` first — which
/// migrates a legacy account — so it can never create an empty API
/// record that shadows legacy balances.
pub struct ApiBankRepository {
    client: ApiClient,
}

impl ApiBankRepository {
    pub fn new() -> Result<Self, String> {
        Ok(Self {
            client: ApiClient::configured()?,
        })
    }

    /// The API is the only persistence backend: build the client, and
    /// if that fails log loudly and return a repository whose every
    /// operation fails with the construction error. There is no
    /// fallback to SurrealDB.
    pub fn configured() -> Self {
        match Self::new() {
            Ok(repository) => repository,
            Err(error) => {
                crate::log::log(
                    "bank",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, bank persistence disabled (no SurrealDB fallback): {error}"
                    ),
                );
                Self::unavailable(error)
            }
        }
    }

    /// A repository that fails every operation with `error`: used when
    /// the API client could not be built.
    pub fn unavailable(error: String) -> Self {
        Self {
            client: ApiClient::unavailable(error),
        }
    }

    fn path(uid: &str) -> String {
        format!("/players/{}/bank", encode_segment(uid))
    }

    /// A bank whose balances or transaction log differ from a fresh
    /// account: only those need a full replace after create.
    fn is_non_default(bank: &Bank) -> bool {
        bank.bank != 0.0
            || bank.cash != 0.0
            || bank.earnings != 0.0
            || !bank.transactions.is_empty()
    }

    fn put_full(&self, bank: &Bank) -> Result<(), String> {
        let path = Self::path(&bank.uid);
        let body = bank_to_api_body(bank)?;
        let (status, response) = self.client.put(&path, Some(body))?;
        require_success("PUT", &path, status, response)?;
        Ok(())
    }

    /// Move a legacy bank account into the API. Returns the migrated
    /// account when one existed, `None` when there was no legacy
    /// record. A legacy-read error fails open (warn, `None` — the
    /// legacy rows are left alone); an API-write error propagates.
    /// The legacy rows are deleted best-effort after a successful PUT,
    /// so the account lives in exactly one place.
    fn migrate(&self, uid: &str) -> Result<Option<Bank>, String> {
        let legacy = match LegacyBankRepository.get_by_id(uid) {
            Ok(legacy) => legacy,
            Err(error) => {
                crate::log::log(
                    "bank",
                    "WARN",
                    &format!(
                        "forge-webapi bank migration: legacy bank read failed for {uid}, proceeding without it: {error}"
                    ),
                );
                return Ok(None);
            }
        };
        let Some(bank) = legacy else {
            return Ok(None);
        };
        self.put_full(&bank)?;
        if let Err(error) = LegacyBankRepository.delete(uid) {
            crate::log::log(
                "bank",
                "WARN",
                &format!(
                    "forge-webapi bank migration: legacy bank delete failed for {uid} after migration: {error}"
                ),
            );
        }
        Ok(Some(bank))
    }

    /// GET the API record, migrating a legacy one on 404.
    fn get_or_migrate(&self, uid: &str) -> Result<Option<Bank>, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return self.migrate(uid);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(bank_from_api_record(body)?))
    }
}

impl BankRepository for ApiBankRepository {
    fn create(&self, bank: &Bank) -> Result<(), String> {
        if self.exists(&bank.uid)? {
            if Self::is_non_default(bank) {
                self.put_full(bank)?;
            }
            return Ok(());
        }
        let path = Self::path(&bank.uid);
        let (status, body) = self.client.post(
            &path,
            Some(serde_json::json!({ "name": bank.name, "pin": bank.pin })),
        )?;
        if status != reqwest::StatusCode::CONFLICT {
            require_success("POST", &path, status, body)?;
        }
        if Self::is_non_default(bank) {
            self.put_full(bank)?;
        }
        Ok(())
    }

    fn get_by_id(&self, id: &str) -> Result<Option<Bank>, String> {
        self.get_or_migrate(id)
    }

    fn update(&self, bank: &Bank) -> Result<(), String> {
        self.put_full(bank)
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        let path = Self::path(id);
        let (status, body) = self.client.delete(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(());
        }
        require_success("DELETE", &path, status, body)?;
        Ok(())
    }

    fn exists(&self, id: &str) -> Result<bool, String> {
        Ok(self.get_or_migrate(id)?.is_some())
    }
}

/// Legacy bank rows in SurrealDB (`bank`, `bank_transaction`).
///
/// Migration-only: read once by [`ApiBankRepository::migrate`] so a
/// legacy account can be moved into the API, then deleted. Never used
/// as a live backend — there is no fallback.
pub struct LegacyBankRepository;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct BankAccountRecord {
    uid: String,
    name: String,
    bank: f64,
    cash: f64,
    earnings: f64,
    pin: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct BankTransactionRecord {
    uid: String,
    ordinal: u64,
    message: String,
}

impl BankAccountRecord {
    fn into_bank(self, transactions: Vec<String>) -> Bank {
        Bank {
            uid: self.uid,
            name: self.name,
            bank: self.bank,
            cash: self.cash,
            earnings: self.earnings,
            pin: self.pin,
            transactions,
        }
    }
}

impl From<&Bank> for BankAccountRecord {
    fn from(bank: &Bank) -> Self {
        Self {
            uid: bank.uid.clone(),
            name: bank.name.clone(),
            bank: bank.bank,
            cash: bank.cash,
            earnings: bank.earnings,
            pin: bank.pin,
        }
    }
}

fn bank_transaction_id(uid: &str, ordinal: usize) -> String {
    format!("{}:{}", uid, ordinal)
}

fn bank_transactions_from_records(mut records: Vec<BankTransactionRecord>) -> Vec<String> {
    records.sort_by_key(|record| record.ordinal);
    records
        .into_iter()
        .map(|record| record.message)
        .collect::<Vec<_>>()
}

impl BankRepository for LegacyBankRepository {
    fn create(&self, bank: &Bank) -> Result<(), String> {
        self.update(bank)
    }

    fn get_by_id(&self, id: &str) -> Result<Option<Bank>, String> {
        let Some(record) = surreal_select::<BankAccountRecord>("bank", id, "bank")? else {
            return Ok(None);
        };

        let transaction_records = surreal_select_by_uid::<BankTransactionRecord>(
            "bank_transaction",
            "bank transactions",
            id,
        )?;
        let transactions = bank_transactions_from_records(transaction_records);

        Ok(Some(record.into_bank(transactions)))
    }

    fn update(&self, bank: &Bank) -> Result<(), String> {
        let account = BankAccountRecord::from(bank);
        surreal_upsert("bank", bank.uid.as_str(), "bank", &account)?;
        surreal_delete_by_uid("bank_transaction", "bank transactions", &bank.uid)?;

        for (ordinal, message) in bank.transactions.iter().enumerate() {
            let record = BankTransactionRecord {
                uid: bank.uid.clone(),
                ordinal: ordinal as u64,
                message: message.clone(),
            };
            surreal_upsert(
                "bank_transaction",
                &bank_transaction_id(&bank.uid, ordinal),
                "bank transaction",
                &record,
            )?;
        }

        Ok(())
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        surreal_delete_by_uid("bank_transaction", "bank transactions", id)?;
        surreal_delete::<BankAccountRecord>("bank", id, "bank")
    }

    fn exists(&self, id: &str) -> Result<bool, String> {
        self.get_by_id(id).map(|bank| bank.is_some())
    }
}
