#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Gets a player object by UID.
 *
 * Arguments:
 * 0: Player UID <STRING>
 *
 * Return Value:
 * Player object or objNull if not found <OBJECT>
 *
 * Example:
 * ["0123456789"] call forge_server_common_fnc_getPlayer
 *
 * Public: Yes
 */

params ["_uid"];

private _player = objNull;

{
    if ((getPlayerUID _x) isEqualTo _uid) exitWith { _player = _x; };
} forEach allPlayers;

_player
