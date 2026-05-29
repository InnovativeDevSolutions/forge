#include "..\script_component.hpp"

/*
 * File: fnc_initWebUIBridge.sqf
 * Author: IDSolutions
 * Date: 2026-03-13
 * Last Update: 2026-03-13
 * Public: No
 *
 * Description:
 * Initializes the shared web UI bridge and screen declarations used by
 * CT_WEBBROWSER feature bridges.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Web UI bridge declarations [HASHMAP]
 *
 * Example:
 * call forge_client_common_fnc_initWebUIBridge
 */

if !(isNil QGVAR(WebUIScreenDeclaration) || { isNil QGVAR(WebUIBridgeDeclaration) }) exitWith {
    createHashMapFromArray [
        ["bridgeDeclaration", GVAR(WebUIBridgeDeclaration)],
        ["screenDeclaration", GVAR(WebUIScreenDeclaration)]
    ]
};

#pragma hemtt ignore_variables ["_self"]
GVAR(WebUIScreenDeclaration) = compileFinal createHashMapFromArray [
    ["#type", "IWebUIScreen"],
    ["#create", compileFinal {
        params [["_control", controlNull, [controlNull]]];

        _self set ["control", _control];
        _self set ["readyState", false];
        _self set ["pendingEvents", []];
    }],
    ["dispose", compileFinal {
        _self set ["control", controlNull];
        _self set ["readyState", false];
        _self set ["pendingEvents", []];

        true
    }],
    ["getControl", compileFinal {
        _self getOrDefault ["control", controlNull]
    }],
    ["consumePendingEvents", compileFinal {
        private _pendingEvents = +(_self getOrDefault ["pendingEvents", []]);
        _self set ["pendingEvents", []];

        _pendingEvents
    }],
    ["isReady", compileFinal {
        _self getOrDefault ["readyState", false]
    }],
    ["markReady", compileFinal {
        params [["_isReady", true, [false]]];

        _self set ["readyState", _isReady];
        _isReady
    }],
    ["queueEvent", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _pendingEvents = +(_self getOrDefault ["pendingEvents", []]);
        _pendingEvents pushBack _payload;
        _self set ["pendingEvents", _pendingEvents];

        count _pendingEvents
    }],
    ["setControl", compileFinal {
        params [["_control", controlNull, [controlNull]]];

        _self set ["control", _control];
        _control
    }],
    ["#delete", compileFinal {
        _self call ["dispose", []];
    }]
];

GVAR(WebUIBridgeDeclaration) = compileFinal createHashMapFromArray [
    ["#type", "IWebUIBridge"],
    ["#create", compileFinal {
        _self set ["screen", createHashMapObject [GVAR(WebUIScreenDeclaration)]];
    }],
    ["deliverPayload", compileFinal {
        params [["_control", controlNull, [controlNull]], ["_payload", createHashMap, [createHashMap]]];

        if (isNull _control) exitWith { false };

        private _json = toJSON _payload;
        _control ctrlWebBrowserAction ["ExecJS", format ["ForgeBridge.receive(%1)", _json]];

        true
    }],
    ["execJS", compileFinal {
        params [["_control", controlNull, [controlNull]], ["_statement", "", [""]]];

        if (isNull _control || { _statement isEqualTo "" }) exitWith { false };

        _control ctrlWebBrowserAction ["ExecJS", _statement];
        true
    }],
    ["flushPendingEvents", compileFinal {
        private _screen = _self call ["getScreen", []];
        private _control = _self call ["getActiveBrowserControl", []];
        if (isNull _control) exitWith { 0 };

        private _pendingEvents = _screen call ["consumePendingEvents", []];

        {
            _self call ["deliverPayload", [_control, _x]];
        } forEach _pendingEvents;

        count _pendingEvents
    }],
    ["getActiveBrowserControl", compileFinal {
        private _screen = _self call ["getScreen", []];
        _screen call ["getControl", []]
    }],
    ["getScreen", compileFinal {
        private _hasScreen = "screen" in _self;
        private _screen = if (_hasScreen) then {
            _self get "screen"
        } else {
            createHashMap
        };

        if (!_hasScreen) then {
            _screen = createHashMapObject [GVAR(WebUIScreenDeclaration)];
            _self set ["screen", _screen];
        };

        _screen
    }],
    ["handleClose", compileFinal {
        private _screen = _self call ["getScreen", []];
        _screen call ["dispose", []]
    }],
    ["handleReady", compileFinal {
        params [["_control", controlNull, [controlNull]], ["_data", createHashMap, [createHashMap]]];

        private _screen = _self call ["getScreen", []];
        _screen call ["setControl", [_control]];
        _screen call ["markReady", [true]];

        _self call ["flushPendingEvents", []];
        true
    }],
    ["queueEvent", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _screen = _self call ["getScreen", []];
        _screen call ["queueEvent", [_payload]]
    }],
    ["sendEvent", compileFinal {
        params [
            ["_event", "", [""]],
            ["_data", createHashMap, [createHashMap]],
            ["_control", controlNull, [controlNull]]
        ];

        if (_event isEqualTo "") exitWith { false };

        private _payload = createHashMapFromArray [
            ["event", _event],
            ["data", _data]
        ];
        private _screen = _self call ["getScreen", []];
        private _targetControl = _control;

        if (isNull _targetControl) then {
            _targetControl = _self call ["getActiveBrowserControl", []];
        };

        if (isNull _targetControl) exitWith {
            _self call ["queueEvent", [_payload]];
            false
        };

        _screen call ["setControl", [_targetControl]];

        if !(_screen call ["isReady", []]) exitWith {
            _self call ["queueEvent", [_payload]];
            false
        };

        _self call ["deliverPayload", [_targetControl, _payload]]
    }],
    ["setActiveBrowserControl", compileFinal {
        params [["_control", controlNull, [controlNull]]];

        private _screen = _self call ["getScreen", []];
        _screen call ["setControl", [_control]]
    }],
    ["#delete", compileFinal {
        _self call ["handleClose", []];
    }]
];

createHashMapFromArray [
    ["bridgeDeclaration", GVAR(WebUIBridgeDeclaration)],
    ["screenDeclaration", GVAR(WebUIScreenDeclaration)]
]
