use arma_rs::CallContext;

pub fn resolve_uid(uid: &str, call_context: &CallContext) -> Option<String> {
    if !uid.is_empty() && uid != "_SP_PLAYER_" {
        return Some(uid.to_string());
    }

    match call_context.caller() {
        arma_rs::Caller::Steam(steam_id) => Some(steam_id.to_string()),
        arma_rs::Caller::Unknown => None,
    }
}
