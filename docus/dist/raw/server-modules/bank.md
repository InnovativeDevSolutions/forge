# Bank Usage Guide

The bank module stores player account balances, earnings, PINs, and transaction
strings. The hot-state API also owns the active banking workflows used by the
UI: deposit, withdraw, transfer, checkout charge, and PIN validation.

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

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Arguments
    </th>
    
    <th>
      Returns
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        bank:create
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        bank_json
      </code>
    </td>
    
    <td>
      Persisted bank JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:get
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Bank JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:update
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        patch_json
      </code>
    </td>
    
    <td>
      Updated bank JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:exists
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      <code>
        true
      </code>
      
       or <code>
        false
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:delete
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      <code>
        OK
      </code>
      
      .
    </td>
  </tr>
</tbody>
</table>

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

<table>
<thead>
  <tr>
    <th>
      Command
    </th>
    
    <th>
      Arguments
    </th>
    
    <th>
      Returns
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        bank:hot:init
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Bank JSON loaded into hot state.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:get
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Bank JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:override
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        bank_json
      </code>
    </td>
    
    <td>
      Bank JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:patch
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        patch_json
      </code>
    </td>
    
    <td>
      <code>
        { account, patch }
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:deposit
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        amount
      </code>
      
      , <code>
        context_json
      </code>
    </td>
    
    <td>
      <code>
        { account, patch }
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:withdraw
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        amount
      </code>
      
      , <code>
        context_json
      </code>
    </td>
    
    <td>
      <code>
        { account, patch }
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:deposit_earnings
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        amount
      </code>
      
      , <code>
        context_json
      </code>
    </td>
    
    <td>
      <code>
        { account, patch }
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:transfer
      </code>
    </td>
    
    <td>
      <code>
        source_uid
      </code>
      
      , <code>
        target_uid
      </code>
      
      , <code>
        amount
      </code>
      
      , <code>
        context_json
      </code>
    </td>
    
    <td>
      Transfer result JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:charge_checkout
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        amount
      </code>
      
      , <code>
        context_json
      </code>
    </td>
    
    <td>
      <code>
        { account, patch }
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:validate_pin
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        pin
      </code>
      
      , <code>
        context_json
      </code>
    </td>
    
    <td>
      <code>
        {}
      </code>
      
       on success.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:save
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Current hot bank JSON and async durable save.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        bank:hot:remove
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      <code>
        OK
      </code>
      
      .
    </td>
  </tr>
</tbody>
</table>

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

## Error Handling

```sqf
private _result = "forge_server" callExtension ["bank:hot:get", [getPlayerUID player]];
private _payload = _result select 0;

if (_payload find "Error:" == 0) exitWith {
    systemChat format ["Bank error: %1", _payload];
};

private _bank = fromJSON _payload;
```
