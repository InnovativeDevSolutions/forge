use arma_rs::CallContext;

use super::expect_arg_count;
use crate::v_garage;

pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "owned:garage:create" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_garage::create_vgarage(call_context, arguments[0].clone()))
        }
        "owned:garage:fetch" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_garage::fetch_vgarage(call_context, arguments[0].clone()))
        }
        "owned:garage:get" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(v_garage::get_vgarage(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "owned:garage:add" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(v_garage::add_vgarage(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        "owned:garage:remove" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(v_garage::remove_vgarage(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        "owned:garage:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_garage::delete_vgarage(call_context, arguments[0].clone()))
        }
        "owned:garage:exists" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_garage::vgarage_exists(call_context, arguments[0].clone()))
        }
        "owned:garage:hot:init" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_garage::init_hot_vgarage(
                call_context,
                arguments[0].clone(),
            ))
        }
        "owned:garage:hot:fetch" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_garage::fetch_hot_vgarage(
                call_context,
                arguments[0].clone(),
            ))
        }
        "owned:garage:hot:get" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(v_garage::get_hot_vgarage(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "owned:garage:hot:override" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(v_garage::override_hot_vgarage(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "owned:garage:hot:save" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_garage::save_hot_vgarage(
                call_context,
                arguments[0].clone(),
            ))
        }
        "owned:garage:hot:remove" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(v_garage::remove_hot_vgarage(
                call_context,
                arguments[0].clone(),
            ))
        }
        "owned:garage:hot:add" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(v_garage::add_hot_vgarage(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        "owned:garage:hot:remove_item" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(v_garage::remove_hot_vgarage_item(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
