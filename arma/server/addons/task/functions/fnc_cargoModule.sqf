#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Grouping module for cargo entities in a delivery task.
 * This module has no logic of its own — it acts as a sync target so that
 * cargo objects can be grouped and discovered by the parent delivery module
 * via synchronizedObjects + typeOf "FORGE_Module_Cargo".
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
