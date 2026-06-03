#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Initializes the framework mission setup service.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Mission setup service object <HASHMAP OBJECT>
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(MissionSetupServiceBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "MissionSetupServiceBaseClass"],
    ["getMissionConfig", compileFinal {
        private _missionConfig = missionConfigFile >> "CfgMissions";
        if !(isClass _missionConfig) then {
            _missionConfig = configFile >> "CfgMissions";
        };
        _missionConfig
    }],
    ["numberOrDefault", compileFinal {
        params ["_value", "_default"];

        if (_value isEqualType "") exitWith {
            private _parsed = parseNumber _value;
            [_default, _parsed] select (_parsed isEqualType 0)
        };

        if (_value isEqualType 0) exitWith { _value };
        _default
    }],
    ["resolveFactionSide", compileFinal {
        params [["_faction", "", [""]], ["_fallbackSide", east]];

        private _cfgFaction = configFile >> "CfgFactionClasses" >> _faction;
        if !(isClass _cfgFaction) exitWith { _fallbackSide };

        private _sideNumber = -1;
        if (isNumber (_cfgFaction >> "side")) then {
            _sideNumber = getNumber (_cfgFaction >> "side");
        } else {
            private _sideText = toUpperANSI getText (_cfgFaction >> "side");
            _sideNumber = switch (_sideText) do {
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

        switch (_sideNumber) do {
            case 0: { east };
            case 2: { resistance };
            default { _fallbackSide };
        }
    }],
    ["apply", compileFinal {
        if !(isServer) exitWith { false };

        params [
            ["_overrides", createHashMap, [createHashMap]]
        ];

        private _missionConfig = _self call ["getMissionConfig", []];
        private _paramOrDefault = {
            params ["_varName", "_default", "_overrides"];

            if (_varName in _overrides) exitWith {
                _overrides getOrDefault [_varName, _default]
            };

            missionNamespace getVariable [_varName, _default]
        };

        private _maxConcurrent = [
            ["maxConcurrentMissions", getNumber (_missionConfig >> "maxConcurrentMissions"), _overrides] call _paramOrDefault,
            3
        ] call (_self get "numberOrDefault");
        private _interval = [
            ["missionInterval", getNumber (_missionConfig >> "missionInterval"), _overrides] call _paramOrDefault,
            300
        ] call (_self get "numberOrDefault");
        private _locationReuseCooldown = [
            ["locationReuseCooldown", getNumber (_missionConfig >> "locationReuseCooldown"), _overrides] call _paramOrDefault,
            900
        ] call (_self get "numberOrDefault");

        private _moneyMin = [["moneyMin", 500, _overrides] call _paramOrDefault, 500] call (_self get "numberOrDefault");
        private _moneyMax = [["moneyMax", 1000, _overrides] call _paramOrDefault, 1000] call (_self get "numberOrDefault");
        private _repMin = [["reputationMin", 25, _overrides] call _paramOrDefault, 25] call (_self get "numberOrDefault");
        private _repMax = [["reputationMax", 100, _overrides] call _paramOrDefault, 100] call (_self get "numberOrDefault");
        private _penMin = [["penaltyMin", -5, _overrides] call _paramOrDefault, -5] call (_self get "numberOrDefault");
        private _penMax = [["penaltyMax", -25, _overrides] call _paramOrDefault, -25] call (_self get "numberOrDefault");
        private _timeMin = [["timeLimitMin", 600, _overrides] call _paramOrDefault, 600] call (_self get "numberOrDefault");
        private _timeMax = [["timeLimitMax", 900, _overrides] call _paramOrDefault, 900] call (_self get "numberOrDefault");
        private _generatorProvider = _overrides getOrDefault ["generatorProvider", GETGVAR(generatorProvider,"builtin")];
        if !(_generatorProvider isEqualType "") then { _generatorProvider = str _generatorProvider; };
        _generatorProvider = toLowerANSI _generatorProvider;
        if !(_generatorProvider in ["builtin", "custom"]) then { _generatorProvider = "builtin"; };

        private _enemyFaction = _overrides getOrDefault [
            "enemyFaction",
            GETMVAR(ENEMY_FACTION_STR,GETMVAR(enemyFaction,"IND_G_F"))
        ];
        if !(_enemyFaction isEqualType "") then { _enemyFaction = str _enemyFaction; };
        if (_enemyFaction isEqualTo "") then { _enemyFaction = "IND_G_F"; };

        _maxConcurrent = (_maxConcurrent max 1) min 50;
        _interval = _interval max 1;
        _locationReuseCooldown = _locationReuseCooldown max 0;

        _moneyMin = _moneyMin max 0;
        _moneyMax = _moneyMax max _moneyMin;

        _repMin = _repMin max -100000;
        _repMax = _repMax max _repMin;

        _penMin = _penMin min 0;
        _penMax = _penMax min 0;

        _timeMin = _timeMin max 1;
        _timeMax = _timeMax max _timeMin;

        private _settings = createHashMapFromArray [
            ["useMenuSettings", true],
            ["maxConcurrentMissions", _maxConcurrent],
            ["missionInterval", _interval],
            ["locationReuseCooldown", _locationReuseCooldown],
            ["moneyMin", _moneyMin],
            ["moneyMax", _moneyMax],
            ["reputationMin", _repMin],
            ["reputationMax", _repMax],
            ["penaltyMin", _penMin],
            ["penaltyMax", _penMax],
            ["timeLimitMin", _timeMin],
            ["timeLimitMax", _timeMax],
            ["enemyFaction", _enemyFaction],
            ["generatorProvider", _generatorProvider]
        ];

        SETMPVAR(GVAR(missionSetup_settings),_settings);
        SETMPVAR(GVAR(missionSetup_settingsApplied),true);
        SETMPVAR(GVAR(generatorProvider),_generatorProvider);

        private _side = _self call ["resolveFactionSide", [_enemyFaction, east]];
        ENEMY_SIDE = _side;
        SETMPVAR(ENEMY_FACTION_STR,_enemyFaction);
        publicVariable "ENEMY_SIDE";

        ["INFO", format [
            "Framework mission setup applied. Faction=%1, Side=%2, MaxConcurrent=%3, Interval=%4, GeneratorProvider=%5",
            _enemyFaction,
            _side,
            _maxConcurrent,
            _interval,
            _generatorProvider
        ]] call EFUNC(common,log);

        if !(isNil QEGVAR(common,EventBus)) then {
            EGVAR(common,EventBus) call ["emit", [
                "mission.setup.applied",
                createHashMapFromArray [["settings", _settings]],
                createHashMapFromArray [["source", "task"]]
            ]];
        };

        true
    }]
];

GVAR(MissionSetupService) = createHashMapObject [GVAR(MissionSetupServiceBaseClass)];
GVAR(MissionSetupService)
