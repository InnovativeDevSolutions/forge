#include "..\script_component.hpp"

/*
 * File: fnc_initCadStore.sqf
 * Author: IDSolutions
 * Date: 2026-03-29
 * Public: Yes
 *
 * Description:
 * Initializes the CAD store: contracts (task catalog entries), which group
 * each is assigned to, accept/decline by the group leader, and live groups
 * with their role, status and members.
 *
 * CAD keeps no contract state of its own; TaskStore is the single source of
 * truth. Other addons (e.g. forge_server_dispatch) extend the hydrate payload
 * through `registerHydrateContributor`.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * CAD store object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_cad_fnc_initCadStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(CadStoreBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "CadStoreBaseClass"],
    ["#create", compileFinal {
        private _permissionService = call FUNC(initPermissionService);
        private _groupRepository = call FUNC(initGroupRepository);
        private _contractService = call FUNC(initContractService);

        _groupRepository set ["permissionService", _permissionService];
        _contractService set ["permissionService", _permissionService];
        _contractService set ["groupRepository", _groupRepository];

        _self set ["PermissionService", _permissionService];
        _self set ["GroupRepository", _groupRepository];
        _self set ["ContractService", _contractService];
        _self set ["hydrateContributors", createHashMap];

        ["INFO", "CAD Store Initialized!"] call EFUNC(common,log);
    }],

    // --- Extension point -------------------------------------------------

    ["registerHydrateContributor", compileFinal {
        // _code receives [uid, session, payload] and returns a hashmap whose
        // keys are merged into the hydrate payload (overwriting defaults).
        params [["_key", "", [""]], ["_code", {}, [{}]]];

        if (_key isEqualTo "") exitWith { false };
        (_self get "hydrateContributors") set [_key, _code];
        ["INFO", format ["CAD hydrate contributor registered: %1", _key]] call EFUNC(common,log);
        true
    }],

    // --- Messaging helpers -----------------------------------------------

    ["notifyPlayer", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_type", "info", [""]],
            ["_title", "CAD", [""]],
            ["_message", "", [""]]
        ];

        if (_uid isEqualTo "" || { _message isEqualTo "" }) exitWith { false };
        if (isNil QEGVAR(common,EventBus)) exitWith {
            private _player = [_uid] call EFUNC(common,getPlayer);
            if (isNull _player) exitWith { false };

            [CRPC(notifications,recieveNotification), [_type, _title, _message], _player] call CFUNC(targetEvent);
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
            createHashMapFromArray [["source", "cad"]]
        ]];
        true
    }],
    ["emitEvent", compileFinal {
        params [["_eventName", "", [""]], ["_payload", createHashMap, [createHashMap]]];

        if (_eventName isEqualTo "" || { isNil QEGVAR(common,EventBus) }) exitWith { false };
        EGVAR(common,EventBus) call ["emit", [_eventName, _payload, createHashMapFromArray [["source", "cad"]]]];
        true
    }],
    ["invalidateClients", compileFinal {
        [CRPC(cad,invalidateCadState), []] call CFUNC(globalEvent);
    }],
    ["resolveRequestPlayer", compileFinal {
        params [["_uid", "", [""]], ["_warning", "Invalid CAD payload.", [""]]];

        if (_uid isEqualTo "") exitWith {
            ["WARNING", _warning] call EFUNC(common,log);
            objNull
        };

        [_uid] call EFUNC(common,getPlayer)
    }],
    ["handleRpc", compileFinal {
        // Runs a store method for a client RPC, sends the result back, and
        // refreshes every open CAD when the state changed.
        params [
            ["_uid", "", [""]],
            ["_responseRpc", "", [""]],
            ["_method", "", [""]],
            ["_arguments", [], [[]]]
        ];

        private _player = _self call ["resolveRequestPlayer", [_uid, format ["CAD %1 request received with empty UID.", _method]]];
        if (isNull _player) exitWith { createHashMap };

        private _result = _self call [_method, _arguments];
        [_responseRpc, [_result], _player] call CFUNC(targetEvent);

        if ((_result getOrDefault ["success", false]) && { _result getOrDefault ["changed", true] }) then {
            _self call ["invalidateClients", []];
        };
        _result
    }],

    // --- Contracts -------------------------------------------------------

    ["assignContract", compileFinal {
        params [["_uid", "", [""]], ["_taskID", "", [""]], ["_groupID", "", [""]], ["_note", "", [""]]];

        private _result = (_self get "ContractService") call ["assign", [_uid, _taskID, _groupID, _note]];
        if !(_result getOrDefault ["success", false]) exitWith { _result };

        private _title = (_result getOrDefault ["entry", createHashMap]) getOrDefault ["title", _taskID];
        _self call ["notifyPlayer", [
            _result getOrDefault ["leaderUid", ""],
            "info",
            "CAD",
            format ["Contract assigned: %1. Open CAD to accept or decline.", _title]
        ]];
        _self call ["emitEvent", ["cad.contract.assigned", _result]];
        _result
    }],
    ["acceptContract", compileFinal {
        params [["_uid", "", [""]], ["_taskID", "", [""]]];

        private _result = (_self get "ContractService") call ["accept", [_uid, _taskID]];
        if !(_result getOrDefault ["success", false]) exitWith { _result };

        private _entry = _result getOrDefault ["entry", createHashMap];
        _self call ["notifyPlayer", [
            _result getOrDefault ["dispatcherUid", ""],
            "success",
            "CAD",
            format ["%1 accepted %2.", _entry getOrDefault ["assignedGroupCallsign", "Group"], _entry getOrDefault ["title", _taskID]]
        ]];
        _self call ["emitEvent", ["cad.contract.accepted", _result]];
        _result
    }],
    ["declineContract", compileFinal {
        params [["_uid", "", [""]], ["_taskID", "", [""]]];

        private _result = (_self get "ContractService") call ["decline", [_uid, _taskID]];
        if !(_result getOrDefault ["success", false]) exitWith { _result };

        private _entry = _result getOrDefault ["entry", createHashMap];
        _self call ["notifyPlayer", [
            _result getOrDefault ["dispatcherUid", ""],
            "warning",
            "CAD",
            format ["%1 declined %2.", _entry getOrDefault ["lastDeclinedGroupCallsign", "Group"], _entry getOrDefault ["title", _taskID]]
        ]];
        _self call ["emitEvent", ["cad.contract.declined", _result]];
        _result
    }],

    // --- Groups ----------------------------------------------------------

    ["updateGroupProfile", compileFinal {
        params [["_uid", "", [""]], ["_groupID", "", [""]], ["_status", "", [""]], ["_role", "", [""]]];

        private _result = (_self get "GroupRepository") call ["updateProfile", [_uid, _groupID, _status, _role]];
        if ((_result getOrDefault ["success", false]) && { _result getOrDefault ["changed", false] }) then {
            _self call ["emitEvent", ["cad.group.updated", _result]];
        };
        _result
    }],

    // --- Hydrate ---------------------------------------------------------

    ["toContractEntry", compileFinal {
        params [["_entry", createHashMap, [createHashMap]]];

        private _contract = +_entry;
        private _taskID = _entry getOrDefault ["taskId", _entry getOrDefault ["taskID", ""]];
        private _groupID = _entry getOrDefault ["assignedGroupId", ""];
        private _assignmentState = switch (toLowerANSI (_entry getOrDefault ["status", ""])) do {
            case "assigned": { "assigned" };
            case "active": { ["active", "accepted"] select (_groupID isNotEqualTo "") };
            default { "unassigned" };
        };

        _contract set ["taskId", _taskID];
        _contract set ["taskID", _taskID];
        _contract set ["assignedGroupId", _groupID];
        _contract set ["assignmentState", _assignmentState];
        _contract set ["isDispatchOrder", (_entry getOrDefault ["source", ""]) isEqualTo "dispatch"];
        _contract
    }],
    ["buildSession", compileFinal {
        params [["_uid", "", [""]]];

        private _groupRepository = _self get "GroupRepository";
        private _groupID = _groupRepository call ["getPlayerGroupId", [_uid]];

        createHashMapFromArray [
            ["uid", _uid],
            ["orgId", EGVAR(actor,ActorStore) call ["getOrganization", [_uid]]],
            ["isDispatcher", (_self get "PermissionService") call ["canDispatch", [_uid]]],
            ["groupId", _groupID],
            ["isLeader", _groupRepository call ["isGroupLeader", [_uid, _groupID]]]
        ]
    }],
    ["buildHydratePayload", compileFinal {
        params [["_uid", "", [""]]];

        private _session = _self call ["buildSession", [_uid]];
        private _isDispatcher = _session get "isDispatcher";
        private _sessionGroupID = _session get "groupId";

        // One catalog read per hydrate; groups reuse it for their current task.
        private _catalog = EGVAR(task,TaskStore) call ["getActiveTaskCatalog", []];
        private _taskByGroup = createHashMap;
        private _contracts = [];
        {
            private _contract = _self call ["toContractEntry", [_x]];
            private _groupID = _contract get "assignedGroupId";

            if (_groupID isNotEqualTo "") then {
                _taskByGroup set [_groupID, createHashMapFromArray [
                    ["taskId", _contract get "taskId"],
                    ["title", _contract getOrDefault ["title", _contract get "taskId"]]
                ]];
            };

            if (_isDispatcher || { _groupID isNotEqualTo "" && { _groupID isEqualTo _sessionGroupID } }) then {
                _contracts pushBack _contract;
            };
        } forEach _catalog;

        private _payload = createHashMapFromArray [
            ["groups", (_self get "GroupRepository") call ["buildGroups", [_taskByGroup]]],
            ["contracts", _contracts],
            ["requests", []],
            ["activity", []],
            ["generatedTaskTypes", []],
            ["dispatchEnabled", false],
            ["session", _session]
        ];

        // Contributors get [uid, session, payload] and return a hashmap of
        // sections to merge. They may also decorate payload entries in place.
        {
            private _key = _x;
            private _section = [_uid, _session, _payload] call _y;
            if (_section isEqualType createHashMap) then {
                _payload merge [_section, true];
            } else {
                ["WARNING", format ["CAD hydrate contributor '%1' returned a non-hashmap result.", _key]] call EFUNC(common,log);
            };
        } forEach (_self get "hydrateContributors");

        _payload
    }]
];

GVAR(CadStore) = createHashMapObject [GVAR(CadStoreBaseClass)];
GVAR(CadStore)
