#include "..\script_component.hpp"

/*
 * Review-only prototype defuse task class.
 *
 * Example:
 * call compile preprocessFileLineNumbers
 *     "\forge\forge_server\addons\task\prototypes\TaskInstanceBaseClass.sqf";
 * call compile preprocessFileLineNumbers
 *     "\forge\forge_server\addons\task\prototypes\DefuseTaskBaseClass.sqf";
 *
 * private _task = createHashMapObject [
 *     GVAR(DefuseTaskBaseClass),
 *     [
 *         "task_defuse_review",
 *         createHashMapFromArray [
 *             ["ieds", [ied1, ied2]],
 *             ["protected", [truck1]]
 *         ],
 *         createHashMapFromArray [
 *             ["limitSuccess", 2],
 *             ["limitFail", 1],
 *             ["iedTimer", 300],
 *             ["funds", 75000],
 *             ["ratingSuccess", 30]
 *         ]
 *     ]
 * ];
 *
 * [_task] spawn {
 *     params ["_task"];
 *     _task call ["runLoop", []];
 * };
 *
 * Note:
 * `runLoop` uses `sleep`, so it must be entered from scheduled code.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(DefuseTaskBaseClass) = createHashMapFromArray [
    ["#base", GVAR(TaskInstanceBaseClass)],
    ["#type", "DefuseTaskBaseClass"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entities", createHashMap, [createHashMap]],
            ["_taskParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeBaseState", [_taskID, "defuse", _entities, _taskParams]];

        private _ieds = +(_entities getOrDefault ["ieds", []]);
        private _protected = +(_entities getOrDefault ["protected", []]);
        private _requiredDefusals = _taskParams getOrDefault ["limitSuccess", -1];
        if (_requiredDefusals < 0) then { _requiredDefusals = count _ieds; };

        private _maxProtectedLosses = _taskParams getOrDefault ["limitFail", -1];
        if (_maxProtectedLosses < 0) then { _maxProtectedLosses = count _protected; };

        _self set ["ieds", _ieds];
        _self set ["protected", _protected];
        _self set ["requiredDefusals", _requiredDefusals];
        _self set ["maxProtectedLosses", _maxProtectedLosses];
        _self set ["iedTimer", _taskParams getOrDefault ["iedTimer", 300]];
        _self set ["useTaskStore", _taskParams getOrDefault ["useTaskStore", false]];
        _self set ["localDefuseCount", _taskParams getOrDefault ["localDefuseCount", 0]];

        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["countProtectedDestroyed", compileFinal {
        private _protected = _self getOrDefault ["protected", []];
        { !alive _x } count _protected
    }],
    ["getDefuseCount", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "") exitWith { 0 };
        if !(_self getOrDefault ["useTaskStore", false]) exitWith {
            _self getOrDefault ["localDefuseCount", 0]
        };

        GVAR(TaskStore) call ["getDefuseCount", [_taskID]]
    }],
    ["incrementLocalDefuseCount", compileFinal {
        private _next = (_self getOrDefault ["localDefuseCount", 0]) + 1;
        _self set ["localDefuseCount", _next];
        _next
    }],
    ["tick", compileFinal {
        private _defusedCount = _self call ["getDefuseCount", []];
        private _protectedDestroyed = _self call ["countProtectedDestroyed", []];
        private _requiredDefusals = _self getOrDefault ["requiredDefusals", 0];
        private _maxProtectedLosses = _self getOrDefault ["maxProtectedLosses", 0];

        createHashMapFromArray [
            ["defusedCount", _defusedCount],
            ["protectedDestroyed", _protectedDestroyed],
            ["requiredDefusals", _requiredDefusals],
            ["maxProtectedLosses", _maxProtectedLosses],
            ["shouldFail", (_protectedDestroyed >= _maxProtectedLosses) && { _maxProtectedLosses > 0 }],
            ["shouldSucceed", (_defusedCount >= _requiredDefusals) && { _requiredDefusals > 0 } && { _protectedDestroyed < _maxProtectedLosses || { _maxProtectedLosses <= 0 } }]
        ]
    }],
    ["handleFailureOutcome", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _ieds = _self getOrDefault ["ieds", []];
        private _protected = _self getOrDefault ["protected", []];
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingFail = _rewardData getOrDefault ["ratingFail", 0];
        private _endFail = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endFail", false];

        { deleteVehicle _x } forEach _ieds;
        { deleteVehicle _x } forEach _protected;

        if (_self getOrDefault ["useTaskStore", false]) then {
            [_taskID, "FAILED"] call BFUNC(taskSetState);
            GVAR(TaskStore) call ["setTaskStatus", [_taskID, "failed"]];

            sleep 1;

            GVAR(TaskStore) call ["notifyParticipants", [_taskID, "warning", "Tasks", format ["Task failed: %1 reputation", _ratingFail]]];
            GVAR(TaskStore) call ["applyRatingOutcome", [_taskID, _ratingFail]];
            GVAR(TaskStore) call ["clearTask", [_taskID]];
        };

        if (_endFail) then { "EveryoneLost" call BFUNC(endMissionServer); };
        true
    }],
    ["handleSuccessOutcome", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _ieds = _self getOrDefault ["ieds", []];
        private _protected = _self getOrDefault ["protected", []];
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingSuccess = _rewardData getOrDefault ["ratingSuccess", 0];
        private _funds = _rewardData getOrDefault ["funds", 0];
        private _endSuccess = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endSuccess", false];

        { deleteVehicle _x } forEach _ieds;
        { deleteVehicle _x } forEach _protected;

        if (_self getOrDefault ["useTaskStore", false]) then {
            [_taskID, _rewardData] call FUNC(handleTaskRewards);
            [_taskID, "SUCCEEDED"] call BFUNC(taskSetState);
            GVAR(TaskStore) call ["setTaskStatus", [_taskID, "succeeded"]];

            sleep 1;

            GVAR(TaskStore) call ["notifyParticipants", [_taskID, "success", "Tasks", format ["Task completed: %1 reputation, $%2 funds", _ratingSuccess, [_funds] call EFUNC(common,formatNumber)]]];
            GVAR(TaskStore) call ["applyRatingOutcome", [_taskID, _ratingSuccess]];
            GVAR(TaskStore) call ["clearTask", [_taskID]];
        };

        if (_endSuccess) then { "EveryoneWon" call BFUNC(endMissionServer); };
        true
    }],
    ["runLoop", compileFinal {
        _self call ["markActive", []];

        while { (_self call ["getStatus", []]) isEqualTo "active" } do {
            private _snapshot = _self call ["tick", []];

            if (_snapshot getOrDefault ["shouldFail", false]) exitWith {
                _self call ["markFailed", ["Defuse fail conditions met.", _snapshot]];
            };

            if (_snapshot getOrDefault ["shouldSucceed", false]) exitWith {
                _self call ["markSucceeded", [_snapshot]];
            };

            sleep 1;
        };

        if ((_self call ["getStatus", []]) isEqualTo "failed") then {
            _self call ["handleFailureOutcome", []];
        } else {
            _self call ["handleSuccessOutcome", []];
        };

        _self call ["cleanup", []];
        true
    }]
];
