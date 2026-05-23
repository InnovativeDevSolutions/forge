#include "..\script_component.hpp"

/*
 * Assigns an IED to a task and starts its required countdown timer.
 *
 * Public compatibility adapter around IEDEntityController.
 */

params [["_entity", objNull, [objNull]], ["_taskID", "", [""]], ["_time", 0, [0]]];

if (isNull _entity) exitWith { ["ERROR", "Attempt to create entity from null object"] call EFUNC(common,log); false };
if (_taskID isEqualTo "") exitWith { ["ERROR", "No task ID provided for entity"] call EFUNC(common,log); false };
if (_time <= 0) exitWith { ["ERROR", "Invalid time provided for IED"] call EFUNC(common,log); false };

["INFO", format ["Make IED: %1", _this]] call EFUNC(common,log);

_entity setVariable [QGVAR(iedCountdown), _time, true];

private _controller = createHashMapObject [
    GVAR(IEDEntityController),
    [_taskID, _entity, createHashMapFromArray [["countdown", _time]]]
];

_controller call ["registerTaskEntity", ["ieds"]];

true
