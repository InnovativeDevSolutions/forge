#include "script_component.hpp"

[{
    GETVAR(player,FORGE_isLoaded,false)
}, {
    [QGVAR(initPhone), []] call CFUNC(localEvent);
}] call CFUNC(waitUntilAndExecute);

if (isNil QGVAR(PhoneRepository)) then { [] call FUNC(initRepository); };

[QGVAR(initPhone), {
    GVAR(PhoneRepository) call ["init", []];

    ["forge_server_phone_requestInitPhone", [getPlayerUID player, createHashMap]] call CFUNC(serverEvent);
    ["forge_server_phone_requestRefreshContacts", [getPlayerUID player, player]] call CFUNC(serverEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseSyncPhone), {
    params [["_data", createHashMap, [createHashMap]]];

    GVAR(PhoneRepository) call ["sync", [_data]];
}] call CFUNC(addEventHandler);

// Contact Management Response Events
[QGVAR(responseAddContact), {
    params [["_success", false, [false]]];

    if (_success) then {
        EGVAR(notifications,NotificationService) call ["create", ["success", "Contact Added", "Contact added successfully", 3000]];
        [QGVAR(refreshUI), []] call CFUNC(localEvent);
    } else {
        EGVAR(notifications,NotificationService) call ["create", ["danger", "Contact Error", "Failed to add contact", 4000]];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseAddContactByPhone), {
    params [["_success", false, [false]], ["_phoneNumber", "", [""]]];

    if (_success) then {
        EGVAR(notifications,NotificationService) call ["create", ["success", "Contact Added", format ["Contact with phone %1 added successfully", _phoneNumber], 3000]];
        [QGVAR(refreshUI), []] call CFUNC(localEvent);
    } else {
        EGVAR(notifications,NotificationService) call ["create", ["warning", "Contact Not Found", format ["Player with phone %1 not found", _phoneNumber], 4000]];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseAddContactByEmail), {
    params [["_success", false, [false]], ["_email", "", [""]]];

    if (_success) then {
        EGVAR(notifications,NotificationService) call ["create", ["success", "Contact Added", format ["Contact with email %1 added successfully", _email], 3000]];
        [QGVAR(refreshUI), []] call CFUNC(localEvent);
    } else {
        EGVAR(notifications,NotificationService) call ["create", ["warning", "Contact Not Found", format ["Player with email %1 not found", _email], 4000]];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseRemoveContact), {
    params [["_success", false, [false]], ["_contactUid", "", [""]]];

    if (_success) then {
        EGVAR(notifications,NotificationService) call ["create", ["success", "Contact Removed", "Contact removed successfully", 3000]];
        [QGVAR(refreshUI), []] call CFUNC(localEvent);
    } else {
        EGVAR(notifications,NotificationService) call ["create", ["danger", "Contact Error", "Failed to remove contact", 4000]];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseRefreshContacts), {
    params [["_contacts", [], [[]]]];

    diag_log format ["[FORGE:Client:Phone] Contacts refreshed: %1 contacts", count _contacts];

    [QGVAR(updateContacts), [_contacts]] call CFUNC(localEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseGetContacts), {
    params [["_contactUids", [], [[]]]];

    diag_log format ["[FORGE:Client:Phone] Got contact UIDs: %1", _contactUids];
}] call CFUNC(addEventHandler);

// Messaging Response Events
[QGVAR(responseMessageSent), {
    params [["_messageObj", createHashMap, [createHashMap]]];

    diag_log format ["[FORGE:Client:Phone] Message sent: %1", _messageObj];

    [QGVAR(updateMessageSent), [_messageObj]] call CFUNC(localEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseMessageReceived), {
    params [["_messageObj", createHashMap, [createHashMap]]];

    private _fromUid = _messageObj get "from";
    private _message = _messageObj get "message";
    private _contacts = player getVariable ["FORGE_Contacts", []];
    private _senderName = "Unknown";

    {
        if ((_x get "uid") isEqualTo _fromUid) exitWith {
            _senderName = _x get "name";
        };
    } forEach _contacts;

    EGVAR(notifications,NotificationService) call ["create", ["info", "New Message", format ["From %1", _senderName], 4000]];

    diag_log format ["[FORGE:Client:Phone] Message received from %1: %2", _fromUid, _message];

    [QGVAR(updateMessageReceived), [_messageObj]] call CFUNC(localEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseSendMessage), {
    params [["_success", false, [false]]];

    if (_success) then {
        EGVAR(notifications,NotificationService) call ["create", ["success", "Message Sent", "Message sent successfully", 2000]];
    } else {
        EGVAR(notifications,NotificationService) call ["create", ["danger", "Message Failed", "Failed to send message", 4000]];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseGetMessages), {
    params [["_messages", [], [[]]]];

    diag_log format ["[FORGE:Client:Phone] Got %1 messages", count _messages];

    [QGVAR(updateMessages), [_messages]] call CFUNC(localEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseGetMessageThread), {
    params [["_messages", [], [[]]], ["_otherUid", "", [""]]];

    diag_log format ["[FORGE:Client:Phone] Got message thread with %1: %2 messages", _otherUid, count _messages];

    [QGVAR(updateMessageThread), [_messages, _otherUid]] call CFUNC(localEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseMarkMessageRead), {
    params [["_success", false, [false]], ["_messageId", "", [""]]];

    if (_success) then { diag_log format ["[FORGE:Client:Phone] Message %1 marked as read", _messageId]; };
}] call CFUNC(addEventHandler);

[QGVAR(responseMessageRead), {
    params [["_messageId", "", [""]]];

    diag_log format ["[FORGE:Client:Phone] Message %1 marked as read", _messageId];

    [QGVAR(updateMessageRead), [_messageId]] call CFUNC(localEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseDeleteMessage), {
    params [["_success", false, [false]], ["_messageId", "", [""]]];

    if (_success) then {
        diag_log format ["[FORGE:Client:Phone] Message %1 deleted", _messageId];
        [QGVAR(updateMessageDeleted), [_messageId]] call CFUNC(localEvent);
    } else {
        EGVAR(notifications,NotificationService) call ["create", ["danger", "Message Delete Failed", "Failed to delete message", 4000]];
    };
}] call CFUNC(addEventHandler);

// Email Response Events
[QGVAR(responseEmailSent), {
    params [["_emailObj", createHashMap, [createHashMap]]];

    diag_log format ["[FORGE:Client:Phone] Email sent: %1", _emailObj];

    [QGVAR(updateEmailSent), [_emailObj]] call CFUNC(localEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseEmailReceived), {
    params [["_emailObj", createHashMap, [createHashMap]]];

    private _fromUid = _emailObj get "from";
    private _subject = _emailObj get "subject";
    private _contacts = player getVariable ["FORGE_Contacts", []];
    private _senderName = "Unknown";

    {
        if ((_x get "uid") isEqualTo _fromUid) exitWith {
            _senderName = _x get "name";
        };
    } forEach _contacts;

    EGVAR(notifications,NotificationService) call ["create", ["info", "New Email", format ["From %1: %2", _senderName, _subject], 4000]];

    diag_log format ["[FORGE:Client:Phone] Email received from %1: %2", _fromUid, _subject];

    [QGVAR(updateEmailReceived), [_emailObj]] call CFUNC(localEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseSendEmail), {
    params [["_success", false, [false]]];

    if (_success) then {
        EGVAR(notifications,NotificationService) call ["create", ["success", "Email Sent", "Email sent successfully", 2000]];
    } else {
        EGVAR(notifications,NotificationService) call ["create", ["danger", "Email Failed", "Failed to send email", 4000]];
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseGetEmails), {
    params [["_emails", [], [[]]]];

    diag_log format ["[FORGE:Client:Phone] Got %1 emails", count _emails];

    [QGVAR(updateEmails), [_emails]] call CFUNC(localEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseMarkEmailRead), {
    params [["_success", false, [false]], ["_emailId", "", [""]]];

    if (_success) then {
        diag_log format ["[FORGE:Client:Phone] Email %1 marked as read", _emailId];
        [QGVAR(updateEmailRead), [_emailId]] call CFUNC(localEvent);
    };
}] call CFUNC(addEventHandler);

[QGVAR(responseEmailRead), {
    params [["_emailId", "", [""]]];

    diag_log format ["[FORGE:Client:Phone] Email %1 marked as read", _emailId];

    [QGVAR(updateEmailRead), [_emailId]] call CFUNC(localEvent);
}] call CFUNC(addEventHandler);

[QGVAR(responseDeleteEmail), {
    params [["_success", false, [false]], ["_emailId", "", [""]]];

    if (_success) then {
        diag_log format ["[FORGE:Client:Phone] Email %1 deleted", _emailId];
        [QGVAR(updateEmailDeleted), [_emailId]] call CFUNC(localEvent);
    } else {
        EGVAR(notifications,NotificationService) call ["create", ["danger", "Email Delete Failed", "Failed to delete email", 4000]];
    };
}] call CFUNC(addEventHandler);

// Cleanup Response Events
[QGVAR(responseRemovePhone), {
    params [["_success", false, [false]]];

    if (_success) then { diag_log "[FORGE:Client:Phone] Phone data removed successfully"; };
}] call CFUNC(addEventHandler);

// UI Update Events (for internal use)
[QGVAR(refreshUI), {
    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", "refreshContacts()"]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateContacts), {
    params [["_contacts", [], [[]]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateContacts(%1)", (toJSON _contacts)]]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateMessageSent), {
    params [["_messageObj", createHashMap, [createHashMap]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateMessageSent(%1)", (toJSON _messageObj)]]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateMessageReceived), {
    params [["_messageObj", createHashMap, [createHashMap]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateMessageReceived(%1)", (toJSON _messageObj)]]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateMessages), {
    params [["_messages", [], [[]]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateMessages(%1)", (toJSON _messages)]]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateMessageThread), {
    params [["_messages", [], [[]]], ["_otherUid", "", [""]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateMessageThread(%1, %2)", (toJSON _messages), (toJSON _otherUid)]]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateMessageDeleted), {
    params [["_messageId", "", [""]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateMessageDeleted(%1)", (toJSON _messageId)]]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateEmailSent), {
    params [["_emailObj", createHashMap, [createHashMap]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateEmailSent(%1)", (toJSON _emailObj)]]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateEmailReceived), {
    params [["_emailObj", createHashMap, [createHashMap]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateEmailReceived(%1)", (toJSON _emailObj)]]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateEmails), {
    params [["_emails", [], [[]]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateEmails(%1)", (toJSON _emails)]]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateEmailRead), {
    params [["_emailId", "", [""]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateEmailRead(%1)", (toJSON _emailId)]]; };
}] call CFUNC(addEventHandler);

[QGVAR(updateEmailDeleted), {
    params [["_emailId", "", [""]]];

    private _control = (uiNamespace getVariable ["RscPhone", displayNull]) displayCtrl 1001;

    if (!isNull _control) then { _control ctrlWebBrowserAction ["ExecJS", format ["updateEmailDeleted(%1)", (toJSON _emailId)]]; };
}] call CFUNC(addEventHandler);
