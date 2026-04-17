use super::common::*;
use super::*;

pub enum ActorStorageRepository {
    Surreal(SurrealActorRepository),
}

impl ActorStorageRepository {
    pub fn configured() -> Self {
        Self::Surreal(SurrealActorRepository)
    }
}

impl ActorRepository for ActorStorageRepository {
    fn create(&self, actor: &Actor) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.create(actor),
        }
    }

    fn get_by_id(&self, id: &str) -> Result<Option<Actor>, String> {
        match self {
            Self::Surreal(repository) => repository.get_by_id(id),
        }
    }

    fn update(&self, actor: &Actor) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.update(actor),
        }
    }

    fn delete(&self, id: &str) -> Result<(), String> {
        match self {
            Self::Surreal(repository) => repository.delete(id),
        }
    }

    fn exists(&self, id: &str) -> Result<bool, String> {
        match self {
            Self::Surreal(repository) => repository.exists(id),
        }
    }
}

pub struct SurrealActorRepository;

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

impl ActorRepository for SurrealActorRepository {
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
