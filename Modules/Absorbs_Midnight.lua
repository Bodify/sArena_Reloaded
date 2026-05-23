-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local ABSORB_GLOW_ALPHA  = 0.6
local ABSORB_GLOW_OFFSET = -5

local function AdjustAbsorbGlow(absorbGlow, anchorBar, clamped, useRightEdge)
    local barTex = anchorBar:GetStatusBarTexture()
    local topAnchor = useRightEdge and "TOPRIGHT" or "TOPLEFT"
    local bottomAnchor = useRightEdge and "BOTTOMRIGHT" or "BOTTOMLEFT"
    absorbGlow:ClearAllPoints()
    absorbGlow:SetPoint("TOPLEFT", barTex, topAnchor, ABSORB_GLOW_OFFSET, 1)
    absorbGlow:SetPoint("BOTTOMLEFT", barTex, bottomAnchor, ABSORB_GLOW_OFFSET, -1)
    absorbGlow:SetAlphaFromBoolean(clamped, ABSORB_GLOW_ALPHA, 0)
end

local function CreateOvershield(frame)
    local healthBar = frame.HealthBar

    local overshieldBar = CreateFrame("StatusBar", nil, healthBar)
    overshieldBar:SetAllPoints(healthBar)
    overshieldBar:SetReverseFill(true)
    overshieldBar:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Overlay")
    overshieldBar:SetFrameLevel(healthBar:GetFrameLevel())
    overshieldBar:SetStatusBarColor(1, 1, 1, 0.7)

    local barTex = overshieldBar:GetStatusBarTexture()
    barTex:SetTexture("Interface\\RaidFrame\\Shield-Overlay", "REPEAT", "REPEAT")
    barTex:SetHorizTile(true)
    barTex:SetVertTile(true)
    barTex:SetDrawLayer("ARTWORK", 1)

    frame.healPredictionCalc = CreateUnitHealPredictionCalculator()
    frame.healPredictionCalc:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MissingHealth)

    frame.OvershieldBar = overshieldBar
end

local function CreateAbsorb(frame)
    local healthBar = frame.HealthBar

    local fillBar = CreateFrame("StatusBar", nil, healthBar)
    fillBar:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill")
    fillBar:SetFrameLevel(healthBar:GetFrameLevel())
    fillBar:SetStatusBarColor(1, 1, 1, 1)
    fillBar:Hide()

    local barTex = fillBar:GetStatusBarTexture()
    barTex:SetDrawLayer("ARTWORK", 0)

    local overlay = fillBar:CreateTexture(nil, "ARTWORK", nil, 1)
    overlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", "REPEAT", "REPEAT")
    overlay:SetHorizTile(true)
    overlay:SetVertTile(true)
    overlay:SetVertexColor(1, 1, 1, 0.7)
    overlay:SetAllPoints(barTex)
    fillBar.overlay = overlay

    frame.AbsorbBar = fillBar

    C_Timer.After(0.1, function()
        if fillBar:GetNumPoints() > 0 then return end
        fillBar:SetPoint("TOPLEFT", healthBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        fillBar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
    end)
end

local function UpdateAbsorbBars(parent, frame, unit)
    local healthBar     = frame.HealthBar
    local absorbGlow    = frame.overAbsorbGlow
    local overshieldBar = frame.OvershieldBar
    local absorbFillBar = frame.AbsorbBar

    if not (healthBar and absorbGlow and overshieldBar and absorbFillBar and frame.healPredictionCalc) then
        return
    end

    if not (unit and UnitExists(unit)) then
        overshieldBar:SetAlpha(0)
        absorbFillBar:Hide()
        absorbGlow:SetAlpha(0)
        return
    end

    local disableOvershields = parent.parent.db.profile.disableOvershields

    UnitGetDetailedHealPrediction(unit, nil, frame.healPredictionCalc)
    local absorbAmount, clamped = frame.healPredictionCalc:GetDamageAbsorbs()
    local missingHealth = frame.healPredictionCalc:GetMissingHealth()
    local totalAbsorbs = UnitGetTotalAbsorbs(unit) or 0

    if disableOvershields then
        AdjustAbsorbGlow(absorbGlow, overshieldBar, clamped, true)
        overshieldBar:SetAlpha(0)
        absorbFillBar.overlay:SetAlpha(1)
        absorbGlow:SetAlphaFromBoolean(clamped, ABSORB_GLOW_ALPHA, 0)
    else
        local _, maxVal = healthBar:GetMinMaxValues()
        overshieldBar:SetMinMaxValues(0, maxVal)
        overshieldBar:SetValue(totalAbsorbs)
        overshieldBar:SetAlphaFromBoolean(clamped, 1, 0)
        absorbFillBar.overlay:SetAlphaFromBoolean(clamped, 0, 1)
        AdjustAbsorbGlow(absorbGlow, overshieldBar, clamped)
    end

    absorbFillBar:SetMinMaxValues(0, missingHealth)
    absorbFillBar:SetValue(absorbAmount or 0)
    absorbFillBar:Show()
end

function sArenaFrameMixin:CreateOvershieldBar()
    CreateOvershield(self)
end

function sArenaFrameMixin:CreateAbsorbBar()
    CreateAbsorb(self)
end

function sArenaPetFrameMixin:CreateOvershieldBar()
    CreateOvershield(self)
end

function sArenaPetFrameMixin:CreateAbsorbBar()
    CreateAbsorb(self)
end

function sArenaFrameMixin:UpdateAbsorb()
    UpdateAbsorbBars(self, self, self.unit)
end

function sArenaPetFrameMixin:UpdateAbsorb()
    UpdateAbsorbBars(self.OwnerFrame, self, self.unit)
end
