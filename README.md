# Spirit Blade (Rojo)

Bleach-inspired anime combat sandbox for Roblox — spirit reapers vs Voidspawn. Edit Luau here → Studio updates live via [Rojo](https://rojo.space).

**Game name:** Spirit Blade  
**Sword:** Neon katana (handle + guard + blade) — sheathed on back by default; **E** toggles to right hand  
**Melee:** Sword Attack (M1) — auto-unsheaths if needed  
**Abilities (hotbar):** 1 Flash Step, 2 Spirit Wave, 3–9 locked  
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
- `[SwordService] Equipped SpiritBlade on <name> (N visible parts, sheathed)`
- `[Spirit Blade] Client ready. E sheath · M1 sword · hotbar 1/2 abilities`

## Controls

| Input | Action |
|-------|--------|
| **E** | Toggle sheath / unsheath spirit blade |
| **Mouse1** / tap | Sword Attack — auto-unsheaths; 3-hit melee combo |
| **1** / hotbar slot 1 | Flash Step — short ~11-stud dash (MoveDirection-aimed) |
| **2** / hotbar slot 2 | Spirit Wave — ranged projectile |
| **3–9** | Locked hotbar slots (no-op for now) |

Mobile: on-screen **E Sheath** button; tap hotbar slots for abilities; tap world to sword-attack.

## What you should see in Play

1. A **neon cyan/white katana** on your back at spawn — large handle, metal guard, glowing blade. **E** moves it into your right hand.
2. Ability **hotbar** (9 slots) above the Spirit Power bar — slots 1–2 filled, 3–9 empty.
3. 1–2 **Voidspawn** near spawn — idle until you enter aggro (~35 studs); deaggro beyond ~50.
4. Slash VFX, short flash-step trails, cyan Spirit Wave parts.
5. PvP friendly fire on (sandbox).
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

- `shared/Config.luau` — tunables (Flash Step distance, Voidspawn aggro, costs)
- `shared/Remotes.luau` — `ReplicatedStorage.CombatRemotes`
- `server/SwordService.luau` — Motor6D katana model + sheath toggle
- `server/CombatService.luau` — sword melee, flash step, spirit wave
- `server/VoidspawnService.luau` — PvE + aggro radii
- `client/AbilityHotbar.luau` — 1–9 hotbar UI
- `client/InputController.luau` / `SpiritUI.luau` / `CombatVFX.luau`

Tune numbers in **one place**: `src/shared/Config.luau`.

## Repo

https://github.com/anzu/roblox-rojo-starter
