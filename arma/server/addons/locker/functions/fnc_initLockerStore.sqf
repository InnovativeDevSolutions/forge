#include "..\script_component.hpp"

/*
 * File: fnc_initLockerStore.sqf
 * Author: IDSolutions
 * Date: 2025-12-17
 * Last Update: 2026-04-01
 * Public: No
 *
 * Description:
 * Initializes the Locker store for managing player locker items.
 * Locker hot state is owned by the extension; SQF acts as a thin bridge.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Locker store object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_locker_fnc_initLockerStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(LockerBaseStore) = compileFinal ([
    EGVAR(common,BaseStore),
    createHashMapFromArray [
    ["#type", "LockerBaseStore"],
    ["#create", compileFinal {
        ["INFO", "Locker Store Initialized!"] call EFUNC(common,log);
        true
    }],
    ["callHotLocker", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        if (_function isEqualTo "") exitWith { createHashMap };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith { createHashMap };
        if !(_result isEqualType "") exitWith { createHashMap };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Locker extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            createHashMap
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith { createHashMap };
        _data
    }],
    ["loadHotLocker", compileFinal {
        params [["_uid", "", [""]], ["_initialize", false, [false]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _command = ["locker:hot:get", "locker:hot:init"] select _initialize;
        _self call ["callHotLocker", [_command, [_uid]]]
    }],
    ["init", compileFinal {
        params [["_uid", "", [""]]];

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { createHashMap };

        private _locker = _self call ["loadHotLocker", [_uid, true]];

        [CRPC(locker,responseInitLocker), [_locker], _player] call CFUNC(targetEvent);
        _locker
    }],
    ["override", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_data", createHashMap, [createHashMap]],
            ["_save", false, [false]]
        ];

        if (_uid isEqualTo "") exitWith { createHashMap };
        if !(_data isEqualType createHashMap) exitWith { createHashMap };

        private _locker = _self call ["callHotLocker", ["locker:hot:override", [_uid, toJSON _data]]];
        if (_save && { _locker isNotEqualTo createHashMap }) then {
            private _savedLocker = _self call ["callHotLocker", ["locker:hot:save", [_uid]]];
            if (_savedLocker isNotEqualTo createHashMap) then {
                _locker = _savedLocker;
            } else {
                _locker = createHashMap;
            };
        };

        _locker
    }],
    ["save", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { createHashMap };
        _self call ["callHotLocker", ["locker:hot:save", [_uid]]]
    }]
]] call {
    params ["_base", "_child"];

    private _merged = +_base;
    { _merged set [_x, _y]; } forEach _child;
    _merged
});

GVAR(LockerStore) = createHashMapObject [GVAR(LockerBaseStore), []];
true
