#include "..\script_component.hpp"

/*
 * File: fnc_initService.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the notification service for client notification display.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Notification service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_notifications_fnc_initService;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(NotificationService) = createHashMapObject [[
    ["#type", "INotificationService"],
    ["#create", {
        private _display = uiNamespace getVariable ["RscNotifications", nil];
        private _control = _display displayCtrl 1004;

        _self set ["control", _control];
        _self set ["isLoaded", false];
    }],
    ["init", {
        private _params = ["success", "System Ready", "Notification system handshake complete!", 3000];

        _self call ["create", _params];
        _self set ["isLoaded", true];

        systemChat format ["Notifications loaded for %1", name player];
        diag_log "[FORGE:Client:Notifications] Notification Service Initialized!";
    }],
    ["create", {
        params [["_type", "", ["info"]], ["_title", "", [""]], ["_content", "", [""]], ["_duration", 4000]];

        private _control = _self get "control";
        private _message = createHashMap;

        _message set ["type", _type];
        _message set ["title", _title];
        _message set ["message", _content];
        _message set ["duration", _duration];

        _control ctrlWebBrowserAction ["ExecJS", format ["window.dispatchEvent(new CustomEvent('forge:notify', { detail: %1 }))", (toJSON _message)]];
    }]
]];

GVAR(NotificationService)
