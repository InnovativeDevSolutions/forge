#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];

if (isNil QGVAR(PhoneStore)) then { [] call FUNC(initPhoneStore); true };

// Contact Management Events
[QGVAR(requestInitPhone), {
    params [["_uid", "", [""]], ["_data", createHashMap, [createHashMap]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Empty UID provided to requestInitPhone"; };

    GVAR(PhoneStore) call ["init", [_uid]];
}] call CFUNC(addEventHandler);

[QGVAR(requestAddContact), {
    params [["_uid", "", [""]], ["_contactUid", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "" || _contactUid isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Invalid parameters for requestAddContact"; };

    private _result = GVAR(PhoneStore) call ["addContact", [_uid, _contactUid]];

    if (!isNull _player) then { ["forge_client_phone_responseAddContact", [_result], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

[QGVAR(requestAddContactByPhone), {
    params [["_uid", "", [""]], ["_phoneNumber", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "" || _phoneNumber isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Invalid parameters for requestAddContactByPhone"; };

    private _result = GVAR(PhoneStore) call ["addContactByPhone", [_uid, _phoneNumber]];

    if (!isNull _player) then { ["forge_client_phone_responseAddContactByPhone", [_result, _phoneNumber], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

[QGVAR(requestAddContactByEmail), {
    params [["_uid", "", [""]], ["_email", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "" || _email isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Invalid parameters for requestAddContactByEmail"; };

    private _result = GVAR(PhoneStore) call ["addContactByEmail", [_uid, _email]];

    if (!isNull _player) then { ["forge_client_phone_responseAddContactByEmail", [_result, _email], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

[QGVAR(requestRemoveContact), {
    params [["_uid", "", [""]], ["_contactUid", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "" || _contactUid isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Invalid parameters for requestRemoveContact"; };

    private _result = GVAR(PhoneStore) call ["removeContact", [_uid, _contactUid]];

    if (!isNull _player) then { ["forge_client_phone_responseRemoveContact", [_result, _contactUid], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

[QGVAR(requestRefreshContacts), {
    params [["_uid", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Empty UID provided to requestRefreshContacts"; };

    private _contacts = GVAR(PhoneStore) call ["refreshContacts", [_uid]];

    if (!isNull _player) then { ["forge_client_phone_responseRefreshContacts", [_contacts], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

[QGVAR(requestGetContacts), {
    params [["_uid", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Empty UID provided to requestGetContacts"; };

    private _contactUids = GVAR(PhoneStore) call ["getContacts", [_uid]];

    if (!isNull _player) then { ["forge_client_phone_responseGetContacts", [_contactUids], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

// Messaging Events
[QGVAR(requestSendMessage), {
    params [["_fromUid", "", [""]], ["_toUid", "", [""]], ["_message", "", [""]], ["_player", objNull, [objNull]]];

    if (_fromUid isEqualTo "" || _toUid isEqualTo "" || _message isEqualTo "") exitWith {
        diag_log "[FORGE:Server:Phone] Invalid parameters for requestSendMessage";
    };

    private _messageObj = GVAR(PhoneStore) call ["sendMessage", [_fromUid, _toUid, _message]];
    private _success = _messageObj isEqualType createHashMap && { _messageObj isNotEqualTo createHashMap };

    if (!isNull _player) then {
        ["forge_client_phone_responseSendMessage", [_success], _player] call CFUNC(targetEvent);
        if (_success) then {
            ["forge_client_phone_responseMessageSent", [_messageObj], _player] call CFUNC(targetEvent);
        };
    };

    private _recipient = [_toUid] call EFUNC(common,getPlayer);
    if (_success && { _toUid isNotEqualTo _fromUid } && { !isNull _recipient }) then {
        ["forge_client_phone_responseMessageReceived", [_messageObj], _recipient] call CFUNC(targetEvent);
    };
}] call CFUNC(addEventHandler);

[QGVAR(requestGetMessages), {
    params [["_uid", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Empty UID provided to requestGetMessages"; };

    private _messages = GVAR(PhoneStore) call ["getMessages", [_uid]];

    if (!isNull _player) then { ["forge_client_phone_responseGetMessages", [_messages], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

[QGVAR(requestGetMessageThread), {
    params [["_uid", "", [""]], ["_otherUid", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "" || _otherUid isEqualTo "") exitWith {
        diag_log "[FORGE:Server:Phone] Invalid parameters for requestGetMessageThread";
    };

    private _messages = GVAR(PhoneStore) call ["getMessageThread", [_uid, _otherUid]];

    if (!isNull _player) then { ["forge_client_phone_responseGetMessageThread", [_messages, _otherUid], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

[QGVAR(requestMarkMessageRead), {
    params [["_uid", "", [""]], ["_messageId", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "" || _messageId isEqualTo "") exitWith {
        diag_log "[FORGE:Server:Phone] Invalid parameters for requestMarkMessageRead";
    };

    private _result = GVAR(PhoneStore) call ["markMessageRead", [_uid, _messageId]];

    if (!isNull _player) then { ["forge_client_phone_responseMarkMessageRead", [_result, _messageId], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

[QGVAR(requestDeleteMessage), {
    params [["_uid", "", [""]], ["_messageId", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "" || _messageId isEqualTo "") exitWith {
        diag_log "[FORGE:Server:Phone] Invalid parameters for requestDeleteMessage";
    };

    private _result = GVAR(PhoneStore) call ["deleteMessage", [_uid, _messageId]];

    if (!isNull _player) then { ["forge_client_phone_responseDeleteMessage", [_result, _messageId], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

// Email Events
[QGVAR(requestSendEmail), {
    params [["_fromUid", "", [""]], ["_toUid", "", [""]], ["_subject", "", [""]], ["_body", "", [""]], ["_player", objNull, [objNull]]];
    if (_subject isEqualTo "") then { _subject = "No subject"; };

    if (_fromUid isEqualTo "" || _toUid isEqualTo "" || _body isEqualTo "") exitWith {
        diag_log "[FORGE:Server:Phone] Invalid parameters for requestSendEmail";
    };

    private _emailObj = GVAR(PhoneStore) call ["sendEmail", [_fromUid, _toUid, _subject, _body]];
    private _success = _emailObj isEqualType createHashMap && { _emailObj isNotEqualTo createHashMap };

    if (!isNull _player) then {
        ["forge_client_phone_responseSendEmail", [_success], _player] call CFUNC(targetEvent);
        if (_success) then {
            ["forge_client_phone_responseEmailSent", [_emailObj], _player] call CFUNC(targetEvent);
        };
    };

    private _recipient = [_toUid] call EFUNC(common,getPlayer);
    if (_success && { _toUid isNotEqualTo _fromUid } && { !isNull _recipient }) then {
        ["forge_client_phone_responseEmailReceived", [_emailObj], _recipient] call CFUNC(targetEvent);
    };
}] call CFUNC(addEventHandler);

[QGVAR(requestGetEmails), {
    params [["_uid", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Empty UID provided to requestGetEmails"; };

    private _emails = GVAR(PhoneStore) call ["getEmails", [_uid]];

    if (!isNull _player) then { ["forge_client_phone_responseGetEmails", [_emails], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

[QGVAR(requestMarkEmailRead), {
    params [["_uid", "", [""]], ["_emailId", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "" || _emailId isEqualTo "") exitWith {
        diag_log "[FORGE:Server:Phone] Invalid parameters for requestMarkEmailRead";
    };

    private _result = GVAR(PhoneStore) call ["markEmailRead", [_uid, _emailId]];

    if (!isNull _player) then { ["forge_client_phone_responseMarkEmailRead", [_result, _emailId], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

[QGVAR(requestDeleteEmail), {
    params [["_uid", "", [""]], ["_emailId", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "" || _emailId isEqualTo "") exitWith {
        diag_log "[FORGE:Server:Phone] Invalid parameters for requestDeleteEmail";
    };

    private _result = GVAR(PhoneStore) call ["deleteEmail", [_uid, _emailId]];

    if (!isNull _player) then { ["forge_client_phone_responseDeleteEmail", [_result, _emailId], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);

// Cleanup Event
[QGVAR(requestRemovePhone), {
    params [["_uid", "", [""]], ["_player", objNull, [objNull]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Phone] Empty UID provided to requestRemovePhone"; };

    private _result = GVAR(PhoneStore) call ["remove", [_uid]];

    if (!isNull _player) then { ["forge_client_phone_responseRemovePhone", [_result], _player] call CFUNC(targetEvent); };
}] call CFUNC(addEventHandler);
