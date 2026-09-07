-- Spirit Blade — bleach-inspired anime combat (maintainer note only).
-- All tunables live here; change and re-sync with Rojo.

local Config = {
	GameName = "Spirit Blade",

	-- Melee (M1) — 3-hit combo
	MeleeRange = 8,
	MeleeHitboxSize = Vector3.new(6, 5, 8),
	MeleeCooldown = 0.32,
	MeleeComboMax = 3,
	MeleeDamage = { 10, 14, 22 },
	MeleeComboReset = 0.9,
	MeleeLungeSpeed = 28,
	MeleeLungeDuration = 0.08,

	-- Flash Step (Q)
	FlashStepDistance = 28,
	FlashStepDuration = 0.12,
	FlashStepCooldown = 2,
	FlashStepCost = 20,
	FlashStepIFrames = 0.2,

	-- Spirit Wave (E)
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
	VoidspawnMeleeRange = 5.5,
	VoidspawnAttackCooldown = 1.25,
	VoidspawnRespawnDelay = 8,
	VoidspawnSpawnRadius = 28,
	VoidspawnThinkInterval = 0.25,

	-- Misc
	FriendlyFire = true,
	KillerTagSeconds = 4,
}

return Config
