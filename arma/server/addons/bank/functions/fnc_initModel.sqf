#include "..\script_component.hpp"

/*
 * File: fnc_initModel.sqf
 * Author: IDSolutions
 * Date: 2026-03-16
 * Last Update: 2026-03-16
 * Public: No
 *
 * Description:
 *     Initializes the bank account data model. Provides default account
 *     schema, player-based account creation, schema migration for
 *     existing accounts.
 *
 * Parameter(s):
 *     None
 *
 * Returns:
 *     Bank model object [HASHMAP OBJECT]
 *
 * Example(s):
 *     call forge_server_bank_fnc_initModel
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(BankModel) = compileFinal createHashMapObject [[
    ["#type", "BankModel"],
    ["defaults", compileFinal {
        private _account = createHashMap;

        _account set ["uid", ""];
        _account set ["name", ""];
        _account set ["bank", 0];
        _account set ["cash", 0];
        _account set ["earnings", 0];
        _account set ["pin", 1234];
        _account set ["transactions", []];

        _account
    }],
    ["fromPlayer", compileFinal {
        params [["_player", objNull, [objNull]]];

        if (_player isEqualTo objNull) exitWith { _self call ["defaults", []] };

        private _account = _self call ["defaults", []];

        _account set ["uid", getPlayerUID _player];
        _account set ["name", name _player];

        _account
    }],
    ["migrate", compileFinal {
        params [["_account", createHashMap, [createHashMap]]];

        private _defaults = _self call ["defaults", []];
        {
            if !(_x in _account) then {
                _account set [_x, _y];
            };
        } forEach _defaults;

        _account
    }]
]];

GVAR(BankModel)
