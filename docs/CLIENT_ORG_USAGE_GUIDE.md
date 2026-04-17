# Client Organization Usage Guide

The client organization addon provides the organization portal UI and browser
bridge for login, registration, membership, invites, credit lines, leave and
disband flows, assets, fleet, and treasury display.

## Open Organization UI

```sqf
call forge_client_org_fnc_openUI;
```

The UI opens `RscOrg`, loads `ui/_site/index.html`, and routes browser alerts
through `forge_client_org_fnc_handleUIEvents`.

## Repository and Bridge

`forge_client_org_fnc_initRepository` caches organization portal state.

`forge_client_org_fnc_initUIBridge` owns:

- active browser control tracking
- portal hydrate requests
- create/login response routing
- leave and disband requests
- credit-line assignment requests
- invite, accept invite, and decline invite requests
- targeted browser response events

## Browser Events

| Event | Client behavior |
| --- | --- |
| `org::ready` | Mark browser ready and request `org::sync`. |
| `org::login::request` | Request portal hydrate as `org::login::success`. |
| `org::create::request` | Validate org name and request creation on server. |
| `org::disband::request` | Request disband on server. |
| `org::leave::request` | Request leave on server. |
| `org::credit::request` | Request credit-line assignment. |
| `org::invite::request` | Request member invite. |
| `org::invite::accept` | Accept invite by org ID. |
| `org::invite::decline` | Decline invite by org ID. |
| `org::close` | Close the display. |

## Browser Response Events

| Event | Purpose |
| --- | --- |
| `org::sync` | Full portal sync payload. |
| `org::login::success` | Login hydrate payload. |
| `org::create::success` | Creation hydrate payload. |
| `org::create::failure` | Creation validation or server failure. |
| `org::disband::success` | Requester disband success. |
| `org::disband::failure` | Disband failure. |
| `org::portal::revoked` | Portal state revoked by someone else's disband action. |
| `org::leave::success` | Leave success. |
| `org::leave::failure` | Leave failure. |
| `org::credit::success` | Credit-line request success. |
| `org::credit::failure` | Credit-line request failure. |
| `org::member::creditUpdated` | Targeted member credit-line patch. |
| `org::invite::success` | Invite success. |
| `org::invite::failure` | Invite failure. |
| `org::invite::decision::success` | Invite accept/decline success. |
| `org::invite::decision::failure` | Invite accept/decline failure. |

## Request Examples

Create organization request payload:

```json
{
  "orgName": "Example Logistics"
}
```

Credit-line request payload:

```json
{
  "memberUid": "76561198000000000",
  "memberName": "Player Name",
  "amount": 2500
}
```

Invite request payload:

```json
{
  "targetUid": "76561198000000000",
  "targetName": "Player Name"
}
```

## Authoritative State

Organization funds, reputation, membership, invites, credit lines, assets,
fleet, and persistence are server-owned. The client portal only displays and
requests changes.

## Related Guides

- [Organization Usage Guide](./ORG_USAGE_GUIDE.md)
- [Client Common Usage Guide](./CLIENT_COMMON_USAGE_GUIDE.md)
- [Client Bank Usage Guide](./CLIENT_BANK_USAGE_GUIDE.md)
- [Client Store Usage Guide](./CLIENT_STORE_USAGE_GUIDE.md)
