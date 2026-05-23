#include "..\script_component.hpp"

/*
 * File: fnc_initPayloadService.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the garage payload service for browser hydrate payload composition.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Garage payload service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_garage_fnc_initPayloadService;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(GaragePayloadServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "GaragePayloadServiceBaseClass"],
    ["buildStoredVehicles", compileFinal {
        private _garageMap = if (isNil QGVAR(GarageRepository)) then { createHashMap } else { GVAR(GarageRepository) call ["getState", []] };
        private _storedVehicles = [];
        { _storedVehicles pushBack (GVAR(GarageHelperService) call ["buildStoredVehicle", [_x, _y]]); } forEach _garageMap;
        private _storedVehiclePairs = _storedVehicles apply { [toLowerANSI (_x getOrDefault ["displayName", ""]), _x] };
        _storedVehiclePairs sort true;
        _storedVehiclePairs apply { _x param [1, createHashMap] }
    }],
    ["buildPayload", compileFinal {
        private _localState = GVAR(GarageContextService) call ["buildNearbyState", []];
        private _storedVehicles = _self call ["buildStoredVehicles", []];
        private _session = +(_localState getOrDefault ["session", createHashMap]);
        _session set ["capacityUsed", count _storedVehicles];
        _session set ["capacityMax", 5];
        createHashMapFromArray [["session", _session], ["garage", createHashMapFromArray [["vehicles", _storedVehicles]]], ["nearby", +(_localState getOrDefault ["nearby", createHashMap])]]
    }]
];

GVAR(GaragePayloadService) = createHashMapObject [GVAR(GaragePayloadServiceBaseClass)];
GVAR(GaragePayloadService)
