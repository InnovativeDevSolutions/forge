#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Reads shared Eden task chain attributes and returns startTask parameter pairs.
 *
 * Arguments:
 * 0: Logic <OBJECT>
 *
 * Return Value:
 * Task parameter pairs <ARRAY>
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

private _prerequisiteRaw = _logic getVariable ["PrerequisiteTaskIds", ""];
private _prerequisiteTaskIds = [];

if (_prerequisiteRaw isEqualType []) then {
    {
        if !(_x isEqualType "") then { continue; };
        if (_x isEqualTo "") then { continue; };
        _prerequisiteTaskIds pushBackUnique _x;
    } forEach _prerequisiteRaw;
} else {
    if (_prerequisiteRaw isEqualType "") then {
        {
            if (_x isEqualTo "") then { continue; };
            _prerequisiteTaskIds pushBackUnique _x;
        } forEach (_prerequisiteRaw splitString ", ");
    };
};

[
    ["prerequisiteTaskIds", _prerequisiteTaskIds]
]
