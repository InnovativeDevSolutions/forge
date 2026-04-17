#include "..\script_component.hpp"

/*
 * Review-only prototype hostage task class.
 *
 * Example:
 * call compile preprocessFileLineNumbers
 *     "\forge\forge_server\addons\task\prototypes\TaskInstanceBaseClass.sqf";
 * call compile preprocessFileLineNumbers
 *     "\forge\forge_server\addons\task\prototypes\HostageTaskBaseClass.sqf";
 *
 * private _task = createHashMapObject [
 *     GVAR(HostageTaskBaseClass),
 *     [
 *         "task_hostage_review",
 *         createHashMapFromArray [
 *             ["hostages", [hostage1, hostage2]],
 *             ["shooters", [shooter1, shooter2]]
 *         ],
 *         createHashMapFromArray [
 *             ["extractionZone", "hostage_extract"],
 *             ["limitSuccess", 2],
 *             ["limitFail", 1],
 *             ["execution", true],
 *             ["timeLimit", 900],
 *             ["funds", 100000],
 *             ["ratingSuccess", 50]
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
 * `runLoop` and the wait helpers use `sleep`, so they must be entered from
 * scheduled code.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(HostageTaskBaseClass) = createHashMapFromArray [
    ["#base", GVAR(TaskInstanceBaseClass)],
    ["#type", "HostageTaskBaseClass"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entities", createHashMap, [createHashMap]],
            ["_taskParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeBaseState", [_taskID, "hostage", _entities, _taskParams]];

        private _hostages = +(_entities getOrDefault ["hostages", []]);
        private _shooters = +(_entities getOrDefault ["shooters", []]);
        private _requiredRescues = _taskParams getOrDefault ["limitSuccess", -1];
        if (_requiredRescues < 0) then { _requiredRescues = count _hostages; };

        private _maxHostageLosses = _taskParams getOrDefault ["limitFail", -1];
        if (_maxHostageLosses < 0) then { _maxHostageLosses = count _hostages; };

        private _type = _taskParams getOrDefault ["type", []];
        private _cbrn = _taskParams getOrDefault ["cbrn", false];
        private _execution = _taskParams getOrDefault ["execution", false];

        if (_type isEqualType [] && { count _type >= 2 }) then {
            _cbrn = _type param [0, false, [false]];
            _execution = _type param [1, true, [false]];
        };

        _self set ["hostages", _hostages];
        _self set ["shooters", _shooters];
        _self set ["extractionZone", _taskParams getOrDefault ["extractionZone", ""]];
        _self set ["timeLimit", _taskParams getOrDefault ["timeLimit", 0]];
        _self set ["execution", _execution];
        _self set ["cbrn", _cbrn];
        _self set ["cbrnZone", _taskParams getOrDefault ["cbrnZone", ""]];
        _self set ["useTaskStore", _taskParams getOrDefault ["useTaskStore", false]];
        _self set ["requiredRescues", _requiredRescues];
        _self set ["maxHostageLosses", _maxHostageLosses];
        _self set ["hostageControllers", []];

        _self call ["createHostageControllers", []];

        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["createHostageControllers", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _hostages = _self getOrDefault ["hostages", []];
        private _controllers = [];

        {
            _controllers pushBack (createHashMapObject [
                GVAR(HostageEntityController),
                [
                    _taskID,
                    _x,
                    createHashMapFromArray [
                        ["rescueRadius", 2],
                        ["loopAnimation", "acts_executionvictim_loop"],
                        ["rescueAnimation", "acts_executionvictim_unbow"]
                    ]
                ]
            ]);
        } forEach _hostages;

        _self set ["hostageControllers", _controllers];
        _controllers
    }],
    ["startHostageControllers", compileFinal {
        private _controllers = _self getOrDefault ["hostageControllers", []];

        {
            [_x] spawn {
                params ["_controller"];
                _controller call ["runLoop", []];
            };
        } forEach _controllers;

        true
    }],
    ["refreshEntitiesFromStore", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "" || { !(_self getOrDefault ["useTaskStore", false]) }) exitWith { false };

        private _hostages = GVAR(TaskStore) call ["getTaskEntities", ["hostages", _taskID]];
        private _shooters = GVAR(TaskStore) call ["getTaskEntities", ["shooters", _taskID]];

        _self set ["hostages", _hostages];
        _self set ["shooters", _shooters];
        true
    }],
    ["trackParticipants", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "" || { !(_self getOrDefault ["useTaskStore", false]) }) exitWith { false };

        private _hostages = _self getOrDefault ["hostages", []];
        private _shooters = _self getOrDefault ["shooters", []];
        private _extZone = _self getOrDefault ["extractionZone", ""];

        GVAR(TaskStore) call ["trackParticipants", [_taskID, _hostages + _shooters, _extZone, 250]];
        true
    }],
    ["waitForRequiredEntities", compileFinal {
        if (_self getOrDefault ["useTaskStore", false]) then {
            waitUntil {
                sleep 1;
                _self call ["refreshEntitiesFromStore", []];
                count (_self getOrDefault ["hostages", []]) > 0
            };

            waitUntil {
                sleep 1;
                _self call ["refreshEntitiesFromStore", []];
                _self call ["trackParticipants", []];
                count (_self getOrDefault ["shooters", []]) > 0
            };
        } else {
            waitUntil {
                sleep 1;
                count (_self getOrDefault ["hostages", []]) > 0
            };

            waitUntil {
                sleep 1;
                count (_self getOrDefault ["shooters", []]) > 0
            };
        };

        private _hostages = _self getOrDefault ["hostages", []];
        private _taskParams = _self getOrDefault ["taskParams", createHashMap];
        private _requiredRescues = _taskParams getOrDefault ["limitSuccess", -1];
        if (_requiredRescues < 0) then { _requiredRescues = count _hostages; };

        private _maxHostageLosses = _taskParams getOrDefault ["limitFail", -1];
        if (_maxHostageLosses < 0) then { _maxHostageLosses = count _hostages; };

        _self set ["requiredRescues", _requiredRescues];
        _self set ["maxHostageLosses", _maxHostageLosses];
        true
    }],
    ["waitForAssignmentIfTimed", compileFinal {
        private _timeLimit = _self getOrDefault ["timeLimit", 0];
        private _taskID = _self getOrDefault ["taskID", ""];

        if (_timeLimit <= 0 || { _taskID isEqualTo "" } || { !(_self getOrDefault ["useTaskStore", false]) }) exitWith { true };

        waitUntil {
            sleep 1;
            GVAR(TaskStore) call ["isTaskAccepted", [_taskID]]
        };

        true
    }],
    ["countFreedHostages", compileFinal {
        private _playerGroups = allPlayers apply { group _x };
        private _hostages = _self getOrDefault ["hostages", []];

        {
            alive _x && { ((group _x) in _playerGroups) || { !captive _x } }
        } count _hostages
    }],
    ["countHostagesInZone", compileFinal {
        private _extZone = _self getOrDefault ["extractionZone", ""];
        private _hostages = _self getOrDefault ["hostages", []];

        if (_extZone isEqualTo "") exitWith { 0 };
        { _x inArea _extZone } count _hostages
    }],
    ["countKilledHostages", compileFinal {
        private _hostages = _self getOrDefault ["hostages", []];
        { !alive _x } count _hostages
    }],
    ["countAliveShooters", compileFinal {
        private _shooters = _self getOrDefault ["shooters", []];
        { alive _x } count _shooters
    }],
    ["tick", compileFinal {
        private _startedAt = _self getOrDefault ["startedAt", -1];
        private _timeLimit = _self getOrDefault ["timeLimit", 0];
        private _killed = _self call ["countKilledHostages", []];
        private _freed = _self call ["countFreedHostages", []];
        private _inZone = _self call ["countHostagesInZone", []];
        private _shootersAlive = _self call ["countAliveShooters", []];
        private _requiredRescues = _self getOrDefault ["requiredRescues", 0];
        private _maxHostageLosses = _self getOrDefault ["maxHostageLosses", 0];
        private _timeExpired = false;

        if (_timeLimit > 0 && { _startedAt >= 0 }) then {
            _timeExpired = (serverTime - _startedAt) >= _timeLimit;
        };

        private _hostageSucceeded = (_inZone >= _requiredRescues) && { _killed < _maxHostageLosses };
        private _shootersClearedSucceeded = (_shootersAlive <= 0) && { _hostageSucceeded };

        createHashMapFromArray [
            ["freed", _freed],
            ["inZone", _inZone],
            ["killed", _killed],
            ["shootersAlive", _shootersAlive],
            ["requiredRescues", _requiredRescues],
            ["maxHostageLosses", _maxHostageLosses],
            ["timeExpired", _timeExpired],
            ["shouldFail", (_killed >= _maxHostageLosses) || { _timeExpired && { !_hostageSucceeded } }],
            ["shouldSucceed", _hostageSucceeded || _shootersClearedSucceeded]
        ]
    }],
    ["handleFailureOutcome", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _hostages = _self getOrDefault ["hostages", []];
        private _shooters = _self getOrDefault ["shooters", []];
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingFail = _rewardData getOrDefault ["ratingFail", 0];
        private _endFail = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endFail", false];
        private _cbrn = _self getOrDefault ["cbrn", false];
        private _hostage = _self getOrDefault ["execution", false];
        private _cbrnZone = _self getOrDefault ["cbrnZone", ""];
        private _useTaskStore = _self getOrDefault ["useTaskStore", false];

        if (_cbrn && { _cbrnZone isNotEqualTo "" }) then {
            "SmokeShellYellow" createVehicle getMarkerPos _cbrnZone;

            sleep 5;

            {
                if (captive _x) then {
                    _x setDamage 0.9;
                    _x playMove "acts_executionvictim_kill_end";

                    sleep 2.75;

                    _x setDamage 1;
                };
            } forEach _hostages;
        };

        if (_hostage) then {
            {
                _x enableAIFeature ["MOVE", true];
                _x playMove "";
            } forEach _shooters;

            sleep 1;

            { _x setCaptive false; } forEach _hostages;

            sleep 5;
        };

        { deleteVehicle _x } forEach _hostages;
        { deleteVehicle _x } forEach _shooters;

        if (_useTaskStore) then {
            [_taskID, "FAILED"] call BFUNC(taskSetState);

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
        private _hostages = _self getOrDefault ["hostages", []];
        private _shooters = _self getOrDefault ["shooters", []];
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingSuccess = _rewardData getOrDefault ["ratingSuccess", 0];
        private _funds = _rewardData getOrDefault ["funds", 0];
        private _endSuccess = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endSuccess", false];
        private _useTaskStore = _self getOrDefault ["useTaskStore", false];

        { deleteVehicle _x } forEach _hostages;
        { deleteVehicle _x } forEach _shooters;

        if (_useTaskStore) then {
            [_taskID, _rewardData] call FUNC(handleTaskRewards);
            [_taskID, "SUCCEEDED"] call BFUNC(taskSetState);

            sleep 1;

            GVAR(TaskStore) call ["notifyParticipants", [_taskID, "success", "Tasks", format ["Task completed: %1 reputation, $%2 funds", _ratingSuccess, [_funds] call EFUNC(common,formatNumber)]]];
            GVAR(TaskStore) call ["applyRatingOutcome", [_taskID, _ratingSuccess]];
            GVAR(TaskStore) call ["clearTask", [_taskID]];
        };

        if (_endSuccess) then { "EveryoneWon" call BFUNC(endMissionServer); };
        true
    }],
    ["runLoop", compileFinal {
        _self call ["waitForRequiredEntities", []];
        _self call ["startHostageControllers", []];
        _self call ["waitForAssignmentIfTimed", []];
        _self call ["markActive", []];

        while { (_self call ["getStatus", []]) isEqualTo "active" } do {
            _self call ["trackParticipants", []];
            private _snapshot = _self call ["tick", []];

            if (_snapshot getOrDefault ["shouldFail", false]) exitWith {
                _self call ["markFailed", ["Hostage fail conditions met.", _snapshot]];
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
