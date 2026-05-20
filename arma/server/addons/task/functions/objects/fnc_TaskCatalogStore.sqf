#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Catalog/status/chaining store for task metadata.
 *
 * TaskStore keeps the public facade used by the rest of the task system. This
 * object owns catalog persistence calls, active status, acceptance, and chained
 * task availability.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Task catalog store object <HASHMAP OBJECT>
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TaskCatalogStore) = createHashMapObject [[
    ["#type", "TaskCatalogStore"],
    ["#create", compileFinal {
        _self call ["resetRuntimeState", []];
    }],
    ["resetRuntimeState", compileFinal {
        _self set ["completedTaskRegistry", createHashMap];
        _self set ["taskDependencyRegistry", createHashMap];
        true
    }],
    ["bindTaskOwnership", compileFinal {
        params [["_taskID", "", [""]], ["_requesterUid", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["requesterUid", _requesterUid],
            ["orgID", "default"],
            ["message", ""]
        ];

        if (_taskID isEqualTo "") exitWith {
            _result set ["message", "Missing task ID."];
            _result
        };

        private _orgID = "default";

        if (_requesterUid isNotEqualTo "") then {
            private _actor = EGVAR(actor,ActorStore) call ["load", [_requesterUid]];

            if (_actor isEqualTo createHashMap) exitWith {
                _result set ["message", format ["Failed to load actor for %1.", _requesterUid]];
                _result
            };

            _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        };

        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["orgId", _orgID]
        ];
        private _envelope = GVAR(TaskStateGateway) call [
            "callTaskStateEnvelope",
            [
                "task:ownership:bind",
                [_taskID, toJSON _context]
            ]
        ];
        if !(_envelope getOrDefault ["success", false]) exitWith {
            _result set ["message", _envelope getOrDefault ["error", "Failed to bind task ownership."]];
            _result
        };

        private _bindResult = _envelope getOrDefault ["data", createHashMap];
        _result set ["success", true];
        _result set ["message", _bindResult getOrDefault [
            "message",
            ["No requester UID provided. Bound task to default organization.", "Task ownership updated."] select (_requesterUid isNotEqualTo "")
        ]];
        _result set ["orgID", _bindResult getOrDefault ["orgId", _orgID]];
        _result
    }],
    ["releaseTaskOwnership", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _envelope = GVAR(TaskStateGateway) call ["callTaskStateEnvelope", ["task:ownership:release", [_taskID]]];
        _envelope getOrDefault ["success", false]
    }],
    ["normalizePrerequisiteTaskIds", compileFinal {
        params [["_value", [], [[], ""]]];

        if (_value isEqualType "") then { _value = [_value]; };
        if !(_value isEqualType []) exitWith { [] };

        private _taskIDs = [];
        {
            if !(_x isEqualType "") then { continue; };
            if (_x isEqualTo "") then { continue; };
            _taskIDs pushBackUnique _x;
        } forEach _value;

        _taskIDs
    }],
    ["getTaskPrerequisites", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { [] };

        private _dependencyRegistry = _self getOrDefault ["taskDependencyRegistry", createHashMap];
        +(_dependencyRegistry getOrDefault [_taskID, []])
    }],
    ["isTaskCompleted", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _completedRegistry = _self getOrDefault ["completedTaskRegistry", createHashMap];
        if (_completedRegistry getOrDefault [_taskID, false]) exitWith { true };

        (_self call ["getTaskStatus", [_taskID]]) isEqualTo "succeeded"
    }],
    ["areTaskPrerequisitesSatisfied", compileFinal {
        params [["_taskID", "", [""]], ["_entry", createHashMap, [createHashMap]]];

        private _prerequisites = _self call ["getTaskPrerequisites", [_taskID]];
        if (_prerequisites isEqualTo [] && { _entry isNotEqualTo createHashMap }) then {
            _prerequisites = _self call ["normalizePrerequisiteTaskIds", [_entry getOrDefault ["prerequisiteTaskIds", []]]];
        };
        if (_prerequisites isEqualTo []) exitWith { true };

        private _satisfied = true;
        {
            if !(_self call ["isTaskCompleted", [_x]]) exitWith { _satisfied = false; };
        } forEach _prerequisites;

        _satisfied
    }],
    ["resolveInitialTaskStatus", compileFinal {
        params [["_taskID", "", [""]], ["_entry", createHashMap, [createHashMap]]];

        if (_self call ["areTaskPrerequisitesSatisfied", [_taskID, _entry]]) exitWith { "available" };

        "locked"
    }],
    ["markTaskCompleted", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _completedRegistry = _self getOrDefault ["completedTaskRegistry", createHashMap];
        _completedRegistry set [_taskID, true];
        _self set ["completedTaskRegistry", _completedRegistry];
        true
    }],
    ["unlockDependentTasks", compileFinal {
        params [["_completedTaskID", "", [""]]];

        private _dependencyRegistry = _self getOrDefault ["taskDependencyRegistry", createHashMap];
        {
            private _dependentTaskID = _x;
            private _prerequisites = _y;

            if !(_completedTaskID in _prerequisites) then { continue; };
            if ((_self call ["getTaskStatus", [_dependentTaskID]]) isNotEqualTo "locked") then { continue; };
            if !(_self call ["areTaskPrerequisitesSatisfied", [_dependentTaskID]]) then { continue; };

            _self call ["setTaskStatus", [_dependentTaskID, "available"]];
            ["INFO", format ["Unlocked chained task '%1' after prerequisite '%2' completed.", _dependentTaskID, _completedTaskID]] call EFUNC(common,log);
        } forEach _dependencyRegistry;

        true
    }],
    ["registerTaskCatalogEntry", compileFinal {
        params [["_taskID", "", [""]], ["_entry", createHashMap, [createHashMap]]];

        if (_taskID isEqualTo "" || { _entry isEqualTo createHashMap }) exitWith { false };

        _entry set ["taskID", _taskID];
        _entry set ["taskId", _taskID];

        private _prerequisiteTaskIds = _self call ["normalizePrerequisiteTaskIds", [_entry getOrDefault ["prerequisiteTaskIds", []]]];
        _entry set ["prerequisiteTaskIds", _prerequisiteTaskIds];

        private _dependencyRegistry = _self getOrDefault ["taskDependencyRegistry", createHashMap];
        if (_prerequisiteTaskIds isEqualTo []) then {
            _dependencyRegistry deleteAt _taskID;
        } else {
            _dependencyRegistry set [_taskID, _prerequisiteTaskIds];
        };
        _self set ["taskDependencyRegistry", _dependencyRegistry];

        private _initialStatus = ["available", "locked"] select !(_self call ["areTaskPrerequisitesSatisfied", [_taskID, _entry]]);
        _entry set ["locked", _initialStatus isEqualTo "locked"];

        private _envelope = GVAR(TaskStateGateway) call [
            "callTaskStateEnvelope",
            [
                "task:catalog:upsert",
                [_taskID, toJSON _entry]
            ]
        ];
        private _registered = _envelope getOrDefault ["success", false];

        if (_registered) then {
            GVAR(TaskLifecycleReporter) call ["recordTaskCreated", [_taskID]];
            GVAR(TaskLifecycleReporter) call ["emitTaskLifecycleEvent", ["task.created", _taskID, "created", createHashMap]];
            _self call ["setTaskStatus", [_taskID, _initialStatus]];
        };

        _registered
    }],
    ["getActiveTaskCatalog", compileFinal {
        private _entries = GVAR(TaskStateGateway) call ["callTaskState", ["task:catalog:active", [], []]];
        if !(_entries isEqualType []) exitWith { [] };

        private _visibleEntries = [];
        {
            if !(_x isEqualType createHashMap) then { continue; };

            private _taskID = _x getOrDefault ["taskID", _x getOrDefault ["taskId", ""]];
            if (_taskID isEqualTo "") then { continue; };

            private _status = _self call ["getTaskStatus", [_taskID]];
            if !(_status in ["available", "assigned", "active"]) then { continue; };
            if !(_self call ["areTaskPrerequisitesSatisfied", [_taskID, _x]]) then { continue; };

            _visibleEntries pushBack _x;
        } forEach _entries;

        _visibleEntries
    }],
    ["hasTaskCatalogEntry", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _entry = GVAR(TaskStateGateway) call ["callTaskState", ["task:catalog:get", [_taskID], objNull]];
        _entry isEqualType createHashMap
    }],
    ["getTaskCatalogEntry", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { createHashMap };

        [(GVAR(TaskStateGateway) call ["callTaskState", ["task:catalog:get", [_taskID], createHashMap]])] params [["_entry", createHashMap, [createHashMap]]];
        if !(_entry isEqualType createHashMap) exitWith { createHashMap };

        _entry
    }],
    ["isTaskAccepted", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        [(_self call ["getTaskCatalogEntry", [_taskID]])] params [["_entry", createHashMap, [createHashMap]]];
        if (_entry isEqualTo createHashMap) exitWith { false };

        [(_entry getOrDefault ["accepted", false])] params [["_accepted", false, [false]]];
        [(_entry getOrDefault ["requesterUid", ""])] params [["_requesterUid", "", [""]]];

        _accepted || { _requesterUid isNotEqualTo "" }
    }],
    ["acceptTask", compileFinal {
        params [["_taskID", "", [""]], ["_requesterUid", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to accept task."],
            ["entry", createHashMap]
        ];

        if (_taskID isEqualTo "" || { _requesterUid isEqualTo "" }) exitWith {
            _result set ["message", "Missing task ID or requester UID."];
            _result
        };

        private _actor = EGVAR(actor,ActorStore) call ["load", [_requesterUid]];
        if (_actor isEqualTo createHashMap) exitWith {
            _result set ["message", format ["Failed to load actor for %1.", _requesterUid]];
            _result
        };

        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];

        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["orgId", _orgID]
        ];
        private _envelope = GVAR(TaskStateGateway) call [
            "callTaskStateEnvelope",
            [
                "task:ownership:accept",
                [_taskID, toJSON _context]
            ]
        ];
        if !(_envelope getOrDefault ["success", false]) exitWith {
            _result set ["message", _envelope getOrDefault ["error", "Unable to accept task."]];
            _result
        };

        private _acceptResult = _envelope getOrDefault ["data", createHashMap];
        private _entry = _acceptResult getOrDefault ["entry", createHashMap];
        if !(_entry isEqualType createHashMap) then { _entry = createHashMap; };

        _result set ["success", true];
        _result set ["message", _acceptResult getOrDefault ["message", "Task accepted."]];
        _result set ["entry", _entry];
        _result
    }],
    ["setTaskStatus", compileFinal {
        params [["_taskID", "", [""]], ["_status", "", [""]]];

        if (_taskID isEqualTo "" || { _status isEqualTo "" }) exitWith { false };

        private _envelope = GVAR(TaskStateGateway) call ["callTaskStateEnvelope", ["task:status:set", [_taskID, _status]]];
        private _statusResult = _envelope getOrDefault ["success", false];

        if (_statusResult) then {
            private _normalizedStatus = toLowerANSI _status;
            private _eventName = GVAR(TaskLifecycleReporter) call ["recordTaskStatus", [_taskID, _normalizedStatus]];

            if (_eventName isNotEqualTo "") then {
                GVAR(TaskLifecycleReporter) call ["emitTaskLifecycleEvent", [_eventName, _taskID, _normalizedStatus, createHashMap]];
            };

            if (_normalizedStatus isEqualTo "succeeded") then {
                _self call ["markTaskCompleted", [_taskID]];
                _self call ["unlockDependentTasks", [_taskID]];
            };
        };

        _statusResult
    }],
    ["getTaskStatus", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { "" };

        [(GVAR(TaskStateGateway) call ["callTaskState", ["task:status:get", [_taskID], ""]])] params [["_status", "", [""]]];
        _status
    }],
    ["clearTaskStatus", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        [(GVAR(TaskStateGateway) call ["callTaskState", ["task:status:clear", [_taskID], false]])] params [["_statusResult", false, [false]]];

        _statusResult
    }]
]];

GVAR(TaskCatalogStore)
