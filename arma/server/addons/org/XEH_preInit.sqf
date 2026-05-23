#include "script_component.hpp"

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// private _category = [QUOTE(MOD_NAME), LLSTRING(displayName)];

GVAR(RequestOrgSync) = {
    params [["_memberUids", [], [[]]], ["_patch", createHashMap, [createHashMap]]];

    if (_memberUids isEqualTo []) exitWith {};

    if (isNil QEGVAR(common,EventBus)) exitWith {
        {
            private _memberPlayer = [_x] call EFUNC(common,getPlayer);
            if (_memberPlayer isNotEqualTo objNull) then {
                [CRPC(org,responseSyncOrg), [_patch], _memberPlayer] call CFUNC(targetEvent);
            };
        } forEach _memberUids;
    };

    EGVAR(common,EventBus) call ["emit", [
        "org.sync.requested",
        createHashMapFromArray [
            ["memberUids", +_memberUids],
            ["patch", +_patch]
        ],
        createHashMapFromArray [["source", "org"]]
    ]];
};

GVAR(RequestNotification) = {
    params [
        ["_uids", [], [[]]],
        ["_type", "info", [""]],
        ["_title", "", [""]],
        ["_message", "", [""]],
        ["_duration", -1, [0]]
    ];

    if (_uids isEqualTo [] || { _message isEqualTo "" }) exitWith {};

    if (isNil QEGVAR(common,EventBus)) exitWith {
        private _params = [_type, _title, _message];
        if (_duration >= 0) then { _params pushBack _duration; };
        {
            private _player = [_x] call EFUNC(common,getPlayer);
            if (_player isNotEqualTo objNull) then {
                [CRPC(notifications,recieveNotification), _params, _player] call CFUNC(targetEvent);
            };
        } forEach _uids;
    };

    private _payload = createHashMapFromArray [
        ["uids", +_uids],
        ["notificationType", _type],
        ["title", _title],
        ["message", _message]
    ];
    if (_duration >= 0) then { _payload set ["duration", _duration]; };

    EGVAR(common,EventBus) call ["emit", [
        "notification.requested",
        _payload,
        createHashMapFromArray [["source", "org"]]
    ]];
};

[QGVAR(requestInitOrg), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Org] Empty/Invalid UID!" };

    GVAR(OrgStore) call ["init", [_uid]];
}] call CFUNC(addEventHandler);

[QGVAR(requestHydrateOrg), {
    params [["_uid", "", [""]], ["_bridgeEvent", "org::sync", [""]]];

    if (_uid isEqualTo "") exitWith { diag_log "[FORGE:Server:Org] Empty/Invalid UID!" };

    if !(_bridgeEvent in ["org::login::success", "org::create::success", "org::sync"]) then {
        _bridgeEvent = "org::sync";
    };

    private _player = [_uid] call EFUNC(common,getPlayer);
    if (_player isEqualTo objNull) exitWith {};

    private _payload = GVAR(OrgStore) call ["buildPortalPayload", [_uid]];
    if (_payload isEqualTo createHashMap) exitWith {};

    [CRPC(org,responseHydrateOrg), [_payload, _bridgeEvent], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestCreateOrg), {
    params [["_uid", "", [""]], ["_orgName", "", [""]]];

    if (_uid isEqualTo "" || { _orgName isEqualTo "" }) exitWith {
        diag_log "[FORGE:Server:Org] Empty/Invalid UID or Organization Name!"
    };

    private _player = [_uid] call EFUNC(common,getPlayer);
    private _result = GVAR(OrgStore) call ["register", [_uid, _orgName]];

    if (_result getOrDefault ["success", false]) then {
        private _actorPatch = _result getOrDefault ["actorPatch", createHashMap];
        if (_actorPatch isNotEqualTo createHashMap) then {
            [CRPC(actor,responseSyncActor), [_actorPatch], _player] call CFUNC(targetEvent);
        };
    };

    [CRPC(org,responseCreateOrg), [_result], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestAssignCreditLine), {
    params [
        ["_uid", "", [""]],
        ["_memberUid", "", [""]],
        ["_memberName", "", [""]],
        ["_amount", 0, [0]]
    ];

    if (_uid isEqualTo "" || { _memberUid isEqualTo "" } || { _amount <= 0 }) exitWith {
        diag_log "[FORGE:Server:Org] Invalid credit line request payload!"
    };

    private _requester = [_uid] call EFUNC(common,getPlayer);
    if (_requester isEqualTo objNull) exitWith {};

    private _result = GVAR(OrgStore) call ["assignCreditLine", [_uid, _memberUid, _memberName, _amount]];
    if (_result getOrDefault ["success", false]) then {
        private _patch = _result getOrDefault ["patch", createHashMap];

        if (_patch isNotEqualTo createHashMap) then {
            [_result getOrDefault ["memberUids", []], _patch] call GVAR(RequestOrgSync);
        };
    };

    [CRPC(org,responseCreditLine), [createHashMapFromArray [
        ["success", _result getOrDefault ["success", false]],
        ["message", _result getOrDefault ["message", "Unable to assign credit line."]]
    ]], _requester] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestPayroll), {
    params [
        ["_uid", "", [""]],
        ["_amount", 0, [0]]
    ];

    if (_uid isEqualTo "" || { _amount <= 0 }) exitWith {
        diag_log "[FORGE:Server:Org] Invalid payroll request payload!"
    };

    private _requester = [_uid] call EFUNC(common,getPlayer);
    if (_requester isEqualTo objNull) exitWith {};

    private _result = GVAR(OrgStore) call ["runPayroll", [_uid, _amount]];
    if (_result getOrDefault ["success", false]) then {
        private _syncTargets = +(_result getOrDefault ["memberUids", []]);
        _syncTargets pushBackUnique _uid;
        [_syncTargets, createHashMap] call GVAR(RequestOrgSync);
    };

    [CRPC(org,responseTreasuryAction), [createHashMapFromArray [
        ["success", _result getOrDefault ["success", false]],
        ["message", _result getOrDefault ["message", "Unable to run payroll."]]
    ]], _requester] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestTreasuryTransfer), {
    params [
        ["_uid", "", [""]],
        ["_memberUid", "", [""]],
        ["_memberName", "", [""]],
        ["_amount", 0, [0]]
    ];

    if (_uid isEqualTo "" || { _memberUid isEqualTo "" } || { _amount <= 0 }) exitWith {
        diag_log "[FORGE:Server:Org] Invalid treasury transfer request payload!"
    };

    private _requester = [_uid] call EFUNC(common,getPlayer);
    if (_requester isEqualTo objNull) exitWith {};

    private _result = GVAR(OrgStore) call ["transferFunds", [_uid, _memberUid, _memberName, _amount]];
    if (_result getOrDefault ["success", false]) then {
        private _syncTargets = +(_result getOrDefault ["memberUids", []]);
        _syncTargets pushBackUnique _uid;
        [_syncTargets, createHashMap] call GVAR(RequestOrgSync);
    };

    [CRPC(org,responseTreasuryAction), [createHashMapFromArray [
        ["success", _result getOrDefault ["success", false]],
        ["message", _result getOrDefault ["message", "Unable to send funds."]]
    ]], _requester] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestInviteOrgMember), {
    params [["_uid", "", [""]], ["_targetUid", "", [""]], ["_targetName", "", [""]]];

    if (_uid isEqualTo "" || { _targetUid isEqualTo "" }) exitWith {
        diag_log "[FORGE:Server:Org] Invalid org invite request payload!"
    };

    private _requester = [_uid] call EFUNC(common,getPlayer);
    if (_requester isEqualTo objNull) exitWith {};

    private _result = GVAR(OrgStore) call ["inviteMember", [_uid, _targetUid, _targetName]];
    if (_result getOrDefault ["success", false]) then {
        private _resolvedTargetUid = _result getOrDefault ["targetUid", _targetUid];
        [[_uid, _resolvedTargetUid], createHashMap] call GVAR(RequestOrgSync);
        [[_resolvedTargetUid], "info", "Organization Invite", "You received an organization invite. Open the organization portal to accept or decline it.", 7000] call GVAR(RequestNotification);
    };

    [CRPC(org,responseInviteOrg), [createHashMapFromArray [
        ["success", _result getOrDefault ["success", false]],
        ["message", _result getOrDefault ["message", "Unable to send organization invite."]]
    ]], _requester] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestAcceptOrgInvite), {
    params [["_uid", "", [""]], ["_orgID", "", [""]]];

    if (_uid isEqualTo "" || { _orgID isEqualTo "" }) exitWith {
        diag_log "[FORGE:Server:Org] Invalid accept invite request payload!"
    };

    private _player = [_uid] call EFUNC(common,getPlayer);
    if (_player isEqualTo objNull) exitWith {};

    private _result = GVAR(OrgStore) call ["acceptInvite", [_uid, _orgID]];
    if (_result getOrDefault ["success", false]) then {
        private _actorPatch = _result getOrDefault ["actorPatch", createHashMap];
        if (_actorPatch isNotEqualTo createHashMap) then {
            [CRPC(actor,responseSyncActor), [_actorPatch], _player] call CFUNC(targetEvent);
        };

        private _syncTargets = [_uid];
        {
            private _orgData = GVAR(OrgStore) call ["loadById", [_x]];
            if !(_orgData isEqualType createHashMap) then { continue; };

            {
                private _memberUid = _y getOrDefault ["uid", ""];
                if (_memberUid isNotEqualTo "") then {
                    _syncTargets pushBackUnique _memberUid;
                };
            } forEach (_orgData getOrDefault ["members", createHashMap]);
        } forEach (_result getOrDefault ["affectedOrgIds", []]);

        [_syncTargets, createHashMap] call GVAR(RequestOrgSync);
    };

    [CRPC(org,responseInviteDecision), [createHashMapFromArray [
        ["success", _result getOrDefault ["success", false]],
        ["message", _result getOrDefault ["message", "Unable to accept organization invite."]],
        ["action", "accept"]
    ]], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestDeclineOrgInvite), {
    params [["_uid", "", [""]], ["_orgID", "", [""]]];

    if (_uid isEqualTo "" || { _orgID isEqualTo "" }) exitWith {
        diag_log "[FORGE:Server:Org] Invalid decline invite request payload!"
    };

    private _player = [_uid] call EFUNC(common,getPlayer);
    if (_player isEqualTo objNull) exitWith {};

    private _result = GVAR(OrgStore) call ["declineInvite", [_uid, _orgID]];
    if (_result getOrDefault ["success", false]) then {
        private _syncTargets = [_uid];
        {
            private _orgData = GVAR(OrgStore) call ["loadById", [_x]];
            if !(_orgData isEqualType createHashMap) then { continue; };

            {
                private _memberUid = _y getOrDefault ["uid", ""];
                if (_memberUid isNotEqualTo "") then {
                    _syncTargets pushBackUnique _memberUid;
                };
            } forEach (_orgData getOrDefault ["members", createHashMap]);
        } forEach (_result getOrDefault ["affectedOrgIds", []]);

        [_syncTargets, createHashMap] call GVAR(RequestOrgSync);
    };

    [CRPC(org,responseInviteDecision), [createHashMapFromArray [
        ["success", _result getOrDefault ["success", false]],
        ["message", _result getOrDefault ["message", "Unable to decline organization invite."]],
        ["action", "decline"]
    ]], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestLeaveOrg), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith {
        diag_log "[FORGE:Server:Org] Empty/Invalid UID for leave request!"
    };

    private _player = [_uid] call EFUNC(common,getPlayer);
    if (_player isEqualTo objNull) exitWith {};

    private _result = GVAR(OrgStore) call ["leave", [_uid]];
    if (_result getOrDefault ["success", false]) then {
        private _actorPatch = _result getOrDefault ["actorPatch", createHashMap];
        if (_actorPatch isNotEqualTo createHashMap) then {
            [CRPC(actor,responseSyncActor), [_actorPatch], _player] call CFUNC(targetEvent);
        };

        GVAR(OrgStore) call ["init", [_uid]];

        private _notificationParams = _result getOrDefault ["notification", []];
        if (_notificationParams isEqualType [] && { count _notificationParams > 0 }) then {
            private _duration = if ((count _notificationParams) > 3) then { _notificationParams # 3 } else { -1 };
            [[_uid], _notificationParams # 0, _notificationParams # 1, _notificationParams # 2, _duration] call GVAR(RequestNotification);
        };
    };

    [CRPC(org,responseLeaveOrg), [createHashMapFromArray [
        ["success", _result getOrDefault ["success", false]],
        ["message", _result getOrDefault ["message", "Unable to leave the organization."]]
    ]], _player] call CFUNC(targetEvent);
}] call CFUNC(addEventHandler);

[QGVAR(requestDisbandOrg), {
    params [["_uid", "", [""]]];

    if (_uid isEqualTo "") exitWith {
        diag_log "[FORGE:Server:Org] Empty/Invalid UID for disband request!"
    };

    private _requester = [_uid] call EFUNC(common,getPlayer);
    if (_requester isEqualTo objNull) exitWith {};

    private _result = GVAR(OrgStore) call ["disband", [_uid]];
    if !(_result getOrDefault ["success", false]) exitWith {
        [CRPC(org,responseDisbandOrg), [createHashMapFromArray [
            ["success", false],
            ["message", _result getOrDefault ["message", "Failed to disband organization."]],
            ["requester", true]
        ]], _requester] call CFUNC(targetEvent);
    };

    {
        [_x, _result] call {
            params [["_member", createHashMap, [createHashMap]], ["_disbandResult", createHashMap, [createHashMap]]];

            private _memberUid = _member getOrDefault ["uid", ""];
            if (_memberUid isEqualTo "") exitWith {};

            private _memberPlayer = [_memberUid] call EFUNC(common,getPlayer);
            if (_memberPlayer isEqualTo objNull) exitWith {};

            private _actorPatch = _member getOrDefault ["actorPatch", createHashMap];
            if (_actorPatch isNotEqualTo createHashMap) then {
                [CRPC(actor,responseSyncActor), [_actorPatch], _memberPlayer] call CFUNC(targetEvent);
            };

            GVAR(OrgStore) call ["init", [_memberUid]];
            [CRPC(org,responseDisbandOrg), [createHashMapFromArray [
                ["success", true],
                ["message", _member getOrDefault ["message", _disbandResult getOrDefault ["message", "Organization disbanded."]]],
                ["requester", _member getOrDefault ["requester", false]]
            ]], _memberPlayer] call CFUNC(targetEvent);

            private _notificationParams = _member getOrDefault ["notification", []];
            if (_notificationParams isEqualType [] && { count _notificationParams > 0 }) then {
                private _duration = if ((count _notificationParams) > 3) then { _notificationParams # 3 } else { -1 };
                [[_memberUid], _notificationParams # 0, _notificationParams # 1, _notificationParams # 2, _duration] call GVAR(RequestNotification);
            };
        };
    } forEach (_result getOrDefault ["members", []]);
}] call CFUNC(addEventHandler);
