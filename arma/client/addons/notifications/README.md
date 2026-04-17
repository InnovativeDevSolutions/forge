# Forge Client Notifications

## Overview
The notifications addon owns the client notification HUD, notification sound,
and local notification service used by other Forge client and server modules.

## Dependencies
- `forge_client_main`

## Main Components
- `fnc_initService.sqf` manages queued and visible notifications.
- `fnc_openUI.sqf` opens the notification HUD display.
- `fnc_handleUIEvents.sqf` handles browser/HUD events.
- `CfgSounds.hpp` defines the notification sound.

## Event Surface
`forge_client_notifications_recieveNotification` accepts:

```sqf
[_type, _title, _content, _duration]
```

The event plays the configured sound and adds the notification to the HUD.

## Runtime Notes
The HUD opens after the virtual arsenal repository is loaded. Other addons
should use this notification event instead of creating their own transient UI.
