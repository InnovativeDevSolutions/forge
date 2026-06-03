#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Dispatches task notification events to client notification UIs.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Task notification service object <HASHMAP OBJECT>
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TaskNotificationService) = createHashMapObject [[
    ["#type", "TaskNotificationService"],
    ["sendToPlayers", compileFinal {
        params [
            ["_uids", [], [[]]],
            ["_type", "info", [""]],
            ["_title", "Tasks", [""]],
            ["_message", "", [""]]
        ];

        if (_message isEqualTo "" || { _uids isEqualTo [] }) exitWith { false };

        {
            private _player = [_x] call EFUNC(common,getPlayer);
            if (isNull _player) then { continue; };
            [CRPC(notifications,recieveNotification), [_type, _title, _message], _player] call CFUNC(targetEvent);
        } forEach _uids;

        true
    }],
    ["handleTaskNotification", compileFinal {
        params ["_event"];

        private _type = _event getOrDefault ["notificationType", "info"];
        private _title = _event getOrDefault ["title", "Tasks"];
        private _message = _event getOrDefault ["message", ""];
        private _participantUids = +(_event getOrDefault ["participantUids", []]);

        if !(_self call ["sendToPlayers", [_participantUids, _type, _title, _message]]) exitWith { false };

        if (GETGVAR(enableEventLogs,false)) then {
            ["INFO", format [
                "Task notification event: taskID=%1 type=%2 recipients=%3 message=%4",
                _event getOrDefault ["taskID", ""],
                _type,
                _participantUids,
                _message
            ]] call EFUNC(common,log);
        };

        true
    }],
    ["handleRewardNotification", compileFinal {
        params ["_event"];

        private _type = _event getOrDefault ["notificationType", "info"];
        private _title = _event getOrDefault ["title", "Tasks"];
        private _message = _event getOrDefault ["message", ""];
        private _memberUids = +(_event getOrDefault ["memberUids", []]);

        if !(_self call ["sendToPlayers", [_memberUids, _type, _title, _message]]) exitWith { false };

        if (GETGVAR(enableEventLogs,false)) then {
            ["INFO", format [
                "Task reward notification event: taskID=%1 type=%2 recipients=%3 message=%4",
                _event getOrDefault ["taskID", ""],
                _type,
                _memberUids,
                _message
            ]] call EFUNC(common,log);
        };

        true
    }],
    ["registerEventListeners", compileFinal {
        if !(isNil QGVAR(TaskNotificationEventTokens)) exitWith { GVAR(TaskNotificationEventTokens) };

        private _sendTaskNotification = {
            params ["_event"];
            GVAR(TaskNotificationService) call ["handleTaskNotification", [_event]];
        };

        private _sendRewardNotification = {
            params ["_event"];
            GVAR(TaskNotificationService) call ["handleRewardNotification", [_event]];
        };

        GVAR(TaskNotificationEventTokens) = [
            EGVAR(common,EventBus) call ["on", ["task.notification.requested", _sendTaskNotification, "task.notification.send"]],
            EGVAR(common,EventBus) call ["on", ["task.reward.notification.requested", _sendRewardNotification, "task.reward.notification.send"]]
        ];

        GVAR(TaskNotificationEventTokens)
    }]
]];

GVAR(TaskNotificationService)
