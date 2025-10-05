# IDS Forge Development Plan

## Overview
This plan outlines the development of a modular extension system for IDS Forge that efficiently manages various game data types using Redis and stays within Arma 3's 20KB buffer constraints.

## Architecture Decisions

### Data Structure Strategy
- **Redis Sets** for simple unlocks (Arsenal, Garage): Fast membership checks, no duplicates
- **Redis Lists** of JSON strings for rich data (Messages, Locker): Preserves order, supports complex metadata
- **Redis Hashes** for key-value data (Player stats): Efficient field updates

### Buffer Management
- Modular approach: Each module loads only its relevant data subset
- Hybrid system: Small data calls for most operations, chunking for large data transfers
- Target: Stay well under 20KB per call (aim for ~10-15KB safety margin)

## Development Phases

### Phase 1: Arsenal Module (Priority: Critical)
**Timeline: 1-2 weeks**

#### Data Structure
```
Redis Key: "arsenal:{playerId}"
Type: Redis Set
Content: Strings (weapon/item class names)
Example: ["arifle_MX_F", "arifle_MXC_F", "hgun_Pistol_heavy_01_F"]
```

#### Functions
- `arsenal_get(playerId)` - Get all unlocked items
- `arsenal_unlock(playerId, itemClass)` - Unlock single item
- `arsenal_unlock_batch(playerId, [itemClasses])` - Unlock multiple items
- `arsenal_lock(playerId, itemClass)` - Remove unlock
- `arsenal_has(playerId, itemClass)` - Check if item is unlocked
- `arsenal_clear(playerId)` - Clear all unlocks

#### Success Metrics
- Sub-second response times for get operations
- Support for 500+ items per player without buffer issues
- Seamless integration with existing Arma 3 Virtual Arsenal

### Phase 2: Garage Module (Priority: High)
**Timeline: 1-2 weeks**

#### Data Structure
```
Redis Key: "garage:{playerId}:{category}"
Type: Redis Set per category
Categories: "cars", "armor", "helis", "planes", "naval", "statics"
Content: Vehicle class names
Example garage:player123:helis: ["B_Heli_Light_01_F", "B_Heli_Transport_01_F"]
```

#### Functions
- `garage_get(playerId, category?)` - Get vehicles (all or by category)
- `garage_unlock(playerId, vehicleClass, category)` - Unlock vehicle
- `garage_unlock_batch(playerId, [{class, category}])` - Unlock multiple
- `garage_lock(playerId, vehicleClass)` - Remove vehicle access
- `garage_has(playerId, vehicleClass)` - Check access
- `garage_clear(playerId, category?)` - Clear category or all

#### Expected Output Format (Virtual Garage)
```sqf
// Returns array of arrays by category:
[
    ["C_Offroad_01_F", "B_G_Offroad_01_F"],    // cars
    ["B_MBT_01_cannon_F"],                     // armor
    ["B_Heli_Light_01_F"],                     // helis
    [],                                        // planes
    [],                                        // naval  
    []                                         // statics
]
```

#### Success Metrics
- Category-based filtering working correctly
- Support for 200+ vehicles per category
- Fast lookup for spawn dialogs
- Virtual garage integration ready

### Phase 3: Messages Module (Priority: Medium)
**Timeline: 2-3 weeks**

#### Data Structure
```
Redis Key: "messages:{playerId}"
Type: Redis List (newest first)
Content: JSON strings with message metadata
```

#### JSON Structure
```json
{
  "id": "uuid",
  "from": "senderId",
  "fromName": "Sender Display Name",
  "subject": "Message Subject",
  "content": "Message body...",
  "timestamp": "2024-01-15T10:30:00Z",
  "read": false,
  "priority": "normal" // "low", "normal", "high", "urgent"
}
```

#### Functions
- `messages_get(playerId, limit?, offset?)` - Get messages (paginated)
- `messages_send(fromId, toId, subject, content, priority?)` - Send message
- `messages_mark_read(playerId, messageId)` - Mark as read
- `messages_delete(playerId, messageId)` - Delete message
- `messages_count_unread(playerId)` - Get unread count

#### Chunking Considerations
- Implement pagination for large message lists
- Consider message content size limits
- Support for chunked message content if needed

### Phase 4: Locker Module (Priority: Medium-Low)
**Timeline: 3-4 weeks**

#### Two-Tier System: Items + Loadouts

##### **Individual Items Storage**
```
Redis Key: "locker:{playerId}:items"
Type: Redis List
Content: JSON strings with item metadata
```

**Item Data Format**:
```json
{
    "id": "item_001",
    "class": "arifle_MX_F", 
    "condition": 0.95,
    "attachments": ["optic_Hamr", "acc_flashlight"],
    "ammo": 30,
    "stored_at": "2024-01-15T10:30:00Z"
}
```

##### **Saved Loadouts**
```
Redis Key: "locker:{playerId}:loadouts"
Type: Redis List  
Content: JSON strings following Arma 3 Loadout Array format
```

**Arma 3 Loadout Array Structure**:
```json
{
  "id": "loadout_uuid",
  "name": "Loadout Name",
  "loadout": [
    ["uniform_class", [["item1", count], ["item2", count]]],  // Uniform + inventory
    ["vest_class", [["mag1", count], ["grenade1", count]]],   // Vest + inventory  
    ["backpack_class", [["item3", count]]],                   // Backpack + inventory
    ["headgear_class"],                                       // Helmet/hat
    ["faceware_class"],                                       // Goggles/glasses
    ["binocular_class"],                                      // Binoculars
    [["weapon_class", "suppressor", "pointer", "optic", ["mag_class", ammo_count], [], ""], ""], // Primary weapon
    [],                                                       // Launcher (if any)
    [["pistol_class", "", "", "", ["pistol_mag", ammo], [], ""], ""], // Handgun
    ["uniform_insignia"],                                     // Uniform insignia
    ["vest_insignia"]                                         // Vest insignia
  ],
  "timestamp": "2024-01-15T10:30:00Z"
}
```

#### Functions
**Item Management**:
- `locker_get_items(playerId)` - Get all stored items with metadata
- `locker_add_item(playerId, itemData)` - Add item with condition/attachments
- `locker_remove_item(playerId, itemId)` - Remove specific item
- `locker_update_item(playerId, itemId, itemData)` - Update item metadata

**Loadout Management**:
- `locker_get_loadouts(playerId)` - Get all saved loadouts
- `locker_save_loadout(playerId, name, loadoutArray)` - Save new loadout
- `locker_delete_loadout(playerId, loadoutId)` - Delete loadout
- `locker_rename_loadout(playerId, loadoutId, newName)` - Rename loadout
- `locker_apply_loadout(playerId, loadoutId)` - Get loadout for applying to unit

## Testing Strategy

### **Per-Module Testing** (For Each New Module)
1. **Unit Tests**: Test individual functions in isolation
2. **Demo Script**: SQF examples showing real-world usage  
3. **Redis Verification**: Manual verification of data structures
4. **Buffer Testing**: Ensure all responses stay under 20KB
5. **Performance Testing**: Measure response times under load

### **Integration Testing**
- **Multi-Module**: Multiple modules working together seamlessly
- **Data Consistency**: Player data consistency across all modules
- **Memory Usage**: System performance with multiple concurrent players
- **Arma 3 Integration**: Extension loading and function calls in game

### **Performance Benchmarks**
- **Response Time**: All functions under 50ms average
- **Buffer Size**: All responses under 20KB (chunking for larger data)
- **Memory Usage**: Under 100MB per 100 concurrent players
- **Throughput**: Support 1000+ concurrent players
- **Redis Performance**: Individual operations under 10ms

## Documentation Requirements

### Technical Documentation
- API reference for each module
- Redis schema documentation  
- Error code reference
- Performance characteristics

### User Documentation
- SQF usage examples
- Integration guide for mission makers
- Troubleshooting guide
- Migration guide from existing systems

## Success Metrics

### Performance Targets
- Function calls under 50ms average
- Memory usage under 100MB per 100 concurrent players
- Redis operations under 10ms
- Zero data corruption incidents

### Scalability Targets
- Support 100+ concurrent players
- Handle 10,000+ items per module per player
- Maintain performance with 1M+ total records
- 99.9% uptime reliability

## Progress Tracking

### ✅ **Completed Tasks**
1. **Foundation**: Core Redis connection and `get_list` function implemented
2. **Arsenal Module**: Redis Sets implementation with 6 functions complete
   - `arsenal_get`, `arsenal_unlock`, `arsenal_unlock_batch`, `arsenal_lock`, `arsenal_has`, `arsenal_clear`
   - Full API documentation in `docs/ARSENAL_API.md`
   - Demo scripts: `arsenal_demo.sqf`, `test_arsenal.sqf`
   - Performance optimization: Removed unnecessary Arc cloning
3. **Code Quality**: Optimized Redis client handling across all modules
4. **Documentation**: Arsenal API documentation and demo scripts created

### 🔄 **Current Tasks**
1. **Testing**: Create test framework for Arsenal module
2. **Deployment**: Build and test Arsenal module in Arma 3 environment

### ⏳ **Upcoming Tasks** 
1. **Phase 2: Garage Module** - Implement vehicle category system
2. **Phase 3: Messages Module** - Design pagination and chunking system  
3. **Phase 4: Locker Module** - Implement Arma 3 loadout array handling

## Implementation Strategy

### **Development Order** (Optimized for Success)
1. **Arsenal Module** ✅ - Most straightforward, critical for gameplay, tests Redis Set pattern
2. **Garage Module** 🔄 - Same pattern as Arsenal, more categories but same logic
3. **Messages Module** ⏳ - Tests Redis List pattern, more complex JSON data
4. **Locker Module** ⏳ - Most complex metadata handling, rich JSON structures

### **Immediate Next Session Tasks**
1. **Test Arsenal Module** - Run `test_arsenal.sqf` with actual Arma 3 + Redis
2. **Create Garage Module** - Implement `garage.rs` following Arsenal patterns
3. **Garage Demo Script** - Create `garage_demo.sqf` and `test_garage.sqf`
4. **Garage Documentation** - Create `docs/GARAGE_API.md`

**Estimated Timeline**:
- **Garage Module**: 1-2 sessions
- **Messages Module**: 2-3 sessions  
- **Locker Module**: 2-3 sessions
- **Total Remaining**: 5-8 development sessions

### **File Structure**
```
server/extension/src/
├── lib.rs              # Main extension setup
├── config.rs           # Redis configuration
├── actor.rs            # Player data (existing)  
├── org.rs              # Organization data (existing)
├── arsenal.rs          # Arsenal unlocks ✅
├── garage.rs           # Vehicle unlocks 🔄
├── locker.rs           # Item storage ⏳
├── messages.rs         # Player messages ⏳
└── stats.rs            # Player statistics ⏳
```

## Risk Mitigation

### Technical Risks
- **Buffer overflow**: Implement size monitoring and warnings
- **Redis connection failures**: Add connection pooling and retry logic
- **Data corruption**: Implement atomic operations and validation
- **Performance degradation**: Add monitoring and optimization hooks

### Project Risks
- **Scope creep**: Stick to modular approach, resist feature additions
- **Timeline delays**: Prioritize core functionality over nice-to-have features
- **Integration issues**: Regular testing with actual Arma 3 environment

## Architecture Benefits

### Modularity
- Independent development and testing
- Easy to add new modules
- Minimal impact when modifying existing modules

### Performance
- Efficient Redis data structures for each use case
- Buffer size optimization per module
- Minimal memory footprint

### Maintainability
- Clear separation of concerns
- Consistent API patterns across modules
- Comprehensive error handling

### Scalability
- Redis clustering support for large deployments
- Module-specific optimization opportunities
- Horizontal scaling potential