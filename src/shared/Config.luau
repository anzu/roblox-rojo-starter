-- Spirit Blade — bleach-inspired anime combat (maintainer note only).
-- All tunables live here; change and re-sync with Rojo.

local Config = {
	GameName = "Spirit Blade",

	-- Zanjutsu / Melee (M1) — 3-hit combo
	MeleeRange = 12,
	MeleeHitboxSize = Vector3.new(10, 7, 12),
	MeleeCooldown = 0.38,
	MeleeComboMax = 3,
	MeleeDamage = { 10, 14, 22 },
	MeleeComboReset = 1.0,
	MeleeLungeSpeed = 10,
	MeleeLungeDuration = 0.08,
	MeleeHitDelay = 0.22, -- mid-late slash (~synced with arm strike)
	MeleeConeAngleDeg = 70, -- forward cone for magnet / forgiving hits
	MeleeMagnetRange = 10, -- Voidspawn inside cone within this range still count
	MeleeFinisherKnockback = 28, -- hit 3 knockback speed
	MeleeFinisherStunSeconds = 0.65,

	-- Swing timing (client arm Transform) — must stay coherent with MeleeHitDelay
	SwingTotal = 0.50,
	SwingWindupEnd = 0.12,
	SwingStrikeEnd = 0.32,

	-- Sprint (LeftShift hold)
	WalkSpeedDefault = 16,
	SprintWalkSpeed = 28,
	SprintFovBoost = 8, -- optional FOV bump while sprinting
	SprintSpiritDrainPerSecond = 0, -- free for foundation; set >0 to tax Spirit

	-- Camera lock (LeftControl toggle)
	CameraLockSoftAssist = true,
	CameraLockSoftRange = 40,
	CameraLockSoftConeDeg = 55,
	CameraLockSoftYawStrength = 0.12, -- blend per frame toward target yaw (subtle)

	-- Flash Step (hotbar 1)
	FlashStepDistance = 11,
	FlashStepDuration = 0.07,
	FlashStepCooldown = 2,
	FlashStepCost = 15,
	FlashStepIFrames = 0.15,
	FlashStepCancelSwingAfter = 0.28, -- cancel late-swing recovery if Flash Step after this elapsed

	-- Spirit Wave (hotbar 2)
	SpiritWaveSpeed = 70,
	SpiritWaveDamage = 28,
	SpiritWaveCooldown = 5,
	SpiritWaveCost = 30,
	SpiritWaveLifetime = 2.5,
	SpiritWaveSize = Vector3.new(2.2, 2.2, 4),

	-- Spirit Guard (hold F / hotbar 3)
	GuardDamageMult = 0.25, -- frontal melee chip when blocking
	GuardSpiritDrainPerSecond = 6,
	GuardSpiritCostOnBlock = 4,
	GuardMinSpirit = 1, -- drop guard if Spirit below this

	-- Reiatsu / Spirit Power meter
	SpiritPowerMax = 100,
	SpiritPowerRegenPerSecond = 8,
	MeleeSpiritCost = 0,
	MeleeSpiritGainOnHit = 4, -- gain small Spirit on successful melee hit

	-- Voidspawn PvE
	VoidspawnCount = 2,
	VoidspawnHealth = 80,
	VoidspawnDamage = 12,
	VoidspawnWalkSpeed = 16,
	VoidspawnIdleWalkSpeed = 6,
	VoidspawnMeleeRange = 5.5,
	VoidspawnStandoff = 5.5, -- stop this far from player (melee ring)
	VoidspawnTooClose = 3, -- back up / strafe inside this
	VoidspawnAttackCooldown = 1.25,
	VoidspawnRespawnDelay = 8,
	VoidspawnSpawnRadius = 70,
	VoidspawnThinkInterval = 0.25,
	VoidspawnAggroRadius = 22,
	VoidspawnDeaggroRadius = 35,
	VoidspawnSpawnDelay = 4,
	VoidspawnPlayerGraceSeconds = 6,
	VoidspawnFacingDot = 0.35, -- must roughly face player to attack

	-- Misc
	FriendlyFire = true,
	KillerTagSeconds = 4,
}

return Config
