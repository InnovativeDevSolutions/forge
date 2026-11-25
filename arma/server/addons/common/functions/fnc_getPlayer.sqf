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

// In single-player the hot stores are keyed by the extension-resolved UID
// (see resolve_uid in the server extension), which never matches
// getPlayerUID -- that returns "_SP_PLAYER_" in SP while the stores hold a
// session-generated numeric UID. Without this fallback the actor snapshot
// (and every other getPlayer caller) got objNull and fell back to cached
// values. There is only one human player in SP, so if no match was found
// the local player object is the player being looked up. Multiplayer is
// untouched: getPlayerUID matches the Steam ID there.
if (isNull _player && { !isMultiplayer } && { !isNull player }) then {
    _player = player;
};

_player
