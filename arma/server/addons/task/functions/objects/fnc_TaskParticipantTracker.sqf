#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Runtime participant tracking and task notification fanout.
 *
 * TaskStore remains the public facade, while this object owns participant
 * snapshots keyed by task ID.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Task participant tracker object <HASHMAP OBJECT>
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TaskParticipantTracker) = createHashMapObject [[
    ["#type", "TaskParticipantTracker"],
    ["#create", compileFinal {
        _self call ["resetRuntimeState", []];
    }],
    ["resetRuntimeState", compileFinal {
        _self set ["participantRegistry", createHashMap];
        true
    }],
    ["trackParticipants", compileFinal {
        params [["_taskID", "", [""]], ["_entities", [], [[]]], ["_marker", "", [""]], ["_radius", 300, [0]]];

        if (_taskID isEqualTo "") exitWith { createHashMap };

        private _participantRegistry = _self getOrDefault ["participantRegistry", createHashMap];
        private _participantSnapshots = +(_participantRegistry getOrDefault [_taskID, createHashMap]);
        private _activePlayers = allPlayers select {
            alive _x
            && { side group _x isEqualTo west }
        };

        if (_marker isNotEqualTo "" && { markerShape _marker in ["RECTANGLE", "ELLIPSE"] }) then {
            {
                private _uid = getPlayerUID _x;
                if (_uid isNotEqualTo "" && { _x inArea _marker }) then {
                    if !(_uid in _participantSnapshots) then {
                        _participantSnapshots set [_uid, createHashMapFromArray [
                            ["startRating", rating _x]
                        ]];
                    };
                };
            } forEach _activePlayers;
        };

        if (_radius > 0 && { _entities isNotEqualTo [] }) then {
            {
                private _entity = _x;
                if (isNull _entity) then { continue; };

                {
                    private _uid = getPlayerUID _x;
                    if (_uid isNotEqualTo "" && { (_x distance2D _entity) <= _radius }) then {
                        if !(_uid in _participantSnapshots) then {
                            _participantSnapshots set [_uid, createHashMapFromArray [
                                ["startRating", rating _x]
                            ]];
                        };
                    };
                } forEach _activePlayers;
            } forEach _entities;
        };

        _participantRegistry set [_taskID, _participantSnapshots];
        _self set ["participantRegistry", _participantRegistry];

        _participantSnapshots
    }],
    ["recordParticipant", compileFinal {
        params [["_taskID", "", [""]], ["_uid", "", [""]], ["_snapshot", createHashMap, [createHashMap]]];

        if (_taskID isEqualTo "" || { _uid isEqualTo "" }) exitWith { createHashMap };

        private _participantRegistry = _self getOrDefault ["participantRegistry", createHashMap];
        private _participantSnapshots = +(_participantRegistry getOrDefault [_taskID, createHashMap]);
        _participantSnapshots set [_uid, +_snapshot];
        _participantRegistry set [_taskID, _participantSnapshots];
        _self set ["participantRegistry", _participantRegistry];

        _participantSnapshots
    }],
    ["getTaskParticipants", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { createHashMap };

        private _participantRegistry = _self getOrDefault ["participantRegistry", createHashMap];
        +(_participantRegistry getOrDefault [_taskID, createHashMap])
    }],
    ["getTaskParticipantUids", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { [] };

        keys (_self call ["getTaskParticipants", [_taskID]])
    }],
    ["clearTaskParticipants", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _participantRegistry = _self getOrDefault ["participantRegistry", createHashMap];
        _participantRegistry deleteAt _taskID;
        _self set ["participantRegistry", _participantRegistry];
        true
    }],
    ["notifyParticipants", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_type", "info", [""]],
            ["_title", "Tasks", [""]],
            ["_message", "", [""]]
        ];

        if (_taskID isEqualTo "" || { _message isEqualTo "" }) exitWith { false };

        private _participantSnapshots = _self call ["getTaskParticipants", [_taskID]];
        if (_participantSnapshots isEqualTo createHashMap) exitWith { false };

        private _participantUids = keys _participantSnapshots;
        if (_participantUids isEqualTo []) exitWith { false };
        if (isNil QEGVAR(common,EventBus)) exitWith {
            {
                private _player = [_x] call EFUNC(common,getPlayer);
                if (isNull _player) then { continue; };
                [CRPC(notifications,recieveNotification), [_type, _title, _message], _player] call CFUNC(targetEvent);
            } forEach _participantUids;
            true
        };

        EGVAR(common,EventBus) call ["emit", [
            "task.notification.requested",
            createHashMapFromArray [
                ["taskID", _taskID],
                ["notificationType", _type],
                ["title", _title],
                ["message", _message],
                ["participantUids", _participantUids]
            ],
            createHashMapFromArray [["source", "task"]]
        ]];

        true
    }]
]];

GVAR(TaskParticipantTracker)
