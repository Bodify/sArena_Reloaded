-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local isMidnight = sArenaMixin.isMidnight

function sArenaMixin:ChainIndicator(indicator, previous, direction, spacing)
    indicator:ClearAllPoints()
    spacing = spacing or 3
    if direction == "LEFT" then
        indicator:SetPoint("RIGHT", previous, "LEFT", -spacing, 0)
    elseif direction == "RIGHT" then
        indicator:SetPoint("LEFT", previous, "RIGHT", spacing, 0)
    elseif direction == "UP" then
        indicator:SetPoint("BOTTOM", previous, "TOP", 0, spacing)
    elseif direction == "DOWN" then
        indicator:SetPoint("TOP", previous, "BOTTOM", 0, -spacing)
    end
end

function sArenaMixin:RegisterWidgetEvents()
    local db = self.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets

    self:UnregisterWidgetEvents()

    if widgetSettings then
        local ti = widgetSettings.targetIndicator
        local fi = widgetSettings.focusIndicator
        if ti and ti.enabled then
            self:RegisterEvent("PLAYER_TARGET_CHANGED")
        end

        if fi and fi.enabled then
            self:RegisterEvent("PLAYER_FOCUS_CHANGED")
        end

        local pti = widgetSettings.partyTargetIndicators
        local ptt = widgetSettings.partyTargetText
        self.unitTargetAlwaysOn = ptt and ptt.enabled and ptt.arenaOnParty and ptt.arenaOnParty.enabled and ptt.arenaOnParty.alwaysOn or nil
        if (pti and pti.enabled and ((pti.partyOnArena and pti.partyOnArena.enabled) or (pti.arenaOnParty and pti.arenaOnParty.enabled)))
        or (ptt and ptt.enabled and ((ptt.partyOnArena and ptt.partyOnArena.enabled) or (ptt.arenaOnParty and (ptt.arenaOnParty.enabled or (ptt.arenaOnParty.enabled and ptt.arenaOnParty.alwaysOn))))) then
            self:RegisterEvent("UNIT_TARGET")
        end

        if widgetSettings.combatIndicator and widgetSettings.combatIndicator.enabled then
            for i = 1, self.maxArenaOpponents do
                local frame = self["arena" .. i]
                local unit = frame.unit
                frame:RegisterUnitEvent("UNIT_FLAGS", unit)
            end
        end
    end
end

function sArenaMixin:UnregisterWidgetEvents()
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
    if not self.unitTargetAlwaysOn then
        self:UnregisterEvent("UNIT_TARGET")
    end
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame:UnregisterEvent("UNIT_FLAGS")
    end
end

function sArenaMixin:UpdateWidgetSettings(db, info, val)

    self:UnregisterWidgetEvents()
    self:RegisterWidgetEvents()

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        if db.combatIndicator then frame.WidgetOverlay.combatIndicator:SetScale(db.combatIndicator.scale or 1) end
        if db.healerIndicator then frame.WidgetOverlay.healerIndicator:SetScale(db.healerIndicator.scale or 1) end
        if db.targetIndicator then frame.WidgetOverlay.targetIndicator:SetScale(db.targetIndicator.scale or 1) end
        if db.focusIndicator then frame.WidgetOverlay.focusIndicator:SetScale(db.focusIndicator.scale or 1) end
        if db.partyTargetIndicators then
            local poaScale = db.partyTargetIndicators.partyOnArena and db.partyTargetIndicators.partyOnArena.scale or 1
            for j = 1, 4 do
                frame.WidgetOverlay["partyTarget" .. j]:SetScale(poaScale)
            end
        end

        frame:PositionArenaTargetText()
        if self.testMode then
            frame:UpdateArenaTargetTextTestMode()
        else
            frame:UpdateArenaTargetText(frame.unit)
        end
        frame:UpdateTargetFocusBorderVisibility()

        -- Only try to update orientation if called from config (with info parameter)
        if info and info.handler then
            local layout = info.handler.layouts[info.handler.db.profile.currentLayout]
            if frame and layout and layout.UpdateOrientation then
                layout:UpdateOrientation(frame)
            end
        else
            -- Called from layout Initialize, get current layout directly
            local currentLayout = self.db.profile.currentLayout
            local layout = self.layouts[currentLayout]
            if frame and layout and layout.UpdateOrientation then
                layout:UpdateOrientation(frame)
            end
        end
    end

    self:UpdateArenaTargetsOnPartyFrames()
    self:PositionArenaTargetTextOnPartyFrames()
    if self.testMode then
        self:UpdateArenaTargetTextOnPartyFramesTestMode()
    else
        self:UpdateArenaTargetTextOnPartyFrames()
    end
end

local function SetCombatIndicatorTexture(indicator, inCombat, ci)
    if inCombat then
        if ci.useSapIcon then
            indicator.Texture:SetTexture("Interface\\Icons\\ABILITY_DUALWIELD")
        else
            indicator.Texture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\combat_swords-icon")
        end
    else
        if ci.useSapIcon then
            indicator.Texture:SetTexture("Interface\\Icons\\Ability_Sap")
        else
            indicator.Texture:SetAtlas("Food")
        end
    end
end

function sArenaFrameMixin:UpdateCombatStatus(unit)
    local ws = self.parent.db.profile.layoutSettings[self.parent.db.profile.currentLayout].widgets
    local ci = ws and ws.combatIndicator
    local indicator = self.WidgetOverlay.combatIndicator

    if ci and ci.enabled and unit and not self.DeathIcon:IsShown() then
        local inCombat = UnitAffectingCombat(unit)
        local showOutOfCombat = ci.showOutOfCombat ~= false  -- default true
        local showInCombat = ci.showInCombat

        if inCombat and showInCombat then
            SetCombatIndicatorTexture(indicator, true, ci)
            indicator:Show()
        elseif not inCombat and showOutOfCombat then
            SetCombatIndicatorTexture(indicator, false, ci)
            indicator:Show()
        else
            indicator:Hide()
        end
    else
        indicator:Hide()
    end

    local pet = self.PetFrame
    local pci = pet:GetWidgetSettings().combatIndicator
    local petUnit = pet:IsShown() and pet.unit
    local petIndicator = pet.WidgetOverlay.combatIndicator

    if pci and pci.enabled and petUnit and UnitExists(petUnit) then
        local petInCombat = UnitAffectingCombat(petUnit)
        local showOutOfCombat = pci.showOutOfCombat ~= false
        local showInCombat = pci.showInCombat

        if petInCombat and showInCombat then
            SetCombatIndicatorTexture(petIndicator, true, pci)
            petIndicator:Show()
        elseif not petInCombat and showOutOfCombat then
            SetCombatIndicatorTexture(petIndicator, false, pci)
            petIndicator:Show()
        else
            petIndicator:Hide()
        end
    else
        petIndicator:Hide()
    end
end

function sArenaFrameMixin:UpdateHealerStatus()
    local db = self.parent and self.parent.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    if not widgetSettings or not widgetSettings.healerIndicator or not widgetSettings.healerIndicator.enabled then
        self.WidgetOverlay.healerIndicator:Hide()
        return
    end
    self.WidgetOverlay.healerIndicator:SetShown(self.isHealer == true and not self.DeathIcon:IsShown())
end

local function UnitIsProbablyUnit(unit1, unit2)
    if not UnitExists(unit1) or not UnitExists(unit2) then return end

    local name1, name2 = UnitName(unit1), UnitName(unit2)
    if issecretvalue(name1) or issecretvalue(name2) then return end

    return name1 == name2
end

local function UpdateIndicator(frame, unit, widgetSettings, key, unitType, stateKey)
    local ind = widgetSettings and widgetSettings[key]
    local isUnit = ind and ind.enabled and unit and UnitIsUnit(unit, unitType)
    frame.WidgetOverlay[key]:SetShown(isUnit and (not ind.useBorder or ind.useBorderWithIcon) or false)
    if stateKey then frame[stateKey] = isUnit and true or false end
    frame:UpdateTargetFocusBorderVisibility()
end

function sArenaFrameMixin:UpdateTarget(unit)
    local db = self.parent.db
    local ws = db.profile.layoutSettings[db.profile.currentLayout].widgets
    UpdateIndicator(self, unit, ws, "targetIndicator", "target")
    local pet = self.PetFrame
    UpdateIndicator(pet, pet:IsShown() and pet.unit, pet:GetWidgetSettings(), "targetIndicator", "target", "isTarget")
end

function sArenaFrameMixin:UpdateFocus(unit)
    local db = self.parent.db
    local ws = db.profile.layoutSettings[db.profile.currentLayout].widgets
    UpdateIndicator(self, unit, ws, "focusIndicator", "focus")
    local pet = self.PetFrame
    UpdateIndicator(pet, pet:IsShown() and pet.unit, pet:GetWidgetSettings(), "focusIndicator", "focus", "isFocus")
end

function sArenaMixin:SetTargetFocusBorderEdges(border, borderSize, offset)
    borderSize = borderSize or 1
    offset     = offset     or 0

    border.top:SetIgnoreParentScale(true)
    border.right:SetIgnoreParentScale(true)
    border.bottom:SetIgnoreParentScale(true)
    border.left:SetIgnoreParentScale(true)

    -- Top edge
    border.top:ClearAllPoints()
    border.top:SetPoint("TOPLEFT",  border, "TOPLEFT")
    border.top:SetPoint("TOPRIGHT", border, "TOPRIGHT")
    border.top:SetHeight(borderSize)

    -- Right edge
    border.right:ClearAllPoints()
    border.right:SetPoint("TOPRIGHT",    border, "TOPRIGHT")
    border.right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    border.right:SetWidth(borderSize)

    -- Bottom edge
    border.bottom:ClearAllPoints()
    border.bottom:SetPoint("BOTTOMLEFT",  border, "BOTTOMLEFT")
    border.bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    border.bottom:SetHeight(borderSize)

    -- Left edge
    border.left:ClearAllPoints()
    border.left:SetPoint("TOPLEFT",    border, "TOPLEFT")
    border.left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
    border.left:SetWidth(borderSize)

    border.borderSize = borderSize
    border.baseOffset = offset
end

function sArenaFrameMixin:SetupTargetFocusBorder()
    local border = self.TargetFocusBorder
    local borderSize = 1
    local offset = 0

    local topAnchor    = self.HealthBar
    local bottomAnchor = self.PowerBar or self.HealthBar

    border:ClearAllPoints()
    border:SetPoint("TOPLEFT",     topAnchor,    "TOPLEFT",     -(offset + borderSize),  offset + borderSize)
    border:SetPoint("BOTTOMRIGHT", bottomAnchor, "BOTTOMRIGHT",  (offset + borderSize), -(offset + borderSize))

    self.parent:SetTargetFocusBorderEdges(border, borderSize, offset)
end

function sArenaFrameMixin:ApplyTargetFocusBorderSize(borderSize)
    local border = self.TargetFocusBorder
    border.top:SetHeight(borderSize)
    border.right:SetWidth(borderSize)
    border.bottom:SetHeight(borderSize)
    border.left:SetWidth(borderSize)
end

function sArenaFrameMixin:UpdateTargetFocusBorderAnchors(indicatorSettings)
    local border = self.TargetFocusBorder

    local borderSize = (indicatorSettings and indicatorSettings.borderSize) or border.borderSize or 1
    local baseOffset = border.baseOffset or 0
    local extraOffset = (indicatorSettings and indicatorSettings.borderOffset) or 0
    local offset = baseOffset + extraOffset
    local pad = offset + borderSize

    self:ApplyTargetFocusBorderSize(borderSize)

    local topAnchor = self.HealthBar
    local bottomAnchor = self.PowerBar

    local wrapClass = indicatorSettings and indicatorSettings.wrapClass
    local wrapTrinket = indicatorSettings and indicatorSettings.wrapTrinket
    local wrapRacial = indicatorSettings and indicatorSettings.wrapRacial

    -- Check if BlizzArena layout for vertical adjustment
    local db = self.parent.db
    local isBlizzArena = db and db.profile.currentLayout == "BlizzArena"
    local topPad = isBlizzArena and (pad + 1) or pad
    local bottomPad = isBlizzArena and (-pad + 1) or -pad

    -- If no wrap settings enabled, use simple bar anchoring
    if not wrapClass and not wrapTrinket and not wrapRacial then
        border:ClearAllPoints()
        border:SetPoint("TOPLEFT", topAnchor, "TOPLEFT", -pad, topPad)
        border:SetPoint("BOTTOMRIGHT", bottomAnchor, "BOTTOMRIGHT", pad, bottomPad)
        return
    end

    -- Figure out anchors
    local allFrames = { topAnchor }
    if bottomAnchor ~= topAnchor then
        allFrames[#allFrames + 1] = bottomAnchor
    end
    if wrapClass and self.ClassIcon then
        allFrames[#allFrames + 1] = self.ClassIcon
    end
    if wrapTrinket and self.Trinket then
        allFrames[#allFrames + 1] = self.Trinket
    end
    if wrapRacial and self.Racial then
        allFrames[#allFrames + 1] = self.Racial
    end

    local minLeft, maxTop, maxRight, minBottom
    local minLeftFrame, maxTopFrame, maxRightFrame, minBottomFrame

    for _, frame in ipairs(allFrames) do
        local left = frame and frame.GetLeft and frame:GetLeft()
        local right = frame and frame.GetRight and frame:GetRight()
        local top = frame and frame.GetTop and frame:GetTop()
        local bottom = frame and frame.GetBottom and frame:GetBottom()
        local scale = frame and frame.GetEffectiveScale and frame:GetEffectiveScale() or 1

        if left and right and top and bottom then
            left = left * scale
            right = right * scale
            top = top * scale
            bottom = bottom * scale

            if not minLeft or left < minLeft then
                minLeft = left
                minLeftFrame = frame
            end
            if not maxTop or top > maxTop then
                maxTop = top
                maxTopFrame = frame
            end
            if not maxRight or right > maxRight then
                maxRight = right
                maxRightFrame = frame
            end
            if not minBottom or bottom < minBottom then
                minBottom = bottom
                minBottomFrame = frame
            end
        end
    end

    if not minLeftFrame or not maxTopFrame or not maxRightFrame or not minBottomFrame then
        border:ClearAllPoints()
        border:SetPoint("TOPLEFT", topAnchor, "TOPLEFT", -pad, topPad)
        border:SetPoint("BOTTOMRIGHT", bottomAnchor, "BOTTOMRIGHT", pad, bottomPad)
        return
    end

    border:ClearAllPoints()
    border:SetPoint("LEFT", minLeftFrame, "LEFT", -pad, 0)
    border:SetPoint("RIGHT", maxRightFrame, "RIGHT", pad, 0)
    border:SetPoint("TOP", maxTopFrame, "TOP", 0, topPad)
    border:SetPoint("BOTTOM", minBottomFrame, "BOTTOM", 0, bottomPad)
end

function sArenaMixin:GetArenaFrameForDrag(frameToMove, isWidget)
    if isWidget then
        local overlay = frameToMove:GetParent()
        return overlay and overlay:GetParent()
    else
        return frameToMove:GetParent()
    end
end

function sArenaMixin:HideTargetFocusBorderForDrag(frameToMove, isWidget)
    local arenaFrame = self:GetArenaFrameForDrag(frameToMove, isWidget)
    if arenaFrame.TargetFocusBorder and arenaFrame.TargetFocusBorder:IsShown() then
        arenaFrame.TargetFocusBorder:ClearAllPoints()
        arenaFrame.TargetFocusBorder:Hide()
        frameToMove._borderWasHidden = true
    end
end

function sArenaMixin:RestoreTargetFocusBorderAfterDrag(frameToMove, isWidget)
    if frameToMove._borderWasHidden then
        frameToMove._borderWasHidden = nil
        local arenaFrame = self:GetArenaFrameForDrag(frameToMove, isWidget)
        if not arenaFrame.TargetFocusBorder then return end
        arenaFrame.TargetFocusBorder:Show()
        arenaFrame:UpdateTargetFocusBorderVisibility()
    end
end

function sArenaFrameMixin:SetTargetFocusBorderColor(r, g, b, a)
    local border = self.TargetFocusBorder
    border.top:SetColorTexture(r, g, b, a or 1)
    border.right:SetColorTexture(r, g, b, a or 1)
    border.bottom:SetColorTexture(r, g, b, a or 1)
    border.left:SetColorTexture(r, g, b, a or 1)
end

function sArenaFrameMixin:SetTargetFocusBorderDrawLayer(isTarget)
    local border = self.TargetFocusBorder
    local subLevel = isTarget and 6 or 5
    border.top:SetDrawLayer("OVERLAY", subLevel)
    border.right:SetDrawLayer("OVERLAY", subLevel)
    border.bottom:SetDrawLayer("OVERLAY", subLevel)
    border.left:SetDrawLayer("OVERLAY", subLevel)
end

function sArenaFrameMixin:UpdateTargetFocusBorderVisibility()
    local border = self.TargetFocusBorder
    local db = self.parent.db

    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    if not widgetSettings then
        border:Hide()
        return
    end

    local ti = widgetSettings.targetIndicator
    local fi = widgetSettings.focusIndicator
    local targetUseBorder = ti and ti.enabled and ti.useBorder
    local focusUseBorder = fi and fi.enabled and fi.useBorder

    if not targetUseBorder and not focusUseBorder then
        border:Hide()
        return
    end

    if self.parent.testMode and border:IsShown() then
        local id = self:GetID()
        if id == 1 and focusUseBorder then
            local c = fi.borderColor or {0, 0, 1, 1}
            self:SetTargetFocusBorderColor(c[1], c[2], c[3], c[4])
            self:SetTargetFocusBorderDrawLayer(false)
            self:UpdateTargetFocusBorderAnchors(fi)
        elseif id == 2 and targetUseBorder then
            local c = ti.borderColor or {1, 0.7, 0, 1}
            self:SetTargetFocusBorderColor(c[1], c[2], c[3], c[4])
            self:SetTargetFocusBorderDrawLayer(true)
            self:UpdateTargetFocusBorderAnchors(ti)
        end
        return
    end

    local unit = self.unit
    if not unit then
        border:Hide()
        return
    end

    local isTarget = targetUseBorder and UnitIsUnit(unit, "target")
    local isFocus = focusUseBorder and UnitIsUnit(unit, "focus")

    if isTarget then
        local c = ti.borderColor or {1, 0.7, 0, 1}
        self:SetTargetFocusBorderColor(c[1], c[2], c[3], c[4])
        self:SetTargetFocusBorderDrawLayer(true)
        self:UpdateTargetFocusBorderAnchors(ti)
        border:Show()
    elseif isFocus then
        local c = fi.borderColor or {0, 0, 1, 1}
        self:SetTargetFocusBorderColor(c[1], c[2], c[3], c[4])
        self:SetTargetFocusBorderDrawLayer(false)
        self:UpdateTargetFocusBorderAnchors(fi)
        border:Show()
    else
        border:Hide()
    end
end

function sArenaFrameMixin:CreateArenaTargetText()
    local overlay = self.WidgetOverlay
    if overlay.arenaTargetText then return end
    local textFrame = CreateFrame("Frame", nil, overlay)
    textFrame:SetSize(80, 14)
    textFrame:SetMovable(true)
    textFrame:EnableMouse(true)
    local fs = overlay:CreateFontString(nil, "OVERLAY")
    local nf, _, nflag = self.Name:GetFont()
    fs:SetFont(nf or self.parent.pFont, 10, nflag or "OUTLINE")
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
    fs:SetIgnoreParentAlpha(true)
    fs:SetText("")
    overlay.arenaTargetTextFrame = textFrame
    overlay.arenaTargetText = fs
end

function sArenaFrameMixin:PositionArenaTargetText()
    self:CreateArenaTargetText()
    local db = self.parent.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    local ptt = widgetSettings and widgetSettings.partyTargetText
    local poa = ptt and ptt.partyOnArena
    local textFrame = self.WidgetOverlay.arenaTargetTextFrame
    local fs = self.WidgetOverlay.arenaTargetText
    if not ptt or not ptt.enabled or not poa or not poa.enabled then
        fs:SetText("")
        return
    end
    local fontSize = poa.fontSize or 10
    local anchorMap = { LEFT = "TOPLEFT", CENTER = "TOP", RIGHT = "TOPRIGHT" }
    local anchor = anchorMap[poa.anchor] or "TOPRIGHT"
    local nf, _, nflag = self.Name:GetFont()
    fs:SetFont(nf or self.parent.pFont, fontSize, nflag or "OUTLINE")
    fs:ClearAllPoints()
    fs:SetPoint(anchor, self.HealthBar, anchor, poa.posX or 0, poa.posY or 0)
    textFrame:SetSize(80, fontSize + 4)
    textFrame:ClearAllPoints()
    textFrame:SetPoint(anchor, self.HealthBar, anchor, poa.posX or 0, poa.posY or 0)
end

function sArenaFrameMixin:UpdateArenaTargetText(unit)
    local fs = self.WidgetOverlay.arenaTargetText
    if not fs then return end
    local db = self.parent.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    local ptt = widgetSettings and widgetSettings.partyTargetText
    local poa = ptt and ptt.partyOnArena
    if not ptt or not ptt.enabled or not poa or not poa.enabled then
        fs:SetText("")
        return
    end
    if not unit or not UnitExists(unit) then
        fs:SetText("")
        return
    end
    local targetUnit = unit .. "target"
    local targetName = UnitName(targetUnit)
    if targetName then
        local class = UnitClassBase(targetUnit)
        local color = class and C_ClassColor.GetClassColor(class)
        if color then
            fs:SetTextColor(color.r, color.g, color.b)
        else
            fs:SetTextColor(1, 1, 1)
        end
        fs:SetText(targetName)
    else
        fs:SetText("")
    end
end

function sArenaFrameMixin:UpdateArenaTargetTextTestMode()
    local fs = self.WidgetOverlay.arenaTargetText
    if not fs then return end
    local db = self.parent.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    local ptt = widgetSettings and widgetSettings.partyTargetText
    local poa = ptt and ptt.partyOnArena
    if not ptt or not ptt.enabled or not poa or not poa.enabled then
        fs:SetText("")
        return
    end
    local name = UnitName("player")
    local class = UnitClassBase("player")
    local color = class and C_ClassColor.GetClassColor(class)
    if color then
        fs:SetTextColor(color.r, color.g, color.b)
    else
        fs:SetTextColor(1, 1, 1)
    end
    fs:SetText(name)
end

function sArenaMixin:CreatePartyFrameTargetText(partyFrame)
    if not partyFrame.WidgetOverlay then
        local overlay = CreateFrame("Frame", nil, partyFrame)
        overlay:SetFrameStrata("HIGH")
        overlay:SetFrameLevel(partyFrame:GetFrameLevel() + 10)
        partyFrame.WidgetOverlay = overlay
    end
    partyFrame.WidgetOverlay:SetParent(partyFrame)
    partyFrame.WidgetOverlay:ClearAllPoints()
    partyFrame.WidgetOverlay:SetAllPoints()
    local overlay = partyFrame.WidgetOverlay
    if overlay.partyTargetText then return end
    local textFrame = CreateFrame("Frame", nil, overlay)
    textFrame:SetSize(80, 14)
    textFrame:SetMovable(true)
    textFrame:EnableMouse(true)
    local fs = overlay:CreateFontString(nil, "OVERLAY")
    local refName = self["arena1"] and self["arena1"].Name
    local nf, _, nflag = refName and refName:GetFont()
    fs:SetFont(nf or self.pFont, 10, nflag or "OUTLINE")
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
    fs:SetIgnoreParentAlpha(true)
    fs:SetText("")
    overlay.partyTargetTextFrame = textFrame
    overlay.partyTargetText = fs
end

function sArenaMixin:PositionArenaTargetTextOnPartyFrames()
    local db = self.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    local ptt = widgetSettings and widgetSettings.partyTargetText
    local aop = ptt and ptt.arenaOnParty
    if not ptt or not ptt.enabled or not aop or not aop.enabled then
        for i = 1, 5 do
            local partyFrame = self:GetPartyFrame(i)
            if partyFrame and partyFrame.WidgetOverlay and partyFrame.WidgetOverlay.partyTargetText then
                partyFrame.WidgetOverlay.partyTargetText:SetText("")
            end
        end
        return
    end
    local fontSize = aop.fontSize or 10
    local anchorMap = { LEFT = "TOPLEFT", CENTER = "TOP", RIGHT = "TOPRIGHT" }
    local anchor = anchorMap[aop.anchor] or "TOPRIGHT"
    local posX = aop.posX or 0
    local posY = aop.posY or 0
    for i = 1, 5 do
        local partyFrame = self:GetPartyFrame(i)
        if partyFrame then
            self:CreatePartyFrameTargetText(partyFrame)
            self:SetupDrag(partyFrame, partyFrame, "partyTargetText", nil, "widget", "arenaOnParty", partyFrame)
            local overlay = partyFrame.WidgetOverlay
            local textFrame = overlay.partyTargetTextFrame
            local fs = overlay.partyTargetText
            local refName = self["arena1"] and self["arena1"].Name
            local nf, _, nflag = refName and refName:GetFont()
            fs:SetFont(nf or self.pFont, fontSize, nflag or "OUTLINE")
            fs:ClearAllPoints()
            fs:SetPoint(anchor, overlay, anchor, posX, posY)
            textFrame:SetSize(80, fontSize + 4)
            textFrame:ClearAllPoints()
            textFrame:SetPoint(anchor, overlay, anchor, posX, posY)
        end
    end
end

function sArenaMixin:UpdateArenaTargetTextOnPartyFrames()
    if self.suppressPartyTextUpdate then return end
    local db = self.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    local ptt = widgetSettings and widgetSettings.partyTargetText
    local aop = ptt and ptt.arenaOnParty
    if (not ptt or not ptt.enabled or not aop or not aop.enabled) or (not self:IsInArena() and (not aop or not aop.alwaysOn)) then
        for i = 1, 5 do
            local partyFrame = self:GetPartyFrame(i)
            if partyFrame and partyFrame.WidgetOverlay and partyFrame.WidgetOverlay.partyTargetText then
                partyFrame.WidgetOverlay.partyTargetText:SetText("")
            end
        end
        return
    end
    for i = 1, 5 do
        local partyFrame = self:GetPartyFrame(i)
        if partyFrame then
            self:CreatePartyFrameTargetText(partyFrame)
            local fs = partyFrame.WidgetOverlay.partyTargetText
            if fs then
                local partyUnit = partyFrame.unit or partyFrame:GetAttribute("unit")
                if partyUnit and UnitExists(partyUnit) then
                    local targetUnit = partyUnit .. "target"
                    local targetName = UnitName(targetUnit)
                    if targetName then
                        local class = UnitClassBase(targetUnit)
                        local color = class and C_ClassColor.GetClassColor(class)
                        if class and color then
                            fs:SetTextColor(color.r, color.g, color.b)
                        else
                            fs:SetTextColor(1, 1, 1)
                        end
                        fs:SetText(targetName)
                    else
                        fs:SetText("")
                    end
                else
                    fs:SetText("")
                end
            end
        end
    end
end

function sArenaMixin:UpdateArenaTargetTextOnPartyFramesTestMode()
    if self.suppressPartyTextUpdate then return end
    local numArena = self.maxArenaOpponents or 3
    for i = 1, 5 do
        local partyFrame = self:GetPartyFrame(i)
        if partyFrame and partyFrame.WidgetOverlay then
            local fs = partyFrame.WidgetOverlay.partyTargetText
            if fs then
                local pick = self["arena" .. math.random(numArena)]
                local name = pick and pick.tempName or "Target"
                local class = pick and pick.tempClass
                local color = class and C_ClassColor.GetClassColor(class)
                if class and color then
                    fs:SetTextColor(color.r, color.g, color.b)
                else
                    fs:SetTextColor(1, 1, 1)
                end
                fs:SetText(name)
            end
        end
    end
end

function sArenaFrameMixin:UpdateArenaTargets(unit)
    local db = self.parent.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    local pet = self.PetFrame
    local pws = pet and pet:GetWidgetSettings()
    local petOverlay = pet and pet.WidgetOverlay
    local pti = pws and pws.partyTargetIndicators
    local petEnabled = pti and pti.enabled and pet and pet:IsShown() and petOverlay

    if not widgetSettings or not widgetSettings.partyTargetIndicators
       or not widgetSettings.partyTargetIndicators.enabled
       or not widgetSettings.partyTargetIndicators.partyOnArena
       or not widgetSettings.partyTargetIndicators.partyOnArena.enabled then
        for i = 1, 4 do
            self.WidgetOverlay["partyTarget" .. i]:Hide()
        end
        if not petEnabled then
            if petOverlay then
                for i = 1, 4 do
                    local ind = petOverlay["partyTarget" .. i]
                    if ind then ind:Hide() end
                end
            end
            return
        end
    end

    local UnitIsUnitSafe = isMidnight and UnitIsProbablyUnit or UnitIsUnit

    -- Arena (player) frame indicators
    local arenaTargets = {}
    if widgetSettings and widgetSettings.partyTargetIndicators
       and widgetSettings.partyTargetIndicators.enabled
       and widgetSettings.partyTargetIndicators.partyOnArena
       and widgetSettings.partyTargetIndicators.partyOnArena.enabled
       and unit and UnitExists(unit) then
        for i = 1, 4 do
            if UnitIsUnitSafe("party" .. i .. "target", unit) then
                table.insert(arenaTargets, "party" .. i)
            end
        end
        for i = 1, 4 do
            local indicator = self.WidgetOverlay["partyTarget" .. i]
            if arenaTargets[i] then
                local class = UnitClassBase(arenaTargets[i])
                if class then
                    local color = C_ClassColor.GetClassColor(class)
                    if color then
                        indicator.Texture:SetVertexColor(color.r, color.g, color.b)
                    end
                end
                indicator:Show()
            else
                indicator:Hide()
            end
        end
    end

    if petEnabled then
        local petUnit = pet.unit
        local petTargets = {}
        if petUnit and UnitExists(petUnit) then
            for i = 1, 4 do
                if UnitIsUnitSafe("party" .. i .. "target", petUnit) then
                    table.insert(petTargets, "party" .. i)
                end
            end
        end
        for i = 1, 4 do
            local indicator = petOverlay["partyTarget" .. i]
            if indicator then
                if petTargets[i] then
                    local class = UnitClassBase(petTargets[i])
                    if class then
                        local color = C_ClassColor.GetClassColor(class)
                        if color then
                            indicator.Texture:SetVertexColor(color.r, color.g, color.b)
                        end
                    end
                    indicator:Show()
                else
                    indicator:Hide()
                end
            end
        end
    end
end

function sArenaMixin:CreatePartyFrameIndicators(partyFrame)
    if not partyFrame.WidgetOverlay then
        local overlay = CreateFrame("Frame", nil, partyFrame)
        overlay:SetAllPoints()
        overlay:SetFrameStrata("HIGH")
        overlay:SetFrameLevel(partyFrame:GetFrameLevel() + 10)
        partyFrame.WidgetOverlay = overlay
    else
        partyFrame.WidgetOverlay:SetParent(partyFrame)
    end

    if partyFrame.WidgetOverlay.arenaTarget1 then return end

    local overlay = partyFrame.WidgetOverlay
    for i = 1, self.maxArenaOpponents do
        local indicator = CreateFrame("Frame", nil, overlay)
        indicator:SetSize(15, 15)
        indicator:SetMovable(true)
        indicator:EnableMouse(true)
        indicator:Hide()
        indicator:SetIgnoreParentAlpha(true)

        local texture = indicator:CreateTexture(nil, "OVERLAY")
        texture:SetAllPoints()
        texture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\GM-icon-headCount.tga")
        texture:SetDesaturated(true)
        indicator.Texture = texture

        overlay["arenaTarget" .. i] = indicator
    end
end

function sArenaMixin:RepositionPartyFrameIndicators(partyFrame, direction, spacing, posX, posY)
    local overlay = partyFrame.WidgetOverlay
    if not overlay then return end

    local first = overlay.arenaTarget1
    first:ClearAllPoints()
    first:SetPoint("TOPRIGHT", partyFrame, "TOPRIGHT", posX or 0, (posY or 0) -0.5)
    for i = 2, self.maxArenaOpponents do
        self:ChainIndicator(overlay["arenaTarget" .. i], overlay["arenaTarget" .. (i - 1)], direction, spacing or 1)
    end
end

function sArenaMixin:UpdateArenaTargetsOnPartyFrames()
    local db = self.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    if not widgetSettings or not widgetSettings.partyTargetIndicators
       or not widgetSettings.partyTargetIndicators.enabled
       or not widgetSettings.partyTargetIndicators.arenaOnParty
       or not widgetSettings.partyTargetIndicators.arenaOnParty.enabled then
        for i = 1, 5 do
            local partyFrame = self:GetPartyFrame(i)
            if partyFrame and partyFrame.WidgetOverlay then
                for j = 1, self.maxArenaOpponents do
                    local indicator = partyFrame.WidgetOverlay["arenaTarget" .. j]
                    if indicator then indicator:Hide() end
                end
            end
        end
        return
    end

    local aop = widgetSettings.partyTargetIndicators.arenaOnParty
    local arenaDirection = aop.direction or "LEFT"
    local arenaSpacing = aop.spacing or 1
    local arenaScale = aop.scale or 1
    local aopPosX = aop.posX or 0
    local aopPosY = aop.posY or 0

    for i = 1, 5 do
        local partyFrame = self:GetPartyFrame(i)
        if partyFrame then
            self:CreatePartyFrameIndicators(partyFrame)
            local ov = partyFrame.WidgetOverlay
            ov.arenaTarget1.useCursorDelta = true
            self:SetupDrag(ov.arenaTarget1, ov.arenaTarget1, "partyTargetIndicators", nil, "widget", "arenaOnParty")
            for j = 2, self.maxArenaOpponents do
                self:SetupDrag(ov["arenaTarget" .. j], ov.arenaTarget1, "partyTargetIndicators", nil, "widget", "arenaOnParty")
            end
            self:RepositionPartyFrameIndicators(partyFrame, arenaDirection, arenaSpacing, aopPosX, aopPosY)

            for j = 1, self.maxArenaOpponents do
                partyFrame.WidgetOverlay["arenaTarget" .. j]:SetScale(arenaScale)
            end

            if self.testMode then
                for j = 1, self.maxArenaOpponents do
                    local indicator = partyFrame.WidgetOverlay["arenaTarget" .. j]
                    indicator:Show()
                    indicator:SetAlpha(1)
                end
            else
                local partyUnit = partyFrame.unit or partyFrame:GetAttribute("unit")
                if partyUnit and UnitExists(partyUnit) then
                    local attackers = {}
                    local UnitIsUnitSafe = isMidnight and UnitIsProbablyUnit or UnitIsUnit
                    for j = 1, self.maxArenaOpponents do
                        local arenaUnit = "arena" .. j
                        if UnitExists(arenaUnit) and UnitIsUnitSafe(arenaUnit .. "target", partyUnit) then
                            table.insert(attackers, arenaUnit)
                        end
                    end

                    for j = 1, self.maxArenaOpponents do
                        local indicator = partyFrame.WidgetOverlay["arenaTarget" .. j]
                        if attackers[j] then
                            local class = UnitClassBase(attackers[j])
                            if class then
                                local color = C_ClassColor.GetClassColor(class)
                                if color then
                                    indicator.Texture:SetVertexColor(color.r, color.g, color.b)
                                end
                            end
                            indicator:Show()
                        else
                            indicator:Hide()
                        end
                    end
                else
                    for j = 1, self.maxArenaOpponents do
                        partyFrame.WidgetOverlay["arenaTarget" .. j]:Hide()
                    end
                end
            end
        end
    end
end
