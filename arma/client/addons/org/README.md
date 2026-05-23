# Forge Client Organization

## Overview
The organization addon provides the client organization portal UI and bridge for
organization hydrate, registration, membership, invitations, credit lines,
leave/disband actions, assets, fleet, and treasury display. Registration shows
the $50,000 personal funds requirement enforced by the server org addon.

## Dependencies
- `forge_client_common`
- `forge_client_main`
- server organization events from `forge_server_org`
- notifications for user feedback

## Main Components
- `fnc_initRepository.sqf` caches organization portal state.
- `fnc_initUIBridge.sqf` sends browser requests to server org RPCs and pushes
  hydrate/sync events back to the browser.
- `fnc_handleUIEvents.sqf` handles `org::*` browser events.
- `fnc_openUI.sqf` opens `RscOrg`.

## Browser Events
- `org::login::request`
- `org::create::request`
- `org::disband::request`
- `org::leave::request`
- `org::credit::request`
- `org::invite::request`
- `org::invite::accept`
- `org::invite::decline`

## Runtime Notes
The client portal is a view/controller. Organization state, funds, reputation,
credit lines, assets, fleet, and membership are authoritative on the server.
