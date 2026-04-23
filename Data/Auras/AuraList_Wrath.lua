-- Auras we want tooltip info from to display as stacks
sArenaMixin.tooltipInfoAuras = {
    --[115867] = true, -- Mana Tea
    [1247275] = true,     -- Tigereye Brew
}

sArenaMixin.spellLockReducer = {
    [317920] = 0.7, -- Concentration Aura
    [234084] = 0.5, -- Moon and Stars
    [383020] = 0.5, -- Tranquil Air
}

sArenaMixin.auraList = {
    -- Special
    [122465]  = {10, "important"},    -- Dematerialize
    [114028]  = {10, "important"},    -- Mass Spell Reflection
    [23920]   = {10, "important"},    -- Spell Reflection
    [113002]  = {10, "important"},    -- Spell Reflection (Symbiosis)
    [8178]    = {10, "important"},    -- Grounding Totem Effect

    -- Full CC (Stuns and Disorients)
    [33786]   = {9, "cc"},    -- Cyclone (Disorient)
    [58861]   = {9, "cc"},    -- Bash (Spirit Wolves)
    [5211]    = {9, "cc"},    -- Bash
    [8983]    = {9, "cc"},    -- Bash
    [6789]    = {9, "cc"},    -- Death Coil
    [27223]   = {9, "cc"},    -- Death Coil
    [1833]    = {9, "cc"},    -- Cheap Shot
    [7922]    = {9, "cc"},    -- Charge Stun
    [12809]   = {9, "cc"},    -- Concussion Blow
    [44572]   = {9, "cc"},    -- Deep Freeze
    [60995]   = {9, "cc"},    -- Demon Charge
    [47481]   = {9, "cc"},    -- Gnaw
    [853]     = {9, "cc"},    -- Hammer of Justice
    [10308]   = {9, "cc"},    -- Hammer of Justice
    [85388]   = {9, "cc"},    -- Throwdown
    [90337]   = {9, "cc"},    -- Bad Manner
    [20253]   = {9, "cc"},    -- Intercept
    [30153]   = {9, "cc"},    -- Pursuit
    [24394]   = {9, "cc"},    -- Intimidation
    [19577]   = {9, "cc"},    -- Intimidation
    [408]     = {9, "cc"},    -- Kidney Shot
    [8643]    = {9, "cc"},    -- Kidney Shot
    [22570]   = {9, "cc"},    -- Maim
    [9005]    = {9, "cc"},    -- Pounce
    [64058]   = {9, "cc"},    -- Psychic Horror
    [6572]    = {9, "cc"},    -- Ravage
    [30283]   = {9, "cc"},    -- Shadowfury
    [46968]   = {9, "cc"},    -- Shockwave
    [39796]   = {9, "cc"},    -- Stoneclaw Stun
    [20549]   = {9, "cc"},    -- War Stomp
    [61025]   = {9, "cc"},    -- Polymorph: Serpent
    [82691]   = {9, "cc"},    -- Ring of Frost
    [115078]  = {9, "cc"},    -- Paralysis
    [76780]   = {9, "cc"},    -- Bind Elemental
    [107079]  = {9, "cc"},    -- Quaking Palm (Racial)
    [99]      = {9, "cc"},    -- Disorienting Roar
    [123393]  = {9, "cc"},    -- Glyph of Breath of Fire
    [108194]  = {9, "cc"},    -- Asphyxiate
    [91797]   = {9, "cc"},    -- Monstrous Blow (Dark Transformation)
    [113801]  = {9, "cc"},    -- Bash (Treants)
    [117526]  = {9, "cc"},    -- Binding Shot
    [56626]   = {9, "cc"},    -- Sting (Wasp)
    [50519]   = {9, "cc"},    -- Sonic Blast
    [118271]  = {9, "cc"},    -- Combustion Impact
    [119392]  = {9, "cc"},    -- Charging Ox Wave
    [122242]  = {9, "cc"},    -- Clash (Symbiosis)
    [122057]  = {9, "cc"},    -- Clash
    [120086]  = {9, "cc"},    -- Fists of Fury
    [119381]  = {9, "cc"},    -- Leg Sweep
    [115752]  = {9, "cc"},    -- Blinding Light (Glyphed)
    [110698]  = {9, "cc"},    -- Hammer of Justice (Symbiosis)
    [119072]  = {9, "cc"},    -- Holy Wrath
    [105593]  = {9, "cc"},    -- Fist of Justice
    [118345]  = {9, "cc"},    -- Pulverize (Primal Earth Elemental)
    [118905]  = {9, "cc"},    -- Static Charge (Capacitor Totem)
    [89766]   = {9, "cc"},    -- Axe Toss (Felguard)
    [22703]   = {9, "cc"},    -- Inferno Effect
    [107570]  = {9, "cc"},    -- Storm Bolt
    [132169]  = {9, "cc"},    -- Storm Bolt
    [113004]  = {9, "cc"},    -- Intimidating Roar (Symbiosis)
    [113056]  = {9, "cc"},    -- Intimidating Roar (Symbiosis 2)
    [118699]  = {9, "cc"},    -- Fear (alt ID)
    [113792]  = {9, "cc"},    -- Psychic Terror (Psyfiend)
    [115268]  = {9, "cc"},    -- Mesmerize (Shivarra)
    [104045]  = {9, "cc"},    -- Sleep (Metamorphosis)
    [20511]   = {9, "cc"},    -- Intimidating Shout (secondary)
    [96201]   = {9, "cc"},    -- Web Wrap
    [132168]  = {9, "cc"},    -- Shockwave
    [118895]  = {9, "cc"},    -- Dragon Roar
    [115001]  = {9, "cc"},    -- Remorseless Winter
    [102795]  = {9, "cc"},    -- Bear Hug
    [77505]   = {9, "cc"},    -- Earthquake
    [15618]   = {9, "cc"},    -- Snap Kick
    [113953]  = {9, "cc"},    -- Paralysis
    [137143]  = {9, "cc"},    -- Blood Horror
    [87204]   = {9, "cc"},    -- Sin and Punishment
    [127361]  = {9, "cc"},    -- Bear Hug (Symbiosis)

    -- Stun Procs
    [34510]   = {9, "cc"},    -- Stun (various procs)
    [5530]    = {9, "cc"},    -- Mace Stun Effect
    [15269]   = {9, "cc"},    -- Blackout Stun
    [16922]   = {9, "cc"},    -- Imp Starfire Stun
    [12355]   = {9, "cc"},    -- Impact
    [23454]   = {9, "cc"},    -- Stun
    [20170]   = {9, "cc"},    -- Seal of Justice

    -- Disorient / Incapacitate / Fear / Charm
    [2094]    = {9, "cc"},    -- Blind
    [31661]   = {9, "cc"},    -- Dragon's Breath
    [5782]    = {9, "cc"},    -- Fear
    [130616]  = {9, "cc"},    -- Fear (Glyphed)
    [3355]    = {9, "cc"},    -- Freezing Trap
    [14309]   = {9, "cc"},    -- Freezing Trap Effect
    [1776]    = {9, "cc"},    -- Gouge
    [51514]   = {9, "cc"},    -- Hex
    [2637]    = {9, "cc"},    -- Hibernate
    [18658]   = {9, "cc"},    -- Hibernate
    [5484]    = {9, "cc"},    -- Howl of Terror
    [49203]   = {9, "cc"},    -- Hungering Cold
    [5246]    = {9, "cc"},    -- Intimidating Shout
    [25274]   = {9, "cc"},    -- Intercept Stun
    [605]     = {9, "cc"},    -- Mind Control
    [118]     = {9, "cc"},    -- Polymorph
    [12826]   = {9, "cc"},    -- Polymorph
    [28271]   = {9, "cc"},    -- Polymorph: Turtle
    [28272]   = {9, "cc"},    -- Polymorph: Pig
    [61721]   = {9, "cc"},    -- Polymorph: Rabbit
    [61780]   = {9, "cc"},    -- Polymorph: Turkey
    [61305]   = {9, "cc"},    -- Polymorph: Black Cat
    [8122]    = {9, "cc"},    -- Psychic Scream
    [20066]   = {9, "cc"},    -- Repentance
    [6770]    = {9, "cc"},    -- Sap
    [1513]    = {9, "cc"},    -- Scare Beast
    [14327]   = {9, "cc"},    -- Scare Beast
    [19503]   = {9, "cc"},    -- Scatter Shot
    [6358]    = {9, "cc"},    -- Seduction
    [9484]    = {9, "cc"},    -- Shackle Undead
    [1090]    = {9, "cc"},    -- Sleep
    [10326]   = {9, "cc"},    -- Turn Evil
    [145067]  = {9, "cc"},    -- Turn Evil
    [19386]   = {9, "cc"},    -- Wyvern Sting
    [88625]   = {9, "cc"},    -- Chastise
    [710]     = {9, "cc"},    -- Banish
    [105421]  = {9, "cc"},    -- Blinding Light
    [113506]  = {9, "cc"},    -- Cyclone (Symbiosis)
    [126355]  = {9, "cc"},    -- Paralyzing Quill
    [126246]  = {9, "cc"},    -- Lullaby
    [91800]   = {9, "cc"},    -- Gnaw (Ghoul stun)
    [64044]   = {9, "cc"},    -- Psychic Horror (alt ID)
    [31117]   = {9, "cc"},    -- UA silence (on dispel)
    [126423]  = {9, "cc"},    -- Petrifying Gaze (Basilisk pet) -- TODO: verify category
    [102546]  = {9, "cc"},    -- Pounce

    -- Immunities
    [115760]  = {7, "important"},      -- Glyph of Ice Block, Immune to Spells
    [46924]   = {7},      -- Bladestorm
    [19263]   = {7, "defensive"},      -- Deterrence
    [110617]  = {7, "defensive"},      -- Deterrence (Symbiosis)
    [47585]   = {7, "defensive"},      -- Dispersion
    [110715]  = {7, "defensive"},      -- Dispersion (Symbiosis)
    [642]     = {7, "defensive"},      -- Divine Shield
    [110700]  = {7, "defensive"},      -- Divine Shield (Symbiosis)
    [498]     = {7, "defensive"},      -- Divine Protection
    [45438]   = {7, "defensive"},      -- Ice Block
    [110696]  = {7, "defensive"},      -- Ice Block (Symbiosis)
    [34692]   = {7},      -- The Beast Within
    [26064]   = {7, "defensive"},      -- Shell Shield
    [19574]   = {7},      -- Bestial Wrath
    [1022]    = {7, "defensive"},      -- Hand of Protection
    [10278]   = {7, "defensive"},      -- Blessing of Protection
    [3169]    = {7, "defensive"},      -- Invulnerability
    [20230]   = {7},      -- Retaliation
    [16621]   = {7, "defensive"},      -- Self Invulnerability
    [92681]   = {7, "defensive"},      -- Phase Shift
    [20594]   = {7, "defensive"},      -- Stoneform -- FIX
    [31224]   = {7, "defensive"},      -- Cloak of Shadows
    [110788]  = {7, "defensive"},      -- Cloak of Shadows (Symbiosis)
    [27827]   = {7, "defensive"},      -- Spirit of Redemption
    [49039]   = {7, "defensive"},      -- Lichborne
    [148467]  = {7, "defensive"},      -- Deterrence

    [12043]   = {6.6, "important"},    -- Presence of Mind
    [132158]  = {6.6, "important"},    -- Nature's Swiftness
    [16188]   = {6.6, "important"},    -- Nature's Swiftness

    -- Anti-CCs
    [115018]  = {6.5, "important"},    -- Desecrated Ground (All CC Immunity)
    [48707]   = {6.5, "defensive"},    -- Anti-Magic Shell
    [110570]  = {6.5, "defensive"},    -- Anti-Magic Shell (Symbiosis)
    [137562]  = {6.5, "important"},    -- Nimble Brew
    [6940]    = {6.5, "defensive"},    -- Hand of Sacrifice
    [5384]    = {6.5, "defensive"},    -- Feign Death
    [34471]   = {6.5, "important"},    -- The Beast Within

    -- Silences
    [25046]   = {6, "cc"},    -- Arcane Torrent
    [1330]    = {6, "cc"},    -- Garrote
    [15487]   = {6, "cc"},    -- Silence (Priest)
    [18498]   = {6, "cc"},    -- Silenced - Gag Order (Warrior)
    [18469]   = {6, "cc"},    -- Silenced - Improved Counterspell (Mage)
    [55021]   = {6, "cc"},    -- Silenced - Improved Counterspell (Mage alt)
    [18425]   = {6, "cc"},    -- Silenced - Improved Kick (Rogue)
    [34490]   = {6, "cc"},    -- Silencing Shot (Hunter)
    [24259]   = {6, "cc"},    -- Spell Lock (Felhunter)
    [47476]   = {6, "cc"},    -- Strangulate (Death Knight)
    [43523]   = {6, "cc"},    -- Unstable Affliction (Silence effect)
    [114238]  = {6, "cc"},    -- Glyph of Fae Silence
    [102051]  = {6, "cc"},    -- Frostjaw
    [137460]  = {6, "cc"},    -- Ring of Peace (Silence)
    [115782]  = {6, "cc"},    -- Optical Blast (Observer)
    [50613]   = {6, "cc"},    -- Arcane Torrent (Runic Power)
    [28730]   = {6, "cc"},    -- Arcane Torrent (Mana)
    [69179]   = {6, "cc"},    -- Arcane Torrent (Rage)
    [80483]   = {6, "cc"},    -- Arcane Torrent (Focus)
    [31935]   = {6, "cc"},    -- Avenger's Shield
    [116709]  = {6, "cc"},    -- Spear Hand Strike
    [142895]  = {6, "cc"},    -- Silence (Ring of Peace?)

    [1766]    = {6, "cc"},    -- Kick (Rogue)
    [2139]    = {6, "cc"},    -- Counterspell (Mage)
    [6552]    = {6, "cc"},    -- Pummel (Warrior)
    [19647]   = {6, "cc"},    -- Spell Lock (Warlock)
    [47528]   = {6, "cc"},    -- Mind Freeze (Death Knight)
    [57994]   = {6, "cc"},    -- Wind Shear (Shaman)
    [91802]   = {6, "cc"},    -- Shambling Rush (Death Knight)
    -- [96231] = 6, -- Rebuke (Paladin) -- intentionally commented out
    [106839]  = {6, "cc"},    -- Skull Bash (Feral)
    [115781]  = {6, "cc"},    -- Optical Blast (Warlock)
    [116705]  = {6, "cc"},    -- Spear Hand Strike (Monk)
    [132409]  = {6, "cc"},    -- Spell Lock (Warlock)
    [147362]  = {6, "cc"},    -- Countershot (Hunter)
    --[171138] = 6, -- Shadow Lock (Warlock) --not mop
    --[183752] = 6, -- Consume Magic (Demon Hunter) --not mop
    --[187707] = 6, -- Muzzle (Hunter) -- not mop
    --[212619] = 6, -- Call Felhunter (Warlock) --not mop
    --[231665] = 6, -- Avenger's Shield (Paladin) --not mop
    --[351338] = 6, -- Quell (Evoker) --not mop
    [97547]   = {6, "cc"},    -- Solar Beam
    [113286]  = {6, "cc"},    -- Solar Beam
    [78675]   = {6, "cc"},    -- Solar Beam
    [81261]   = {6, "cc"},    -- Solar Beam

    -- Disarms
    [676]     = {5, "cc"},    -- Disarm
    [15752]   = {5, "cc"},    -- Disarm
    [14251]   = {5, "cc"},    -- Riposte
    [51722]   = {5, "cc"},    -- Dismantle
    [50541]   = {5, "cc"},    -- Clench (Scorpid)
    [91644]   = {5, "cc"},    -- Snatch (Bird of Prey)
    [117368]  = {5, "cc"},    -- Grapple Weapon
    [126458]  = {5, "cc"},    -- Grapple Weapon (Symbiosis)
    [137461]  = {5, "cc"},    -- Ring of Peace (Disarm)
    [118093]  = {5, "cc"},    -- Disarm (Voidwalker/Voidlord)
    [142896]  = {5, "cc"},    -- Disarmed
    [116844]  = {5, "cc"},    -- Ring of Peace (Silence / Disarm)

    -- Important Stuff
    [116849]  = {4.5, "defensive"},    -- life Cocoon
    [110575]  = {4.5, "defensive"},    -- Icebound Fortitude (Druid)
    [48792]   = {4.5, "defensive"},    -- Icebound Fortitude
    [122783]  = {4.5, "defensive"},    -- Diffuse Magic
    [125174]  = {4.5, "defensive"},    -- Monk: Touch of Karma
    [110909]  = {4.5, "defensive"},    -- Alter Time
    --[378081] = 4.5, -- Natures's Swiftness --not mop

    -- Roots
    [44047]   = {4, "cc"},      -- Chastise (Root)
    [339]     = {4, "cc"},      -- Entangling Roots
    [26989]   = {4, "cc"},      -- Entangling Roots
    [27010]   = {4, "cc"},      -- Nature's Grasp
    [19975]   = {4, "cc"},      -- Entangling Roots (Nature's Grasp talent)
    [19306]   = {4, "cc"},      -- Counterattack
    [25999]   = {4, "cc"},      -- Boar Charge
    [4167]    = {4, "cc"},      -- Web
    [122]     = {4, "cc"},      -- Frost Nova
    [27088]   = {4, "cc"},      -- Frost Nova
    [33395]   = {4, "cc"},      -- Freeze (Water Elemental)
    [96294]   = {4, "cc"},      -- Chains of Ice (Chilblains)
    [113275]  = {4, "cc"},      -- Entangling Roots (Symbiosis)
    [113770]  = {4, "cc"},      -- Entangling Roots (Treant)
    [102359]  = {4, "cc"},      -- Mass Entanglement
    [128405]  = {4, "cc"},      -- Narrow Escape
    [90327]   = {4, "cc"},      -- Lock Jaw (Dog)
    [54706]   = {4, "cc"},      -- Venom Web Spray (Silithid)
    [50245]   = {4, "cc"},      -- Pin (Crab)
    [110693]  = {4, "cc"},      -- Frost Nova (Symbiosis)
    [116706]  = {4, "cc"},      -- Disable
    [87194]   = {4, "cc"},      -- Glyph of Mind Blast
    [114404]  = {4, "cc"},      -- Void Tendrils
    [115197]  = {4, "cc"},      -- Partial Paralysis
    [63685]   = {4, "cc"},      -- Freeze (Frost Shock)
    [107566]  = {4, "cc"},      -- Staggering Shout
    [115757]  = {4, "cc"},      -- Frost nova
    [105771]  = {4, "cc"},      -- Warbringer
    [53148]   = {4, "cc"},      -- Charge
    [136634]  = {4, "cc"},      -- Narrow Escape
    --[127797] = 4, -- Ursol's Vortex
    [81210]   = {4, "cc"},      -- Net
    [35963]   = {4, "cc"},      -- Improved Wing Clip
    [19185]   = {4, "cc"},      -- Entrapment
    [16979]   = {4, "cc"},      -- Feral Charge
    [23694]   = {4, "cc"},      -- Improved Hamstring
    [13120]   = {4, "cc"},      -- Net-o-Matic
    [64803]   = {4, "cc"},      -- Entrapment
    [111340]  = {4, "cc"},      -- Ice Ward
    [123407]  = {4, "cc"},      -- Spinning Fire Blossom
    [64695]   = {4, "cc"},      -- Earthgrab Totem
    [91807]   = {4, "cc"},      -- Shambling Rush
    [135373]  = {4, "cc"},      -- Entrapment
    [45334]   = {4, "cc"},      -- Immobilized

    [22734]   = {3.6, "important"},    -- Drink
    [28612]   = {3.6, "important"},    -- Conjured Food
    [33717]   = {3.6, "important"},    -- Conjured Food

    -- Defensive Buffs
    [115610]  = {3.5, "defensive"},    -- Temporal Shield
    [147833]  = {3.4, "defensive"},    -- Intervene
    [114029]  = {3.4, "defensive"},    -- Safeguard
    [3411]    = {3.4, "defensive"},    -- Intervene
    [122292]  = {3.4, "defensive"},    -- Intervene (Symbiosis)
    [53476]   = {3.4, "defensive"},    -- Intervene (Hunter Pet)
    [111264]  = {3.3, "defensive"},    -- Ice Ward (Buff)
    [89485]   = {3.3, "defensive"},    -- Inner Focus (instant cast immunity)
    [113862]  = {3.3, "defensive"},    -- Greater Invisibility (90% dmg reduction)
    [111397]  = {3.3, "defensive"},    -- Blood Horror (flee on attack)
    [45182]   = {3.2, "defensive"},    -- Cheating Death (85% reduced inc dmg)
    [31821]   = {3.2, "defensive"},    -- Aura Mastery
    [53480]   = {3.1, "defensive"},    -- Roar of Sacrifice
    --[124280] = 1, -- Touch of Karma (Debuff)
    --[122470] = 1, -- Touch of Karma (Debuff)
    [871]     = {3, "defensive"},      -- Shield Wall
    [118038]  = {3, "defensive"},      -- Die by the Sword
    [33206]   = {3, "defensive"},      -- Pain Suppresion
    [47788]   = {3, "defensive"},      -- Guardian Spirit
    [47000]   = {3},      -- Improved Blink
    [5277]    = {3, "defensive"},      -- Evasion
    [26669]   = {3, "defensive"},      -- Evasion
    [126456]  = {3, "defensive"},      -- Fortifying Brew (Symbiosis)
    [110791]  = {3, "defensive"},      -- Evasion (Symbiosis)
    [122291]  = {3, "defensive"},      -- Unending Resolve (Symbiosis)
    [30823]   = {3, "defensive"},      -- Shamanistic Rage
    [18499]   = {3, "defensive"},      -- Berserker Rage
    [55694]   = {3, "defensive"},      -- Enraged Regeneration
    [31842]   = {3, "defensive"},      -- Divine Favor
    [1044]    = {3, "defensive"},      -- Hand of Freedom
    [22812]   = {3, "defensive"},      -- Barkskin
    [47484]   = {3, "defensive"},      -- Huddle
    [97463]   = {3, "defensive"},      -- Rallying Cry
    [86669]   = {3, "defensive"},      -- Guardian of Ancient Kings
    [108359]  = {3, "defensive"},      -- Dark Regeneration
    [108416]  = {3, "defensive"},      -- Sacrificial Pact
    [104773]  = {3, "defensive"},      -- Unending Resolve
    [110913]  = {3, "defensive"},      -- Dark Bargain
    [79206]   = {3, "defensive"},      -- Spiritwalker's Grace (movement casting)
    [108271]  = {3, "defensive"},      -- Astral Shift
    [108281]  = {3, "defensive"},      -- Ancestral Guidance (healing)
    [31616]   = {3, "defensive"},      -- Nature’s Guardian
    [114052]  = {3, "defensive"},      -- Ascendance (Restoration)
    [61336]   = {3, "defensive"},      -- Survival Instincts
    [106922]  = {3, "defensive"},      -- Might of Ursoc
    [122278]  = {3, "defensive"},      -- Dampen Harm
    [120954]  = {3, "defensive"},      -- Fortifying Brew
    [115176]  = {3, "defensive"},      -- Zen Meditation
    [81782]   = {3, "defensive"},      -- Power Word: Barrier
    [109964]  = {2.9, "defensive"},    -- Spirit Shell (Buff)
    [102342]  = {2.9, "defensive"},    -- Ironbark
    [50461]   = {2.9, "defensive"},    -- Anti-Magic Zone
    [29166]   = {2.9, "defensive"},    -- Innervate
    [30458]   = {2.9, "defensive"},    -- Nigh Invulnerability Shield
    [30457]   = {2.9, "defensive"},    -- Nigh Invulnerability Belt Backfire
    [114908]  = {2.8, "defensive"},    -- Spirit Shell (Absorb Shield)
    [64901]   = {2.8, "defensive"},    -- Hymn of Hope
    [98007]   = {2.8, "defensive"},    -- Spirit Link Totem
    [114214]  = {2.5, "defensive"},    -- Angelic Bulwark
    [114893]  = {2.5, "defensive"},    -- Stone Bulwark Totem
    [145629]  = {2.5, "defensive"},    -- Anti-Magic Zone
    [117679]  = {2.5, "defensive"},    -- Incarnation: Tree of Life

    -- Offensive Buffs
    [13750]   = {2},       -- Adrenaline Rush
    [12042]   = {2},       -- Arcane Power
    [31884]   = {2},       -- Avenging Wrath
    [34936]   = {2},       -- Backlash
    [50334]   = {2},       -- Berserk
    [2825]    = {2},       -- Bloodlust
    [12292]   = {2},       -- Death Wish
    [16166]   = {2},       -- Elemental Mastery
    [12051]   = {2},       -- Evocation
    [12472]   = {2, "important"},       -- Icy Veins
    [131078]  = {2, "important"},       -- Icy Veins (split)
    [32182]   = {2},       -- Heroism
    [51690]   = {2},       -- Killing Spree
    [17941]   = {2},       -- Shadow Trance
    [10060]   = {2},       -- Power Infusion
    [3045]    = {2},       -- Rapid Fire
    [1719]    = {2},       -- Recklessness
    [51713]   = {2, "important"},       -- Shadow Dance
    [107574]  = {2},       -- Avatar
    [121471]  = {2},       -- Shadow Blades
    [14177]   = {2},       -- Cold Blood
    [18708]   = {2},       -- Fel Domination
    [47241]   = {2},       -- Metamorphosis
    [105809]  = {2},       -- Holy Avenger
    [86698]   = {2},       -- Guardian of Ancient Kings (alt)
    [113858]  = {2},       -- Dark Soul: Instability
    [113860]  = {2},       -- Dark Soul: Misery
    [113861]  = {2},       -- Dark Soul: Knowledge
    [114050]  = {2},       -- Ascendance (Enhancement)
    [114051]  = {2},       -- Ascendance (Elemental)
    [102543]  = {2},       -- Incarnation: King of the Jungle
    [102560]  = {2},       -- Incarnation: Chosen of Elune
    [106951]  = {2},       -- Berserk
    [124974]  = {2},       -- Nature’s Vigil
    [51271]   = {2},       -- Pillar of Frost
    [49206]   = {2},       -- Summon Gargoyle
    [114868]  = {2},       -- Soul Reaper (Buff)
    [137639]  = {2},       -- Storm, Earth, and Fire
    [12328]   = {2},       -- Sweeping Strikes
    [84747]   = {1.9},     -- Deep Insight (Red Buff Rogue)
    [1247275] = {1.9},     -- Tigereye Brew (Monk)

    [76577]   = {1.8},     -- Smoke Bomb
    [88611]   = {1.8},     -- Smoke Bomb

    [6346]    = {1.7, "important"},     -- Fear Ward
    [110717]  = {1.7, "important"},     -- Fear Ward (Symbiosis)
    [7744]    = {1.7, "important"},     -- Will of the Forsaken
    [126084]  = {1.6},     -- Fingers of Frost
    [44544]   = {1.6},     -- Fingers of Frost
    [77616]   = {1.6},     -- Dark Simulacrum (Buff, has spell)

    -- Freedoms
    [96268]   = {1.4},    -- Deaths Advance
    [62305]   = {1.4},    -- Master's Call
    [5024]    = {1.4},    -- Flee (Skull of Impending Doom)
    [114896]  = {1.4},    -- Windwalk Totem
    [116841]  = {1.4},    -- Tiger's Lust (70% speed)

    -- Lesser defensives
    [1966]    = {1.3},   -- Feint
    --[102351] = 1.2, -- Cenarion Ward
    --[33763] = 1.1, -- Lifebloom
    --[121279] = 1.1, -- Lifebloom


    -- Misc
    [34709]  = {0.9, "important"},     -- Shadow Sight (Arena Eye)
    [110806] = {0.9},     -- Spirit Walker's Grace (Symbiosis)
    [11426]  = {0.8},     -- Ice Barrier
    [113656] = {0.8},     -- Fists of Fury
    [83853]  = {0.8},     -- Combustion (Debuff)
    --[41635]  = 0.5, -- Prayer of Mending
    [64844]  = {0.5},     -- Divine Hymn
    [114206] = {0.5},     -- Skull Banner

    -- Forms
    [5487]   = {0.5},     -- Bear Form
    [783]    = {0.5},     -- Travel Form
    [768]    = {0.5},     -- Cat Form
    [24858]  = {0.5},     -- Moonkin Form

    -- Slows
    [50435]  = {0.4},     -- Chilblains (50%)
    [12323]  = {0.4},     -- Piercing Howl (50%)
    [113092] = {0.4},     -- Frost Bomb (70%)
    [120]    = {0.4},     -- Cone of Cold (70%)
    [60947]  = {0.4},     -- Nightmare (30%)
    [1715]   = {0.4},     -- Hamstring (50%)
    [116095] = {0.4},     -- Disable (50%)

    -- Miscellaneous
    [25771]  = {0.3},     -- Forbearance (debuff)
    [115867] = {0.1},     -- Mana Tea
    [125195] = {0.1},     -- Tigereye Brew (Stacking)
    --[28612]  = 0.2, -- Cojured Food --not mop
    --[33717]  = 0.2, -- Cojured Food --not mop
    [108366] = {0.1},     -- Soul Leech
    [41425]  = {0.1},     -- Hypothermia
    [108199] = {0},       -- Gorefiend's Grasp
    [102793] = {0},       -- Ursol's Vortex
    [61391]  = {0},       -- Typhoon
    [13812]  = {0},       -- Glyph of Explosive Trap
    [51490]  = {0},       -- Thunderstorm
    [6360]   = {0},       -- Whiplash
    [115770] = {0},       -- Fellash
    [114018] = {0},       -- Shroud of Concealment
    [110960] = {0},       -- Greater Invisibility (Invis)
    [66]     = {0},       -- Invisibility
    [2457]   = {0},       -- Battle Stance
    [2458]   = {0},       -- Berserker Stance
    [71]     = {0},       -- Defensive Stance



    -- ##########################
    -- Cata bonus ids, needs to be verified
    -- ##########################
    -- *** Controlled Stun Effects ***
    [93433] = {9},     -- Burrow Attack (Worm)
    --[83046] = 9, -- Improved Polymorph (Rank 1) --not mop
    --[83047] = 9, -- Improved Polymorph (Rank 2) --not in mop
    --[2812]  = 9, -- Holy Wrath
    --[88625] = "Stunned", -- Holy Word: Chastise
    --[93986] = 9, -- Aura of Foreboding--not mop
    [54786] = {9},     -- Demon Leap

    -- *** Non-controlled Stun Effects ***
    [85387] = {9},     -- Aftermath
    [15283] = {9},     -- Stunning Blow (Weapon Proc)
    [56]    = {9},     -- Stun (Weapon Proc)

    -- *** Fear Effects ***
    [5134]  = {9},     -- Flash Bomb Fear (Item)

    -- *** Controlled Root Effects ***
    --[96293] = 4, -- Chains of Ice (Chilblains Rank 1) --not mop
    --[87193] = 4, -- Paralysis -- not mop

    -- *** Non-controlled Root Effects ***
    [47168] = {4},     -- Improved Wing Clip
    --[83301] = 4, -- Improved Cone of Cold (Rank 1) --not mop
    --[83302] = 4, -- Improved Cone of Cold (Rank 2) --not mop
    --[55080] = 4, -- Shattered Barrier (Rank 1) --not mop
    --[83073] = 4, -- Shattered Barrier (Rank 2) --not mop
    [50479] = {6},     -- Nether Shock (Nether Ray)
    --[86759] = 6, -- Silenced - Improved Kick (Rank 2) --not mop
}