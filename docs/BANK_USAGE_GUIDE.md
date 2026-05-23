# Bank Usage Guide

The bank module stores player account balances, earnings, PINs, and transaction
strings. The hot-state API also owns the active banking workflows used by the
UI: deposit, withdraw, transfer, checkout charge, PIN validation, and PIN
changes.

## Storage Model

Bank data is persisted through SurrealDB by the server extension.

```json
{
  "uid": "76561198000000000",
  "name": "Player Name",
  "bank": 1000.0,
  "cash": 250.0,
  "earnings": 0.0,
  "pin": 1234,
  "transactions": []
}
```

Rules validated by the Rust service:

- `uid` is authoritative from the command argument.
- `name` cannot be empty.
- `bank` and `cash` cannot be negative.
- `pin` must be a four-digit number.
- Durable `bank:get` requires an existing bank account.

## Durable Commands

| Command | Arguments | Returns |
| --- | --- | --- |
| `bank:create` | `uid`, `bank_json` | Persisted bank JSON. |
| `bank:get` | `uid` | Bank JSON. |
| `bank:update` | `uid`, `patch_json` | Updated bank JSON. |
| `bank:exists` | `uid` | `true` or `false`. |
| `bank:delete` | `uid` | `OK`. |

## Create an Account

The `uid` field in the JSON is overwritten with the command UID.

```sqf
private _account = createHashMapFromArray [
    ["uid", getPlayerUID player],
    ["name", name player],
    ["bank", 0],
    ["cash", 0],
    ["earnings", 0],
    ["pin", 1234],
    ["transactions", []]
];

private _result = "forge_server" callExtension ["bank:create", [
    getPlayerUID player,
    toJSON _account
]];
```

## Hot-State Commands

| Command | Arguments | Returns |
| --- | --- | --- |
| `bank:hot:init` | `uid` | Bank JSON loaded into hot state. |
| `bank:hot:get` | `uid` | Bank JSON. |
| `bank:hot:override` | `uid`, `bank_json` | Bank JSON. |
| `bank:hot:patch` | `uid`, `patch_json` | `{ account, patch }`. |
| `bank:hot:deposit` | `uid`, `amount`, `context_json` | `{ account, patch }`. |
| `bank:hot:withdraw` | `uid`, `amount`, `context_json` | `{ account, patch }`. |
| `bank:hot:deposit_earnings` | `uid`, `amount`, `context_json` | `{ account, patch }`. |
| `bank:hot:transfer` | `source_uid`, `target_uid`, `amount`, `context_json` | Transfer result JSON. |
| `bank:hot:charge_checkout` | `uid`, `amount`, `context_json` | `{ account, patch }`. |
| `bank:hot:validate_pin` | `uid`, `pin`, `context_json` | `{}` on success. |
| `bank:hot:change_pin` | `uid`, `current_pin`, `new_pin`, `context_json` | `{ account, patch }`. |
| `bank:hot:save` | `uid` | Current hot bank JSON and async durable save. |
| `bank:hot:remove` | `uid` | `OK`. |

Use hot-state commands for UI workflows. They return patch objects so the UI can
update only changed fields.

## Deposit and Withdraw

ATM sessions require `atmAuthorized: true`. Full bank sessions can set
`mode: "bank"`.

```sqf
private _context = createHashMapFromArray [
    ["mode", "atm"],
    ["atmAuthorized", true]
];

private _deposit = "forge_server" callExtension ["bank:hot:deposit", [
    getPlayerUID player,
    "100",
    toJSON _context
]];

private _withdraw = "forge_server" callExtension ["bank:hot:withdraw", [
    getPlayerUID player,
    "50",
    toJSON _context
]];
```

## Transfer

Transfers are only available from the full bank interface. `fromField` can be
`bank` or `cash`.

```sqf
private _context = createHashMapFromArray [
    ["mode", "bank"],
    ["atmAuthorized", false],
    ["fromField", "bank"]
];

private _result = "forge_server" callExtension ["bank:hot:transfer", [
    getPlayerUID player,
    _targetUid,
    "250",
    toJSON _context
]];
```

## Checkout Charge

Checkout charging supports `sourceField: "cash"` or `sourceField: "bank"`.
Set `commit` to `false` to preview the patch without saving.

```sqf
private _context = createHashMapFromArray [
    ["sourceField", "bank"],
    ["commit", true]
];

private _result = "forge_server" callExtension ["bank:hot:charge_checkout", [
    getPlayerUID player,
    "125",
    toJSON _context
]];
```

## PIN Validation

PIN entry is only valid in ATM mode.

```sqf
private _context = createHashMapFromArray [["mode", "atm"]];

private _result = "forge_server" callExtension ["bank:hot:validate_pin", [
    getPlayerUID player,
    "1234",
    toJSON _context
]];
```

## PIN Changes

PIN changes require the current PIN and a different four-digit new PIN. The
command is only valid from the full bank interface.

```sqf
private _context = createHashMapFromArray [
    ["mode", "bank"],
    ["atmAuthorized", false]
];

private _result = "forge_server" callExtension ["bank:hot:change_pin", [
    getPlayerUID player,
    "1234",
    "5678",
    toJSON _context
]];
```

## Error Handling

```sqf
private _result = "forge_server" callExtension ["bank:hot:get", [getPlayerUID player]];
private _payload = _result select 0;

if (_payload find "Error:" == 0) exitWith {
    systemChat format ["Bank error: %1", _payload];
};

private _bank = fromJSON _payload;
```
