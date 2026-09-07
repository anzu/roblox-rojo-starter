# Spirit Blade (Rojo)

Bleach-inspired anime combat sandbox for Roblox — spirit reapers vs Voidspawn. Edit Luau here → Studio updates live via [Rojo](https://rojo.space).

**Game name:** Spirit Blade  
**Sword:** Higher-fidelity metal uchigatana (tsuba / ito wrap / kissaki) + dark saya on back — **E** draws/sheaths into the right hand  
**Melee (Zanjutsu):** Sword Attack (M1) — auto-unsheaths; **arm-driven** Motor6D.Transform swing (sword welded to hand); hit 3 knocks back + briefly stuns Voidspawn  
**Sprint:** **Shift** hold (WalkSpeed boost)  
**Camera:** **Ctrl** toggles mouse-lock combat aim (+ subtle soft assist toward nearby Voidspawn)  
**Abilities (hotbar):** 1 Flash Step, 2 Spirit Wave, 3 Spirit Guard (hold), 4–9 locked  
**Meter (Reiatsu):** Spirit Power — regenerates; gain a little on successful melee hits; spent on Flash Step / Spirit Wave / Guard

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
- `[Spirit Blade] Client ready. E sheath · M1 sword · Shift sprint · Ctrl lock · F guard · hotbar 1/2/3`

## Controls

| Input | Action |
|-------|--------|
| **E** | Toggle sheath / unsheath katana (saya stays on back) |
| **Mouse1** / tap | Sword Attack — auto-unsheaths; 3-hit Zanjutsu combo (**arm moves, sword follows**) |
| **Shift** (hold) | Sprint (WalkSpeed ~16→28) |
| **Ctrl** | Toggle mouse-lock (LockCenter + face camera look; soft assist toward Voidspawn) |
| **F** / **hotbar 3** (hold) | Spirit Guard — block frontal melee (chip damage; drains Spirit) |
| **1** / hotbar slot 1 | Flash Step — short ~11-stud dash (cancels late swing recovery) |
| **2** / hotbar slot 2 | Spirit Wave — ranged projectile |
| **4–9** | Locked hotbar slots (no-op for now) |

Mobile: on-screen **E Sheath** button; tap/hold hotbar slots for abilities; tap world to sword-attack. Sprint / Ctrl lock are desktop-oriented.

## What you should see in Play

1. A **dark saya on your back** at spawn (koiguchi mouth + kojiri tip). **E** draws a long thin **metal katana** (steel blade, dark ito wrap, round tsuba) into your right hand — **no neon / lightsaber glow**. Sheathed: only handle + tsuba stick out of the saya mouth.
2. **M1** plays a fluid **~0.5s arm-chain Transform slash** (RightShoulder + RightElbow + RightWrist — **blade stays welded**, never self-animates). Horizontal / diagonal / overhead with a soft blade trail. Hits mid-late swing; forgiving wide hitbox + Voidspawn magnet cone (~10 studs).
3. **Hit 3** knocks Voidspawn back and briefly stuns them.
4. **Shift** sprints; **Ctrl** locks mouse to center and rotates you toward camera look (subtle soft yaw toward Voidspawn in front).
5. **F** / hotbar **3** holds Spirit Guard — frontal Voidspawn melee chips instead of full damage.
6. Ability **hotbar** (9 slots) — slots 1–3 filled, 4–9 empty.
7. Successful melee hits restore a little **Spirit Power**.
8. **Voidspawn** spawn farther out (~70 studs); ignore you for ~6s; aggro ~22 / deaggro ~35. They **do not jump onto your head** — they hold a ~5.5-stud standoff ring and back up if too close.
9. Flash-step trails, Spirit Wave parts, hit/guard/stun sparks.
10. PvP friendly fire on (sandbox). Voidspawn respawn ~8s after death.

## Test checklist (Andrew)

```bash
git pull
# Rojo connect → Play
```

Try, in order:

1. **Walk + M1 while moving** — must not get stuck walking one direction after the swing.
2. **Shift hold** — sprint faster; release returns to normal walk. Shift is **not** camera lock.
3. **Ctrl** — toggle camera lock; face camera yaw; unlock restores free rotate.
4. **M1×3** — **arm arc visible**, sword stuck to hand (not floating alone); hit 3 stuns/knocks Voidspawn.
5. Fight Voidspawn — they stay on the ground at melee range, **do not pile on your head**.
6. **F** hold / hotbar **3** — **guard arm pose** across body; block frontal Voidspawn hits (chip + Spirit drain).
7. **1** Flash Step — brief arm tuck pose; during late swing cancels recovery cleanly.
8. **2** Spirit Wave — cast arm thrust; Spirit Power regen + small gain on melee hits.

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

- `shared/Config.luau` — all tunables (melee, sprint, guard, Voidspawn, soft lock)
- `shared/Remotes.luau` — `ReplicatedStorage.CombatRemotes`
- `server/SwordService.luau` — uchigatana + back saya Parts kit (Motor6D sheath; offsets in Config.Sword)
- `server/CombatService.luau` — Zanjutsu melee (forgiving hitbox + magnet), flash step, spirit wave, guard
- `server/DamageService.luau` — damage, guard chip, knockback/stun
- `server/SpiritPowerService.luau` — Reiatsu regen / spend / gain-on-hit / guard drain
- `server/VoidspawnService.luau` — PvE + standoff AI (no jump) + aggro/grace
- `client/AbilityHotbar.luau` — 1–9 hotbar UI (Guard on 3)
- `client/ArmAnimator.luau` — arm-driven Transform (swing/cast/flash/guard); sword passive/welded; hard cancel cleanup
- `client/SwingController.luau` — shim → ArmAnimator
- `client/SprintController.luau` — LeftShift hold sprint
- `client/CameraLock.luau` — LeftControl mouse-lock + soft assist
- `client/InputController.luau` / `SpiritUI.luau` / `CombatVFX.luau`

Tune numbers in **one place**: `src/shared/Config.luau`.

## Repo

https://github.com/anzu/roblox-rojo-starter
