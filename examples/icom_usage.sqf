// ICOM (Internal Communication) Usage Example
// Complete guide for using ICOM to communicate between Arma 3 servers

// ============================================================================
// STEP 1: Define the event handler (in init.sqf or mission init)
// ============================================================================
forge_icom_event = {
    params ["_eventName", "_data"];

    systemChat format ["📡 ICOM Event: %1", _eventName];
    diag_log format ["[ICOM] Event received: %1 | Data: %2", _eventName, _data];

    // Handle specific events
    switch (_eventName) do {
        case "supply_drop": {
            systemChat "📦 Supply drop incoming!";

            if (_data isEqualType createHashMap) then {
                private _coords = _data getOrDefault ["coords", []];
                private _supplies = _data getOrDefault ["supplies", []];

                // Spawn supply crate at coordinates
                if (count _coords >= 2) then {
                    private _pos = [_coords select 0, _coords select 1, 0];
                    private _crate = createVehicle ["Box_NATO_Ammo_F", _pos, [], 0, "NONE"];

                    systemChat format ["Supply crate spawned at %1", _pos];
                    diag_log format ["[ICOM] Supply drop: %1 supplies at %2", _supplies, _pos];
                };
            };
        };

        case "spawn_mission": {
            systemChat "🎯 New mission spawning!";

            if (_data isEqualType createHashMap) then {
                private _missionType = _data getOrDefault ["mission_type", ""];
                private _location = _data getOrDefault ["location", []];
                private _difficulty = _data getOrDefault ["difficulty", "normal"];

                // Trigger mission spawn logic here
                systemChat format ["Mission: %1 (%2) at %3", _missionType, _difficulty, _location];
            };
        };

        case "global_alert": {
            systemChat "⚠️ GLOBAL ALERT";

            if (_data isEqualType createHashMap) then {
                private _message = _data getOrDefault ["message", ""];
                private _severity = _data getOrDefault ["severity", "info"];

                if (_message != "") then {
                    systemChat format ["Alert: %1", _message];

                    // Play sound based on severity
                    switch (_severity) do {
                        case "critical": { playSound "alarm"; };
                        case "warning": { playSound "hint"; };
                    };
                };
            };
        };

        case "player_join": {
            if (_data isEqualType createHashMap) then {
                private _playerName = _data getOrDefault ["name", "Unknown"];
                private _serverName = _data getOrDefault ["server", "Unknown"];

                systemChat format ["Player %1 joined %2", _playerName, _serverName];
            };
        };

        default {
            diag_log format ["[ICOM] Unhandled event: %1", _eventName];
        };
    };
};

systemChat "✅ ICOM event handler registered";
diag_log "[ICOM] Event handler initialized";


// ============================================================================
// STEP 2: Send events to other servers
// ============================================================================

// Example 1: Send supply drop to server_2
private _supplyData = createHashMapFromArray [
    ["coords", [1234, 5678, 0]],
    ["supplies", ["ammo_box", "medical_supplies", "repair_kit"]]
];
private _result = "forge_server" callExtension ["icom:send_event", ["server_2", "supply_drop", (toJSON _supplyData)]];
// Returns: ["OK",0,0] on success, ["ERROR: ...",0,0] on failure

// Example 2: Spawn mission on server_2
private _missionData = createHashMapFromArray [
    ["mission_type", "convoy_ambush"],
    ["difficulty", "hard"],
    ["location", [2345, 6789, 0]],
    ["reward", 5000]
];
"forge_server" callExtension ["icom:send_event", ["server_2", "spawn_mission", (toJSON _missionData)]];

// Example 3: Broadcast to all servers
private _alertData = createHashMapFromArray [
    ["message", "Server restart in 5 minutes"],
    ["severity", "warning"]
];
"forge_server" callExtension ["icom:broadcast", ["global_alert", (toJSON _alertData)]];

// Example 4: Notify all servers when a player joins
private _playerJoinData = createHashMapFromArray [
    ["name", name player],
    ["uid", getPlayerUID player],
    ["server", "server_1"]
];
"forge_server" callExtension ["icom:broadcast", ["player_join", (toJSON _playerJoinData)]];


// ============================================================================
// TIPS AND BEST PRACTICES
// ============================================================================

// 1. Always use toJSON to convert hashmaps to JSON strings
private _data = createHashMapFromArray [["key", "value"]];
private _json = toJSON _data;

// 2. Check for errors
private _result = "forge_server" callExtension ["icom:send_event", ["server_2", "test", _json]];
if ((_result select 0) find "ERROR" != -1) then {
    systemChat "Failed to send event!";
    diag_log format ["[ICOM] Error: %1", _result select 0];
};

// 3. Handle missing data gracefully in the event handler
// Use getOrDefault instead of direct hash access

// 4. Log everything for debugging
// All ICOM events are logged to @forge_server/logs/icom.log

// 5. Server IDs must match what's configured in the extension
// Default is "server_1", configure others as needed


// ============================================================================
// COMMON EVENT PATTERNS
// ============================================================================

// Pattern 1: Request-Response
// Server 1 requests something from Server 2
private _requestData = createHashMapFromArray [
    ["request_id", str (random 10000)],
    ["request_type", "player_data"],
    ["player_uid", getPlayerUID player]
];
"forge_server" callExtension ["icom:send_event", ["server_2", "data_request", (toJSON _requestData)]];
// Server 2 responds with a "data_response" event back to server_1

// Pattern 2: Cross-server triggers
// Trigger an action on all servers simultaneously
private _triggerData = createHashMapFromArray [
    ["trigger_type", "airdrop"],
    ["position", [5000, 5000, 0]],
    ["timestamp", time]
];
"forge_server" callExtension ["icom:broadcast", ["synchronized_trigger", (toJSON _triggerData)]];

// Pattern 3: Server status updates
// Periodically broadcast server status to other servers
[] spawn {
    while {true} do {
        sleep 60;  // Every minute

        private _statusData = createHashMapFromArray [
            ["player_count", count allPlayers],
            ["server_fps", diag_fps],
            ["mission_time", time]
        ];

        "forge_server" callExtension ["icom:broadcast", ["server_status", (toJSON _statusData)]];
    };
};
