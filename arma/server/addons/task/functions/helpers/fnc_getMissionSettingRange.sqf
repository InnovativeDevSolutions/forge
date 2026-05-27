#include "..\script_component.hpp"

/*
 * Author: IDSolutions, Blackbox AI, MrPākehā
 * Resolves a numeric mission range, preferring startup UI settings when
 * present and falling back to CfgMissions values.
 *
 * Arguments:
 * 0: Root config class <CONFIG>
 * 1: Config path segments to the range array <ARRAY>
 * 2: Mission settings min key <STRING>
 * 3: Mission settings max key <STRING>
 * 4: Fallback [min, max] range <ARRAY> (Default: [0, 0])
 *
 * Return Value:
 * Numeric [min, max] range <ARRAY>. Reversed input is sorted so reputation-hit
 * fields can use -5 / -25 semantics while generators still receive [-25, -5].
 *
 * Public: No
 */

params [
    ["_config", configNull, [configNull]],
    ["_path", [], [[]]],
    ["_minKey", "", [""]],
    ["_maxKey", "", [""]],
    ["_fallback", [0, 0], [[]]]
];

private _rangeConfig = _config;
{
    _rangeConfig = _rangeConfig >> _x;
} forEach _path;

private _range = getArray _rangeConfig;
private _fallbackMin = _fallback param [0, 0, [0]];
private _fallbackMax = _fallback param [1, _fallbackMin, [0]];

private _min = _range param [0, _fallbackMin, [0]];
private _max = _range param [1, _fallbackMax, [0]];

private _settings = missionNamespace getVariable ["forge_pmc_missionSettings", createHashMap];
if (_settings isEqualType createHashMap) then {
    _min = _settings getOrDefault [_minKey, _min];
    _max = _settings getOrDefault [_maxKey, _max];
};

if (_max < _min) then {
    private _swap = _min;
    _min = _max;
    _max = _swap;
};

[_min, _max]
