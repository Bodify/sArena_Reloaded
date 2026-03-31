-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

-- Huge thanks to Verz for helping with this with his work on MiniCC
-- Portions of the code below are adapted and/or copied from his work in MiniCC with his permission.

local function AurasChanged(updateInfo)
    if not updateInfo then return true end
    if updateInfo.isFullUpdate then return true end
    if (updateInfo.addedAuras and #updateInfo.addedAuras > 0)
        or (updateInfo.updatedAuraInstanceIDs and #updateInfo.updatedAuraInstanceIDs > 0)
        or (updateInfo.removedAuraInstanceIDs and #updateInfo.removedAuraInstanceIDs > 0)
    then
        return true
    end
    return false
end

local function IterateAuras(filter, validateAura, unit, seen)
    local spellID, icon, applications, auraInstanceID
    local auras = C_UnitAuras.GetUnitAuras(unit, filter)

    for _, auraData in ipairs(auras) do
        if not seen[auraData.auraInstanceID] then
            local garbageAuraData = false

            if validateAura then -- units out of range produce garbage data, so double check
                local isValid = validateAura(auraData.spellId)
                if not (issecretvalue(isValid) or isValid) then
                    garbageAuraData = true
                end
            end

            if not garbageAuraData then
                spellID = auraData.spellId
                icon = auraData.icon
                applications = auraData.applications
                auraInstanceID = auraData.auraInstanceID
                applications = auraData.applications
            end
        end

        seen[auraData.auraInstanceID] = true
    end

    return spellID, icon, auraInstanceID, applications
end

local prioImportant

function sArenaMixin:UpdateAuraPrioImportant()
    local db = self.db
    prioImportant = db and db.profile.prioImportantOverDefensives or false
end

function sArenaFrameMixin:FindAura(updateInfo)
    if not UnitExists(self.unit) then
        self.currentAuraSpellID = nil
        self.currentAuraDurationObj = nil
        self.currentAuraTexture = nil
        self.currentAuraApplications = nil
        self:UpdateClassIcon(true)
        return
    end
    if updateInfo and not AurasChanged(updateInfo) then return end

    local unit = self.unit
    local spellID, texture, auraInstanceID, applications
    local seen = {}

    -- Crowd Control
    spellID, texture, auraInstanceID = IterateAuras("HARMFUL|CROWD_CONTROL", C_Spell.IsSpellCrowdControl, unit, seen)

    if prioImportant then
        -- Important buffs
        if not spellID then
            spellID, texture, auraInstanceID, applications = IterateAuras("HELPFUL|IMPORTANT", C_Spell.IsSpellImportant, unit, seen)
        end

        -- Big Defensives
        if not spellID then
            spellID, texture, auraInstanceID, applications = IterateAuras("HELPFUL|BIG_DEFENSIVE", C_UnitAuras.AuraIsBigDefensive, unit, seen)
        end

        -- External Defensives
        if not spellID then
            spellID, texture, auraInstanceID, applications = IterateAuras("HELPFUL|EXTERNAL_DEFENSIVE", nil, unit, seen)
        end
    else
        -- Big Defensives
        if not spellID then
            spellID, texture, auraInstanceID, applications = IterateAuras("HELPFUL|BIG_DEFENSIVE", C_UnitAuras.AuraIsBigDefensive, unit, seen)
        end

        -- External Defensives
        if not spellID then
            spellID, texture, auraInstanceID, applications = IterateAuras("HELPFUL|EXTERNAL_DEFENSIVE", nil, unit, seen)
        end

        -- Important buffs
        if not spellID then
            spellID, texture, auraInstanceID, applications = IterateAuras("HELPFUL|IMPORTANT", C_Spell.IsSpellImportant, unit, seen)
        end
    end

    if spellID then
        self.currentAuraSpellID = spellID
        self.currentAuraDurationObj = C_UnitAuras.GetAuraDuration(unit, auraInstanceID)
        self.currentAuraTexture = texture
        self.currentAuraApplications = applications
    else
        self.currentAuraSpellID = nil
        self.currentAuraDurationObj = nil
        self.currentAuraTexture = nil
        self.currentAuraApplications = nil
    end

    self:UpdateAuraStacks()
    self:UpdateClassIcon()
end

function sArenaFrameMixin:UpdateAuraStacks()
    -- if not self.currentAuraApplications then
        self.AuraStacks:SetText("")
    --     return
    -- end

    -- self.AuraStacks:SetText(self.currentAuraApplications)
    -- self.AuraStacks:SetAlpha(self.currentAuraApplications)
    -- self.AuraStacks:SetScale(1)
end