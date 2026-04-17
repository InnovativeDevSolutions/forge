#include "..\script_component.hpp"

/*
 * File: fnc_initFEconomyStore.sqf
 * Author: IDSolutions
 * Date: 2025-12-20
 * Last Update: 2026-05-15
 * Public: No
 *
 * Description:
 *     Initializes the fuel economy store. Active refueling sessions remain
 *     server-local; payment is routed through the organization extension hot
 *     cache. Garage service refuels use the same organization billing path
 *     and only fill the vehicle after the charge succeeds.
 *
 * Parameter(s):
 *     N/A
 *
 * Returns:
 *     Fuel economy store object [HASHMAP OBJECT]
 *
 * Example(s):
 *     call forge_server_economy_fnc_initFEconomyStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(FEconomyStore) = createHashMapObject [[
    ["#type", "IFuelEconomy"],
    ["#create", {
        GVAR(FuelCost) = 5;
        _self set ["fuelRegistry", createHashMap];

        ["INFO", "Fuel Store Initialized!", nil, nil] call EFUNC(common,log);
    }],
    ["start", {
        params ["_source", "_target", "_unit"];

        private _index = netId _target;
        private _uid = getPlayerUID _unit;
        private _fuelRegistry = _self getOrDefault ["fuelRegistry", createHashMap];

        _fuelRegistry set [_index, createHashMapFromArray [
            ["uid", _uid],
            ["initialFuel", fuel _target]
        ]];
        SETVAR(_target,liters,0);
    }],
    ["rollbackFuel", {
        params [["_target", objNull, [objNull]], ["_initialFuel", 0, [0]]];

        if (isNull _target) exitWith { false };

        _target setFuel (_initialFuel max 0 min 1);
        SETVAR(_target,liters,0);
        true
    }],
    ["notify", {
        params [["_unit", objNull, [objNull]], ["_type", "info", [""]], ["_title", "Refueling", [""]], ["_message", "", [""]]];

        if (isNull _unit || { _message isEqualTo "" }) exitWith { false };

        private _uid = getPlayerUID _unit;
        if (_uid isEqualTo "") exitWith { false };
        if (isNil QEGVAR(common,EventBus)) then {
            [CRPC(notifications,recieveNotification), [_type, _title, _message], _unit] call CFUNC(targetEvent);
        } else {
            EGVAR(common,EventBus) call ["emit", [
                "notification.requested",
                createHashMapFromArray [
                    ["uids", [_uid]],
                    ["notificationType", _type],
                    ["title", _title],
                    ["message", _message]
                ],
                createHashMapFromArray [["source", "economy"]]
            ]];
        };

        true
    }],
    ["refuel", {
        params [["_target", objNull, [objNull]], ["_unit", objNull, [objNull]]];

        if (isNull _target || { isNull _unit }) exitWith { false };

        private _currentFuel = fuel _target;
        private _missingFuel = (1 - _currentFuel) max 0 min 1;
        if (_missingFuel <= 0.001) exitWith {
            _self call ["notify", [_unit, "info", "Refueling", "Vehicle fuel tank is already full."]];
            false
        };

        if (isNil QGVAR(SEconomyStore)) exitWith {
            ["ERROR", "Service economy store unavailable for garage refueling charge.", nil, nil] call EFUNC(common,log);
            _self call ["notify", [_unit, "danger", "Refueling", "Organization billing is unavailable. Refueling was not completed."]];
            false
        };

        private _fuelCapacity = getNumber (configOf _target >> "fuelCapacity");
        if (_fuelCapacity <= 0) then { _fuelCapacity = 100; };

        private _totalLiters = _missingFuel * _fuelCapacity;
        private _totalCost = _totalLiters * GVAR(FuelCost);
        private _chargeResult = GVAR(SEconomyStore) call ["chargeOrg", [_unit, _totalCost, "Refueling"]];
        if !(_chargeResult getOrDefault ["success", false]) exitWith {
            _self call ["notify", [_unit, "danger", "Refueling", _chargeResult getOrDefault ["message", "Organization funds cannot cover this refuel. Refueling was not completed."]]];
            false
        };

        _target setFuel 1;
        SETVAR(_target,liters,0);

        private _formattedTotalCost = [_totalCost] call EFUNC(common,formatNumber);
        private _formattedTotalLiters = _totalLiters toFixed 2;
        _self call ["notify", [_unit, "info", "Refueling", format ["Refueling complete: %1L<br />Organization charged $%2.", _formattedTotalLiters, _formattedTotalCost]]];
        true
    }],
    ["stop", {
        params ["_source", "_target"];

        private _index = netId _target;
        private _fuelRegistry = _self getOrDefault ["fuelRegistry", createHashMap];
        private _session = _fuelRegistry getOrDefault [_index, createHashMap];
        if (_session isEqualType "") then {
            _session = createHashMapFromArray [["uid", _session], ["initialFuel", fuel _target]];
        };

        private _uid = _session getOrDefault ["uid", ""];
        private _initialFuel = _session getOrDefault ["initialFuel", fuel _target];
        private _player = [_uid] call EFUNC(common,getPlayer);

        private _totalLiters = GETVAR(_target,liters,0);
        private _totalCost = _totalLiters * GVAR(FuelCost);
        private _formattedTotalCost = [_totalCost] call EFUNC(common,formatNumber);
        private _formattedTotalLiters = _totalLiters toFixed 2;

        if (isNull _player || { _uid isEqualTo "" }) exitWith {
            ["WARNING", format ["Unable to resolve refueling player for vehicle %1.", _index], nil, nil] call EFUNC(common,log);
            _self call ["rollbackFuel", [_target, _initialFuel]];
            _fuelRegistry deleteAt _index;
        };

        if (_totalCost <= 0) exitWith {
            _self call ["notify", [_player, "info", "Refueling", format ["Refueling complete: %1L", _formattedTotalLiters]]];
            _fuelRegistry deleteAt _index;
        };

        if (isNil QGVAR(SEconomyStore)) exitWith {
            ["ERROR", "Service economy store unavailable for refueling charge.", nil, nil] call EFUNC(common,log);
            _self call ["notify", [_player, "danger", "Refueling", "Organization billing is unavailable. Refueling was not completed."]];
            _self call ["rollbackFuel", [_target, _initialFuel]];
            _fuelRegistry deleteAt _index;
        };

        private _chargeResult = GVAR(SEconomyStore) call ["chargeOrg", [_player, _totalCost, "Refueling"]];
        if !(_chargeResult getOrDefault ["success", false]) exitWith {
            _self call ["notify", [_player, "danger", "Refueling", _chargeResult getOrDefault ["message", "Organization funds cannot cover this refuel. Refueling was not completed."]]];
            _self call ["rollbackFuel", [_target, _initialFuel]];
            _fuelRegistry deleteAt _index;
        };

        _self call ["notify", [_player, "info", "Refueling", format ["Refueling complete: %1L<br />Organization charged $%2.", _formattedTotalLiters, _formattedTotalCost]]];
        _fuelRegistry deleteAt _index;
    }]
]];

SETMVAR(FORGE_FEconomyStore,GVAR(FEconomyStore));
GVAR(FEconomyStore)
