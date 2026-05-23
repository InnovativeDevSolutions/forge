use arma_rs::CallContext;

use super::expect_arg_count;
use crate::phone;

pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "phone:init" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(phone::init_phone(arguments[0].clone()))
        }
        "phone:contacts:list" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(phone::list_contacts(arguments[0].clone()))
        }
        "phone:contacts:add" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(phone::add_contact(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "phone:contacts:remove" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(phone::remove_contact(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "phone:messages:list" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(phone::list_messages(arguments[0].clone()))
        }
        "phone:messages:thread" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(phone::message_thread(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "phone:messages:send" => {
            expect_arg_count(function_name, &arguments, 4)?;
            Ok(phone::send_message(
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
                arguments[3].clone(),
            ))
        }
        "phone:messages:mark_read" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(phone::mark_message_read(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "phone:messages:delete" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(phone::delete_message(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "phone:emails:list" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(phone::list_emails(arguments[0].clone()))
        }
        "phone:emails:send" => {
            expect_arg_count(function_name, &arguments, 5)?;
            Ok(phone::send_email(
                arguments[0].clone(),
                arguments[1].clone(),
                arguments[2].clone(),
                arguments[3].clone(),
                arguments[4].clone(),
            ))
        }
        "phone:emails:mark_read" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(phone::mark_email_read(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "phone:emails:delete" => {
            expect_arg_count(function_name, &arguments, 2)?;
            Ok(phone::delete_email(
                arguments[0].clone(),
                arguments[1].clone(),
            ))
        }
        "phone:remove" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(phone::remove_phone(arguments[0].clone()))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
