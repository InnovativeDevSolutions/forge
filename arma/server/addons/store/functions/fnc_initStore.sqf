#include "..\script_component.hpp"

/*
 * File: fnc_initStore.sqf
 * Author: IDSolutions
 * Date: 2026-04-17
 * Public: No
 *
 * Description:
 * Initializes all editor-placed store entities.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call forge_server_store_fnc_initStore
 */

private _stores = (allVariables missionNamespace) select {
    private _var = missionNamespace getVariable _x;
    ("store" in _x) && { _var isEqualType objNull } && { !isNull _var }
};

if (_stores isEqualTo []) exitWith { ["INFO", "No editor-placed stores found."] call EFUNC(common,log) };

{
    private _store = missionNamespace getVariable _x;
    SETPVAR(_store,isStore,true);
} forEach _stores;
