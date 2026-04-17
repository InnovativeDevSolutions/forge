# Forge Client Phone

## Overview
The phone addon provides the in-game phone UI for contacts, SMS messages, and
email. It keeps a local `PhoneClass` facade for view state and sends all
authoritative operations to the server phone addon.

## Dependencies
- `forge_client_main`
- server phone events from `forge_server_phone`
- notifications for contact/message/email feedback

## Main Components
- `fnc_initClass.sqf` initializes the local phone facade.
- `fnc_handleUIEvents.sqf` translates browser events into server phone RPCs.
- `fnc_openUI.sqf` opens `RscPhone`.
- `ui/_site` contains the browser phone UI source.

## Supported Operations
- initialize and sync phone state
- refresh contacts
- add/remove contacts by UID, phone number, or email
- send, read, and delete SMS messages
- send, read, and delete email
- push incoming message/email updates into the browser UI

## Runtime Notes
Phone data is owned by the server extension. Client state is only used to render
the phone UI and provide immediate feedback.
