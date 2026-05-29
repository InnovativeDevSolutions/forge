# FORGE Shared Mod

Shared client/server config classes for FORGE missions. This HEMTT project
builds to `@forge_mod`.

Load `@forge_mod` on both clients and servers. Server runtime systems remain in
`@forge_server`, and player-facing UI remains in `@forge_client`.

## Addons

- `forge_mod_common`: shared vehicle/config definitions, including
  `forge_bodyBag`.
- `forge_mod_task`: Forge Eden task module classes used by missions. The module
  config points at server-side task functions, but those functions are still
  provided by `@forge_server`.

Mission `requiredAddons` should reference `forge_mod_*` packages for shared
classes. Clients should never need `@forge_server` just to load or edit a Forge
mission.
