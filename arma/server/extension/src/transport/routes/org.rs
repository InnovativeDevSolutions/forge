use arma_rs::CallContext;

use super::expect_arg_count;
use crate::org;

pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "org:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::get_org(arguments[0].clone()))
        }
        "org:create" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(org::create_org(arguments[0].clone(), arguments[1].clone()))
        }
        "org:update" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(org::update_org(arguments[0].clone(), arguments[1].clone()))
        }
        "org:exists" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::org_exists(arguments[0].clone()))
        }
        "org:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::delete_org(arguments[0].clone()))
        }
        "org:hot:init" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::init_hot_org(arguments[0].clone()))
        }
        "org:hot:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::get_hot_org(arguments[0].clone()))
        }
        "org:hot:override" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(org::override_hot_org(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "org:hot:ensure_member" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::ensure_hot_org_member(arguments[0].clone()))
        }
        "org:hot:member_invites" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::get_hot_org_member_invites(arguments[0].clone()))
        }
        "org:hot:register" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::register_hot_org(arguments[0].clone()))
        }
        "org:hot:invite_member" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::invite_hot_org_member(arguments[0].clone()))
        }
        "org:hot:accept_invite" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::accept_hot_org_invite(arguments[0].clone()))
        }
        "org:hot:decline_invite" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::decline_hot_org_invite(arguments[0].clone()))
        }
        "org:hot:assign_credit_line" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::assign_credit_line_hot_org(arguments[0].clone()))
        }
        "org:hot:repay_credit_line" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::repay_credit_line_hot_org(arguments[0].clone()))
        }
        "org:hot:charge_checkout" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::charge_checkout_hot_org(arguments[0].clone()))
        }
        "org:hot:add_assets" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(org::add_assets_hot_org(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "org:hot:add_fleet" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(org::add_fleet_hot_org(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "org:hot:leave" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::leave_hot_org(arguments[0].clone()))
        }
        "org:hot:disband" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::disband_hot_org(arguments[0].clone()))
        }
        "org:hot:save" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::save_hot_org(arguments[0].clone()))
        }
        "org:hot:remove" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::remove_hot_org(arguments[0].clone()))
        }
        "org:assets:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::get_assets(arguments[0].clone()))
        }
        "org:assets:update" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(org::update_assets(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "org:fleet:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::get_fleet(arguments[0].clone()))
        }
        "org:fleet:update" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(org::update_fleet(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "org:members:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(org::get_members(arguments[0].clone()))
        }
        "org:members:add" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(org::add_member(arguments[0].clone(), arguments[1].clone()))
        }
        "org:members:remove" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(org::remove_member(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
