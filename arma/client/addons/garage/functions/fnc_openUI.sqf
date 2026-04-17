#include "..\script_component.hpp"

/*
 * File: fnc_openUI.sqf
 * Author: IDSolutions
 * Date: 2025-12-16
 * Last Update: 2026-01-30
 * Public: No
 *
 * Description:
 * Opens the garage UI.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * UI opened [BOOL]
 *
 * Example:
 * call forge_client_garage_fnc_openUI;
 */

private _display = createDialog ["RscGarage", true];
private _ctrl = _display displayCtrl 1006;

_ctrl ctrlAddEventHandler ["JSDialog", {
    params ["_control", "_isConfirmDialog", "_message"];

    [_control, _isConfirmDialog, _message] call FUNC(handleUIEvents);
}];

if !(isNil QGVAR(GarageUIBridge)) then {
    GVAR(GarageUIBridge) call ["setActiveBrowserControl", [_ctrl]];
};

_ctrl ctrlWebBrowserAction ["LoadFile", QPATHTOF2(ui\_site\index.html)];

true;
