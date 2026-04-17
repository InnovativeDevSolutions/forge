#include "..\script_component.hpp"

/*
 * File: fnc_initUIBridge.sqf
 * Author: IDSolutions
 * Date: 2026-03-10
 * Last Update: 2026-03-13
 * Public: No
 *
 * Description:
 * Initializes the org UI bridge for browser control state and event routing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Org UI bridge object [HASHMAP OBJECT]
 *
 * Examples:
 * call forge_client_org_fnc_initUIBridge
 */

#pragma hemtt ignore_variables ["_self"]
private _webUIDeclarations = call EFUNC(common,initWebUIBridge);
private _webUIBridgeDeclaration = _webUIDeclarations get "bridgeDeclaration";

GVAR(OrgUIBridgeBaseClass) = compileFinal createHashMapFromArray [
    ["#base", _webUIBridgeDeclaration],
    ["#type", "OrgUIBridgeBaseClass"],
    ["setPendingBrowserControl", compileFinal {
        params [["_control", controlNull, [controlNull]]];

        _self set ["pendingBrowserControl", _control];
        _control
    }],
    ["consumePendingBrowserControl", compileFinal {
        private _control = _self getOrDefault ["pendingBrowserControl", controlNull];
        _self set ["pendingBrowserControl", controlNull];

        _control
    }],
    ["getActiveBrowserControl", compileFinal {
        private _display = uiNamespace getVariable ["RscOrg", displayNull];
        if (isNull _display) exitWith {
            _self call ["setActiveBrowserControl", [controlNull]];
            controlNull
        };

        private _control = _display displayCtrl 1003;
        _self call ["setActiveBrowserControl", [_control]];
        _control
    }],
    ["hasOpenScreen", compileFinal {
        private _screen = _self call ["getScreen", []];
        private _control = _self call ["getActiveBrowserControl", []];

        !(isNull _control) && { _screen call ["isReady", []] }
    }],
    ["requestHydrate", compileFinal {
        params [["_bridgeEvent", "org::sync", [""]]];

        if !(_self call ["hasOpenScreen", []]) exitWith { false };

        private _event = _bridgeEvent;
        if !(_event in ["org::login::success", "org::create::success", "org::sync"]) then {
            _event = "org::sync";
        };

        [SRPC(org,requestHydrateOrg), [getPlayerUID player, _event]] call CFUNC(serverEvent);
        true
    }],
    ["handleHydrateResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]], ["_bridgeEvent", "org::sync", [""]]];

        if !(_self call ["hasOpenScreen", []]) exitWith { false };

        private _event = _bridgeEvent;
        if !(_event in ["org::login::success", "org::create::success", "org::sync"]) then {
            _event = "org::sync";
        };

        _self call ["sendEvent", [_event, _payload, _self call ["getActiveBrowserControl", []]]]
    }],
    ["handleLoginRequest", compileFinal {
        params [["_control", controlNull, [controlNull]]];

        _self call ["setActiveBrowserControl", [_control]];
        _self call ["requestHydrate", ["org::login::success"]];
    }],
    ["handleCreateRequest", compileFinal {
        params [["_control", controlNull, [controlNull]], ["_data", createHashMap, [createHashMap]]];

        private _orgName = _data getOrDefault ["orgName", ""];
        if (_orgName isEqualTo "") exitWith {
            _self call ["sendEvent", ["org::create::failure", createHashMapFromArray [
                ["message", "Enter an organization name."]
            ], _control]];
        };

        _self call ["setPendingBrowserControl", [_control]];
        [SRPC(org,requestCreateOrg), [getPlayerUID player, _orgName]] call CFUNC(serverEvent);
    }],
    ["handleCreateResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _control = _self call ["consumePendingBrowserControl", []];
        private _success = _payload getOrDefault ["success", false];
        if (!_success) exitWith {
            if (isNull _control) exitWith {};

            _self call ["sendEvent", ["org::create::failure", createHashMapFromArray [
                ["message", _payload getOrDefault ["message", "Organization registration failed."]]
            ], _control]];
        };

        if !(isNull _control) then {
            _self call ["setActiveBrowserControl", [_control]];
        };

        _self call ["requestHydrate", ["org::create::success"]];
    }],
    ["handleDisbandResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _eventName = if (_payload getOrDefault ["success", false]) then {
            ["org::portal::revoked", "org::disband::success"] select (_payload getOrDefault ["requester", false])
        } else {
            "org::disband::failure"
        };

        _self call ["sendEvent", [_eventName, _payload]];
    }],
    ["handleLeaveResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _eventName = [
            "org::leave::failure",
            "org::leave::success"
        ] select (_payload getOrDefault ["success", false]);

        _self call ["sendEvent", [_eventName, _payload]];
    }],
    ["handleCreditLineResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _eventName = [
            "org::credit::failure",
            "org::credit::success"
        ] select (_payload getOrDefault ["success", false]);

        _self call ["sendEvent", [_eventName, _payload]];

        if (_payload getOrDefault ["success", false]) then {
            private _memberUid = _payload getOrDefault ["memberUid", ""];
            if (_memberUid isNotEqualTo "") then {
                _self call ["sendEvent", ["org::member::creditUpdated", createHashMapFromArray [
                    ["amount", _payload getOrDefault ["amount", 0]],
                    ["memberName", _payload getOrDefault ["memberName", ""]],
                    ["memberUid", _memberUid]
                ]]];
            };
        };
    }],
    ["handleTreasuryResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _eventName = [
            "org::treasury::failure",
            "org::treasury::success"
        ] select (_payload getOrDefault ["success", false]);

        _self call ["sendEvent", [_eventName, _payload]];
    }],
    ["handleInviteResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _eventName = [
            "org::invite::failure",
            "org::invite::success"
        ] select (_payload getOrDefault ["success", false]);

        _self call ["sendEvent", [_eventName, _payload]];
    }],
    ["handleInviteDecisionResponse", compileFinal {
        params [["_payload", createHashMap, [createHashMap]]];

        private _eventName = [
            "org::invite::decision::failure",
            "org::invite::decision::success"
        ] select (_payload getOrDefault ["success", false]);

        _self call ["sendEvent", [_eventName, _payload]];
    }],
    ["requestDisband", compileFinal {
        [SRPC(org,requestDisbandOrg), [getPlayerUID player]] call CFUNC(serverEvent);
    }],
    ["requestLeave", compileFinal {
        [SRPC(org,requestLeaveOrg), [getPlayerUID player]] call CFUNC(serverEvent);
    }],
    ["requestCreditLine", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _memberUid = _data getOrDefault ["memberUid", ""];
        private _memberName = _data getOrDefault ["memberName", ""];
        private _amount = _data getOrDefault ["amount", 0];

        [SRPC(org,requestAssignCreditLine), [getPlayerUID player, _memberUid, _memberName, _amount]] call CFUNC(serverEvent);
    }],
    ["requestPayroll", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _amount = _data getOrDefault ["amount", 0];
        [SRPC(org,requestPayroll), [getPlayerUID player, _amount]] call CFUNC(serverEvent);
    }],
    ["requestTransferFunds", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _memberUid = _data getOrDefault ["memberUid", ""];
        private _memberName = _data getOrDefault ["memberName", ""];
        private _amount = _data getOrDefault ["amount", 0];
        [SRPC(org,requestTreasuryTransfer), [getPlayerUID player, _memberUid, _memberName, _amount]] call CFUNC(serverEvent);
    }],
    ["requestInvite", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _targetUid = _data getOrDefault ["targetUid", ""];
        private _targetName = _data getOrDefault ["targetName", ""];
        [SRPC(org,requestInviteOrgMember), [getPlayerUID player, _targetUid, _targetName]] call CFUNC(serverEvent);
    }],
    ["requestAcceptInvite", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _orgID = _data getOrDefault ["orgId", ""];
        [SRPC(org,requestAcceptOrgInvite), [getPlayerUID player, _orgID]] call CFUNC(serverEvent);
    }],
    ["requestDeclineInvite", compileFinal {
        params [["_data", createHashMap, [createHashMap]]];

        private _orgID = _data getOrDefault ["orgId", ""];
        [SRPC(org,requestDeclineOrgInvite), [getPlayerUID player, _orgID]] call CFUNC(serverEvent);
    }],
    ["refreshPortal", compileFinal {
        _self call ["requestHydrate", ["org::sync"]]
    }]
];

GVAR(OrgUIBridge) = createHashMapObject [GVAR(OrgUIBridgeBaseClass)];
GVAR(OrgUIBridge)
