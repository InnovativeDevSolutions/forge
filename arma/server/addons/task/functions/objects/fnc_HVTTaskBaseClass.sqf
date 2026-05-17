#include "..\script_component.hpp"

/*
 * Object-style HVT task class.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(HVTTaskBaseClass) = createHashMapFromArray [
    ["#base", GVAR(TaskInstanceBaseClass)],
    ["#type", "HVTTaskBaseClass"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entities", createHashMap, [createHashMap]],
            ["_taskParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeBaseState", [_taskID, "hvt", _entities, _taskParams]];

        private _hvts = +(_entities getOrDefault ["hvts", []]);
        private _required = _taskParams getOrDefault ["limitSuccess", -1];
        if (_required < 0) then { _required = count _hvts; };

        private _maxKilled = _taskParams getOrDefault ["limitFail", -1];
        if (_maxKilled < 0) then { _maxKilled = count _hvts; };

        private _type = _taskParams getOrDefault ["type", []];
        private _captureHvt = _taskParams getOrDefault ["captureHvt", true];
        private _capture = _captureHvt;
        private _eliminate = !_captureHvt;

        if (_type isEqualType [] && { count _type >= 2 }) then {
            _capture = _type param [0, true, [false]];
            _eliminate = _type param [1, false, [false]];
        };

        _self set ["hvts", _hvts];
        _self set ["extractionZone", _taskParams getOrDefault ["extractionZone", ""]];
        _self set ["required", _required];
        _self set ["maxKilled", _maxKilled];
        _self set ["capture", _capture];
        _self set ["eliminate", _eliminate];
        _self set ["timeLimit", _taskParams getOrDefault ["timeLimit", 0]];
        _self set ["useTaskStore", _taskParams getOrDefault ["useTaskStore", false]];
        _self set ["hvtControllers", []];

        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["refreshEntitiesFromStore", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "" || { !(_self getOrDefault ["useTaskStore", false]) }) exitWith { false };

        private _hvts = GVAR(TaskStore) call ["getTaskEntities", ["hvts", _taskID]];
        _self set ["hvts", _hvts];
        true
    }],
    ["trackParticipants", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "" || { !(_self getOrDefault ["useTaskStore", false]) }) exitWith { false };

        GVAR(TaskStore) call ["trackParticipants", [_taskID, _self getOrDefault ["hvts", []], _self getOrDefault ["extractionZone", ""], 250]];
        true
    }],
    ["waitForRequiredEntities", compileFinal {
        if (_self getOrDefault ["useTaskStore", false]) then {
            waitUntil {
                sleep 1;
                _self call ["refreshEntitiesFromStore", []];
                _self call ["trackParticipants", []];
                count (_self getOrDefault ["hvts", []]) > 0
            };
        } else {
            waitUntil {
                sleep 1;
                count (_self getOrDefault ["hvts", []]) > 0
            };
        };

        private _hvts = _self getOrDefault ["hvts", []];
        private _taskParams = _self getOrDefault ["taskParams", createHashMap];
        private _required = _taskParams getOrDefault ["limitSuccess", -1];
        if (_required < 0) then { _required = count _hvts; };

        private _maxKilled = _taskParams getOrDefault ["limitFail", -1];
        if (_maxKilled < 0) then { _maxKilled = count _hvts; };

        _self set ["required", _required];
        _self set ["maxKilled", _maxKilled];
        true
    }],
    ["startHvtControllers", compileFinal {
        if ((_self getOrDefault ["hvtControllers", []]) isNotEqualTo []) exitWith { true };

        private _taskID = _self getOrDefault ["taskID", ""];
        private _controllers = [];

        {
            if (!isNull _x) then {
                private _controller = createHashMapObject [
                    GVAR(HVTEntityController),
                    [_taskID, _x, createHashMapFromArray [["captureRadius", 2]]]
                ];

                _controllers pushBack _controller;
                [_controller] spawn {
                    params ["_controller"];
                    _controller call ["runLoop", []];
                };
            };
        } forEach (_self getOrDefault ["hvts", []]);

        _self set ["hvtControllers", _controllers];
        true
    }],
    ["waitForAssignment", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];

        if (_taskID isEqualTo "" || { !(_self getOrDefault ["useTaskStore", false]) }) exitWith { true };

        waitUntil {
            sleep 1;
            GVAR(TaskStore) call ["isTaskAccepted", [_taskID]]
        };

        true
    }],
    ["tick", compileFinal {
        private _startedAt = _self getOrDefault ["startedAt", -1];
        private _timeLimit = _self getOrDefault ["timeLimit", 0];
        private _hvts = _self getOrDefault ["hvts", []];
        private _extZone = _self getOrDefault ["extractionZone", ""];
        private _capture = _self getOrDefault ["capture", true];
        private _eliminate = _self getOrDefault ["eliminate", false];
        private _required = _self getOrDefault ["required", 0];
        private _maxKilled = _self getOrDefault ["maxKilled", 0];
        private _captives = { captive _x } count _hvts;
        private _killed = { !alive _x } count _hvts;
        private _inZone = if (_extZone isEqualTo "") then { 0 } else { { _x inArea _extZone } count _hvts };
        private _timeExpired = false;

        if (_timeLimit > 0 && { _startedAt >= 0 }) then {
            _timeExpired = (serverTime - _startedAt) >= _timeLimit;
        };

        private _captureSucceeded = _capture && { _inZone >= _required } && { _killed < _maxKilled };
        private _eliminateSucceeded = _eliminate && { _killed >= _required };

        createHashMapFromArray [
            ["captives", _captives],
            ["killed", _killed],
            ["inZone", _inZone],
            ["required", _required],
            ["maxKilled", _maxKilled],
            ["timeExpired", _timeExpired],
            ["shouldFail", (_capture && { _killed >= _maxKilled }) || { _timeExpired && { (_capture && { !_captureSucceeded }) || { _eliminate && { !_eliminateSucceeded } } } }],
            ["shouldSucceed", _captureSucceeded || _eliminateSucceeded]
        ]
    }],
    ["handleFailureOutcome", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _hvts = _self getOrDefault ["hvts", []];
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingFail = _rewardData getOrDefault ["ratingFail", 0];
        private _endFail = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endFail", false];

        { deleteVehicle _x } forEach _hvts;

        if (_self getOrDefault ["useTaskStore", false]) then {
            [_taskID, "FAILED"] call BFUNC(taskSetState);
            GVAR(TaskStore) call ["setTaskStatus", [_taskID, "failed"]];

            sleep 1;

            GVAR(TaskStore) call ["applyRatingOutcome", [_taskID, _ratingFail]];
            GVAR(TaskStore) call ["notifyParticipants", [_taskID, "warning", "Tasks", format ["Task failed: %1 reputation", _ratingFail]]];
            GVAR(TaskStore) call ["clearTask", [_taskID]];
        };

        if (_endFail) then { "EveryoneLost" call BFUNC(endMissionServer); };
        true
    }],
    ["handleSuccessOutcome", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _hvts = _self getOrDefault ["hvts", []];
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingSuccess = _rewardData getOrDefault ["ratingSuccess", 0];
        private _funds = _rewardData getOrDefault ["funds", 0];
        private _endSuccess = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endSuccess", false];

        { deleteVehicle _x } forEach _hvts;

        if (_self getOrDefault ["useTaskStore", false]) then {
            [_taskID, "SUCCEEDED"] call BFUNC(taskSetState);
            GVAR(TaskStore) call ["setTaskStatus", [_taskID, "succeeded"]];
            [_taskID, _rewardData] call FUNC(handleTaskRewards);

            sleep 1;

            GVAR(TaskStore) call ["applyRatingOutcome", [_taskID, _ratingSuccess]];
            GVAR(TaskStore) call ["notifyParticipants", [_taskID, "success", "Tasks", format ["Task completed: %1 reputation, $%2 funds", _ratingSuccess, [_funds] call EFUNC(common,formatNumber)]]];
            GVAR(TaskStore) call ["clearTask", [_taskID]];
        };

        if (_endSuccess) then { "EveryoneWon" call BFUNC(endMissionServer); };
        true
    }],
    ["runLoop", compileFinal {
        _self call ["waitForRequiredEntities", []];
        _self call ["waitForAssignment", []];
        _self call ["startHvtControllers", []];
        _self call ["markActive", []];

        while { (_self call ["getStatus", []]) isEqualTo "active" } do {
            _self call ["trackParticipants", []];
            private _snapshot = _self call ["tick", []];

            if (_snapshot getOrDefault ["shouldFail", false]) exitWith {
                _self call ["markFailed", ["HVT fail conditions met.", _snapshot]];
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
