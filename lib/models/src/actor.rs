use arma_rs::{FromArma, IntoArma, loadout::Loadout as ArmaLoadout};
use forge_shared::{
    ActorValidationError, arma_value_to_json, generate_email, generate_phone_number, is_valid_uid,
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

        if !is_valid_uid(&uid_string) {
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

        if !is_valid_uid(&self.uid) {
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
        serde_json::Value::Array(Vec::new())
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_accepts_twelve_digit_single_player_uid() {
        // The 12-digit UID single-player hands out (from the 2026-11-24 log).
        let actor = Actor::new("805289554520").expect("12-digit SP UID should be accepted");
        assert_eq!(actor.uid(), "805289554520");
        // Phone number is built from the last 6 digits of the UID.
        assert_eq!(actor.phone_number, "0160554520");
    }

    #[test]
    fn new_accepts_seventeen_digit_steam_id() {
        let actor = Actor::new("76561198027566824").expect("17-digit Steam ID should be accepted");
        assert_eq!(actor.uid(), "76561198027566824");
        assert_eq!(actor.phone_number, "0160566824");
    }

    #[test]
    fn new_rejects_short_non_numeric_and_long_uids() {
        assert!(Actor::new("80528955452").is_err()); // 11 digits
        assert!(Actor::new("765611980275668241").is_err()); // 18 digits
        assert!(Actor::new("76561198A27566824").is_err()); // non-numeric
        assert!(Actor::new("").is_err());
        assert!(Actor::new("   ").is_err());
    }

    #[test]
    fn validate_accepts_twelve_digit_uid() {
        let actor = Actor::new("805289554520").unwrap();
        assert!(actor.validate().is_ok());
    }
}
