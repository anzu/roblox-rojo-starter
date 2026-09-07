# Spirit Blade (Rojo)

Bleach-inspired anime combat sandbox for Roblox — spirit reapers vs Voidspawn. Edit Luau here → Studio updates live via [Rojo](https://rojo.space).

**Game name:** Spirit Blade  
**Abilities:** Spirit Slash (M1), Flash Step (Q), Spirit Wave (E)  
**Meter:** Spirit Power (regenerates; spent on Flash Step / Spirit Wave)

## Quick start every session

```bash
git pull
cd /path/to/roblox-rojo-starter
aftman install   # once per machine / after tool bumps
rojo serve
```

In Roblox Studio: **Plugins → Rojo → Connect** (default `localhost:34872`).

Press **Play**.

Output should show:

- `[Spirit Blade] Server combat systems online.`
- `[Spirit Blade] Client ready. M1 slash · Q flash step · E spirit wave`

## Controls

| Input | Action |
|-------|--------|
| **Mouse1** / tap | Spirit Slash — 3-hit melee combo |
| **Q** | Flash Step — short dash (costs Spirit Power, ~2s CD) |
| **E** | Spirit Wave — ranged projectile (costs Spirit Power, ~5s CD) |

Mobile: on-screen buttons for Flash Step / Spirit Wave; tap to slash.

## What you should see in Play

1. Spirit Power bar at the bottom of the screen + control hints.
2. 1–2 **Voidspawn** NPCs near spawn — they walk toward you and melee.
3. Slash hitboxes, dash trails, and cyan Spirit Wave parts.
4. PvP friendly fire on (sandbox) — players can damage each other with the same abilities.
5. Voidspawn respawn ~8s after death.

## Mac setup (once)

1. Install [Aftman](https://github.com/LPGhatguy/aftman): `brew install aftman`
2. In this folder: `aftman install` (pins Rojo from `aftman.toml`)
3. Studio plugin: Plugins → Get Plugins → **Rojo** (or https://rojo.space/docs/installation)
4. Open a Baseplate (or any place). Rojo owns the scripts under `ReplicatedStorage.Shared`, `ServerScriptService.Server`, `StarterPlayerScripts.Client`.

## Layout

| Disk | Roblox |
|------|--------|
| `src/shared/` | `ReplicatedStorage.Shared` |
| `src/server/` | `ServerScriptService.Server` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` |

### Key modules

- `shared/Config.luau` — all tunables (`GameName`, damage, cooldowns, Spirit Power, Voidspawn)
- `shared/Remotes.luau` — creates `ReplicatedStorage.CombatRemotes`
- `shared/CombatTypes.luau` — ability / FX ids
- `server/CombatService.luau` — server-authoritative melee, dash, projectile
- `server/VoidspawnService.luau` — PvE spawn + AI
- `client/InputController.luau` / `SpiritUI.luau` / `CombatVFX.luau`

Tune numbers in **one place**: `src/shared/Config.luau`.

## Repo

https://github.com/anzu/roblox-rojo-starter
