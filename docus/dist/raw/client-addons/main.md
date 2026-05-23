# Client Main Usage Guide

The client `main` addon provides the shared mod identity, version metadata,
CBA settings, and macro foundation used by the Forge client addons.

## Purpose

Use `forge_client_main` as the foundation dependency for client addons that
need Forge macros, function naming, settings, or mod-level configuration.

Feature logic should stay in the owning addon. `main` should remain limited to
shared client configuration and compile infrastructure.

## Key Files

<table>
<thead>
  <tr>
    <th>
      File
    </th>
    
    <th>
      Purpose
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        script_mod.hpp
      </code>
    </td>
    
    <td>
      Client mod identity.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        script_version.hpp
      </code>
    </td>
    
    <td>
      Client mod version values.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        script_macros.hpp
      </code>
    </td>
    
    <td>
      Shared client macros.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        CfgSettings.hpp
      </code>
    </td>
    
    <td>
      Client CBA settings.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        config.cpp
      </code>
    </td>
    
    <td>
      Addon config and mod wiring.
    </td>
  </tr>
</tbody>
</table>

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

- [Client Usage Guide](/client-addons)
- [Client Common Usage Guide](/client-addons/common)
- [Development Guide](/getting-started/development)
