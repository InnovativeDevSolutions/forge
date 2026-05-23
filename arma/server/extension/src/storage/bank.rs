use super::common::*;
use super::*;

pub enum BankStorageRepository {
    Surreal(SurrealBankRepository),
}

impl BankStorageRepository {
    pub fn configured() -> Self {
        Self::Surreal(SurrealBankRepository)
    }
}

impl BankRepository for BankStorageRepository {
    fn create(&self, bank: &Bank) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(bank),
        }
    }

    fn get_by_id(&self, id: &str) -> Result<Option<Bank>, String> {
        match self {
            Self::Surreal(repository) => repository.get_by_id(id),
        }
    }

    fn update(&self, bank: &Bank) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(bank),
        }
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.delete(id),
        }
    }

    fn exists(&self, id: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.exists(id),
        }
    }
}

pub struct SurrealBankRepository;

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

impl BankRepository for SurrealBankRepository {
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
