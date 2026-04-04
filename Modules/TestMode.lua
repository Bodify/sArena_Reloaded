-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local isRetail = sArenaMixin.isRetail
local isMidnight = sArenaMixin.isMidnight
local isTBC = sArenaMixin.isTBC
local L = sArenaMixin.L
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local LSM = LibStub("LibSharedMedia-3.0")

-- Older clients dont show opponents in spawn
local noEarlyFrames = sArenaMixin.isTBC or sArenaMixin.isWrath
local isModernArena = isRetail or isMidnight -- For old trinkets

sArenaMixin.specInfo = {
    -- Tanks
    [66]   = { type = "Tanks",   name = "Protection" },
    [73]   = { type = "Tanks",   name = "Protection" },
    [104]  = { type = "Tanks",   name = "Guardian" },
    [250]  = { type = "Tanks",   name = "Blood" },
    [268]  = { type = "Tanks",   name = "Brewmaster" },
    [581]  = { type = "Tanks",   name = "Vengeance" },
    -- Healers
    [65]   = { type = "Healers", name = "Holy" },
    [105]  = { type = "Healers", name = "Restoration" },
    [256]  = { type = "Healers", name = "Discipline" },
    [257]  = { type = "Healers", name = "Holy" },
    [264]  = { type = "Healers", name = "Restoration" },
    [270]  = { type = "Healers", name = "Mistweaver" },
    [1468] = { type = "Healers", name = "Preservation" },
    -- Casters
    [62]   = { type = "Casters", name = "Arcane" },
    [63]   = { type = "Casters", name = "Fire" },
    [64]   = { type = "Casters", name = "Frost" },
    [102]  = { type = "Casters", name = "Balance" },
    [258]  = { type = "Casters", name = "Shadow" },
    [262]  = { type = "Casters", name = "Elemental" },
    [265]  = { type = "Casters", name = "Affliction" },
    [266]  = { type = "Casters", name = "Demonology" },
    [267]  = { type = "Casters", name = "Destruction" },
    [1467] = { type = "Casters", name = "Devastation" },
    [1473] = { type = "Casters", name = "Augmentation" },
    -- Hunters
    [253]  = { type = "Hunters", name = "Beast Mastery" },
    [254]  = { type = "Hunters", name = "Marksmanship" },
    [255]  = { type = "Hunters", name = "Survival" },
    -- Melee
    [70]   = { type = "Melee",   name = "Retribution" },
    [71]   = { type = "Melee",   name = "Arms" },
    [72]   = { type = "Melee",   name = "Fury" },
    [103]  = { type = "Melee",   name = "Feral" },
    [251]  = { type = "Melee",   name = "Frost" },
    [252]  = { type = "Melee",   name = "Unholy" },
    [259]  = { type = "Melee",   name = "Assassination" },
    [260]  = { type = "Melee",   name = "Outlaw" },
    [261]  = { type = "Melee",   name = "Subtlety" },
    [263]  = { type = "Melee",   name = "Enhancement" },
    [269]  = { type = "Melee",   name = "Windwalker" },
    [577]  = { type = "Melee",   name = "Havoc" },
    [1480] = { type = "Melee",   name = "Devourer" },
}

sArenaMixin.defaultSpecOrder = {
    Tanks   = {66, 73, 104, 250, 268, 581},
    Healers = {65, 105, 256, 257, 264, 270, 1468},
    Casters = {62, 63, 64, 102, 258, 262, 265, 266, 267, 1467, 1473},
    Hunters = {253, 254, 255},
    Melee   = {70, 71, 72, 103, 251, 252, 259, 260, 261, 263, 269, 577, 1480},
}

local specTemplates = {
    BM_HUNTER = {
        class = "HUNTER",
        specId = 253,
        specIcon = noEarlyFrames and 132164 or 461112,
        castName = "Cobra Shot",
        castIcon = noEarlyFrames and 132211 or 461114,
        racial = 135726,
        race = "Orc",
        unint = true,
    },
    MM_HUNTER = {
        class = "HUNTER",
        specId = 254,
        specIcon = noEarlyFrames and 132222 or 461113,
        castName = "Aimed Shot",
        castIcon = 132222,
        racial = 136225,
        race = "NightElf",
        unint = true,
    },
    SURV_HUNTER = {
        class = "HUNTER",
        specId = 255,
        specIcon = noEarlyFrames and 132215 or 461113,
        castName = "Mending Bandage",
        castIcon = isRetail and 1014022 or 133690,
        racial = 136225,
        race = "NightElf",
        channel = true,
    },
    ELE_SHAMAN = {
        class = "SHAMAN",
        specId = 262,
        specIcon = 136048,
        castName = "Lightning Bolt",
        castIcon = 136048,
        racial = 135726,
        race = "Orc",
    },
    ENH_SHAMAN = {
        class = "SHAMAN",
        specId = 263,
        specIcon = noEarlyFrames and 136051 or 237581,
        castName = "Stormstrike",
        castIcon = 132314,
        racial = 135726,
        race = "Orc",
    },
    RESTO_SHAMAN = {
        class = "SHAMAN",
        specId = 264,
        specIcon = 136052,
        castName = "Healing Wave",
        castIcon = 136052,
        racial = 135726,
        race = "Orc",
    },
    RESTO_DRUID = {
        class = "DRUID",
        specId = 105,
        specIcon = 136041,
        castName = "Regrowth",
        castIcon = 136085,
        racial = 132089,
        race = "NightElf",
    },
    AFF_WARLOCK = {
        class = "WARLOCK",
        specId = 265,
        specIcon = 136145,
        castName = "Fear",
        castIcon = 136183,
        racial = 132089,
        race = "NightElf",
    },
    DESTRO_WARLOCK = {
        class = "WARLOCK",
        specId = 267,
        specIcon = 136145,
        castName = "Chaos Bolt",
        castIcon = 136186,
        racial = 132089,
        race = "NightElf",
    },
    ARMS_WARRIOR = {
        class = "WARRIOR",
        specId = 71,
        specIcon = 132355,
        castName = "Slam",
        castIcon = 132340,
        racial = 136129,
        race = "Human",
        unint = true,
    },
    DISC_PRIEST = {
        class = "PRIEST",
        specId = 256,
        specIcon = 135940,
        castName = "Penance",
        castIcon = 237545,
        racial = 136129,
        race = "Human",
        channel = true,
    },
    HOLY_PRIEST = {
        class = "PRIEST",
        specId = 257,
        specIcon = 237542,
        castName = "Holy Fire",
        castIcon = 135972,
        racial = 136129,
        race = "Human",
    },
    FERAL_DRUID = {
        class = "DRUID",
        specId = 103,
        specIcon = 132115,
        castName = "Cyclone",
        castIcon = noEarlyFrames and 136022 or 132469,
        racial = 132089,
        race = "NightElf",
    },
    FROST_MAGE = {
        class = "MAGE",
        specId = 64,
        specIcon = 135846,
        castName = "Frostbolt",
        castIcon = 135846,
        racial = 136129,
        race = "Human",
    },
    ARCANE_MAGE = {
        class = "MAGE",
        specId = 62,
        specIcon = 135932,
        castName = "Arcane Blast",
        castIcon = 135735,
        racial = 136129,
        race = "Human",
    },
    FIRE_MAGE = {
        class = "MAGE",
        specId = 63,
        specIcon = 135810,
        castName = "Pyroblast",
        castIcon = 135808,
        racial = 132089,
        race = "NightElf",
    },
    RET_PALADIN = {
        class = "PALADIN",
        specId = 70,
        specIcon = 135873,
        castName = "Feet Up",
        castIcon = 133029,
        racial = 136129,
        race = "Human",
    },
    UNHOLY_DK = {
        class = "DEATHKNIGHT",
        specId = 252,
        specIcon = isTBC and 136212 or 135775,
        racial = 135726,
        race = "Orc",
        castName = "Army of the Dead",
        castIcon = isTBC and 136212 or 237511,
        channel = true,
    },
    SUB_ROGUE = {
        class = "ROGUE",
        specId = 261,
        specIcon = 132320,
        castName = "Crippling Poison",
        castIcon = 132273,
        racial = 135726,
        race = "Orc",
        unint = true,
    },
}

local testPlayers = {
    { template = "BM_HUNTER", name = "Despytimes" },
    { template = "BM_HUNTER", name = "Littlejimmy", racial = 132309, race = "Gnome" },
    { template = "MM_HUNTER", name = "Jellybeans" },
    { template = "SURV_HUNTER", name = "Bicmex" },
    { template = "ELE_SHAMAN", name = "Bluecheese" },
    { template = "ENH_SHAMAN", name = "Saul" },
    { template = "RESTO_SHAMAN", name = "Cdew" },
    { template = "RESTO_SHAMAN", name = "Absterge" },
    { template = "RESTO_SHAMAN", name = "Lontarito" },
    { template = "RESTO_SHAMAN", name = "Foxyllama" },
    { template = "ELE_SHAMAN", name = "Whaazzlasso", castName = "Feet Up", castIcon = 133029 },
    { template = "RESTO_DRUID", name = "Metaphors" },
    { template = "RESTO_DRUID", name = "Flop" },
    { template = "RESTO_DRUID", name = "Rennar" },
    { template = "FERAL_DRUID", name = "Sodapoopin" },
    { template = "FERAL_DRUID", name = "Bean" },
    { template = "FERAL_DRUID", name = "Snupy" },
    { template = "FERAL_DRUID", name = "Whaazzform" },
    { template = "AFF_WARLOCK", name = "Chan" },
    { template = "DESTRO_WARLOCK", name = "Merce" },
    { template = "DESTRO_WARLOCK", name = "Infernion" },
    { template = "DESTRO_WARLOCK", name = "Jazggz" },
    { template = "ARMS_WARRIOR", name = "Trillebartom" },
    { template = "DISC_PRIEST", name = "Hydra" },
    { template = "HOLY_PRIEST", name = "Mehh" },
    { template = "FROST_MAGE", name = "Raiku" },
    { template = "FROST_MAGE", name = "Samiyam" },
    { template = "FROST_MAGE", name = "Aeghis" },
    { template = "FROST_MAGE", name = "Venruki" },
    { template = "FROST_MAGE", name = "Xaryu" },
    { template = "FIRE_MAGE", name = "Hansol" },
    { template = "ARCANE_MAGE", name = "Ziqo" },
    { template = "ARCANE_MAGE", name = "Mmrklepter" },
    { template = "RET_PALADIN", name = "Judgewhaazz" },
    { template = "UNHOLY_DK", name = "Darthchan" },
    { template = "UNHOLY_DK", name = "Mes" },
    { template = "SUB_ROGUE", name = "Nahj" },
    { template = "SUB_ROGUE", name = "Invisbull", racial = 132368, race = "Tauren" },
    { template = "SUB_ROGUE", name = "Cshero" },
    { template = "SUB_ROGUE", name = "Pshero" },
    { template = "SUB_ROGUE", name = "Whaazz" },
    { template = "SUB_ROGUE", name = "Pikawhoo" },
    { template = "ARMS_WARRIOR", name = "Magnusz" },
}

local function GetFactionTrinketIconByRace(race)
    local allianceRaces = {
        ["Human"] = true,
        ["Dwarf"] = true,
        ["NightElf"] = true,
        ["Gnome"] = true,
        ["Draenei"] = true,
        ["Worgen"] = true,
    }

    if allianceRaces[race] then
        return 133452  -- Alliance trinket
    else
        return 133453  -- Horde trinket
    end
end

-- FrameSort integration: sort test players based on FrameSort's configured enemy arena sort mode
function sArenaMixin:SortTestPlayersForFrameSort(players)
    if not FrameSortApi or not FrameSortApi.v3 then return players end

    local enabled = FrameSortApi.v3.Options:GetEnabled("EnemyArena")
    if not enabled then
        return players
    end

    if not self.FrameSortCallbackRegistered then
        self.FrameSortCallbackRegistered = true
        FrameSortApi.v3.Options:RegisterConfigurationChangedCallback(function()
            if self.testMode then
                self:Test()
            end
        end)
    end

    local sortMode = FrameSortApi.v3.Options:GetGroupSortMode("EnemyArena")
    local reverse = FrameSortApi.v3.Options:GetReverse("EnemyArena")

    if sortMode == "Role" then
        local ordering = FrameSortDB and FrameSortDB.Options and FrameSortDB.Options.Sorting and FrameSortDB.Options.Sorting.Ordering
        local typeOrder = {
            Tanks   = ordering and ordering.Tanks   or 1,
            Healers = ordering and ordering.Healers or 2,
            Casters = ordering and ordering.Casters or 3,
            Hunters = ordering and ordering.Hunters or 4,
            Melee   = ordering and ordering.Melee   or 5,
        }

        -- Build sorted type list for spec ordering
        local sortedTypes = {}
        for key, order in pairs(typeOrder) do
            sortedTypes[#sortedTypes + 1] = {key = key, order = order}
        end
        table.sort(sortedTypes, function(a, b) return a.order < b.order end)

        -- Build specId → global position lookup (mirrors FrameSort's Comparer.lua Ordering())
        local specPriority = FrameSortDB and FrameSortDB.Options and FrameSortDB.Options.Sorting and FrameSortDB.Options.Sorting.SpecPriority
        local specOrderLookup = {}
        local globalIndex = 1
        for _, entry in ipairs(sortedTypes) do
            local priority = specPriority and specPriority[entry.key]
            if not priority or #priority == 0 then
                priority = self.defaultSpecOrder[entry.key]
            end
            for _, specId in ipairs(priority) do
                specOrderLookup[specId] = globalIndex
                globalIndex = globalIndex + 1
            end
        end

        local specInfo = self.specInfo
        table.sort(players, function(a, b)
            local aInfo = specInfo[a.specId]
            local bInfo = specInfo[b.specId]
            local aTypeOrder = aInfo and typeOrder[aInfo.type] or 5
            local bTypeOrder = bInfo and typeOrder[bInfo.type] or 5
            if aTypeOrder ~= bTypeOrder then
                return aTypeOrder < bTypeOrder
            end
            local aSpecOrder = specOrderLookup[a.specId] or 999
            local bSpecOrder = specOrderLookup[b.specId] or 999
            if aSpecOrder ~= bSpecOrder then
                return aSpecOrder < bSpecOrder
            end
            if a.class ~= b.class then
                return a.class < b.class
            end
            return a.name < b.name
        end)
    end

    if reverse then
        local n = #players
        for i = 1, math.floor(n / 2) do
            players[i], players[n - i + 1] = players[n - i + 1], players[i]
        end
    end

    return players
end

function sArenaMixin:ExpandTestTemplates()
    for _, player in ipairs(testPlayers) do
        local template = specTemplates[player.template]
        if template then
            for k, v in pairs(template) do
                if player[k] == nil then
                    player[k] = v
                end
            end
            player.template = nil
        end

        if player.specId and not player.specName then
            player.specName = self:GetSpecNameByID(player.specId)
        end
    end
    self.expandedTemplates = true
end

function sArenaMixin:ShufflePlayerExamples()
    local MAX = self.maxArenaOpponents or 3
    if MAX < 1 then return {} end

    local specInfo = self.specInfo
    local function isHealer(p)
        local info = p.specId and specInfo[p.specId]
        return info and info.type == "Healers" or false
    end

    local byClass, nonHealerByClass, healerList, classes = {}, {}, {}, {}

    for _, p in ipairs(testPlayers) do
        local cls = p.class
        if not byClass[cls] then
            byClass[cls] = {}
            nonHealerByClass[cls] = {}
            table.insert(classes, cls)
        end
        table.insert(byClass[cls], p)
        if isHealer(p) then
            table.insert(healerList, p)
        else
            table.insert(nonHealerByClass[cls], p)
        end
    end

    local chosen, usedClass = {}, {}

    -- 1) Pick exactly one healer (if any)
    if #healerList > 0 then
        local hp = healerList[math.random(#healerList)]
        table.insert(chosen, hp)
        --usedClass[hp.class] = true
    end

    -- 2) Fill remaining slots with NON-healers, preferring unique classes
    local candidateClasses = {}
    for _, cls in ipairs(classes) do
        if not usedClass[cls] and #nonHealerByClass[cls] > 0 then
            table.insert(candidateClasses, cls)
        end
    end
    -- shuffle classes
    for i = #candidateClasses, 2, -1 do
        local j = math.random(i)
        candidateClasses[i], candidateClasses[j] = candidateClasses[j], candidateClasses[i]
    end
    -- pick one non-healer from as many unique classes as possible
    for _, cls in ipairs(candidateClasses) do
        if #chosen >= MAX then break end
        local pool = nonHealerByClass[cls]
        table.insert(chosen, pool[math.random(#pool)])
        usedClass[cls] = true
    end

    -- 3) If still short of MAX (e.g., not enough unique classes), allow duplicates but still NO extra healers
    if #chosen < MAX then
        local flatNonHealers = {}
        for _, pool in pairs(nonHealerByClass) do
            for _, p in ipairs(pool) do table.insert(flatNonHealers, p) end
        end
        -- Fallback: if there were zero non-healers at all, fill with healers (only case we can’t enforce “only 1”)
        local fallbackPool = (#flatNonHealers > 0) and flatNonHealers or healerList
        while #chosen < MAX and #fallbackPool > 0 do
            table.insert(chosen, fallbackPool[math.random(#fallbackPool)])
        end
    end

    -- 4) Final shuffle so healer isn’t always first
    for i = #chosen, 2, -1 do
        local j = math.random(i)
        chosen[i], chosen[j] = chosen[j], chosen[i]
    end

    -- Trim just in case (shouldn't happen, but safe)
    while #chosen > MAX do table.remove(chosen) end

    return chosen
end

function sArenaMixin:Test()
    local _, instanceType = IsInInstance()
    if (InCombatLockdown() or instanceType == "arena") then
        self:Print(L["Message_TestModeWarning"])
        return
    end

    self.testMode = true

    local currTime = GetTime()
    if not self.expandedTemplates then
        self:ExpandTestTemplates()
    end
    local shuffledPlayers = self:ShufflePlayerExamples()
    shuffledPlayers = self:SortTestPlayersForFrameSort(shuffledPlayers)
    local db = self.db
    local cropIcons = db.profile.layoutSettings[db.profile.currentLayout].cropIcons
    local replaceClassIcon = db.profile.layoutSettings[db.profile.currentLayout].replaceClassIcon
    local hideSpecIcon = db.profile.layoutSettings[db.profile.currentLayout].hideSpecIcon
    local hideClassIcon = db.profile.hideClassIcon
    local colorTrinket = db.profile.colorTrinket
    local modernCastbars = db.profile.layoutSettings[db.profile.currentLayout].castBar.useModernCastbars
    local keepDefaultModernTextures = db.profile.layoutSettings[db.profile.currentLayout].castBar.keepDefaultModernTextures
    local widgetSettings = db.profile.layoutSettings[db.profile.currentLayout].widgets
    local partyTargetIndicatorsOn = widgetSettings.partyTargetIndicators
        and widgetSettings.partyTargetIndicators.enabled
        and widgetSettings.partyTargetIndicators.partyOnArena
        and widgetSettings.partyTargetIndicators.partyOnArena.enabled
    local targetIndicatorOn = widgetSettings.targetIndicator.enabled
    local focusIndicatorOn = widgetSettings.focusIndicator.enabled
    local combatIndicatorOn = widgetSettings.combatIndicator.enabled

    local ti = widgetSettings.targetIndicator
    local fi = widgetSettings.focusIndicator
    local targetUseBorder = ti and ti.enabled and ti.useBorder
    local focusUseBorder = fi and fi.enabled and fi.useBorder
    local targetUseBoth = ti and ti.enabled and ti.useBorderWithIcon
    local focusUseBoth = fi and fi.enabled and fi.useBorderWithIcon

    local topFrame
    local numUnits = math.min(self.testUnits or self.maxArenaOpponents, self.maxArenaOpponents)

    for i = 1, numUnits do
        local frame = self["arena" .. i]
        local data = shuffledPlayers[i]

        if i == 1 then
            topFrame = frame
        end

        if self.masqueOn and frame.masqueHidden then
            frame.FrameMsq:Show()
            frame.ClassIconMsq:Show()
            frame.SpecIconMsq:Show()
            frame.CastBarMsq:Show()
            if frame.CastBar.MSQ then
                frame.CastBar.MSQ:Show()
                frame.CastBar.Icon:Hide()
            end
            frame.TrinketMsq:Show()
            frame.RacialMsq:Show()
            frame.DispelMsq:Show()
            frame.masqueHidden = false
        end

        frame.tempName = data.name
        frame.tempSpecName = data.specName
        frame.tempClass = data.class
        frame.class = data.class
        frame.tempSpecIcon = data.specIcon
        frame.replaceClassIcon = replaceClassIcon
        frame.isHealer = self.healerSpecNames[data.specName] or false

        local currentLayout = self.layouts[self.db.profile.currentLayout]
        if currentLayout and currentLayout.UpdateHealthbarOrientation then
            currentLayout:UpdateHealthbarOrientation(frame)
        end

        frame:Show()
        frame:SetAlpha(1)
        frame.HealthBar:SetAlpha(1)
        frame.WidgetOverlay:Show()

        frame.HealthBar:SetMinMaxValues(0, 100)
        frame.HealthBar:SetValue(100)

        if i == 1 then
            local showFocusIcon = focusIndicatorOn and (not focusUseBorder or focusUseBoth)
            frame.WidgetOverlay.focusIndicator:SetShown(showFocusIcon)

            if focusUseBorder then
                local c = fi.borderColor or {0, 0, 1, 1}
                frame:SetTargetFocusBorderColor(c[1], c[2], c[3], c[4])
                frame:SetTargetFocusBorderDrawLayer(false)
                frame:UpdateTargetFocusBorderAnchors(fi)
                frame.TargetFocusBorder:Show()
            elseif frame.TargetFocusBorder then
                frame.TargetFocusBorder:Hide()
            end
        elseif i == 2 then
            frame.HealthBar:SetValue(75)

            local showTargetIcon = targetIndicatorOn and (not targetUseBorder or targetUseBoth)
            frame.WidgetOverlay.targetIndicator:SetShown(showTargetIcon)

            if targetUseBorder then
                local c = ti.borderColor or {1, 0.7, 0, 1}
                frame:SetTargetFocusBorderColor(c[1], c[2], c[3], c[4])
                frame:SetTargetFocusBorderDrawLayer(true)
                frame:UpdateTargetFocusBorderAnchors(ti)
                frame.TargetFocusBorder:Show()
            elseif frame.TargetFocusBorder then
                frame.TargetFocusBorder:Hide()
            end
        elseif i == 3 then
            frame.HealthBar:SetValue(45)
        end

        -- Show 2 party target indicators on every arena frame
        if partyTargetIndicatorsOn then
            local classColors = {}
            for classToken, color in pairs(RAID_CLASS_COLORS) do
                table.insert(classColors, color)
            end
            for j = 1, 4 do
                local indicator = frame.WidgetOverlay["partyTarget" .. j]
                if j <= 2 then
                    local c = classColors[math.random(#classColors)]
                    indicator.Texture:SetVertexColor(c.r, c.g, c.b)
                    indicator:Show()
                    indicator:SetAlpha(1)
                else
                    indicator:Hide()
                    indicator:SetAlpha(0)
                end
            end
        else
            for j = 1, 4 do
                frame.WidgetOverlay["partyTarget" .. j]:Hide()
                frame.WidgetOverlay["partyTarget" .. j]:SetAlpha(0)
            end
        end

        if i > 2 and frame.TargetFocusBorder then
            frame.TargetFocusBorder:Hide()
        end

        frame.WidgetOverlay.combatIndicator:SetShown(combatIndicatorOn)

        frame.PowerBar:SetMinMaxValues(0, 100)
        frame.PowerBar:SetValue(100)

        -- Class Icon and Spec Icon + Spec Name
        if hideClassIcon then
            local ccSpells = {408, 2139, 33786, 118, 122}
            local ccIndex = ((i - 1) % #ccSpells) + 1
            local spellTexture = GetSpellTexture(ccSpells[ccIndex])
            frame.ClassIcon.Texture:SetTexture(spellTexture)
            if frame.ClassIconMsq then
                frame.ClassIconMsq:Hide()
            end
            if frame.SpecIconMsq then
                frame.SpecIconMsq:Hide()
            end
            if not replaceClassIcon and not hideSpecIcon then
                frame.SpecIcon:Show()
                frame.SpecIcon.Texture:SetTexture(data.specIcon)
                if frame.SpecIconMsq then
                    frame.SpecIconMsq:Show()
                end
            end
        else
            if replaceClassIcon then
                frame.SpecIcon:Hide()
                frame.SpecIcon.Texture:SetTexture(nil)
                if frame.SpecIconMsq then
                    frame.SpecIconMsq:Hide()
                end
                frame.ClassIcon.Texture:SetTexture(data.specIcon, true)
            elseif hideSpecIcon then
                frame.SpecIcon:Hide()
                frame.SpecIcon.Texture:SetTexture(nil)
                if frame.SpecIconMsq then
                    frame.SpecIconMsq:Hide()
                end
                frame.ClassIcon.Texture:SetTexture(self.classIcons[data.class])
            else
                frame.SpecIcon:Show()
                frame.SpecIcon.Texture:SetTexture(data.specIcon)
                if frame.SpecIconMsq then
                    frame.SpecIconMsq:Show()
                end
                frame.ClassIcon.Texture:SetTexture(self.classIcons[data.class])
            end
            if frame.ClassIconMsq then
                frame.ClassIconMsq:Show()
            end
        end

        local cropType
        if db.profile.replaceHealerIcon and frame.isHealer then
            frame.ClassIcon.Texture:SetAtlas("UI-LFG-RoleIcon-Healer")
            cropType = "healer"
        else
            cropType = "class"
        end

        frame:SetTextureCrop(frame.ClassIcon.Texture, cropIcons, cropType)

        frame.SpecNameText:SetText(data.specName)
        frame.SpecNameText:SetShown(db.profile.layoutSettings[db.profile.currentLayout].showSpecManaText)
        frame:UpdateSpecNameColor()

        frame.ClassIcon.Cooldown:SetCooldown(currTime, math.random(5, 35))

        if db.profile.showArenaNumber then
            if db.profile.arenaNumberIdOnly then
                frame.Name:SetText(i)
            else
                frame.Name:SetText("Arena " .. i)
            end
        else
            frame.Name:SetText(data.name)
        end
        frame.Name:SetShown(db.profile.showNames or db.profile.showArenaNumber)
        frame:UpdateNameColor()

        frame.race = data.race
        frame.unit = "arena" .. i

        local shouldForceHumanTrinket = not isRetail and data.race == "Human" and db.profile.forceShowTrinketOnHuman
        local shouldReplaceHumanRacial = not isRetail and data.race == "Human" and db.profile.replaceHumanRacialWithTrinket
        local shouldSwapRacialToTrinket = false

        frame.Trinket.Cooldown:SetCooldown(currTime, math.random(5, 35))
        if colorTrinket then
            local colors = db.profile.trinketColors
            local keepTexture = db.profile.colorTrinketKeepTexture
            if keepTexture then
                frame.Trinket.Texture:SetDesaturated(true)
            else
                frame.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
            end
            if i <= 2 then
                frame.Trinket.Texture:SetVertexColor(unpack(colors.available))
                frame.Trinket.Cooldown:Clear()
            else
                frame.Trinket.Texture:SetVertexColor(unpack(colors.used))
            end
        else
            frame.Trinket.Texture:SetVertexColor(1, 1, 1)
            if shouldSwapRacialToTrinket then
                frame.Trinket.Texture:SetTexture(data.racial or 132089)
            elseif shouldForceHumanTrinket then
                frame.Trinket.Texture:SetTexture(133452)
            else
                if not isModernArena then
                    frame.Trinket.Texture:SetTexture(GetFactionTrinketIconByRace(data.race))
                else
                    frame.Trinket.Texture:SetTexture(self.trinketTexture)
                end
            end
            frame.Trinket.Texture:SetDesaturated(false)
        end

        frame.updateRacialOnTrinketSlot = shouldSwapRacialToTrinket
        local shouldShowRacial = false

        if data.race and db.profile.racialCategories and db.profile.racialCategories[data.race] then
            shouldShowRacial = true
        end

        if shouldReplaceHumanRacial then
            frame.Racial.Texture:SetTexture(133452)
            frame.Racial.Cooldown:SetCooldown(currTime, math.random(5, 35))
            if frame.RacialMsq then
                frame.RacialMsq:Show()
            end
        elseif shouldShowRacial and not shouldSwapRacialToTrinket then
            frame.Racial.Texture:SetTexture(data.racial or 132089)
            frame.Racial.Cooldown:SetCooldown(currTime, math.random(5, 35))
            if frame.RacialMsq then
                frame.RacialMsq:Show()
            end
        else
            frame.Racial.Texture:SetTexture(nil)
            frame.Racial.Cooldown:Clear()
            if frame.RacialMsq then
                frame.RacialMsq:Hide()
            end
        end

        if db.profile.showDispels then
            local dispelInfo = frame.GetTestModeDispelData and frame:GetTestModeDispelData()
            if dispelInfo then
                frame.Dispel.Texture:SetTexture(dispelInfo.texture)
                frame.Dispel:Show()
                frame.Dispel.Cooldown:SetCooldown(currTime, math.random(5, 35))
            else
                frame.Dispel.Texture:SetTexture(nil)
                frame.Dispel:Hide()
            end
        else
            frame.Dispel.Texture:SetTexture(nil)
            frame.Dispel:Hide()
        end

        -- Colors
        local color = RAID_CLASS_COLORS[data.class]
        if (db.profile.classColors and color) then
            frame.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
        else
            frame.HealthBar:SetStatusBarColor(0, 1, 0, 1)
        end

        local powerType
        if data.class == "DRUID" then
            -- Check if druid is feral/guardian (energy) or balance/restoration (mana)
            if data.specName == "Feral" or data.specName == "Guardian" then
                powerType = "ENERGY"
            else
                powerType = "MANA"
            end
        else
            powerType = self.classPowerType[data.class] or "MANA"
        end
        local powerColor = PowerBarColor[powerType] or { r = 0, g = 0, b = 1 }

        frame.PowerBar:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)

        frame:UpdateFrameColors()


        -- DR Frames
        if isMidnight then
            local layoutdb = db.profile.layoutSettings[db.profile.currentLayout]
            local drSettings = layoutdb.dr or {}

            if frame.drFrames then
                local drCategoryTextures = {
                    [1] = 136071,     -- Incap (Poly)
                    [2] = 135860,     -- Stun (Whirl)
                    [3] = 136100,     -- Root (Entangling Roots)
                    [4] = 136183,     -- Fear (Fear)
                    [5] = 458230,     -- Silence
                    [6] = 132114,     -- Disarm (Dismantle)
                }

                for n = 1, #frame.drFrames do
                    local drFrame = frame.drFrames[n]
                    if drFrame then
                        drFrame.Icon:SetTexture(drCategoryTextures[n])
                        drFrame:Show()
                        drFrame.Cooldown:SetCooldown(currTime, math.random(12, 35))

                        local blackDRBorder = drSettings.blackDRBorder

                        if (n == 1) then
                            local borderColor = blackDRBorder and { 0, 0, 0, 1 } or { 1, 0, 0, 1 }
                            drFrame.Border:SetVertexColor(unpack(borderColor))
                            if drFrame.PixelBorder then
                                drFrame.PixelBorder:SetVertexColor(unpack(borderColor))
                            end
                            drFrame.DRTextFrame.DRText:SetText("%")
                            drFrame.DRTextFrame.DRText:SetTextColor(1, 0, 0)

                            if self.db.profile.colorDRCooldownText and drFrame.Cooldown.Text then
                                drFrame.Cooldown.Text:SetTextColor(1, 0, 0, 1)
                            end
                        else
                            local borderColor = blackDRBorder and { 0, 0, 0, 1 } or { 0, 1, 0, 1 }
                            drFrame.Border:SetVertexColor(unpack(borderColor))
                            if drFrame.PixelBorder then
                                drFrame.PixelBorder:SetVertexColor(unpack(borderColor))
                            end
                            drFrame.DRTextFrame.DRText:SetText("½")
                            drFrame.DRTextFrame.DRText:SetTextColor(0, 1, 0)

                            if self.db.profile.colorDRCooldownText and drFrame.Cooldown.Text then
                                drFrame.Cooldown.Text:SetTextColor(0, 1, 0, 1)
                            end
                        end
                    end
                end

                self:UpdateDRSettings(drSettings)
            end
        else
            local drsEnabled = #self.drCategories
            if drsEnabled > 0 then
                local drCategoryOrder = {
                    "Incapacitate",
                    "Stun",
                    "Root",
                    "Disorient",
                    "Silence",
                }
                local drCategoryTextures = {
                    [1] = 136071, -- Incap (Poly)
                    [2] = 132298, -- Stun (Kidney)
                    [3] = 135848, -- Root (Frost Nova)
                    [4] = 136184, -- Fear (Psychic Scream)
                    [5] = 458230, -- Silence
                }

                for n = 1, 4 do
                    local drFrame = frame[drCategoryOrder[n]]
                    local textureID = drCategoryTextures[n]
                    drFrame.Icon:SetTexture(textureID)
                    drFrame:Show()
                    drFrame.Cooldown:SetCooldown(currTime, math.random(12, 25))

                    local layout = self.db.profile.layoutSettings[self.db.profile.currentLayout]
                    local db = layout.dr or {}
                    local blackDRBorder = db.blackDRBorder

                    if db.disableDRBorder then
                        drFrame.Border:Hide()
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:Hide()
                        end
                    elseif db.thickPixelBorder then
                        drFrame.Border:Hide()
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:Show()
                        end
                    else
                        -- Show only normal border (for thinPixelBorder, brightDRBorder, drBorderGlowOff, or default)
                        drFrame.Border:Show()
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:Hide()
                        end
                    end

                    if (n == 1) then
                        local borderColor = blackDRBorder and { 0, 0, 0, 1 } or { 1, 0, 0, 1 }
                        local pixelBorderColor = blackDRBorder and { 0, 0, 0, 1 } or { 1, 0, 0, 1 }
                        drFrame.Border:SetVertexColor(unpack(borderColor))
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:SetVertexColor(unpack(pixelBorderColor))
                        end
                        drFrame.DRTextFrame.DRText:SetText("%")
                        drFrame.DRTextFrame.DRText:SetTextColor(1, 0, 0)
                        if drFrame.__MSQ_New_Normal then
                            drFrame.__MSQ_New_Normal:SetDesaturated(true)
                            drFrame.__MSQ_New_Normal:SetVertexColor(1, 0, 0, 1)
                        end

                        if self.db.profile.colorDRCooldownText then
                            if drFrame.Cooldown.Text then
                                drFrame.Cooldown.Text:SetTextColor(1, 0, 0, 1)
                            end
                            if drFrame.Cooldown.sArenaText then
                                drFrame.Cooldown.sArenaText:SetTextColor(1, 0, 0, 1)
                            end
                        end
                    else
                        local borderColor = blackDRBorder and { 0, 0, 0, 1 } or { 0, 1, 0, 1 }
                        local pixelBorderColor = blackDRBorder and { 0, 0, 0, 1 } or { 0, 1, 0, 1 }
                        drFrame.Border:SetVertexColor(unpack(borderColor))
                        if drFrame.PixelBorder then
                            drFrame.PixelBorder:SetVertexColor(unpack(pixelBorderColor))
                        end
                        drFrame.DRTextFrame.DRText:SetText("½")
                        drFrame.DRTextFrame.DRText:SetTextColor(0, 1, 0)
                        if drFrame.__MSQ_New_Normal then
                            drFrame.__MSQ_New_Normal:SetDesaturated(true)
                            drFrame.__MSQ_New_Normal:SetVertexColor(0, 1, 0, 1)
                        end

                        if self.db.profile.colorDRCooldownText then
                            if drFrame.Cooldown.Text then
                                drFrame.Cooldown.Text:SetTextColor(0, 1, 0, 1)
                            end
                            if drFrame.Cooldown.sArenaText then
                                drFrame.Cooldown.sArenaText:SetTextColor(0, 1, 0, 1)
                            end
                        end
                    end
                end
            end
        end

        -- Cast Bar
        if data.castName then
            local layout = self.db.profile.layoutSettings[self.db.profile.currentLayout]
            local texKeys = layout.textures or {
                generalStatusBarTexture = "sArena Default",
                healStatusBarTexture    = "sArena Default",
                castbarStatusBarTexture = "sArena Default",
                castbarUninterruptibleTexture = "sArena Default",
            }

            -- Get custom colors if enabled
            local colors = db.profile.castBarColors
            local useCustomColors = layout.castBar and layout.castBar.recolorCastbar

            frame.tempCast = true
            frame.tempCastName = data.castName
            frame.tempChannel = data.channel or false
            frame.tempUninterruptible = data.unint or false

            frame.CastBar.fadeOut = nil
            frame.CastBar:Show()
            frame.CastBar:SetAlpha(1)
            frame.CastBar.Icon:SetTexture(data.castIcon)
            frame.CastBar.Text:SetText(data.castName)

            if db.profile.showCastbarTarget then
                local playerName = UnitName("player")
                local _, playerClass = UnitClass("player")
                local textSettings = layout.textSettings
                local anchorInside = textSettings and textSettings.castbarTargetAnchorInside

                if anchorInside then
                    local coloredName = playerName
                    if playerClass then
                        local color = C_ClassColor and C_ClassColor.GetClassColor(playerClass) or RAID_CLASS_COLORS[playerClass]
                        if color then
                            if color.WrapTextInColorCode then
                                coloredName = color:WrapTextInColorCode(playerName)
                            elseif color.colorStr then
                                coloredName = "|c" .. color.colorStr .. playerName .. "|r"
                            end
                        end
                    end
                    frame.CastBar.Text:SetText(data.castName .. ": " .. coloredName)
                else
                    if frame.CastBar.ArenaTargetText then
                        local coloredName = playerName
                        if playerClass then
                            local color = C_ClassColor and C_ClassColor.GetClassColor(playerClass) or RAID_CLASS_COLORS[playerClass]
                            if color then
                                if color.WrapTextInColorCode then
                                    coloredName = color:WrapTextInColorCode(playerName)
                                elseif color.colorStr then
                                    coloredName = "|c" .. color.colorStr .. playerName .. "|r"
                                end
                            end
                        end
                        local justify = (textSettings and textSettings.castbarTargetJustifyH) or "CENTER"
                        frame.CastBar.ArenaTargetText:SetText("")
                        frame.CastBar.ArenaTargetText:SetJustifyH(justify)
                        frame.CastBar.ArenaTargetText:SetText(coloredName)
                        frame.CastBar.ArenaTargetText:Show()
                    end
                end
            end

            if db.profile.highlightCastsOnMe and frame.CastBar.ArenaTargetHighlight then
                frame.CastBar.ArenaTargetHighlight:SetAlpha(i == 2 and 1 or 0)
            end

            if data.unint then
                frame.CastBar.BorderShield:Show()
                if useCustomColors then
                    frame.CastBar:SetStatusBarColor(unpack(colors.uninterruptable))
                else
                    frame.CastBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
                end
            else
                frame.CastBar.BorderShield:Hide()
                if data.channel then
                    if useCustomColors then
                        frame.CastBar:SetStatusBarColor(unpack(colors.channel))
                    else
                        frame.CastBar:SetStatusBarColor(0, 1, 0, 1)
                    end
                else
                    if useCustomColors then
                        frame.CastBar:SetStatusBarColor(unpack(colors.standard))
                    else
                        frame.CastBar:SetStatusBarColor(1, 0.7, 0, 1)
                    end
                end
            end

            if modernCastbars then
                if keepDefaultModernTextures then
                    if isRetail then
                        frame.CastBar:SetStatusBarTexture(data.unint and "UI-CastingBar-Uninterruptable" or data.channel and "UI-CastingBar-Filling-Channel" or "ui-castingbar-filling-standard")
                    else
                        frame.CastBar:SetStatusBarTexture(data.unint and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or data.channel and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                    end
                    -- Handle desaturation for modern castbars with default textures
                    local castTexture = frame.CastBar:GetStatusBarTexture()
                    if useCustomColors then
                        if castTexture then
                            castTexture:SetDesaturated(true)
                        end
                    else
                        if castTexture then
                            castTexture:SetDesaturated(false)
                        end
                        frame.CastBar:SetStatusBarColor(1,1,1,1)
                    end
                else
                    local castPath
                    if data.unint then
                        castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarUninterruptibleTexture or texKeys.castbarStatusBarTexture)
                    else
                        castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
                    end
                    frame.CastBar:SetStatusBarTexture(castPath)
                end
            else
                local castPath
                if data.unint then
                    castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarUninterruptibleTexture or texKeys.castbarStatusBarTexture)
                else
                    castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
                end
                frame.CastBar:SetStatusBarTexture(castPath)
            end
        else
            frame.CastBar.fadeOut = nil
            frame.CastBar:Hide()
            frame.CastBar:SetAlpha(0)
            if frame.CastBar.ArenaTargetText then
                frame.CastBar.ArenaTargetText:Hide()
                frame.CastBar.ArenaTargetText:SetText("")
            end
        end

        if isTBC then
            frame.CastBar.Spark:Hide()
        end

        frame.hideStatusText = false

        local playerHpMax = UnitHealthMax("player")
        local playerPpMax = UnitPowerMax("player")

        local hpPercent = 100
        if i == 2 then
            hpPercent = 75
        elseif i == 3 then
            hpPercent = 45
        end

        local testHp = math.floor((playerHpMax * hpPercent) / 100)

        if (db.profile.statusText.usePercentage) then
            frame.HealthText:SetText(hpPercent .. "%")
            frame.PowerText:SetText("100%")
        else
            if db.profile.statusText.formatNumbers then
                frame.HealthText:SetText(AbbreviateNumbers(testHp))
                frame.PowerText:SetText(AbbreviateNumbers(playerPpMax))
            else
                frame.HealthText:SetText(AbbreviateLargeNumbers(testHp))
                frame.PowerText:SetText(AbbreviateLargeNumbers(playerPpMax))
            end
        end

        frame:UpdateStatusTextVisible()

        if self.masqueOn and not db.profile.enableMasque and frame.FrameMsq then
            frame.FrameMsq:Hide()
            frame.ClassIconMsq:Hide()
            frame.SpecIconMsq:Hide()
            frame.CastBarMsq:Hide()
            if frame.CastBar.MSQ then
                frame.CastBar.MSQ:Hide()
                frame.CastBar.Icon:Show()
            end
            frame.TrinketMsq:Hide()
            frame.RacialMsq:Hide()
            frame.DispelMsq:Hide()
            frame.masqueHidden = true
        end
    end

    local arenaTargetsOnPartyOn = widgetSettings.partyTargetIndicators
        and widgetSettings.partyTargetIndicators.enabled
        and widgetSettings.partyTargetIndicators.arenaOnParty
        and widgetSettings.partyTargetIndicators.arenaOnParty.enabled
    if arenaTargetsOnPartyOn then
        local aop = widgetSettings.partyTargetIndicators.arenaOnParty
        local arenaDirection = aop.direction or "LEFT"
        local arenaSpacing = aop.spacing or 1
        local arenaScale = aop.scale or 1
        local aopPosX = aop.posX or 0
        local aopPosY = aop.posY or 0
        local classColors = {}
        for _, color in pairs(RAID_CLASS_COLORS) do
            table.insert(classColors, color)
        end

        for i = 1, 5 do
            local partyFrame = self:GetPartyFrame(i)
            if partyFrame then
                self:CreatePartyFrameIndicators(partyFrame)
                self:RepositionPartyFrameIndicators(partyFrame, arenaDirection, arenaSpacing, aopPosX, aopPosY)
                for j = 1, self.maxArenaOpponents do
                    local indicator = partyFrame.WidgetOverlay["arenaTarget" .. j]
                    indicator:SetScale(arenaScale)
                    local c = classColors[math.random(#classColors)]
                    indicator.Texture:SetVertexColor(c.r, c.g, c.b)
                    indicator:Show()
                    indicator:SetAlpha(1)
                end
            end
        end
    else
        for i = 1, 5 do
            local partyFrame = self:GetPartyFrame(i)
            if partyFrame and partyFrame.WidgetOverlay then
                for j = 1, self.maxArenaOpponents do
                    partyFrame.WidgetOverlay["arenaTarget" .. j]:Hide()
                end
            end
        end
    end

    if not self.TestTitle then
        local f = CreateFrame("Frame")
        self.TestTitle = f
        self.TestTitle:EnableMouse(true)

        local t = f:CreateFontString(nil, "OVERLAY")
        t:SetFontObject("GameFontHighlightLarge")
        t:SetFont(self.pFont, 12, "OUTLINE")
        t:SetText("|T132961:16|t "..L["Drag_Hint"])
        t:SetPoint("BOTTOM", topFrame, "TOP", 17, 17)

        local bg = f:CreateTexture(nil, "BACKGROUND", nil, -1)
        bg:SetPoint("TOPLEFT", t, "TOPLEFT", -6, 4)
        bg:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 6, -3)
        bg:SetAtlas("PetList-ButtonBackground")

        local t2 = f:CreateFontString(nil, "OVERLAY")
        t2:SetFontObject("GameFontHighlightLarge")
        t2:SetFont(self.pFont, 21, "OUTLINE")
        t2:SetText("sArena |cffff8000Reloaded|r |T135884:13:13|t")
        t2:SetPoint("BOTTOM", t, "TOP", 3, 5)

        self.TestTitle:SetPoint("TOPLEFT", t, "TOPLEFT", -5, 45)
        self.TestTitle:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 5, -5)
        self.TestTitle:SetScript("OnMouseUp", function(frame, button)
            if button == "RightButton" then
                if frame:GetAlpha() > 0 then
                    frame:SetAlpha(0)
                else
                    frame:SetAlpha(1)
                end
            end
        end)

        self.TestTitle:SetScript("OnHide", function(frame)
            self.testMode = nil
            for i = 1, 5 do
                local partyFrame = self:GetPartyFrame(i)
                if partyFrame and partyFrame.WidgetOverlay then
                    for j = 1, self.maxArenaOpponents do
                        local indicator = partyFrame.WidgetOverlay["arenaTarget" .. j]
                        indicator:Hide()
                        indicator:SetAlpha(0)
                    end
                end
            end
        end)

        self:SetupDrag(self.TestTitle, self, nil, "UpdateFrameSettings")
    end

    self.TestTitle:Show()

    self:UpdateTextures()

    if self.masqueOn then
        self:RefreshMasque()
        for i = 1, self.maxArenaOpponents do
            local frame = self["arena" .. i]
            for n = 1, 5 do
                local drFrame = frame[self.drCategories[n]]
                if drFrame and drFrame.__MSQ_New_Normal then
                    drFrame.__MSQ_New_Normal:SetDesaturated(true)
                    drFrame.__MSQ_New_Normal:SetVertexColor(0, 1, 0, 1)
                end
            end
        end
    end

    local testCount = self.testUnits or self.maxArenaOpponents
    if testCount < self.maxArenaOpponents then
        for i = testCount + 1, self.maxArenaOpponents do
            local frame = self["arena" .. i]
            if frame then
                frame:Hide()
            end
        end
    end
end