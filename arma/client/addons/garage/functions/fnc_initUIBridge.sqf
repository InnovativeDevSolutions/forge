#include "..\script_component.hpp"

/*
 * File: fnc_initUIBridge.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the garage UI bridge for browser control state and UI events.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Garage UI bridge object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_garage_fnc_initUIBridge;
 */

#pragma hemtt ignore_variables ["_self"]
private _webUIDeclarations = call EFUNC(common,initWebUIBridge);
private _webUIBridgeDeclaration = _webUIDeclarations get "bridgeDeclaration";

GVAR(GarageUIBridgeBaseClass) = compileFinal createHashMapFromArray [
    ["#base", _webUIBridgeDeclaration],
    ["#type", "GarageUIBridgeBaseClass"],
    ["getActiveBrowserControl", compileFinal {
        private _display = uiNamespace getVariable ["RscGarage", displayNull];
        if (isNull _display) exitWith {
            _self call ["setActiveBrowserControl", [controlNull]];
            controlNull
        };

        private _control = _display displayCtrl 1006;
        _self call ["setActiveBrowserControl", [_control]];
        _control
    }],
    ["handleReady", compileFinal {
        params [["_control", controlNull, [controlNull]], ["_data", createHashMap, [createHashMap]]];

        private _screen = _self call ["getScreen", []];
        _screen call ["setControl", [_control]];
        _screen call ["markReady", [true]];

        _self call ["flushPendingEvents", []];
        _self call ["sendEvent", ["garage::hydrate", GVAR(GaragePayloadService) call ["buildPayload", []], _control]];
    }],
    ["refreshGarage", compileFinal {
        private _control = _self call ["getActiveBrowserControl", []];
        if (isNull _control) exitWith { false };

        _self call ["sendEvent", ["garage::sync", GVAR(GaragePayloadService) call ["buildPayload", []], _control]]
    }]
];

GVAR(GarageUIBridge) = createHashMapObject [GVAR(GarageUIBridgeBaseClass)];
GVAR(GarageUIBridge)
