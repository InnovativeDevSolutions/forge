#include "script_component.hpp"

if (isNil QEGVAR(common,EventBus)) then { call EFUNC(common,eventBus); };
if (isNil QGVAR(TaskLifecycleEventLogTokens)) then {
    private _logTaskLifecycleEvent = {
        params ["_event"];

        if !(missionNamespace getVariable [QGVAR(enableEventLogs), false]) exitWith {};

        ["INFO", format [
            "Task lifecycle event: %1 taskID=%2 taskType=%3 status=%4 participants=%5",
            _event getOrDefault ["event", ""],
            _event getOrDefault ["taskID", ""],
            _event getOrDefault ["taskType", ""],
            _event getOrDefault ["status", ""],
            _event getOrDefault ["participants", []]
        ]] call EFUNC(common,log);
    };

    private _logTaskRewardEvent = {
        params ["_event"];

        if !(missionNamespace getVariable [QGVAR(enableEventLogs), false]) exitWith {};

        ["INFO", format [
            "Task reward event: %1 taskID=%2 success=%3 message=%4",
            _event getOrDefault ["event", ""],
            _event getOrDefault ["taskID", ""],
            !((_event getOrDefault ["event", ""]) in ["task.reward.failed", "task.rating.failed"]),
            _event getOrDefault ["message", ""]
        ]] call EFUNC(common,log);
    };

    GVAR(TaskLifecycleEventLogTokens) = [
        EGVAR(common,EventBus) call ["on", ["task.created", _logTaskLifecycleEvent, "task.lifecycle.log"]],
        EGVAR(common,EventBus) call ["on", ["task.started", _logTaskLifecycleEvent, "task.lifecycle.log"]],
        EGVAR(common,EventBus) call ["on", ["task.completed", _logTaskLifecycleEvent, "task.lifecycle.log"]],
        EGVAR(common,EventBus) call ["on", ["task.failed", _logTaskLifecycleEvent, "task.lifecycle.log"]],
        EGVAR(common,EventBus) call ["on", ["task.cleared", _logTaskLifecycleEvent, "task.lifecycle.log"]],
        EGVAR(common,EventBus) call ["on", ["task.reward.requested", _logTaskRewardEvent, "task.reward.log"]],
        EGVAR(common,EventBus) call ["on", ["task.reward.applied", _logTaskRewardEvent, "task.reward.log"]],
        EGVAR(common,EventBus) call ["on", ["task.reward.failed", _logTaskRewardEvent, "task.reward.log"]],
        EGVAR(common,EventBus) call ["on", ["task.rating.applied", _logTaskRewardEvent, "task.reward.log"]],
        EGVAR(common,EventBus) call ["on", ["task.rating.failed", _logTaskRewardEvent, "task.reward.log"]]
    ];
};

if (isNil QGVAR(TaskNotificationEventTokens)) then {
    private _sendTaskNotification = {
        params ["_event"];

        private _type = _event getOrDefault ["notificationType", "info"];
        private _title = _event getOrDefault ["title", "Tasks"];
        private _message = _event getOrDefault ["message", ""];
        private _participantUids = +(_event getOrDefault ["participantUids", []]);

        if (_message isEqualTo "" || { _participantUids isEqualTo [] }) exitWith {};

        {
            private _player = [_x] call EFUNC(common,getPlayer);
            if (isNull _player) then { continue; };
            [CRPC(notifications,recieveNotification), [_type, _title, _message], _player] call CFUNC(targetEvent);
        } forEach _participantUids;

        if (missionNamespace getVariable [QGVAR(enableEventLogs), false]) then {
            ["INFO", format [
                "Task notification event: taskID=%1 type=%2 recipients=%3 message=%4",
                _event getOrDefault ["taskID", ""],
                _type,
                _participantUids,
                _message
            ]] call EFUNC(common,log);
        };
    };

    private _sendRewardNotification = {
        params ["_event"];

        private _type = _event getOrDefault ["notificationType", "info"];
        private _title = _event getOrDefault ["title", "Tasks"];
        private _message = _event getOrDefault ["message", ""];
        private _memberUids = +(_event getOrDefault ["memberUids", []]);

        if (_message isEqualTo "" || { _memberUids isEqualTo [] }) exitWith {};

        {
            private _player = [_x] call EFUNC(common,getPlayer);
            if (isNull _player) then { continue; };
            [CRPC(notifications,recieveNotification), [_type, _title, _message], _player] call CFUNC(targetEvent);
        } forEach _memberUids;

        if (missionNamespace getVariable [QGVAR(enableEventLogs), false]) then {
            ["INFO", format [
                "Task reward notification event: taskID=%1 type=%2 recipients=%3 message=%4",
                _event getOrDefault ["taskID", ""],
                _type,
                _memberUids,
                _message
            ]] call EFUNC(common,log);
        };
    };

    GVAR(TaskNotificationEventTokens) = [
        EGVAR(common,EventBus) call ["on", ["task.notification.requested", _sendTaskNotification, "task.notification.send"]],
        EGVAR(common,EventBus) call ["on", ["task.reward.notification.requested", _sendRewardNotification, "task.reward.notification.send"]]
    ];
};

["ace_explosives_defuse", {
    private _taskID = "";
    private _explosive = objNull;
    {
        if (_x isEqualType objNull && { !isNull _x }) then {
            if (isNull _explosive) then { _explosive = _x; };
            _taskID = _x getVariable ["assignedTask", ""];
            if (_taskID isNotEqualTo "") exitWith {};
        };
    } forEach _this;

    if (_taskID isEqualTo "" && { !isNull _explosive }) then {
        _taskID = GVAR(TaskStore) call ["findTaskEntityOwner", ["ieds", _explosive]];
    };

    if (_taskID isEqualTo "") exitWith {
        ["WARNING", format [
            "ACE Defuse Event Ignored: No assignedTask found. Explosive=%1, Type=%2, NetID=%3",
            _explosive,
            typeOf _explosive,
            netId _explosive
        ]] call EFUNC(common,log);
    };

    GVAR(TaskStore) call ["incrementDefuseCount", [_taskID]];
}] call CFUNC(addEventHandler);
[] call FUNC(missionManager);
