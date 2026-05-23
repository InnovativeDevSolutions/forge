use arma_rs::CallContext;

mod actor;
mod bank;
mod cad;
mod garage;
mod locker;
mod org;
mod phone;
mod store;
mod v_garage;
mod v_locker;

const UNSUPPORTED_ROUTE_PREFIX: &str = "Unsupported transport route";

pub(super) fn route_command(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    if function_name.starts_with("actor:") {
        return actor::route(call_context, function_name, arguments);
    }
    if function_name.starts_with("bank:") {
        return bank::route(call_context, function_name, arguments);
    }
    if function_name.starts_with("org:") {
        return org::route(call_context, function_name, arguments);
    }
    if function_name == "store:checkout" {
        return store::route(call_context, function_name, arguments);
    }
    if function_name.starts_with("garage:") {
        return garage::route(call_context, function_name, arguments);
    }
    if function_name.starts_with("locker:") {
        return locker::route(call_context, function_name, arguments);
    }
    if function_name.starts_with("owned:garage:") {
        return v_garage::route(call_context, function_name, arguments);
    }
    if function_name.starts_with("owned:locker:") {
        return v_locker::route(call_context, function_name, arguments);
    }
    if function_name.starts_with("cad:") {
        return cad::route(call_context, function_name, arguments);
    }
    if function_name.starts_with("phone:") {
        return phone::route(call_context, function_name, arguments);
    }

    Err(unsupported_route(function_name))
}

pub(super) fn expect_arg_count(
    function_name: &str,
    arguments: &[String],
    expected_count: usize,
) -> Result<(), String> {
    if arguments.len() == expected_count {
        return Ok(());
    }

    Err(format!(
        "Transport route '{}' expected {} arguments but received {}",
        function_name,
        expected_count,
        arguments.len()
    ))
}

pub(super) fn unsupported_route(function_name: &str) -> String {
    format!("{UNSUPPORTED_ROUTE_PREFIX} for function '{function_name}'")
}
