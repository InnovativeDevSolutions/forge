# Redis Module

This module provides comprehensive Redis operations for the Forge extension, enabling persistent data storage and retrieval from SQF scripts.

## Architecture

The Redis module is organized into specialized operation groups:

- **Common**: Basic key-value operations
- **Hash**: Structured data storage (field-value pairs)
- **List**: Ordered collections and queues
- **Set**: Unique collections and membership tracking

## Connection Management

### Connection Pool

The module uses `bb8` for connection pooling, providing:

- **Automatic connection reuse**: Reduces overhead
- **Configurable pool size**: Control max/min connections
- **Idle timeout**: Prevents stale connections
- **Lazy initialization**: Pool created on first use

### Configuration

Redis connection settings are loaded from `@forge_server/config.toml`:

```toml
[redis]
host = "127.0.0.1"
port = 6379
password = ""  # Optional
max_connections = 10
min_connections = 2
idle_timeout = 300  # seconds
```

## Common Operations

Basic key-value operations for simple data storage.

### Available Commands

| Command             | Description               | Returns                |
| ------------------- | ------------------------- | ---------------------- |
| `redis:common:set`  | Set a string value        | "OK"                   |
| `redis:common:get`  | Get a string value        | Value or empty string  |
| `redis:common:incr` | Increment a numeric value | New value              |
| `redis:common:decr` | Decrement a numeric value | New value              |
| `redis:common:del`  | Delete a key              | Number of keys removed |
| `redis:common:keys` | List all keys             | Comma-separated keys   |

### SQF Examples

```sqf
// Set a value
"forge_server" callExtension ["redis:common:set", ["player_count", "42"]];

// Get a value
private _result = "forge_server" callExtension ["redis:common:get", ["player_count"]];
private _count = _result select 0;  // "42"

// Increment
"forge_server" callExtension ["redis:common:incr", ["player_count", 1]];

// Delete
"forge_server" callExtension ["redis:common:del", ["player_count"]];
```

## Hash Operations

Hash operations store structured data as field-value pairs, ideal for objects and entities.

### Available Commands

| Command             | Description                    | Returns                  |
| ------------------- | ------------------------------ | ------------------------ |
| `redis:hash:set`    | Set a single field             | 1 if new, 0 if updated   |
| `redis:hash:mset`   | Set multiple fields atomically | "OK"                     |
| `redis:hash:get`    | Get a field value              | Value or empty string    |
| `redis:hash:getall` | Get all fields and values      | Comma-separated pairs    |
| `redis:hash:del`    | Delete a field                 | Number of fields removed |
| `redis:hash:keys`   | Get all field names            | Comma-separated keys     |
| `redis:hash:vals`   | Get all values                 | Comma-separated values   |
| `redis:hash:len`    | Get number of fields           | Field count              |
| `redis:hash:exists` | Check if field exists          | "1" or "0"               |

### SQF Examples

```sqf
// Set a single field
"forge_server" callExtension ["redis:hash:set", ["actor:76561198123456789", "name", "John Doe"]];

// Set multiple fields atomically
private _fields = [
    ["name", "John Doe"],
    ["bank", "1000"],
    ["level", "5"]
];
"forge_server" callExtension ["redis:hash:mset", ["actor:76561198123456789", _fields]];

// Get a field
private _result = "forge_server" callExtension ["redis:hash:get", ["actor:76561198123456789", "name"]];
private _name = _result select 0;  // "John Doe"

// Get all fields
private _result = "forge_server" callExtension ["redis:hash:getall", ["actor:76561198123456789"]];
// Returns: "name, John Doe, bank, 1000, level, 5"

// Check if field exists
private _result = "forge_server" callExtension ["redis:hash:exists", ["actor:76561198123456789", "name"]];
private _exists = (_result select 0) == "1";
```

## List Operations

List operations manage ordered collections, useful for queues, logs, and sequential data.

### Available Commands

| Command            | Description           | Returns                        |
| ------------------ | --------------------- | ------------------------------ |
| `redis:list:set`   | Set element at index  | "OK"                           |
| `redis:list:get`   | Get element at index  | Value (base64 decoded)         |
| `redis:list:len`   | Get list length       | Element count                  |
| `redis:list:range` | Get range of elements | JSON array                     |
| `redis:list:lpush` | Prepend to list       | New length                     |
| `redis:list:rpush` | Append to list        | New length                     |
| `redis:list:lpop`  | Remove from beginning | JSON array of removed elements |
| `redis:list:rpop`  | Remove from end       | JSON array of removed elements |
| `redis:list:trim`  | Trim to range         | "OK"                           |
| `redis:list:del`   | Remove by value       | Number removed                 |

### SQF Examples

```sqf
// Append to list
"forge_server" callExtension ["redis:list:rpush", ["event_log", "Player joined"]];
"forge_server" callExtension ["redis:list:rpush", ["event_log", "Player spawned"]];

// Get range
private _result = "forge_server" callExtension ["redis:list:range", ["event_log", 0, -1]];
private _events = parseJSON (_result select 0);  // Array of all events

// Pop from end
private _result = "forge_server" callExtension ["redis:list:rpop", ["event_log", 1]];
private _lastEvent = parseJSON (_result select 0);  // ["Player spawned"]

// Trim to last 100 entries
"forge_server" callExtension ["redis:list:trim", ["event_log", -100, -1]];
```

> [!NOTE]
> List values are automatically base64 encoded/decoded to handle special characters safely.

## Set Operations

Set operations manage unique collections, perfect for membership tracking and preventing duplicates.

### Available Commands

| Command                 | Description            | Returns                      |
| ----------------------- | ---------------------- | ---------------------------- |
| `redis:set:add`         | Add member to set      | 1 if new, 0 if exists        |
| `redis:set:members`     | Get all members        | Comma-separated members      |
| `redis:set:card`        | Get member count       | Cardinality                  |
| `redis:set:ismember`    | Check membership       | "1" or "0"                   |
| `redis:set:randmember`  | Get random member      | Member value                 |
| `redis:set:randmembers` | Get N random members   | Comma-separated members      |
| `redis:set:pop`         | Remove random member   | Removed member               |
| `redis:set:del`         | Remove specific member | 1 if removed, 0 if not found |

### SQF Examples

```sqf
// Add members to a set
"forge_server" callExtension ["redis:set:add", ["org:elite_squad:members", "76561198123456789"]];
"forge_server" callExtension ["redis:set:add", ["org:elite_squad:members", "76561198987654321"]];

// Check membership
private _result = "forge_server" callExtension ["redis:set:ismember", ["org:elite_squad:members", "76561198123456789"]];
private _isMember = (_result select 0) == "1";

// Get all members
private _result = "forge_server" callExtension ["redis:set:members", ["org:elite_squad:members"]];
private _memberUIDs = (_result select 0) splitString ",";

// Get member count
private _result = "forge_server" callExtension ["redis:set:card", ["org:elite_squad:members"]];
private _memberCount = parseNumber (_result select 0);

// Remove member
"forge_server" callExtension ["redis:set:del", ["org:elite_squad:members", "76561198123456789"]];
```

## Helper Utilities

### Base64 Encoding

List operations use base64 encoding to safely store complex strings:

```rust
use crate::redis::helpers::{encode_b64, decode_b64};

let encoded = encode_b64("Complex [string] with {special} chars");
let decoded = decode_b64(&encoded)?;  // Original string
```

### Value Parsing

The `parse_redis_value` function intelligently converts Redis strings to JSON types:

```rust
use crate::redis::helpers::parse_redis_value;

parse_redis_value("42");           // Number(42)
parse_redis_value("true");         // Bool(true)
parse_redis_value("{\"key\":1}");  // Object
parse_redis_value("text");         // String("text")
```

## Macro Usage

The `redis_operation!` macro handles all connection and async boilerplate:

```rust
use crate::redis_operation;
use bb8_redis::redis::AsyncCommands;

pub fn my_redis_command(key: String) -> String {
    redis_operation!(conn => {
        match conn.get::<_, String>(&key).await {
            Ok(value) => value,
            Err(e) => format!("Error: {}", e),
        }
    })
}
```

The macro automatically:

- Acquires a connection from the pool
- Handles lazy initialization if needed
- Executes the operation asynchronously
- Returns the result to SQF

## Error Handling

All Redis operations return strings:

- **Success**: Operation result (e.g., "OK", value, count)
- **Error**: String starting with "Error: " followed by the error message

```sqf
private _result = "forge_server" callExtension ["redis:common:get", ["mykey"]];
private _value = _result select 0;

if (_value find "Error:" == 0) then {
    diag_log format ["Redis error: %1", _value];
} else {
    // Use the value
    systemChat format ["Value: %1", _value];
};
```

## Performance Considerations

- **Connection Pooling**: Reuses connections to minimize overhead
- **Async Operations**: Non-blocking I/O prevents server lag
- **Atomic Operations**: `hash:mset` sets multiple fields in one operation
- **Batch Operations**: Use lists and sets for bulk data

## Best Practices

1. **Use Hashes for Objects**: Store actor/org data as hash fields
2. **Use Sets for Membership**: Track organization members, online players
3. **Use Lists for Logs**: Event logs, chat history, audit trails
4. **Prefix Keys**: Use namespaces like `actor:`, `org:`, `vehicle:`
5. **Handle Errors**: Always check for "Error:" prefix in results
6. **Atomic Updates**: Use `hash:mset` instead of multiple `hash:set` calls
