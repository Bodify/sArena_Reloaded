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
    [30146]  = true, -- Summon Demonic Tyrant (Demonology)
    [691]    = true, -- Summon Felhunter (for Spell Lock)
    [108503] = true, -- Grimoire of Sacrifice
}

sArenaMixin.interruptIcon = CreateFrame("Frame")
sArenaMixin.interruptIcon.cooldown = CreateFrame("Cooldown", nil, sArenaMixin.interruptIcon, "CooldownFrameTemplate")
sArenaMixin.interruptIcon.cooldown:HookScript("OnCooldownDone", function()
    sArenaMixin.interruptReady = true
    sArenaMixin:UpdateCastbarInterruptStatus()
end)

function sArenaMixin:UpdateCastbarInterruptStatus()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = _G["sArenaEnemyFrame" .. i]
        local castBar = frame.CastBar
        if castBar:IsShown() then
            sArenaMixin:CastbarOnEvent(castBar)
        end
    end
end

-- Function to update the interrupt icon
local function UpdateInterruptTracking()
    if not playerKick then
        playerKick = GetInterruptSpell()
    end
    if playerKick then
        if isMidnight then
            local cooldownInfo = C_Spell.GetSpellCooldownDuration(playerKick)
            if cooldownInfo then
                sArenaMixin.interruptIcon.cooldown:SetCooldownFromDurationObject(cooldownInfo)
                sArenaMixin.interruptReady = not sArenaMixin.interruptIcon.cooldown:IsShown()
            end
        else
            local cooldownInfo = C_Spell.GetSpellCooldown(playerKick)
            if cooldownInfo then
                sArenaMixin.interruptReady = cooldownInfo.duration == 0
            end
        end
    else
        sArenaMixin.interruptReady = nil
    end
end

local function OnPetEvent(self, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if not petSummonSpells[spellID] then return end
    end
    C_Timer.After(0.1, function()
        UpdateInterruptTracking()
    end)
end


local cooldownFrame = CreateFrame("Frame")
cooldownFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
cooldownFrame:RegisterEvent("SPELL_UPDATE_USABLE")
cooldownFrame:SetScript("OnEvent", function(self, event, spellID)
    if event == "SPELL_UPDATE_COOLDOWN" then
        if spellID ~= playerKick then return end
        UpdateInterruptTracking()
        sArenaMixin:UpdateCastbarInterruptStatus()
    else
        local oldInterruptStatus = sArenaMixin.interruptReady
        UpdateInterruptTracking()
        if oldInterruptStatus ~= sArenaMixin.interruptReady then
            sArenaMixin:UpdateCastbarInterruptStatus()
        end
    end
end)

sArenaMixin.interruptSpellUpdate = CreateFrame("Frame")
sArenaMixin.interruptSpellUpdate:SetScript("OnEvent", OnPetEvent)

function sArenaMixin:RegisterInterruptEvents()
    self.interruptSpellUpdate:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    self.interruptSpellUpdate:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self.interruptSpellUpdate:RegisterEvent("PLAYER_TALENT_UPDATE")

    UpdateInterruptTracking()
end

function sArenaMixin:UnregisterInterruptEvents()
    self.interruptSpellUpdate:UnregisterAllEvents()
end