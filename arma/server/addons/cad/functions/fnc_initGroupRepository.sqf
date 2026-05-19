#include "..\script_component.hpp"

/*
 * File: fnc_initGroupRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-30
 * Public: No
 *
 * Description:
 * Initializes the CAD group repository for live group state, roles,
 * and dispatcher/leader-managed group profiles.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * CAD group repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_cad_fnc_initGroupRepository
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(GroupRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "CadGroupRepositoryBaseClass"],
    ["#create", compileFinal {
        _self set ["validStatuses", [
            "available",
            "en_route",
            "on_task",
            "holding",
            "danger",
            "unavailable"
        ]];
        _self set ["validRoles", [
            "infantry",
            "recon",
            "armor",
            "air",
            "logistics",
            "support"
        ]];
    }],
    ["resolveGroupId", compileFinal {
        params [["_group", grpNull, [grpNull]]];

        if (isNull _group) exitWith { "" };

        private _leader = leader _group;
        private _leaderUid = if (isNull _leader) then { "" } else { getPlayerUID _leader };
        if (_leaderUid isNotEqualTo "") exitWith { format ["group:%1", _leaderUid] };

        private _groupLabel = groupId _group;
        if (_groupLabel isNotEqualTo "") exitWith { format ["group:%1", _groupLabel] };

        str _group
    }],
    ["getCurrentTaskIdForGroup", compileFinal {
        params [["_groupID", "", [""]]];

        if (_groupID isEqualTo "") exitWith { "" };

        private _assignmentRepository = _self getOrDefault ["assignmentRepository", createHashMap];
        if (_assignmentRepository isEqualTo createHashMap) exitWith { "" };

        _assignmentRepository call ["getCurrentTaskIdForGroup", [_groupID]]
    }],
    ["syncGroups", compileFinal {
        private _liveGroups = [];

        {
            private _group = _x;
            if (side _group isNotEqualTo west) then { continue; };

            private _members = allPlayers select { group _x isEqualTo _group };
            if (_members isEqualTo []) then { continue; };

            private _leader = leader _group;
            if (isNull _leader || { !isPlayer _leader }) then {
                _leader = _members # 0;
            };

            private _groupID = _self call ["resolveGroupId", [_group]];
            if (_groupID isEqualTo "") then { continue; };

            private _leaderUid = getPlayerUID _leader;
            private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_leaderUid]];
            private _memberUids = [];
            private _memberRoster = [];
            {
                private _memberUid = getPlayerUID _x;
                private _memberState = toLowerANSI (lifeState _x);

                if (_memberUid isNotEqualTo "") then {
                    _memberUids pushBack _memberUid;
                };

                _memberRoster pushBack (createHashMapFromArray [
                    ["uid", _memberUid],
                    ["name", name _x],
                    ["lifeState", _memberState],
                    ["isLeader", _x isEqualTo _leader],
                    ["position", getPosATL _x]
                ]);
            } forEach _members;

            _liveGroups pushBack (createHashMapFromArray [
                ["groupId", _groupID],
                ["callsign", [groupId _group, _groupID] select ((groupId _group) isEqualTo "")],
                ["leaderUid", _leaderUid],
                ["leaderName", name _leader],
                ["memberUids", _memberUids],
                ["members", _memberRoster],
                ["orgId", _orgID],
                ["role", "infantry"],
                ["status", "available"],
                ["position", getPosATL _leader],
                ["currentTaskId", _self call ["getCurrentTaskIdForGroup", [_groupID]]],
                ["lastUpdate", serverTime]
            ]);
        } forEach allGroups;

        private _mergedGroups = _liveGroups;
        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isNotEqualTo createHashMap) then {
            private _buildResult = _persistenceService call ["buildGroups", [_liveGroups]];
            if (_buildResult getOrDefault ["success", false]) then {
                _mergedGroups = +(_buildResult getOrDefault ["data", _liveGroups]);
            };
        };

        private _nextRegistry = createHashMap;
        {
            if !(_x isEqualType createHashMap) then { continue; };
            private _groupID = _x getOrDefault ["groupId", ""];
            if (_groupID isEqualTo "") then { continue; };

            private _groupRecord = +_x;
            _nextRegistry set [_groupID, _groupRecord];
        } forEach _mergedGroups;

        _nextRegistry
    }],
    ["getGroupRecord", compileFinal {
        params [["_groupID", "", [""]]];

        if (_groupID isEqualTo "") exitWith { createHashMap };

        private _groupRegistry = _self call ["syncGroups", []];
        +(_groupRegistry getOrDefault [_groupID, createHashMap])
    }],
    ["getPlayerGroupId", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { "" };

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (_player isEqualTo objNull) exitWith { "" };

        _self call ["resolveGroupId", [group _player]]
    }],
    ["isGroupLeader", compileFinal {
        params [["_uid", "", [""]], ["_groupID", "", [""]]];

        if (_uid isEqualTo "" || { _groupID isEqualTo "" }) exitWith { false };

        private _groupRecord = _self call ["getGroupRecord", [_groupID]];
        (_groupRecord getOrDefault ["leaderUid", ""]) isEqualTo _uid
    }],
    ["buildGroups", compileFinal {
        private _groupRegistry = _self call ["syncGroups", []];
        private _groups = [];

        {
            _groups pushBack +_y;
        } forEach _groupRegistry;

        _groups
    }],
    ["applyGroupProfileUpdate", compileFinal {
        params [
            ["_requesterUid", "", [""]],
            ["_groupID", "", [""]],
            ["_status", "", [""]],
            ["_role", "", [""]],
            ["_mode", "profile", [""]]
        ];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to update group profile."],
            ["changed", false],
            ["group", createHashMap]
        ];

        private _finalStatus = toLowerANSI _status;
        private _finalRole = toLowerANSI _role;
        private _hasStatus = _finalStatus isNotEqualTo "";
        private _hasRole = _finalRole isNotEqualTo "";

        if (_mode isEqualTo "status" && !_hasStatus) exitWith {
            _result set ["message", "Invalid group status."];
            _result
        };

        if (_mode isEqualTo "role" && !_hasRole) exitWith {
            _result set ["message", "Invalid group role."];
            _result
        };

        if (_mode isEqualTo "profile" && !(_hasStatus || _hasRole)) exitWith {
            _result set ["message", "No group changes were provided."];
            _result
        };

        if (_hasStatus && !(_finalStatus in (_self getOrDefault ["validStatuses", []]))) exitWith {
            _result set ["message", "Invalid group status."];
            _result
        };

        if (_hasRole && !(_finalRole in (_self getOrDefault ["validRoles", []]))) exitWith {
            _result set ["message", "Invalid group role."];
            _result
        };

        private _permissionService = _self getOrDefault ["permissionService", createHashMap];
        private _isAuthorized = (_self call ["isGroupLeader", [_requesterUid, _groupID]]) || { _permissionService call ["canDispatch", [_requesterUid]] };
        if !_isAuthorized exitWith {
            _result set ["message", "You are not authorized to update that group."];
            _result
        };

        private _groupRegistry = _self call ["syncGroups", []];
        private _groupRecord = +(_groupRegistry getOrDefault [_groupID, createHashMap]);
        if (_groupRecord isEqualTo createHashMap) exitWith {
            _result set ["message", "Group could not be resolved."];
            _result
        };

        private _didChangeStatus = _hasStatus && { (_groupRecord getOrDefault ["status", ""]) isNotEqualTo _finalStatus };
        private _didChangeRole = _hasRole && { (_groupRecord getOrDefault ["role", ""]) isNotEqualTo _finalRole };
        private _persistenceService = _self getOrDefault ["persistenceService", createHashMap];
        if (_persistenceService isEqualTo createHashMap) exitWith {
            _result set ["message", "CAD extension state is unavailable."];
            _result
        };

        private _updateContext = createHashMapFromArray [
            ["groupId", _groupID],
            ["groupCallsign", _groupRecord getOrDefault ["callsign", _groupID]],
            ["requesterUid", _requesterUid],
            ["currentRole", _groupRecord getOrDefault ["role", "infantry"]],
            ["currentStatus", _groupRecord getOrDefault ["status", "available"]],
            ["role", [_finalRole, ""] select !_hasRole],
            ["status", [_finalStatus, ""] select !_hasStatus],
            ["mode", _mode]
        ];

        private _profileResult = _persistenceService call ["updateGroupProfileFromContext", [_updateContext]];
        if !(_profileResult getOrDefault ["success", false]) exitWith {
            _result set ["message", "CAD extension rejected the group profile update."];
            _result
        };

        private _profileData = +(_profileResult getOrDefault ["data", createHashMap]);
        private _profile = +(_profileData getOrDefault ["profile", createHashMap]);
        if (_profile isEqualTo createHashMap) exitWith {
            _result set ["message", "CAD extension returned an invalid group profile."];
            _result
        };

        _groupRecord set ["role", _profile getOrDefault ["role", _groupRecord getOrDefault ["role", "infantry"]]];
        _groupRecord set ["status", _profile getOrDefault ["status", _groupRecord getOrDefault ["status", "available"]]];
        _groupRecord set ["lastUpdate", serverTime];

        private _activityEntry = +(_profileData getOrDefault ["activity", createHashMap]);
        if (_activityEntry isNotEqualTo createHashMap) then {
            private _activityRepository = _self getOrDefault ["activityRepository", createHashMap];
            _activityRepository call ["appendEntry", [_activityEntry]];
        };

        _result set ["success", true];
        _result set ["message", _profileData getOrDefault ["message", "Group profile updated."]];
        _result set ["changed", _profileData getOrDefault ["changed", (_didChangeStatus || _didChangeRole)]];
        _result set ["group", _groupRecord];
        _result
    }],
    ["updateGroupStatus", compileFinal {
        _self call ["applyGroupProfileUpdate", [_this # 0, _this # 1, _this # 2, "", "status"]]
    }],
    ["updateGroupRole", compileFinal {
        _self call ["applyGroupProfileUpdate", [_this # 0, _this # 1, "", _this # 2, "role"]]
    }],
    ["updateGroupProfile", compileFinal {
        _self call ["applyGroupProfileUpdate", [_this # 0, _this # 1, _this # 2, _this # 3, "profile"]]
    }]
];

createHashMapObject [GVAR(GroupRepositoryBaseClass)]
