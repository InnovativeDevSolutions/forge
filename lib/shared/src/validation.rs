use std::fmt;

/// Validation errors for Actor model
#[derive(Debug, Clone)]
pub enum ActorValidationError {
    EmptyUid,
    InvalidName(String),
    InvalidUid(String),
    InvalidPosition(String),
    InvalidDirection(f64),
    InvalidEmail(String),
    InvalidPhoneNumber(String),
    InvalidState(String),
    InvalidRank(String),
    InvalidOrganization(String),
    LoadoutError(String),
    UidModificationAttempt,
}

impl fmt::Display for ActorValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ActorValidationError::EmptyUid => write!(f, "UID cannot be empty"),
            ActorValidationError::InvalidName(name) => write!(
                f,
                "Invalid name '{}' - cannot be empty or longer than 50 characters",
                name
            ),
            ActorValidationError::InvalidUid(uid) => write!(
                f,
                "Invalid UID format '{}' - must be a 17-digit Steam ID",
                uid
            ),
            ActorValidationError::InvalidPosition(msg) => write!(f, "Invalid position: {}", msg),
            ActorValidationError::InvalidDirection(dir) => write!(
                f,
                "Invalid direction {} - must be between 0 and 360 degrees",
                dir
            ),
            ActorValidationError::InvalidEmail(email) => write!(
                f,
                "Invalid email format '{}' - must contain @ and end with .mil",
                email
            ),
            ActorValidationError::InvalidPhoneNumber(phone) => write!(
                f,
                "Invalid phone number '{}' - must start with 0160 and be 10 digits",
                phone
            ),
            ActorValidationError::InvalidState(state) => write!(
                f,
                "Invalid state '{}' - must be HEALTHY, INJURED, INCAPACITATED, or DEAD",
                state
            ),
            ActorValidationError::InvalidRank(rank) => write!(
                f,
                "Invalid rank '{}' - cannot be empty or longer than 50 characters",
                rank
            ),
            ActorValidationError::InvalidOrganization(org) => write!(
                f,
                "Invalid organization '{}' - cannot be empty or longer than 100 characters",
                org
            ),
            ActorValidationError::LoadoutError(msg) => write!(f, "Loadout error: {}", msg),
            ActorValidationError::UidModificationAttempt => write!(
                f,
                "UID cannot be modified - it's the player's permanent Steam ID"
            ),
        }
    }
}

impl std::error::Error for ActorValidationError {}

/// Validation errors for Organization model
#[derive(Debug, Clone)]
pub enum OrgValidationError {
    EmptyId,
    EmptyOwner,
    EmptyName,
    NegativeFunds,
    NegativeCreditLine(String),
    InvalidId(String),
    InvalidOwner(String),
    InvalidName(String),
    InvalidCreditLineUid(String),
}

impl fmt::Display for OrgValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            OrgValidationError::EmptyId => write!(f, "Organization ID cannot be empty"),
            OrgValidationError::EmptyOwner => write!(f, "Organization owner cannot be empty"),
            OrgValidationError::EmptyName => write!(f, "Organization name cannot be empty"),
            OrgValidationError::NegativeFunds => {
                write!(f, "Organization funds cannot be negative")
            }
            OrgValidationError::NegativeCreditLine(uid) => {
                write!(f, "Credit line for '{}' cannot be negative", uid)
            }
            OrgValidationError::InvalidId(id) => write!(
                f,
                "Invalid organization ID '{}' - must contain only alphanumeric characters and underscores",
                id
            ),
            OrgValidationError::InvalidOwner(owner) => {
                write!(f, "Invalid owner '{}' - must be a 17-digit Steam ID", owner)
            }
            OrgValidationError::InvalidName(name) => write!(
                f,
                "Invalid organization name '{}' - cannot exceed 100 characters or contain control characters",
                name
            ),
            OrgValidationError::InvalidCreditLineUid(uid) => write!(
                f,
                "Invalid credit line UID '{}' - must be a 17-digit Steam ID",
                uid
            ),
        }
    }
}

impl std::error::Error for OrgValidationError {}

/// Validation errors for Bank model
#[derive(Debug, Clone)]
pub enum BankValidationError {
    UidEmpty,
    NameEmpty,
    BankNegative,
    CashNegative,
    InvalidPin(u64),
}

impl fmt::Display for BankValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            BankValidationError::UidEmpty => write!(f, "UID cannot be empty"),
            BankValidationError::NameEmpty => write!(f, "Name cannot be empty"),
            BankValidationError::BankNegative => write!(f, "Bank balance cannot be negative"),
            BankValidationError::CashNegative => write!(f, "Cash cannot be negative"),
            BankValidationError::InvalidPin(pin) => {
                write!(f, "Invalid PIN format '{}' - must be a 4-digit number", pin)
            }
        }
    }
}

impl std::error::Error for BankValidationError {}

/// Validation errors for Garage model
#[derive(Debug, Clone)]
pub enum GarageValidationError {
    UidEmpty,
    ClassnameEmpty,
    FuelInvalid,
    DamageInvalid,
    HitpointNamesEmpty,
    SelectionNamesEmpty,
    DamageValuesEmpty,
    HitpointArrayLengthMismatch,
    HitpointValueInvalid(usize),
}

impl fmt::Display for GarageValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            GarageValidationError::UidEmpty => write!(f, "UID cannot be empty"),
            GarageValidationError::ClassnameEmpty => write!(f, "Classname cannot be empty"),
            GarageValidationError::FuelInvalid => write!(f, "Fuel must be between 0.0 and 1.0"),
            GarageValidationError::DamageInvalid => write!(f, "Damage must be between 0.0 and 1.0"),
            GarageValidationError::HitpointNamesEmpty => {
                write!(f, "Hitpoint names cannot be empty")
            }
            GarageValidationError::SelectionNamesEmpty => {
                write!(f, "Selection names cannot be empty")
            }
            GarageValidationError::DamageValuesEmpty => write!(f, "Damage values cannot be empty"),
            GarageValidationError::HitpointArrayLengthMismatch => write!(
                f,
                "Hit point arrays (names, selections, values) must all have the same length"
            ),
            GarageValidationError::HitpointValueInvalid(index) => write!(
                f,
                "Hitpoint value at index {} is invalid - must be between 0.0 and 1.0",
                index
            ),
        }
    }
}

impl std::error::Error for GarageValidationError {}

/// Validation errors for Locker model
#[derive(Debug, Clone)]
pub enum LockerValidationError {
    UidEmpty,
    CategoryEmpty,
    ClassnameEmpty,
    AmountZero,
    ItemValidationError,
}

impl fmt::Display for LockerValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            LockerValidationError::UidEmpty => write!(f, "UID cannot be empty"),
            LockerValidationError::CategoryEmpty => write!(f, "Category cannot be empty"),
            LockerValidationError::ClassnameEmpty => write!(f, "Classname cannot be empty"),
            LockerValidationError::AmountZero => write!(f, "Amount cannot be zero"),
            LockerValidationError::ItemValidationError => write!(f, "Item validation error"),
        }
    }
}

impl std::error::Error for LockerValidationError {}
