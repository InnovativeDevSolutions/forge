//! SurrealDB connection bootstrap for persistent storage.

use arma_rs::Group;
use std::sync::{LazyLock, OnceLock, RwLock as StdRwLock};
use surrealdb::Surreal;
use surrealdb::engine::remote::http::{Client, Http};
use surrealdb::opt::auth::Root;
use tokio::time::{Duration, sleep, timeout};

use crate::config::SurrealConfig;
use crate::log;
use crate::schema;

pub type SurrealDb = Surreal<Client>;

const CLIENT_READY_TIMEOUT: Duration = Duration::from_secs(30);
const CLIENT_READY_POLL_INTERVAL: Duration = Duration::from_millis(25);

static SURREAL_DB: OnceLock<SurrealDb> = OnceLock::new();
static SURREAL_CONNECTION_STATE: LazyLock<StdRwLock<SurrealConnectionState>> =
    LazyLock::new(|| StdRwLock::new(SurrealConnectionState::Disabled));
static SURREAL_FAILURE_REASON: LazyLock<StdRwLock<Option<String>>> =
    LazyLock::new(|| StdRwLock::new(None));

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

    log::log("surreal", "DEBUG", "Applying SurrealDB schemas");
    if let Err(error) = schema::apply_all(&db).await {
        log::log(
            "surreal",
            "ERROR",
            &format!("Failed to apply SurrealDB schemas: {}", error),
        );
        set_failure_reason(error);
        *SURREAL_CONNECTION_STATE.write().unwrap() = SurrealConnectionState::Failed;
        return;
    }

    if SURREAL_DB.set(db).is_ok() {
        log::log("surreal", "INFO", "Connected to SurrealDB server");
        *SURREAL_CONNECTION_STATE.write().unwrap() = SurrealConnectionState::Connected;
    } else {
        log::log("surreal", "ERROR", "Failed to set SurrealDB client");
        set_failure_reason("Failed to set SurrealDB client".to_string());
        *SURREAL_CONNECTION_STATE.write().unwrap() = SurrealConnectionState::Failed;
    }
}

fn set_failure_reason(reason: String) {
    *SURREAL_FAILURE_REASON.write().unwrap() = Some(reason);
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

pub async fn client() -> Result<&'static SurrealDb, String> {
    if let Some(db) = SURREAL_DB.get() {
        return Ok(db);
    }

    timeout(CLIENT_READY_TIMEOUT, wait_for_client())
        .await
        .unwrap_or_else(|_| {
            Err("SurrealDB connection did not become ready before timeout".to_string())
        })
}

async fn wait_for_client() -> Result<&'static SurrealDb, String> {
    loop {
        if let Some(db) = SURREAL_DB.get() {
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

pub fn group() -> Group {
    Group::new().command("status", status)
}
