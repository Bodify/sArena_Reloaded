-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local LCG = LibStub("LibCustomGlow-1.0", true)

local defaultHighlightTexture = "Interface\\AddOns\\sArena_Reloaded\\Textures\\newplayertutorial-drag-slotgreen.tga"
local defaultTextureMultiplier  = 1.19

local layoutSpecificGlowSettings = {
    BlizzRaid = {
        mult    = 0.75,
        texture = defaultHighlightTexture,
    },
    Pixelated = {
        mult    = 1.23,
        texture = defaultHighlightTexture,
    },
    BlizzArena = {
        mult    = 0.35,
        texture = "charactercreate-ring-select",
    },
    BlizzTarget = {
        mult    = 0.25,
        texture = "charactercreate-ring-select",
    },
    BlizzTourney = {
        mult    = 0.25,
        texture = "charactercreate-ring-select",
    },
    BlizzRetail = {
        mult    = 0.3,
        texture = "charactercreate-ring-select",
    },
}

local function GetGlowSettings(layoutName)
    local o = layoutName and layoutSpecificGlowSettings[layoutName]
    if o then
        return o.mult or defaultTextureMultiplier,
               o.texture or defaultHighlightTexture,
               true
    end
    return defaultTextureMultiplier, defaultHighlightTexture
end

function sArenaFrameMixin:CreateAuraHighlight()
    if self.AuraHighlights then return end

    local classIcon = self.ClassIcon

    local highlight = CreateFrame("Frame", nil, self)
    highlight:SetFrameStrata("MEDIUM")
    highlight:SetFrameLevel(49)
    self.AuraHighlights = highlight

    local classIconGlow = CreateFrame("Frame", nil, highlight)
    classIconGlow:SetFrameStrata("MEDIUM")
    classIconGlow:SetFrameLevel(49)
    classIconGlow:Hide()

    local tex = classIconGlow:CreateTexture(nil, "OVERLAY", nil, 6)
    tex:SetTexture(defaultHighlightTexture)
    tex:SetAllPoints(classIconGlow)
    tex:SetDesaturated(true)
    classIconGlow.Texture = tex
    highlight.ClassIconGlow = classIconGlow

    local classIconPixelGlow = CreateFrame("Frame", nil, highlight)
    classIconPixelGlow:SetFrameStrata("MEDIUM")
    classIconPixelGlow:SetFrameLevel(48)
    classIconPixelGlow:SetAllPoints(classIcon)
    highlight.ClassIconPixelGlow = classIconPixelGlow

    local framePixelGlow = CreateFrame("Frame", nil, self)
    framePixelGlow:SetFrameStrata("MEDIUM")
    framePixelGlow:SetFrameLevel(48)
    framePixelGlow:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT", 0, 0)
    framePixelGlow:SetPoint("BOTTOMRIGHT", self.PowerBar, "BOTTOMRIGHT", 0, 0)
    highlight.FramePixelGlow = framePixelGlow
end

function sArenaFrameMixin:UpdateFramePixelGlowAnchors(wrapClass, wrapTrinket, wrapRacial)
    local highlight = self.AuraHighlights
    if not highlight then return end
    local framePixelGlow = highlight.FramePixelGlow

    if not wrapClass and not wrapTrinket and not wrapRacial then
        framePixelGlow:ClearAllPoints()
        framePixelGlow:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT", 0, 0)
        framePixelGlow:SetPoint("BOTTOMRIGHT", self.PowerBar, "BOTTOMRIGHT", 0, 0)
        return
    end

    local allFrames = { self.HealthBar, self.PowerBar }
    if wrapClass and self.ClassIcon then
        allFrames[#allFrames + 1] = self.ClassIcon
    end
    if wrapTrinket and self.Trinket then
        allFrames[#allFrames + 1] = self.Trinket
    end
    if wrapRacial and self.Racial then
        allFrames[#allFrames + 1] = self.Racial
    end

    local minLeft, maxTop, maxRight, minBottom
    local minLeftFrame, maxTopFrame, maxRightFrame, minBottomFrame

    for _, frame in ipairs(allFrames) do
        local left   = frame and frame.GetLeft   and frame:GetLeft()
        local right  = frame and frame.GetRight  and frame:GetRight()
        local top    = frame and frame.GetTop    and frame:GetTop()
        local bottom = frame and frame.GetBottom and frame:GetBottom()
        local scale  = frame and frame.GetEffectiveScale and frame:GetEffectiveScale() or 1

        if left and right and top and bottom then
            left   = left   * scale
            right  = right  * scale
            top    = top    * scale
            bottom = bottom * scale

            if not minLeft   or left   < minLeft   then minLeft   = left;   minLeftFrame   = frame end
            if not maxTop    or top    > maxTop    then maxTop    = top;    maxTopFrame    = frame end
            if not maxRight  or right  > maxRight  then maxRight  = right;  maxRightFrame  = frame end
            if not minBottom or bottom < minBottom then minBottom = bottom; minBottomFrame = frame end
        end
    end

    if not minLeftFrame or not maxTopFrame or not maxRightFrame or not minBottomFrame then
        framePixelGlow:ClearAllPoints()
        framePixelGlow:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT", 0, 0)
        framePixelGlow:SetPoint("BOTTOMRIGHT", self.PowerBar, "BOTTOMRIGHT", 0, 0)
        return
    end

    framePixelGlow:ClearAllPoints()
    framePixelGlow:SetPoint("LEFT",   minLeftFrame,   "LEFT",   0, 0)
    framePixelGlow:SetPoint("RIGHT",  maxRightFrame,  "RIGHT",  0, 0)
    framePixelGlow:SetPoint("TOP",    maxTopFrame,    "TOP",    0, 0)
    framePixelGlow:SetPoint("BOTTOM", minBottomFrame, "BOTTOM", 0, 0)
end

function sArenaFrameMixin:UpdateAuraHighlightLayout()
    local highlight = self.AuraHighlights
    if not highlight then return end

    local classIcon = self.ClassIcon
    local w, h = classIcon:GetSize()

    local layoutName = self.parent and self.parent.db
        and self.parent.db.profile and self.parent.db.profile.currentLayout
    local mult, texture, useAtlas = GetGlowSettings(layoutName)

    local widthOffset  = w * mult
    local heightOffset = h * mult

    local glow = highlight.ClassIconGlow
    if useAtlas then
        glow.Texture:SetAtlas(texture)
    else
        glow.Texture:SetTexture(texture)
    end
    glow:ClearAllPoints()
    glow:SetPoint("TOPLEFT", classIcon, "TOPLEFT", -widthOffset, heightOffset)
    glow:SetPoint("BOTTOMRIGHT", classIcon, "BOTTOMRIGHT", widthOffset, -heightOffset)

    local ah = self.parent and self.parent.db and self.parent.db.profile.auraHighlight
    local pb = ah and ah.pixelBorder
    self:UpdateFramePixelGlowAnchors(
        pb and pb.wrapClass,
        pb and pb.wrapTrinket,
        pb and pb.wrapRacial
    )
end

local function BuildCategoryConfig(ah, category)
    local cc = ah[category]
    if not (cc and cc.enabled) then return nil end
    local pb, pi = ah.pixelBorder, ah.pixelClassIcon
    return {
        color         = cc.color,
        glowIcon      = ah.glowClassIcon.enabled and true or false,
        pbEnabled     = pb.enabled and true or false,
        pbLines       = pb.lines,
        pbFreq        = pb.frequency,
        pbLen         = pb.length,
        pbThick       = pb.thickness,
        pbWrapClass   = pb.wrapClass and true or false,
        pbWrapTrinket = pb.wrapTrinket and true or false,
        pbWrapRacial  = pb.wrapRacial and true or false,
        piEnabled     = pi.enabled and true or false,
        piLines       = pi.lines,
        piFreq        = pi.frequency,
        piLen         = pi.length,
        piThick       = pi.thickness,
    }
end

function sArenaFrameMixin:ApplyAuraHighlight(category)
    local highlight = self.AuraHighlights
    if not highlight then return end
    local cfg = category and highlight.cfg and highlight.cfg[category]

    local db = self.parent and self.parent.db
    local hideClassIcon = db and db.profile and db.profile.hideClassIcon

    local classGlow = highlight.ClassIconGlow
    if cfg and cfg.glowIcon and not hideClassIcon then
        local c = cfg.color
        classGlow.Texture:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        classGlow:Show()
    else
        classGlow:Hide()
    end

    LCG.PixelGlow_Stop(highlight.FramePixelGlow)
    if cfg and cfg.pbEnabled then
        LCG.PixelGlow_Start(highlight.FramePixelGlow, cfg.color,
            cfg.pbLines, cfg.pbFreq, cfg.pbLen, cfg.pbThick, 0, 0, false)
    end

    LCG.PixelGlow_Stop(highlight.ClassIconPixelGlow)
    if cfg and cfg.piEnabled and not hideClassIcon then
        LCG.PixelGlow_Start(highlight.ClassIconPixelGlow, cfg.color,
            cfg.piLines, cfg.piFreq, cfg.piLen, cfg.piThick, 0, 0, false)
    end
end

function sArenaFrameMixin:SetAuraHighlightActive(category)
    local highlight = self.AuraHighlights
    if not highlight then return end
    if highlight.activeCategory == category then return end

    if category and not self.auraHighlightsOn then
        if self.parent.testMode then
            highlight.activeCategory = category
        end
        return
    end

    highlight.activeCategory = category
    self:ApplyAuraHighlight(category)
end

function sArenaFrameMixin:UpdateAuraHighlightEnabled()
    local db = self.parent and self.parent.db
    local ah = db and db.profile and db.profile.auraHighlight
    local enabled = ah and ah.enabled and (not ah.onlyOnHealer or self.isHealer) and true or false
    self.auraHighlightsOn = enabled

    local highlight = self.AuraHighlights
    if not enabled and highlight then
        if not self.parent.testMode then
            highlight.activeCategory = nil
        end
        self:ApplyAuraHighlight()
    end

    self:RefreshAuraHighlight()
end

function sArenaFrameMixin:RefreshAuraHighlight()
    local highlight = self.AuraHighlights
    if not highlight then return end

    local ah = self.parent.db.profile.auraHighlight
    local active = ah.enabled and (not ah.onlyOnHealer or self.isHealer)

    local cache = highlight.cfg or {}
    highlight.cfg = cache
    if active then
        cache.cc        = BuildCategoryConfig(ah, "cc")
        cache.important = BuildCategoryConfig(ah, "important")
        cache.defensive = BuildCategoryConfig(ah, "defensive")
    else
        cache.cc, cache.important, cache.defensive = nil, nil, nil
    end

    self:UpdateAuraHighlightLayout()

    local category = highlight.activeCategory
    self:ApplyAuraHighlight(category)
end

function sArenaMixin:RefreshAllAuraHighlights()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame then
            frame:CreateAuraHighlight()
            frame:UpdateAuraHighlightLayout()
            frame:UpdateAuraHighlightEnabled()
            frame:SetUnitAuraRegistration()
        end
    end
end
