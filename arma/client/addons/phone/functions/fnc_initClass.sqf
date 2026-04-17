#include "..\script_component.hpp"

#pragma hemtt ignore_variables ["_self"]

/*
 * Author: IDSolutions
 * Initialize unified phone class
 *
 * Arguments:
 * N/A
 *
 * Return Value:
 * N/A
 *
 * Examples:
 * [] call forge_client_phone_fnc_initClass
 *
 * Public: Yes
 */

// TODO: Perform comprehensive review and edit of phone class implementation
// Then integrate this class to replace current phone handling logic
// Key areas to address:
// - Verify all phone data structures and methods
// - Ensure proper data persistence
// - Implement robust error handling
// - Replace direct UI manipulation with class-based approach
GVAR(PhoneClass) = createHashMapObject [[
    ["#type", "IPhoneClass"],
    ["#create", {
        _self set ["uid", getPlayerUID player];
        _self set ["notes", createHashMap];
        _self set ["events", []];
        _self set ["settings", createHashMap];
        _self set ["isLoaded", false];
        _self set ["lastSave", time];

        // Initialize default settings
        private _settings = createHashMap;
        _settings set ["theme", "light"];
        _settings set ["notifications", true];
        _settings set ["sound", true];
        _settings set ["vibration", true];
        _self set ["settings", _settings];
    }],
    ["init", {
        // Contacts/messages/emails are server-owned. Keep only local utility-app
        // state in profileNamespace until those apps are migrated.
        private _savedNotes = profileNamespace getVariable ["FORGE_Phone_Notes", createHashMap];
        private _savedEvents = profileNamespace getVariable ["FORGE_Phone_Events", []];
        private _savedSettings = profileNamespace getVariable ["FORGE_Phone_Settings", createHashMap];

        _self set ["notes", _savedNotes];
        _self set ["events", _savedEvents];

        // Merge saved settings with defaults
        private _defaultSettings = _self get "settings";
        {
            _defaultSettings set [_x, _y];
        } forEach _savedSettings;

        _self set ["settings", _defaultSettings];
        _self set ["isLoaded", true];

        systemChat format ["Phone loaded for %1", (name player)];
        diag_log "[FORGE:Client:Phone] Phone Class Initialized!";
    }],
    ["_padString", {
        params [["_number", 0, [0]], ["_length", 0, [0]]];

        private _str = str _number;

        while { (_str select [(_length - 1), 1]) == "" } do { _str = "0" + _str };
        _str
    }],
    ["save", {
        params [["_sync", false, [false]]];

        // Save local-only phone app state to profile.
        profileNamespace setVariable ["FORGE_Phone_Notes", _self get "notes"];
        profileNamespace setVariable ["FORGE_Phone_Events", _self get "events"];
        profileNamespace setVariable ["FORGE_Phone_Settings", _self get "settings"];

        if (_sync) then { saveProfileNamespace; };

        _self set ["lastSave", time];
    }],
    ["sync", {
        params [["_data", createHashMap, [createHashMap]]];

        if (_data isEqualTo createHashMap) exitWith { diag_log "[FORGE:Client:Phone] Empty data received for sync, skipping."; };
    }],
    ["get", {
        params [["_key", "", [""]], ["_default", nil, [[], "", 0, false, createHashMap]]];

        private _settings = _self get "settings";
        _settings getOrDefault [_key, _default];
    }],
    ["addNote", {
        params [["_data", createHashMap, [createHashMap]]];

        if (_data isEqualTo createHashMap) exitWith { false };

        private _noteId = _data get "id";
        private _notes = _self get "notes";

        _notes set [_noteId, _data];
        _self call ["save", [true]];

        diag_log format ["[FORGE:Client:Phone] Added note [ID: %1]", _noteId];
        true
    }],
    ["updateNote", {
        params [["_data", createHashMap, [createHashMap]]];

        private _noteId = _data get "id";
        if (isNil "_noteId" || _noteId == "") exitWith { false };

        private _notes = _self get "notes";
        if !(_noteId in _notes) exitWith { false };

        _notes set [_noteId, _data];
        _self set ["notes", _notes];
        _self call ["save", [true]];

        diag_log format ["[FORGE:Client:Phone] Updated note [ID: %1]", _noteId];
        true
    }],
    ["deleteNote", {
        params [["_noteId", "", [""]]];

        if (_noteId == "") exitWith { false };

        private _notes = _self get "notes";
        if (!(_noteId in _notes)) exitWith { false };

        _notes deleteAt _noteId;
        _self set ["notes", _notes];
        _self call ["save", [true]];

        diag_log format ["[FORGE:Client:Phone] Deleted note [ID: %1]", _noteId];
        true
    }],
    ["getNote", {
        params [["_noteId", "", [""]], ["_default", nil]];

        private _notes = _self get "notes";
        _notes getOrDefault [_noteId, _default];
    }],
    ["getAllNotes", {
        private _notes = _self get "notes";
        private _notesArray = [];

        {
            _notesArray pushBack _y;
        } forEach _notes;

        _notesArray
    }],
    ["setSetting", {
        params [["_key", "", [""]], ["_value", nil]];

        if (_key == "") exitWith { false };

        private _settings = _self get "settings";
        _settings set [_key, _value];
        _self set ["settings", _settings];
        _self call ["save", [true]];

        true
    }],
    ["getSetting", {
        params [["_key", "", [""]], ["_default", nil]];

        private _settings = _self get "settings";
        _settings getOrDefault [_key, _default];
    }],
    ["getAllSettings", {
        _self get "settings";
    }],
    ["addEvent", {
        params [["_eventData", createHashMap, [createHashMap]]];

        if (_eventData isEqualTo createHashMap) exitWith { false };

        private _eventId = _eventData get "id";
        if (isNil "_eventId" || _eventId == "") exitWith { false };

        private _events = _self get "events";

        // Check if event already exists
        private _existingIndex = _events findIf {(_x get "id") isEqualTo _eventId};

        if (_existingIndex >= 0) then {
            // Update existing event
            _events set [_existingIndex, _eventData];
            diag_log format ["[FORGE:Client:Phone] Updated event [ID: %1]", _eventId];
        } else {
            // Add new event
            _events pushBack _eventData;
            diag_log format ["[FORGE:Client:Phone] Added event [ID: %1]", _eventId];
        };

        _self set ["events", _events];
        _self call ["save", [true]];
        true
    }],
    ["updateEvent", {
        params [["_eventData", createHashMap, [createHashMap]]];

        private _eventId = _eventData get "id";
        if (isNil "_eventId" || _eventId == "") exitWith { false };

        private _events = _self get "events";
        private _existingIndex = _events findIf {(_x get "id") isEqualTo _eventId};

        if (_existingIndex < 0) exitWith { false };

        _events set [_existingIndex, _eventData];
        _self set ["events", _events];
        _self call ["save", [true]];

        diag_log format ["[FORGE:Client:Phone] Updated event [ID: %1]", _eventId];
        true
    }],
    ["deleteEvent", {
        params [["_eventId", "", [""]]];

        if (_eventId == "") exitWith { false };

        private _events = _self get "events";
        private _existingIndex = _events findIf {(_x get "id") isEqualTo _eventId};

        if (_existingIndex < 0) exitWith { false };

        _events deleteAt _existingIndex;
        _self set ["events", _events];
        _self call ["save", [true]];

        diag_log format ["[FORGE:Client:Phone] Deleted event [ID: %1]", _eventId];
        true
    }],
    ["getEvent", {
        params [["_eventId", "", [""]], ["_default", nil]];

        private _events = _self get "events";
        private _event = _events select {(_x get "id") isEqualTo _eventId};

        if (_event isNotEqualTo []) then {
            _event select 0
        } else {
            _default
        };
    }],
    ["getAllEvents", {
        private _events = _self get "events";
        _events
    }],
    ["getEventsByDate", {
        params [["_date", "", [""]]];

        private _events = _self get "events";
        private _dateEvents = _events select {
            private _eventStartTime = _x get "startTime";
            if (isNil "_eventStartTime") then { false } else {
                // Extract date from ISO string (YYYY-MM-DD)
                private _eventDate = (_eventStartTime splitString "T") select 0;
                _eventDate isEqualTo _date
            };
        };

        _dateEvents
    }],
    ["clearAllEvents", {
        _self set ["events", []];
        _self call ["save", [true]];
        diag_log "[FORGE:Client:Phone] Cleared all events";
        true
    }],
    ["getEventsForToday", {
        private _currentTime = systemTimeUTC;
        private _todayDate = format ["%1-%2-%3",
            _currentTime select 0,
            _self call ["_padString", [(_currentTime select 1), 2]],
            _self call ["_padString", [(_currentTime select 2), 2]]
        ];

        _self call ["getEventsByDate", [_todayDate]]
    }]
]];

SETVAR(player,FORGE_PhoneClass,GVAR(PhoneClass));
GVAR(PhoneClass)
