# Forge Client Store

## Overview
The store addon provides the client storefront UI for catalog browsing,
category loading, payment-source display, cart handling, and checkout requests.

## Dependencies
- `forge_client_common`
- `forge_client_main`
- server store events from `forge_server_store`
- bank/org/locker/garage server state through checkout results

## Main Components
- `fnc_initUIBridge.sqf` handles browser readiness, category requests, checkout
  requests, and server responses.
- `fnc_handleUIEvents.sqf` handles `store::*` browser events.
- `fnc_openUI.sqf` opens `RscStore`.

## Browser Events
- `store::ready`
- `store::category::request`
- `store::checkout::request`
- `store::close`

## Runtime Notes
The client never calculates authoritative checkout results. The server store
addon and extension validate prices, charge payment sources, grant assets, and
return patches for the UI.
