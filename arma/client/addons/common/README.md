# Forge Client Common

## Overview
The common addon contains shared client-side UI bridge helpers and common
configuration used by browser-based feature addons.

## Dependencies
- `forge_client_main`

## Main Components
- `fnc_initWebUIBridge.sqf` provides shared bridge behavior for web browser UI
  controls.
- `WEB_UI_FRAMEWORK.md` documents the proposed shared browser runtime and event
  API for Forge web UIs.

## Notes
Keep feature-specific behavior in the owning addon. Common should hold reusable
browser bridge patterns, not copied application logic.
