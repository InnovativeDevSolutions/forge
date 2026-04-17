#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Unified task initializer used by both Eden modules and missionManager-generated
 * tasks. Registers entities, creates the BIS task, registers the catalog entry,
 * and dispatches to the task handler.
 *
 * Arguments:
 * 0: Task type <STRING> ("attack"|"defuse"|"destroy"|"delivery"|"hostage"|"hvt"|"defend")
 * 1: Task ID <STRING>
 * 2: Task position <ARRAY>
 * 3: Task title <STRING>
 * 4: Task description <STRING>
 * 5: Task entities <HASHMAP>
 *    Keys: "targets"   <ARRAY> -- attack, destroy
 *          "hostages"  <ARRAY> -- hostage
 *          "shooters"  <ARRAY> -- hostage
 *          "hvts"      <ARRAY> -- hvt
 *          "ieds"      <ARRAY> -- defuse
 *          "protected" <ARRAY> -- defuse
 *          "cargo"     <ARRAY> -- delivery
 * 6: Task parameters <HASHMAP>
 *    Common keys:
 *      "limitFail"     <NUMBER> (default: -1)
 *      "limitSuccess"  <NUMBER> (default: -1)
 *      "funds"         <NUMBER> (default: 0)
 *      "ratingFail"    <NUMBER> (default: 0)
 *      "ratingSuccess" <NUMBER> (default: 0)
 *      "endSuccess"    <BOOL>   (default: false)
 *      "endFail"       <BOOL>   (default: false)
 *      "timeLimit"     <NUMBER> (default: 0, 0 = no limit)
 *    Reward keys:
 *      "equipment" <ARRAY>, "supplies" <ARRAY>, "weapons" <ARRAY>,
 *      "vehicles"  <ARRAY>, "special"  <ARRAY>
 *    Type-specific keys:
 *      defuse:   "iedTimer"       <NUMBER> -- required IED countdown in seconds (> 0)
 *      delivery: "deliveryZone"   <STRING> -- marker name
 *      hostage:  "extractionZone" <STRING> -- marker name
 *                "cbrn"           <BOOL>   (default: false)
 *                "execution"      <BOOL>   (default: false)
 *                "cbrnZone"       <STRING> (default: "")
 *      hvt:      "extractionZone" <STRING> -- marker name (capture mode only)
 *                "captureHvt"     <BOOL>   (default: true)
 *      defend:   "defenseZone"    <STRING> -- marker name
 *                "defendTime"     <NUMBER> (default: 600)
 *                "waveCount"      <NUMBER> (default: 3)
 *                "waveCooldown"   <NUMBER> (default: 300)
 *                "minBlufor"      <NUMBER> (default: 1)
 *                "enemyTemplates" <ARRAY>  (default: [])
 * 7: Minimum org reputation required <NUMBER> (default: 0)
 * 8: Requester UID <STRING> (default: "")
 * 9: Source tag <STRING> (default: "eden") -- "eden"|"mission_manager"|"script"
 *
 * Return Value:
 * Success <BOOL>
 *
 * Examples:
 * // From a unit init field -- register entity first, then start task from trigger/init.sqf:
 * [this, "compound_attack_01"] call forge_server_task_fnc_makeTarget;
 *
 * // From a trigger or init.sqf (all-in-one):
 * [
 *     "attack", "compound_attack_01", getPosATL leader1,
 *     "Attack: East Compound", "Eliminate all hostile forces.",
 *     createHashMapFromArray [["targets", [unit1, unit2, unit3]]],
 *     createHashMapFromArray [
 *         ["limitFail", 0], ["limitSuccess", 3],
 *         ["funds", 50000], ["ratingFail", -10], ["ratingSuccess", 20],
 *         ["timeLimit", 900]
 *     ]
 * ] call forge_server_task_fnc_startTask;
 *
 * Public: Yes
 */

params [
    ["_taskType", "", [""]],
    ["_taskID", "", [""]],
    ["_position", [0, 0, 0], [[]]],
    ["_title", "", [""]],
    ["_description", "", [""]],
    ["_entities", createHashMap, [createHashMap]],
    ["_taskParams", createHashMap, [createHashMap]],
    ["_minRating", 0, [0]],
    ["_requesterUid", "", [""]],
    ["_source", "eden", [""]]
];

if (_taskType isEqualTo "" || { _taskID isEqualTo "" }) exitWith {
    ["ERROR", "startTask: missing task type or task ID."] call EFUNC(common,log);
    false
};

// --- 1. Register task entities ---

private _iedTimer = _taskParams getOrDefault ["iedTimer", 0];

{
    private _role = _x;
    private _objects = _entities getOrDefault [_role, []];
    {
        if !(_x isEqualType objNull) then {
            ["WARNING", format ["startTask: skipping non-object entity for role '%1' in task '%2': %3", _role, _taskID, _x]] call EFUNC(common,log);
            continue;
        };
        if (isNull _x) then { continue; };
        switch (_role) do {
            case "targets": { [_x, _taskID] call FUNC(makeTarget); };
            case "hostages": { [_x, _taskID] call FUNC(makeHostage); };
            case "shooters": { [_x, _taskID] call FUNC(makeShooter); };
            case "hvts": { [_x, _taskID] call FUNC(makeHVT); };
            case "ieds": { [_x, _taskID, _iedTimer] call FUNC(makeIED); };
            case "protected": { [_x, _taskID] call FUNC(makeObject); };
            case "cargo": { [_x, _taskID] call FUNC(makeCargo); };
        };
    } forEach _objects;
} forEach ["targets", "hostages", "shooters", "hvts", "ieds", "protected", "cargo"];

// --- 2. Create BIS task ---

[west, _taskID, [_description, _title, _taskType], _position, "CREATED", 1, true, _taskType] call BFUNC(taskCreate);

// --- 3. Register catalog entry ---

GVAR(TaskStore) call ["registerTaskCatalogEntry", [_taskID, createHashMapFromArray [
    ["type", _taskType],
    ["title", _title],
    ["description", _description],
    ["position", _position],
    ["accepted", false],
    ["requesterUid", _requesterUid],
    ["orgID", "default"],
    ["source", _source]
]]];

// --- 4. Assemble type-specific handler args ---

private _limitFail = _taskParams getOrDefault ["limitFail", -1];
private _limitSuccess = _taskParams getOrDefault ["limitSuccess", -1];
private _funds = _taskParams getOrDefault ["funds", 0];
private _ratingFail = _taskParams getOrDefault ["ratingFail", 0];
private _ratingSuccess = _taskParams getOrDefault ["ratingSuccess", 0];
private _endSuccess = _taskParams getOrDefault ["endSuccess", false];
private _endFail = _taskParams getOrDefault ["endFail", false];
private _timeLimit = _taskParams getOrDefault ["timeLimit", 0];
private _equipRewards = _taskParams getOrDefault ["equipment", []];
private _supplyRewards = _taskParams getOrDefault ["supplies", []];
private _weaponRewards = _taskParams getOrDefault ["weapons", []];
private _vehicleRewards = _taskParams getOrDefault ["vehicles", []];
private _specialRewards = _taskParams getOrDefault ["special", []];

private _rewardTail = [_equipRewards, _supplyRewards, _weaponRewards, _vehicleRewards, _specialRewards];

private _handlerArgs = switch (_taskType) do {
    case "attack";
    case "destroy": {
        private _args = [_taskID, _limitFail, _limitSuccess, _funds, _ratingFail, _ratingSuccess, _endSuccess, _endFail, _timeLimit];
        _args + _rewardTail
    };
    case "defuse": {
        [_taskID, _limitFail, _limitSuccess, _funds, _ratingFail, _ratingSuccess, _endSuccess, _endFail] + _rewardTail
    };
    case "delivery": {
        private _deliveryZone = _taskParams getOrDefault ["deliveryZone", ""];
        private _args = [_taskID, _limitFail, _limitSuccess, _deliveryZone, _funds, _ratingFail, _ratingSuccess, _endSuccess, _endFail, _timeLimit];
        _args + _rewardTail
    };
    case "hostage": {
        private _extZone = _taskParams getOrDefault ["extractionZone", ""];
        private _cbrn = _taskParams getOrDefault ["cbrn", false];
        private _execution = _taskParams getOrDefault ["execution", false];
        private _cbrnZone = _taskParams getOrDefault ["cbrnZone", ""];
        private _args = [_taskID, _limitFail, _limitSuccess, _extZone, _funds, _ratingFail, _ratingSuccess, [_cbrn, _execution], _endSuccess, _endFail, _timeLimit];
        _args pushBack _cbrnZone;
        _args + _rewardTail
    };
    case "hvt": {
        private _extZone = _taskParams getOrDefault ["extractionZone", ""];
        private _captureHvt = _taskParams getOrDefault ["captureHvt", true];
        private _args = [_taskID, _limitFail, _limitSuccess, _extZone, _funds, _ratingFail, _ratingSuccess, [_captureHvt, !_captureHvt], _endSuccess, _endFail, _timeLimit];
        _args + _rewardTail
    };
    case "defend": {
        private _defenseZone = _taskParams getOrDefault ["defenseZone", ""];
        private _defendTime = _taskParams getOrDefault ["defendTime", 600];
        private _waveCount = _taskParams getOrDefault ["waveCount", 3];
        private _waveCooldown = _taskParams getOrDefault ["waveCooldown", 300];
        private _minBlufor = _taskParams getOrDefault ["minBlufor", 1];
        private _enemyTemplates = _taskParams getOrDefault ["enemyTemplates", []];
        [_taskID, _defenseZone, _defendTime, _funds, _ratingFail, _ratingSuccess, _endSuccess, _endFail, _waveCount, _waveCooldown, _minBlufor, _enemyTemplates] + _rewardTail
    };
    default {
        ["ERROR", format ["startTask: unknown task type '%1'.", _taskType]] call EFUNC(common,log);
        []
    };
};

if (_handlerArgs isEqualTo []) exitWith { false };

// --- 5. Dispatch handler ---

[_taskType, _handlerArgs, _minRating, _requesterUid] spawn FUNC(handler);

true
