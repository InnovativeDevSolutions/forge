#include "..\script_component.hpp"

/*
 * File: fnc_eventBus.sqf
 * Author: IDSolutions
 * Date: 2026-05-14
 * Public: No
 *
 * Description:
 * Initializes the framework-wide in-process event bus.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Event bus object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_common_fnc_eventBus
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(EventBusBase) = compileFinal createHashMapFromArray [
    ["#type", "EventBus"],
    ["#create", compileFinal {
        _self set ["handlers", createHashMap];
        _self set ["nextToken", 0];

        ["INFO", "Common EventBus Initialized!"] call EFUNC(common,log);
    }],
    ["on", compileFinal {
        params [["_eventName", "", [""]], ["_handler", {}, [{}]], ["_owner", "", [""]]];

        if (_eventName isEqualTo "") exitWith { "" };

        private _handlers = _self getOrDefault ["handlers", createHashMap];
        private _eventHandlers = +(_handlers getOrDefault [_eventName, []]);
        private _nextToken = (_self getOrDefault ["nextToken", 0]) + 1;
        private _token = format ["%1:%2", _eventName, _nextToken];

        _eventHandlers pushBack createHashMapFromArray [
            ["token", _token],
            ["owner", _owner],
            ["handler", _handler]
        ];

        _handlers set [_eventName, _eventHandlers];
        _self set ["handlers", _handlers];
        _self set ["nextToken", _nextToken];

        _token
    }],
    ["off", compileFinal {
        params [["_token", "", [""]]];

        if (_token isEqualTo "") exitWith { false };

        private _handlers = _self getOrDefault ["handlers", createHashMap];
        private _removed = false;

        {
            private _eventHandlers = +(_handlers getOrDefault [_x, []]);
            private _remainingHandlers = _eventHandlers select {
                (_x getOrDefault ["token", ""]) isNotEqualTo _token
            };

            if ((count _remainingHandlers) isNotEqualTo (count _eventHandlers)) then {
                _removed = true;
                if (_remainingHandlers isEqualTo []) then {
                    _handlers deleteAt _x;
                } else {
                    _handlers set [_x, _remainingHandlers];
                };
            };
        } forEach (keys _handlers);

        _self set ["handlers", _handlers];
        _removed
    }],
    ["emit", compileFinal {
        params [["_eventName", "", [""]], ["_payload", createHashMap], ["_options", createHashMap]];

        private _result = createHashMapFromArray [
            ["event", _eventName],
            ["listenerCount", 0],
            ["invoked", 0],
            ["failed", 0]
        ];

        if (_eventName isEqualTo "") exitWith { _result };

        if !(_payload isEqualType createHashMap) then {
            _payload = createHashMapFromArray [["value", _payload]];
        };
        if !(_options isEqualType createHashMap) then {
            _options = createHashMap;
        };

        private _eventPayload = +_payload;
        _eventPayload set ["event", _eventName];
        _eventPayload set ["source", _eventPayload getOrDefault ["source", _options getOrDefault ["source", "unknown"]]];
        _eventPayload set ["timestamp", _eventPayload getOrDefault ["timestamp", serverTime]];

        private _handlers = _self getOrDefault ["handlers", createHashMap];
        private _eventHandlers = +(_handlers getOrDefault [_eventName, []]);
        _result set ["listenerCount", count _eventHandlers];

        {
            private _handler = _x getOrDefault ["handler", {}];
            private _token = _x getOrDefault ["token", ""];
            private _owner = _x getOrDefault ["owner", ""];

            try {
                [_eventPayload] call _handler;
                _result set ["invoked", (_result getOrDefault ["invoked", 0]) + 1];
            } catch {
                _result set ["failed", (_result getOrDefault ["failed", 0]) + 1];
                ["ERROR", format ["EventBus handler failed. Event=%1 Token=%2 Owner=%3 Error=%4", _eventName, _token, _owner, _exception]] call EFUNC(common,log);
            };
        } forEach _eventHandlers;

        _result
    }],
    ["clear", compileFinal {
        params [["_eventName", "", [""]]];

        private _handlers = _self getOrDefault ["handlers", createHashMap];

        if (_eventName isEqualTo "") then {
            _self set ["handlers", createHashMap];
        } else {
            _handlers deleteAt _eventName;
            _self set ["handlers", _handlers];
        };

        true
    }],
    ["listenerCount", compileFinal {
        params [["_eventName", "", [""]]];

        private _handlers = _self getOrDefault ["handlers", createHashMap];

        if (_eventName isEqualTo "") exitWith {
            private _total = 0;
            { _total = _total + (count _y); } forEach _handlers;
            _total
        };

        count (_handlers getOrDefault [_eventName, []])
    }],
    ["listeners", compileFinal {
        params [["_eventName", "", [""]]];

        private _handlers = _self getOrDefault ["handlers", createHashMap];

        if (_eventName isNotEqualTo "") exitWith { +(_handlers getOrDefault [_eventName, []]) };

        private _counts = createHashMap;
        { _counts set [_x, count _y]; } forEach _handlers;

        _counts
    }]
];

GVAR(EventBus) = createHashMapObject [GVAR(EventBusBase)];

GVAR(EventBus)
