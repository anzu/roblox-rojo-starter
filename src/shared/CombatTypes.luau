-- Shared combat enums / string ids for remotes and FX.

export type AbilityId = "Melee" | "FlashStep" | "SpiritWave"
export type FxKind = "Slash" | "FlashStep" | "SpiritWave" | "Hit" | "Death"

local CombatTypes = {
	Ability = {
		Melee = "Melee",
		FlashStep = "FlashStep",
		SpiritWave = "SpiritWave",
	},
	Fx = {
		Slash = "Slash",
		FlashStep = "FlashStep",
		SpiritWave = "SpiritWave",
		Hit = "Hit",
		Death = "Death",
	},
	Tags = {
		Voidspawn = "Voidspawn",
		SpiritProjectile = "SpiritProjectile",
		IFrames = "IFrames",
	},
}

return CombatTypes
