# Phone Usage Guide

The phone module stores contacts, messages, and emails for each UID. It is a
server-extension state module backed by SurrealDB.

## Storage Model

```json
{
  "contacts": ["76561198000000000", "field_commander"],
  "messages": [
    {
      "id": "phone-message:sender:receiver:1",
      "from": "sender",
      "to": "receiver",
      "message": "Text body",
      "timestamp": 123.45,
      "read": false
    }
  ],
  "emails": [
    {
      "id": "phone-email:sender:receiver:2",
      "from": "sender",
      "to": "receiver",
      "subject": "Subject",
      "body": "Email body",
      "timestamp": 123.45,
      "read": false
    }
  ]
}
```

Rules validated by the Rust service:

- UID arguments cannot be empty.
- Message and email bodies cannot be empty.
- Empty email subjects become `No subject`.
- Player messages and emails cannot target `field_commander`.
- `field_commander` can send messages or emails to players.
- Deleting a message or email removes it only from the requesting UID's index.

## Commands

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
        phone:init
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Full phone payload.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:contacts:list
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Contact UID array.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:contacts:add
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        contact_uid
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
        phone:contacts:remove
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        contact_uid
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
        phone:messages:list
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Message array.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:messages:thread
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        other_uid
      </code>
    </td>
    
    <td>
      Message array for both participants.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:messages:send
      </code>
    </td>
    
    <td>
      <code>
        from_uid
      </code>
      
      , <code>
        to_uid
      </code>
      
      , <code>
        message
      </code>
      
      , <code>
        timestamp
      </code>
    </td>
    
    <td>
      Message JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:messages:mark_read
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        message_id
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
        phone:messages:delete
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        message_id
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
        phone:emails:list
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
    </td>
    
    <td>
      Email array.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:emails:send
      </code>
    </td>
    
    <td>
      <code>
        from_uid
      </code>
      
      , <code>
        to_uid
      </code>
      
      , <code>
        subject
      </code>
      
      , <code>
        body
      </code>
      
      , <code>
        timestamp
      </code>
    </td>
    
    <td>
      Email JSON.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        phone:emails:mark_read
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        email_id
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
        phone:emails:delete
      </code>
    </td>
    
    <td>
      <code>
        uid
      </code>
      
      , <code>
        email_id
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
        phone:remove
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

## Initialize Phone State

`phone:init` creates phone state if needed and seeds self-contact plus
`field_commander`.

```sqf
private _result = "forge_server" callExtension ["phone:init", [getPlayerUID player]];
private _payload = _result select 0;

if (_payload find "Error:" == 0) exitWith {
    systemChat format ["Phone init failed: %1", _payload];
};

private _phone = fromJSON _payload;
```

## Send a Message

```sqf
private _timestamp = str diag_tickTime;

private _result = "forge_server" callExtension ["phone:messages:send", [
    getPlayerUID player,
    _targetUid,
    "Move to checkpoint Alpha.",
    _timestamp
]];
```

## Read a Conversation

```sqf
private _result = "forge_server" callExtension ["phone:messages:thread", [
    getPlayerUID player,
    _otherUid
]];

private _messages = fromJSON (_result select 0);
```

## Send an Email

```sqf
private _result = "forge_server" callExtension ["phone:emails:send", [
    getPlayerUID player,
    _targetUid,
    "Supply Request",
    "Requesting resupply at grid 123456.",
    str diag_tickTime
]];
```

## Mark and Delete Records

```sqf
"forge_server" callExtension ["phone:messages:mark_read", [
    getPlayerUID player,
    _messageId
]];

"forge_server" callExtension ["phone:emails:delete", [
    getPlayerUID player,
    _emailId
]];
```

## Error Handling

```sqf
private _payload = (_result select 0);
if (_payload find "Error:" == 0) then {
    systemChat format ["Phone error: %1", _payload];
};
```
