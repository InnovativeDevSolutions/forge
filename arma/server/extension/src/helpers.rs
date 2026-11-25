use arma_rs::CallContext;
use std::sync::Mutex;

/// Cache for the single-player UID resolution.
///
/// In single-player the client sends the placeholder UID `"_SP_PLAYER_"` and
/// `resolve_uid` falls back to the engine-supplied caller ID. On a local
/// hosted (non-dedicated) server that caller ID is NOT stable across
/// extension calls: the same player is reported under two different
/// session-generated IDs (observed differing by exactly 512 in every
/// single-player session), so a store created under one ID could not be
/// found or saved under the other -- bank balances never persisted
/// (`"Bank with UID ... not found"` on save) and `actor:hot:get` reported
/// `"was not found"`. There is exactly one local player in single-player,
/// so the first successful resolution is cached for the lifetime of the
/// process and reused for every later placeholder resolution. Real UIDs
/// (multiplayer Steam IDs) never touch the cache, and a failed resolution
/// (`Caller::Unknown`) is not cached, so a later call can still succeed
/// once the engine reports a caller.
static RESOLVED_SP_UID: Mutex<Option<String>> = Mutex::new(None);

pub fn resolve_uid(uid: &str, call_context: &CallContext) -> Option<String> {
    if !uid.is_empty() && uid != "_SP_PLAYER_" {
        return Some(uid.to_string());
    }

    resolve_sp_uid(call_context.caller())
}

/// Resolves the `"_SP_PLAYER_"` placeholder via the engine caller ID,
/// caching the first successful resolution for the process lifetime.
/// Split out from `resolve_uid` so the caching behaviour is unit-testable
/// without an Arma call context.
fn resolve_sp_uid(caller: &arma_rs::Caller) -> Option<String> {
    // A poisoned lock (only possible if a thread panicked while holding it)
    // degrades to uncached resolution instead of failing the call.
    let mut cached = RESOLVED_SP_UID.lock().unwrap_or_else(|e| e.into_inner());
    if let Some(uid) = cached.as_ref() {
        return Some(uid.clone());
    }

    match caller {
        arma_rs::Caller::Steam(steam_id) => {
            let uid = steam_id.to_string();
            *cached = Some(uid.clone());
            Some(uid)
        }
        // Do not cache the failure: the engine may report a caller later.
        arma_rs::Caller::Unknown => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Mutex as StdMutex;

    // Serializes the tests that touch the process-wide cache.
    static TEST_CACHE_LOCK: StdMutex<()> = StdMutex::new(());

    fn clear_cache() {
        *RESOLVED_SP_UID.lock().unwrap() = None;
    }

    #[test]
    fn sp_uid_resolution_is_cached_across_calls() {
        let _guard = TEST_CACHE_LOCK.lock().unwrap();
        clear_cache();

        // First call resolves and caches the base UID.
        assert_eq!(
            resolve_sp_uid(&arma_rs::Caller::Steam(271851681144)),
            Some("271851681144".to_string())
        );
        // The engine later reports the +512 sibling ID for the same player;
        // every store must still agree on the first UID.
        assert_eq!(
            resolve_sp_uid(&arma_rs::Caller::Steam(271851681656)),
            Some("271851681144".to_string())
        );

        clear_cache();
    }

    #[test]
    fn unknown_caller_is_not_cached() {
        let _guard = TEST_CACHE_LOCK.lock().unwrap();
        clear_cache();

        assert_eq!(resolve_sp_uid(&arma_rs::Caller::Unknown), None);
        // A later successful resolution still works.
        assert_eq!(
            resolve_sp_uid(&arma_rs::Caller::Steam(271851681144)),
            Some("271851681144".to_string())
        );

        clear_cache();
    }
}
