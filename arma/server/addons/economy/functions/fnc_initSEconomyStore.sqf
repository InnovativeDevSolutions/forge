#include "..\script_component.hpp"

/*
 * File: fnc_initSEconomyStore.sqf
 * Author: IDSolutions
 * Date: 2025-12-20
 * Last Update: 2026-05-15
 * Public: No
 *
 * Description:
 *     Initializes the service economy store for organization-funded world
 *     services such as repairs, with optional member debt recording for
 *     organization-covered medical fallback charges.
 *
 * Parameter(s):
 *     N/A
 *
 * Returns:
 *     Service economy store object [HASHMAP OBJECT]
 *
 * Example(s):
 *     call forge_server_economy_fnc_initSEconomyStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(SEconomyStore) = createHashMapObject [[
    ["#type", "IServiceEconomy"],
    ["#create", {
        GVAR(ServiceRepairCost) = 500;
        ["INFO", "Service Store Initialized!", nil, nil] call EFUNC(common,log);
    }],
    ["notify", {
        params [["_unit", objNull, [objNull]], ["_type", "info", [""]], ["_title", "Service", [""]], ["_message", "", [""]]];

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
    ["syncOrgPatch", {
        params [["_result", createHashMap, [createHashMap]]];

        private _patch = _result getOrDefault ["patch", createHashMap];
        if ((keys _patch) isEqualTo []) exitWith { false };

        private _memberUids = +(_result getOrDefault ["memberUids", []]);
        if (isNil QEGVAR(common,EventBus)) then {
            {
                private _memberPlayer = [_x] call EFUNC(common,getPlayer);
                if (_memberPlayer isNotEqualTo objNull) then {
                    [CRPC(org,responseSyncOrg), [_patch], _memberPlayer] call CFUNC(targetEvent);
                };
            } forEach _memberUids;
        } else {
            EGVAR(common,EventBus) call ["emit", [
                "org.sync.requested",
                createHashMapFromArray [
                    ["memberUids", _memberUids],
                    ["patch", +_patch]
                ],
                createHashMapFromArray [["source", "economy"]]
            ]];
        };

        true
    }],
    ["chargeOrg", {
        params [
            ["_unit", objNull, [objNull]],
            ["_amount", 0, [0]],
            ["_label", "Service", [""]],
            ["_recordDebt", false, [false]]
        ];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to charge organization funds."],
            ["patch", createHashMap],
            ["memberUids", []],
            ["persisted", false],
            ["persistenceMessage", ""]
        ];

        if (isNull _unit) exitWith {
            _result set ["message", "A valid player is required for organization billing."];
            _result
        };

        private _uid = getPlayerUID _unit;
        if (_uid isEqualTo "") exitWith {
            _result set ["message", "A valid player UID is required for organization billing."];
            _result
        };

        if (_amount <= 0) exitWith {
            _result set ["success", true];
            _result set ["message", ""];
            _result
        };

        if (isNil QEGVAR(org,OrgStore)) exitWith {
            _result set ["message", "Organization service is unavailable."];
            ["ERROR", format ["Org store unavailable for %1 charge.", _label], nil, nil] call EFUNC(common,log);
            _result
        };

        private _orgID = EGVAR(org,OrgStore) call ["resolveOrgIdForUid", [_uid]];
        if (_orgID isEqualTo "") then { _orgID = "default"; };

        private _actor = createHashMap;
        if !(isNil QEGVAR(actor,ActorStore)) then {
            _actor = EGVAR(actor,ActorStore) call ["load", [_uid]];
        };
        private _memberName = EGVAR(org,OrgStore) call ["resolveActorName", [_uid, _unit, _actor]];
        private _org = EGVAR(org,OrgStore) call ["ensureMember", [_orgID, _uid, _memberName]];
        if (_org isEqualTo createHashMap) exitWith {
            _result set ["message", "Organization membership could not be verified."];
            _result
        };

        private _charge = EGVAR(org,OrgStore) call ["chargeCheckout", [_uid, _unit, "org_funds", _amount, true, true, _recordDebt]];
        if !(_charge getOrDefault ["success", false]) exitWith {
            _result set ["message", _charge getOrDefault ["message", "Organization funds cannot cover this service."]];
            _result
        };

        _self call ["syncOrgPatch", [_charge]];
        _charge
    }],
    ["repair", {
        params [["_target", objNull, [objNull]], ["_unit", objNull, [objNull]], ["_cost", -1, [0]]];

        if (isNull _target || { isNull _unit }) exitWith { false };

        private _repairCost = [_cost, GVAR(ServiceRepairCost)] select (_cost < 0);
        private _charge = _self call ["chargeOrg", [_unit, _repairCost, "Repair"]];
        if !(_charge getOrDefault ["success", false]) exitWith {
            _self call ["notify", [_unit, "danger", "Repair", _charge getOrDefault ["message", "Organization funds cannot cover this repair."]]];
            false
        };

        _target setDamage 0;
        _self call ["notify", [_unit, "info", "Repair", format ["Repair complete. Organization charged $%1.", [_repairCost] call EFUNC(common,formatNumber)]]];
        true
    }],
    ["init", {}]
]];

SETMVAR(FORGE_SEconomyStore,GVAR(SEconomyStore));
GVAR(SEconomyStore)
