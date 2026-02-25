-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local isMidnight = sArenaMixin.isMidnight

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

        if widgetSettings.partyTargetIndicators and widgetSettings.partyTargetIndicators.enabled then
            self:RegisterEvent("UNIT_TARGET")
        end

        if widgetSettings.combatIndicator and widgetSettings.combatIndicator.enabled then
            for i = 1, sArenaMixin.maxArenaOpponents do
                local frame = self["arena" .. i]
                local unit = frame.unit
                self:RegisterUnitEvent("UNIT_FLAGS", unit)
            end
        end
    end
end

function sArenaMixin:UnregisterWidgetEvents()
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
    self:UnregisterEvent("UNIT_TARGET")
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        local unit = frame.unit
        self:UnregisterEvent("UNIT_FLAGS", unit)
    end
end

function sArenaMixin:UpdateWidgetSettings(db, info, val)

    self:UnregisterWidgetEvents()
    self:RegisterWidgetEvents()

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]


        if db.combatIndicator then frame.WidgetOverlay.combatIndicator:SetScale(db.combatIndicator.scale or 1) end
        if db.targetIndicator then frame.WidgetOverlay.targetIndicator:SetScale(db.targetIndicator.scale or 1) end
        if db.focusIndicator then frame.WidgetOverlay.focusIndicator:SetScale(db.focusIndicator.scale or 1) end
        if db.partyTargetIndicators then
            frame.WidgetOverlay.partyTarget1:SetScale(db.partyTargetIndicators.scale or 1)
            frame.WidgetOverlay.partyTarget2:SetScale(db.partyTargetIndicators.scale or 1)
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
end

function sArenaFrameMixin:UpdateCombatStatus(unit)
    local db = self.parent.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    if not widgetSettings or not widgetSettings.combatIndicator or not widgetSettings.combatIndicator.enabled then
        self.WidgetOverlay.combatIndicator:Hide()
        return
    end
    self.WidgetOverlay.combatIndicator:SetShown((unit and not UnitAffectingCombat(unit) and not self.DeathIcon:IsShown()))
end

function sArenaFrameMixin:UpdateTarget(unit)
    local db = self.parent.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    local ti = widgetSettings and widgetSettings.targetIndicator
    local useBorder = ti and ti.useBorder
    local useBoth = ti and ti.useBorderWithIcon

    local showIcon = false
    if ti and ti.enabled then
        if not useBorder or useBoth then
            showIcon = unit and UnitIsUnit(unit, "target")
        end
    end
    self.WidgetOverlay.targetIndicator:SetShown(showIcon)

    self:UpdateTargetFocusBorderVisibility()
end

function sArenaFrameMixin:UpdateFocus(unit)
    local db = self.parent.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    local fi = widgetSettings and widgetSettings.focusIndicator
    local useBorder = fi and fi.useBorder
    local useBoth = fi and fi.useBorderWithIcon

    local showIcon = false
    if fi and fi.enabled then
        if not useBorder or useBoth then
            showIcon = unit and UnitIsUnit(unit, "focus")
        end
    end
    self.WidgetOverlay.focusIndicator:SetShown(showIcon)

    self:UpdateTargetFocusBorderVisibility()
end

function sArenaFrameMixin:SetupTargetFocusBorder()
    local border = self.TargetFocusBorder
    local borderSize = 1
    local offset = 0

    border:SetFrameLevel(self:GetFrameLevel() + 10)

    border.top:SetIgnoreParentScale(true)
    border.right:SetIgnoreParentScale(true)
    border.bottom:SetIgnoreParentScale(true)
    border.left:SetIgnoreParentScale(true)

    local topAnchor = self.HealthBar
    local bottomAnchor = self.PowerBar

    border:ClearAllPoints()
    border:SetPoint("TOPLEFT", topAnchor, "TOPLEFT", -(offset + borderSize), offset + borderSize)
    border:SetPoint("BOTTOMRIGHT", bottomAnchor, "BOTTOMRIGHT", offset + borderSize, -(offset + borderSize))

    -- Top edge
    border.top:ClearAllPoints()
    border.top:SetPoint("TOPLEFT", border, "TOPLEFT")
    border.top:SetPoint("TOPRIGHT", border, "TOPRIGHT")
    border.top:SetHeight(borderSize)

    -- Right edge
    border.right:ClearAllPoints()
    border.right:SetPoint("TOPRIGHT", border, "TOPRIGHT")
    border.right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    border.right:SetWidth(borderSize)

    -- Bottom edge
    border.bottom:ClearAllPoints()
    border.bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
    border.bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    border.bottom:SetHeight(borderSize)

    -- Left edge
    border.left:ClearAllPoints()
    border.left:SetPoint("TOPLEFT", border, "TOPLEFT")
    border.left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
    border.left:SetWidth(borderSize)

    border.borderSize = borderSize
    border.baseOffset = offset
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

function sArenaFrameMixin:UpdatePartyTargets(unit)
    local db = self.parent.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    if not widgetSettings or not widgetSettings.partyTargetIndicators or not widgetSettings.partyTargetIndicators.enabled then
        self.WidgetOverlay.partyTarget1:Hide()
        self.WidgetOverlay.partyTarget2:Hide()
        return
    end

    if not unit or not UnitExists(unit) then return end

    if isMidnight then
        local isParty1Target = UnitIsUnit("party1target", unit)
        local isParty2Target = UnitIsUnit("party2target", unit)

        local class1 = select(2, UnitClass("party1"))
        if class1 then
            local color = RAID_CLASS_COLORS[class1]
            self.WidgetOverlay.partyTarget1.Texture:SetVertexColor(color.r, color.g, color.b)
        end

        local class2 = select(2, UnitClass("party2"))
        if class2 then
            local color = RAID_CLASS_COLORS[class2]
            self.WidgetOverlay.partyTarget2.Texture:SetVertexColor(color.r, color.g, color.b)
        end

        self.WidgetOverlay.partyTarget1:Show()
        self.WidgetOverlay.partyTarget2:Show()
        self.WidgetOverlay.partyTarget1:SetAlphaFromBoolean(isParty1Target, 1, 0)
        self.WidgetOverlay.partyTarget2:SetAlphaFromBoolean(isParty2Target, 1, 0)
    else
        local targets = {}
        if UnitIsUnit("party1target", unit) then
            table.insert(targets, "party1")
        end
        if UnitIsUnit("party2target", unit) then
            table.insert(targets, "party2")
        end

        -- Update Icons Based on Targets Found
        if #targets >= 1 then
            local class1 = select(2, UnitClass(targets[1]))
            if class1 then
                local color = RAID_CLASS_COLORS[class1]
                self.WidgetOverlay.partyTarget1.Texture:SetVertexColor(color.r, color.g, color.b)
            end
            self.WidgetOverlay.partyTarget1:Show()
        else
            self.WidgetOverlay.partyTarget1:Hide()
        end

        if #targets >= 2 then
            local class2 = select(2, UnitClass(targets[2]))
            if class2 then
                local color = RAID_CLASS_COLORS[class2]
                self.WidgetOverlay.partyTarget2.Texture:SetVertexColor(color.r, color.g, color.b)
            end
            self.WidgetOverlay.partyTarget2:Show()
        else
            self.WidgetOverlay.partyTarget2:Hide()
        end
    end
end
