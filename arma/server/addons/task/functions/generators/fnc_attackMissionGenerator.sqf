#include "..\script_component.hpp"

/*
 * Author: IDSolutions
 * Attack mission generator used by the dynamic mission manager.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call forge_server_task_fnc_attackMissionGenerator
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(AttackMissionGeneratorBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "AttackMissionGeneratorBaseClass"],
    ["#create", compileFinal {
        private _missionConfig = missionConfigFile >> "CfgMissions";
        _self set ["missionConfig", _missionConfig];
        _self set ["aiGroupsConfig", (_missionConfig >> "AIGroups")];
        _self set ["attackConfig", (_missionConfig >> "MissionTypes" >> "Attack")];
        _self set ["generatorType", "attack"];
    }],
    ["getGeneratorType", compileFinal {
        _self getOrDefault ["generatorType", "attack"]
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
            if ((_y getOrDefault ["generatorType", ""]) isNotEqualTo "attack") then { continue; };

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
            private _candidate = [_center, _worldSize / 2 - _minEdgeDist, _worldSize / 2 - _minEdgeDist, 3, 0, 0.3, 0] call BIS_fnc_findSafePos;

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

            if (!_inBlkList) then {
                _taskPos = _candidate;
            };
        };

        if (_taskPos isEqualTo []) exitWith {
            ["WARNING", "Attack mission generator: selectLocation failed to find a valid dynamic position."] call EFUNC(common,log);
            createHashMap
        };

        createHashMapFromArray [
            ["position", _taskPos],
            ["grid", mapGridPosition _taskPos]
        ]
    }],
    ["spawnAttackGroup", compileFinal {
        params [["_position", [0, 0, 0], [[]]]];

        private _aiGroupsConfig = _self getOrDefault ["aiGroupsConfig", configNull];
        private _attackConfig = _self getOrDefault ["attackConfig", configNull];
        private _groups = [];
        {
            if ("attack" in getArray (_x >> "suitable")) then {
                _groups pushBack _x;
            };
        } forEach ("true" configClasses _aiGroupsConfig);

        if (_groups isEqualTo []) exitWith {
            ["WARNING", "Attack mission generator: no AI group configs are suitable for attack missions."] call EFUNC(common,log);
            grpNull
        };

        private _groupConfig = selectRandom _groups;
        private _side = getText (_groupConfig >> "side");
        private _group = createGroup (call compile _side);
        private _minUnits = getNumber (_attackConfig >> "minUnits");
        private _maxUnits = getNumber (_attackConfig >> "maxUnits");
        private _patrolRadius = getNumber (_attackConfig >> "patrolRadius");

        if (_minUnits <= 0) then { _minUnits = 4; };
        if (_maxUnits < _minUnits) then { _maxUnits = _minUnits; };
        if (_patrolRadius <= 0) then { _patrolRadius = 200; };

        private _targetUnitCount = floor random [_minUnits, ceil ((_minUnits + _maxUnits) / 2), _maxUnits + 1];
        private _unitPool = [];
        {
            if ((getText (_x >> "side")) isNotEqualTo _side) then { continue; };

            {
                _unitPool pushBack createHashMapFromArray [
                    ["vehicle", getText (_x >> "vehicle")],
                    ["rank", getText (_x >> "rank")],
                    ["position", getArray (_x >> "position")]
                ];
            } forEach ("true" configClasses (_x >> "Units"));
        } forEach _groups;

        if (_unitPool isEqualTo []) exitWith {
            ["WARNING", format ["Attack mission generator: selected AI group side '%1' produced an empty unit pool.", _side]] call EFUNC(common,log);
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
            "Attack mission generator: spawned attack group. Side=%1, Units=%2, PatrolRadius=%3, Position=%4",
            _side,
            count (units _group),
            _patrolRadius,
            _position
        ]] call EFUNC(common,log);
        _group
    }],
    ["rollRewards", compileFinal {
        private _attackConfig = _self getOrDefault ["attackConfig", configNull];
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
            } forEach (getArray (_attackConfig >> "Rewards" >> _category));
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

        private _attackConfig = _self getOrDefault ["attackConfig", configNull];
        private _locationData = _self call ["selectLocation", [_manager]];
        if (_locationData isEqualTo createHashMap) exitWith { "" };

        private _position = _locationData getOrDefault ["position", [0, 0, 0]];
        private _grid = _locationData getOrDefault ["grid", mapGridPosition _position];

        ["INFO", format [
            "Attack mission generator: selected location. Grid=%1, Position=%2",
            _grid,
            _position
        ]] call EFUNC(common,log);

        private _group = _self call ["spawnAttackGroup", [_position]];
        if (isNull _group) exitWith {
            ["WARNING", format [
                "Attack mission generator: spawnAttackGroup failed for Grid=%1, Position=%2",
                _grid,
                _position
            ]] call EFUNC(common,log);
            ""
        };

        private _units = units _group;
        if (_units isEqualTo []) exitWith {
            ["WARNING", format [
                "Attack mission generator: spawned group has no units. Grid=%1, Group=%2",
                _grid,
                _group
            ]] call EFUNC(common,log);
            deleteGroup _group;
            ""
        };

        private _taskID = format ["task_attack_%1", round (diag_tickTime * 1000)];
        private _rewardRange = getArray (_attackConfig >> "Rewards" >> "money");
        private _reputationRange = getArray (_attackConfig >> "Rewards" >> "reputation");
        private _penaltyRange = getArray (_attackConfig >> "penalty");
        private _timeRange = getArray (_attackConfig >> "timeLimit");
        private _rewards = _self call ["rollRewards"];
        private _fundsReward = _rewardRange call BFUNC(randomNum);
        private _reputationReward = _reputationRange call BFUNC(randomNum);
        private _reputationPenalty = _penaltyRange call BFUNC(randomNum);
        private _timeLimit = _timeRange call BFUNC(randomNum);

        ["INFO", format [
            "Attack mission generator: creating task. TaskID=%1, Grid=%2, Units=%3",
            _taskID,
            _grid,
            count _units
        ]] call EFUNC(common,log);

        private _success = [
            "attack",
            _taskID,
            _position,
            format ["Attack: Grid %1", _grid],
            format ["Eliminate hostile forces operating near grid %1.", _grid],
            createHashMapFromArray [["targets", _units]],
            createHashMapFromArray [
                ["limitFail", 0],
                ["limitSuccess", count _units],
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
                ["special", _rewards get "special"]
            ],
            0,
            "",
            "mission_manager"
        ] call FUNC(startTask);

        if !(_success) exitWith {
            ["WARNING", format [
                "Attack mission generator: startTask failed. TaskID=%1, Grid=%2, Units=%3",
                _taskID,
                _grid,
                count _units
            ]] call EFUNC(common,log);
            ""
        };

        ["INFO", format [
            "Attack mission generator: task registered. TaskID=%1, Source=mission_manager, TimeLimit=%2s, LimitSuccess=%3",
            _taskID,
            _timeLimit,
            count _units
        ]] call EFUNC(common,log);

        private _activeMissionRegistry = _manager getOrDefault ["activeMissionRegistry", createHashMap];
        _activeMissionRegistry set [_taskID, createHashMapFromArray [
            ["generatorType", _self call ["getGeneratorType", []]],
            ["position", _position],
            ["startedAt", serverTime]
        ]];
        _manager set ["activeMissionRegistry", _activeMissionRegistry];

        ["INFO", format [
            "Attack mission generator: mission started successfully. TaskID=%1, Grid=%2",
            _taskID,
            _grid
        ]] call EFUNC(common,log);

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
