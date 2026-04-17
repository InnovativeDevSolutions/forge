#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Handles UI events.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call forge_client_phone_fnc_handleUIEvents;
 *
 * Public: No
 */

params ["_control", "_isConfirmDialog", "_message"];

private _alert = fromJSON _message;
private _event = _alert get "event";
private _data = _alert get "data";

// diag_log format ["[FORGE:Client:Phone] Handling UI event: %1 with data: %2", _event, _data];

switch (_event) do {
    case "phone::get::player": {
        private _uid = getPlayerUID player;
        _control ctrlWebBrowserAction ["ExecJS", format ["setPlayerUid(%1)", (toJSON _uid)]];
    };
    case "phone::get::theme": {
        private _isDark = profileNamespace getVariable ["FORGE_Phone_isDark", true];
        private _theme = ["light", "dark"] select (_isDark);

        _control ctrlWebBrowserAction ["ExecJS", format ["setTheme(%1)", (toJSON _theme)]];
    };
    case "phone::get::contacts": {
        private _contacts = player getVariable ["FORGE_Contacts", []];

        _control ctrlWebBrowserAction ["ExecJS", format ["loadContacts(%1)", (toJSON _contacts)]];
        ["forge_server_phone_requestRefreshContacts", [getPlayerUID player, player]] call CFUNC(serverEvent);
    };
    case "phone::set::theme": {
        private _isDark = _data get "isDark";

        profileNamespace setVariable ["FORGE_Phone_isDark", _isDark];
    };
    case "phone::add::contact": {
        private _contactPhone = _data get "phone";

        if (_contactPhone isNotEqualTo "") then {
            ["forge_server_phone_requestAddContactByPhone", [getPlayerUID player, _contactPhone, player]] call CFUNC(serverEvent);
        } else {
            diag_log "[FORGE:Client:Phone] No phone number provided for contact addition";
        };
    };
    case "phone::add::contact::by::phone": {
        private _phoneNumber = _data get "phone";

        if (_phoneNumber isNotEqualTo "") then {
            ["forge_server_phone_requestAddContactByPhone", [getPlayerUID player, _phoneNumber, player]] call CFUNC(serverEvent);
        } else {
            diag_log "[FORGE:Client:Phone] No phone number provided";
        };
    };
    case "phone::add::contact::by::email": {
        private _email = _data get "email";

        if (_email isNotEqualTo "") then {
            ["forge_server_phone_requestAddContactByEmail", [getPlayerUID player, _email, player]] call CFUNC(serverEvent);
        } else {
            diag_log "[FORGE:Client:Phone] No email provided";
        };
    };
    case "phone::remove::contact": {
        private _contactUid = _data get "uid";

        if (_contactUid isNotEqualTo "") then {
            ["forge_server_phone_requestRemoveContact", [getPlayerUID player, _contactUid, player]] call CFUNC(serverEvent);
        } else {
            diag_log "[FORGE:Client:Phone] No contact UID provided for removal";
        };
    };
    case "phone::refresh::contacts": {
        ["forge_server_phone_requestRefreshContacts", [getPlayerUID player, player]] call CFUNC(serverEvent);
    };
    case "phone::send::message": {
        private _contactName = _data get "contactName";
        private _messageData = _data get "message";
        private _messageText = _messageData get "text";
        private _toUid = _data get "toUid";

        if (_toUid isNotEqualTo "") then {
            ["forge_server_phone_requestSendMessage", [getPlayerUID player, _toUid, _messageText, player]] call CFUNC(serverEvent);
        } else {
            diag_log format ["[FORGE:Client:Phone] No recipient UID provided for message to %1", _contactName];
        };
    };
    case "phone::get::messages": {
        ["forge_server_phone_requestGetMessages", [getPlayerUID player, player]] call CFUNC(serverEvent);
    };
    case "phone::get::message::thread": {
        private _otherUid = _data get "otherUid";

        if (_otherUid isNotEqualTo "") then {
            ["forge_server_phone_requestGetMessageThread", [getPlayerUID player, _otherUid, player]] call CFUNC(serverEvent);
        } else {
            diag_log "[FORGE:Client:Phone] No other UID provided for message thread";
        };
    };
    case "phone::mark::message::read": {
        private _messageId = _data get "messageId";

        if (_messageId isNotEqualTo "") then {
            ["forge_server_phone_requestMarkMessageRead", [getPlayerUID player, _messageId, player]] call CFUNC(serverEvent);
        } else {
            diag_log "[FORGE:Client:Phone] No message ID provided for mark read";
        };
    };
    case "phone::delete::message": {
        private _messageId = _data get "messageId";

        if (_messageId isNotEqualTo "") then {
            ["forge_server_phone_requestDeleteMessage", [getPlayerUID player, _messageId, player]] call CFUNC(serverEvent);
        } else {
            diag_log "[FORGE:Client:Phone] No message ID provided for delete";
        };
    };
    case "phone::send::email": {
        private _toUid = _data get "toUid";
        private _subject = _data get "subject";
        private _body = _data get "body";
        if (_subject isEqualTo "") then { _subject = "No subject"; };

        if (_toUid isNotEqualTo "" && _body isNotEqualTo "") then {
            diag_log format ["[FORGE:Client:Phone] Sending email to %1 subject length %2 body length %3", _toUid, count _subject, count _body];
            ["forge_server_phone_requestSendEmail", [getPlayerUID player, _toUid, _subject, _body, player]] call CFUNC(serverEvent);
        } else {
            diag_log "[FORGE:Client:Phone] Missing required email parameters";
        };
    };
    case "phone::get::emails": {
        ["forge_server_phone_requestGetEmails", [getPlayerUID player, player]] call CFUNC(serverEvent);
    };
    case "phone::mark::email::read": {
        private _emailId = _data get "emailId";

        if (_emailId isNotEqualTo "") then {
            ["forge_server_phone_requestMarkEmailRead", [getPlayerUID player, _emailId, player]] call CFUNC(serverEvent);
        } else {
            diag_log "[FORGE:Client:Phone] No email ID provided for mark read";
        };
    };
    case "phone::delete::email": {
        private _emailId = _data get "emailId";

        if (_emailId isNotEqualTo "") then {
            ["forge_server_phone_requestDeleteEmail", [getPlayerUID player, _emailId, player]] call CFUNC(serverEvent);
        } else {
            diag_log "[FORGE:Client:Phone] No email ID provided for delete";
        };
    };
    case "phone::get::notes": {
        private _notes = GVAR(PhoneRepository) call ["getAllNotes", []];

        _control ctrlWebBrowserAction ["ExecJS", format ["loadNotes(%1)", (toJSON _notes)]];
    };
    case "phone::save::note": {
        private _success = GVAR(PhoneRepository) call ["addNote", [_data]];
        _success
    };
    case "phone::delete::note": {
        private _noteId = _data get "id";

        private _success = GVAR(PhoneRepository) call ["deleteNote", [_noteId]];
        _success
    };
    case "phone::get::events": {
        private _events = profileNamespace getVariable ["FORGE_Phone_Events", []];

        _control ctrlWebBrowserAction ["ExecJS", format ["loadCalendarEvents(%1)", (toJSON _events)]];
    };
    case "phone::save::event": {
        private _eventId = _data get "id";
        private _eventTitle = _data get "title";

        private _events = profileNamespace getVariable ["FORGE_Phone_Events", []];
        private _existingIndex = -1;
        {
            private _existingId = _x get "id";
            if (_existingId isEqualTo _eventId) then {
                _existingIndex = _forEachIndex;
            };
        } forEach _events;

        if (_existingIndex >= 0) then {
            _events set [_existingIndex, _data];
            diag_log format ["[PHONE] Updated event: %1 [ID: %2]", _eventTitle, _eventId];
        } else {
            _events pushBack _data;
            diag_log format ["[PHONE] Added new event: %1 [ID: %2]", _eventTitle, _eventId];
        };

        profileNamespace setVariable ["FORGE_Phone_Events", _events];
        diag_log format ["[PHONE] Saved events to profile. Total events: %1", count _events];
    };
    case "phone::delete::event": {
        private _eventId = _data get "id";
        private _events = profileNamespace getVariable ["FORGE_Phone_Events", []];

        private _newEvents = [];
        private _deleted = false;
        {
            private _existingId = _x get "id";
            if (_existingId isEqualTo _eventId) then {
                _deleted = true;
            } else {
                _newEvents pushBack _x;
            };
        } forEach _events;

        if (_deleted) then {
            profileNamespace setVariable ["FORGE_Phone_Events", _newEvents];
            diag_log format ["[PHONE] Deleted calendar event [ID: %1]. Remaining events: %2", _eventId, count _newEvents];
        } else {
            diag_log format ["[PHONE] Calendar event not found for deletion [ID: %1]", _eventId];
        };
    };
    case "phone::get::clocks": {
        private _worldClocks = profileNamespace getVariable ["FORGE_Phone_WorldClocks", []];

        _control ctrlWebBrowserAction ["ExecJS", format ["loadWorldClocks(%1)", (toJSON _worldClocks)]];
    };
    case "phone::save::clock": {
        private _clockId = _data get "id";
        private _timezone = _data get "timezone";
        private _city = _data get "city";

        private _worldClocks = profileNamespace getVariable ["FORGE_Phone_WorldClocks", []];
        private _clockExists = false;
        {
            private _existingId = _x get "id";
            private _existingTimezone = _x get "timezone";
            if (_existingId isEqualTo _clockId || _existingTimezone isEqualTo _timezone) then {
                _clockExists = true;
            };
        } forEach _worldClocks;

        if (!_clockExists) then {
            _worldClocks pushBack _data;
            profileNamespace setVariable ["FORGE_Phone_WorldClocks", _worldClocks];

            diag_log format ["[PHONE] Added world clock: %1 (%2) [ID: %3]. Total clocks: %4", _city, _timezone, _clockId, count _worldClocks];
        } else {
            diag_log format ["[PHONE] World clock already exists: %1 (%2) [ID: %3]. Skipping duplicate.", _city, _timezone, _clockId];
        };
    };
    case "phone::delete::clock": {
        private _clockId = _data get "id";

        private _worldClocks = profileNamespace getVariable ["FORGE_Phone_WorldClocks", []];
        private _newClocks = [];
        private _deleted = false;
        {
            private _existingId = _x get "id";
            if (_existingId isEqualTo _clockId) then {
                _deleted = true;
            } else {
                _newClocks pushBack _x;
            };
        } forEach _worldClocks;

        if (_deleted) then {
            profileNamespace setVariable ["FORGE_Phone_WorldClocks", _newClocks];
            diag_log format ["[PHONE] Deleted world clock [ID: %1]. Remaining clocks: %2", _clockId, count _newClocks];
        } else {
            diag_log format ["[PHONE] World clock not found for deletion [ID: %1]", _clockId];
        };
    };
    case "phone::get::alarms": {
        private _alarms = profileNamespace getVariable ["FORGE_Phone_Alarms", []];

        _control ctrlWebBrowserAction ["ExecJS", format ["loadAlarms(%1)", (toJSON _alarms)]];
    };
    case "phone::save::alarm": {
        private _alarmId = _data get "id";
        private _alarmTime = _data get "time";
        private _alarmLabel = _data get "label";

        private _alarms = profileNamespace getVariable ["FORGE_Phone_Alarms", []];
        private _existingIndex = -1;
        {
            private _existingId = _x get "id";
            if (_existingId isEqualTo _alarmId) then {
                _existingIndex = _forEachIndex;
            };
        } forEach _alarms;

        if (_existingIndex >= 0) then {
            _alarms set [_existingIndex, _data];
            diag_log format ["[PHONE] Updated alarm: %1 at %2 [ID: %3]", _alarmLabel, _alarmTime, _alarmId];
        } else {
            _alarms pushBack _data;
            diag_log format ["[PHONE] Added new alarm: %1 at %2 [ID: %3]", _alarmLabel, _alarmTime, _alarmId];
        };

        profileNamespace setVariable ["FORGE_Phone_Alarms", _alarms];
        diag_log format ["[PHONE] Saved alarms to profile. Total alarms: %1", count _alarms];
    };
    case "phone::delete::alarm": {
        private _alarmId = _data get "id";

        private _alarms = profileNamespace getVariable ["FORGE_Phone_Alarms", []];
        private _newAlarms = [];
        private _deleted = false;
        {
            private _existingId = _x get "id";
            if (_existingId isEqualTo _alarmId) then {
                _deleted = true;
            } else {
                _newAlarms pushBack _x;
            };
        } forEach _alarms;

        if (_deleted) then {
            profileNamespace setVariable ["FORGE_Phone_Alarms", _newAlarms];
            diag_log format ["[PHONE] Deleted alarm [ID: %1]. Remaining alarms: %2", _alarmId, count _newAlarms];
        } else {
            diag_log format ["[PHONE] Alarm not found for deletion [ID: %1]", _alarmId];
        };
    };
    case "phone::toggle::alarm": {
        private _alarmId = _data get "id";

        private _alarms = profileNamespace getVariable ["FORGE_Phone_Alarms", []];
        {
            private _existingId = _x get "id";
            if (_existingId isEqualTo _alarmId) then {
                private _currentEnabled = _x get "enabled";
                _x set ["enabled", !_currentEnabled];
                diag_log format ["[PHONE] Toggled alarm [ID: %1] to %2", _alarmId, !_currentEnabled];
            };
        } forEach _alarms;

        profileNamespace setVariable ["FORGE_Phone_Alarms", _alarms];
    };
    default { hint format ["Unhandled phone event: %1", _event]; };
};

true;
