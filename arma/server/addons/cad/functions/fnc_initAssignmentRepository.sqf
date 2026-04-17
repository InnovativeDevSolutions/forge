#include "..\script_component.hpp"

/*
 * File: fnc_initAssignmentRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-30
 * Public: No
 *
 * Description:
 * Initializes the CAD assignment repository for contract assignment
 * state and dispatcher/group-leader task actions.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * CAD assignment repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_cad_fnc_initAssignmentRepository
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(AssignmentRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "CadAssignmentRepositoryBaseClass"],
    ["#create", compileFinal {
        _self set ["ownershipHydrated", false];
    }],
    ["loadState", compileFinal {
        private _result = createHashMapFromArray [
            ["success", false],
            ["assignments", createHashMap],
            ["dispatchOrders", createHashMap]
        ];

        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith { _result };

        private _assignmentsResult = _persistenceService call ["loadAssignments", []];
        if !(_assignmentsResult getOrDefault ["success", false]) exitWith { _result };

        private _ordersResult = _persistenceService call ["loadDispatchOrders", []];
        if !(_ordersResult getOrDefault ["success", false]) exitWith { _result };

        private _assignmentRegistry = +(_assignmentsResult getOrDefault ["data", createHashMap]);
        private _dispatchOrderRegistry = +(_ordersResult getOrDefault ["data", createHashMap]);

        if !(_self getOrDefault ["ownershipHydrated", false]) then {
            {
                if ((_y getOrDefault ["state", ""]) isNotEqualTo "acknowledged") then { continue; };
                if ((_y getOrDefault ["acknowledgedByUid", ""]) isEqualTo "") then { continue; };
                if ((_dispatchOrderRegistry getOrDefault [_x, createHashMap]) isNotEqualTo createHashMap) then { continue; };
                if ((EGVAR(task,TaskStore) call ["getTaskStatus", [_x]]) isNotEqualTo "active") then { continue; };

                EGVAR(task,TaskStore) call ["bindTaskOwnership", [_x, _y getOrDefault ["acknowledgedByUid", ""]]];
            } forEach _assignmentRegistry;

            _self set ["ownershipHydrated", true];
        };

        _result set ["success", true];
        _result set ["assignments", _assignmentRegistry];
        _result set ["dispatchOrders", _dispatchOrderRegistry];
        _result
    }],
    ["pruneAssignments", compileFinal {
        private _state = _self call ["loadState", []];
        if !(_state getOrDefault ["success", false]) exitWith { 0 };

        private _assignmentRegistry = _state getOrDefault ["assignments", createHashMap];
        private _dispatchOrderRegistry = _state getOrDefault ["dispatchOrders", createHashMap];
        private _keysToRemove = [];

        {
            if ((_dispatchOrderRegistry getOrDefault [_x, createHashMap]) isNotEqualTo createHashMap) then {
                continue;
            };

            private _status = EGVAR(task,TaskStore) call ["getTaskStatus", [_x]];
            if !(_status in ["active", ""]) then {
                _keysToRemove pushBack _x;
            };
        } forEach _assignmentRegistry;

        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isNotEqualTo createHashMap) then {
            {
                _persistenceService call ["deleteAssignment", [_x]];
            } forEach _keysToRemove;
        };

        count _keysToRemove
    }],
    ["getAssignments", compileFinal {
        private _state = _self call ["loadState", []];
        if !(_state getOrDefault ["success", false]) exitWith { [] };

        values (_state getOrDefault ["assignments", createHashMap])
    }],
    ["isDispatchOrder", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _state = _self call ["loadState", []];
        if !(_state getOrDefault ["success", false]) exitWith { false };

        ((_state getOrDefault ["dispatchOrders", createHashMap]) getOrDefault [_taskID, createHashMap]) isNotEqualTo createHashMap
    }],
    ["getAssignmentByTaskId", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { createHashMap };

        private _state = _self call ["loadState", []];
        if !(_state getOrDefault ["success", false]) exitWith { createHashMap };

        +((_state getOrDefault ["assignments", createHashMap]) getOrDefault [_taskID, createHashMap])
    }],
    ["getDispatchOrderByTaskId", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { createHashMap };

        private _state = _self call ["loadState", []];
        if !(_state getOrDefault ["success", false]) exitWith { createHashMap };

        +((_state getOrDefault ["dispatchOrders", createHashMap]) getOrDefault [_taskID, createHashMap])
    }],
    ["getCurrentTaskIdForGroup", compileFinal {
        params [["_groupID", "", [""]]];

        if (_groupID isEqualTo "") exitWith { "" };

        private _state = _self call ["loadState", []];
        if !(_state getOrDefault ["success", false]) exitWith { "" };

        private _assignmentRegistry = _state getOrDefault ["assignments", createHashMap];
        private _dispatchOrderRegistry = _state getOrDefault ["dispatchOrders", createHashMap];
        private _taskID = "";

        {
            if ((_y getOrDefault ["groupId", ""]) isNotEqualTo _groupID) then { continue; };
            if !((_y getOrDefault ["state", ""]) in ["assigned", "acknowledged"]) then { continue; };

            private _dispatchOrder = +(_dispatchOrderRegistry getOrDefault [_x, createHashMap]);
            if (_dispatchOrder isEqualTo createHashMap) then {
                if ((EGVAR(task,TaskStore) call ["getTaskStatus", [_x]]) isNotEqualTo "active") then { continue; };
                _taskID = _x;
            } else {
                _taskID = _dispatchOrder getOrDefault ["title", _x];
            };
        } forEach _assignmentRegistry;

        _taskID
    }],
    ["buildDispatchOrderEntry", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_order", createHashMap, [createHashMap]],
            ["_assignment", createHashMap, [createHashMap]],
            ["_groupRepository", createHashMap, [createHashMap]]
        ];

        if (_taskID isEqualTo "" || { _order isEqualTo createHashMap }) exitWith { createHashMap };

        private _entry = +_order;
        private _targetGroupID = _order getOrDefault ["targetGroupId", ""];
        if (_targetGroupID isNotEqualTo "") then {
            private _targetGroup = _groupRepository call ["getGroupRecord", [_targetGroupID]];
            if (_targetGroup isNotEqualTo createHashMap) then {
                private _targetCallsign = _targetGroup getOrDefault ["callsign", _targetGroupID];
                _entry set ["targetGroupCallsign", _targetCallsign];
                _entry set ["position", +(_targetGroup getOrDefault ["position", _entry getOrDefault ["position", []]])];
                _entry set ["title", format ["Backup %1", _targetCallsign]];

                if ((_order getOrDefault ["note", ""]) isEqualTo "") then {
                    _entry set ["description", format ["Dispatch order to back up %1 at its current position.", _targetCallsign]];
                };
            };
        };

        _entry set ["taskId", _taskID];
        _entry set ["taskID", _taskID];
        _entry set ["type", _entry getOrDefault ["type", "dispatch_order"]];
        _entry set ["isDispatchOrder", true];
        _entry set ["assignedGroupId", _assignment getOrDefault ["groupId", ""]];
        _entry set ["assignmentState", [_assignment getOrDefault ["state", ""], "unassigned"] select (_assignment isEqualTo createHashMap)];
        _entry
    }],
    ["buildDispatchOrderEntryForTask", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_groupRepository", createHashMap, [createHashMap]]
        ];

        if (_taskID isEqualTo "") exitWith { createHashMap };

        private _state = _self call ["loadState", []];
        if !(_state getOrDefault ["success", false]) exitWith { createHashMap };

        private _order = +((_state getOrDefault ["dispatchOrders", createHashMap]) getOrDefault [_taskID, createHashMap]);
        if (_order isEqualTo createHashMap) exitWith { createHashMap };

        private _assignment = +((_state getOrDefault ["assignments", createHashMap]) getOrDefault [_taskID, createHashMap]);
        _self call ["buildDispatchOrderEntry", [_taskID, _order, _assignment, _groupRepository]]
    }],
    ["assignTaskToGroup", compileFinal {
        params [
            ["_requesterUid", "", [""]],
            ["_taskID", "", [""]],
            ["_groupID", "", [""]],
            ["_note", "", [""]]
        ];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to assign task."],
            ["assignment", createHashMap]
        ];

        private _permissionService = _self getOrDefault ["permissionService", createHashMap];
        if !(_permissionService call ["canDispatch", [_requesterUid]]) exitWith {
            _result set ["message", "You are not authorized to assign contracts."];
            _result
        };

        private _state = _self call ["loadState", []];
        if !(_state getOrDefault ["success", false]) exitWith {
            _result set ["message", "CAD extension state is unavailable."];
            _result
        };

        private _assignmentRegistry = _state getOrDefault ["assignments", createHashMap];
        private _dispatchOrderRegistry = _state getOrDefault ["dispatchOrders", createHashMap];
        private _isDispatchOrder = (_dispatchOrderRegistry getOrDefault [_taskID, createHashMap]) isNotEqualTo createHashMap;

        if (!_isDispatchOrder && { (EGVAR(task,TaskStore) call ["getTaskStatus", [_taskID]]) isNotEqualTo "active" }) exitWith {
            _result set ["message", "Task is no longer active."];
            _result
        };

        private _existingAssignment = +(_assignmentRegistry getOrDefault [_taskID, createHashMap]);
        if (
            _existingAssignment isNotEqualTo createHashMap
            && { (_existingAssignment getOrDefault ["state", ""]) in ["assigned", "acknowledged"] }
        ) exitWith {
            _result set ["message", ["Task is already assigned and must be declined or completed before reassignment.", "Dispatch order is already assigned and must be declined or closed before reassignment."] select _isDispatchOrder];
            _result set ["assignment", _existingAssignment];
            _result
        };

        private _groupRepository = _self getOrDefault ["groupRepository", createHashMap];
        private _groupRecord = _groupRepository call ["getGroupRecord", [_groupID]];
        if (_groupRecord isEqualTo createHashMap) exitWith {
            _result set ["message", "Selected group is unavailable."];
            _result
        };

        private _leaderUid = _groupRecord getOrDefault ["leaderUid", ""];
        if (_leaderUid isEqualTo "") exitWith {
            _result set ["message", "Selected group has no online leader."];
            _result
        };

        private _requesterPlayer = [_requesterUid] call EFUNC(common,getPlayer);
        private _assignment = createHashMapFromArray [
            ["taskId", _taskID],
            ["groupId", _groupID],
            ["groupCallsign", _groupRecord getOrDefault ["callsign", _groupID]],
            ["assignedByUid", _requesterUid],
            ["assignedByName", ["Dispatcher", name _requesterPlayer] select (_requesterPlayer isNotEqualTo objNull)],
            ["assignedAt", serverTime],
            ["state", "assigned"],
            ["note", _note]
        ];

        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith {
            _result set ["message", "CAD extension state is unavailable."];
            _result
        };

        private _assignResult = _persistenceService call ["assignAssignment", [_taskID, _assignment]];
        if !(_assignResult getOrDefault ["success", false]) exitWith {
            _result set ["message", "CAD extension rejected the assignment."];
            _result
        };

        private _assignData = +(_assignResult getOrDefault ["data", createHashMap]);
        _assignment = +(_assignData getOrDefault ["assignment", createHashMap]);
        if (_assignment isEqualTo createHashMap) exitWith {
            _result set ["message", "CAD extension returned an invalid assignment."];
            _result
        };

        private _activityEntry = +(_assignData getOrDefault ["activity", createHashMap]);
        if (_activityEntry isNotEqualTo createHashMap) then {
            private _activityRepository = _self getOrDefault ["activityRepository", createHashMap];
            _activityRepository call ["appendEntry", [_activityEntry]];
        };

        _result set ["success", true];
        _result set ["message", _assignData getOrDefault ["message", ["Task assigned.", "Dispatch order assigned."] select _isDispatchOrder]];
        _result set ["assignment", _assignment];
        _result set ["leaderUid", _leaderUid];
        _result set ["isDispatchOrder", _isDispatchOrder];
        if (_isDispatchOrder) then {
            _result set ["order", +(_dispatchOrderRegistry getOrDefault [_taskID, createHashMap])];
        };
        _result
    }],
    ["createDispatchOrder", compileFinal {
        params [
            ["_requesterUid", "", [""]],
            ["_assigneeGroupID", "", [""]],
            ["_targetGroupID", "", [""]],
            ["_note", "", [""]],
            ["_priority", "priority", [""]],
            ["_request", createHashMap, [createHashMap]]
        ];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to create dispatch order."],
            ["assignment", createHashMap],
            ["order", createHashMap]
        ];

        private _permissionService = _self getOrDefault ["permissionService", createHashMap];
        if !(_permissionService call ["canDispatch", [_requesterUid]]) exitWith {
            _result set ["message", "You are not authorized to create dispatch orders."];
            _result
        };

        if (_assigneeGroupID isEqualTo "" || { _targetGroupID isEqualTo "" }) exitWith {
            _result set ["message", "Assignee and target groups are required."];
            _result
        };

        if (_assigneeGroupID isEqualTo _targetGroupID) exitWith {
            _result set ["message", "Assignee and target groups must be different."];
            _result
        };

        private _groupRepository = _self getOrDefault ["groupRepository", createHashMap];
        private _assigneeGroup = _groupRepository call ["getGroupRecord", [_assigneeGroupID]];
        if (_assigneeGroup isEqualTo createHashMap) exitWith {
            _result set ["message", "Selected assignee group is unavailable."];
            _result
        };

        private _assigneeLeaderUid = _assigneeGroup getOrDefault ["leaderUid", ""];
        if (_assigneeLeaderUid isEqualTo "") exitWith {
            _result set ["message", "Selected assignee group has no online leader."];
            _result
        };

        private _targetGroup = _groupRepository call ["getGroupRecord", [_targetGroupID]];
        if (_targetGroup isEqualTo createHashMap) exitWith {
            _result set ["message", "Selected target group is unavailable."];
            _result
        };

        private _validPriorities = ["routine", "priority", "emergency"];
        private _finalPriority = toLowerANSI _priority;
        if !(_finalPriority in _validPriorities) then {
            _finalPriority = "priority";
        };

        private _requesterPlayer = [_requesterUid] call EFUNC(common,getPlayer);
        private _dispatchContext = createHashMapFromArray [
            ["assigneeGroupId", _assigneeGroupID],
            ["assigneeGroupCallsign", _assigneeGroup getOrDefault ["callsign", _assigneeGroupID]],
            ["targetGroupId", _targetGroupID],
            ["targetGroupCallsign", _targetGroup getOrDefault ["callsign", _targetGroupID]],
            ["targetPosition", +(_targetGroup getOrDefault ["position", []])],
            ["createdByUid", _requesterUid],
            ["createdByName", ["Dispatcher", name _requesterPlayer] select (_requesterPlayer isNotEqualTo objNull)],
            ["requestId", _request getOrDefault ["requestId", ""]],
            ["requestType", _request getOrDefault ["type", ""]],
            ["requestTitle", _request getOrDefault ["title", ""]],
            ["requestSummary", _request getOrDefault ["summary", ""]],
            ["requestFields", +(_request getOrDefault ["fields", createHashMap])],
            ["note", _note],
            ["priority", _finalPriority],
            ["createdAt", serverTime]
        ];

        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith {
            _result set ["message", "CAD extension state is unavailable."];
            _result
        };

        private _createResult = _persistenceService call ["createDispatchOrderFromContext", [_dispatchContext]];
        if !(_createResult getOrDefault ["success", false]) exitWith {
            _result set ["message", "CAD extension rejected the dispatch order."];
            _result
        };

        private _createData = +(_createResult getOrDefault ["data", createHashMap]);
        private _taskID = _createData getOrDefault ["taskId", ""];
        private _order = +(_createData getOrDefault ["order", createHashMap]);
        private _assignment = +(_createData getOrDefault ["assignment", createHashMap]);
        if (_taskID isEqualTo "" || { _order isEqualTo createHashMap } || { _assignment isEqualTo createHashMap }) exitWith {
            _result set ["message", "CAD extension returned an invalid dispatch order."];
            _result
        };

        private _activityEntry = +(_createData getOrDefault ["activity", createHashMap]);
        if (_activityEntry isNotEqualTo createHashMap) then {
            private _activityRepository = _self getOrDefault ["activityRepository", createHashMap];
            _activityRepository call ["appendEntry", [_activityEntry]];
        };

        _result set ["success", true];
        _result set ["message", _createData getOrDefault ["message", "Dispatch order created."]];
        _result set ["assignment", _assignment];
        _result set ["order", _order];
        _result set ["leaderUid", _assigneeLeaderUid];
        _result set ["isDispatchOrder", true];
        _result
    }],
    ["closeDispatchOrder", compileFinal {
        params [["_requesterUid", "", [""]], ["_taskID", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to close dispatch order."],
            ["assignment", createHashMap]
        ];

        private _permissionService = _self getOrDefault ["permissionService", createHashMap];
        if !(_permissionService call ["canDispatch", [_requesterUid]]) exitWith {
            _result set ["message", "You are not authorized to close dispatch orders."];
            _result
        };

        private _state = _self call ["loadState", []];
        if !(_state getOrDefault ["success", false]) exitWith {
            _result set ["message", "CAD extension state is unavailable."];
            _result
        };

        private _order = +((_state getOrDefault ["dispatchOrders", createHashMap]) getOrDefault [_taskID, createHashMap]);
        if (_order isEqualTo createHashMap) exitWith {
            _result set ["message", "Dispatch order could not be resolved."];
            _result
        };

        private _assignment = +((_state getOrDefault ["assignments", createHashMap]) getOrDefault [_taskID, createHashMap]);

        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith {
            _result set ["message", "CAD extension state is unavailable."];
            _result
        };

        private _closeResult = _persistenceService call ["closeDispatchOrder", [_taskID]];
        if !(_closeResult getOrDefault ["success", false]) exitWith {
            _result set ["message", "CAD extension rejected the dispatch order close."];
            _result
        };

        private _closeData = +(_closeResult getOrDefault ["data", createHashMap]);
        _assignment = +(_closeData getOrDefault ["assignment", _assignment]);

        private _activityEntry = +(_closeData getOrDefault ["activity", createHashMap]);
        if (_activityEntry isNotEqualTo createHashMap) then {
            _activityEntry set ["actorUid", _requesterUid];
            private _activityRepository = _self getOrDefault ["activityRepository", createHashMap];
            _activityRepository call ["appendEntry", [_activityEntry]];
        };

        _result set ["success", true];
        _result set ["message", _closeData getOrDefault ["message", "Dispatch order closed."]];
        _result set ["assignment", _assignment];
        _result set ["isDispatchOrder", true];
        _result
    }],
    ["applyAssignmentTransition", compileFinal {
        params [["_requesterUid", "", [""]], ["_taskID", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to update task assignment."],
            ["assignment", createHashMap]
        ];

        private _transition = _this param [2, "acknowledge", [""]];
        private _state = _self call ["loadState", []];
        if !(_state getOrDefault ["success", false]) exitWith {
            _result set ["message", "CAD extension state is unavailable."];
            _result
        };

        private _assignment = +((_state getOrDefault ["assignments", createHashMap]) getOrDefault [_taskID, createHashMap]);
        private _isDispatchOrder = ((_state getOrDefault ["dispatchOrders", createHashMap]) getOrDefault [_taskID, createHashMap]) isNotEqualTo createHashMap;
        if (_assignment isEqualTo createHashMap) exitWith {
            _result set ["message", "Task is not assigned."];
            _result
        };

        private _groupID = _assignment getOrDefault ["groupId", ""];
        private _groupRepository = _self getOrDefault ["groupRepository", createHashMap];
        if !(_groupRepository call ["isGroupLeader", [_requesterUid, _groupID]]) exitWith {
            _result set ["message", format ["Only the assigned group leader can %1 this task.", _transition]];
            _result
        };

        switch (_transition) do {
            case "acknowledge": {
                if (!_isDispatchOrder) then {
                    private _bindResult = EGVAR(task,TaskStore) call ["bindTaskOwnership", [_taskID, _requesterUid]];
                    if !(_bindResult getOrDefault ["success", false]) exitWith {
                        _result set ["message", _bindResult getOrDefault ["message", "Failed to bind task ownership."]];
                        _result
                    };
                };
            };
            case "decline": {
                if (!_isDispatchOrder) then {
                    EGVAR(task,TaskStore) call ["releaseTaskOwnership", [_taskID]];
                };
            };
        };

        if (_result getOrDefault ["success", false]) exitWith { _result };

        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith {
            _result set ["message", "CAD extension state is unavailable."];
            _result
        };

        private _patch = switch (_transition) do {
            case "decline": {
                createHashMapFromArray [
                    ["state", "declined"],
                    ["declinedAt", serverTime],
                    ["declinedByUid", _requesterUid]
                ]
            };
            default {
                createHashMapFromArray [
                    ["state", "acknowledged"],
                    ["acknowledgedAt", serverTime],
                    ["acknowledgedByUid", _requesterUid]
                ]
            };
        };
        private _transitionResult = switch (_transition) do {
            case "decline": { _persistenceService call ["declineAssignment", [_taskID, _patch]] };
            default { _persistenceService call ["acknowledgeAssignment", [_taskID, _patch]] };
        };
        if !(_transitionResult getOrDefault ["success", false]) exitWith {
            _result set ["message", switch (_transition) do {
                case "decline": { "CAD extension rejected the decline." };
                default { "CAD extension rejected the acknowledgement." };
            }];
            _result
        };

        private _transitionData = +(_transitionResult getOrDefault ["data", createHashMap]);
        _assignment = +(_transitionData getOrDefault ["assignment", createHashMap]);
        if (_assignment isEqualTo createHashMap) exitWith {
            _result set ["message", "CAD extension returned an invalid assignment."];
            _result
        };

        private _activityEntry = +(_transitionData getOrDefault ["activity", createHashMap]);
        if (_activityEntry isNotEqualTo createHashMap) then {
            if (_isDispatchOrder) then {
                _activityEntry set ["type", format ["dispatch_order_%1", _transition]];
                _activityEntry set ["message", format ["%1 %2d %3.", _requesterUid, _transition, _taskID]];
            };

            private _activityRepository = _self getOrDefault ["activityRepository", createHashMap];
            _activityRepository call ["appendEntry", [_activityEntry]];
        };

        _result set ["success", true];
        _result set ["message", switch (_transition) do {
            case "decline": { [_transitionData getOrDefault ["message", "Task declined and returned to the contract board."], "Dispatch order declined and returned to the dispatch board."] select _isDispatchOrder };
            default { [_transitionData getOrDefault ["message", "Task acknowledged."], "Dispatch order acknowledged."] select _isDispatchOrder };
        }];
        _result set ["assignment", _assignment];
        _result set ["isDispatchOrder", _isDispatchOrder];
        _result
    }],
    ["acknowledgeTask", compileFinal {
        _self call ["applyAssignmentTransition", [_this # 0, _this # 1, "acknowledge"]]
    }],
    ["declineTask", compileFinal {
        _self call ["applyAssignmentTransition", [_this # 0, _this # 1, "decline"]]
    }]
];

createHashMapObject [GVAR(AssignmentRepositoryBaseClass)]
