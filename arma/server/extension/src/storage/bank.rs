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
/// anything to write.
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
    /// operation fails with the construction error.
    pub fn configured() -> Self {
        match Self::new() {
            Ok(repository) => repository,
            Err(error) => {
                crate::log::log(
                    "bank",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, bank persistence disabled: {error}"
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
}

impl BankRepository for ApiBankRepository {
    fn create(&self, bank: &Bank) -> Result<(), String> {
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
        let path = Self::path(id);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(None);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(bank_from_api_record(body)?))
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
        Ok(self.get_by_id(id)?.is_some())
    }
}
