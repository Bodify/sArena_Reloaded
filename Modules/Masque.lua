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
    local sArenaDispel = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Dispel")
    local sArenaDRs = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "DRs")
    local sArenaFrame = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Frame")
    local sArenaCastbar = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Castbar")
    local sArenaCastbarIcon = Masque:Group("sArena |cffff8000Reloaded|r |T135884:13:13|t", "Castbar Icon")

    function sArenaMixin:RefreshMasque()
        sArenaClass:ReSkin(true)
        sArenaTrinket:ReSkin(true)
        sArenaSpecIcon:ReSkin(true)
        sArenaRacial:ReSkin(true)
        sArenaDispel:ReSkin(true)
        sArenaDRs:ReSkin(true)
        sArenaFrame:ReSkin(true)
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
        frame.FrameMsq = CreateFrame("Frame", nil, frame)
        frame.FrameMsq:SetFrameStrata("HIGH")
        frame.FrameMsq:SetPoint("TOPLEFT", frame.HealthBar, "TOPLEFT", 0, 0)
        frame.FrameMsq:SetPoint("BOTTOMRIGHT", frame.PowerBar, "BOTTOMRIGHT", 0, 0)

        frame.ClassIconMsq = CreateFrame("Frame", nil, frame)
        frame.ClassIconMsq:SetFrameStrata("DIALOG")
        frame.ClassIconMsq:SetAllPoints(frame.ClassIcon)

        frame.SpecIconMsq = CreateFrame("Frame", nil, frame)
        frame.SpecIconMsq:SetFrameStrata("DIALOG")
        frame.SpecIconMsq:SetAllPoints(frame.SpecIcon)

        frame.TrinketMsq = CreateFrame("Frame", nil, frame)
        frame.TrinketMsq:SetFrameStrata("DIALOG")
        frame.TrinketMsq:SetAllPoints(frame.Trinket)

        frame.RacialMsq = CreateFrame("Frame", nil, frame)
        frame.RacialMsq:SetFrameStrata("DIALOG")
        frame.RacialMsq:SetAllPoints(frame.Racial)

        frame.DispelMsq = CreateFrame("Frame", nil, frame)
        frame.DispelMsq:SetFrameStrata("DIALOG")
        frame.DispelMsq:SetAllPoints(frame.Dispel)

        frame.CastBarMsq = CreateFrame("Frame", nil, frame.CastBar)
        frame.CastBarMsq:SetFrameStrata("HIGH")
        frame.CastBarMsq:SetAllPoints(frame.CastBar)

        addToMasque(frame.FrameMsq, sArenaFrame)
        addToMasque(frame.ClassIconMsq, sArenaClass)
        addToMasque(frame.SpecIconMsq, sArenaSpecIcon)
        addToMasque(frame.TrinketMsq, sArenaTrinket)
        addToMasque(frame.RacialMsq, sArenaRacial)
        addToMasque(frame.DispelMsq, sArenaDispel)
        addToMasque(frame.CastBarMsq, sArenaCastbar)
        MsqSkinIcon(frame.CastBar, sArenaCastbarIcon)

        frame.CastBar.MSQ:SetFrameStrata("DIALOG")

        -- Add MasqueBorderHook for Trinket
        if not frame.Trinket.MasqueBorderHook then
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
            frame.Trinket.MasqueBorderHook = true
        end

        -- Add MasqueBorderHook for Racial
        if not frame.Racial.MasqueBorderHook then
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
            frame.Racial.MasqueBorderHook = true
        end

        -- Add MasqueBorderHook for Dispel
        if not frame.Dispel.MasqueBorderHook then
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
            frame.Dispel.MasqueBorderHook = true
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
