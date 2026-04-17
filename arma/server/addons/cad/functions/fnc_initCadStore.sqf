#include "..\script_component.hpp"

/*
 * File: fnc_initCadStore.sqf
 * Author: IDSolutions
 * Date: 2026-03-29
 * Public: Yes
 *
 * Description:
 * Initializes the CAD store as a coordinator over activity, group,
 * assignment, and permission domain objects.
 *
 * CAD operational state is extension-backed but intentionally transient.
 * Orders, requests, assignments, hydrate state, and recent activity are
 * scoped to the active server/mission lifecycle and start fresh after a
 * restart.
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
        private _activityRepository = call FUNC(initActivityRepository);
        private _permissionService = call FUNC(initPermissionService);
        private _groupRepository = call FUNC(initGroupRepository);
        private _assignmentRepository = call FUNC(initAssignmentRepository);
        private _persistenceService = call FUNC(initPersistenceService);
        private _requestRepository = call FUNC(initRequestRepository);

        _groupRepository set ["activityRepository", _activityRepository];
        _groupRepository set ["assignmentRepository", _assignmentRepository];
        _groupRepository set ["permissionService", _permissionService];
        _groupRepository set ["persistenceService", _persistenceService];

        _assignmentRepository set ["activityRepository", _activityRepository];
        _assignmentRepository set ["groupRepository", _groupRepository];
        _assignmentRepository set ["permissionService", _permissionService];
        _assignmentRepository set ["persistenceService", _persistenceService];

        _requestRepository set ["activityRepository", _activityRepository];
        _requestRepository set ["groupRepository", _groupRepository];
        _requestRepository set ["permissionService", _permissionService];
        _requestRepository set ["persistenceService", _persistenceService];

        _activityRepository set ["persistenceService", _persistenceService];

        _self set ["ActivityRepository", _activityRepository];
        _self set ["PermissionService", _permissionService];
        _self set ["GroupRepository", _groupRepository];
        _self set ["AssignmentRepository", _assignmentRepository];
        _self set ["PersistenceService", _persistenceService];
        _self set ["RequestRepository", _requestRepository];

        ["INFO", "CAD Store Initialized!"] call EFUNC(common,log);
    }],
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
            if (_player isEqualTo objNull) exitWith { false };

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
    ["resolveRequestPlayer", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_warning", "Invalid CAD payload.", [""]]
        ];

        if (_uid isEqualTo "") exitWith {
            ["WARNING", _warning] call EFUNC(common,log);
            objNull
        };

        [_uid] call EFUNC(common,getPlayer)
    }],
    ["sendRpcResult", compileFinal {
        params [
            ["_player", objNull, [objNull]],
            ["_responseRpc", "", [""]],
            ["_result", createHashMap, [createHashMap]],
            ["_invalidateOnSuccess", false, [false]],
            ["_requireChanged", false, [false]]
        ];

        if (_player isEqualTo objNull || { _responseRpc isEqualTo "" }) exitWith {};

        [_responseRpc, [_result], _player] call CFUNC(targetEvent);

        if (
            _invalidateOnSuccess
            && { _result getOrDefault ["success", false] }
            && { !_requireChanged || { _result getOrDefault ["changed", true] } }
        ) then {
            [CRPC(cad,invalidateCadState), []] call CFUNC(globalEvent);
        };
    }],
    ["dispatchRpcMutation", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_warning", "Invalid CAD payload.", [""]],
            ["_responseRpc", "", [""]],
            ["_method", "", [""]],
            ["_arguments", [], [[]]],
            ["_invalidateOnSuccess", false, [false]],
            ["_requireChanged", false, [false]]
        ];

        private _player = _self call ["resolveRequestPlayer", [_uid, _warning]];
        if (_player isEqualTo objNull || { _method isEqualTo "" }) exitWith { createHashMap };

        private _result = _self call [_method, _arguments];
        _self call ["sendRpcResult", [_player, _responseRpc, _result, _invalidateOnSuccess, _requireChanged]];
        _result
    }],
    ["emitAssignmentEvent", compileFinal {
        params [["_eventName", "", [""]], ["_result", createHashMap, [createHashMap]]];

        if (_eventName isEqualTo "" || { !(_result getOrDefault ["success", false]) }) exitWith { createHashMap };
        if (isNil QEGVAR(common,EventBus)) exitWith { createHashMap };

        private _assignment = +(_result getOrDefault ["assignment", createHashMap]);
        private _payload = createHashMapFromArray [
            ["taskID", _assignment getOrDefault ["taskId", ""]],
            ["assignment", _assignment],
            ["leaderUid", _result getOrDefault ["leaderUid", ""]],
            ["isDispatchOrder", _result getOrDefault ["isDispatchOrder", false]],
            ["message", _result getOrDefault ["message", ""]]
        ];

        if (_result getOrDefault ["isDispatchOrder", false]) then {
            _payload set ["order", +(_result getOrDefault ["order", createHashMap])];
        };

        EGVAR(common,EventBus) call ["emit", [
            _eventName,
            _payload,
            createHashMapFromArray [["source", "cad"]]
        ]]
    }],
    ["emitRequestEvent", compileFinal {
        params [["_eventName", "", [""]], ["_result", createHashMap, [createHashMap]]];

        if (_eventName isEqualTo "" || { !(_result getOrDefault ["success", false]) }) exitWith { createHashMap };
        if (isNil QEGVAR(common,EventBus)) exitWith { createHashMap };

        private _request = +(_result getOrDefault ["request", createHashMap]);
        EGVAR(common,EventBus) call ["emit", [
            _eventName,
            createHashMapFromArray [
                ["requestID", _request getOrDefault ["requestId", ""]],
                ["groupID", _request getOrDefault ["groupId", ""]],
                ["request", _request],
                ["message", _result getOrDefault ["message", ""]]
            ],
            createHashMapFromArray [["source", "cad"]]
        ]]
    }],
    ["emitGroupEvent", compileFinal {
        params [["_eventName", "", [""]], ["_result", createHashMap, [createHashMap]]];

        if (
            _eventName isEqualTo ""
            || { !(_result getOrDefault ["success", false]) }
            || { !(_result getOrDefault ["changed", true]) }
        ) exitWith { createHashMap };
        if (isNil QEGVAR(common,EventBus)) exitWith { createHashMap };

        private _group = +(_result getOrDefault ["group", createHashMap]);
        EGVAR(common,EventBus) call ["emit", [
            _eventName,
            createHashMapFromArray [
                ["groupID", _group getOrDefault ["groupId", ""]],
                ["group", _group],
                ["message", _result getOrDefault ["message", ""]],
                ["changed", _result getOrDefault ["changed", true]]
            ],
            createHashMapFromArray [["source", "cad"]]
        ]]
    }],
    ["notifyAssignmentLeader", compileFinal {
        params [["_result", createHashMap, [createHashMap]]];

        if !(_result getOrDefault ["success", false]) exitWith { false };

        private _leaderUid = _result getOrDefault ["leaderUid", ""];
        if (_leaderUid isEqualTo "") exitWith { false };

        private _assignmentRepository = _self get "AssignmentRepository";
        private _message = if (_result getOrDefault ["isDispatchOrder", false]) then {
            private _order = _result getOrDefault ["order", createHashMap];
            if (_order isEqualTo createHashMap) then {
                private _assignment = _result getOrDefault ["assignment", createHashMap];
                private _taskID = _assignment getOrDefault ["taskId", ""];
                _order = _assignmentRepository call ["buildDispatchOrderEntryForTask", [_taskID, _self get "GroupRepository"]];
            };

            format ["Dispatch order assigned: %1. Open CAD to review and acknowledge.", _order getOrDefault ["title", "Dispatch Order"]]
        } else {
            private _assignment = _result getOrDefault ["assignment", createHashMap];
            format ["Contract assigned: %1. Open CAD to review and acknowledge.", _assignment getOrDefault ["taskId", "Task"]]
        };

        _self call ["notifyPlayer", [
            _leaderUid,
            "info",
            "Tasks",
            _message
        ]]
    }],
    ["assignTaskToGroup", compileFinal {
        private _result = (_self get "AssignmentRepository") call ["assignTaskToGroup", _this];
        if !(_result getOrDefault ["success", false]) exitWith { _result };

        _self call ["notifyAssignmentLeader", [_result]];
        _self call ["emitAssignmentEvent", ["cad.assignment.assigned", _result]];
        _result
    }],
    ["createDispatchOrder", compileFinal {
        private _result = (_self get "AssignmentRepository") call ["createDispatchOrder", _this];
        if !(_result getOrDefault ["success", false]) exitWith { _result };

        _self call ["notifyAssignmentLeader", [_result]];
        _self call ["emitAssignmentEvent", ["cad.assignment.created", _result]];
        _result
    }],
    ["closeDispatchOrder", compileFinal {
        private _result = (_self get "AssignmentRepository") call ["closeDispatchOrder", _this];
        _self call ["emitAssignmentEvent", ["cad.assignment.closed", _result]];
        _result
    }],
    ["submitSupportRequest", compileFinal {
        private _result = (_self get "RequestRepository") call ["submitRequest", _this];
        _self call ["emitRequestEvent", ["cad.request.submitted", _result]];
        _result
    }],
    ["closeSupportRequest", compileFinal {
        private _result = (_self get "RequestRepository") call ["closeRequest", _this];
        _self call ["emitRequestEvent", ["cad.request.closed", _result]];
        _result
    }],
    ["acknowledgeTask", compileFinal {
        private _result = (_self get "AssignmentRepository") call ["acknowledgeTask", _this];
        _self call ["emitAssignmentEvent", ["cad.assignment.acknowledged", _result]];
        _result
    }],
    ["declineTask", compileFinal {
        private _result = (_self get "AssignmentRepository") call ["declineTask", _this];
        _self call ["emitAssignmentEvent", ["cad.assignment.declined", _result]];
        _result
    }],
    ["updateGroupStatus", compileFinal {
        private _result = (_self get "GroupRepository") call ["updateGroupStatus", _this];
        _self call ["emitGroupEvent", ["cad.group.updated", _result]];
        _result
    }],
    ["updateGroupRole", compileFinal {
        private _result = (_self get "GroupRepository") call ["updateGroupRole", _this];
        _self call ["emitGroupEvent", ["cad.group.updated", _result]];
        _result
    }],
    ["updateGroupProfile", compileFinal {
        private _result = (_self get "GroupRepository") call ["updateGroupProfile", _this];
        _self call ["emitGroupEvent", ["cad.group.updated", _result]];
        _result
    }],
    ["buildHydratePayload", compileFinal {
        params [["_uid", "", [""]]];

        private _permissionService = _self get "PermissionService";
        private _groupRepository = _self get "GroupRepository";

        private _groupID = _groupRepository call ["getPlayerGroupId", [_uid]];
        private _session = createHashMapFromArray [
            ["uid", _uid],
            ["orgId", EGVAR(actor,ActorStore) call ["getOrganization", [_uid]]],
            ["isDispatcher", _permissionService call ["canDispatch", [_uid]]],
            ["groupId", _groupID],
            ["isLeader", _groupRepository call ["isGroupLeader", [_uid, _groupID]]]
        ];
        private _seed = createHashMapFromArray [
            ["groups", _groupRepository call ["buildGroups", []]],
            ["activeTasks", EGVAR(task,TaskStore) call ["getActiveTaskCatalog", []]],
            ["session", _session]
        ];
        private _emptyPayload = createHashMapFromArray [
            ["groups", _seed get "groups"],
            ["contracts", []],
            ["requests", []],
            ["assignments", []],
            ["activity", []],
            ["session", _session]
        ];
        private _persistenceService = _self getOrDefault ["PersistenceService", createHashMap];

        if (_persistenceService isEqualTo createHashMap) exitWith {
            ["WARNING", "CAD hydrate extension state is unavailable; returning seed-only payload."] call EFUNC(common,log);
            _emptyPayload
        };

        private _hydrateResult = _persistenceService call ["buildHydratePayload", [_seed]];
        if (_hydrateResult getOrDefault ["success", false]) exitWith {
            _hydrateResult getOrDefault ["data", createHashMap]
        };

        ["WARNING", "CAD hydrate failed in the extension; returning seed-only payload."] call EFUNC(common,log);
        _emptyPayload
    }]
];

GVAR(CadStore) = createHashMapObject [GVAR(CadStoreBaseClass)];
GVAR(CadStore)
