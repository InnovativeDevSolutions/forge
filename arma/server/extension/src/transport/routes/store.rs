use arma_rs::CallContext;

use super::expect_arg_count;
pub(super) fn route(
    call_context: CallContext,
    function_name: &str,
    arguments: Vec<String>,
) -> Result<String, String> {
    let _ = &call_context;

    match function_name {
        "store:checkout" => {
            expect_arg_count(function_name, &arguments, 1)?;
            Ok(crate::store::checkout(arguments[0].clone()))
        }
        _ => Err(super::unsupported_route(function_name)),
    }
}
