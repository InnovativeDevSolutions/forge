#include "..\script_component.hpp"

/*
 * Author: IDSolutions, Blackbox AI, MrPākehā
 * Builds an infantry unit pool for the selected enemy faction. The returned
 * entries match the generator spawn format.
 *
 * Arguments:
 * 0: Faction classname <STRING> (Default: ENEMY_FACTION_STR or "IND_G_F")
 * 1: Fallback side <SIDE> (Default: ENEMY_SIDE or east)
 * 2: Allow side-default fallback units when no faction units exist <BOOL>
 *    (Default: true)
 *
 * Return Value:
 * Unit definitions with vehicle, rank, and position keys <ARRAY>
 *
 * Public: No
 */

params [
    ["_faction", missionNamespace getVariable ["ENEMY_FACTION_STR", "IND_G_F"], [""]],
    ["_fallbackSide", missionNamespace getVariable ["ENEMY_SIDE", east], [east]],
    ["_allowSideFallback", true, [false]]
];

if (_faction isEqualTo "") then {
    _faction = "IND_G_F";
};

private _pool = [];
private _sideNumber = [_fallbackSide] call BIS_fnc_sideID;

// Check CfgFactionUnitMap first for explicit faction unit definitions
private _factionMapRoot = missionConfigFile >> "CfgFactionUnitMap";
if !(isClass _factionMapRoot) then {
    _factionMapRoot = configFile >> "CfgFactionUnitMap";
};

private _factionMapConfig = _factionMapRoot >> _faction;
if (isClass _factionMapConfig) then {
    {
        private _vehicle = getText (_x >> "vehicle");
        if (_vehicle isEqualTo "" || { !(isClass (configFile >> "CfgVehicles" >> _vehicle)) }) then {
            continue;
        };

        _pool pushBack createHashMapFromArray [
            ["vehicle", _vehicle],
            ["rank", getText (_x >> "rank")],
            ["position", getArray (_x >> "position")]
        ];
    } forEach ("true" configClasses (_factionMapConfig >> "Units"));
};

// Fall back to config traversal if no explicit mapping exists.
if (_pool isEqualTo []) then {
    private _factionFallback = _faction;

    {
        if (getNumber (_x >> "scope") < 2) then { continue; };
        private _unitFaction = getText (_x >> "faction");
        if ((_unitFaction isNotEqualTo _faction) && (_unitFaction isNotEqualTo _factionFallback)) then { continue; };
        if (getNumber (_x >> "side") isNotEqualTo _sideNumber) then { continue; };
        if !(configName _x isKindOf "CAManBase") then { continue; };

        private _className = configName _x;
        private _upperClassName = toUpperANSI _className;
        private _rank = "PRIVATE";

        if (
            (_upperClassName find "_SL_" >= 0)
            || { _upperClassName find "_TL_" >= 0 }
            || { _upperClassName find "OFFICER" >= 0 }
            || { _upperClassName find "COMMANDER" >= 0 }
        ) then {
            _rank = "SERGEANT";
        };

        _pool pushBack createHashMapFromArray [
            ["vehicle", _className],
            ["rank", _rank],
            ["position", [0, 0, 0]]
        ];
    } forEach ("true" configClasses (configFile >> "CfgVehicles"));
};

if (_pool isEqualTo [] && { _allowSideFallback }) then {
    private _fallbackUnits = switch (_fallbackSide) do {
        case east: { ["O_Soldier_SL_F", "O_Soldier_TL_F", "O_Soldier_F", "O_Soldier_AR_F", "O_Soldier_GL_F", "O_medic_F"] };
        case resistance: { ["I_G_Soldier_SL_F", "I_G_Soldier_TL_F", "I_G_Soldier_F", "I_G_Soldier_AR_F", "I_G_medic_F"] };
        default { ["O_Soldier_SL_F", "O_Soldier_TL_F", "O_Soldier_F", "O_Soldier_AR_F", "O_medic_F"] };
    };

    {
        _pool pushBack createHashMapFromArray [
            ["vehicle", _x],
            ["rank", ["PRIVATE", "SERGEANT"] select (_forEachIndex == 0)],
            ["position", [0, 0, 0]]
        ];
    } forEach _fallbackUnits;
};

_pool
