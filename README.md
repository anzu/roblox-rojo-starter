# Family Roblox Starter (Rojo)

Minimal Roblox place synced from this folder via [Rojo](https://rojo.space). Edit Luau here → Studio updates live.

## Mac setup (once)

1. **Install Aftman** (pins Rojo for this repo):
   ```bash
   brew install aftman
   ```
   Or see https://github.com/LPGhatguy/aftman

2. In this folder:
   ```bash
   aftman install
   ```
   That installs the Rojo version from `aftman.toml`.

3. **Roblox Studio plugin:** In Studio → Plugins → Get Plugins → search **Rojo**, install the official one (or install from https://rojo.space/docs/installation).

4. Open a **new Baseplate** (or any place) in Studio. File → Save to File is optional; Rojo owns the scripts.

## Connect every session

```bash
cd /path/to/roblox-rojo-starter
rojo serve
```

In Studio: **Plugins → Rojo → Connect** (default `localhost:34872`).

Press **Play**. Output should show something like:

- `[Family Roblox Starter] Hello, server!`
- `[Family Roblox Starter] Hello, <YourName>!`

Change `src/shared/Config.luau` → save → Rojo syncs → Play again to confirm.

## Layout

| Disk | Roblox |
|------|--------|
| `src/shared/` | `ReplicatedStorage.Shared` |
| `src/server/` | `ServerScriptService.Server` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` |

## Repo

https://github.com/anzu/roblox-rojo-starter (private)
