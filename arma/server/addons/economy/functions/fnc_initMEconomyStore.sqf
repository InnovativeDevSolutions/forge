#include "..\script_component.hpp"

/*
 * File: fnc_initMEconomyStore.sqf
 * Author: IDSolutions
 * Date: 2025-12-20
 * Last Update: 2026-05-15
 * Public: No
 *
 * Description:
 *     Initializes the medical economy store. Respawn, body-bag, and spawn
 *     occupancy behavior remains server-local, while money mutations are
 *     routed through player bank hot state first, then organization hot state
 *     with a repayable member debt when personal funds cannot cover the bill.
 *
 * Parameter(s):
 *     N/A
 *
 * Returns:
 *     Medical economy store object [HASHMAP OBJECT]
 *
 * Example(s):
 *     call forge_server_economy_fnc_initMEconomyStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(MEconomyStore) = createHashMapObject [[
    ["#type", "IMedEconomy"],
    ["#create", {
        _self set ["mSpawns", createHashMap];

        GVAR(occupancyTriggers) = [];
        ["INFO", "Medical Store Initialized!", nil, nil] call EFUNC(common,log);
    }],
    ["init", {
        private _mSpawns = (_self get "mSpawns");
        private _prefix = "med_spawn";

        for "_i" from 0 to 10 do {
            private _var = if (_i == 0) then { _prefix } else { format ["%1_%2", _prefix, _i] };
            private _obj = missionNamespace getVariable [_var, objNull];

            if (!isNull _obj) then {
                _mSpawns set [_var, [_obj, (getPos _obj)]];
            };
        };

        if (_mSpawns isEqualTo createHashMap) then {
            ["WARNING", "No medical spawns found in the world.", nil, nil] call EFUNC(common,log);
        } else {
            {
                _y params ["_obj", "_pos"];
                private _trigger = createTrigger ["EmptyDetector", _pos];

                _trigger setVariable ["isOccupied", false, true];
                _trigger setVariable ["linkedObject", _obj, true];
                _trigger setTriggerArea [5, 5, 0, true, 5];
                _trigger setTriggerActivation ["ANYPLAYER", "PRESENT", true];
                _trigger setTriggerStatements [
                    "{ (_x isKindOf 'CAManBase') && _x distance thisTrigger < 0.5 } count thisList > 0",
                    "thisTrigger setVariable ['isOccupied', true, true];",
                    "thisTrigger setVariable ['isOccupied', false, true];"
                ];

                GVAR(occupancyTriggers) pushBack _trigger;
            } forEach _mSpawns;
        };
    }],
    ["notify", {
        params [["_unit", objNull, [objNull]], ["_type", "info", [""]], ["_title", "Medical Billing", [""]], ["_message", "", [""]]];

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
    ["chargePlayer", {
        params [["_uid", "", [""]], ["_amount", 0, [0]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["fallbackEligible", false],
            ["source", ""],
            ["message", "Unable to charge personal funds."]
        ];

        if (_uid isEqualTo "") exitWith {
            _result set ["message", "A valid player UID is required for medical billing."];
            _result
        };
        if (_amount <= 0) exitWith {
            _result set ["success", true];
            _result
        };
        if (isNil QEGVAR(bank,BankStore)) exitWith {
            _result set ["message", "Personal billing is unavailable. Medical service cannot complete."];
            _result
        };

        private _account = EGVAR(bank,BankStore) call ["get", [_uid, ""]];
        if (_account isEqualTo createHashMap) exitWith {
            _result set ["message", "Personal account could not be loaded for medical billing."];
            _result
        };

        private _source = "";
        if ((_account getOrDefault ["bank", 0]) >= _amount) then {
            _source = "bank";
        } else {
            if ((_account getOrDefault ["cash", 0]) >= _amount) then {
                _source = "cash";
            };
        };

        if (_source isEqualTo "") exitWith {
            _result set ["fallbackEligible", true];
            _result set ["message", "Personal bank and cash balances cannot cover this medical service."];
            _result
        };

        private _charge = EGVAR(bank,BankStore) call ["chargeCheckout", [_uid, _source, _amount, true]];
        if !(_charge getOrDefault ["success", false]) exitWith {
            _result set ["message", _charge getOrDefault ["message", "Personal funds could not be charged for medical service."]];
            _result
        };

        private _patch = _charge getOrDefault ["patch", createHashMap];
        if (_patch isNotEqualTo createHashMap && { !(isNil QEGVAR(bank,BankMessenger)) }) then {
            if (isNil QEGVAR(common,EventBus)) then {
                EGVAR(bank,BankMessenger) call ["sendAccountSync", [_uid, _patch]];
            } else {
                EGVAR(common,EventBus) call ["emit", [
                    "bank.account.sync.requested",
                    createHashMapFromArray [
                        ["uid", _uid],
                        ["account", +_patch]
                    ],
                    createHashMapFromArray [["source", "economy"]]
                ]];
            };
        };

        private _savedAccount = EGVAR(bank,BankStore) call ["save", [_uid]];
        if (_savedAccount isEqualTo createHashMap) then {
            ["ERROR", format ["Medical charge for %1 succeeded in hot bank state, but durable bank save failed.", _uid]] call EFUNC(common,log);
        };

        _result set ["success", true];
        _result set ["source", _source];
        _result set ["message", ""];
        _result
    }],
    ["onHealed", {
        params [["_unit", objNull, [objNull]]];

        if (isNull _unit) exitWith { ["WARNING", format ["Invalid unit provided: %1", (name _unit)], nil, nil] call EFUNC(common,log); };

        private _uid = getPlayerUID _unit;
        if (_uid isEqualTo "") exitWith { ["WARNING", "Unable to charge medical service for unit without UID.", nil, nil] call EFUNC(common,log); };

        private _healCost = 100;

        private _personalCharge = _self call ["chargePlayer", [_uid, _healCost]];
        if (_personalCharge getOrDefault ["success", false]) exitWith {
            private _sourceLabel = ["cash", "bank"] select ((_personalCharge getOrDefault ["source", "bank"]) isEqualTo "bank");
            _self call ["notify", [_unit, "info", "Medical Billing", format ["Medical service charged $%1 from your %2.", [_healCost] call EFUNC(common,formatNumber), _sourceLabel]]];
            [CRPC(actor,onActorHealed), [], _unit] call CFUNC(targetEvent);
        };

        if !(_personalCharge getOrDefault ["fallbackEligible", false]) exitWith {
            private _message = _personalCharge getOrDefault ["message", "Personal funds could not be charged for medical service."];
            _self call ["notify", [_unit, "danger", "Medical Billing", _message]];
        };

        if (isNil QGVAR(SEconomyStore)) exitWith {
            ["ERROR", "Service economy store unavailable for medical organization fallback charge.", nil, nil] call EFUNC(common,log);
            _self call ["notify", [_unit, "danger", "Medical Billing", "Organization billing is unavailable. Medical service cannot complete."]];
        };

        private _chargeResult = GVAR(SEconomyStore) call ["chargeOrg", [_unit, _healCost, "Medical", true]];
        if !(_chargeResult getOrDefault ["success", false]) exitWith {
            private _message = _chargeResult getOrDefault ["message", "Organization funds cannot cover this medical service."];
            _self call ["notify", [_unit, "danger", "Medical Billing", _message]];
        };

        _self call ["notify", [_unit, "info", "Medical Billing", format ["Personal funds could not cover medical service. Organization charged $%1; repay it through your organization credit line.", [_healCost] call EFUNC(common,formatNumber)]]];
        [CRPC(actor,onActorHealed), [], _unit] call CFUNC(targetEvent);
    }],
    ["onRespawn", {
        params [["_unit", objNull, [objNull]], ["_corpse", objNull, [objNull]], ["_uid", "", [""]]];

        private _loadout = [[], [], [], ["U_BG_Guerrilla_6_1", []], [], [], "", "", [], ["", "", "", "", "", ""]];
        private _medSpawn = (GVAR(occupancyTriggers) select { !(GETVAR(_x,isOccupied,false)) }) param [0, objNull];
        private _medSpawnObj = _medSpawn getVariable ["linkedObject", objNull];
        private _medSpawnPos = (getPosATL _medSpawnObj) vectorAdd [0.05, -0.125, 0.45];
        private _medSpawnDir = getDir _medSpawnObj;

        deleteVehicle _corpse;

        private _player = [_uid] call EFUNC(common,getPlayer);
        [CRPC(actor,onActorRespawn), [_loadout, _medSpawnPos, _medSpawnDir], _player] call CFUNC(targetEvent);
    }],
    ["onKilled", {
        params [["_unit", objNull, [objNull]]];

        private _unitPos = getPosATL _unit;
        private _bodyBag = createVehicle ["forge_bodyBag", _unitPos, [], 0, "NONE"];

        _self call ["saveWeapons", [_unit]];
        _self call ["moveInventory", [_unit, _bodyBag]];
    }],
    ["saveWeapons", {
        params [["_unit", objNull, [objNull]]];

        private _droppedWeapons = [];
        private _droppedItems = [];

        _droppedWeapons pushBack (primaryWeapon _unit);
        _droppedItems append (primaryWeaponItems _unit);
        _droppedItems append (primaryWeaponMagazine _unit);
        _droppedWeapons pushBack (secondaryWeapon _unit);
        _droppedItems append (secondaryWeaponItems _unit);
        _droppedItems append (secondaryWeaponMagazine _unit);

        if (isPlayer _unit) then { _droppedItems pushBack (goggles _unit); };
        if (currentWeapon _unit isEqualTo handgunWeapon _unit) then {
            _droppedWeapons pushBack (handgunWeapon _unit);
            _droppedItems append (handgunItems _unit);
            _droppedItems append (handgunMagazine _unit);
        };

        _unit setVariable [QGVAR(droppedWeapons), _droppedWeapons, true];
        _unit setVariable [QGVAR(droppedItems), _droppedItems, true];
    }],
    ["moveInventory", {
        params [["_unit", objNull, [objNull]], ["_bodyBag", objNull, [objNull]]];

        private _items = [];
        private _weapons = [];
        private _backpack = backpack _unit;
        private _nearHolders = _bodyBag nearObjects ["WeaponHolderSimulated", 3];

        _items pushBack (headgear _unit);
        _items pushBack (uniform _unit);
        _items append (uniformItems _unit);
        _items pushBack (vest _unit);
        _items append (vestItems _unit);
        _items append (backpackItems _unit);
        _weapons pushBack (primaryWeapon _unit);
        _items append (primaryWeaponItems _unit);
        _items append (primaryWeaponMagazine _unit);
        _weapons pushBack (secondaryWeapon _unit);
        _items append (secondaryWeaponItems _unit);
        _items append (secondaryWeaponMagazine _unit);
        _weapons pushBack (handgunWeapon _unit);
        _items append (handgunItems _unit);
        _items append (handgunMagazine _unit);
        _weapons append (_unit getVariable [QGVAR(droppedWeapons), []]);
        _items append (_unit getVariable [QGVAR(droppedItems), []]);
        _items append (assignedItems _unit);
        _items pushBack (_unit call CFUNC(binocularMagazine));

        if !((goggles _unit ) in (_unit getVariable [QGVAR(droppedItems), []])) then { _items pushBack (goggles _unit); };

        _items = _items select { _x isNotEqualTo "" };
        _weapons = _weapons select { _x isNotEqualTo "" };

        { _bodyBag addItemCargoGlobal [_x, 1] } forEach _items;

        {
            private _weaponNonPresent = [_x] call CFUNC(getNonPresetClass);
            if (_weaponNonPresent == "") then { _weaponNonPresent = _x; };
            _bodyBag addWeaponCargoGlobal [_weaponNonPresent, 1];
        } forEach _weapons;

        if (_backpack isNotEqualTo "") then {
            private _backpackNonPresent = [_backpack, "CfgVehicles"] call CFUNC(getNonPresetClass);
            if (_backpackNonPresent == "") then { _backpackNonPresent = _backpack; };
            _bodyBag addItemCargoGlobal [_backpackNonPresent, 1];
        };

        {
            private _holderWeapons = ((getWeaponCargo _x) select 0) select { _x in _weapons };
            if (_holderWeapons isNotEqualTo []) then { deleteVehicle _x; };
        } forEach _nearHolders;
    }]
]];

SETMVAR(FORGE_MEconomyStore,GVAR(MEconomyStore));
GVAR(MEconomyStore)
