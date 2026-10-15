local GetSpellName = C_Spell.GetSpellName
local GetSpellTexture = C_Spell.GetSpellTexture

sArenaMixin.dispelData = {
	[527] = { texture = GetSpellTexture(527), name = GetSpellName(527) or "Purify", classes = "DispelClass_DiscHolyPriest", cooldown = 8, healer = true },
	[213634] = { texture = GetSpellTexture(213634), name = GetSpellName(213634) or "Purify Disease", classes = "DispelClass_ShadowPriest", cooldown = 8, showAfterUse = true },
	[4987] = { texture = GetSpellTexture(4987), name = GetSpellName(4987) or "Cleanse", classes = "DispelClass_HolyPaladin", cooldown = 8, healer = true },
	[213644] = { texture = GetSpellTexture(213644), name = GetSpellName(213644) or "Cleanse Toxins", classes = "DispelClass_ProtRetPaladin", cooldown = 8, showAfterUse = true },
	[77130] = { texture = GetSpellTexture(77130), name = GetSpellName(77130) or "Purify Spirit", classes = "DispelClass_RestoShaman", cooldown = 8, healer = true },
	[51886] = { texture = GetSpellTexture(51886), name = GetSpellName(51886) or "Cleanse Spirit", classes = "DispelClass_EnhEleShaman", cooldown = 8, showAfterUse = true },
	[88423] = { texture = GetSpellTexture(88423), name = GetSpellName(88423) or "Nature's Cure", classes = "DispelClass_RestoDruid", cooldown = 8, healer = true },
	[2782] = { texture = GetSpellTexture(2782), name = GetSpellName(2782) or "Remove Corruption", classes = "DispelClass_BalFeralGuardianDruid", cooldown = 8, showAfterUse = true },
	[475] = { texture = GetSpellTexture(475), name = GetSpellName(475) or "Remove Curse", classes = "DispelClass_Mage", cooldown = 8, showAfterUse = true },
	[218164] = { texture = GetSpellTexture(218164), name = GetSpellName(218164) or "Detox", classes = "DispelClass_Monk", cooldown = 8, showAfterUse = true },
	[115450] = { texture = GetSpellTexture(115450), name = GetSpellName(115450) or "Detox", classes = "DispelClass_MistweaverMonk", cooldown = 8, healer = true },
	[360823] = { texture = GetSpellTexture(360823), name = GetSpellName(360823) or "Naturalize", classes = "DispelClass_Evoker", cooldown = 8, healer = true },
	[374251] = { texture = GetSpellTexture(374251), name = GetSpellName(374251) or "Cauterizing Flame", classes = "DispelClass_DevEvoker", cooldown = 60, showAfterUse = true },
	[119905] = { texture = GetSpellTexture(119905), name = GetSpellName(119905) or "Singe Magic", classes = "DispelClass_WarlockPet", cooldown = 15, showAfterUse = true },
	[132411] = { texture = GetSpellTexture(132411), name = GetSpellName(132411) or "Singe Magic", classes = "DispelClass_WarlockGrimoire", cooldown = 15, showAfterUse = true },
	[212640] = { texture = GetSpellTexture(212640), name = GetSpellName(212640) or "Mending Bandage", classes = "DispelClass_SurvivalHunter", cooldown = 25, showAfterUse = true },
}

sArenaMixin.specToDispel = {
	-- Druid
	[102] = 2782,   -- Balance -> Remove Corruption
	[103] = 2782,   -- Feral -> Remove Corruption  
	[104] = 2782,   -- Guardian -> Remove Corruption
	[105] = 88423,  -- Restoration -> Nature's Cure

	-- Evoker
	[1467] = 374251, -- Devastation -> Cauterizing Flame
	[1468] = 360823, -- Preservation -> Naturalize

	-- Hunter
	[255] = 212640,  -- Survival -> Mending Bandage

	-- Mage
	[62] = 475,     -- Arcane -> Remove Curse
	[63] = 475,     -- Fire -> Remove Curse
	[64] = 475,     -- Frost -> Remove Curse

	-- Monk
	[268] = 218164, -- Brewmaster -> Detox
	[269] = 218164, -- Windwalker -> Detox
	[270] = 115450, -- Mistweaver -> Detox

	-- Paladin
	[65] = 4987,    -- Holy -> Cleanse
	[66] = 213644,  -- Protection -> Cleanse Toxins
	[70] = 213644,  -- Retribution -> Cleanse Toxins

	-- Priest
	[256] = 527,    -- Discipline -> Purify
	[257] = 527,    -- Holy -> Purify
	[258] = 213634, -- Shadow -> Purify Disease

	-- Shaman
	[262] = 51886,  -- Elemental -> Cleanse Spirit
	[263] = 51886,  -- Enhancement -> Cleanse Spirit
	[264] = 77130,  -- Restoration -> Purify Spirit

	-- Warlock (both pet and grimoire variants)
	[265] = {119905, 132411}, -- Affliction -> Singe Magic (both pet and grimoire)
	[266] = {119905, 132411}, -- Demonology -> Singe Magic (both pet and grimoire)
	[267] = {119905, 132411}, -- Destruction -> Singe Magic (both pet and grimoire)
}

-- Default dispel categories for retail
sArenaMixin.defaultSettings.profile.dispelCategories = {
	[527] = true,     -- Purify (Priest - Discipline/Holy)
	[4987] = true,    -- Cleanse (Holy Paladin)
	[77130] = true,   -- Purify Spirit (Resto Shaman)
	[88423] = true,   -- Nature's Cure (Resto Druid)
	[115450] = true,  -- Detox (Mistweaver Monk)
	[360823] = true,  -- Naturalize (Preservation Evoker)
}
