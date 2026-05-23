# Forge Server Organization

## Overview
The organization addon is the server-side bridge for player organizations,
membership, treasury funds, reputation, credit lines, shared assets, fleet
entries, and invitations.

Organization hot state is owned by the extension. SQF coordinates Arma-facing
events, UI payloads, membership syncs, and integration with actor, bank, store,
and task flows.

Organization registration charges a $50,000 personal funds fee before the
player is assigned to the new organization.

## Dependencies
- `forge_server_main`
- `forge_server_common`
- `forge_server_extension` at runtime for organization extension calls
- `forge_server_actor` at runtime for organization membership lookups
- `forge_client_org` and `forge_client_notifications` for response RPCs

## Main Components
- `fnc_initOrgStore.sqf` initializes `OrgModel` and `OrgStore`.
- `fnc_initPayloadBuilder.sqf` builds portal, organization, member, asset, and
  fleet payloads.

## Supported Operations
- initialize and hydrate organization portal data
- register, leave, and disband organizations
- invite, accept, and decline members
- assign and repay credit lines
- update funds and reputation
- grant assets and fleet vehicles
- save organization hot state

## Runtime Notes
The addon ensures the `default` organization exists during store creation.
Task rewards and store checkout both rely on `OrgStore` for authoritative
organization-owned state.

Organization syncs and notifications route through the event bus:
- `org.sync.requested` - client-facing organization patch and member updates
- `notification.requested` - alerts about funds, reputation, and membership changes

These events are emitted and listened to by the notifications addon.
