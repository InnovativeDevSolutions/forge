use super::common::*;
use super::*;
use crate::api::{
    ApiClient, actor_from_api_record, actor_to_api_body, encode_segment, require_success,
};

/// Actor persistence through forge-webapi (`POST/GET/PUT/DELETE
/// /players/{uid}/actor`).
///
/// The API stores actors in its own `player_actor` table (not the
/// legacy `actor` table — the legacy record is snake_case
/// `phone_number`, the API is camelCase `phoneNumber`, so sharing the
/// table would drop the phone number). `create` sends the full actor
/// body; a 409 (already exists) falls through to a full replace.
/// `create` checks `exists()` first — which migrates a legacy actor —
/// so it can never create an API record that shadows legacy data.
pub struct ApiActorRepository {
    client: ApiClient,
}

impl ApiActorRepository {
    pub fn new() -> Result<Self, String> {
        Ok(Self {
            client: ApiClient::configured()?,
        })
    }

    /// The API is the only persistence backend: build the client, and
    /// if that fails log loudly and return a repository whose every
    /// operation fails with the construction error. There is no
    /// fallback to SurrealDB.
    pub fn configured() -> Self {
        match Self::new() {
            Ok(repository) => repository,
            Err(error) => {
                crate::log::log(
                    "actor",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, actor persistence disabled (no SurrealDB fallback): {error}"
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
        format!("/players/{}/actor", encode_segment(uid))
    }

    fn put_full(&self, actor: &Actor) -> Result<(), String> {
        let path = Self::path(&actor.uid);
        let body = actor_to_api_body(actor)?;
        let (status, response) = self.client.put(&path, Some(body))?;
        require_success("PUT", &path, status, response)?;
        Ok(())
    }

    /// Move a legacy actor into the API. Returns the migrated actor
    /// when one existed, `None` when there was no legacy record. A
    /// legacy-read error fails open (warn, `None` — the legacy row is
    /// left alone); an API-write error propagates. The legacy row is
    /// deleted best-effort after a successful PUT, so the actor lives
    /// in exactly one place.
    fn migrate(&self, uid: &str) -> Result<Option<Actor>, String> {
        let legacy = match LegacyActorRepository.get_by_id(uid) {
            Ok(legacy) => legacy,
            Err(error) => {
                crate::log::log(
                    "actor",
                    "WARN",
                    &format!(
                        "forge-webapi actor migration: legacy actor read failed for {uid}, proceeding without it: {error}"
                    ),
                );
                return Ok(None);
            }
        };
        let Some(actor) = legacy else {
            return Ok(None);
        };
        self.put_full(&actor)?;
        if let Err(error) = LegacyActorRepository.delete(uid) {
            crate::log::log(
                "actor",
                "WARN",
                &format!(
                    "forge-webapi actor migration: legacy actor delete failed for {uid} after migration: {error}"
                ),
            );
        }
        Ok(Some(actor))
    }

    /// GET the API record, migrating a legacy one on 404.
    fn get_or_migrate(&self, uid: &str) -> Result<Option<Actor>, String> {
        let path = Self::path(uid);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return self.migrate(uid);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(actor_from_api_record(body)?))
    }
}

impl ActorRepository for ApiActorRepository {
    fn create(&self, actor: &Actor) -> Result<(), String> {
        if self.exists(&actor.uid)? {
            self.put_full(actor)?;
            return Ok(());
        }
        let path = Self::path(&actor.uid);
        let body = actor_to_api_body(actor)?;
        let (status, response) = self.client.post(&path, Some(body))?;
        if status != reqwest::StatusCode::CONFLICT {
            require_success("POST", &path, status, response)?;
        } else {
            self.put_full(actor)?;
        }
        Ok(())
    }

    fn get_by_id(&self, id: &str) -> Result<Option<Actor>, String> {
        self.get_or_migrate(id)
    }

    fn update(&self, actor: &Actor) -> Result<(), String> {
        self.put_full(actor)
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
        Ok(self.get_or_migrate(id)?.is_some())
    }
}

/// Legacy actor rows in SurrealDB (`actor`).
///
/// Migration-only: read once by [`ApiActorRepository::migrate`] so a
/// legacy actor can be moved into the API, then deleted. Never used
/// as a live backend — there is no fallback.
pub struct LegacyActorRepository;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ActorRecord {
    uid: String,
    name: Option<String>,
    loadout: serde_json::Value,
    position: Option<Vec<f64>>,
    direction: f64,
    stance: Option<String>,
    email: String,
    phone_number: String,
    state: String,
    holster: bool,
    rank: Option<String>,
    organization: String,
}

impl ActorRecord {
    fn into_actor(self) -> Actor {
        Actor {
            uid: self.uid,
            name: self.name,
            loadout: self.loadout,
            position: self.position,
            direction: self.direction,
            stance: self.stance,
            email: self.email,
            phone_number: self.phone_number,
            state: self.state,
            holster: self.holster,
            rank: self.rank,
            organization: self.organization,
        }
    }
}

impl From<&Actor> for ActorRecord {
    fn from(actor: &Actor) -> Self {
        Self {
            uid: actor.uid.clone(),
            name: actor.name.clone(),
            loadout: actor.loadout.clone(),
            position: actor.position.clone(),
            direction: actor.direction,
            stance: actor.stance.clone(),
            email: actor.email.clone(),
            phone_number: actor.phone_number.clone(),
            state: actor.state.clone(),
            holster: actor.holster,
            rank: actor.rank.clone(),
            organization: actor.organization.clone(),
        }
    }
}

impl ActorRepository for LegacyActorRepository {
    fn create(&self, actor: &Actor) -> Result<(), String> {
        self.update(actor)
    }

    fn get_by_id(&self, id: &str) -> Result<Option<Actor>, String> {
        surreal_select::<ActorRecord>("actor", id, "actor")
            .map(|record| record.map(ActorRecord::into_actor))
    }

    fn update(&self, actor: &Actor) -> Result<(), String> {
        let record = ActorRecord::from(actor);
        surreal_upsert("actor", actor.uid.as_str(), "actor", &record)
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        surreal_delete::<ActorRecord>("actor", id, "actor")
    }

    fn exists(&self, id: &str) -> Result<bool, String> {
        self.get_by_id(id).map(|actor| actor.is_some())
    }
}
