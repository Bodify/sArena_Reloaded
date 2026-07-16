-- Auras we want tooltip info from to display as stacks
sArenaMixin.tooltipInfoAuras = {
}

-- Auras reducing interrupt durations
sArenaMixin.spellLockReducer = {
}

-- Stance auras for TBC (stances don't have real auras, only cast/aura events)
sArenaMixin.stanceAuras = {
    [71]   = 0, -- Defensive Stance
    [2458] = 0, -- Berserker Stance
    [2457] = 0, -- Battle Stance
}

-- Active stance auras per unit: [unit] = spellID (e.g. ["arena1"] = 71)
sArenaMixin.activeStanceAuras = {}

sArenaMixin.auraList = {
    -- Special
    [23920]   = {10, "important"},    -- Spell Reflection
    [8178]    = {10, "important"},    -- Grounding Totem Effect

    -- Full CC (Stuns and Disorients)
    [33786]   = {9, "cc"},    -- Cyclone (Disorient)
    [5211]    = {9, "cc"},    -- Bash
    [6798]    = {9, "cc"},    -- Bash
    [8983]    = {9, "cc"},    -- Bash
    [6789]    = {9, "cc"},    -- Death Coil
    [17925]   = {9, "cc"},    -- Death Coil
    [17926]   = {9, "cc"},    -- Death Coil
    [27223]   = {9, "cc"},    -- Death Coil
    [1833]    = {9, "cc"},    -- Cheap Shot
    [7922]    = {9, "cc"},    -- Charge Stun
    [853]     = {9, "cc"},    -- Hammer of Justice
    [5588]    = {9, "cc"},    -- Hammer of Justice
    [5589]    = {9, "cc"},    -- Hammer of Justice
    [10308]   = {9, "cc"},    -- Hammer of Justice
    [30153]   = {9, "cc"},    -- Pursuit
    [24394]   = {9, "cc"},    -- Intimidation
    [19577]   = {9, "cc"},    -- Intimidation
    [408]     = {9, "cc"},    -- Kidney Shot
    [8643]    = {9, "cc"},    -- Kidney Shot
    [22570]   = {9, "cc"},    -- Maim
    [9005]    = {9, "cc"},    -- Pounce
    [9823]    = {9, "cc"},    -- Pounce
    [9827]    = {9, "cc"},    -- Pounce
    [27006]   = {9, "cc"},    -- Pounce
    [6572]    = {9, "cc"},    -- Ravage
    [30283]   = {9, "cc"},    -- Shadowfury
    [30413]   = {9, "cc"},    -- Shadowfury
    [30414]   = {9, "cc"},    -- Shadowfury
    [20549]   = {9, "cc"},    -- War Stomp
    [99]      = {9, "cc"},    -- Disorienting Roar
    [22703]   = {9, "cc"},    -- Inferno Effect
    [20511]   = {9, "cc"},    -- Intimidating Shout (secondary)
    [15618]   = {9, "cc"},    -- Snap Kick
    [12809]   = {9, "cc"},    -- Concussion Blow
    [20253]   = {9, "cc"},    -- Intercept Stun (Rank 1)
    [20614]   = {9, "cc"},    -- Intercept Stun (Rank 2)
    [20615]   = {9, "cc"},    -- Intercept Stun (Rank 3)
    [25273]   = {9, "cc"},    -- Intercept Stun (Rank 4)
    [13237]   = {9, "cc"},    -- Goblin Mortar (Item)
    [835]     = {9, "cc"},    -- Tidal Charm (Item)

    -- Stun Procs
    [34510]   = {9, "cc"},    -- Stun (various procs)
    [5530]    = {9, "cc"},    -- Mace Stun Effect
    [15269]   = {9, "cc"},    -- Blackout Stun
    [16922]   = {9, "cc"},    -- Imp Starfire Stun
    [11103]   = {9, "cc"},    -- Impact
    [12355]   = {9, "cc"},    -- Impact
    [12357]   = {9, "cc"},    -- Impact
    [12358]   = {9, "cc"},    -- Impact
    [12359]   = {9, "cc"},    -- Impact
    [12360]   = {9, "cc"},    -- Impact
    [23454]   = {9, "cc"},    -- Stun
    [19410]   = {9, "cc"},    -- Improved Concussive Shot
    [20170]   = {9, "cc"},    -- Seal of Justice Stun
    [18093]   = {9, "cc"},    -- Pyroclasm
    [39796]   = {9, "cc"},    -- Stoneclaw Stun
    [12798]   = {9, "cc"},    -- Revenge Stun

    -- Disorient / Incapacitate / Fear / Charm
    [2094]    = {9, "cc"},    -- Blind
    [31661]   = {9, "cc"},    -- Dragon's Breath
    [33041]   = {9, "cc"},    -- Dragon's Breath
    [33042]   = {9, "cc"},    -- Dragon's Breath
    [33043]   = {9, "cc"},    -- Dragon's Breath
    [5782]    = {9, "cc"},    -- Fear
    [6213]    = {9, "cc"},    -- Fear
    [6215]    = {9, "cc"},    -- Fear
    [3355]    = {9, "cc"},    -- Freezing Trap
    [14309]   = {9, "cc"},    -- Freezing Trap Effect
    [1776]    = {9, "cc"},    -- Gouge
    [1777]    = {9, "cc"},    -- Gouge
    [8629]    = {9, "cc"},    -- Gouge
    [11285]   = {9, "cc"},    -- Gouge
    [11286]   = {9, "cc"},    -- Gouge
    [38764]   = {9, "cc"},    -- Gouge
    [2637]    = {9, "cc"},    -- Hibernate
    [18657]   = {9, "cc"},    -- Hibernate
    [18658]   = {9, "cc"},    -- Hibernate
    [5484]    = {9, "cc"},    -- Howl of Terror
    [17928]   = {9, "cc"},    -- Howl of Terror
    [5246]    = {9, "cc"},    -- Intimidating Shout
    [25274]   = {9, "cc"},    -- Intercept Stun
    [605]     = {9, "cc"},    -- Mind Control
    [10911]   = {9, "cc"},    -- Mind Control
    [10912]   = {9, "cc"},    -- Mind Control
    [118]     = {9, "cc"},    -- Polymorph
    [12824]   = {9, "cc"},    -- Polymorph
    [12825]   = {9, "cc"},    -- Polymorph
    [12826]   = {9, "cc"},    -- Polymorph
    [28271]   = {9, "cc"},    -- Polymorph: Turtle
    [28272]   = {9, "cc"},    -- Polymorph: Pig
    [8122]    = {9, "cc"},    -- Psychic Scream
    [8124]    = {9, "cc"},    -- Psychic Scream
    [10888]   = {9, "cc"},    -- Psychic Scream
    [10890]   = {9, "cc"},    -- Psychic Scream
    [20066]   = {9, "cc"},    -- Repentance
    [2070]    = {9, "cc"},    -- Sap
    [6770]    = {9, "cc"},    -- Sap
    [11297]   = {9, "cc"},    -- Sap
    [1513]    = {9, "cc"},    -- Scare Beast
    [14326]   = {9, "cc"},    -- Scare Beast
    [14327]   = {9, "cc"},    -- Scare Beast
    [19503]   = {9, "cc"},    -- Scatter Shot
    [6358]    = {9, "cc"},    -- Seduction
    [20407]   = {9, "cc"},    -- Seduction
    [30850]   = {9, "cc"},    -- Seduction
    [9484]    = {9, "cc"},    -- Shackle Undead
    [1090]    = {9, "cc"},    -- Sleep
    [10326]   = {9, "cc"},    -- Turn Evil
    [19386]   = {9, "cc"},    -- Wyvern Sting
    [24132]   = {9, "cc"},    -- Wyvern Sting
    [24135]   = {9, "cc"},    -- Wyvern Sting
    [27068]   = {9, "cc"},    -- Wyvern Sting
    [710]     = {9, "cc"},    -- Banish
    [18647]   = {9, "cc"},    -- Banish

    -- Immunities
    [19263]   = {7, "defensive"},      -- Deterrence
    [642]     = {7, "defensive"},      -- Divine Shield
    [1020]    = {7, "defensive"},      -- Divine Shield
    [498]     = {7, "defensive"},      -- Divine Protection
    [45438]   = {7, "defensive"},      -- Ice Block
    [34692]   = {7, "defensive"},      -- The Beast Within
    [26064]   = {7, "defensive"},      -- Shell Shield
    [19574]   = {7, "defensive"},      -- Bestial Wrath
    [1022]    = {7, "defensive"},      -- Hand of Protection
    [5599]    = {7, "defensive"},      -- Blessing of Protection
    [10278]   = {7, "defensive"},      -- Blessing of Protection
    [3169]    = {7, "defensive"},      -- Invulnerability
    [20230]   = {7, "defensive"},      -- Retaliation
    [16621]   = {7, "defensive"},      -- Self Invulnerability
    [20594]   = {7, "defensive"},      -- Stoneform -- FIX
    [31224]   = {7, "defensive"},      -- Cloak of Shadows
    [27827]   = {7, "defensive"},      -- Spirit of Redemption

    [12043]   = {6.6, "important"},    -- Presence of Mind
    [16188]   = {6.6, "important"},    -- Nature's Swiftness

    -- Anti-CCs
    [6940]    = {6.5, "defensive"},    -- Hand of Sacrifice
    [20729]   = {6.5, "defensive"},    -- Blessing of Sacrifice
    [27147]   = {6.5, "defensive"},    -- Blessing of Sacrifice
    [27148]   = {6.5, "defensive"},    -- Blessing of Sacrifice
    [5384]    = {6.5, "defensive"},    -- Feign Death
    [34471]   = {6.5, "important"},    -- The Beast Within

    -- Silences
    [25046]   = {6, "cc"},    -- Arcane Torrent
    [1330]    = {6, "cc"},    -- Garrote
    [15487]   = {6, "cc"},    -- Silence (Priest)
    [18498]   = {6, "cc"},    -- Silenced - Gag Order (Warrior)
    [18469]   = {6, "cc"},    -- Silenced - Improved Counterspell (Mage)
    [18425]   = {6, "cc"},    -- Silenced - Improved Kick (Rogue)
    [34490]   = {6, "cc"},    -- Silencing Shot (Hunter)
    [19244]   = {6, "cc"},    -- Spell Lock (Felhunter)
    [30108]   = {6, "cc"},    -- Unstable Affliction (Silence)
    [30404]   = {6, "cc"},    -- Unstable Affliction (Silence)
    [30405]   = {6, "cc"},    -- Unstable Affliction (Silence)
    [31117]   = {6, "cc"},    -- UA silence (on dispel)
    [24259]   = {6, "cc"},    -- Spell Lock (Felhunter)
    [43523]   = {6, "cc"},    -- Unstable Affliction (Silence effect)
    [28730]   = {6, "cc"},    -- Arcane Torrent (Mana)
    [31935]   = {6, "cc"},    -- Avenger's Shield

    [1766]    = {5, "cc"},    -- Kick (Rogue)
    [38768]   = {5, "cc"},    -- Kick (Rogue)
    [2139]    = {6, "cc"},    -- Counterspell (Mage)
    [6552]    = {6, "cc"},    -- Pummel (Warrior)
    [19647]   = {6, "cc"},    -- Spell Lock (Warlock)
    -- [96231] = 6, -- Rebuke (Paladin) -- intentionally commented out

    -- Disarms
    [676]     = {5, "cc"},    -- Disarm
    [15752]   = {5, "cc"},    -- Disarm
    [14251]   = {5, "cc"},    -- Riposte
    [34097]   = {5, "cc"},    -- Riposte 2 (TODO: not sure which ID is correct)

    -- Important Stuff
    --[0] = 4.5, --

    -- Roots
    [44041]   = {4, "cc"},      -- Chastise (Root)
    [44043]   = {4, "cc"},      -- Chastise (Root)
    [44044]   = {4, "cc"},      -- Chastise (Root)
    [44045]   = {4, "cc"},      -- Chastise (Root)
    [44046]   = {4, "cc"},      -- Chastise (Root)
    [44047]   = {4, "cc"},      -- Chastise (Root)
    [339]     = {4, "cc"},      -- Entangling Roots
    [1062]    = {4, "cc"},      -- Entangling Roots
    [5195]    = {4, "cc"},      -- Entangling Roots
    [5196]    = {4, "cc"},      -- Entangling Roots
    [9852]    = {4, "cc"},      -- Entangling Roots
    [9853]    = {4, "cc"},      -- Entangling Roots
    [26989]   = {4, "cc"},      -- Entangling Roots
    [19970]   = {4, "cc"},      -- Entangling Roots (Nature's Grasp)
    [19971]   = {4, "cc"},      -- Entangling Roots (Nature's Grasp)
    [19972]   = {4, "cc"},      -- Entangling Roots (Nature's Grasp)
    [19973]   = {4, "cc"},      -- Entangling Roots (Nature's Grasp)
    [19974]   = {4, "cc"},      -- Entangling Roots (Nature's Grasp)
    [19975]   = {4, "cc"},      -- Entangling Roots (Nature's Grasp talent)
    [27010]   = {4, "cc"},      -- Nature's Grasp
    [25999]   = {4, "cc"},      -- Boar Charge
    [4167]    = {4, "cc"},      -- Web
    [122]     = {4, "cc"},      -- Frost Nova
    [865]     = {4, "cc"},      -- Frost Nova
    [6131]    = {4, "cc"},      -- Frost Nova
    [10230]   = {4, "cc"},      -- Frost Nova
    [27088]   = {4, "cc"},      -- Frost Nova
    [33395]   = {4, "cc"},      -- Freeze (Water Elemental)
    [35963]   = {4, "cc"},      -- Improved Wing Clip
    [19185]   = {4, "cc"},      -- Entrapment
    [16979]   = {4, "cc"},      -- Feral Charge
    [23694]   = {4, "cc"},      -- Improved Hamstring
    [13120]   = {4, "cc"},      -- Net-o-Matic
    [45334]   = {4, "cc"},      -- Immobilized
    [19306]   = {4, "cc"},      -- Counterattack (Rank 1)
    [20909]   = {4, "cc"},      -- Counterattack (Rank 2)
    [20910]   = {4, "cc"},      -- Counterattack (Rank 3)
    [27067]   = {4, "cc"},      -- Counterattack (Rank 4)
    [19229]   = {4, "cc"},      -- Improved Wing Clip
    [12494]   = {4, "cc"},      -- Frostbite

    [22734]   = {3.6, "important"},    -- Drink

    -- Defensive Buffs
    [3411]    = {3.4, "important"},    -- Intervene
    [45182]   = {3.2, "defensive"},    -- Cheating Death (85% reduced inc dmg)
    [31821]   = {3.2, "defensive"},    -- Aura Mastery
    [871]     = {3, "defensive"},      -- Shield Wall
    [33206]   = {3, "defensive"},      -- Pain Suppresion
    [47000]  = {3}, -- Improved Blink --not mop
    [2983]    = {3},      -- Sprint
    [5277]    = {3, "defensive"},      -- Evasion
    [8696]    = {3},      -- Sprint
    [11305]   = {3},      -- Sprint
    [26669]   = {3, "defensive"},      -- Evasion
    [17116]   = {6.6, "important"},    -- Nature's Swiftness (Shaman)
    [30823]   = {3, "defensive"},      -- Shamanistic Rage
    [30824]   = {3, "defensive"},      -- Shamanistic Rage
    [18499]   = {3, "defensive"},      -- Berserker Rage
    [31842]   = {3, "defensive"},      -- Divine Favor
    [1044]    = {3, "defensive"},      -- Hand of Freedom
    [22812]   = {3, "defensive"},      -- Barkskin
    [31616]   = {3, "defensive"},      -- Nature’s Guardian
    [12976]   = {2.9, "defensive"},    -- Last Stand
    [29166]   = {2.9, "defensive"},    -- Innervate
    [30458]   = {2.9, "defensive"},    -- Nigh Invulnerability Shield

    -- Offensive Buffs
    [13750]   = {2},       -- Adrenaline Rush
    [12042]   = {2},       -- Arcane Power
    [31884]   = {2, "important"},       -- Avenging Wrath
    [34936]   = {2},       -- Backlash
    [2825]    = {2},       -- Bloodlust
    [12292]   = {2},       -- Death Wish
    [16166]   = {2},       -- Elemental Mastery
    [12051]   = {2},       -- Evocation
    [12472]   = {2, "important"},       -- Icy Veins
    [32182]   = {2},       -- Heroism
    [10060]   = {2},       -- Power Infusion
    [3045]    = {2},       -- Rapid Fire
    [1719]    = {2},       -- Recklessness
    [12328]   = {2},       -- Sweeping Strikes
    [31641]   = {2},       -- Blazing Speed
    [31642]   = {2},       -- Blazing Speed
    [31643]   = {2},       -- Blazing Speed
    [14177] = {1.9},       -- Cold Blood

    [6346]    = {1.7, "important"},     -- Fear Ward
    [7744]    = {1.7, "important"},     -- Will of the Forsaken
    [20216] = {1.6, "important"}, -- Divine Favor

    -- Freedoms
    [5024]    = {1.4},    -- Flee (Skull of Impending Doom)

    -- Lesser defensives
    [1966]    = {1.3},   -- Feint

    -- Misc
    [18708] = {0.9},      -- Fel Domination
    [34709]  = {0.9},     -- Shadow Sight (Arena Eye)
    [11426]  = {0.8},     -- Ice Barrier

    -- Forms
    [5487]   = {0.5},     -- Bear Form
    [783]    = {0.5},     -- Travel Form
    [768]    = {0.5},     -- Cat Form
    [24858]  = {0.5},     -- Moonkin Form

    -- Slows
    [12323]  = {0.4},     -- Piercing Howl (50%)
    [120]    = {0.4},     -- Cone of Cold (70%)
    [1715]   = {0.4},     -- Hamstring (50%)

    [1953] = {0.5},      -- Blink
    [46989] = {0.4},     -- Improved Blink (25% chance to miss attacks and spells, 4sec buff)

    -- Miscellaneous
    [25771]  = {0.3},     -- Forbearance (debuff)
    [20600]  = {0.2},    -- Perception
    [28612]  = {0.2}, -- Cojured Food --not mop
    [33717]  = {0.2}, -- Cojured Food --not mop
    [41425]  = {0.1},     -- Hypothermia
    [13812]  = {0},       -- Glyph of Explosive Trap
    [6360]   = {0},       -- Whiplash
    [66]     = {0},       -- Invisibility



    -- ##########################
    -- Cata bonus ids, needs to be verified
    -- ##########################
    -- *** Controlled Stun Effects ***
    [2812]  = {9}, -- Holy Wrath

    -- *** Non-controlled Stun Effects ***
    [15283] = {9},     -- Stunning Blow (Weapon Proc)
    [56]    = {9},     -- Stun (Weapon Proc)

    -- *** Fear Effects ***
    [5134]  = {9},     -- Flash Bomb Fear (Item)

    -- *** Non-controlled Root Effects ***
    [47168] = {4},     -- Improved Wing Clip
}