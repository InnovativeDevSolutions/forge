#include "..\script_component.hpp"

/*
 * Assigns an AI unit to a task as an HVT.
 *
 * Public compatibility adapter around HVTEntityController.
 */

params [["_entity", objNull, [objNull, grpNull]], ["_taskID", "", [""]]];

if (isNull _entity) exitWith { ["ERROR", "Attempt to create entity from null object"] call EFUNC(common,log); false };
if (_taskID isEqualTo "") exitWith { ["ERROR", "No task ID provided for entity"] call EFUNC(common,log); false };

["INFO", format ["Make HVT: %1", _this]] call EFUNC(common,log);

private _controller = createHashMapObject [
    GVAR(HVTEntityController),
    [_taskID, _entity, createHashMap]
];

_controller call ["registerTaskEntity", ["hvts"]];

true
