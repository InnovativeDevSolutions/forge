#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initialize phone store for communication management
 *
 * Arguments:
 * N/A
 *
 * Return Value:
 * Phone Store Object
 *
 * Examples:
 * [] call forge_server_phone_fnc_initPhoneStore
 *
 * Public: No
 *
 * ARCHITECTURAL REFACTOR COMPLETE:
 * This PhoneStore now acts as a facade pattern coordinating between:
 * - MessageStore (for SMS/messaging functionality)
 * - EmailStore (for email functionality)
 * - ContactStore (for contact management)
 *
 * Phone runtime state is owned by the extension. SQF stores are bridge objects
 * that preserve the legacy event-facing API.
 */

// Initialize the sub-stores
if (isNil QGVAR(MessageStore)) then { [] call FUNC(initMessageStore); };
if (isNil QGVAR(EmailStore)) then { [] call FUNC(initEmailStore); };
if (isNil QGVAR(ContactStore)) then { [] call FUNC(initContactStore); };

#pragma hemtt ignore_variables ["_self"]
GVAR(PhoneStore) = createHashMapObject [[
    ["#type", "IPhoneStore"],
    ["#create", {
        // Sub-stores are already initialized above
        diag_log "[FORGE:Server:Phone] Phone Store Initialized with sub-stores!";
    }],
    ["callPhonePayload", {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if (!_isSuccess || { !(_result isEqualType "") }) exitWith { createHashMap };
        if ((_result find "Error:") == 0) exitWith {
            diag_log format ["[FORGE:Server:Phone] Extension call %1 failed: %2", _function, _result];
            createHashMap
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith { createHashMap };
        _data
    }],
    ["init", {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Empty UID provided to init"; createHashMap };

        private _payload = _self call ["callPhonePayload", ["phone:init", [_uid]]];
        if (_payload isEqualTo createHashMap) exitWith {
            diag_log format ["[FORGE:Server:Phone] Phone extension init failed for %1", _uid];
            false
        };

        // Initialize all sub-stores for this user
        GVAR(ContactStore) call ["init", [_uid]];
        GVAR(MessageStore) call ["init", [_uid]];
        GVAR(EmailStore) call ["init", [_uid]];

        diag_log format ["[FORGE:Server:Phone] Phone initialized for %1", _uid];
        true
    }],
    ["addContact", {
        params [["_uid", "", [""]], ["_contactUid", "", [""]]];
        GVAR(ContactStore) call ["addContact", [_uid, _contactUid]]
    }],
    ["removeContact", {
        params [["_uid", "", [""]], ["_contactUid", "", [""]]];
        GVAR(ContactStore) call ["removeContact", [_uid, _contactUid]]
    }],
    ["addContactByPhone", {
        params [["_uid", "", [""]], ["_phoneNumber", "", [""]]];
        GVAR(ContactStore) call ["addContactByPhone", [_uid, _phoneNumber]]
    }],
    ["addContactByEmail", {
        params [["_uid", "", [""]], ["_email", "", [""]]];
        GVAR(ContactStore) call ["addContactByEmail", [_uid, _email]]
    }],
    ["getContacts", {
        params [["_uid", "", [""]]];
        GVAR(ContactStore) call ["getContacts", [_uid]]
    }],
    ["refreshContacts", {
        params [["_uid", "", [""]]];
        GVAR(ContactStore) call ["refreshContacts", [_uid]]
    }],
    ["loadMessagesFromDatabase", {
        params [["_uid", "", [""]]];
        GVAR(MessageStore) call ["loadMessagesFromDatabase", [_uid]]
    }],
    ["sendMessage", {
        params [["_fromUid", "", [""]], ["_toUid", "", [""]], ["_message", "", [""]]];
        GVAR(MessageStore) call ["sendMessage", [_fromUid, _toUid, _message]]
    }],
    ["getMessageThread", {
        params [["_uid", "", [""]], ["_otherUid", "", [""]]];
        GVAR(MessageStore) call ["getMessageThread", [_uid, _otherUid]]
    }],
    ["getMessages", {
        params [["_uid", "", [""]]];
        GVAR(MessageStore) call ["getMessages", [_uid]]
    }],
    ["markMessageRead", {
        params [["_uid", "", [""]], ["_messageId", "", [""]]];
        GVAR(MessageStore) call ["markMessageRead", [_uid, _messageId]]
    }],
    ["deleteMessage", {
        params [["_uid", "", [""]], ["_messageId", "", [""]]];
        GVAR(MessageStore) call ["deleteMessage", [_uid, _messageId]]
    }],
    ["syncMessageIndices", {
        params [["_uid", "", [""]]];
        GVAR(MessageStore) call ["syncMessageIndices", [_uid]]
    }],
    ["sendEmail", {
        params [["_fromUid", "", [""]], ["_toUid", "", [""]], ["_subject", "", [""]], ["_body", "", [""]]];
        GVAR(EmailStore) call ["sendEmail", [_fromUid, _toUid, _subject, _body]]
    }],
    ["getEmails", {
        params [["_uid", "", [""]]];
        GVAR(EmailStore) call ["getEmails", [_uid]]
    }],
    ["markEmailRead", {
        params [["_uid", "", [""]], ["_emailId", "", [""]]];
        GVAR(EmailStore) call ["markEmailRead", [_uid, _emailId]]
    }],
    ["deleteEmail", {
        params [["_uid", "", [""]], ["_emailId", "", [""]]];
        GVAR(EmailStore) call ["deleteEmail", [_uid, _emailId]]
    }],
    ["remove", {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith {
            diag_log "[FORGE:Server:Phone] Empty UID provided to remove";
            false
        };

        // Remove from all sub-stores
        GVAR(ContactStore) call ["remove", [_uid]];
        GVAR(MessageStore) call ["remove", [_uid]];
        GVAR(EmailStore) call ["remove", [_uid]];

        diag_log format ["[FORGE:Server:Phone] Removed phone data for %1", _uid];
        true
    }],
    ["toArray", {
        params [["_data", createHashMap, [createHashMap]]];

        private _keys = keys _data;
        private _array = [];

        {
            private _key = _x;
            private _value = _data get _key;
            _array pushBack _key;
            _array pushBack _value;
        } forEach _keys;

        _array
    }],
    ["toHashMap", {
        params [["_data", [], [[]]]];

        private _keyValuePairs = [];
        _data = _data select 0;

        for "_i" from 0 to (count _data - 2) step 2 do {
            private _key = _data select _i;
            private _value = _data select (_i + 1);
            _keyValuePairs pushBack [_key, _value];
        };

        private _hashMap = createHashMapFromArray _keyValuePairs;
        _hashMap
    }]
]];

SETMVAR(FORGE_PhoneStore,GVAR(PhoneStore));
GVAR(PhoneStore)
