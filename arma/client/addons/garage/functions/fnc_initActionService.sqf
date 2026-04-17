#include "..\script_component.hpp"

/*
 * File: fnc_initActionService.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Last Update: 2026-04-18
 * Public: No
 *
 * Description:
 * Initializes the garage action service for retrieve, store, refuel, and
 * repair world actions.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Garage action service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_garage_fnc_initActionService;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(GarageActionServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "GarageActionServiceBaseClass"],
    ["#create", compileFinal {
        _self set ["pendingStoreVehicle", objNull];
        _self set ["pendingRetrieve", createHashMap];
    }],
    ["sendServiceResult", compileFinal {
        params [["_action", "", [""]], ["_success", false, [false]], ["_message", "", [""]]];

        private _event = ["garage::service::failure", "garage::service::success"] select _success;
        GVAR(GarageUIBridge) call ["sendEvent", [_event, createHashMapFromArray [["action", _action], ["message", _message]]]];
    }],
    ["refreshAfterService", compileFinal {
        [] spawn {
            sleep 0.75;
            if !(isNil QGVAR(GarageUIBridge)) then {
                GVAR(GarageUIBridge) call ["refreshGarage", []];
            };
        };
    }],
    ["resolveServiceVehicle", compileFinal {
        params [["_data", createHashMap, [createHashMap]], ["_action", "service", [""]]];

        private _netId = _data getOrDefault ["netId", ""];
        if (_netId isEqualTo "") exitWith {
            _self call ["sendServiceResult", [_action, false, "Select a nearby vehicle first."]];
            objNull
        };

        private _vehicle = objectFromNetId _netId;
        if (isNull _vehicle) exitWith {
            _self call ["sendServiceResult", [_action, false, "The selected vehicle is no longer available."]];
            objNull
        };

        if !(_vehicle isKindOf "Car" || { _vehicle isKindOf "Tank" } || { _vehicle isKindOf "Air" } || { _vehicle isKindOf "Ship" }) exitWith {
            _self call ["sendServiceResult", [_action, false, "Selected object is not a serviceable vehicle."]];
            objNull
        };

        _vehicle
    }],
    ["vehicleNeedsRepair", compileFinal {
        params [["_vehicle", objNull, [objNull]]];

        if (isNull _vehicle) exitWith { false };
        if ((damage _vehicle) > 0.001) exitWith { true };

        private _rawHitPoints = getAllHitPointsDamage _vehicle;
        private _hitPointValues = if (_rawHitPoints isEqualType [] && { count _rawHitPoints >= 3 }) then { _rawHitPoints param [2, []] } else { [] };
        ({ _x > 0.001 } count _hitPointValues) > 0
    }],
    ["handleRetrieveRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _plate = _data getOrDefault ["plate", ""];
        if (_plate isEqualTo "") exitWith {
            GVAR(GarageUIBridge) call ["sendEvent", ["garage::retrieve::failure", createHashMapFromArray [["message", "Select a stored vehicle to retrieve."]]]];
        };

        private _garageMap = if (isNil QGVAR(GarageRepository)) then { createHashMap } else { GVAR(GarageRepository) call ["getState", []] };
        private _vehicleData = _garageMap getOrDefault [_plate, createHashMap];
        if (_vehicleData isEqualTo createHashMap) exitWith {
            GVAR(GarageUIBridge) call ["sendEvent", ["garage::retrieve::failure", createHashMapFromArray [["message", "Stored vehicle record could not be found."]]]];
        };

        private _className = _vehicleData getOrDefault ["classname", ""];
        if (_className isEqualTo "") exitWith {
            GVAR(GarageUIBridge) call ["sendEvent", ["garage::retrieve::failure", createHashMapFromArray [["message", "Stored vehicle record is missing a classname."]]]];
        };

        private _context = GVAR(GarageContextService) call ["getContext", []];
        private _vehicleCategory = GVAR(GarageHelperService) call ["resolveVGCategory", [_className]];
        private _spawnLane = GVAR(GarageContextService) call ["getExactSpawnLane", [_vehicleCategory, _context]];
        if (_spawnLane isEqualTo createHashMap) exitWith {
            private _categoryLabel = GVAR(GarageHelperService) call ["resolveGarageCategoryLabel", [_vehicleCategory]];
            GVAR(GarageUIBridge) call ["sendEvent", ["garage::retrieve::failure", createHashMapFromArray [["message", format ["This garage does not support spawning %1.", _categoryLabel]]]]];
        };

        private _spawnPosition = _spawnLane getOrDefault ["spawnPosition", _context getOrDefault ["spawnPosition", getPosATL player]];
        private _spawnHeading = _spawnLane getOrDefault ["spawnHeading", _context getOrDefault ["spawnHeading", getDir player]];
        private _spawnRadius = _context getOrDefault ["spawnRadius", 6];
        private _blockingVehicles = [];
        { _blockingVehicles pushBackUnique _x; } forEach (_spawnPosition nearEntities [["Car", "Tank", "Air", "Ship"], _spawnRadius]);
        { _blockingVehicles pushBackUnique _x; } forEach (nearestObjects [_spawnPosition, ["Car", "Tank", "Air", "Ship"], _spawnRadius]);
        if (_blockingVehicles isNotEqualTo []) exitWith {
            GVAR(GarageUIBridge) call ["sendEvent", ["garage::retrieve::failure", createHashMapFromArray [["message", "The garage spawn area is blocked."]]]];
        };

        private _vehicle = createVehicle [_className, _spawnPosition, [], 0, "CAN_COLLIDE"];
        _vehicle setDir _spawnHeading;
        _vehicle setFuel (_vehicleData getOrDefault ["fuel", 0]);
        _vehicle setDamage (_vehicleData getOrDefault ["damage", 0]);

        private _hitPoints = _vehicleData getOrDefault ["hit_points", createHashMap];
        private _hitPointNames = _hitPoints getOrDefault ["names", []];
        private _hitPointValues = _hitPoints getOrDefault ["values", []];
        for "_index" from 0 to ((count _hitPointNames) - 1) do {
            _vehicle setHitPointDamage [_hitPointNames param [_index, ""], _hitPointValues param [_index, 0]];
        };

        _vehicle setVariable ["forge_garage_plate", _plate, true];
        _vehicle setVariable ["forge_garage_owner_uid", getPlayerUID player, true];

        _self set ["pendingRetrieve", createHashMapFromArray [["plate", _plate], ["vehicle", _vehicle]]];
        [SRPC(garage,requestRetrieveVehicle), [getPlayerUID player, _plate]] call CFUNC(serverEvent);
    }],
    ["handleStoreRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _netId = _data getOrDefault ["netId", ""];
        if (_netId isEqualTo "") exitWith {
            GVAR(GarageUIBridge) call ["sendEvent", ["garage::store::failure", createHashMapFromArray [["message", "Select a nearby vehicle to store."]]]];
        };

        private _vehicle = objectFromNetId _netId;
        if (isNull _vehicle) exitWith {
            GVAR(GarageUIBridge) call ["sendEvent", ["garage::store::failure", createHashMapFromArray [["message", "The selected vehicle is no longer available."]]]];
        };

        if (crew _vehicle isNotEqualTo []) exitWith {
            GVAR(GarageUIBridge) call ["sendEvent", ["garage::store::failure", createHashMapFromArray [["message", "All crew must exit the vehicle before storing it."]]]];
        };

        private _rawHitPoints = getAllHitPointsDamage _vehicle;
        private _hitPointsJson = toJSON (createHashMapFromArray [["names", _rawHitPoints param [0, []]], ["selections", _rawHitPoints param [1, []]], ["values", _rawHitPoints param [2, []]]]);

        _self set ["pendingStoreVehicle", _vehicle];
        [SRPC(garage,requestStoreVehicle), [getPlayerUID player, netId _vehicle, typeOf _vehicle, fuel _vehicle, damage _vehicle, _hitPointsJson]] call CFUNC(serverEvent);
    }],
    ["handleRefuelRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _vehicle = _self call ["resolveServiceVehicle", [_data, "refuel"]];
        if (isNull _vehicle) exitWith { false };

        if ((fuel _vehicle) >= 0.999) exitWith {
            _self call ["sendServiceResult", ["refuel", false, "Vehicle fuel tank is already full."]];
            false
        };

        [SRPC(economy,RefuelService), [_vehicle, player]] call CFUNC(serverEvent);
        _self call ["sendServiceResult", ["refuel", true, "Refuel request sent. Billing result will appear as a notification."]];
        _self call ["refreshAfterService", []];
        true
    }],
    ["handleRepairRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _vehicle = _self call ["resolveServiceVehicle", [_data, "repair"]];
        if (isNull _vehicle) exitWith { false };

        if !(_self call ["vehicleNeedsRepair", [_vehicle]]) exitWith {
            _self call ["sendServiceResult", ["repair", false, "Vehicle has no reported damage."]];
            false
        };

        [SRPC(economy,RepairService), [_vehicle, player, -1]] call CFUNC(serverEvent);
        _self call ["sendServiceResult", ["repair", true, "Repair request sent. Billing result will appear as a notification."]];
        _self call ["refreshAfterService", []];
        true
    }],
    ["handleActionResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _action = _payload getOrDefault ["action", ""];
        private _success = _payload getOrDefault ["success", false];
        private _message = _payload getOrDefault ["message", "Garage action failed."];

        switch (_action) do {
            case "retrieve": {
                private _pendingRetrieve = _self getOrDefault ["pendingRetrieve", createHashMap];
                private _vehicle = _pendingRetrieve getOrDefault ["vehicle", objNull];
                if (!_success && { !isNull _vehicle }) then { deleteVehicle _vehicle; };
                _self set ["pendingRetrieve", createHashMap];
                GVAR(GarageUIBridge) call ["sendEvent", [[ "garage::retrieve::failure", "garage::retrieve::success" ] select _success, createHashMapFromArray [["message", _message]]]];
            };
            case "store": {
                private _vehicle = _self getOrDefault ["pendingStoreVehicle", objNull];
                if (_success && { !isNull _vehicle }) then { deleteVehicle _vehicle; };
                _self set ["pendingStoreVehicle", objNull];
                GVAR(GarageUIBridge) call ["sendEvent", [[ "garage::store::failure", "garage::store::success" ] select _success, createHashMapFromArray [["message", _message]]]];
            };
        };

        [] spawn {
            sleep 0.05;
            if !(isNil QGVAR(GarageUIBridge)) then {
                GVAR(GarageUIBridge) call ["refreshGarage", []];
            };
        };
    }]
];

GVAR(GarageActionService) = createHashMapObject [GVAR(GarageActionServiceBaseClass)];
GVAR(GarageActionService)
