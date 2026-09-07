-- Shared combat enums / string ids for remotes and FX.

export type AbilityId = "Melee" | "FlashStep" | "SpiritWave" | "ToggleSheath"
export type FxKind = "Slash" | "FlashStep" | "SpiritWave" | "Hit" | "Death" | "Deny" | "Sheath"

local CombatTypes = {
	Ability = {
		Melee = "Melee",
		FlashStep = "FlashStep",
		SpiritWave = "SpiritWave",
		ToggleSheath = "ToggleSheath",
	},
	Fx = {
		Slash = "Slash",
		FlashStep = "FlashStep",
		SpiritWave = "SpiritWave",
		Hit = "Hit",
		Death = "Death",
		Deny = "Deny",
		Sheath = "Sheath",
	},
	Tags = {
		Voidspawn = "Voidspawn",
		SpiritProjectile = "SpiritProjectile",
		IFrames = "IFrames",
		SpiritBlade = "SpiritBlade",
	},
}

return CombatTypes
