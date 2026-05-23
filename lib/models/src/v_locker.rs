use arma_rs::{FromArma, IntoArma};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EquipmentCategory {
    Items,
    Weapons,
    Magazines,
    Backpacks,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VLocker {
    pub items: Vec<String>,
    pub weapons: Vec<String>,
    pub magazines: Vec<String>,
    pub backpacks: Vec<String>,
}

impl VLocker {
    pub fn new() -> Self {
        Self::default_unlocks()
    }

    fn default_unlocks() -> Self {
        Self {
            items: vec![
                "FirstAidKit".to_string(),
                "G_Combat".to_string(),
                "H_Cap_blk_ION".to_string(),
                "H_HelmetB".to_string(),
                "ACE_EarPlugs".to_string(),
                "ItemCompass".to_string(),
                "ItemGPS".to_string(),
                "ItemMap".to_string(),
                "ItemRadio".to_string(),
                "ItemWatch".to_string(),
                "U_BG_Guerrilla_6_1".to_string(),
                "V_TacVest_oli".to_string(),
            ],
            weapons: vec!["arifle_MX_F".to_string(), "hgun_P07_F".to_string()],
            magazines: vec![
                "16Rnd_9x21_Mag".to_string(),
                "30Rnd_65x39_caseless_black_mag".to_string(),
                "Chemlight_blue".to_string(),
                "Chemlight_green".to_string(),
                "Chemlight_red".to_string(),
                "Chemlight_yellow".to_string(),
                "HandGrenade".to_string(),
                "SmokeShell".to_string(),
                "SmokeShellBlue".to_string(),
                "SmokeShellGreen".to_string(),
                "SmokeShellOrange".to_string(),
                "SmokeShellPurple".to_string(),
                "SmokeShellRed".to_string(),
                "SmokeShellYellow".to_string(),
            ],
            backpacks: vec!["B_AssaultPack_rgr".to_string()],
        }
    }

    pub fn add(&mut self, category: EquipmentCategory, classnames: Vec<String>) {
        let target_array = match category {
            EquipmentCategory::Items => &mut self.items,
            EquipmentCategory::Weapons => &mut self.weapons,
            EquipmentCategory::Magazines => &mut self.magazines,
            EquipmentCategory::Backpacks => &mut self.backpacks,
        };

        for classname in classnames {
            if !target_array.contains(&classname) {
                target_array.push(classname);
            }
        }
    }

    pub fn get(&self, category: EquipmentCategory) -> &Vec<String> {
        match category {
            EquipmentCategory::Items => &self.items,
            EquipmentCategory::Weapons => &self.weapons,
            EquipmentCategory::Magazines => &self.magazines,
            EquipmentCategory::Backpacks => &self.backpacks,
        }
    }

    pub fn remove(&mut self, category: EquipmentCategory, classname: &str) -> Option<String> {
        let target_array = match category {
            EquipmentCategory::Items => &mut self.items,
            EquipmentCategory::Weapons => &mut self.weapons,
            EquipmentCategory::Magazines => &mut self.magazines,
            EquipmentCategory::Backpacks => &mut self.backpacks,
        };

        target_array
            .iter()
            .position(|x| x == classname)
            .map(|pos| target_array.remove(pos))
    }
}

impl Default for VLocker {
    fn default() -> Self {
        Self::new()
    }
}

impl FromArma for VLocker {
    fn from_arma(s: String) -> Result<Self, arma_rs::FromArmaError> {
        serde_json::from_str(&s)
            .map_err(|e| arma_rs::FromArmaError::InvalidPrimitive(format!("Invalid JSON: {}", e)))
    }
}

impl IntoArma for VLocker {
    fn to_arma(&self) -> arma_rs::Value {
        let json_str = serde_json::to_string(self).unwrap_or_default();
        arma_rs::Value::String(json_str)
    }
}
