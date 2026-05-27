//! SurrealDB connection bootstrap for persistent storage.

use arma_rs::Group;
use std::sync::{
    Arc, LazyLock, RwLock as StdRwLock,
    atomic::{AtomicU64, Ordering},
};
use surrealdb::Surreal;
use surrealdb::engine::remote::http::{Client, Http};
use surrealdb::opt::auth::Root;
use tokio::time::{Duration, sleep, timeout};

use crate::config::SurrealConfig;
use crate::log;
use crate::schema;
use crate::{RUNTIME, config};

pub type SurrealDb = Surreal<Client>;

const CLIENT_READY_TIMEOUT: Duration = Duration::from_secs(30);
const CLIENT_READY_POLL_INTERVAL: Duration = Duration::from_millis(25);

static SURREAL_DB: LazyLock<StdRwLock<Option<Arc<SurrealDb>>>> =
    LazyLock::new(|| StdRwLock::new(None));
static SURREAL_CONNECTION_STATE: LazyLock<StdRwLock<SurrealConnectionState>> =
    LazyLock::new(|| StdRwLock::new(SurrealConnectionState::Disabled));
static SURREAL_FAILURE_REASON: LazyLock<StdRwLock<Option<String>>> =
    LazyLock::new(|| StdRwLock::new(None));
static SURREAL_INIT_GENERATION: AtomicU64 = AtomicU64::new(0);

#[derive(Clone, Copy, PartialEq, Eq)]
enum SurrealConnectionState {
    Disabled,
    Initializing,
    Connected,
    Failed,
}

pub fn prepare() {
    *SURREAL_FAILURE_REASON.write().unwrap() = None;
    *SURREAL_CONNECTION_STATE.write().unwrap() = SurrealConnectionState::Initializing;
}

pub async fn initialize(config: SurrealConfig) {
    let generation = SURREAL_INIT_GENERATION.fetch_add(1, Ordering::SeqCst) + 1;
    prepare();

    log::log(
        "surreal",
        "INFO",
        &format!(
            "Connecting to SurrealDB endpoint '{}' namespace '{}' database '{}'",
            config.endpoint, config.namespace, config.database
        ),
    );

    let timeout_duration = Duration::from_millis(config.connect_timeout_ms.unwrap_or(5000));
    let connection = timeout(timeout_duration, connect(config)).await;

    let db = match connection {
        Err(_) => {
            if !is_current_generation(generation) {
                return;
            }
            log::log(
                "surreal",
                "ERROR",
                &format!(
                    "SurrealDB connection timed out after {} ms",
                    timeout_duration.as_millis()
                ),
            );
            set_failure_reason(format!(
                "SurrealDB connection timed out after {} ms",
                timeout_duration.as_millis()
            ));
            *SURREAL_CONNECTION_STATE.write().unwrap() = SurrealConnectionState::Failed;
            return;
        }
        Ok(Ok(db)) => db,
        Ok(Err(error)) => {
            if !is_current_generation(generation) {
                return;
            }
            log::log(
                "surreal",
                "ERROR",
                &format!("Failed to connect to SurrealDB: {}", error),
            );
            set_failure_reason(error);
            *SURREAL_CONNECTION_STATE.write().unwrap() = SurrealConnectionState::Failed;
            return;
        }
    };

    if !is_current_generation(generation) {
        return;
    }

    log::log("surreal", "DEBUG", "Applying SurrealDB schemas");
    if let Err(error) = schema::apply_all(&db).await {
        if !is_current_generation(generation) {
            return;
        }
        log::log(
            "surreal",
            "ERROR",
            &format!("Failed to apply SurrealDB schemas: {}", error),
        );
        set_failure_reason(error);
        *SURREAL_CONNECTION_STATE.write().unwrap() = SurrealConnectionState::Failed;
        return;
    }

    if !is_current_generation(generation) {
        return;
    }

    *SURREAL_DB.write().unwrap() = Some(Arc::new(db));
    log::log("surreal", "INFO", "Connected to SurrealDB server");
    *SURREAL_CONNECTION_STATE.write().unwrap() = SurrealConnectionState::Connected;
}

fn set_failure_reason(reason: String) {
    *SURREAL_FAILURE_REASON.write().unwrap() = Some(reason);
}

fn is_current_generation(generation: u64) -> bool {
    SURREAL_INIT_GENERATION.load(Ordering::SeqCst) == generation
}

fn failure_reason() -> String {
    SURREAL_FAILURE_REASON
        .read()
        .unwrap()
        .clone()
        .unwrap_or_else(|| "unknown failure".to_string())
}

async fn connect(config: SurrealConfig) -> Result<SurrealDb, String> {
    let db = Surreal::new::<Http>(config.endpoint.as_str())
        .await
        .map_err(|error| error.to_string())?;

    if let (Some(username), Some(password)) = (&config.username, &config.password) {
        db.signin(Root {
            username: username.clone(),
            password: password.clone(),
        })
        .await
        .map_err(|error| error.to_string())?;
    }

    db.use_ns(config.namespace.as_str())
        .use_db(config.database.as_str())
        .await
        .map_err(|error| error.to_string())?;

    Ok(db)
}

pub async fn client() -> Result<Arc<SurrealDb>, String> {
    if let Some(db) = SURREAL_DB.read().unwrap().clone() {
        return Ok(db);
    }

    timeout(CLIENT_READY_TIMEOUT, wait_for_client())
        .await
        .unwrap_or_else(|_| {
            Err("SurrealDB connection did not become ready before timeout".to_string())
        })
}

async fn wait_for_client() -> Result<Arc<SurrealDb>, String> {
    loop {
        if let Some(db) = SURREAL_DB.read().unwrap().clone() {
            return Ok(db);
        }

        let state = *SURREAL_CONNECTION_STATE.read().unwrap();
        match state {
            SurrealConnectionState::Disabled => {
                return Err("SurrealDB connection is disabled".to_string());
            }
            SurrealConnectionState::Failed => {
                return Err(format!("SurrealDB connection failed: {}", failure_reason()));
            }
            SurrealConnectionState::Initializing | SurrealConnectionState::Connected => {
                sleep(CLIENT_READY_POLL_INTERVAL).await;
            }
        }
    }
}

pub fn status() -> String {
    let state = *SURREAL_CONNECTION_STATE.read().unwrap();
    match state {
        SurrealConnectionState::Disabled => "disabled".to_string(),
        SurrealConnectionState::Initializing => "initializing".to_string(),
        SurrealConnectionState::Connected => "connected".to_string(),
        SurrealConnectionState::Failed => "failed".to_string(),
    }
}

pub fn reconnect() -> String {
    let surreal_config = config::load().surreal.clone();
    prepare();
    RUNTIME.spawn(async move {
        initialize(surreal_config).await;
    });
    "reconnect initiated".to_string()
}

pub fn group() -> Group {
    Group::new()
        .command("status", status)
        .command("reconnect", reconnect)
}
