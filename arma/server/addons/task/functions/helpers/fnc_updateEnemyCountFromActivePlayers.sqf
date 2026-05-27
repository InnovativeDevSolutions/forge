#include "..\script_component.hpp"

/*
 * Author: IDSolutions, Blackbox AI, MrPākehā
 * Calculates enemy spawn scaling from active player count and stores the
 * result in missionNamespace for mission generators.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Enemy count multiplier <NUMBER>
 *
 * Public: No
 */

if !(isServer) exitWith { 1 };

private _table = missionNamespace getVariable [
    "forge_pmc_enemyCountMultiplierTable",
    [
        [1, 2, 0.75],
        [3, 6, 1.0],
        [7, 10, 1.25],
        [11, 19, 1.5]
    ]
];

private _minMultiplier = missionNamespace getVariable ["forge_pmc_enemyCountMultiplierMin", 0.5];
private _maxMultiplier = missionNamespace getVariable ["forge_pmc_enemyCountMultiplierMax", 2.0];

private _activeCount = {
    (isPlayer _x) && { alive _x }
} count allPlayers;

private _activeCountSafe = _activeCount max 1;
private _multiplier = 1;

{
    _x params ["_min", "_max", "_value"];
    if (_activeCountSafe >= _min && { _activeCountSafe <= _max }) exitWith {
        _multiplier = _value;
    };
} forEach _table;

_multiplier = (_multiplier max _minMultiplier) min _maxMultiplier;

missionNamespace setVariable ["forge_pmc_activePlayerCount", _activeCountSafe, true];
missionNamespace setVariable ["forge_pmc_enemyCountMultiplier", _multiplier, true];

["INFO", format [
    "Mission enemy scaling updated. ActivePlayers=%1, Multiplier=%2",
    _activeCountSafe,
    _multiplier
]] call EFUNC(common,log);

_multiplier
