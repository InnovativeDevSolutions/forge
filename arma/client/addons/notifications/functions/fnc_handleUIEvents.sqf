#include "..\script_component.hpp"

/*
 * File: fnc_handleUIEvents.sqf
 * Author: IDSolutions
 * Date: 2026-01-28
 * Last Update: 2026-01-30
 * Public: No
 *
 * Description:
 * Handles the UI events.
 *
 * Arguments:
 * 0: [CONTROL] - The control that triggered the event
 * 1: [BOOL] - Whether the event is from a confirm dialog
 * 2: [STRING] - The message containing the event data
 *
 * Return Value:
 * UI events handled [BOOL]
 *
 * Example:
 * call forge_client_notifications_fnc_handleUIEvents;
 */

params ["_control", "_isConfirmDialog", "_message"];

private _alert = fromJSON _message;
private _event = _alert get "event";
private _data = _alert get "data";

diag_log format ["[FORGE:Client:Notifications] Handling UI event: %1 with data: %2", _event, _data];

switch (_event) do {
    case "notifications::ready": {
        GVAR(NotificationService) call ["init", []];
    };
    default { hint format ["[FORGE:Client:Notifications] Unhandled event: %1", _event]; };
};

true;
