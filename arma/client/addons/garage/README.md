# Forge Client Garage

## Overview
The garage addon provides player vehicle storage UI, vehicle store/retrieve
actions, selected nearby vehicle service requests, and virtual garage state on
the client.

## Dependencies
- `forge_client_common`
- `forge_client_main`
- server garage events from `forge_server_garage`
- notifications for action feedback

## Main Components
- `fnc_initRepository.sqf` manages player garage view state.
- `fnc_initVGRepository.sqf` manages virtual garage view state.
- `fnc_initHelperService.sqf` resolves vehicle names, hit points, and payload
  details.
- `fnc_initContextService.sqf` gathers nearby/current vehicle context.
- `fnc_initPayloadService.sqf` builds browser hydrate payloads.
- `fnc_initActionService.sqf` sends store/retrieve requests, forwards selected
  nearby vehicle refuel/repair service requests, and handles action responses.
- `fnc_initUIBridge.sqf` pushes hydrate/sync events to the browser.
- `fnc_openUI.sqf` opens `RscGarage`.
- `fnc_openVG.sqf` opens the Arma garage-style virtual garage view.

## Browser Events
- `garage::ready`
- `garage::refresh`
- `garage::vehicle::retrieve::request`
- `garage::vehicle::store::request`
- `garage::vehicle::refuel::request`
- `garage::vehicle::repair::request`
- `garage::close`

## Runtime Notes
The client builds vehicle context and sends requests. The server garage addon
and extension own stored vehicle state.

Virtual garage spawning resolves the active garage context and category lane,
then finalizes only the vehicle selected in that BIS garage session. Nearby
world vehicles are ignored as spawn candidates and are only used for the spawn
blocking check at the resolved lane.

Refuel and repair buttons are available from the selected vehicle detail panel
for nearby world vehicles. Stored records must be retrieved before they can be
serviced because fuel and repair operate on live vehicle objects. Service
billing is handled by the server economy addon and charges organization funds.
