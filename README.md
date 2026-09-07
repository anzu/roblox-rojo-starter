# Spirit Blade (Rojo)

Bleach-inspired anime combat sandbox for Roblox — spirit reapers vs Voidspawn. Edit Luau here → Studio updates live via [Rojo](https://rojo.space).

**Game name:** Spirit Blade  
**Sword:** Metal katana + dark saya (scabbard) — saya stays on your back; **E** draws/sheaths the blade into the right hand  
**Melee:** Sword Attack (M1) — auto-unsheaths; visible arm swing + mid-swing hitbox  
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
- `[SwordService] Equipped metal katana + saya on <name> (... sheathed)`
- `[SwordService] Motor6D debug | ...` (once)
- `[Spirit Blade] Client ready. E sheath · M1 sword · hotbar 1/2 abilities`

## Controls

| Input | Action |
|-------|--------|
| **E** | Toggle sheath / unsheath katana (saya stays on back) |
| **Mouse1** / tap | Sword Attack — auto-unsheaths; 3-hit combo with arm swing |
| **1** / hotbar slot 1 | Flash Step — short ~11-stud dash (MoveDirection-aimed) |
| **2** / hotbar slot 2 | Spirit Wave — ranged projectile |
| **3–9** | Locked hotbar slots (no-op for now) |

Mobile: on-screen **E Sheath** button; tap hotbar slots for abilities; tap world to sword-attack.

## What you should see in Play

1. A **dark saya on your back** at spawn (diagonal, not piercing the chest). Sheathed blade handle sticks out the top; steel blade is hidden inside the saya. **E** draws a **normal metal katana** (silver blade, dark ito wrap, tsuba) into your right hand — **no neon / lightsaber glow**.
2. **M1** plays a visible **RightShoulder swing** (horizontal / diagonal / overhead by combo) and hits ~0.12s into the swing.
3. Ability **hotbar** (9 slots) above the Spirit Power bar — slots 1–2 filled, 3–9 empty.
4. **Voidspawn** spawn farther out (~70 studs) after a short delay; they ignore you for ~6s after spawn/respawn and only aggro inside ~22 studs (deaggro ~35).
5. Soft slash trails, flash-step trails, Spirit Wave parts.
6. PvP friendly fire on (sandbox).
7. Voidspawn respawn ~8s after death.

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

- `shared/Config.luau` — tunables (Flash Step distance, Voidspawn aggro/grace, melee hit delay)
- `shared/Remotes.luau` — `ReplicatedStorage.CombatRemotes`
- `server/SwordService.luau` — metal katana + back saya (Motor6D sheath)
- `server/CombatService.luau` — sword melee, flash step, spirit wave
- `server/VoidspawnService.luau` — PvE + aggro radii + player grace
- `client/AbilityHotbar.luau` — 1–9 hotbar UI
- `client/CombatVFX.luau` — slash FX + RightShoulder swing tween
- `client/InputController.luau` / `SpiritUI.luau`

Tune numbers in **one place**: `src/shared/Config.luau`.

## Repo

https://github.com/anzu/roblox-rojo-starter
