# Client Usage Guide

Forge Client contains the Arma client-side addons that open player interfaces,
handle browser events, cache client-visible state, and forward authoritative
requests to the server addons.

Use this guide as the entry point for client-side integration. Domain data,
validation, persistence, rewards, ownership, and checkout behavior remain
server-side responsibilities.

## Client Responsibilities

- Open Arma displays and `CT_WEBBROWSER` controls.
- Load browser UI assets from each addon's `ui/_site` folder.
- Receive browser alerts through `JSDialog` handlers.
- Translate browser events into local actions or CBA server events.
- Cache display state in client repositories.
- Push server responses back into browser UIs with `ExecJS`.
- Provide local-only utility state where the feature is intentionally local.

## Authoritative Boundaries

Client repositories are view state. They are useful for rendering, local UI
decisions, and short-lived session behavior, but they should not be treated as
durable state.

Authoritative state lives in:

- server SQF addons for mission and player workflow ownership
- the `forge_server` extension for durable and hot-state domain logic
- SurrealDB where the extension persists durable domain records

## Common Runtime Flow

Most browser-backed client addons follow this shape:

1. The addon creates a display, finds a browser control, and registers a
   `JSDialog` event handler.
2. The browser loads an HTML entrypoint from `ui/_site`.
3. The browser sends JSON alerts with an `event` name and `data` payload.
4. `fnc_handleUIEvents.sqf` parses the alert and routes the event.
5. A bridge object or repository sends a CBA server event when server data is
   needed.
6. Server responses are caught in `XEH_postInitClient.sqf`.
7. The bridge sends browser update events back through `ExecJS`.

Browser alert payload:

```json
{
  "event": "module::action",
  "data": {}
}
```

## Open UI Entry Points

| UI | Entry point |
| --- | --- |
| Actor menu | `call forge_client_actor_fnc_openUI;` |
| Bank | `call forge_client_bank_fnc_openUI;` |
| ATM | `[true] call forge_client_bank_fnc_openUI;` |
| CAD | `call forge_client_cad_fnc_openUI;` |
| Garage | `call forge_client_garage_fnc_openUI;` |
| Virtual garage | `call forge_client_garage_fnc_openVG;` |
| Organization portal | `call forge_client_org_fnc_openUI;` |
| Phone | `call forge_client_phone_fnc_openUI;` |
| Store | `call forge_client_store_fnc_openUI;` |

Notifications are normally opened during client initialization and then updated
through the notification event/service.

## Addon Guides

- [Client Main Usage Guide](./CLIENT_MAIN_USAGE_GUIDE.md)
- [Client Common Usage Guide](./CLIENT_COMMON_USAGE_GUIDE.md)
- [Client Actor Usage Guide](./CLIENT_ACTOR_USAGE_GUIDE.md)
- [Client Bank Usage Guide](./CLIENT_BANK_USAGE_GUIDE.md)
- [Client CAD Usage Guide](./CLIENT_CAD_USAGE_GUIDE.md)
- [Client Garage Usage Guide](./CLIENT_GARAGE_USAGE_GUIDE.md)
- [Client Locker Usage Guide](./CLIENT_LOCKER_USAGE_GUIDE.md)
- [Client Notifications Usage Guide](./CLIENT_NOTIFICATIONS_USAGE_GUIDE.md)
- [Client Organization Usage Guide](./CLIENT_ORG_USAGE_GUIDE.md)
- [Client Phone Usage Guide](./CLIENT_PHONE_USAGE_GUIDE.md)
- [Client Store Usage Guide](./CLIENT_STORE_USAGE_GUIDE.md)

## Extension Calls

Client addons should usually call server SQF events, not the `forge_server`
extension directly. The server addon owns validation context and converts the
request into extension commands.

Example:

```sqf
[SRPC(bank,requestDeposit), [getPlayerUID player, 100]] call CFUNC(serverEvent);
```

Direct extension calls from client code bypass server authorization boundaries
and should be avoided.

## Browser Bridge Notes

`forge_client_common_fnc_initWebUIBridge` provides reusable bridge and screen
objects for newer browser UIs. It queues outbound events until a browser screen
is ready, then delivers payloads through:

```sqf
_control ctrlWebBrowserAction ["ExecJS", format ["ForgeBridge.receive(%1)", _json]];
```

Feature addons still own their event names, request payloads, and response
mapping.

## Development Checklist

- Keep feature-specific behavior in the owning addon.
- Send authoritative changes to the server addon.
- Use namespaced browser events such as `bank::deposit::request`.
- Treat `profileNamespace` as local player preference or utility state only.
- Make browser-ready events request the current server state before rendering
  stale data.
- Queue or ignore bridge responses when the display is closed.
- Keep mission object setup on the mission/server side and client display logic
  on the client side.
