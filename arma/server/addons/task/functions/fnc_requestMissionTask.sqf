#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Framework-owned on-demand dynamic mission request entry point for CAD and
 * other server-side dispatchers.
 *
 * Arguments:
 * 0: Generator type <STRING>
 * 1: Request metadata <HASHMAP> (Default: createHashMap)
 * 2: Requesting player UID <STRING> (Default: "")
 *
 * Return Value:
 * Request result with success, message, taskID, and taskType keys <HASHMAP>
 *
 * Public: No
 */

if !(isServer) exitWith {
    createHashMapFromArray [
        ["success", false],
        ["message", "Generated task requests must run on the server."]
    ]
};

params [
    ["_requestedType", "", [""]],
    ["_metadata", createHashMap, [createHashMap]],
    ["_requesterUid", "", [""]]
];

private _result = createHashMapFromArray [
    ["success", false],
    ["message", "Generated task request failed."],
    ["taskID", ""],
    ["taskType", _requestedType]
];

if !(GVAR(enableGenerator)) exitWith {
    _result set ["message", "Generated task requests are disabled by server settings."];
    _result
};

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

private _generatorType = _typeAliases getOrDefault [toLowerANSI _requestedType, ""];
if (_generatorType isEqualTo "") exitWith {
    _result set ["message", format ["Unknown generated task type: %1", _requestedType]];
    _result
};
_result set ["taskType", _generatorType];

if (isNil QGVAR(TaskStore)) exitWith {
    _result set ["message", "Task store is not ready yet."];
    _result
};

if (isNil QGVAR(MissionManager)) then {
    call FUNC(missionManager);
};

if (isNil QGVAR(MissionManager)) exitWith {
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
    _result set ["message", format ["Generated task type is unavailable: %1", _generatorType]];
    _result
};

private _taskID = _generator call ["startMission", [GVAR(MissionManager)]];
if (_taskID isEqualTo "") exitWith {
    _result set ["message", format ["Mission generator failed to start task type: %1", _generatorType]];
    _result
};

GVAR(MissionManager) set ["lastMissionGenerationAt", diag_tickTime];

["INFO", format [
    "Dispatcher %1 requested generated %2 mission %3.",
    _requesterUid,
    _generatorType,
    _taskID
]] call EFUNC(common,log);

_result set ["success", true];
_result set ["message", format ["Generated %1 task %2.", _generatorType, _taskID]];
_result set ["taskID", _taskID];
_result
