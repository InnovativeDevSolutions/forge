#include "..\script_component.hpp"

/*
 * File: fnc_initUI.sqf
 * Author: IDSolutions
 * Date: 2026-03-28
 * Public: No
 *
 * Description:
 * Initializes the CAD map dialog controls and local map event handling.
 *
 * Arguments:
 * 0: Display [DISPLAY]
 *
 * Return Value:
 * UI initialized [BOOL]
 *
 * Example:
 * [_display] call forge_client_cad_fnc_initUI
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith { false };

private _mapCtrl = _display displayCtrl 1001;
private _topBarCtrl = _display displayCtrl 1002;
private _bottomBarCtrl = _display displayCtrl 1003;
private _sidePanelCtrl = _display displayCtrl 1005;
private _dispatcherCtrl = _display displayCtrl 1006;

uiNamespace setVariable [QGVAR(Display), _display];
uiNamespace setVariable [QGVAR(MapCtrl), _mapCtrl];
uiNamespace setVariable [QGVAR(TopBarCtrl), _topBarCtrl];
uiNamespace setVariable [QGVAR(BottomBarCtrl), _bottomBarCtrl];
uiNamespace setVariable [QGVAR(SidePanelCtrl), _sidePanelCtrl];
uiNamespace setVariable [QGVAR(DispatcherCtrl), _dispatcherCtrl];

_dispatcherCtrl ctrlShow false;

private _center = if (isNull player) then {
    [worldSize / 2, worldSize / 2, 0]
} else {
    getPosATL player
};

_mapCtrl ctrlMapAnimAdd [0, 0.2, _center];
ctrlMapAnimCommit _mapCtrl;

diag_log "[FORGE:Client:CAD] CAD UI initialized.";
true
