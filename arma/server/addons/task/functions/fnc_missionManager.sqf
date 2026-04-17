#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Manages dynamic mission generators.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call forge_server_task_fnc_missionManager
 *
 * Public: No
 */

if !(isServer) exitWith { false };
if !(isNil QGVAR(MissionManagerPFH)) exitWith { false };
if (isNil QGVAR(AttackMissionGeneratorBaseClass)) then { call FUNC(attackMissionGenerator); };

#pragma hemtt ignore_variables ["_self"]
GVAR(MissionManagerBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "MissionManagerBaseClass"],
    ["#create", compileFinal {
        _self set ["recentLocationRegistry", []];
        _self set ["activeMissionRegistry", createHashMap];
        _self set ["generators", [createHashMapObject [GVAR(AttackMissionGeneratorBaseClass)]]];
    }],
    ["getGenerators", compileFinal {
        _self getOrDefault ["generators", []]
    }],
    ["getActiveMissionIds", compileFinal {
        private _activeMissionRegistry = _self getOrDefault ["activeMissionRegistry", createHashMap];
        keys _activeMissionRegistry
    }],
    ["getActiveGeneratedMissionIds", compileFinal {
        private _activeCatalog = GVAR(TaskStore) call ["getActiveTaskCatalog", []];
        if !(_activeCatalog isEqualType []) exitWith { [] };

        private _taskIds = [];
        {
            if !(_x isEqualType createHashMap) then { continue; };
            if ((_x getOrDefault ["source", ""]) isNotEqualTo "mission_manager") then { continue; };

            private _taskID = _x getOrDefault ["taskId", _x getOrDefault ["taskID", ""]];
            if (_taskID isNotEqualTo "") then {
                _taskIds pushBackUnique _taskID;
            };
        } forEach _activeCatalog;

        _taskIds
    }],
    ["getMaxConcurrentMissions", compileFinal {
        private _maxConcurrent = 1;
        {
            _maxConcurrent = _maxConcurrent max (_x call ["getMaxConcurrentMissions", []]);
        } forEach (_self call ["getGenerators", []]);
        _maxConcurrent
    }],
    ["getMissionInterval", compileFinal {
        private _interval = 300;
        private _generators = _self call ["getGenerators", []];
        if (_generators isEqualTo []) exitWith { _interval };

        _interval = (_generators select 0) call ["getMissionInterval", []];
        {
            _interval = _interval min (_x call ["getMissionInterval", []]);
        } forEach _generators;
        _interval
    }],
    ["cleanupCompletedMissions", compileFinal {
        {
            private _taskID = _x;
            private _status = GVAR(TaskStore) call ["getTaskStatus", [_taskID]];
            private _hasCatalogEntry = GVAR(TaskStore) call ["hasTaskCatalogEntry", [_taskID]];
            private _shouldCleanup = (_status in ["succeeded", "failed"]) || { _status isEqualTo "" && { !_hasCatalogEntry } };
            if (_shouldCleanup) then {
                ["INFO", format [
                    "Mission manager cleaning up generated mission %1. Status='%2', HasCatalogEntry=%3",
                    _taskID,
                    _status,
                    _hasCatalogEntry
                ]] call EFUNC(common,log);

                {
                    if (_x call ["completeMission", [_self, _taskID]]) exitWith {};
                } forEach (_self call ["getGenerators", []]);

                GVAR(TaskStore) call ["clearTaskStatus", [_taskID]];
            };
        } forEach (_self call ["getActiveMissionIds", []]);

        true
    }],
    ["completeMission", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        {
            if (_x call ["completeMission", [_self, _taskID]]) exitWith { true };
        } forEach (_self call ["getGenerators", []]);

        false
    }],
    ["startAvailableMissions", compileFinal {
        private _activeGeneratedMissionIds = _self call ["getActiveGeneratedMissionIds", []];
        private _maxConcurrentMissions = _self call ["getMaxConcurrentMissions", []];
        if (count _activeGeneratedMissionIds >= _maxConcurrentMissions) exitWith {
            ["INFO", format [
                "Mission manager skipped generation because cap was reached. ActiveGenerated=%1, Cap=%2, TaskIDs=%3",
                count _activeGeneratedMissionIds,
                _maxConcurrentMissions,
                _activeGeneratedMissionIds
            ]] call EFUNC(common,log);
            ""
        };

        private _startedTaskID = "";
        {
            private _taskID = _x call ["startMission", [_self]];
            if (_taskID isNotEqualTo "") exitWith {
                _startedTaskID = _taskID;
            };
        } forEach (_self call ["getGenerators", []]);

        _startedTaskID
    }]
];

GVAR(MissionManager) = createHashMapObject [GVAR(MissionManagerBaseClass)];

if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); };
if (isNil QGVAR(MissionManagerTaskEventTokens)) then {
    private _handleTaskCleared = {
        params ["_event"];

        private _taskID = _event getOrDefault ["taskID", ""];
        if (_taskID isEqualTo "") exitWith {};
        if (isNil QGVAR(MissionManager)) exitWith {};

        if (GVAR(MissionManager) call ["completeMission", [_taskID]]) then {
            ["INFO", format ["Mission manager completed generated mission from event. TaskID=%1", _taskID]] call EFUNC(common,log);
        };
    };

    GVAR(MissionManagerTaskEventTokens) = [
        EGVAR(common,EventBus) call ["on", ["task.cleared", _handleTaskCleared, "task.missionManager.cleanup"]]
    ];
};

if (GVAR(enableGenerator)) then {
    GVAR(MissionManagerPFH) = [{
        GVAR(MissionManager) call ["cleanupCompletedMissions", []];

        private _taskID = GVAR(MissionManager) call ["startAvailableMissions", []];
        if (_taskID isEqualTo "") exitWith {};

        ["INFO", format ["Mission manager started mission %1.", _taskID]] call EFUNC(common,log);
    }, GVAR(MissionManager) call ["getMissionInterval", []], []] call CFUNC(addPerFrameHandler);
};

true
