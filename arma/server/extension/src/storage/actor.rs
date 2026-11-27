use super::*;
use crate::api::{
    ApiClient, actor_from_api_record, actor_to_api_body, encode_segment, require_success,
};

/// Actor persistence through forge-webapi (`POST/GET/PUT/DELETE
/// /players/{uid}/actor`).
///
/// The API stores actors in its `player_actor` table. `create` sends the
/// full actor body; a 409 (already exists) falls through to a full
/// replace.
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
    /// operation fails with the construction error.
    pub fn configured() -> Self {
        match Self::new() {
            Ok(repository) => repository,
            Err(error) => {
                crate::log::log(
                    "actor",
                    "ERROR",
                    &format!(
                        "forge-webapi client unavailable, actor persistence disabled: {error}"
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
}

impl ActorRepository for ApiActorRepository {
    fn create(&self, actor: &Actor) -> Result<(), String> {
        let path = Self::path(&actor.uid);
        let body = actor_to_api_body(actor)?;
        let (status, response) = self.client.post(&path, Some(body))?;
        if status == reqwest::StatusCode::CONFLICT {
            return self.put_full(actor);
        }
        require_success("POST", &path, status, response)?;
        Ok(())
    }

    fn get_by_id(&self, id: &str) -> Result<Option<Actor>, String> {
        let path = Self::path(id);
        let (status, body) = self.client.get(&path)?;
        if status == reqwest::StatusCode::NOT_FOUND {
            return Ok(None);
        }
        let body = require_success("GET", &path, status, body)?;
        Ok(Some(actor_from_api_record(body)?))
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
        Ok(self.get_by_id(id)?.is_some())
    }
}
