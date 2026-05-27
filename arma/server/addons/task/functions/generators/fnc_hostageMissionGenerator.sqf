#include "..\script_component.hpp"

/*
 * Author: IDSolutions, Blackbox AI, MrPākehā
 * Defines the Hostage mission generator base class used by the dynamic
 * mission manager. The generator selects a location, spawns required
 * entities, registers a Forge task, and cleans up manager state when the
 * task completes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * N/A. Defines GVAR(HostageMissionGeneratorBaseClass) in missionNamespace.
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(HostageMissionGeneratorBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "HostageMissionGeneratorBaseClass"],
    ["#create", compileFinal {
        private _missionConfig = missionConfigFile >> "CfgMissions";
        if !(isClass _missionConfig) then {
            _missionConfig = configFile >> "CfgMissions";
        };
        _self set ["missionConfig", _missionConfig];
        _self set ["aiGroupsConfig", (_missionConfig >> "AIGroups")];
        _self set ["attackConfig", (_missionConfig >> "MissionTypes" >> "Attack")];
        _self set ["hostageConfig", (_missionConfig >> "MissionTypes" >> "Hostage")];
        _self set ["generatorType", "hostage"];
        ["INFO", format ["Mission generator registered. Type=hostage, ConfigPath=%1", _missionConfig]] call EFUNC(common,log);
    }],
    ["getGeneratorType", compileFinal {
        _self getOrDefault ["generatorType", "hostage"]
    }],
    ["getMissionInterval", compileFinal {
        private _missionConfig = _self getOrDefault ["missionConfig", configNull];
        private _settings = missionNamespace getVariable ["forge_pmc_missionSettings", createHashMap];
        private _interval = getNumber (_missionConfig >> "missionInterval");
        if (_settings isEqualType createHashMap) then {
            _interval = _settings getOrDefault ["missionInterval", _interval];
        };
        if (_interval <= 0) then { _interval = 300; };
        _interval
    }],
    ["getMaxConcurrentMissions", compileFinal {
        private _missionConfig = _self getOrDefault ["missionConfig", configNull];
        private _settings = missionNamespace getVariable ["forge_pmc_missionSettings", createHashMap];
        private _maxConcurrent = getNumber (_missionConfig >> "maxConcurrentMissions");
        if (_settings isEqualType createHashMap) then {
            _maxConcurrent = _settings getOrDefault ["maxConcurrentMissions", _maxConcurrent];
        };
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
            if ((_y getOrDefault ["generatorType", ""]) isNotEqualTo "hostage") then { continue; };

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
            ["WARNING", "Hostage mission generator: selectLocation failed to find a valid dynamic position."] call EFUNC(common,log);
            createHashMap
        };

        // Try to bias hostage/shooter spawns to buildings.
        // We pick a nearby house-like building and later use building positions for spawn points.
        private _building = objNull;
        private _buildingCandidates = nearestObjects [
            _taskPos,
            ["House_F","House","Building","BuildingBase"],
            200
        ];
        if (_buildingCandidates isNotEqualTo []) then {
            _building = selectRandom _buildingCandidates;
        };

        private _buildingPositions = [];
        if !(isNull _building) then {
            // buildingPos returns positions for building interiors; we random-pick from these.
            for "_i" from 0 to 100 do {
                private _bp = _building buildingPos _i;
                if (_bp isEqualTo [0,0,0]) exitWith {};
                _buildingPositions pushBack _bp;
            };
        };

        createHashMapFromArray [
            ["position", _taskPos],
            ["grid", mapGridPosition _taskPos],
            ["building", _building],
            ["buildingPositions", _buildingPositions]
        ]
    }],

    ["spawnPatrolGroup", compileFinal {
        params [["_position", [0, 0, 0], [[]]]];

        private _aiGroupsConfig = _self getOrDefault ["aiGroupsConfig", configNull];
        private _attackConfig = _self getOrDefault ["attackConfig", configNull];
        private _groups = [];
        {
            if ("attack" in getArray (_x >> "suitable")) then {
                _groups pushBack _x;
            };
        } forEach ("true" configClasses _aiGroupsConfig);

        private _side = missionNamespace getVariable ["ENEMY_SIDE", east];
        private _sideText = str _side;
        private _group = createGroup _side;
        [] call FUNC(updateEnemyCountFromActivePlayers);
        private _enemyMult = missionNamespace getVariable ["forge_pmc_enemyCountMultiplier", 1];
        private _minUnitsBase = getNumber (_attackConfig >> "minUnits");
        private _maxUnitsBase = getNumber (_attackConfig >> "maxUnits");
        private _patrolRadius = getNumber (_attackConfig >> "patrolRadius");

        if (_minUnitsBase <= 0) then { _minUnitsBase = 4; };
        if (_maxUnitsBase < _minUnitsBase) then { _maxUnitsBase = _minUnitsBase; };
        if (_patrolRadius <= 0) then { _patrolRadius = 200; };
        private _minUnits = floor ((_minUnitsBase max 1) * _enemyMult);
        private _maxUnits = ceil ((_maxUnitsBase max _minUnitsBase) * _enemyMult);

        if (_minUnits <= 0) then { _minUnits = 1; };
        if (_maxUnits < _minUnits) then { _maxUnits = _minUnits; };

        private _targetUnitCount = floor random [_minUnits, ceil ((_minUnits + _maxUnits) / 2), _maxUnits + 1];
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

        if (_unitPool isEqualTo []) exitWith {
            ["WARNING", format ["Hostage mission generator: selected AI group side '%1' produced an empty unit pool.", _side]] call EFUNC(common,log);
            deleteGroup _group;
            grpNull
        };

        private _leaderPool = _unitPool select {
            toUpperANSI (_x getOrDefault ["rank", "PRIVATE"]) in ["SERGEANT", "LIEUTENANT", "CAPTAIN", "MAJOR", "COLONEL"]
        };
        if (_leaderPool isEqualTo []) then { _leaderPool = +_unitPool; };

        private _spawnDefs = [selectRandom _leaderPool];
        for "_i" from 1 to (_targetUnitCount - 1) do {
            _spawnDefs pushBack (selectRandom _unitPool);
        };

        {
            private _unitClass = _x getOrDefault ["vehicle", ""];
            if (_unitClass isEqualTo "") then { continue; };

            private _unitOffset = +(_x getOrDefault ["position", [0, 0, 0]]);
            if (count _unitOffset < 3) then { _unitOffset resize 3; };
            _unitOffset set [0, (_unitOffset # 0) + (random 6 - 3)];
            _unitOffset set [1, (_unitOffset # 1) + (random 6 - 3)];

            private _unit = _group createUnit [_unitClass, _position vectorAdd _unitOffset, [], 0, "NONE"];
            _unit setRank (_x getOrDefault ["rank", "PRIVATE"]);
        } forEach _spawnDefs;

        [_group, _position, _patrolRadius] call BFUNC(taskPatrol);

        ["INFO", format [
            "Hostage mission generator: spawned attack group. Side=%1, Units=%2, PatrolRadius=%3, Position=%4",
            _side,
            count (units _group),
            _patrolRadius,
            _position
        ]] call EFUNC(common,log);
        _group
    }],

    ["spawnHostageUnits", compileFinal {
        params [['_position', [0, 0, 0], [[]]], ['_buildingPositions', []]];

        private _hostageConfig = _self getOrDefault ["hostageConfig", configNull];
        private _hostageClasses = getArray (_hostageConfig >> "Hostages" >> "civilian") + getArray (_hostageConfig >> "Hostages" >> "military");
        if (_hostageClasses isEqualTo []) exitWith { [] };

        // Prefer interior building positions when available.
        private _spawnBasePos = _position;
        private _useBuildingPositions = (_buildingPositions isEqualTo []);
        if (_buildingPositions isNotEqualTo []) then {
            _useBuildingPositions = false;
        };

        private _hostageCount = 1 + floor (random 2);
        private _hostageGroup = createGroup civilian;
        private _hostages = [];
        for "_i" from 1 to _hostageCount do {
            private _hostageClass = selectRandom _hostageClasses;

            private _hostagePos = [0,0,0];
            if !(_useBuildingPositions) then {
                private _bp = selectRandom _buildingPositions;
                _hostagePos = _bp;
            } else {
                _hostagePos = _spawnBasePos vectorAdd [(random 40 - 20), (random 40 - 20), 0];
            };

            private _hostage = _hostageGroup createUnit [_hostageClass, _hostagePos, [], 0, "NONE"];
            if !(isNull _hostage) then {
                _hostage setCaptive true;
                _hostages pushBack _hostage;
            };
        };

        _hostages
    }],

    ["spawnHostageShooters", compileFinal {
        params [['_position', [0, 0, 0], [[]]], ['_buildingPositions', []]];

        private _aiGroupsConfig = _self getOrDefault ["aiGroupsConfig", configNull];
        private _groups = [];

        {
            if ("hostage" in getArray (_x >> "suitable")) then {
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
        private _group = createGroup _side;

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

        if (_unitPool isEqualTo []) exitWith {
            deleteGroup _group;
            []
        };

        private _shooterCount = 1 + floor (random 3);
        private _shooterDefs = [];
        for "_i" from 1 to _shooterCount do {
            _shooterDefs pushBack (selectRandom _unitPool);
        };

        private _shooters = [];
        // Prefer exterior/adjacent building positions when available.
        private _shootBasePos = _position;
        if (_buildingPositions isNotEqualTo []) then {
            _shootBasePos = selectRandom _buildingPositions;
        };

        {
            private _unitClass = _x getOrDefault ["vehicle", ""];

            if (_unitClass isEqualTo "") exitWith { };

            private _unitOffset = +(_x getOrDefault ["position", [0, 0, 0]]);
            if (count _unitOffset < 3) then { _unitOffset resize 3; };
            _unitOffset set [0, (_unitOffset # 0) + (random 10 - 5)];
            _unitOffset set [1, (_unitOffset # 1) + (random 10 - 5)];

            private _shooter = _group createUnit [_unitClass, _shootBasePos vectorAdd _unitOffset, [], 0, "NONE"];
            if !(isNull _shooter) then {
                _shooter setRank (_x getOrDefault ["rank", "PRIVATE"]);
                _shooters pushBack _shooter;
            };
        } forEach _shooterDefs;

        _shooters
    }],

    ["rollRewards", compileFinal {
        private _hostageConfig = _self getOrDefault ["hostageConfig", configNull];
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
            } forEach (getArray (_hostageConfig >> "Rewards" >> _category));
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

        private _hostageConfig = _self getOrDefault ["hostageConfig", configNull];
        private _locationData = _self call ["selectLocation", [_manager]];
        if (_locationData isEqualTo createHashMap) exitWith { "" };

        private _position = _locationData getOrDefault ["position", [0, 0, 0]];
        private _grid = _locationData getOrDefault ["grid", mapGridPosition _position];
        private _buildingPositions = _locationData getOrDefault ["buildingPositions", []];

        ["INFO", format [
            "Hostage mission generator: selected location. Grid=%1, Position=%2",
            _grid,
            _position
        ]] call EFUNC(common,log);

        private _group = _self call ["spawnPatrolGroup", [_position]];
        if (isNull _group) exitWith {
            ["WARNING", format [
                "Hostage mission generator: spawnPatrolGroup failed for Grid=%1, Position=%2",
                _grid,
                _position
            ]] call EFUNC(common,log);
            ""
        };

        private _units = units _group;
        if (_units isEqualTo []) exitWith {
            ["WARNING", format [
                "Hostage mission generator: spawned group has no units. Grid=%1, Group=%2",
                _grid,
                _group
            ]] call EFUNC(common,log);
            deleteGroup _group;
            ""
        };

        private _taskID = format ["task_hostage_%1", round (diag_tickTime * 1000)];
        private _rewardRange = [_hostageConfig, ["Rewards", "money"], "moneyMin", "moneyMax", [60000, 140000]] call FUNC(getMissionSettingRange);
        private _reputationRange = [_hostageConfig, ["Rewards", "reputation"], "reputationMin", "reputationMax", [12, 25]] call FUNC(getMissionSettingRange);
        private _penaltyRange = [_hostageConfig, ["penalty"], "penaltyMin", "penaltyMax", [-16, -6]] call FUNC(getMissionSettingRange);
        private _timeRange = [_hostageConfig, ["timeLimit"], "timeLimitMin", "timeLimitMax", [600, 900]] call FUNC(getMissionSettingRange);
        private _rewards = _self call ["rollRewards"];

        private _hostageUnits = _self call ["spawnHostageUnits", [_position, _buildingPositions]];
        private _shooterUnits = _self call ["spawnHostageShooters", [_position, _buildingPositions]];
        if (_hostageUnits isEqualTo [] || _shooterUnits isEqualTo []) exitWith { "" };

        private _fundsReward = _rewardRange call BFUNC(randomNum);
        private _reputationReward = _reputationRange call BFUNC(randomNum);
        private _reputationPenalty = _penaltyRange call BFUNC(randomNum);
        private _timeLimit = _timeRange call BFUNC(randomNum);

        private _extZone = format ["forge_hostage_ext_zone_%1", _taskID];

        // Choose extraction marker position:
        // 1) Prefer editor-placed marker containing "ExtZone".
        // 2) Else, pick a safe point inside a marker containing "blklist".
        // 3) Else, pick a safe point anywhere on the map at least 2km away from task position.
        private _extPos = [0, 0, 0];

        private _extZoneMarkers = allMapMarkers select {
            (toLowerANSI (markerText _x) find "extzone") == 0
            || { (toLowerANSI _x find "extzone") == 0 }
        };

        if (_extZoneMarkers isNotEqualTo []) then {
            private _mPos = getMarkerPos (selectRandom _extZoneMarkers);
            // Put marker on ground.
            private _ground = +_mPos;
            private _safe = [_ground, 0, 30, 3, 0, 0.3, 0] call BFUNC(findSafePos);
            if (_safe isNotEqualTo [0, 0, 0]) then {
                _ground = _safe;
            };
            _ground set [2, 0];
            _extPos = _ground;

        } else {
            // Collect blklist-like markers (rectangle/ellipse) that already exist.
            private _blkListMarkers = allMapMarkers select { markerShape _x in ["RECTANGLE", "ELLIPSE"] };
            _blkListMarkers = _blkListMarkers select {
                (
                    (toLowerANSI _x find "blklist") == 0
                    || { (toLowerANSI (markerText _x) find "blklist") == 0 }
                )
                && { getMarkerPos _x distance2D [0, 0] > 0 }
            };

            if (_blkListMarkers isNotEqualTo []) then {
                private _selectedBlk = selectRandom _blkListMarkers;
                private _attempt = 0;
                private _maxAttempts = 60;
                private _found = false;
                while { _attempt < _maxAttempts && { !_found } } do {
                    _attempt = _attempt + 1;
                    private _markerSize = getMarkerSize _selectedBlk;
                    private _markerRadius = ((_markerSize param [0, 250, [0]]) max (_markerSize param [1, 250, [0]])) max 250;
                    private _candidate = [getMarkerPos _selectedBlk, 0, _markerRadius, 3, 0, 0.3, 0] call BFUNC(findSafePos);
                    if (_candidate isEqualTo [0, 0, 0]) then { continue; };
                    if !(_candidate inArea _selectedBlk) then { continue; };
                    // Ensure it's on land.
                    private _try = +_candidate;
                    _try set [2, 0];
                    _extPos = _try;
                    _found = true;
                };
            };

            if (_extPos isEqualTo [0, 0, 0]) then {
                // Fallback: anywhere on map, at least 2km from task location.
                private _taskPos2D = +_position;
                _taskPos2D set [2, 0];

                private _worldMin = 0;
                private _worldMax = worldSize;
                private _attempt = 0;
                private _maxAttempts = 80;
                private _found = false;

                while { _attempt < _maxAttempts && { !_found } } do {
                    _attempt = _attempt + 1;
                    private _randX = _worldMin + random (_worldMax - _worldMin);
                    private _randY = _worldMin + random (_worldMax - _worldMin);
                    private _probe = [_randX, _randY, 0];
                    if ((_probe distance2D _taskPos2D) < 2000) then { continue; };
                    private _safe = [_probe, 0, 500, 3, 0, 0.3, 0] call BFUNC(findSafePos);
                    if (_safe isEqualTo [0, 0, 0]) then { continue; };
                    if ((_safe distance2D _taskPos2D) < 2000) then { continue; };
                    _safe set [2, 0];
                    _extPos = _safe;
                    _found = true;
                };

                // Absolute last resort.
                if (_extPos isEqualTo [0, 0, 0]) then {
                    private _fallback = _position vectorAdd [2500, 0, 0];
                    _fallback set [2, 0];
                    _extPos = _fallback;
                };
            };
        };

        createMarker [_extZone, _extPos];
        _extZone setMarkerShapeLocal "ELLIPSE";
        _extZone setMarkerSizeLocal [25, 25];
        _extZone setMarkerTextLocal format ["Hostage Extraction %1", _grid];
        _extZone setMarkerAlphaLocal 0.5;
        _extZone setMarkerBrushLocal "DiagGrid";
        _extZone setMarkerColor "ColorOrange";

        private _hostageCount = count _hostageUnits;
        private _limitFail = 1;

        private _success = [
            "hostage",
            _taskID,
            _position,
            format ["Hostage: Grid %1", _grid],
            format ["Rescue hostages operating near grid %1.", _grid],
            createHashMapFromArray [["hostages", _hostageUnits], ["shooters", _shooterUnits]],
            createHashMapFromArray [
                ["limitFail", _limitFail],
                ["limitSuccess", _hostageCount],
                ["extractionZone", _extZone],
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
                ["execution", true],
                ["cbrn", false]
            ],
            0,
            "",
            "mission_manager"
        ] call FUNC(startTask);

        if !(_success) exitWith {
            deleteMarker _extZone;
            ""
        };

        private _activeMissionRegistry = _manager getOrDefault ["activeMissionRegistry", createHashMap];
        _activeMissionRegistry set [_taskID, createHashMapFromArray [
            ["generatorType", _self call ["getGeneratorType", []]],
            ["position", _position],
            ["markers", [_extZone]],
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
