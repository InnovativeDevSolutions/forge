# Server Module Guides

These pages document the authoritative server-side workflows in Forge.

Most modules follow the same shape:

1. Server SQF gathers game context and validates mission/runtime assumptions.
2. The `forge_server` extension routes the request into the matching command group.
3. Services apply business rules through storage-agnostic repository traits.
4. The extension persists durable state through SurrealDB adapters when needed.

## Gameplay Domains

<u-page-grid>
<u-page-card icon="i-lucide-user-round" title="Actor" to="/server-modules/actor">

Persistent player identity, position, loadout, contact fields, and hot state.

</u-page-card>

<u-page-card icon="i-lucide-wallet" title="Bank" to="/server-modules/bank">

Player funds, transfers, PIN validation, checkout charging, and bank hot state.

</u-page-card>

<u-page-card icon="i-lucide-map" title="CAD" to="/server-modules/cad">

Dispatch requests, assignments, profiles, grouped state, and hydrated views.

</u-page-card>

<u-page-card icon="i-lucide-ambulance" title="Economy" to="/server-modules/economy">

Fuel, service, and medical charging rules across player and organization funds.

</u-page-card>

<u-page-card icon="i-lucide-car-front" title="Garage" to="/server-modules/garage">

Vehicle storage, hot-state updates, and persistence of vehicle condition.

</u-page-card>

<u-page-card icon="i-lucide-package" title="Locker" to="/server-modules/locker">

Player inventory storage, unique item limits, and locker hot-state behavior.

</u-page-card>

<u-page-card icon="i-lucide-building-2" title="Organization" to="/server-modules/organization">

Membership, treasury, shared assets, fleet, and organization hot workflows.

</u-page-card>

<u-page-card icon="i-lucide-key-round" title="Owned Storage" to="/server-modules/owned-storage">

Owner-scoped locker and vehicle unlock storage used by org-linked features.

</u-page-card>

<u-page-card icon="i-lucide-smartphone" title="Phone" to="/server-modules/phone">

Contacts, message threads, and email state for in-game phone workflows.

</u-page-card>

<u-page-card icon="i-lucide-shopping-cart" title="Store" to="/server-modules/store">

Checkout orchestration across pricing, grants, payment sources, and rollback.

</u-page-card>

<u-page-card icon="i-lucide-flag" title="Task" to="/server-modules/task">

Task catalog, ownership, status transitions, defuse counters, and rewards.

</u-page-card>
</u-page-grid>
