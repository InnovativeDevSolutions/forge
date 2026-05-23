#include "..\script_component.hpp"

/*
 * File: fnc_initPayloadBuilder.sqf
 * Author: IDSolutions
 * Date: 2026-04-02
 * Public: No
 *
 * Description:
 *     Initializes the bank payload builder for session/view shaping.
 *     Keeps hydrate/context construction out of BankStore so the store
 *     can focus on extension-backed account operations.
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(BankPayloadBuilder) = createHashMapObject [[
    ["#type", "BankPayloadBuilder"],
    ["buildOperationContext", compileFinal {
        params [["_uid", "", [""]], ["_modeOverride", "", [""]]];

        private _session = GVAR(BankSessionManager) call ["getSessionState", [_uid]];
        private _mode = if (_modeOverride isEqualTo "") then {
            _session getOrDefault ["mode", "bank"]
        } else {
            GVAR(BankSessionManager) call ["resolveMode", [_modeOverride]]
        };

        createHashMapFromArray [
            ["mode", _mode],
            ["atmAuthorized", _session getOrDefault ["atmAuthorized", false]]
        ]
    }],
    ["buildTransferContext", compileFinal {
        params [["_uid", "", [""]], ["_from", "", [""]]];

        private _context = _self call ["buildOperationContext", [_uid]];
        _context set ["fromField", _from];
        _context
    }],
    ["buildCheckoutContext", compileFinal {
        params [["_source", "bank", [""]], ["_commit", false, [false]]];

        createHashMapFromArray [
            ["commit", _commit],
            ["sourceField", toLowerANSI _source]
        ]
    }],
    ["resolveOrgState", compileFinal {
        params [["_uid", "", [""]]];

        private _defaultCreditLine = createHashMapFromArray [
            ["approvedAmount", 0],
            ["availableAmount", 0],
            ["outstandingPrincipal", 0],
            ["interestRate", 0.1],
            ["amountDue", 0]
        ];
        private _defaultState = createHashMapFromArray [
            ["funds", 0],
            ["name", ""],
            ["creditLine", _defaultCreditLine]
        ];
        if (_uid isEqualTo "") exitWith { _defaultState };

        private _orgID = EGVAR(actor,ActorStore) call ["getOrganization", [_uid]];
        private _org = EGVAR(org,OrgStore) call ["loadById", [_orgID]];
        if (_org isEqualTo createHashMap) then {
            _org = EGVAR(org,OrgStore) call ["loadById", ["default"]];
        };
        if (_org isEqualTo createHashMap) exitWith { _defaultState };

        private _creditLines = _org getOrDefault ["credit_lines", createHashMap];
        if !(_creditLines isEqualType createHashMap) then {
            _creditLines = createHashMap;
        };

        private _creditLine = _creditLines getOrDefault [_uid, createHashMap];
        if !(_creditLine isEqualType createHashMap) then {
            _creditLine = createHashMap;
        };

        createHashMapFromArray [
            ["funds", _org getOrDefault ["funds", 0]],
            ["name", _org getOrDefault ["name", ""]],
            ["creditLine", createHashMapFromArray [
                ["approvedAmount", _creditLine getOrDefault [
                    "approved_amount",
                    _creditLine getOrDefault ["amount", 0]
                ]],
                ["availableAmount", _creditLine getOrDefault [
                    "available_amount",
                    _creditLine getOrDefault ["amount", 0]
                ]],
                ["outstandingPrincipal", _creditLine getOrDefault ["outstanding_principal", 0]],
                ["interestRate", _creditLine getOrDefault ["interest_rate", 0.1]],
                ["amountDue", _creditLine getOrDefault ["amount_due", 0]]
            ]]
        ]
    }],
    ["buildTransferTargets", compileFinal {
        params [["_sourceUid", "", [""]]];

        private _targets = [];
        {
            if (isNull _x) then { continue; };
            private _targetUid = getPlayerUID _x;
            private _targetName = name _x;
            if (_targetUid isEqualTo "" || { _targetUid isEqualTo _sourceUid } || { _targetName isEqualTo "" }) then { continue; };
            _targets pushBack (createHashMapFromArray [["name", _targetName], ["uid", _targetUid]]);
        } forEach allPlayers;

        private _targetPairs = _targets apply { [toLowerANSI (_x getOrDefault ["name", ""]), _x] };
        _targetPairs sort true;
        _targetPairs apply { _x param [1, createHashMap] }
    }],
    ["buildHydratePayload", compileFinal {
        params [["_uid", "", [""]], ["_mode", "", [""]], ["_resetAuthorization", false, [false]]];

        if (_uid isEqualTo "") exitWith { createHashMap };

        private _account = GVAR(BankStore) call ["get", [_uid, ""]];
        if (_account isEqualTo createHashMap) then {
            _account = GVAR(BankStore) call ["init", [_uid]];
        };
        if (_account isEqualTo createHashMap) exitWith { createHashMap };

        private _session = GVAR(BankSessionManager) call ["syncSessionMode", [_uid, _mode, _resetAuthorization]];
        private _orgState = _self call ["resolveOrgState", [_uid]];
        private _player = [_uid] call EFUNC(common,getPlayer);
        private _playerName = if (isNull _player) then { _account getOrDefault ["name", "Unknown"] } else { name _player };

        createHashMapFromArray [
            ["session", createHashMapFromArray [
                ["atmAuthorized", _session getOrDefault ["atmAuthorized", false]],
                ["mode", _session getOrDefault ["mode", "bank"]],
                ["orgFunds", _orgState getOrDefault ["funds", 0]],
                ["orgName", _orgState getOrDefault ["name", ""]],
                ["creditLine", _orgState getOrDefault ["creditLine", createHashMap]],
                ["playerName", _playerName],
                ["transferTargets", _self call ["buildTransferTargets", [_uid]]],
                ["uid", _uid]
            ]],
            ["account", GVAR(BankMessenger) call ["buildAccountPatch", [_account]]]
        ]
    }]
]];

GVAR(BankPayloadBuilder)
