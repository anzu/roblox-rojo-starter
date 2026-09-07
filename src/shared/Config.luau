-- Spirit Blade — bleach-inspired anime combat (maintainer note only).
-- All tunables live here; change and re-sync with Rojo.

local Config = {
	GameName = "Spirit Blade",

	-- Melee (M1) — basic drawn-blade sword attack, 3-hit combo
	MeleeRange = 10,
	MeleeHitboxSize = Vector3.new(8, 6, 10),
	MeleeCooldown = 0.32,
	MeleeComboMax = 3,
	MeleeDamage = { 10, 14, 22 },
	MeleeComboReset = 0.9,
	MeleeLungeSpeed = 12, -- soft nudge; swing anim carries the feel
	MeleeLungeDuration = 0.08,
	MeleeHitDelay = 0.1, -- mid-swing (~synced with Transform strike)

	-- Flash Step (hotbar 1) — short controlled dash
	FlashStepDistance = 11,
	FlashStepDuration = 0.07,
	FlashStepCooldown = 2,
	FlashStepCost = 15,
	FlashStepIFrames = 0.15,

	-- Spirit Wave (hotbar 2)
	SpiritWaveSpeed = 70,
	SpiritWaveDamage = 28,
	SpiritWaveCooldown = 5,
	SpiritWaveCost = 30,
	SpiritWaveLifetime = 2.5,
	SpiritWaveSize = Vector3.new(2.2, 2.2, 4),

	-- Spirit Power meter
	SpiritPowerMax = 100,
	SpiritPowerRegenPerSecond = 8,
	MeleeSpiritCost = 0,

	-- Voidspawn PvE
	VoidspawnCount = 2,
	VoidspawnHealth = 80,
	VoidspawnDamage = 12,
	VoidspawnWalkSpeed = 16,
	VoidspawnIdleWalkSpeed = 6,
	VoidspawnMeleeRange = 5.5,
	VoidspawnAttackCooldown = 1.25,
	VoidspawnRespawnDelay = 8,
	VoidspawnSpawnRadius = 70,
	VoidspawnThinkInterval = 0.25,
	VoidspawnAggroRadius = 22,
	VoidspawnDeaggroRadius = 35,
	VoidspawnSpawnDelay = 4,
	VoidspawnPlayerGraceSeconds = 6,

	-- Misc
	FriendlyFire = true,
	KillerTagSeconds = 4,
}

return Config
