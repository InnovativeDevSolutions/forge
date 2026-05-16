use arma_rs::CallContext;

use super::expect_arg_count;
use crate::bank;

pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "bank:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(bank::get_bank(call_context, arguments[0].clone()))
        }
        "bank:create" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(bank::create_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "bank:update" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(bank::update_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "bank:exists" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(bank::bank_exists(call_context, arguments[0].clone()))
        }
        "bank:delete" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(bank::delete_bank(call_context, arguments[0].clone()))
        }
        "bank:hot:init" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(bank::init_hot_bank(call_context, arguments[0].clone()))
        }
        "bank:hot:get" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(bank::get_hot_bank(call_context, arguments[0].clone()))
        }
        "bank:hot:override" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(bank::override_hot_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "bank:hot:patch" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(bank::patch_hot_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "bank:hot:charge_checkout" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(bank::charge_checkout_hot_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        "bank:hot:deposit" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(bank::deposit_hot_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        "bank:hot:withdraw" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(bank::withdraw_hot_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        "bank:hot:deposit_earnings" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(bank::deposit_earnings_hot_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        "bank:hot:transfer" => {
            expect_arg_count(function_name, &arguments, 4)?;
            Ok(bank::transfer_hot_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
                arguments[3].clone(),
            ))
        }
        "bank:hot:validate_pin" => {
            expect_arg_count(function_name, &arguments, 3)?;
            Ok(bank::validate_pin_hot_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
            ))
        }
        "bank:hot:change_pin" => {
            expect_arg_count(function_name, &arguments, 4)?;
            Ok(bank::change_pin_hot_bank(
                call_context,
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
                arguments[3].clone(),
            ))
        }
        "bank:hot:save" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(bank::save_hot_bank(call_context, arguments[0].clone()))
        }
        "bank:hot:remove" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(bank::remove_hot_bank(call_context, arguments[0].clone()))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
