#include "..\script_component.hpp"

/*
 * File: fnc_initRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the garage repository for persisted stored vehicle records.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Garage repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_garage_fnc_initRepository;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(GarageRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "GarageRepositoryBaseClass"],
    ["#create", compileFinal {
        _self set ["uid", getPlayerUID player];
        _self set ["garage", createHashMap];
        _self set ["isLoaded", false];
        _self set ["lastSave", time];
    }],
    ["init", compileFinal {
        private _uid = _self get "uid";
        [SRPC(garage,requestInitGarage), [_uid]] call CFUNC(serverEvent);
        _self set ["lastSave", time];

        systemChat format ["Garage loaded for %1", name player];
        diag_log "[FORGE:Client:Garage] Garage Repository Initialized!";
    }],
    ["save", compileFinal {
        private _uid = _self get "uid";
        [SRPC(garage,requestSaveGarage), [_uid]] call CFUNC(serverEvent);
        _self set ["lastSave", time];
    }],
    ["sync", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _isLoaded = _self get "isLoaded";
        private _garage = createHashMap;
        { _garage set [_x, _y]; } forEach _data;
        _self set ["garage", _garage];

        if !(_isLoaded) then { _self set ["isLoaded", true]; };
        diag_log "[FORGE:Client:Garage] Repository sync completed";
    }],
    ["getState", compileFinal {
        _self getOrDefault ["garage", createHashMap]
    }],
    ["get", compileFinal {
        params [["_key", "", [""]], ["_default", nil, [[], "", 0, false, createHashMap]]];

        private _garage = _self get "garage";
        _garage getOrDefault [_key, _default];
    }]
];

GVAR(GarageRepository) = createHashMapObject [GVAR(GarageRepositoryBaseClass)];
GVAR(GarageRepository)
