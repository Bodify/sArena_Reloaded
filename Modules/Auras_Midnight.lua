-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

-- Huge thanks to Verz and Muleyo.
-- Verz for helping with this in the past and many other things and
-- Muleyo for helping me with questions and examples about the new aura systems in 12.1

local SORT_METHODS = {
    last         = { AuraContainerSortMethod.AuraInstanceIDOnly, AuraContainerSortDirection.Reverse },
    blizzDefault = { AuraContainerSortMethod.Default,            AuraContainerSortDirection.Normal },
    lastending   = { AuraContainerSortMethod.ExpirationOnly,     AuraContainerSortDirection.Reverse },
    firstending  = { AuraContainerSortMethod.ExpirationOnly,     AuraContainerSortDirection.Normal },
}

local DEFAULT_SORT = { AuraContainerSortMethod.AuraInstanceIDOnly, AuraContainerSortDirection.Normal }
local AURA_CATEGORIES = { "cc", "important", "defensive" }
local otherCC = sArenaMixin.otherCC
local otherDebuffs = sArenaMixin.otherDebuffs
local ccBlacklist = sArenaMixin.ccBlacklist
local interruptList = sArenaMixin.interruptList
local specInterrupts = sArenaMixin.specInterrupts
local classInterrupts = sArenaMixin.classInterrupts
local GetSpellTexture = C_Spell.GetSpellTexture

local defaultInterruptTexture = 132219
local defaultInterruptDuration = 3
local defaultInterruptWindow = 0.1

local CastStartEvents = {
    UNIT_SPELLCAST_START         = true,
    UNIT_SPELLCAST_CHANNEL_START = true,
    UNIT_SPELLCAST_EMPOWER_START = true,
}

local CastStopEvents = {
    UNIT_SPELLCAST_INTERRUPTED   = true,
    UNIT_SPELLCAST_CHANNEL_STOP  = true,
    UNIT_SPELLCAST_EMPOWER_STOP  = true,
}

local function GetProfile(frame)
    return frame.parent and frame.parent.db and frame.parent.db.profile
end

local function GetSort(frame, sortKey)
    local profile = GetProfile(frame)
    local sort = profile and SORT_METHODS[profile[sortKey]] or DEFAULT_SORT
    return sort[1], sort[2]
end

local LAYOUT_COOLDOWN = {
    BlizzCompact = { swipe = [[Interface\AddOns\sArena_Reloaded\Textures\talentsmasknodechoiceflyout]], circular = true },
    BlizzRetail  = { swipe = [[Interface\CharacterFrame\TempPortraitAlphaMask]], circular = true, edge = [[Interface\Cooldown\edge]] },
    BlizzArena   = { swipe = [[Interface\CharacterFrame\TempPortraitAlphaMask]], circular = true },
    BlizzTarget  = { swipe = [[Interface\CharacterFrame\TempPortraitAlphaMask]], circular = true },
    BlizzTourney = { swipe = [[Interface\CharacterFrame\TempPortraitAlphaMask]], circular = true },
}

local function StyleCooldown(frame, cooldown, icon)
    local parent = frame.parent
    local profile = GetProfile(frame)
    local layoutSettings = profile and profile.layoutSettings and profile.layoutSettings[profile.currentLayout]
    local cropIcons = layoutSettings and layoutSettings.cropIcons or false
    local look = profile and LAYOUT_COOLDOWN[profile.currentLayout]

    cooldown:SetSwipeTexture(look and look.swipe or 1)
    cooldown:SetUseCircularEdge(look and look.circular or false)

    if look and look.edge then
        cooldown:SetEdgeTexture(look.edge)
    end

    local color = profile and profile.cooldownSwipeColor or { 0, 0, 0, 0.55 }
    cooldown:SetSwipeColor(color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 0.55)

    local classIconCooldown = frame.ClassIcon.Cooldown
    cooldown:SetReverse(classIconCooldown:GetReverse())
    cooldown:SetDrawSwipe(classIconCooldown:GetDrawSwipe())
    cooldown:SetDrawEdge(classIconCooldown:GetDrawEdge())
    cooldown:SetDrawBling(false)
    frame:SetTextureCrop(icon, cropIcons, "class")

    parent:UpdateCooldownThresholds(cooldown, profile and profile.showDecimalsClassIcon)

    local font = parent:GetAuraCooldownFont()
    cooldown:SetCountdownFont(font:GetName())

    local text = cooldown:GetCountdownFontString()
    if text:GetFontObject() ~= font then
        text:SetFont(font:GetFont())
    end
end

local function AppendSignature(parts, ...)
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring((select(i, ...)))
    end
end

local function AuraSlotSignature(frame)
    local profile = GetProfile(frame)
    if not profile then return end

    local layoutSettings = profile.layoutSettings and profile.layoutSettings[profile.currentLayout]
    local swipe = profile.cooldownSwipeColor or { 0, 0, 0, 0.55 }
    local cooldown = frame.ClassIcon.Cooldown
    local ah = profile.auraHighlight or {}
    local glow = ah.glowClassIcon or {}
    local pixel = ah.pixelClassIcon or {}
    local pulse = ah.framePulse or {}

    local parts = {}

    AppendSignature(parts, profile.currentLayout, layoutSettings and layoutSettings.cropIcons)
    AppendSignature(parts, swipe[1], swipe[2], swipe[3], swipe[4])
    AppendSignature(parts, cooldown:GetReverse(), cooldown:GetDrawSwipe(), cooldown:GetDrawEdge())
    AppendSignature(parts, profile.showDecimalsClassIcon)
    AppendSignature(parts, ah.enabled, glow.enabled, pixel.enabled)
    AppendSignature(parts, pulse.enabled, pulse.wrapTrinket, pulse.wrapRacial)
    AppendSignature(parts, pulse.size, pulse.minAlpha, pulse.maxAlpha, pulse.speed)

    for _, category in ipairs(AURA_CATEGORIES) do
        local settings = ah[category] or {}
        local color = settings.color or {}
        AppendSignature(parts, settings.enabled, color[1], color[2], color[3], color[4])
    end

    return table.concat(parts, ":")
end

local function InitIcon(frame, button, category)
    button:SetAllPoints(frame.ClassIcon)

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(button)
    button:SetIcon(icon)

    if frame.auraSlotMask then
        icon:AddMaskTexture(frame.auraSlotMask)
    end

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints(button)
    cooldown:SetUsingParentLevel(true)
    StyleCooldown(frame, cooldown, icon)
    button:SetDurationCooldown(cooldown)
    button:EnableMouse(false)

    if category then
        frame:CreateAuraSlotGlow(button, category)
        frame:CreateAuraSlotFramePulse(button, category)
    end
end

local function CanFilterHarmfulSpellIDs(unit)
    if not unit or not UnitExists(unit) then return false end
    return not UnitCanAssist("player", unit, true, true)
end

local function NewContainer(frame, filter, sortKey, category, candidateFilters)
    local container = CreateFrame("AuraContainer", nil, frame.ClassIcon, "CustomAuraContainerTemplate")
    container:SetAllPoints(frame.ClassIcon)
    container:SetUnit(frame.unit)
    container:SetEnabled(false)
    container:Hide()

    local sortMethod, sortDirection = GetSort(frame, sortKey)

    container.slot = container:AddAuraSlot("Aura", filter, {
        sortMethod = sortMethod,
        sortDirection = sortDirection,
        candidateFilters = candidateFilters,
        initializeFrame = function(button) InitIcon(frame, button, category) end,
    })

    container.sortKey = sortKey
    container.category = category
    container.needsHarmfulSpellIDs = (candidateFilters and candidateFilters.includeSpellIDs) and true or false
    return container
end

local function NewInterruptSlot(frame)
    local slot = CreateFrame("Frame", nil, frame.ClassIcon)
    slot:SetAllPoints(frame.ClassIcon)
    slot:Hide()

    local icon = slot:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(slot)
    if frame.auraSlotMask then
        icon:AddMaskTexture(frame.auraSlotMask)
    end

    local cooldown = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
    cooldown:SetAllPoints(slot)
    cooldown:SetUsingParentLevel(true)
    StyleCooldown(frame, cooldown, icon)

    frame:CreateAuraSlotGlow(slot, "cc")
    frame:CreateAuraSlotFramePulse(slot, "cc")

    slot.Icon = icon
    slot.Cooldown = cooldown
    return slot
end

local function ApplyContainerLayering(frame)
    local classIcon = frame.ClassIcon
    local strata = classIcon:GetFrameStrata()
    local level = classIcon:GetFrameLevel()

    local order = { frame.AuraOtherDebuffs, frame.AuraExtDef, frame.AuraBigDef, frame.AuraImportant, frame.AuraInterrupt, frame.AuraOtherCC, frame.AuraCC }
    for index, container in ipairs(order) do
        container:SetFrameStrata(strata)
        container:SetFrameLevel(level + index)
    end
end

function sArenaFrameMixin:SetupAuraDisplay()
    local signature = AuraSlotSignature(self)

    if self.auraContainers and signature == self.auraSlotSignature then
        ApplyContainerLayering(self)
        self:UpdateAuraSlotState()
        return
    end

    if self.auraContainers then
        for _, container in ipairs(self.auraContainers) do
            container:SetEnabled(false)
            container:Hide()
        end
    end

    if self.AuraInterrupt then
        self.AuraInterrupt:Hide()
    end

    self.auraSlotSignature = signature

    self.AuraCC = NewContainer(self, "HARMFUL|CROWD_CONTROL", "ccSort", "cc", { excludeSpellIDs = ccBlacklist })
    self.AuraOtherCC = NewContainer(self, "HARMFUL", "ccSort", "cc", { includeSpellIDs = otherCC })
    self.AuraInterrupt = NewInterruptSlot(self)
    self.AuraImportant = NewContainer(self, "HELPFUL|IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE", "importantSort", "important")
    self.AuraBigDef = NewContainer(self, "HELPFUL|BIG_DEFENSIVE", "defensiveSort", "defensive")
    self.AuraExtDef = NewContainer(self, "HELPFUL|EXTERNAL_DEFENSIVE", "defensiveSort", "defensive")
    self.AuraOtherDebuffs = NewContainer(self, "HARMFUL", "ccSort", nil, { includeSpellIDs = otherDebuffs })

    self.AuraCC.isCC = true
    self.AuraOtherCC.isCC = true

    self.auraContainers = { self.AuraCC, self.AuraOtherCC, self.AuraImportant, self.AuraBigDef, self.AuraExtDef, self.AuraOtherDebuffs }

    ApplyContainerLayering(self)
    self:UpdateAuraSlotState()
end

function sArenaFrameMixin:UpdateAuraSlotState()
    if not self.auraContainers then return end

    local profile = GetProfile(self)
    local hideIcon = profile and (profile.disableAurasOnClassIcon or profile.hideClassIcon)

    local active = self.parent and self.parent.engagedInMatch
        and not self.disabledAuras
        and not hideIcon
        and UnitExists(self.unit)

    local onlyCC = profile and profile.onlyShowCCAuras
    local harmfulIDsUsable = CanFilterHarmfulSpellIDs(self.unit)

    for _, container in ipairs(self.auraContainers) do
        local wanted = active and (not onlyCC or container.isCC) and (not container.needsHarmfulSpellIDs or harmfulIDsUsable)
        container:SetEnabled(wanted and true or false)
        container:SetShown(wanted and true or false)
    end

    self.interruptSlotWanted = active and true or false
    self:UpdateInterruptSlot()
end

function sArenaFrameMixin:SetInterrupt(texture, duration)
    if self.interruptTimer then
        self.interruptTimer:Cancel()
    end

    self.interruptTexture = texture
    self.interruptStart = GetTime()
    self.interruptDuration = duration
    self.interruptTimer = C_Timer.NewTimer(duration, function()
        self.interruptTimer = nil
        self.interruptTexture = nil
        self:UpdateInterruptSlot()
    end)

    self:UpdateInterruptSlot()
end

function sArenaFrameMixin:UpdateInterruptSlot()
    local slot = self.AuraInterrupt
    if not slot then return end

    if self.interruptTexture and self.interruptSlotWanted then
        slot.Icon:SetTexture(self.interruptTexture)
        slot.Cooldown:SetCooldown(self.interruptStart, self.interruptDuration)
        slot:Show()
    else
        slot.Cooldown:Clear()
        slot:Hide()
    end
end

local function GetLocalizedSpecs()
    local specs = {}
    local classFirst = GetLocale() == "esMX"
    local specInfo = C_SpecializationInfo
    local GetNumSpecs = specInfo and specInfo.GetNumSpecializationsForClassID or GetNumSpecializationsForClassID

    local classIDs = specInfo and specInfo.GetAllClassIDs and specInfo.GetAllClassIDs()
    if not classIDs then
        classIDs = {}
        for classID = 1, GetNumClasses() do
            classIDs[classID] = classID
        end
    end

    for _, classID in ipairs(classIDs) do
        local _, class = GetClassInfo(classID)
        local classMale = class and LOCALIZED_CLASS_NAMES_MALE[class]
        local classFemale = class and LOCALIZED_CLASS_NAMES_FEMALE[class]

        for specIndex = 1, GetNumSpecs(classID) do
            local specID, specMale = GetSpecializationInfoForClassID(classID, specIndex)
            local _, specFemale = GetSpecializationInfoForClassID(classID, specIndex, 3)

            for _, specName in pairs({ specMale, specFemale }) do
                for _, className in pairs({ classMale, classFemale }) do
                    if classFirst then
                        specs[className .. " " .. specName] = specID
                    else
                        specs[specName .. " " .. className] = specID
                    end
                end
            end
        end
    end

    return specs
end

local tooltipSpecs
local specCache = {}

local function GetPartySpec(unit)
    local guid = UnitGUID(unit)
    local canCache = guid and not issecretvalue(guid)
    if canCache and specCache[guid] then
        return specCache[guid]
    end

    local tooltipData = C_TooltipInfo.GetUnit(unit)
    if not (tooltipData and tooltipData.lines) then return end

    tooltipSpecs = tooltipSpecs or GetLocalizedSpecs()

    for _, line in ipairs(tooltipData.lines) do
        local text = line.leftText
        if line.type == Enum.TooltipDataLineType.None and text and not issecretvalue(text) then
            local id = tooltipSpecs[text]
            if id then
                if canCache then
                    specCache[guid] = id
                end
                return id
            end
        end
    end
end

local function GetPartyInterrupt(unit)
    local specID = GetPartySpec(unit)
    if specID and specInterrupts[specID] ~= nil then
        return specInterrupts[specID]
    end

    local class = UnitClassBase(unit)
    return class and classInterrupts[class]
end

local function GuessAllyInterrupt()
    local onlyInterrupt
    local count = 0

    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local interrupt = GetPartyInterrupt(unit)
            if interrupt then
                count = count + 1
                onlyInterrupt = interrupt
            end
        end
    end

    if count == 1 then
        return GetSpellTexture(onlyInterrupt) or defaultInterruptTexture, interruptList[onlyInterrupt] or defaultInterruptDuration
    end

    return defaultInterruptTexture, defaultInterruptDuration
end

function sArenaMixin:GetInterruptGuess()
    local last = self.lastPlayerInterrupt
    if last.texture and GetTime() - last.time <= last.window then
        return last.texture, last.duration
    end
    return GuessAllyInterrupt()
end

function sArenaFrameMixin:CreateInterruptWatcher()
    if self.interruptWatcher then return end

    local watcher = CreateFrame("Frame")
    for event in pairs(CastStartEvents) do
        watcher:RegisterUnitEvent(event, self.unit)
    end
    for event in pairs(CastStopEvents) do
        watcher:RegisterUnitEvent(event, self.unit)
    end

    watcher:SetScript("OnEvent", function(_, event, _, _, _, arg4, arg5)
        if CastStartEvents[event] then
            self.interruptCounted = nil
            return
        end

        local interruptedBy
        if event == "UNIT_SPELLCAST_EMPOWER_STOP" then
            interruptedBy = arg5
        else
            interruptedBy = arg4
        end

        if not interruptedBy or self.interruptCounted then return end
        self.interruptCounted = true

        C_Timer.After(0, function()
            self:SetInterrupt(self.parent:GetInterruptGuess())
        end)
    end)

    self.interruptWatcher = watcher
end

function sArenaMixin:SetupInterruptAuras()
    if self.playerInterruptTracker then return end

    self.lastPlayerInterrupt = { time = -math.huge }

    local playerInterruptTracker = CreateFrame("Frame")
    playerInterruptTracker:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet")
    playerInterruptTracker:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    playerInterruptTracker:RegisterEvent("PLAYER_ENTERING_WORLD")
    playerInterruptTracker:SetScript("OnEvent", function(_, event, _, _, spellID)
        if event ~= "UNIT_SPELLCAST_SUCCEEDED" then
            wipe(specCache)
            return
        end

        if issecretvalue(spellID) then return end

        local duration = interruptList[spellID]
        if not duration or duration == 0 then return end

        local last = self.lastPlayerInterrupt
        last.texture = GetSpellTexture(spellID)
        last.duration = duration
        last.window = defaultInterruptWindow
        last.time = GetTime()
    end)
    self.playerInterruptTracker = playerInterruptTracker

    for i = 1, self.maxArenaOpponents do
        self["arena" .. i]:CreateInterruptWatcher()
    end
end

function sArenaMixin:RefreshAuraDisplays()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        if frame and frame.SetupAuraDisplay then
            frame:SetupAuraDisplay()
        end
    end
end

function sArenaMixin:UpdateAuraSortSettings()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        if frame and frame.auraContainers then
            for _, container in ipairs(frame.auraContainers) do
                local sortMethod, sortDirection = GetSort(frame, container.sortKey)
                container:SetAuraSlotSortMethod("Aura", sortMethod, sortDirection)
            end
        end
    end
end

function sArenaFrameMixin:FindAura()
    if not self.auraContainers then
        self:SetupAuraDisplay()
    end

    if self.auraContainers then
        self:UpdateAuraSlotState()

        for _, container in ipairs(self.auraContainers) do
            if container:IsShown() then
                container:UpdateAllAuras()
            end
        end
    end

    self:UpdateClassIcon()
end

function sArenaFrameMixin:UpdateAuraStacks()
    self.AuraStacks:SetText("")
end
