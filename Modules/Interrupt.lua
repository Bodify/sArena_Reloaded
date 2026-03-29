-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local interruptList = sArenaMixin.interruptList

local function GetInterruptSpell()
    for spellID, _ in pairs(interruptList) do
        if IsSpellKnownOrOverridesKnown(spellID) or (UnitExists("pet") and IsSpellKnownOrOverridesKnown(spellID, true)) then
            return spellID
        end
    end
    return nil
end

local isMidnight = sArenaMixin.isMidnight
local playerKick = GetInterruptSpell()

-- Recheck interrupt spells when lock resummons/sacrifices pet
local petSummonSpells = {
    [30146]  = true, -- Summon Felguard (Demonology)
    [691]    = true, -- Summon Felhunter (for Spell Lock)
    [108503] = true, -- Grimoire of Sacrifice
}

function sArenaMixin:UpdateCastbarInterruptStatus()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local castBar = frame.CastBar
        if castBar:IsShown() then
            self:CastbarOnEvent(castBar)
        end
    end
end

function sArenaMixin:UpdateInterruptTracking()
    if not playerKick then
        playerKick = GetInterruptSpell()
    end
    if playerKick then
        if isMidnight then
            local cooldownInfo = C_Spell.GetSpellCooldownDuration(playerKick)
            if cooldownInfo then
                self.interruptIcon.cooldown:SetCooldownFromDurationObject(cooldownInfo)
                self.interruptReady = not self.interruptIcon.cooldown:IsShown()
            end
        else
            local cooldownInfo = C_Spell.GetSpellCooldown(playerKick)
            if cooldownInfo then
                self.interruptReady = cooldownInfo.duration == 0
            end
        end
    else
        self.interruptReady = nil
    end
end

function sArenaMixin:InterruptTracker()
    self.interruptIcon = CreateFrame("Frame")
    self.interruptIcon.cooldown = CreateFrame("Cooldown", nil, self.interruptIcon, "CooldownFrameTemplate")
    self.interruptIcon.cooldown:HookScript("OnCooldownDone", function()
        self.interruptReady = true
        self:UpdateCastbarInterruptStatus()
    end)

    local function OnPetEvent(frame, event, unit, _, spellID)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            if not petSummonSpells[spellID] then return end
        end
        C_Timer.After(0.1, function()
            self:UpdateInterruptTracking()
        end)
    end

    local cooldownFrame = CreateFrame("Frame")
    cooldownFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    cooldownFrame:RegisterEvent("SPELL_UPDATE_USABLE")
    cooldownFrame:SetScript("OnEvent", function(frame, event, spellID)
        if event == "SPELL_UPDATE_COOLDOWN" then
            if spellID ~= playerKick then return end
            self:UpdateInterruptTracking()
            self:UpdateCastbarInterruptStatus()
        else
            local oldInterruptStatus = self.interruptReady
            self:UpdateInterruptTracking()
            if oldInterruptStatus ~= self.interruptReady then
                self:UpdateCastbarInterruptStatus()
            end
        end
    end)

    self.interruptSpellUpdate = CreateFrame("Frame")
    self.interruptSpellUpdate:SetScript("OnEvent", OnPetEvent)
end

function sArenaMixin:RegisterInterruptEvents()
    self.interruptSpellUpdate:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    self.interruptSpellUpdate:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self.interruptSpellUpdate:RegisterEvent("PLAYER_TALENT_UPDATE")

    self:UpdateInterruptTracking()
end

function sArenaMixin:UnregisterInterruptEvents()
    self.interruptSpellUpdate:UnregisterAllEvents()
end