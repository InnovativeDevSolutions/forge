#include "..\script_component.hpp"

/*
 * File: fnc_initRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the actor repository for managing player actor data.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Actor repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_actor_fnc_initRepository;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(ActorRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "ActorRepositoryBaseClass"],
    ["#create", compileFinal {
        _self set ["uid", getPlayerUID player];
        _self set ["actor", createHashMap];
        _self set ["isLoaded", false];
        _self set ["lastSave", time];
    }],
    ["init", compileFinal {
        private _uid = _self get "uid";
        [SRPC(actor,requestInitActor), [_uid]] call CFUNC(serverEvent);
        _self set ["lastSave", time];

        systemChat format ["Loading actor for %1", name player];
        diag_log "[FORGE:Client:Actor] Actor Repository Initialized!";
    }],
    ["save", compileFinal {
        params [["_sync", false, [false]]];

        private _uid = _self get "uid";
        [SRPC(actor,requestSaveActor), [_uid, _sync]] call CFUNC(serverEvent);

        _self set ["lastSave", time];
    }],
    ["sync", compileFinal {
        params [["_data", createHashMap, [createHashMap]], ["_jip", false, [false]]];

        private _actor = _self get "actor";
        private _isLoaded = _self get "isLoaded";

        {
            _actor set [_x, _y];

            if (_jip) then {
                switch (_x) do {
                    case "position": { _self call ["applyPosition"]; };
                    case "direction": { _self call ["applyDirection"]; };
                    case "stance": { _self call ["applyStance"]; };
                    case "rank": { _self call ["applyRank"]; };
                    case "loadout": { _self call ["applyLoadout"]; };
                    default {};
                };
            };
        } forEach _data;

        _self set ["actor", _actor];
        SETPVAR(player,FORGE_isLoaded,true);
        if !(_isLoaded) then { _self set ["isLoaded", true]; };
        diag_log "[FORGE:Client:Actor] Sync completed";
    }],
    ["get", compileFinal {
        params [["_key", "", [""]], ["_default", nil, [[], "", 0, false, createHashMap]]];
        private _actor = _self get "actor";
        _actor getOrDefault [_key, _default];
    }],
    ["applyPosition", compileFinal {
        private _position = _self call ["get", ["position", [0, 0, 0]]];
        if (GVAR(enableLoc)) then {
            player setPosASL _position;
            private _pAlt = ((getPosATLVisual player) select 2);
            private _pVelZ = ((velocity player) select 2);
            if (_pAlt > 5 && _pVelZ < 0) then {
                player setVelocity [0, 0, 0];
                player setPosATL [((getPosATLVisual player) select 0), ((getPosATLVisual player) select 1), 1];
                hint "You logged off mid air. You were moved to a safe position on the ground";
            };
        };
    }],
    ["applyDirection", compileFinal {
        private _direction = _self call ["get", ["direction", 0]];
        if (GVAR(enableLoc)) then { player setDir _direction; };
    }],
    ["applyStance", compileFinal {
        private _stance = _self call ["get", ["stance", "STAND"]];
        if (GVAR(enableLoc)) then { player playAction _stance; };
    }],
    ["applyRank", compileFinal {
        private _rank = _self call ["get", ["rank", "PRIVATE"]];
        player setUnitRank _rank;
    }],
    ["applyLoadout", compileFinal {
        private _loadout = _self call ["get", ["loadout", []]];
        if (GVAR(enableGear) && count _loadout > 0) then { player setUnitLoadout _loadout; };
    }],
    ["getNearbyActions", compileFinal {
        params [["_control", controlNull, [controlNull]]];
        private _nearbyActions = [];
        {
            private _isAtm = _x getVariable ["isAtm", false];
            private _isBank = _x getVariable ["isBank", false];
            private _isGarage = _x getVariable ["isGarage", false];
            private _isLocker = _x getVariable ["isLocker", false];
            private _isStore = _x getVariable ["isStore", false];
            private _garageType = _x getVariable ["garageType", ""];
            private _garageContext = createHashMapFromArray [
                ["netId", netId _x],
                ["name", vehicleVarName _x],
                ["garageType", _garageType]
            ];
            private _deviceType = _x getVariable ["deviceType", ""];
            private _isPlayer = _x isKindOf "Man" && isPlayer _x;
            private _objectName = vehicleVarName _x;
            private _transportPrefix = _x getVariable ["transportNodePrefix", "transport"];
            private _isTransport = _x getVariable ["isTransport", false];
            if (!_isTransport && { _objectName isNotEqualTo "" }) then {
                _isTransport = _objectName isEqualTo _transportPrefix || { (_objectName find format ["%1_", _transportPrefix]) == 0 };
            };

            if (_isStore) then { _nearbyActions pushBack ["store", true]; };
            if (_isAtm) then { _nearbyActions pushBack ["atm", true]; };
            if (_isBank) then { _nearbyActions pushBack ["bank", true]; };
            if (_isLocker && GVAR(enableVA)) then { _nearbyActions pushBack ["va", true]; };
            if (_isGarage) then { _nearbyActions pushBack ["garage", _garageContext]; };
            if (_isGarage && GVAR(enableVG)) then { _nearbyActions pushBack ["vg", _garageContext]; };
            if (_deviceType isNotEqualTo "") then { _nearbyActions pushBack ["device", _deviceType]; };
            if (_isTransport) then {
                private _fromTransportNode = _x;
                private _maxIndexedNodes = _x getVariable ["transportMaxIndexedNodes", 10];
                private _baseFare = _x getVariable ["transportBaseFare", 100];
                private _pricePerKm = _x getVariable ["transportPricePerKm", 50];
                private _vehiclePrefix = _x getVariable ["transportVehiclePrefix", format ["%1_vehicle", _transportPrefix]];
                private _arrivalPrefix = _x getVariable ["transportArrivalPrefix", format ["%1_arrival", _transportPrefix]];
                private _nodeNames = [_transportPrefix];

                for "_i" from 1 to _maxIndexedNodes do {
                    _nodeNames pushBack format ["%1_%2", _transportPrefix, _i];
                };

                private _destinations = [];
                {
                    private _node = missionNamespace getVariable [_x, objNull];
                    if (!isNull _node && { _node isNotEqualTo _fromTransportNode }) then {
                        private _nodeLabel = _node getVariable ["transportLabel", vehicleVarName _node];
                        if (_nodeLabel isEqualTo "") then { _nodeLabel = "Transport Point"; };

                        private _distanceMeters = _fromTransportNode distance2D _node;
                        private _cost = round (_baseFare + ((_distanceMeters / 1000) * _pricePerKm));
                        _destinations pushBack createHashMapFromArray [
                            ["netId", netId _node],
                            ["name", vehicleVarName _node],
                            ["label", _nodeLabel],
                            ["cost", _cost]
                        ];
                    };
                } forEach _nodeNames;

                if (_destinations isNotEqualTo []) then {
                    private _transportContext = createHashMapFromArray [
                        ["netId", netId _x],
                        ["name", _objectName],
                        ["label", _x getVariable ["transportLabel", "Transport"]],
                        ["nodePrefix", _transportPrefix],
                        ["vehiclePrefix", _vehiclePrefix],
                        ["arrivalPrefix", _arrivalPrefix],
                        ["maxIndexedNodes", _maxIndexedNodes],
                        ["baseFare", _baseFare],
                        ["pricePerKm", _pricePerKm],
                        ["cargoRadius", _x getVariable ["transportCargoRadius", 25]],
                        ["includeCargo", _x getVariable ["transportIncludeCargo", true]],
                        ["destinations", _destinations]
                    ];
                    _nearbyActions pushBack ["transport", _transportContext];
                };
            };
            if (_isPlayer && { _x isNotEqualTo player }) then { _nearbyActions pushBack ["player", name _x]; };
        } forEach (player nearObjects 5);

        _control ctrlWebBrowserAction ["ExecJS", format ["updateAvailableActions(%1)", (toJSON _nearbyActions)]];
    }]
];

GVAR(ActorRepository) = createHashMapObject [GVAR(ActorRepositoryBaseClass)];
GVAR(ActorRepository)
