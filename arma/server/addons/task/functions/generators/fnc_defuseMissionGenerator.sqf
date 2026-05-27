#include "..\script_component.hpp"

/*
 * Author: IDSolutions, Blackbox AI, MrPākehā
 * Defines the Defuse mission generator base class used by the dynamic
 * mission manager. The generator selects a location, spawns required
 * entities, registers a Forge task, and cleans up manager state when the
 * task completes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * N/A. Defines GVAR(DefuseMissionGeneratorBaseClass) in missionNamespace.
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(DefuseMissionGeneratorBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "DefuseMissionGeneratorBaseClass"],
    ["#create", compileFinal {
        private _missionConfig = missionConfigFile >> "CfgMissions";
        if !(isClass _missionConfig) then {
            _missionConfig = configFile >> "CfgMissions";
        };
        _self set ["missionConfig", _missionConfig];
        _self set ["aiGroupsConfig", (_missionConfig >> "AIGroups")];
        _self set ["attackConfig", (_missionConfig >> "MissionTypes" >> "Attack")];
        _self set ["defuseConfig", (_missionConfig >> "MissionTypes" >> "Defuse")];
        _self set ["generatorType", "defuse"];
    }],
    ["getGeneratorType", compileFinal {
        _self getOrDefault ["generatorType", "defuse"]
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
            if ((_y getOrDefault ["generatorType", ""]) isNotEqualTo "defuse") then { continue; };

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
            ["WARNING", "Defuse mission generator: selectLocation failed to find a valid dynamic position."] call EFUNC(common,log);
            createHashMap
        };

        createHashMapFromArray [
            ["position", _taskPos],
            ["grid", mapGridPosition _taskPos]
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
        diag_log format ["Defuse: Unit Count %1", _targetUnitCount];
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
            ["WARNING", format ["Defuse mission generator: selected AI group side '%1' produced an empty unit pool.", _side]] call EFUNC(common,log);
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
            "Defuse mission generator: spawned attack group. Side=%1, Units=%2, PatrolRadius=%3, Position=%4",
            _side,
            count (units _group),
            _patrolRadius,
            _position
        ]] call EFUNC(common,log);
        _group
    }],

    ["rollRewards", compileFinal {
        private _defuseConfig = _self getOrDefault ["defuseConfig", configNull];
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
            } forEach (getArray (_defuseConfig >> "Rewards" >> _category));
        } forEach ["equipment", "supplies", "weapons", "vehicles", "special"];

        createHashMapFromArray [
            ["equipment", _equipmentRewards],
            ["supplies", _supplyRewards],
            ["weapons", _weaponRewards],
            ["vehicles", _vehicleRewards],
            ["special", _specialRewards]
        ]
    }],

    ["spawnDefuseDevices", compileFinal {
        params [['_position', [0, 0, 0], [[]]]];

        private _defuseConfig = _self getOrDefault ["defuseConfig", configNull];
        private _smallDevices = getArray (_defuseConfig >> "Devices" >> "small");
        private _largeDevices = getArray (_defuseConfig >> "Devices" >> "large");
        private _protectedClasses = getArray (_defuseConfig >> "Devices" >> "protected");
        private _devicePool = _smallDevices + _largeDevices;
        if (_devicePool isEqualTo [] || _protectedClasses isEqualTo []) exitWith { [] };

        private _maxDevices = getNumber (_defuseConfig >> "maxDevices");
        if (_maxDevices <= 0) then { _maxDevices = 1; };
        private _deviceCount = 1 + floor (random _maxDevices);

        private _protectedClass = selectRandom _protectedClasses;

        // Try to spawn inside a building if there is a suitable building near the selected location.
        // This will attempt up to N building positions before falling back to outdoor offsets.
        private _buildingSpawnAttempts = 10;
        private _buildingPos = [];

        private _nearBuildings = nearestObjects [_position, ["House"], 50];
        private _building = objNull;
        if (_nearBuildings isNotEqualTo []) then {
            // prefer the closest building that actually contains the position
            {
                if !(isNull _x && { _position inArea _x }) exitWith {
                    _building = _x;
                };
            } forEach _nearBuildings;

            if (isNull _building) then {
                // fallback: pick nearest
                _building = _nearBuildings select 0;
                {
                    if (_position distance2D _x < _position distance2D _building) then {
                        _building = _x;
                    };
                } forEach _nearBuildings;
            };
        };

        if !(isNull _building) then {
            for "_i" from 1 to _buildingSpawnAttempts do {
                private _posIndex = floor random 1000;
                private _candidate = _building buildingPos _posIndex;
                // buildingPos returns [0,0,0] for invalid positions
                if (_candidate isEqualTo [0, 0, 0]) then { continue; };
                // ensure candidate is still inside the building footprint
                if !((_candidate isEqualType [])) then { continue; };
                if ((_candidate vectorDistance _position) <= 60) exitWith {
                    _buildingPos = _candidate;
                };
            };
        };

        private _protectedPos = [0,0,0];
        if (_buildingPos isNotEqualTo []) then {
            _protectedPos = _buildingPos;
        } else {
            // Outdoor fallback: keep previous behavior
            _protectedPos = _position vectorAdd [(random 20 - 10), (random 20 - 10), 0];
        };

        private _protectedObject = createVehicle [_protectedClass, _protectedPos, [], 0, "NONE"];
        private _protectedObjects = [];
        if !(isNull _protectedObject) then {
            _protectedObjects pushBack _protectedObject;
        };

        private _deviceRadiusMin = 2;
        private _deviceRadiusMax = 5;
        private _devices = [];

        for "_i" from 1 to _deviceCount do {
            private _deviceClass = selectRandom _devicePool;

            // If we managed to pick a building position, keep devices clustered relative to it.
            // This keeps them inside the building volume more reliably than using ground offsets.
            private _angle = random 2 * pi;
            private _radius = _deviceRadiusMin + random (_deviceRadiusMax - _deviceRadiusMin);
            private _deviceOffset = [_radius * cos _angle, _radius * sin _angle, 0];
            private _devicePos = _protectedPos vectorAdd _deviceOffset;

            private _deviceObject = createVehicle [_deviceClass, _devicePos, [], 0, "NONE"];
            if !(isNull _deviceObject) then {
                _devices pushBack _deviceObject;
            };
        };

        [_devices, _protectedObjects]
    }],

    ["startMission", compileFinal {
        params [["_manager", createHashMapObject [createHashMapFromArray []], [createHashMap]]];

        private _defuseConfig = _self getOrDefault ["defuseConfig", configNull];
        private _locationData = _self call ["selectLocation", [_manager]];
        if (_locationData isEqualTo createHashMap) exitWith { "" };

        private _position = _locationData getOrDefault ["position", [0, 0, 0]];
        private _grid = _locationData getOrDefault ["grid", mapGridPosition _position];

        ["INFO", format [
            "Defuse mission generator: selected location. Grid=%1, Position=%2",
            _grid,
            _position
        ]] call EFUNC(common,log);

        private _group = _self call ["spawnPatrolGroup", [_position]];
        if (isNull _group) exitWith {
            ["WARNING", format [
                "Defuse mission generator: spawnPatrolGroup failed for Grid=%1, Position=%2",
                _grid,
                _position
            ]] call EFUNC(common,log);
            ""
        };

        private _units = units _group;
        if (_units isEqualTo []) exitWith {
            ["WARNING", format [
                "Defuse mission generator: spawned group has no units. Grid=%1, Group=%2",
                _grid,
                _group
            ]] call EFUNC(common,log);
            deleteGroup _group;
            ""
        };

        private _taskID = format ["task_defuse_%1", round (diag_tickTime * 1000)];
        private _rewardRange = [_defuseConfig, ["Rewards", "money"], "moneyMin", "moneyMax", [20000, 50000]] call FUNC(getMissionSettingRange);
        private _reputationRange = [_defuseConfig, ["Rewards", "reputation"], "reputationMin", "reputationMax", [5, 12]] call FUNC(getMissionSettingRange);
        private _penaltyRange = [_defuseConfig, ["penalty"], "penaltyMin", "penaltyMax", [-9, -3]] call FUNC(getMissionSettingRange);
        private _timeRange = [_defuseConfig, ["timeLimit"], "timeLimitMin", "timeLimitMax", [600, 900]] call FUNC(getMissionSettingRange);
        private _rewards = _self call ["rollRewards"];

        private _spawnResult = _self call ["spawnDefuseDevices", [_position]];
        private _devices = _spawnResult select 0;
        private _protectedObjects = _spawnResult select 1;
        if (_devices isEqualTo [] || _protectedObjects isEqualTo []) exitWith { "" };

        private _fundsReward = _rewardRange call BFUNC(randomNum);
        private _reputationReward = _reputationRange call BFUNC(randomNum);
        private _reputationPenalty = _penaltyRange call BFUNC(randomNum);
        private _timeLimit = _timeRange call BFUNC(randomNum);
        private _iedTimer = 300;
        private _targetCount = count _devices;

        private _defuseZone = format ["forge_defuse_zone_%1", _taskID];
        createMarker [_defuseZone, _position];
        _defuseZone setMarkerShapeLocal "ELLIPSE";
        _defuseZone setMarkerSizeLocal [120, 120];
        _defuseZone setMarkerText format ["Defuse Area %1", _grid];

        private _success = [
            "defuse",
            _taskID,
            _position,
            format ["Defuse: Grid %1", _grid],
            format ["Defuse explosives operating near grid %1.", _grid],
            createHashMapFromArray [["ieds", _devices], ["protected", _protectedObjects]],
            createHashMapFromArray [
                ["limitFail", 0],
                ["limitSuccess", _targetCount],
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
                ["iedTimer", _iedTimer],
                ["defuseZone", _defuseZone]
            ],
            0,
            "",
            "mission_manager"
        ] call FUNC(startTask);

        if !(_success) exitWith {
            deleteMarker _defuseZone;
            ""
        };

        private _activeMissionRegistry = _manager getOrDefault ["activeMissionRegistry", createHashMap];
        _activeMissionRegistry set [_taskID, createHashMapFromArray [
            ["generatorType", _self call ["getGeneratorType", []]],
            ["position", _position],
            ["markers", [_defuseZone]],
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
