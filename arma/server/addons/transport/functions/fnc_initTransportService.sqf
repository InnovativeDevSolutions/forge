#include "..\script_component.hpp"

/*
 * File: fnc_initTransportService.sqf
 * Author: IDSolutions
 * Date: 2026-05-25
 * Public: No
 *
 * Description:
 * Initializes the server-side paid transport service for player and vehicle
 * transfers between mission-placed transport nodes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Transport service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_transport_fnc_initTransportService
 */

if !(isServer) exitWith { objNull };
if !(isNil QGVAR(TransportService)) exitWith { GVAR(TransportService) };
if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); };

#pragma hemtt ignore_variables ["_self"]
GVAR(TransportServiceBase) = compileFinal createHashMapFromArray [
    ["#type", "TransportService"],
    ["#create", compileFinal {
        _self set ["baseFare", 100];
        _self set ["pricePerKm", 50];
        _self set ["cargoRadius", 25];
        _self set ["nodePrefix", "transport"];
        _self set ["vehiclePrefix", "transport_vehicle"];
        _self set ["arrivalPrefix", "transport_arrival"];
        _self set ["maxIndexedNodes", 10];
        _self set ["eventTokens", []];
        ["INFO", "Transport Service Initialized!"] call EFUNC(common,log);
        true
    }],
    ["notify", compileFinal {
        params [["_unit", objNull, [objNull]], ["_type", "info", [""]], ["_title", "Transport", [""]], ["_message", "", [""]]];

        if (isNull _unit || { _message isEqualTo "" }) exitWith { false };

        private _uid = getPlayerUID _unit;
        if (_uid isEqualTo "") exitWith {
            [_message] remoteExecCall ["systemChat", _unit];
            true
        };

        if (isNil QEGVAR(common,EventBus)) exitWith {
            [_message] remoteExecCall ["systemChat", _unit];
            true
        };

        EGVAR(common,EventBus) call ["emit", [
            "notification.requested",
            createHashMapFromArray [
                ["uids", [_uid]],
                ["notificationType", _type],
                ["title", _title],
                ["message", _message]
            ],
            createHashMapFromArray [["source", "transport"]]
        ]];
        true
    }],
    ["emit", compileFinal {
        params [["_eventName", "", [""]], ["_payload", createHashMap, [createHashMap]]];

        if (_eventName isEqualTo "" || { isNil QEGVAR(common,EventBus) }) exitWith { createHashMap };

        EGVAR(common,EventBus) call ["emit", [
            _eventName,
            _payload,
            createHashMapFromArray [["source", "transport"]]
        ]]
    }],
    ["getIndexedNames", compileFinal {
        params [["_prefix", "", [""]], ["_maxIndex", 10, [0]]];

        private _names = [_prefix];
        for "_i" from 1 to _maxIndex do {
            _names pushBack format ["%1_%2", _prefix, _i];
        };
        _names
    }],
    ["getNodes", compileFinal {
        params [["_options", createHashMap, [createHashMap]]];

        private _nodeNames = +(_options getOrDefault ["nodeNames", []]);
        if (_nodeNames isEqualTo []) then {
            private _prefix = _options getOrDefault ["nodePrefix", _self getOrDefault ["nodePrefix", "transport"]];
            private _maxIndex = _options getOrDefault ["maxIndexedNodes", _self getOrDefault ["maxIndexedNodes", 10]];
            _nodeNames = _self call ["getIndexedNames", [_prefix, _maxIndex]];
        };

        private _nodes = _nodeNames apply { missionNamespace getVariable [_x, objNull] };
        _nodes select { !isNull _x }
    }],
    ["getExclusionObjects", compileFinal {
        params [["_options", createHashMap, [createHashMap]]];

        private _excluded = +(_options getOrDefault ["excludedObjects", []]);
        _excluded append (_self call ["getNodes", [_options]]);

        private _vehicleNames = +(_options getOrDefault ["vehicleNames", []]);
        if (_vehicleNames isEqualTo []) then {
            private _prefix = _options getOrDefault ["vehiclePrefix", _self getOrDefault ["vehiclePrefix", "transport_vehicle"]];
            private _maxIndex = _options getOrDefault ["maxIndexedNodes", _self getOrDefault ["maxIndexedNodes", 10]];
            _vehicleNames = _self call ["getIndexedNames", [_prefix, _maxIndex]];
        };

        private _vehicles = _vehicleNames apply { missionNamespace getVariable [_x, objNull] };
        _excluded append (_vehicles select { !isNull _x });
        _excluded
    }],
    ["getCost", compileFinal {
        params [["_fromNode", objNull, [objNull]], ["_toNode", objNull, [objNull]], ["_options", createHashMap, [createHashMap]]];

        private _baseFare = _options getOrDefault ["baseFare", _self getOrDefault ["baseFare", 100]];
        private _pricePerKm = _options getOrDefault ["pricePerKm", _self getOrDefault ["pricePerKm", 50]];
        private _distanceMeters = _fromNode distance2D _toNode;

        round (_baseFare + ((_distanceMeters / 1000) * _pricePerKm))
    }],
    ["getArrivalMarker", compileFinal {
        params [["_toNode", objNull, [objNull]], ["_options", createHashMap, [createHashMap]]];

        private _explicitMarker = _options getOrDefault ["arrivalMarker", ""];
        if (_explicitMarker isNotEqualTo "") exitWith { _explicitMarker };

        private _nodeName = vehicleVarName _toNode;
        private _nodePrefix = _options getOrDefault ["nodePrefix", _self getOrDefault ["nodePrefix", "transport"]];
        private _arrivalPrefix = _options getOrDefault ["arrivalPrefix", _self getOrDefault ["arrivalPrefix", "transport_arrival"]];

        if (_nodeName isEqualTo _nodePrefix) exitWith { _arrivalPrefix };

        private _prefixWithSeparator = format ["%1_", _nodePrefix];
        if ((_nodeName find _prefixWithSeparator) != 0) exitWith { "" };

        private _suffix = _nodeName select [count _prefixWithSeparator];
        if (_suffix isEqualTo "") exitWith { "" };

        format ["%1_%2", _arrivalPrefix, _suffix]
    }],
    ["getArrivalPosition", compileFinal {
        params [["_toNode", objNull, [objNull]], ["_index", -1, [0]], ["_options", createHashMap, [createHashMap]]];

        private _marker = _self call ["getArrivalMarker", [_toNode, _options]];
        private _basePos = if (_marker in allMapMarkers) then {
            getMarkerPos _marker
        } else {
            ASLToATL (_toNode modelToWorldWorld [0, -8, 1.2])
        };

        if (_index < 0) exitWith { _basePos };

        private _spacingX = _options getOrDefault ["cargoSpacingX", 5];
        private _spacingY = _options getOrDefault ["cargoSpacingY", 7];
        private _columns = _options getOrDefault ["cargoColumns", 3];
        private _xOffset = ((_index % _columns) - floor (_columns / 2)) * _spacingX;
        private _yOffset = floor (_index / _columns) * _spacingY;

        _basePos vectorAdd [_xOffset, _yOffset, 0]
    }],
    ["chargePassenger", compileFinal {
        params [["_unit", objNull, [objNull]], ["_amount", 0, [0]], ["_label", "Transport", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", format ["Unable to charge %1 fare.", _label]],
            ["source", ""]
        ];

        if (isNull _unit) exitWith { _result };
        if (_amount <= 0) exitWith {
            _result set ["success", true];
            _result set ["message", ""];
            _result
        };

        private _uid = getPlayerUID _unit;
        if (_uid isEqualTo "") exitWith {
            _result set ["message", "A valid player UID is required for transport billing."];
            _result
        };

        if !(isNil QEGVAR(bank,BankStore)) then {
            private _account = EGVAR(bank,BankStore) call ["get", [_uid, ""]];
            if (_account isEqualTo createHashMap) then {
                _account = EGVAR(bank,BankStore) call ["init", [_uid]];
            };

            if (_account isNotEqualTo createHashMap) then {
                private _source = "";
                if ((_account getOrDefault ["bank", 0]) >= _amount) then {
                    _source = "bank";
                } else {
                    if ((_account getOrDefault ["cash", 0]) >= _amount) then {
                        _source = "cash";
                    };
                };

                if (_source isNotEqualTo "") then {
                    private _charge = EGVAR(bank,BankStore) call ["chargeCheckout", [_uid, _source, _amount, true]];
                    if (_charge getOrDefault ["success", false]) exitWith {
                        EGVAR(bank,BankStore) call ["save", [_uid]];
                        _result set ["success", true];
                        _result set ["source", _source];
                        _result set ["message", format ["%1 charged $%2 from your %3.", _label, [_amount] call EFUNC(common,formatNumber), _source]];
                    };
                };
            };
        };

        if !(isNil QEGVAR(economy,SEconomyStore)) then {
            private _orgCharge = EGVAR(economy,SEconomyStore) call ["chargeOrg", [_unit, _amount, _label, true]];
            if (_orgCharge getOrDefault ["success", false]) exitWith {
                _result set ["success", true];
                _result set ["source", "org_credit"];
                _result set ["message", format [
                    "Personal funds could not cover %1. Organization charged $%2 and added it to your credit line.",
                    _label,
                    [_amount] call EFUNC(common,formatNumber)
                ]];
            };

            _result set ["message", _orgCharge getOrDefault ["message", format ["You cannot afford %1.", _label]]];
        };

        _result
    }],
    ["getNearbyCargo", compileFinal {
        params [
            ["_fromNode", objNull, [objNull]],
            ["_unit", objNull, [objNull]],
            ["_options", createHashMap, [createHashMap]]
        ];

        private _radius = _options getOrDefault ["cargoRadius", _self getOrDefault ["cargoRadius", 25]];
        if (_radius <= 0) exitWith { [] };

        private _nearby = nearestObjects [
            _fromNode,
            ["LandVehicle", "Air", "Ship", "CAManBase"],
            _radius,
            true
        ];
        private _excluded = _self call ["getExclusionObjects", [_options]];

        _nearby select {
            !isNull _x
            && { _x isNotEqualTo _fromNode }
            && { !(_x in _excluded) }
            && { _x isNotEqualTo _unit }
            && { alive _x }
            && {
                (_x isKindOf "LandVehicle")
                || { _x isKindOf "Air" }
                || { _x isKindOf "Ship" }
                || { _x isKindOf "CAManBase" && { isPlayer _x } }
            }
        }
    }],
    ["moveCargo", compileFinal {
        params [["_cargo", [], [[]]], ["_toNode", objNull, [objNull]], ["_options", createHashMap, [createHashMap]]];

        private _moved = [];
        {
            private _entity = _x;
            if (isNull _entity) then { continue; };

            private _pos = _self call ["getArrivalPosition", [_toNode, _forEachIndex, _options]];
            if (_entity isKindOf "CAManBase") then {
                [_entity, _pos] remoteExecCall ["setPosATL", _entity];
            } else {
                _entity setPosATL _pos;
                _entity setDir (getDir _toNode);
            };

            _moved pushBack _entity;
        } forEach _cargo;

        _moved
    }],
    ["requestTransport", compileFinal {
        params [
            ["_unit", objNull, [objNull]],
            ["_fromNode", objNull, [objNull]],
            ["_toNode", objNull, [objNull]],
            ["_options", createHashMap, [createHashMap]]
        ];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Transport request failed."],
            ["cost", 0],
            ["movedCargo", []]
        ];

        if (isNull _unit || { !isPlayer _unit }) exitWith { _result };
        if (isNull _fromNode || { isNull _toNode }) exitWith { _result };
        if (_fromNode isEqualTo _toNode) exitWith {
            _result set ["message", "Origin and destination are the same."];
            _result
        };

        private _nodes = _self call ["getNodes", [_options]];
        if !(_fromNode in _nodes && { _toNode in _nodes }) exitWith {
            _result set ["message", "Transport route is unavailable."];
            _result
        };

        private _label = _options getOrDefault ["label", "Transport"];
        private _cost = _self call ["getCost", [_fromNode, _toNode, _options]];
        _result set ["cost", _cost];

        _self call ["emit", [
            "transport.requested",
            createHashMapFromArray [
                ["unit", _unit],
                ["uid", getPlayerUID _unit],
                ["from", _fromNode],
                ["to", _toNode],
                ["cost", _cost],
                ["label", _label]
            ]
        ]];

        private _charge = _self call ["chargePassenger", [_unit, _cost, _label]];
        if !(_charge getOrDefault ["success", false]) exitWith {
            private _message = _charge getOrDefault ["message", "Transport payment failed."];
            _result set ["message", _message];
            _self call ["notify", [_unit, "danger", _label, _message]];
            _self call ["emit", ["transport.failed", +_result]];
            _result
        };

        private _cargo = if (_options getOrDefault ["includeCargo", true]) then {
            _self call ["getNearbyCargo", [_fromNode, _unit, _options]]
        } else {
            []
        };
        private _destination = _self call ["getArrivalPosition", [_toNode, -1, _options]];
        private _movedCargo = _self call ["moveCargo", [_cargo, _toNode, _options]];

        [_unit, _destination] remoteExecCall ["setPosATL", _unit];
        _self call ["notify", [_unit, "info", _label, _charge getOrDefault ["message", format ["%1 paid.", _label]]]];

        if (_movedCargo isNotEqualTo []) then {
            _self call ["notify", [_unit, "info", _label, format ["Moved %1 nearby passenger/vehicle item(s).", count _movedCargo]]];
        };

        _result set ["success", true];
        _result set ["message", "Transport completed."];
        _result set ["movedCargo", _movedCargo];
        _result set ["paymentSource", _charge getOrDefault ["source", ""]];

        _self call ["emit", ["transport.completed", +_result]];
        _result
    }],
    ["registerEventHandlers", compileFinal {
        if (isNil QEGVAR(common,EventBus)) exitWith { false };
        if ((_self getOrDefault ["eventTokens", []]) isNotEqualTo []) exitWith { true };

        private _handleRequest = {
            params ["_event"];

            private _unit = _event getOrDefault ["unit", objNull];
            private _from = _event getOrDefault ["from", objNull];
            private _to = _event getOrDefault ["to", objNull];
            private _options = _event getOrDefault ["options", createHashMap];

            if (isNil QGVAR(TransportService)) exitWith {};
            GVAR(TransportService) call ["requestTransport", [_unit, _from, _to, _options]];
        };

        _self set ["eventTokens", [
            EGVAR(common,EventBus) call ["on", ["transport.request", _handleRequest, "transport.request"]]
        ]];
        true
    }],
    ["#delete", compileFinal {
        if !(isNil QEGVAR(common,EventBus)) then {
            {
                EGVAR(common,EventBus) call ["off", [_x]];
            } forEach (_self getOrDefault ["eventTokens", []]);
        };
        _self set ["eventTokens", []];
    }]
];

GVAR(TransportService) = createHashMapObject [GVAR(TransportServiceBase), []];
GVAR(TransportService) call ["registerEventHandlers", []];

GVAR(TransportService)
