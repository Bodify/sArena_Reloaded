local layoutName = "BlizzTarget"
local layout = {}
layout.name = "|cff00b4ffBlizz|r Target |A:NewCharacter-Alliance:36:64|a"
local L = sArenaMixin.L

layout.defaultSettings = {
    posX = 450,
    posY = 170,
    scale = 1,
    classIconFontSize = 20,
    spacing = 14,
    growthDirection = 1,
    specIcon = {
        posX = 82,
        posY = -25,
        scale = 1,
    },
    trinket = {
        posX = 80,
        posY = 0,
        scale = 1.5,
        fontSize = 12,
    },
    racial = {
        posX = 104,
        posY = 0,
        scale = 1.5,
        fontSize = 12,
    },
    dispel = {
        posX = 128,
        posY = 0,
        scale = 1.5,
        fontSize = 12,
    },
    castBar = {
        posX = -15,
        posY = -29,
        scale = 1.2,
        width = 82,
        iconScale = 1,
        keepDefaultModernTextures = true,
        recolorCastbar = false,
    },
    dr = {
        posX = -114,
        posY = 0,
        size = 28,
        borderSize = 2.5,
        fontSize = 12,
        spacing = 7,
        growthDirection = 4,
    },
    widgets = {
        combatIndicator = {
            posX = 0,
            posY = 0,
            scale = 1,
        },
        targetIndicator = {
            posX = 0,
            posY = 0,
            scale = 1,
            useBorder = false,
            useBorderWithIcon = false,
        },
        focusIndicator = {
            posX = 0,
            posY = 0,
            scale = 1,
            useBorder = false,
            useBorderWithIcon = false,
        },
        partyTargetIndicators = {
            partyOnArena = {
                enabled = true,
                posX = 0,
                posY = 0,
                scale = 1,
                direction = "LEFT",
                spacing = 0,
            },
            arenaOnParty = {
                enabled = true,
                posX = 0,
                posY = 0,
                scale = 1,
                direction = "LEFT",
                spacing = 0,
            },
        },
    },

    textures          = {
        generalStatusBarTexture       = "sArena Default",
        healStatusBarTexture          = "sArena Stripes",
        castbarStatusBarTexture       = "sArena Default",
        castbarUninterruptibleTexture = "sArena Default",
        bgTexture = "Solid",
        bgColor = {0, 0, 0, 0.6},
    },
    retextureHealerClassStackOnly = true,

    -- custom layout settings
    frameFont = "Prototype",
    cdFont  = "Prototype",
    mirrored = false,
    bigHealthbar = true,
    keepHealerManabar = true,

    textSettings = {
    },
}

local function getSetting(info)
    return layout.db[info[#info]]
end

local function setSetting(info, val)
    layout.db[info[#info]] = val

    for i = 1, info.handler.maxArenaOpponents do
        local frame = info.handler["arena" .. i]
        layout:UpdateOrientation(frame)
    end

    if info[#info] == "mirrored" then
        local expectedCastBarPosX = val and layout.defaultSettings.castBar.posX or (layout.defaultSettings.castBar.posX + 50)
        local expectedSpecIconPosX = val and layout.defaultSettings.specIcon.posX or (layout.defaultSettings.specIcon.posX - 161)

        if layout.db.castBar.posX == expectedCastBarPosX then
            if val then
                layout.db.castBar.posX = layout.db.castBar.posX + 50
            else
                layout.db.castBar.posX = layout.db.castBar.posX - 50
            end
            info.handler:UpdateCastBarSettings(layout.db.castBar)
        end

        if layout.db.specIcon.posX == expectedSpecIconPosX then
            if val then
                layout.db.specIcon.posX = layout.db.specIcon.posX - 161
            else
                layout.db.specIcon.posX = layout.db.specIcon.posX + 161
            end
            info.handler:UpdateSpecIconSettings(layout.db.specIcon)
        end
    end

    info.handler:RefreshConfig()
end

local function setupOptionsTable(self)
    layout.optionsTable = self:GetLayoutOptionsTable(layoutName)

    layout.optionsTable.arenaFrames.args.positioning.args.mirrored = {
        order = 5,
        name = L["Option_MirroredFrames"],
        type = "toggle",
        width = "full",
        get = getSetting,
        set = setSetting,
    }

    layout.optionsTable.arenaFrames.args.other.args.bigHealthbar = {
        order = 1,
        name = L["Option_BigHealthbar"],
        type = "toggle",
        get = getSetting,
        set = setSetting,
    }
end

function layout:Initialize(frame)
    self.db = frame.parent.db.profile.layoutSettings[layoutName]

    if (not self.optionsTable) then
        setupOptionsTable(frame.parent)
    end

    if (frame:GetID() == frame.parent.maxArenaOpponents) then
        frame.parent:UpdateCastBarSettings(self.db.castBar)
        frame.parent:UpdateDRSettings(self.db.dr)
        frame.parent:UpdateFrameSettings(self.db)
        frame.parent:UpdateSpecIconSettings(self.db.specIcon)
        frame.parent:UpdateTrinketSettings(self.db.trinket)
        frame.parent:UpdateRacialSettings(self.db.racial)
        frame.parent:UpdateDispelSettings(self.db.dispel)
        frame.parent:UpdateWidgetSettings(self.db.widgets)
    end

    frame.ClassIcon.Cooldown:SetSwipeTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    frame.ClassIcon.Cooldown:SetUseCircularEdge(true)
    frame.ClassIcon:SetFrameStrata("LOW")
    frame.ClassIcon:SetFrameLevel(7)

    frame:SetSize(192, 76.8)
    frame.SpecIcon:SetSize(22, 22)
    frame.SpecIcon.Texture:AddMaskTexture(frame.SpecIcon.Mask)
    frame.Trinket:SetSize(22, 22)
    frame.Racial:SetSize(22, 22)
    frame.Dispel:SetSize(22, 22)

    frame.AuraStacks:SetPoint("BOTTOMLEFT", frame.ClassIcon, "BOTTOMLEFT", 6, -1)
    frame.AuraStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 18, "THICKOUTLINE")

    if not frame.NameBackground then
        local bg = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
        bg:SetTexture(137017)
        bg:SetPoint("TOPLEFT", frame.HealthBar, "TOPLEFT", -1, 18.5)
        bg:SetPoint("BOTTOMRIGHT", frame.HealthBar, "TOPRIGHT", 2, 2)
        bg:SetVertexColor(0,0,0, 0.6)
        frame.NameBackground = bg
    end

    local healthBar = frame.HealthBar
    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    local powerBar = frame.PowerBar
    powerBar:SetSize(118, 9)
    powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -1.5)
    powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    local f = frame.ClassIcon
    f:SetSize(62, 62)
    f:Show()
    f.Texture:AddMaskTexture(f.Mask)

    f.Mask:SetSize(66, 66)
    f.Mask:ClearAllPoints()
    f.Mask:SetPoint("CENTER", f, "CENTER", 0, 0)

    -- SpecIcon border (owned by SpecIcon)
    if not frame.SpecIcon.Border then
        frame.SpecIcon.Border = frame.SpecIcon:CreateTexture(nil, "ARTWORK", nil, 3)
    end

    local specBorder = frame.SpecIcon.Border
    specBorder:ClearAllPoints()
    specBorder:SetTexture("Interface\\CHARACTERFRAME\\TotemBorder")
    specBorder:SetPoint("TOPLEFT", frame.SpecIcon, "TOPLEFT", -8, 8)
    specBorder:SetPoint("BOTTOMRIGHT", frame.SpecIcon, "BOTTOMRIGHT", 8, -8)
    specBorder:Show()

    f = frame.Name
    f:SetJustifyH("CENTER")
    --f:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 2, 4)
    --f:SetPoint("BOTTOMRIGHT", healthBar, "TOPRIGHT", -2, 4)
    f:SetHeight(12)
    f:SetFont("Fonts\\FRIZQT__.TTF", 11, "")

    f = frame.CastBar
    f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

    f = frame.DeathIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", frame.HealthBar, "TOP")
    f:SetSize(48, 48)

    frame.PowerText:SetAlpha(frame.parent.db.profile.hidePowerText and 0 or 1)

    local frameTexture = frame.frameTexture
    frameTexture:ClearAllPoints()
    frameTexture:SetAllPoints(frame)
    frameTexture:SetDrawLayer("ARTWORK", 2)
    frameTexture:Show()

    if self.db.bigHealthbar then
        healthBar:SetSize(118, 29)
        frame.NameBackground:Hide()
        frameTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-TargetingFrame-NoLevel-Large")
    else
        healthBar:SetSize(118, 9)
        frameTexture:SetTexture("Interface\\TargetingFrame\\UI-FocusFrame-Large")
        frame.NameBackground:Show()
    end

    self:UpdateOrientation(frame)
end

function layout:UpdateHealthbarOrientation(frame)
    local healthBar = frame.HealthBar
    local shouldHide = self.db.hideManabars and not (self.db.keepHealerManabar and frame.isHealer)
    local normalHeight = self.db.bigHealthbar and 29 or 9
    local hiddenHeight = normalHeight + 1.5 + 9
    local extra = hiddenHeight - normalHeight

    healthBar:ClearAllPoints()
    healthBar:SetSize(118, shouldHide and hiddenHeight or normalHeight)

    if self.db.bigHealthbar then
        if shouldHide then
            frame.frameTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-TargetingFrame-NoLevel-Large-ManaOff")
        else
            frame.frameTexture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-TargetingFrame-NoLevel-Large")
        end
    end

    local yBase = self.db.bigHealthbar and 7 or -2
    if self.db.mirrored then
        healthBar:SetPoint("RIGHT", -5, yBase - (shouldHide and extra / 2 or 0))
    else
        healthBar:SetPoint("LEFT", 5, yBase - (shouldHide and extra / 2 or 0))
    end

    frame.PowerBar:SetAlpha(shouldHide and 0 or 1)
    frame.PowerText:SetAlpha((shouldHide or frame.parent.db.profile.hidePowerText) and 0 or 1)

    if not self.db.textSettings then return end
    local txt = self.db.textSettings
    local hideOffset = (shouldHide and not self.db.moveStatusbarText) and extra / 2 or 0
    local name = frame.Name
    local healthText = frame.HealthText

    name:ClearAllPoints()
    if (txt.nameAnchor or "CENTER") == "LEFT" then
        name:SetPoint("BOTTOMLEFT", healthBar, "TOPLEFT", 3 + (txt.nameOffsetX or 0), 4 + (txt.nameOffsetY or 0))
    elseif (txt.nameAnchor or "CENTER") == "RIGHT" then
        name:SetPoint("BOTTOMRIGHT", healthBar, "TOPRIGHT", -3 + (txt.nameOffsetX or 0), 4 + (txt.nameOffsetY or 0))
    else
        name:SetPoint("BOTTOM", healthBar, "TOP", (txt.nameOffsetX or 0), 4 + (txt.nameOffsetY or 0))
    end

    healthText:ClearAllPoints()
    if (txt.healthAnchor or "CENTER") == "LEFT" then
        healthText:SetPoint("LEFT", healthBar, "LEFT", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0) + hideOffset)
    elseif (txt.healthAnchor or "CENTER") == "RIGHT" then
        healthText:SetPoint("RIGHT", healthBar, "RIGHT", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0) + hideOffset)
    else
        healthText:SetPoint("CENTER", healthBar, "CENTER", (txt.healthOffsetX or 0), (txt.healthOffsetY or 0) + hideOffset)
    end

    local specName = frame.SpecNameText
    local specY = -(normalHeight + 6)
    specName:ClearAllPoints()
    if (txt.specNameAnchor or "CENTER") == "LEFT" then
        specName:SetPoint("LEFT", healthBar, "TOPLEFT", (txt.specNameOffsetX or 0), specY + (txt.specNameOffsetY or 0))
    elseif (txt.specNameAnchor or "CENTER") == "RIGHT" then
        specName:SetPoint("RIGHT", healthBar, "TOPRIGHT", (txt.specNameOffsetX or 0), specY + (txt.specNameOffsetY or 0))
    else
        specName:SetPoint("CENTER", healthBar, "TOP", (txt.specNameOffsetX or 0), specY + (txt.specNameOffsetY or 0))
    end
end

function layout:UpdateOrientation(frame)
    local frameTexture = frame.frameTexture
    local healthBar = frame.HealthBar
    local name = frame.Name
    local specName = frame.SpecNameText
    local healthText = frame.HealthText
    local powerText = frame.PowerText
    local castbarText = frame.CastBar.Text

    if self.db.widgets then
        local w = self.db.widgets

        -- Combat Indicator
        if w.combatIndicator then
            frame.WidgetOverlay.combatIndicator:ClearAllPoints()
            frame.WidgetOverlay.combatIndicator:SetSize(18, 18)
            frame.WidgetOverlay.combatIndicator:SetScale(w.combatIndicator.scale or 1)
            frame.WidgetOverlay.combatIndicator:SetPoint("CENTER", frame.HealthBar, "CENTER",
                (w.combatIndicator.posX or 0), (w.combatIndicator.posY or 0) - 20)
        end

        -- Target Indicator
        if w.targetIndicator then
            frame.WidgetOverlay.targetIndicator:ClearAllPoints()
            frame.WidgetOverlay.targetIndicator:SetSize(34, 34)
            frame.WidgetOverlay.targetIndicator:SetScale(w.targetIndicator.scale or 1)
            frame.WidgetOverlay.targetIndicator:SetPoint("CENTER", frame.ClassIcon, "CENTER",
                (w.targetIndicator.posX or 0) - 5, (w.targetIndicator.posY or 0) - 26)
        end

        -- Focus Indicator
        if w.focusIndicator then
            frame.WidgetOverlay.focusIndicator:ClearAllPoints()
            frame.WidgetOverlay.focusIndicator:SetSize(20, 20)
            frame.WidgetOverlay.focusIndicator:SetScale(w.focusIndicator.scale or 1)
            frame.WidgetOverlay.focusIndicator:SetPoint("BOTTOMRIGHT", frame.ClassIcon, "BOTTOMRIGHT",
                (w.focusIndicator.posX or 0) - 25, (w.focusIndicator.posY or 0) - 6)
        end

        -- Party Target Indicators
        if w.partyTargetIndicators and w.partyTargetIndicators.partyOnArena then
            local poa = w.partyTargetIndicators.partyOnArena
            local direction = poa.direction or "LEFT"
            frame.WidgetOverlay.partyTarget1:ClearAllPoints()
            frame.WidgetOverlay.partyTarget1:SetSize(15, 15)
            frame.WidgetOverlay.partyTarget1:SetScale(poa.scale or 1)
            frame.WidgetOverlay.partyTarget1:SetPoint("TOPLEFT", frame.HealthBar, "TOPRIGHT",
                (poa.posX or 0) - 7, (poa.posY or 0) + 14)

            for i = 2, 4 do
                local indicator = frame.WidgetOverlay["partyTarget" .. i]
                indicator:SetSize(15, 15)
                indicator:SetScale(poa.scale or 1)
                sArenaMixin:ChainIndicator(indicator, frame.WidgetOverlay["partyTarget" .. (i - 1)], direction, poa.spacing or 3)
            end
        end
    end

    if self.db.textSettings then
        local txt = self.db.textSettings
        local modernCastbar = self.db.castBar.useModernCastbars
        name:SetScale(txt.nameSize or 1)
        healthText:SetScale(txt.healthSize or 1)
        specName:SetScale(txt.specNameSize or 1)
        castbarText:SetScale(txt.castbarSize or 1)
        powerText:SetScale(txt.powerSize or 1)

        self:UpdateHealthbarOrientation(frame)

        -- Power Text
        powerText:ClearAllPoints()
        if (txt.powerAnchor or "CENTER") == "LEFT" then
            powerText:SetPoint("LEFT", frame.PowerBar, "LEFT", 0 + (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        elseif (txt.powerAnchor or "CENTER") == "RIGHT" then
            powerText:SetPoint("RIGHT", frame.PowerBar, "RIGHT", 0 + (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        else
            powerText:SetPoint("CENTER", frame.PowerBar, "CENTER", (txt.powerOffsetX or 0), (txt.powerOffsetY or 0))
        end

        -- Castbar Text
        castbarText:ClearAllPoints()
        local simpleCastbar = self.db.castBar.simpleCastbar and modernCastbar
        if (txt.castbarAnchor or "CENTER") == "LEFT" then
            castbarText:SetPoint("LEFT", frame.CastBar, "LEFT", 3 + (txt.castbarOffsetX or 0), (modernCastbar and (simpleCastbar and 0 or -11) or 0) + (txt.castbarOffsetY or 0))
        elseif (txt.castbarAnchor or "CENTER") == "RIGHT" then
            castbarText:SetPoint("RIGHT", frame.CastBar, "RIGHT", -3 + (txt.castbarOffsetX or 0), (modernCastbar and (simpleCastbar and 0 or -11) or 0) + (txt.castbarOffsetY or 0))
        else
            castbarText:SetPoint("CENTER", frame.CastBar, "CENTER", (txt.castbarOffsetX or 0), (modernCastbar and (simpleCastbar and 0 or -11) or 0) + (txt.castbarOffsetY or 0))
        end

        if txt.forceCastbarTextWidth then
            castbarText:SetWidth(self.db.castBar.width or frame.CastBar:GetWidth())
        else
            castbarText:SetWidth(0)
        end
    end

    healthBar:ClearAllPoints()
    frame.ClassIcon:ClearAllPoints()

    if (self.db.mirrored) then
        frameTexture:SetTexCoord(0.85, 0.1, 0.05, 0.65)
        healthBar:SetPoint("RIGHT", -5, self.db.bigHealthbar and 7 or -2)
        frame.ClassIcon:SetPoint("LEFT", 5, 0)
    else
        frameTexture:SetTexCoord(0.1, 0.85, 0.05, 0.65)
        healthBar:SetPoint("LEFT", 5, self.db.bigHealthbar and 7 or -2)
        frame.ClassIcon:SetPoint("RIGHT", -5, 0)
    end

    self:UpdateHealthbarOrientation(frame)
end

sArenaMixin.layouts[layoutName] = layout
sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings
