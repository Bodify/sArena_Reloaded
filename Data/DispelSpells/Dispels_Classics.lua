local GetSpellName = C_Spell.GetSpellName
local GetSpellTexture = C_Spell.GetSpellTexture

sArenaMixin.dispelData = {
	[527] = { texture = GetSpellTexture(527), name = GetSpellName(527) or "Purify", classes = "DispelClass_Priest", cooldown = 8, healer = true },
	[4987] = { texture = GetSpellTexture(4987), name = GetSpellName(4987) or "Cleanse", classes = "DispelClass_HolyPaladin", cooldown = 8, sharedSpecSpellID = true },
	[77130] = { texture = GetSpellTexture(77130), name = GetSpellName(77130) or "Purify Spirit", classes = "DispelClass_RestoShaman", cooldown = 8, healer = true },
	[51886] = { texture = GetSpellTexture(51886), name = GetSpellName(51886) or "Cleanse Spirit", classes = "DispelClass_EnhEleShaman", cooldown = 8, showAfterUse = true },
	[88423] = { texture = GetSpellTexture(88423), name = GetSpellName(88423) or "Nature's Cure", classes = "DispelClass_RestoDruid", cooldown = 8, healer = true },
	[2782] = { texture = GetSpellTexture(2782), name = GetSpellName(2782) or "Remove Corruption", classes = "DispelClass_Druid", cooldown = 8, showAfterUse = true },
	[475] = { texture = GetSpellTexture(475), name = GetSpellName(475) or "Remove Curse", classes = "DispelClass_Mage", cooldown = 8, showAfterUse = true },
	[115450] = { texture = GetSpellTexture(115450), name = GetSpellName(115450) or "Detox", classes = "DispelClass_Monk", cooldown = 8, sharedSpecSpellID = true },
	[103150] = { texture = GetSpellTexture(103150), name = GetSpellName(103150) or "Singe Magic", classes = "DispelClass_WarlockPet", cooldown = 10, showAfterUse = true },
	[132411] = { texture = GetSpellTexture(132411), name = GetSpellName(132411) or "Singe Magic", classes = "DispelClass_WarlockGrimoire", cooldown = 10, showAfterUse = true },
	[32375] = { texture = GetSpellTexture(32375), name = GetSpellName(32375) or "Mass Dispel", classes = "DispelClass_ShadowPriest", cooldown = 15, showAfterUse = true },
}

sArenaMixin.specToDispel = {
	-- Druid
	[102] = 2782, -- Balance -> Remove Corruption
	[103] = 2782, -- Feral -> Remove Corruption
	[104] = 2782, -- Guardian -> Remove Corruption
	[105] = 88423, -- Restoration -> Nature's Cure

	-- Hunter
	[255] = 212640, -- Survival -> Mending Bandage

	-- Mage
	[62] = 475, -- Arcane -> Remove Curse
	[63] = 475, -- Fire -> Remove Curse
	[64] = 475, -- Frost -> Remove Curse

	-- Monk
	[268] = 115450, -- Brewmaster -> Detox
	[269] = 115450, -- Windwalker -> Detox
	[270] = 115450, -- Mistweaver -> Detox

	-- Paladin
	[65] = 4987, -- Holy -> Cleanse
	[66] = 4987, -- Protection -> Cleanse
	[70] = 4987, -- Retribution -> Cleanse

	-- Priest
	[256] = 527, -- Discipline -> Purify
	[257] = 527, -- Holy -> Purify
	[258] = 32375, -- Shadow -> Mass Dispel

	-- Shaman
	[262] = 51886, -- Elemental -> Cleanse Spirit
	[263] = 51886, -- Enhancement -> Cleanse Spirit
	[264] = 77130, -- Restoration -> Purify Spirit

	-- Warlock (both pet and grimoire variants)
	[265] = { 103150, 132411 }, -- Affliction -> Singe Magic (both pet and grimoire)
	[266] = { 103150, 132411 }, -- Demonology -> Singe Magic (both pet and grimoire)
	[267] = { 103150, 132411 }, -- Destruction -> Singe Magic (both pet and grimoire)
}

-- Default dispel categories for MoP  
sArenaMixin.defaultSettings.profile.dispelCategories = {
	-- Healer spells (enabled by default)
	[77130] = true,   -- Purify Spirit (Resto Shaman)
	[88423] = true,   -- Nature's Cure (Resto Druid)
	[527] = true,   -- Purify (Priest healers)

	-- Shared spells - healer variants (enabled by default)
	["4987_healer"] = true,    -- Cleanse (Holy Paladin)
	["115450_healer"] = true,  -- Detox (Mistweaver)
}
