# Client Actor Usage Guide

The client actor addon owns the player interaction menu and client-side actor
repository. It is the main launcher for nearby player actions and other Forge
client UIs.

## Open the Actor Menu

```sqf
call forge_client_actor_fnc_openUI;
```

The actor menu opens `RscActorMenu`, loads `ui/_site/index.html`, and routes
browser alerts through `forge_client_actor_fnc_handleUIEvents`.

## Repository

`forge_client_actor_fnc_initRepository` creates `GVAR(ActorRepository)`.

The repository:

- requests actor initialization from the server
- saves actor state through the server actor addon
- caches client-visible actor fields
- applies position, direction, stance, rank, and loadout on JIP sync when the
  relevant settings allow it
- provides nearby interaction actions to the browser UI

Initialize actor state through the repository:

```sqf
GVAR(ActorRepository) call ["init", []];
```

Save actor state through the server:

```sqf
GVAR(ActorRepository) call ["save", [true]];
```

## Nearby Actions

The menu asks for nearby actions with:

```text
actor::get::actions
```

The repository scans objects within 5 meters and returns actions based on
mission object variables:

| Variable | Action |
| --- | --- |
| `isStore` | store |
| `isAtm` | ATM |
| `isBank` | bank |
| `isGarage` | garage |
| `garageType` | garage subtype |
| `isLocker` | virtual arsenal action when VA is enabled |
| `deviceType` | device action placeholder |
| nearby player unit | player interaction placeholder |

The response is pushed into the browser with `updateAvailableActions(...)`.

## Browser Events

| Event | Client behavior |
| --- | --- |
| `actor::get::actions` | Refresh nearby actions. |
| `actor::close::menu` | Close actor menu. |
| `actor::open::atm` | Open bank UI in ATM mode. |
| `actor::open::bank` | Open bank UI in bank mode. |
| `actor::open::cad` | Open CAD UI. |
| `actor::open::garage` | Open garage UI. |
| `actor::open::vgarage` | Open virtual garage. |
| `actor::open::org` | Open organization UI. |
| `actor::open::vlocker` | Open ACE arsenal on `FORGE_Locker_Box`. |
| `actor::open::phone` | Open phone UI. |
| `actor::open::store` | Open store UI. |

Device and player interaction events currently display placeholder feedback.

## Authoritative State

Actor persistence is server-owned. The client repository requests and displays
actor data, but actor creation, durable updates, and hot-state behavior are
handled by the server actor addon and extension.

## Related Guides

- [Actor Usage Guide](./ACTOR_USAGE_GUIDE.md)
- [Client Bank Usage Guide](./CLIENT_BANK_USAGE_GUIDE.md)
- [Client CAD Usage Guide](./CLIENT_CAD_USAGE_GUIDE.md)
- [Client Garage Usage Guide](./CLIENT_GARAGE_USAGE_GUIDE.md)
- [Client Locker Usage Guide](./CLIENT_LOCKER_USAGE_GUIDE.md)
- [Client Organization Usage Guide](./CLIENT_ORG_USAGE_GUIDE.md)
- [Client Phone Usage Guide](./CLIENT_PHONE_USAGE_GUIDE.md)
- [Client Store Usage Guide](./CLIENT_STORE_USAGE_GUIDE.md)
