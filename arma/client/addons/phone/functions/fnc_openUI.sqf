#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Open phone interface.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call forge_client_phone_fnc_openUI;
 *
 * Public: No
 */

private _display = (findDisplay 46) createDisplay "RscPhone";
private _ctrl = (_display displayCtrl 1001);

_ctrl ctrlAddEventHandler ["JSDialog", {
    params ["_control", "_isConfirmDialog", "_message"];

    [_control, _isConfirmDialog, _message] call FUNC(handleUIEvents);
}];

_ctrl ctrlWebBrowserAction ["LoadFile", QUOTE(PATHTOF(ui\_site\index.html))];
// _ctrl ctrlWebBrowserAction ["OpenDevConsole"];

true;
