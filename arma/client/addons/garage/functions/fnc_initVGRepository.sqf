#include "..\script_component.hpp"

/*
 * File: fnc_initVGRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the virtual garage repository for BIS virtual garage state.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Virtual garage repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_garage_fnc_initVGRepository;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(VGRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "VGRepositoryBaseClass"],
    ["#create", compileFinal {
        GVAR(isPreLoaded) = false;
        _self set ["uid", getPlayerUID player];
        _self set ["vGarage", createHashMap];
        _self set ["isLoaded", false];
        _self set ["lastSave", time];
    }],
    ["init", compileFinal {
        private _uid = _self get "uid";
        [SRPC(garage,requestInitVG), [_uid]] call CFUNC(serverEvent);
        _self set ["lastSave", time];

        systemChat format ["VGarage loaded for %1", name player];
        diag_log "[FORGE:Client:VGarage] Repository Initialized!";
    }],
    ["save", compileFinal {
        private _uid = _self get "uid";
        [SRPC(garage,requestSaveVG), [_uid]] call CFUNC(serverEvent);
        _self set ["lastSave", time];
    }],
    ["sync", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _vGarage = _self get "vGarage";
        private _isLoaded = _self get "isLoaded";

        {
            _vGarage set [_x, _y];
            switch (_x) do {
                case "cars": { _self call ["apply", ["cars"]]; };
                case "armor": { _self call ["apply", ["armor"]]; };
                case "helis": { _self call ["apply", ["helis"]]; };
                case "planes": { _self call ["apply", ["planes"]]; };
                case "naval": { _self call ["apply", ["naval"]]; };
                case "other": { _self call ["apply", ["other"]]; };
                default {};
            };
        } forEach _data;

        _self set ["vGarage", _vGarage];
        if !(_isLoaded) then { _self set ["isLoaded", true]; };
        diag_log "[FORGE:Client:VGarage] Repository sync completed";
    }],
    ["get", compileFinal {
        params [["_key", "", [""]], ["_default", nil, [[], "", 0, false, createHashMap]]];

        private _vGarage = _self get "vGarage";
        _vGarage getOrDefault [_key, _default];
    }],
    ["apply", compileFinal {
        params [["_key", "", [""]]];

        private _vehicles = _self call ["get", [_key, []]];
        private _appliedVehicles = [];
        {
            _appliedVehicles append [getText (configFile >> "CfgVehicles" >> _x >> "model"), [configFile >> "CfgVehicles" >> _x]];
        } forEach _vehicles;

        switch (_key) do {
            case "cars": { GVAR(Cars) = _appliedVehicles; };
            case "armor": { GVAR(Armor) = _appliedVehicles; };
            case "helis": { GVAR(Helis) = _appliedVehicles; };
            case "planes": { GVAR(Planes) = _appliedVehicles; };
            case "naval": { GVAR(Naval) = _appliedVehicles; };
            case "other": { GVAR(Other) = _appliedVehicles; };
            default {};
        };
    }]
];

GVAR(VGRepository) = createHashMapObject [GVAR(VGRepositoryBaseClass)];
GVAR(VGRepository)
