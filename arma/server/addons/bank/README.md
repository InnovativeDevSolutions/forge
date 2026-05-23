# Forge Server Bank

## Overview
The bank addon owns the SQF bridge for player accounts, cash and bank balances,
PIN/session handling, transfers, checkout charging, earnings deposits, and
credit-line repayment. It also verifies and persists player-requested ATM PIN
changes.

Account truth lives in the extension hot cache. SQF handles Arma-facing
validation, client messaging, session state, and payment integration with other
server addons.

## Dependencies
- `forge_server_main`
- `forge_server_common`
- `forge_server_extension` at runtime for bank extension calls
- `forge_server_org` at runtime for credit-line repayment
- `forge_client_bank` and `forge_client_notifications` for response RPCs

## Main Components
- `fnc_initBank.sqf` initializes all bank stores and helpers.
- `fnc_initModel.sqf` defines account defaults and migration behavior.
- `fnc_initPayloadBuilder.sqf` builds UI, checkout, and organization payment
  context.
- `fnc_initSessionManager.sqf` manages PIN and authorization session state.
- `fnc_initMessenger.sqf` sends account syncs, alerts, and notifications.
- `fnc_initStore.sqf` wraps hot bank calls and account mutations.

## Supported Operations
- initialize and hydrate player bank state
- deposit, withdraw, transfer, and deposit earnings
- validate PIN-backed sessions and change ATM PINs
- charge checkout previews and committed purchases
- repay organization credit lines with rollback on failure
- save hot bank state to durable storage

## Runtime Notes
`forge_server_main_fnc_saveHotState` saves bank hot state on disconnect and
mission shutdown. Store checkout and task rewards use this addon for
authoritative player balance changes.

Account syncs and notifications route through the event bus:
- `bank.account.sync.requested` - client-facing account sync
- `notification.requested` - alerts and transaction notifications

These events are emitted and listened to by the notifications addon.
