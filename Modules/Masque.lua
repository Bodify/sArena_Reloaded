-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local function addToMasque(frame, masqueGroup)
    masqueGroup:AddButton(frame)
end

function sArenaMixin:AddMasqueSupport()
    if not self.db.profile.enableMasque or self.masqueOn or not C_AddOns.IsAddOnLoaded("Masque") then return end
    local Masque = LibStub("Masque", true)
    self.masqueOn = true

    local sArenaClass = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Class/Aura")
    local sArenaTrinket = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Trinket")
    local sArenaSpecIcon = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "SpecIcon")
    local sArenaRacial = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Racial")
    local sArenaDispel = not self.isMidnight and Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Dispel")
    local sArenaDRs = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "DRs")
    local sArenaFrame = self.db.profile.enableMasqueExtra and Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Frame")
    local sArenaCastbar = self.db.profile.enableMasqueExtra and Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Castbar")
    local sArenaCastbarIcon = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Castbar Icon")

    function self:RefreshMasque()
        sArenaClass:ReSkin(true)
        sArenaTrinket:ReSkin(true)
        sArenaSpecIcon:ReSkin(true)
        sArenaRacial:ReSkin(true)
        if sArenaDispel then
            sArenaDispel:ReSkin(true)
        end
        sArenaDRs:ReSkin(true)
        if sArenaFrame then sArenaFrame:ReSkin(true) end
        if sArenaCastbar then sArenaCastbar:ReSkin(true) end
        sArenaCastbarIcon:ReSkin(true)
    end

    local function MsqSkinIcon(frame, group)
        local skinWrapper = CreateFrame("Frame")
        skinWrapper:SetParent(frame)
        skinWrapper:SetSize(30, 30)
        skinWrapper:SetAllPoints(frame.Icon)
        frame.MSQ = skinWrapper
        frame.Icon:Hide()
        frame.SkinnedIcon = skinWrapper:CreateTexture(nil, "BACKGROUND")
        frame.SkinnedIcon:SetSize(30, 30)
        frame.SkinnedIcon:SetPoint("CENTER")
        frame.SkinnedIcon:SetTexture(frame.Icon:GetTexture())
        hooksecurefunc(frame.Icon, "SetTexture", function(_, tex)
            skinWrapper:SetScale(frame.Icon:GetScale())
            frame.SkinnedIcon:SetTexture(tex)
        end)
        group:AddButton(skinWrapper, {
            Icon = frame.SkinnedIcon,
        })
    end

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not frame.FrameMsq and sArenaFrame then
            frame.FrameMsq = CreateFrame("Frame", nil, frame)
            frame.FrameMsq:SetFrameStrata("MEDIUM")
            frame.FrameMsq:SetFrameLevel(19)
            frame.FrameMsq:SetPoint("TOPLEFT", frame.HealthBar, "TOPLEFT", 0, 0)
            frame.FrameMsq:SetPoint("BOTTOMRIGHT", frame.PowerBar, "BOTTOMRIGHT", 0, 0)
        end

        frame.ClassIconMsq = CreateFrame("Frame", nil, frame)
        frame.ClassIconMsq:SetFrameStrata("MEDIUM")
        frame.ClassIconMsq:SetFrameLevel(19)
        frame.ClassIconMsq:SetAllPoints(frame.ClassIcon)

        frame.SpecIconMsq = CreateFrame("Frame", nil, frame)
        frame.SpecIconMsq:SetFrameStrata("MEDIUM")
        frame.SpecIconMsq:SetFrameLevel(19)
        frame.SpecIconMsq:SetAllPoints(frame.SpecIcon)

        frame.TrinketMsq = CreateFrame("Frame", nil, frame)
        frame.TrinketMsq:SetFrameStrata("MEDIUM")
        frame.TrinketMsq:SetFrameLevel(19)
        frame.TrinketMsq:SetAllPoints(frame.Trinket)

        frame.RacialMsq = CreateFrame("Frame", nil, frame)
        frame.RacialMsq:SetFrameStrata("MEDIUM")
        frame.RacialMsq:SetFrameLevel(19)
        frame.RacialMsq:SetAllPoints(frame.Racial)

        if sArenaDispel then
            frame.DispelMsq = CreateFrame("Frame", nil, frame)
            frame.DispelMsq:SetFrameStrata("MEDIUM")
            frame.DispelMsq:SetFrameLevel(19)
            frame.DispelMsq:SetAllPoints(frame.Dispel)
        end

        if not frame.CastBarMsq and sArenaCastbar then
            frame.CastBarMsq = CreateFrame("Frame", nil, frame.CastBar)
            frame.CastBarMsq:SetFrameStrata("HIGH")
            frame.CastBarMsq:SetAllPoints(frame.CastBar)
        end

        if frame.FrameMsq then addToMasque(frame.FrameMsq, sArenaFrame) end
        addToMasque(frame.ClassIconMsq, sArenaClass)
        addToMasque(frame.SpecIconMsq, sArenaSpecIcon)
        addToMasque(frame.TrinketMsq, sArenaTrinket)
        addToMasque(frame.RacialMsq, sArenaRacial)
        if sArenaDispel then
            addToMasque(frame.DispelMsq, sArenaDispel)
        end
        if frame.CastBarMsq then addToMasque(frame.CastBarMsq, sArenaCastbar) end
        MsqSkinIcon(frame.CastBar, sArenaCastbarIcon)

        frame.CastBar.MSQ:SetFrameStrata("DIALOG")

        -- Add MasqueBorderHook for Trinket
        hooksecurefunc(frame.Trinket.Texture, "SetTexture", function(self, t)
            if not t then
                if frame.TrinketMsq then
                    frame.TrinketMsq:Hide()
                end
            else
                if frame.TrinketMsq and frame.parent.db.profile.enableMasque then
                    frame.TrinketMsq:Hide()
                    frame.TrinketMsq:Show()
                end
            end
        end)

        -- Add MasqueBorderHook for Racial
        hooksecurefunc(frame.Racial.Texture, "SetTexture", function(self, t)
            if not t then
                if frame.RacialMsq then
                    frame.RacialMsq:Hide()
                end
            else
                if frame.RacialMsq and frame.parent.db.profile.enableMasque then
                    frame.RacialMsq:Hide()
                    frame.RacialMsq:Show()
                end
            end
        end)

        -- Add MasqueBorderHook for Dispel
        if sArenaDispel then
            hooksecurefunc(frame.Dispel.Texture, "SetTexture", function(self, t)
                if not t then
                    if frame.DispelMsq then
                        frame.DispelMsq:Hide()
                    end
                else
                    if frame.DispelMsq and frame.parent.db.profile.enableMasque then
                        frame.DispelMsq:Hide()
                        frame.DispelMsq:Show()
                    end
                end
            end)
        end

        -- DR frames
        local useDrFrames = frame.drFrames ~= nil
        local drList = frame.drFrames or self.drCategories
        if drList then
            for i = 1, #drList do
                local drFrame = useDrFrames and drList[i] or frame[drList[i]]
                if drFrame then
                    addToMasque(drFrame, sArenaDRs)
                end
            end
        end
    end
end
