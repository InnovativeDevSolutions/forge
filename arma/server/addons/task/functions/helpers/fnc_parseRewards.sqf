#include "..\script_component.hpp"

/*
 * Author: OpenAI
 * Parses an Eden module reward string into a SQF array.
 *
 * Supports both the preferred comma-separated format:
 *   ItemGPS, FirstAidKit
 * and the legacy SQF array string format:
 *   ["ItemGPS","FirstAidKit"]
 *
 * Arguments:
 * 0: Raw value <STRING>
 * 1: Task label <STRING>
 * 2: Reward key <STRING>
 *
 * Return Value:
 * Parsed reward array <ARRAY>
 *
 * Example:
 * [_logic getVariable ["EquipmentRewards", ""], "attack_01", "equipment"] call forge_server_task_fnc_parseRewards;
 *
 * Public: No
 */

params [["_rawValue", "", [""]], ["_taskLabel", "", [""]], ["_rewardKey", "", [""]]];

private _trimmed = trim _rawValue;
if (_trimmed isEqualTo "") exitWith { [] };
if ((_trimmed select [0, 1]) isEqualTo "[") then {
    private _parsed = parseSimpleArray _trimmed;
    if (_parsed isEqualType []) exitWith { _parsed };

    ["WARNING", format [
        "Task module '%1' reward input '%2' is invalid: %3. Expected comma-separated class names like ItemGPS, FirstAidKit or SQF array syntax like [""ItemGPS"",""FirstAidKit""].",
        _taskLabel,
        _rewardKey,
        _rawValue
    ]] call EFUNC(common,log);

    []
};

private _parsedRewards = [];
{
    private _reward = trim _x;
    if (_reward isEqualTo "") then { continue; };

    _parsedRewards pushBackUnique _reward;
} forEach (_trimmed splitString ",");

_parsedRewards
