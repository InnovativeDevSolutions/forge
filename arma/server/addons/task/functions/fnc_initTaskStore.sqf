#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the task store for task entity tracking, participant
 * contribution tracking, and task outcome application.
 *
 * Task metadata is extension-backed but intentionally transient. The task
 * backend is reset explicitly from task preInit so task/catalog/status state
 * starts clean before mission setup repopulates contracts.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Task store object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_task_fnc_initTaskStore
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TaskStore) = createHashMapObject [[
    ["#type", "TaskStore"],
    ["#create", compileFinal {}],
    ["resetMissionState", compileFinal {
        GVAR(TaskLifecycleReporter) call ["resetRuntimeState", []];
        GVAR(TaskCatalogStore) call ["resetRuntimeState", []];
        GVAR(TaskEntityRegistry) call ["resetRuntimeState", []];
        GVAR(TaskParticipantTracker) call ["resetRuntimeState", []];

        GVAR(TaskStateGateway) call ["reset", []]
    }],
    ["bindTaskOwnership", compileFinal {
        params [["_taskID", "", [""]], ["_requesterUid", "", [""]]];
        GVAR(TaskCatalogStore) call ["bindTaskOwnership", [_taskID, _requesterUid]]
    }],
    ["releaseTaskOwnership", compileFinal {
        params [["_taskID", "", [""]]];
        GVAR(TaskCatalogStore) call ["releaseTaskOwnership", [_taskID]]
    }],
    ["buildTaskLifecycleEventPayload", compileFinal {
        GVAR(TaskLifecycleReporter) call ["buildTaskLifecycleEventPayload", _this]
    }],
    ["emitTaskLifecycleEvent", compileFinal {
        GVAR(TaskLifecycleReporter) call ["emitTaskLifecycleEvent", _this]
    }],
    ["normalizePrerequisiteTaskIds", compileFinal {
        GVAR(TaskCatalogStore) call ["normalizePrerequisiteTaskIds", _this]
    }],
    ["getTaskPrerequisites", compileFinal {
        GVAR(TaskCatalogStore) call ["getTaskPrerequisites", _this]
    }],
    ["isTaskCompleted", compileFinal {
        GVAR(TaskCatalogStore) call ["isTaskCompleted", _this]
    }],
    ["areTaskPrerequisitesSatisfied", compileFinal {
        GVAR(TaskCatalogStore) call ["areTaskPrerequisitesSatisfied", _this]
    }],
    ["resolveInitialTaskStatus", compileFinal {
        GVAR(TaskCatalogStore) call ["resolveInitialTaskStatus", _this]
    }],
    ["markTaskCompleted", compileFinal {
        GVAR(TaskCatalogStore) call ["markTaskCompleted", _this]
    }],
    ["unlockDependentTasks", compileFinal {
        GVAR(TaskCatalogStore) call ["unlockDependentTasks", _this]
    }],
    ["registerTaskCatalogEntry", compileFinal {
        GVAR(TaskCatalogStore) call ["registerTaskCatalogEntry", _this]
    }],
    ["getActiveTaskCatalog", compileFinal {
        GVAR(TaskCatalogStore) call ["getActiveTaskCatalog", _this]
    }],
    ["hasTaskCatalogEntry", compileFinal {
        GVAR(TaskCatalogStore) call ["hasTaskCatalogEntry", _this]
    }],
    ["getTaskCatalogEntry", compileFinal {
        GVAR(TaskCatalogStore) call ["getTaskCatalogEntry", _this]
    }],
    ["isTaskAccepted", compileFinal {
        GVAR(TaskCatalogStore) call ["isTaskAccepted", _this]
    }],
    ["acceptTask", compileFinal {
        GVAR(TaskCatalogStore) call ["acceptTask", _this]
    }],
    ["setTaskStatus", compileFinal {
        GVAR(TaskCatalogStore) call ["setTaskStatus", _this]
    }],
    ["getTaskStatus", compileFinal {
        GVAR(TaskCatalogStore) call ["getTaskStatus", _this]
    }],
    ["clearTaskStatus", compileFinal {
        GVAR(TaskCatalogStore) call ["clearTaskStatus", _this]
    }],
    ["registerTaskEntity", compileFinal {
        GVAR(TaskEntityRegistry) call ["registerTaskEntity", _this]
    }],
    ["getTaskEntities", compileFinal {
        GVAR(TaskEntityRegistry) call ["getTaskEntities", _this]
    }],
    ["findTaskEntityOwner", compileFinal {
        GVAR(TaskEntityRegistry) call ["findTaskEntityOwner", _this]
    }],
    ["clearTaskEntities", compileFinal {
        GVAR(TaskEntityRegistry) call ["clearTaskEntities", _this]
    }],
    ["trackParticipants", compileFinal {
        GVAR(TaskParticipantTracker) call ["trackParticipants", _this]
    }],
    ["getTaskParticipants", compileFinal {
        GVAR(TaskParticipantTracker) call ["getTaskParticipants", _this]
    }],
    ["getTaskParticipantUids", compileFinal {
        GVAR(TaskParticipantTracker) call ["getTaskParticipantUids", _this]
    }],
    ["resolveRewardContext", compileFinal {
        GVAR(TaskRewardService) call ["resolveRewardContext", _this]
    }],
    ["incrementDefuseCount", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { 0 };

        [GVAR(TaskStateGateway) call ["callTaskState", ["task:defuse:increment", [_taskID], 0]]] params [["_count", 0, [0]]];
        _count
    }],
    ["getDefuseCount", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { 0 };

        [GVAR(TaskStateGateway) call ["callTaskState", ["task:defuse:get", [_taskID], 0]]] params [["_count", 0, [0]]];
        _count
    }],
    ["notifyParticipants", compileFinal {
        GVAR(TaskParticipantTracker) call ["notifyParticipants", _this]
    }],
    ["clearTask", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        _self call ["emitTaskLifecycleEvent", ["task.cleared", _taskID, "cleared", createHashMap]];

        GVAR(TaskLifecycleReporter) call ["clearTaskLifecycle", [_taskID]];
        GVAR(TaskParticipantTracker) call ["clearTaskParticipants", [_taskID]];
        GVAR(TaskStateGateway) call ["callTaskState", ["task:clear", [_taskID], false]];
        _self call ["clearTaskEntities", [_taskID]];
        true
    }],
    ["applyRatingOutcome", compileFinal {
        GVAR(TaskRewardService) call ["applyRatingOutcome", _this]
    }]
]];

GVAR(TaskStore)
