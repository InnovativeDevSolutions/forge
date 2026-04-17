#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the defend task module.
 * Reads parameters from the logic object and delegates to fnc_startTask.
 * The designer must place a named marker in Eden for the defense zone.
 * Enemy waves are spawned automatically by fnc_defend — no entities need
 * to be synced to this module.
 *
 * Arguments:
 * 0: Logic <OBJECT>
 * 1: Units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if !(_activated) exitWith {};

private _taskID = _logic getVariable ["TaskID", ""];
private _defenseZone = _logic getVariable ["DefenseZone", ""];

if (_taskID isEqualTo "") exitWith {
    ["ERROR", "Defend module: no task ID configured."] call EFUNC(common,log);
};
if (_defenseZone isEqualTo "" || { markerShape _defenseZone isEqualTo "" }) exitWith {
    ["ERROR", format ["Defend module '%1': DefenseZone marker '%2' is missing or invalid.", _taskID, _defenseZone]] call EFUNC(common,log);
};

["INFO", format [
    "Defend Module Parameters: TaskID: %1, DefenseZone: %2, DefendTime: %3, WaveCount: %4, WaveCooldown: %5, MinBlufor: %6",
    _taskID, _defenseZone,
    _logic getVariable ["DefendTime", 600],
    _logic getVariable ["WaveCount", 3],
    _logic getVariable ["WaveCooldown", 300],
    _logic getVariable ["MinBlufor", 1]
]] call EFUNC(common,log);

[
    "defend",
    _taskID,
    getMarkerPos _defenseZone,
    format ["Defend: %1", _taskID],
    "Hold the defense zone against incoming enemy forces.",
    createHashMap,
    createHashMapFromArray [
        ["funds", _logic getVariable ["CompanyFunds", 0]],
        ["ratingFail", _logic getVariable ["RatingFail", 0]],
        ["ratingSuccess", _logic getVariable ["RatingSuccess", 0]],
        ["endSuccess", _logic getVariable ["EndSuccess", false]],
        ["endFail", _logic getVariable ["EndFail", false]],
        ["defenseZone", _defenseZone],
        ["defendTime", _logic getVariable ["DefendTime", 600]],
        ["waveCount", _logic getVariable ["WaveCount", 3]],
        ["waveCooldown", _logic getVariable ["WaveCooldown", 300]],
        ["minBlufor", _logic getVariable ["MinBlufor", 1]]
    ]
] call FUNC(startTask);

deleteVehicle _logic;
