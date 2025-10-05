# Arsenal Module API Documentation

## Overview

The Arsenal module provides a fast, efficient system for managing player weapon and item unlocks using Redis Sets. This ensures no duplicates, fast membership checks, and optimal performance for Virtual Arsenal integration.

## Data Structure

- **Redis Key Pattern**: `arsenal:{playerId}`
- **Data Type**: Redis Set
- **Content**: Weapon/item class names as strings
- **Benefits**: O(1) membership checks, automatic duplicate prevention

## Functions

### arsenal_get

Retrieves all unlocked items for a player.

**Syntax:**
```sqf
"forge_server" callExtension ["arsenal", ["get", _playerId]]
```

**Parameters:**
- `_playerId` (String): Player's unique identifier (typically from `getPlayerUID`)

**Returns:**
- Success: JSON array of unlocked item class names
- Error: JSON object with error message

**Example:**
```sqf
private _playerId = getPlayerUID player;
private _result = "forge_server" callExtension ["arsenal", ["get", _playerId]];
// Returns: ["arifle_MX_F", "hgun_Pistol_heavy_01_F", "LMG_Mk200_F"]
```

### arsenal_unlock

Unlocks a single item for a player.

**Syntax:**
```sqf
"forge_server" callExtension ["arsenal", ["unlock", _playerId, _itemClass]]
```

**Parameters:**
- `_playerId` (String): Player's unique identifier
- `_itemClass` (String): Class name of the item to unlock

**Returns:**
- Success: `{"success": true, "action": "unlocked"}` or `{"success": true, "action": "already_unlocked"}`
- Error: JSON object with error message

**Example:**
```sqf
private _result = "forge_server" callExtension ["arsenal", ["unlock", getPlayerUID player, "arifle_MX_F"]];
// Returns: {"success": true, "action": "unlocked"}
```

### arsenal_unlock_batch

Unlocks multiple items for a player in a single operation.

**Syntax:**
```sqf
"forge_server" callExtension ["arsenal", ["unlock_batch", _playerId, _itemArray]]
```

**Parameters:**
- `_playerId` (String): Player's unique identifier
- `_itemArray` (Array): Array of item class names to unlock

**Returns:**
- Success: JSON object with unlock statistics
- Error: JSON object with error message

**Example:**
```sqf
private _items = ["arifle_MX_F", "arifle_MXC_F", "hgun_Pistol_heavy_01_F"];
private _result = "forge_server" callExtension ["arsenal", ["unlock_batch", getPlayerUID player, _items]];
// Returns: {"success": true, "total_items": 3, "new_unlocks": 2, "already_unlocked": 1}
```

### arsenal_lock

Removes an unlocked item from a player (locks it).

**Syntax:**
```sqf
"forge_server" callExtension ["arsenal", ["lock", _playerId, _itemClass]]
```

**Parameters:**
- `_playerId` (String): Player's unique identifier
- `_itemClass` (String): Class name of the item to lock

**Returns:**
- Success: `{"success": true, "action": "locked"}` or `{"success": true, "action": "was_not_unlocked"}`
- Error: JSON object with error message

**Example:**
```sqf
private _result = "forge_server" callExtension ["arsenal", ["lock", getPlayerUID player, "arifle_MX_F"]];
// Returns: {"success": true, "action": "locked"}
```

### arsenal_has

Checks if a player has a specific item unlocked.

**Syntax:**
```sqf
"forge_server" callExtension ["arsenal", ["has", _playerId, _itemClass]]
```

**Parameters:**
- `_playerId` (String): Player's unique identifier
- `_itemClass` (String): Class name of the item to check

**Returns:**
- Success: `{"has_item": true}` or `{"has_item": false}`
- Error: JSON object with error message

**Example:**
```sqf
private _result = "forge_server" callExtension ["arsenal", ["has", getPlayerUID player, "arifle_MX_F"]];
// Returns: {"has_item": true}
```

### arsenal_clear

Clears all unlocked items for a player. **Use with caution!**

**Syntax:**
```sqf
"forge_server" callExtension ["arsenal", ["clear", _playerId]]
```

**Parameters:**
- `_playerId` (String): Player's unique identifier

**Returns:**
- Success: `{"success": true, "action": "cleared"}` or `{"success": true, "action": "was_already_empty"}`
- Error: JSON object with error message

**Example:**
```sqf
private _result = "forge_server" callExtension ["arsenal", ["clear", getPlayerUID player]];
// Returns: {"success": true, "action": "cleared"}
```

## Integration Examples

### Virtual Arsenal Integration

```sqf
// Function to populate Virtual Arsenal with unlocked items
fnc_setupPlayerArsenal = {
    params ["_arsenalBox", "_player"];
    
    private _playerId = getPlayerUID _player;
    private _result = "forge_server" callExtension ["arsenal", ["get", _playerId]];
    private _unlockedItems = parseSimpleArray _result;
    
    if (!isNil "_unlockedItems") then {
        // Clear existing cargo
        clearWeaponCargoGlobal _arsenalBox;
        clearMagazineCargoGlobal _arsenalBox;
        clearItemCargoGlobal _arsenalBox;
        clearBackpackCargoGlobal _arsenalBox;
        
        // Add unlocked items
        {
            [_arsenalBox, _x, true] call BIS_fnc_addVirtualWeaponCargo;
        } forEach _unlockedItems;
        
        // Open Virtual Arsenal
        ["Open", [true]] call BIS_fnc_arsenal;
    } else {
        hint "Failed to load arsenal data!";
    };
};

// Usage: [_arsenalBox, player] call fnc_setupPlayerArsenal;
```

### Mission Reward System

```sqf
// Function to reward player with arsenal items
fnc_rewardArsenalItems = {
    params ["_player", "_rewardItems"];
    
    private _playerId = getPlayerUID _player;
    private _result = "forge_server" callExtension ["arsenal", ["unlock_batch", _playerId, _rewardItems]];
    private _parsedResult = parseSimpleArray _result;
    
    if (!isNil "_parsedResult" && {_parsedResult getOrDefault ["success", false]}) then {
        private _newUnlocks = _parsedResult getOrDefault ["new_unlocks", 0];
        
        if (_newUnlocks > 0) then {
            [_player, format ["You unlocked %1 new items!", _newUnlocks]] remoteExec ["hint", _player];
            
            // Log for admin tracking
            diag_log format ["Player %1 (%2) unlocked %3 arsenal items: %4", 
                name _player, _playerId, _newUnlocks, _rewardItems];
        } else {
            [_player, "All reward items were already unlocked!"] remoteExec ["hint", _player];
        };
        
        true
    } else {
        [_player, "Failed to process arsenal rewards!"] remoteExec ["hint", _player];
        false
    };
};

// Usage: [player, ["srifle_LRR_F", "optic_LRPS"]] call fnc_rewardArsenalItems;
```

### Access Control System

```sqf
// Function to check equipment prerequisites for missions
fnc_checkArsenalPrerequisites = {
    params ["_player", "_requiredItems"];
    
    private _playerId = getPlayerUID _player;
    private _canAccess = true;
    private _missingItems = [];
    
    {
        private _hasResult = "forge_server" callExtension ["arsenal", ["has", _playerId, _x]];
        private _parsedResult = parseSimpleArray _hasResult;
        
        if (!isNil "_parsedResult" && {!(_parsedResult getOrDefault ["has_item", false])}) then {
            _missingItems pushBack _x;
            _canAccess = false;
        };
    } forEach _requiredItems;
    
    [_canAccess, _missingItems]
};

// Usage in mission start condition
private _requiredGear = ["arifle_MX_F", "hgun_Pistol_heavy_01_F", "optic_MRCO"];
private _accessCheck = [player, _requiredGear] call fnc_checkArsenalPrerequisites;

if (!(_accessCheck select 0)) exitWith {
    private _missing = _accessCheck select 1;
    hint format ["Mission requires unlocked equipment: %1", _missing];
};
```

## Performance Considerations

### Buffer Size Management

- Each item class name averages 15-20 characters
- With JSON overhead, expect ~25 bytes per item
- Target: Keep under 500 items per player (≈12.5KB)
- Monitor actual sizes in production environments

### Redis Optimization

- Redis Sets provide O(1) lookup performance
- Memory efficient compared to other Redis data types
- Automatic duplicate prevention reduces storage waste
- Consider Redis clustering for high-scale deployments

### Best Practices

1. **Batch Operations**: Use `unlock_batch` for multiple items instead of multiple `unlock` calls
2. **Error Handling**: Always check return values and handle errors gracefully
3. **Caching**: Cache frequently accessed data locally when possible
4. **Monitoring**: Track buffer sizes and response times in production

## Error Handling

All functions return JSON with consistent error format:

```json
{
  "error": "Descriptive error message"
}
```

Common error scenarios:
- Missing or invalid parameters
- Redis connection failures  
- Malformed data
- Buffer size exceeded

Always use `parseSimpleArray` to safely parse JSON responses and check for errors before processing results.

## Migration from Legacy Systems

### From Hash-Based Storage

```sqf
// Convert existing hash-based unlocks to set-based
fnc_migratePlayerArsenal = {
    params ["_playerId"];
    
    // Get existing data from hash (example)
    private _oldData = "forge_server" callExtension ["legacy", ["get_arsenal", _playerId]];
    private _parsedOldData = parseSimpleArray _oldData;
    
    if (!isNil "_parsedOldData") then {
        private _unlockedItems = [];
        
        // Extract unlocked items from old format
        {
            if (_y == "true" || _y == "1") then {
                _unlockedItems pushBack _x;
            };
        } forEach _parsedOldData;
        
        // Migrate to new format
        if (count _unlockedItems > 0) then {
            "forge_server" callExtension ["arsenal", ["unlock_batch", _playerId, _unlockedItems]];
            diag_log format ["Migrated %1 arsenal items for player %2", count _unlockedItems, _playerId];
        };
    };
};
```

## Security Considerations

- Player IDs should be validated (use `getPlayerUID` consistently)
- Consider rate limiting for batch operations
- Log suspicious unlock patterns
- Implement admin tools for unlock management
- Regular Redis backups recommended

## Troubleshooting

### Common Issues

1. **Empty Results**: Check Redis connection and key format
2. **Performance Issues**: Monitor buffer sizes and optimize batch sizes
3. **Duplicate Items**: Not possible with Redis Sets - investigate client-side caching
4. **Missing Items**: Verify item class names are correct and properly unlocked