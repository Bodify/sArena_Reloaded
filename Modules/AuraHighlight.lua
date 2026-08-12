-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local LCG = LibStub("LibCustomGlow-1.0", true)
local isMidnight = sArenaMixin.isMidnight

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

    local classIconGlow = CreateFrame("Frame", nil, classIcon)
    classIconGlow:SetFrameStrata("MEDIUM")
    classIconGlow:SetFrameLevel(49)
    classIconGlow:Hide()

    local tex = classIconGlow:CreateTexture(nil, "OVERLAY", nil, 6)
    tex:SetTexture(defaultHighlightTexture)
    tex:SetAllPoints(classIconGlow)
    tex:SetDesaturated(true)
    classIconGlow.Texture = tex
    highlight.ClassIconGlow = classIconGlow

    local classIconPixelGlow = CreateFrame("Frame", nil, classIcon)
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

    local framePulseGlow = CreateFrame("Frame", nil, self)
    framePulseGlow:SetFrameStrata("MEDIUM")
    framePulseGlow:SetFrameLevel(48)
    framePulseGlow:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT", 0, 0)
    framePulseGlow:SetPoint("BOTTOMRIGHT", self.PowerBar, "BOTTOMRIGHT", 0, 0)
    highlight.FramePulseGlow = framePulseGlow

    local pulse = framePulseGlow:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local pulseAlpha = pulse:CreateAnimation("Alpha")
    pulseAlpha:SetFromAlpha(0)
    pulseAlpha:SetToAlpha(1)
    pulseAlpha:SetDuration(0.3)
    pulseAlpha:SetSmoothing("IN_OUT")
    framePulseGlow.Pulse = pulse
    framePulseGlow.PulseAlpha = pulseAlpha

    framePulseGlow:Hide()
end

local function AnchorWrapTarget(unitFrame, target, wrapClass, wrapTrinket, wrapRacial)
    if not wrapClass and not wrapTrinket and not wrapRacial then
        target:ClearAllPoints()
        target:SetPoint("TOPLEFT", unitFrame.HealthBar, "TOPLEFT", 0, 0)
        target:SetPoint("BOTTOMRIGHT", unitFrame.PowerBar, "BOTTOMRIGHT", 0, 0)
        return
    end

    local allFrames = { unitFrame.HealthBar, unitFrame.PowerBar }
    if wrapClass and unitFrame.ClassIcon then
        allFrames[#allFrames + 1] = unitFrame.ClassIcon
    end
    if wrapTrinket and unitFrame.Trinket then
        allFrames[#allFrames + 1] = unitFrame.Trinket
    end
    if wrapRacial and unitFrame.Racial then
        allFrames[#allFrames + 1] = unitFrame.Racial
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
        target:ClearAllPoints()
        target:SetPoint("TOPLEFT", unitFrame.HealthBar, "TOPLEFT", 0, 0)
        target:SetPoint("BOTTOMRIGHT", unitFrame.PowerBar, "BOTTOMRIGHT", 0, 0)
        return
    end

    target:ClearAllPoints()
    target:SetPoint("LEFT",   minLeftFrame,   "LEFT",   0, 0)
    target:SetPoint("RIGHT",  maxRightFrame,  "RIGHT",  0, 0)
    target:SetPoint("TOP",    maxTopFrame,    "TOP",    0, 0)
    target:SetPoint("BOTTOM", minBottomFrame, "BOTTOM", 0, 0)
end

local function CreateInwardPixelBorder(parent, key, size)
    local holder = parent[key]
    if not holder then
        holder = CreateFrame("Frame", nil, parent)

        local edges = {}
        for i = 1, 4 do
            local tex = holder:CreateTexture(nil, "OVERLAY", nil, 6)
            tex:SetColorTexture(1, 1, 1, 1)
            edges[i] = tex
        end
        holder.edges = edges

        function holder:SetVertexColor(r, g, b, a)
            for _, tex in ipairs(self.edges) do
                tex:SetColorTexture(r, g, b, a or 1)
            end
        end

        parent[key] = holder
    end

    holder:ClearAllPoints()
    holder:SetAllPoints(parent)

    local edges = holder.edges

    edges[1]:ClearAllPoints()
    edges[1]:SetPoint("TOPLEFT", holder, "TOPLEFT")
    edges[1]:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
    edges[1]:SetHeight(size)

    edges[2]:ClearAllPoints()
    edges[2]:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, -size)
    edges[2]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, size)
    edges[2]:SetWidth(size)

    edges[3]:ClearAllPoints()
    edges[3]:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT")
    edges[3]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT")
    edges[3]:SetHeight(size)

    edges[4]:ClearAllPoints()
    edges[4]:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -size)
    edges[4]:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, size)
    edges[4]:SetWidth(size)

    return holder
end

function sArenaFrameMixin:UpdateFramePixelGlowAnchors(wrapClass, wrapTrinket, wrapRacial)
    local highlight = self.AuraHighlights
    if not highlight then return end
    AnchorWrapTarget(self, highlight.FramePixelGlow, wrapClass, wrapTrinket, wrapRacial)
end

function sArenaFrameMixin:UpdateFramePulseGlowAnchors(wrapTrinket, wrapRacial)
    local highlight = self.AuraHighlights
    if not highlight then return end
    AnchorWrapTarget(self, highlight.FramePulseGlow, false, wrapTrinket, wrapRacial)
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
    glow:SetFrameStrata("MEDIUM")
    glow:SetFrameLevel(49)

    local pixelGlow = highlight.ClassIconPixelGlow
    pixelGlow:SetFrameStrata("MEDIUM")
    pixelGlow:SetFrameLevel(48)

    local ah = self.parent and self.parent.db and self.parent.db.profile.auraHighlight

    if not isMidnight then
        local pb = ah and ah.pixelBorder
        self:UpdateFramePixelGlowAnchors(
            pb and pb.wrapClass,
            pb and pb.wrapTrinket,
            pb and pb.wrapRacial
        )
    end

    local fp = ah and ah.framePulse
    self:UpdateFramePulseGlowAnchors(fp and fp.wrapTrinket, fp and fp.wrapRacial)
end

local function BuildCategoryConfig(ah, category)
    local cc = ah[category]
    if not (cc and cc.enabled) then return nil end
    local pb, pi, fp = ah.pixelBorder, ah.pixelClassIcon, ah.framePulse
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
        fpEnabled     = fp and fp.enabled and true or false,
        fpSpeed       = (fp and fp.speed) or 0.3,
        fpSize        = (fp and fp.size) or 1.5,
        fpMinAlpha    = (fp and fp.minAlpha) or 0,
        fpMaxAlpha    = (fp and fp.maxAlpha) or 1,
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

    if not isMidnight then
        local framePixelGlow = highlight.FramePixelGlow
        LCG.PixelGlow_Stop(framePixelGlow)
        if cfg and cfg.pbEnabled then
            LCG.PixelGlow_Start(framePixelGlow, cfg.color,
                cfg.pbLines, cfg.pbFreq, cfg.pbLen, cfg.pbThick, 0, 0, false)
        end
    end

    local framePulseGlow = highlight.FramePulseGlow
    if cfg and cfg.fpEnabled then
        local c = cfg.color
        local border = CreateInwardPixelBorder(framePulseGlow, "border", cfg.fpSize)
        border:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        framePulseGlow.PulseAlpha:SetFromAlpha(cfg.fpMinAlpha)
        framePulseGlow.PulseAlpha:SetToAlpha(cfg.fpMaxAlpha)
        framePulseGlow.PulseAlpha:SetDuration(cfg.fpSpeed)
        framePulseGlow:Show()
        if not framePulseGlow.Pulse:IsPlaying() then
            framePulseGlow.Pulse:Play()
        end
    else
        framePulseGlow.Pulse:Stop()
        framePulseGlow:Hide()
    end

    if not isMidnight then
        LCG.PixelGlow_Stop(highlight.ClassIconPixelGlow)
        if cfg and cfg.piEnabled and not hideClassIcon then
            LCG.PixelGlow_Start(highlight.ClassIconPixelGlow, cfg.color,
                cfg.piLines, cfg.piFreq, cfg.piLen, cfg.piThick, 0, 0, false)
        end
    end
end

local auraSlotGlowPriority = {
    defensive = 1,
    important = 2,
    cc        = 3,
}

function sArenaFrameMixin:CreateAuraSlotGlow(button, category)
    local db = self.parent and self.parent.db
    local ah = db and db.profile and db.profile.auraHighlight
    if not (ah and ah.enabled) then return end

    local categorySettings = ah[category]
    if not (categorySettings and categorySettings.enabled) then return end

    local wantsGlow = (ah.glowClassIcon and ah.glowClassIcon.enabled)
        or (ah.pixelClassIcon and ah.pixelClassIcon.enabled)
    if not wantsGlow then return end

    local reference = self.AuraHighlights and self.AuraHighlights.ClassIconGlow
    if not reference then return end

    local host = CreateFrame("Frame", nil, button)
    host:SetAllPoints(reference)
    host:SetFrameStrata(reference:GetFrameStrata())
    host:SetFrameLevel(reference:GetFrameLevel() + (auraSlotGlowPriority[category] or 0))

    local glow = host:CreateTexture(nil, "OVERLAY", nil, 6)
    glow:SetAllPoints(host)
    glow:SetDesaturated(true)

    local atlas = reference.Texture:GetAtlas()
    if atlas then
        glow:SetAtlas(atlas)
    else
        glow:SetTexture(reference.Texture:GetTexture())
    end

    local color = categorySettings.color or { 1, 1, 1, 1 }
    glow:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
end

function sArenaFrameMixin:CreateAuraSlotFramePulse(button, category)
    local db = self.parent and self.parent.db
    local ah = db and db.profile and db.profile.auraHighlight
    if not (ah and ah.enabled) then return end

    local categorySettings = ah[category]
    if not (categorySettings and categorySettings.enabled) then return end

    local fp = ah.framePulse
    if not (fp and fp.enabled) then return end

    local host = CreateFrame("Frame", nil, button)
    AnchorWrapTarget(self, host, false, fp.wrapTrinket, fp.wrapRacial)
    host:SetFrameStrata("MEDIUM")
    host:SetFrameLevel(48 + (auraSlotGlowPriority[category] or 0))

    local border = CreateInwardPixelBorder(host, "border", fp.size or 1.5)

    local color = categorySettings.color or { 1, 1, 1, 1 }
    border:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)

    local pulse = host:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local pulseAlpha = pulse:CreateAnimation("Alpha")
    pulseAlpha:SetFromAlpha(fp.minAlpha or 0)
    pulseAlpha:SetToAlpha(fp.maxAlpha or 1)
    pulseAlpha:SetDuration(fp.speed or 0.3)
    pulseAlpha:SetSmoothing("IN_OUT")

    pulse:Play()
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
        frame:CreateAuraHighlight()
        frame:UpdateAuraHighlightLayout()
        frame:UpdateAuraHighlightEnabled()
        frame:SetUnitAuraRegistration()

        if frame.SetupAuraDisplay then
            frame:SetupAuraDisplay()
        end
    end
end
