#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Generates a secure data object with timestamp, signature, and token.
 *
 * Arguments:
 * 0: Player UID <STRING>
 * 1: Data to secure <CREATEHASHMAP>
 *
 * Return Value:
 * Secure data object <CREATEHASHMAP>
 *
 * Example:
 * ["test_uid", createHashMap] call forge_server_common_fnc_generateSecureData
 * // Returns: ["data", createHashMap], ["timestamp", <NUMBER>], ["signature", <STRING>], ["token", <STRING>]
 *
 * Public: Yes
 */

params [["_uid", "", [""]], ["_data", createHashMap, [createHashMap]]];

private _timestamp = systemTime;
private _sessionToken = EGVAR(actor,PlayerSessions) getOrDefault [_uid, ""];
private _sigInput = format ["%1|%2|%3|%4", _uid, str _data, _timestamp, _sessionToken];
private _signature = _sigInput call EFUNC(common,generateHash);

private _secureData = createHashMap;
_secureData set ["data", _data];
_secureData set ["timestamp", _timestamp];
_secureData set ["signature", _signature];
_secureData set ["token", _sessionToken];

["INFO", format ["Generated secure data for %1: sig=%2", _uid, _signature], nil, nil] call EFUNC(common,log);

_secureData
