#include "..\script_component.hpp"

/*
 * File: fnc_initGroupRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-30
 * Public: No
 *
 * Description:
 * Initializes the CAD group repository: live player groups, their members,
 * and the role/status profile set by the group leader or a dispatcher.
 *
 * Each tracked group gets a stable CAD ID stored on the group itself, so the
 * ID and the role/status profile survive leader changes. Profiles live on the
 * group object and are lost only when the group is deleted.
 *
 * Tracked sides default to [west] and can be overridden by the mission with
 * `missionNamespace setVariable ["forge_server_cad_sides", [west, independent]]`.
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
        _self set ["validStatuses", ["available", "en_route", "on_task", "holding", "danger", "unavailable"]];
        _self set ["validRoles", ["infantry", "recon", "armor", "air", "logistics", "support"]];
        _self set ["groupSequence", 0];
    }],
    ["getTrackedSides", compileFinal {
        private _sides = missionNamespace getVariable [QGVAR(sides), [west]];
        if !(_sides isEqualType []) then { _sides = [west]; };
        _sides
    }],
    ["getPlayerMembers", compileFinal {
        params [["_group", grpNull, [grpNull]]];

        if (isNull _group) exitWith { [] };
        (units _group) select { isPlayer _x }
    }],
    ["isTrackedGroup", compileFinal {
        params [["_group", grpNull, [grpNull]]];

        if (isNull _group) exitWith { false };
        if !((side _group) in (_self call ["getTrackedSides", []])) exitWith { false };
        (_self call ["getPlayerMembers", [_group]]) isNotEqualTo []
    }],
    ["ensureGroupId", compileFinal {
        params [["_group", grpNull, [grpNull]]];

        if (isNull _group) exitWith { "" };

        private _groupID = _group getVariable [QGVAR(groupId), ""];
        if (_groupID isNotEqualTo "") exitWith { _groupID };

        private _sequence = (_self getOrDefault ["groupSequence", 0]) + 1;
        _self set ["groupSequence", _sequence];
        _groupID = format ["grp:%1", _sequence];
        _group setVariable [QGVAR(groupId), _groupID];
        _groupID
    }],
    ["findGroup", compileFinal {
        params [["_groupID", "", [""]]];

        if (_groupID isEqualTo "") exitWith { grpNull };

        private _index = allGroups findIf { (_x getVariable [QGVAR(groupId), ""]) isEqualTo _groupID };
        if (_index < 0) exitWith { grpNull };
        allGroups # _index
    }],
    ["resolveLeader", compileFinal {
        params [["_group", grpNull, [grpNull]]];

        if (isNull _group) exitWith { objNull };

        private _leader = leader _group;
        if (!isNull _leader && { isPlayer _leader }) exitWith { _leader };

        private _members = _self call ["getPlayerMembers", [_group]];
        if (_members isEqualTo []) exitWith { objNull };
        _members # 0
    }],
    ["getPlayerGroupId", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { "" };

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { "" };

        private _group = group _player;
        if !(_self call ["isTrackedGroup", [_group]]) exitWith { "" };
        _self call ["ensureGroupId", [_group]]
    }],
    ["isGroupLeader", compileFinal {
        params [["_uid", "", [""]], ["_groupID", "", [""]]];

        if (_uid isEqualTo "" || { _groupID isEqualTo "" }) exitWith { false };

        private _leader = _self call ["resolveLeader", [_self call ["findGroup", [_groupID]]]];
        !isNull _leader && { (getPlayerUID _leader) isEqualTo _uid }
    }],
    ["buildGroupRecord", compileFinal {
        params [
            ["_group", grpNull, [grpNull]],
            ["_taskByGroup", createHashMap, [createHashMap]]
        ];

        if !(_self call ["isTrackedGroup", [_group]]) exitWith { createHashMap };

        private _groupID = _self call ["ensureGroupId", [_group]];
        private _leader = _self call ["resolveLeader", [_group]];
        private _leaderUid = getPlayerUID _leader;
        private _members = _self call ["getPlayerMembers", [_group]];
        private _task = _taskByGroup getOrDefault [_groupID, createHashMap];

        createHashMapFromArray [
            ["groupId", _groupID],
            ["callsign", [groupId _group, _groupID] select ((groupId _group) isEqualTo "")],
            ["side", str side _group],
            ["leaderUid", _leaderUid],
            ["leaderName", name _leader],
            ["memberUids", _members apply { getPlayerUID _x }],
            ["members", _members apply {
                createHashMapFromArray [
                    ["uid", getPlayerUID _x],
                    ["name", name _x],
                    ["lifeState", toLowerANSI (lifeState _x)],
                    ["isLeader", _x isEqualTo _leader],
                    ["position", getPosATL _x]
                ]
            }],
            ["orgId", EGVAR(actor,ActorStore) call ["getOrganization", [_leaderUid]]],
            ["role", _group getVariable [QGVAR(role), "infantry"]],
            ["status", _group getVariable [QGVAR(status), "available"]],
            ["position", getPosATL _leader],
            ["currentTaskId", _task getOrDefault ["taskId", ""]],
            ["currentTaskTitle", _task getOrDefault ["title", ""]],
            ["lastUpdate", serverTime]
        ]
    }],
    ["buildGroups", compileFinal {
        params [["_taskByGroup", createHashMap, [createHashMap]]];

        private _groups = [];
        {
            private _record = _self call ["buildGroupRecord", [_x, _taskByGroup]];
            if (_record isNotEqualTo createHashMap) then { _groups pushBack _record; };
        } forEach allGroups;

        _groups
    }],
    ["getGroupRecord", compileFinal {
        params [["_groupID", "", [""]]];

        _self call ["buildGroupRecord", [_self call ["findGroup", [_groupID]], createHashMap]]
    }],
    ["updateProfile", compileFinal {
        params [
            ["_requesterUid", "", [""]],
            ["_groupID", "", [""]],
            ["_status", "", [""]],
            ["_role", "", [""]]
        ];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to update group profile."],
            ["changed", false],
            ["group", createHashMap]
        ];

        private _finalStatus = toLowerANSI _status;
        private _finalRole = toLowerANSI _role;

        if (_finalStatus isEqualTo "" && { _finalRole isEqualTo "" }) exitWith {
            _result set ["message", "No group changes were provided."];
            _result
        };
        if (_finalStatus isNotEqualTo "" && { !(_finalStatus in (_self get "validStatuses")) }) exitWith {
            _result set ["message", "Invalid group status."];
            _result
        };
        if (_finalRole isNotEqualTo "" && { !(_finalRole in (_self get "validRoles")) }) exitWith {
            _result set ["message", "Invalid group role."];
            _result
        };

        private _group = _self call ["findGroup", [_groupID]];
        if !(_self call ["isTrackedGroup", [_group]]) exitWith {
            _result set ["message", "Group could not be resolved."];
            _result
        };

        private _permissionService = _self getOrDefault ["permissionService", createHashMap];
        private _isAuthorized = (_self call ["isGroupLeader", [_requesterUid, _groupID]])
            || { _permissionService call ["canDispatch", [_requesterUid]] };
        if !_isAuthorized exitWith {
            _result set ["message", "You are not authorized to update that group."];
            _result
        };

        private _changed = false;
        if (_finalStatus isNotEqualTo "" && { (_group getVariable [QGVAR(status), "available"]) isNotEqualTo _finalStatus }) then {
            _group setVariable [QGVAR(status), _finalStatus];
            _changed = true;
        };
        if (_finalRole isNotEqualTo "" && { (_group getVariable [QGVAR(role), "infantry"]) isNotEqualTo _finalRole }) then {
            _group setVariable [QGVAR(role), _finalRole];
            _changed = true;
        };

        _result set ["success", true];
        _result set ["changed", _changed];
        _result set ["message", ["Group profile already up to date.", "Group profile updated."] select _changed];
        _result set ["group", _self call ["buildGroupRecord", [_group, createHashMap]]];
        _result
    }]
];

createHashMapObject [GVAR(GroupRepositoryBaseClass)]
