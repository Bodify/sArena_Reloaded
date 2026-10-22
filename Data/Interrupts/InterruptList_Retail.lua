sArenaMixin.interruptList = {
    [1766]   = 3,     -- Kick (Rogue)
    [2139]   = 5,     -- Counterspell (Mage)
    [6552]   = 3,     -- Pummel (Warrior)
    [19647]  = 5,     -- Spell Lock (Warlock)
    [47528]  = 3,     -- Mind Freeze (Death Knight)
    [57994]  = 2,     -- Wind Shear (Shaman)
    [91802]  = 2,     -- Shambling Rush (Death Knight)
    [96231]  = 3,     -- Rebuke (Paladin)
    [106839] = 3,     -- Skull Bash (Feral)
    [93985]  = 3,     -- Skull Bash (hit)
    [115781] = 5,     -- Optical Blast (Warlock)
    [116705] = 3,     -- Spear Hand Strike (Monk)
    [132409] = 5,     -- Spell Lock (Warlock)
    [119910] = 5,     -- Spell Lock (Warlock Pet)
    [89766]  = 3,     -- Axe Toss (Warlock Pet)
    [147362] = 3,     -- Countershot (Hunter)
    [171138] = 5,     -- Shadow Lock (Warlock)
    [183752] = 3,     -- Consume Magic (Demon Hunter)
    [187707] = 3,     -- Muzzle (Hunter)
    [212619] = 5,     -- Call Felhunter (Warlock)
    [231665] = 3,     -- Avengers Shield (Paladin)
    [351338] = 4,     -- Quell (Evoker)
    [97547]  = 5,     -- Solar Beam
    [78675]  = 5,     -- Solar Beam
    [15487]  = 4,     -- Silence (Not an interrupt, but used for interrupt color. Irrelevant on Retail for now)
}

-- Interrupt per spec. false = no interrupt.
sArenaMixin.specInterrupts = {
    -- Death Knight: Blood, Frost, Unholy
    [250] = 47528, [251] = 47528, [252] = 47528,
    -- Demon Hunter: Havoc, Vengeance, Devourer
    [577] = 183752, [581] = 183752, [1480] = 183752,
    -- Druid: Balance, Feral, Guardian, Restoration
    [102] = 78675, [103] = 106839, [104] = 106839, [105] = false,
    -- Evoker: Devastation, Preservation, Augmentation
    [1467] = 351338, [1468] = false, [1473] = false,
    -- Hunter: Beast Mastery, Marksmanship, Survival
    [253] = 147362, [254] = 147362, [255] = 187707,
    -- Mage: Arcane, Fire, Frost
    [62] = 2139, [63] = 2139, [64] = 2139,
    -- Monk: Brewmaster, Mistweaver, Windwalker
    [268] = 116705, [270] = false, [269] = 116705,
    -- Paladin: Holy, Protection, Retribution
    [65] = false, [66] = 96231, [70] = 96231,
    -- -- Priest: Discipline, Holy, Shadow
    -- [256] = false, [257] = false, [258] = false,
    -- Rogue: Assassination, Outlaw, Subtlety
    [259] = 1766, [260] = 1766, [261] = 1766,
    -- Shaman: Elemental, Enhancement, Restoration
    [262] = 57994, [263] = 57994, [264] = 57994,
    -- Warlock: Affliction, Demonology, Destruction
    [265] = 132409, [266] = 132409, [267] = 132409,
    -- Warrior: Arms, Fury, Protection
    [71] = 6552, [72] = 6552, [73] = 6552,
}

sArenaMixin.meleeInterrupts = {
    [1766]   = true, -- Kick
    [6552]   = true, -- Pummel
    [47528]  = true, -- Mind Freeze
    [96231]  = true, -- Rebuke
    [106839] = true, -- Skull Bash
    [116705] = true, -- Spear Hand Strike
    [183752] = true, -- Disrupt
    [187707] = true, -- Muzzle
}

-- Fallback if spec not found
sArenaMixin.classInterrupts = {
    DEATHKNIGHT = 47528,
    DEMONHUNTER = 183752,
    DRUID       = 106839,
    EVOKER      = 351338,
    HUNTER      = 147362,
    MAGE        = 2139,
    MONK        = 116705,
    PALADIN     = 96231,
    ROGUE       = 1766,
    SHAMAN      = 57994,
    WARLOCK     = 132409,
    WARRIOR     = 6552,
}
