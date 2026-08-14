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

local function StyleCooldown(frame, cooldown)
    local parent = frame.parent
    local profile = GetProfile(frame)
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

    parent:CreateCustomCooldown(cooldown, profile and profile.showDecimalsClassIcon)

    local font = parent:GetAuraCooldownFont()
    cooldown:SetCountdownFont(font:GetName())

    local text = cooldown:GetCountdownFontString()
    if text:GetFontObject() ~= font then
        text:SetFont(font:GetFont())
    end
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
    StyleCooldown(frame, cooldown)
    button:SetDurationCooldown(cooldown)
    button:EnableMouse(false)
    frame:CreateAuraSlotGlow(button, category)
    frame:CreateAuraSlotFramePulse(button, category)
end

local function NewContainer(frame, filter, sortKey, category)
    local container = CreateFrame("AuraContainer", nil, frame.ClassIcon, "CustomAuraContainerTemplate")
    container:SetAllPoints(frame.ClassIcon)
    container:SetUnit(frame.unit)
    container:SetEnabled(false)
    container:Hide()

    local sortMethod, sortDirection = GetSort(frame, sortKey)

    container.slot = container:AddAuraSlot("Aura", filter, {
        sortMethod = sortMethod,
        sortDirection = sortDirection,
        initializeFrame = function(button) InitIcon(frame, button, category) end,
    })

    container.sortKey = sortKey
    container.category = category
    return container
end

function sArenaFrameMixin:SetupAuraDisplay()
    self.AuraCC = NewContainer(self, "HARMFUL|CROWD_CONTROL", "ccSort", "cc")
    self.AuraImportant = NewContainer(self, "HELPFUL|IMPORTANT|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE", "importantSort", "important")
    self.AuraBigDef = NewContainer(self, "HELPFUL|BIG_DEFENSIVE", "defensiveSort", "defensive")
    self.AuraExtDef = NewContainer(self, "HELPFUL|EXTERNAL_DEFENSIVE", "defensiveSort", "defensive")

    self.auraContainers = { self.AuraCC, self.AuraImportant, self.AuraBigDef, self.AuraExtDef }

    local classIcon = self.ClassIcon
    local strata = classIcon:GetFrameStrata()
    local level = classIcon:GetFrameLevel()

    local order = { self.AuraExtDef, self.AuraBigDef, self.AuraImportant, self.AuraCC }
    for index, container in ipairs(order) do
        container:SetFrameStrata(strata)
        container:SetFrameLevel(level + index)
    end

    self:UpdateAuraSlotState()
end

function sArenaFrameMixin:UpdateAuraSlotState()
    if not self.auraContainers then return end

    local profile = GetProfile(self)
    local hideIcon = profile and (profile.disableAurasOnClassIcon or profile.hideClassIcon)

    local active = self.parent and self.parent.engagedInMatch
        and not self.disabledAuras
        and not hideIcon

    local onlyCC = profile and profile.onlyShowCCAuras

    for _, container in ipairs(self.auraContainers) do
        local wanted = active and (not onlyCC or container == self.AuraCC)
        container:SetEnabled(wanted and true or false)
        container:SetShown(wanted and true or false)
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
