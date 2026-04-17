#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Handles task completion rewards for organizations.
 *
 * Arguments:
 * 0: Task ID <STRING>
 * 1: Reward Data <HASHMAP>
 * - funds: Amount of money to award <NUMBER>
 * - equipment: Array of equipment classnames to award <ARRAY>
 * - supplies: Array of supply classnames to award <ARRAY>
 * - weapons: Array of weapon classnames to award <ARRAY>
 * - vehicles: Array of vehicle classnames to award <ARRAY>
 * - special: Array of special item classnames to award <ARRAY>
 *
 * Return Value:
 * Success <BOOLEAN>
 *
 * Example:
 * private _rewards = createHashMapFromArray [
 *     ["funds", 10000],
 *     ["reputation", 50],
 *     ["equipment", ["ItemGPS", "ItemCompass"]],
 *     ["supplies", ["FirstAidKit", "Medikit"]],
 *     ["weapons", ["arifle_MX_F"]],
 *     ["vehicles", ["B_MRAP_01_F"]],
 *     ["special", ["B_UAV_01_F"]]
 * ];
 * ["task_1", _rewards] call forge_server_task_fnc_handleTaskRewards;
 *
 * Public: No
 */

params [["_taskID", ""], ["_rewards", createHashMap]];

if (_taskID == "") exitWith {
    ["ERROR", "No task ID provided for rewards"] call EFUNC(common,log);
    false
};

private _emitRewardEvent = {
    params [["_eventName", "", [""]], ["_payload", createHashMap, [createHashMap]]];

    if (_eventName isEqualTo "" || { isNil QEGVAR(common,EventBus) }) exitWith { createHashMap };

    private _eventPayload = +_payload;
    _eventPayload set ["taskID", _taskID];
    _eventPayload set ["rewardData", +_rewards];

    EGVAR(common,EventBus) call ["emit", [
        _eventName,
        _eventPayload,
        createHashMapFromArray [["source", "task"]]
    ]]
};

private _rewardContext = GVAR(TaskStore) call ["resolveRewardContext", [_taskID]];
private _requesterUid = _rewardContext getOrDefault ["requesterUid", ""];
private _orgID = _rewardContext getOrDefault ["orgID", ""];
private _memberUids = _rewardContext getOrDefault ["memberUids", []];
if (_orgID isEqualTo "") exitWith {
    ["ERROR", format ["No organization reward context found for task %1.", _taskID]] call EFUNC(common,log);
    ["task.reward.failed", createHashMapFromArray [
        ["rewardContext", _rewardContext],
        ["failureMessages", ["missing organization reward context"]]
    ]] call _emitRewardEvent;
    false
};

["task.reward.requested", createHashMapFromArray [
    ["rewardContext", _rewardContext]
]] call _emitRewardEvent;

private _success = true;
private _funds = _rewards getOrDefault ["funds", 0];
private _rewardMessages = [];
private _failureMessages = [];

private _resolveRewardLabel = {
    params [["_className", "", [""]]];

    if (_className isEqualTo "") exitWith { "" };

    {
        private _cfg = _x >> _className;
        if (isClass _cfg) exitWith {
            private _displayName = getText (_cfg >> "displayName");
            [_displayName, _className] select (_displayName isEqualTo "");
        };
    } forEach [
        configFile >> "CfgWeapons",
        configFile >> "CfgMagazines",
        configFile >> "CfgVehicles",
        configFile >> "CfgGlasses"
    ];

    _className
};

private _notifyMembers = {
    params [["_type", "info", [""]], ["_title", "Tasks", [""]], ["_message", "", [""]]];

    if (_message isEqualTo "") exitWith {};
    if (isNil QEGVAR(common,EventBus)) exitWith {
        {
            private _player = [_x] call EFUNC(common,getPlayer);
            if (isNull _player) then { continue; };
            [CRPC(notifications,recieveNotification), [_type, _title, _message], _player] call CFUNC(targetEvent);
        } forEach _memberUids;
    };

    EGVAR(common,EventBus) call ["emit", [
        "task.reward.notification.requested",
        createHashMapFromArray [
            ["taskID", _taskID],
            ["notificationType", _type],
            ["title", _title],
            ["message", _message],
            ["memberUids", +_memberUids]
        ],
        createHashMapFromArray [["source", "task"]]
    ]];
};

private _syncOrgPatch = {
    params [["_patch", createHashMap, [createHashMap]]];

    if (_patch isEqualTo createHashMap) exitWith {};
    if (isNil QEGVAR(common,EventBus)) exitWith {
        {
            private _player = [_x] call EFUNC(common,getPlayer);
            if (isNull _player) then { continue; };
            [CRPC(org,responseSyncOrg), [_patch], _player] call CFUNC(targetEvent);
        } forEach _memberUids;
    };

    EGVAR(common,EventBus) call ["emit", [
        "org.sync.requested",
        createHashMapFromArray [
            ["orgID", _orgID],
            ["memberUids", +_memberUids],
            ["patch", +_patch]
        ],
        createHashMapFromArray [["source", "task"]]
    ]];
};

if (_funds > 0) then {
    private _org = EGVAR(org,OrgStore) call ["loadById", [_orgID]];

    if (_org isEqualTo createHashMap) then {
        ["ERROR", format ["Failed to load organization %1 for task %2 funds reward.", _orgID, _taskID]] call EFUNC(common,log);
        _success = false;
    } else {
        private _nextFunds = (_org getOrDefault ["funds", 0]) + _funds;
        _org set ["funds", _nextFunds];
        private _updatedOrg = EGVAR(org,OrgStore) call [
            "callHotOrg",
            [
                "org:hot:override",
                [_orgID, toJSON _org]
            ]
        ];

        if (_updatedOrg isEqualTo createHashMap) then {
            ["ERROR", format ["Failed to update organization %1 funds for task %2.", _orgID, _taskID]] call EFUNC(common,log);
            _success = false;
            _failureMessages pushBack "org funds update";
        } else {
            private _patch = createHashMapFromArray [["funds", _nextFunds]];
            private _savedOrg = EGVAR(org,OrgStore) call ["saveById", [_orgID]];
            if (_savedOrg isEqualTo createHashMap) then {
                ["ERROR", format ["Task %1 updated organization %2 funds, but durable save failed.", _taskID, _orgID]] call EFUNC(common,log);
                _success = false;
                _failureMessages pushBack "org funds persistence";
            };

            [_patch] call _syncOrgPatch;
            _rewardMessages pushBack format ["$%1 org funds", [_funds] call EFUNC(common,formatNumber)];
        };
    };
};

private _grantOrgAssets = {
    params [["_category", "items", [""]], ["_items", [], [[]]]];

    if (_items isEqualTo []) exitWith {};

    private _assetEntries = _items apply {
        createHashMapFromArray [
            ["classname", _x],
            ["category", _category],
            ["quantity", 1]
        ]
    };

    private _grantResult = EGVAR(org,OrgStore) call ["addAssets", [_requesterUid, _assetEntries, false, _orgID]];
    if !(_grantResult getOrDefault ["success", false]) then {
        ["ERROR", format ["Failed to award %1 assets for task %2: %3", _category, _taskID, _grantResult getOrDefault ["message", "Unknown error."]]] call EFUNC(common,log);
        _success = false;
        _failureMessages pushBack format ["%1 asset update", _category];
    } else {
        [_grantResult getOrDefault ["patch", createHashMap]] call _syncOrgPatch;
        if !(_grantResult getOrDefault ["persisted", false]) then {
            private _persistenceMessage = _grantResult getOrDefault ["persistenceMessage", format ["%1 assets updated, but durable save failed.", _category]];
            ["ERROR", format ["Task %1 %2", _taskID, _persistenceMessage]] call EFUNC(common,log);
            _success = false;
            _failureMessages pushBack format ["%1 asset persistence", _category];
        };
        private _labels = _items apply { [_x] call _resolveRewardLabel };
        _rewardMessages pushBack format ["%1: %2", _category, _labels joinString ", "];
    };
};

private _grantOrgFleet = {
    params [["_vehicles", [], [[]]]];

    if (_vehicles isEqualTo []) exitWith {};

    private _vehicleEntries = _vehicles apply {
        private _category = "other";
        if (_x isKindOf "Car") then { _category = "cars"; };
        if (_x isKindOf "Tank") then { _category = "armor"; };
        if (_x isKindOf "Helicopter") then { _category = "helis"; };
        if (_x isKindOf "Plane") then { _category = "planes"; };
        if (_x isKindOf "Ship") then { _category = "naval"; };

        createHashMapFromArray [
            ["classname", _x],
            ["category", _category]
        ]
    };

    private _fleetResult = EGVAR(org,OrgStore) call ["addFleetVehicles", [_requesterUid, _vehicleEntries, false, _orgID]];
    if !(_fleetResult getOrDefault ["success", false]) then {
        ["ERROR", format ["Failed to award vehicle rewards for task %2: %1", _fleetResult getOrDefault ["message", "Unknown error."], _taskID]] call EFUNC(common,log);
        _success = false;
        _failureMessages pushBack "fleet update";
    } else {
        [_fleetResult getOrDefault ["patch", createHashMap]] call _syncOrgPatch;
        if !(_fleetResult getOrDefault ["persisted", false]) then {
            private _persistenceMessage = _fleetResult getOrDefault ["persistenceMessage", "Fleet updated, but durable save failed."];
            ["ERROR", format ["Task %1 %2", _taskID, _persistenceMessage]] call EFUNC(common,log);
            _success = false;
            _failureMessages pushBack "fleet persistence";
        };
        private _labels = _vehicles apply { [_x] call _resolveRewardLabel };
        _rewardMessages pushBack format ["vehicles: %1", _labels joinString ", "];
    };
};

private _equipment = _rewards getOrDefault ["equipment", []];
private _special = _rewards getOrDefault ["special", []];
private _supplies = _rewards getOrDefault ["supplies", []];
private _vehicles = _rewards getOrDefault ["vehicles", []];
private _weapons = _rewards getOrDefault ["weapons", []];

if (_equipment isNotEqualTo []) then { ["equipment", _equipment] call _grantOrgAssets; };
if (_supplies isNotEqualTo []) then {["supplies", _supplies] call _grantOrgAssets; };
if (_weapons isNotEqualTo []) then { ["weapons", _weapons] call _grantOrgAssets; };
if (_special isNotEqualTo []) then { ["special", _special] call _grantOrgAssets; };
if (_vehicles isNotEqualTo []) then { [_vehicles] call _grantOrgFleet; };

if (_success) then {
    private _orgName = "";
    private _org = EGVAR(org,OrgStore) call ["loadById", [_orgID]];
    if (_org isNotEqualTo createHashMap) then {
        _orgName = _org getOrDefault ["name", _orgID];
    };
    if (_orgName isEqualTo "") then { _orgName = _orgID; };

    private _message = format ["Task rewards added to %1.", _orgName];
    if (_rewardMessages isNotEqualTo []) then {
        _message = format ["%1 %2", _message, _rewardMessages joinString ", "];
    };

    ["INFO", _message] call EFUNC(common,log);
    ["success", "Tasks", _message] call _notifyMembers;
    ["task.reward.applied", createHashMapFromArray [
        ["rewardContext", _rewardContext],
        ["rewardMessages", +_rewardMessages],
        ["message", _message]
    ]] call _emitRewardEvent;
} else {
    private _warningMessage = format ["Task %1 completed, but one or more org rewards failed to apply.", _taskID];
    if (_failureMessages isNotEqualTo []) then {
        _warningMessage = format ["%1 Failed areas: %2.", _warningMessage, _failureMessages joinString ", "];
    };

    ["warning", "Tasks", _warningMessage] call _notifyMembers;
    ["task.reward.failed", createHashMapFromArray [
        ["rewardContext", _rewardContext],
        ["rewardMessages", +_rewardMessages],
        ["failureMessages", +_failureMessages],
        ["message", _warningMessage]
    ]] call _emitRewardEvent;
};

_success
