use arma_rs::CallContext;

use super::expect_arg_count;
use crate::locker;

pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "locker:create" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(locker::create_locker(call_context, arguments[0].clone()))
        }
        "locker:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(locker::get_locker(call_context, arguments[0].clone()))
        }
        "locker:add" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(locker::add_item(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "locker:update" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(locker::update_locker(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "locker:patch" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(locker::patch_item(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "locker:remove" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(locker::remove_item(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "locker:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(locker::delete_locker(call_context, arguments[0].clone()))
        }
        "locker:exists" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(locker::locker_exists(call_context, arguments[0].clone()))
        }
        "locker:hot:init" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(locker::init_hot_locker(call_context, arguments[0].clone()))
        }
        "locker:hot:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(locker::get_hot_locker(call_context, arguments[0].clone()))
        }
        "locker:hot:override" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(locker::override_hot_locker(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "locker:hot:save" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(locker::save_hot_locker(call_context, arguments[0].clone()))
        }
        "locker:hot:remove" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(locker::remove_hot_locker(
                call_context,
                arguments[0].clone(),
            ))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
