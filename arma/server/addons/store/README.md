# Forge Server Store

## Overview
The store addon manages server-side storefront entities, catalog hydration, and
checkout coordination.

SQF owns Arma-facing storefront discovery and request validation. The Rust
extension owns authoritative checkout calculation through `store:checkout`.

## Dependencies
- `forge_server_main`
- `forge_server_common`
- `forge_server_extension` at runtime for checkout calls
- `forge_server_actor`, `forge_server_bank`, and `forge_server_org` at runtime
  for checkout context and payment state
- `forge_client_store` for response RPCs

## Main Components
- `fnc_initStore.sqf` marks editor-placed store objects with `isStore = true`.
- `fnc_initCatalogService.sqf` scans live Arma config categories, builds
  catalog responses, resolves checkout entries, and calculates authoritative
  catalog prices.
- `fnc_initStorefrontStore.sqf` builds hydrate payloads, validates checkout
  requests, calls `store:checkout`, syncs client patches, and coordinates
  related bank/org persistence.

## Editor Entities
`fnc_initStore` matches non-null mission namespace objects whose variable names
contain `store`, mirroring the garage entity initialization pattern.

## Checkout Flow
Store checkout can charge cash, bank balance, organization funds, or approved
credit lines depending on the hydrated session context. Checkout results can
grant locker assets, organization assets, and fleet vehicles through the
related domain stores.

Checkout results emit notifications and syncs through the event bus:
- `notification.requested` - receipt and transaction alerts
- `bank.account.sync.requested` - player balance updates
- `org.sync.requested` - organization balance and asset updates
- `locker.sync.requested` - item grant notifications
- `garage.vgarage.sync.requested` - vehicle grant notifications
