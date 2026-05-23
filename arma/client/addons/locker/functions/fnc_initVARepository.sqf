#include "..\script_component.hpp"

/*
 * File: fnc_initVARepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the virtual arsenal repository for managing player arsenal unlocks.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Virtual arsenal repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_locker_fnc_initVARepository;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(VARepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "VARepositoryBaseClass"],
    ["#create", compileFinal {
        _self set ["uid", getPlayerUID player];
        _self set ["vArsenal", createHashMap];
        _self set ["isLoaded", false];
        _self set ["lastSave", time];
    }],
    ["init", compileFinal {
        private _uid = _self get "uid";
        FORGE_Locker_Box = "ReammoBox_F" createVehicleLocal [0, 0, -999];
        [SRPC(locker,requestInitVA), [_uid]] call CFUNC(serverEvent);
        _self set ["lastSave", time];

        systemChat format ["VArsenal loaded for %1", name player];
        diag_log "[FORGE:Client:VArsenal] Repository Initialized!";
    }],
    ["save", compileFinal {
        private _uid = _self get "uid";
        [SRPC(locker,requestSaveVA), [_uid]] call CFUNC(serverEvent);

        _self set ["lastSave", time];
    }],
    ["sync", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _vArsenal = _self get "vArsenal";
        private _isLoaded = _self get "isLoaded";

        {
            _vArsenal set [_x, _y];

            switch (_x) do {
                case "items": { _self call ["applyItems", []]; };
                case "weapons": { _self call ["applyWeapons", []]; };
                case "magazines": { _self call ["applyMagazines", []]; };
                case "backpacks": { _self call ["applyBackpacks", []]; };
                default {};
            };
        } forEach _data;

        _self set ["vArsenal", _vArsenal];

        if !(_isLoaded) then { _self set ["isLoaded", true]; };
        diag_log "[FORGE:Client:VArsenal] Sync completed";
    }],
    ["get", compileFinal {
        params [["_key", "", [""]], ["_default", nil, [[], "", 0, false, createHashMap]]];

        private _vArsenal = _self get "vArsenal";
        _vArsenal getOrDefault [_key, _default];
    }],
    ["applyItems", compileFinal {
        private _items = _self call ["get", ["items", []]];
        [FORGE_Locker_Box, _items] call AFUNC(arsenal,addVirtualItems);
    }],
    ["applyWeapons", compileFinal {
        private _weapons = _self call ["get", ["weapons", []]];
        [FORGE_Locker_Box, _weapons] call AFUNC(arsenal,addVirtualItems);
    }],
    ["applyMagazines", compileFinal {
        private _magazines = _self call ["get", ["magazines", []]];
        [FORGE_Locker_Box, _magazines] call AFUNC(arsenal,addVirtualItems);
    }],
    ["applyBackpacks", compileFinal {
        private _backpacks = _self call ["get", ["backpacks", []]];
        [FORGE_Locker_Box, _backpacks] call AFUNC(arsenal,addVirtualItems);
    }]
];

GVAR(VARepository) = createHashMapObject [GVAR(VARepositoryBaseClass)];
GVAR(VARepository)
