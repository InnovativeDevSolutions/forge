#include "..\script_component.hpp"

/*
 * File: fnc_initLocker.sqf
 * Author: IDSolutions
 * Date: 2025-12-17
 * Last Update: 2026-02-05
 * Public: No
 *
 * Description:
 * Initializes lockers by hiding editor-placed global locker objects.
 * Each client will create their own local instance.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call forge_server_locker_fnc_initLocker
 */

private _lockers = (allVariables missionNamespace) select {
    private _var = missionNamespace getVariable _x;
    ("locker" in _x) && { _var isEqualType objNull } && { !isNull _var } && { _x isNotEqualTo "forge_locker_box" }
};

if (_lockers isEqualTo []) exitWith { ["INFO", "No editor-placed lockers found."] call EFUNC(common,log) };

{
    private _locker = missionNamespace getVariable _x;
    _locker hideObjectGlobal true;
} forEach _lockers;
