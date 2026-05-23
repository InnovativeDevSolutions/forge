use arma_rs::CallContext;

use super::expect_arg_count;
use crate::v_locker;

pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "owned:locker:create" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_locker::create_vlocker(call_context, arguments[0].clone()))
        }
        "owned:locker:fetch" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_locker::fetch_vlocker(call_context, arguments[0].clone()))
        }
        "owned:locker:get" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(v_locker::get_vlocker(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "owned:locker:add" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(v_locker::add_vlocker(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        "owned:locker:remove" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(v_locker::remove_vlocker(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        "owned:locker:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_locker::delete_vlocker(call_context, arguments[0].clone()))
        }
        "owned:locker:exists" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_locker::vlocker_exists(call_context, arguments[0].clone()))
        }
        "owned:locker:hot:init" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_locker::init_hot_vlocker(
                call_context,
                arguments[0].clone(),
            ))
        }
        "owned:locker:hot:fetch" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_locker::fetch_hot_vlocker(
                call_context,
                arguments[0].clone(),
            ))
        }
        "owned:locker:hot:get" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(v_locker::get_hot_vlocker(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "owned:locker:hot:override" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(v_locker::override_hot_vlocker(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "owned:locker:hot:save" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_locker::save_hot_vlocker(
                call_context,
                arguments[0].clone(),
            ))
        }
        "owned:locker:hot:remove" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_locker::remove_hot_vlocker(
                call_context,
                arguments[0].clone(),
            ))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
