#include "..\script_component.hpp"

/*
 * Object-style attack task class.
 *
 * Example:
 * call compile preprocessFileLineNumbers
 *     "\forge\forge_server\addons\task\objects\TaskInstanceBaseClass.sqf";
 * call compile preprocessFileLineNumbers
 *     "\forge\forge_server\addons\task\objects\AttackTaskBaseClass.sqf";
 *
 * private _task = createHashMapObject [
 *     GVAR(AttackTaskBaseClass),
 *     [
 *         "task_attack_review",
 *         createHashMapFromArray [
 *             ["targets", [unit1, unit2, unit3]]
 *         ],
 *         createHashMapFromArray [
 *             ["limitSuccess", 3],
 *             ["timeLimit", 900],
 *             ["funds", 50000],
 *             ["ratingSuccess", 25]
 *         ]
 *     ]
 * ];
 *
 * [_task] spawn {
 *     params ["_task"];
 *     _task call ["runLoop", []];
 * };
 * _task = nil; // Safe after the spawned closure has captured the reference.
 *
 * Note:
 * `runLoop` uses `sleep`, so it must be entered from scheduled code.
 */

#pragma hemtt ignore_variables ["_self"]

GVAR(AttackTaskBaseClass) = createHashMapFromArray [
    ["#base", GVAR(TaskInstanceBaseClass)],
    ["#type", "AttackTaskBaseClass"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entities", createHashMap, [createHashMap]],
            ["_taskParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeBaseState", [_taskID, "attack", _entities, _taskParams]];

        private _targets = +(_entities getOrDefault ["targets", []]);
        private _requiredKills = _taskParams getOrDefault ["limitSuccess", -1];
        if (_requiredKills < 0) then { _requiredKills = count _targets; };

        private _maxTargetLosses = _taskParams getOrDefault ["limitFail", -1];
        if (_maxTargetLosses < 0) then { _maxTargetLosses = count _targets; };

        _self set ["targets", _targets];
        _self set ["requiredKills", _requiredKills];
        _self set ["maxTargetLosses", _maxTargetLosses];
        _self set ["timeLimit", _taskParams getOrDefault ["timeLimit", 0]];
        _self set ["useTaskStore", _taskParams getOrDefault ["useTaskStore", false]];

        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["refreshTargetsFromStore", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "" || { !(_self getOrDefault ["useTaskStore", false]) }) exitWith { false };

        private _targets = GVAR(TaskStore) call ["getTaskEntities", ["targets", _taskID]];
        _self set ["targets", _targets];

        private _taskParams = _self getOrDefault ["taskParams", createHashMap];
        private _requiredKills = _taskParams getOrDefault ["limitSuccess", -1];
        if (_requiredKills < 0) then { _requiredKills = count _targets; };

        private _maxTargetLosses = _taskParams getOrDefault ["limitFail", -1];
        if (_maxTargetLosses < 0) then { _maxTargetLosses = count _targets; };

        _self set ["requiredKills", _requiredKills];
        _self set ["maxTargetLosses", _maxTargetLosses];
        true
    }],
    ["countKilledTargets", compileFinal {
        private _targets = _self getOrDefault ["targets", []];
        { !alive _x } count _targets
    }],
    ["tick", compileFinal {
        private _startedAt = _self getOrDefault ["startedAt", -1];
        private _timeLimit = _self getOrDefault ["timeLimit", 0];
        private _targetsKilled = _self call ["countKilledTargets", []];
        private _requiredKills = _self getOrDefault ["requiredKills", 0];
        private _maxTargetLosses = _self getOrDefault ["maxTargetLosses", 0];
        private _timeExpired = false;

        if (_timeLimit > 0 && { _startedAt >= 0 }) then {
            _timeExpired = (serverTime - _startedAt) >= _timeLimit;
        };

        createHashMapFromArray [
            ["targetsKilled", _targetsKilled],
            ["requiredKills", _requiredKills],
            ["maxTargetLosses", _maxTargetLosses],
            ["timeExpired", _timeExpired],
            ["shouldFail", _timeExpired && { _targetsKilled < _requiredKills }],
            ["shouldSucceed", _targetsKilled >= _requiredKills]
        ]
    }],
    ["runLoop", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _timeLimit = _self getOrDefault ["timeLimit", 0];
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingFail = _rewardData getOrDefault ["ratingFail", 0];
        private _ratingSuccess = _rewardData getOrDefault ["ratingSuccess", 0];
        private _funds = _rewardData getOrDefault ["funds", 0];
        private _endFail = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endFail", false];
        private _endSuccess = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endSuccess", false];
        private _useTaskStore = _self getOrDefault ["useTaskStore", false];

        if (_useTaskStore) then {
            waitUntil {
                sleep 1;
                _self call ["refreshTargetsFromStore", []];
                private _targets = _self getOrDefault ["targets", []];
                GVAR(TaskStore) call ["trackParticipants", [_taskID, _targets, "", 300]];
                count _targets > 0
            };
        } else {
            waitUntil {
                sleep 1;
                count (_self getOrDefault ["targets", []]) > 0
            };
        };

        if (_timeLimit isNotEqualTo 0 && { _useTaskStore }) then {
            private _catalogEntry = GVAR(TaskStore) call ["getTaskCatalogEntry", [_taskID]];
            ["INFO", format [
                "Attack task %1 initial state before acceptance wait. Accepted=%2, RequesterUid='%3', Source='%4', TimeLimit=%5s",
                _taskID,
                _catalogEntry getOrDefault ["accepted", false],
                _catalogEntry getOrDefault ["requesterUid", ""],
                _catalogEntry getOrDefault ["source", ""],
                _timeLimit
            ]] call EFUNC(common,log);

            ["INFO", format ["Attack task %1 waiting for acceptance before starting %2s time limit.", _taskID, _timeLimit]] call EFUNC(common,log);
            waitUntil {
                sleep 1;
                GVAR(TaskStore) call ["isTaskAccepted", [_taskID]]
            };

            ["INFO", format ["Attack task %1 accepted. Starting %2s time limit.", _taskID, _timeLimit]] call EFUNC(common,log);
        };

        _self call ["markActive", []];

        while { (_self call ["getStatus", []]) isEqualTo "active" } do {
            private _targets = _self getOrDefault ["targets", []];

            if (_useTaskStore) then {
                _self call ["refreshTargetsFromStore", []];
                _targets = _self getOrDefault ["targets", []];
                GVAR(TaskStore) call ["trackParticipants", [_taskID, _targets, "", 300]];
            };

            private _snapshot = _self call ["tick", []];

            if (_snapshot getOrDefault ["shouldFail", false]) exitWith {
                ["WARNING", format [
                    "Attack task %1 failed by timeout. TargetsKilled=%2, Required=%3, TimeLimit=%4s",
                    _taskID,
                    _snapshot getOrDefault ["targetsKilled", 0],
                    _snapshot getOrDefault ["requiredKills", 0],
                    _timeLimit
                ]] call EFUNC(common,log);
                _self call ["markFailed", ["Attack fail conditions met.", _snapshot]];
            };

            if (_snapshot getOrDefault ["shouldSucceed", false]) exitWith {
                ["INFO", format [
                    "Attack task %1 succeeded. TargetsRequired=%2, TargetsKilled=%3",
                    _taskID,
                    _snapshot getOrDefault ["requiredKills", 0],
                    _snapshot getOrDefault ["targetsKilled", 0]
                ]] call EFUNC(common,log);
                _self call ["markSucceeded", [_snapshot]];
            };

            sleep 1;
        };

        if ((_self call ["getStatus", []]) isEqualTo "failed") then {
            private _targets = _self getOrDefault ["targets", []];
            { deleteVehicle _x } forEach _targets;

            if (_useTaskStore) then {
                [_taskID, "FAILED"] call BFUNC(taskSetState);
                GVAR(TaskStore) call ["setTaskStatus", [_taskID, "failed"]];

                sleep 1;

                GVAR(TaskStore) call ["applyRatingOutcome", [_taskID, _ratingFail]];
                GVAR(TaskStore) call ["notifyParticipants", [_taskID, "warning", "Tasks", format ["Task failed: %1 reputation", _ratingFail]]];
                GVAR(TaskStore) call ["clearTask", [_taskID]];
            };

            if (_endFail) then { "EveryoneLost" call BFUNC(endMissionServer); };
        } else {
            private _targets = _self getOrDefault ["targets", []];
            { deleteVehicle _x } forEach _targets;

            if (_useTaskStore) then {
                [_taskID, "SUCCEEDED"] call BFUNC(taskSetState);
                GVAR(TaskStore) call ["setTaskStatus", [_taskID, "succeeded"]];
                [_taskID, _rewardData] call FUNC(handleTaskRewards);

                sleep 1;

                GVAR(TaskStore) call ["applyRatingOutcome", [_taskID, _ratingSuccess]];
                GVAR(TaskStore) call ["notifyParticipants", [_taskID, "success", "Tasks", format ["Task completed: %1 reputation, $%2 funds", _ratingSuccess, [_funds] call EFUNC(common,formatNumber)]]];
                GVAR(TaskStore) call ["clearTask", [_taskID]];
            };

            if (_endSuccess) then { "EveryoneWon" call BFUNC(endMissionServer); };
        };

        _self call ["cleanup", []];
        true
    }]
];
