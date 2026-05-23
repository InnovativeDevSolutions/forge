#include "..\script_component.hpp"

/*
 * File: fnc_initRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the org repository for client org lifecycle state.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Org repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_org_fnc_initRepository;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(OrgRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "OrgRepositoryBaseClass"],
    ["#create", compileFinal {
        _self set ["uid", getPlayerUID player];
        _self set ["isLoaded", false];
        _self set ["lastSave", time];
    }],
    ["init", compileFinal {
        [SRPC(org,requestInitOrg), [getPlayerUID player]] call CFUNC(serverEvent);
        _self set ["lastSave", time];

        systemChat format ["Org loaded for %1", name player];
        diag_log "[FORGE:Client:Org] Org Repository Initialized!";
    }],
    ["markLoaded", compileFinal {
        if !(_self getOrDefault ["isLoaded", false]) then { _self set ["isLoaded", true]; };
        true
    }]
];

GVAR(OrgRepository) = createHashMapObject [GVAR(OrgRepositoryBaseClass)];
GVAR(OrgRepository)
