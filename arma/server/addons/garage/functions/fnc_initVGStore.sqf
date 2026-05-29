#include "..\script_component.hpp"

/*
 * File: fnc_initVGStore.sqf
 * Author: IDSolutions
 * Date: 2025-12-17
 * Last Update: 2026-04-01
 * Public: No
 *
 * Description:
 * Initializes the Virtual Garage store for managing player vehicle unlocks.
 * Virtual garage hot state is owned by the extension; SQF acts as a thin bridge.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * VG store object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_garage_fnc_initVGStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(VGarageModel) = compileFinal createHashMapObject [[
    ["#type", "VGarageModel"],
    ["defaults", compileFinal {
        private _vGarage = createHashMap;

        _vGarage set ["armor", []];
        _vGarage set ["cars", ["B_Quadbike_01_F"]];
        _vGarage set ["helis", []];
        _vGarage set ["naval", []];
        _vGarage set ["other", []];
        _vGarage set ["planes", []];

        _vGarage
    }]
]];

GVAR(VGBaseStore) = compileFinal createHashMapFromArray [
    ["#base", EGVAR(common,BaseStore)],
    ["#type", "VGBaseStore"],
    ["#create", compileFinal {
        ["INFO", "VGarage Store Initialized!"] call EFUNC(common,log);
    }],
    ["callHotVGarage", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        if (_function isEqualTo "") exitWith { createHashMap };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith { createHashMap };
        if !(_result isEqualType "") exitWith { createHashMap };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["VGarage extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            createHashMap
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith { createHashMap };
        _data
    }],
    ["loadHotVGarage", compileFinal {
        params [["_uid", "", [""]], ["_initialize", false, [false]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _command = ["owned:garage:hot:fetch", "owned:garage:hot:init"] select _initialize;
        _self call ["callHotVGarage", [_command, [_uid]]]
    }],
    ["init", compileFinal {
        params [["_uid", "", [""]]];

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { createHashMap };

        private _garage = _self call ["loadHotVGarage", [_uid, true]];
        if (_garage isEqualTo createHashMap) then {
            _garage = GVAR(VGarageModel) call ["defaults", []];
            ["ERROR", format ["Failed to initialize virtual garage for %1! Using fallback virtual garage.", _uid]] call EFUNC(common,log);
        };

        [CRPC(garage,responseInitVG), [_garage], _player] call CFUNC(targetEvent);
        _garage
    }],
    ["save", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { createHashMap };
        _self call ["callHotVGarage", ["owned:garage:hot:save", [_uid]]]
    }]
];

GVAR(VGarageStore) = createHashMapObject [GVAR(VGBaseStore)];
GVAR(VGarageStore)
