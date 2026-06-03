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
    ["getStartingUnlocksConfig", compileFinal {
        missionConfigFile >> "CfgStartingEquipment" >> "Unlocks" >> "Garage"
    }],
    ["getStartingUnlocks", compileFinal {
        params [["_category", "", [""]], ["_fallback", [], [[]]]];

        private _config = _self call ["getStartingUnlocksConfig", []];
        private _categoryConfig = _config >> _category;

        if (isArray _categoryConfig) exitWith { getArray _categoryConfig };

        +_fallback
    }],
    ["defaults", compileFinal {
        private _vGarage = createHashMap;

        _vGarage set ["armor", _self call ["getStartingUnlocks", ["armor", []]]];
        _vGarage set ["cars", _self call ["getStartingUnlocks", ["cars", ["B_Quadbike_01_F"]]]];
        _vGarage set ["helis", _self call ["getStartingUnlocks", ["helis", []]]];
        _vGarage set ["naval", _self call ["getStartingUnlocks", ["naval", []]]];
        _vGarage set ["other", _self call ["getStartingUnlocks", ["other", []]]];
        _vGarage set ["planes", _self call ["getStartingUnlocks", ["planes", []]]];

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
    ["isPersistentVGarageInitialized", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { false };

        ["owned:garage:exists", [_uid]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        _isSuccess && { _result isEqualTo "true" }
    }],
    ["seedStartingUnlocks", compileFinal {
        params [["_uid", "", [""]], ["_garage", createHashMap, [createHashMap]]];

        if (_uid isEqualTo "" || { _garage isEqualTo createHashMap }) exitWith { _garage };

        private _defaults = GVAR(VGarageModel) call ["defaults", []];
        private _seeded = +_garage;
        {
            _seeded set [_x, +_y];
        } forEach _defaults;

        private _updated = _self call ["callHotVGarage", ["owned:garage:hot:override", [_uid, toJSON _seeded]]];
        if (_updated isEqualTo createHashMap) exitWith { _seeded };

        _self call ["callHotVGarage", ["owned:garage:hot:save", [_uid]]];
        _updated
    }],
    ["init", compileFinal {
        params [["_uid", "", [""]]];

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { createHashMap };

        private _hasPersistentGarage = _self call ["isPersistentVGarageInitialized", [_uid]];
        private _garage = _self call ["loadHotVGarage", [_uid, true]];
        if (_garage isEqualTo createHashMap) then {
            _garage = GVAR(VGarageModel) call ["defaults", []];
            ["ERROR", format ["Failed to initialize virtual garage for %1! Using fallback virtual garage.", _uid]] call EFUNC(common,log);
        };
        if !(_hasPersistentGarage) then {
            _garage = _self call ["seedStartingUnlocks", [_uid, _garage]];
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
