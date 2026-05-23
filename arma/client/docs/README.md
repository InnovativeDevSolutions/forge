# Forge Client Documentation

This folder documents the Arma client mod. The client side is responsible for
displaying UI, handling player input, caching client-visible state, and sending
CBA events to server addons.

Authoritative gameplay state lives on the server side or in the Rust extension.
Client repositories should be treated as view state, not durable storage.

## Architecture
- Each addon declares its own UI resources and CBA extended event handlers.
- `XEH_preStart.sqf`/`XEH_preInit.sqf` compile functions.
- `XEH_postInitClient.sqf` initializes client repositories, UI bridges, and
  response event handlers.
- Browser UIs send JSON events through A3API.
- SQF handlers translate browser events into local actions or server RPCs.
- Server responses update repositories and push browser events back into the UI.

## Addon Docs
- [Main](../addons/main/README.md)
- [Common](../addons/common/README.md)
- [Actor](../addons/actor/README.md)
- [Bank](../addons/bank/README.md)
- [CAD](../addons/cad/README.md)
- [Garage](../addons/garage/README.md)
- [Locker](../addons/locker/README.md)
- [Notifications](../addons/notifications/README.md)
- [Organization](../addons/org/README.md)
- [Phone](../addons/phone/README.md)
- [Store](../addons/store/README.md)

## Related Docs
- [Root Client Usage Guide](../../../docs/CLIENT_USAGE_GUIDE.md)
- [Root Client Main Usage Guide](../../../docs/CLIENT_MAIN_USAGE_GUIDE.md)
- [Root Client Common Usage Guide](../../../docs/CLIENT_COMMON_USAGE_GUIDE.md)
- [Root Client Actor Usage Guide](../../../docs/CLIENT_ACTOR_USAGE_GUIDE.md)
- [Root Client Bank Usage Guide](../../../docs/CLIENT_BANK_USAGE_GUIDE.md)
- [Root Client CAD Usage Guide](../../../docs/CLIENT_CAD_USAGE_GUIDE.md)
- [Root Client Garage Usage Guide](../../../docs/CLIENT_GARAGE_USAGE_GUIDE.md)
- [Root Client Locker Usage Guide](../../../docs/CLIENT_LOCKER_USAGE_GUIDE.md)
- [Root Client Notifications Usage Guide](../../../docs/CLIENT_NOTIFICATIONS_USAGE_GUIDE.md)
- [Root Client Organization Usage Guide](../../../docs/CLIENT_ORG_USAGE_GUIDE.md)
- [Root Client Phone Usage Guide](../../../docs/CLIENT_PHONE_USAGE_GUIDE.md)
- [Root Client Store Usage Guide](../../../docs/CLIENT_STORE_USAGE_GUIDE.md)
- [Shared web UI framework notes](../addons/common/WEB_UI_FRAMEWORK.md)
- [CAD map integration notes](../addons/cad/MAP_README.md)
- [Root framework docs](../../../docs/README.md)
