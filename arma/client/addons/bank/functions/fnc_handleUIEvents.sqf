#include "..\script_component.hpp"

/*
 * File: fnc_handleUIEvents.sqf
 * Author: IDSolutions
 * Date: 2025-12-16
 * Last Update: 2026-02-17
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
 * call forge_client_bank_fnc_handleUIEvents;
 */

params ["_control", "_isConfirmDialog", "_message"];

private _alert = fromJSON _message;
private _event = _alert get "event";
private _data = _alert get "data";

diag_log format ["[FORGE:Client:Bank] Handling UI event: %1 with data: %2", _event, _data];

switch (_event) do {
    case "bank::close": {
        if !(isNil QGVAR(BankUIBridge)) then {
            GVAR(BankUIBridge) call ["handleClose", []];
        };

        closeDialog 1;
    };
    case "bank::ready": {
        if !(isNil QGVAR(BankUIBridge)) then {
            GVAR(BankUIBridge) call ["handleReady", [_control, _data]];
        };
    };
    case "bank::refresh": {
        if !(isNil QGVAR(BankUIBridge)) then {
            GVAR(BankUIBridge) call ["refreshSession", []];
        };
    };
    case "bank::deposit::request": {
        if !(isNil QGVAR(BankUIBridge)) then {
            GVAR(BankUIBridge) call ["handleDepositRequest", [_data]];
        };
    };
    case "bank::withdraw::request": {
        if !(isNil QGVAR(BankUIBridge)) then {
            GVAR(BankUIBridge) call ["handleWithdrawRequest", [_data]];
        };
    };
    case "bank::transfer::request": {
        if !(isNil QGVAR(BankUIBridge)) then {
            GVAR(BankUIBridge) call ["handleTransferRequest", [_data]];
        };
    };
    case "bank::depositEarnings::request": {
        if !(isNil QGVAR(BankUIBridge)) then {
            GVAR(BankUIBridge) call ["handleDepositEarningsRequest", [_data]];
        };
    };
    case "bank::repayCreditLine::request": {
        if !(isNil QGVAR(BankUIBridge)) then {
            GVAR(BankUIBridge) call ["handleRepayCreditLineRequest", [_data]];
        };
    };
    case "bank::pin::request": {
        if !(isNil QGVAR(BankUIBridge)) then {
            GVAR(BankUIBridge) call ["handleSubmitPinRequest", [_data]];
        };
    };
    case "bank::pin::change::request": {
        if !(isNil QGVAR(BankUIBridge)) then {
            GVAR(BankUIBridge) call ["handleChangePinRequest", [_data]];
        };
    };
    default {
        hint format ["Unhandled bank UI event: %1", _event];
    };
};

true;
