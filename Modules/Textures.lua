-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local LSM = LibStub("LibSharedMedia-3.0")

function sArenaMixin:CheckClassStacking()
    local classCount = {}
    local classHasHealer = {}

    -- Count all players by class and track which classes have healers
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame.class then
            if frame.secretClass then return false end
            classCount[frame.class] = (classCount[frame.class] or 0) + 1
            if frame.isHealer then
                classHasHealer[frame.class] = true
            end
        end
    end

    -- Check if any class has multiple players AND at least one healer
    for class, count in pairs(classCount) do
        if count > 1 and classHasHealer[class] then
            return true
        end
    end

    return false
end

function sArenaMixin:UpdateTextures()
    local db = self.db

    local layout = db.profile.layoutSettings[db.profile.currentLayout]
    local texKeys = layout.textures or {
        generalStatusBarTexture   = "sArena Default",
        healStatusBarTexture      = "sArena Stripes",
        castbarStatusBarTexture   = "sArena Default",
        castbarUninterruptibleTexture = "sArena Default",
        bgTexture = "Solid",
        bgColor = {0, 0, 0, 0.6},
        castbarBgTexture = "Solid",
        castbarBgColor = {0, 0, 0, 0.5},
    }

    local castTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
    local castUninterruptibleTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarUninterruptibleTexture or texKeys.castbarStatusBarTexture)
    local dpsTexture     = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.generalStatusBarTexture)
    local healerTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.healStatusBarTexture)
    local bgTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.bgTexture or "Solid")
    local bgColor = texKeys.bgColor or {0, 0, 0, 0.6}
    local cbBgTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarBgTexture or "Solid")
    local cbBgColor = texKeys.castbarBgColor or {0, 0, 0, 0.5}
    local modernCastbars            = layout.castBar.useModernCastbars
    local keepDefaultModernTextures = layout.castBar.keepDefaultModernTextures
    local interruptStatusColorOn     = layout.castBar.interruptStatusColorOn
    local classStacking = self:CheckClassStacking()
    local reverseBarsFill = db.profile.reverseBarsFill or false

    self.castTexture = castTexture
    self.castUninterruptibleTexture = castUninterruptibleTexture
    self.keepDefaultModernTextures = keepDefaultModernTextures
    self.modernCastbars = modernCastbars
    self.interruptStatusColorOn = interruptStatusColorOn
    self.highlightCastsOnMe = db.profile.highlightCastsOnMe
    self.highlightCC = db.profile.highlightCC
    self.highlightColor = db.profile.useHighlightColor and (db.profile.highlightColor or {0, 1, 0, 1}) or nil
    self.glowCastbarIcon = db.profile.glowCastbarIcon
    if sArenaCastingBarExtensionMixin then
        sArenaCastingBarExtensionMixin.typeInfo = {
            filling = castTexture,
            full = castTexture,
            glow = castTexture
        }
    end

    self:UpdateCastbarColors()

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local textureToUse = dpsTexture

        if self.isMidnight then
            if not frame.CastBar.unintTextureOverlay then
                frame.CastBar.unintTextureOverlay = frame.CastBar:CreateTexture(nil, "ARTWORK", nil, 1)
            end
            frame.CastBar.unintTextureOverlay:SetTexture(castUninterruptibleTexture)
        end
        frame.CastBar.changeUnint = not (modernCastbars and keepDefaultModernTextures) and (castTexture ~= castUninterruptibleTexture)

        if frame.isHealer then
            if layout.retextureHealerClassStackOnly then
                if classStacking then
                    textureToUse = healerTexture
                end
            else
                textureToUse = healerTexture
            end
        end

        frame.HealthBar:SetStatusBarTexture(textureToUse)
        frame.PowerBar:SetStatusBarTexture(dpsTexture)

        frame.PetFrame.HealthBar:SetStatusBarTexture(dpsTexture)
        if frame.PetFrame.HealthBar.hpUnderlay then
            frame.PetFrame.HealthBar.hpUnderlay:SetTexture(bgTexture)
            frame.PetFrame.HealthBar.hpUnderlay:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
        end

        if frame.HealthBar.hpUnderlay then
            frame.HealthBar.hpUnderlay:SetTexture(bgTexture)
            frame.HealthBar.hpUnderlay:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
        end
        if frame.PowerBar.ppUnderlay then
            frame.PowerBar.ppUnderlay:SetTexture(bgTexture)
            frame.PowerBar.ppUnderlay:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
        end
        if frame.CastBar.Background then
            frame.CastBar.Background:SetTexture(cbBgTexture)
            frame.CastBar.Background:SetVertexColor(cbBgColor[1], cbBgColor[2], cbBgColor[3], cbBgColor[4])
        end

        frame.HealthBar:SetReverseFill(reverseBarsFill)
        frame.PowerBar:SetReverseFill(reverseBarsFill)

        if modernCastbars then
            if not keepDefaultModernTextures then
                frame.CastBar:SetStatusBarTexture(castTexture)
            end
        else
            frame.CastBar:SetStatusBarTexture(castTexture)
        end

        if db.profile.currentLayout == "BlizzRetail" then
            frame.PowerBar:GetStatusBarTexture():SetDrawLayer("BACKGROUND", 2)
        end

        if frame.CastBar.barHighlight then
            local hc = self.highlightColor
            if hc then
                frame.CastBar.barHighlight:SetDesaturated(true)
                frame.CastBar.barHighlight:SetVertexColor(hc[1], hc[2], hc[3], 1)
            else
                frame.CastBar.barHighlight:SetDesaturated(false)
                frame.CastBar.barHighlight:SetVertexColor(1, 1, 1, 1)
            end
        end

        if frame.CastBar.iconHighlight then
            local iconGlow = frame.CastBar.iconHighlight
            local hc = self.highlightColor
            if hc then
                iconGlow:SetVertexColor(hc[1], hc[2], hc[3], 1)
            else
                iconGlow:SetVertexColor(1, 0.55, 0.55, 1)
            end
            if not self.glowCastbarIcon then
                iconGlow:SetAlpha(0)
            end
            local icon = frame.CastBar.Icon
            local iconScale = layout.castBar and layout.castBar.iconScale or 1
            local size = 16 * iconScale

            local mult = 1.2
            iconGlow:ClearAllPoints()
            iconGlow:SetPoint("TOPLEFT", icon, "TOPLEFT", -(size * mult), size * mult)
            iconGlow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", size * mult, -(size * mult))
        end
    end

    self:RefreshTestModeCastbars()
end