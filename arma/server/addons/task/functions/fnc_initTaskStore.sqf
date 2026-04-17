#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the task store for task entity tracking, participant
 * contribution tracking, and task outcome application.
 *
 * Task metadata is extension-backed but intentionally transient. The
 * task backend is reset when this store is created so task/catalog/status
 * state starts clean for each server or mission lifecycle.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Task store object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_task_fnc_initTaskStore
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TaskStore) = createHashMapObject [[
    ["#type", "TaskStore"],
    ["#create", compileFinal {
        _self set ["participantRegistry", createHashMap];
        _self set ["taskLifecycleRegistry", createHashMap];
        _self set ["taskEntityRegistries", createHashMapFromArray [
            ["cargo", createHashMap],
            ["hostages", createHashMap],
            ["hvts", createHashMap],
            ["ieds", createHashMap],
            ["entities", createHashMap],
            ["shooters", createHashMap],
            ["targets", createHashMap]
        ]];

        // Task extension state is mission-scoped and intentionally reset on
        // startup rather than being treated as durable account data.
        ["task:reset", []] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if (
            !_isSuccess
            || { !(_result isEqualType "") }
            || { (_result find "Error:") == 0 }
        ) then {
            ["WARNING", "Failed to reset task backend state during task store initialization."] call EFUNC(common,log);
        };
    }],
    ["callTaskStateEnvelope", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        private _envelope = createHashMapFromArray [
            ["success", false],
            ["error", ""]
        ];

        if (_function isEqualTo "") exitWith { _envelope };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !_isSuccess exitWith {
            _envelope set ["error", format ["Task backend call '%1' failed.", _function]];
            _envelope
        };
        if !(_result isEqualType "") exitWith {
            _envelope set ["error", format ["Task backend call '%1' returned an invalid response.", _function]];
            _envelope
        };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Task extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            _envelope set ["error", _result select [7]];
            _envelope
        };

        _envelope set ["success", true];
        if (_result isNotEqualTo "") then {
            _envelope set ["data", fromJSON _result];
        };

        _envelope
    }],
    ["callTaskState", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]], ["_fallback", nil]];

        private _envelope = _self call ["callTaskStateEnvelope", [_function, _arguments]];
        if !(_envelope getOrDefault ["success", false]) exitWith { _fallback };

        _envelope getOrDefault ["data", _fallback]
    }],
    ["bindTaskOwnership", compileFinal {
        params [["_taskID", "", [""]], ["_requesterUid", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["requesterUid", _requesterUid],
            ["orgID", "default"],
            ["message", ""]
        ];

        if (_taskID isEqualTo "") exitWith {
            _result set ["message", "Missing task ID."];
            _result
        };

        private _orgID = "default";

        if (_requesterUid isNotEqualTo "") then {
            private _actor = EGVAR(actor,ActorStore) call ["load", [_requesterUid]];

            if (_actor isEqualTo createHashMap) exitWith {
                _result set ["message", format ["Failed to load actor for %1.", _requesterUid]];
                _result
            };

            _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        };

        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["orgId", _orgID]
        ];
        private _envelope = _self call [
            "callTaskStateEnvelope",
            [
                "task:ownership:bind",
                [_taskID, toJSON _context]
            ]
        ];
        if !(_envelope getOrDefault ["success", false]) exitWith {
            _result set ["message", _envelope getOrDefault ["error", "Failed to bind task ownership."]];
            _result
        };

        private _bindResult = _envelope getOrDefault ["data", createHashMap];
        _result set ["success", true];
        _result set ["message", _bindResult getOrDefault [
            "message",
            ["No requester UID provided. Bound task to default organization.", "Task ownership updated."] select (_requesterUid isNotEqualTo "")
        ]];
        _result set ["orgID", _bindResult getOrDefault ["orgId", _orgID]];
        _result
    }],
    ["releaseTaskOwnership", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _envelope = _self call ["callTaskStateEnvelope", ["task:ownership:release", [_taskID]]];
        _envelope getOrDefault ["success", false]
    }],
    ["buildTaskLifecycleEventPayload", compileFinal {
        params [["_taskID", "", [""]], ["_status", "", [""]], ["_extra", createHashMap]];

        if !(_extra isEqualType createHashMap) then {
            _extra = createHashMap;
        };

        private _catalogEntry = _self call ["getTaskCatalogEntry", [_taskID]];
        private _lifecycleRegistry = _self getOrDefault ["taskLifecycleRegistry", createHashMap];
        private _lifecycle = +(_lifecycleRegistry getOrDefault [_taskID, createHashMap]);
        private _startedAt = _lifecycle getOrDefault ["startedAt", -1];
        private _finishedAt = _lifecycle getOrDefault ["finishedAt", -1];

        createHashMapFromArray [
            ["taskID", _taskID],
            ["taskType", _catalogEntry getOrDefault ["type", ""]],
            ["title", _catalogEntry getOrDefault ["title", _taskID]],
            ["description", _catalogEntry getOrDefault ["description", ""]],
            ["position", +(_catalogEntry getOrDefault ["position", []])],
            ["status", _status],
            ["source", _catalogEntry getOrDefault ["source", "task"]],
            ["requesterUid", _catalogEntry getOrDefault ["requesterUid", ""]],
            ["orgID", _catalogEntry getOrDefault ["orgID", "default"]],
            ["startedAt", _startedAt],
            ["finishedAt", _finishedAt],
            ["duration", if (_startedAt >= 0 && { _finishedAt >= 0 }) then { _finishedAt - _startedAt } else { -1 }],
            ["failureReason", _extra getOrDefault ["failureReason", ""]],
            ["participants", _self call ["getTaskParticipantUids", [_taskID]]],
            ["rewardData", +(_extra getOrDefault ["rewardData", createHashMap])],
            ["resultSnapshot", +(_extra getOrDefault ["resultSnapshot", createHashMap])],
            ["catalogEntry", +_catalogEntry]
        ]
    }],
    ["emitTaskLifecycleEvent", compileFinal {
        params [["_eventName", "", [""]], ["_taskID", "", [""]], ["_status", "", [""]], ["_extra", createHashMap]];

        if (_eventName isEqualTo "" || { _taskID isEqualTo "" }) exitWith { createHashMap };
        if (isNil QEGVAR(common,EventBus)) exitWith { createHashMap };

        EGVAR(common,EventBus) call ["emit", [
            _eventName,
            _self call ["buildTaskLifecycleEventPayload", [_taskID, _status, _extra]],
            createHashMapFromArray [["source", "task"]]
        ]]
    }],
    ["registerTaskCatalogEntry", compileFinal {
        params [["_taskID", "", [""]], ["_entry", createHashMap, [createHashMap]]];

        if (_taskID isEqualTo "" || { _entry isEqualTo createHashMap }) exitWith { false };

        private _envelope = _self call [
            "callTaskStateEnvelope",
            [
                "task:catalog:upsert",
                [_taskID, toJSON _entry]
            ]
        ];
        private _registered = _envelope getOrDefault ["success", false];

        if (_registered) then {
            private _lifecycleRegistry = _self getOrDefault ["taskLifecycleRegistry", createHashMap];
            private _lifecycle = +(_lifecycleRegistry getOrDefault [_taskID, createHashMap]);
            _lifecycle set ["createdAt", serverTime];
            _lifecycleRegistry set [_taskID, _lifecycle];
            _self set ["taskLifecycleRegistry", _lifecycleRegistry];

            _self call ["emitTaskLifecycleEvent", ["task.created", _taskID, "created", createHashMap]];
        };

        _registered
    }],
    ["getActiveTaskCatalog", compileFinal {
        private _entries = _self call ["callTaskState", ["task:catalog:active", [], []]];
        if !(_entries isEqualType []) exitWith { [] };

        _entries
    }],
    ["hasTaskCatalogEntry", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _entry = _self call ["callTaskState", ["task:catalog:get", [_taskID], objNull]];
        _entry isEqualType createHashMap
    }],
    ["getTaskCatalogEntry", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { createHashMap };

        private _entry = _self call ["callTaskState", ["task:catalog:get", [_taskID], createHashMap]];
        if !(_entry isEqualType createHashMap) exitWith { createHashMap };

        _entry
    }],
    ["isTaskAccepted", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _entry = _self call ["getTaskCatalogEntry", [_taskID]];
        if (_entry isEqualTo createHashMap) exitWith { false };

        (_entry getOrDefault ["accepted", false]) || { (_entry getOrDefault ["requesterUid", ""]) isNotEqualTo "" }
    }],
    ["acceptTask", compileFinal {
        params [["_taskID", "", [""]], ["_requesterUid", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to accept task."],
            ["entry", createHashMap]
        ];

        if (_taskID isEqualTo "" || { _requesterUid isEqualTo "" }) exitWith {
            _result set ["message", "Missing task ID or requester UID."];
            _result
        };

        private _actor = EGVAR(actor,ActorStore) call ["load", [_requesterUid]];
        if (_actor isEqualTo createHashMap) exitWith {
            _result set ["message", format ["Failed to load actor for %1.", _requesterUid]];
            _result
        };

        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];

        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["orgId", _orgID]
        ];
        private _envelope = _self call [
            "callTaskStateEnvelope",
            [
                "task:ownership:accept",
                [_taskID, toJSON _context]
            ]
        ];
        if !(_envelope getOrDefault ["success", false]) exitWith {
            _result set ["message", _envelope getOrDefault ["error", "Unable to accept task."]];
            _result
        };

        private _acceptResult = _envelope getOrDefault ["data", createHashMap];
        private _entry = _acceptResult getOrDefault ["entry", createHashMap];
        if !(_entry isEqualType createHashMap) then {
            _entry = createHashMap;
        };

        _result set ["success", true];
        _result set ["message", _acceptResult getOrDefault ["message", "Task accepted."]];
        _result set ["entry", _entry];
        _result
    }],
    ["setTaskStatus", compileFinal {
        params [["_taskID", "", [""]], ["_status", "", [""]]];

        if (_taskID isEqualTo "" || { _status isEqualTo "" }) exitWith { false };

        private _envelope = _self call ["callTaskStateEnvelope", ["task:status:set", [_taskID, _status]]];
        private _statusResult = _envelope getOrDefault ["success", false];

        if (_statusResult) then {
            private _normalizedStatus = toLowerANSI _status;
            private _lifecycleRegistry = _self getOrDefault ["taskLifecycleRegistry", createHashMap];
            private _lifecycle = +(_lifecycleRegistry getOrDefault [_taskID, createHashMap]);
            private _eventName = "";

            switch (_normalizedStatus) do {
                case "active": {
                    _lifecycle set ["startedAt", serverTime];
                    _eventName = "task.started";
                };
                case "succeeded": {
                    _lifecycle set ["finishedAt", serverTime];
                    _eventName = "task.completed";
                };
                case "failed": {
                    _lifecycle set ["finishedAt", serverTime];
                    _eventName = "task.failed";
                };
            };

            _lifecycleRegistry set [_taskID, _lifecycle];
            _self set ["taskLifecycleRegistry", _lifecycleRegistry];

            if (_eventName isNotEqualTo "") then {
                _self call ["emitTaskLifecycleEvent", [_eventName, _taskID, _normalizedStatus, createHashMap]];
            };
        };

        _statusResult
    }],
    ["getTaskStatus", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { "" };

        private _status = _self call ["callTaskState", ["task:status:get", [_taskID], ""]];
        if !(_status isEqualType "") exitWith { "" };

        _status
    }],
    ["clearTaskStatus", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        [(_self call ["callTaskState", ["task:status:clear", [_taskID], false]])] params [["_statusResult", false, [false]]];

        _statusResult
    }],
    ["registerTaskEntity", compileFinal {
        params [["_registryKey", "", [""]], ["_taskID", "", [""]], ["_entity", objNull, [objNull]]];

        if (_registryKey isEqualTo "" || { _taskID isEqualTo "" } || { isNull _entity }) exitWith { false };

        private _taskEntityRegistries = _self getOrDefault ["taskEntityRegistries", createHashMap];
        private _registry = +(_taskEntityRegistries getOrDefault [_registryKey, createHashMap]);
        private _entities = +(_registry getOrDefault [_taskID, []]);
        _entities pushBackUnique _entity;
        _registry set [_taskID, _entities];
        _taskEntityRegistries set [_registryKey, _registry];
        _self set ["taskEntityRegistries", _taskEntityRegistries];

        true
    }],
    ["getTaskEntities", compileFinal {
        params [["_registryKey", "", [""]], ["_taskID", "", [""]]];

        if (_registryKey isEqualTo "" || { _taskID isEqualTo "" }) exitWith { [] };

        private _taskEntityRegistries = _self getOrDefault ["taskEntityRegistries", createHashMap];
        private _registry = _taskEntityRegistries getOrDefault [_registryKey, createHashMap];

        +(_registry getOrDefault [_taskID, []])
    }],
    ["findTaskEntityOwner", compileFinal {
        params [["_registryKey", "", [""]], ["_entity", objNull, [objNull]]];

        if (_registryKey isEqualTo "" || { isNull _entity }) exitWith { "" };

        private _taskEntityRegistries = _self getOrDefault ["taskEntityRegistries", createHashMap];
        private _registry = _taskEntityRegistries getOrDefault [_registryKey, createHashMap];
        private _resolvedTaskID = "";

        {
            private _taskID = _x;
            private _entities = _y;

            if (_entity in _entities) exitWith {
                _resolvedTaskID = _taskID;
            };

            private _matchingEntity = _entities select {
                !isNull _x
                && { (typeOf _x) isEqualTo (typeOf _entity) }
                && { _x distance _entity < 1 }
            };
            if (_matchingEntity isNotEqualTo []) exitWith {
                _resolvedTaskID = _taskID;
            };
        } forEach _registry;

        _resolvedTaskID
    }],
    ["clearTaskEntities", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        private _taskEntityRegistries = _self getOrDefault ["taskEntityRegistries", createHashMap];

        {
            private _registry = +_y;
            _registry deleteAt _taskID;
            _taskEntityRegistries set [_x, _registry];
        } forEach _taskEntityRegistries;

        _self set ["taskEntityRegistries", _taskEntityRegistries];
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
    ["resolveRewardContext", compileFinal {
        params [["_taskID", "", [""]]];

        private _result = createHashMapFromArray [
            ["requesterUid", ""],
            ["orgID", ""],
            ["memberUids", []]
        ];

        if (_taskID isEqualTo "") exitWith { _result };

        private _rewardState = _self call ["callTaskState", ["task:ownership:reward_context", [_taskID], createHashMap]];
        if (_rewardState isEqualTo createHashMap) exitWith { _result };

        private _requesterUid = _rewardState getOrDefault ["requesterUid", ""];
        private _resolvedOrgID = _rewardState getOrDefault ["orgId", ""];
        if (_resolvedOrgID isEqualTo "") exitWith { _result };

        private _org = EGVAR(org,OrgStore) call ["loadById", [_resolvedOrgID]];
        private _memberUids = [];
        if (_org isNotEqualTo createHashMap) then {
            private _members = _org getOrDefault ["members", createHashMap];
            if (_members isEqualType createHashMap) then {
                _memberUids = keys _members;
            };
            if (_requesterUid isNotEqualTo "" && { !(_requesterUid in _memberUids) }) then {
                _memberUids pushBack _requesterUid;
            };
        };

        _result set ["requesterUid", _requesterUid];
        _result set ["orgID", _resolvedOrgID];
        _result set ["memberUids", _memberUids];
        _result
    }],
    ["incrementDefuseCount", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { 0 };

        ["task:defuse:increment", [_taskID]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];

        if !_isSuccess exitWith { 0 };
        if !(_result isEqualType "") exitWith { 0 };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Task extension call 'task:defuse:increment' failed: %1", _result]] call EFUNC(common,log);
            0
        };

        parseNumber _result
    }],
    ["getDefuseCount", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { 0 };

        ["task:defuse:get", [_taskID]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !_isSuccess exitWith { 0 };
        if !(_result isEqualType "") exitWith { 0 };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Task extension call 'task:defuse:get' failed: %1", _result]] call EFUNC(common,log);
            0
        };

        parseNumber _result
    }],
    ["notifyParticipants", compileFinal {
        params [
            ["_taskID", "", [""]],
            ["_type", "info", [""]],
            ["_title", "Tasks", [""]],
            ["_message", "", [""]]
        ];

        if (_taskID isEqualTo "" || { _message isEqualTo "" }) exitWith { false };

        private _participantRegistry = _self getOrDefault ["participantRegistry", createHashMap];
        private _participantSnapshots = +(_participantRegistry getOrDefault [_taskID, createHashMap]);
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
    }],
    ["clearTask", compileFinal {
        params [["_taskID", "", [""]]];

        if (_taskID isEqualTo "") exitWith { false };

        _self call ["emitTaskLifecycleEvent", ["task.cleared", _taskID, "cleared", createHashMap]];

        private _participantRegistry = _self getOrDefault ["participantRegistry", createHashMap];
        _participantRegistry deleteAt _taskID;
        _self set ["participantRegistry", _participantRegistry];

        private _lifecycleRegistry = _self getOrDefault ["taskLifecycleRegistry", createHashMap];
        _lifecycleRegistry deleteAt _taskID;
        _self set ["taskLifecycleRegistry", _lifecycleRegistry];

        _self call ["callTaskState", ["task:clear", [_taskID], false]];
        _self call ["clearTaskEntities", [_taskID]];
        true
    }],
    ["applyRatingOutcome", compileFinal {
        params [["_taskID", "", [""]], ["_delta", 0, [0]]];

        private _emitRatingEvent = {
            params [["_eventName", "", [""]], ["_payload", createHashMap, [createHashMap]]];

            if (_eventName isEqualTo "" || { isNil QEGVAR(common,EventBus) }) exitWith { createHashMap };

            private _eventPayload = +_payload;
            _eventPayload set ["taskID", _taskID];
            _eventPayload set ["ratingDelta", _delta];

            EGVAR(common,EventBus) call ["emit", [
                _eventName,
                _eventPayload,
                createHashMapFromArray [["source", "task"]]
            ]]
        };

        private _result = createHashMapFromArray [
            ["participantUids", []],
            ["orgIds", []],
            ["contributions", createHashMap],
            ["success", true],
            ["mutationFailures", []],
            ["persistenceFailures", []],
            ["message", ""]
        ];

        if (_taskID isEqualTo "" || { _delta isEqualTo 0 }) exitWith { _result };

        private _participantRegistry = _self getOrDefault ["participantRegistry", createHashMap];
        private _participantSnapshots = +(_participantRegistry getOrDefault [_taskID, createHashMap]);
        if (_participantSnapshots isEqualTo createHashMap) exitWith { _result };

        private _rewardContext = _self call ["resolveRewardContext", [_taskID]];
        private _participantUids = keys _participantSnapshots;
        if (_participantUids isEqualTo [] && { _delta > 0 }) then {
            private _requesterUid = _rewardContext getOrDefault ["requesterUid", ""];
            if (_requesterUid isNotEqualTo "") then {
                private _requesterPlayer = [_requesterUid] call EFUNC(common,getPlayer);
                if (!isNull _requesterPlayer) then {
                    _participantUids pushBack _requesterUid;
                    _participantSnapshots set [_requesterUid, createHashMapFromArray [
                        ["startRating", rating _requesterPlayer]
                    ]];
                    _participantRegistry set [_taskID, _participantSnapshots];
                    _self set ["participantRegistry", _participantRegistry];
                    ["WARNING", format ["Task %1 had no tracked participants at payout time; falling back to requester %2 for personal earnings.", _taskID, _requesterUid]] call EFUNC(common,log);
                };
            };
        };
        if (_participantUids isEqualTo []) exitWith {
            _result set ["success", false];
            _result set ["message", "No task participants were available for rating outcome."];
            ["task.rating.failed", createHashMapFromArray [
                ["participantUids", []],
                ["orgIds", []],
                ["contributions", createHashMap],
                ["mutationFailures", []],
                ["persistenceFailures", []],
                ["message", _result get "message"]
            ]] call _emitRatingEvent;
            _result
        };

        private _orgIds = [];
        private _contributions = createHashMap;
        private _totalContribution = 0;
        private _mutationFailures = [];
        private _persistenceFailures = [];

        if (_delta > 0) then {
            {
                private _uid = _x;
                private _player = [_uid] call EFUNC(common,getPlayer);
                if (isNull _player) then { continue; };

                _contributions set [_uid, 1];
                _totalContribution = _totalContribution + 1;
            } forEach _participantUids;
        };

        if (_totalContribution <= 0) exitWith {
            _result set ["success", false];
            _result set ["message", "No eligible participant contribution was available for rating outcome."];
            ["task.rating.failed", createHashMapFromArray [
                ["participantUids", +_participantUids],
                ["orgIds", +_orgIds],
                ["contributions", +_contributions],
                ["mutationFailures", []],
                ["persistenceFailures", []],
                ["message", _result get "message"]
            ]] call _emitRatingEvent;
            _self call ["clearTask", [_taskID]];
            _result
        };

        {
            private _uid = _x;
            private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_uid, ""]];
            if (_orgID isNotEqualTo "") then {
                _orgIds pushBackUnique _orgID;
            };

            if (_delta > 0) then {
                private _contribution = _contributions getOrDefault [_uid, 0];
                if (_contribution <= 0) then { continue; };

                private _account = EGVAR(bank,BankStore) call ["get", [_uid, ""]];
                if (_account isEqualTo createHashMap) then {
                    _account = EGVAR(bank,BankStore) call ["init", [_uid]];
                };

                if (_account isNotEqualTo createHashMap) then {
                    private _earnings = _account getOrDefault ["earnings", 0];
                    private _earningsDelta = round ((_delta * _contribution) / _totalContribution);
                    if (_earningsDelta <= 0) then { continue; };

                    private _patch = EGVAR(bank,BankStore) call [
                        "mset",
                        [
                            _uid,
                            createHashMapFromArray [["earnings", (_earnings + _earningsDelta)]],
                            false
                        ]
                    ];
                    if !(_patch isEqualType createHashMap) then { continue; };
                    if (_patch isEqualTo createHashMap) then { continue; };

                    if (isNil QEGVAR(common,EventBus)) then {
                        EGVAR(bank,BankMessenger) call ["sendAccountSync", [_uid, _patch]];
                    } else {
                        EGVAR(common,EventBus) call ["emit", [
                            "bank.account.sync.requested",
                            createHashMapFromArray [
                                ["uid", _uid],
                                ["account", +_patch]
                            ],
                            createHashMapFromArray [["source", "task"]]
                        ]];
                    };

                    if ((EGVAR(bank,BankStore) call ["save", [_uid]]) isEqualTo createHashMap) then {
                        _persistenceFailures pushBackUnique format ["bank:%1", _uid];
                        ["ERROR", format ["Task %1 updated bank earnings for %2, but durable save failed.", _taskID, _uid]] call EFUNC(common,log);
                    };
                };
            };
        } forEach _participantUids;

        private _ownerOrgID = _rewardContext getOrDefault ["orgID", ""];
        if (_ownerOrgID isNotEqualTo "") then {
            private _org = EGVAR(org,OrgStore) call ["loadById", [_ownerOrgID]];

            if (_org isNotEqualTo createHashMap) then {
                private _reputation = _org getOrDefault ["reputation", 0];
                private _nextReputation = round (_reputation + _delta);
                _org set ["reputation", _nextReputation];
                private _updatedOrg = EGVAR(org,OrgStore) call [
                    "callHotOrg",
                    [
                        "org:hot:override",
                        [_ownerOrgID, toJSON _org]
                    ]
                ];

                if (_updatedOrg isNotEqualTo createHashMap) then {
                    private _patch = createHashMapFromArray [["reputation", _nextReputation]];
                    private _memberUids = _rewardContext getOrDefault ["memberUids", []];
                    if (isNil QEGVAR(common,EventBus)) then {
                        {
                            private _player = [_x] call EFUNC(common,getPlayer);
                            if (isNull _player) then { continue; };
                            [CRPC(org,responseSyncOrg), [_patch], _player] call CFUNC(targetEvent);
                        } forEach _memberUids;
                    } else {
                        EGVAR(common,EventBus) call ["emit", [
                            "org.sync.requested",
                            createHashMapFromArray [
                                ["orgID", _ownerOrgID],
                                ["memberUids", +_memberUids],
                                ["patch", +_patch]
                            ],
                            createHashMapFromArray [["source", "task"]]
                        ]];
                    };

                    _orgIds = [_ownerOrgID];
                    if ((EGVAR(org,OrgStore) call ["saveById", [_ownerOrgID]]) isEqualTo createHashMap) then {
                        _persistenceFailures pushBackUnique format ["organization:%1", _ownerOrgID];
                        ["ERROR", format ["Task %1 updated reputation for organization %2, but durable save failed.", _taskID, _ownerOrgID]] call EFUNC(common,log);
                    };
                } else {
                    ["ERROR", format ["Failed to update organization %1 reputation for task %2.", _ownerOrgID, _taskID]] call EFUNC(common,log);
                    _mutationFailures pushBackUnique format ["organization:%1", _ownerOrgID];
                };
            };
        };

        _result set ["participantUids", _participantUids];
        _result set ["orgIds", _orgIds];
        _result set ["contributions", _contributions];
        _result set ["success", (_mutationFailures isEqualTo []) && { _persistenceFailures isEqualTo [] }];
        _result set ["mutationFailures", _mutationFailures];
        _result set ["persistenceFailures", _persistenceFailures];
        if (_mutationFailures isNotEqualTo [] || { _persistenceFailures isNotEqualTo [] }) then {
            private _messageParts = [];
            if (_mutationFailures isNotEqualTo []) then {
                _messageParts pushBack format ["mutation failures: %1", _mutationFailures joinString ", "];
            };
            if (_persistenceFailures isNotEqualTo []) then {
                _messageParts pushBack format ["persistence failures: %1", _persistenceFailures joinString ", "];
            };
            _result set ["message", _messageParts joinString "; "];
        };

        private _eventName = ["task.rating.failed", "task.rating.applied"] select (_result getOrDefault ["success", false]);
        [_eventName, createHashMapFromArray [
            ["participantUids", +(_result getOrDefault ["participantUids", []])],
            ["orgIds", +(_result getOrDefault ["orgIds", []])],
            ["contributions", +(_result getOrDefault ["contributions", createHashMap])],
            ["mutationFailures", +(_result getOrDefault ["mutationFailures", []])],
            ["persistenceFailures", +(_result getOrDefault ["persistenceFailures", []])],
            ["message", _result getOrDefault ["message", ""]]
        ]] call _emitRatingEvent;

        _result
    }]
]];

GVAR(TaskStore)
