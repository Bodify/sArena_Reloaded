local L = sArenaMixin.L

sArenaMixin.rangeTextures = {
    ["common-icon-checkmark-yellow"] = "|A:common-icon-checkmark-yellow:14:14|a Icon 1",
    ["common-icon-redx"] = "|A:common-icon-redx:14:14|a Icon 2",
    ["common-icon-zoomin"] = "|A:common-icon-zoomin:14:14|a Icon 3",
    ["common-icon-zoomout"] = "|A:common-icon-zoomout:14:14|a Icon 4",
    ["None"] = "|A:None:14:14|a Icon 5",
    ["ArtifactQuest"] = "|A:ArtifactQuest:14:14|a Icon 6",
    ["QuestSharing-DialogIcon"] = "|A:QuestSharing-DialogIcon:14:14|a Icon 7",
    ["QuestSharing-Stop-DialogIcon"] = "|A:QuestSharing-Stop-DialogIcon:14:14|a Icon 8",
    ["charactercreate-ring-select"] = "|A:charactercreate-ring-select:14:14|a Icon 9",
    ["CircleMaskScalable"] = "|A:CircleMaskScalable:14:14|a Icon 10",
    ["perks-border-square-gold"] = "|A:perks-border-square-gold:14:14|a Icon 11",
    ["bags-newitem"] = "|A:bags-newitem:14:14|a Icon 12",
    ["bags-glow-artifact"] = "|A:bags-glow-artifact:14:14|a Icon 13",
    ["GM-icon-visible-hover"] = "|A:GM-icon-visible-hover:14:14|a Icon 14",
    ["GM-icon-visibleDis-hover"] = "|A:GM-icon-visibleDis-hover:14:14|a Icon 15",

    [""] = L["Widget_RangeCheck_PresetNone"],
    ["custom"] = L["Widget_RangeCheck_CustomAtlas"],
}

sArenaMixin.rangeTexturesSorting = {
    "common-icon-checkmark-yellow",
    "common-icon-redx",
    "common-icon-zoomin",
    "common-icon-zoomout",
    "None",
    "ArtifactQuest",
    "QuestSharing-DialogIcon",
    "QuestSharing-Stop-DialogIcon",
    "charactercreate-ring-select",
    "CircleMaskScalable",
    "perks-border-square-gold",
    "bags-newitem",
    "bags-glow-artifact",
    "GM-icon-visible-hover",
    "GM-icon-visibleDis-hover",
    "",
    "custom",
}

sArenaMixin.defaultRangeSpellsPerSpec = {
    -- Warrior
    [71]   = 107570, -- Arms: Storm Bolt
    [72]   = 107570, -- Fury: Storm Bolt
    [73]   = 107570, -- Protection: Storm Bolt
    -- Paladin
    [65]   = 20066,  -- Holy: Repentance
    [66]   = 20066,  -- Protection: Repentance
    [70]   = 20066,  -- Retribution: Repentance
    -- Hunter
    [253]  = 193455, -- Beast Mastery: Cobra Shot
    [254]  = 19434,  -- Marksmanship: Aimed Shot
    [255]  = 1515,   -- Survival: Tame Beast
    -- Rogue
    [259]  = 36554,  -- Assassination: Shadowstep
    [260]  = 36554,  -- Outlaw: Shadowstep
    [261]  = 36554,  -- Subtlety: Shadowstep
    -- Priest
    [256]  = 605,    -- Discipline: Mind Control
    [257]  = 605,    -- Holy: Mind Control
    [258]  = 605,    -- Shadow: Mind Control
    -- Death Knight
    [250]  = 49576,  -- Blood: Death Grip
    [251]  = 49576,  -- Frost: Death Grip
    [252]  = 49576,  -- Unholy: Death Grip
    -- Shaman
    [262]  = 51514,  -- Elemental: Hex
    [263]  = 51514,  -- Enhancement: Hex
    [264]  = 51514,  -- Restoration: Hex
    -- Mage
    [62]   = 118,    -- Arcane: Polymorph
    [63]   = 118,    -- Fire: Polymorph
    [64]   = 118,    -- Frost: Polymorph
    -- Warlock
    [265]  = 5782,   -- Affliction: Fear
    [266]  = 5782,   -- Demonology: Fear
    [267]  = 5782,   -- Destruction: Fear
    -- Monk
    [268]  = 115078, -- Brewmaster: Paralysis
    [269]  = 115078, -- Windwalker: Paralysis
    [270]  = 115078, -- Mistweaver: Paralysis
    -- Druid
    [102]  = 33786,  -- Balance: Cyclone
    [103]  = 33786,  -- Feral: Cyclone
    [104]  = 33786,  -- Guardian: Cyclone
    [105]  = 33786,  -- Restoration: Cyclone
    -- Demon Hunter
    [577]  = 217832, -- Havoc: Imprison
    [581]  = 217832, -- Vengeance: Imprison
    [1480] = 217832, -- Devourer: Imprison
    -- Evoker
    [1467] = 360806, -- Devastation: Sleep Walk
    [1468] = 360806, -- Preservation: Sleep Walk
    [1473] = 360806, -- Augmentation: Sleep Walk
}
