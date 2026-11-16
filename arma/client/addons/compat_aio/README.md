# Forge Client Compat - AIO

## Overview
Optional compatibility addon for
[AIO - Arma Inventory Overhaul](https://github.com/MissHeda/Arma-Inventory-Overhaul).
It loads only when AIO is loaded (`skipWhenMissingDependencies = 1` with
`aio_main`, `aio_storage` and `aio_gui` in `requiredAddons`); without AIO,
Arma skips it quietly and Forge behaves as before.

## Why it is needed
Forge lockers are per-player boxes made with `createVehicleLocal`. They fill
on the vanilla `ContainerOpened` event and save on `ContainerClosed`. AIO
replaces the vanilla inventory with its own window, so:

- the vanilla container events no longer drive the locker;
- AIO sends moves on objects through the server unless they are marked
  `aio_storage_localOnly`, and the server cannot see a local-only box;
- AIO treats containers as loot that has to be searched unless they are marked
  `aio_noSearch`.

## What it does
For each locker box the locker addon creates (`forge_client_locker_lockersCreated`):

- sets `aio_storage_localOnly` and `aio_noSearch`;
- sets `forge_client_locker_externallyManaged` so the vanilla container
  handlers leave the box alone;
- fills the box once from the saved locker;
- every 2 seconds while the player is within 15 m, compares the box with its
  last saved contents and saves through the locker repository when they differ;
- after a server sync (`forge_client_locker_synced`), refills a box that has no
  unsaved changes, never while the AIO window is open.

## Dependencies
- `forge_client_main`, `forge_client_locker`
- CBA_A3
- AIO (`aio_main`, `aio_storage`, `aio_gui`)

## Tuning
`LOCKER_CHECK_INTERVAL` and `LOCKER_CHECK_RANGE` in `script_component.hpp`.
