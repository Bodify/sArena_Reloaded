-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local RANGE_INTERVAL = 0.05
local rangeElapsed = 0

local noEarlyFrames = sArenaMixin.isTBC or sArenaMixin.isWrath
local stealthCheck = noEarlyFrames and UnitExists or UnitIsVisible

local function IsSpellInRange(spellID, unit)
    if IsSpellKnownOrOverridesKnown(spellID) or (UnitExists("pet") and IsSpellKnownOrOverridesKnown(spellID, true)) then
        return C_Spell.IsSpellInRange(spellID, unit)
    end
    -- If the spell isnt known always show as in range
    -- for it not to display as if out of range forever
    return true, true
end

function sArenaMixin:RegisterRangeCheckEvents()
    local rc = self.db and self.db.profile.rangeCheck
    if rc and rc.enabled then
        self:UpdateRangeSettings()
        if not self.rangeCheckUpdate then
            self.rangeCheckUpdate = CreateFrame("Frame")
        end
        self.rangeCheckUpdate:SetScript("OnUpdate", function(_, elapsed)
            rangeElapsed = rangeElapsed + elapsed
            if rangeElapsed >= RANGE_INTERVAL then
                rangeElapsed = 0
                self:UpdateAllRangeChecks()
            end
        end)
    end
end

function sArenaMixin:UnregisterRangeCheckEvents()
    if self.rangeCheckUpdate then
        self.rangeCheckUpdate:SetScript("OnUpdate", nil)
    end
end

function sArenaMixin:GetRangeCheckAtlas(ri, isNotInRange)
    if isNotInRange then
        local atlas = ri.notInRangeAtlas or "communities-icon-searchmagnifyingglass"
        if atlas == "custom" then
            return ri.notInRangeCustomAtlas or ""
        end
        return atlas
    else
        local atlas = ri.inRangeAtlas or ""
        if atlas == "custom" then
            return ri.inRangeCustomAtlas or ""
        end
        return atlas
    end
end

function sArenaMixin:UpdateRangeSettings()
    local ri = self.db and self.db.profile.rangeCheck
    if not ri then return end

    local mode = ri.mode or "transparency"
    self.rangeMode = mode
    self.rangeUseIcon = (mode == "icon" or mode == "both")
    self.rangeUseAlpha = (mode == "transparency" or mode == "both")
    self.rangeNotInRangeAlpha = ri.notInRangeAlpha or 0.4

    self:UpdatePlayerRangeSpell()
    self:ApplyRangeCheckTextures()
end

function sArenaMixin:UpdatePlayerRangeSpell()
    local db = self.db and self.db.profile
    if not db then return end

    local specKey = self.playerSpecID or 0
    local perSpec = db.rangeCheckSpellsPerSpec or {}
    self.rangeSpell = perSpec[specKey] or self.defaultRangeSpellsPerSpec[specKey]
end

function sArenaMixin:CreateRangeCheckFrames()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local inRangeIcon = frame.WidgetOverlay.inRangeIcon
        local notInRangeIcon = frame.WidgetOverlay.notInRangeIcon
        inRangeIcon:SetIgnoreParentAlpha(true)
        notInRangeIcon:SetIgnoreParentAlpha(true)
    end
end

function sArenaMixin:ApplyRangeCheckTextures()
    local ri = self.db and self.db.profile.rangeCheck
    if not ri then return end

    local outAtlas = self:GetRangeCheckAtlas(ri, true)
    local inAtlas = self:GetRangeCheckAtlas(ri, false)

    local outScale = ri.notInRangeScale or 1
    local inScale = ri.inRangeScale or 1
    local baseSize = 24

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local outIcon = frame.WidgetOverlay.notInRangeIcon
        if outAtlas and outAtlas ~= "" then
            if tonumber(outAtlas) then
                outIcon.Texture:SetTexture(tonumber(outAtlas))
            else
                outIcon.Texture:SetAtlas(outAtlas)
            end
            if ri.notInRangeColorEnabled and ri.notInRangeColor then
                local c = ri.notInRangeColor
                outIcon.Texture:SetDesaturated(true)
                outIcon.Texture:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
            else
                outIcon.Texture:SetDesaturated(false)
                outIcon.Texture:SetVertexColor(1, 1, 1, 1)
            end
            outIcon:SetSize(baseSize * outScale, baseSize * outScale)
            outIcon.hasAtlas = true
        else
            outIcon.hasAtlas = false
        end

        local inIcon = frame.WidgetOverlay.inRangeIcon
        if inAtlas and inAtlas ~= "" then
            if tonumber(inAtlas) then
                inIcon.Texture:SetTexture(tonumber(inAtlas))
            else
                inIcon.Texture:SetAtlas(inAtlas)
            end
            if ri.inRangeColorEnabled and ri.inRangeColor then
                local c = ri.inRangeColor
                inIcon.Texture:SetDesaturated(true)
                inIcon.Texture:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
            else
                inIcon.Texture:SetDesaturated(false)
                inIcon.Texture:SetVertexColor(1, 1, 1, 1)
            end
            inIcon:SetSize(baseSize * inScale, baseSize * inScale)
            inIcon.hasAtlas = true
        else
            inIcon.hasAtlas = false
        end

        outIcon:ClearAllPoints()
        outIcon:SetPoint("CENTER", frame.HealthBar, "CENTER", ri.notInRangePosX or 0, ri.notInRangePosY or 0)

        inIcon:ClearAllPoints()
        inIcon:SetPoint("CENTER", frame.HealthBar, "CENTER", ri.inRangePosX or 0, ri.inRangePosY or 0)
    end
end

function sArenaMixin:ResetRangeChecks()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame.WidgetOverlay.inRangeIcon:Hide()
        frame.WidgetOverlay.notInRangeIcon:Hide()
        frame.notInRange = nil
        frame:SetAlpha(1)
    end
end



function sArenaMixin:UpdateAllRangeChecks()
    local spellID = self.rangeSpell
    if not spellID then return end

    local useIcon = self.rangeUseIcon
    local useAlpha = self.rangeUseAlpha

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame:IsShown() then
            frame:UpdateRangeCheck(frame.unit, spellID, useIcon, useAlpha)
        end
    end
end

function sArenaFrameMixin:UpdateRangeCheck(unit, spellID, useIcon, useAlpha)
    if not spellID then spellID = self.parent.rangeSpell end
    if not spellID then return end
    if not useIcon and not useAlpha then
        useIcon = self.parent.rangeUseIcon
        useAlpha = self.parent.rangeUseAlpha
    end

    local inRangeIcon = self.WidgetOverlay.inRangeIcon
    local notInRangeIcon = self.WidgetOverlay.notInRangeIcon

    if not unit or not UnitExists(unit) then
        inRangeIcon:Hide()
        notInRangeIcon:Hide()
        self.notInRange = nil
        return
    end

    local inRange, spellNotKnown = IsSpellInRange(spellID, unit)
    self.notInRange = not inRange

    if useIcon then
        if self.notInRange then
            inRangeIcon:Hide()
            if notInRangeIcon.hasAtlas then
                notInRangeIcon:SetShown(not spellNotKnown)
            else
                notInRangeIcon:Hide()
            end
        else
            notInRangeIcon:Hide()
            if inRangeIcon.hasAtlas then
                inRangeIcon:SetShown(not spellNotKnown)
            else
                inRangeIcon:Hide()
            end
        end
    else
        inRangeIcon:Hide()
        notInRangeIcon:Hide()
    end

    if useAlpha then
        self:ApplyRangeAlpha()
    end
end

function sArenaFrameMixin:ApplyRangeAlpha()
    local parent = self.parent
    local notInRangeAlpha = parent.rangeNotInRangeAlpha
    local stealthAlpha = parent.stealthAlpha
    local unit = self.unit

    if unit and not stealthCheck(unit) then
        self:SetAlpha(math.min(stealthAlpha, notInRangeAlpha))
    elseif self.notInRange then
        self:SetAlpha(notInRangeAlpha)
    else
        self:SetAlpha(1)
    end
end
