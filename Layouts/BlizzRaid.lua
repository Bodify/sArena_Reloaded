-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local layoutName = "BlizzRaid"
local layout = {}
layout.name = "|cff00b4ffBlizz|r Raid |A:NewCharacter-Alliance:38:65|a"
local L = sArenaMixin.L

layout.defaultSettings = {
    posX = 485.2,
    posY = 121.6,
    scale = 1,
    classIconFontSize = 22,
    spacing = 0,
    growthDirection = 1,
    classIcon = {
        posX = 40,
        posY = -1,
        scale = 0.6,
    },
    specIcon = {
        posX = -45,
        posY = 38,
        scale = 0.62,
    },
    trinket = {
        posX = 164.2,
        posY = 23.7,
        scale = 0.75,
        fontSize = 14,
    },
    racial = {
        posX = 210.4,
        posY = 23.4,
        scale = 0.75,
        fontSize = 14,
    },
    dispel = {
        posX = 189,
        posY = 0,
        scale = 1.049,--handle
        fontSize = 14,
    },
    castBar = {
        posX = -86,
        posY = -14,
        scale = 1.5,
        width = 117,
        iconScale = 1,
        iconPosX = -2,
        iconPosY = 0,
        simpleCastbar = true,
        keepDefaultModernTextures = true,
        recolorCastbar = false,
    },
    dr = {
        posX = -106,
        posY = 15,
        size = 36,
        borderSize = 1,
        fontSize = 12,
        spacing = 7,
        growthDirection = 4,
        thinPixelBorder = true,
    },
    widgets = {
        enabled = true,
        posX = 9,
        posY = 5,
        combatIndicator = {
            posX = 0,
            posY = 0,
            scale = 1,
        },
        targetIndicator = {
            enabled = true,
            posX = 9,
            posY = 4,
            scale = 1,
            borderSize = 1.5,
            useBorder = true,
            useBorderWithIcon = false,
            wrapClass = false,
            wrapTrinket = false,
            wrapRacial = false,
        },
        focusIndicator = {
            posX = 0,
            posY = 0,
            scale = 1,
            borderSize = 1.5,
            useBorder = true,
            useBorderWithIcon = false,
            wrapClass = true,
            wrapTrinket = false,
            wrapRacial = false,
        },
        partyTargetIndicators = {
            enabled = true,
            partyOnArena = {
                enabled = true,
                posX = -1,
                posY = -10,
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
    statusText = {
        usePercentage = true,
        alwaysShow = true,
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
    changeFont = true,
    frameFont = "Friz Quadrata TT",
    cdFont  = "2002 Bold",
    fontOutline = "",
    width = 208,
    height = 70,
    powerBarHeight = 9,
    pixelBorderSize = 1,
    drPixelBorderSize = 2,
    mirrored = true,
    classicBars = false,
    showSpecManaText = true,
    keepHealerManabar = true,
    cropIcons = true,

    textSettings = {
        nameAnchor = "LEFT",
        nameOffsetX = 17,
        nameOffsetY = 20,
        healthAnchor = "CENTER",
        healthOffsetY = -1,
        healthSize = 1.4,
        powerAnchor = "RIGHT",
        specNameAnchor = "CENTER",
        castbarSize = 1.02,
    },
}


local function getSetting(info)
    return layout.db[info[#info]]
end

local function setSetting(info, val)
    layout.db[info[#info]] = val

    for i = 1, info.handler.maxArenaOpponents do
        local frame = info.handler["arena" .. i]
        frame:SetSize(layout.db.width, layout.db.height)
        local baseSize = layout.db.height - 4
        frame.ClassIcon:SetSize(baseSize, baseSize)
        local classIconScale = layout.db.classIcon and layout.db.classIcon.scale or 1
        frame.ClassIcon:SetScale(classIconScale)
        frame.DeathIcon:SetSize(layout.db.height * 0.8, layout.db.height * 0.8)
        frame.PowerBar:SetHeight(layout.db.powerBarHeight)
        layout:UpdateOrientation(frame)
    end
end

local function setPixelBorderSetting(info, val)
    layout.db[info[#info]] = val

    for i = 1, info.handler.maxArenaOpponents do
        local frame = info.handler["arena" .. i]
        frame:AddPixelBorderToFrame()
    end
end

local function setToggleSetting(info, val)
    layout.db[info[#info]] = val
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
        set = setToggleSetting,
    }

    layout.optionsTable.arenaFrames.args.sizing.args.width = {
        order = 3,
        name = L["Width"],
        type = "range",
        min = 40,
        max = 400,
        step = 1,
        get = getSetting,
        set = setSetting,
    }

    layout.optionsTable.arenaFrames.args.sizing.args.height = {
        order = 4,
        name = L["Height"],
        type = "range",
        min = 2,
        max = 100,
        step = 1,
        get = getSetting,
        set = setSetting,
    }

    layout.optionsTable.arenaFrames.args.sizing.args.powerBarHeight = {
        order = 5,
        name = L["Option_PowerBarHeight"],
        type = "range",
        min = 1,
        max = 50,
        step = 1,
        get = getSetting,
        set = setSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.cropIcons = {
        order = 5,
        name = L["Option_CropIcons"],
        type = "toggle",
        width = "full",
        get = getSetting,
        set = setToggleSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.pixelBorderSize = {
        order = 6,
        name = L["Option_PixelBorderSize"],
        type = "range",
        min = 0,
        max = 3,
        step = 0.5,
        get = getSetting,
        set = setPixelBorderSetting,
    }
    layout.optionsTable.arenaFrames.args.other.args.pixelBorderOffset = {
        order = 7,
        name = L["Option_PixelBorderOffset"],
        type = "range",
        min = -3,
        max = 3,
        step = 0.5,
        get = getSetting,
        set = setPixelBorderSetting,
    }


    -- Add classIcon settings specific to BlizzRaid layout
    layout.optionsTable.classIcon = {
        order = 1.5,
        name = L["Category_ClassIcon"],
        type = "group",
        get = function(info) 
            return layout.db.classIcon[info[#info]] 
        end,
        set = function(info, val)
            layout.db.classIcon[info[#info]] = val
            
            for i = 1, info.handler.maxArenaOpponents do
                local frame = info.handler["arena" .. i]
                layout:UpdateOrientation(frame)
            end
            
            --info.handler:RefreshConfig()
        end,
        args = {
            positioning = {
                order = 1,
                name = L["Positioning"],
                type = "group",
                inline = true,
                args = {
                    posX = {
                        order = 1,
                        name = L["Horizontal"],
                        type = "range",
                        min = -700,
                        max = 700,
                        softMin = -350,
                        softMax = 350,
                        step = 0.1,
                        bigStep = 1,
                    },
                    posY = {
                        order = 2,
                        name = L["Vertical"],
                        type = "range",
                        min = -700,
                        max = 700,
                        softMin = -350,
                        softMax = 350,
                        step = 0.1,
                        bigStep = 1,
                    },
                },
            },
            sizing = {
                order = 2,
                name = L["Sizing"],
                type = "group",
                inline = true,
                args = {
                    scale = {
                        order = 1,
                        name = L["Scale"],
                        type = "range",
                        min = 0.1,
                        max = 5.0,
                        softMin = 0.5,
                        softMax = 2.0,
                        step = 0.01,
                        isPercent = true,
                    },
                },
            },
        },
    }

end

function layout:Initialize(frame)
    self.db = frame.parent.db.profile.layoutSettings[layoutName]
    frame.parent.useSpecClassIcon = true

    if (not self.optionsTable) then
        setupOptionsTable(frame.parent)
    end

    frame:AddPixelBorderToFrame()

    if (frame:GetID() == frame.parent.maxArenaOpponents) then
        frame.parent:UpdateCastBarSettings(self.db.castBar)
        frame.parent:UpdateDRSettings(self.db.dr)
        frame.parent:UpdateFrameSettings(self.db)
        frame.parent:UpdateSpecIconSettings(self.db.specIcon)
        frame.parent:UpdateTrinketSettings(self.db.trinket)
        frame.parent:UpdateRacialSettings(self.db.racial)
        frame.parent:UpdateDispelSettings(self.db.dispel)
        frame.parent:UpdateWidgetSettings(self.db.widgets)

        for n = 1, #frame.parent.drCategories do
            local drFrame = frame[frame.parent.drCategories[n]]
            if drFrame and not drFrame.PixelBorder then
                if not drFrame.Border:GetTexture() then
                    drFrame.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress", true)
                end
            end
        end
    end

     --0,0,0,1,1,0,1,1

    frame:SetSize(self.db.width, self.db.height)
    frame.SpecIcon:SetSize(22, 22)
    frame.Trinket:SetSize(41, 41)
    frame.Racial:SetSize(41, 41)
    frame.Dispel:SetSize(41, 41)
    frame.Name:SetTextColor(1,1,1)
    frame.SpecNameText:SetTextColor(1,1,1)
    frame.ClassIcon.Cooldown:SetUseCircularEdge(false)
    frame.ClassIcon.Cooldown:SetSwipeTexture(1)


    frame.Trinket.Cooldown:SetSwipeTexture(1)
    frame.Trinket.Cooldown:SetSwipeColor(0, 0, 0, 0.55)
    frame.Trinket.Cooldown:SetUseCircularEdge(false)

    frame.Racial.Cooldown:SetSwipeTexture(1)
    frame.Racial.Cooldown:SetSwipeColor(0, 0, 0, 0.55)
    frame.Racial.Cooldown:SetUseCircularEdge(false)

    if not frame.Trinket.TrinketPixelBorderHook then
        hooksecurefunc(frame.Trinket.Texture, "SetTexture", function(self, t)
            if not frame.parent.showPixelBorder then
                frame.PixelBorders.trinket:Hide()
                return
            end

            if frame.parent.db.profile.colorTrinket then
                if frame.Trinket.spellID == nil then
                    frame.PixelBorders.trinket:Hide()
                    return
                end
                return
            end

            if not t then
                frame.PixelBorders.trinket:Hide()
            else
                frame.PixelBorders.trinket:Show()
            end
        end)

        hooksecurefunc(frame.Trinket.Texture, "SetColorTexture", function(self, r, g, b, a)
            if not frame.parent.showPixelBorder then
                frame.PixelBorders.trinket:Hide()
                return
            end

            if not frame.parent.db.profile.colorTrinket then
                return
            end

            if r ~= nil and g ~= nil and b ~= nil then
                frame.PixelBorders.trinket:Show()
            else
                frame.PixelBorders.trinket:Hide()
            end
        end)

        frame.Trinket.TrinketPixelBorderHook = true
    end

    if not frame.Racial.RacialPixelBorderHook then
        hooksecurefunc(frame.Racial.Texture, "SetTexture", function(self, t)
            if not t or not frame.parent.showPixelBorder then
                frame.PixelBorders.racial:Hide()
            else
                frame.PixelBorders.racial:Show()
            end
        end)
        frame.Racial.RacialPixelBorderHook = true
    end

    if not frame.Dispel.DispelPixelBorderHook then
        hooksecurefunc(frame.Dispel.Texture, "SetTexture", function(self, t)
            if not frame.parent.db.profile.showDispels or not t or not frame.parent.showPixelBorder then
                frame.PixelBorders.dispel:Hide()
            else
                frame.PixelBorders.dispel:Show()
            end
        end)
        hooksecurefunc(frame.Dispel, "Hide", function()
            frame.PixelBorders.dispel:Hide()
        end)
        frame.Dispel.DispelPixelBorderHook = true
    end

    if not frame.parent.db.profile.showDispels then
        frame.PixelBorders.dispel:Hide()
    end

    if not frame.ClassIcon.ClassIconPixelBorderHook then
        hooksecurefunc(frame.ClassIcon.Texture, "SetTexture", function(self, t)
            if not t or not frame.parent.showPixelBorder then
                frame.PixelBorders.classIcon:Hide()
            else
                frame.PixelBorders.classIcon:Show()
            end
        end)
        frame.ClassIcon.ClassIconPixelBorderHook = true
    end

    frame.PowerBar:SetHeight(self.db.powerBarHeight)

    local baseSize = self.db.height - 4
    frame.ClassIcon:SetSize(baseSize, baseSize)
    local classIconScale = self.db.classIcon and self.db.classIcon.scale or 1
    frame.ClassIcon:SetScale(classIconScale)
    frame.ClassIcon:Show()

    local f = frame.Name
    f:SetJustifyH("LEFT")
    --f:SetPoint("LEFT", frame.HealthBar, "LEFT", 3, -1)
    f:SetHeight(12)



    f = frame.DeathIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", frame.HealthBar, "CENTER", 0, -1)
    f:SetSize(self.db.height * 0.8, self.db.height * 0.8)

    frame.PowerText:SetAlpha(frame.parent.db.profile.hidePowerText and 0 or 1)

    frame.SpecNameText:SetPoint("LEFT", frame.PowerBar, "LEFT", 3, 0)

    self:UpdateOrientation(frame)
end

function layout:UpdateHealthbarOrientation(frame)
    local healthBar = frame.HealthBar
    local powerBar = frame.PowerBar
    local shouldHide = self.db.hideManabars and not (self.db.keepHealerManabar and frame.isHealer)

    healthBar:ClearAllPoints()
    if (self.db.mirrored) then
        healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -2)
        healthBar:SetPoint("BOTTOMLEFT", powerBar, shouldHide and "BOTTOMLEFT" or "TOPLEFT")
    else
        healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
        healthBar:SetPoint("BOTTOMRIGHT", powerBar, shouldHide and "BOTTOMRIGHT" or "TOPRIGHT")
    end

    powerBar:SetAlpha(shouldHide and 0 or 1)
    frame.PowerText:SetAlpha((shouldHide or frame.parent.db.profile.hidePowerText) and 0 or 1)

    if not self.db.textSettings then return end
    local txt = self.db.textSettings
    local hideOffset = (shouldHide and not self.db.moveStatusbarText) and (self.db.powerBarHeight / 2) or 0
    local name = frame.Name
    local healthText = frame.HealthText

    name:ClearAllPoints()
    if (txt.nameAnchor or "CENTER") == "LEFT" then
        name:SetPoint("LEFT", healthBar, "LEFT", 3 + (txt.nameOffsetX or 0), -1 + (txt.nameOffsetY or 0) + hideOffset)
    elseif (txt.nameAnchor or "CENTER") == "RIGHT" then
        name:SetPoint("RIGHT", healthBar, "RIGHT", -3 + (txt.nameOffsetX or 0), -1 + (txt.nameOffsetY or 0) + hideOffset)
    else
        name:SetPoint("CENTER", healthBar, "CENTER", (txt.nameOffsetX or 0), -1 + (txt.nameOffsetY or 0) + hideOffset)
    end

    hideOffset = (shouldHide and not self.db.moveStatusbarText) and hideOffset-1.5 or 0
    healthText:ClearAllPoints()
    if (txt.healthAnchor or "CENTER") == "LEFT" then
        healthText:SetPoint("LEFT", healthBar, "LEFT", 0 + (txt.healthOffsetX or 0), 1 + (txt.healthOffsetY or 0) + hideOffset)
    elseif (txt.healthAnchor or "CENTER") == "RIGHT" then
        healthText:SetPoint("RIGHT", healthBar, "RIGHT", 0 + (txt.healthOffsetX or 0), -1 + (txt.healthOffsetY or 0) + hideOffset)
    else
        healthText:SetPoint("CENTER", healthBar, "CENTER", (txt.healthOffsetX or 0), -1 + (txt.healthOffsetY or 0) + hideOffset)
    end
end

function layout:UpdateOrientation(frame)
    local healthBar = frame.HealthBar
    local powerBar = frame.PowerBar
    local classIcon = frame.ClassIcon
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
                (w.combatIndicator.posX or 0), (w.combatIndicator.posY or 0))
        end

        -- Target Indicator
        if w.targetIndicator then
            frame.WidgetOverlay.targetIndicator:ClearAllPoints()
            frame.WidgetOverlay.targetIndicator:SetSize(34, 34)
            frame.WidgetOverlay.targetIndicator:SetScale(w.targetIndicator.scale or 1)
            frame.WidgetOverlay.targetIndicator:SetPoint("TOPLEFT", frame.ClassIcon, "BOTTOMRIGHT",
                -16 + (w.targetIndicator.posX or 0), 15 + (w.targetIndicator.posY or 0))
        end

        -- Focus Indicator
        if w.focusIndicator then
            frame.WidgetOverlay.focusIndicator:ClearAllPoints()
            frame.WidgetOverlay.focusIndicator:SetSize(20, 20)
            frame.WidgetOverlay.focusIndicator:SetScale(w.focusIndicator.scale or 1)
            frame.WidgetOverlay.focusIndicator:SetPoint("BOTTOMRIGHT", frame.ClassIcon, "BOTTOMRIGHT",
                4 + (w.focusIndicator.posX or 0), -5 + (w.focusIndicator.posY or 0))
        end

        -- Party Target Indicators
        if w.partyTargetIndicators and w.partyTargetIndicators.partyOnArena then
            local poa = w.partyTargetIndicators.partyOnArena
            local direction = poa.direction or "LEFT"
            frame.WidgetOverlay.partyTarget1:ClearAllPoints()
            frame.WidgetOverlay.partyTarget1:SetSize(15, 15)
            frame.WidgetOverlay.partyTarget1:SetScale(poa.scale or 1)
            frame.WidgetOverlay.partyTarget1:SetPoint("BOTTOMRIGHT", frame.HealthBar, "TOPRIGHT",
                2 + (poa.posX or 0), (poa.posY or 0) - 4)

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

        -- Spec Text
        specName:ClearAllPoints()
        if (txt.specNameAnchor or "CENTER") == "LEFT" then
            specName:SetPoint("LEFT", frame.PowerBar, "LEFT", 3 + (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
        elseif (txt.specNameAnchor or "CENTER") == "RIGHT" then
            specName:SetPoint("RIGHT", frame.PowerBar, "RIGHT", -3 + (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
        else
            specName:SetPoint("CENTER", frame.PowerBar, "CENTER", (txt.specNameOffsetX or 0), (txt.specNameOffsetY or 0))
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

    powerBar:ClearAllPoints()
    frame.ClassIcon:ClearAllPoints()

    -- Apply classIcon settings
    local classIconSettings = self.db.classIcon or { posX = 0, posY = 0, scale = 1 }
    local baseSize = self.db.height - 4
    frame.ClassIcon:SetSize(baseSize, baseSize)
    frame.ClassIcon:SetScale(classIconSettings.scale or 1)

    if (self.db.mirrored) then
        powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 2)
        powerBar:SetPoint("LEFT", frame, "LEFT", baseSize, 0)

        classIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", (classIconSettings.posX or 0), -2 + (classIconSettings.posY or 0))
    else
        powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 2)
        powerBar:SetPoint("RIGHT", frame, "RIGHT", -baseSize, 0)

        classIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", (classIconSettings.posX or 0), -2 + (classIconSettings.posY or 0))
    end

    self:UpdateHealthbarOrientation(frame)
end

sArenaMixin.layouts[layoutName] = layout
sArenaMixin.defaultSettings.profile.layoutSettings[layoutName] = layout.defaultSettings