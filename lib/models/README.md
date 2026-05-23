# Forge Models

This crate defines the shared data structures (models) used throughout the Forge application. These models represent the core entities of the game and are shared between the Extension, Service, and Repository layers.

## Actor Model

The `Actor` struct represents a player in the game. It contains all persistent data associated with a character.

### Fields

| Field          | Type                     | Description                                    |
| :------------- | :----------------------- | :--------------------------------------------- |
| `uid`          | `String`                 | Unique Steam ID (64-bit). Immutable.           |
| `name`         | `Option<String>`         | Player's display name.                         |
| `loadout`      | `serde_json::Value`      | JSON representation of the player's equipment. |
| `position`     | `Option<Vec<f64>>`       | `[x, y, z]` coordinates.                       |
| `direction`    | `f64`                    | Compass direction (0-360).                     |
| `stance`       | `Option<String>`         | Player stance (e.g., "STAND", "CROUCH").       |
| `email`        | `String`                 | In-game email address (auto-generated).        |
| `phone_number` | `String`                 | In-game phone number (auto-generated).         |
| `bank`         | `f64`                    | Money in the bank.                             |
| `cash`         | `f64`                    | Money on hand.                                 |
| `earnings`     | `f64`                    | Total earnings.                                |
| `state`        | `String`                 | Health/Status state (default: "HEALTHY").      |
| `holster`      | `bool`                   | Whether the weapon is holstered.               |
| `rank`         | `Option<String>`         | Rank within an organization.                   |
| `organization` | `String`                 | ID of the organization the player belongs to.  |
| `transactions` | `Vec<serde_json::Value>` | History of financial transactions.             |

### Validation Rules

- **UID**: Must be a 17-digit numeric string.
- **Name**: Max 50 characters, cannot be empty if set.
- **Position**: Must be an array of 3 finite numbers.
- **Direction**: Must be between 0.0 and 360.0.
- **Phone Number**: Must start with "0160" and be 10 digits long.
- **Email**: Must end with "@spearnet.mil".

### Arma Integration

The `Actor` struct implements `FromArma` and `IntoArma` for seamless conversion between Rust structs and SQF values.

- **From Arma**: Expects a JSON string.
- **To Arma**: Returns a JSON string.

## Organization Model

The `Org` struct represents a guild, clan, or group of players.

### Fields

| Field        | Type     | Description                       |
| :----------- | :------- | :-------------------------------- |
| `id`         | `String` | Unique identifier (slug).         |
| `owner`      | `String` | UID of the organization leader.   |
| `name`       | `String` | Display name of the organization. |
| `funds`      | `f64`    | Shared organization funds.        |
| `reputation` | `i64`    | Organization's reputation score.  |

### Validation Rules

- **ID**: Alphanumeric and underscores only. Cannot be empty.
- **Owner**: Must be a valid 17-digit UID.
- **Name**: Max 100 characters, no control characters.
- **Funds**: Cannot be negative.

## Contributing

We welcome contributions to the Forge Models crate! When adding a new model, please follow these guidelines to ensure consistency.

### Adding a New Model

To add a new model (e.g., `Vehicle`), follow these steps:

1.  **Define the Struct**: Create a new file in `src/` (e.g., `src/vehicle.rs`) and define your struct.
    - Derive `Debug`, `Clone`, `Serialize`, and `Deserialize`.
    - Use `#[serde(default)]` for optional fields that should have default values.

    ```rust
    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct Vehicle {
        pub id: String,
        pub class_name: String,
        #[serde(default)]
        pub damage: f64,
    }
    ```

2.  **Implement `new`**: Provide a constructor that initializes the struct with valid defaults.

    ```rust
    impl Vehicle {
        pub fn new(id: String, class_name: String) -> Result<Self, String> {
            let vehicle = Self {
                id,
                class_name,
                damage: 0.0,
            };
            vehicle.validate()?;
            Ok(vehicle)
        }
    }
    ```

3.  **Implement `validate`**: Create a method to enforce business rules and data integrity.

    ```rust
    impl Vehicle {
        pub fn validate(&self) -> Result<(), String> {
            if self.id.is_empty() {
                return Err("ID cannot be empty".to_string());
            }
            if self.damage < 0.0 || self.damage > 1.0 {
                return Err("Damage must be between 0.0 and 1.0".to_string());
            }
            Ok(())
        }
    }
    ```

4.  **Implement Arma Traits**: Implement `FromArma` and `IntoArma` for SQF interoperability.

    ```rust
    use arma_rs::{FromArma, IntoArma, Value};

    impl FromArma for Vehicle {
        fn from_arma(s: String) -> Result<Self, arma_rs::FromArmaError> {
            serde_json::from_str(&s).map_err(|e| ... )
        }
    }

    impl IntoArma for Vehicle {
        fn to_arma(&self) -> Value {
            let json = serde_json::to_string(self).unwrap_or_default();
            Value::String(json)
        }
    }
    ```

5.  **Register the Module**: Add your new module to `src/lib.rs`.
    ```rust
    pub mod vehicle;
    pub use vehicle::Vehicle;
    ```
