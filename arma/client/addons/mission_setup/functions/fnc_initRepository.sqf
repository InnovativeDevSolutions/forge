#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the client mission setup repository.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Mission setup repository object <HASHMAP OBJECT>
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(MissionSetupRepositoryBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "MissionSetupRepositoryBaseClass"],
    ["getEnemyFactionOptions", compileFinal {
        private _config = missionConfigFile >> "CfgEnemyFactions";
        if !(isClass _config) then { _config = configFile >> "CfgEnemyFactions"; };

        private _allowedSides = getArray (_config >> "sides");
        if (_allowedSides isEqualTo []) then { _allowedSides = [0, 2]; };

        private _denylist = getArray (_config >> "denylist");
        private _overridesConfig = _config >> "Overrides";

        private _spawnableFactions = createHashMap;
        {
            if (getNumber (_x >> "scope") < 2) then { continue; };
            if !(configName _x isKindOf "CAManBase") then { continue; };

            private _faction = getText (_x >> "faction");
            if (_faction isEqualTo "") then { continue; };

            private _side = getNumber (_x >> "side");
            if !(_side in _allowedSides) then { continue; };

            _spawnableFactions set [_faction, true];
        } forEach ("true" configClasses (configFile >> "CfgVehicles"));

        private _mappedFactions = createHashMap;
        private _factionMapRoot = missionConfigFile >> "CfgFactionUnitMap";
        if !(isClass _factionMapRoot) then { _factionMapRoot = configFile >> "CfgFactionUnitMap"; };

        {
            private _unitsConfig = _x >> "Units";
            if !(isClass _unitsConfig) then { continue; };

            private _hasUnits = false;
            {
                private _vehicle = getText (_x >> "vehicle");
                if (_vehicle isNotEqualTo "" && { isClass (configFile >> "CfgVehicles" >> _vehicle) }) exitWith { _hasUnits = true; };
            } forEach ("true" configClasses _unitsConfig);

            if (_hasUnits) then { _mappedFactions set [configName _x, true]; };
        } forEach ("true" configClasses _factionMapRoot);

        private _getFactionSideNumber = {
            params ["_factionConfig"];

            if (isNumber (_factionConfig >> "side")) exitWith { getNumber (_factionConfig >> "side") };
            switch (toUpperANSI getText (_factionConfig >> "side")) do {
                case "0";
                case "EAST";
                case "OPFOR": { 0 };
                case "2";
                case "GUER";
                case "GUERRILA";
                case "GUERRILLA";
                case "INDEPENDENT";
                case "RESISTANCE": { 2 };
                default { -1 };
            };
        };

        private _records = [];
        private _dynamicIndex = 0;
        {
            private _faction = configName _x;
            if (_faction isEqualTo "") then { continue; };
            if (_faction in _denylist) then { continue; };

            private _side = [_x] call _getFactionSideNumber;
            if !(_side in _allowedSides) then { continue; };
            if (!(_spawnableFactions getOrDefault [_faction, false]) && {
                !(_mappedFactions getOrDefault [_faction, false])
            }) then {
                continue;
            };

            private _override = _overridesConfig >> _faction;
            private _display = getText (_x >> "displayName");
            private _order = 1000 + _dynamicIndex;
            private _value = 1000 + _dynamicIndex;

            if (isClass _override) then {
                private _overrideDisplay = getText (_override >> "display");
                if (_overrideDisplay isNotEqualTo "") then { _display = _overrideDisplay; };
                if (isNumber (_override >> "order")) then { _order = getNumber (_override >> "order"); };
                if (isNumber (_override >> "value")) then { _value = getNumber (_override >> "value"); };
            };
            if (_display isEqualTo "") then { _display = _faction; };

            _records pushBack [_order, _display, _faction, _value];
            _dynamicIndex = _dynamicIndex + 1;
        } forEach ("true" configClasses (configFile >> "CfgFactionClasses"));

        _records sort true;

        private _options = [];
        {
            _x params ["_order", "_display", "_faction", "_value"];
            _options pushBack [_faction, _display, _value];
        } forEach _records;

        if (_options isEqualTo []) then {
            _options = [
                ["OPF_F", "CSAT", 0],
                ["IND_G_F", "FIA", 6]
            ];
        };

        _options
    }],
    ["resolveEnemyFactionParam", compileFinal {
        params [
            ["_value", 6, [0, ""]],
            ["_fallback", "IND_G_F", [""]]
        ];

        if (_value isEqualType "") then {
            if (_value isEqualTo "") exitWith { _fallback };
            if (isClass (configFile >> "CfgFactionClasses" >> _value)) exitWith { _value };
            _value = parseNumber _value;
        };

        private _faction = _fallback;
        {
            _x params ["_optionFaction", "_display", "_optionValue"];
            if (_optionValue isEqualTo _value) exitWith { _faction = _optionFaction; };
        } forEach (_self call ["getEnemyFactionOptions", []]);

        _faction
    }],
    ["buildSetupPayload", compileFinal {
        private _missionConfig = missionConfigFile >> "CfgMissions";
        if !(isClass _missionConfig) then { _missionConfig = configFile >> "CfgMissions"; };

        private _paramOrDefault = {
            params ["_varName", "_default"];

            private _value = missionNamespace getVariable [_varName, _default];
            if (_value isEqualType "") exitWith { parseNumber _value };
            _value
        };

        private _factions = [];
        {
            _x params ["_faction", "_display", "_value"];
            _factions pushBack createHashMapFromArray [
                ["faction", _faction],
                ["display", _display],
                ["value", _value]
            ];
        } forEach (_self call ["getEnemyFactionOptions", []]);

        private _defaultFactionParam = GETMVAR(enemyFaction,6);
        if (_defaultFactionParam isEqualTo 6) then {
            private _paramValue = ["enemyFaction", -1] call BIS_fnc_getParamValue;
            if (_paramValue isNotEqualTo -1) then { _defaultFactionParam = _paramValue; };
        };

        private _defaultFaction = _self call ["resolveEnemyFactionParam", [_defaultFactionParam, "IND_G_F"]];
        private _hasDefaultFaction = false;
        {
            if ((_x getOrDefault ["faction", ""]) isEqualTo _defaultFaction) exitWith { _hasDefaultFaction = true; };
        } forEach _factions;

        if (!_hasDefaultFaction && { _factions isNotEqualTo [] }) then {
            _defaultFaction = (_factions select 0) getOrDefault ["faction", _defaultFaction];
        };

        createHashMapFromArray [
            ["factions", _factions],
            ["settings", createHashMapFromArray [
                ["enemyFaction", _defaultFaction],
                ["maxConcurrentMissions", ["maxConcurrentMissions", getNumber (_missionConfig >> "maxConcurrentMissions")] call _paramOrDefault],
                ["missionInterval", ["missionInterval", getNumber (_missionConfig >> "missionInterval")] call _paramOrDefault],
                ["locationReuseCooldown", ["locationReuseCooldown", getNumber (_missionConfig >> "locationReuseCooldown")] call _paramOrDefault],
                ["moneyMin", ["moneyMin", 500] call _paramOrDefault],
                ["moneyMax", ["moneyMax", 1000] call _paramOrDefault],
                ["reputationMin", ["reputationMin", 25] call _paramOrDefault],
                ["reputationMax", ["reputationMax", 100] call _paramOrDefault],
                ["penaltyMin", ["penaltyMin", -5] call _paramOrDefault],
                ["penaltyMax", ["penaltyMax", -25] call _paramOrDefault],
                ["timeLimitMin", ["timeLimitMin", 600] call _paramOrDefault],
                ["timeLimitMax", ["timeLimitMax", 900] call _paramOrDefault]
            ]]
        ]
    }]
];

GVAR(MissionSetupRepository) = createHashMapObject [GVAR(MissionSetupRepositoryBaseClass)];
GVAR(MissionSetupRepository)
