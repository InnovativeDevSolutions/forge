use arma_rs::{FromArma, IntoArma};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VehicleCategory {
    Cars,
    Armor,
    Helis,
    Planes,
    Naval,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VGarage {
    pub cars: Vec<String>,
    pub armor: Vec<String>,
    pub helis: Vec<String>,
    pub planes: Vec<String>,
    pub naval: Vec<String>,
    pub other: Vec<String>,
}

impl VGarage {
    pub fn new() -> Self {
        Self::default_unlocks()
    }

    fn default_unlocks() -> Self {
        Self {
            cars: vec!["B_Quadbike_01_F".to_string()],
            armor: Vec::new(),
            helis: Vec::new(),
            planes: Vec::new(),
            naval: Vec::new(),
            other: Vec::new(),
        }
    }

    pub fn add(&mut self, category: VehicleCategory, classnames: Vec<String>) {
        let target_array = match category {
            VehicleCategory::Cars => &mut self.cars,
            VehicleCategory::Armor => &mut self.armor,
            VehicleCategory::Helis => &mut self.helis,
            VehicleCategory::Planes => &mut self.planes,
            VehicleCategory::Naval => &mut self.naval,
            VehicleCategory::Other => &mut self.other,
        };

        for classname in classnames {
            if !target_array.contains(&classname) {
                target_array.push(classname);
            }
        }
    }

    pub fn get(&self, category: VehicleCategory) -> &Vec<String> {
        match category {
            VehicleCategory::Cars => &self.cars,
            VehicleCategory::Armor => &self.armor,
            VehicleCategory::Helis => &self.helis,
            VehicleCategory::Planes => &self.planes,
            VehicleCategory::Naval => &self.naval,
            VehicleCategory::Other => &self.other,
        }
    }

    pub fn remove(&mut self, category: VehicleCategory, classname: &str) -> Option<String> {
        let target_array = match category {
            VehicleCategory::Cars => &mut self.cars,
            VehicleCategory::Armor => &mut self.armor,
            VehicleCategory::Helis => &mut self.helis,
            VehicleCategory::Planes => &mut self.planes,
            VehicleCategory::Naval => &mut self.naval,
            VehicleCategory::Other => &mut self.other,
        };

        target_array
            .iter()
            .position(|x| x == classname)
            .map(|pos| target_array.remove(pos))
    }
}

impl Default for VGarage {
    fn default() -> Self {
        Self::new()
    }
}

impl FromArma for VGarage {
    fn from_arma(s: String) -> Result<Self, arma_rs::FromArmaError> {
        serde_json::from_str(&s)
            .map_err(|e| arma_rs::FromArmaError::InvalidPrimitive(format!("Invalid JSON: {}", e)))
    }
}

impl IntoArma for VGarage {
    fn to_arma(&self) -> arma_rs::Value {
        let json_str = serde_json::to_string(self).unwrap_or_default();
        arma_rs::Value::String(json_str)
    }
}
