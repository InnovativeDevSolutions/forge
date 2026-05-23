#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Task reward and rating outcome service.
 *
 * Resolves task ownership reward context and applies player earnings plus
 * organization reputation outcomes. TaskStore remains the public facade.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Task reward service object <HASHMAP OBJECT>
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(TaskRewardService) = createHashMapObject [[
    ["#type", "TaskRewardService"],
    ["resolveRewardContext", compileFinal {
        params [["_taskID", "", [""]]];

        private _result = createHashMapFromArray [
            ["requesterUid", ""],
            ["orgID", ""],
            ["memberUids", []]
        ];

        if (_taskID isEqualTo "") exitWith { _result };

        private _rewardState = GVAR(TaskStateGateway) call ["callTaskState", ["task:ownership:reward_context", [_taskID], createHashMap]];
        if (_rewardState isEqualTo createHashMap) exitWith { _result };

        private _requesterUid = _rewardState getOrDefault ["requesterUid", ""];
        private _resolvedOrgID = _rewardState getOrDefault ["orgId", ""];
        if (_resolvedOrgID isEqualTo "") exitWith { _result };

        private _org = EGVAR(org,OrgStore) call ["loadById", [_resolvedOrgID]];
        private _memberUids = [];
        if (_org isNotEqualTo createHashMap) then {
            private _members = _org getOrDefault ["members", createHashMap];

            if (_members isEqualType createHashMap) then { _memberUids = keys _members; };
            if (_requesterUid isNotEqualTo "" && { !(_requesterUid in _memberUids) }) then { _memberUids pushBack _requesterUid; };
        };

        _result set ["requesterUid", _requesterUid];
        _result set ["orgID", _resolvedOrgID];
        _result set ["memberUids", _memberUids];
        _result
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

        private _participantSnapshots = GVAR(TaskParticipantTracker) call ["getTaskParticipants", [_taskID]];
        if (_participantSnapshots isEqualTo createHashMap) exitWith { _result };

        private _rewardContext = _self call ["resolveRewardContext", [_taskID]];
        private _participantUids = keys _participantSnapshots;
        if (_participantUids isEqualTo [] && { _delta > 0 }) then {
            private _requesterUid = _rewardContext getOrDefault ["requesterUid", ""];
            if (_requesterUid isNotEqualTo "") then {
                private _requesterPlayer = [_requesterUid] call EFUNC(common,getPlayer);
                if (!isNull _requesterPlayer) then {
                    _participantUids pushBack _requesterUid;
                    _participantSnapshots = GVAR(TaskParticipantTracker) call ["recordParticipant", [_taskID, _requesterUid, createHashMapFromArray [
                        ["startRating", rating _requesterPlayer]
                    ]]];
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
            GVAR(TaskStore) call ["clearTask", [_taskID]];
            _result
        };

        {
            private _uid = _x;
            private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_uid, ""]];
            if (_orgID isNotEqualTo "") then { _orgIds pushBackUnique _orgID; };
            if (_delta > 0) then {
                private _contribution = _contributions getOrDefault [_uid, 0];
                if (_contribution <= 0) then { continue; };

                private _account = EGVAR(bank,BankStore) call ["get", [_uid, ""]];
                if (_account isEqualTo createHashMap) then { _account = EGVAR(bank,BankStore) call ["init", [_uid]]; };
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

GVAR(TaskRewardService)
