#include "..\script_component.hpp"

/*
 * File: fnc_handleUIEvents.sqf
 * Author: IDSolutions
 * Date: 2025-12-16
 * Last Update: 2026-04-18
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
 * call forge_client_garage_fnc_handleUIEvents;
 */

params ["_control", "_isConfirmDialog", "_message"];

private _alert = fromJSON _message;
private _event = _alert get "event";
private _data = _alert get "data";

diag_log format ["[FORGE:Client:Garage] Handling UI event: %1 with data: %2", _event, _data];

switch (_event) do {
    case "garage::close": {
        if !(isNil QGVAR(GarageUIBridge)) then {
            GVAR(GarageUIBridge) call ["handleClose", []];
        };

        closeDialog 1;
    };
    case "garage::ready": {
        if !(isNil QGVAR(GarageUIBridge)) then {
            GVAR(GarageUIBridge) call ["handleReady", [_control, _data]];
        };
    };
    case "garage::vehicle::retrieve::request": {
        if !(isNil QGVAR(GarageActionService)) then {
            GVAR(GarageActionService) call ["handleRetrieveRequest", [_data]];
        };
    };
    case "garage::vehicle::store::request": {
        if !(isNil QGVAR(GarageActionService)) then {
            GVAR(GarageActionService) call ["handleStoreRequest", [_data]];
        };
    };
    case "garage::vehicle::refuel::request": {
        if !(isNil QGVAR(GarageActionService)) then {
            GVAR(GarageActionService) call ["handleRefuelRequest", [_data]];
        };
    };
    case "garage::vehicle::repair::request": {
        if !(isNil QGVAR(GarageActionService)) then {
            GVAR(GarageActionService) call ["handleRepairRequest", [_data]];
        };
    };
    case "garage::vehicle::rearm::request": {
        if !(isNil QGVAR(GarageActionService)) then {
            GVAR(GarageActionService) call ["handleRearmRequest", [_data]];
        };
    };
    case "garage::refresh": {
        if !(isNil QGVAR(GarageUIBridge)) then {
            GVAR(GarageUIBridge) call ["refreshGarage", []];
        };
    };
    default {
        hint format ["Unhandled garage UI event: %1", _event];
    };
};

true;
