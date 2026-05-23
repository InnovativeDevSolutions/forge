#include "..\script_component.hpp"

/*
 * File: fnc_initHelperService.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the garage helper service for vehicle metadata and UI-friendly shaping.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Garage helper service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_garage_fnc_initHelperService;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(GarageHelperServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "GarageHelperServiceBaseClass"],
    ["normalizeGarageCategory", compileFinal {
        params [["_value", "", [""]]];

        private _normalized = toLowerANSI (trim _value);
        if (_normalized isEqualTo "") exitWith { "" };
        if (_normalized in ["cars", "armor", "helis", "planes", "naval", "other"]) exitWith { _normalized };
        ""
    }],
    ["inferGarageCategory", compileFinal {
        params [["_value", "", [""]]];

        private _normalized = toLowerANSI (trim _value);
        if (_normalized isEqualTo "") exitWith { "" };

        private _resolvedCategory = _self call ["normalizeGarageCategory", [_normalized]];
        if (_resolvedCategory isNotEqualTo "") exitWith { _resolvedCategory };

        switch (true) do {
            case ((_normalized find "cars") >= 0): { "cars" };
            case ((_normalized find "armor") >= 0): { "armor" };
            case ((_normalized find "helis") >= 0): { "helis" };
            case ((_normalized find "planes") >= 0): { "planes" };
            case ((_normalized find "naval") >= 0): { "naval" };
            case ((_normalized find "other") >= 0): { "other" };
            default { "" };
        }
    }],
    ["resolveCategory", compileFinal {
        params [["_className", "", [""]]];

        if (_className isEqualTo "") exitWith { "other" };

        switch (true) do {
            case (_className isKindOf ["Car", configFile >> "CfgVehicles"]): { "car" };
            case (_className isKindOf ["Tank", configFile >> "CfgVehicles"]): { "armor" };
            case (_className isKindOf ["Helicopter", configFile >> "CfgVehicles"]): { "air" };
            case (_className isKindOf ["Plane", configFile >> "CfgVehicles"]): { "air" };
            case (_className isKindOf ["Ship", configFile >> "CfgVehicles"]): { "naval" };
            default { "other" };
        }
    }],
    ["resolveVGCategory", compileFinal {
        params [["_className", "", [""]]];

        if (_className isEqualTo "") exitWith { "other" };

        switch (true) do {
            case (_className isKindOf ["Car", configFile >> "CfgVehicles"]): { "cars" };
            case (_className isKindOf ["Tank", configFile >> "CfgVehicles"]): { "armor" };
            case (_className isKindOf ["Helicopter", configFile >> "CfgVehicles"]): { "helis" };
            case (_className isKindOf ["Plane", configFile >> "CfgVehicles"]): { "planes" };
            case (_className isKindOf ["Ship", configFile >> "CfgVehicles"]): { "naval" };
            default { "other" };
        }
    }],
    ["resolveGarageCategoryLabel", compileFinal {
        params [["_category", "", [""]]];

        switch (_category) do {
            case "cars": { "cars" };
            case "armor": { "armored vehicles" };
            case "helis": { "helicopters" };
            case "planes": { "planes" };
            case "naval": { "naval vehicles" };
            case "other": { "other vehicles" };
            default { "this vehicle type" };
        }
    }],
    ["resolveDisplayName", compileFinal {
        params [["_className", "", [""]]];

        private _displayName = getText (configFile >> "CfgVehicles" >> _className >> "displayName");
        if (_displayName isEqualTo "") then {
            _displayName = _className;
        };

        _displayName
    }],
    ["resolvePicture", compileFinal {
        params [["_className", "", [""]]];

        private _picture = getText (configFile >> "CfgVehicles" >> _className >> "editorPreview");
        if (_picture isEqualTo "") then {
            _picture = getText (configFile >> "CfgVehicles" >> _className >> "picture");
        };

        _picture
    }],
    ["buildHitPointRows", compileFinal {
        params [["_hitPoints", createHashMap, [createHashMap]]];

        private _rows = [];
        private _names = _hitPoints getOrDefault ["names", []];
        private _selections = _hitPoints getOrDefault ["selections", []];
        private _values = _hitPoints getOrDefault ["values", []];
        private _count = count _names;

        for "_index" from 0 to (_count - 1) do {
            private _rowName = _names param [_index, ""];
            _rows pushBack (createHashMapFromArray [
                ["name", _rowName],
                ["selection", _selections param [_index, ""]],
                ["value", _values param [_index, 0]]
            ]);
        };

        _rows
    }],
    ["resolveHealth", compileFinal {
        params [["_damage", 0, [0]], ["_hitPointRows", [], [[]]]];

        private _worstHitPoint = 0;
        {
            private _value = _x getOrDefault ["value", 0];
            if (_value > _worstHitPoint) then {
                _worstHitPoint = _value;
            };
        } forEach _hitPointRows;

        1 - ((_damage max _worstHitPoint) min 1)
    }],
    ["buildStoredVehicle", compileFinal {
        params [["_plate", "", [""]], ["_vehicleData", createHashMap, [createHashMap]]];

        private _className = _vehicleData getOrDefault ["classname", ""];
        private _damage = _vehicleData getOrDefault ["damage", 0];
        private _fuel = _vehicleData getOrDefault ["fuel", 0];
        private _hitPoints = _vehicleData getOrDefault ["hit_points", createHashMap];
        private _hitPointRows = _self call ["buildHitPointRows", [_hitPoints]];

        createHashMapFromArray [
            ["entryKind", "stored"],
            ["plate", _plate],
            ["classname", _className],
            ["displayName", _self call ["resolveDisplayName", [_className]]],
            ["picture", _self call ["resolvePicture", [_className]]],
            ["category", _self call ["resolveCategory", [_className]]],
            ["damage", _damage],
            ["fuel", _fuel],
            ["health", _self call ["resolveHealth", [_damage, _hitPointRows]]],
            ["hitPoints", _hitPointRows]
        ]
    }],
    ["buildNearbyVehicle", compileFinal {
        params [
            ["_vehicle", objNull, [objNull]],
            ["_origin", [], [[]]]
        ];

        if (isNull _vehicle) exitWith { createHashMap };

        private _className = typeOf _vehicle;
        private _rawHitPoints = getAllHitPointsDamage _vehicle;
        private _hitPointRows = [];
        if (_rawHitPoints isEqualType [] && { count _rawHitPoints >= 3 }) then {
            private _names = _rawHitPoints param [0, []];
            private _selections = _rawHitPoints param [1, []];
            private _values = _rawHitPoints param [2, []];
            private _count = count _names;

            for "_index" from 0 to (_count - 1) do {
                _hitPointRows pushBack (createHashMapFromArray [
                    ["name", _names param [_index, ""]],
                    ["selection", _selections param [_index, ""]],
                    ["value", _values param [_index, 0]]
                ]);
            };
        };

        private _damage = damage _vehicle;
        private _distance = if (_origin isEqualType [] && { count _origin >= 2 }) then {
            _vehicle distance2D _origin
        } else {
            _vehicle distance2D player
        };
        private _ownerUid = _vehicle getVariable ["forge_garage_owner_uid", ""];
        private _plate = _vehicle getVariable ["forge_garage_plate", ""];

        createHashMapFromArray [
            ["entryKind", "nearby"],
            ["netId", netId _vehicle],
            ["plate", _plate],
            ["classname", _className],
            ["displayName", _self call ["resolveDisplayName", [_className]]],
            ["picture", _self call ["resolvePicture", [_className]]],
            ["category", _self call ["resolveCategory", [_className]]],
            ["damage", _damage],
            ["fuel", fuel _vehicle],
            ["health", _self call ["resolveHealth", [_damage, _hitPointRows]]],
            ["hitPoints", _hitPointRows],
            ["distance", _distance],
            ["ownerUid", _ownerUid],
            ["isEmpty", crew _vehicle isEqualTo []]
        ]
    }]
];

GVAR(GarageHelperService) = createHashMapObject [GVAR(GarageHelperServiceBaseClass)];
GVAR(GarageHelperService)
