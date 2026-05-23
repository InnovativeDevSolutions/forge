#include "..\script_component.hpp"

/*
 * File: fnc_openUI.sqf
 * Author: IDSolutions
 * Date: 2026-03-28
 * Public: No
 *
 * Description:
 * Opens the CAD map interface.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * UI opened [BOOL]
 *
 * Example:
 * call forge_client_cad_fnc_openUI
 */

private _display = createDialog ["RscMapUI", true];
if (isNull _display) exitWith {
    diag_log "[FORGE:Client:CAD] ERROR: Failed to create CAD dialog.";
    false
};

private _topBarCtrl = _display displayCtrl 1002;
private _bottomBarCtrl = _display displayCtrl 1003;
private _sidePanelCtrl = _display displayCtrl 1005;
private _dispatcherCtrl = _display displayCtrl 1006;

{
    _x ctrlAddEventHandler ["JSDialog", {
        params ["_control", "_isConfirmDialog", "_message"];
        [_control, _isConfirmDialog, _message] call FUNC(handleUIEvents);
    }];
} forEach [_topBarCtrl, _bottomBarCtrl, _sidePanelCtrl, _dispatcherCtrl];

_topBarCtrl ctrlWebBrowserAction ["LoadFile", QPATHTOF2(ui\_site\topbar.html)];
_bottomBarCtrl ctrlWebBrowserAction ["LoadFile", QPATHTOF2(ui\_site\bottombar.html)];
_sidePanelCtrl ctrlWebBrowserAction ["LoadFile", QPATHTOF2(ui\_site\sidepanel.html)];
_dispatcherCtrl ctrlWebBrowserAction ["LoadFile", QPATHTOF2(ui\_site\dispatcher.html)];

if !(isNil QGVAR(CADRepository)) then {
    GVAR(CADRepository) call ["setOpen", [true]];
};

true
