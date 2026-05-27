#include "..\script_component.hpp"

/*
 * Author: IDSolutions, Blackbox AI, MrPākehā
 * Defines the Defend mission generator base class used by the dynamic
 * mission manager. The generator selects a location, spawns required
 * entities, registers a Forge task, and cleans up manager state when the
 * task completes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * N/A. Defines GVAR(DefendMissionGeneratorBaseClass) in missionNamespace.
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(DefendMissionGeneratorBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "DefendMissionGeneratorBaseClass"],
    ["#create", compileFinal {
        private _missionConfig = missionConfigFile >> "CfgMissions";
        if !(isClass _missionConfig) then {
            _missionConfig = configFile >> "CfgMissions";
        };
        _self set ["missionConfig", _missionConfig];
        _self set ["aiGroupsConfig", (_missionConfig >> "AIGroups")];
        _self set ["defendConfig", (_missionConfig >> "MissionTypes" >> "Defend")];
        _self set ["generatorType", "defend"];
    }],
    ["getGeneratorType", compileFinal {
        _self getOrDefault ["generatorType", "defend"]
    }],
    ["getMissionInterval", compileFinal {
        private _missionConfig = _self getOrDefault ["missionConfig", configNull];
        private _interval = getNumber (_missionConfig >> "missionInterval");
        if (_interval <= 0) then { _interval = 300; };
        _interval
    }],
    ["getMaxConcurrentMissions", compileFinal {
        private _missionConfig = _self getOrDefault ["missionConfig", configNull];
        private _maxConcurrent = getNumber (_missionConfig >> "maxConcurrentMissions");
        if (_maxConcurrent <= 0) then { _maxConcurrent = 1; };
        _maxConcurrent
    }],
    ["getLocationReuseCooldown", compileFinal {
        private _missionConfig = _self getOrDefault ["missionConfig", configNull];
        private _cooldown = getNumber (_missionConfig >> "locationReuseCooldown");
        if (_cooldown <= 0) then { _cooldown = 900; };
        _cooldown
    }],
    ["pruneRecentLocations", compileFinal {
        params [["_manager", createHashMapObject [createHashMapFromArray []], [createHashMap]]];

        private _recentLocationRegistry = _manager getOrDefault ["recentLocationRegistry", []];
        private _reuseCooldown = _self call ["getLocationReuseCooldown", []];
        private _now = serverTime;

        _recentLocationRegistry = _recentLocationRegistry select {
            private _usedAt = _x param [1, -1, [0]];
            (_usedAt >= 0) && { (_now - _usedAt) < _reuseCooldown }
        };

        _manager set ["recentLocationRegistry", _recentLocationRegistry];
        _recentLocationRegistry
    }],
    ["getActiveMissionPositions", compileFinal {
        params [["_manager", createHashMapObject [createHashMapFromArray []], [createHashMap]]];

        private _activeMissionRegistry = _manager getOrDefault ["activeMissionRegistry", createHashMap];
        private _positions = [];
        {
            if ((_y getOrDefault ["generatorType", ""]) isNotEqualTo "defend") then { continue; };

            private _position = _y getOrDefault ["position", []];
            if (_position isEqualType [] && { count _position >= 2 }) then {
                _positions pushBack _position;
            };
        } forEach _activeMissionRegistry;
        _positions
    }],
    ["selectLocation", compileFinal {
        params [["_manager", createHashMapObject [createHashMapFromArray []], [createHashMap]]];

        private _worldSize = worldSize;
        private _center = [_worldSize / 2, _worldSize / 2, 0];
        private _safeDist = 800;
        private _playerPos = _center;
        private _minEdgeDist = _safeDist + 200;
        private _searchRadius = (_worldSize / 2 - _minEdgeDist) max 500;

        private _recentLocationRegistry = _self call ["pruneRecentLocations", [_manager]];
        private _activeMissionPositions = _self call ["getActiveMissionPositions", [_manager]];

        private _blkListMarkers = allMapMarkers select { markerShape _x in ["RECTANGLE", "ELLIPSE"] };
        _blkListMarkers = _blkListMarkers select {
            (
                (toLowerANSI _x find "blklist") == 0
                || { (toLowerANSI (markerText _x) find "blklist") == 0 }
            )
            && { getMarkerPos _x distance2D [0, 0] > 0 }
        };

        private _taskPos = [];
        private _attempt = 0;
        private _maxAttempts = 50;

        while { _attempt < _maxAttempts && { _taskPos isEqualTo [] } } do {
            _attempt = _attempt + 1;
            private _candidate = [_center, _searchRadius, _searchRadius, 3, 0, 0.3, 0] call BFUNC(findSafePos);

            if (_candidate isEqualTo [0, 0, 0]) then { continue; };
            if (_candidate distance2D _playerPos < _safeDist) then { continue; };

            private _isTooClose = false;
            {
                private _prevPos = _x param [0, [], [[]]];
                if (_prevPos isEqualType [] && { count _prevPos >= 2 } && { _candidate distance2D _prevPos < 500 }) exitWith {
                    _isTooClose = true;
                };
            } forEach _recentLocationRegistry;

            if (_isTooClose) then { continue; };

            {
                if (_candidate distance2D _x < 500) exitWith {
                    _isTooClose = true;
                };
            } forEach _activeMissionPositions;

            if (_isTooClose) then { continue; };

            private _inBlkList = false;
            {
                if (_candidate inArea _x) exitWith {
                    _inBlkList = true;
                };
            } forEach _blkListMarkers;

            if !(_inBlkList) then {
                _taskPos = _candidate;
            };
        };

        if (_taskPos isEqualTo []) exitWith {
            ["WARNING", "Defend mission generator: selectLocation failed to find a valid dynamic position."] call EFUNC(common,log);
            createHashMap
        };

        createHashMapFromArray [
            ["position", _taskPos],
            ["grid", mapGridPosition _taskPos]
        ]
    }],

    ["buildDefendTemplateGroups", compileFinal {
        params [['_position', [0, 0, 0], [[]]]];

        private _aiGroupsConfig = _self getOrDefault ["aiGroupsConfig", configNull];
        private _defendConfig = _self getOrDefault ["defendConfig", configNull];
        private _groups = [];

        {
            if ("defend" in getArray (_x >> "suitable")) then {
                _groups pushBack _x;
            };
        } forEach ("true" configClasses _aiGroupsConfig);

        if (_groups isEqualTo []) then {
            {
                if ("attack" in getArray (_x >> "suitable")) then {
                    _groups pushBack _x;
                };
            } forEach ("true" configClasses _aiGroupsConfig);
        };

        private _side = missionNamespace getVariable ["ENEMY_SIDE", east];
        private _sideText = str _side;
        [] call FUNC(updateEnemyCountFromActivePlayers);
        private _enemyMult = missionNamespace getVariable ["forge_pmc_enemyCountMultiplier", 1];
        private _unitCountConfig = getArray (_defendConfig >> "unitsPerWave");
        private _minUnits = _unitCountConfig select 0;
        private _maxUnits = _unitCountConfig select 1;
        if (_minUnits <= 0) then { _minUnits = 4; };
        if (_maxUnits < _minUnits) then { _maxUnits = _minUnits; };
        _minUnits = floor ((_minUnits max 1) * _enemyMult);
        _maxUnits = ceil ((_maxUnits max _minUnits) * _enemyMult);
        if (_minUnits <= 0) then { _minUnits = 1; };
        if (_maxUnits < _minUnits) then { _maxUnits = _minUnits; };
        private _targetUnitCount = _minUnits + floor random ((_maxUnits - _minUnits) + 1);

        private _enemyFaction = missionNamespace getVariable ["ENEMY_FACTION_STR", missionNamespace getVariable ["enemyFaction", "IND_G_F"]];
        private _unitPool = [_enemyFaction, _side] call FUNC(getEnemyFactionUnitPool);

        if (_unitPool isEqualTo [] && { _groups isNotEqualTo [] }) then {
            {
                if ((getText (_x >> "side")) isNotEqualTo _sideText) then { continue; };

                {
                    _unitPool pushBack createHashMapFromArray [
                        ["vehicle", getText (_x >> "vehicle")],
                        ["rank", getText (_x >> "rank")],
                        ["position", getArray (_x >> "position")]
                    ];
                } forEach ("true" configClasses (_x >> "Units"));
            } forEach _groups;
        };

        if (_unitPool isEqualTo []) exitWith { [] };

        private _templateGroup = [];
        for "_i" from 1 to _targetUnitCount do {
            private _unitDef = selectRandom _unitPool;
            private _unitClass = _unitDef getOrDefault ["vehicle", ""];
            if (_unitClass isNotEqualTo "") then {
                _templateGroup pushBack createHashMapFromArray [
                    ["type", _unitClass],
                    ["side", _side],
                    ["rank", _unitDef getOrDefault ["rank", "PRIVATE"]],
                    ["skill", 0.45 + random 0.25]
                ];
            };
        };

        if (_templateGroup isEqualTo []) exitWith { [] };
        [_templateGroup]
    }],

    ["rollRewards", compileFinal {
        private _defendConfig = _self getOrDefault ["defendConfig", configNull];
        private _equipmentRewards = [];
        private _supplyRewards = [];
        private _weaponRewards = [];
        private _vehicleRewards = [];
        private _specialRewards = [];

        {
            private _category = _x;
            {
                _x params ["_item", "_chance"];
                if (random 1 < _chance) then {
                    switch (_category) do {
                        case "equipment": { _equipmentRewards pushBack _item; };
                        case "supplies": { _supplyRewards pushBack _item; };
                        case "weapons": { _weaponRewards pushBack _item; };
                        case "vehicles": { _vehicleRewards pushBack _item; };
                        case "special": { _specialRewards pushBack _item; };
                    };
                };
            } forEach (getArray (_defendConfig >> "Rewards" >> _category));
        } forEach ["equipment", "supplies", "weapons", "vehicles", "special"];

        createHashMapFromArray [
            ["equipment", _equipmentRewards],
            ["supplies", _supplyRewards],
            ["weapons", _weaponRewards],
            ["vehicles", _vehicleRewards],
            ["special", _specialRewards]
        ]
    }],

    ["startMission", compileFinal {
        params [["_manager", createHashMapObject [createHashMapFromArray []], [createHashMap]]];

        private _defendConfig = _self getOrDefault ["defendConfig", configNull];
        private _locationData = _self call ["selectLocation", [_manager]];
        if (_locationData isEqualTo createHashMap) exitWith { "" };

        private _position = _locationData getOrDefault ["position", [0, 0, 0]];
        private _grid = _locationData getOrDefault ["grid", mapGridPosition _position];

        private _taskID = format ["task_defend_%1", round (diag_tickTime * 1000)];
        private _rewardRange = [_defendConfig, ["Rewards", "money"], "moneyMin", "moneyMax", [40000, 90000]] call FUNC(getMissionSettingRange);
        private _reputationRange = [_defendConfig, ["Rewards", "reputation"], "reputationMin", "reputationMax", [8, 18]] call FUNC(getMissionSettingRange);
        private _penaltyRange = [_defendConfig, ["penalty"], "penaltyMin", "penaltyMax", [-12, -4]] call FUNC(getMissionSettingRange);
        private _timeRange = [_defendConfig, ["timeLimit"], "timeLimitMin", "timeLimitMax", [300, 1800]] call FUNC(getMissionSettingRange);
        private _rewards = _self call ["rollRewards"];
        private _enemyTemplates = _self call ["buildDefendTemplateGroups", [_position]];
        if (_enemyTemplates isEqualTo []) exitWith { "" };

        private _fundsReward = _rewardRange call BFUNC(randomNum);
        private _reputationReward = _reputationRange call BFUNC(randomNum);
        private _reputationPenalty = _penaltyRange call BFUNC(randomNum);
        private _timeLimit = _timeRange call BFUNC(randomNum);

        private _minWaves = getNumber (_defendConfig >> "minWaves");
        if (_minWaves <= 0) then { _minWaves = 3; };
        private _maxWaves = getNumber (_defendConfig >> "maxWaves");
        if (_maxWaves < _minWaves) then { _maxWaves = _minWaves; };
        private _limitSuccess = _minWaves + floor random ((_maxWaves - _minWaves) + 1);
        private _waveCooldown = getNumber (_defendConfig >> "waveCooldown");
        if (_waveCooldown <= 0) then { _waveCooldown = 300; };
        private _minBlufor = 1;

        private _defenseZone = format ["forge_defend_zone_%1", _taskID];
        createMarker [_defenseZone, _position];
        _defenseZone setMarkerShapeLocal "ELLIPSE";
        _defenseZone setMarkerSizeLocal [25, 25];
        _defenseZone setMarkerTextLocal format ["Defense Zone %1", _grid];
        _defenseZone setMarkerAlphaLocal 0.5;
        _defenseZone setMarkerBrushLocal "DiagGrid";
        _defenseZone setMarkerColor "ColorOrange";

        private _success = [
            "defend",
            _taskID,
            _position,
            format ["Defend: Grid %1", _grid],
            format ["Hold the area in and around grid %1.", _grid],
            createHashMapFromArray [],
            createHashMapFromArray [
                ["limitFail", 0],
                ["limitSuccess", _limitSuccess],
                ["funds", _fundsReward],
                ["ratingFail", _reputationPenalty],
                ["ratingSuccess", _reputationReward],
                ["endSuccess", false],
                ["endFail", false],
                ["timeLimit", _timeLimit],
                ["equipment", _rewards get "equipment"],
                ["supplies", _rewards get "supplies"],
                ["weapons", _rewards get "weapons"],
                ["vehicles", _rewards get "vehicles"],
                ["special", _rewards get "special"],
                ["defenseZone", _defenseZone],
                ["defendTime", _timeLimit],
                ["waveCount", _limitSuccess],
                ["waveCooldown", _waveCooldown],
                ["minBlufor", _minBlufor],
                ["enemyTemplates", _enemyTemplates]
            ],
            0,
            "",
            "mission_manager"
        ] call FUNC(startTask);

        if !(_success) exitWith {
            deleteMarker _defenseZone;
            ""
        };

        private _activeMissionRegistry = _manager getOrDefault ["activeMissionRegistry", createHashMap];
        _activeMissionRegistry set [_taskID, createHashMapFromArray [
            ["generatorType", _self call ["getGeneratorType", []]],
            ["position", _position],
            ["markers", [_defenseZone]],
            ["startedAt", serverTime]
        ]];
        _manager set ["activeMissionRegistry", _activeMissionRegistry];

        _taskID
    }],

    ["completeMission", compileFinal {
        params [
            ["_manager", createHashMapObject [createHashMapFromArray []], [createHashMap]],
            ["_taskID", "", [""]]
        ];

        if (_taskID isEqualTo "") exitWith { false };

        private _activeMissionRegistry = _manager getOrDefault ["activeMissionRegistry", createHashMap];
        private _missionRecord = _activeMissionRegistry getOrDefault [_taskID, createHashMap];
        if ((_missionRecord getOrDefault ["generatorType", ""]) isNotEqualTo (_self call ["getGeneratorType", []])) exitWith { false };

        private _position = _missionRecord getOrDefault ["position", []];
        private _markers = _missionRecord getOrDefault ["markers", []];
        {
            if (_x isEqualType "" && { _x in allMapMarkers }) then {
                deleteMarker _x;
            };
        } forEach _markers;

        _activeMissionRegistry deleteAt _taskID;
        _manager set ["activeMissionRegistry", _activeMissionRegistry];

        if (_position isEqualType [] && { count _position >= 2 }) then {
            private _recentLocationRegistry = _manager getOrDefault ["recentLocationRegistry", []];
            _recentLocationRegistry pushBack [_position, serverTime];
            _manager set ["recentLocationRegistry", _recentLocationRegistry];
        };

        true
    }]
];
