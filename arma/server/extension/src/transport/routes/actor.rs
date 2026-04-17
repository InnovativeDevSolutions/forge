use arma_rs::CallContext;

use super::expect_arg_count;
use crate::actor;

pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "actor:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(actor::get_actor(call_context, arguments[0].clone()))
        }
        "actor:create" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(actor::create_actor(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "actor:update" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(actor::update_actor(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "actor:exists" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(actor::actor_exists(call_context, arguments[0].clone()))
        }
        "actor:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(actor::delete_actor(call_context, arguments[0].clone()))
        }
        "actor:hot:init" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(actor::init_hot_actor(call_context, arguments[0].clone()))
        }
        "actor:hot:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(actor::get_hot_actor(call_context, arguments[0].clone()))
        }
        "actor:hot:keys" => {
            expect_arg_count(function_name, &arguments, 0)?;
            Ok(actor::list_hot_actor_keys())
        }
        "actor:hot:override" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(actor::override_hot_actor(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "actor:hot:save" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(actor::save_hot_actor(call_context, arguments[0].clone()))
        }
        "actor:hot:remove" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(actor::remove_hot_actor(call_context, arguments[0].clone()))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
