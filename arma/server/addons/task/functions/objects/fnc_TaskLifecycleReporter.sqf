#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Task lifecycle timestamp tracking and event reporting.
 *
 * Owns task lifecycle timestamps and emits task lifecycle events through the
 * common event bus. TaskStore remains the public facade.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Task lifecycle reporter object <HASHMAP OBJECT>
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TaskLifecycleReporter) = createHashMapObject [[
    ["#type", "TaskLifecycleReporter"],
    ["#create", compileFinal {
        _self call ["resetRuntimeState", []];
    }],
    ["resetRuntimeState", compileFinal {
        _self set ["taskLifecycleRegistry", createHashMap];
        true
    }],
    ["recordTaskCreated", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _lifecycleRegistry = _self getOrDefault ["taskLifecycleRegistry", createHashMap];
        private _lifecycle = +(_lifecycleRegistry getOrDefault [_taskID, createHashMap]);
        _lifecycle set ["createdAt", serverTime];
        _lifecycleRegistry set [_taskID, _lifecycle];
        _self set ["taskLifecycleRegistry", _lifecycleRegistry];
        true
    }],
    ["recordTaskStatus", compileFinal {
        params [["_taskID", "", [""]], ["_status", "", [""]]];

        if (_taskID isEqualTo "" || { _status isEqualTo "" }) exitWith { "" };

        private _normalizedStatus = toLowerANSI _status;
        private _lifecycleRegistry = _self getOrDefault ["taskLifecycleRegistry", createHashMap];
        private _lifecycle = +(_lifecycleRegistry getOrDefault [_taskID, createHashMap]);
        private _eventName = "";

        switch (_normalizedStatus) do {
            case "active": {
                _lifecycle set ["startedAt", serverTime];
                _eventName = "task.started";
            };
            case "succeeded": {
                _lifecycle set ["finishedAt", serverTime];
                _eventName = "task.completed";
            };
            case "failed": {
                _lifecycle set ["finishedAt", serverTime];
                _eventName = "task.failed";
            };
        };

        _lifecycleRegistry set [_taskID, _lifecycle];
        _self set ["taskLifecycleRegistry", _lifecycleRegistry];

        _eventName
    }],
    ["clearTaskLifecycle", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _lifecycleRegistry = _self getOrDefault ["taskLifecycleRegistry", createHashMap];
        _lifecycleRegistry deleteAt _taskID;
        _self set ["taskLifecycleRegistry", _lifecycleRegistry];
        true
    }],
    ["buildTaskLifecycleEventPayload", compileFinal {
        params [["_taskID", "", [""]], ["_status", "", [""]], ["_extra", createHashMap]];

        if !(_extra isEqualType createHashMap) then {
            _extra = createHashMap;
        };

        private _catalogEntry = GVAR(TaskCatalogStore) call ["getTaskCatalogEntry", [_taskID]];
        private _lifecycleRegistry = _self getOrDefault ["taskLifecycleRegistry", createHashMap];
        private _lifecycle = +(_lifecycleRegistry getOrDefault [_taskID, createHashMap]);
        private _startedAt = _lifecycle getOrDefault ["startedAt", -1];
        private _finishedAt = _lifecycle getOrDefault ["finishedAt", -1];

        createHashMapFromArray [
            ["taskID", _taskID],
            ["taskType", _catalogEntry getOrDefault ["type", ""]],
            ["title", _catalogEntry getOrDefault ["title", _taskID]],
            ["description", _catalogEntry getOrDefault ["description", ""]],
            ["position", +(_catalogEntry getOrDefault ["position", []])],
            ["status", _status],
            ["source", _catalogEntry getOrDefault ["source", "task"]],
            ["requesterUid", _catalogEntry getOrDefault ["requesterUid", ""]],
            ["orgID", _catalogEntry getOrDefault ["orgID", "default"]],
            ["startedAt", _startedAt],
            ["finishedAt", _finishedAt],
            ["duration", if (_startedAt >= 0 && { _finishedAt >= 0 }) then { _finishedAt - _startedAt } else { -1 }],
            ["failureReason", _extra getOrDefault ["failureReason", ""]],
            ["participants", GVAR(TaskParticipantTracker) call ["getTaskParticipantUids", [_taskID]]],
            ["rewardData", +(_extra getOrDefault ["rewardData", createHashMap])],
            ["resultSnapshot", +(_extra getOrDefault ["resultSnapshot", createHashMap])],
            ["catalogEntry", +_catalogEntry]
        ]
    }],
    ["emitTaskLifecycleEvent", compileFinal {
        params [["_eventName", "", [""]], ["_taskID", "", [""]], ["_status", "", [""]], ["_extra", createHashMap]];

        if (_eventName isEqualTo "" || { _taskID isEqualTo "" }) exitWith { createHashMap };
        if (isNil QEGVAR(common,EventBus)) exitWith { createHashMap };

        EGVAR(common,EventBus) call ["emit", [
            _eventName,
            _self call ["buildTaskLifecycleEventPayload", [_taskID, _status, _extra]],
            createHashMapFromArray [["source", "task"]]
        ]]
    }]
]];

GVAR(TaskLifecycleReporter)
