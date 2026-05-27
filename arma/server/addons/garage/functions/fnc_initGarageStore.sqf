#include "..\script_component.hpp"

/*
 * File: fnc_initGarageStore.sqf
 * Author: IDSolutions
 * Date: 2025-12-17
 * Last Update: 2026-04-01
 * Public: No
 *
 * Description:
 * Initializes the Garage store for managing player vehicles.
 * Garage hot state is owned by the extension; SQF acts as a thin bridge.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Garage store object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_garage_fnc_initGarageStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(GarageBaseStore) = compileFinal ([
    EGVAR(common,BaseStore),
    createHashMapFromArray [
    ["#type", "GarageBaseStore"],
    ["#create", compileFinal {
        ["INFO", "Garage Store Initialized!"] call EFUNC(common,log);
        _self set ["lastCallSucceeded", false];
        _self set ["lastError", ""];
        true
    }],
    ["callHotGarage", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        _self set ["lastCallSucceeded", false];
        _self set ["lastError", ""];

        if (_function isEqualTo "") exitWith {
            _self set ["lastError", "Garage extension function was empty."];
            createHashMap
        };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith {
            _self set ["lastError", format ["Garage extension call '%1' did not succeed.", _function]];
            createHashMap
        };
        if !(_result isEqualType "") exitWith {
            _self set ["lastError", format ["Garage extension call '%1' returned invalid data.", _function]];
            createHashMap
        };
        if ((_result find "Error:") == 0) exitWith {
            _self set ["lastError", _result];
            ["ERROR", format ["Garage extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            createHashMap
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith {
            _self set ["lastError", format ["Garage extension call '%1' returned non-map JSON.", _function]];
            createHashMap
        };

        _self set ["lastCallSucceeded", true];
        _data
    }],
    ["didLastCallSucceed", compileFinal {
        _self getOrDefault ["lastCallSucceeded", false]
    }],
    ["getLastError", compileFinal {
        _self getOrDefault ["lastError", ""]
    }],
    ["loadHotGarage", compileFinal {
        params [["_uid", "", [""]], ["_initialize", false, [false]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _command = ["garage:hot:get", "garage:hot:init"] select _initialize;
        _self call ["callHotGarage", [_command, [_uid]]]
    }],
    ["init", compileFinal {
        params [["_uid", "", [""]]];

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { createHashMap };

        private _garage = _self call ["loadHotGarage", [_uid, true]];

        [CRPC(garage,responseInitGarage), [_garage], _player] call CFUNC(targetEvent);
        _garage
    }],
    ["save", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { createHashMap };
        _self call ["callHotGarage", ["garage:hot:save", [_uid]]]
    }],
    ["storeVehicle", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_payloadJson", "", [""]]
        ];

        if (_uid isEqualTo "" || { _payloadJson isEqualTo "" }) exitWith { createHashMap };
        _self call ["callHotGarage", ["garage:hot:add", [_uid, _payloadJson]]]
    }],
    ["retrieveVehicle", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_payloadJson", "", [""]]
        ];

        if (_uid isEqualTo "" || { _payloadJson isEqualTo "" }) exitWith { createHashMap };
        _self call ["callHotGarage", ["garage:hot:remove_vehicle", [_uid, _payloadJson]]]
    }]
]] call {
    params ["_base", "_child"];

    private _merged = +_base;
    { _merged set [_x, _y]; } forEach _child;
    _merged
});

GVAR(GarageStore) = createHashMapObject [GVAR(GarageBaseStore), []];
true
