use arma_rs::CallContext;

use super::expect_arg_count;
use crate::dispatch;

pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "dispatch:activity:append" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(dispatch::append_activity(arguments[0].clone()))
        }
        "dispatch:activity:recent" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(dispatch::recent_activity(arguments[0].clone()))
        }
        "dispatch:requests:list" => {
            expect_arg_count(function_name, &arguments, 0)?;
            Ok(dispatch::list_requests())
        }
        "dispatch:requests:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(dispatch::get_request(arguments[0].clone()))
        }
        "dispatch:requests:submit" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(dispatch::submit_request(arguments[0].clone()))
        }
        "dispatch:requests:close" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(dispatch::close_request(arguments[0].clone()))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
