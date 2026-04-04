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
        local frame = _G["sArenaEnemyFrame"..i]
        if frame.class then
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
    }

    local castTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
    local castUninterruptibleTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarUninterruptibleTexture or texKeys.castbarStatusBarTexture)
    local dpsTexture     = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.generalStatusBarTexture)
    local healerTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.healStatusBarTexture)
    local bgTexture = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.bgTexture or "Solid")
    local bgColor = texKeys.bgColor or {0, 0, 0, 0.6}
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
    if sArenaCastingBarExtensionMixin then
        sArenaCastingBarExtensionMixin.typeInfo = {
            filling = castTexture,
            full = castTexture,
            glow = castTexture
        }
    end

    -- Update castbar colors
    self:UpdateCastbarColors()

    for i = 1, self.maxArenaOpponents do
        local frame = _G["sArenaEnemyFrame" .. i]
        local textureToUse = dpsTexture

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

        -- Set background texture and color
        if frame.HealthBar.hpUnderlay then
            frame.HealthBar.hpUnderlay:SetTexture(bgTexture)
            frame.HealthBar.hpUnderlay:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
        end
        if frame.PowerBar.ppUnderlay then
            frame.PowerBar.ppUnderlay:SetTexture(bgTexture)
            frame.PowerBar.ppUnderlay:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
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
    end

    -- Refresh test mode castbars if test mode is active
    self:RefreshTestModeCastbars()
end