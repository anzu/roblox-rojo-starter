-- Shared combat enums / string ids for remotes and FX.

export type AbilityId = "Melee" | "FlashStep" | "SpiritWave" | "ToggleSheath" | "Guard"
export type FxKind = "Slash" | "FlashStep" | "SpiritWave" | "Hit" | "Death" | "Deny" | "Sheath" | "Guard" | "Stun"

local CombatTypes = {
	Ability = {
		Melee = "Melee",
		FlashStep = "FlashStep",
		SpiritWave = "SpiritWave",
		ToggleSheath = "ToggleSheath",
		Guard = "Guard",
	},
	Fx = {
		Slash = "Slash",
		FlashStep = "FlashStep",
		SpiritWave = "SpiritWave",
		Hit = "Hit",
		Death = "Death",
		Deny = "Deny",
		Sheath = "Sheath",
		Guard = "Guard",
		Stun = "Stun",
	},
	Tags = {
		Voidspawn = "Voidspawn",
		SpiritProjectile = "SpiritProjectile",
		IFrames = "IFrames",
		SpiritBlade = "SpiritBlade",
		Guarding = "Guarding",
		Stunned = "Stunned",
	},
}

return CombatTypes
