#include "..\script_component.hpp"

/*
 * File: fnc_initUIBridge.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the bank UI bridge for browser control state and bank UI events.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Bank UI bridge object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_bank_fnc_initUIBridge;
 */

#pragma hemtt ignore_variables ["_self"]
private _webUIDeclarations = call EFUNC(common,initWebUIBridge);
private _webUIBridgeDeclaration = _webUIDeclarations get "bridgeDeclaration";

GVAR(BankUIBridgeBaseClass) = compileFinal createHashMapFromArray [
    ["#base", _webUIBridgeDeclaration],
    ["#type", "BankUIBridgeBaseClass"],
    ["#create", compileFinal {
        _self set ["mode", "bank"];
    }],
    ["getActiveBrowserControl", compileFinal {
        private _display = uiNamespace getVariable ["RscBank", displayNull];
        if (isNull _display) exitWith {
            _self call ["setActiveBrowserControl", [controlNull]];
            controlNull
        };

        private _control = _display displayCtrl 1002;
        _self call ["setActiveBrowserControl", [_control]];
        _control
    }],
    ["getMode", compileFinal {
        _self getOrDefault ["mode", "bank"]
    }],
    ["hasOpenScreen", compileFinal {
        private _screen = _self call ["getScreen", []];
        private _control = _self call ["getActiveBrowserControl", []];

        !(isNull _control) && { _screen call ["isReady", []] }
    }],
    ["handleDepositEarningsRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _amount = floor (_data getOrDefault ["amount", 0]);
        [SRPC(bank,requestDepositEarnings), [getPlayerUID player, _amount]] call CFUNC(serverEvent);
        true
    }],
    ["handleDepositRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _amount = floor (_data getOrDefault ["amount", 0]);
        [SRPC(bank,requestDeposit), [getPlayerUID player, _amount]] call CFUNC(serverEvent);
        true
    }],
    ["handleRepayCreditLineRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _amount = floor (_data getOrDefault ["amount", 0]);
        [SRPC(bank,requestRepayCreditLine), [getPlayerUID player, _amount]] call CFUNC(serverEvent);
        true
    }],
    ["handleHydrateResponse", compileFinal {
        params [["_data", createHashMap, [createHashMap]], ["_event", "bank::hydrate", [""]]];

        if !(_self call ["hasOpenScreen", []]) exitWith { false };

        _self call ["sendEvent", [_event, _data, _self call ["getActiveBrowserControl", []]]]
    }],
    ["handleAccountSyncResponse", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        if !(_self call ["hasOpenScreen", []]) exitWith { false };

        _self call ["sendEvent", ["bank::sync", _data, _self call ["getActiveBrowserControl", []]]]
    }],
    ["handleNoticeResponse", compileFinal {
        params [["_type", "error", [""]], ["_message", "", [""]]];

        _self call ["sendNotice", [_type, _message]]
    }],
    ["handleReady", compileFinal {
        params [["_control", controlNull, [controlNull]], ["_data", createHashMap, [createHashMap]]];

        private _screen = _self call ["getScreen", []];
        _screen call ["setControl", [_control]];
        _screen call ["markReady", [true]];
        _self call ["flushPendingEvents", []];

        _self call ["requestHydrate", [true]]
    }],
    ["handleSubmitPinRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _pin = _data getOrDefault ["pin", ""];
        if !(_pin isEqualType "") then { _pin = str _pin; };

        [SRPC(bank,requestSubmitPin), [getPlayerUID player, _pin]] call CFUNC(serverEvent);
        true
    }],
    ["handleTransferRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _amount = floor (_data getOrDefault ["amount", 0]);
        private _target = _data getOrDefault ["target", ""];
        private _from = toLowerANSI (_data getOrDefault ["from", "bank"]);

        [SRPC(bank,requestTransfer), [getPlayerUID player, _target, _from, _amount]] call CFUNC(serverEvent);
        true
    }],
    ["handleWithdrawRequest", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _amount = floor (_data getOrDefault ["amount", 0]);
        [SRPC(bank,requestWithdraw), [getPlayerUID player, _amount]] call CFUNC(serverEvent);
        true
    }],
    ["refreshSession", compileFinal {
        _self call ["requestHydrate", [false]]
    }],
    ["requestHydrate", compileFinal {
        params [["_resetAuthorization", false, [false]]];

        if !(_self call ["hasOpenScreen", []]) exitWith { false };

        [SRPC(bank,requestHydrateBank), [getPlayerUID player, _self call ["getMode", []], _resetAuthorization]] call CFUNC(serverEvent);
        true
    }],
    ["sendNotice", compileFinal {
        params [["_type", "error", [""]], ["_message", "", [""]], ["_control", controlNull, [controlNull]]];

        if (_message isEqualTo "" || { !(_self call ["hasOpenScreen", []]) }) exitWith { false };

        _self call ["sendEvent", ["bank::notice", createHashMapFromArray [
            ["message", _message],
            ["type", _type]
        ], _control]]
    }],
    ["setMode", compileFinal {
        params [["_mode", "bank", [""]]];

        private _finalMode = toLowerANSI _mode;
        if !(_finalMode in ["bank", "atm"]) then { _finalMode = "bank"; };

        _self set ["mode", _finalMode];
        _finalMode
    }]
];

GVAR(BankUIBridge) = createHashMapObject [GVAR(BankUIBridgeBaseClass)];
GVAR(BankUIBridge)
