#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initialize message store for phone SMS management.
 *
 * Message state is owned by the extension phone hot-state service.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(MessageStore) = createHashMapObject [[
    ["#type", "IMessageStore"],
    ["#create", {
        diag_log "[FORGE:Server:Phone] Message Store Initialized!";
    }],
    ["callPhoneArray", {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if (!_isSuccess || { !(_result isEqualType "") }) exitWith { [] };
        if ((_result find "Error:") == 0) exitWith {
            diag_log format ["[FORGE:Server:Phone:Message] Extension call %1 failed: %2", _function, _result];
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
            diag_log format ["[FORGE:Server:Phone:Message] Extension call %1 failed: %2", _function, _result];
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
            diag_log format ["[FORGE:Server:Phone:Message] Extension call %1 failed: %2", _function, _result];
            false
        };

        _result isEqualTo "true"
    }],
    ["init", {
        params [["_uid", "", [""]]];
        if (_uid isEqualTo "") exitWith { false };
        true
    }],
    ["loadMessagesFromDatabase", {
        params [["_uid", "", [""]]];
        if (_uid isEqualTo "") exitWith { false };
        true
    }],
    ["sendMessage", {
        params [["_fromUid", "", [""]], ["_toUid", "", [""]], ["_message", "", [""]]];

        if (_fromUid isEqualTo "" || { _toUid isEqualTo "" } || { _message isEqualTo "" }) exitWith {
            diag_log "[FORGE:Server:Phone:Message] Invalid parameters provided to sendMessage";
            false
        };

        _self call ["callPhoneObject", ["phone:messages:send", [_fromUid, _toUid, _message, str serverTime]]]
    }],
    ["getMessageThread", {
        params [["_uid", "", [""]], ["_otherUid", "", [""]]];
        if (_uid isEqualTo "" || { _otherUid isEqualTo "" }) exitWith { [] };
        _self call ["callPhoneArray", ["phone:messages:thread", [_uid, _otherUid]]]
    }],
    ["markMessageRead", {
        params [["_uid", "", [""]], ["_messageId", "", [""]]];
        if (_uid isEqualTo "" || { _messageId isEqualTo "" }) exitWith { false };
        _self call ["callPhoneBool", ["phone:messages:mark_read", [_uid, _messageId]]]
    }],
    ["deleteMessage", {
        params [["_uid", "", [""]], ["_messageId", "", [""]]];
        if (_uid isEqualTo "" || { _messageId isEqualTo "" }) exitWith { false };
        _self call ["callPhoneBool", ["phone:messages:delete", [_uid, _messageId]]]
    }],
    ["getMessages", {
        params [["_uid", "", [""]]];
        if (_uid isEqualTo "") exitWith { [] };
        _self call ["callPhoneArray", ["phone:messages:list", [_uid]]]
    }],
    ["remove", {
        params [["_uid", "", [""]]];
        if (_uid isEqualTo "") exitWith { false };

        ["phone:remove", [_uid]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        _isSuccess && { _result isEqualTo "OK" }
    }],
    ["syncMessageIndices", {
        params [["_uid", "", [""]]];
        _uid isNotEqualTo ""
    }]
]];

SETMVAR(FORGE_MessageStore,GVAR(MessageStore));
GVAR(MessageStore)
