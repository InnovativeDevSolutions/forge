#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Generates a 6-digit hash from input string using DJB2 algorithm.
 *
 * Arguments:
 * 0: Input string to hash <STRING>
 *
 * Return Value:
 * 6-digit hash string <STRING>
 *
 * Example:
 * ["test_input"] call forge_server_common_fnc_generateHash
 * // Returns: "461324"
 *
 * Public: Yes
 */

params [["_input", "", [""]]];

private _hash = 5381;
private _chars = toArray _input;

{
    _hash = ((_hash * 33) + _x) mod 999999;
} forEach _chars;

private _result = str _hash;

while { count _result < 6 } do { _result = "0" + _result; };

_result
