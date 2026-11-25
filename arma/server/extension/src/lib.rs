//! Entry point and runtime bootstrap for the Forge Arma server extension.
//!
//! Initializes a global async runtime, registers all command groups,
//! and asynchronously connects SurrealDB for the one-time migration
//! of legacy data (see `surreal`). All persistence goes through the
//! forge-webapi (`api`); there is no SurrealDB fallback.
//!
#![allow(future_incompatible)] // Future-incompatible lint is triggered by arma_rs

use arma_rs::{Context, Extension, Group, arma};
use std::sync::LazyLock;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::{Duration, Instant};
use tokio::runtime::{Builder, Runtime};
use tokio::sync::RwLock as TokioRwLock;

pub mod actor;
pub mod api;
pub mod bank;
pub mod config;
pub mod dispatch;
pub mod garage;
pub mod helpers;
pub mod icom;
pub mod locker;
mod log;
pub mod org;
pub mod phone;
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

/// Number of queued or running persistence tasks, so a shutdown can wait for
/// them (see `persistence:flush`).
static PENDING_PERSISTENCE: AtomicUsize = AtomicUsize::new(0);

/// Upper bound for `persistence:flush` so a stuck database never hangs the server.
const MAX_FLUSH_TIMEOUT_MS: u64 = 30_000;
const DEFAULT_FLUSH_TIMEOUT_MS: u64 = 10_000;

/// Decrements the pending counter when a persistence task ends, even if it panics.
struct PendingGuard;

impl Drop for PendingGuard {
    fn drop(&mut self) {
        PENDING_PERSISTENCE.fetch_sub(1, Ordering::SeqCst);
    }
}

pub(crate) fn enqueue_persistence_task<F>(module: &'static str, job: F)
where
    F: FnOnce() -> Result<(), String> + Send + 'static,
{
    PENDING_PERSISTENCE.fetch_add(1, Ordering::SeqCst);
    RUNTIME.spawn_blocking(move || {
        let _guard = PendingGuard;
        if let Err(error) = job() {
            crate::log::log(
                module,
                "ERROR",
                &format!("Async persistence failed: {}", error),
            );
        }
    });
}

/// Number of persistence tasks that have not finished yet.
fn pending_persistence() -> String {
    PENDING_PERSISTENCE.load(Ordering::SeqCst).to_string()
}

/// Blocks until every queued persistence task has finished or the timeout
/// (milliseconds, default 10 s, max 30 s) runs out. Returns `OK`, or
/// `Error: ...` with the number of writes still pending.
fn flush_persistence(timeout_ms: String) -> String {
    let timeout_ms = timeout_ms
        .trim()
        .parse::<u64>()
        .unwrap_or(DEFAULT_FLUSH_TIMEOUT_MS)
        .min(MAX_FLUSH_TIMEOUT_MS);
    wait_for_pending(Duration::from_millis(timeout_ms))
}

fn wait_for_pending(timeout: Duration) -> String {
    let deadline = Instant::now() + timeout;
    loop {
        let pending = PENDING_PERSISTENCE.load(Ordering::SeqCst);
        if pending == 0 {
            return "OK".to_string();
        }
        if Instant::now() >= deadline {
            crate::log::log(
                "persistence",
                "WARNING",
                &format!("Flush timed out with {pending} write(s) still pending."),
            );
            return format!("Error: flush timed out with {pending} write(s) still pending");
        }
        std::thread::sleep(Duration::from_millis(25));
    }
}

#[arma]
/// Initializes the extension, registers commands/groups, and
/// asynchronously connects SurrealDB for the one-time legacy-data
/// migration on the global runtime.
fn init() -> Extension {
    let config = config::load();
    let ext = Extension::build()
        .command("version", get_version)
        .command("status", get_status)
        .group(
            "persistence",
            Group::new()
                .command("pending", pending_persistence)
                .command("flush", flush_persistence),
        )
        .group("surreal", surreal::group())
        .group("api", api::group())
        .group("actor", actor::group())
        .group("bank", bank::group())
        .group("dispatch", dispatch::group())
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

/// Returns the forge-webapi status: `connected (database: …)` or
/// `unavailable: <reason>`. The API is the only persistence backend,
/// so this is the persistence status. Intended for SQF polling before
/// issuing operations that require persistence.
fn get_status() -> String {
    crate::api::status()
}

/// Returns the extension version string for diagnostics and tooling.
pub fn get_version() -> String {
    format!("forge-server v{}", env!("CARGO_PKG_VERSION"))
}

#[cfg(test)]
mod tests {
    use super::{enqueue_persistence_task, pending_persistence, wait_for_pending};
    use std::time::Duration;

    // One test so the shared pending counter is not touched by others in parallel.
    #[test]
    fn flush_waits_for_pending_writes_and_times_out() {
        enqueue_persistence_task("test", || {
            std::thread::sleep(Duration::from_millis(100));
            Ok(())
        });
        assert_eq!(pending_persistence(), "1");
        assert_eq!(wait_for_pending(Duration::from_secs(5)), "OK");
        assert_eq!(pending_persistence(), "0");

        enqueue_persistence_task("test", || {
            std::thread::sleep(Duration::from_millis(400));
            Ok(())
        });
        assert!(wait_for_pending(Duration::from_millis(20)).starts_with("Error:"));
        assert_eq!(wait_for_pending(Duration::from_secs(5)), "OK");
    }
}
