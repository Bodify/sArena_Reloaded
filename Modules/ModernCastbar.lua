-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local isMidnight = sArenaMixin.isMidnight

function sArenaMixin:ModernOrClassicCastbar()
    local db = self.db
    local layoutSettings = db.profile.layoutSettings[db.profile.currentLayout]
    local useModern = layoutSettings.castBar.useModernCastbars
    local simpleCastbar = layoutSettings.castBar.simpleCastbar
    local castbarSettings = layoutSettings.castBar

    if isMidnight then
        for i = 1, self.maxArenaOpponents do
            local frame = _G["sArenaEnemyFrame" .. i]
            local newBar = frame.CastBar

            if useModern then
                local castTexture = newBar:GetStatusBarTexture()
                if not newBar.MaskTexture then
                    newBar.MaskTexture = newBar:CreateMaskTexture()
                end
                newBar.MaskTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\RetailCastMask.tga",
                    "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                newBar.MaskTexture:SetPoint("TOPLEFT", newBar, "TOPLEFT", -1, 0)
                newBar.MaskTexture:SetPoint("BOTTOMRIGHT", newBar, "BOTTOMRIGHT", 1, 0)
                newBar.MaskTexture:Show()
                castTexture:AddMaskTexture(newBar.MaskTexture)

                newBar.__modernHooked = true

                if self:DarkMode() then
                    local darkModeColor = self:DarkModeColor()
                    newBar.TextBorder:SetDesaturated(true)
                    newBar.TextBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
                    newBar.Border:SetDesaturated(true)
                    newBar.Border:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
                end

                newBar.Border:SetAlpha(1)
                if simpleCastbar then
                    newBar.Text:ClearAllPoints()
                    newBar.Text:SetPoint("CENTER", newBar, "CENTER", 0, 0)
                    newBar.TextBorder:SetAlpha(0)
                else
                    newBar.Text:ClearAllPoints()
                    newBar.Text:SetPoint("BOTTOM", newBar, 0, -14)
                    newBar.TextBorder:SetAlpha(1)
                end
                newBar.Background:SetAtlas("UI-CastingBar-Background")
                newBar:SetHeight(9)
                newBar.Icon:SetSize(20,20)
                if newBar.ArenaTargetHighlight then
                    newBar.ArenaTargetHighlight:ClearAllPoints()
                    newBar.ArenaTargetHighlight:SetPoint("TOPLEFT", -3, 4)
                    newBar.ArenaTargetHighlight:SetPoint("BOTTOMRIGHT", 3, -4)
                end
            else
                newBar.Text:ClearAllPoints()
                newBar.Text:SetPoint("CENTER", newBar, "CENTER", 0, 0)
                newBar:SetHeight(16)
                newBar.TextBorder:SetAlpha(0)
                newBar.Border:SetAlpha(0)
                newBar.Icon:SetSize(16,16)
                newBar.Background:SetColorTexture(0,0,0,0.5)
                if newBar.MaskTexture then
                    newBar.MaskTexture:Hide()
                end
                if newBar.ArenaTargetHighlight then
                    newBar.ArenaTargetHighlight:ClearAllPoints()
                    newBar.ArenaTargetHighlight:SetPoint("TOPLEFT", -2, 2)
                    newBar.ArenaTargetHighlight:SetPoint("BOTTOMRIGHT", 2, -2)
                end
            end
            newBar.Spark:SetSize(3, 20)

            newBar:SetParent(frame)

            if i == self.maxArenaOpponents then
                self:UpdateCastBarSettings(castbarSettings)
                self:UpdateFonts()
            end
            local fontName, s = frame.CastBar.Text:GetFont()
            frame.CastBar.Text:SetFont(fontName, s, "THINOUTLINE")
            self:SetupDrag(frame.CastBar, frame.CastBar, "castBar", "UpdateCastBarSettings")
            frame.CastBar:SetFrameLevel(7)
        end

        local currentLayout = self.layouts[db.profile.currentLayout]
        if currentLayout and currentLayout.UpdateOrientation then
            for i = 1, self.maxArenaOpponents do
                local frame = _G["sArenaEnemyFrame" .. i]
                if frame then
                    currentLayout:UpdateOrientation(frame)
                end
            end
        end
    else
        for i = 1, self.maxArenaOpponents do
            local frame = _G["sArenaEnemyFrame" .. i]
            if (frame and useModern) or frame.CastBar.__modernHooked then
                local unit = "arena"..i
                self:ApplyCastbarStyle(frame, unit, useModern, simpleCastbar)
                if i == self.maxArenaOpponents then
                    self:UpdateCastBarSettings(castbarSettings)
                    self:UpdateFonts()
                end
                local fontName, s = frame.CastBar.Text:GetFont()
                frame.CastBar.Text:SetFont(fontName, s, "THINOUTLINE")
                self:SetupDrag(frame.CastBar, frame.CastBar, "castBar", "UpdateCastBarSettings")
                frame.CastBar:SetFrameLevel(7)
            end
        end

        local currentLayout = self.layouts[db.profile.currentLayout]
        if currentLayout and currentLayout.UpdateOrientation then
            for i = 1, self.maxArenaOpponents do
                local frame = _G["sArenaEnemyFrame" .. i]
                if frame then
                    currentLayout:UpdateOrientation(frame)
                end
            end
        end
    end
end

function sArenaFrameMixin:SetupMidnightCastBarDrag()
    local midnightCastBarMoveFrame = CreateFrame("Frame", nil, self)
    midnightCastBarMoveFrame:SetMovable(true)
    midnightCastBarMoveFrame:EnableMouse(true)
    midnightCastBarMoveFrame:SetAllPoints(self.CastBar)
    midnightCastBarMoveFrame:SetFrameLevel(self.CastBar:GetFrameLevel() + 5)
    self.midnightCastBarMoveFrame = midnightCastBarMoveFrame

    self.parent:SetupDrag(midnightCastBarMoveFrame, midnightCastBarMoveFrame, "castBar", "UpdateCastBarSettings")

    local frame = self
    local dragOffsetX, dragOffsetY = 0, 0

    local function castBarDragOnUpdate(moveFrame, dt)
        local moveFrameX, moveFrameY = moveFrame:GetCenter()
        local parentX, parentY = frame:GetCenter()
        local castBarScale = frame.CastBar:GetScale()

        local offsetX = floor(((moveFrameX - parentX) / castBarScale) * 10 + 0.5) / 10 + dragOffsetX
        local offsetY = floor(((moveFrameY - parentY) / castBarScale) * 10 + 0.5) / 10 + dragOffsetY

        frame.CastBar:ClearAllPoints()
        frame.CastBar:SetPoint("CENTER", frame, "CENTER", offsetX, offsetY)
    end

    midnightCastBarMoveFrame:HookScript("OnMouseDown", function()
        local cbX, cbY = frame.CastBar:GetCenter()
        local parentX, parentY = frame:GetCenter()
        local castBarScale = frame.CastBar:GetScale()
        local moveX, moveY = midnightCastBarMoveFrame:GetCenter()

        local curOffsetX = (cbX * castBarScale - parentX) / castBarScale
        local curOffsetY = (cbY * castBarScale - parentY) / castBarScale

        local moveFrameOffsetX = (moveX - parentX) / castBarScale
        local moveFrameOffsetY = (moveY - parentY) / castBarScale

        dragOffsetX = floor((curOffsetX - moveFrameOffsetX) * 10 + 0.5) / 10
        dragOffsetY = floor((curOffsetY - moveFrameOffsetY) * 10 + 0.5) / 10

        midnightCastBarMoveFrame:SetScript("OnUpdate", castBarDragOnUpdate)
    end)

    midnightCastBarMoveFrame:HookScript("OnMouseUp", function()
        midnightCastBarMoveFrame:SetScript("OnUpdate", nil)
        local moveFrameX, moveFrameY = midnightCastBarMoveFrame:GetCenter()
        local parentX, parentY = frame:GetCenter()
        local castBarScale = frame.CastBar:GetScale()

        local offsetX = floor(((moveFrameX - parentX) / castBarScale) * 10 + 0.5) / 10 + dragOffsetX
        local offsetY = floor(((moveFrameY - parentY) / castBarScale) * 10 + 0.5) / 10 + dragOffsetY

        local settings = frame.parent.db.profile.layoutSettings[frame.parent.db.profile.currentLayout].castBar
        settings.posX = offsetX
        settings.posY = offsetY
        frame.parent:UpdateCastBarSettings(settings)

        dragOffsetX, dragOffsetY = 0, 0
        midnightCastBarMoveFrame:ClearAllPoints()
        midnightCastBarMoveFrame:SetAllPoints(frame.CastBar)
    end)
end

function sArenaMixin:CreateCastbarIDText()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local castBar = frame.CastBar
        if castBar and not castBar.ArenaIDText then
            local idText = castBar:CreateFontString(nil, "OVERLAY")

            local fontFile, fontSize, fontFlags = castBar.Text:GetFont()
            idText:SetFont(fontFile, fontSize, fontFlags)
            local r, g, b, a = castBar.Text:GetTextColor()
            idText:SetTextColor(r, g, b, a)
            local sr, sg, sb, sa = castBar.Text:GetShadowColor()
            idText:SetShadowColor(sr, sg, sb, sa)
            local sx, sy = castBar.Text:GetShadowOffset()
            idText:SetShadowOffset(sx, sy)
            idText:SetJustifyH(castBar.Text:GetJustifyH())
            idText:SetJustifyV(castBar.Text:GetJustifyV())
            idText:Hide()
            castBar.ArenaIDText = idText
        end
    end
end

function sArenaMixin:UpdateCastbarIDText()
    local db = self.db
    if not db then return end

    local showID = db.profile.showCastbarID
    local layoutSettings = db.profile.layoutSettings[db.profile.currentLayout]
    local textSettings = layoutSettings and layoutSettings.textSettings

    local idAnchor = textSettings and textSettings.castbarIDAnchor or "LEFT"
    local idOffsetX = textSettings and textSettings.castbarIDOffsetX or 0
    local idOffsetY = textSettings and textSettings.castbarIDOffsetY or 0
    local idSize = textSettings and textSettings.castbarIDSize or 1.0

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local castBar = frame.CastBar
        if castBar and castBar.ArenaIDText then
            local idText = castBar.ArenaIDText

            if not showID then
                idText:Hide()
                idText:SetText("")
            else
                idText:ClearAllPoints()
                idText:SetScale(idSize)

                if idAnchor == "LEFT" then
                    idText:SetPoint("RIGHT", castBar.Text, "LEFT", -2 + idOffsetX, idOffsetY)
                    idText:SetText(i .. " -")
                elseif idAnchor == "RIGHT" then
                    idText:SetPoint("LEFT", castBar.Text, "RIGHT", 2 + idOffsetX, idOffsetY)
                    idText:SetText("- " .. i)
                else -- CENTER
                    idText:SetPoint("CENTER", castBar.Text, "CENTER", idOffsetX, idOffsetY)
                    idText:SetText(tostring(i))
                end

                idText:Show()
            end
        end
    end
end

function sArenaMixin:CreateCastbarHighlight()
    if not isMidnight then return end
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local castBar = frame.CastBar
        if castBar and not castBar.ArenaTargetHighlight then
            castBar.ArenaTargetHighlight = castBar:CreateTexture(nil, "OVERLAY", nil, 7)
            castBar.ArenaTargetHighlight:SetAtlas("ui-hud-nameplates-targetedbyenemy")
            castBar.ArenaTargetHighlight:SetPoint("TOPLEFT", -2.5, 2)
            castBar.ArenaTargetHighlight:SetPoint("BOTTOMRIGHT", 2.5, -2)
            castBar.ArenaTargetHighlight:SetAlpha(0)
        end
    end
end

function sArenaMixin:CreateCastbarTargetText()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local castBar = frame.CastBar
        if castBar and not castBar.ArenaTargetText then
            if not castBar.ArenaTargetTextFrame then
                castBar.ArenaTargetTextFrame = CreateFrame("Frame", nil, castBar)
                castBar.ArenaTargetTextFrame:SetAllPoints(castBar)
                castBar.ArenaTargetTextFrame:SetFrameLevel(castBar:GetFrameLevel() + 6)
            end
            local targetText = castBar.ArenaTargetTextFrame:CreateFontString(nil, "OVERLAY")

            local fontFile, fontSize, fontFlags = castBar.Text:GetFont()
            targetText:SetFont(fontFile, fontSize-2, fontFlags)
            local sr, sg, sb, sa = castBar.Text:GetShadowColor()
            targetText:SetShadowColor(sr, sg, sb, sa)
            local sx, sy = castBar.Text:GetShadowOffset()
            targetText:SetShadowOffset(sx, sy)
            targetText:SetJustifyH(castBar.Text:GetJustifyH())
            targetText:SetJustifyV(castBar.Text:GetJustifyV())
            targetText:SetWidth(castBar:GetWidth())
            targetText:Hide()
            castBar.ArenaTargetText = targetText
        end
    end
end

function sArenaMixin:UpdateCastbarTargetText()
    local db = self.db
    if not db then return end

    local showTarget = db.profile.showCastbarTarget
    local layoutSettings = db.profile.layoutSettings[db.profile.currentLayout]
    local textSettings = layoutSettings and layoutSettings.textSettings

    local anchorInside = textSettings and textSettings.castbarTargetAnchorInside
    local anchorToCastbar = not textSettings or textSettings.castbarTargetAnchorToCastbar ~= false
    local targetAnchor = textSettings and textSettings.castbarTargetAnchor or "BOTTOM"
    local targetOffsetX = textSettings and textSettings.castbarTargetOffsetX or 0
    local targetOffsetY = textSettings and textSettings.castbarTargetOffsetY or 0
    local targetSize = textSettings and textSettings.castbarTargetSize or 1.0
    local targetJustifyH = textSettings and textSettings.castbarTargetJustifyH or "CENTER"
    local useModern = layoutSettings and layoutSettings.castBar and layoutSettings.castBar.useModernCastbars
    local bottomExtra = useModern and 10 or 3

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local castBar = frame.CastBar
        if castBar and castBar.ArenaTargetText then
            local targetText = castBar.ArenaTargetText

            if not showTarget or anchorInside then
                targetText:Hide()
                targetText:SetText("")
            else
                targetText:ClearAllPoints()
                targetText:SetScale(targetSize)
                targetText:SetWidth(castBar:GetWidth())
                targetText:SetText("")
                targetText:SetJustifyH(targetJustifyH)
                targetText:SetText(targetText:GetText())

                local anchorParent = anchorToCastbar and castBar or castBar.Text

                if targetAnchor == "LEFT" then
                    targetText:SetPoint("RIGHT", anchorParent, "LEFT", -2 + targetOffsetX, targetOffsetY)
                elseif targetAnchor == "RIGHT" then
                    targetText:SetPoint("LEFT", anchorParent, "RIGHT", 2 + targetOffsetX, targetOffsetY)
                elseif targetAnchor == "TOP" then
                    targetText:SetPoint("BOTTOM", anchorParent, "TOP", targetOffsetX, 2 + targetOffsetY)
                elseif targetAnchor == "BOTTOM" then
                    targetText:SetPoint("TOP", anchorParent, "BOTTOM", targetOffsetX, -2 + targetOffsetY + bottomExtra)
                end
            end
        end
    end
end

local function GetCastbarTargetName(unit)
    if isMidnight then
        local name = UnitSpellTargetName(unit)
        if not name then
            name = UnitName(unit .. "target")
        end
        if not name then return nil, nil end

        local class = UnitSpellTargetClass(unit)
        if not class then
            _, class = UnitClass(unit .. "target")
        end
        return name, class
    else
        local name = UnitName(unit .. "target")
        if not name then return nil, nil end
        local _, class = UnitClass(unit .. "target")
        return name, class
    end
end

local function GetColoredTargetString(name, class)
    if not name then return nil end
    if class then
        local color = C_ClassColor and C_ClassColor.GetClassColor(class) or RAID_CLASS_COLORS[class]
        if color then
            if color.WrapTextInColorCode then
                return color:WrapTextInColorCode(name)
            elseif color.colorStr then
                return "|c" .. color.colorStr .. name .. "|r"
            end
        end
    end
    return name
end

local CastStartEvents = {
    UNIT_SPELLCAST_START          = true,
    UNIT_SPELLCAST_CHANNEL_START  = true,
    UNIT_SPELLCAST_EMPOWER_START  = true,
}

function sArenaMixin:UpdateCastbarTargetOnEvent(castBar, event)
    local db = self.db
    if not db or not db.profile.showCastbarTarget then return end

    local unitToken = castBar.unit
    if not unitToken then return end

    local layoutSettings = db.profile.layoutSettings[db.profile.currentLayout]
    local textSettings = layoutSettings and layoutSettings.textSettings
    local anchorInside = textSettings and textSettings.castbarTargetAnchorInside

    if CastStartEvents[event] then
        local spell = UnitCastingInfo(unitToken) or UnitChannelInfo(unitToken)
        if not spell then return end

        local name, class = GetCastbarTargetName(unitToken)
        local coloredName = GetColoredTargetString(name, class)

        if anchorInside then
            if coloredName then
                castBar.Text:SetText(spell .. ": " .. coloredName)
            end
        else
            if castBar.ArenaTargetText and coloredName then
                castBar.ArenaTargetText:SetText(coloredName)
                castBar.ArenaTargetText:Show()
            end
        end
    end
end

if isMidnight then return end

local CastStopEvents = {
    UNIT_SPELLCAST_STOP                = true,
    UNIT_SPELLCAST_FAILED              = true,
    UNIT_SPELLCAST_FAILED_QUIET        = true,
    UNIT_SPELLCAST_INTERRUPTED         = true,
    UNIT_SPELLCAST_CHANNEL_STOP        = true,
    UNIT_SPELLCAST_CHANNEL_INTERRUPTED = true,
}

local MOD_NONINT_TEX  = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable"
local MOD_CHANNEL_TEX = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel"
local MOD_CAST_TEX    = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard"
local MOD_BG_TEX      = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Background.tga"
local MOD_FRAME_TEX   = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Frame.tga"
local MOD_TEXTBOX_TEX = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-TextBox.tga"
local MOD_SHIELD_TEX  = "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Shield.tga"

local function EnsureModernPieces(bar)
    if bar.TextBorder and bar.Background and bar.Border then return end
    bar.TextBorder = bar.TextBorder or bar:CreateTexture(nil, "BACKGROUND", nil, 2)
    bar.Background = bar.Background or bar:CreateTexture(nil, "BACKGROUND", nil, 2)
    bar.Border     = bar.Border or bar:CreateTexture(nil, "OVERLAY", nil, 7)
end

local function ApplyModern(bar, simpleCastbar, frame, unit)
    EnsureModernPieces(bar)

    bar.TextBorder:SetTexture(MOD_TEXTBOX_TEX)
    bar.Background:SetTexture(MOD_BG_TEX)
    bar.Border:SetTexture(MOD_FRAME_TEX)
    bar.BorderShield:SetTexture(MOD_SHIELD_TEX)
    bar.BorderShield:SetDrawLayer("BACKGROUND", 0)

    local function _snapColor(c)
        if c and c.GetRGBA then
            local r, g, b, a = c:GetRGBA()
            return { r = r, g = g, b = b, a = a }
        end
    end

    if not bar.__origColorsSaved then
        bar.__origColors = {
            failed   = _snapColor(bar.failedCastColor),
            finished = _snapColor(bar.finishedCastColor),
            nonint   = _snapColor(bar.nonInterruptibleColor),
            start    = _snapColor(bar.startCastColor),
            channel  = _snapColor(bar.startChannelColor),
        }
        bar.__origColorsSaved = true
    end

    local castbarColors = frame.parent.castbarColors
    if castbarColors and castbarColors.enabled then
        local standardColor = castbarColors.standard or { 1.0, 0.7, 0.0, 1 }
        local channelColor = castbarColors.channel or { 0.0, 1.0, 0.0, 1 }
        local unintColor = castbarColors.uninterruptable or { 0.7, 0.7, 0.7, 1 }
        local interruptedColor = { 1.0, 0.0, 0.0, 1 }

        bar.failedCastColor       = CreateColor(interruptedColor[1], interruptedColor[2], interruptedColor[3], interruptedColor[4])
        bar.finishedCastColor     = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
        bar.nonInterruptibleColor = CreateColor(unintColor[1], unintColor[2], unintColor[3], unintColor[4])
        bar.startCastColor        = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
        bar.startChannelColor     = CreateColor(channelColor[1], channelColor[2], channelColor[3], channelColor[4])
    else
        bar.failedCastColor       = CreateColor(1.0, 0.0, 0.0, 1)
        bar.finishedCastColor     = CreateColor(1.0, 0.7, 0.0, 1)
        bar.nonInterruptibleColor = CreateColor(0.7, 0.7, 0.7, 1)
        bar.startCastColor        = CreateColor(1.0, 0.7, 0.0, 1)
        bar.startChannelColor     = CreateColor(0.0, 1.0, 0.0, 1)
    end

    bar.Background:SetAllPoints(bar)
    bar.Background:Show()
    bar.Border:ClearAllPoints()
    bar.Border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1.5)
    bar.Border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1.5)
    bar.Border:Show()

    if simpleCastbar then
        bar.TextBorder:Hide()
        bar.Text:ClearAllPoints()
        bar.Text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    else
        bar.TextBorder:ClearAllPoints()
        bar.TextBorder:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, 1)
        bar.TextBorder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -1, -13.5)
        bar.TextBorder:Show()
        bar.Text:ClearAllPoints()
        bar.Text:SetPoint("BOTTOM", bar, 0, -10.5)
    end

    local ogBg = select(1, bar:GetRegions())
    if ogBg then
        ogBg:Hide()
    end

    if not bar.MaskTexture then
        bar.MaskTexture = bar:CreateMaskTexture()
    end
    local castTexture = bar:GetStatusBarTexture()
    bar.MaskTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\RetailCastMask.tga",
        "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    bar.MaskTexture:SetAllPoints(bar)
    bar.MaskTexture:Show()
    castTexture:AddMaskTexture(bar.MaskTexture)

    bar:SetHeight(12)
    if bar.Icon then
        bar.Icon:SetSize(21, 21)
        bar.Icon:SetDrawLayer("OVERLAY", 7)
    end

    if not bar.__modernHooked then
        bar:HookScript("OnEvent", function(castBar, event, eventUnit)
            if CastStopEvents[event] and eventUnit == unit then
                if castBar.interruptedBy then
                    castBar:Show()
                else
                    local cast = UnitCastingInfo(unit) or UnitChannelInfo(unit)
                    if not cast then
                        castBar:Hide()
                        -- no return cuz sometimes castbar still fades idk and we need the color
                    end
                end
            end
            sArenaMixin:CastbarOnEvent(bar)
            sArenaMixin:UpdateCastbarTargetOnEvent(bar, event)
        end)
        bar.__modernHooked = true
    end

    bar.__modernActive = true
    bar:Show()
end

local function RestoreClassic(bar, frame)
    bar.Text:ClearAllPoints()
    bar.Text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar:SetHeight(16)
    if bar.Icon then bar.Icon:SetSize(16, 16) end

    if bar.TextBorder then bar.TextBorder:Hide() end
    if bar.Background then bar.Background:Hide() end
    if bar.Border then bar.Border:Hide() end

    local castbarColors = frame and frame.parent and frame.parent.castbarColors
    if castbarColors and castbarColors.enabled then
        local standardColor = castbarColors.standard or { 1.0, 0.7, 0.0, 1 }
        local channelColor = castbarColors.channel or { 0.0, 1.0, 0.0, 1 }
        local unintColor = castbarColors.uninterruptable or { 0.7, 0.7, 0.7, 1 }
        local interruptedColor = { 1.0, 0.0, 0.0, 1 }

        bar.failedCastColor       = CreateColor(interruptedColor[1], interruptedColor[2], interruptedColor[3], interruptedColor[4])
        bar.finishedCastColor     = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
        bar.nonInterruptibleColor = CreateColor(unintColor[1], unintColor[2], unintColor[3], unintColor[4])
        bar.startCastColor        = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
        bar.startChannelColor     = CreateColor(channelColor[1], channelColor[2], channelColor[3], channelColor[4])
    else
        local o = bar.__origColors
        if o then
            if o.failed then bar.failedCastColor = CreateColor(o.failed.r, o.failed.g, o.failed.b, o.failed.a) end
            if o.finished then bar.finishedCastColor = CreateColor(o.finished.r, o.finished.g, o.finished.b, o.finished
                .a) end
            if o.nonint then bar.nonInterruptibleColor = CreateColor(o.nonint.r, o.nonint.g, o.nonint.b, o.nonint.a) end
            if o.start then bar.startCastColor = CreateColor(o.start.r, o.start.g, o.start.b, o.start.a) end
            if o.channel then bar.startChannelColor = CreateColor(o.channel.r, o.channel.g, o.channel.b, o.channel.a) end
        end
    end

    local ogBg = select(1, bar:GetRegions())
    if ogBg then
        ogBg:Show()
    end

    if bar.MaskTexture then
        bar.MaskTexture:Hide()
    end

    if bar.BorderShield then
        bar.BorderShield:SetTexture(330124)
    end

    bar.__modernActive = false
    bar:Show()
end

local function EnableCastBarClassicMode(bar, modern, simpleCastbar, frame, unit)
    if not bar then return end
    if modern then
        ApplyModern(bar, simpleCastbar, frame, unit)
    else
        RestoreClassic(bar, frame)
    end
end

local function UpdateCastbarColorsMoP(bar, parent)
    if not bar then return end

    local castbarColors = parent and parent.castbarColors
    if castbarColors and castbarColors.enabled then
        local standardColor = castbarColors.standard or { 1.0, 0.7, 0.0, 1 }
        local channelColor = castbarColors.channel or { 0.0, 1.0, 0.0, 1 }
        local unintColor = castbarColors.uninterruptable or { 0.7, 0.7, 0.7, 1 }
        local interruptedColor = { 1.0, 0.0, 0.0, 1 }

        bar.failedCastColor       = CreateColor(interruptedColor[1], interruptedColor[2], interruptedColor[3], interruptedColor[4])
        bar.finishedCastColor     = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
        bar.nonInterruptibleColor = CreateColor(unintColor[1], unintColor[2], unintColor[3], unintColor[4])
        bar.startCastColor        = CreateColor(standardColor[1], standardColor[2], standardColor[3], standardColor[4])
        bar.startChannelColor     = CreateColor(channelColor[1], channelColor[2], channelColor[3], channelColor[4])
    else
        local o = bar.__origColors
        if o then
            if o.failed then bar.failedCastColor = CreateColor(o.failed.r, o.failed.g, o.failed.b, o.failed.a) end
            if o.finished then bar.finishedCastColor = CreateColor(o.finished.r, o.finished.g, o.finished.b, o.finished.a) end
            if o.nonint then bar.nonInterruptibleColor = CreateColor(o.nonint.r, o.nonint.g, o.nonint.b, o.nonint.a) end
            if o.start then bar.startCastColor = CreateColor(o.start.r, o.start.g, o.start.b, o.start.a) end
            if o.channel then bar.startChannelColor = CreateColor(o.channel.r, o.channel.g, o.channel.b, o.channel.a) end
        end
    end
end

function sArenaMixin:UpdateMoPCastbarColors()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame and frame.CastBar then
            UpdateCastbarColorsMoP(frame.CastBar, self)
        end
    end
end

function sArenaMixin:ApplyCastbarStyle(frame, unit, modern, simpleCastbar)
    if InCombatLockdown and InCombatLockdown() then
        frame.__pendingCastbarStyle = modern and "modern" or "classic"
        frame.__pendingSimpleCastbar = simpleCastbar
        return
    end
    EnableCastBarClassicMode(frame.CastBar, modern, simpleCastbar, frame, unit)
    frame.__pendingCastbarStyle = nil
    frame.__pendingSimpleCastbar = nil
end