#include "..\script_component.hpp"

/*
 * File: fnc_initVAStore.sqf
 * Author: IDSolutions
 * Date: 2025-12-17
 * Last Update: 2026-04-05
 * Public: No
 *
 * Description:
 * Initializes the Virtual Arsenal store for managing player arsenal unlocks.
 * Virtual arsenal hot state is owned by the extension; SQF acts as a thin bridge.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * VA store object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_locker_fnc_initVAStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(VArsenalModel) = compileFinal createHashMapObject [[
    ["#type", "VArsenalModel"],
    ["defaults", compileFinal {
        private _vArsenal = createHashMap;

        _vArsenal set ["backpacks", ["B_AssaultPack_rgr"]];
        _vArsenal set ["items", ["FirstAidKit", "G_Combat", "H_Cap_blk_ION", "H_HelmetB", "ItemCompass", "ItemGPS", "ItemMap", "ItemRadio", "ItemWatch", "U_BG_Guerrilla_6_1", "V_TacVest_oli", "ACE_EarPlugs"]];
        _vArsenal set ["magazines", ["16Rnd_9x21_Mag", "30Rnd_65x39_caseless_black_mag", "Chemlight_blue", "Chemlight_green", "Chemlight_red", "Chemlight_yellow", "HandGrenade", "SmokeShell", "SmokeShellBlue", "SmokeShellGreen", "SmokeShellOrange", "SmokeShellPurple", "SmokeShellRed", "SmokeShellYellow"]];
        _vArsenal set ["weapons", ["arifle_MX_F", "hgun_P07_F"]];

        _vArsenal
    }]
]];

GVAR(VABaseStore) = compileFinal ([
    EGVAR(common,BaseStore),
    createHashMapFromArray [
    ["#type", "VABaseStore"],
    ["#create", compileFinal {
        ["INFO", "VArsenal Store Initialized!"] call EFUNC(common,log);
        true
    }],
    ["callHotVArsenal", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        if (_function isEqualTo "") exitWith { createHashMap };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith { createHashMap };
        if !(_result isEqualType "") exitWith { createHashMap };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["VArsenal extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            createHashMap
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith { createHashMap };
        _data
    }],
    ["loadHotVArsenal", compileFinal {
        params [["_uid", "", [""]], ["_initialize", false, [false]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _command = ["owned:locker:hot:fetch", "owned:locker:hot:init"] select _initialize;
        _self call ["callHotVArsenal", [_command, [_uid]]]
    }],
    ["init", compileFinal {
        params [["_uid", "", [""]]];

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { createHashMap };

        private _arsenal = _self call ["loadHotVArsenal", [_uid, true]];
        if (_arsenal isEqualTo createHashMap) then {
            _arsenal = GVAR(VArsenalModel) call ["defaults", []];
            ["ERROR", format ["Failed to initialize virtual arsenal for %1! Using fallback virtual arsenal.", _uid]] call EFUNC(common,log);
        };

        [CRPC(locker,responseInitVA), [_arsenal], _player] call CFUNC(targetEvent);
        _arsenal
    }],
    ["save", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { createHashMap };
        _self call ["callHotVArsenal", ["owned:locker:hot:save", [_uid]]]
    }]
]] call {
    params ["_base", "_child"];

    private _merged = +_base;
    { _merged set [_x, _y]; } forEach _child;
    _merged
});

GVAR(VAStore) = createHashMapObject [GVAR(VABaseStore), []];
true
