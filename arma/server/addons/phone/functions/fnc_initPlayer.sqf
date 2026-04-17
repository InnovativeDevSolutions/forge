#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initialize phone system for a player
 *
 * Arguments:
 * 0: Player UID <STRING>
 *
 * Return Value:
 * Success <BOOL>
 *
 * Examples:
 * ["76561198123456789"] call forge_server_phone_fnc_initPlayer
 *
 * Public: Yes
 */

params [["_uid", "", [""]]];

if (_uid isEqualTo "") exitWith { 
    diag_log "[FORGE:Server:Phone] Empty UID provided to initPlayer";
    false 
};

// Initialize phone store for player
GVAR(PhoneStore) call ["init", [_uid]];

diag_log format ["[FORGE:Server:Phone] Initialized phone for player %1", _uid];
true
