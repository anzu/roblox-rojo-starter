# Spirit Blade (Rojo)

Bleach-inspired anime combat sandbox for Roblox — spirit reapers vs Voidspawn. Edit Luau here → Studio updates live via [Rojo](https://rojo.space).

**Game name:** Spirit Blade  
**Abilities:** Spirit Slash (M1), Flash Step (1), Spirit Wave (2)  
**Sword:** Neon spirit blade — sheathed on back by default; **E** toggles sheath  
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
- `[Spirit Blade] Client ready. E sheath · M1 slash · 1 flash · 2 wave`

## Controls

| Input | Action |
|-------|--------|
| **E** | Toggle sheath / unsheath spirit blade |
| **Mouse1** / tap | Spirit Slash — auto-unsheaths on first swing; 3-hit combo |
| **1** | Flash Step — short dash (costs Spirit Power, ~2s CD) |
| **2** | Spirit Wave — ranged projectile (costs Spirit Power, ~5s CD) |
| **3–9** | Reserved (no-op) |

Mobile: on-screen buttons for **1 Flash Step**, **2 Spirit Wave**, and **E Sheath**; tap to slash.

## What you should see in Play

1. Neon cyan/white **spirit blade** on your back (sheathed) — **E** moves it to your hand.
2. Spirit Power bar at the bottom of the screen + control hints.
3. 1–2 **Voidspawn** NPCs near spawn — they idle until you enter aggro range (~35 studs), chase inside that radius, and deaggro beyond ~50.
4. Slash hitboxes, dash trails, and cyan Spirit Wave parts.
5. PvP friendly fire on (sandbox) — players can damage each other with the same abilities.
6. Voidspawn respawn ~8s after death.

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

- `shared/Config.luau` — all tunables (`GameName`, damage, cooldowns, Spirit Power, Voidspawn aggro)
- `shared/Remotes.luau` — creates `ReplicatedStorage.CombatRemotes`
- `shared/CombatTypes.luau` — ability / FX ids
- `server/SwordService.luau` — welded spirit blade + sheath toggle
- `server/CombatService.luau` — server-authoritative melee, dash, projectile
- `server/VoidspawnService.luau` — PvE spawn + aggro AI
- `client/InputController.luau` / `SpiritUI.luau` / `CombatVFX.luau`

Tune numbers in **one place**: `src/shared/Config.luau`.

## Repo

https://github.com/anzu/roblox-rojo-starter
