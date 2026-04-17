#include "..\script_component.hpp"

/*
 * Assigns cargo to a task for delivery.
 *
 * Public compatibility adapter around CargoEntityController.
 */

params [["_cargo", objNull, [objNull]], ["_taskID", "", [""]]];

["INFO", format ["Make Cargo: %1", _this]] call EFUNC(common,log);

if (isNull _cargo) exitWith { ["ERROR", "Attempt to create cargo from null object"] call EFUNC(common,log); false };
if (_taskID isEqualTo "") exitWith { ["ERROR", "No task ID provided for cargo"] call EFUNC(common,log); false };

private _controller = createHashMapObject [
    GVAR(CargoEntityController),
    [_taskID, _cargo, createHashMap]
];

if !(_controller call ["registerTaskEntity", ["cargo"]]) exitWith { false };
_controller call ["watchDamage", []]
