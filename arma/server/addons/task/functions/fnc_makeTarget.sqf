#include "..\script_component.hpp"

/*
 * Assigns an object to a task as a target.
 *
 * Public compatibility adapter around TargetEntityController.
 */

params [["_entity", objNull, [objNull, grpNull]], ["_taskID", "", [""]]];

if (isNull _entity) exitWith { ["ERROR", "Attempt to create entity from null object"] call EFUNC(common,log); false };
if (_taskID isEqualTo "") exitWith { ["ERROR", "No task ID provided for entity"] call EFUNC(common,log); false };

["INFO", format ["Make Target: %1", _this]] call EFUNC(common,log);

private _controller = createHashMapObject [
    GVAR(TargetEntityController),
    [_taskID, _entity, createHashMap]
];

_controller call ["registerTaskEntity", ["targets"]]
