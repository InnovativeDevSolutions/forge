#include "..\script_component.hpp"

/*
 * File: fnc_initUIBridge.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the store UI bridge for browser control state and store UI events.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Store UI bridge object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_store_fnc_initUIBridge;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(StoreUIBridgeBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "StoreUIBridgeBaseClass"],
    ["getActiveBrowserControl", compileFinal {
        private _display = uiNamespace getVariable ["RscStore", displayNull];
        if (isNull _display) exitWith { controlNull };

        _display displayCtrl 1004
    }],
    ["execBridge", compileFinal {
        params [["_control", controlNull, [controlNull]], ["_fnName", "", [""]], ["_payload", createHashMap, [createHashMap]]];

        if (isNull _control || { _fnName isEqualTo "" }) exitWith { false };

        private _json = toJSON _payload;
        _control ctrlWebBrowserAction ["ExecJS", format ["StoreUIBridge.%1(%2)", _fnName, _json]];

        true
    }],
    ["sendBridgeEvent", compileFinal {
        params [["_event", "", [""]], ["_data", createHashMap, [createHashMap]], ["_control", controlNull, [controlNull]]];

        if (_event isEqualTo "") exitWith { false };

        private _targetControl = _control;
        if (isNull _targetControl) then { _targetControl = _self call ["getActiveBrowserControl", []]; };
        if (isNull _targetControl) exitWith { false };

        _self call ["execBridge", [_targetControl, "receive", createHashMapFromArray [
            ["event", _event],
            ["data", _data]
        ]]]
    }],
    ["handleReady", compileFinal {
        params [["_control", controlNull, [controlNull]]];

        private _uid = getPlayerUID player;
        if (_uid isEqualTo "") exitWith {
            _self call ["sendBridgeEvent", ["store::hydrate", createHashMap, _control]];
        };

        [SRPC(store,requestHydrateStore), [_uid, "store::hydrate"]] call CFUNC(serverEvent);
    }],
    ["handleCategoryRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _category = toLowerANSI (_data getOrDefault ["category", ""]);
        private _uid = getPlayerUID player;
        if (_category isEqualTo "") exitWith {
            _self call ["sendBridgeEvent", ["store::category::failure", createHashMapFromArray [
                ["message", "No store category was provided."]
            ]]];
        };

        if (_uid isEqualTo "") exitWith {
            _self call ["sendBridgeEvent", ["store::category::failure", createHashMapFromArray [
                ["category", _category],
                ["message", "Store catalog request is unavailable."]
            ]]];
        };

        diag_log format ["[FORGE:Client:Store] Category request forwarded to server: %1", _category];
        [SRPC(store,requestCategory), [_uid, _category]] call CFUNC(serverEvent);
    }],
    ["handleCategoryResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _success = _payload getOrDefault ["success", false];
        private _bridgeEvent = ["store::category::failure", "store::category::hydrate"] select _success;
        _self call ["sendBridgeEvent", [_bridgeEvent, _payload]];
    }],
    ["refreshStoreConfig", compileFinal {
        private _uid = getPlayerUID player;
        if (_uid isEqualTo "") exitWith { false };

        [SRPC(store,requestHydrateStore), [_uid, "store::config::hydrate"]] call CFUNC(serverEvent);
        true
    }],
    ["handleHydrateResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]], ["_bridgeEvent", "store::hydrate", [""]]];

        private _event = _bridgeEvent;
        if !(_event in ["store::hydrate", "store::config::hydrate"]) then { _event = "store::hydrate"; };

        _self call ["sendBridgeEvent", [_event, _payload]]
    }],
    ["handleCheckoutRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _uid = getPlayerUID player;
        private _checkoutJson = _data getOrDefault ["checkoutJson", ""];

        if (_uid isEqualTo "" || { _checkoutJson isEqualTo "" }) exitWith {
            _self call ["sendBridgeEvent", ["store::checkout::failure", createHashMapFromArray [
                ["message", "Add at least one supported item before checkout."]
            ]]];
        };

        diag_log format ["[FORGE:Client:Store] Checkout request forwarded to server: %1", _checkoutJson];
        [SRPC(store,requestCheckout), [_uid, _checkoutJson]] call CFUNC(serverEvent);
    }],
    ["handleCheckoutResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _success = _payload getOrDefault ["success", false];
        private _bridgeEvent = ["store::checkout::failure", "store::checkout::success"] select _success;
        _self call ["sendBridgeEvent", [_bridgeEvent, _payload]];

        if (_success) then {
            [] spawn {
                sleep 0.05;
                if !(isNil QGVAR(StoreUIBridge)) then {
                    GVAR(StoreUIBridge) call ["refreshStoreConfig", []];
                };
            };
        };
    }]
];

GVAR(StoreUIBridge) = createHashMapObject [GVAR(StoreUIBridgeBaseClass)];
GVAR(StoreUIBridge)
