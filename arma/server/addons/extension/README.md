# Forge Server Extension

## Overview
The extension addon is the SQF bridge to the `forge_server` arma-rs extension.
It normalizes `callExtension` responses, routes large payloads through the
transport layer, and exposes helper functions used by extension-backed server
addons.

## Dependencies
- `forge_server_main`

## Main Components
- `fnc_extCall.sqf` is the primary extension call wrapper.
- `fnc_transport.sqf` stages large requests and assembles chunked responses.
- `fnc_setHandler.sqf` registers local SQF handlers for extension callback
  integration.

## Transport Behavior
Most commands use direct `callExtension`. Commands that can return large
payloads, or requests whose encoded arguments exceed the chunk threshold, are
routed through `transport:invoke` or staged transport requests.

The wrapper falls back to direct calls if the transport route is unsupported and
the request was not chunked.

## Notes
Domain addons should call `EFUNC(extension,extCall)` instead of calling the
extension directly. This keeps response handling, chunking, and error logging
consistent.
