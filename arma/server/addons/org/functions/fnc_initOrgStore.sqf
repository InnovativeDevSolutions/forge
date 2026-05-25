#include "..\script_component.hpp"

/*
 * File: fnc_initOrgStore.sqf
 * Author: IDSolutions
 * Date: 2026-02-13
 * Last Update: 2026-05-15
 * Public: Yes
 *
 * Description:
 * Initializes the org store for managing player organizations.
 * Org hot state is owned by the extension; SQF acts as the bridge for
 * treasury charges, credit lines, and service debt recording.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Org store object [HASHMAP OBJECT]
 *
 * Examples:
 * call forge_server_org_fnc_initOrgStore
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(OrgModel) = compileFinal createHashMapObject [[
    ["#type", "OrgModel"],
    ["defaults", compileFinal {
        private _org = createHashMap;

        _org set ["id", ""];
        _org set ["owner", ""];
        _org set ["name", ""];
        _org set ["funds", 0];
        _org set ["reputation", 0];
        _org set ["credit_lines", createHashMap];
        _org set ["assets", createHashMap];
        _org set ["fleet", createHashMap];
        _org set ["members", createHashMap];
        _org set ["pending_invites", createHashMap];

        _org
    }],
    ["migrate", compileFinal {
        params [["_org", createHashMap, [createHashMap]]];

        private _defaults = _self call ["defaults", []];
        {
            if !(_x in _org) then { _org set [_x, _y]; };
        } forEach _defaults;

        private _assets = _org getOrDefault ["assets", createHashMap];
        if !(_assets isEqualType createHashMap) then {
            _assets = createHashMap;
        };

        private _migratedAssets = createHashMap;
        {
            private _categoryKey = _x;
            private _value = _y;

            if (_value isEqualType createHashMap) then {
                private _categoryMap = createHashMap;

                if (_categoryKey find ":" >= 0) then {
                    private _legacyAsset = +_value;
                    private _category = toLowerANSI (_legacyAsset getOrDefault ["type", "items"]);
                    private _className = _legacyAsset getOrDefault ["classname", ""];
                    if (_className isNotEqualTo "") then {
                        _categoryMap = +(_migratedAssets getOrDefault [_category, createHashMap]);
                        _categoryMap set [_className, _legacyAsset];
                        _migratedAssets set [_category, _categoryMap];
                    };
                } else {
                    {
                        if (_y isEqualType createHashMap) then {
                            _categoryMap set [_x, +_y];
                        };
                    } forEach _value;

                    _migratedAssets set [toLowerANSI _categoryKey, _categoryMap];
                };
            };
        } forEach _assets;

        _org set ["assets", _migratedAssets];

        private _creditLines = _org getOrDefault ["credit_lines", createHashMap];
        if !(_creditLines isEqualType createHashMap) then {
            _creditLines = createHashMap;
        };

        {
            if !(_y isEqualType createHashMap) then { continue; };

            private _line = +_y;
            private _legacyAmount = _line getOrDefault ["amount", 0];
            private _approvedAmount = _line getOrDefault ["approved_amount", _legacyAmount];
            private _availableAmount = _line getOrDefault ["available_amount", _approvedAmount];
            private _outstandingPrincipal = _line getOrDefault ["outstanding_principal", 0];
            private _interestRate = _line getOrDefault ["interest_rate", 0.1];
            private _amountDue = _line getOrDefault ["amount_due", 0];

            _line set ["uid", _line getOrDefault ["uid", _x]];
            _line set ["approved_amount", _approvedAmount];
            _line set ["available_amount", _availableAmount];
            _line set ["outstanding_principal", _outstandingPrincipal];
            _line set ["interest_rate", _interestRate];
            _line set ["amount_due", _amountDue];
            _line set ["amount", _availableAmount];
            _creditLines set [_x, _line];
        } forEach _creditLines;

        _org set ["credit_lines", _creditLines];

        private _pendingInvites = _org getOrDefault ["pending_invites", createHashMap];
        if !(_pendingInvites isEqualType createHashMap) then {
            _pendingInvites = createHashMap;
        };

        _org set ["pending_invites", _pendingInvites];

        _org
    }],
    ["validate", compileFinal {
        params [["_org", createHashMap, [createHashMap]]];

        private _id = _org get "id";
        private _owner = _org get "owner";
        private _name = _org get "name";
        private _funds = _org get "funds";
        private _reputation = _org get "reputation";
        private _creditLines = _org getOrDefault ["credit_lines", createHashMap];

        [_id, _owner, _name, _funds, _reputation, _creditLines] try {
            if (_id isEqualTo "" || !(_id isEqualType "")) then { throw "Invalid ID!"; };
            if (_owner isEqualTo "" || !(_owner isEqualType "")) then { throw "Invalid Owner!"; };
            if (_name isEqualTo "" || !(_name isEqualType "")) then { throw "Invalid Name!"; };
            if (_funds isEqualTo 0 || !(_funds isEqualType 0)) then { throw "Invalid Funds!"; };
            if (_reputation isEqualTo 0 || !(_reputation isEqualType 0)) then { throw "Invalid Reputation!"; };
            if !(_creditLines isEqualType createHashMap) then { throw "Invalid Credit Lines!"; };
        } catch {
            ["ERROR", format ["Failed to validate org %1!", _exception]] call EFUNC(common,log);
            false
        };

        true
    }]
]];

GVAR(OrgBaseStore) = compileFinal ([
    EGVAR(common,BaseStore),
    createHashMapFromArray [
    ["#type", "OrgBaseStore"],
    ["#create", compileFinal {
        ["INFO", "Org Store Initialized!"] call EFUNC(common,log);

        ["org:exists", ["default"]] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith {
            ["ERROR", "Failed to check for default org!"] call EFUNC(common,log);
            true
        };

        if (_result != "true") then {
            private _defaultOrg = createHashMapFromArray [
                ["id", "default"],
                ["owner", "server"],
                ["name", "Forge Dynamics"],
                ["funds", 200000],
                ["reputation", 0],
                ["credit_lines", createHashMap],
                ["assets", createHashMap],
                ["fleet", createHashMap],
                ["members", createHashMap],
                ["pending_invites", createHashMap]
            ];

            private _defaultJson = _self call ["toJSON", [_defaultOrg]];
            ["org:create", ["default", _defaultJson]] call EFUNC(extension,extCall);
        };

        private _loadedDefaultOrg = _self call ["loadHotOrg", ["default", true]];
        if (_loadedDefaultOrg isEqualTo createHashMap) then {
            _loadedDefaultOrg = createHashMapFromArray [
                ["id", "default"],
                ["owner", "server"],
                ["name", "Forge Dynamics"],
                ["funds", 200000],
                ["reputation", 0],
                ["credit_lines", createHashMap],
                ["assets", createHashMap],
                ["fleet", createHashMap],
                ["members", createHashMap],
                ["pending_invites", createHashMap]
            ];
        };

        true
    }],
    ["callHotOrg", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        if (_function isEqualTo "") exitWith { createHashMap };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith { createHashMap };
        if !(_result isEqualType "") exitWith { createHashMap };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Org extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            createHashMap
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith { createHashMap };

        _self call ["syncHotOrg", [_data]]
    }],
    ["callHotOrgEnvelope", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        if (_function isEqualTo "") exitWith { createHashMap };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith { createHashMap };
        if !(_result isEqualType "") exitWith { createHashMap };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Org extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            createHashMap
        };

        private _data = fromJSON _result;
        if !(_data isEqualType createHashMap) exitWith { createHashMap };

        if ("org" in _data) then {
            private _syncedOrg = _self call ["syncHotOrg", [_data getOrDefault ["org", createHashMap]]];
            if (_syncedOrg isNotEqualTo createHashMap) then {
                _data set ["org", _syncedOrg];
            };
        };

        _data
    }],
    ["callHotOrgArray", compileFinal {
        params [["_function", "", [""]], ["_arguments", [], [[]]]];

        if (_function isEqualTo "") exitWith { [] };

        [_function, _arguments] call EFUNC(extension,extCall) params ["_result", "_isSuccess"];
        if !(_isSuccess) exitWith { [] };
        if !(_result isEqualType "") exitWith { [] };
        if ((_result find "Error:") == 0) exitWith {
            ["ERROR", format ["Org extension call '%1' failed: %2", _function, _result]] call EFUNC(common,log);
            []
        };

        private _data = fromJSON _result;
        if !(_data isEqualType []) exitWith { [] };

        _data
    }],
    ["syncHotOrg", compileFinal {
        params [["_org", createHashMap, [createHashMap]]];

        if !(_org isEqualType createHashMap) exitWith { createHashMap };

        private _migratedOrg = GVAR(OrgModel) call ["migrate", [+_org]];
        private _orgID = _migratedOrg getOrDefault ["id", ""];
        if (_orgID isEqualTo "") exitWith { createHashMap };

        _migratedOrg
    }],
    ["resolveOrgIdForUid", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { "default" };

        EGVAR(actor,ActorStore) call ["getOrganization", [_uid]]
    }],
    ["resolveActorName", compileFinal {
        params [["_uid", "", [""]], ["_player", objNull, [objNull]], ["_actor", createHashMap, [createHashMap]]];

        private _memberName = _actor getOrDefault ["name", ""];
        if ((_memberName isEqualTo "" || { toLowerANSI _memberName isEqualTo "unknown" }) && { _player isNotEqualTo objNull }) then {
            _memberName = name _player;
        };
        if (_memberName isEqualTo "") then { _memberName = "Unknown"; };
        _memberName
    }],
    ["applyActorOrganization", compileFinal {
        params [["_uid", "", [""]], ["_orgID", "", [""]], ["_actor", createHashMap, [createHashMap]]];

        if (_uid isEqualTo "" || { _orgID isEqualTo "" }) exitWith { createHashMap };

        private _actorPatch = EGVAR(actor,ActorStore) call ["set", [_uid, "organization", _orgID, true]];
        private _updatedActor = EGVAR(actor,ActorStore) call ["load", [_uid]];
        if (
            !(_updatedActor isEqualType createHashMap)
            || { _updatedActor isEqualTo createHashMap }
            || { (_updatedActor getOrDefault ["organization", ""]) isNotEqualTo _orgID }
        ) then {
            private _forcedActor = +_actor;
            if !(_forcedActor isEqualType createHashMap) then {
                _forcedActor = EGVAR(actor,ActorModel) call ["defaults", []];
                _forcedActor set ["uid", _uid];
            };

            _forcedActor set ["organization", _orgID];
            _updatedActor = EGVAR(actor,ActorStore) call ["override", [_uid, _forcedActor, true]];
            if (_updatedActor isEqualType createHashMap && { _updatedActor isNotEqualTo createHashMap }) then {
                _actorPatch = createHashMapFromArray [["organization", _orgID]];
            };
        };

        if (
            !(_updatedActor isEqualType createHashMap)
            || { _updatedActor isEqualTo createHashMap }
            || { (_updatedActor getOrDefault ["organization", ""]) isNotEqualTo _orgID }
        ) exitWith { createHashMap };

        _actorPatch
    }],
    ["loadHotOrg", compileFinal {
        params [["_orgID", "", [""]], ["_initialize", false, [false]]];

        if (_orgID isEqualTo "") exitWith { createHashMap };

        private _command = ["org:hot:get", "org:hot:init"] select _initialize;
        _self call ["callHotOrg", [_command, [_orgID]]]
    }],
    ["get", compileFinal {
        params [["_orgID", "", [""]], ["_field", "", [""]]];

        private _org = _self call ["loadHotOrg", [_orgID, false]];
        if (_org isEqualTo createHashMap) then {
            _org = _self call ["loadHotOrg", [_orgID, true]];
        };

        if (_field isEqualTo "") exitWith { _org };
        _org getOrDefault [_field, createHashMap]
    }],
    ["delete", compileFinal {
        params [["_orgID", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""]
        ];

        if (_orgID isEqualTo "" || { toLower _orgID isEqualTo "default" }) exitWith {
            _result set ["message", "Invalid organization ID."];
            _result
        };

        ["org:delete", [_orgID]] call EFUNC(extension,extCall) params ["_deleteResult", "_deleteSuccess"];
        if (!_deleteSuccess || { _deleteResult isNotEqualTo "OK" }) exitWith {
            _result set ["message", format ["Failed to delete organization: %1", _deleteResult]];
            _result
        };

        ["org:hot:remove", [_orgID]] call EFUNC(extension,extCall);
        _result set ["success", true];
        _result
    }],
    ["ensureMember", compileFinal {
        params [["_orgID", "", [""]], ["_uid", "", [""]], ["_memberName", "", [""]]];

        if (_orgID isEqualTo "" || { _uid isEqualTo "" }) exitWith { createHashMap };

        private _context = createHashMapFromArray [
            ["orgId", _orgID],
            ["memberUid", _uid],
            ["memberName", _memberName]
        ];

        _self call ["callHotOrg", ["org:hot:ensure_member", [toJSON _context]]]
    }],
    ["listMemberInvites", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { [] };

        _self call ["callHotOrgArray", ["org:hot:member_invites", [_uid]]]
    }],
    ["inviteMember", compileFinal {
        params [["_requesterUid", "", [""]], ["_targetUid", "", [""]], ["_targetName", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""],
            ["targetUid", _targetUid],
            ["persisted", false],
            ["persistenceMessage", ""]
        ];

        if (_requesterUid isEqualTo "" || { _targetUid isEqualTo "" }) exitWith {
            _result set ["message", "A valid organization invite target is required."];
            _result
        };

        private _requesterPlayer = [_requesterUid] call EFUNC(common,getPlayer);
        private _requesterActor = EGVAR(actor,ActorStore) call ["load", [_requesterUid]];
        private _requesterOrgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        private _requesterName = _self call ["resolveActorName", [_requesterUid, _requesterPlayer, _requesterActor]];
        private _requesterIsDefaultOrgCeo = (
            _requesterPlayer isNotEqualTo objNull
            && { _requesterOrgID isEqualTo "default" }
            && { toLowerANSI (vehicleVarName _requesterPlayer) isEqualTo "ceo" }
        );
        private _targetOrgID = EGVAR(actor,ActorStore) call ["getOrganization", [_targetUid]];

        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["requesterName", _requesterName],
            ["orgId", _requesterOrgID],
            ["requesterIsDefaultOrgCeo", _requesterIsDefaultOrgCeo],
            ["targetUid", _targetUid],
            ["targetName", _targetName],
            ["targetOrgId", _targetOrgID]
        ];

        private _envelope = _self call ["callHotOrgEnvelope", ["org:hot:invite_member", [toJSON _context]]];
        if (_envelope isEqualTo createHashMap) exitWith {
            _result set ["message", "Unable to send organization invite."];
            _result
        };

        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", "Invitation sent."]];
        _result set ["targetUid", _envelope getOrDefault ["targetUid", _targetUid]];
        _self call ["persistMutationResult", [_requesterOrgID, _result, "Organization invite"]]
    }],
    ["acceptInvite", compileFinal {
        params [["_requesterUid", "", [""]], ["_orgID", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""],
            ["actorPatch", createHashMap],
            ["affectedOrgIds", []]
        ];

        if (_requesterUid isEqualTo "" || { _orgID isEqualTo "" }) exitWith {
            _result set ["message", "A valid invite selection is required."];
            _result
        };

        private _requesterPlayer = [_requesterUid] call EFUNC(common,getPlayer);
        private _requesterActor = EGVAR(actor,ActorStore) call ["load", [_requesterUid]];
        private _requesterName = _self call ["resolveActorName", [_requesterUid, _requesterPlayer, _requesterActor]];
        private _existingOrgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["requesterName", _requesterName],
            ["orgId", _orgID],
            ["existingOrgId", _existingOrgID]
        ];

        ["org:hot:accept_invite", [toJSON _context]] call EFUNC(extension,extCall) params ["_rawResult", "_isSuccess"];
        if !_isSuccess exitWith {
            _result set ["message", "Organization invite service was unavailable."];
            _result
        };
        if !(_rawResult isEqualType "") exitWith {
            _result set ["message", "Organization invite service returned an invalid response."];
            _result
        };
        if ((_rawResult find "Error:") == 0) exitWith {
            _result set ["message", _rawResult select [7]];
            _result
        };

        private _envelope = fromJSON _rawResult;
        if !(_envelope isEqualType createHashMap) exitWith {
            _result set ["message", "Organization invite service returned malformed data."];
            _result
        };

        private _invitedOrg = _self call ["syncHotOrg", [_envelope getOrDefault ["invitedOrg", createHashMap]]];
        if (_invitedOrg isNotEqualTo createHashMap) then {
            _envelope set ["invitedOrg", _invitedOrg];
        };

        private _previousOrgData = _envelope getOrDefault ["previousOrg", createHashMap];
        if (_previousOrgData isEqualType createHashMap && { _previousOrgData isNotEqualTo createHashMap }) then {
            private _syncedPreviousOrg = _self call ["syncHotOrg", [_previousOrgData]];
            if (_syncedPreviousOrg isNotEqualTo createHashMap) then {
                _envelope set ["previousOrg", _syncedPreviousOrg];
            };
        };

        private _actorOrg = _envelope getOrDefault ["actorOrganization", _orgID];
        private _actorPatch = _self call ["applyActorOrganization", [_requesterUid, _actorOrg, _requesterActor]];
        if (_actorPatch isEqualTo createHashMap) exitWith {
            _result set ["message", "Failed to assign the player to the invited organization."];
            _result
        };

        private _affectedOrgIds = [_actorOrg];
        private _previousOrg = _envelope getOrDefault ["previousOrg", createHashMap];
        if (_previousOrg isEqualType createHashMap && { _previousOrg isNotEqualTo createHashMap }) then {
            private _previousOrgID = _previousOrg getOrDefault ["id", ""];
            if (_previousOrgID isNotEqualTo "") then {
                _affectedOrgIds pushBackUnique _previousOrgID;
            };
        };

        {
            _self call ["saveById", [_x]];
        } forEach _affectedOrgIds;

        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", "Organization invite accepted."]];
        _result set ["actorPatch", _actorPatch];
        _result set ["affectedOrgIds", _affectedOrgIds];
        _result
    }],
    ["declineInvite", compileFinal {
        params [["_requesterUid", "", [""]], ["_orgID", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""],
            ["affectedOrgIds", []]
        ];

        if (_requesterUid isEqualTo "" || { _orgID isEqualTo "" }) exitWith {
            _result set ["message", "A valid invite selection is required."];
            _result
        };

        private _requesterPlayer = [_requesterUid] call EFUNC(common,getPlayer);
        private _requesterActor = EGVAR(actor,ActorStore) call ["load", [_requesterUid]];
        private _requesterName = _self call ["resolveActorName", [_requesterUid, _requesterPlayer, _requesterActor]];
        private _existingOrgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["requesterName", _requesterName],
            ["orgId", _orgID],
            ["existingOrgId", _existingOrgID]
        ];

        ["org:hot:decline_invite", [toJSON _context]] call EFUNC(extension,extCall) params ["_rawResult", "_isSuccess"];
        if !_isSuccess exitWith {
            _result set ["message", "Organization invite service was unavailable."];
            _result
        };
        if !(_rawResult isEqualType "") exitWith {
            _result set ["message", "Organization invite service returned an invalid response."];
            _result
        };
        if ((_rawResult find "Error:") == 0) exitWith {
            _result set ["message", _rawResult select [7]];
            _result
        };

        private _envelope = fromJSON _rawResult;
        if !(_envelope isEqualType createHashMap) exitWith {
            _result set ["message", "Organization invite service returned malformed data."];
            _result
        };

        private _invitedOrg = _self call ["syncHotOrg", [_envelope getOrDefault ["invitedOrg", createHashMap]]];
        if (_invitedOrg isNotEqualTo createHashMap) then {
            _envelope set ["invitedOrg", _invitedOrg];
        };

        _self call ["saveById", [_orgID]];

        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", "Organization invite declined."]];
        _result set ["affectedOrgIds", [_orgID]];
        _result
    }],
    ["leave", compileFinal {
        params [["_uid", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""],
            ["actorPatch", createHashMap],
            ["notification", []]
        ];

        if (_uid isEqualTo "") exitWith {
            _result set ["message", "A valid player UID is required."];
            _result
        };

        private _player = [_uid] call EFUNC(common,getPlayer);
        private _actor = EGVAR(actor,ActorStore) call ["load", [_uid]];
        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_uid]];
        private _memberName = _self call ["resolveActorName", [_uid, _player, _actor]];
        private _context = createHashMapFromArray [
            ["requesterUid", _uid],
            ["requesterName", _memberName],
            ["orgId", _orgID]
        ];

        private _envelope = _self call ["callHotOrgEnvelope", ["org:hot:leave", [toJSON _context]]];
        if (_envelope isEqualTo createHashMap) exitWith {
            _result set ["message", "Unable to leave the organization."];
            _result
        };

        private _actorOrg = _envelope getOrDefault ["actorOrganization", "default"];
        private _actorPatch = _self call ["applyActorOrganization", [_uid, _actorOrg, _actor]];
        if (_actorPatch isEqualTo createHashMap) exitWith {
            _result set ["message", "Failed to restore default organization membership."];
            _result
        };

        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", "You returned to the default organization."]];
        _result set ["actorPatch", _actorPatch];
        _result set ["notification", ["info", "Organization Left", _result get "message", 6000]];
        _result
    }],
    ["disband", compileFinal {
        params [["_uid", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""],
            ["members", []]
        ];

        if (_uid isEqualTo "") exitWith {
            _result set ["message", "A valid player UID is required."];
            _result
        };

        private _player = [_uid] call EFUNC(common,getPlayer);
        private _actor = EGVAR(actor,ActorStore) call ["load", [_uid]];
        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_uid]];
        private _memberName = _self call ["resolveActorName", [_uid, _player, _actor]];
        private _context = createHashMapFromArray [
            ["requesterUid", _uid],
            ["requesterName", _memberName],
            ["orgId", _orgID]
        ];

        private _envelope = _self call ["callHotOrgEnvelope", ["org:hot:disband", [toJSON _context]]];
        if (_envelope isEqualTo createHashMap) exitWith {
            _result set ["message", "Failed to disband organization."];
            _result
        };

        private _memberResults = [];
        {
            private _memberUid = _x getOrDefault ["uid", ""];
            if (_memberUid isEqualTo "") then { continue; };

            private _memberActor = EGVAR(actor,ActorStore) call ["load", [_memberUid]];
            private _actorPatch = _self call ["applyActorOrganization", [_memberUid, _x getOrDefault ["actorOrganization", "default"], _memberActor]];
            if (_actorPatch isEqualTo createHashMap) then {
                ["WARNING", format ["Failed to restore actor organization for %1 after org disband.", _memberUid]] call EFUNC(common,log);
            };

            private _responseMessage = _x getOrDefault ["message", _envelope getOrDefault ["message", "Organization disbanded."]];
            private _notificationParams = [
                ["warning", "Organization Disbanded", _responseMessage, 6000],
                ["success", "Organization Disbanded", _responseMessage, 6000]
            ] select (_x getOrDefault ["requester", false]);

            _memberResults pushBack (createHashMapFromArray [
                ["uid", _memberUid],
                ["requester", _x getOrDefault ["requester", false]],
                ["message", _responseMessage],
                ["notification", _notificationParams],
                ["actorPatch", _actorPatch]
            ]);
        } forEach (_envelope getOrDefault ["members", []]);

        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", "Organization disbanded."]];
        _result set ["members", _memberResults];
        _result
    }],
    ["assignCreditLine", compileFinal {
        params [["_requesterUid", "", [""]], ["_memberUid", "", [""]], ["_memberName", "", [""]], ["_amount", 0, [0]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""],
            ["patch", createHashMap],
            ["memberUids", []],
            ["persisted", false],
            ["persistenceMessage", ""]
        ];

        if (_requesterUid isEqualTo "" || { _memberUid isEqualTo "" } || { _amount <= 0 }) exitWith {
            _result set ["message", "A valid requester, member, and credit amount are required."];
            _result
        };

        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        private _requesterPlayer = [_requesterUid] call EFUNC(common,getPlayer);
        private _requesterIsDefaultOrgCeo = (
            _requesterPlayer isNotEqualTo objNull
            && { _orgID isEqualTo "default" }
            && { toLowerANSI (vehicleVarName _requesterPlayer) isEqualTo "ceo" }
        );

        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["orgId", _orgID],
            ["requesterIsDefaultOrgCeo", _requesterIsDefaultOrgCeo],
            ["memberUid", _memberUid],
            ["memberName", _memberName],
            ["amount", _amount]
        ];

        private _envelope = _self call ["callHotOrgEnvelope", ["org:hot:assign_credit_line", [toJSON _context]]];
        if (_envelope isEqualTo createHashMap) exitWith {
            _result set ["message", "Unable to assign credit line."];
            _result
        };

        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", "Credit line assigned."]];
        _result set ["patch", _envelope getOrDefault ["patch", createHashMap]];
        _result set ["memberUids", _envelope getOrDefault ["memberUids", []]];
        _self call ["persistMutationResult", [_orgID, _result, "Credit line assignment"]]
    }],
    ["creditMemberBank", compileFinal {
        params [["_memberUid", "", [""]], ["_amount", 0, [0]], ["_message", "", [""]]];

        if (_memberUid isEqualTo "" || { _amount <= 0 }) exitWith { false };

        private _account = EGVAR(bank,BankStore) call ["get", [_memberUid, ""]];
        if (_account isEqualTo createHashMap) then {
            _account = EGVAR(bank,BankStore) call ["init", [_memberUid]];
        };
        if (_account isEqualTo createHashMap) exitWith { false };

        private _currentBank = _account getOrDefault ["bank", 0];
        private _patch = EGVAR(bank,BankStore) call ["mset", [_memberUid, createHashMapFromArray [["bank", _currentBank + _amount]], true]];
        if (_patch isEqualTo createHashMap) exitWith { false };
        if (isNil QEGVAR(common,EventBus)) then {
            EGVAR(bank,BankMessenger) call ["sendAccountSync", [_memberUid, _patch]];
        } else {
            EGVAR(common,EventBus) call ["emit", [
                "bank.account.sync.requested",
                createHashMapFromArray [
                    ["uid", _memberUid],
                    ["account", +_patch]
                ],
                createHashMapFromArray [["source", "org"]]
            ]];
        };

        if (_message isNotEqualTo "") then {
            if (isNil QEGVAR(common,EventBus)) then {
                EGVAR(bank,BankMessenger) call ["sendNotification", [_memberUid, "info", "Treasury", _message]];
            } else {
                EGVAR(common,EventBus) call ["emit", [
                    "notification.requested",
                    createHashMapFromArray [
                        ["uids", [_memberUid]],
                        ["notificationType", "info"],
                        ["title", "Treasury"],
                        ["message", _message]
                    ],
                    createHashMapFromArray [["source", "org"]]
                ]];
            };
        };

        true
    }],
    ["syncBankPatch", compileFinal {
        params [["_uid", "", [""]], ["_patch", createHashMap, [createHashMap]]];

        if (_uid isEqualTo "" || { _patch isEqualTo createHashMap }) exitWith { false };

        if (isNil QEGVAR(common,EventBus)) then {
            EGVAR(bank,BankMessenger) call ["sendAccountSync", [_uid, _patch]];
        } else {
            EGVAR(common,EventBus) call ["emit", [
                "bank.account.sync.requested",
                createHashMapFromArray [
                    ["uid", _uid],
                    ["account", +_patch]
                ],
                createHashMapFromArray [["source", "org"]]
            ]];
        };

        true
    }],
    ["chargeRegistrationFee", compileFinal {
        params [["_uid", "", [""]], ["_amount", 50000, [0]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to charge the organization registration fee."],
            ["patch", createHashMap],
            ["refundPatch", createHashMap]
        ];

        if (_uid isEqualTo "" || { _amount <= 0 }) exitWith { _result };
        if (isNil QEGVAR(bank,BankStore)) exitWith {
            _result set ["message", "Bank service is unavailable for organization registration."];
            _result
        };

        private _account = EGVAR(bank,BankStore) call ["get", [_uid, ""]];
        if (_account isEqualTo createHashMap) then {
            _account = EGVAR(bank,BankStore) call ["init", [_uid]];
        };
        if (_account isEqualTo createHashMap) exitWith {
            _result set ["message", "Bank account could not be loaded for organization registration."];
            _result
        };

        private _currentBank = _account getOrDefault ["bank", 0];
        private _currentCash = _account getOrDefault ["cash", 0];
        if ((_currentBank + _currentCash) < _amount) exitWith {
            _result set ["message", format ["You need at least $%1 in personal funds to create an organization.", [_amount] call EFUNC(common,formatNumber)]];
            _result
        };

        private _bankCharge = _amount min _currentBank;
        private _cashCharge = _amount - _bankCharge;
        private _patch = createHashMapFromArray [
            ["bank", _currentBank - _bankCharge],
            ["cash", _currentCash - _cashCharge]
        ];
        private _refundPatch = createHashMapFromArray [
            ["bank", _currentBank],
            ["cash", _currentCash]
        ];

        private _appliedPatch = EGVAR(bank,BankStore) call ["mset", [_uid, _patch, true]];
        if (_appliedPatch isEqualTo createHashMap) exitWith {
            _result set ["message", "Organization registration fee could not be charged."];
            _result
        };

        _result set ["success", true];
        _result set ["message", ""];
        _result set ["patch", _appliedPatch];
        _result set ["refundPatch", _refundPatch];
        _result
    }],
    ["refundRegistrationFee", compileFinal {
        params [["_uid", "", [""]], ["_refundPatch", createHashMap, [createHashMap]]];

        if (_uid isEqualTo "" || { _refundPatch isEqualTo createHashMap } || { isNil QEGVAR(bank,BankStore) }) exitWith { false };

        private _patch = EGVAR(bank,BankStore) call ["mset", [_uid, _refundPatch, true]];
        if (_patch isEqualTo createHashMap) exitWith { false };

        _self call ["syncBankPatch", [_uid, _patch]]
    }],
    ["updateOrgTreasuryFunds", compileFinal {
        params [["_orgID", "", [""]], ["_funds", 0, [0]]];

        if (_orgID isEqualTo "") exitWith { createHashMap };

        private _org = _self call ["loadById", [_orgID]];
        if (_org isEqualTo createHashMap) exitWith { createHashMap };

        private _nextOrg = +_org;
        _nextOrg set ["funds", _funds];

        private _updatedOrg = _self call ["callHotOrg", ["org:hot:override", [_orgID, toJSON _nextOrg]]];
        if (_updatedOrg isEqualTo createHashMap) exitWith { createHashMap };

        _self call ["saveById", [_orgID]]
    }],
    ["runPayroll", compileFinal {
        params [["_requesterUid", "", [""]], ["_amountPerMember", 0, [0]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""],
            ["memberUids", []]
        ];

        if (_requesterUid isEqualTo "" || { _amountPerMember <= 0 }) exitWith {
            _result set ["message", "A valid payroll amount is required."];
            _result
        };

        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        private _requesterPlayer = [_requesterUid] call EFUNC(common,getPlayer);
        private _requesterIsDefaultOrgCeo = (
            _requesterPlayer isNotEqualTo objNull
            && { _orgID isEqualTo "default" }
            && { toLowerANSI (vehicleVarName _requesterPlayer) isEqualTo "ceo" }
        );

        private _org = _self call ["loadById", [_orgID]];
        if (_org isEqualTo createHashMap) exitWith {
            _result set ["message", "Organization data could not be loaded."];
            _result
        };

        private _ownerUid = _org getOrDefault ["owner", ""];
        private _canManageTreasury = (
            _requesterUid isEqualTo _ownerUid
            || { _orgID isEqualTo "default" && { _requesterIsDefaultOrgCeo } }
        );
        if !(_canManageTreasury) exitWith {
            _result set ["message", "Only the organization leader or CEO can manage treasury actions."];
            _result
        };

        private _membersRaw = _org getOrDefault ["members", createHashMap];
        private _memberUids = [];
        {
            private _memberUid = _y getOrDefault ["uid", ""];
            if (_memberUid isNotEqualTo "") then {
                _memberUids pushBackUnique _memberUid;
            };
        } forEach _membersRaw;

        if (_memberUids isEqualTo []) exitWith {
            _result set ["message", "No members available for payroll."];
            _result
        };

        private _total = _amountPerMember * count _memberUids;
        private _funds = _org getOrDefault ["funds", 0];
        if (_total > _funds) exitWith {
            _result set ["message", "Insufficient org funds for payroll."];
            _result
        };

        {
            private _memberData = _membersRaw getOrDefault [_x, createHashMap];
            private _memberName = _memberData getOrDefault ["name", "a member"];
            private _ok = _self call ["creditMemberBank", [_x, _amountPerMember, format ["Received payroll of $%1 from %2.", [_amountPerMember] call EFUNC(common,formatNumber), _org getOrDefault ["name", "the organization"]]]];
            if !(_ok) exitWith {
                _result set ["message", format ["Failed to credit payroll for %1.", _memberName]];
                _result set ["success", false];
            };
        } forEach _memberUids;
        if (_result getOrDefault ["message", ""] isNotEqualTo "") exitWith { _result };

        private _savedOrg = _self call ["updateOrgTreasuryFunds", [_orgID, _funds - _total]];
        if (_savedOrg isEqualTo createHashMap) exitWith {
            _result set ["message", "Payroll was credited, but organization funds could not be updated."];
            _result
        };

        _result set ["success", true];
        _result set ["message", format ["Payroll sent to %1 members for $%2.", count _memberUids, [_total] call EFUNC(common,formatNumber)]];
        _result set ["memberUids", _memberUids];
        _result
    }],
    ["transferFunds", compileFinal {
        params [["_requesterUid", "", [""]], ["_memberUid", "", [""]], ["_memberName", "", [""]], ["_amount", 0, [0]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""],
            ["memberUids", []]
        ];

        if (_requesterUid isEqualTo "" || { _memberUid isEqualTo "" } || { _amount <= 0 }) exitWith {
            _result set ["message", "A valid member and transfer amount are required."];
            _result
        };

        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        private _requesterPlayer = [_requesterUid] call EFUNC(common,getPlayer);
        private _requesterIsDefaultOrgCeo = (
            _requesterPlayer isNotEqualTo objNull
            && { _orgID isEqualTo "default" }
            && { toLowerANSI (vehicleVarName _requesterPlayer) isEqualTo "ceo" }
        );

        private _org = _self call ["loadById", [_orgID]];
        if (_org isEqualTo createHashMap) exitWith {
            _result set ["message", "Organization data could not be loaded."];
            _result
        };

        private _ownerUid = _org getOrDefault ["owner", ""];
        private _canManageTreasury = (
            _requesterUid isEqualTo _ownerUid
            || { _orgID isEqualTo "default" && { _requesterIsDefaultOrgCeo } }
        );
        if !(_canManageTreasury) exitWith {
            _result set ["message", "Only the organization leader or CEO can manage treasury actions."];
            _result
        };

        private _membersRaw = _org getOrDefault ["members", createHashMap];
        private _memberData = _membersRaw getOrDefault [_memberUid, createHashMap];
        if (_memberData isEqualTo createHashMap) exitWith {
            _result set ["message", "Selected member was not found in the organization roster."];
            _result
        };

        private _funds = _org getOrDefault ["funds", 0];
        if (_amount > _funds) exitWith {
            _result set ["message", "Insufficient org funds for this transfer."];
            _result
        };

        private _resolvedMemberName = _memberData getOrDefault ["name", _memberName];
        private _ok = _self call ["creditMemberBank", [_memberUid, _amount, format ["Received treasury transfer of $%1 from %2.", [_amount] call EFUNC(common,formatNumber), _org getOrDefault ["name", "the organization"]]]];
        if !(_ok) exitWith {
            _result set ["message", format ["Failed to transfer funds to %1.", _resolvedMemberName]];
            _result
        };

        private _savedOrg = _self call ["updateOrgTreasuryFunds", [_orgID, _funds - _amount]];
        if (_savedOrg isEqualTo createHashMap) exitWith {
            _result set ["message", "Transfer was credited, but organization funds could not be updated."];
            _result
        };

        _result set ["success", true];
        _result set ["message", format ["$%1 sent to %2.", [_amount] call EFUNC(common,formatNumber), _resolvedMemberName]];
        _result set ["memberUids", [_memberUid]];
        _result
    }],
    ["repayCreditLine", compileFinal {
        params [["_requesterUid", "", [""]], ["_amount", 0, [0]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""],
            ["patch", createHashMap],
            ["memberUids", []],
            ["persisted", false],
            ["persistenceMessage", ""]
        ];

        if (_requesterUid isEqualTo "" || { _amount <= 0 }) exitWith {
            _result set ["message", "A valid repayment amount is required."];
            _result
        };

        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["orgId", _orgID],
            ["amount", _amount]
        ];

        private _envelope = _self call ["callHotOrgEnvelope", ["org:hot:repay_credit_line", [toJSON _context]]];
        if (_envelope isEqualTo createHashMap) exitWith {
            _result set ["message", "Unable to apply credit repayment."];
            _result
        };

        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", "Credit repayment posted."]];
        _result set ["patch", _envelope getOrDefault ["patch", createHashMap]];
        _result set ["memberUids", _envelope getOrDefault ["memberUids", []]];
        _self call ["persistMutationResult", [_orgID, _result, "Credit repayment"]]
    }],
    ["buildPortalPayload", compileFinal {
        params [["_uid", "", [""]]];

        GVAR(OrgPayloadBuilder) call ["buildPortalPayload", [_uid]]
    }],
    ["persistMutationResult", compileFinal {
        params [
            ["_orgID", "", [""]],
            ["_result", createHashMap, [createHashMap]],
            ["_actionLabel", "Organization update", [""]]
        ];

        if (_orgID isEqualTo "" || { _result isEqualTo createHashMap }) exitWith { _result };

        if !(_result getOrDefault ["success", false]) exitWith { _result };

        _result set ["persisted", false];
        _result set ["persistenceMessage", ""];

        private _savedOrg = _self call ["saveById", [_orgID]];
        if (_savedOrg isEqualTo createHashMap) exitWith {
            private _message = format ["%1 applied, but durable save failed for organization %2.", _actionLabel, _orgID];
            ["ERROR", _message] call EFUNC(common,log);
            _result set ["persistenceMessage", _message];
            _result
        };

        _result set ["persisted", true];
        _result
    }],
    ["chargeCheckout", compileFinal {
        params [
            ["_requesterUid", "", [""]],
            ["_requesterPlayer", objNull, [objNull]],
            ["_source", "org_funds", [""]],
            ["_amount", 0, [0]],
            ["_commit", false, [false]],
            ["_allowMemberCharge", false, [false]],
            ["_recordMemberDebt", false, [false]]
        ];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to process organization payment."],
            ["patch", createHashMap],
            ["memberUids", []],
            ["persisted", false],
            ["persistenceMessage", ""]
        ];

        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        private _requesterIsDefaultOrgCeo = (
            _requesterPlayer isNotEqualTo objNull
            && { _orgID isEqualTo "default" }
            && { toLowerANSI (vehicleVarName _requesterPlayer) isEqualTo "ceo" }
        );

        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["orgId", _orgID],
            ["requesterIsDefaultOrgCeo", _requesterIsDefaultOrgCeo],
            ["allowMemberCharge", _allowMemberCharge],
            ["recordMemberDebt", _recordMemberDebt],
            ["source", _source],
            ["amount", _amount],
            ["commit", _commit]
        ];

        private _envelope = _self call ["callHotOrgEnvelope", ["org:hot:charge_checkout", [toJSON _context]]];
        if (_envelope isEqualTo createHashMap) exitWith { _result };

        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", ""]];
        _result set ["patch", _envelope getOrDefault ["patch", createHashMap]];
        _result set ["memberUids", _envelope getOrDefault ["memberUids", []]];
        _self call ["persistMutationResult", [_orgID, _result, "Organization checkout charge"]]
    }],
    ["saveById", compileFinal {
        params [["_orgID", "", [""]]];

        if (_orgID isEqualTo "") exitWith { createHashMap };

        _self call ["callHotOrg", ["org:hot:save", [_orgID]]]
    }],
    ["addAssets", compileFinal {
        params [["_requesterUid", "", [""]], ["_assets", [], [[]]], ["_commit", false, [false]], ["_orgID", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to update organization assets."],
            ["patch", createHashMap],
            ["memberUids", []],
            ["persisted", false],
            ["persistenceMessage", ""]
        ];

        if (_assets isEqualTo []) exitWith {
            _result set ["success", true];
            _result set ["message", ""];
            _result
        };

        private _resolvedOrgID = _orgID;
        if (_resolvedOrgID isEqualTo "") then {
            _resolvedOrgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        };
        if (_resolvedOrgID isEqualTo "") then { _resolvedOrgID = "default"; };

        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["orgId", _resolvedOrgID],
            ["commit", _commit]
        ];
        private _assetSeeds = _assets apply {
            createHashMapFromArray [
                ["classname", _x getOrDefault ["classname", ""]],
                ["category", toLowerANSI (_x getOrDefault ["category", "items"])],
                ["quantity", floor ((_x getOrDefault ["quantity", 0]) max 0)]
            ]
        };

        private _envelope = _self call ["callHotOrgEnvelope", ["org:hot:add_assets", [toJSON _context, toJSON _assetSeeds]]];
        if (_envelope isEqualTo createHashMap) exitWith {
            _result set ["message", "Failed to update organization asset cache."];
            _result
        };

        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", ""]];
        _result set ["patch", _envelope getOrDefault ["patch", createHashMap]];
        _result set ["memberUids", _envelope getOrDefault ["memberUids", []]];
        _self call ["persistMutationResult", [_resolvedOrgID, _result, "Organization asset update"]]
    }],
    ["addFleetVehicles", compileFinal {
        params [["_requesterUid", "", [""]], ["_vehicles", [], [[]]], ["_commit", false, [false]], ["_orgID", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", "Unable to update organization fleet."],
            ["patch", createHashMap],
            ["memberUids", []],
            ["persisted", false],
            ["persistenceMessage", ""]
        ];

        if (_vehicles isEqualTo []) exitWith {
            _result set ["success", true];
            _result set ["message", ""];
            _result
        };

        private _resolvedOrgID = _orgID;
        if (_resolvedOrgID isEqualTo "") then {
            _resolvedOrgID = EGVAR(actor,ActorStore) call ["getOrganization", [_requesterUid]];
        };
        if (_resolvedOrgID isEqualTo "") then { _resolvedOrgID = "default"; };

        private _context = createHashMapFromArray [
            ["requesterUid", _requesterUid],
            ["orgId", _resolvedOrgID],
            ["commit", _commit]
        ];
        private _fleetSeeds = _vehicles apply {
            createHashMapFromArray [
                ["classname", _x getOrDefault ["classname", ""]],
                ["category", toLowerANSI (_x getOrDefault ["category", "other"])]
            ]
        };

        private _envelope = _self call ["callHotOrgEnvelope", ["org:hot:add_fleet", [toJSON _context, toJSON _fleetSeeds]]];
        if (_envelope isEqualTo createHashMap) exitWith {
            _result set ["message", "Failed to update organization fleet cache."];
            _result
        };

        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", ""]];
        _result set ["patch", _envelope getOrDefault ["patch", createHashMap]];
        _result set ["memberUids", _envelope getOrDefault ["memberUids", []]];
        _self call ["persistMutationResult", [_resolvedOrgID, _result, "Organization fleet update"]]
    }],
    ["loadById", compileFinal {
        params [["_orgID", "", [""]]];

        if (_orgID isEqualTo "") exitWith { createHashMap };

        _self call ["loadHotOrg", [_orgID, true]]
    }],
    ["register", compileFinal {
        params [["_uid", "", [""]], ["_orgName", "", [""]]];

        private _result = createHashMapFromArray [
            ["success", false],
            ["message", ""],
            ["org", createHashMap],
            ["actorPatch", createHashMap]
        ];

        if (_uid isEqualTo "" || { _orgName isEqualTo "" }) exitWith {
            _result set ["message", "A valid player and organization name are required."];
            _result
        };

        private _actor = EGVAR(actor,ActorStore) call ["load", [_uid]];
        private _existingOrgID = EGVAR(actor,ActorStore) call ["getOrganization", [_uid, ""]];
        private _orgID = EGVAR(actor,ActorStore) call ["getPhoneNumber", [_uid]];
        if (_orgID isEqualTo "") exitWith {
            _result set ["message", "Player phone number was not available for organization registration."];
            _result
        };

        private _context = createHashMapFromArray [
            ["requesterUid", _uid],
            ["requesterName", _self call ["resolveActorName", [_uid, [_uid] call EFUNC(common,getPlayer), _actor]]],
            ["orgId", _orgID],
            ["orgName", _orgName],
            ["existingOrgId", _existingOrgID]
        ];

        private _registrationFee = 50000;
        private _feeCharge = _self call ["chargeRegistrationFee", [_uid, _registrationFee]];
        if !(_feeCharge getOrDefault ["success", false]) exitWith {
            _result set ["message", _feeCharge getOrDefault ["message", "Organization registration fee could not be charged."]];
            _result
        };
        private _refundPatch = _feeCharge getOrDefault ["refundPatch", createHashMap];

        ["org:hot:register", [toJSON _context]] call EFUNC(extension,extCall) params ["_rawResult", "_isSuccess"];
        if !_isSuccess exitWith {
            _self call ["refundRegistrationFee", [_uid, _refundPatch]];
            _result set ["message", "Organization service was unavailable during registration."];
            _result
        };

        if !(_rawResult isEqualType "") exitWith {
            _self call ["refundRegistrationFee", [_uid, _refundPatch]];
            _result set ["message", "Organization service returned an invalid registration response."];
            _result
        };

        if ((_rawResult find "Error:") == 0) exitWith {
            _self call ["refundRegistrationFee", [_uid, _refundPatch]];
            _result set ["message", _rawResult select [7]];
            _result
        };

        private _envelope = fromJSON _rawResult;
        if !(_envelope isEqualType createHashMap) exitWith {
            _self call ["refundRegistrationFee", [_uid, _refundPatch]];
            _result set ["message", "Organization service returned malformed registration data."];
            _result
        };

        if ("org" in _envelope) then {
            private _syncedOrg = _self call ["syncHotOrg", [_envelope getOrDefault ["org", createHashMap]]];
            if (_syncedOrg isNotEqualTo createHashMap) then {
                _envelope set ["org", _syncedOrg];
            };
        };

        private _actorPatch = _self call ["applyActorOrganization", [_uid, _envelope getOrDefault ["actorOrganization", _orgID], _actor]];
        if (_actorPatch isEqualTo createHashMap) exitWith {
            _self call ["refundRegistrationFee", [_uid, _refundPatch]];
            _result set ["message", "Failed to assign the player to the new organization."];
            _result
        };

        _self call ["syncBankPatch", [_uid, _feeCharge getOrDefault ["patch", createHashMap]]];
        _result set ["success", true];
        _result set ["message", _envelope getOrDefault ["message", ""]];
        _result set ["org", _envelope getOrDefault ["org", createHashMap]];
        _result set ["actorPatch", _actorPatch];
        _result
    }],
    ["init", compileFinal {
        params [["_uid", "", [""]]];

        private _player = [_uid] call EFUNC(common,getPlayer);
        private _actor = EGVAR(actor,ActorStore) call ["load", [_uid]];
        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_uid]];
        private _finalOrg = _self call ["loadById", [_orgID]];
        if (_finalOrg isEqualTo createHashMap) then {
            ["WARNING", format ["No existing org found for %1, using default org.", _uid]] call EFUNC(common,log);
            _finalOrg = _self call ["loadById", ["default"]];
            _orgID = "default";
        };

        private _verifiedOrg = _self call ["ensureMember", [_orgID, _uid, _self call ["resolveActorName", [_uid, _player, _actor]]]];
        if (_verifiedOrg isNotEqualTo createHashMap) then {
            _finalOrg = _verifiedOrg;
        };

        [CRPC(org,responseInitOrg), [_finalOrg], _player] call CFUNC(targetEvent);

        _finalOrg
    }]
]] call {
    params ["_base", "_child"];

    private _merged = +_base;
    { _merged set [_x, _y]; } forEach _child;
    _merged
});

GVAR(OrgStore) = createHashMapObject [GVAR(OrgBaseStore), []];
true
