#include "..\script_component.hpp"

/*
 * File: fnc_initRepository.sqf
 * Author: IDSolutions
 * Date: 2026-03-27
 * Public: No
 *
 * Description:
 * Initializes the bank repository for client bank lifecycle state.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Bank repository object [HASHMAP OBJECT]
 *
 * Example:
 * call forge_client_bank_fnc_initRepository;
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(BankRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "BankRepositoryBaseClass"],
    ["#create", compileFinal {
        _self set ["uid", getPlayerUID player];
        _self set ["isLoaded", false];
        _self set ["lastSave", time];
    }],
    ["init", compileFinal {
        [SRPC(bank,requestInitBank), [getPlayerUID player]] call CFUNC(serverEvent);
        _self set ["lastSave", time];

        systemChat format ["Bank loaded for %1", name player];
        diag_log "[FORGE:Client:Bank] Bank Repository Initialized!";
    }],
    ["markLoaded", compileFinal {
        if !(_self getOrDefault ["isLoaded", false]) then { _self set ["isLoaded", true]; };
        true
    }]
];

GVAR(BankRepository) = createHashMapObject [GVAR(BankRepositoryBaseClass)];
GVAR(BankRepository)
