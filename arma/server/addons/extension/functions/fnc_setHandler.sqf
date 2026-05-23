#include "..\script_component.hpp"

/*
 * File: fnc_setHandler.sqf
 * Author: IDSolutions
 * Date: 2026-01-03
 * Last Update: 2026-01-03
 * Public: No
 *
 * Description:
 *     Set handler for extension function callbacks.
 *
 * Parameter(s):
 *     0: Function name to handle callbacks <STRING>
 *     1: Callback function to use as handler <CODE>
 *     2: Arguments to pass to callback function <ARRAY>
 *
 * Returns:
 *     Handler was set <BOOL>
 *
 * Example(s):
 *     ["actor:greet", {
 *          params ["_message"];
 *          private _player = _arguments select 0;
 *          systemChat format ["Hello, %1! %2", name _player, _message];
 *      }, [player]] call forge_x_component_fnc_setHandler;
 */

params [["_function", "", [""]], ["_callback", {}, [{}]], ["_arguments", [], [[]]]];

if (_function isEqualTo "") exitWith {
    ["WARNING", "Function not specified, handler not set!", nil, nil] call EFUNC(common,log);
    false
};
if (_callback isEqualTo {}) exitWith {
    ["WARNING", "Callback not specified, handler not set!", nil, nil] call EFUNC(common,log);
    false
};
if (isNil QGVAR(handlers)) then { GVAR(handlers) = createHashMap; };

private _entry = format ["forge_server:%1", _function];
GVAR(handlers) set [_entry, [_callback, _arguments]];
["INFO", format ["Handler set: %1", _entry], nil, nil] call EFUNC(common,log);

true
