#include "..\script_component.hpp"

/*
 * File: fnc_initPermissionService.sqf
 * Author: IDSolutions
 * Date: 2026-03-30
 * Public: No
 *
 * Description:
 * Initializes the CAD permission service for dispatcher authorization checks.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * CAD permission service object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_server_cad_fnc_initPermissionService
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(PermissionServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "CadPermissionServiceBaseClass"],
    ["canDispatch", compileFinal {
        params [["_uid", "", [""]]];

        if (_uid isEqualTo "") exitWith { false };

        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_uid]];
        private _org = EGVAR(org,OrgStore) call ["loadById", [_orgID]];
        if (_org isEqualTo createHashMap) exitWith { false };

        private _owner = _org getOrDefault ["owner", ""];
        if (_owner isEqualTo _uid) exitWith { true };

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (_player isEqualTo objNull) exitWith { false };

        private _playerVar = toLowerANSI (vehicleVarName _player);
        (_orgID isEqualTo "default") && { _playerVar in ["ceo", "dispatch"] }
    }]
];

createHashMapObject [GVAR(PermissionServiceBaseClass)]
