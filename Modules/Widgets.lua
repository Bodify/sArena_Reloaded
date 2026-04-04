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
        if pti and pti.enabled and ((pti.partyOnArena and pti.partyOnArena.enabled) or (pti.arenaOnParty and pti.arenaOnParty.enabled)) then
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
    self:UnregisterEvent("UNIT_TARGET")
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
        if db.targetIndicator then frame.WidgetOverlay.targetIndicator:SetScale(db.targetIndicator.scale or 1) end
        if db.focusIndicator then frame.WidgetOverlay.focusIndicator:SetScale(db.focusIndicator.scale or 1) end
        if db.partyTargetIndicators then
            local poaScale = db.partyTargetIndicators.partyOnArena and db.partyTargetIndicators.partyOnArena.scale or 1
            for j = 1, 4 do
                frame.WidgetOverlay["partyTarget" .. j]:SetScale(poaScale)
            end
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

    border:SetFrameLevel(self:GetFrameLevel() + 8)

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

function sArenaFrameMixin:UpdateArenaTargets(unit)
    local db = self.parent.db
    local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
    if not widgetSettings or not widgetSettings.partyTargetIndicators
       or not widgetSettings.partyTargetIndicators.enabled
       or not widgetSettings.partyTargetIndicators.partyOnArena
       or not widgetSettings.partyTargetIndicators.partyOnArena.enabled then
        for i = 1, 4 do
            self.WidgetOverlay["partyTarget" .. i]:Hide()
        end
        return
    end

    if not unit or not UnitExists(unit) then return end

    if isMidnight then
        for i = 1, 4 do
            local partyUnit = "party" .. i
            local indicator = self.WidgetOverlay["partyTarget" .. i]
            local isTarget = UnitIsUnit(partyUnit .. "target", unit)
            local class = select(2, UnitClass(partyUnit))
            if class then
                local color = RAID_CLASS_COLORS[class]
                indicator.Texture:SetVertexColor(color.r, color.g, color.b)
            end
            if isTarget ~= nil then
                indicator:Show()
                indicator:SetAlphaFromBoolean(isTarget, 1, 0)
            else
                indicator:Hide()
            end
        end
    else
        local targets = {}
        for i = 1, 4 do
            if UnitIsUnit("party" .. i .. "target", unit) then
                table.insert(targets, "party" .. i)
            end
        end

        for i = 1, 4 do
            local indicator = self.WidgetOverlay["partyTarget" .. i]
            if targets[i] then
                local class = select(2, UnitClass(targets[i]))
                if class then
                    local color = RAID_CLASS_COLORS[class]
                    indicator.Texture:SetVertexColor(color.r, color.g, color.b)
                end
                indicator:Show()
            else
                indicator:Hide()
            end
        end
    end
end

function sArenaMixin:CreatePartyFrameIndicators(partyFrame)
    if partyFrame.WidgetOverlay then return end

    local overlay = CreateFrame("Frame", nil, partyFrame)
    overlay:SetAllPoints()
    overlay:SetFrameStrata("HIGH")
    overlay:SetFrameLevel(partyFrame:GetFrameLevel() + 10)
    partyFrame.WidgetOverlay = overlay

    for i = 1, self.maxArenaOpponents do
        local indicator = CreateFrame("Frame", nil, overlay)
        indicator:SetSize(15, 15)
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
                    partyFrame.WidgetOverlay["arenaTarget" .. j]:Hide()
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
                if isMidnight then
                    for j = 1, self.maxArenaOpponents do
                        local arenaUnit = "arena" .. j
                        local indicator = partyFrame.WidgetOverlay["arenaTarget" .. j]
                        local isTarget = UnitExists(arenaUnit) and UnitIsUnit(arenaUnit .. "target", partyUnit)
                        local class = select(2, UnitClass(arenaUnit))
                        if class then
                            local color = RAID_CLASS_COLORS[class]
                            indicator.Texture:SetVertexColor(color.r, color.g, color.b)
                        end
                        if isTarget ~= nil then
                            indicator:Show()
                            indicator:SetAlphaFromBoolean(isTarget, 1, 0)
                        else
                            indicator:Hide()
                        end
                    end
                else
                    local attackers = {}
                    for j = 1, self.maxArenaOpponents do
                        local arenaUnit = "arena" .. j
                        if UnitExists(arenaUnit) and UnitIsUnit(arenaUnit .. "target", partyUnit) then
                            table.insert(attackers, arenaUnit)
                        end
                    end

                    for j = 1, self.maxArenaOpponents do
                        local indicator = partyFrame.WidgetOverlay["arenaTarget" .. j]
                        if attackers[j] then
                            local class = select(2, UnitClass(attackers[j]))
                            if class then
                                local color = RAID_CLASS_COLORS[class]
                                indicator.Texture:SetVertexColor(color.r, color.g, color.b)
                            end
                            indicator:Show()
                        else
                            indicator:Hide()
                        end
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
