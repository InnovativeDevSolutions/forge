#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Formats a number with thousands separators and decimal places
 *
 * Arguments:
 * 0: Number <NUMBER>
 *
 * Return Value:
 * Formatted Number <STRING>
 *
 * Examples:
 * [1234567.89] call forge_server_common_fnc_formatNumber
 *
 * Public: Yes
 */

#define PX_DC_SEP "."
#define PX_TH_SEP ","
#define PX_DC_PL 2

private _value = _this;
if (_value isEqualType []) then {
    _value = _value param [0, 0, [0]];
};

private _count = 0;
private _arr = (_value toFixed PX_DC_PL) splitString ".";
private _str = PX_DC_SEP+(_arr select 1);

_arr = toArray(_arr select 0);
reverse _arr;

{
	if (_count == 3) then {
		_count = 0;
		_str = PX_TH_SEP + _str;
	};

	_str = toString[_x] + _str;
	_count = _count + 1;

	true
} count (_arr);

_str
