#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the protected module
 *
 * Arguments:
 * 0: Logic <OBJECT> - The logic object
 * 1: Units <ARRAY> - The array of units
 * 2: Activated <BOOL> - Whether the module is activated
 *
 * Return Value:
 * None
 *
 * Example:
 * [logicObject, [unit1, unit2], true] call forge_server_task_fnc_protectedModule;
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if !(_activated) exitWith {};
