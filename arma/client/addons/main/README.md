# Forge Client Main

## Overview
The main addon provides shared mod metadata, macros, settings, and compile
infrastructure for Forge client addons.

## Dependencies
- `cba_main`

## Main Components
- `script_macros.hpp` defines shared function, RPC, path, variable, and compile
  macros.
- `script_mod.hpp` and `script_version.hpp` define mod identity and version.
- `CfgSettings.hpp` contains client-side CBA settings.

## Notes
Feature logic should live in the owning addon. Main is the shared foundation for
configuration, macros, and mod-level metadata.
