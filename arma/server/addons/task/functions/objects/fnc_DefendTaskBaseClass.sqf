#include "..\script_component.hpp"

/*
 * Object-style defend task class.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(DefendTaskBaseClass) = createHashMapFromArray [
    ["#base", GVAR(TaskInstanceBaseClass)],
    ["#type", "DefendTaskBaseClass"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entities", createHashMap, [createHashMap]],
            ["_taskParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeBaseState", [_taskID, "defend", _entities, _taskParams]];

        _self set ["defenseZone", _taskParams getOrDefault ["defenseZone", ""]];
        _self set ["defendTime", _taskParams getOrDefault ["defendTime", 600]];
        _self set ["waveCount", _taskParams getOrDefault ["waveCount", 3]];
        _self set ["waveCooldown", _taskParams getOrDefault ["waveCooldown", 300]];
        _self set ["minBlufor", _taskParams getOrDefault ["minBlufor", 1]];
        _self set ["enemyTemplates", _taskParams getOrDefault ["enemyTemplates", []]];
        _self set ["nextWaveTime", -1];
        _self set ["currentWave", 0];
        _self set ["zoneEmptyCounter", 0];
        _self set ["warningIssued", false];
        _self set ["useTaskStore", _taskParams getOrDefault ["useTaskStore", false]];

        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["isValidDefenseZone", compileFinal {
        private _defenseZone = _self getOrDefault ["defenseZone", ""];
        _defenseZone isNotEqualTo "" && { markerShape _defenseZone in ["RECTANGLE", "ELLIPSE"] }
    }],
    ["trackParticipants", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "" || { !(_self getOrDefault ["useTaskStore", false]) }) exitWith { false };

        GVAR(TaskStore) call ["trackParticipants", [_taskID, [], _self getOrDefault ["defenseZone", ""], 0]];
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
    ["countBluforInZone", compileFinal {
        private _defenseZone = _self getOrDefault ["defenseZone", ""];
        if (_defenseZone isEqualTo "") exitWith { 0 };

        count (allUnits select { _x isKindOf "CAManBase" && { side _x == west } && { alive _x }} inAreaArray _defenseZone)
    }],
    ["waitForDefenseStart", compileFinal {
        private _minBlufor = _self getOrDefault ["minBlufor", 1];

        waitUntil {
            sleep 1;
            _self call ["trackParticipants", []];

            private _ready = (_self call ["countBluforInZone", []]) >= _minBlufor;
            if (_ready) then {
                _self call ["markActive", []];
                _self set ["nextWaveTime", serverTime];

                if (_self getOrDefault ["useTaskStore", false]) then {
                    GVAR(TaskStore) call ["notifyParticipants", [_self getOrDefault ["taskID", ""], "info", "Tasks", "Defense has started. Hold the zone."]];
                };
            };

            _ready
        };

        true
    }],
    ["tick", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _defenseZone = _self getOrDefault ["defenseZone", ""];
        private _defendTime = _self getOrDefault ["defendTime", 600];
        private _waveCount = _self getOrDefault ["waveCount", 3];
        private _waveCooldown = _self getOrDefault ["waveCooldown", 300];
        private _minBlufor = _self getOrDefault ["minBlufor", 1];
        private _currentWave = _self getOrDefault ["currentWave", 0];
        private _enemyTemplates = _self getOrDefault ["enemyTemplates", []];
        private _nextWaveTime = _self getOrDefault ["nextWaveTime", -1];
        private _zoneEmptyCounter = _self getOrDefault ["zoneEmptyCounter", 0];
        private _warningIssued = _self getOrDefault ["warningIssued", false];
        private _bluforInZone = _self call ["countBluforInZone", []];
        private _elapsed = serverTime - (_self getOrDefault ["startedAt", serverTime]);

        if (_bluforInZone < _minBlufor) then {
            _zoneEmptyCounter = _zoneEmptyCounter + 1;

            if (_zoneEmptyCounter == 15 && { !_warningIssued } && { _self getOrDefault ["useTaskStore", false] }) then {
                GVAR(TaskStore) call ["notifyParticipants", [_taskID, "warning", "Tasks", "Defense zone is empty. Return immediately."]];
                _warningIssued = true;
            };
        } else {
            _zoneEmptyCounter = 0;
            _warningIssued = false;
        };

        if (_currentWave < _waveCount && { serverTime >= _nextWaveTime }) then {
            [_defenseZone, _taskID, _currentWave, _enemyTemplates] call FUNC(spawnEnemyWave);

            _currentWave = _currentWave + 1;
            _nextWaveTime = serverTime + _waveCooldown;

            if (_self getOrDefault ["useTaskStore", false]) then {
                GVAR(TaskStore) call ["notifyParticipants", [_taskID, "info", "Tasks", format ["Enemy forces approaching. Wave %1 of %2.", _currentWave, _waveCount]]];
            };
        };

        _self set ["currentWave", _currentWave];
        _self set ["nextWaveTime", _nextWaveTime];
        _self set ["zoneEmptyCounter", _zoneEmptyCounter];
        _self set ["warningIssued", _warningIssued];

        createHashMapFromArray [
            ["bluforInZone", _bluforInZone],
            ["elapsed", _elapsed],
            ["currentWave", _currentWave],
            ["waveCount", _waveCount],
            ["zoneEmptyCounter", _zoneEmptyCounter],
            ["shouldFail", _zoneEmptyCounter >= 30],
            ["shouldSucceed", (_bluforInZone >= _minBlufor) && { _elapsed >= _defendTime } && { _currentWave >= _waveCount }]
        ]
    }],
    ["handleFailureOutcome", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingFail = _rewardData getOrDefault ["ratingFail", 0];
        private _endFail = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endFail", false];

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
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingSuccess = _rewardData getOrDefault ["ratingSuccess", 0];
        private _funds = _rewardData getOrDefault ["funds", 0];
        private _endSuccess = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endSuccess", false];

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
        if !(_self call ["isValidDefenseZone", []]) exitWith {
            _self call ["markFailed", ["Invalid defense zone.", createHashMap]];
            _self call ["cleanup", []];
            false
        };

        _self call ["waitForAssignment", []];
        _self call ["waitForDefenseStart", []];

        while { (_self call ["getStatus", []]) isEqualTo "active" } do {
            _self call ["trackParticipants", []];
            private _snapshot = _self call ["tick", []];

            if (_snapshot getOrDefault ["shouldFail", false]) exitWith {
                _self call ["markFailed", ["Defend fail conditions met.", _snapshot]];
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
