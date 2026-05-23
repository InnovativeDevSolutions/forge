#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initialize email store for phone email management.
 *
 * Email state is owned by the extension phone hot-state service.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(EmailStore) = createHashMapObject [[
    ["#type", "IEmailStore"],
    ["#create", {
        diag_log "[FORGE:Server:Phone] Email Store Initialized!";
    }],
    ["callPhoneArray", {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if (!_isSuccess || { !(_result isEqualType "") }) exitWith { [] };
        if ((_result find "Error:") == 0) exitWith {
            diag_log format ["[FORGE:Server:Phone:Email] Extension call %1 failed: %2", _function, _result];
            []
        };

        private _data = fromJSON _result;
        if !(_data isEqualType []) exitWith { [] };
        _data
    }],
    ["callPhoneObject", {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if (!_isSuccess || { !(_result isEqualType "") }) exitWith { createHashMap };
        if ((_result find "Error:") == 0) exitWith {
            diag_log format ["[FORGE:Server:Phone:Email] Extension call %1 failed: %2", _function, _result];
            createHashMap
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith { createHashMap };
        _data
    }],
    ["callPhoneBool", {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if (!_isSuccess || { !(_result isEqualType "") }) exitWith { false };
        if ((_result find "Error:") == 0) exitWith {
            diag_log format ["[FORGE:Server:Phone:Email] Extension call %1 failed: %2", _function, _result];
            false
        };

        _result isEqualTo "true"
    }],
    ["init", {
        params [["_uid", "", [""]]];
        if (_uid isEqualTo "") exitWith { false };
        true
    }],
    ["loadEmailsFromDatabase", {
        params [["_uid", "", [""]]];
        if (_uid isEqualTo "") exitWith { false };
        true
    }],
    ["sendEmail", {
        params [["_fromUid", "", [""]], ["_toUid", "", [""]], ["_subject", "", [""]], ["_body", "", [""]]];
        if (_subject isEqualTo "") then { _subject = "No subject"; };

        if (_fromUid isEqualTo "" || { _toUid isEqualTo "" } || { _body isEqualTo "" }) exitWith {
            diag_log "[FORGE:Server:Phone:Email] Invalid parameters provided to sendEmail";
            false
        };

        _self call ["callPhoneObject", ["phone:emails:send", [_fromUid, _toUid, _subject, _body, str serverTime]]]
    }],
    ["getEmails", {
        params [["_uid", "", [""]]];
        if (_uid isEqualTo "") exitWith { [] };
        _self call ["callPhoneArray", ["phone:emails:list", [_uid]]]
    }],
    ["markEmailRead", {
        params [["_uid", "", [""]], ["_emailId", "", [""]]];
        if (_uid isEqualTo "" || { _emailId isEqualTo "" }) exitWith { false };
        _self call ["callPhoneBool", ["phone:emails:mark_read", [_uid, _emailId]]]
    }],
    ["deleteEmail", {
        params [["_uid", "", [""]], ["_emailId", "", [""]]];
        if (_uid isEqualTo "" || { _emailId isEqualTo "" }) exitWith { false };
        _self call ["callPhoneBool", ["phone:emails:delete", [_uid, _emailId]]]
    }],
    ["remove", {
        params [["_uid", "", [""]]];
        if (_uid isEqualTo "") exitWith { false };

        ["phone:remove", [_uid]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        _isSuccess && { _result isEqualTo "OK" }
    }]
]];

SETMVAR(FORGE_EmailStore,GVAR(EmailStore));
GVAR(EmailStore)
