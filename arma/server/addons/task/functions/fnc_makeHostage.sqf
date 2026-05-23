#include "..\script_component.hpp"

/*
 * Assigns an AI unit to a task as a hostage.
 *
 * Public compatibility adapter around HostageEntityController. The hostage
 * task instance owns the rescue loop, so this helper only registers and
 * applies initial state.
 */

params [["_entity", objNull, [objNull, grpNull]], ["_taskID", "", [""]]];

if (isNull _entity) exitWith { ["ERROR", "Attempt to create entity from null object"] call EFUNC(common,log); false };
if (_taskID isEqualTo "") exitWith { ["ERROR", "No task ID provided for entity"] call EFUNC(common,log); false };

["INFO", format ["Make Hostage: %1", _this]] call EFUNC(common,log);

private _controller = createHashMapObject [
    GVAR(HostageEntityController),
    [_taskID, _entity, createHashMap]
];

if !(_controller call ["registerTaskEntity", ["hostages"]]) exitWith { false };
_controller call ["applyInitialState", []]
