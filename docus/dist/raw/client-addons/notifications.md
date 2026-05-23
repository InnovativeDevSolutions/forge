# Client Notifications Usage Guide

The client notifications addon owns the notification HUD, notification sound,
and local notification service used by Forge client and server modules.

## Runtime Behavior

The notification display is created during client initialization. The browser
HUD sends:

```text
notifications::ready
```

When that event is received, `NotificationService` initializes and sends a
startup notification.

## Create a Notification

Use the notification service when available:

```sqf
GVAR(NotificationService) call ["create", [
    "success",
    "Title",
    "Notification text.",
    4000
]];
```

Arguments:

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        _type
      </code>
    </td>
    
    <td>
      Notification type, such as <code>
        success
      </code>
      
      , <code>
        info
      </code>
      
      , <code>
        warning
      </code>
      
      , or <code>
        error
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        _title
      </code>
    </td>
    
    <td>
      Notification title.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        _content
      </code>
    </td>
    
    <td>
      Notification body text.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        _duration
      </code>
    </td>
    
    <td>
      Display duration in milliseconds.
    </td>
  </tr>
</tbody>
</table>

The service dispatches a browser `forge:notify` custom event.

## CBA Event Surface

Other addons can use the client notification event:

```sqf
["forge_client_notifications_recieveNotification", [
    "warning",
    "Garage",
    "Vehicle spawn position is blocked.",
    3000
]] call CBA_fnc_localEvent;
```

The event payload is:

```sqf
[_type, _title, _content, _duration]
```

## Usage Rules

- Use the shared notification service instead of opening separate transient
browser UIs.
- Keep server-driven player feedback short and actionable.
- Treat notification state as transient client UI state.
- Do not use notifications as the only record of durable domain changes.

## Related Guides

- [Client Usage Guide](/client-addons)
- [Client Garage Usage Guide](/client-addons/garage)
- [Client Bank Usage Guide](/client-addons/bank)
- [Client Store Usage Guide](/client-addons/store)
