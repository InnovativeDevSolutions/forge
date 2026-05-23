#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Converts systemTime array to total seconds since midnight.
 *
 * Arguments:
 * 0: System time array from systemTime command <ARRAY>
 *
 * Return Value:
 * Total seconds since midnight <NUMBER>
 *
 * Example:
 * [systemTime] call forge_server_common_fnc_timeToSeconds
 * // Returns: 43200 (for 12:00:00)
 *
 * Public: Yes
 */

params [["_systemTime", [], [[]]]];

if (typeName _systemTime != "ARRAY") exitWith {
    ["WARNING", format ["timeToSeconds received %1 instead of ARRAY: %2", typeName _systemTime, _systemTime], nil, nil] call EFUNC(common,log);
    0
};

if (count _systemTime < 6) exitWith {
    ["WARNING", format ["timeToSeconds received array with %1 elements, need at least 6: %2", count _systemTime, _systemTime], nil, nil] call EFUNC(common,log);
    0
};

private _hours = _systemTime select 3;
private _minutes = _systemTime select 4;
private _seconds = _systemTime select 5;

(_hours * 3600) + (_minutes * 60) + _seconds
