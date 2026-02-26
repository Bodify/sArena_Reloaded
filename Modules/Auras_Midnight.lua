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
        or (updateInfo.updatedAuras and #updateInfo.updatedAuras > 0)
        or (updateInfo.removedAuraInstanceIDs and #updateInfo.removedAuraInstanceIDs > 0)
    then
        return true
    end
    return false
end

local function IterateAuras(filter, validateDefensive, unit)
    local spellID, start, duration, icon, applications

    for i = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
        if not auraData then break end

        local durationInfo = C_UnitAuras.GetAuraDuration(unit, auraData.auraInstanceID)
        local auraStart = durationInfo and durationInfo:GetStartTime()
        local auraDuration = durationInfo and durationInfo:GetTotalDuration()

        if auraStart and auraDuration then
            local garbageAuraData = false

            if validateDefensive then -- units out of range produce garbage data, so double check
                local isDefensive = C_UnitAuras.AuraIsBigDefensive(auraData.spellId)
                if not (issecretvalue(isDefensive) or isDefensive) then
                    garbageAuraData = true
                end
            end

            if not garbageAuraData then
                spellID = auraData.spellId
                start = auraStart
                duration = auraDuration
                icon = auraData.icon
                applications = auraData.applications
            end
        end
    end

    return spellID, start, duration, icon, applications
end

function sArenaFrameMixin:FindAura(updateInfo)
    if updateInfo and not AurasChanged(updateInfo) then return end

    local unit = self.unit
    local spellID, startTime, duration, texture, applications

    -- Crowd Control
    spellID, startTime, duration, texture, applications = IterateAuras("HARMFUL|CROWD_CONTROL", false, unit)

    -- Big Defensives
    if not spellID then
        spellID, startTime, duration, texture, applications = IterateAuras("HELPFUL|BIG_DEFENSIVE", true, unit)
    end

    -- External Defensives
    if not spellID then
        spellID, startTime, duration, texture, applications = IterateAuras("HELPFUL|EXTERNAL_DEFENSIVE", false, unit)
    end

    -- Important buffs
    if not spellID then
        spellID, startTime, duration, texture, applications = IterateAuras("HELPFUL|IMPORTANT", false, unit)
    end

    if spellID then
        self.currentAuraSpellID = spellID
        self.currentAuraStartTime = startTime
        self.currentAuraDuration = duration
        self.currentAuraTexture = texture
        self.currentAuraApplications = applications
    else
        self.currentAuraSpellID = nil
        self.currentAuraStartTime = nil
        self.currentAuraDuration = nil
        self.currentAuraTexture = nil
        self.currentAuraApplications = nil
    end

    self:UpdateAuraStacks()
    self:UpdateClassIcon()
end

function sArenaFrameMixin:UpdateAuraStacks()
    if not self.currentAuraApplications then
        self.AuraStacks:SetText("")
        return
    end

    self.AuraStacks:SetText(self.currentAuraApplications)
    self.AuraStacks:SetScale(1)
end