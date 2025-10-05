# Forge - Arma 3 Mod Collection

This repository contains the Arma 3 mods that make up the Forge collection, organized using Git submodules.

## Features

### Arsenal Module
- **Fast weapon/item unlock system** using Redis Sets
- **Virtual Arsenal integration** for persistent unlocks
- **Batch operations** for efficient bulk unlocks
- **Access control** for mission prerequisites
- **Performance optimized** with O(1) membership checks

See [docs/ARSENAL_API.md](docs/ARSENAL_API.md) for complete API documentation.

## Structure

- `client/` - Client-side mod (Git submodule)
- `server/` - Server-side mod (Git submodule)  
- `mod/` - Shared mod assets and configuration

## Working with Submodules

### Initial Setup
If you're cloning this repository for the first time:
```bash
git clone --recurse-submodules https://github.com/InnovativeDevSolutions/forge
```

Or if you already cloned without submodules:
```bash
git submodule init
git submodule update
```

### Updating Submodules
To pull the latest changes from all submodules:
```bash
git submodule update --remote
```

To update a specific submodule:
```bash
git submodule update --remote client
git submodule update --remote server
```

### Working on Submodules
1. Navigate to the submodule directory: `cd client` or `cd server`
2. Make your changes and commit them normally
3. Push your changes: `git push`
4. Return to the parent directory: `cd ..`
5. Commit the updated submodule reference: `git add client` and `git commit`

### Adding New Submodules
```bash
git submodule add https://github.com/InnovativeDevSolutions/forge <path>
```

### Submodule Information
- **Client**: https://github.com/InnovativeDevSolutions/client.git
- **Server**: https://github.com/InnovativeDevSolutions/server.git

## Notes
- Each submodule maintains its own Git history
- The parent repository tracks specific commits from each submodule
- Always commit submodule reference updates in the parent repository after updating submodules
