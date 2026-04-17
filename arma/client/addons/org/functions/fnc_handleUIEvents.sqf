#include "..\script_component.hpp"

/*
 * File: fnc_handleUIEvents.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Handles the org UI events.
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
 * call forge_client_org_fnc_handleUIEvents;
 */

params ["_control", "_isConfirmDialog", "_message"];

private _alert = fromJSON _message;
private _event = _alert get "event";
private _data = _alert get "data";

diag_log format ["[FORGE:Client:Org] Handling UI event: %1 with data: %2", _event, _data];

switch (_event) do {
    case "org::close": { closeDialog 1; };
    case "org::login::request": {
        GVAR(OrgUIBridge) call ["handleLoginRequest", [_control]];
    };
    case "org::create::request": {
        GVAR(OrgUIBridge) call ["handleCreateRequest", [_control, _data]];
    };
    case "org::disband::request": {
        GVAR(OrgUIBridge) call ["requestDisband", []];
    };
    case "org::leave::request": {
        GVAR(OrgUIBridge) call ["requestLeave", []];
    };
    case "org::credit::request": {
        GVAR(OrgUIBridge) call ["requestCreditLine", [_data]];
    };
    case "org::payroll::request": {
        GVAR(OrgUIBridge) call ["requestPayroll", [_data]];
    };
    case "org::transfer::request": {
        GVAR(OrgUIBridge) call ["requestTransferFunds", [_data]];
    };
    case "org::invite::request": {
        GVAR(OrgUIBridge) call ["requestInvite", [_data]];
    };
    case "org::invite::accept": {
        GVAR(OrgUIBridge) call ["requestAcceptInvite", [_data]];
    };
    case "org::invite::decline": {
        GVAR(OrgUIBridge) call ["requestDeclineInvite", [_data]];
    };
    case "org::ready": {
        GVAR(OrgUIBridge) call ["handleReady", [_control]];
    };
    default { hint format ["Unhandled UI event: %1", _event]; };
};

true;
