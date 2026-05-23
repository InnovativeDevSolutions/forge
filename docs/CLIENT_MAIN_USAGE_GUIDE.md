# Client Main Usage Guide

The client `main` addon provides the shared mod identity, version metadata,
CBA settings, and macro foundation used by the Forge client addons.

## Purpose

Use `forge_client_main` as the foundation dependency for client addons that
need Forge macros, function naming, settings, or mod-level configuration.

Feature logic should stay in the owning addon. `main` should remain limited to
shared client configuration and compile infrastructure.

## Key Files

| File | Purpose |
| --- | --- |
| `script_mod.hpp` | Client mod identity. |
| `script_version.hpp` | Client mod version values. |
| `script_macros.hpp` | Shared client macros. |
| `CfgSettings.hpp` | Client CBA settings. |
| `config.cpp` | Addon config and mod wiring. |

## Dependency Pattern

Feature addons normally depend on `forge_client_main` in their `config.cpp`.

```cpp
class forge_client_example {
    requiredAddons[] = {
        "forge_client_main"
    };
};
```

## Usage Notes

- Put domain UI, repositories, and event handling in feature addons.
- Put reusable browser bridge behavior in `forge_client_common`.
- Put server-only behavior in `arma/server/addons`.
- Keep settings in `CfgSettings.hpp` when they apply to the client mod as a
  whole or to a client feature toggle.

## Related Guides

- [Client Usage Guide](./CLIENT_USAGE_GUIDE.md)
- [Client Common Usage Guide](./CLIENT_COMMON_USAGE_GUIDE.md)
- [Development Guide](./DEVELOPMENT_GUIDE.md)
