# Forge Client

Forge Client contains the Arma client-side addons for Forge. It owns player UI,
browser bridges, client repositories, local event handling, and client-to-server
CBA RPC requests.

The client mod pairs with `arma/server`: client addons collect player input and
render state, while server addons and the Rust extension own authoritative
state and persistence.

## Requirements
- CBA A3
- ACE3 for features that use ACE interactions, arsenal, spectator, or medical
  integrations
- Forge Server running the matching server-side addons

## Addons
- `main`: shared client mod config and macros
- `common`: shared browser UI bridge helpers
- `actor`: player interaction menu and actor repository
- `bank`: banking UI and account request bridge
- `cad`: map/CAD UI for dispatch, groups, tasks, and support requests
- `garage`: vehicle storage and virtual garage UI
- `locker`: locker and virtual arsenal repositories
- `notifications`: notification HUD and sounds
- `org`: organization portal UI
- `phone`: phone, contacts, messages, and email UI
- `store`: storefront catalog and checkout UI

## UI Pattern
Most feature UIs use an Arma display with a `CT_WEBBROWSER` control. JavaScript
sends JSON events through A3API, SQF handles them in `fnc_handleUIEvents.sqf`,
and response events are sent back into the browser with `ctrlWebBrowserAction
["ExecJS", ...]`.

Client repositories cache the most recent state for display only. Server addons
and the extension remain authoritative.

## Documentation
- [Root client usage guide](../../docs/CLIENT_USAGE_GUIDE.md)
- [Client docs](./docs/README.md)
- [Common web UI framework notes](./addons/common/WEB_UI_FRAMEWORK.md)
- [CAD map integration notes](./addons/cad/MAP_README.md)

## License
Forge Client is licensed under [APL-SA](./LICENSE.md).
