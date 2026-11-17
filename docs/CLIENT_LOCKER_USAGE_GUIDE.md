# Client Locker Usage Guide

The client locker addon manages personal locker display state, local locker
container behavior, and virtual arsenal unlock state.

## Repositories

`forge_client_locker_fnc_initRepository` creates `GVAR(LockerRepository)`.

`forge_client_locker_fnc_initVARepository` creates `GVAR(VARepository)`.

Initialize locker state:

```sqf
GVAR(LockerRepository) call ["init", []];
GVAR(VARepository) call ["init", []];
```

## Locker Container Flow

The repository searches mission namespace variables whose names contain
`locker` and refer to objects. For each server/mission locker object, it creates
a local box of the same class (`Box_NATO_Equip_F` if it has none) at the same
position and attaches container event handlers. The server hides the placed
locker objects, so players only interact with their own local box.

On container open:

- the local container is cleared
- cached locker items are inserted into the container
- over-capacity warnings are emitted when the item count is above 25

On container close:

- cargo, nested container items, and weapon attachments are read back
- the new locker map is sent to the server with the override request
- the local repository cache is updated

The override only updates the server's in-memory state. It reaches the
database on autosave, disconnect or mission end; see
[When Player Data Is Saved](./surrealdb-setup.md#when-player-data-is-saved).

Backpacks cannot be put into a local-only box in multiplayer (the engine logs
"Tried to create local-only container with backpacks"), so stored backpacks do
not appear in the locker.

### Compatibility hooks

Compat addons can take over a box's fill/save cycle:

- `forge_client_locker_lockersCreated [lockers]` and `forge_client_locker_synced []`
  (local CBA events)
- `forge_client_locker_externallyManaged = true` on a box makes the vanilla
  container handlers skip it
- repository methods `fillContainer`, `readContainer`, `commitContainer`

### AIO - Arma Inventory Overhaul

AIO replaces the vanilla inventory, so the container events above no longer
drive the locker. The optional `forge_client_compat_aio` addon loads only with
AIO (`skipWhenMissingDependencies`) and, for each locker box:

- sets `aio_storage_localOnly` (moves run on the player's machine) and
  `aio_noSearch` (the locker is not loot)
- fills it once when it is created
- saves it when its contents change, checked every 2 s within 15 m
- refills it after a server sync when it has no unsaved changes

## Virtual Arsenal Flow

The virtual arsenal repository creates a local `FORGE_Locker_Box` and requests
virtual arsenal unlocks from the server.

As sync data arrives, it applies unlocks through ACE Arsenal:

| Data key | Client behavior |
| --- | --- |
| `items` | Add virtual items. |
| `weapons` | Add virtual weapons. |
| `magazines` | Add virtual magazines. |
| `backpacks` | Add virtual backpacks. |

The actor menu opens the virtual locker with:

```sqf
[FORGE_Locker_Box, player, false] spawn ace_arsenal_fnc_openBox;
```

## Server Events

The client repository sends requests for:

- locker initialization
- locker save
- locker override after container close
- virtual arsenal initialization
- virtual arsenal save

The server locker addon and extension own the saved locker and virtual arsenal
state.

## Mission Setup

Mission locker objects must be placed into `missionNamespace` with a variable
name containing `locker`. The client creates local interactive containers from
those authoritative mission objects.

Example:

```sqf
missionNamespace setVariable ["forge_locker_alpha", _lockerObject, true];
```

## Related Guides

- [Locker Usage Guide](./LOCKER_USAGE_GUIDE.md)
- [Owned Storage Usage Guide](./OWNED_STORAGE_USAGE_GUIDE.md)
- [Client Actor Usage Guide](./CLIENT_ACTOR_USAGE_GUIDE.md)
