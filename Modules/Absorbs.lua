-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local ABSORB_GLOW_ALPHA  = 0.6
local ABSORB_GLOW_OFFSET = -5

local function UpdateAbsorbBars(parent, frame, unit)
    local healthBar     = frame.HealthBar
    local absorbBar     = frame.totalAbsorbBar
    local absorbOverlay = frame.totalAbsorbBarOverlay
    local glow          = frame.overAbsorbGlow

    if not (healthBar and absorbBar and absorbOverlay and glow) then return end

    if not (unit and UnitExists(unit)) then
        absorbBar:Hide()
        absorbOverlay:Hide()
        glow:Hide()
        return
    end

    local maxHealth   = UnitHealthMax(unit)
    local totalAbsorb = (UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit)) or 0

    if maxHealth <= 0 or totalAbsorb <= 0 then
        absorbBar:Hide()
        absorbOverlay:Hide()
        glow:Hide()
        return
    end

    local currentHealth = UnitHealth(unit)
    local healthWidth   = healthBar:GetWidth()
    local healthHeight  = healthBar:GetHeight()
    local profile       = parent.parent.db.profile
    local isReversed    = profile.reverseBarsFill or false

    -- Default, no Overshields.
    if profile.disableOvershields then
        local isOverAbsorb = (currentHealth + totalAbsorb >= maxHealth)

        -- Clamp absorbs to actual missing health
        local missingHealth = maxHealth - currentHealth
        totalAbsorb = math.min(totalAbsorb, missingHealth)

        if isOverAbsorb then
            glow:Show()
        else
            glow:Hide()
        end

        if totalAbsorb > 0 then
            local absorbWidth        = healthWidth * (totalAbsorb / maxHealth)
            local missingHealthWidth = (maxHealth - currentHealth) / maxHealth * healthWidth
            local absorbBarWidth     = math.min(absorbWidth, missingHealthWidth)

            absorbBar:ClearAllPoints()
            absorbOverlay:ClearAllPoints()
            if isReversed then
                absorbBar:SetPoint("TOPRIGHT", healthBar, "TOPLEFT", missingHealthWidth, 0)
                absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0)
                absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0)
                if absorbOverlay.tileSize then
                    absorbOverlay:SetTexCoord(0, absorbBarWidth / absorbOverlay.tileSize, 0, healthHeight / absorbOverlay.tileSize)
                end
            else
                absorbBar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", currentHealth / maxHealth * healthWidth, 0)
                absorbOverlay:SetPoint("TOPLEFT", absorbBar, "TOPLEFT", 0, 0)
                absorbOverlay:SetPoint("BOTTOMLEFT", absorbBar, "BOTTOMLEFT", 0, 0)
                if absorbOverlay.tileSize then
                    absorbOverlay:SetTexCoord(1 - (absorbBarWidth / absorbOverlay.tileSize), 1, 0, healthHeight / absorbOverlay.tileSize)
                end
            end

            absorbBar:SetSize(absorbBarWidth, healthHeight)
            absorbBar:Show()
            absorbOverlay:SetSize(absorbBarWidth, healthHeight)
            absorbOverlay:Show()
        else
            absorbBar:Hide()
            absorbOverlay:Hide()
        end
    else
        -- Overshields: wrapping overlay + overshield glow
        local isOverAbsorb = false

        if totalAbsorb > maxHealth then
            isOverAbsorb = true
            totalAbsorb = maxHealth
        else
            isOverAbsorb = (currentHealth + totalAbsorb > maxHealth)
        end

        local absorbWidth        = totalAbsorb / maxHealth * healthWidth
        local missingHealthWidth = (maxHealth - currentHealth) / maxHealth * healthWidth
        local absorbBarWidth     = math.min(absorbWidth, missingHealthWidth)

        -- Show absorb bar only for missing health
        if absorbBarWidth > 0 then
            absorbBar:ClearAllPoints()
            if isReversed then
                absorbBar:SetPoint("TOPRIGHT", healthBar, "TOPLEFT", missingHealthWidth, 0)
            else
                absorbBar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", currentHealth / maxHealth * healthWidth, 0)
            end
            absorbBar:SetSize(absorbBarWidth, healthHeight)
            absorbBar:Show()
        else
            absorbBar:Hide()
        end

        -- Show striped overlay for full absorb width (wraps onto filled health if needed)
        if absorbWidth > 0 then
            absorbOverlay:SetParent(healthBar)
            absorbOverlay:ClearAllPoints()
            if isReversed then
                if isOverAbsorb then
                    absorbOverlay:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", 0, 0)
                else
                    absorbOverlay:SetPoint("TOPLEFT", absorbBar, "TOPLEFT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMLEFT", absorbBar, "BOTTOMLEFT", 0, 0)
                end
            else
                if isOverAbsorb then
                    absorbOverlay:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
                else
                    absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0)
                end
            end

            absorbOverlay:SetSize(absorbWidth, healthHeight)

            if absorbOverlay.tileSize then
                if isReversed then
                    absorbOverlay:SetTexCoord(0, absorbWidth / absorbOverlay.tileSize, 0, healthHeight / absorbOverlay.tileSize)
                else
                    absorbOverlay:SetTexCoord(1 - (absorbWidth / absorbOverlay.tileSize), 1, 0, healthHeight / absorbOverlay.tileSize)
                end
            end

            absorbOverlay:Show()
        else
            absorbOverlay:Hide()
        end

        -- Glow if over-absorb occurs
        glow:ClearAllPoints()
        if isOverAbsorb then
            if isReversed then
                glow:SetPoint("TOPRIGHT", absorbOverlay, "TOPRIGHT", -ABSORB_GLOW_OFFSET, 0)
                glow:SetPoint("BOTTOMRIGHT", absorbOverlay, "BOTTOMRIGHT", -ABSORB_GLOW_OFFSET, 0)
            else
                glow:SetPoint("TOPLEFT", absorbOverlay, "TOPLEFT", ABSORB_GLOW_OFFSET, 0)
                glow:SetPoint("BOTTOMLEFT", absorbOverlay, "BOTTOMLEFT", ABSORB_GLOW_OFFSET, 0)
            end
            glow:SetAlpha(ABSORB_GLOW_ALPHA)
            glow:Show()
        else
            glow:Hide()
        end
    end
end

function sArenaFrameMixin:UpdateAbsorb()
    UpdateAbsorbBars(self, self, self.unit)
end

function sArenaPetFrameMixin:UpdateAbsorb()
    UpdateAbsorbBars(self.OwnerFrame, self, self.unit)
end