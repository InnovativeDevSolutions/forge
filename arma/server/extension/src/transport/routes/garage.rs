use arma_rs::CallContext;

use super::expect_arg_count;
use crate::garage;

pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "garage:create" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(garage::create_garage(call_context, arguments[0].clone()))
        }
        "garage:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(garage::get_garage(call_context, arguments[0].clone()))
        }
        "garage:add" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(garage::add_vehicle(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "garage:update" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(garage::update_garage(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "garage:patch" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(garage::patch_vehicle(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "garage:remove" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(garage::remove_vehicle(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "garage:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(garage::delete_garage(call_context, arguments[0].clone()))
        }
        "garage:exists" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(garage::garage_exists(call_context, arguments[0].clone()))
        }
        "garage:hot:init" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(garage::init_hot_garage(call_context, arguments[0].clone()))
        }
        "garage:hot:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(garage::get_hot_garage(call_context, arguments[0].clone()))
        }
        "garage:hot:override" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(garage::override_hot_garage(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "garage:hot:save" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(garage::save_hot_garage(call_context, arguments[0].clone()))
        }
        "garage:hot:remove" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(garage::remove_hot_garage(
                call_context,
                arguments[0].clone(),
            ))
        }
        "garage:hot:add" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(garage::add_hot_vehicle(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "garage:hot:remove_vehicle" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(garage::remove_hot_vehicle(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
