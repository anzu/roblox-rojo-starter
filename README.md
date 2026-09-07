# Spirit Blade (Rojo)

Bleach-inspired anime combat sandbox for Roblox — spirit reapers vs Voidspawn. Edit Luau here → Studio updates live via [Rojo](https://rojo.space).

**Game name:** Spirit Blade  
**Sword:** Metal katana + dark saya (scabbard) — saya stays on your back; **E** draws/sheaths the blade into the right hand  
**Melee:** Sword Attack (M1) — auto-unsheaths; **Motor6D.Transform** arm+blade swing (Animator-safe) + mid-swing hitbox  
**Camera:** **Shift** toggles mouse-lock combat aim  
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
- `[Spirit Blade] Client ready. E sheath · M1 sword · Shift lock · hotbar 1/2`

## Controls

| Input | Action |
|-------|--------|
| **E** | Toggle sheath / unsheath katana (saya stays on back) |
| **Mouse1** / tap | Sword Attack — auto-unsheaths; 3-hit combo with visible Transform swing |
| **Shift** | Toggle mouse-lock (LockCenter + face camera look) |
| **1** / hotbar slot 1 | Flash Step — short ~11-stud dash (MoveDirection-aimed) |
| **2** / hotbar slot 2 | Spirit Wave — ranged projectile |
| **3–9** | Locked hotbar slots (no-op for now) |

Mobile: on-screen **E Sheath** button; tap hotbar slots for abilities; tap world to sword-attack. Shift lock is desktop-only.

## What you should see in Play

1. A **dark saya on your back** at spawn (diagonal, not piercing the chest). Sheathed blade handle sticks out the top; steel blade is hidden inside the saya. **E** draws a **normal metal katana** (silver blade, dark ito wrap, tsuba) into your right hand — **no neon / lightsaber glow**.
2. **M1** immediately plays a visible **RightShoulder + blade Transform swing** (horizontal / diagonal / overhead by combo) with a subtle blade trail — **no floating transparent slash part**. Hits ~0.1s mid-swing; forgiving ~8×6×10 hitbox (prefers blade position).
3. **Shift** locks the mouse to center and rotates you toward camera look for easier aiming.
4. Ability **hotbar** (9 slots) above the Spirit Power bar — slots 1–2 filled, 3–9 empty.
5. **Voidspawn** spawn farther out (~70 studs) after a short delay; they ignore you for ~6s after spawn/respawn and only aggro inside ~22 studs (deaggro ~35).
6. Flash-step trails, Spirit Wave parts, hit sparks.
7. PvP friendly fire on (sandbox).
8. Voidspawn respawn ~8s after death.

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

- `shared/Config.luau` — tunables (melee hitbox/delay, Flash Step, Voidspawn)
- `shared/Remotes.luau` — `ReplicatedStorage.CombatRemotes`
- `server/SwordService.luau` — metal katana + back saya (Motor6D sheath)
- `server/CombatService.luau` — sword melee (blade-biased hitbox), flash step, spirit wave
- `server/VoidspawnService.luau` — PvE + aggro radii + player grace
- `client/AbilityHotbar.luau` — 1–9 hotbar UI
- `client/SwingController.luau` — Motor6D.Transform windup→strike→recover on Stepped
- `client/CombatVFX.luau` — remote Slash → other players' swings; flash/hit FX
- `client/ShiftLock.luau` — LeftShift mouse-lock combat camera
- `client/InputController.luau` / `SpiritUI.luau`

Tune numbers in **one place**: `src/shared/Config.luau`.

## Repo

https://github.com/anzu/roblox-rojo-starter
