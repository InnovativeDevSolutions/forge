#include "..\script_component.hpp"

/*
 * Object-style delivery task class.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(DeliveryTaskBaseClass) = createHashMapFromArray [
    ["#base", GVAR(TaskInstanceBaseClass)],
    ["#type", "DeliveryTaskBaseClass"],
    ["#create", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_entities", createHashMap, [createHashMap]],
            ["_taskParams", createHashMap, [createHashMap]]
        ];

        _self call ["initializeBaseState", [_taskID, "delivery", _entities, _taskParams]];

        private _cargo = +(_entities getOrDefault ["cargo", []]);
        private _requiredDelivered = _taskParams getOrDefault ["limitSuccess", -1];
        if (_requiredDelivered < 0) then { _requiredDelivered = count _cargo; };

        private _maxDamaged = _taskParams getOrDefault ["limitFail", -1];
        if (_maxDamaged < 0) then { _maxDamaged = count _cargo; };

        _self set ["cargo", _cargo];
        _self set ["deliveryZone", _taskParams getOrDefault ["deliveryZone", ""]];
        _self set ["requiredDelivered", _requiredDelivered];
        _self set ["maxDamaged", _maxDamaged];
        _self set ["timeLimit", _taskParams getOrDefault ["timeLimit", 0]];
        _self set ["useTaskStore", _taskParams getOrDefault ["useTaskStore", false]];

        _self call ["registerInstance", []];
    }],
    ["#delete", compileFinal {
        _self call ["unregisterInstance", []];
    }],
    ["refreshEntitiesFromStore", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "" || { !(_self getOrDefault ["useTaskStore", false]) }) exitWith { false };

        private _cargo = GVAR(TaskStore) call ["getTaskEntities", ["cargo", _taskID]];
        _self set ["cargo", _cargo];
        true
    }],
    ["trackParticipants", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "" || { !(_self getOrDefault ["useTaskStore", false]) }) exitWith { false };

        GVAR(TaskStore) call ["trackParticipants", [_taskID, _self getOrDefault ["cargo", []], _self getOrDefault ["deliveryZone", ""], 125]];
        true
    }],
    ["waitForRequiredEntities", compileFinal {
        if (_self getOrDefault ["useTaskStore", false]) then {
            waitUntil {
                sleep 1;
                _self call ["refreshEntitiesFromStore", []];
                _self call ["trackParticipants", []];
                count (_self getOrDefault ["cargo", []]) > 0
            };
        } else {
            waitUntil {
                sleep 1;
                count (_self getOrDefault ["cargo", []]) > 0
            };
        };

        private _cargo = _self getOrDefault ["cargo", []];
        private _taskParams = _self getOrDefault ["taskParams", createHashMap];
        private _requiredDelivered = _taskParams getOrDefault ["limitSuccess", -1];
        if (_requiredDelivered < 0) then { _requiredDelivered = count _cargo; };

        private _maxDamaged = _taskParams getOrDefault ["limitFail", -1];
        if (_maxDamaged < 0) then { _maxDamaged = count _cargo; };

        _self set ["requiredDelivered", _requiredDelivered];
        _self set ["maxDamaged", _maxDamaged];
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
    ["countDeliveredCargo", compileFinal {
        private _deliveryZone = _self getOrDefault ["deliveryZone", ""];
        private _cargo = _self getOrDefault ["cargo", []];

        if (_deliveryZone isEqualTo "") exitWith { 0 };
        { _x inArea _deliveryZone && { damage _x < 0.7 } } count _cargo
    }],
    ["countDamagedCargo", compileFinal {
        private _cargo = _self getOrDefault ["cargo", []];
        { damage _x >= 0.7 } count _cargo
    }],
    ["tick", compileFinal {
        private _startedAt = _self getOrDefault ["startedAt", -1];
        private _timeLimit = _self getOrDefault ["timeLimit", 0];
        private _delivered = _self call ["countDeliveredCargo", []];
        private _damaged = _self call ["countDamagedCargo", []];
        private _requiredDelivered = _self getOrDefault ["requiredDelivered", 0];
        private _maxDamaged = _self getOrDefault ["maxDamaged", 0];
        private _timeExpired = false;

        if (_timeLimit > 0 && { _startedAt >= 0 }) then {
            _timeExpired = (serverTime - _startedAt) >= _timeLimit;
        };

        createHashMapFromArray [
            ["delivered", _delivered],
            ["damaged", _damaged],
            ["requiredDelivered", _requiredDelivered],
            ["maxDamaged", _maxDamaged],
            ["timeExpired", _timeExpired],
            ["shouldFail", (_damaged >= _maxDamaged) || { _timeExpired && { _delivered < _requiredDelivered } }],
            ["shouldSucceed", (_delivered >= _requiredDelivered) && { _damaged < _maxDamaged }]
        ]
    }],
    ["handleFailureOutcome", compileFinal {
        private _taskID = _self getOrDefault ["taskID", ""];
        private _cargo = _self getOrDefault ["cargo", []];
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingFail = _rewardData getOrDefault ["ratingFail", 0];
        private _endFail = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endFail", false];

        { deleteVehicle _x } forEach _cargo;

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
        private _cargo = _self getOrDefault ["cargo", []];
        private _rewardData = _self getOrDefault ["rewardData", createHashMap];
        private _ratingSuccess = _rewardData getOrDefault ["ratingSuccess", 0];
        private _funds = _rewardData getOrDefault ["funds", 0];
        private _endSuccess = (_self getOrDefault ["taskParams", createHashMap]) getOrDefault ["endSuccess", false];

        { deleteVehicle _x } forEach _cargo;

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
        _self call ["waitForAssignmentIfTimed", []];
        _self call ["markActive", []];

        while { (_self call ["getStatus", []]) isEqualTo "active" } do {
            _self call ["trackParticipants", []];
            private _snapshot = _self call ["tick", []];

            if (_snapshot getOrDefault ["shouldFail", false]) exitWith {
                _self call ["markFailed", ["Delivery fail conditions met.", _snapshot]];
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
