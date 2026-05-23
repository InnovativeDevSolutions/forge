#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Gateway for task hot-state extension calls.
 *
 * TaskStore owns gameplay/runtime behavior. This gateway owns the transport
 * boundary to the extension-backed task state service.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Task state gateway object <HASHMAP OBJECT>
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TaskStateGateway) = createHashMapObject [[
    ["#type", "TaskStateGateway"],
    ["reset", compileFinal {
        ["task:reset", []] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if (
            !_isSuccess
            || { !(_result isEqualType "") }
            || { (_result find "Error:") == 0 }
        ) exitWith {
            ["WARNING", "Failed to reset task backend state during task store initialization."] call EFUNC(common,log);
            false
        };

        ["INFO", "Task backend state reset for mission lifecycle."] call EFUNC(common,log);
        true
    }],
    ["callTaskStateEnvelope", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        private _envelope = createHashMapFromArray [
            ["success", false],
            ["error", ""]
        ];

        if (_function isEqualTo "") exitWith { _envelope };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !_isSuccess exitWith {
            _envelope set ["error", format ["Task backend call '%1' failed.", _function]];
            _envelope
        };
        if !(_result isEqualType "") exitWith {
            _envelope set ["error", format ["Task backend call '%1' returned an invalid response.", _function]];
            _envelope
        };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Task extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            _envelope set ["error", _result select [7]];
            _envelope
        };

        _envelope set ["success", true];
        if (_result isNotEqualTo "") then { _envelope set ["data", fromJSON _result]; };

        _envelope
    }],
    ["callTaskState", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]], ["_fallback", nil]];

        private _envelope = _self call ["callTaskStateEnvelope", [_function, _arguments]];
        if !(_envelope getOrDefault ["success", false]) exitWith { _fallback };
        if (isNil { _envelope get "data" }) exitWith { _fallback };

        _envelope get "data"
    }]
]];

GVAR(TaskStateGateway)
