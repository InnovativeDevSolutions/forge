use arma_rs::{FromArma, IntoArma};
use forge_shared::GarageValidationError;
use serde::{Deserialize, Deserializer, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Garage {
    pub vehicles: HashMap<String, Vehicle>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Vehicle {
    pub plate: String,
    pub classname: String,
    pub fuel: f64,
    pub damage: f64,
    pub hit_points: HitPoints,
}

#[derive(Debug, Clone, Serialize)]
pub struct HitPoints {
    pub names: Vec<String>,
    pub selections: Vec<String>,
    pub values: Vec<f64>,
}

#[derive(Deserialize)]
struct HitPointsWire {
    #[serde(default)]
    names: Vec<String>,
    #[serde(default)]
    selections: Vec<String>,
    #[serde(default)]
    values: Vec<f64>,
}

impl HitPoints {
    pub fn new() -> Self {
        Self {
            names: Vec::new(),
            selections: Vec::new(),
            values: Vec::new(),
        }
    }

    fn normalize_legacy_fields(&mut self) {
        if self.names.is_empty()
            && !self.selections.is_empty()
            && self.selections.len() == self.values.len()
        {
            self.names = self.selections.clone();
        }

        if self.selections.is_empty()
            && !self.names.is_empty()
            && self.names.len() == self.values.len()
        {
            self.selections = self.names.clone();
        }
    }

    pub fn from_json_str(json_str: &str) -> Result<Self, String> {
        let hit_points: HitPoints = serde_json::from_str(json_str)
            .map_err(|e| format!("Failed to parse hit_points JSON: {}", e))?;

        let names_len = hit_points.names.len();
        let selections_len = hit_points.selections.len();
        let values_len = hit_points.values.len();

        if names_len != selections_len || names_len != values_len {
            return Err(format!(
                "Hitpoint array length mismatch: names={}, selections={}, values={}",
                names_len, selections_len, values_len
            ));
        }

        Ok(hit_points)
    }
}

impl<'de> Deserialize<'de> for HitPoints {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let wire = HitPointsWire::deserialize(deserializer)?;
        let mut hit_points = Self {
            names: wire.names,
            selections: wire.selections,
            values: wire.values,
        };
        hit_points.normalize_legacy_fields();
        Ok(hit_points)
    }
}

impl Default for HitPoints {
    fn default() -> Self {
        Self::new()
    }
}

impl Vehicle {
    pub fn new<S: Into<String>>(
        plate: S,
        classname: S,
        fuel: f64,
        damage: f64,
        hit_points: HitPoints,
    ) -> Result<Self, GarageValidationError> {
        let vehicle = Self {
            plate: plate.into(),
            classname: classname.into(),
            fuel,
            damage,
            hit_points,
        };

        vehicle.validate()?;
        Ok(vehicle)
    }

    pub fn validate(&self) -> Result<(), GarageValidationError> {
        if self.classname.trim().is_empty() {
            return Err(GarageValidationError::ClassnameEmpty);
        }

        if self.fuel < 0.0 || self.fuel > 1.0 {
            return Err(GarageValidationError::FuelInvalid);
        }

        if self.damage < 0.0 || self.damage > 1.0 {
            return Err(GarageValidationError::DamageInvalid);
        }

        let names_len = self.hit_points.names.len();
        let selections_len = self.hit_points.selections.len();
        let values_len = self.hit_points.values.len();

        if names_len != selections_len || names_len != values_len {
            return Err(GarageValidationError::HitpointArrayLengthMismatch);
        }

        for (i, value) in self.hit_points.values.iter().enumerate() {
            if *value < 0.0 || *value > 1.0 {
                return Err(GarageValidationError::HitpointValueInvalid(i));
            }
        }

        Ok(())
    }
}

impl Garage {
    pub fn new() -> Result<Self, GarageValidationError> {
        let garage = Self {
            vehicles: HashMap::new(),
        };

        garage.validate()?;
        Ok(garage)
    }

    pub fn validate(&self) -> Result<(), GarageValidationError> {
        for vehicle in self.vehicles.values() {
            vehicle.validate()?;
        }

        Ok(())
    }

    pub fn add_vehicle(&mut self, vehicle: Vehicle) -> Result<(), GarageValidationError> {
        vehicle.validate()?;
        self.vehicles.insert(vehicle.plate.clone(), vehicle);
        Ok(())
    }

    pub fn remove_vehicle(&mut self, plate: &str) -> Option<Vehicle> {
        self.vehicles.remove(plate)
    }

    pub fn get_vehicle(&self, plate: &str) -> Option<&Vehicle> {
        self.vehicles.get(plate)
    }

    pub fn get_vehicle_mut(&mut self, plate: &str) -> Option<&mut Vehicle> {
        self.vehicles.get_mut(plate)
    }
}

impl FromArma for Vehicle {
    fn from_arma(s: String) -> Result<Self, arma_rs::FromArmaError> {
        serde_json::from_str(&s)
            .map_err(|e| arma_rs::FromArmaError::InvalidPrimitive(format!("Invalid JSON: {}", e)))
    }
}

impl IntoArma for Vehicle {
    fn to_arma(&self) -> arma_rs::Value {
        let json_str = serde_json::to_string(self).unwrap_or_default();
        arma_rs::Value::String(json_str)
    }
}

#[cfg(test)]
mod tests {
    use super::HitPoints;

    #[test]
    fn deserializes_legacy_hit_points_missing_names() {
        let hit_points =
            HitPoints::from_json_str(r#"{"selections":["engine_hitpoint"],"values":[0.35]}"#)
                .expect("legacy hit points should deserialize");

        assert_eq!(hit_points.names, vec!["engine_hitpoint"]);
        assert_eq!(hit_points.selections, vec!["engine_hitpoint"]);
        assert_eq!(hit_points.values, vec![0.35]);
    }

    #[test]
    fn deserializes_empty_legacy_hit_points_object() {
        let hit_points =
            HitPoints::from_json_str(r#"{}"#).expect("empty legacy hit points should deserialize");

        assert!(hit_points.names.is_empty());
        assert!(hit_points.selections.is_empty());
        assert!(hit_points.values.is_empty());
    }

    #[test]
    fn rejects_unbalanced_legacy_hit_points() {
        let error =
            HitPoints::from_json_str(r#"{"selections":["engine_hitpoint"],"values":[0.35,0.5]}"#)
                .expect_err("unbalanced hit points should be rejected");

        assert!(error.contains("Hitpoint array length mismatch"));
    }
}
