#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Opens the framework mission setup UI.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * UI opened <BOOL>
 *
 * Public: Yes
 */

if !(hasInterface) exitWith {
    diag_log "[FORGE:Client:MissionSetup] openUI skipped: no interface.";
    false
};
if !(isNull (uiNamespace getVariable ["RscMissionSetup", displayNull])) exitWith {
    diag_log "[FORGE:Client:MissionSetup] openUI skipped: dialog already open.";
    true
};

diag_log "[FORGE:Client:MissionSetup] Creating mission setup dialog.";

private _display = createDialog ["RscMissionSetup", true];
if (isNull _display) exitWith {
    diag_log "[FORGE:Client:MissionSetup] createDialog returned null display.";
    false
};

uiNamespace setVariable [QGVAR(MissionSetupHandled), false];
_display displayAddEventHandler ["Unload", {
    if !(uiNamespace getVariable [QGVAR(MissionSetupHandled), false]) then {
        diag_log "[FORGE:Client:MissionSetup] Dialog unloaded before apply/cancel; applying default mission setup settings.";
        [SRPC(task,requestApplyMissionSetupSettings), [createHashMap, player]] call CFUNC(serverEvent);
    };

    uiNamespace setVariable [QGVAR(MissionSetupHandled), nil];
}];

private _control = _display displayCtrl 94011;
if (isNull _control) exitWith {
    diag_log "[FORGE:Client:MissionSetup] Browser control 94011 not found. Closing dialog.";
    closeDialog 1;
    false
};

_control ctrlAddEventHandler ["JSDialog", {
    params ["_control", "_isConfirmDialog", "_message"];
    [_control, _isConfirmDialog, _message] call FUNC(handleUIEvents);
}];

_control ctrlWebBrowserAction ["LoadFile", QPATHTOF2(ui\_site\index.html)];
diag_log "[FORGE:Client:MissionSetup] Mission setup UI load requested.";

true
