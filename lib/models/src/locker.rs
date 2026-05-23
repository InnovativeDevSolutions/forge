use arma_rs::{FromArma, IntoArma};
use forge_shared::LockerValidationError;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Locker {
    pub items: HashMap<String, Item>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Item {
    pub category: String,
    pub classname: String,
    pub amount: u32,
}

impl Item {
    pub fn new<S: Into<String>>(
        category: S,
        classname: S,
        amount: u32,
    ) -> Result<Self, LockerValidationError> {
        let item = Self {
            category: category.into(),
            classname: classname.into(),
            amount,
        };

        item.validate()?;
        Ok(item)
    }

    pub fn validate(&self) -> Result<(), LockerValidationError> {
        if self.category.trim().is_empty() {
            return Err(LockerValidationError::CategoryEmpty);
        }

        if self.classname.trim().is_empty() {
            return Err(LockerValidationError::ClassnameEmpty);
        }

        if self.amount == 0 {
            return Err(LockerValidationError::AmountZero);
        }

        Ok(())
    }
}

impl Locker {
    pub fn new() -> Result<Self, LockerValidationError> {
        let locker = Self {
            items: HashMap::new(),
        };

        locker.validate()?;
        Ok(locker)
    }

    pub fn validate(&self) -> Result<(), LockerValidationError> {
        for item in self.items.values() {
            item.validate()?;
        }

        Ok(())
    }

    pub fn add_item(&mut self, item: Item) -> Result<(), LockerValidationError> {
        item.validate()?;
        self.items.insert(item.classname.clone(), item);
        Ok(())
    }

    pub fn remove_item(&mut self, classname: &str) -> Option<Item> {
        self.items.remove(classname)
    }

    pub fn get_item(&self, classname: &str) -> Option<&Item> {
        self.items.get(classname)
    }

    pub fn get_item_mut(&mut self, classname: &str) -> Option<&mut Item> {
        self.items.get_mut(classname)
    }
}

impl FromArma for Item {
    fn from_arma(s: String) -> Result<Self, arma_rs::FromArmaError> {
        serde_json::from_str(&s)
            .map_err(|e| arma_rs::FromArmaError::InvalidPrimitive(format!("Invalid JSON: {}", e)))
    }
}

impl IntoArma for Item {
    fn to_arma(&self) -> arma_rs::Value {
        let json_str = serde_json::to_string(self).unwrap_or_default();
        arma_rs::Value::String(json_str)
    }
}
