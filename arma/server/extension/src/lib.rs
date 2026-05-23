//! Entry point and runtime bootstrap for the Forge Arma server extension.
//!
//! Initializes a global async runtime, SurrealDB persistence, and registers
//! all command groups. Provides status/version commands and maintains a shared
//! Arma `Context` for engine interop.
//!
#![allow(future_incompatible)] // Future-incompatible lint is triggered by arma_rs

use arma_rs::{Context, Extension, Group, arma};
use std::sync::LazyLock;
use tokio::runtime::{Builder, Runtime};
use tokio::sync::RwLock as TokioRwLock;

pub mod actor;
pub mod bank;
pub mod cad;
pub mod config;
pub mod garage;
pub mod helpers;
pub mod icom;
pub mod locker;
mod log;
pub mod org;
pub mod phone;
pub mod schema;
pub mod storage;
pub mod store;
pub mod surreal;
pub mod task;
pub mod terrain;
pub mod transport;
pub mod v_garage;
pub mod v_locker;

/// Global Arma `Context` captured at initialization and made available to
/// commands that need engine interop. Stored inside an async `RwLock` to
/// allow mutation by the startup task and later reads.
static CONTEXT: LazyLock<TokioRwLock<Option<Context>>> = LazyLock::new(|| TokioRwLock::new(None));
/// Global multi-threaded Tokio runtime used to execute async operations from
/// command handlers and startup tasks.
pub(crate) static RUNTIME: LazyLock<Runtime> = LazyLock::new(|| {
    Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("Failed to create tokio runtime")
});

pub(crate) fn enqueue_persistence_task<F>(module: &'static str, job: F)
where
    F: FnOnce() -> Result<(), String> + Send + 'static,
{
    RUNTIME.spawn_blocking(move || {
        if let Err(error) = job() {
            crate::log::log(
                module,
                "ERROR",
                &format!("Async persistence failed: {}", error),
            );
        }
    });
}

#[arma]
/// Initializes the extension, registers commands/groups, and asynchronously
/// connects SurrealDB on the global runtime.
fn init() -> Extension {
    let config = config::load();
    let ext = Extension::build()
        .command("version", get_version)
        .command("status", get_status)
        .group("surreal", surreal::group())
        .group("actor", actor::group())
        .group("bank", bank::group())
        .group("cad", cad::group())
        .group("garage", garage::group())
        .group("icom", icom::group())
        .group("locker", locker::group())
        .group("org", org::group())
        .group("phone", phone::group())
        .group("store", store::group())
        .group("task", task::group())
        .group("terrain", terrain::group())
        .group("transport", transport::group())
        .group(
            "owned",
            Group::new()
                .group("garage", v_garage::group())
                .group("locker", v_locker::group()),
        )
        .finish();

    let surreal_config = config.surreal.clone();
    surreal::prepare();
    RUNTIME.spawn(async move {
        surreal::initialize(surreal_config).await;
    });

    ext
}

/// Returns current persistence connection state as a string: `initializing`,
/// `connected`, or `failed`. Intended for SQF polling before issuing
/// operations that require persistence.
fn get_status() -> String {
    surreal::status()
}

/// Returns the extension version string for diagnostics and tooling.
pub fn get_version() -> String {
    format!("forge-server v{}", env!("CARGO_PKG_VERSION"))
}
