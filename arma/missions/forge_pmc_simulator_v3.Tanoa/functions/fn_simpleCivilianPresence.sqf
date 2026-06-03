/*
 * File: fn_simpleCivilianPresence.sqf
 * Author: IDSolutions
 * Date: 2026-05-24
 * Last Update: 2026-05-24
 * Public: No
 *
 * Description:
 *     Initializes lightweight server-side civilian pedestrians and traffic.
 *
 * Parameter(s):
 *     N/A
 *
 * Returns:
 *     Civilian presence service [HASHMAP OBJECT]
 *
 * Example(s):
 *     [] call forge_pmc_fnc_simpleCivilianPresence
 */

if !(isServer) exitWith { objNull };
if !(isNil "CivilianPresenceService") exitWith { CivilianPresenceService };

CivilianPresenceServiceBaseClass = compileFinal createHashMapFromArray [
    ["#type", "CivilianPresenceService"],
    ["#create", compileFinal {
        _self set ["running", false];
        _self set ["pedestrians", []];
        _self set ["drivers", []];
        _self set ["invalidRoads", []];
        _self set ["validRoads", []];
        _self set ["workers", []];
        _self set ["debugMarkers", []];

        _self set ["config", createHashMapFromArray [
            ["includeZeus", false],
            ["addToZeus", true],
            ["debug", false],
            ["deadCleanupDelay", 30],
            ["spawnScanRate", 2],
            ["pedestrianTickRate", 0.25],
            ["vehicleTickRate", 1],
            ["movementTickRate", 5],
            ["vehicleMovementTickRate", 10],
            ["minSpawnDistance", 500],
            ["spawnScanDistance", 1250],
            ["deleteDistance", 1250],
            ["maxRoadBudget", 1000],
            ["maxPedestrians", 10],
            ["maxVehicles", 5],
            ["pedestrianMinTravelDistance", 300],
            ["pedestrianMaxTravelDistance", 600],
            ["vehicleMinTravelDistance", 1500],
            ["vehicleMaxTravelDistance", 2000],
            ["blacklistMilitaryDistance", 125],
            ["blacklistAirportDistance", 500],
            ["civilianClasses", [
                "C_man_1", "C_man_polo_1_F", "C_man_polo_2_F", "C_man_polo_4_F",
                "C_man_polo_5_F", "C_man_polo_6_F", "C_man_p_fugitive_F",
                "C_man_w_worker_F", "C_Man_casual_1_F", "C_Man_casual_2_F",
                "C_Man_casual_3_F", "C_Man_casual_4_F", "C_Man_casual_5_F",
                "C_Man_casual_6_F", "C_Man_ConstructionWorker_01_Red_F",
                "C_Man_Paramedic_01_F", "C_Man_UtilityWorker_01_F",
                "C_Man_Fisherman_01_F", "C_Man_Messenger_01_F"
            ]],
            ["vehicleClasses", [
                "C_Offroad_01_F", "C_Offroad_01_repair_F", "C_Quadbike_01_F",
                "C_Truck_02_covered_F", "C_Truck_02_transport_F",
                "C_Hatchback_01_F", "C_Hatchback_01_sport_F", "C_SUV_01_F",
                "C_Van_01_transport_F", "C_Van_01_box_F", "C_Van_01_fuel_F",
                "C_Offroad_02_unarmed_F", "C_Van_02_transport_F",
                "C_Van_02_vehicle_F", "C_Van_02_service_F"
            ]],
            ["blacklistedAirportObjects", [
                "Land_Airport_Tower_F", "Land_Hangar_F", "Land_TentHangar_V1_F",
                "Land_Airport_01_controlTower_F", "Land_Airport_02_controlTower_F",
                "Land_Airport_01_hangar_F", "Land_Airport_02_terminal_F",
                "Land_Airport_01_terminal_F", "Land_LandMark_F"
            ]],
            ["blacklistedMilitaryObjects", [
                "Land_Dome_Big_F", "Land_Dome_Small_F", "Land_Cargo_House_V3_F",
                "Land_Cargo_House_V1_F", "Land_Cargo_House_V2_F", "Land_Cargo_HQ_V3_F",
                "Land_Cargo_HQ_V1_F", "Land_Medevac_HQ_V1_F", "Land_Cargo_HQ_V2_F",
                "Land_Cargo_Patrol_V1_F", "Land_Cargo_Patrol_V2_F", "Land_Cargo_Patrol_V3_F",
                "Land_Cargo_Tower_V3_F", "Land_Cargo_Tower_V1_F", "Land_Cargo_Tower_V2_F",
                "Land_MilOffices_V1_F", "Land_Research_house_V1_F", "Land_Research_HQ_F",
                "Land_Bunker_01_big_F", "Land_Bunker_01_blocks_1_F", "Land_Bunker_01_small_F",
                "Land_Bunker_01_tall_F", "Land_BagBunker_01_large_green_F"
            ]]
        ]];

        true
    }],
    ["getConfig", compileFinal {
        params [["_key", "", [""]], ["_default", nil]];

        (_self get "config") getOrDefault [_key, _default]
    }],
    ["setConfig", compileFinal {
        params [["_key", "", [""]], ["_value", nil]];

        if (_key isEqualTo "") exitWith { false };
        (_self get "config") set [_key, _value];
        true
    }],
    ["isRunning", compileFinal {
        _self getOrDefault ["running", false]
    }],
    ["getPlayers", compileFinal {
        private _includeZeus = _self call ["getConfig", ["includeZeus", false]];
        if (_includeZeus || { count allPlayers <= 1 }) exitWith { allPlayers };

        allPlayers - (call BIS_fnc_listCuratorPlayers)
    }],
    ["getProjectedPosition", compileFinal {
        params [["_object", objNull, [objNull]], ["_maxDistance", 250, [0]], ["_maxVelocity", 30, [0]]];

        private _center = getPosATL _object;
        private _velocityRatio = ((vectorMagnitude (velocity _object)) / _maxVelocity) min 1;
        private _offset = (vectorNormalized (velocity _object)) vectorMultiply (_maxDistance * _velocityRatio);
        private _position = _center vectorAdd _offset;
        _position set [2, _center select 2];
        _position
    }],
    ["isRoadAllowed", compileFinal {
        params [["_road", objNull, [objNull]]];

        private _invalidRoads = _self get "invalidRoads";
        if (_road in _invalidRoads) exitWith { false };

        private _config = _self get "config";
        private _militaryClasses = _config get "blacklistedMilitaryObjects";
        private _airportClasses = _config get "blacklistedAirportObjects";
        private _militaryDistance = _config get "blacklistMilitaryDistance";
        private _airportDistance = _config get "blacklistAirportDistance";
        private _objects = nearestTerrainObjects [_road, ["House"], _airportDistance, false];
        _objects append (_road nearObjects ["Land_LandMark_F", _militaryDistance]);

        private _allowed = true;
        {
            private _className = typeOf _x;
            if ((_className in _airportClasses) || { (_className in _militaryClasses) && { (_x distance _road) < _militaryDistance } }) exitWith {
                _allowed = false;
            };
        } forEach _objects;

        if (!_allowed) then { _invalidRoads pushBackUnique _road };
        _allowed
    }],
    ["updateValidRoads", compileFinal {
        private _minDistance = _self call ["getConfig", ["minSpawnDistance", 500]];
        private _maxDistance = _self call ["getConfig", ["spawnScanDistance", 1250]];
        private _validRoads = [];
        private _rejectedRoads = [];

        {
            private _projectedPosition = _self call ["getProjectedPosition", [_x, 250, 30]];
            {
                if (((_x distance _projectedPosition) > _minDistance) && { !(_x in _rejectedRoads) } && { _self call ["isRoadAllowed", [_x]] }) then {
                    _validRoads pushBackUnique _x;
                };
            } forEach (_projectedPosition nearRoads _maxDistance);

            _rejectedRoads append ((_projectedPosition nearRoads _maxDistance) - _validRoads);
            uiSleep 0.05;
        } forEach (_self call ["getPlayers", []]);

        _self set ["validRoads", _validRoads];
        _self call ["updateDebugMarkers", []];
        count _validRoads
    }],
    ["getNearestPlayerDistance", compileFinal {
        params [["_object", objNull, [objNull]]];

        private _nearest = 1e10;
        {
            private _projectedPosition = _self call ["getProjectedPosition", [_x, 250, 30]];
            _nearest = _nearest min (_projectedPosition distance (getPosATL _object));
        } forEach (_self call ["getPlayers", []]);

        _nearest
    }],
    ["moveToRandomRoad", compileFinal {
        params [["_unit", objNull, [objNull]], ["_minDistance", 75, [0]], ["_maxDistance", 250, [0]], ["_rotateVehicle", false, [false]]];

        if (isNull _unit) exitWith { false };

        private _roads = (_unit nearRoads _maxDistance) select {
            (_unit distance _x) > _minDistance
                && {
                    if (_rotateVehicle) then {
                        _self call ["isRoadAllowedForDriver", [_x]]
                    } else {
                        _self call ["isRoadAllowed", [_x]]
                    }
                }
        };
        if (_roads isEqualTo []) exitWith { false };

        private _destination = selectRandom _roads;
        private _destinationPosition = getPosATL _destination;

        _unit setVariable ["civPresenceDestination", _destinationPosition, false];
        _unit setVariable ["civPresenceLastMoveAt", time, false];

        if (_rotateVehicle) then {
            vehicle _unit setDir ((getDir _unit) + (_unit getRelDir _destination));
        };

        _unit moveTo _destinationPosition;
        true
    }],
    ["getRoadDirection", compileFinal {
        params [["_road", objNull, [objNull]]];

        private _connectedRoads = roadsConnectedTo _road;
        if (_connectedRoads isEqualTo []) exitWith { random 360 };

        _road getDir (selectRandom _connectedRoads)
    }],
    ["getDriverBlacklistMarkers", compileFinal {
        private _markers = allMapMarkers select { markerShape _x in ["RECTANGLE", "ELLIPSE"] };

        _markers select {
            private _markerName = toLowerANSI _x;
            private _markerText = toLowerANSI (markerText _x);

            (_markerName find "blklist") == 0
                || { (_markerText find "blklist") == 0 }
                || { (_markerName find "blkmarker") == 0 }
                || { (_markerText find "blkmarker") == 0 }
        }
    }],
    ["isRoadAllowedForDriver", compileFinal {
        params [["_road", objNull, [objNull]]];

        if !(_self call ["isRoadAllowed", [_road]]) exitWith { false };

        private _position = getPosATL _road;
        private _blacklistMarkers = _self call ["getDriverBlacklistMarkers", []];
        (_blacklistMarkers findIf { _position inArea _x }) < 0
    }],
    ["getDynamicLimit", compileFinal {
        params [["_limitKey", "", [""]]];

        private _maxCount = _self call ["getConfig", [_limitKey, 0]];
        private _roadBudget = _self call ["getConfig", ["maxRoadBudget", 1000]];
        private _validRoadCount = count (_self get "validRoads");

        round ((_maxCount * ((_validRoadCount / _roadBudget) min 1)) max 1)
    }],
    ["deleteAgent", compileFinal {
        params [["_agent", objNull, [objNull]]];

        if (isNull _agent) exitWith { false };

        private _vehicle = _agent getVariable ["ownedVehicle", objNull];
        if (!isNull _vehicle) then {
            if ((crew _vehicle findIf { _x in allPlayers }) < 0) then {
                deleteVehicle _vehicle;
            };
        };

        private _group = group _agent;
        deleteVehicle _agent;
        if (!isNull _group && { (count units _group) == 0 }) then {
            deleteGroup _group;
        };
        true
    }],
    ["cleanupAgents", compileFinal {
        params [["_collectionKey", "", [""]], ["_deleteDistance", 1250, [0]]];

        private _agents = (_self getOrDefault [_collectionKey, []]) select { !isNull _x };
        {
            if ((_self call ["getNearestPlayerDistance", [_x]]) > _deleteDistance) then {
                _self call ["deleteAgent", [_x]];
            };
        } forEach _agents;

        _self set [_collectionKey, _agents select { !isNull _x }];
    }],
    ["cleanupDeadAgents", compileFinal {
        private _delay = _self call ["getConfig", ["deadCleanupDelay", 30]];

        {
            if (_x getVariable ["isCivPopAgent", false]) then {
                private _timeLeft = _x getVariable ["deathCleanupTime", _delay];
                _timeLeft = _timeLeft - 1;
                _x setVariable ["deathCleanupTime", _timeLeft, false];

                if (_timeLeft <= 0) then {
                    _self call ["deleteAgent", [_x]];
                };
            };
        } forEach allDeadMen;

        true
    }],
    ["spawnPedestrian", compileFinal {
        private _roads = _self get "validRoads";
        if (_roads isEqualTo []) exitWith { false };

        private _spawnRoad = selectRandom _roads;
        if !(_self call ["isRoadAllowed", [_spawnRoad]]) exitWith { false };

        private _className = selectRandom (_self call ["getConfig", ["civilianClasses", []]]);
        private _agent = createAgent [_className, getPosATL _spawnRoad, [], 0, "CAN_COLLIDE"];
        _agent disableAI "FSM";
        _agent forceWalk true;
        _agent allowFleeing 0;
        _agent setVariable ["isCivPopAgent", true, false];

        _self call [
            "moveToRandomRoad",
            [
                _agent,
                _self call ["getConfig", ["pedestrianMinTravelDistance", 300]],
                _self call ["getConfig", ["pedestrianMaxTravelDistance", 600]],
                false
            ]
        ];

        (_self get "pedestrians") pushBack _agent;
        true
    }],
    ["spawnVehicle", compileFinal {
        private _roads = (_self get "validRoads") select { _self call ["isRoadAllowedForDriver", [_x]] };
        if (_roads isEqualTo []) exitWith { false };

        private _spawnRoad = selectRandom _roads;
        if !(_self call ["isRoadAllowedForDriver", [_spawnRoad]]) exitWith { false };

        private _driverClass = selectRandom (_self call ["getConfig", ["civilianClasses", []]]);
        private _vehicleClass = selectRandom (_self call ["getConfig", ["vehicleClasses", []]]);
        private _spawnPosition = getPosATL _spawnRoad;
        private _spawnDirection = _self call ["getRoadDirection", [_spawnRoad]];
        private _driver = createAgent [_driverClass, _spawnPosition, [], 0, "CAN_COLLIDE"];
        private _vehicle = createVehicle [_vehicleClass, _spawnPosition, [], 0, "NONE"];

        _vehicle setDir _spawnDirection;
        _vehicle setPosATL _spawnPosition;
        _vehicle setVectorUp (surfaceNormal _spawnPosition);
        _vehicle setFuel 1;
        _vehicle engineOn true;

        _vehicle addEventHandler ["Hit", { ["play", _this select 0] call BIS_fnc_carAlarm; }];
        { _vehicle disableCollisionWith _x; } forEach (_self get "pedestrians");

        _driver moveInDriver _vehicle;
        _driver disableAI "FSM";
        _driver forceWalk true;
        _driver allowFleeing 0;
        _driver setVariable ["ownedVehicle", _vehicle, false];
        _driver setVariable ["isCivPopAgent", true, false];

        _self call [
            "moveToRandomRoad",
            [
                _driver,
                _self call ["getConfig", ["vehicleMinTravelDistance", 1500]],
                _self call ["getConfig", ["vehicleMaxTravelDistance", 2000]],
                true
            ]
        ];

        (_self get "drivers") pushBack _driver;
        true
    }],
    ["updateMovement", compileFinal {
        params [["_collectionKey", "", [""]], ["_minSpeed", 0.125, [0]], ["_minDistance", 75, [0]], ["_maxDistance", 250, [0]], ["_rotateVehicle", false, [false]]];

        {
            if (!isNull _x && { (vectorMagnitude (velocity _x)) < _minSpeed }) then {
                _self call ["moveToRandomRoad", [_x, _minDistance, _maxDistance, _rotateVehicle]];
            };
            uiSleep 0.05;
        } forEach (_self getOrDefault [_collectionKey, []]);
    }],
    ["updateDebugMarkers", compileFinal {
        if !(_self call ["getConfig", ["debug", false]]) exitWith {
            { deleteMarker _x; } forEach (_self getOrDefault ["debugMarkers", []]);
            _self set ["debugMarkers", []];
        };

        { deleteMarker _x; } forEach (_self getOrDefault ["debugMarkers", []]);
        private _markers = [];
        {
            private _marker = createMarker [format ["CivPresenceRoad_%1", count _markers], getPosATL _x];
            _marker setMarkerType "mil_dot";
            _marker setMarkerColor "ColorCivilian";
            _markers pushBack _marker;
        } forEach (_self get "validRoads");
        _self set ["debugMarkers", _markers];
    }],
    ["addToZeus", compileFinal {
        if !(_self call ["getConfig", ["addToZeus", true]]) exitWith { false };

        private _objects = ((_self get "pedestrians") + (_self get "drivers")) select { !isNull _x };
        private _vehicles = _objects apply { vehicle _x };
        {
            _x addCuratorEditableObjects [_objects + _vehicles, true];
        } forEach allCurators;

        true
    }],
    ["startWorker", compileFinal {
        params [["_workerName", "", [""]], ["_code", {}, [{}]]];

        private _workers = _self get "workers";
        _workers pushBack ([_self] spawn _code);
        _self set ["workers", _workers];
        _workerName
    }],
    ["start", compileFinal {
        if (_self call ["isRunning", []]) exitWith { false };

        _self set ["running", true];

        _self call ["startWorker", ["roads", {
            params ["_service"];

            while { _service call ["isRunning", []] } do {
                _service call ["updateValidRoads", []];
                sleep (_service call ["getConfig", ["spawnScanRate", 2]]);
            };
        }]];

        _self call ["startWorker", ["pedestrians", {
            params ["_service"];

            while { _service call ["isRunning", []] } do {
                private _deleteDistance = _service call ["getConfig", ["deleteDistance", 1250]];
                _service call ["cleanupAgents", ["pedestrians", _deleteDistance]];

                if (count (_service get "pedestrians") < (_service call ["getDynamicLimit", ["maxPedestrians"]])) then {
                    _service call ["spawnPedestrian", []];
                };

                sleep (_service call ["getConfig", ["pedestrianTickRate", 0.25]]);
            };
        }]];

        _self call ["startWorker", ["vehicles", {
            params ["_service"];

            while { _service call ["isRunning", []] } do {
                private _deleteDistance = _service call ["getConfig", ["deleteDistance", 1250]];
                _service call ["cleanupAgents", ["drivers", _deleteDistance]];

                if (count (_service get "drivers") < (_service call ["getDynamicLimit", ["maxVehicles"]])) then {
                    _service call ["spawnVehicle", []];
                };

                sleep (_service call ["getConfig", ["vehicleTickRate", 1]]);
            };
        }]];

        _self call ["startWorker", ["pedestrianMovement", {
            params ["_service"];

            while { _service call ["isRunning", []] } do {
                _service call [
                    "updateMovement",
                    [
                        "pedestrians",
                        0.125,
                        _service call ["getConfig", ["pedestrianMinTravelDistance", 300]],
                        _service call ["getConfig", ["pedestrianMaxTravelDistance", 600]],
                        false
                    ]
                ];
                sleep (_service call ["getConfig", ["movementTickRate", 5]]);
            };
        }]];

        _self call ["startWorker", ["vehicleMovement", {
            params ["_service"];

            while { _service call ["isRunning", []] } do {
                _service call [
                    "updateMovement",
                    [
                        "drivers",
                        0.25,
                        _service call ["getConfig", ["vehicleMinTravelDistance", 1500]],
                        _service call ["getConfig", ["vehicleMaxTravelDistance", 2000]],
                        true
                    ]
                ];
                sleep (_service call ["getConfig", ["vehicleMovementTickRate", 10]]);
            };
        }]];

        _self call ["startWorker", ["maintenance", {
            params ["_service"];

            while { _service call ["isRunning", []] } do {
                _service call ["addToZeus", []];
                sleep 3;
            };
        }]];

        _self call ["startWorker", ["deadCleanup", {
            params ["_service"];

            while { _service call ["isRunning", []] } do {
                _service call ["cleanupDeadAgents", []];
                sleep 1;
            };
        }]];

        true
    }],
    ["stop", compileFinal {
        _self set ["running", false];

        { terminate _x; } forEach (_self getOrDefault ["workers", []]);
        _self set ["workers", []];

        {
            _self call ["deleteAgent", [_x]];
        } forEach ((_self getOrDefault ["pedestrians", []]) + (_self getOrDefault ["drivers", []]));

        { deleteMarker _x; } forEach (_self getOrDefault ["debugMarkers", []]);
        _self set ["debugMarkers", []];
        _self set ["pedestrians", []];
        _self set ["drivers", []];
        true
    }],
    ["#delete", compileFinal {
        _self call ["stop", []];
    }]
];

CivilianPresenceService = createHashMapObject [CivilianPresenceServiceBaseClass, []];
CivilianPresenceService call ["start", []];

CivilianPresenceService
