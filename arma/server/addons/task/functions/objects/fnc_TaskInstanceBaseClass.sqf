#include "..\script_component.hpp"

/*
 * Object-style base class for object-based task instances.
 *
 * Example:
 * call compile preprocessFileLineNumbers
 *     "\forge\forge_server\addons\task\objects\TaskInstanceBaseClass.sqf";
 *
 * private _task = createHashMapObject [
 *     GVAR(TaskInstanceBaseClass),
 *     [
 *         "task_review_001",
 *         "custom",
 *         createHashMap,
 *         createHashMapFromArray [
 *             ["funds", 50000],
 *             ["ratingSuccess", 25]
 *         ]
 *     ]
 * ];
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TaskInstanceBaseClass) = createHashMapFromArray [
    ["#type", "TaskInstanceBaseClass"],
    ["initializeBaseState", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_taskType", "custom", [""]],
            ["_entities", createHashMap, [createHashMap]],
            ["_taskParams", createHashMap, [createHashMap]]
        ];

        _self set ["taskID", _taskID];
        _self set ["taskType", _taskType];
        _self set ["entities", _entities];
        _self set ["taskParams", _taskParams];
        _self set ["status", "created"];
        _self set ["startedAt", -1];
        _self set ["finishedAt", -1];
        _self set ["failureReason", ""];
        _self set ["resultSnapshot", createHashMap];
        _self set ["rewardData", createHashMapFromArray [
            ["funds", _taskParams getOrDefault ["funds", 0]],
            ["ratingFail", _taskParams getOrDefault ["ratingFail", 0]],
            ["ratingSuccess", _taskParams getOrDefault ["ratingSuccess", 0]],
            ["equipment", _taskParams getOrDefault ["equipment", []]],
            ["supplies", _taskParams getOrDefault ["supplies", []]],
            ["weapons", _taskParams getOrDefault ["weapons", []]],
            ["vehicles", _taskParams getOrDefault ["vehicles", []]],
            ["special", _taskParams getOrDefault ["special", []]]
        ]];
        true
    }],
    ["#create", compileFinal {
        private _taskID = "";
        private _taskType = "custom";
        private _entities = createHashMap;
        private _taskParams = createHashMap;

        if (_this isEqualType [] && { count _this > 0 }) then {
            _taskID = _this param [0, "", [""]];

            if ((count _this > 1) && { (_this select 1) isEqualType "" }) then {
                _taskType = _this param [1, "custom", [""]];
                _entities = _this param [2, createHashMap, [createHashMap]];
                _taskParams = _this param [3, createHashMap, [createHashMap]];
            } else {
                _entities = _this param [1, createHashMap, [createHashMap]];
                _taskParams = _this param [2, createHashMap, [createHashMap]];
            };
        };

        _self call ["initializeBaseState", [_taskID, _taskType, _entities, _taskParams]];
    }],
    ["getTaskID", compileFinal {
        _self getOrDefault ["taskID", ""]
    }],
    ["getTaskType", compileFinal {
        _self getOrDefault ["taskType", ""]
    }],
    ["getStatus", compileFinal {
        _self getOrDefault ["status", "created"]
    }],
    ["getRewardData", compileFinal {
        _self getOrDefault ["rewardData", createHashMap]
    }],
    ["getRegistryKey", compileFinal {
        _self getOrDefault ["taskID", ""]
    }],
    ["registerInstance", compileFinal {
        private _registryKey = _self call ["getRegistryKey", []];
        if (_registryKey isEqualTo "") exitWith { false };

        private _registry = missionNamespace getVariable [QGVAR(ObjectTaskInstances), createHashMap];
        _registry set [_registryKey, _self];
        missionNamespace setVariable [QGVAR(ObjectTaskInstances), _registry];
        missionNamespace setVariable [_registryKey, _self];
        true
    }],
    ["unregisterInstance", compileFinal {
        private _registryKey = _self call ["getRegistryKey", []];
        if (_registryKey isEqualTo "") exitWith { false };

        private _registry = missionNamespace getVariable [QGVAR(ObjectTaskInstances), createHashMap];
        _registry deleteAt _registryKey;
        missionNamespace setVariable [_registryKey, nil];
        true
    }],
    ["buildLifecycleEventPayload", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _taskType = _self getOrDefault ["taskType", "custom"];
        private _status = _self getOrDefault ["status", "created"];
        private _startedAt = _self getOrDefault ["startedAt", -1];
        private _finishedAt = _self getOrDefault ["finishedAt", -1];
        private _participantUids = [];

        if (
            _taskID isNotEqualTo ""
            && { _self getOrDefault ["useTaskStore", false] }
            && { !(isNil QGVAR(TaskStore)) }
        ) then {
            _participantUids = GVAR(TaskStore) call ["getTaskParticipantUids", [_taskID]];
        };

        private _payload = createHashMapFromArray [
            ["taskID", _taskID],
            ["taskType", _taskType],
            ["status", _status],
            ["startedAt", _startedAt],
            ["finishedAt", _finishedAt],
            ["duration", if (_startedAt >= 0 && { _finishedAt >= 0 }) then { _finishedAt - _startedAt } else { -1 }],
            ["failureReason", _self getOrDefault ["failureReason", ""]],
            ["participants", _participantUids],
            ["rewardData", +(_self getOrDefault ["rewardData", createHashMap])],
            ["resultSnapshot", +(_self getOrDefault ["resultSnapshot", createHashMap])]
        ];

        _payload
    }],
    ["emitLifecycleEvent", compileFinal {
        params [["_eventName", "", [""]]];

        if (_eventName isEqualTo "") exitWith { createHashMap };
        if (isNil QEGVAR(common,EventBus)) exitWith { createHashMap };

        EGVAR(common,EventBus) call ["emit", [
            _eventName,
            _self call ["buildLifecycleEventPayload", []],
            createHashMapFromArray [["source", "task"]]
        ]]
    }],
    ["markActive", compileFinal {
        _self set ["status", "active"];
        _self set ["startedAt", serverTime];
        if !(_self getOrDefault ["useTaskStore", false]) then {
            _self call ["emitLifecycleEvent", ["task.started"]];
        };
        true
    }],
    ["markSucceeded", compileFinal {
        params [["_resultSnapshot", createHashMap, [createHashMap]]];

        _self set ["status", "succeeded"];
        _self set ["finishedAt", serverTime];
        _self set ["resultSnapshot", _resultSnapshot];
        if !(_self getOrDefault ["useTaskStore", false]) then {
            _self call ["emitLifecycleEvent", ["task.completed"]];
        };
        true
    }],
    ["markFailed", compileFinal {
        params [["_reason", "", [""]], ["_resultSnapshot", createHashMap, [createHashMap]]];

        _self set ["status", "failed"];
        _self set ["finishedAt", serverTime];
        _self set ["failureReason", _reason];
        _self set ["resultSnapshot", _resultSnapshot];
        if !(_self getOrDefault ["useTaskStore", false]) then {
            _self call ["emitLifecycleEvent", ["task.failed"]];
        };
        true
    }],
    ["cleanup", compileFinal {
        _self call ["unregisterInstance", []]
    }],
    ["tick", compileFinal {
        createHashMap
    }],
    ["runLoop", compileFinal {
        false
    }]
];
