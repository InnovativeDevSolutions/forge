#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Built-in generated mission provider adapter around the framework mission
 * manager.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Built-in mission generator provider object <HASHMAP OBJECT>
 *
 * Public: No
 */

if !(isServer) exitWith { createHashMap };

#pragma hemtt ignore_variables ["_self"]
GVAR(BuiltinMissionGeneratorProviderBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "BuiltinMissionGeneratorProviderBaseClass"],
    ["emptyResult", compileFinal {
        params [
            ["_message", "Generated task request failed.", [""]],
            ["_taskType", "", [""]]
        ];

        createHashMapFromArray [
            ["success", false],
            ["message", _message],
            ["taskID", ""],
            ["taskType", _taskType]
        ]
    }],
    ["resolveGeneratorType", compileFinal {
        params [["_requestedType", "", [""]]];

        private _typeAliases = createHashMapFromArray [
            ["attack", "attack"],
            ["defend", "defend"],
            ["defense", "defend"],
            ["delivery", "delivery"],
            ["deliver", "delivery"],
            ["destroy", "destroy"],
            ["defuse", "defuse"],
            ["hostage", "hostage"],
            ["hvt", "hvtkill"],
            ["hvtkill", "hvtkill"],
            ["killhvt", "hvtkill"],
            ["kill_hvt", "hvtkill"],
            ["hvtcapture", "hvtcapture"],
            ["capturehvt", "hvtcapture"],
            ["capture_hvt", "hvtcapture"]
        ];

        _typeAliases getOrDefault [toLowerANSI _requestedType, ""]
    }],
    ["ensureMissionManager", compileFinal {
        if (isNil QGVAR(MissionManager)) then {
            call FUNC(missionManager);
        };

        !(isNil QGVAR(MissionManager))
    }],
    ["getGeneratedTaskTypes", compileFinal {
        if !(GVAR(enableGenerator)) exitWith {
            ["INFO", "Built-in generated task types disabled by forge_server_task_enableGenerator."] call EFUNC(common,log);
            []
        };

        if !(_self call ["ensureMissionManager", []]) exitWith {
            ["INFO", "Built-in generated task types unavailable because mission manager is not ready."] call EFUNC(common,log);
            []
        };

        GVAR(MissionManager) call ["getGeneratedTaskTypes", []]
    }],
    ["requestMissionTask", compileFinal {
        params [
            ["_requestedType", "", [""]],
            ["_metadata", createHashMap, [createHashMap]],
            ["_requesterUid", "", [""]]
        ];

        private _result = _self call ["emptyResult", ["Generated task request failed.", _requestedType]];

        if !(GVAR(enableGenerator)) exitWith {
            _result set ["message", "Built-in generated task requests are disabled by server settings."];
            _result
        };

        private _generatorType = _self call ["resolveGeneratorType", [_requestedType]];
        if (_generatorType isEqualTo "") exitWith {
            _result set ["message", format ["Unknown built-in generated task type: %1", _requestedType]];
            _result
        };
        _result set ["taskType", _generatorType];

        if (isNil QGVAR(TaskStore)) exitWith {
            _result set ["message", "Task store is not ready yet."];
            _result
        };

        if !(_self call ["ensureMissionManager", []]) exitWith {
            _result set ["message", "Mission manager is not ready yet."];
            _result
        };

        GVAR(MissionManager) call ["cleanupCompletedMissions", []];

        private _activeCount = count (GVAR(MissionManager) call ["getActiveMissionIds", []]);
        private _maxConcurrent = GVAR(MissionManager) call ["getMaxConcurrentMissions", []];
        if (_activeCount >= _maxConcurrent) exitWith {
            _result set ["message", format [
                "Mission cap reached (%1/%2 active). Close or complete a task before requesting another.",
                _activeCount,
                _maxConcurrent
            ]];
            _result
        };

        private _generator = GVAR(MissionManager) call ["getGeneratorByType", [_generatorType]];
        if (_generator isEqualTo createHashMap) exitWith {
            _result set ["message", format ["Built-in generated task type is unavailable: %1", _generatorType]];
            _result
        };

        private _taskID = _generator call ["startMission", [GVAR(MissionManager)]];
        if (_taskID isEqualTo "") exitWith {
            _result set ["message", format ["Built-in mission generator failed to start task type: %1", _generatorType]];
            _result
        };

        GVAR(MissionManager) set ["lastMissionGenerationAt", diag_tickTime];

        ["INFO", format [
            "Dispatcher %1 requested built-in generated %2 mission %3.",
            _requesterUid,
            _generatorType,
            _taskID
        ]] call EFUNC(common,log);

        _result set ["success", true];
        _result set ["message", format ["Generated %1 task %2.", _generatorType, _taskID]];
        _result set ["taskID", _taskID];
        _result
    }]
];

GVAR(BuiltinMissionGeneratorProvider) = createHashMapObject [GVAR(BuiltinMissionGeneratorProviderBaseClass)];
GVAR(BuiltinMissionGeneratorProvider)
