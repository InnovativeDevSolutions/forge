#include "..\script_component.hpp"

/*
 * File: fnc_initContextService.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the garage context service for local garage context and nearby state.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Garage context service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_garage_fnc_initContextService;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(GarageContextServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "GarageContextServiceBaseClass"],
    ["#create", compileFinal {
        _self set ["lastContext", createHashMap];
        _self set ["activeGarageObject", objNull];
    }],
    ["#delete", compileFinal {
        _self set ["lastContext", createHashMap];
        _self set ["activeGarageObject", objNull];
    }],
    ["setActiveGarageObject", compileFinal {
        params [["_garageObject", objNull, [objNull]]];

        if (isNull _garageObject || { !(_garageObject getVariable ["isGarage", false]) }) exitWith {
            _self set ["activeGarageObject", objNull];
            false
        };

        _self set ["activeGarageObject", _garageObject];
        true
    }],
    ["getActiveGarageObject", compileFinal {
        private _garageObject = _self getOrDefault ["activeGarageObject", objNull];
        if (isNull _garageObject || { !(_garageObject getVariable ["isGarage", false]) }) exitWith { objNull };
        if ((player distance2D _garageObject) > 12) exitWith {
            _self set ["activeGarageObject", objNull];
            objNull
        };

        _garageObject
    }],
    ["createDefaultContext", compileFinal {
        createHashMapFromArray [
            ["name", "Vehicle Garage"],
            ["anchorPosition", getPosATL player],
            ["sourceObject", objNull],
            ["garageType", ""],
            ["spawnHeading", getDir player],
            ["spawnPosition", player getPos [8, getDir player]],
            ["spawnLanes", createHashMap],
            ["spawnRadius", 6],
            ["nearbyRadius", 30],
            ["laneRadius", 25]
        ]
    }],
    ["findNearbyGarageObject", compileFinal {
        private _nearestGarage = objNull;
        private _nearestDistance = 1e10;

        {
            if (isNull _x || { !(_x getVariable ["isGarage", false]) }) then { continue; };
            private _distance = player distance2D _x;
            if (_distance < _nearestDistance) then {
                _nearestDistance = _distance;
                _nearestGarage = _x;
            };
        } forEach (player nearObjects 12);

        _nearestGarage
    }],
    ["resolveGarageName", compileFinal {
        params [["_garageObject", objNull, [objNull]]];

        if (isNull _garageObject) exitWith { "Vehicle Garage" };

        private _displayName = _garageObject getVariable ["garageName", ""];
        if (_displayName isNotEqualTo "") exitWith { _displayName };

        private _varName = vehicleVarName _garageObject;
        if (_varName isEqualTo "") exitWith { "Vehicle Garage" };

        _varName
    }],
    ["buildMarkerLane", compileFinal {
        params [["_markerName", "", [""]], ["_garageObject", objNull, [objNull]]];

        if (_markerName isEqualTo "" || { markerShape _markerName isEqualTo "" }) exitWith { createHashMap };

        private _spawnCategory = GVAR(GarageHelperService) call ["inferGarageCategory", [_markerName]];
        if (_spawnCategory isEqualTo "") exitWith { createHashMap };

        private _spawnPosition = markerPos _markerName;
        private _interactionPosition = if (isNull _garageObject) then { _spawnPosition } else { getPosATL _garageObject };
        private _markerDistance = if (isNull _garageObject) then { player distance2D _spawnPosition } else { _garageObject distance2D _spawnPosition };
        private _garageVarName = if (isNull _garageObject) then { "" } else { toLowerANSI (vehicleVarName _garageObject) };
        private _markerKey = toLowerANSI _markerName;
        private _isExplicitMatch = _garageVarName isNotEqualTo "" && { (_markerKey find _garageVarName) >= 0 };

        createHashMapFromArray [
            ["name", _markerName],
            ["isExplicitMatch", _isExplicitMatch],
            ["interactionPosition", _interactionPosition],
            ["sourceObject", _garageObject],
            ["spawnCategory", _spawnCategory],
            ["spawnHeading", markerDir _markerName],
            ["spawnPosition", _spawnPosition],
            ["score", _markerDistance]
        ]
    }],
    ["discoverSpawnLanes", compileFinal {
        params [["_garageObject", objNull, [objNull]]];

        private _laneRadius = (_self call ["createDefaultContext", []]) getOrDefault ["laneRadius", 25];
        private _explicitLanes = createHashMap;
        private _fallbackLanes = createHashMap;

        {
            private _markerName = _x;
            if ((toLowerANSI _markerName find "garage") < 0) then { continue; };

            private _entry = _self call ["buildMarkerLane", [_markerName, _garageObject]];
            if (_entry isEqualTo createHashMap) then { continue; };

            private _spawnPosition = _entry getOrDefault ["spawnPosition", []];
            if (_spawnPosition isEqualTo []) then { continue; };

            private _distance = if (isNull _garageObject) then { player distance2D _spawnPosition } else { _garageObject distance2D _spawnPosition };
            if (_distance > _laneRadius) then { continue; };

            private _spawnCategory = _entry getOrDefault ["spawnCategory", ""];
            private _laneSet = _fallbackLanes;
            if (_entry getOrDefault ["isExplicitMatch", false]) then {
                _laneSet = _explicitLanes;
            };
            private _currentEntry = _laneSet getOrDefault [_spawnCategory, createHashMap];

            if (_currentEntry isEqualTo createHashMap || { (_entry getOrDefault ["score", 1e10]) < (_currentEntry getOrDefault ["score", 1e10]) }) then {
                _laneSet set [_spawnCategory, _entry];
            };
        } forEach allMapMarkers;

        private _lanes = createHashMap;
        { _lanes set [_x, _y]; } forEach _fallbackLanes;
        { _lanes set [_x, _y]; } forEach _explicitLanes;

        _lanes
    }],
    ["selectSpawnLane", compileFinal {
        params [
            ["_lanes", createHashMap, [createHashMap]],
            ["_preferredCategory", "", [""]],
            ["_defaultPosition", [], [[]]],
            ["_defaultHeading", 0, [0]]
        ];

        private _normalizedCategory = GVAR(GarageHelperService) call ["normalizeGarageCategory", [_preferredCategory]];
        private _lane = createHashMap;

        if (_normalizedCategory isNotEqualTo "") then {
            _lane = _lanes getOrDefault [_normalizedCategory, createHashMap];
        };

        if (_lane isEqualTo createHashMap) then {
            {
                private _candidate = _lanes getOrDefault [_x, createHashMap];
                if (_candidate isNotEqualTo createHashMap) exitWith { _lane = _candidate; };
            } forEach ["cars", "armor", "helis", "planes", "naval", "other"];
        };

        if (_lane isEqualTo createHashMap) then {
            _lane = createHashMapFromArray [
                ["spawnCategory", _normalizedCategory],
                ["spawnHeading", _defaultHeading],
                ["spawnPosition", _defaultPosition]
            ];
        };

        _lane
    }],
    ["getSpawnLane", compileFinal {
        params [["_category", "", [""]], ["_context", createHashMap, [createHashMap]]];

        private _resolvedContext = _context;
        if (_resolvedContext isEqualTo createHashMap) then {
            _resolvedContext = _self call ["getContext", []];
        };

        private _spawnLanes = _resolvedContext getOrDefault ["spawnLanes", createHashMap];
        private _defaultPosition = _resolvedContext getOrDefault ["spawnPosition", getPosATL player];
        private _defaultHeading = _resolvedContext getOrDefault ["spawnHeading", getDir player];
        _self call ["selectSpawnLane", [_spawnLanes, _category, _defaultPosition, _defaultHeading]]
    }],
    ["getExactSpawnLane", compileFinal {
        params [["_category", "", [""]], ["_context", createHashMap, [createHashMap]]];

        private _resolvedContext = _context;
        if (_resolvedContext isEqualTo createHashMap) then {
            _resolvedContext = _self call ["getContext", []];
        };

        private _normalizedCategory = GVAR(GarageHelperService) call ["normalizeGarageCategory", [_category]];
        if (_normalizedCategory isEqualTo "") exitWith { createHashMap };

        private _spawnLanes = _resolvedContext getOrDefault ["spawnLanes", createHashMap];
        _spawnLanes getOrDefault [_normalizedCategory, createHashMap]
    }],
    ["resolveContext", compileFinal {
        params [["_preferredGarageObject", objNull, [objNull]]];

        private _context = _self call ["createDefaultContext", []];
        private _garageObject = _preferredGarageObject;
        if (isNull _garageObject || { !(_garageObject getVariable ["isGarage", false]) }) then {
            _garageObject = _self call ["getActiveGarageObject", []];
        };
        if (isNull _garageObject) then {
            _garageObject = _self call ["findNearbyGarageObject", []];
        };
        private _garageName = _self call ["resolveGarageName", [_garageObject]];
        private _garageType = "";
        private _anchorPosition = getPosATL player;
        private _spawnHeading = getDir player;
        private _spawnPosition = player getPos [8, _spawnHeading];
        private _spawnLanes = createHashMap;

        if (!isNull _garageObject) then {
            _garageType = GVAR(GarageHelperService) call ["normalizeGarageCategory", [_garageObject getVariable ["garageType", ""]]];
            _anchorPosition = getPosATL _garageObject;
            _spawnHeading = getDir _garageObject;
            _spawnPosition = _garageObject getPos [8, _spawnHeading];
            _spawnLanes = _self call ["discoverSpawnLanes", [_garageObject]];
        };

        private _selectedLane = _self call ["selectSpawnLane", [_spawnLanes, _garageType, _spawnPosition, _spawnHeading]];
        _spawnHeading = _selectedLane getOrDefault ["spawnHeading", _spawnHeading];
        _spawnPosition = _selectedLane getOrDefault ["spawnPosition", _spawnPosition];

        _context set ["name", _garageName];
        _context set ["anchorPosition", _anchorPosition];
        _context set ["sourceObject", _garageObject];
        _context set ["garageType", _garageType];
        _context set ["spawnHeading", _spawnHeading];
        _context set ["spawnPosition", _spawnPosition];
        _context set ["spawnLanes", _spawnLanes];
        _self set ["lastContext", _context];
        _context
    }],
    ["getContext", compileFinal {
        params [["_preferredGarageObject", objNull, [objNull]]];
        _self call ["resolveContext", [_preferredGarageObject]]
    }],
    ["buildNearbyState", compileFinal {
        private _context = _self call ["getContext", []];
        private _anchorPosition = _context getOrDefault ["anchorPosition", []];
        private _spawnPosition = _context getOrDefault ["spawnPosition", getPosATL player];
        private _spawnRadius = _context getOrDefault ["spawnRadius", 6];
        private _nearbyRadius = _context getOrDefault ["nearbyRadius", 30];
        private _nearbyOrigin = [_anchorPosition, _spawnPosition] select (_anchorPosition isEqualTo []);
        private _nearbyVehicles = [];
        private _nearbyEntities = [];
        private _candidateVehicles = [];
        { _candidateVehicles pushBackUnique _x; } forEach (_nearbyOrigin nearEntities [["Car", "Tank", "Air", "Ship"], _nearbyRadius]);
        { _candidateVehicles pushBackUnique _x; } forEach ((getPosATL player) nearEntities [["Car", "Tank", "Air", "Ship"], _nearbyRadius]);
        { _candidateVehicles pushBackUnique _x; } forEach (nearestObjects [_nearbyOrigin, ["AllVehicles"], _nearbyRadius]);
        { _candidateVehicles pushBackUnique _x; } forEach (nearestObjects [getPosATL player, ["AllVehicles"], _nearbyRadius]);
        {
            if (isNull _x) then { continue; };
            if (_x isKindOf "CAManBase") then { continue; };
            if !(_x isKindOf "Car" || _x isKindOf "Tank" || _x isKindOf "Air" || _x isKindOf "Ship") then { continue; };
            _nearbyEntities pushBackUnique _x;
        } forEach _candidateVehicles;
        {
            if (isNull _x) then { continue; };
            private _builtVehicle = GVAR(GarageHelperService) call ["buildNearbyVehicle", [_x, _nearbyOrigin]];
            if (_builtVehicle isEqualTo createHashMap) then { continue; };
            _nearbyVehicles pushBack _builtVehicle;
        } forEach _nearbyEntities;
        private _nearbyVehiclePairs = _nearbyVehicles apply { [_x getOrDefault ["distance", 0], _x] };
        _nearbyVehiclePairs sort true;
        _nearbyVehicles = _nearbyVehiclePairs apply { _x param [1, createHashMap] };
        private _spawnBlocked = ((_spawnPosition nearEntities [["Car", "Tank", "Air", "Ship"], _spawnRadius]) + (nearestObjects [_spawnPosition, ["Car", "Tank", "Air", "Ship"], _spawnRadius])) isNotEqualTo [];
        createHashMapFromArray [["session", createHashMapFromArray [["garageName", _context getOrDefault ["name", "Vehicle Garage"]], ["nearbyCount", count _nearbyVehicles], ["spawnBlocked", _spawnBlocked], ["spawnStatus", ["Ready", "Blocked"] select _spawnBlocked]]], ["nearby", createHashMapFromArray [["vehicles", _nearbyVehicles]]]]
    }]
];

GVAR(GarageContextService) = createHashMapObject [GVAR(GarageContextServiceBaseClass)];
GVAR(GarageContextService)
