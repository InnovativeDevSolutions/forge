# Git Workflow

This repository uses `master` as the clean framework branch. Mission folders are
kept off `master` so the framework can be versioned without bundling local test
missions or playable mission copies.

## Workflow Helper

The repository includes a small helper for the common branch checks and branch
switching commands:

```powershell
npm run workflow -- status
npm run workflow -- doctor
npm run workflow -- switch dev
npm run workflow -- switch missions
npm run workflow -- start-feature cad-task-request
npm run workflow -- release-check
```

The helper refuses branch switches and feature branch creation when the working
tree has uncommitted changes. Use the manual Git commands below when you need
more control.

## Branch Roles

- `master`: framework source, addon code, Rust extension code, docs, tooling,
  and release tags.
- `missions/local-mission-copies`: local mission folders used for testing and
  mission iteration. This branch is not pushed unless intentionally needed.
- `archive/pre-v0.1-history`: read-only archive of the previous full `master`
  history before the `v0.1.0` baseline cleanup.

## Daily Framework Work

Start from the clean framework branch.

```powershell
git switch master
git pull
git status --short --branch
```

Create a short-lived feature branch for framework work.

```powershell
git switch -c feature/garage-marker-selection
```

Make the change, validate it, then commit.

```powershell
git status --short --branch
git add arma/client/addons/garage/functions/fnc_initContextService.sqf
git commit -m "Improve garage spawn marker selection"
```

Merge the work back into `master`. Squash merges keep future `master` history
compact.

```powershell
git switch master
git merge --squash feature/garage-marker-selection
git commit -m "Improve garage spawn marker selection"
git push
```

Remove the local feature branch when it is no longer needed.

```powershell
git branch -D feature/garage-marker-selection
```

## Mission Work

Switch to the local mission branch before editing mission folders.

```powershell
git switch missions/local-mission-copies
git status --short --branch
```

Mission folders currently tracked on that branch:

```text
arma/forge_framework.Malden
arma/forge_pmc_simulator.Tanoa
arma/forge_pmc_simulator_v2.Tanoa
```

Commit mission-only changes on the mission branch.

```powershell
git add arma/forge_pmc_simulator.Tanoa
git commit -m "Update PMC simulator mission setup"
```

Do not merge the mission branch into `master`. If a mission change becomes
framework code, copy only the reusable files or logic onto a framework feature
branch created from `master`.

Example:

```powershell
git switch master
git switch -c feature/cad-on-demand-task-request

# Bring over only the framework files needed from the mission branch.
git checkout missions/local-mission-copies -- arma/client/addons/cad/functions/fnc_initUIBridge.sqf
git checkout missions/local-mission-copies -- arma/server/addons/cad/XEH_preInit.sqf

git add arma/client/addons/cad/functions/fnc_initUIBridge.sqf arma/server/addons/cad/XEH_preInit.sqf
git commit -m "Add CAD on-demand mission task request bridge"
```

## Release Versioning

Use tags to mark framework releases.

Version guideline:

- Patch, such as `v0.1.1`: fixes and small compatible changes.
- Minor, such as `v0.2.0`: new modules or features.
- Major, such as `v1.0.0`: stable release line or breaking changes.

Create a release tag from `master`.

```powershell
git switch master
git pull
git status --short --branch
git tag -a v0.1.1 -m "v0.1.1"
git push origin master
git push origin v0.1.1
```

## Safety Checks

Before committing on `master`, check that no mission folders are staged.

```powershell
git status --short --branch
```

On `master`, these paths should not appear:

```text
arma/forge_framework.Malden
arma/forge_pmc_simulator.Tanoa
arma/forge_pmc_simulator_v2.Tanoa
```

If mission files appear while on `master`, stop and switch to the mission
branch before continuing.

```powershell
git switch missions/local-mission-copies
```

