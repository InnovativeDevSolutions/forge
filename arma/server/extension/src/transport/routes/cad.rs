use arma_rs::CallContext;

use super::expect_arg_count;
use crate::cad;

pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "cad:activity:append" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::append_activity(arguments[0].clone()))
        }
        "cad:activity:recent" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::recent_activity(arguments[0].clone()))
        }
        "cad:assignments:list" => {
            expect_arg_count(function_name, &arguments, 0)?;
            Ok(cad::list_assignments())
        }
        "cad:assignments:assign" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(cad::assign_assignment(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "cad:assignments:acknowledge" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(cad::acknowledge_assignment(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "cad:assignments:decline" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(cad::decline_assignment(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "cad:assignments:upsert" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(cad::upsert_assignment(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "cad:assignments:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::delete_assignment(arguments[0].clone()))
        }
        "cad:orders:list" => {
            expect_arg_count(function_name, &arguments, 0)?;
            Ok(cad::list_orders())
        }
        "cad:orders:create" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::create_order(arguments[0].clone()))
        }
        "cad:orders:create_from_context" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::create_order_from_context(arguments[0].clone()))
        }
        "cad:orders:close" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::close_order(arguments[0].clone()))
        }
        "cad:orders:upsert" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(cad::upsert_order(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "cad:orders:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::delete_order(arguments[0].clone()))
        }
        "cad:requests:list" => {
            expect_arg_count(function_name, &arguments, 0)?;
            Ok(cad::list_requests())
        }
        "cad:requests:submit" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::submit_request(arguments[0].clone()))
        }
        "cad:requests:submit_from_context" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::submit_request_from_context(arguments[0].clone()))
        }
        "cad:requests:close" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::close_request(arguments[0].clone()))
        }
        "cad:requests:upsert" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(cad::upsert_request(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "cad:requests:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::delete_request(arguments[0].clone()))
        }
        "cad:profiles:list" => {
            expect_arg_count(function_name, &arguments, 0)?;
            Ok(cad::list_profiles())
        }
        "cad:profiles:update_from_context" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::update_profile_from_context(arguments[0].clone()))
        }
        "cad:profiles:upsert" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(cad::upsert_profile(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "cad:profiles:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::delete_profile(arguments[0].clone()))
        }
        "cad:groups:build" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::build_groups(arguments[0].clone()))
        }
        "cad:view:hydrate" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(cad::hydrate_view(arguments[0].clone()))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
