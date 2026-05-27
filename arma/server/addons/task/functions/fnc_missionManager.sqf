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

if (
    !(missionNamespace getVariable ["forge_pmc_missionSettingsApplied", false]) &&
    { !(isNil "forge_pmc_fnc_setupMenu_applySettings") }
) exitWith {
    if !(missionNamespace getVariable [QGVAR(MissionManagerStartupPending), false]) then {
        missionNamespace setVariable [QGVAR(MissionManagerStartupPending), true, true];
        ["INFO", "Mission manager startup deferred until mission setup settings are applied."] call EFUNC(common,log);

        [] spawn {
            waitUntil {
                sleep 1;
                (missionNamespace getVariable ["forge_pmc_missionSettingsApplied", false]) || { time > 180 }
            };

            if !(missionNamespace getVariable ["forge_pmc_missionSettingsApplied", false]) then {
                ["INFO", "Mission manager startup applying mission setup fallback settings after timeout."] call EFUNC(common,log);
                [] call forge_pmc_fnc_setupMenu_applySettings;
            };

            missionNamespace setVariable [QGVAR(MissionManagerStartupPending), false, true];
            call FUNC(missionManager);
        };
    };

    true
};

if (isNil QGVAR(AttackMissionGeneratorBaseClass)) then { call FUNC(attackMissionGenerator); };
if (isNil QGVAR(DefendMissionGeneratorBaseClass)) then { call FUNC(defendMissionGenerator); };
if (isNil QGVAR(DefuseMissionGeneratorBaseClass)) then { call FUNC(defuseMissionGenerator); };
if (isNil QGVAR(DeliveryMissionGeneratorBaseClass)) then { call FUNC(deliveryMissionGenerator); };
if (isNil QGVAR(DestroyMissionGeneratorBaseClass)) then { call FUNC(destroyMissionGenerator); };
if (isNil QGVAR(HostageMissionGeneratorBaseClass)) then { call FUNC(hostageMissionGenerator); };
if (isNil QGVAR(KillHvtMissionGeneratorBaseClass)) then { call FUNC(hvtMissionGenerator); };
if (isNil QGVAR(CaptureHvtMissionGeneratorBaseClass)) then { call FUNC(captureHvtMissionGenerator); };

#pragma hemtt ignore_variables ["_self"]
GVAR(MissionManagerBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "MissionManagerBaseClass"],
    ["#create", compileFinal {
        _self set ["lastMissionGenerationAt", -1e10];
        _self set ["recentLocationRegistry", []];
        _self set ["activeMissionRegistry", createHashMap];
        _self set ["generators", [
            ["attack", createHashMapObject [GVAR(AttackMissionGeneratorBaseClass)]],
            ["defend", createHashMapObject [GVAR(DefendMissionGeneratorBaseClass)]],
            ["defuse", createHashMapObject [GVAR(DefuseMissionGeneratorBaseClass)]],
            ["delivery", createHashMapObject [GVAR(DeliveryMissionGeneratorBaseClass)]],
            ["destroy", createHashMapObject [GVAR(DestroyMissionGeneratorBaseClass)]],
            ["hostage", createHashMapObject [GVAR(HostageMissionGeneratorBaseClass)]],
            ["hvtkill", createHashMapObject [GVAR(KillHvtMissionGeneratorBaseClass)]],
            ["hvtcapture", createHashMapObject [GVAR(CaptureHvtMissionGeneratorBaseClass)]]
        ]];
        ["INFO", format [
            "Mission manager registered generator entries: %1",
            (_self getOrDefault ["generators", []]) apply { _x param [0, ""] }
        ]] call EFUNC(common,log);
    }],
    ["getGenerators", compileFinal {
        (_self getOrDefault ["generators", []]) apply { _x param [1, createHashMap, [createHashMap]] }
    }],
    ["getGeneratorEntries", compileFinal {
        _self getOrDefault ["generators", []]
    }],
    ["getGeneratorByType", compileFinal {
        params [["_generatorType", "", [""]]];

        private _result = createHashMap;
        {
            if ((_x param [0, "", [""]]) isEqualTo _generatorType) exitWith {
                _result = _x param [1, createHashMap, [createHashMap]];
            };
        } forEach (_self call ["getGeneratorEntries", []]);

        _result
    }],
    ["getGeneratedTaskTypes", compileFinal {
        private _labels = createHashMapFromArray [
            ["attack", "Attack"],
            ["defend", "Defend"],
            ["defuse", "Defuse"],
            ["delivery", "Delivery"],
            ["destroy", "Destroy"],
            ["hostage", "Hostage"],
            ["hvtkill", "Kill HVT"],
            ["hvtcapture", "Capture HVT"]
        ];

        (_self call ["getGeneratorEntries", []]) apply {
            private _generatorType = _x param [0, "", [""]];
            createHashMapFromArray [
                ["value", _generatorType],
                ["label", _labels getOrDefault [_generatorType, _generatorType]]
            ]
        }
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

        private _missionConfig = missionConfigFile >> "CfgMissions";
        if !(isClass _missionConfig) then {
            _missionConfig = configFile >> "CfgMissions";
        };
        private _weightsConfig = _missionConfig >> "MissionWeights";
        private _weighted = [];
        private _totalWeight = 0;
        {
            private _generatorType = _x param [0, "", [""]];
            private _generator = _x param [1, createHashMap, [createHashMap]];
            if (_generatorType isEqualTo "" || { _generator isEqualTo createHashMap }) then { continue; };

            private _weight = getNumber (_weightsConfig >> _generatorType);
            if (_weight <= 0) then { _weight = 1; };

            _totalWeight = _totalWeight + _weight;
            _weighted pushBack [_generatorType, _generator, _totalWeight];
        } forEach (_self call ["getGeneratorEntries", []]);

        if (_weighted isEqualTo [] || { _totalWeight <= 0 }) exitWith { "" };

        private _roll = random _totalWeight;
        private _selected = _weighted select 0;
        {
            if (_roll <= (_x param [2, 0, [0]])) exitWith {
                _selected = _x;
            };
        } forEach _weighted;

        private _generatorType = _selected param [0, "", [""]];
        private _generator = _selected param [1, createHashMap, [createHashMap]];
        private _taskID = _generator call ["startMission", [_self]];
        if (_taskID isEqualTo "") exitWith {
            ["WARNING", format ["Mission manager failed to start '%1' generated mission.", _generatorType]] call EFUNC(common,log);
            ""
        };

        _taskID
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
        if !(GVAR(enableGenerator)) exitWith {};

        GVAR(MissionManager) call ["cleanupCompletedMissions", []];

        private _now = diag_tickTime;
        private _interval = GVAR(MissionManager) call ["getMissionInterval", []];
        private _lastMissionGenerationAt = GVAR(MissionManager) getOrDefault ["lastMissionGenerationAt", -1e10];
        if ((_now - _lastMissionGenerationAt) < _interval) exitWith {};

        GVAR(MissionManager) set ["lastMissionGenerationAt", _now];

        private _taskID = GVAR(MissionManager) call ["startAvailableMissions", []];
        if (_taskID isEqualTo "") exitWith {};

        ["INFO", format ["Mission manager started mission %1.", _taskID]] call EFUNC(common,log);
    }, GVAR(MissionManager) call ["getMissionInterval", []], []] call CFUNC(addPerFrameHandler);
};

true
