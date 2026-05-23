#include "..\script_component.hpp"

/*
 * File: fnc_initPayloadBuilder.sqf
 * Author: IDSolutions
 * Date: 2026-04-02
 * Public: No
 *
 * Description:
 *     Initializes the org payload builder for portal/read-model shaping.
 *     Keeps hydrate construction out of OrgStore so the store can focus on
 *     extension-backed org operations and actor coordination.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(OrgPayloadBuilder) = createHashMapObject [[
    ["#type", "OrgPayloadBuilder"],
    ["resolveOrgForUid", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _orgID = GVAR(OrgStore) call ["resolveOrgIdForUid", [_uid]];
        private _org = GVAR(OrgStore) call ["loadById", [_orgID]];
        if (_org isEqualTo createHashMap) then {
            _org = GVAR(OrgStore) call ["init", [_uid]];
        };

        _org
    }],
    ["resolveOwnerName", compileFinal {
        params [["_ownerUid", "", [""]], ["_uid", "", [""]], ["_playerName", "", [""]], ["_membersRaw", createHashMap, [createHashMap]]];

        private _ownerName = ["", "Server"] select (toLowerANSI _ownerUid isEqualTo "server");
        {
            private _memberData = _y;
            private _memberUid = _memberData getOrDefault ["uid", ""];
            if (_memberUid isEqualTo _ownerUid && { _ownerName isEqualTo "" }) exitWith {
                _ownerName = _memberData getOrDefault ["name", "Unknown"];
            };
        } forEach _membersRaw;

        if (_ownerName isEqualTo "" && { _ownerUid isEqualTo _uid }) then { _ownerName = _playerName; };
        if (_ownerName isEqualTo "" && { _ownerUid isNotEqualTo "" }) then { _ownerName = "Unknown Owner"; };
        if !(_ownerName isEqualType "") then { _ownerName = str _ownerName; };
        _ownerName
    }],
    ["buildMembersList", compileFinal {
        params [["_membersRaw", createHashMap, [createHashMap]], ["_uid", "", [""]], ["_ownerUid", "", [""]]];

        private _sessionRole = "Member";
        private _membersList = [];

        {
            private _memberData = _y;
            private _memberName = _memberData getOrDefault ["name", "Unknown"];
            private _memberUid = _memberData getOrDefault ["uid", ""];

            if (_memberUid isEqualTo _uid) then { _sessionRole = "Member"; };
            if (_memberUid isEqualTo _ownerUid) then { _sessionRole = ["Member", "Leader"] select (_ownerUid isEqualTo _uid); };

            _membersList pushBack [
                ["uid", _memberUid],
                ["name", _memberName]
            ];
        } forEach _membersRaw;

        createHashMapFromArray [
            ["members", _membersList],
            ["sessionRole", _sessionRole]
        ]
    }],
    ["resolveDisplayName", compileFinal {
        params [["_className", "", [""]], ["_configRoots", [], [[]]]];

        if (_className isEqualTo "") exitWith { "" };

        private _displayName = _className;
        {
            private _cfg = _x >> _className;
            if (isClass _cfg) exitWith {
                private _resolvedName = getText (_cfg >> "displayName");
                if (_resolvedName isNotEqualTo "") then { _displayName = _resolvedName; };
            };
        } forEach _configRoots;

        _displayName
    }],
    ["buildAssetsList", compileFinal {
        params [["_assetsRaw", createHashMap, [createHashMap]]];

        private _assetsList = [];
        {
            private _category = _x;
            {
                private _assetData = _y;
                private _className = _assetData getOrDefault ["classname", ""];
                private _displayName = _self call ["resolveDisplayName", [_className, [
                    configFile >> "CfgWeapons",
                    configFile >> "CfgMagazines",
                    configFile >> "CfgVehicles",
                    configFile >> "CfgGlasses"
                ]]];

                _assetsList pushBack [
                    ["name", _displayName],
                    ["type", _assetData getOrDefault ["type", _category]],
                    ["quantity", str (_assetData getOrDefault ["quantity", 0])]
                ];
            } forEach _y;
        } forEach _assetsRaw;

        _assetsList
    }],
    ["buildFleetList", compileFinal {
        params [["_fleetRaw", createHashMap, [createHashMap]]];

        private _fleetList = [];
        {
            private _vehicleData = _y;
            _fleetList pushBack [
                ["name", _vehicleData getOrDefault ["name", "Unknown Vehicle"]],
                ["type", _vehicleData getOrDefault ["type", "other"]],
                ["status", _vehicleData getOrDefault ["status", "Unknown"]],
                ["damage", _vehicleData getOrDefault ["damage", "0%"]]
            ];
        } forEach _fleetRaw;

        _fleetList
    }],
    ["buildCreditLinesList", compileFinal {
        params [["_creditLinesRaw", createHashMap, [createHashMap]]];

        private _creditLinesList = [];
        {
            private _creditLineData = _y;
            private _availableAmount = _creditLineData getOrDefault [
                "available_amount",
                _creditLineData getOrDefault ["amount", 0]
            ];
            _creditLinesList pushBack [
                ["uid", _creditLineData getOrDefault ["uid", _x]],
                ["member", _creditLineData getOrDefault ["name", "Unknown Member"]],
                ["approvedAmount", _creditLineData getOrDefault ["approved_amount", _availableAmount]],
                ["availableAmount", _availableAmount],
                ["outstandingPrincipal", _creditLineData getOrDefault ["outstanding_principal", 0]],
                ["interestRate", _creditLineData getOrDefault ["interest_rate", 0.1]],
                ["amountDue", _creditLineData getOrDefault ["amount_due", 0]],
                ["amount", _availableAmount]
            ];
        } forEach _creditLinesRaw;

        _creditLinesList
    }],
    ["buildPendingInvitesList", compileFinal {
        params [["_pendingInvitesRaw", [], [[]]]];

        private _pendingInvites = [];
        {
            if !(_x isEqualType createHashMap) then { continue; };

            _pendingInvites pushBack [
                ["orgId", _x getOrDefault ["orgId", ""]],
                ["orgName", _x getOrDefault ["orgName", "Unknown Organization"]],
                ["inviterUid", _x getOrDefault ["inviterUid", ""]],
                ["inviterName", _x getOrDefault ["inviterName", "Unknown"]],
                ["targetUid", _x getOrDefault ["targetUid", ""]],
                ["targetName", _x getOrDefault ["targetName", "Unknown"]]
            ];
        } forEach _pendingInvitesRaw;

        _pendingInvites
    }],
    ["buildInviteablePlayers", compileFinal {
        params [
            ["_uid", "", [""]],
            ["_orgID", "", [""]],
            ["_membersRaw", createHashMap, [createHashMap]],
            ["_pendingInvitesRaw", createHashMap, [createHashMap]]
        ];

        private _memberUids = [];
        {
            _memberUids pushBackUnique (_y getOrDefault ["uid", ""]);
        } forEach _membersRaw;

        private _pendingInviteUids = [];
        {
            _pendingInviteUids pushBackUnique (_x);
        } forEach _pendingInvitesRaw;

        private _players = [];
        {
            private _player = _x;
            if (isNull _player) then { continue; };

            private _playerUid = getPlayerUID _player;
            if (_playerUid isEqualTo "" || { _playerUid isEqualTo _uid }) then { continue; };
            if (_playerUid in _memberUids || { _playerUid in _pendingInviteUids }) then { continue; };

            private _playerOrgID = GVAR(OrgStore) call ["resolveOrgIdForUid", [_playerUid]];
            if (_playerOrgID isNotEqualTo "default") then { continue; };

            _players pushBack [
                ["uid", _playerUid],
                ["name", name _player],
                ["orgId", _playerOrgID]
            ];
        } forEach allPlayers;

        _players
    }],
    ["buildPortalPayload", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { createHashMap };

        private _actor = EGVAR(actor,ActorStore) call ["load", [_uid]];
        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_uid]];
        private _org = _self call ["resolveOrgForUid", [_uid]];
        if (_org isEqualTo createHashMap) exitWith { createHashMap };

        private _verifiedOrg = GVAR(OrgStore) call ["ensureMember", [_orgID, _uid, GVAR(OrgStore) call ["resolveActorName", [_uid, _player, _actor]]]];
        if (_verifiedOrg isNotEqualTo createHashMap) then { _org = _verifiedOrg; };

        private _name = _org getOrDefault ["name", ""];
        private _id = _org getOrDefault ["id", _orgID];
        private _ownerUid = _org getOrDefault ["owner", ""];
        private _funds = _org getOrDefault ["funds", 0];
        private _reputation = _org getOrDefault ["reputation", 0];
        private _creditLinesRaw = _org getOrDefault ["credit_lines", createHashMap];
        private _assetsRaw = _org getOrDefault ["assets", createHashMap];
        private _fleetRaw = _org getOrDefault ["fleet", createHashMap];
        private _membersRaw = _org getOrDefault ["members", createHashMap];
        private _pendingInvitesRaw = _org getOrDefault ["pending_invites", createHashMap];
        private _isDefaultOrg = (_org getOrDefault ["default", false])
            || { toLowerANSI _id isEqualTo "default" }
            || { toLowerANSI _ownerUid isEqualTo "server" };
        private _memberInvites = [];
        if (_isDefaultOrg) then {
            _memberInvites = GVAR(OrgStore) call ["listMemberInvites", [_uid]];
        };

        private _playerName = name _player;
        private _playerVar = vehicleVarName _player;
        private _sessionIsCeo = _isDefaultOrg && { _playerVar isEqualTo "ceo" };
        private _memberShape = _self call ["buildMembersList", [_membersRaw, _uid, _ownerUid]];
        private _sessionRole = _memberShape getOrDefault ["sessionRole", "Member"];
        private _ownerName = _self call ["resolveOwnerName", [_ownerUid, _uid, _playerName, _membersRaw]];

        if (_ownerUid isEqualTo _uid) then { _sessionRole = "Leader"; };

        createHashMapFromArray [
            ["session", createHashMapFromArray [
                ["actorName", _playerName],
                ["actorUid", _uid],
                ["role", _sessionRole],
                ["ceo", _sessionIsCeo]
            ]],
            ["portalData", createHashMapFromArray [
                ["org", createHashMapFromArray [
                    ["name", _name],
                    ["tag", _id],
                    ["owner", _ownerName],
                    ["ownerUid", _ownerUid],
                    ["isDefault", _isDefaultOrg]
                ]],
                ["funds", _funds],
                ["reputation", _reputation],
                ["creditLines", _self call ["buildCreditLinesList", [_creditLinesRaw]]],
                ["members", _memberShape getOrDefault ["members", []]],
                ["pendingInvites", _self call ["buildPendingInvitesList", [_memberInvites]]],
                ["inviteablePlayers", _self call ["buildInviteablePlayers", [_uid, _id, _membersRaw, _pendingInvitesRaw]]],
                ["fleet", _self call ["buildFleetList", [_fleetRaw]]],
                ["assets", _self call ["buildAssetsList", [_assetsRaw]]],
                ["activity", []]
            ]]
        ]
    }]
]];

GVAR(OrgPayloadBuilder)
