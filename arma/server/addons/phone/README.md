# Forge Server Phone

## Overview
The phone addon is the server-side bridge for contacts, SMS messages, and email.
Phone runtime state is owned by the extension. SQF stores preserve the
event-facing API and synchronize client UI state.

## Dependencies
- `forge_server_main`
- `forge_server_common` at runtime for online player lookup
- `forge_server_actor` at runtime for contact and player lookups
- `forge_server_extension` at runtime for phone extension calls
- `forge_client_phone` for response RPCs

## Main Components
- `fnc_initPhoneStore.sqf` coordinates the phone facade.
- `fnc_initContactStore.sqf` manages contacts.
- `fnc_initMessageStore.sqf` manages SMS messages and threads.
- `fnc_initEmailStore.sqf` manages email messages.
- `fnc_initPlayer.sqf` initializes phone data for a player.

## Persistent Extension Tables
- `phone_user`: owner row for an initialized phone profile
- `phone_contact`: per-owner contact rows keyed by owner UID and contact UID
- `phone_message`: shared message records
- `phone_message_index`: per-owner message visibility and read state
- `phone_email`: shared email records
- `phone_email_index`: per-owner email visibility and read state
- `phone_sequence`: global sequence state for generated message and email IDs

## Event Surface
The addon handles client requests to initialize phone state, add/remove/refresh
contacts, send/read/delete messages, send/read/delete emails, and remove phone
state.
