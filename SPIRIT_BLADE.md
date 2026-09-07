# Spirit Blade — Game & Contributor Brief

**Purpose:** Single source of truth so **Chief of Staff (Grok Bot)**, **ChatGPT Astra**, and Andrew can build the same Roblox game without drifting. Paste this whole file into Astra when starting a session; keep it updated when systems change.

| | |
|---|---|
| **Working title** | Spirit Blade |
| **Repo** | https://github.com/anzu/roblox-rojo-starter (public) |
| **Owner** | Andrew Nguyen (`anzu` on GitHub) |
| **Engine** | Roblox + Luau |
| **Sync** | Rojo 7.7.x (`aftman.toml`) → Studio plugin Connect `localhost:34872` |
| **Local path (Andrew Mac)** | `~/roblox-rojo-starter` |
| **Inspiration** | Bleach-style anime sword combat (PvE + PvP) |
| **Status (2026-09-07)** | Playable combat sandbox foundation; iterating feel (arm anims, AI, hitboxes) |

---

## 1. Vision

Build a **Bleach-inspired** Roblox experience: fluid sword combat (Zanjutsu feel), mobility (Flash Step), spirit projectiles, reiatsu management, PvE Voidspawn, and later PvP arenas / progression.

**North star feel:** You move the **body/arm**; the **katana rides the hand**. Abilities have readable windup/recovery. Enemies fight at a standoff, not on your head. Desktop combat uses sprint + camera lock.

**Not yet:** full map, classes, gacha, bankai clones, story campaign, monetization.

---

## 2. IP / naming rules (non-negotiable)

Public Roblox cannot ship official Bleach IP (names, logos, exact characters, trademarked attacks).

| Use (original) | Avoid in UI / product copy |
|----------------|----------------------------|
| Spirit Blade (game name) | “Bleach” as title |
| Spirit Reaper vibe (flavor only) | Ichigo, Rukia, Aizen, etc. |
| Voidspawn | Hollow (as product name) |
| Flash Step | exclusive trademarked move names as feature titles |
| Spirit Wave / Spirit Guard / Spirit Power (Reiatsu meter) | Getsuga, Bankai, Zanpakutō as product strings |
| Zanjutsu (generic swordsmanship label OK in design docs; keep light in UI) | Soul Society, Quincy, etc. as branded systems |

Code comments may say `bleach-inspired` once for maintainers. Player-facing strings stay original.

---

## 3. How we work together (CoS + Astra + Andrew)

### Roles
- **Andrew:** Product taste, Playtests in Studio, `git pull` + Rojo Connect, final say.
- **Chief of Staff (Grok):** Default coordinator; can edit repo, push `main`, run routines, translate playtest → tasks.
- **Astra (ChatGPT):** Contributor — implement features/fixes from this brief + Andrew’s notes; prefer PRs or clear commits on `main` if Andrew grants push.

### Workflow every change
1. Read this file + `README.md` + `src/shared/Config.luau`.
2. Implement in Luau under `src/` (Rojo layout).
3. Commit with a clear message; push `origin/main` (or open a PR if collaborating in parallel — **don’t silently overwrite** each other’s in-flight WIP; pull first).
4. Tell Andrew: `git pull` → Stop → Play (leave `rojo serve` + Connect up).
5. Update **§8 Current state** and **§9 Backlog** in this file when behavior/controls change.

### Hard rules
- **Server-authoritative** damage, Spirit spend, sheath state, AI.
- Tunables only in `src/shared/Config.luau` unless impossible.
- **Arm-driven animation:** animate `RightShoulder` / `RightElbow` / `RightWrist` via `Motor6D.Transform` on `RunService.Stepped`. **Do not** animate the blade Motor6D as the swing — sword stays welded to the hand.
- Always **reset Transforms to identity** and disconnect Stepped on cancel/end/`CharacterRemoving` (stuck-walk bug class).
- **Shift = sprint.** **Ctrl = camera lock.** Do not rebind Shift to mouse-lock.
- No Cloud/Agent spend on Andrew’s Replit for this project; this is GitHub + Studio.

### Rojo / Mac session (Andrew)
```bash
cd ~/roblox-rojo-starter
git pull
# Terminal A:
rojo serve
# Studio: Plugins → Rojo → Connect
# Terminal B after each push:
git pull
```
Rojo **7.7.0** CLI must match Studio plugin (`rojo plugin install` after upgrades).

---

## 4. Controls (current)

| Input | Action |
|-------|--------|
| **E** | Sheath / unsheath katana (saya stays on back) |
| **M1** / tap | Sword attack — 3-hit combo; auto-unsheath; arm-driven slash |
| **Shift** (hold) | Sprint (~16 → ~28 WalkSpeed) |
| **Ctrl** | Toggle camera lock (LockCenter + face camera; soft assist to Voidspawn) |
| **F** / hotbar **3** (hold) | Spirit Guard — frontal block (chip + Spirit drain) |
| **1** / hotbar 1 | Flash Step — short dash; can cancel late swing recovery |
| **2** / hotbar 2 | Spirit Wave — ranged spirit projectile |
| **4–9** | Locked |

---

## 5. Architecture

```
src/shared/     → ReplicatedStorage.Shared
  Config.luau         All tunables
  Remotes.luau        CombatRemotes folder
  CombatTypes.luau    Ability / FX / tag ids

src/server/     → ServerScriptService.Server
  init.server.luau
  SwordService.luau       Katana + saya Motor6D
  CombatService.luau      Melee / flash / wave / guard hooks
  DamageService.luau      Damage, chip, knockback, stun
  SpiritPowerService.luau Reiatsu regen / spend / on-hit gain
  VoidspawnService.luau   PvE spawn + standoff AI

src/client/     → StarterPlayerScripts.Client
  init.client.luau
  ArmAnimator.luau        Arm-chain Transform swings / cast / flash / guard
  SwingController.luau    Shim → ArmAnimator
  InputController.luau
  AbilityHotbar.luau
  SprintController.luau
  CameraLock.luau
  SpiritUI.luau
  CombatVFX.luau
```

`default.project.json` maps the tree; StarterPlayer enables mouse-lock options but **custom** Ctrl lock is the combat path (built-in Shift mouse-lock disabled to free Shift for sprint).

---

## 6. Combat foundation (designed loop)

1. **Zanjutsu (M1)** — 3-hit arm slash; hit 3 = knockback + short stun on Voidspawn.
2. **Reiatsu (Spirit Power)** — regen; **gain on melee hit**; spend on Flash Step / Spirit Wave / Guard.
3. **Flash Step (1)** — short reposition; late-swing cancel.
4. **Spirit Wave (2)** — projectile; cast arm pose.
5. **Spirit Guard (F/3)** — hold block frontal melee.
6. **Sprint (Shift)** + **Camera lock (Ctrl)** — desktop fight readability.
7. **Voidspawn PvE** — aggro radius, player grace on spawn, **ground standoff** (no head-pile, JumpPower 0).

PvP: friendly fire currently **on** (sandbox). Expect a party/FFA mode flag later.

---

## 7. Animation contract (read this before touching combat feel)

**Problem we already hit:** Floating slash parts and blade-only Motor tweens look fake; Animator overwrites `C0` tweens.

**Contract:**
- Drive **arm** `Motor6D.Transform` every `Stepped` for the duration of the move.
- Keep **BladeMotor** at identity grip — sword follows hand.
- Large, readable joint deltas (shoulder + elbow + wrist).
- Same pattern for cast / flash tuck / guard hold.
- Hard cleanup → no stuck walk / frozen AutoRotate (camera lock alone may set AutoRotate false **only while locked**).

Future upgrade path: upload real R15 `Animation` assets to Roblox and load via `Animator` (Action priority). Until then, Transform arm-chain is the SoT.

---

## 8. Current state (as of 2026-09-07, tip `178f564`)

### Working
- Rojo sync project; Spirit Blade bootstrap
- Metal katana + back saya; E draw/sheath
- Hotbar 1–9 (1–3 live)
- ArmAnimator full-arm swings + Wave/Flash/Guard poses
- Sprint Shift / Ctrl lock / soft assist
- Spirit Power meter + on-hit gain
- Voidspawn standoff AI + grace/aggro
- Forgiving melee hit window + cone magnet

### Known soft spots / playtest themes
- Animation still iterating toward “real slash” feel (may need Animation assets next)
- Hit registration vs mobile Voidspawn still taste-sensitive
- No real map / spawn lobby / class select
- No progression, inventory, or data stores yet
- PvP is sandbox FF only

---

## 9. Backlog (prioritized)

### P0 — Feel
- [ ] Further polish arm arcs / timing to match hit frames
- [ ] Optional: real uploaded slash Animations (R15) replacing Transform for M1
- [ ] Lock target (hard lock-on) toggle for PvE

### P1 — Bleach-inspired systems (original names)
- [ ] Spiritual pressure / intimidation (slow weak Voidspawn in radius when Spirit high)
- [ ] Posture / chip break on Guard
- [ ] Ability slots 4–6: e.g. rising slash, AOE spirit burst, counter flash
- [ ] Voidspawn archetypes (rusher / ranged / big)
- [ ] Simple arena map + spawn pads

### P2 — Meta
- [ ] DataStore: unlocks, cosmetics (non-IP)
- [ ] Parties / FF off for co-op PvE
- [ ] Ranked PvP duel mode
- [ ] Mobile parity for sprint/lock

### Explicitly later (Andrew-gated)
- Unique “signature” moves per playstyle
- Progression seasons / monetization

---

## 10. Playtest checklist (paste results back)

```bash
cd ~/roblox-rojo-starter && git pull
# rojo serve + Connect → Play
```

1. Walk + M1 — arm swings, sword glued to hand, **no stuck walk**
2. Shift sprint · Ctrl lock/unlock
3. M1×3 — third hit stuns/knocks Voidspawn
4. Voidspawn stay at melee ring — **not on head**
5. F/3 Guard pose + chip
6. 1 Flash (arm tuck) · 2 Wave (cast arm)

---

## 11. Message templates

**Andrew → Astra (start session):**  
> Here’s `SPIRIT_BLADE.md`. Repo `anzu/roblox-rojo-starter`. Pull latest `main`, follow §3 and §7. Task: \<one concrete task\>. Push and tell me to `git pull`.

**Contributor → Andrew (done):**  
> Pushed `\<sha\>`. Change: \<one line\>. Pull + Play. Verify: \<2–3 bullets\>.

**Handoff CoS ↔ Astra:**  
> Update §8/§9 in `SPIRIT_BLADE.md` in the same commit as behavior changes.

---

## 12. Reference links

- Repo: https://github.com/anzu/roblox-rojo-starter  
- Rojo: https://rojo.space  
- Player README (session ops): `README.md` in repo root  
- This brief: `SPIRIT_BLADE.md` (keep in sync)

---

*Last updated: 2026-09-07 — arm-driven ArmAnimator (`178f564`). Maintainers: Andrew, Chief of Staff, Astra.*
