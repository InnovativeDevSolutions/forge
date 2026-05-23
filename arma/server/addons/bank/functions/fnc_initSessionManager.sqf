#include "..\script_component.hpp"

/*
 * File: fnc_initSessionManager.sqf
 * Author: IDSolutions
 * Date: 2026-03-16
 * Last Update: 2026-04-02
 * Public: No
 *
 * Description:
 *     Initializes the bank session manager for managing ATM/bank
 *     session state, mode resolution, and PIN authorization.
 *
 * Parameter(s):
 *     None
 *
 * Returns:
 *     Session manager object [HASHMAP OBJECT]
 *
 * Example(s):
 *     call forge_server_bank_fnc_initSessionManager
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(BankSessionManager) = createHashMapObject [[
    ["#type", "BankSessionManager"],
    ["#create", compileFinal {
        _self set ["sessions", createHashMap];
    }],
    ["getSessionState", compileFinal {
        params [["_uid", "", [""]]];

        private _sessions = _self getOrDefault ["sessions", createHashMap];
        private _session = _sessions getOrDefault [_uid, createHashMap];
        if (_session isEqualTo createHashMap) then {
            _session = createHashMapFromArray [
                ["atmAuthorized", false],
                ["mode", "bank"]
            ];
            _sessions set [_uid, _session];
        };

        _session
    }],
    ["setSessionState", compileFinal {
        params [["_uid", "", [""]], ["_fieldValuePairs", createHashMap, [createHashMap]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _session = +(_self call ["getSessionState", [_uid]]);
        private _sessions = _self getOrDefault ["sessions", createHashMap];
        { _session set [_x, _y]; } forEach _fieldValuePairs;

        _sessions set [_uid, _session];
        _session
    }],
    ["resolveMode", compileFinal {
        params [["_mode", "bank", [""]]];

        private _finalMode = toLowerANSI _mode;
        if !(_finalMode in ["atm", "bank"]) then { _finalMode = "bank"; };

        _finalMode
    }],
    ["syncSessionMode", compileFinal {
        params [["_uid", "", [""]], ["_mode", "", [""]], ["_resetAuthorization", false, [false]]];

        private _current = _self call ["getSessionState", [_uid]];
        private _finalMode = if (_mode isEqualTo "") then {
            _current getOrDefault ["mode", "bank"]
        } else {
            _self call ["resolveMode", [_mode]]
        };
        private _atmAuthorized = _current getOrDefault ["atmAuthorized", false];

        if (_finalMode isEqualTo "atm") then {
            if (_resetAuthorization || { (_current getOrDefault ["mode", "bank"]) isNotEqualTo "atm" }) then {
                _atmAuthorized = false;
            };
        } else {
            _atmAuthorized = false;
        };

        _self call ["setSessionState", [_uid, createHashMapFromArray [
            ["atmAuthorized", _atmAuthorized],
            ["mode", _finalMode]
        ]]]
    }],
    ["submitPin", compileFinal {
        params [["_uid", "", [""]], ["_pin", "", [""]]];

        if (_uid isEqualTo "") exitWith { false };

        _self call ["setSessionState", [_uid, createHashMapFromArray [["atmAuthorized", false], ["mode", "atm"]]]];
        if !(GVAR(BankStore) call ["validatePin", [_uid, _pin]]) exitWith {
            GVAR(BankStore) call ["hydrateSession", [_uid, "atm", false]];
            false
        };

        _self call ["setSessionState", [_uid, createHashMapFromArray [["atmAuthorized", true], ["mode", "atm"]]]];
        GVAR(BankMessenger) call ["sendNotification", [_uid, "info", "Bank", "ATM access granted."]];
        GVAR(BankStore) call ["hydrateSession", [_uid, "atm", false]];
        true
    }]
]];

GVAR(BankSessionManager)
