#include "..\script_component.hpp"

/*
 * Author: IDSolutions, Blackbox AI, MrPākehā
 * Defines the Delivery mission generator base class used by the dynamic
 * mission manager. The generator selects a location, spawns required
 * entities, registers a Forge task, and cleans up manager state when the
 * task completes.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * N/A. Defines GVAR(DeliveryMissionGeneratorBaseClass) in missionNamespace.
 *
 * Public: No
 */

#pragma hemtt ignore_variables ["_self"]
GVAR(DeliveryMissionGeneratorBaseClass) = compileFinal createHashMapFromArray [
    ["#type", "DeliveryMissionGeneratorBaseClass"],
    ["#create", compileFinal {
        private _missionConfig = missionConfigFile >> "CfgMissions";
        if !(isClass _missionConfig) then {
            _missionConfig = configFile >> "CfgMissions";
        };
        _self set ["missionConfig", _missionConfig];
        _self set ["aiGroupsConfig", (_missionConfig >> "AIGroups")];
        _self set ["deliveryConfig", (_missionConfig >> "MissionTypes" >> "Delivery")];
        _self set ["generatorType", "delivery"];
    }],
    ["getGeneratorType", compileFinal {
        _self getOrDefault ["generatorType", "delivery"]
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
            if ((_y getOrDefault ["generatorType", ""]) isNotEqualTo "delivery") then { continue; };

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
            ["WARNING", "Delivery mission generator: selectLocation failed to find a valid dynamic position."] call EFUNC(common,log);
            createHashMap
        };

        createHashMapFromArray [
            ["position", _taskPos],
            ["grid", mapGridPosition _taskPos]
        ]
    }],

    ["rollRewards", compileFinal {
        private _deliveryConfig = _self getOrDefault ["deliveryConfig", configNull];
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
            } forEach (getArray (_deliveryConfig >> "Rewards" >> _category));
        } forEach ["equipment", "supplies", "weapons", "vehicles", "special"];

        createHashMapFromArray [
            ["equipment", _equipmentRewards],
            ["supplies", _supplyRewards],
            ["weapons", _weaponRewards],
            ["vehicles", _vehicleRewards],
            ["special", _specialRewards]
        ]
    }],

    ["getCargoPickupPosition", compileFinal {
        params [["_fallbackPosition", [0, 0, 0], [[]]]];

        if ("CargoSpawn" in allMapMarkers) exitWith { getMarkerPos "CargoSpawn" };

        private _cargoSpawn = missionNamespace getVariable ["CargoSpawn", objNull];
        if (_cargoSpawn isEqualType "" && { _cargoSpawn in allMapMarkers }) exitWith { getMarkerPos _cargoSpawn };
        if (_cargoSpawn isEqualType objNull && { !(isNull _cargoSpawn) }) exitWith { getPosATL _cargoSpawn };

        if ("ExtZone" in allMapMarkers) exitWith { getMarkerPos "ExtZone" };

        private _extZone = missionNamespace getVariable ["ExtZone", objNull];
        if (_extZone isEqualType "" && { _extZone in allMapMarkers }) exitWith { getMarkerPos _extZone };
        if (_extZone isEqualType objNull && { !(isNull _extZone) }) exitWith { getPosATL _extZone };

        _fallbackPosition
    }],

    ["spawnDeliveryCargo", compileFinal {
        params [["_pickupPosition", [0, 0, 0], [[]]]];

        private _deliveryConfig = _self getOrDefault ["deliveryConfig", configNull];
        private _supplyCargo = getArray (_deliveryConfig >> "Cargo" >> "supplies");
        private _vehicleCargo = getArray (_deliveryConfig >> "Cargo" >> "vehicles");
        private _cargoPool = _supplyCargo + _vehicleCargo;
        private _cargoCount = 1 + floor (random 2);
        private _cargoObjects = [];

        if (_cargoPool isEqualTo []) exitWith { [] };

        for "_i" from 1 to _cargoCount do {
            private _cargoClass = selectRandom _cargoPool;
            private _spawnPos = _pickupPosition vectorAdd [(random 12 - 6), (random 12 - 6), 0];

            private _cargoObject = createVehicle [_cargoClass, _spawnPos, [], 0, "NONE"];
            if !(isNull _cargoObject) then {
                _cargoObjects pushBack _cargoObject;
            };
        };

        _cargoObjects
    }],

    ["startMission", compileFinal {
        params [["_manager", createHashMapObject [createHashMapFromArray []], [createHashMap]]];

        private _deliveryConfig = _self getOrDefault ["deliveryConfig", configNull];
        private _locationData = _self call ["selectLocation", [_manager]];
        if (_locationData isEqualTo createHashMap) exitWith { "" };

        private _position = _locationData getOrDefault ["position", [0, 0, 0]];
        private _pickupPos = _self call ["getCargoPickupPosition", [_position]];
        private _grid = mapGridPosition _pickupPos;
        private _taskID = format ["task_delivery_%1", round (diag_tickTime * 1000)];
        private _pickupMarker = format ["forge_delivery_pickup_%1", _taskID];
        private _deliveryZone = format ["forge_delivery_zone_%1", _taskID];
        private _dropoffMarker = format ["forge_delivery_dropoff_%1", _taskID];
        private _worldSize = worldSize;
        private _center = [_worldSize / 2, _worldSize / 2, 0];
        private _deliveryPos = [0, 0, 0];
        private _attempt = 0;
        private _deliverySearchRadius = (_worldSize / 2 - 1000) max 500;
        while { _attempt < 80 && { _deliveryPos isEqualTo [0, 0, 0] } } do {
            _attempt = _attempt + 1;
            private _candidate = [_center, 0, _deliverySearchRadius, 10, 0, 0.3, 0] call BFUNC(findSafePos);
            if (_candidate isEqualTo [0, 0, 0]) then { continue; };
            if ((_candidate distance2D _pickupPos) < 1200) then { continue; };
            _candidate set [2, 0];
            _deliveryPos = _candidate;
        };
        if (_deliveryPos isEqualTo [0, 0, 0]) then {
            _deliveryPos = [_pickupPos, 1200, 2500, 10, 0, 0.3, 0] call BFUNC(findSafePos);
        };
        if (_deliveryPos isEqualTo [0, 0, 0]) then {
            _deliveryPos = _pickupPos vectorAdd [1500, 0, 0];
        };
        private _deliveryGrid = mapGridPosition _deliveryPos;

        private _rewardRange = [_deliveryConfig, ["Rewards", "money"], "moneyMin", "moneyMax", [10000, 30000]] call FUNC(getMissionSettingRange);
        private _reputationRange = [_deliveryConfig, ["Rewards", "reputation"], "reputationMin", "reputationMax", [3, 8]] call FUNC(getMissionSettingRange);
        private _penaltyRange = [_deliveryConfig, ["penalty"], "penaltyMin", "penaltyMax", [-6, -2]] call FUNC(getMissionSettingRange);
        private _rewards = _self call ["rollRewards"];
        private _cargoObjects = _self call ["spawnDeliveryCargo", [_pickupPos]];

        if (_cargoObjects isEqualTo []) exitWith { "" };

        createMarker [_pickupMarker, _pickupPos];
        _pickupMarker setMarkerTypeLocal "hd_pickup";
        _pickupMarker setMarkerColorLocal "ColorBLUFOR";
        _pickupMarker setMarkerText format ["Pickup %1", _grid];

        createMarker [_deliveryZone, _deliveryPos];
        _deliveryZone setMarkerShapeLocal "ELLIPSE";
        _deliveryZone setMarkerSizeLocal [25, 25];
        _deliveryZone setMarkerTextLocal format ["Delivery Zone %1", _deliveryGrid];
        _deliveryZone setMarkerAlphaLocal 0.5;
        _deliveryZone setMarkerBrushLocal "DiagGrid";
        _deliveryZone setMarkerColor "ColorOrange";

        createMarker [_dropoffMarker, _deliveryPos];
        _dropoffMarker setMarkerTypeLocal "hd_end";
        _dropoffMarker setMarkerColorLocal "ColorBLUFOR";
        _dropoffMarker setMarkerText format ["Drop-off %1", _deliveryGrid];

        private _fundsReward = _rewardRange call BFUNC(randomNum);
        private _reputationReward = _reputationRange call BFUNC(randomNum);
        private _reputationPenalty = _penaltyRange call BFUNC(randomNum);
        private _timeLimit = 0;
        private _cargoCount = count _cargoObjects;

        private _success = [
            "delivery",
            _taskID,
            _pickupPos,
            format ["Delivery: Grid %1", _grid],
            format ["Move cargo from grid %1 to the delivery zone near grid %2.", _grid, _deliveryGrid],
            createHashMapFromArray [["cargo", _cargoObjects]],
            createHashMapFromArray [
                ["limitFail", 1],
                ["limitSuccess", _cargoCount],
                ["deliveryZone", _deliveryZone],
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
            deleteMarker _pickupMarker;
            deleteMarker _deliveryZone;
            deleteMarker _dropoffMarker;
            ""
        };

        private _activeMissionRegistry = _manager getOrDefault ["activeMissionRegistry", createHashMap];
        _activeMissionRegistry set [_taskID, createHashMapFromArray [
            ["generatorType", _self call ["getGeneratorType", []]],
            ["position", _pickupPos],
            ["markers", [_pickupMarker, _deliveryZone, _dropoffMarker]],
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
