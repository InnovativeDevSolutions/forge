#include "..\script_component.hpp"

/*
 * File: fnc_openUI.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Opens the org UI.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * UI opened [BOOL]
 *
 * Example:
 * call forge_client_org_fnc_openUI;
 */

private _display = createDialog ["RscOrg", true];
private _ctrl = _display displayCtrl 1003;

_ctrl ctrlAddEventHandler ["JSDialog", {
    params ["_control", "_isConfirmDialog", "_message"];

    [_control, _isConfirmDialog, _message] call FUNC(handleUIEvents);
}];

_ctrl ctrlWebBrowserAction ["LoadFile", QPATHTOF2(ui\_site\index.html)];
// _ctrl ctrlWebBrowserAction ["OpenDevConsole"];

true;
