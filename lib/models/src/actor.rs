use arma_rs::{
    FromArma, IntoArma,
    loadout::{AssignedItems, InventoryItem, Loadout as ArmaLoadout},
};
use forge_shared::{
    ActorValidationError, arma_value_to_json, generate_email, generate_phone_number,
};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Actor {
    pub uid: String,
    pub name: Option<String>,

    #[serde(default)]
    pub loadout: serde_json::Value,

    pub position: Option<Vec<f64>>,
    #[serde(default)]
    pub direction: f64,
    pub stance: Option<String>,

    #[serde(default)]
    pub email: String,
    #[serde(default)]
    pub phone_number: String,

    #[serde(default)]
    pub state: String,
    #[serde(default)]
    pub holster: bool,
    pub rank: Option<String>,
    #[serde(default)]
    pub organization: String,
}

impl Actor {
    pub fn new<S: Into<String>>(uid: S) -> Result<Self, ActorValidationError> {
        let uid_string = uid.into();

        if uid_string.trim().is_empty() {
            return Err(ActorValidationError::EmptyUid);
        }

        if !uid_string.chars().all(|c| c.is_numeric()) || uid_string.len() != 17 {
            return Err(ActorValidationError::InvalidUid(uid_string));
        }

        let phone_number = generate_phone_number(&uid_string);
        let email = generate_email(&phone_number);

        let actor = Self {
            uid: uid_string,
            name: None,
            loadout: Self::default_loadout_json(),
            position: None,
            direction: 0.0,
            stance: None,
            email,
            phone_number,
            state: "HEALTHY".to_string(),
            holster: true,
            rank: None,
            organization: "default".to_string(),
        };

        actor.validate()?;
        Ok(actor)
    }

    pub fn validate(&self) -> Result<(), ActorValidationError> {
        if self.uid.trim().is_empty() {
            return Err(ActorValidationError::EmptyUid);
        }

        if !self.uid.chars().all(|c| c.is_numeric()) || self.uid.len() != 17 {
            return Err(ActorValidationError::InvalidUid(self.uid.clone()));
        }

        if let Some(ref name) = self.name
            && (name.trim().is_empty() || name.len() > 50)
        {
            return Err(ActorValidationError::InvalidName(name.clone()));
        }

        if let Some(ref pos) = self.position {
            if pos.len() != 3 {
                return Err(ActorValidationError::InvalidPosition(
                    "Position must have exactly 3 coordinates".to_string(),
                ));
            }
            for coord in pos {
                if !coord.is_finite() {
                    return Err(ActorValidationError::InvalidPosition(
                        "Position coordinates must be finite numbers".to_string(),
                    ));
                }
            }
        }

        if !self.direction.is_finite() || self.direction < 0.0 || self.direction >= 360.0 {
            return Err(ActorValidationError::InvalidDirection(self.direction));
        }

        if !self.phone_number.is_empty()
            && (!self.phone_number.starts_with("0160") || self.phone_number.len() != 10)
        {
            return Err(ActorValidationError::InvalidPhoneNumber(
                self.phone_number.clone(),
            ));
        }

        if !self.email.is_empty() && (!self.email.contains('@') || !self.email.ends_with(".mil")) {
            return Err(ActorValidationError::InvalidEmail(self.email.clone()));
        }

        if !self.organization.is_empty() && self.organization.len() > 100 {
            return Err(ActorValidationError::InvalidOrganization(
                self.organization.clone(),
            ));
        }

        Ok(())
    }

    pub fn uid(&self) -> &str {
        &self.uid
    }

    fn default_loadout_json() -> serde_json::Value {
        let mut loadout = ArmaLoadout::default();

        let uniform = loadout.uniform_mut();
        uniform.set_class("U_BG_Guerrilla_6_1".to_string());

        let uniform_items = uniform.items_mut().unwrap();
        uniform_items.push(InventoryItem::new_item("FirstAidKit".to_string(), 1));

        loadout.set_headgear("H_Cap_blk_ION".to_string());

        let mut items = AssignedItems::default();
        items.set_map("ItemMap".to_string());
        items.set_terminal("ItemGPS".to_string());
        items.set_radio("ItemRadio".to_string());
        items.set_compass("ItemCompass".to_string());
        items.set_watch("ItemWatch".to_string());
        loadout.set_assigned_items(items);

        let arma_value = loadout.to_arma();
        arma_value_to_json(&arma_value)
    }

    pub fn get_loadout(&self) -> Result<ArmaLoadout, String> {
        let loadout_str = serde_json::to_string(&self.loadout)
            .map_err(|e| format!("Failed to serialize loadout: {}", e))?;
        ArmaLoadout::from_arma(loadout_str).map_err(|e| format!("Failed to parse loadout: {}", e))
    }

    pub fn set_loadout(&mut self, loadout: ArmaLoadout) {
        let arma_value = loadout.to_arma();
        self.loadout = arma_value_to_json(&arma_value);
    }
}

impl FromArma for Actor {
    fn from_arma(s: String) -> Result<Self, arma_rs::FromArmaError> {
        let mut actor: Actor = serde_json::from_str(&s).map_err(|e| {
            arma_rs::FromArmaError::InvalidPrimitive(format!("Invalid JSON: {}", e))
        })?;

        if actor.organization.trim().is_empty() {
            actor.organization = "default".to_string();
        }

        Ok(actor)
    }
}

impl IntoArma for Actor {
    fn to_arma(&self) -> arma_rs::Value {
        let json_str = serde_json::to_string(self).unwrap_or_default();
        arma_rs::Value::String(json_str)
    }
}
