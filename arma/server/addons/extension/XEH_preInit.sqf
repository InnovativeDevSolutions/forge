#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];

addMissionEventHandler ["ExtensionCallback", {
    params ["_function", "_result", "_data"];
    (GVAR(handlers) get _function) params ["_handler", "_arguments"];
    [_result, (fromJSON _data), _arguments] call _handler;
}];
