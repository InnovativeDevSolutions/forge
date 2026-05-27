#include "..\script_component.hpp"

/*
 * Author: IDSolutions, Blackbox AI, MrPākehā
 * Defines the HVT capture mission generator base class used by the dynamic
 * mission manager. The generator selects a location, spawns required
 * entities, registers a Forge task, and cleans up manager state when the
 * task completes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * N/A. Defines GVAR(CaptureHvtMissionGeneratorBaseClass) in missionNamespace.
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(CaptureHvtMissionGeneratorBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "CaptureHvtMissionGeneratorBaseClass"],
    ["#create", compileFinal {
        private _missionConfig = missionConfigFile >> "CfgMissions";
        if !(isClass _missionConfig) then {
            _missionConfig = configFile >> "CfgMissions";
        };
        _self set ["missionConfig", _missionConfig];
        _self set ["aiGroupsConfig", (_missionConfig >> "AIGroups")];
        _self set ["hvtConfig", (_missionConfig >> "MissionTypes" >> "HVTCapture")];
        _self set ["generatorType", "hvtcapture"];
        ["INFO", format ["Mission generator registered. Type=hvtcapture, ConfigPath=%1", _missionConfig]] call EFUNC(common,log);
    }],
    ["getGeneratorType", compileFinal {
        _self getOrDefault ["generatorType", "hvtcapture"]
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
            if ((_y getOrDefault ["generatorType", ""]) isNotEqualTo "hvtcapture") then { continue; };

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
            ["WARNING", "Capture HVT mission generator: selectLocation failed to find a valid dynamic position."] call EFUNC(common,log);
            createHashMap
        };

        private _building = objNull;
        private _buildingCandidates = nearestObjects [
            _taskPos,
            ["House_F", "House", "Building", "BuildingBase"],
            200
        ];
        if (_buildingCandidates isNotEqualTo []) then {
            _building = selectRandom _buildingCandidates;
        };

        private _buildingPositions = [];
        if !(isNull _building) then {
            for "_i" from 0 to 100 do {
                private _buildingPos = _building buildingPos _i;
                if (_buildingPos isEqualTo [0, 0, 0]) exitWith {};
                _buildingPositions pushBack _buildingPos;
            };
        };

        createHashMapFromArray [
            ["position", _taskPos],
            ["grid", mapGridPosition _taskPos],
            ["buildingPositions", _buildingPositions]
        ]
    }],

    ["spawnHvtTarget", compileFinal {
        params [['_position', [0, 0, 0], [[]]], ["_buildingPositions", [], [[]]]];

        private _hvtConfig = _self getOrDefault ["hvtConfig", configNull];
        private _side = missionNamespace getVariable ["ENEMY_SIDE", east];
        private _enemyFaction = missionNamespace getVariable ["ENEMY_FACTION_STR", missionNamespace getVariable ["enemyFaction", "IND_G_F"]];
        private _unitPool = [_enemyFaction, _side] call FUNC(getEnemyFactionUnitPool);
        if (_unitPool isEqualTo []) exitWith { [] };

        private _leaderPool = _unitPool select {
            toUpperANSI (_x getOrDefault ["rank", "PRIVATE"]) in ["SERGEANT", "LIEUTENANT", "CAPTAIN", "MAJOR", "COLONEL"]
        };
        if (_leaderPool isEqualTo []) then { _leaderPool = +_unitPool; };

        private _targetDef = selectRandom _leaderPool;
        private _targetClass = _targetDef getOrDefault ["vehicle", ""];
        if (_targetClass isEqualTo "") exitWith { [] };

        private _group = createGroup _side;
        private _leaderPos = if (_buildingPositions isEqualTo []) then {
            _position vectorAdd [(random 20 - 10), (random 20 - 10), 0]
        } else {
            selectRandom _buildingPositions
        };
        private _leader = _group createUnit [_targetClass, _leaderPos, [], 0, "NONE"];
        if (isNull _leader) exitWith {
            deleteGroup _group;
            []
        };
        _leader setRank "LIEUTENANT";

        [] call FUNC(updateEnemyCountFromActivePlayers);
        private _enemyMult = missionNamespace getVariable ["forge_pmc_enemyCountMultiplier", 1];
        private _escortCount = getNumber (_hvtConfig >> "escorts");
        if (_escortCount < 0) then { _escortCount = 0; };
        _escortCount = floor (_escortCount * _enemyMult);
        private _escortUnits = [];
        for "_i" from 1 to _escortCount do {
            private _escortDef = selectRandom _unitPool;
            private _escortClass = _escortDef getOrDefault ["vehicle", ""];
            if (_escortClass isEqualTo "") then { continue; };
            private _escortPos = if (_buildingPositions isEqualTo []) then {
                _position vectorAdd [(random 35 - 17), (random 35 - 17), 0]
            } else {
                selectRandom _buildingPositions
            };
            private _escort = _group createUnit [_escortClass, _escortPos, [], 0, "NONE"];
            if !(isNull _escort) then {
                _escort setRank (_escortDef getOrDefault ["rank", "PRIVATE"]);
                _escortUnits pushBack _escort;
            };
        };

        private _groupUnits = [_leader] + _escortUnits;

        [_group, _position, 200] call BFUNC(taskPatrol);

        [_leader, _groupUnits]
    }],

    ["rollRewards", compileFinal {
        private _hvtConfig = _self getOrDefault ["hvtConfig", configNull];
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
            } forEach (getArray (_hvtConfig >> "Rewards" >> _category));
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

        private _hvtConfig = _self getOrDefault ["hvtConfig", configNull];
        private _locationData = _self call ["selectLocation", [_manager]];
        if (_locationData isEqualTo createHashMap) exitWith { "" };

        private _position = _locationData getOrDefault ["position", [0, 0, 0]];
        private _grid = _locationData getOrDefault ["grid", mapGridPosition _position];
        private _buildingPositions = _locationData getOrDefault ["buildingPositions", []];

       ["INFO", format [
            "Capture HVT mission generator: selected location. Grid=%1, Position=%2",
            _grid,
            _position
        ]] call EFUNC(common,log);

        private _taskID = format ["task_capture_hvt_%1", round (diag_tickTime * 1000)];
        private _rewardRange = [_hvtConfig, ["Rewards", "money"], "moneyMin", "moneyMax", [50000, 120000]] call FUNC(getMissionSettingRange);
        private _reputationRange = [_hvtConfig, ["Rewards", "reputation"], "reputationMin", "reputationMax", [10, 22]] call FUNC(getMissionSettingRange);
        private _penaltyRange = [_hvtConfig, ["penalty"], "penaltyMin", "penaltyMax", [-14, -5]] call FUNC(getMissionSettingRange);
        private _timeRange = [_hvtConfig, ["timeLimit"], "timeLimitMin", "timeLimitMax", [900, 1800]] call FUNC(getMissionSettingRange);
        private _rewards = _self call ["rollRewards"];

        private _spawnResult = _self call ["spawnHvtTarget", [_position, _buildingPositions]];
        if !(_spawnResult isEqualType [] && { count _spawnResult >= 2 }) exitWith { "" };
        private _hvtTarget = _spawnResult select 0;
        private _hvtGroupUnits = _spawnResult select 1;
        if (isNull _hvtTarget || _hvtGroupUnits isEqualTo []) exitWith { "" };

        private _fundsReward = _rewardRange call BFUNC(randomNum);
        private _reputationReward = _reputationRange call BFUNC(randomNum);
        private _reputationPenalty = _penaltyRange call BFUNC(randomNum);
        private _timeLimit = _timeRange call BFUNC(randomNum);

        private _extZone = format ["forge_hvt_ext_zone_%1", _taskID];
        private _extPos = [0, 0, 0];
        private _extZoneMarkers = allMapMarkers select {
            (toLowerANSI (markerText _x) find "extzone") == 0
            || { (toLowerANSI _x find "extzone") == 0 }
            || { (toLowerANSI (markerText _x) find "extmarker") == 0 }
            || { (toLowerANSI _x find "extmarker") == 0 }
        };

        if (_extZoneMarkers isNotEqualTo []) then {
            _extPos = getMarkerPos (selectRandom _extZoneMarkers);
            _extPos set [2, 0];
        } else {
            private _blkListMarkers = allMapMarkers select { markerShape _x in ["RECTANGLE", "ELLIPSE"] };
            _blkListMarkers = _blkListMarkers select {
                (
                    (toLowerANSI _x find "blklist") == 0
                    || { (toLowerANSI (markerText _x) find "blklist") == 0 }
                    || { (toLowerANSI _x find "blkmarker") == 0 }
                    || { (toLowerANSI (markerText _x) find "blkmarker") == 0 }
                )
                && { getMarkerPos _x distance2D [0, 0] > 0 }
            };

            if (_blkListMarkers isNotEqualTo []) then {
                private _selectedBlk = selectRandom _blkListMarkers;
                private _attempt = 0;
                while { _attempt < 60 && { _extPos isEqualTo [0, 0, 0] } } do {
                    _attempt = _attempt + 1;
                    private _candidate = [getMarkerPos _selectedBlk, 0, 2000, 3, 0, 0.3, 0] call BFUNC(findSafePos);
                    if (_candidate isEqualTo [0, 0, 0]) then { continue; };
                    if !(_candidate inArea _selectedBlk) then { continue; };
                    _candidate set [2, 0];
                    _extPos = _candidate;
                };
            };

            if (_extPos isEqualTo [0, 0, 0]) then {
                private _attempt = 0;
                while { _attempt < 80 && { _extPos isEqualTo [0, 0, 0] } } do {
                    _attempt = _attempt + 1;
                    private _probe = [random worldSize, random worldSize, 0];
                    if ((_probe distance2D _position) < 2000) then { continue; };
                    private _safe = [_probe, 0, 500, 3, 0, 0.3, 0] call BFUNC(findSafePos);
                    if (_safe isEqualTo [0, 0, 0]) then { continue; };
                    _safe set [2, 0];
                    _extPos = _safe;
                };
            };

            if (_extPos isEqualTo [0, 0, 0]) then {
                _extPos = _position vectorAdd [2500, 0, 0];
                _extPos set [2, 0];
            };
        };

        createMarker [_extZone, _extPos];
        _extZone setMarkerShapeLocal "ELLIPSE";
        _extZone setMarkerSizeLocal [160, 160];
        _extZone setMarkerTextLocal format ["HVT Extraction Zone %1", _grid];
        _extZone setMarkerAlphaLocal 0.5;
        _extZone setMarkerBrushLocal "DiagGrid";
        _extZone setMarkerColor "ColorOrange";

        private _success = [
            "hvt",
            _taskID,
            _position,
            format ["HVT: Grid %1", _grid],
            format ["Capture the high-value target near grid %1.", _grid],
            createHashMapFromArray [["hvts", [_hvtTarget]]],
            createHashMapFromArray [
                ["limitFail", 0],
                ["limitSuccess", 1],
                ["extractionZone", _extZone],
                ["captureHvt", true],
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
