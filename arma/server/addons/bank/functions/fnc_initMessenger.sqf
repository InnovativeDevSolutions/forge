#include "..\script_component.hpp"

/*
 * File: fnc_initMessenger.sqf
 * Author: IDSolutions
 * Date: 2026-03-16
 * Last Update: 2026-04-02
 * Public: No
 *
 * Description:
 *     Initializes the bank messenger for all server-to-client
 *     communication including account syncs, toast notifications,
 *     and inline bank UI notices.
 *
 * Parameter(s):
 *     None
 *
 * Returns:
 *     Messenger object [HASHMAP OBJECT]
 *
 * Example(s):
 *     call forge_server_bank_fnc_initMessenger
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(BankMessenger) = createHashMapObject [[
    ["#type", "BankMessenger"],
    ["buildAccountPatch", compileFinal {
        params [["_account", createHashMap, [createHashMap]]];

        private _patch = createHashMap;
        {
            if (_x in _account) then {
                _patch set [_x, _account get _x];
            };
        } forEach ["uid", "name", "bank", "cash", "earnings", "transactions"];

        _patch
    }],
    ["sendAccountSync", compileFinal {
        params [["_uid", "", [""]], ["_account", createHashMap, [createHashMap]], ["_event", CRPC(bank,responseSyncBank), [""]]];

        if (_uid isEqualTo "" || { _account isEqualTo createHashMap }) exitWith { false };

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { false };

        [_event, [_self call ["buildAccountPatch", [_account]]], _player] call CFUNC(targetEvent);
        true
    }],
    ["sendNotification", compileFinal {
        params [["_uid", "", [""]], ["_type", "info", [""]], ["_title", "Bank", [""]], ["_message", "", [""]]];

        if (_uid isEqualTo "" || { _message isEqualTo "" }) exitWith { false };

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { false };

        [CRPC(notifications,recieveNotification), [_type, _title, _message], _player] call CFUNC(targetEvent);
        true
    }],
    ["sendAlert", compileFinal {
        params [["_uid", "", [""]], ["_type", "error", [""]], ["_message", "", [""]]];

        if (_uid isEqualTo "" || { _message isEqualTo "" }) exitWith { false };

        private _player = [_uid] call EFUNC(common,getPlayer);
        if (isNull _player) exitWith { false };

        [CRPC(bank,responseBankNotice), [_type, _message], _player] call CFUNC(targetEvent);
        true
    }]
]];

GVAR(BankMessenger)
