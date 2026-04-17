#include "..\script_component.hpp"

/*
 * File: fnc_openUI.sqf
 * Author: IDSolutions
 * Date: 2026-01-28
 * Last Update: 2026-01-30
 * Public: No
 *
 * Description:
 * Opens the player bank interaction interface.
 *
 * Arguments:
 * 0: [BOOL] - Whether to open the ATM interface
 *
 * Return Value:
 * UI opened [BOOL]
 *
 * Example:
 * [true] call forge_client_bank_fnc_openUI;
 */

params [["_isATM", false, [false]]];

private _display = createDialog ["RscBank", true];
private _ctrl = _display displayCtrl 1002;

_ctrl ctrlAddEventHandler ["JSDialog", {
    params ["_control", "_isConfirmDialog", "_message"];

    [_control, _isConfirmDialog, _message] call FUNC(handleUIEvents);
}];

if !(isNil QGVAR(BankUIBridge)) then {
    GVAR(BankUIBridge) call ["setMode", [["bank", "atm"] select _isATM]];
    GVAR(BankUIBridge) call ["setActiveBrowserControl", [_ctrl]];
};

_ctrl ctrlWebBrowserAction ["LoadFile", QPATHTOF2(ui\_site\index.html)];

true;
