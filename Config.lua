local LSM = LibStub("LibSharedMedia-3.0")
local isRetail = sArenaMixin.isRetail
local isMidnight = sArenaMixin.isMidnight
local isTBC = sArenaMixin.isTBC
local L = sArenaMixin.L

local function GetClassOptionName(classToken)
    local icon = sArenaMixin.classIcons[classToken]
    local color = C_ClassColor.GetClassColor(classToken)
    local name = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken] or classToken
    local label = name
    if color then
        local hex
        if color.colorStr then
            hex = color.colorStr
        elseif color.r and color.g and color.b then
            hex = string.format("ff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
        end
        if hex then
            label = "|c" .. hex .. name .. "|r"
        end
    end
    if icon then
        label = "|T" .. icon .. ":16:16:0:0|t " .. label
    end
    return label
end

local function GetSpellInfoCompat(spellID)
    if not spellID then
        return nil
    end

    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
        end
    end

    return nil
end

local function GetSpellDescriptionCompat(spellID)
    if not spellID then
        return ""
    end

    if GetSpellDescription then
        return GetSpellDescription(spellID) or ""
    end

    if C_Spell and C_Spell.GetSpellDescription then
        return C_Spell.GetSpellDescription(spellID) or ""
    end

    return ""
end

local function getLayoutTable()
    local t = {}

    for k, _ in pairs(sArenaMixin.layouts) do
        t[k] = sArenaMixin.layouts[k].name and sArenaMixin.layouts[k].name or k
    end

    return t
end

local function validateCombat()
    if (InCombatLockdown()) then
        return L["Message_MustLeaveCombat"]
    end

    return true
end

local growthValues = { L["Direction_Down"], L["Direction_Up"], L["Direction_Right"], L["Direction_Left"] }
local drIcons = sArenaMixin.defaultSettings.profile.drIcons or {}

local drCategoryDisplay = {}
for category, tex in pairs(drIcons) do
    drCategoryDisplay[category] = "|cFFFFFFFF|T" .. tostring(tex) .. ":16|t " .. (L["DR_" .. category] or category) .. "|r"
end

local racialCategories = {}
for raceKey, data in pairs(sArenaMixin.racialData or {}) do
    local name = L["Race_" .. raceKey] or raceKey
    local texture = data and data.texture
    if texture then
        if type(texture) == "string" then
            racialCategories[raceKey] = "|T" .. texture .. ":16|t " .. name
        else
            racialCategories[raceKey] = "|T" .. tostring(texture) .. ":16|t " .. name
        end
    else
        racialCategories[raceKey] = name
    end
end

local function StatusbarValues()
    local t, keys = {}, {}
    for k in pairs(LSM:HashTable(LSM.MediaType.STATUSBAR)) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do t[k] = k end
    return t
end

local function SoundValues()
    local t, keys = {}, {}
    for k in pairs(LSM:HashTable(LSM.MediaType.SOUND)) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do t[k] = k end
    return t
end

function sArenaMixin:GetLayoutOptionsTable(layoutName)
    local function LDB(info)
        return info.handler.db.profile.layoutSettings[layoutName]
    end
    local function getSetting(info)
        return LDB(info)[info[#info]]
    end
    local function getFontOutlineSetting(info)
        local value = LDB(info)[info[#info]]
        if value == nil then
            return "OUTLINE"
        end
        return value
    end
    local function setSetting(info, val)
        local db = LDB(info)
        db[info[#info]] = val

        if self.RefreshConfig then self:RefreshConfig() end
    end

    local optionsTable = {
        arenaFrames = {
            order = 1,
            name = L["Category_ArenaFrames"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName][info[#info]] end,
            set = function(info, val)
                self:UpdateFrameSettings(info.handler.db.profile.layoutSettings[layoutName], info,
                    val)
            end,
            args = {
                textures = {
                    order  = 0.1,
                    name   = L["Textures"],
                    type   = "group",
                    inline = true,
                    args   = {
                        generalTexture = {
                            order         = 1,
                            type          = "select",
                            name          = "|A:UI-LFG-RoleIcon-DPS-Micro:20:20|a " .. L["Texture_General"],
                            desc          = L["Texture_General_Desc"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.generalStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                }
                                layout.textures.generalStatusBarTexture = key
                                info.handler:UpdateTextures()
                            end,
                        },
                        healerTexture = {
                            order         = 2,
                            type          = "select",
                            name          = "|A:UI-LFG-RoleIcon-Healer-Micro:20:20|a " .. L["Texture_Healer"],
                            desc          = L["Texture_Healer_Desc"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.healStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                }
                                layout.textures.healStatusBarTexture = key
                                info.handler:UpdateTextures()
                            end,
                        },
                        healerClassStackOnly = {
                            order = 3,
                            type  = "toggle",
                            name  = L["Texture_ClassStackingOnly"],
                            desc  = L["Texture_ClassStackingOnly_Desc"],
                            get   = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return layout.retextureHealerClassStackOnly or false
                            end,
                            set   = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.retextureHealerClassStackOnly = val
                                info.handler:UpdateTextures()
                            end,
                            width = "75%",
                        },
                        bgTexture = {
                            order         = 4,
                            type          = "select",
                            name          = L["Texture_Background"],
                            desc          = L["Texture_Background_Desc"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.bgTexture) or "Solid"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                    bgTexture = "Solid",
                                }
                                layout.textures.bgTexture = key
                                info.handler:UpdateTextures()
                            end,
                            width = "75%",
                        },
                        bgColor = {
                            order = 5,
                            type  = "color",
                            name  = L["Texture_BackgroundColor"],
                            desc  = L["Texture_BackgroundColor_Desc"],
                            hasAlpha = true,
                            get   = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local c = layout.textures and layout.textures.bgColor or {0, 0, 0, 0.6}
                                return c[1], c[2], c[3], c[4]
                            end,
                            set   = function(info, r, g, b, a)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                    bgTexture = "Solid",
                                    bgColor = {0, 0, 0, 0.6},
                                }
                                layout.textures.bgColor = {r, g, b, a}
                                info.handler:UpdateTextures()
                            end,
                            width = 1.5,
                        },
                    },
                },
                other = {
                    order  = 0.5,
                    name   = L["Options"],
                    type   = "group",
                    inline = true,
                    args   = {
                        replaceClassIcon = {
                            order = 2,
                            type  = "toggle",
                            name  = L["Option_ReplaceClassIcon"],
                            desc  = L["Option_ReplaceClassIcon_Desc"],
                            get   = getSetting,
                            set   = setSetting,
                        },
                        hideSpecIcon = {
                            order = 2.5,
                            type  = "toggle",
                            name  = L["Option_HideSpecIcon"],
                            desc  = L["Option_HideSpecIcon_Desc"],
                            get   = getSetting,
                            set   = setSetting,
                        },
                        showSpecManaText = {
                            order = 3,
                            type  = "toggle",
                            name  = L["Option_SpecTextOnManabar"],
                            get   = getSetting,
                            set   = setSetting,
                        },
                        showRaceManaText = {
                            order = 3.1,
                            type  = "toggle",
                            name  = L["Option_RaceTextOnManabar"],
                            desc  = L["Option_RaceTextOnManabar_Desc"],
                            get   = getSetting,
                            set   = setSetting,
                        },
                        manabarVisibility = {
                            order = 4,
                            name = L["Option_ManabarVisibility"],
                            type = "group",
                            inline = true,
                            hidden = function()
                                return layoutName == "BlizzArena" or layoutName == "BlizzTourney"
                            end,
                            args = {
                                hideManabars = {
                                    order = 1,
                                    type  = "toggle",
                                    name  = L["Option_HideManabars"],
                                    get   = getSetting,
                                    set   = setSetting,
                                },
                                keepHealerManabar = {
                                    order = 2,
                                    type  = "toggle",
                                    name  = L["Option_KeepHealerManabar"],
                                    disabled = function(info)
                                        return not LDB(info).hideManabars
                                    end,
                                    get   = getSetting,
                                    set   = setSetting,
                                },
                                moveStatusbarText = {
                                    order = 3,
                                    type  = "toggle",
                                    name  = L["Option_MoveStatusbarText"],
                                    desc  = L["Option_MoveStatusbarText_Desc"],
                                    disabled = function(info)
                                        return not LDB(info).hideManabars
                                    end,
                                    get   = getSetting,
                                    set   = setSetting,
                                },
                            },
                        },
                    },
                },
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
                            min = -1000,
                            max = 1000,
                            step = 0.1,
                            bigStep = 1,
                        },
                        posY = {
                            order = 2,
                            name = L["Vertical"],
                            type = "range",
                            min = -1000,
                            max = 1000,
                            step = 0.1,
                            bigStep = 1,
                        },
                        spacing = {
                            order = 3,
                            name = L["Spacing"],
                            desc = L["Option_SpacingBetweenFrames_Desc"],
                            type = "range",
                            min = -10,
                            max = 100,
                            step = 1,
                        },
                        growthDirection = {
                            order = 4,
                            name = L["Option_GrowthDirection"],
                            type = "select",
                            style = "dropdown",
                            values = growthValues,
                        },
                    },
                },
                sizing = {
                    order = 0.3,
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
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                        },
                        classIconFontSize = {
                            order = 2,
                            name = L["Option_ClassIconCDFontSize"],
                            desc = L["Option_FontSize_Desc"],
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        castBar = {
            order = 2,
            name = L["Category_CastBars"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].castBar[info[#info]] end,
            set = function(info, val)
                self:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                if info.handler.RefreshMasque then
                    info.handler:RefreshMasque()
                end
            end,
            args = {
                castBarLook = {
                    order  = 0,
                    name   = L["Castbar_Look"],
                    type   = "group",
                    inline = true,
                    args   = {
                        useModernCastbars = {
                            order = 1,
                            type  = "toggle",
                            name  = L["Castbar_UseModern"],
                            desc  = L["Castbar_UseModern_Desc"],
                            width = "75%",
                            set   = function(info, val)
                                local castDB = info.handler.db.profile.layoutSettings[layoutName].castBar
                                castDB.useModernCastbars = val
                                info.handler:UpdateTextures()
                                info.handler:RefreshTestModeCastbars()
                                info.handler:RefreshConfig()
                            end,
                        },

                        keepDefaultModernTextures = {
                            order    = 2,
                            type     = "toggle",
                            name     = L["Castbar_KeepDefaultModernTextures"],
                            width    = "90%",
                            desc     = L["Castbar_KeepDefaultModernTextures_Desc"],
                            disabled = function(info)
                                return not info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars
                            end,
                            set      = function(info, val)
                                local castDB = info.handler.db.profile.layoutSettings[layoutName].castBar
                                castDB.keepDefaultModernTextures = val
                                info.handler:UpdateTextures()
                                info.handler:RefreshTestModeCastbars()
                                info.handler:RefreshConfig()
                            end,
                        },

                        simpleCastbar = {
                            order    = 2.3,
                            type     = "toggle",
                            name     = L["Castbar_Simple"],
                            width    = "75%",
                            desc     = L["Castbar_Simple_Desc"],
                            disabled = function(info)
                                return not info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars
                            end,
                            get      = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.simpleCastbar
                            end,
                            set      = function(info, val)
                                local castDB = info.handler.db.profile.layoutSettings[layoutName].castBar
                                castDB.simpleCastbar = val
                                info.handler:RefreshConfig()
                            end,
                        },

                        spacerOne = {
                            order = 2.4,
                            type  = "description",
                            name  = "",
                            width = "full",
                        },

                        hideBorderShield = {
                            order = 2.5,
                            name = L["Castbar_HideShield"],
                            desc = L["Castbar_HideShield_Desc"],
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.hideBorderShield
                            end,
                            set = function(info, val)
                                info.handler.db.profile.layoutSettings[layoutName].castBar.hideBorderShield = val
                                info.handler:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                            end,
                        },

                        hideCastbarSpark = {
                            order = 2.6,
                            name = L["Castbar_HideSpark"],
                            desc = L["Castbar_HideSpark_Desc"],
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbarSpark
                            end,
                            set = function(info, val)
                                info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbarSpark = val
                                info.handler:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                            end,
                        },

                        hideCastbarIcon = {
                            order = 2.7,
                            name = L["Castbar_HideIcon"],
                            desc = L["Castbar_HideIcon_Desc"],
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbarIcon
                            end,
                            set = function(info, val)
                                info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbarIcon = val
                                info.handler:UpdateCastBarSettings(info.handler.db.profile.layoutSettings[layoutName].castBar, info, val)
                            end,
                        },

                        showCastbarID = {
                            order = 2.8,
                            name = L["Castbar_ShowID"],
                            desc = L["Castbar_ShowID_Desc"],
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.showCastbarID
                            end,
                            set = function(info, val)
                                info.handler.db.profile.showCastbarID = val
                                info.handler:CreateCastbarIDText()
                                info.handler:UpdateCastbarIDText()
                            end,
                        },

                        showCastbarTarget = {
                            order = 2.85,
                            name = UnitSpellTargetName and L["Castbar_ShowTarget"] or ("|A:services-icon-warning:20:20|a " .. L["Castbar_ShowTarget"] .. " |A:services-icon-warning:20:20|a"),
                            desc = UnitSpellTargetName and L["Castbar_ShowTarget_Desc_Midnight"] or L["Castbar_ShowTarget_Desc"],
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.showCastbarTarget
                            end,
                            set = function(info, val)
                                info.handler.db.profile.showCastbarTarget = val
                                info.handler:CreateCastbarHighlight()
                                info.handler:CreateCastbarTargetText()
                                info.handler:UpdateCastbarTargetText()
                                info.handler:RefreshTestModeCastbars()
                            end,
                        },

                        hideCastbars = {
                            order = 2.86,
                            name = L["Option_HideCastbars"],
                            desc = L["Option_HideCastbars_Desc"],
                            type = "toggle",
                            get = function(info)
                                local layoutName = info.handler.db.profile.currentLayout
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbars
                            end,
                            set = function(info, val)
                                local layoutName = info.handler.db.profile.currentLayout
                                info.handler.db.profile.layoutSettings[layoutName].castBar.hideCastbars = val
                                info.handler:UpdateCastbarVisibility()
                            end,
                        },

                        spacer = {
                            order = 2.9,
                            type  = "description",
                            name  = "",
                            width = "full",
                        },

                        castbarStatusBarTexture = {
                            order         = 3,
                            type          = "select",
                            name          = "|A:GarrMission_ClassIcon-DemonHunter-Outcast:20:20|a " .. L["Castbar_Texture"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.castbarStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                }
                                layout.textures.castbarStatusBarTexture = key
                                info.handler:UpdateTextures()
                            end,
                            width         = "75%",
                            disabled      = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars and info.handler.db.profile.layoutSettings[layoutName].castBar.keepDefaultModernTextures
                            end,
                        },
                        castbarUninterruptibleTexture = {
                            order         = 3.5,
                            type          = "select",
                            name          = "|A:GarrMission_ClassIcon-DemonHunter-Outcast:20:20|a " .. L["Castbar_UninterruptibleTexture"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.castbarUninterruptibleTexture) or (t and t.castbarStatusBarTexture) or "sArena Default"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                }
                                layout.textures.castbarUninterruptibleTexture = key
                                info.handler:UpdateTextures()
                            end,
                            width         = "75%",
                            disabled      = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].castBar.useModernCastbars and info.handler.db.profile.layoutSettings[layoutName].castBar.keepDefaultModernTextures
                            end,
                        },
                        castbarBgTexture = {
                            order         = 3.6,
                            type          = "select",
                            name          = L["Castbar_BackgroundTexture"],
                            desc          = L["Castbar_BackgroundTexture_Desc"],
                            style         = "dropdown",
                            dialogControl = "LSM30_Statusbar",
                            values        = StatusbarValues,
                            get           = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local t = layout.textures
                                return (t and t.castbarBgTexture) or "Solid"
                            end,
                            set           = function(info, key)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                    castbarBgTexture = "Solid",
                                }
                                layout.textures.castbarBgTexture = key
                                info.handler:UpdateTextures()
                            end,
                            width = "75%",
                        },
                        castbarBgColor = {
                            order = 3.7,
                            type  = "color",
                            name  = L["Castbar_BackgroundColor"],
                            desc  = L["Castbar_BackgroundColor_Desc"],
                            hasAlpha = true,
                            get   = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local c = layout.textures and layout.textures.castbarBgColor or {0, 0, 0, 0.5}
                                return c[1], c[2], c[3], c[4]
                            end,
                            set   = function(info, r, g, b, a)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textures = layout.textures or {
                                    generalStatusBarTexture = "sArena Default",
                                    healStatusBarTexture    = "sArena Default",
                                    castbarStatusBarTexture = "sArena Default",
                                    castbarUninterruptibleTexture = "sArena Default",
                                    castbarBgTexture = "Solid",
                                    castbarBgColor = {0, 0, 0, 0.5},
                                }
                                layout.textures.castbarBgColor = {r, g, b, a}
                                info.handler:UpdateTextures()
                            end,
                            width = 1.5,
                        },
                        castBarColorsGroup = {
                            order = 4,
                            type = "group",
                            name = L["Castbar_Colors"],
                            inline = true,
                            args = {
                                recolorCastbar = {
                                    order = 0,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Castbar_RecolorCastbar"],
                                    desc = L["Castbar_RecolorCastbar_Desc"],
                                    get = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return layout.castBar.recolorCastbar or false
                                    end,
                                    set = function(info, val)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        layout.castBar.recolorCastbar = val
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                standard = {
                                    order = 1,
                                    disabled = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return not layout.castBar.recolorCastbar
                                    end,
                                    type = "color",
                                    name = L["Castbar_Cast"],
                                    hasAlpha = true,
                                    get = function(info)
                                        local colors = info.handler.db.profile.castBarColors
                                        if colors and colors.standard then
                                            return unpack(colors.standard)
                                        end
                                        return 1.0, 0.7, 0.0, 1
                                    end,
                                    set = function(info, r, g, b, a)
                                        info.handler.db.profile.castBarColors = info.handler.db.profile.castBarColors or {}
                                        info.handler.db.profile.castBarColors.standard = {r, g, b, a}
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                channel = {
                                    order = 2,
                                    type = "color",
                                    name = L["Castbar_Channeled"],
                                    hasAlpha = true,
                                    disabled = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return not layout.castBar.recolorCastbar
                                    end,
                                    get = function(info)
                                        local colors = info.handler.db.profile.castBarColors
                                        if colors and colors.channel then
                                            return unpack(colors.channel)
                                        end
                                        return 0.0, 1.0, 0.0, 1
                                    end,
                                    set = function(info, r, g, b, a)
                                        info.handler.db.profile.castBarColors = info.handler.db.profile.castBarColors or {}
                                        info.handler.db.profile.castBarColors.channel = {r, g, b, a}
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                uninterruptable = {
                                    order = 3,
                                    type = "color",
                                    name = L["Castbar_Uninterruptible"],
                                    hasAlpha = true,
                                    disabled = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return not layout.castBar.recolorCastbar
                                    end,
                                    get = function(info)
                                        local colors = info.handler.db.profile.castBarColors
                                        if colors and colors.uninterruptable then
                                            return unpack(colors.uninterruptable)
                                        end
                                        return 0.7, 0.7, 0.7, 1
                                    end,
                                    set = function(info, r, g, b, a)
                                        info.handler.db.profile.castBarColors = info.handler.db.profile.castBarColors or {}
                                        info.handler.db.profile.castBarColors.uninterruptable = {r, g, b, a}
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                            },
                        },
                        interruptNotReadyGroup = {
                            order = 5,
                            type = "group",
                            name = L["Castbar_InterruptNotReady"],
                            inline = true,
                            args = {
                                interruptStatusColorOn = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Castbar_EnableNoInterruptColor"],
                                    desc = L["Castbar_EnableNoInterruptColor_Desc"],
                                    get = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return layout.castBar.interruptStatusColorOn or false
                                    end,
                                    set = function(info, val)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        layout.castBar.interruptStatusColorOn = val
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                includeShadowWordDeath = {
                                    order = 2,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Castbar_IncludeShadowWordDeath"],
                                    desc = L["Castbar_IncludeShadowWordDeath_Desc"],
                                    hidden = function() return select(2, UnitClass("player")) ~= "PRIEST" end,
                                    disabled = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return not (layout.castBar.interruptStatusColorOn)
                                    end,
                                    get = function(info)
                                        return info.handler.db.profile.includeShadowWordDeath or false
                                    end,
                                    set = function(info, val)
                                        info.handler.db.profile.includeShadowWordDeath = val
                                        info.handler:UpdateShadowWordDeathInterrupt()
                                    end,
                                },
                                interruptNotReady = {
                                    order = 3,
                                    type = "color",
                                    name = L["Castbar_InterruptNotReadyColor"],
                                    width = "full",
                                    hasAlpha = true,
                                    disabled = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        return not (layout.castBar.interruptStatusColorOn)
                                    end,
                                    get = function(info)
                                        local colors = info.handler.db.profile.castBarColors
                                        if colors and colors.interruptNotReady then
                                            return unpack(colors.interruptNotReady)
                                        end
                                        return 1.0, 0.0, 0.0, 1
                                    end,
                                    set = function(info, r, g, b, a)
                                        info.handler.db.profile.castBarColors = info.handler.db.profile.castBarColors or {}
                                        info.handler.db.profile.castBarColors.interruptNotReady = {r, g, b, a}
                                        info.handler:UpdateCastbarColors()
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                            },
                        },
                        castbarHighlightGroup = {
                            order = 6,
                            type = "group",
                            name = L["Castbar_HighlightGroup"],
                            inline = true,
                            hidden = function() return not (PlayerIsSpellTarget or (C_Spell and C_Spell.IsSpellCrowdControl)) end,
                            args = {
                                highlightCastsOnMe = {
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                    hidden = function() return not PlayerIsSpellTarget end,
                                    name = L["Castbar_HighlightCastsOnMe"],
                                    desc = L["Castbar_HighlightCastsOnMe_Desc"],
                                    get = function(info)
                                        return info.handler.db.profile.highlightCastsOnMe
                                    end,
                                    set = function(info, val)
                                        info.handler.db.profile.highlightCastsOnMe = val
                                        if val then
                                            info.handler.db.profile.highlightCC = false
                                        end
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                highlightCC = {
                                    order = 2,
                                    type = "toggle",
                                    width = "full",
                                    hidden = function() return not (C_Spell and C_Spell.IsSpellCrowdControl) end,
                                    name = L["Castbar_HighlightCC"],
                                    desc = L["Castbar_HighlightCC_Desc"],
                                    get = function(info)
                                        return info.handler.db.profile.highlightCC
                                    end,
                                    set = function(info, val)
                                        info.handler.db.profile.highlightCC = val
                                        if val then
                                            info.handler.db.profile.highlightCastsOnMe = false
                                        end
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                glowCastbarIcon = {
                                    order = 2.5,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Castbar_GlowIcon"],
                                    desc = L["Castbar_GlowIcon_Desc"],
                                    get = function(info)
                                        return info.handler.db.profile.glowCastbarIcon or false
                                    end,
                                    set = function(info, val)
                                        info.handler.db.profile.glowCastbarIcon = val
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                useHighlightColor = {
                                    order = 3,
                                    type = "toggle",
                                    width = "full",
                                    name = L["Castbar_UseHighlightColor"],
                                    desc = L["Castbar_UseHighlightColor_Desc"],
                                    get = function(info)
                                        return info.handler.db.profile.useHighlightColor or false
                                    end,
                                    set = function(info, val)
                                        info.handler.db.profile.useHighlightColor = val
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                                highlightColor = {
                                    order = 4,
                                    type = "color",
                                    name = L["Castbar_HighlightColor"],
                                    desc = L["Castbar_HighlightColor_Desc"],
                                    hasAlpha = true,
                                    disabled = function(info)
                                        return not (info.handler.db.profile.useHighlightColor)
                                    end,
                                    get = function(info)
                                        local c = info.handler.db.profile.highlightColor
                                        if c then return unpack(c) end
                                        return 0, 1, 0, 1
                                    end,
                                    set = function(info, r, g, b, a)
                                        info.handler.db.profile.highlightColor = {r, g, b, a}
                                        info.handler:UpdateTextures()
                                        info.handler:RefreshTestModeCastbars()
                                    end,
                                },
                            },
                        },
                    },
                },
                castbarSettings = {
                    order = 1,
                    name = L["Castbar_Settings"],
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
                        spacer = {
                            order = 3,
                            type = "description",
                            name = "",
                            width = "full",
                        },
                        scale = {
                            order = 4,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                        },
                        width = {
                            order = 5,
                            name = L["Width"],
                            type = "range",
                            min = 10,
                            max = 400,
                            step = 1,
                        },
                    },
                },
                iconSettings = {
                    order = 2,
                    name = L["Castbar_IconSettings"],
                    type = "group",
                    inline = true,
                    args = {
                        iconPosX = {
                            order = 1,
                            name = L["Horizontal"],
                            type = "range",
                            min = -500,
                            max = 500,
                            softMin = -200,
                            softMax = 200,
                            step = 0.1,
                            bigStep = 1,
                        },
                        iconPosY = {
                            order = 2,
                            name = L["Vertical"],
                            type = "range",
                            min = -500,
                            max = 500,
                            softMin = -200,
                            softMax = 200,
                            step = 0.1,
                            bigStep = 1,
                        },
                        iconScale = {
                            order = 3,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 5.0,
                            softMin = 0.5,
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                        },
                    },
                },
            },
        },
        dr = {
            order = 3,
            name = L["Category_DiminishingReturns"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].dr[info[#info]] end,
            set = function(info, val)
                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                if info.handler.RefreshMasque then
                    info.handler:RefreshMasque()
                end
            end,
            args = {
                options = {
                    order = 0.2,
                    name = L["Options"],
                    type = "group",
                    inline = true,
                    args = {
                        brightDRBorder = {
                            order = 1,
                            name  = L["DR_BrightBorder"],
                            type  = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.brightDRBorder
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.brightDRBorder = val
                                if val then
                                    db.drBorderGlowOff = false
                                    db.thickPixelBorder = false
                                    db.thinPixelBorder = false
                                end
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        blackDRBorder = {
                            order = 2,
                            name  = L["DR_BlackBorder"],
                            type  = "toggle",
                            desc  = L["DR_BlackBorder_Desc"],
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.blackDRBorder
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.blackDRBorder = val
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                info.handler:RefreshConfig()
                                info.handler:Test()
                            end,
                        },
                        showDRText = {
                            order = 3,
                            name = L["DR_ShowText"],
                            desc = L["DR_ShowText_Desc"],
                            type = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.showDRText
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.showDRText = val
                                self:UpdateDRSettings(db, info, val)
                            end,
                        },
                        drBorderGlowOff = {
                            order = 4,
                            name  = L["DR_DisableBorderGlow"],
                            type  = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.drBorderGlowOff
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.drBorderGlowOff = val
                                if val then
                                    db.brightDRBorder = false
                                    db.thickPixelBorder = false
                                    db.thinPixelBorder = false
                                end
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                info.handler:RefreshConfig()
                                info.handler:Test()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        thickPixelBorder = {
                            order = 5,
                            name  = L["DR_ThickPixelBorder"],
                            type  = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.thickPixelBorder
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.thickPixelBorder = val
                                if val then
                                    db.brightDRBorder = false
                                    db.drBorderGlowOff = false
                                    db.thinPixelBorder = false
                                end
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                info.handler:RefreshConfig()
                                info.handler:Test()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        thinPixelBorder = {
                            order = 5.5,
                            name  = L["DR_ThinPixelBorder"],
                            type  = "toggle",
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.thinPixelBorder
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.thinPixelBorder = val
                                if val then
                                    db.brightDRBorder = false
                                    db.drBorderGlowOff = false
                                    db.thickPixelBorder = false
                                end
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                info.handler:RefreshConfig()
                                info.handler:Test()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        disableDRBorder = {
                            order = 6,
                            name  = L["DR_DisableBorder"],
                            type  = "toggle",
                            desc  = L["DR_DisableBorder_Desc"],
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].dr.disableDRBorder
                            end,
                            set = function(info, val)
                                local db = info.handler.db.profile.layoutSettings[layoutName].dr
                                db.disableDRBorder = val
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                                info.handler:RefreshConfig()
                                info.handler:Test()
                            end,
                        },
                    },
                },
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
                        spacing = {
                            order = 3,
                            name = L["Spacing"],
                            type = "range",
                            min = 0,
                            max = 32,
                            softMin = 0,
                            softMax = 32,
                            step = 1,
                        },
                        growthDirection = {
                            order = 4,
                            name = L["Option_GrowthDirection"],
                            type = "select",
                            style = "dropdown",
                            values = growthValues,
                        },
                    },
                },
                sizing = {
                    order = 2,
                    name = L["Sizing"],
                    type = "group",
                    inline = true,
                    args = {
                        size = {
                            order = 1,
                            name = L["Size"],
                            type = "range",
                            min = 2,
                            max = 128,
                            softMin = 8,
                            softMax = 64,
                            step = 1,
                        },
                        borderSize = {
                            order = 2,
                            name = L["DR_BorderSize"],
                            type = "range",
                            min = 0,
                            max = 24,
                            softMin = 1,
                            softMax = 16,
                            step = 0.1,
                            bigStep = 1,
                            hidden = function(info)
                                local drSettings = info.handler.db.profile.layoutSettings[layoutName].dr
                                return drSettings.thickPixelBorder
                            end,
                            disabled = function(info)
                                local drSettings = info.handler.db.profile.layoutSettings[layoutName].dr
                                return drSettings.brightDRBorder or drSettings.drBorderGlowOff or drSettings.thinPixelBorder
                            end,
                        },
                        drPixelBorderSize = {
                            order = 2,
                            name = L["Option_DRPixelBorderSize"],
                            type = "range",
                            min = 0.5,
                            max = 3,
                            step = 0.5,
                            hidden = function(info)
                                local drSettings = info.handler.db.profile.layoutSettings[layoutName].dr
                                return not drSettings.thickPixelBorder
                            end,
                            get = function(info)
                                return info.handler.db.profile.layoutSettings[layoutName].drPixelBorderSize or 2
                            end,
                            set = function(info, val)
                                info.handler.db.profile.layoutSettings[layoutName].drPixelBorderSize = val
                                self:UpdateDRSettings(info.handler.db.profile.layoutSettings[layoutName].dr, info, val)
                            end,
                        },
                        fontSize = {
                            order = 3,
                            name = L["Option_FontSize"],
                            desc = L["Option_FontSize_Desc"],
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
                drCategorySizing = {
                    order = 3,
                    name = L["DR_SpecificSizeAdjustment"],
                    type = "group",
                    inline = true,
                    hidden = function() return isMidnight end,
                    args = {},
                },
            },
        },
        dispel = {
            order = 4,
            name = L["Category_Dispels"],
            type = "group",
            hidden = function() return isMidnight end,
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].dispel[info[#info]] end,
            set = function(info, val)
                self:UpdateDispelSettings(
                    info.handler.db.profile.layoutSettings[layoutName].dispel, info, val)
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
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                        },
                        fontSize = {
                            order = 3,
                            name = L["Option_FontSize"],
                            desc = L["Option_FontSize_Desc"],
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        racial = {
            order = 5,
            name = L["Category_Racials"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].racial[info[#info]] end,
            set = function(info, val)
                self:UpdateRacialSettings(
                    info.handler.db.profile.layoutSettings[layoutName].racial, info, val)
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
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                        },
                        fontSize = {
                            order = 3,
                            name = L["Option_FontSize"],
                            desc = L["Option_FontSize_Desc"],
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        specIcon = {
            order = 6,
            name = L["Category_SpecIcons"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].specIcon[info[#info]] end,
            set = function(info, val)
                self:UpdateSpecIconSettings(
                    info.handler.db.profile.layoutSettings[layoutName].specIcon, info, val)
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
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                        },
                    },
                },
            },
        },
        textSettings = {
            order = 7,
            name = L["Category_TextSettings"],
            type = "group",
            args = {
                fonts = {
                    order  = 0,
                    name   = L["Text_Fonts"],
                    type   = "group",
                    inline = true,
                    args   = {
                        changeFont = {
                            order = 0,
                            type = "toggle",
                            name  = L["Text_ChangeFont"],
                            desc  = L["Text_ChangeFont_Desc"],
                            width = "full",
                            get   = getSetting,
                            set   = setSetting,
                        },
                        improveTextRendering = {
                            order = 0.5,
                            type = "toggle",
                            name  = L["Text_ImproveTextRendering"],
                            desc  = L["Text_ImproveTextRendering_Desc"],
                            width = "full",
                            get   = function(info) return info.handler.db.profile.improveTextRendering end,
                            set   = function(info, val)
                                info.handler.db.profile.improveTextRendering = val
                                if self.RefreshConfig then self:RefreshConfig() end
                            end,
                        },
                        frameFont = {
                            order = 1, type = "select",
                            name  = L["Text_FrameFont"],
                            desc  = L["Text_FrameFont_Desc"],
                            style = "dropdown",
                            width = 0.7,
                            dialogControl = "LSM30_Font",
                            values = sArenaMixin.FontValues,
                            get    = getSetting,
                            set    = setSetting,
                            disabled = function(info)
                                return not info.handler.db.profile.layoutSettings[layoutName].changeFont
                            end,
                        },
                        cdFont = {
                            order = 2, type = "select",
                            name  = L["Text_CooldownFont"],
                            desc  = L["Text_CooldownFont_Desc"],
                            style = "dropdown",
                            width = 0.7,
                            dialogControl = "LSM30_Font",
                            values = sArenaMixin.FontValues,
                            get    = getSetting,
                            set    = setSetting,
                            disabled = function(info)
                                return not info.handler.db.profile.layoutSettings[layoutName].changeFont
                            end,
                        },
                        fontOutline = {
                            order = 3, type = "select",
                            name  = L["Text_FontOutline"],
                            desc  = L["Text_FontOutline_Desc"],
                            style = "dropdown",
                            width = 0.7,
                            values = sArenaMixin.FontOutlineValues,
                            get    = getFontOutlineSetting,
                            set    = setSetting,
                            disabled = function(info)
                                return not info.handler.db.profile.layoutSettings[layoutName].changeFont
                            end,
                        },
                    },
                },
                nameText = {
                    order = 1,
                    name = L["Text_NameText"],
                    type = "group",
                    inline = true,
                    args = {
                        nameAnchor = {
                            order = 1,
                            name = L["Text_AnchorPoint"],
                            type = "select",
                            style = "dropdown",
                            width = 0.5,
                            values = {
                                ["LEFT"] = L["Direction_Left"],
                                ["CENTER"] = L["Direction_Center"],
                                ["RIGHT"] = L["Direction_Right"],
                            },
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.nameAnchor or "CENTER"
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.nameAnchor = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        nameSize = {
                            order = 2,
                            name = L["Size"],
                            type = "range",
                            min = 0.2,
                            max = 3,
                            softMin = 0.05,
                            softMax = 5,
                            step = 0.01,
                            width = 0.8,
                            isPercent = true,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.nameSize or 1.0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.nameSize = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        nameOffsetX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.nameOffsetX or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.nameOffsetX = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        nameOffsetY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.nameOffsetY or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.nameOffsetY = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        resetNameText = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local currentLayout = info.handler.layouts[layoutName]
                                local defaults = currentLayout.defaultSettings.textSettings
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.nameAnchor = defaults.nameAnchor
                                layout.textSettings.nameSize = defaults.nameSize
                                layout.textSettings.nameOffsetX = defaults.nameOffsetX
                                layout.textSettings.nameOffsetY = defaults.nameOffsetY
                                info.handler:UpdateTextPositions(layout.textSettings, info, nil)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                    },
                },
                healthText = {
                    order = 2,
                    name = L["Text_HealthText"],
                    type = "group",
                    inline = true,
                    args = {
                        healthAnchor = {
                            order = 1,
                            name = L["Text_AnchorPoint"],
                            type = "select",
                            style = "dropdown",
                            width = 0.5,
                            values = {
                                ["LEFT"] = L["Direction_Left"],
                                ["CENTER"] = L["Direction_Center"],
                                ["RIGHT"] = L["Direction_Right"],
                            },
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.healthAnchor or "CENTER"
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.healthAnchor = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        healthSize = {
                            order = 2,
                            name = L["Size"],
                            type = "range",
                            min = 0.05,
                            max = 5,
                            step = 0.01,
                            width = 0.8,
                            isPercent = true,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.healthSize or 1.0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.healthSize = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        healthOffsetX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.healthOffsetX or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.healthOffsetX = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        healthOffsetY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.healthOffsetY or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.healthOffsetY = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        resetHealthText = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local currentLayout = info.handler.layouts[layoutName]
                                local defaults = currentLayout.defaultSettings.textSettings
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.healthAnchor = defaults.healthAnchor
                                layout.textSettings.healthSize = defaults.healthSize
                                layout.textSettings.healthOffsetX = defaults.healthOffsetX
                                layout.textSettings.healthOffsetY = defaults.healthOffsetY
                                info.handler:UpdateTextPositions(layout.textSettings, info, nil)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                    },
                },
                powerText = {
                    order = 2.5,
                    name = L["Text_ManaText"],
                    type = "group",
                    inline = true,
                    args = {
                        powerAnchor = {
                            order = 1,
                            name = L["Text_AnchorPoint"],
                            type = "select",
                            style = "dropdown",
                            width = 0.5,
                            values = {
                                ["LEFT"] = L["Direction_Left"],
                                ["CENTER"] = L["Direction_Center"],
                                ["RIGHT"] = L["Direction_Right"],
                            },
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.powerAnchor or "CENTER"
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.powerAnchor = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        powerSize = {
                            order = 2,
                            name = L["Size"],
                            type = "range",
                            min = 0.05,
                            max = 5,
                            step = 0.01,
                            width = 0.8,
                            isPercent = true,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.powerSize or 1.0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.powerSize = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        powerOffsetX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.powerOffsetX or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.powerOffsetX = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        powerOffsetY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.powerOffsetY or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.powerOffsetY = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        resetPowerText = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local currentLayout = info.handler.layouts[layoutName]
                                local defaults = currentLayout.defaultSettings.textSettings
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.powerAnchor = defaults.powerAnchor
                                layout.textSettings.powerSize = defaults.powerSize
                                layout.textSettings.powerOffsetX = defaults.powerOffsetX
                                layout.textSettings.powerOffsetY = defaults.powerOffsetY
                                info.handler:UpdateTextPositions(layout.textSettings, info, nil)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                    },
                },
                specNameText = {
                    order = 3,
                    name = L["Text_SpecNameText"],
                    type = "group",
                    inline = true,
                    args = {
                        specNameAnchor = {
                            order = 1,
                            name = L["Text_AnchorPoint"],
                            type = "select",
                            style = "dropdown",
                            width = 0.5,
                            values = {
                                ["LEFT"] = L["Direction_Left"],
                                ["CENTER"] = L["Direction_Center"],
                                ["RIGHT"] = L["Direction_Right"],
                            },
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.specNameAnchor or "CENTER"
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.specNameAnchor = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        specNameSize = {
                            order = 2,
                            name = L["Size"],
                            type = "range",
                            min = 0.05,
                            max = 5,
                            step = 0.01,
                            width = 0.8,
                            isPercent = true,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.specNameSize or 1.0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.specNameSize = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        specNameOffsetX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.specNameOffsetX or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.specNameOffsetX = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        specNameOffsetY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.specNameOffsetY or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.specNameOffsetY = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        resetSpecNameText = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local currentLayout = info.handler.layouts[layoutName]
                                local defaults = currentLayout.defaultSettings.textSettings
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.specNameAnchor = defaults.specNameAnchor
                                layout.textSettings.specNameSize = defaults.specNameSize
                                layout.textSettings.specNameOffsetX = defaults.specNameOffsetX
                                layout.textSettings.specNameOffsetY = defaults.specNameOffsetY
                                info.handler:UpdateTextPositions(layout.textSettings, info, nil)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                    },
                },
                petNameText = {
                    order = 3.5,
                    name = L["Category_PetFrames"] .. " - " .. L["Text_NameText"],
                    type = "group",
                    inline = true,
                    args = {
                        nameAnchor = {
                            order = 1,
                            name = L["Text_AnchorPoint"],
                            type = "select",
                            style = "dropdown",
                            width = 0.5,
                            values = {
                                ["LEFT"] = L["Direction_Left"],
                                ["CENTER"] = L["Direction_Center"],
                                ["RIGHT"] = L["Direction_Right"],
                            },
                            get = function(info)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                return lyt.petFrames.textSettings.nameAnchor or "LEFT"
                            end,
                            set = function(info, val)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                lyt.petFrames.textSettings.nameAnchor = val
                                info.handler:RefreshPetFrameSettings()
                            end,
                        },
                        nameSize = {
                            order = 2,
                            name = L["Size"],
                            type = "range",
                            min = 0.2, max = 3, softMin = 0.05, softMax = 5,
                            step = 0.01, width = 0.8, isPercent = true,
                            get = function(info)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                return lyt.petFrames.textSettings.nameSize or 1.0
                            end,
                            set = function(info, val)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                lyt.petFrames.textSettings.nameSize = val
                                info.handler:RefreshPetFrameSettings()
                            end,
                        },
                        nameOffsetX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            softMin = -200, softMax = 200, step = 0.5, width = 0.8,
                            get = function(info)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                return lyt.petFrames.textSettings.nameOffsetX or 0
                            end,
                            set = function(info, val)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                lyt.petFrames.textSettings.nameOffsetX = val
                                info.handler:RefreshPetFrameSettings()
                            end,
                        },
                        nameOffsetY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            softMin = -200, softMax = 200, step = 0.5, width = 0.8,
                            get = function(info)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                return lyt.petFrames.textSettings.nameOffsetY or 0
                            end,
                            set = function(info, val)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                lyt.petFrames.textSettings.nameOffsetY = val
                                info.handler:RefreshPetFrameSettings()
                            end,
                        },
                    },
                },
                petHealthText = {
                    order = 3.6,
                    name = L["Category_PetFrames"] .. " - " .. L["Text_HealthText"],
                    type = "group",
                    inline = true,
                    args = {
                        healthAnchor = {
                            order = 1,
                            name = L["Text_AnchorPoint"],
                            type = "select",
                            style = "dropdown",
                            width = 0.5,
                            values = {
                                ["LEFT"] = L["Direction_Left"],
                                ["CENTER"] = L["Direction_Center"],
                                ["RIGHT"] = L["Direction_Right"],
                            },
                            get = function(info)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                return lyt.petFrames.textSettings.healthAnchor or "RIGHT"
                            end,
                            set = function(info, val)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                lyt.petFrames.textSettings.healthAnchor = val
                                info.handler:RefreshPetFrameSettings()
                            end,
                        },
                        healthSize = {
                            order = 2,
                            name = L["Size"],
                            type = "range",
                            min = 0.05, max = 5, step = 0.01, width = 0.8, isPercent = true,
                            get = function(info)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                return lyt.petFrames.textSettings.healthSize or 1.0
                            end,
                            set = function(info, val)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                lyt.petFrames.textSettings.healthSize = val
                                info.handler:RefreshPetFrameSettings()
                            end,
                        },
                        healthOffsetX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            softMin = -200, softMax = 200, step = 0.5, width = 0.8,
                            get = function(info)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                return lyt.petFrames.textSettings.healthOffsetX or 0
                            end,
                            set = function(info, val)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                lyt.petFrames.textSettings.healthOffsetX = val
                                info.handler:RefreshPetFrameSettings()
                            end,
                        },
                        healthOffsetY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            softMin = -200, softMax = 200, step = 0.5, width = 0.8,
                            get = function(info)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                return lyt.petFrames.textSettings.healthOffsetY or 0
                            end,
                            set = function(info, val)
                                local lyt = info.handler.db.profile.layoutSettings[layoutName]
                                lyt.petFrames = lyt.petFrames or {}
                                lyt.petFrames.textSettings = lyt.petFrames.textSettings or {}
                                lyt.petFrames.textSettings.healthOffsetY = val
                                info.handler:RefreshPetFrameSettings()
                            end,
                        },
                    },
                },
                castbarText = {
                    order = 4,
                    name = L["Text_CastbarText"],
                    type = "group",
                    inline = true,
                    args = {
                        forceCastbarTextWidth = {
                            order = 0.5,
                            type  = "toggle",
                            name  = L["Text_ForceCastbarTextWidth"],
                            desc  = L["Text_ForceCastbarTextWidth_Desc"],
                            width = "full",
                            get   = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.forceCastbarTextWidth or false
                            end,
                            set   = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.forceCastbarTextWidth = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        castbarAnchor = {
                            order = 1,
                            name = L["Text_AnchorPoint"],
                            type = "select",
                            style = "dropdown",
                            width = 0.5,
                            values = {
                                ["LEFT"] = L["Direction_Left"],
                                ["CENTER"] = L["Direction_Center"],
                                ["RIGHT"] = L["Direction_Right"],
                            },
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarAnchor or "CENTER"
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarAnchor = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        castbarSize = {
                            order = 2,
                            name = L["Size"],
                            type = "range",
                            min = 0.05,
                            max = 5,
                            step = 0.01,
                            width = 0.8,
                            isPercent = true,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarSize or 1.0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarSize = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        castbarOffsetX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarOffsetX or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarOffsetX = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        castbarOffsetY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarOffsetY or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarOffsetY = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        resetCastbarText = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local currentLayout = info.handler.layouts[layoutName]
                                local defaults = currentLayout.defaultSettings.textSettings
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarAnchor = defaults.castbarAnchor
                                layout.textSettings.castbarSize = defaults.castbarSize
                                layout.textSettings.castbarOffsetX = defaults.castbarOffsetX
                                layout.textSettings.castbarOffsetY = defaults.castbarOffsetY
                                info.handler:UpdateTextPositions(layout.textSettings, info, nil)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                    },
                },
                castbarIDText = {
                    order = 4.5,
                    name = L["Text_CastbarIDText"],
                    type = "group",
                    inline = true,
                    disabled = function(info)
                        return not info.handler.db.profile.showCastbarID
                    end,
                    args = {
                        castbarIDAnchor = {
                            order = 1,
                            name = L["Text_AnchorPoint"],
                            type = "select",
                            style = "dropdown",
                            width = 0.5,
                            values = {
                                ["LEFT"] = L["Direction_Left"],
                                ["CENTER"] = L["Direction_Center"],
                                ["RIGHT"] = L["Direction_Right"],
                            },
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarIDAnchor or "LEFT"
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarIDAnchor = val
                                info.handler:CreateCastbarIDText()
                                info.handler:UpdateCastbarIDText()
                            end,
                        },
                        castbarIDSize = {
                            order = 2,
                            name = L["Size"],
                            type = "range",
                            min = 0.05,
                            max = 5,
                            step = 0.01,
                            width = 0.8,
                            isPercent = true,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarIDSize or 1.0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarIDSize = val
                                info.handler:CreateCastbarIDText()
                                info.handler:UpdateCastbarIDText()
                            end,
                        },
                        castbarIDOffsetX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarIDOffsetX or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarIDOffsetX = val
                                info.handler:CreateCastbarIDText()
                                info.handler:UpdateCastbarIDText()
                            end,
                        },
                        castbarIDOffsetY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarIDOffsetY or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarIDOffsetY = val
                                info.handler:CreateCastbarIDText()
                                info.handler:UpdateCastbarIDText()
                            end,
                        },
                        resetCastbarIDText = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarIDAnchor = "LEFT"
                                layout.textSettings.castbarIDSize = 1.0
                                layout.textSettings.castbarIDOffsetX = 0
                                layout.textSettings.castbarIDOffsetY = 0
                                info.handler:CreateCastbarIDText()
                                info.handler:UpdateCastbarIDText()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                    },
                },
                castbarTargetText = {
                    order = 4.6,
                    name = L["Text_CastbarTargetText"],
                    type = "group",
                    inline = true,
                    disabled = function(info)
                        return not info.handler.db.profile.showCastbarTarget
                    end,
                    args = {
                        castbarTargetAnchorInside = {
                            order = 0,
                            name = L["Castbar_AnchorTargetInside"],
                            type = "toggle",
                            width = 1.2,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarTargetAnchorInside
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarTargetAnchorInside = val
                                info.handler:CreateCastbarHighlight()
                                info.handler:CreateCastbarTargetText()
                                info.handler:UpdateCastbarTargetText()
                                info.handler:RefreshTestModeCastbars()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        forceCastbarTextWidth = {
                            order = 0.1,
                            type  = "toggle",
                            name  = L["Text_ForceCastbarTextWidth"],
                            desc  = L["Text_ForceCastbarTextWidth_Desc"],
                            width = 1.2,
                            hidden = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return not (layout.textSettings and layout.textSettings.castbarTargetAnchorInside)
                            end,
                            get   = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.forceCastbarTextWidth or false
                            end,
                            set   = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.forceCastbarTextWidth = val
                                info.handler:UpdateTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        castbarTargetAnchorToCastbar = {
                            order = 0.5,
                            name = L["Castbar_AnchorToCastbar"],
                            type = "toggle",
                            width = "full",
                            disabled = function(info)
                                if not info.handler.db.profile.showCastbarTarget then return true end
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return layout.textSettings and layout.textSettings.castbarTargetAnchorInside
                            end,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                local val = layout.textSettings.castbarTargetAnchorToCastbar
                                if val == nil then return true end
                                return val
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarTargetAnchorToCastbar = val
                                info.handler:CreateCastbarHighlight()
                                info.handler:CreateCastbarTargetText()
                                info.handler:UpdateCastbarTargetText()
                                info.handler:RefreshTestModeCastbars()
                            end,
                        },
                        castbarTargetAnchor = {
                            order = 1,
                            name = L["Text_AnchorPoint"],
                            type = "select",
                            style = "dropdown",
                            width = 0.5,
                            disabled = function(info)
                                if not info.handler.db.profile.showCastbarTarget then return true end
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return layout.textSettings and layout.textSettings.castbarTargetAnchorInside
                            end,
                            values = {
                                ["LEFT"] = L["Direction_Left"],
                                ["TOP"] = L["Direction_Top"],
                                ["BOTTOM"] = L["Direction_Bottom"],
                                ["RIGHT"] = L["Direction_Right"],
                            },
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarTargetAnchor or "BOTTOM"
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarTargetAnchor = val
                                info.handler:CreateCastbarHighlight()
                                info.handler:CreateCastbarTargetText()
                                info.handler:UpdateCastbarTargetText()
                                info.handler:RefreshTestModeCastbars()
                            end,
                        },
                        castbarTargetSize = {
                            order = 2,
                            name = L["Size"],
                            type = "range",
                            min = 0.05,
                            max = 5,
                            step = 0.01,
                            width = 0.8,
                            isPercent = true,
                            disabled = function(info)
                                if not info.handler.db.profile.showCastbarTarget then return true end
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return layout.textSettings and layout.textSettings.castbarTargetAnchorInside
                            end,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarTargetSize or 1.0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarTargetSize = val
                                info.handler:CreateCastbarHighlight()
                                info.handler:CreateCastbarTargetText()
                                info.handler:UpdateCastbarTargetText()
                                info.handler:RefreshTestModeCastbars()
                            end,
                        },
                        castbarTargetOffsetX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            disabled = function(info)
                                if not info.handler.db.profile.showCastbarTarget then return true end
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return layout.textSettings and layout.textSettings.castbarTargetAnchorInside
                            end,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarTargetOffsetX or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarTargetOffsetX = val
                                info.handler:CreateCastbarHighlight()
                                info.handler:CreateCastbarTargetText()
                                info.handler:UpdateCastbarTargetText()
                                info.handler:RefreshTestModeCastbars()
                            end,
                        },
                        castbarTargetOffsetY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            softMin = -200,
                            softMax = 200,
                            step = 0.5,
                            width = 0.8,
                            disabled = function(info)
                                if not info.handler.db.profile.showCastbarTarget then return true end
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return layout.textSettings and layout.textSettings.castbarTargetAnchorInside
                            end,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarTargetOffsetY or 0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarTargetOffsetY = val
                                info.handler:CreateCastbarHighlight()
                                info.handler:CreateCastbarTargetText()
                                info.handler:UpdateCastbarTargetText()
                                info.handler:RefreshTestModeCastbars()
                            end,
                        },
                        resetCastbarTargetText = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            disabled = function(info)
                                if not info.handler.db.profile.showCastbarTarget then return true end
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return layout.textSettings and layout.textSettings.castbarTargetAnchorInside
                            end,
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarTargetAnchor = "BOTTOM"
                                layout.textSettings.castbarTargetSize = 1.0
                                layout.textSettings.castbarTargetOffsetX = 0
                                layout.textSettings.castbarTargetOffsetY = 0
                                layout.textSettings.castbarTargetAnchorToCastbar = true
                                layout.textSettings.castbarTargetJustifyH = "CENTER"
                                info.handler:CreateCastbarHighlight()
                                info.handler:CreateCastbarTargetText()
                                info.handler:UpdateCastbarTargetText()
                                info.handler:RefreshTestModeCastbars()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        castbarTargetJustifyH = {
                            order = 6,
                            name = L["Text_TextAlignment"],
                            type = "select",
                            style = "dropdown",
                            width = 0.6,
                            disabled = function(info)
                                if not info.handler.db.profile.showCastbarTarget then return true end
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                return layout.textSettings and layout.textSettings.castbarTargetAnchorInside
                            end,
                            values = {
                                ["LEFT"] = L["Direction_Left"],
                                ["CENTER"] = L["Direction_Center"],
                                ["RIGHT"] = L["Direction_Right"],
                            },
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.castbarTargetJustifyH or "CENTER"
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.castbarTargetJustifyH = val
                                info.handler:CreateCastbarHighlight()
                                info.handler:CreateCastbarTargetText()
                                info.handler:UpdateCastbarTargetText()
                                info.handler:RefreshTestModeCastbars()
                            end,
                        },
                    },
                },
                drText = {
                    order = 5,
                    name = L["Text_DRText"],
                    type = "group",
                    inline = true,
                    args = {
                        drTextAnchor = {
                            order = 1,
                            name = L["Text_AnchorPoint"],
                            type = "select",
                            style = "dropdown",
                            width = 0.5,
                            values = {
                                ["TOPLEFT"] = L["Direction_TopLeft"],
                                ["TOP"] = L["Direction_Top"],
                                ["TOPRIGHT"] = L["Direction_TopRight"],
                                ["LEFT"] = L["Direction_Left"],
                                ["CENTER"] = L["Direction_Center"],
                                ["RIGHT"] = L["Direction_Right"],
                                ["BOTTOMLEFT"] = L["Direction_BottomLeft"],
                                ["BOTTOM"] = L["Direction_Bottom"],
                                ["BOTTOMRIGHT"] = L["Direction_BottomRight"],
                            },
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.drTextAnchor or "BOTTOMRIGHT"
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.drTextAnchor = val
                                info.handler:UpdateDRTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        drTextSize = {
                            order = 2,
                            name = L["Scale"],
                            type = "range",
                            min = 0.5,
                            max = 3,
                            step = 0.01,
                            width = 0.8,
                            isPercent = true,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.drTextSize or 1.0
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.drTextSize = val
                                info.handler:UpdateDRTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        drTextOffsetX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            softMin = -50,
                            softMax = 50,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.drTextOffsetX or 4
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.drTextOffsetX = val
                                info.handler:UpdateDRTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        drTextOffsetY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            softMin = -50,
                            softMax = 50,
                            step = 0.5,
                            width = 0.8,
                            get = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                return layout.textSettings.drTextOffsetY or -4
                            end,
                            set = function(info, val)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.drTextOffsetY = val
                                info.handler:UpdateDRTextPositions(layout.textSettings, info, val)
                            end,
                        },
                        resetDRText = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local currentLayout = info.handler.layouts[layoutName]
                                local defaults = currentLayout.defaultSettings.textSettings
                                layout.textSettings = layout.textSettings or {}
                                layout.textSettings.drTextAnchor = defaults.drTextAnchor or "BOTTOMRIGHT"
                                layout.textSettings.drTextSize = defaults.drTextSize or 1.0
                                layout.textSettings.drTextOffsetX = defaults.drTextOffsetX or 4
                                layout.textSettings.drTextOffsetY = defaults.drTextOffsetY or -4
                                info.handler:UpdateDRTextPositions(layout.textSettings, info, nil)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                    },
                },
            },
        },
        trinket = {
            order = 8,
            name = L["Category_Trinkets"],
            type = "group",
            get = function(info) return info.handler.db.profile.layoutSettings[layoutName].trinket[info[#info]] end,
            set = function(info, val)
                self:UpdateTrinketSettings(
                    info.handler.db.profile.layoutSettings[layoutName].trinket, info, val)
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
                            softMax = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                        },
                        fontSize = {
                            order = 3,
                            name = L["Option_FontSize"],
                            desc = L["Option_FontSize_Desc"],
                            type = "range",
                            min = 2,
                            max = 48,
                            softMin = 4,
                            softMax = 32,
                            step = 1,
                        },
                    },
                },
            },
        },
        widgets = {
            order = 9,
            name = L["Category_Widgets"],
            type = "group",
            get = function(info)
                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                local widgetType = info[#info - 1]
                local setting = info[#info]

                if widgets and widgets[widgetType] then
                    return widgets[widgetType][setting]
                end
                return nil
            end,
            set = function(info, val)
                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                widgets = widgets or {}
                local widgetType = info[#info - 1]
                widgets[widgetType] = widgets[widgetType] or {}
                widgets[widgetType][info[#info]] = val

                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                self:UpdateWidgetSettings(widgets, info, val)
            end,
            args = {
                combatIndicator = {
                    order = 1,
                    name = L["Widget_CombatIndicator"] .. " |A:Food:23:23|a",
                    type = "group",
                    inline = true,
                    args = {
                        enabled = {
                            order = 1,
                            name = L["Widget_CombatIndicator_Enable"],
                            desc = L["Widget_CombatIndicator_Desc"],
                            type = "toggle",
                            width = "full",
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.combatIndicator = widgets.combatIndicator or {}
                                widgets.combatIndicator.enabled = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                        },
                        scale = {
                            order = 2,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.combatIndicator and widgets.combatIndicator.enabled)
                            end,
                        },
                        posX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            min = -500,
                            max = 500,
                            step = 0.1,
                            bigStep = 1,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.combatIndicator and widgets.combatIndicator.enabled)
                            end,
                        },
                        posY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            min = -500,
                            max = 500,
                            step = 0.1,
                            bigStep = 1,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.combatIndicator and widgets.combatIndicator.enabled)
                            end,
                        },
                        resetCombatIndicator = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local currentLayout = info.handler.layouts[layoutName]
                                local defaults = currentLayout.defaultSettings.widgets
                                layout.widgets = layout.widgets or {}
                                local currentEnabled = layout.widgets.combatIndicator and layout.widgets.combatIndicator.enabled
                                layout.widgets.combatIndicator = {
                                    enabled = currentEnabled,
                                    scale = defaults.combatIndicator.scale,
                                    posX = defaults.combatIndicator.posX,
                                    posY = defaults.combatIndicator.posY,
                                }
                                self:UpdateWidgetSettings(layout.widgets, info, nil)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        showOutOfCombat = {
                            order = 6,
                            name = L["Widget_CombatIndicator_ShowOutOfCombat"],
                            type = "toggle",
                            width = "full",
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                local ci = widgets and widgets.combatIndicator
                                return ci == nil or ci.showOutOfCombat ~= false
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.combatIndicator = widgets.combatIndicator or {}
                                widgets.combatIndicator.showOutOfCombat = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.combatIndicator and widgets.combatIndicator.enabled)
                            end,
                        },
                        showInCombat = {
                            order = 7,
                            name = L["Widget_CombatIndicator_ShowInCombat"],
                            type = "toggle",
                            width = "full",
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.combatIndicator = widgets.combatIndicator or {}
                                widgets.combatIndicator.showInCombat = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.combatIndicator and widgets.combatIndicator.enabled)
                            end,
                        },
                        useSapIcon = {
                            order = 8,
                            name = L["Widget_CombatIndicator_UseSapIcon"],
                            desc = L["Widget_CombatIndicator_UseSapIcon_Desc"],
                            type = "toggle",
                            width = "full",
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.combatIndicator = widgets.combatIndicator or {}
                                widgets.combatIndicator.useSapIcon = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.combatIndicator and widgets.combatIndicator.enabled)
                            end,
                        },
                    },
                },
                healerIndicator = {
                    order = 2,
                    name = L["Widget_HealerIndicator"] .. " |A:bags-icon-addslots:20:20|a",
                    type = "group",
                    inline = true,
                    args = {
                        enabled = {
                            order = 1,
                            name = L["Widget_HealerIndicator_Enable"],
                            desc = L["Widget_HealerIndicator_Desc"],
                            type = "toggle",
                            width = "full",
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.healerIndicator = widgets.healerIndicator or {}
                                widgets.healerIndicator.enabled = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                        },
                        scale = {
                            order = 2,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.healerIndicator and widgets.healerIndicator.enabled)
                            end,
                        },
                        posX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            min = -500,
                            max = 500,
                            step = 0.1,
                            bigStep = 1,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.healerIndicator and widgets.healerIndicator.enabled)
                            end,
                        },
                        posY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            min = -500,
                            max = 500,
                            step = 0.1,
                            bigStep = 1,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.healerIndicator and widgets.healerIndicator.enabled)
                            end,
                        },
                        resetHealerIndicator = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local currentLayout = info.handler.layouts[layoutName]
                                local defaults = currentLayout.defaultSettings.widgets
                                layout.widgets = layout.widgets or {}
                                local currentEnabled = layout.widgets.healerIndicator and layout.widgets.healerIndicator.enabled
                                layout.widgets.healerIndicator = {
                                    enabled = currentEnabled,
                                    scale = defaults.healerIndicator.scale,
                                    posX = defaults.healerIndicator.posX,
                                    posY = defaults.healerIndicator.posY,
                                }
                                self:UpdateWidgetSettings(layout.widgets, info, nil)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                    },
                },
                targetIndicator = {
                    order = 3,
                    name = L["Widget_TargetIndicator"] .. " |A:TargetCrosshairs:45:45|a",
                    type = "group",
                    inline = true,
                    args = {
                        enabled = {
                            order = 1,
                            name = L["Widget_TargetIndicator_Enable"],
                            desc = L["Widget_TargetIndicator_Desc"],
                            type = "toggle",
                            width = "full",
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.targetIndicator = widgets.targetIndicator or {}
                                widgets.targetIndicator.enabled = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                        },
                        scale = {
                            order = 2,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                if not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled) then
                                    return true
                                end
                                if widgets.targetIndicator.useBorder and not widgets.targetIndicator.useBorderWithIcon then
                                    return true
                                end
                                return false
                            end,
                        },
                        posX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            min = -500,
                            max = 500,
                            step = 0.1,
                            bigStep = 1,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                if not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled) then
                                    return true
                                end
                                if widgets.targetIndicator.useBorder and not widgets.targetIndicator.useBorderWithIcon then
                                    return true
                                end
                                return false
                            end,
                        },
                        posY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            min = -500,
                            max = 500,
                            step = 0.1,
                            bigStep = 1,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                if not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled) then
                                    return true
                                end
                                if widgets.targetIndicator.useBorder and not widgets.targetIndicator.useBorderWithIcon then
                                    return true
                                end
                                return false
                            end,
                        },
                        resetTargetIndicator = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local currentLayout = info.handler.layouts[layoutName]
                                local defaults = currentLayout.defaultSettings.widgets
                                layout.widgets = layout.widgets or {}
                                local currentEnabled = layout.widgets.targetIndicator and layout.widgets.targetIndicator.enabled
                                layout.widgets.targetIndicator = {
                                    enabled = currentEnabled,
                                    scale = defaults.targetIndicator.scale,
                                    posX = defaults.targetIndicator.posX,
                                    posY = defaults.targetIndicator.posY,
                                    borderSize = defaults.targetIndicator.borderSize,
                                    borderOffset = defaults.targetIndicator.borderOffset,
                                }
                                self:UpdateWidgetSettings(layout.widgets, info, nil)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        useTargetFocusBorder = {
                            order = 6,
                            name = L["Widget_UseBorder"],
                            desc = L["Widget_UseBorder_Target_Desc"],
                            type = "toggle",
                            width = 0.6,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.targetIndicator and widgets.targetIndicator.useBorder
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.targetIndicator = widgets.targetIndicator or {}
                                widgets.targetIndicator.useBorder = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled)
                            end,
                        },
                        targetWrapClass = {
                            order = 6.1,
                            name = L["Widget_WrapClass"],
                            desc = L["Widget_WrapClass_Desc"],
                            type = "toggle",
                            width = 0.6,
                            hidden = function()
                                return layoutName ~= "Pixelated" and layoutName ~= "BlizzRaid" and layoutName ~= "Gladiuish" and layoutName ~= "Xaryu"
                            end,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.targetIndicator and widgets.targetIndicator.wrapClass
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.targetIndicator = widgets.targetIndicator or {}
                                widgets.targetIndicator.wrapClass = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled and widgets.targetIndicator.useBorder)
                            end,
                        },
                        targetWrapTrinket = {
                            order = 6.2,
                            name = L["Widget_WrapTrinket"],
                            desc = L["Widget_WrapTrinket_Desc"],
                            type = "toggle",
                            width = 0.6,
                            hidden = function()
                                return layoutName ~= "Pixelated" and layoutName ~= "BlizzRaid" and layoutName ~= "Gladiuish" and layoutName ~= "Xaryu"
                            end,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.targetIndicator and widgets.targetIndicator.wrapTrinket
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.targetIndicator = widgets.targetIndicator or {}
                                widgets.targetIndicator.wrapTrinket = val
                                if val then widgets.targetIndicator.wrapRacial = false end
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled and widgets.targetIndicator.useBorder)
                            end,
                        },
                        targetWrapRacial = {
                            order = 6.3,
                            name = L["Widget_WrapRacial"],
                            desc = L["Widget_WrapRacial_Desc"],
                            type = "toggle",
                            width = 0.6,
                            hidden = function()
                                return layoutName ~= "Pixelated" and layoutName ~= "BlizzRaid" and layoutName ~= "Gladiuish" and layoutName ~= "Xaryu"
                            end,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.targetIndicator and widgets.targetIndicator.wrapRacial
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.targetIndicator = widgets.targetIndicator or {}
                                widgets.targetIndicator.wrapRacial = val
                                if val then widgets.targetIndicator.wrapTrinket = false end
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled and widgets.targetIndicator.useBorder)
                            end,
                        },
                        useTargetFocusBorderWithIcons = {
                            order = 7,
                            name = L["Widget_UseBorderWithIcon"],
                            desc = L["Widget_UseBorderWithIcon_Desc"],
                            type = "toggle",
                            width = "full",
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.targetIndicator and widgets.targetIndicator.useBorderWithIcon
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.targetIndicator = widgets.targetIndicator or {}
                                widgets.targetIndicator.useBorderWithIcon = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled and widgets.targetIndicator.useBorder)
                            end,
                        },
                        targetBorderColor = {
                            order = 8,
                            name = L["Widget_BorderColor"],
                            type = "color",
                            hasAlpha = true,
                            width = 0.95,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                local c = widgets and widgets.targetIndicator and widgets.targetIndicator.borderColor or {1, 0.7, 0, 1}
                                return c[1], c[2], c[3], c[4]
                            end,
                            set = function(info, r, g, b, a)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.targetIndicator = widgets.targetIndicator or {}
                                widgets.targetIndicator.borderColor = {r, g, b, a}
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, nil)
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled and widgets.targetIndicator.useBorder)
                            end,
                        },
                        targetBorderSize = {
                            order = 8.1,
                            name = L["Widget_BorderSize"],
                            type = "range",
                            softMin = 0.5,
                            softMax = 5,
                            min = 0.1,
                            max = 10,
                            step = 0.1,
                            bigStep = 0.5,
                            width = 0.95,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.targetIndicator and widgets.targetIndicator.borderSize or 1
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.targetIndicator = widgets.targetIndicator or {}
                                widgets.targetIndicator.borderSize = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled and widgets.targetIndicator.useBorder)
                            end,
                        },
                        targetBorderOffset = {
                            order = 8.2,
                            name = L["Widget_BorderOffset"],
                            type = "range",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            width = 0.95,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.targetIndicator and widgets.targetIndicator.borderOffset or 0
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.targetIndicator = widgets.targetIndicator or {}
                                widgets.targetIndicator.borderOffset = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.targetIndicator and widgets.targetIndicator.enabled and widgets.targetIndicator.useBorder)
                            end,
                        },
                    },
                },
                focusIndicator = {
                    order = 3,
                    name = L["Widget_FocusIndicator"] .. " |TInterface\\AddOns\\sArena_Reloaded\\Textures\\Waypoint-MapPin-Untracked.tga:23:23|t",
                    type = "group",
                    inline = true,
                    args = {
                        enabled = {
                            order = 1,
                            name = L["Widget_FocusIndicator_Enable"],
                            desc = L["Widget_FocusIndicator_Desc"],
                            type = "toggle",
                            width = "full",
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.focusIndicator = widgets.focusIndicator or {}
                                widgets.focusIndicator.enabled = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                        },
                        scale = {
                            order = 2,
                            name = L["Scale"],
                            type = "range",
                            min = 0.1,
                            max = 3.0,
                            step = 0.01,
                            bigStep = 0.01,
                            isPercent = true,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                if not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled) then
                                    return true
                                end
                                if widgets.focusIndicator.useBorder and not widgets.focusIndicator.useBorderWithIcon then
                                    return true
                                end
                                return false
                            end,
                        },
                        posX = {
                            order = 3,
                            name = L["Horizontal"],
                            type = "range",
                            min = -500,
                            max = 500,
                            step = 0.1,
                            bigStep = 1,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                if not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled) then
                                    return true
                                end
                                if widgets.focusIndicator.useBorder and not widgets.focusIndicator.useBorderWithIcon then
                                    return true
                                end
                                return false
                            end,
                        },
                        posY = {
                            order = 4,
                            name = L["Vertical"],
                            type = "range",
                            min = -500,
                            max = 500,
                            step = 0.1,
                            bigStep = 1,
                            width = 0.95,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                if not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled) then
                                    return true
                                end
                                if widgets.focusIndicator.useBorder and not widgets.focusIndicator.useBorderWithIcon then
                                    return true
                                end
                                return false
                            end,
                        },
                        resetFocusIndicator = {
                            order = 5,
                            name = L["Reset"],
                            width = 0.4,
                            type = "execute",
                            func = function(info)
                                local layout = info.handler.db.profile.layoutSettings[layoutName]
                                local currentLayout = info.handler.layouts[layoutName]
                                local defaults = currentLayout.defaultSettings.widgets
                                layout.widgets = layout.widgets or {}
                                local currentEnabled = layout.widgets.focusIndicator and layout.widgets.focusIndicator.enabled
                                layout.widgets.focusIndicator = {
                                    enabled = currentEnabled,
                                    scale = defaults.focusIndicator.scale,
                                    posX = defaults.focusIndicator.posX,
                                    posY = defaults.focusIndicator.posY,
                                    borderSize = defaults.focusIndicator.borderSize,
                                    borderOffset = defaults.focusIndicator.borderOffset,
                                }
                                self:UpdateWidgetSettings(layout.widgets, info, nil)
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                            end,
                        },
                        useFocusBorder = {
                            order = 6,
                            name = L["Widget_UseBorder"],
                            desc = L["Widget_UseBorder_Focus_Desc"],
                            type = "toggle",
                            width = 0.6,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.focusIndicator and widgets.focusIndicator.useBorder
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.focusIndicator = widgets.focusIndicator or {}
                                widgets.focusIndicator.useBorder = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled)
                            end,
                        },
                        focusWrapClass = {
                            order = 6.1,
                            name = L["Widget_WrapClass"],
                            desc = L["Widget_WrapClass_Desc"],
                            type = "toggle",
                            width = 0.6,
                            hidden = function()
                                return layoutName ~= "Pixelated" and layoutName ~= "BlizzRaid" and layoutName ~= "Gladiuish" and layoutName ~= "Xaryu"
                            end,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.focusIndicator and widgets.focusIndicator.wrapClass
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.focusIndicator = widgets.focusIndicator or {}
                                widgets.focusIndicator.wrapClass = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled and widgets.focusIndicator.useBorder)
                            end,
                        },
                        focusWrapTrinket = {
                            order = 6.2,
                            name = L["Widget_WrapTrinket"],
                            desc = L["Widget_WrapTrinket_Desc"],
                            type = "toggle",
                            width = 0.6,
                            hidden = function()
                                return layoutName ~= "Pixelated" and layoutName ~= "BlizzRaid" and layoutName ~= "Gladiuish" and layoutName ~= "Xaryu"
                            end,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.focusIndicator and widgets.focusIndicator.wrapTrinket
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.focusIndicator = widgets.focusIndicator or {}
                                widgets.focusIndicator.wrapTrinket = val
                                if val then widgets.focusIndicator.wrapRacial = false end
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled and widgets.focusIndicator.useBorder)
                            end,
                        },
                        focusWrapRacial = {
                            order = 6.3,
                            name = L["Widget_WrapRacial"],
                            desc = L["Widget_WrapRacial_Desc"],
                            type = "toggle",
                            width = 0.6,
                            hidden = function()
                                return layoutName ~= "Pixelated" and layoutName ~= "BlizzRaid" and layoutName ~= "Gladiuish" and layoutName ~= "Xaryu"
                            end,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.focusIndicator and widgets.focusIndicator.wrapRacial
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.focusIndicator = widgets.focusIndicator or {}
                                widgets.focusIndicator.wrapRacial = val
                                if val then widgets.focusIndicator.wrapTrinket = false end
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled and widgets.focusIndicator.useBorder)
                            end,
                        },
                        useFocusBorderWithIcon = {
                            order = 7,
                            name = L["Widget_UseBorderWithIcon"],
                            desc = L["Widget_UseBorderWithIcon_Desc"],
                            type = "toggle",
                            width = "full",
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.focusIndicator and widgets.focusIndicator.useBorderWithIcon
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.focusIndicator = widgets.focusIndicator or {}
                                widgets.focusIndicator.useBorderWithIcon = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled and widgets.focusIndicator.useBorder)
                            end,
                        },
                        focusBorderColor = {
                            order = 8,
                            name = L["Widget_BorderColor"],
                            type = "color",
                            hasAlpha = true,
                            width = 0.95,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                local c = widgets and widgets.focusIndicator and widgets.focusIndicator.borderColor or {0, 0, 1, 1}
                                return c[1], c[2], c[3], c[4]
                            end,
                            set = function(info, r, g, b, a)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.focusIndicator = widgets.focusIndicator or {}
                                widgets.focusIndicator.borderColor = {r, g, b, a}
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, nil)
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled and widgets.focusIndicator.useBorder)
                            end,
                        },
                        focusBorderSize = {
                            order = 8.1,
                            name = L["Widget_BorderSize"],
                            type = "range",
                            softMin = 0.5,
                            softMax = 5,
                            min = 0.1,
                            max = 10,
                            step = 0.1,
                            bigStep = 0.5,
                            width = 0.95,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.focusIndicator and widgets.focusIndicator.borderSize or 1
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.focusIndicator = widgets.focusIndicator or {}
                                widgets.focusIndicator.borderSize = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled and widgets.focusIndicator.useBorder)
                            end,
                        },
                        focusBorderOffset = {
                            order = 8.2,
                            name = L["Widget_BorderOffset"],
                            type = "range",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            width = 0.95,
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return widgets and widgets.focusIndicator and widgets.focusIndicator.borderOffset or 0
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.focusIndicator = widgets.focusIndicator or {}
                                widgets.focusIndicator.borderOffset = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                            end,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                return not (widgets and widgets.focusIndicator and widgets.focusIndicator.enabled and widgets.focusIndicator.useBorder)
                            end,
                        },
                    },
                },
                partyTargetIndicators = {
                    order = 4,
                    name = L["Widget_ArenaTargetIndicators"] .. " |TInterface\\AddOns\\sArena_Reloaded\\Textures\\GM-icon-headCount.tga:19:19|t",
                    type = "group",
                    inline = true,
                    args = {
                        enabled = {
                            order = 0,
                            name = L["Widget_ArenaTargetIndicators_Enable"],
                            desc = L["Widget_ArenaTargetIndicators_Desc"],
                            type = "toggle",
                            width = "full",
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                local pti = widgets and widgets.partyTargetIndicators
                                return pti and pti.enabled
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                widgets.partyTargetIndicators.enabled = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                        },
                        partyOnArena = {
                            order = 1,
                            name = L["Widget_PartyOnArena"],
                            type = "group",
                            inline = true,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                local pti = widgets and widgets.partyTargetIndicators
                                return not (pti and pti.enabled)
                            end,
                            args = {
                                enabled = {
                                    order = 1,
                                    name = L["Widget_PartyTargetsOnArena_Enable"],
                                    desc = L["Widget_PartyTargetsOnArena_Desc"],
                                    type = "toggle",
                                    width = "full",
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.partyOnArena
                                        return poa and poa.enabled
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.partyOnArena = widgets.partyTargetIndicators.partyOnArena or {}
                                        widgets.partyTargetIndicators.partyOnArena.enabled = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                        info.handler:Test()
                                    end,
                                },
                                direction = {
                                    order = 2,
                                    name = L["Option_GrowthDirection"],
                                    type = "select",
                                    values = { LEFT = L["Direction_Left"], RIGHT = L["Direction_Right"], UP = L["Direction_Up"], DOWN = L["Direction_Down"] },
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.partyOnArena
                                        return poa and poa.direction or "LEFT"
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.partyOnArena = widgets.partyTargetIndicators.partyOnArena or {}
                                        widgets.partyTargetIndicators.partyOnArena.direction = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local pti = widgets and widgets.partyTargetIndicators
                                        local poa = pti and pti.partyOnArena
                                        return not (pti and pti.enabled and poa and poa.enabled)
                                    end,
                                },
                                scale = {
                                    order = 3,
                                    name = L["Scale"],
                                    type = "range",
                                    min = 0.5, max = 3.0, step = 0.01, bigStep = 0.01, isPercent = true,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.partyOnArena
                                        return poa and poa.scale or 1
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.partyOnArena = widgets.partyTargetIndicators.partyOnArena or {}
                                        widgets.partyTargetIndicators.partyOnArena.scale = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local pti = widgets and widgets.partyTargetIndicators
                                        local poa = pti and pti.partyOnArena
                                        return not (pti and pti.enabled and poa and poa.enabled)
                                    end,
                                },
                                posX = {
                                    order = 4,
                                    name = L["Horizontal"],
                                    type = "range",
                                    min = -200, max = 200, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.partyOnArena
                                        return poa and poa.posX or 0
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.partyOnArena = widgets.partyTargetIndicators.partyOnArena or {}
                                        widgets.partyTargetIndicators.partyOnArena.posX = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local pti = widgets and widgets.partyTargetIndicators
                                        local poa = pti and pti.partyOnArena
                                        return not (pti and pti.enabled and poa and poa.enabled)
                                    end,
                                },
                                posY = {
                                    order = 5,
                                    name = L["Vertical"],
                                    type = "range",
                                    min = -200, max = 200, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.partyOnArena
                                        return poa and poa.posY or 0
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.partyOnArena = widgets.partyTargetIndicators.partyOnArena or {}
                                        widgets.partyTargetIndicators.partyOnArena.posY = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local pti = widgets and widgets.partyTargetIndicators
                                        local poa = pti and pti.partyOnArena
                                        return not (pti and pti.enabled and poa and poa.enabled)
                                    end,
                                },
                                spacing = {
                                    order = 6,
                                    name = L["Widget_Spacing"],
                                    type = "range",
                                    min = -15, max = 15, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.partyOnArena
                                        return poa and poa.spacing or 3
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.partyOnArena = widgets.partyTargetIndicators.partyOnArena or {}
                                        widgets.partyTargetIndicators.partyOnArena.spacing = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local pti = widgets and widgets.partyTargetIndicators
                                        local poa = pti and pti.partyOnArena
                                        return not (pti and pti.enabled and poa and poa.enabled)
                                    end,
                                },
                                resetPartyOnArena = {
                                    order = 7,
                                    name = L["Reset"],
                                    width = 0.4,
                                    type = "execute",
                                    func = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        local currentLayout = info.handler.layouts[layoutName]
                                        local defaults = currentLayout.defaultSettings.widgets.partyTargetIndicators.partyOnArena
                                        layout.widgets = layout.widgets or {}
                                        layout.widgets.partyTargetIndicators = layout.widgets.partyTargetIndicators or {}
                                        local poa = layout.widgets.partyTargetIndicators.partyOnArena or {}
                                        layout.widgets.partyTargetIndicators.partyOnArena = {
                                            enabled = poa.enabled,
                                            direction = defaults.direction,
                                            scale = defaults.scale,
                                            posX = defaults.posX,
                                            posY = defaults.posY,
                                            spacing = defaults.spacing,
                                        }
                                        self:UpdateWidgetSettings(layout.widgets, info, nil)
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                    end,
                                },
                            },
                        },
                        arenaOnParty = {
                            order = 2,
                            name = L["Widget_ArenaOnParty"],
                            type = "group",
                            inline = true,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                local pti = widgets and widgets.partyTargetIndicators
                                return not (pti and pti.enabled)
                            end,
                            args = {
                                enabled = {
                                    order = 1,
                                    name = L["Widget_ArenaTargetsOnParty_Enable"],
                                    desc = L["Widget_ArenaTargetsOnParty_Desc"],
                                    type = "toggle",
                                    width = "full",
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.arenaOnParty
                                        return aop and aop.enabled
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.arenaOnParty = widgets.partyTargetIndicators.arenaOnParty or {}
                                        widgets.partyTargetIndicators.arenaOnParty.enabled = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                        info.handler:Test()
                                    end,
                                },
                                direction = {
                                    order = 2,
                                    name = L["Option_GrowthDirection"],
                                    type = "select",
                                    values = { LEFT = L["Direction_Left"], RIGHT = L["Direction_Right"], UP = L["Direction_Up"], DOWN = L["Direction_Down"] },
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.arenaOnParty
                                        return aop and aop.direction or "LEFT"
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.arenaOnParty = widgets.partyTargetIndicators.arenaOnParty or {}
                                        widgets.partyTargetIndicators.arenaOnParty.direction = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local pti = widgets and widgets.partyTargetIndicators
                                        local aop = pti and pti.arenaOnParty
                                        return not (pti and pti.enabled and aop and aop.enabled)
                                    end,
                                },
                                scale = {
                                    order = 3,
                                    name = L["Scale"],
                                    type = "range",
                                    min = 0.5, max = 3.0, step = 0.01, bigStep = 0.01, isPercent = true,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.arenaOnParty
                                        return aop and aop.scale or 1
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.arenaOnParty = widgets.partyTargetIndicators.arenaOnParty or {}
                                        widgets.partyTargetIndicators.arenaOnParty.scale = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local pti = widgets and widgets.partyTargetIndicators
                                        local aop = pti and pti.arenaOnParty
                                        return not (pti and pti.enabled and aop and aop.enabled)
                                    end,
                                },
                                posX = {
                                    order = 4,
                                    name = L["Horizontal"],
                                    type = "range",
                                    min = -200, max = 200, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.arenaOnParty
                                        return aop and aop.posX or 0
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.arenaOnParty = widgets.partyTargetIndicators.arenaOnParty or {}
                                        widgets.partyTargetIndicators.arenaOnParty.posX = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local pti = widgets and widgets.partyTargetIndicators
                                        local aop = pti and pti.arenaOnParty
                                        return not (pti and pti.enabled and aop and aop.enabled)
                                    end,
                                },
                                posY = {
                                    order = 5,
                                    name = L["Vertical"],
                                    type = "range",
                                    min = -200, max = 200, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.arenaOnParty
                                        return aop and aop.posY or 0
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.arenaOnParty = widgets.partyTargetIndicators.arenaOnParty or {}
                                        widgets.partyTargetIndicators.arenaOnParty.posY = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local pti = widgets and widgets.partyTargetIndicators
                                        local aop = pti and pti.arenaOnParty
                                        return not (pti and pti.enabled and aop and aop.enabled)
                                    end,
                                },
                                spacing = {
                                    order = 6,
                                    name = L["Widget_Spacing"],
                                    type = "range",
                                    min = -15, max = 15, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetIndicators and widgets.partyTargetIndicators.arenaOnParty
                                        return aop and aop.spacing or 1
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetIndicators = widgets.partyTargetIndicators or {}
                                        widgets.partyTargetIndicators.arenaOnParty = widgets.partyTargetIndicators.arenaOnParty or {}
                                        widgets.partyTargetIndicators.arenaOnParty.spacing = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local pti = widgets and widgets.partyTargetIndicators
                                        local aop = pti and pti.arenaOnParty
                                        return not (pti and pti.enabled and aop and aop.enabled)
                                    end,
                                },
                                resetArenaOnParty = {
                                    order = 7,
                                    name = L["Reset"],
                                    width = 0.4,
                                    type = "execute",
                                    func = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        local currentLayout = info.handler.layouts[layoutName]
                                        local defaults = currentLayout.defaultSettings.widgets.partyTargetIndicators.arenaOnParty
                                        layout.widgets = layout.widgets or {}
                                        layout.widgets.partyTargetIndicators = layout.widgets.partyTargetIndicators or {}
                                        local aop = layout.widgets.partyTargetIndicators.arenaOnParty or {}
                                        layout.widgets.partyTargetIndicators.arenaOnParty = {
                                            enabled = aop.enabled,
                                            direction = defaults.direction,
                                            scale = defaults.scale,
                                            posX = defaults.posX,
                                            posY = defaults.posY,
                                            spacing = defaults.spacing,
                                        }
                                        self:UpdateWidgetSettings(layout.widgets, info, nil)
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                    end,
                                },
                            },
                        },
                    },
                },
                partyTargetText = {
                    order = 5,
                    name = L["Widget_ArenaTargetText"] .. " |A:AnimCreate_Icon_Text:20:20|a",
                    type = "group",
                    inline = true,
                    args = {
                        enabled = {
                            order = 0,
                            name = L["Widget_ArenaTargetText_Enable"],
                            desc = L["Widget_ArenaTargetText_Desc"],
                            type = "toggle",
                            width = "full",
                            get = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                local ptt = widgets and widgets.partyTargetText
                                return ptt and ptt.enabled
                            end,
                            set = function(info, val)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                widgets = widgets or {}
                                widgets.partyTargetText = widgets.partyTargetText or {}
                                widgets.partyTargetText.enabled = val
                                info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                self:UpdateWidgetSettings(widgets, info, val)
                                info.handler:Test()
                            end,
                        },
                        partyOnArena = {
                            order = 1,
                            name = L["Widget_PartyTextOnArena"],
                            type = "group",
                            inline = true,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                local ptt = widgets and widgets.partyTargetText
                                return not (ptt and ptt.enabled)
                            end,
                            args = {
                                enabled = {
                                    order = 1,
                                    name = L["Widget_PartyTargetsTextOnArena_Enable"],
                                    desc = L["Widget_PartyTargetsTextOnArena_Desc"],
                                    type = "toggle",
                                    width = "full",
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetText and widgets.partyTargetText.partyOnArena
                                        return poa and poa.enabled
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.partyOnArena = widgets.partyTargetText.partyOnArena or {}
                                        widgets.partyTargetText.partyOnArena.enabled = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                        info.handler:Test()
                                    end,
                                },
                                anchor = {
                                    order = 2,
                                    name = L["Anchor"],
                                    type = "select",
                                    values = {
                                        LEFT = "Left", CENTER = "Center", RIGHT = "Right",
                                    },
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetText and widgets.partyTargetText.partyOnArena
                                        return poa and poa.anchor or "RIGHT"
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.partyOnArena = widgets.partyTargetText.partyOnArena or {}
                                        widgets.partyTargetText.partyOnArena.anchor = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local ptt = widgets and widgets.partyTargetText
                                        local poa = ptt and ptt.partyOnArena
                                        return not (ptt and ptt.enabled and poa and poa.enabled)
                                    end,
                                },
                                fontSize = {
                                    order = 3,
                                    name = L["Option_FontSize"],
                                    type = "range",
                                    min = 6, max = 24, step = 0.5, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetText and widgets.partyTargetText.partyOnArena
                                        return poa and poa.fontSize or 10
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.partyOnArena = widgets.partyTargetText.partyOnArena or {}
                                        widgets.partyTargetText.partyOnArena.fontSize = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local ptt = widgets and widgets.partyTargetText
                                        local poa = ptt and ptt.partyOnArena
                                        return not (ptt and ptt.enabled and poa and poa.enabled)
                                    end,
                                },
                                posX = {
                                    order = 4,
                                    name = L["Horizontal"],
                                    type = "range",
                                    min = -200, max = 200, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetText and widgets.partyTargetText.partyOnArena
                                        return poa and poa.posX or 0
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.partyOnArena = widgets.partyTargetText.partyOnArena or {}
                                        widgets.partyTargetText.partyOnArena.posX = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local ptt = widgets and widgets.partyTargetText
                                        local poa = ptt and ptt.partyOnArena
                                        return not (ptt and ptt.enabled and poa and poa.enabled)
                                    end,
                                },
                                posY = {
                                    order = 5,
                                    name = L["Vertical"],
                                    type = "range",
                                    min = -200, max = 200, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local poa = widgets and widgets.partyTargetText and widgets.partyTargetText.partyOnArena
                                        return poa and poa.posY or 0
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.partyOnArena = widgets.partyTargetText.partyOnArena or {}
                                        widgets.partyTargetText.partyOnArena.posY = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local ptt = widgets and widgets.partyTargetText
                                        local poa = ptt and ptt.partyOnArena
                                        return not (ptt and ptt.enabled and poa and poa.enabled)
                                    end,
                                },
                                resetPartyTextOnArena = {
                                    order = 6,
                                    name = L["Reset"],
                                    width = 0.4,
                                    type = "execute",
                                    func = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        local currentLayout = info.handler.layouts[layoutName]
                                        local defaults = currentLayout.defaultSettings.widgets.partyTargetText.partyOnArena
                                        layout.widgets = layout.widgets or {}
                                        layout.widgets.partyTargetText = layout.widgets.partyTargetText or {}
                                        local poa = layout.widgets.partyTargetText.partyOnArena or {}
                                        layout.widgets.partyTargetText.partyOnArena = {
                                            enabled = poa.enabled,
                                            anchor = defaults.anchor,
                                            fontSize = defaults.fontSize,
                                            posX = defaults.posX,
                                            posY = defaults.posY,
                                        }
                                        self:UpdateWidgetSettings(layout.widgets, info, nil)
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                    end,
                                },
                            },
                        },
                        arenaOnParty = {
                            order = 2,
                            name = L["Widget_ArenaTextOnParty"],
                            type = "group",
                            inline = true,
                            disabled = function(info)
                                local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                local ptt = widgets and widgets.partyTargetText
                                return not (ptt and ptt.enabled)
                            end,
                            args = {
                                enabled = {
                                    order = 1,
                                    name = L["Widget_ArenaTargetsTextOnParty_Enable"],
                                    desc = L["Widget_ArenaTargetsTextOnParty_Desc"],
                                    type = "toggle",
                                    width = "full",
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetText and widgets.partyTargetText.arenaOnParty
                                        return aop and aop.enabled
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.arenaOnParty = widgets.partyTargetText.arenaOnParty or {}
                                        widgets.partyTargetText.arenaOnParty.enabled = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                        info.handler:Test()
                                    end,
                                },
                                alwaysOn = {
                                    order = 1.5,
                                    name = L["Widget_ArenaTextOnParty_AlwaysOn"],
                                    desc = L["Widget_ArenaTextOnParty_AlwaysOn_Desc"],
                                    type = "toggle",
                                    width = "full",
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetText and widgets.partyTargetText.arenaOnParty
                                        return aop and aop.alwaysOn or false
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.arenaOnParty = widgets.partyTargetText.arenaOnParty or {}
                                        widgets.partyTargetText.arenaOnParty.alwaysOn = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local ptt = widgets and widgets.partyTargetText
                                        local aop = ptt and ptt.arenaOnParty
                                        return not (ptt and ptt.enabled and aop and aop.enabled)
                                    end,
                                },
                                anchor = {
                                    order = 2,
                                    name = L["Anchor"],
                                    type = "select",
                                    values = {
                                        LEFT = "Left", CENTER = "Center", RIGHT = "Right",
                                    },
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetText and widgets.partyTargetText.arenaOnParty
                                        return aop and aop.anchor or "RIGHT"
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.arenaOnParty = widgets.partyTargetText.arenaOnParty or {}
                                        widgets.partyTargetText.arenaOnParty.anchor = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local ptt = widgets and widgets.partyTargetText
                                        local aop = ptt and ptt.arenaOnParty
                                        return not (ptt and ptt.enabled and aop and aop.enabled)
                                    end,
                                },
                                fontSize = {
                                    order = 3,
                                    name = L["Option_FontSize"],
                                    type = "range",
                                    min = 6, max = 24, step = 0.5, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetText and widgets.partyTargetText.arenaOnParty
                                        return aop and aop.fontSize or 10
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.arenaOnParty = widgets.partyTargetText.arenaOnParty or {}
                                        widgets.partyTargetText.arenaOnParty.fontSize = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local ptt = widgets and widgets.partyTargetText
                                        local aop = ptt and ptt.arenaOnParty
                                        return not (ptt and ptt.enabled and aop and aop.enabled)
                                    end,
                                },
                                posX = {
                                    order = 4,
                                    name = L["Horizontal"],
                                    type = "range",
                                    min = -200, max = 200, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetText and widgets.partyTargetText.arenaOnParty
                                        return aop and aop.posX or 0
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.arenaOnParty = widgets.partyTargetText.arenaOnParty or {}
                                        widgets.partyTargetText.arenaOnParty.posX = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local ptt = widgets and widgets.partyTargetText
                                        local aop = ptt and ptt.arenaOnParty
                                        return not (ptt and ptt.enabled and aop and aop.enabled)
                                    end,
                                },
                                posY = {
                                    order = 5,
                                    name = L["Vertical"],
                                    type = "range",
                                    min = -200, max = 200, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    get = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local aop = widgets and widgets.partyTargetText and widgets.partyTargetText.arenaOnParty
                                        return aop and aop.posY or 0
                                    end,
                                    set = function(info, val)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        widgets = widgets or {}
                                        widgets.partyTargetText = widgets.partyTargetText or {}
                                        widgets.partyTargetText.arenaOnParty = widgets.partyTargetText.arenaOnParty or {}
                                        widgets.partyTargetText.arenaOnParty.posY = val
                                        info.handler.db.profile.layoutSettings[layoutName].widgets = widgets
                                        self:UpdateWidgetSettings(widgets, info, val)
                                    end,
                                    disabled = function(info)
                                        local widgets = info.handler.db.profile.layoutSettings[layoutName].widgets
                                        local ptt = widgets and widgets.partyTargetText
                                        local aop = ptt and ptt.arenaOnParty
                                        return not (ptt and ptt.enabled and aop and aop.enabled)
                                    end,
                                },
                                resetArenaTextOnParty = {
                                    order = 7,
                                    name = L["Reset"],
                                    width = 0.4,
                                    type = "execute",
                                    func = function(info)
                                        local layout = info.handler.db.profile.layoutSettings[layoutName]
                                        local currentLayout = info.handler.layouts[layoutName]
                                        local defaults = currentLayout.defaultSettings.widgets.partyTargetText.arenaOnParty
                                        layout.widgets = layout.widgets or {}
                                        layout.widgets.partyTargetText = layout.widgets.partyTargetText or {}
                                        local aop = layout.widgets.partyTargetText.arenaOnParty or {}
                                        layout.widgets.partyTargetText.arenaOnParty = {
                                            enabled = aop.enabled,
                                            alwaysOn = aop.alwaysOn,
                                            anchor = defaults.anchor,
                                            fontSize = defaults.fontSize,
                                            posX = defaults.posX,
                                            posY = defaults.posY,
                                        }
                                        self:UpdateWidgetSettings(layout.widgets, info, nil)
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                    end,
                                },
                            },
                        },
                    },
                },
            },
        },
    }

    local drCategoryOrder = {
        Incapacitate = 1,
        Stun         = 2,
        Root         = 3,
        Silence      = 4,
        Disarm       = 5,
        Disorient    = 6,
        Knock        = 7,
    }

    for categoryKey, categoryName in pairs(drCategoryDisplay) do
        optionsTable.dr.args.drCategorySizing.args[categoryKey] = {
            order = drCategoryOrder[categoryKey],
            name = L["DR_" .. categoryKey] or categoryName,
            type = "range",
            min = -25,
            max = 25,
            softMin = -10,
            softMax = 20,
            step = 1,
            get = function(info)
                local dr = info.handler.db.profile.layoutSettings[layoutName].dr
                dr.drCategorySizeOffsets = dr.drCategorySizeOffsets or {}
                return dr.drCategorySizeOffsets[info[#info]] or 0
            end,
            set = function(info, val)
                local dr = info.handler.db.profile.layoutSettings[layoutName].dr
                dr.drCategorySizeOffsets = dr.drCategorySizeOffsets or {}
                dr.drCategorySizeOffsets[info[#info]] = val
                self:UpdateDRSettings(dr, info)
            end,
        }
    end

    local function petGet(info)
        local lyt = info.handler.db.profile.layoutSettings[layoutName]
        lyt.petFrames = lyt.petFrames or {}
        return lyt.petFrames[info[#info]]
    end
    local function petSet(info, val)
        local lyt = info.handler.db.profile.layoutSettings[layoutName]
        lyt.petFrames = lyt.petFrames or {}
        lyt.petFrames[info[#info]] = val
        info.handler:RefreshPetFrameSettings()
    end

    optionsTable.petFrames = {
        order = 4.5,
        name = L["Category_PetFrames"],
        type = "group",
        args = {
            sizing = {
                order = 1,
                name = L["Sizing"],
                type = "group",
                inline = true,
                get = petGet,
                set = petSet,
                args = {
                    width = {
                        order = 1,
                        name = L["Width"],
                        type = "range",
                        min = 20, max = 400, step = 0.01, bigStep = 1,
                    },
                    height = {
                        order = 2,
                        name = L["Height"],
                        type = "range",
                        min = 4, max = 100, step = 0.01, bigStep = 1,
                    },
                    scale = {
                        order = 3,
                        name = L["Scale"],
                        type = "range",
                        min = 0.1,
                        max = 5.0,
                        softMin = 0.5,
                        softMax = 3.0,
                        step = 0.01,
                        bigStep = 0.01,
                        isPercent = true,
                    },
                },
            },
            positioning = {
                order = 2,
                name = L["Positioning"],
                type = "group",
                inline = true,
                get = petGet,
                set = petSet,
                args = {
                    posX = {
                        order = 1,
                        name = L["Horizontal"],
                        type = "range",
                        min = -2000, max = 2000, softMin = -250, softMax = 250, step = 0.01, bigStep = 1,
                    },
                    posY = {
                        order = 2,
                        name = L["Vertical"],
                        type = "range",
                        min = -2000, max = 2000, softMin = -250, softMax = 250, step = 0.01, bigStep = 1,
                    },
                    frameStrata = {
                        order = 3,
                        name = L["Option_PetFrameStrata"],
                        type = "select",
                        style = "dropdown",
                        width = 0.85,
                        values = {
                            LOW    = L["Option_PetFrameStrata_Low"],
                            MEDIUM = L["Option_PetFrameStrata_Medium"],
                        },
                        sorting = { "LOW", "MEDIUM" },
                        get = function(info)
                            local lyt = info.handler.db.profile.layoutSettings[layoutName]
                            lyt.petFrames = lyt.petFrames or {}
                            return lyt.petFrames.frameStrata or "MEDIUM"
                        end,
                        set = function(info, val)
                            local lyt = info.handler.db.profile.layoutSettings[layoutName]
                            lyt.petFrames = lyt.petFrames or {}
                            lyt.petFrames.frameStrata = val
                            info.handler:RefreshPetFrameSettings()
                        end,
                    },
                },
            },
            widgets = {
                order = 3,
                name = L["Category_PetFrameWidgetSettings"],
                type = "group",
                inline = true,
                get = function(info)
                    local lyt = info.handler.db.profile.layoutSettings[layoutName]
                    lyt.petFrames = lyt.petFrames or {}
                    lyt.petFrames.widgets = lyt.petFrames.widgets or {}
                    local wkey = info[#info - 1]
                    local skey = info[#info]
                    local w = lyt.petFrames.widgets[wkey]
                    return w and w[skey]
                end,
                set = function(info, val)
                    local lyt = info.handler.db.profile.layoutSettings[layoutName]
                    lyt.petFrames = lyt.petFrames or {}
                    lyt.petFrames.widgets = lyt.petFrames.widgets or {}
                    local wkey = info[#info - 1]
                    local skey = info[#info]
                    lyt.petFrames.widgets[wkey] = lyt.petFrames.widgets[wkey] or {}
                    lyt.petFrames.widgets[wkey][skey] = val
                    info.handler:RefreshPetFrameSettings()
                end,
                args = (function()
                    local function petWidgetEnabled(info, wkey)
                        local lyt = info.handler.db.profile.layoutSettings[layoutName]
                        local w = lyt and lyt.petFrames and lyt.petFrames.widgets and lyt.petFrames.widgets[wkey]
                        return w and w.enabled
                    end
                    local function disabledIfDisabled(wkey)
                        return function(info) return not petWidgetEnabled(info, wkey) end
                    end
                    local function makeWidgetGroup(order, wkey, displayName, extras)
                        local group = {
                            order = order,
                            name = displayName,
                            type = "group",
                            inline = true,
                            args = {
                                enabled = {
                                    order = 1,
                                    name = L["Enable"],
                                    type = "toggle",
                                    width = "full",
                                },
                                scale = {
                                    order = 2,
                                    name = L["Scale"],
                                    type = "range",
                                    min = 0.1, max = 3.0, step = 0.01, bigStep = 0.01, isPercent = true,
                                    width = 0.95,
                                    disabled = disabledIfDisabled(wkey),
                                },
                                posX = {
                                    order = 3,
                                    name = L["Horizontal"],
                                    type = "range",
                                    min = -500, max = 500, softMin = -100, softMax = 100, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    disabled = disabledIfDisabled(wkey),
                                },
                                posY = {
                                    order = 4,
                                    name = L["Vertical"],
                                    type = "range",
                                    min = -500, max = 500, softMin = -100, softMax = 100, step = 0.1, bigStep = 1,
                                    width = 0.95,
                                    disabled = disabledIfDisabled(wkey),
                                },
                            },
                        }
                        if extras then
                            for k, v in pairs(extras) do group.args[k] = v end
                        end
                        return group
                    end

                    return {
                        targetIndicator = makeWidgetGroup(1, "targetIndicator",
                            L["Widget_TargetIndicator"] .. " |A:TargetCrosshairs:23:23|a"),
                        focusIndicator = makeWidgetGroup(2, "focusIndicator",
                            L["Widget_FocusIndicator"] .. " |TInterface\\AddOns\\sArena_Reloaded\\Textures\\Waypoint-MapPin-Untracked.tga:23:23|t"),
                        combatIndicator = makeWidgetGroup(3, "combatIndicator",
                            L["Widget_CombatIndicator"] .. " |A:Food:23:23|a"),
                        partyTargetIndicators = makeWidgetGroup(4, "partyTargetIndicators",
                            L["Widget_PartyTargetOnPetFrame"] .. " |TInterface\\AddOns\\sArena_Reloaded\\Textures\\GM-icon-headCount.tga:19:19|t",
                            {
                                direction = {
                                    order = 5,
                                    name = L["Direction"],
                                    type = "select",
                                    style = "dropdown",
                                    width = 0.95,
                                    values = {
                                        LEFT  = L["Direction_Left"],
                                        RIGHT = L["Direction_Right"],
                                        UP    = L["Direction_Up"],
                                        DOWN  = L["Direction_Down"],
                                    },
                                    disabled = disabledIfDisabled("partyTargetIndicators"),
                                },
                                spacing = {
                                    order = 6,
                                    name = L["Spacing"],
                                    type = "range",
                                    min = -10, max = 50, step = 0.5,
                                    width = 0.95,
                                    disabled = disabledIfDisabled("partyTargetIndicators"),
                                },
                            }),
                    }
                end)(),
            },
            petFrameRangeCheck = {
                order = 4,
                name = L["Category_PetFrameRangeCheckSettings"],
                type = "group",
                inline = true,
                get = function(info)
                    local lyt = info.handler.db.profile.layoutSettings[layoutName]
                    lyt.petFrames = lyt.petFrames or {}
                    lyt.petFrames.petFrameRangeCheck = lyt.petFrames.petFrameRangeCheck or {}
                    local key = info[#info]
                    local val = lyt.petFrames.petFrameRangeCheck[key]
                    if val ~= nil then return val end
                    if key == "scale" then return 1 end
                    if key == "posX" or key == "posY" then return 0 end
                end,
                set = function(info, val)
                    local lyt = info.handler.db.profile.layoutSettings[layoutName]
                    lyt.petFrames = lyt.petFrames or {}
                    lyt.petFrames.petFrameRangeCheck = lyt.petFrames.petFrameRangeCheck or {}
                    lyt.petFrames.petFrameRangeCheck[info[#info]] = val
                    info.handler:RefreshPetFrameSettings()
                end,
                args = {
                    enabled = {
                        order = 1,
                        name = L["Enable"],
                        type = "toggle",
                        width = "full",
                        set = function(info, val)
                            local lyt = info.handler.db.profile.layoutSettings[layoutName]
                            lyt.petFrames = lyt.petFrames or {}
                            lyt.petFrames.petFrameRangeCheck = lyt.petFrames.petFrameRangeCheck or {}
                            lyt.petFrames.petFrameRangeCheck.enabled = val
                            if not val then
                                info.handler:ResetRangeChecks()
                            end
                            info.handler:RefreshPetFrameSettings()
                            if info.handler.testMode then
                                info.handler:Test()
                            end
                        end,
                    },
                    scale = {
                        order = 2,
                        name = L["Scale"],
                        type = "range",
                        min = 0.1,
                        max = 3.0,
                        softMin = 0.5,
                        softMax = 2.0,
                        step = 0.01,
                        bigStep = 0.01,
                        isPercent = true,
                        width = 0.95,
                        disabled = function(info)
                            local lyt = info.handler.db.profile.layoutSettings[layoutName]
                            return not (lyt and lyt.petFrames and lyt.petFrames.petFrameRangeCheck and lyt.petFrames.petFrameRangeCheck.enabled)
                        end,
                    },
                    posX = {
                        order = 3,
                        name = L["Horizontal"],
                        type = "range",
                        min = -200, max = 200, softMin = -100, softMax = 100, step = 0.1, bigStep = 1,
                        width = 0.95,
                        disabled = function(info)
                            local lyt = info.handler.db.profile.layoutSettings[layoutName]
                            return not (lyt and lyt.petFrames and lyt.petFrames.petFrameRangeCheck and lyt.petFrames.petFrameRangeCheck.enabled)
                        end,
                    },
                    posY = {
                        order = 4,
                        name = L["Vertical"],
                        type = "range",
                        min = -200, max = 200, softMin = -100, softMax = 100, step = 0.1, bigStep = 1,
                        width = 0.95,
                        disabled = function(info)
                            local lyt = info.handler.db.profile.layoutSettings[layoutName]
                            return not (lyt and lyt.petFrames and lyt.petFrames.petFrameRangeCheck and lyt.petFrames.petFrameRangeCheck.enabled)
                        end,
                    },
                },
            },
        },
    }

    do
        local ts = optionsTable.textSettings.args
        local petKeys = { petNameText = true, petHealthText = true }
        local arenaArgs, petArgs = {}, {}
        for k, v in pairs(ts) do
            if petKeys[k] then petArgs[k] = v else arenaArgs[k] = v end
        end
        optionsTable.textSettings.args = {
            arenaFrames = {
                order = 1,
                name = L["Category_ArenaFrames"],
                type = "group",
                inline = true,
                args = arenaArgs,
            },
            petFramesHeader = {
                order = 5,
                name = L["Category_PetFrames"],
                type = "header",
            },
            petFrames = {
                order = 5.5,
                name = L["Category_PetFrames"],
                type = "group",
                inline = true,
                args = petArgs,
            },
        }
    end

    return optionsTable
end

function sArenaMixin:UpdateFrameSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
    self:SetScale(db.scale)

    local growthDirection = db.growthDirection
    local spacing = db.spacing
    local layoutCF = (self.layoutdb and self.layoutdb.changeFont)

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local text = frame.ClassIcon.Cooldown.Text
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.classIconFontSize, self:GetFontFlags("OUTLINE"))
        local sArenaText = frame.ClassIcon.Cooldown.sArenaText
        if sArenaText then
            sArenaText:SetFont(fontToUse, db.classIconFontSize, self:GetFontFlags("OUTLINE"))
        end
    end

    if isMidnight then
        self:UpdateAuraCooldownFont(db.classIconFontSize)
    end

    for i = 2, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local prevFrame = self["arena" .. i - 1]

        frame:ClearAllPoints()
        if (growthDirection == 1) then
            frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
        elseif (growthDirection == 2) then
            frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
        elseif (growthDirection == 3) then
            frame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
        elseif (growthDirection == 4) then
            frame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
        end
    end
end

function sArenaMixin:UpdateCastBarSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.CastBar:ClearAllPoints()
        frame.CastBar:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)

        frame.CastBar.Icon:ClearAllPoints()
        if isRetail then
            frame.CastBar.Icon:SetPoint("RIGHT", frame.CastBar, "LEFT", -5 + (db.iconPosX or 0), (db.iconPosY or 0) + (db.useModernCastbars and -4.5 or 0))
        else
            frame.CastBar.Icon:SetPoint("RIGHT", frame.CastBar, "LEFT", -5 + (db.iconPosX or 0), (db.iconPosY or 0) + (db.useModernCastbars and -5.5 or 0))
        end

        frame.CastBar:SetScale(db.scale)
        frame.CastBar:SetWidth(db.width)
        frame.CastBar.BorderShield:ClearAllPoints()
        if db.useModernCastbars then
            if isRetail then
                frame.CastBar.BorderShield:SetAtlas("UI-CastingBar-Shield")
                frame.CastBar.BorderShield:SetPoint("CENTER", frame.CastBar.Icon, "CENTER", -0.2, -3)
                frame.CastBar.BorderShield:SetSize(30, 34)
            else
                frame.CastBar.BorderShield:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Shield.tga")
                frame.CastBar.BorderShield:SetPoint("CENTER", frame.CastBar.Icon, "CENTER", 0, -3)
                frame.CastBar.BorderShield:SetSize(49, 47)
            end
        else
            frame.CastBar.BorderShield:SetTexture(330124)
            frame.CastBar.BorderShield:SetSize(48, 48)
            frame.CastBar.BorderShield:SetPoint("CENTER", frame.CastBar.Icon, "CENTER", 9, -1)
        end

        if db.hideBorderShield then
            frame.CastBar.BorderShield:SetTexture(nil)
        end

        if db.hideCastbarSpark then
            frame.CastBar.Spark:SetAlpha(0)
        else
            frame.CastBar.Spark:SetAlpha(1)
        end

        if db.hideCastbarIcon then
            frame.CastBar.Icon:SetAlpha(0)
            frame.CastBar.BorderShield:SetAlpha(0)
        else
            frame.CastBar.Icon:SetAlpha(1)
            frame.CastBar.BorderShield:SetAlpha(1)
        end

        frame.CastBar.Icon:SetDrawLayer("OVERLAY", 6)
        frame.CastBar.BorderShield:SetDrawLayer("OVERLAY", 5)

        frame.CastBar.BorderShield:SetScale(db.iconScale or 1)
        frame.CastBar.Icon:SetScale(db.iconScale or 1)

        if frame.CastBar.iconHighlight then
            local iconGlow = frame.CastBar.iconHighlight
            local icon = frame.CastBar.Icon
            local iconScale = db.iconScale or 1
            local size = 16 * iconScale

            local mult = 1.2
            iconGlow:ClearAllPoints()
            iconGlow:SetPoint("TOPLEFT", icon, "TOPLEFT", -(size * mult), size * mult)
            iconGlow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", size * mult, -(size * mult))
        end
    end

    self:UpdateCastBarPixelBorders()
end

function sArenaMixin:UpdateCastBarPixelBorders()
    local currentLayout = self.db and self.db.profile and self.db.profile.currentLayout
    local isPixelBorderLayout = (currentLayout == "Pixelated" or currentLayout == "BlizzRaid")
    local layoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[currentLayout]
    local cropIcons = layoutSettings and layoutSettings.cropIcons or false
    local useModernCastbars = layoutSettings and layoutSettings.castBar and layoutSettings.castBar.useModernCastbars or false
    local pixelBorderSize = layoutSettings and layoutSettings.pixelBorderSize or 1.5
    local bordersHidden = pixelBorderSize == 0

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        if frame.CastBar.barPixelBorder then
            if isPixelBorderLayout and not useModernCastbars and not bordersHidden then
                frame.CastBar.barPixelBorder:Show()
            else
                frame.CastBar.barPixelBorder:Hide()
            end
        end

        if frame.CastBar.iconPixelBorder then
            local hideCastbarIcon = layoutSettings and layoutSettings.castBar and layoutSettings.castBar.hideCastbarIcon
            if isPixelBorderLayout and not useModernCastbars and not hideCastbarIcon and not bordersHidden then
                frame.CastBar.iconPixelBorder:Show()
            else
                frame.CastBar.iconPixelBorder:Hide()
            end
        end

        local shouldCrop = isPixelBorderLayout or cropIcons
        frame:SetTextureCrop(frame.CastBar.Icon, shouldCrop)
    end
end

function sArenaMixin:UpdateCastbarColors()
    local currentLayout = self.db and self.db.profile and self.db.profile.currentLayout
    local layoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[currentLayout]
    local recolorEnabled = layoutSettings and layoutSettings.castBar and layoutSettings.castBar.recolorCastbar
    local interruptStatusColorOn = layoutSettings and layoutSettings.castBar and layoutSettings.castBar.interruptStatusColorOn
    local colors = self.db and self.db.profile and self.db.profile.castBarColors

    if layoutSettings then
        self.interruptStatusColorOn = interruptStatusColorOn
    end

    local defaultStandard = { 1.0, 0.7, 0.0, 1 }
    local defaultChannel = { 0.0, 1.0, 0.0, 1 }
    local defaultUninterruptable = { 0.7, 0.7, 0.7, 1 }
    local defaultInterruptNotReady = { 1.0, 0.0, 0.0, 1 }

    local standardColor = (colors and colors.standard) or defaultStandard
    local channelColor = (colors and colors.channel) or defaultChannel
    local uninterruptableColor = (colors and colors.uninterruptable) or defaultUninterruptable
    local interruptNotReadyColor = (colors and colors.interruptNotReady) or defaultInterruptNotReady

    self.castbarColors = {
        enabled = recolorEnabled,
        standard = standardColor,
        channel = channelColor,
        uninterruptable = uninterruptableColor,
        interruptNotReady = interruptNotReadyColor,
    }

    if isMidnight then
        self.castbarColors.colorStandard = CreateColor(unpack(standardColor))
        self.castbarColors.colorChannel = CreateColor(unpack(channelColor))
        self.castbarColors.colorUninterruptable = CreateColor(unpack(uninterruptableColor))
        self.castbarColors.colorInterruptNotReady = CreateColor(unpack(interruptNotReadyColor))
        self.castbarColors.defaultStandard = CreateColor(1.0, 0.7, 0.0, 1)
        self.castbarColors.defaultChannel = CreateColor(0.0, 1.0, 0.0, 1)
        self.castbarColors.defaultUninterruptable = CreateColor(0.7, 0.7, 0.7, 1)
        self.castbarColors.colorRed = CreateColor(1, 0, 0, 1)
    end

    -- Update MoP castbar colors for already-created castbars
    if self.isMoP and self.UpdateMoPCastbarColors then
        self:UpdateMoPCastbarColors()
    end
end

function sArenaMixin:RefreshTestModeCastbars()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame.tempCast and frame.CastBar:IsShown() then
            local db = self.db
            local layout = db.profile.layoutSettings[db.profile.currentLayout]
            local recolorEnabled = layout and layout.castBar and layout.castBar.recolorCastbar
            local colors = db.profile.castBarColors
            local barTexture = frame.CastBar:GetStatusBarTexture()
            local useModernCastbars = layout and layout.castBar and layout.castBar.useModernCastbars
            local keepDefaultModernTextures = layout and layout.castBar and layout.castBar.keepDefaultModernTextures

            -- Update texture based on cast type
            if not (useModernCastbars and keepDefaultModernTextures) then
                local texKeys = layout.textures or {
                    generalStatusBarTexture = "sArena Default",
                    healStatusBarTexture    = "sArena Default",
                    castbarStatusBarTexture = "sArena Default",
                    castbarUninterruptibleTexture = "sArena Default",
                }

                local castPath
                if frame.tempUninterruptible then
                    castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarUninterruptibleTexture or texKeys.castbarStatusBarTexture)
                else
                    castPath = LSM:Fetch(LSM.MediaType.STATUSBAR, texKeys.castbarStatusBarTexture)
                end
                frame.CastBar:SetStatusBarTexture(castPath)
            end

            if recolorEnabled and colors then
                if frame.tempUninterruptible then
                    frame.CastBar:SetStatusBarColor(unpack(colors.uninterruptable or {0.7, 0.7, 0.7, 1}))
                elseif frame.tempChannel then
                    frame.CastBar:SetStatusBarColor(unpack(colors.channel or {0.0, 1.0, 0.0, 1}))
                else
                    frame.CastBar:SetStatusBarColor(unpack(colors.standard or {1.0, 0.7, 0.0, 1}))
                end
                barTexture:SetDesaturated(true)
            else
                if useModernCastbars and keepDefaultModernTextures then
                    barTexture:SetDesaturated(false)
                    frame.CastBar:SetStatusBarColor(1, 1, 1)
                else
                    if frame.tempUninterruptible then
                        frame.CastBar:SetStatusBarColor(0.7, 0.7, 0.7, 1)
                    elseif frame.tempChannel then
                        frame.CastBar:SetStatusBarColor(0, 1, 0, 1)
                    else
                        frame.CastBar:SetStatusBarColor(1, 0.7, 0, 1)
                    end
                end
            end

            if db.profile.showCastbarTarget and frame.tempCastName then
                local textSettings = layout and layout.textSettings
                local anchorInside = textSettings and textSettings.castbarTargetAnchorInside
                local playerName = UnitName("player")
                local _, playerClass = UnitClass("player")

                local coloredName = playerName
                if playerClass then
                    local color = C_ClassColor.GetClassColor(playerClass)
                    if color then
                        coloredName = color:WrapTextInColorCode(playerName)
                    end
                end

                if anchorInside then
                    frame.CastBar.Text:SetText(frame.tempCastName .. ": " .. coloredName)
                    if frame.CastBar.ArenaTargetText then
                        frame.CastBar.ArenaTargetText:Hide()
                        frame.CastBar.ArenaTargetText:SetText("")
                    end
                else
                    frame.CastBar.Text:SetText(frame.tempCastName)
                    if frame.CastBar.ArenaTargetText then
                        frame.CastBar.ArenaTargetText:SetText(coloredName)
                        frame.CastBar.ArenaTargetText:Show()
                    end
                end
            elseif frame.tempCastName then
                frame.CastBar.Text:SetText(frame.tempCastName)
                if frame.CastBar.ArenaTargetText then
                    frame.CastBar.ArenaTargetText:Hide()
                    frame.CastBar.ArenaTargetText:SetText("")
                end
            end

            if frame.CastBar.barHighlight then
                if (db.profile.highlightCastsOnMe or db.profile.highlightCC) and i == 2 then
                    frame.CastBar.barHighlight:SetAlpha(1)
                else
                    frame.CastBar.barHighlight:SetAlpha(0)
                end
            end
            if frame.CastBar.iconHighlight then
                if db.profile.glowCastbarIcon and (db.profile.highlightCastsOnMe or db.profile.highlightCC) and i == 2 then
                    frame.CastBar.iconHighlight:SetAlpha(1)
                else
                    frame.CastBar.iconHighlight:SetAlpha(0)
                end
            end
        end
    end
end

function sArenaMixin:UpdateDRSettings(db, info, val)
    if not db then return end

    if (val) then
        db[info[#info]] = val
    end

    local layoutCF = (self.layoutdb and self.layoutdb.changeFont)

    self.drBaseSize = isMidnight and (db.size or 28) or db.size

    local currentLayout = self.db and self.db.profile and self.db.profile.currentLayout
    local layoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[currentLayout]
    local cropIcons = layoutSettings and layoutSettings.cropIcons or false

    local categorySizeOffsets = not isMidnight and (db.drCategorySizeOffsets or {}) or nil

    local disableSwipeEdge = self.db.profile.disableSwipeEdge
    local disableDRSwipe = self.db.profile.disableDRSwipe
    local reverseDR = self.db.profile.invertDRCooldown

    local swipeColor = self.db.profile.cooldownSwipeColor or { 0, 0, 0, 0.55 }
    local swipeR, swipeG, swipeB, swipeA = swipeColor[1] or 0, swipeColor[2] or 0, swipeColor[3] or 0, swipeColor[4] or 0.55

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame:UpdateDRPositions()

        local useDrFrames = frame.drFrames ~= nil
        local drList = frame.drFrames or self.drCategories
        local drCount = drList and #drList or 0

        for n = 1, drCount do
            local dr = useDrFrames and drList[n] or frame[drList[n]]
            if not dr then return end
            local sizeOffset = 0
            if categorySizeOffsets and not useDrFrames then
                sizeOffset = categorySizeOffsets[drList[n]] or 0
            end

            if dr then
                local size = (db.size or 28) + sizeOffset

                dr:SetFrameLevel(20)
                dr:SetSize(size, size)

                local borderSize = (db.drBorderGlowOff and 1.5) or (db.brightDRBorder and 1) or db.borderSize or 1
                dr.Border:SetPoint("TOPLEFT", dr, "TOPLEFT", -borderSize, borderSize)
                dr.Border:SetPoint("BOTTOMRIGHT", dr, "BOTTOMRIGHT", borderSize, -borderSize)
                dr.Cooldown:SetSwipeColor(swipeR, swipeG, swipeB, swipeA)

                local text = dr.Cooldown.Text
                local fontToUse = text.fontFile
                if layoutCF then
                    fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
                end
                text:SetFont(fontToUse, db.fontSize, self:GetFontFlags("OUTLINE"))
                local sArenaText = dr.Cooldown.sArenaText
                if sArenaText then
                    sArenaText:SetFont(fontToUse, db.fontSize, self:GetFontFlags("OUTLINE"))
                end

                if dr.Cooldown then
                    dr.Cooldown:SetReverse(reverseDR)
                    if disableDRSwipe then
                        dr.Cooldown:SetDrawSwipe(false)
                        dr.Cooldown:SetDrawEdge(false)
                    else
                        dr.Cooldown:SetDrawSwipe(true)
                        dr.Cooldown:SetDrawEdge(not disableSwipeEdge)
                    end
                end

                if db.showDRText then
                    dr.DRTextFrame:Show()
                else
                    dr.DRTextFrame:Hide()
                end

                dr.Icon:SetDrawLayer("ARTWORK", 0)
                if dr.Boverlay then
                    dr.Border:SetParent(dr)
                    dr.Boverlay:Hide()
                end
                if dr.Mask then
                    dr.Icon:RemoveMaskTexture(dr.Mask)
                end
                if dr.PixelBorder then
                    dr.PixelBorder:Hide()
                end

                dr.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                dr.Border:Show()
                dr.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                dr.Cooldown:SetSwipeTexture(1)

                if db.disableDRBorder then
                    dr.Border:Hide()
                    if dr.PixelBorder then
                        dr.PixelBorder:Hide()
                    end
                    if cropIcons then
                        dr.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    else
                        dr.Icon:SetTexCoord(0, 1, 0, 1)
                    end

                elseif db.thinPixelBorder then
                    dr.Border:Show()
                    if dr.PixelBorder then
                        dr.PixelBorder:Hide()
                    end
                    dr.Border:SetAtlas("communities-create-avatar-border-selected")
                    dr.Icon:SetTexCoord(0.05, 0.95, 0.07, 0.9)

                elseif db.thickPixelBorder then
                    dr.Border:Hide()
                    local drSize = layoutSettings and layoutSettings.drPixelBorderSize or 2
                    frame.parent:CreatePixelTextureBorder(dr, dr, "PixelBorder", drSize, 0, false)
                    dr.PixelBorder:Show()

                    if db.blackDRBorder then
                        dr.PixelBorder:SetVertexColor(0, 0, 0, 1)
                    else
                        if n == 1 then
                            dr.PixelBorder:SetVertexColor(1, 0, 0, 1)
                        else
                            dr.PixelBorder:SetVertexColor(0, 1, 0, 1)
                        end
                    end

                elseif db.drBorderGlowOff then
                    dr.Border:Show()
                    if dr.PixelBorder then
                        dr.PixelBorder:Hide()
                    end
                    if not dr.Mask then
                        dr.Mask = dr:CreateMaskTexture()
                    end
                    dr.Mask:SetPoint("TOPLEFT", dr.Icon, "TOPLEFT", 0.5, -0.5)
                    dr.Mask:SetPoint("BOTTOMRIGHT", dr.Icon, "BOTTOMRIGHT", -0.5, 0.5)
                    dr.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
                    dr.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\squarecutcornermask")
                    dr.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\squarecutcornermask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                    dr.Icon:SetDrawLayer("OVERLAY", 7)
                    dr.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.9)
                    dr.Icon:AddMaskTexture(dr.Mask)

                elseif db.brightDRBorder then
                    dr.Border:Show()
                    if dr.PixelBorder then
                        dr.PixelBorder:Hide()
                    end
                    if not dr.Mask then
                        dr.Mask = dr:CreateMaskTexture()
                    end
                    dr.Mask:SetPoint("TOPLEFT", dr.Icon, "TOPLEFT", -1, 1)
                    dr.Mask:SetPoint("BOTTOMRIGHT", dr.Icon, "BOTTOMRIGHT", 1, -1)
                    if isRetail then
                        dr.Border:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-ActionBar-PetAutoCast-Mask.tga")
                        dr.Cooldown:SetSwipeTexture("Interface\\TalentFrame\\talentsmasknodechoiceflyout")
                        dr.Mask:SetTexture("Interface\\TalentFrame\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                    else
                        dr.Border:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-HUD-ActionBar-PetAutoCast-Mask.tga")
                        dr.Cooldown:SetSwipeTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout")
                        dr.Mask:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\talentsmasknodechoiceflyout", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                    end
                    dr.Icon:SetTexCoord(0.05, 0.95, 0.05, 0.9)
                    dr.Icon:AddMaskTexture(dr.Mask)

                    if not dr.Boverlay then
                        dr.Boverlay = CreateFrame("Frame", nil, dr)
                        dr.Boverlay:SetFrameStrata("MEDIUM")
                        dr.Boverlay:SetFrameLevel(26)
                    end
                    dr.Boverlay:Show()
                    dr.Border:SetParent(dr.Boverlay)
                end
            end
        end
    end

    if layoutSettings and layoutSettings.textSettings then
        self:UpdateDRTextPositions(layoutSettings.textSettings)
    end
end

function sArenaMixin:UpdateSpecIconSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.SpecIcon:ClearAllPoints()
        frame.SpecIcon:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.SpecIcon:SetScale(db.scale)
    end
end

function sArenaMixin:UpdateTrinketSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    local layoutCF = (self.layoutdb and self.layoutdb.changeFont)

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.Trinket:ClearAllPoints()
        frame.Trinket:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.Trinket:SetScale(db.scale)

        local text = self["arena" .. i].Trinket.Cooldown.Text
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.fontSize, self:GetFontFlags("OUTLINE"))
    end
end

function sArenaMixin:UpdateRacialSettings(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.Racial:ClearAllPoints()
        frame.Racial:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.Racial:SetScale(db.scale)

        local text = self["arena" .. i].Racial.Cooldown.Text
        local layoutCF = (self.layoutdb and self.layoutdb.changeFont)
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.fontSize, self:GetFontFlags("OUTLINE"))
    end
end

function sArenaMixin:UpdateDispelSettings(db, info, val)
    if (val ~= nil) then
        db[info[#info]] = val
    end

    local layoutCF = (self.layoutdb and self.layoutdb.changeFont)

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        frame.Dispel:ClearAllPoints()
        frame.Dispel:SetPoint("CENTER", frame, "CENTER", db.posX, db.posY)
        frame.Dispel:SetScale(db.scale)

        local text = self["arena" .. i].Dispel.Cooldown.Text
        local fontToUse = text.fontFile
        if layoutCF then
            fontToUse = LSM:Fetch(LSM.MediaType.FONT, self.layoutdb.cdFont)
        end
        text:SetFont(fontToUse, db.fontSize, self:GetFontFlags("OUTLINE"))

        frame.Dispel:SetShown(self.db.profile.showDispels)
    end
end

function sArenaMixin:UpdateTextPositions(db, info, val)
    for i = 1, self.maxArenaOpponents do
        local frame = info.handler["arena" .. i]
        local layout = info.handler.layouts[info.handler.db.profile.currentLayout]

        if frame and layout and layout.UpdateOrientation then
            layout:UpdateOrientation(frame)
        end
    end
end

function sArenaMixin:UpdateDRTextPositions(db, info, val)
    if (val) then
        db[info[#info]] = val
    end

    for i = 1, self.maxArenaOpponents do
        local frame = info and info.handler["arena" .. i] or self["arena" .. i]
        if not frame then return end

        local useDrFrames = frame.drFrames ~= nil
        local drList = frame.drFrames or self.drCategories
        local drCount = drList and #drList or 0

        for n = 1, drCount do
            local drFrame = useDrFrames and drList[n] or frame[drList[n]]

            if drFrame then
                local drText = drFrame.DRTextFrame.DRText
                drText:ClearAllPoints()
                drText:SetPoint(db.drTextAnchor or "BOTTOMRIGHT", (db.drTextOffsetX or 4), (db.drTextOffsetY or -4))
                drText:SetScale(db.drTextSize or 1.0)

                if drFrame.DRTextFrame.DRTextImmune then
                    local drTextImmune = drFrame.DRTextFrame.DRTextImmune
                    drTextImmune:ClearAllPoints()
                    drTextImmune:SetPoint("CENTER", drText, "CENTER", 0, 0)
                    drTextImmune:SetScale(db.drTextSize or 1.0)
                end
            end
        end
    end
end

function sArenaFrameMixin:UpdateClassIconCooldownReverse()
    local reverse = self.parent.db.profile.invertClassIconCooldown

    self.ClassIcon.Cooldown:SetReverse(reverse)
end

function sArenaFrameMixin:UpdateTrinketRacialCooldownReverse()
    local reverse = self.parent.db.profile.invertTrinketRacialCooldown

    self.Trinket.Cooldown:SetReverse(reverse)
    self.Racial.Cooldown:SetReverse(reverse)
end

function sArenaFrameMixin:UpdateClassIconSwipeSettings()
    local disableSwipe = self.parent.db.profile.disableClassIconSwipe
    local disableSwipeEdge = self.parent.db.profile.disableSwipeEdge

    if disableSwipe then
        self.ClassIcon.Cooldown:SetDrawSwipe(false)
        self.ClassIcon.Cooldown:SetDrawEdge(false)
    else
        self.ClassIcon.Cooldown:SetDrawSwipe(true)
        self.ClassIcon.Cooldown:SetDrawEdge(not disableSwipeEdge)
    end
end

function sArenaFrameMixin:UpdateTrinketRacialSwipeSettings()
    local disableSwipe = self.parent.db.profile.disableTrinketRacialSwipe
    local disableSwipeEdge = self.parent.db.profile.disableSwipeEdge

    if disableSwipe then
        self.Trinket.Cooldown:SetDrawSwipe(false)
        self.Trinket.Cooldown:SetDrawEdge(false)
    else
        self.Trinket.Cooldown:SetDrawSwipe(true)
        self.Trinket.Cooldown:SetDrawEdge(not disableSwipeEdge)
    end

    if disableSwipe then
        self.Racial.Cooldown:SetDrawSwipe(false)
        self.Racial.Cooldown:SetDrawEdge(false)
    else
        self.Racial.Cooldown:SetDrawSwipe(true)
        self.Racial.Cooldown:SetDrawEdge(not disableSwipeEdge)
    end
end

function sArenaFrameMixin:UpdateSwipeEdgeSettings()
    local disableEdge = self.parent.db.profile.disableSwipeEdge

    self.ClassIcon.Cooldown:SetDrawEdge(not disableEdge)
    self.Trinket.Cooldown:SetDrawEdge(not disableEdge)
    self.Racial.Cooldown:SetDrawEdge(not disableEdge)
end

local function setDRIcons()
    local inputs = {
        drIconsTitle = {
            order = 1,
            type = "description",
            name = function(info)
                local db = info.handler.db
                if db.profile.drStaticIconsPerSpec then
                    local className = select(1, UnitClass("player")) or L["Unknown"]
                    local classKey = select(2, UnitClass("player"))
                    local specName = info.handler.playerSpecName or L["Unknown"]
                    local classColor = C_ClassColor.GetClassColor(classKey)
                    local coloredText = specName .. " " .. className
                    if classColor then
                        coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                    end
                    return string.format(L["DR_IconsPerSpec"], coloredText)
                elseif db.profile.drStaticIconsPerClass then
                    local className = select(1, UnitClass("player")) or L["Unknown"]
                    local classKey = select(2, UnitClass("player"))
                    local classColor = C_ClassColor.GetClassColor(classKey)
                    local coloredText = className
                    if classColor then
                        coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                    end
                    return string.format(L["DR_IconsPerClass"], coloredText)
                else
                    return L["DR_IconsGlobal"]
                end
            end,
            fontSize = "medium",
        }
    }

    local order = 2

    for category, defaultIcon in pairs(drIcons) do
        inputs[category] = {
            order = order,
            name = function(info)
                local db = info.handler.db
                local icon = nil
                if db.profile.drStaticIconsPerSpec then
                    local specKey = info.handler.playerSpecID or 0
                    local perSpec = db.profile.drIconsPerSpec or {}
                    local specIcons = perSpec[specKey] or {}
                    icon = specIcons[category]
                elseif db.profile.drStaticIconsPerClass then
                    local classKey = info.handler.playerClass
                    local perClass = db.profile.drIconsPerClass or {}
                    local classIcons = perClass[classKey] or {}
                    icon = classIcons[category]
                end
                if not icon then
                    local dbIcons = db.profile.drIcons or {}
                    icon = dbIcons[category] or defaultIcon
                end
                local textureString = ""
                if type(icon) == "number" then
                    textureString = "|T" .. icon .. ":24:24:0:0:64:64:5:59:5:59|t "
                elseif type(icon) == "string" then
                    textureString = "|T" .. icon .. ":24|t "
                end
                return textureString .. (L["DR_" .. category] or category) .. ":"
            end,
            desc = string.format(L["Option_DefaultIcon_Desc"], defaultIcon, defaultIcon),
            type = "input",
            width = "full",
            get = function(info)
                local db = info.handler.db
                -- If per-spec is enabled, prefer the spec-specific value when present.
                -- If the spec-specific value is missing, show the global saved icon or the default icon
                -- so the edit box isn't empty and the user sees the effective icon.
                if db.profile.drStaticIconsPerSpec then
                    local perSpec = db.profile.drIconsPerSpec or {}
                    local specIcons = perSpec[info.handler.playerSpecID or 0] or {}
                    local specVal = specIcons[category]
                    if specVal ~= nil and specVal ~= "" then
                        return tostring(specVal)
                    end
                    -- fallback to global saved icon or default icon
                    local dbIcons = db.profile.drIcons or {}
                    return tostring(dbIcons[category] or defaultIcon or "")
                elseif db.profile.drStaticIconsPerClass then
                    local perClass = db.profile.drIconsPerClass or {}
                    local classIcons = perClass[info.handler.playerClass] or {}
                    local classVal = classIcons[category]
                    if classVal ~= nil and classVal ~= "" then
                        return tostring(classVal)
                    end
                    -- fallback to global saved icon or default icon
                    local dbIcons = db.profile.drIcons or {}
                    return tostring(dbIcons[category] or defaultIcon or "")
                else
                    local dbIcons = db.profile.drIcons or {}
                    return tostring(dbIcons[category] or defaultIcon or "")
                end
            end,
            set = function(info, value)
                local db = info.handler.db
                if db.profile.drStaticIconsPerSpec then
                    db.profile.drIconsPerSpec = db.profile.drIconsPerSpec or {}
                    local specKey = info.handler.playerSpecID or 0
                    db.profile.drIconsPerSpec[specKey] = db.profile.drIconsPerSpec[specKey] or {}
                    -- treat empty string as removal of the spec-specific override so we fall back
                    -- to the global saved icon/default.
                    if value == nil or tostring(value) == "" then
                        db.profile.drIconsPerSpec[specKey][category] = nil
                    else
                        local num = tonumber(value)
                        db.profile.drIconsPerSpec[specKey][category] = num or value
                    end
                elseif db.profile.drStaticIconsPerClass then
                    db.profile.drIconsPerClass = db.profile.drIconsPerClass or {}
                    db.profile.drIconsPerClass[info.handler.playerClass] = db.profile.drIconsPerClass[info.handler.playerClass] or {}
                    -- treat empty string as removal of the class-specific override so we fall back
                    -- to the global saved icon/default.
                    if value == nil or tostring(value) == "" then
                        db.profile.drIconsPerClass[info.handler.playerClass][category] = nil
                    else
                        local num = tonumber(value)
                        db.profile.drIconsPerClass[info.handler.playerClass][category] = num or value
                    end
                else
                    db.profile.drIcons = db.profile.drIcons or {}
                    if value == nil or tostring(value) == "" then
                        db.profile.drIcons[category] = nil
                    else
                        local num = tonumber(value)
                        db.profile.drIcons[category] = num or value
                    end
                end
                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
            end,
        }

        order = order + 1
    end

    return inputs
end

local conflictType, conflictNames = sArenaMixin:ConflictCheck()

if conflictType == "sarena" then
    sArenaMixin.optionsTable = {
        type = "group",
        name = sArenaMixin.addonTitle,
        childGroups = "tab",
        validate = validateCombat,
        args = {
            ImportOtherForkSettings = {
                order = 1,
                name = L["Option_AddonConflict"],
                desc = L["Conflict_MultipleVersions"],
                type = "group",
                args = {
                    warningTitle = {
                        order = 1,
                        type = "description",
                        name = L["Conflict_Warning"],
                        fontSize = "large",
                    },
                    spacer1 = {
                        order = 1.1,
                        type = "description",
                        name = " ",
                    },
                    explanation = {
                        order = 1.2,
                        type = "description",
                        name = L["Conflict_Explanation"],
                        fontSize = "medium",
                    },
                    spacer2 = {
                        order = 1.3,
                        type = "description",
                        name = " ",
                    },
                    option1 = {
                        order = 2,
                        type = "execute",
                        name = L["Conflict_UseOther"],
                        desc = L["Conflict_UseOther_Desc"],
                        func = function()
                            C_AddOns.DisableAddOn("sArena_Reloaded")
                            ReloadUI()
                        end,
                        width = "full",
                        confirm = true,
                        confirmText = L["Conflict_UseOther_Confirm"],
                    },
                    option2 = {
                        order = 3,
                        type = "execute",
                        name = L["Conflict_UseReloaded_Import"],
                        desc = L["Conflict_UseReloaded_Import_Desc"],
                        func = function(info)
                            if info.handler.ImportOtherForkSettings then
                                info.handler:ImportOtherForkSettings()
                            end
                        end,
                        width = "full",
                        confirm = true,
                        confirmText = L["Conflict_UseReloaded_Import_Confirm"],
                    },
                    option3 = {
                        order = 4,
                        type = "execute",
                        name = L["Conflict_UseReloaded_NoImport"],
                        desc = L["Conflict_UseReloaded_NoImport_Desc"],
                        func = function()
                            sArenaMixin:CompatibilityEnsurer()
                            ReloadUI()
                        end,
                        width = "full",
                        confirm = true,
                        confirmText = L["Conflict_UseReloaded_NoImport_Confirm"],
                    },
                    spacer3 = {
                        order = 4.5,
                        type = "description",
                        name = " ",
                    },
                    conversionStatus = {
                        order = 5,
                        type = "description",
                        name = function(info) return info.handler.conversionStatusText or "" end,
                        fontSize = "large",
                        hidden = function(info) return not info.handler.conversionStatusText end,
                    },
                },
            },
        },
    }
elseif conflictType == "other" then
    local addonListText = ""
    for _, name in ipairs(conflictNames) do
        addonListText = addonListText .. "\n|cffff8800• " .. name .. "|r"
    end

    sArenaMixin.optionsTable = {
        type = "group",
        name = sArenaMixin.addonTitle,
        childGroups = "tab",
        validate = validateCombat,
        args = {
            OtherAddonConflict = {
                order = 1,
                name = L["Option_OtherAddonConflict"],
                desc = L["OtherConflict_Detected"],
                type = "group",
                args = {
                    warningTitle = {
                        order = 1,
                        type = "description",
                        name = L["OtherConflict_Warning"],
                        fontSize = "large",
                    },
                    spacer1 = {
                        order = 1.1,
                        type = "description",
                        name = " ",
                    },
                    explanation = {
                        order = 1.2,
                        type = "description",
                        name = L["OtherConflict_Explanation"],
                        fontSize = "medium",
                    },
                    addonList = {
                        order = 1.3,
                        type = "description",
                        name = addonListText,
                        fontSize = "medium",
                    },
                    spacer2 = {
                        order = 1.4,
                        type = "description",
                        name = " ",
                    },
                    disableButton = {
                        order = 2,
                        type = "execute",
                        name = L["OtherConflict_DisableAndReload"],
                        desc = L["OtherConflict_DisableAndReload_Desc"],
                        func = function()
                            sArenaMixin:CompatibilityEnsurer()
                            sArena_ReloadedDB.reOpenOptions = true
                            ReloadUI()
                        end,
                        width = "full",
                        confirm = true,
                        confirmText = L["OtherConflict_DisableAndReload_Confirm"],
                    },
                },
            },
        },
    }
else
    sArenaMixin.optionsTable = {
        type = "group",
        name = sArenaMixin.addonTitle,
        childGroups = "tab",
        validate = validateCombat,
        args = {
            setLayout = {
                order = 1,
                name = L["Option_Layout"],
                type = "select",
                style = "dropdown",
                dialogControl = "sArena_LayoutPreviewDropdown",
                get = function(info) return info.handler.db.profile.currentLayout end,
                set = "SetLayout",
                values = getLayoutTable,
            },
            test = {
                order = 2,
                name = L["Option_Test"],
                type = "execute",
                func = "Test",
                width = "half",
            },
            hide = {
                order = 3,
                name = L["Option_Hide"],
                type = "execute",
                func = function(info)
                    for i = 1, info.handler.maxArenaOpponents do
                        info.handler["arena" .. i]:OnEvent("PLAYER_ENTERING_WORLD")
                    end
                end,
                width = "half",
            },
            dragNotice = {
                order = 4,
                name = ("|T132961:16|t |cffff3300"..L["Drag_Hint"].."|r"),
                type = "description",
                fontSize = "medium",
                width = 1.5,
            },
            layoutSettingsGroup = {
                order = 5,
                name = L["Layout_Settings"],
                desc = L["Layout_Settings_Desc"],
                type = "group",
                args = {},
            },
            globalSettingsGroup = {
                order = 6,
                name = L["Global_Settings"],
                desc = L["Global_Settings_Desc"],
                type = "group",
                childGroups = "tree",
                args = {
                    framesGroup = {
                        order = 1,
                        name = L["Option_ArenaFrames"],
                        type = "group",
                        args = {
                            statusText = {
                                order = 5,
                                name = L["Option_StatusText"],
                                type = "group",
                                inline = true,
                                args = {
                                    alwaysShow = {
                                        order = 1,
                                        name = L["Option_AlwaysShow"],
                                        desc = L["Text_ShowOnMouseover_Desc"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.statusText.alwaysShow end,
                                        set = function(info, val)
                                            info.handler.db.profile.statusText.alwaysShow = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateStatusTextVisible()
                                            end
                                        end,
                                    },
                                    usePercentage = {
                                        order = 2,
                                        name = L["Option_UsePercentage"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.statusText.usePercentage end,
                                        set = function(info, val)
                                            info.handler.db.profile.statusText.usePercentage = val
                                            if val then
                                                info.handler.db.profile.statusText.formatNumbers = false
                                            end

                                            local _, instanceType = IsInInstance()
                                            if (instanceType ~= "arena" and info.handler.arena1:IsShown()) then
                                                info.handler:Test()
                                            end
                                        end,
                                    },
                                    formatNumbers = {
                                        order = 3,
                                        name = L["Option_FormatNumbers"],
                                        desc = L["Text_FormatLargeNumbers_Desc"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.statusText.formatNumbers end,
                                        set = function(info, val)
                                            info.handler.db.profile.statusText.formatNumbers = val
                                            if val then
                                                info.handler.db.profile.statusText.usePercentage = false
                                            end

                                            local _, instanceType = IsInInstance()
                                            if (instanceType ~= "arena" and info.handler.arena1:IsShown()) then
                                                info.handler:Test()
                                            end
                                        end,
                                    },
                                    hidePowerText = {
                                        order = 4,
                                        name = L["Text_HidePowerText"],
                                        desc = L["Text_HidePowerText_Desc"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.hidePowerText end,
                                        set = function(info, val)
                                            info.handler.db.profile.hidePowerText = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateStatusTextVisible()
                                            end
                                        end,
                                    },
                                },
                            },
                            darkModeGroup = {
                                order = 5.5,
                                name = L["Option_DarkMode"],
                                type = "group",
                                inline = true,
                                args = {
                                    darkMode = {
                                        order = 1,
                                        name = L["DarkMode_Enable"],
                                        type = "toggle",
                                        width = 1,
                                        desc = function(info)
                                            local baseDesc = L["DarkMode_Enable_Desc"]
                                            local layout = info.handler.db.profile.currentLayout
                                            if layout == "BlizzCompact" then
                                                return baseDesc .. "\n\nCan be combined with Class Color FrameTexture. When combined, class colors take priority - use 'Only Class Icon' to apply class color to the icon while Dark Mode colors the rest."
                                            end
                                            return baseDesc
                                        end,
                                        get = function(info) return info.handler.db.profile.darkMode end,
                                        set = function(info, val)
                                            info.handler.db.profile.darkMode = val
                                            info.handler:RefreshConfig()
                                            info.handler:Test()
                                        end,
                                    },
                                    darkModeValue = {
                                        order = 2,
                                        name = L["DarkMode_Value"],
                                        type = "range",
                                        width = 0.75,
                                        desc = L["DarkMode_Value_Desc"],
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        disabled = function(info)
                                            return not info.handler.db.profile.darkMode
                                        end,
                                        get = function(info) return info.handler.db.profile.darkModeValue end,
                                        set = function(info, val)
                                            info.handler.db.profile.darkModeValue = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                    darkModeDesaturate = {
                                        order = 3,
                                        name = L["Option_Desaturate"],
                                        type = "toggle",
                                        width = 0.75,
                                        desc = L["DarkMode_Desaturate_Desc"],
                                        disabled = function(info)
                                            return not info.handler.db.profile.darkMode
                                        end,
                                        get = function(info) return info.handler.db.profile.darkModeDesaturate end,
                                        set = function(info, val)
                                            info.handler.db.profile.darkModeDesaturate = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                },
                            },
                            misc = {
                                order = 6,
                                name = L["Option_Miscellaneous"],
                                type = "group",
                                inline = true,
                                args = {
                                    classColors = {
                                        order = 1,
                                        name = L["ClassColor_Healthbars"],
                                        desc = L["ClassColor_Healthbars_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.classColors end,
                                        set = function(info, val)
                                            local db = info.handler.db
                                            db.profile.classColors = val

                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                local class = frame.tempClass
                                                local color = C_ClassColor.GetClassColor(class)

                                                if val and color then
                                                    frame.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
                                                else
                                                    frame.HealthBar:SetStatusBarColor(0, 1, 0, 1)
                                                end
                                            end
                                        end,
                                    },
                                    classColorFrameTexture = {
                                        order = 1.05,
                                        name = L["ClassColor_FrameTexture"],
                                        desc = L["ClassColor_FrameTexture_Desc"],
                                        type = "toggle",
                                        width = 1.1,
                                        get = function(info) return info.handler.db.profile.classColorFrameTexture end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorFrameTexture = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                    classColorFrameTextureOnlyClassIcon = {
                                        order = 1.06,
                                        name = L["ClassColor_OnlyClassIcon"],
                                        desc = L["ClassColor_OnlyClassIcon_Desc"],
                                        type = "toggle",
                                        width = 0.8,
                                        hidden = function(info)
                                            local layout = info.handler.db.profile.currentLayout
                                            return layout ~= "BlizzCompact"
                                        end,
                                        disabled = function(info) return not info.handler.db.profile.classColorFrameTexture end,
                                        get = function(info) return info.handler.db.profile.classColorFrameTextureOnlyClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorFrameTextureOnlyClassIcon = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                    classColorFrameTextureHealerGreen = {
                                        order = 1.07,
                                        name = L["ClassColor_HealerGreen"],
                                        desc = L["ClassColor_HealerGreen_Desc"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.classColorFrameTexture end,
                                        get = function(info) return info.handler.db.profile.classColorFrameTextureHealerGreen end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorFrameTextureHealerGreen = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena"..i]
                                                if frame then
                                                    frame:UpdateFrameColors()
                                                end
                                            end
                                        end,
                                    },
                                    spacerAfterFrameTexture = {
                                        order = 1.08,
                                        name = "",
                                        type = "description",
                                        width = "full",
                                    },
                                    classColorNames = {
                                        order = 1.1,
                                        name = L["Option_ClassColorNames"],
                                        desc = L["ClassColor_NameText_Desc"],
                                        type = "toggle",
                                        width = 1,
                                        disabled = function(info) return info.handler.db.profile.colorNameEnabled end,
                                        get = function(info) return info.handler.db.profile.classColorNames end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorNames = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if frame.Name:IsShown() then
                                                    frame:UpdateNameColor()
                                                end
                                            end
                                        end,
                                    },
                                    colorNameEnabled = {
                                        order = 1.11,
                                        name = L["Option_ColorName"],
                                        desc = L["Option_ColorName_Desc"],
                                        type = "toggle",
                                        width = 0.7,
                                        get = function(info) return info.handler.db.profile.colorNameEnabled end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorNameEnabled = val
                                            if val then
                                                info.handler.db.profile.classColorNames = false
                                            end
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if frame.Name:IsShown() then
                                                    frame:UpdateNameColor()
                                                end
                                            end
                                        end,
                                    },
                                    colorNameColor = {
                                        order = 1.12,
                                        name = "",
                                        type = "color",
                                        width = 0.15,
                                        disabled = function(info) return not info.handler.db.profile.colorNameEnabled end,
                                        get = function(info)
                                            local color = info.handler.db.profile.colorNameColor
                                            if color then
                                                return color.r, color.g, color.b, 1
                                            end
                                            return 1, 1, 1, 1
                                        end,
                                        set = function(info, r, g, b)
                                            info.handler.db.profile.colorNameColor = {r = r, g = g, b = b}
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if frame.Name:IsShown() then
                                                    frame:UpdateNameColor()
                                                end
                                            end
                                        end,
                                    },
                                    spacerAfterNameColor = {
                                        order = 1.13,
                                        name = "",
                                        type = "description",
                                        width = "full",
                                    },
                                    classColorSpecNames = {
                                        order = 1.15,
                                        name = L["Option_ClassColorSpecNames"],
                                        desc = L["Option_ClassColorSpecNames_Desc"],
                                        type = "toggle",
                                        width = 1,
                                        disabled = function(info) return info.handler.db.profile.colorSpecNameEnabled end,
                                        get = function(info) return info.handler.db.profile.classColorSpecNames end,
                                        set = function(info, val)
                                            info.handler.db.profile.classColorSpecNames = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                frame:UpdateSpecNameColor()
                                            end
                                        end,
                                    },
                                    colorSpecNameEnabled = {
                                        order = 1.16,
                                        name = L["Option_ColorSpecName"],
                                        desc = L["Option_ColorSpecName_Desc"],
                                        type = "toggle",
                                        width = 0.8,
                                        get = function(info) return info.handler.db.profile.colorSpecNameEnabled end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorSpecNameEnabled = val
                                            if val then
                                                info.handler.db.profile.classColorSpecNames = false
                                            end
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                frame:UpdateSpecNameColor()
                                            end
                                        end,
                                    },
                                    colorSpecNameColor = {
                                        order = 1.17,
                                        name = "",
                                        type = "color",
                                        width = 0.15,
                                        disabled = function(info) return not info.handler.db.profile.colorSpecNameEnabled end,
                                        get = function(info)
                                            local color = info.handler.db.profile.colorSpecNameColor
                                            if color then
                                                return color.r, color.g, color.b, 1
                                            end
                                            return 1, 1, 1, 1
                                        end,
                                        set = function(info, r, g, b)
                                            info.handler.db.profile.colorSpecNameColor = {r = r, g = g, b = b}
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                frame:UpdateSpecNameColor()
                                            end
                                        end,
                                    },
                                    spacerAfterSpecNameColor = {
                                        order = 1.18,
                                        name = "",
                                        type = "description",
                                        width = "full",
                                    },
                                    showNames = {
                                        order = 4,
                                        name = L["Option_ShowNames"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.showNames end,
                                        set = function(info, val)
                                            info.handler.db.profile.showNames = val
                                            info.handler.db.profile.showArenaNumber = false
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                frame.Name:SetShown(val)
                                                frame.Name:SetText(frame.tempName or "name")
                                            end
                                        end,
                                    },
                                    showArenaNumber = {
                                        order = 5,
                                        name = L["Option_ShowArenaNumber"],
                                        type = "toggle",
                                        width = 1,
                                        get = function(info) return info.handler.db.profile.showArenaNumber end,
                                        set = function(info, val)
                                            info.handler.db.profile.showArenaNumber = val
                                            info.handler.db.profile.showNames = false
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                local id = i
                                                if FrameSortApi then
                                                    id = FrameSortApi.v3.Frame:FrameNumberForUnit(frame.unit or ("arena"..i)) or i
                                                end
                                                frame.Name:SetShown(val)
                                                if info.handler.db.profile.arenaNumberIdOnly then
                                                    frame.Name:SetText(id)
                                                else
                                                    frame.Name:SetText("Arena " .. id)
                                                end
                                            end
                                        end,
                                    },
                                    arenaNumberIdOnly = {
                                        order = 5.01,
                                        name = L["Option_ArenaNumberIdOnly"],
                                        type = "toggle",
                                        width = 1,
                                        disabled = function(info) return not info.handler.db.profile.showArenaNumber end,
                                        get = function(info) return info.handler.db.profile.arenaNumberIdOnly end,
                                        set = function(info, val)
                                            info.handler.db.profile.arenaNumberIdOnly = val
                                            if info.handler.db.profile.showArenaNumber then
                                                for i = 1, info.handler.maxArenaOpponents do
                                                    local frame = info.handler["arena" .. i]
                                                    local id = i
                                                    if FrameSortApi then
                                                        id = FrameSortApi.v3.Frame:FrameNumberForUnit(frame.unit or ("arena"..i)) or i
                                                    end
                                                    if val then
                                                        frame.Name:SetText(id)
                                                    else
                                                        frame.Name:SetText("Arena " .. id)
                                                    end
                                                end
                                            end
                                        end,
                                    },
                                    reverseBarsFill = {
                                        order = 6,
                                        name = L["Option_ReverseBarsFill"],
                                        desc = L["Healthbar_ReverseFill_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.reverseBarsFill end,
                                        set = function(info, val)
                                            info.handler.db.profile.reverseBarsFill = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                frame.HealthBar:SetReverseFill(val)
                                                frame.PowerBar:SetReverseFill(val)
                                            end
                                        end,
                                    },
                                    shadowSightTimer = {
                                        order = 7.5,
                                        name = L["Option_ShadowsightTimer"],
                                        desc = L["Option_ShadowsightTimer_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.shadowSightTimer end,
                                        set = function(info, val)
                                            info.handler.db.profile.shadowSightTimer = val
                                        end,
                                    },
                                    colorMysteryGray = {
                                        order = 9,
                                        name = L["Option_ColorNonVisibleFramesGray"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["MysteryPlayer_GrayBars_Desc"],
                                        get = function(info) return info.handler.db.profile.colorMysteryGray end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorMysteryGray = val
                                        end,
                                    },
                                    stealthAlpha = {
                                        order = 12,
                                        name = L["Option_StealthAlpha"],
                                        desc = L["Option_StealthAlpha_Desc"],
                                        type = "range",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        isPercent = true,
                                        width = 0.8,
                                        get = function(info) return info.handler.db.profile.stealthAlpha end,
                                        set = function(info, val)
                                            info.handler.db.profile.stealthAlpha = val
                                            info.handler:UpdateStealthAlpha()
                                            if not sArenaMixin.stealthAlphaPreviewActive then
                                                sArenaMixin.stealthAlphaPreviewActive = true
                                                sArenaMixin.stealthAlphaPreviewSaved = {}
                                                for i = 1, info.handler.maxArenaOpponents do
                                                    local frame = info.handler["arena" .. i]
                                                    if frame and frame:IsShown() then
                                                        sArenaMixin.stealthAlphaPreviewSaved[i] = frame:GetAlpha()
                                                    end
                                                end
                                            end

                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if frame and frame:IsShown() then
                                                    frame:SetAlpha(val)
                                                end
                                            end

                                            sArenaMixin.stealthAlphaPreviewGen = (sArenaMixin.stealthAlphaPreviewGen or 0) + 1
                                            local gen = sArenaMixin.stealthAlphaPreviewGen
                                            C_Timer.After(0.7, function()
                                                if sArenaMixin.stealthAlphaPreviewGen ~= gen then return end
                                                local saved = sArenaMixin.stealthAlphaPreviewSaved
                                                sArenaMixin.stealthAlphaPreviewActive = nil
                                                sArenaMixin.stealthAlphaPreviewSaved = nil
                                                sArenaMixin.stealthAlphaPreviewGen = nil
                                                for i = 1, sArenaMixin.maxArenaOpponents do
                                                    local frame = sArena["arena" .. i]
                                                    if frame and frame:IsShown() then
                                                        frame:SetAlpha(saved and saved[i] or 1)
                                                    end
                                                end
                                            end)
                                        end,
                                    },
                                },
                            },
                            swipeAnimations = {
                                order = 7,
                                name = L["Option_SwipeAnimations"],
                                type = "group",
                                inline = true,
                                args = {
                                    cooldownSwipeColor = {
                                        order = -1,
                                        name = L["Option_CooldownSwipeColor"],
                                        desc = L["Option_CooldownSwipeColor_Desc"],
                                        type = "color",
                                        hasAlpha = true,
                                        get = function(info)
                                            local c = info.handler.db.profile.cooldownSwipeColor or { 0, 0, 0, 0.55 }
                                            return c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0.55
                                        end,
                                        set = function(info, r, g, b, a)
                                            info.handler.db.profile.cooldownSwipeColor = { r, g, b, a }
                                            info.handler:UpdateCooldownSwipeColor()
                                            local layoutdb = info.handler.layoutdb
                                            if layoutdb and layoutdb.dr then
                                                info.handler:UpdateDRSettings(layoutdb.dr)
                                            end
                                            if isMidnight then
                                                info.handler:RefreshAuraDisplays()
                                            end
                                        end,
                                    },
                                    disableSwipeEdge = {
                                        order = 0,
                                        name = L["Option_DisableCooldownSwipeEdge"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Cooldown_DisableBrightEdge_Desc"],
                                        get = function(info) return info.handler.db.profile.disableSwipeEdge end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableSwipeEdge = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateSwipeEdgeSettings()
                                            end
                                            -- Update DR settings for current layout
                                            local currentLayout = info.handler.db.profile.currentLayout
                                            if currentLayout and info.handler.db.profile.layoutSettings[currentLayout] then
                                                local drSettings = info.handler.db.profile.layoutSettings[currentLayout].dr
                                                if drSettings then
                                                    info.handler:UpdateDRSettings(drSettings, info)
                                                end
                                            end
                                            if isMidnight then
                                                info.handler:RefreshAuraDisplays()
                                            end
                                        end,
                                    },
                                    disableClassIconSwipe = {
                                        order = 1,
                                        name = L["Option_DisableClassIconSwipe"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Cooldown_DisableClassIconSwipe_Desc"],
                                        get = function(info) return info.handler.db.profile.disableClassIconSwipe end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableClassIconSwipe = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateClassIconSwipeSettings()
                                            end
                                            if isMidnight then
                                                info.handler:RefreshAuraDisplays()
                                            end
                                        end,
                                    },
                                    disableDRSwipe = {
                                        order = 2,
                                        name = L["Option_DisableDRSwipeAnimation"],
                                        desc = L["Cooldown_DisableDRSwipe_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info)
                                            return info.handler.db.profile.disableDRSwipe
                                        end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableDRSwipe = val
                                            -- Update DR settings for current layout
                                            local currentLayout = info.handler.db.profile.currentLayout
                                            if currentLayout and info.handler.db.profile.layoutSettings[currentLayout] then
                                                local drSettings = info.handler.db.profile.layoutSettings[currentLayout].dr
                                                if drSettings then
                                                    info.handler:UpdateDRSettings(drSettings, info)
                                                end
                                            end
                                        end,
                                    },
                                    disableTrinketRacialSwipe = {
                                        order = 3,
                                        name = L["Option_DisableTrinketRacialSwipe"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Cooldown_DisableTrinketRacialSwipe_Desc"],
                                        get = function(info) return info.handler.db.profile.disableTrinketRacialSwipe end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableTrinketRacialSwipe = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateTrinketRacialSwipeSettings()
                                            end
                                        end,
                                    },
                                    invertClassIconCooldown = {
                                        order = 4,
                                        name = L["Option_ReverseClassIconSwipe"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Cooldown_ReverseClassIcon_Desc"],
                                        disabled = function(info) return info.handler.db.profile.disableClassIconSwipe end,
                                        get = function(info) return info.handler.db.profile.invertClassIconCooldown end,
                                        set = function(info, val)
                                            info.handler.db.profile.invertClassIconCooldown = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateClassIconCooldownReverse()
                                            end
                                            if isMidnight then
                                                info.handler:RefreshAuraDisplays()
                                            end
                                        end,
                                    },
                                    invertDRCooldown = {
                                        order = 5,
                                        name = L["Option_ReverseDRSwipeAnimation"],
                                        desc = L["Cooldown_ReverseDR_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        disabled = function(info) return info.handler.db.profile.drSwipeOff end,
                                        get = function(info) return info.handler.db.profile.invertDRCooldown end,
                                        set = function(info, val)
                                            info.handler.db.profile.invertDRCooldown = val
                                            -- Update DR settings which now handles cooldown reverse
                                            local layoutdb = info.handler.layoutdb
                                            if layoutdb and layoutdb.dr then
                                                info.handler:UpdateDRSettings(layoutdb.dr)
                                            end
                                        end
                                    },
                                    invertTrinketRacialCooldown = {
                                        order = 6,
                                        name = L["Option_ReverseTrinketRacialSwipe"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Cooldown_ReverseTrinketRacial_Desc"],
                                        disabled = function(info) return info.handler.db.profile.disableTrinketRacialSwipe end,
                                        get = function(info) return info.handler.db.profile.invertTrinketRacialCooldown end,
                                        set = function(info, val)
                                            info.handler.db.profile.invertTrinketRacialCooldown = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                info.handler["arena" .. i]:UpdateTrinketRacialCooldownReverse()
                                            end
                                        end,
                                    },
                                    disableCDTextClassIcon = {
                                        order = 7,
                                        name = L["Option_DisableCDTextClassIcon"],
                                        desc = L["Option_DisableCDTextClassIcon_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.disableCDTextClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableCDTextClassIcon = val
                                            info.handler:UpdateCDTextVisibility()
                                        end,
                                    },
                                    disableCDTextDR = {
                                        order = 8,
                                        name = L["Option_DisableCDTextDR"],
                                        desc = L["Option_DisableCDTextDR_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.disableCDTextDR end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableCDTextDR = val
                                            info.handler:UpdateCDTextVisibility()
                                        end,
                                    },
                                    disableCDTextTrinket = {
                                        order = 9,
                                        name = L["Option_DisableCDTextTrinket"],
                                        desc = L["Option_DisableCDTextTrinket_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.disableCDTextTrinket end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableCDTextTrinket = val
                                            info.handler:UpdateCDTextVisibility()
                                        end,
                                    },
                                    disableCDTextRacial = {
                                        order = 10,
                                        name = L["Option_DisableCDTextRacial"],
                                        desc = L["Option_DisableCDTextRacial_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.disableCDTextRacial end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableCDTextRacial = val
                                            info.handler:UpdateCDTextVisibility()
                                        end,
                                    },
                                },
                            },
                            masque = {
                                order = 8,
                                name = L["Option_Miscellaneous"],
                                type = "group",
                                inline = true,
                                args = {
                                    enableMasque = {
                                        order = 1,
                                        name = L["Option_EnableMasqueSupport"],
                                        desc = L["Masque_Support_Desc"],
                                        type = "toggle",
                                        width = 1,
                                        get = function(info) return info.handler.db.profile.enableMasque end,
                                        set = function(info, val)
                                            info.handler.db.profile.enableMasque = val
                                            info.handler:AddMasqueSupport()
                                            info.handler:Test()
                                        end
                                    },
                                    enableMasqueExtra = {
                                        order = 1.2,
                                        name = L["Option_EnableMasqueExtraSupport"],
                                        desc = L["Masque_Extra_Support_Desc"],
                                        type = "toggle",
                                        width = "normal",
                                        disabled = function(info) return not info.handler.db.profile.enableMasque end,
                                        confirm = function(info, val) info.handler.db.profile.enableMasqueExtra = val; return L["Masque_Extra_Reload_Desc"] end,
                                        get = function(info) return info.handler.db.profile.enableMasqueExtra end,
                                        set = function(info, val)
                                            info.handler.db.profile.enableMasqueExtra = val
                                            sArena_ReloadedDB.reOpenOptions = true
                                            ReloadUI()
                                        end
                                    },
                                    removeUnequippedTrinketTexture = {
                                        order = 2,
                                        name = L["Option_RemoveUnEquippedTrinketTexture"],
                                        desc = L["Trinket_HideWhenNoTrinket_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.removeUnequippedTrinketTexture end,
                                        set = function(info, val)
                                            info.handler.db.profile.removeUnequippedTrinketTexture = val
                                            info.handler:UpdateNoTrinketTexture()
                                        end
                                    },
                                    desaturateTrinketCD = {
                                        order = 2.1,
                                        name = L["Option_DesaturateTrinketCD"],
                                        desc = L["Trinket_DesaturateOnCD_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.desaturateTrinketCD end,
                                        set = function(info, val)
                                            info.handler.db.profile.desaturateTrinketCD = val
                                        end
                                    },
                                    desaturateDispelCD = {
                                        order = 2.2,
                                        name = L["Option_DesaturateDispelCD"],
                                        desc = L["Dispel_DesaturateOnCD_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.desaturateDispelCD end,
                                        set = function(info, val)
                                            info.handler.db.profile.desaturateDispelCD = val
                                        end
                                    },
                                    disableOvershields = {
                                        order = 2.3,
                                        name = L["Option_DisableOvershields"],
                                        desc = L["Option_DisableOvershields_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.disableOvershields end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableOvershields = val
                                        end
                                    },
                                    gladTracker = {
                                        order = 2.4,
                                        name = L["Option_GladTracker"],
                                        desc = L["Option_GladTracker_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.gladTracker end,
                                        set = function(info, val)
                                            info.handler.db.profile.gladTracker = val
                                            info.handler:GladTracker()
                                        end
                                    },
                                    useDefaultPartyFrames = {
                                        order = 2.5,
                                        name = L["Option_UseDefaultPartyFrames"],
                                        desc = L["Option_UseDefaultPartyFrames_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.useDefaultPartyFrames end,
                                        set = function(info, val)
                                            info.handler.db.profile.useDefaultPartyFrames = val
                                            info.handler:UpdatePartyFrameReferences()
                                        end
                                    },
                                },
                            },
                        },
                    },
                    petFramesGroup = {
                        order = 5.5,
                        name = L["Category_PetFrames"],
                        desc = L["Category_PetFrames_Desc"],
                        type = "group",
                        get = function(info)
                            return info.handler.db.profile.petFrames[info[#info]]
                        end,
                        set = function(info, val)
                            info.handler.db.profile.petFrames[info[#info]] = val
                            if info.handler.RefreshPetFrames then
                                info.handler:RefreshPetFrames()
                            end
                        end,
                        args = {
                            enabled = {
                                order = 1,
                                name = L["Option_PetEnabled"],
                                desc = L["Option_PetEnabled_Desc"],
                                type = "toggle",
                            },
                            classesGroup = {
                                order = 2,
                                name = L["Option_PetClassesEnabled"],
                                type = "group",
                                inline = true,
                                args = {
                                    classDeathknight = {
                                        order = 1,
                                        name = GetClassOptionName("DEATHKNIGHT"),
                                        type = "toggle",
                                        hidden = function() return sArenaMixin.isTBC end,
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        get = function(info) return info.handler.db.profile.petFrames.classes.DEATHKNIGHT end,
                                        set = function(info, val)
                                            info.handler.db.profile.petFrames.classes.DEATHKNIGHT = val
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                    classMage = {
                                        order = 2,
                                        name = GetClassOptionName("MAGE"),
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        get = function(info) return info.handler.db.profile.petFrames.classes.MAGE end,
                                        set = function(info, val)
                                            info.handler.db.profile.petFrames.classes.MAGE = val
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                    classMonk = {
                                        order = 3,
                                        name = GetClassOptionName("MONK"),
                                        type = "toggle",
                                        hidden = function() return sArenaMixin.isTBC or sArenaMixin.isWrath end,
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        get = function(info) return info.handler.db.profile.petFrames.classes.MONK end,
                                        set = function(info, val)
                                            info.handler.db.profile.petFrames.classes.MONK = val
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                    classWarlock = {
                                        order = 4,
                                        name = GetClassOptionName("WARLOCK"),
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        get = function(info) return info.handler.db.profile.petFrames.classes.WARLOCK end,
                                        set = function(info, val)
                                            info.handler.db.profile.petFrames.classes.WARLOCK = val
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                    classHunter = {
                                        order = 5,
                                        name = GetClassOptionName("HUNTER"),
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        get = function(info) return info.handler.db.profile.petFrames.classes.HUNTER end,
                                        set = function(info, val)
                                            info.handler.db.profile.petFrames.classes.HUNTER = val
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                },
                            },
                            colorsGroup = {
                                order = 3,
                                name = L["Option_Colors"],
                                type = "group",
                                inline = true,
                                args = {
                                    classColors = {
                                        order = 1,
                                        name = L["Option_PetClassColors"],
                                        desc = L["Option_PetClassColors_Desc"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                    },
                                    spacerAfterClassColors = {
                                        order = 1.5,
                                        name = "",
                                        type = "description",
                                        width = "full",
                                    },
                                    customColor = {
                                        order = 2,
                                        name = L["Option_PetCustomColor"],
                                        type = "color",
                                        hasAlpha = true,
                                        disabled = function(info)
                                            return not info.handler.db.profile.petFrames.enabled
                                                or info.handler.db.profile.petFrames.classColors
                                        end,
                                        get = function(info)
                                            local c = info.handler.db.profile.petFrames.customColor
                                            return c[1], c[2], c[3], c[4] or 1
                                        end,
                                        set = function(info, r, g, b, a)
                                            info.handler.db.profile.petFrames.customColor = { r, g, b, a }
                                            info.handler:RefreshPetFrameSettings()
                                        end,
                                    },
                                },
                            },
                            displayGroup = {
                                order = 4,
                                name = L["Option_PetDisplay"],
                                type = "group",
                                inline = true,
                                args = {
                                    showPetName = {
                                        order = 1,
                                        name = L["Option_ShowPetName"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        get = function(info) return info.handler.db.profile.petFrames.showPetName end,
                                        set = function(info, val)
                                            info.handler.db.profile.petFrames.showPetName = val
                                            if val then
                                                info.handler.db.profile.petFrames.showPetNumber = false
                                            end
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                    spacerAfterShowPetName = {
                                        order = 1.5,
                                        name = "",
                                        type = "description",
                                        width = "full",
                                    },
                                    showPetNumber = {
                                        order = 2,
                                        name = L["Option_ShowPetNumber"],
                                        type = "toggle",
                                        width = 1,
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        get = function(info) return info.handler.db.profile.petFrames.showPetNumber end,
                                        set = function(info, val)
                                            info.handler.db.profile.petFrames.showPetNumber = val
                                            if val then
                                                info.handler.db.profile.petFrames.showPetName = false
                                            end
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                    petNumberIdOnly = {
                                        order = 3,
                                        name = L["Option_PetNumberIdOnly"],
                                        type = "toggle",
                                        width = 1,
                                        disabled = function(info)
                                            return not info.handler.db.profile.petFrames.enabled
                                                or not info.handler.db.profile.petFrames.showPetNumber
                                        end,
                                        get = function(info) return info.handler.db.profile.petFrames.petNumberIdOnly end,
                                        set = function(info, val)
                                            info.handler.db.profile.petFrames.petNumberIdOnly = val
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                    spacerBeforeBorderStyle = {
                                        order = 3.5,
                                        name = "",
                                        type = "description",
                                        width = "full",
                                    },
                                    borderStyle = {
                                        order = 4,
                                        name = L["Option_PetBorderStyle"],
                                        desc = L["Option_PetBorderStyle_Desc"],
                                        type = "select",
                                        style = "dropdown",
                                        width = 1,
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        values = {
                                            layoutBorders = L["Option_PetBorderStyle_LayoutBorders"],
                                            pixelBorder   = L["Option_PetBorderStyle_PixelBorder"],
                                            modernBorder  = L["Option_PetBorderStyle_ModernBorder"],
                                            classicBorder = L["Option_PetBorderStyle_ClassicBorder"],
                                            none          = L["None"],
                                        },
                                        sorting = {
                                            "layoutBorders",
                                            "pixelBorder",
                                            "modernBorder",
                                            "classicBorder",
                                            "none",
                                        },
                                        get = function(info)
                                            return info.handler.db.profile.petFrames.borderStyle or "layoutBorders"
                                        end,
                                        set = function(info, val)
                                            info.handler.db.profile.petFrames.borderStyle = val
                                            info.handler:RefreshPetFrameSettings()
                                        end,
                                    },
                                },
                            },
                            statusTextGroup = {
                                order = 5,
                                name = L["Option_StatusText"],
                                type = "group",
                                inline = true,
                                args = {
                                    alwaysShow = {
                                        order = 1,
                                        name = L["Option_AlwaysShow"],
                                        desc = L["Text_ShowOnMouseover_Desc"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        get = function(info)
                                            local petSt = info.handler.db.profile.petFrames.statusText
                                            if petSt ~= nil and petSt.alwaysShow ~= nil then
                                                return petSt.alwaysShow
                                            end
                                            return info.handler.db.profile.statusText.alwaysShow
                                        end,
                                        set = function(info, val)
                                            local pf = info.handler.db.profile.petFrames
                                            pf.statusText = pf.statusText or {}
                                            pf.statusText.alwaysShow = val
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                    usePercentage = {
                                        order = 2,
                                        name = L["Option_UsePercentage"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        get = function(info)
                                            local petSt = info.handler.db.profile.petFrames.statusText
                                            if petSt ~= nil and petSt.usePercentage ~= nil then
                                                return petSt.usePercentage
                                            end
                                            return info.handler.db.profile.statusText.usePercentage
                                        end,
                                        set = function(info, val)
                                            local pf = info.handler.db.profile.petFrames
                                            pf.statusText = pf.statusText or {}
                                            pf.statusText.usePercentage = val
                                            if val then
                                                pf.statusText.formatNumbers = false
                                            end
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                    formatNumbers = {
                                        order = 3,
                                        name = L["Option_FormatNumbers"],
                                        desc = L["Text_FormatLargeNumbers_Desc"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.petFrames.enabled end,
                                        get = function(info)
                                            local petSt = info.handler.db.profile.petFrames.statusText
                                            if petSt ~= nil and petSt.formatNumbers ~= nil then
                                                return petSt.formatNumbers
                                            end
                                            if petSt ~= nil and petSt.usePercentage then
                                                return false
                                            end
                                            return info.handler.db.profile.statusText.formatNumbers
                                        end,
                                        set = function(info, val)
                                            local pf = info.handler.db.profile.petFrames
                                            pf.statusText = pf.statusText or {}
                                            pf.statusText.formatNumbers = val
                                            if val then
                                                pf.statusText.usePercentage = false
                                            end
                                            info.handler:RefreshPetFrames()
                                        end,
                                    },
                                },
                            },
                        },
                    },
                    auraHighlightGroup = {
                        order = 2,
                        name = L["AuraHighlight"],
                        desc = L["AuraHighlight_TabDesc"],
                        type = "group",
                        get = function(info)
                            local ah = info.handler.db.profile.auraHighlight
                            return ah and ah[info[#info]]
                        end,
                        set = function(info, val)
                            local profile = info.handler.db.profile
                            profile.auraHighlight = profile.auraHighlight or {}
                            profile.auraHighlight[info[#info]] = val
                            info.handler:RefreshAllAuraHighlights()
                        end,
                        args = {
                            enable = {
                                order = 1,
                                name = L["AuraHighlight_Enable"],
                                desc = L["AuraHighlight_Desc"],
                                type = "toggle",
                                width = "normal",
                                get = function(info)
                                    local ah = info.handler.db.profile.auraHighlight
                                    return ah and ah.enabled
                                end,
                                set = function(info, val)
                                    local profile = info.handler.db.profile
                                    profile.auraHighlight = profile.auraHighlight or {}
                                    profile.auraHighlight.enabled = val
                                    info.handler:RefreshAllAuraHighlights()
                                end,
                            },
                            onlyOnHealer = {
                                order = 1.1,
                                name = L["AuraHighlight_OnlyOnHealer"],
                                desc = L["AuraHighlight_OnlyOnHealer_Desc"],
                                type = "toggle",
                                width = "normal",
                                disabled = function(info)
                                    local ah = info.handler.db.profile.auraHighlight
                                    return not (ah and ah.enabled)
                                end,
                                get = function(info)
                                    local ah = info.handler.db.profile.auraHighlight
                                    return ah and ah.onlyOnHealer
                                end,
                                set = function(info, val)
                                    local profile = info.handler.db.profile
                                    profile.auraHighlight = profile.auraHighlight or {}
                                    profile.auraHighlight.onlyOnHealer = val
                                    info.handler:RefreshAllAuraHighlights()
                                end,
                            },
                            categoriesGroup = {
                                order = 2,
                                name = L["AuraHighlight_Categories"],
                                type = "group",
                                inline = true,
                                args = (function()
                                    local args = {}
                                    local cats = {
                                        { key = "cc",        order = 1, label = "AuraHighlight_CC",        desc = "AuraHighlight_CC_Desc",        defaultColor = {1, 0.87, 0,    1} },
                                        { key = "important", order = 2, label = "AuraHighlight_Important", desc = "AuraHighlight_Important_Desc", defaultColor = {0, 1,    0,    1} },
                                        { key = "defensive", order = 3, label = "AuraHighlight_Defensive", desc = "AuraHighlight_Defensive_Desc", defaultColor = {1, 0.66, 0.95, 1} },
                                    }
                                    for _, cat in ipairs(cats) do
                                        local key = cat.key
                                        args[key .. "Enabled"] = {
                                            order = cat.order * 10,
                                            name = L[cat.label],
                                            desc = L[cat.desc],
                                            type = "toggle",
                                            width = 0.7,
                                            disabled = function(info)
                                                local ah = info.handler.db.profile.auraHighlight
                                                return not (ah and ah.enabled)
                                            end,
                                            get = function(info)
                                                local ah = info.handler.db.profile.auraHighlight
                                                local c = ah and ah[key]
                                                return c and c.enabled
                                            end,
                                            set = function(info, val)
                                                local profile = info.handler.db.profile
                                                profile.auraHighlight = profile.auraHighlight or {}
                                                profile.auraHighlight[key] = profile.auraHighlight[key] or {}
                                                profile.auraHighlight[key].enabled = val
                                                info.handler:RefreshAllAuraHighlights()
                                            end,
                                        }
                                        args[key .. "Color"] = {
                                            order = cat.order * 10 + 1,
                                            name = L["Color"],
                                            type = "color",
                                            hasAlpha = true,
                                            width = 0.5,
                                            disabled = function(info)
                                                local ah = info.handler.db.profile.auraHighlight
                                                return not (ah and ah.enabled)
                                            end,
                                            get = function(info)
                                                local ah = info.handler.db.profile.auraHighlight
                                                local c = ah and ah[key] and ah[key].color
                                                c = c or cat.defaultColor
                                                return c[1], c[2], c[3], c[4] or 1
                                            end,
                                            set = function(info, r, g, b, a)
                                                local profile = info.handler.db.profile
                                                profile.auraHighlight = profile.auraHighlight or {}
                                                profile.auraHighlight[key] = profile.auraHighlight[key] or {}
                                                profile.auraHighlight[key].color = {r, g, b, a}
                                                info.handler:RefreshAllAuraHighlights()
                                            end,
                                        }
                                        args[key .. "Spacer"] = {
                                            order = cat.order * 10 + 2,
                                            name = "",
                                            type = "description",
                                            width = "full",
                                        }
                                    end
                                    return args
                                end)(),
                            },
                            glowClassIconGroup = {
                                order = 3,
                                name = L["AuraHighlight_GlowClassIcon"],
                                type = "group",
                                inline = true,
                                args = {
                                    enabled = {
                                        order = 1,
                                        name = L["AuraHighlight_GlowClassIcon_Enable"],
                                        desc = L["AuraHighlight_GlowClassIcon_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            return not (ah and ah.enabled)
                                        end,
                                        get = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local g = ah and ah.glowClassIcon
                                            return g and g.enabled
                                        end,
                                        set = function(info, val)
                                            local profile = info.handler.db.profile
                                            profile.auraHighlight = profile.auraHighlight or {}
                                            profile.auraHighlight.glowClassIcon = profile.auraHighlight.glowClassIcon or {}
                                            profile.auraHighlight.glowClassIcon.enabled = val
                                            info.handler:RefreshAllAuraHighlights()
                                        end,
                                    },
                                },
                            },
                            pixelBorderGroup = {
                                order = 4,
                                name = L["AuraHighlight_PixelBorder"],
                                type = "group",
                                inline = true,
                                hidden = function() return isMidnight end,
                                get = function(info)
                                    local ah = info.handler.db.profile.auraHighlight
                                    local p = ah and ah.pixelBorder
                                    return p and p[info[#info]]
                                end,
                                set = function(info, val)
                                    local profile = info.handler.db.profile
                                    profile.auraHighlight = profile.auraHighlight or {}
                                    profile.auraHighlight.pixelBorder = profile.auraHighlight.pixelBorder or {}
                                    profile.auraHighlight.pixelBorder[info[#info]] = val
                                    info.handler:RefreshAllAuraHighlights()
                                end,
                                args = {
                                    enabled = {
                                        order = 1,
                                        name = L["AuraHighlight_PixelBorder_Enable"],
                                        desc = L["AuraHighlight_PixelBorder_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            return not (ah and ah.enabled)
                                        end,
                                    },
                                    lines = {
                                        order = 2,
                                        name = L["AuraHighlight_Lines"],
                                        type = "range",
                                        min = 1, max = 30, step = 1,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pb = ah and ah.pixelBorder
                                            return not (ah and ah.enabled and pb and pb.enabled)
                                        end,
                                    },
                                    frequency = {
                                        order = 3,
                                        name = L["AuraHighlight_Speed"],
                                        type = "range",
                                        min = -1, max = 1, step = 0.01,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pb = ah and ah.pixelBorder
                                            return not (ah and ah.enabled and pb and pb.enabled)
                                        end,
                                    },
                                    length = {
                                        order = 4,
                                        name = L["AuraHighlight_Length"],
                                        type = "range",
                                        min = 1, max = 30, step = 1,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pb = ah and ah.pixelBorder
                                            return not (ah and ah.enabled and pb and pb.enabled)
                                        end,
                                    },
                                    thickness = {
                                        order = 5,
                                        name = L["AuraHighlight_Thickness"],
                                        type = "range",
                                        min = 1, max = 20, step = 1,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pb = ah and ah.pixelBorder
                                            return not (ah and ah.enabled and pb and pb.enabled)
                                        end,
                                    },
                                    wrapClass = {
                                        order = 6,
                                        name = L["Widget_WrapClass"],
                                        desc = L["Widget_WrapClass_Desc"],
                                        type = "toggle",
                                        width = 0.6,
                                        get = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pb = ah and ah.pixelBorder
                                            return pb and pb.wrapClass
                                        end,
                                        set = function(info, val)
                                            local profile = info.handler.db.profile
                                            profile.auraHighlight = profile.auraHighlight or {}
                                            profile.auraHighlight.pixelBorder = profile.auraHighlight.pixelBorder or {}
                                            profile.auraHighlight.pixelBorder.wrapClass = val
                                            info.handler:RefreshAllAuraHighlights()
                                        end,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pb = ah and ah.pixelBorder
                                            return not (ah and ah.enabled and pb and pb.enabled)
                                        end,
                                    },
                                    wrapTrinket = {
                                        order = 7,
                                        name = L["Widget_WrapTrinket"],
                                        desc = L["Widget_WrapTrinket_Desc"],
                                        type = "toggle",
                                        width = 0.6,
                                        get = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pb = ah and ah.pixelBorder
                                            return pb and pb.wrapTrinket
                                        end,
                                        set = function(info, val)
                                            local profile = info.handler.db.profile
                                            profile.auraHighlight = profile.auraHighlight or {}
                                            profile.auraHighlight.pixelBorder = profile.auraHighlight.pixelBorder or {}
                                            profile.auraHighlight.pixelBorder.wrapTrinket = val
                                            if val then profile.auraHighlight.pixelBorder.wrapRacial = false end
                                            info.handler:RefreshAllAuraHighlights()
                                        end,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pb = ah and ah.pixelBorder
                                            return not (ah and ah.enabled and pb and pb.enabled)
                                        end,
                                    },
                                    wrapRacial = {
                                        order = 8,
                                        name = L["Widget_WrapRacial"],
                                        desc = L["Widget_WrapRacial_Desc"],
                                        type = "toggle",
                                        width = 0.6,
                                        get = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pb = ah and ah.pixelBorder
                                            return pb and pb.wrapRacial
                                        end,
                                        set = function(info, val)
                                            local profile = info.handler.db.profile
                                            profile.auraHighlight = profile.auraHighlight or {}
                                            profile.auraHighlight.pixelBorder = profile.auraHighlight.pixelBorder or {}
                                            profile.auraHighlight.pixelBorder.wrapRacial = val
                                            if val then profile.auraHighlight.pixelBorder.wrapTrinket = false end
                                            info.handler:RefreshAllAuraHighlights()
                                        end,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pb = ah and ah.pixelBorder
                                            return not (ah and ah.enabled and pb and pb.enabled)
                                        end,
                                    },
                                },
                            },
                            framePulseGroup = {
                                order = 6,
                                name = L["AuraHighlight_FramePulse"],
                                type = "group",
                                inline = true,
                                get = function(info)
                                    local ah = info.handler.db.profile.auraHighlight
                                    local p = ah and ah.framePulse
                                    return p and p[info[#info]]
                                end,
                                set = function(info, val)
                                    local profile = info.handler.db.profile
                                    profile.auraHighlight = profile.auraHighlight or {}
                                    profile.auraHighlight.framePulse = profile.auraHighlight.framePulse or {}
                                    profile.auraHighlight.framePulse[info[#info]] = val
                                    info.handler:RefreshAllAuraHighlights()
                                end,
                                args = {
                                    enabled = {
                                        order = 1,
                                        name = L["AuraHighlight_FramePulse_Enable"],
                                        desc = L["AuraHighlight_FramePulse_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            return not (ah and ah.enabled)
                                        end,
                                    },
                                    speed = {
                                        order = 2,
                                        name = L["AuraHighlight_Speed"],
                                        type = "range",
                                        min = 0.05, max = 1, step = 0.05,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local fp = ah and ah.framePulse
                                            return not (ah and ah.enabled and fp and fp.enabled)
                                        end,
                                    },
                                    size = {
                                        order = 2.5,
                                        name = L["AuraHighlight_FramePulse_Size"],
                                        type = "range",
                                        min = 0.5, max = 4, step = 0.5,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local fp = ah and ah.framePulse
                                            return not (ah and ah.enabled and fp and fp.enabled)
                                        end,
                                    },
                                    minAlpha = {
                                        order = 2.6,
                                        name = L["AuraHighlight_FramePulse_MinAlpha"],
                                        type = "range",
                                        min = 0, max = 1, step = 0.05,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local fp = ah and ah.framePulse
                                            return not (ah and ah.enabled and fp and fp.enabled)
                                        end,
                                    },
                                    maxAlpha = {
                                        order = 2.7,
                                        name = L["AuraHighlight_FramePulse_MaxAlpha"],
                                        type = "range",
                                        min = 0, max = 1, step = 0.05,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local fp = ah and ah.framePulse
                                            return not (ah and ah.enabled and fp and fp.enabled)
                                        end,
                                    },
                                    wrapTrinket = {
                                        order = 3,
                                        name = L["Widget_WrapTrinket"],
                                        desc = L["Widget_WrapTrinket_Desc"],
                                        type = "toggle",
                                        width = 0.6,
                                        get = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local fp = ah and ah.framePulse
                                            return fp and fp.wrapTrinket
                                        end,
                                        set = function(info, val)
                                            local profile = info.handler.db.profile
                                            profile.auraHighlight = profile.auraHighlight or {}
                                            profile.auraHighlight.framePulse = profile.auraHighlight.framePulse or {}
                                            profile.auraHighlight.framePulse.wrapTrinket = val
                                            if val then profile.auraHighlight.framePulse.wrapRacial = false end
                                            info.handler:RefreshAllAuraHighlights()
                                        end,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local fp = ah and ah.framePulse
                                            return not (ah and ah.enabled and fp and fp.enabled)
                                        end,
                                    },
                                    wrapRacial = {
                                        order = 4,
                                        name = L["Widget_WrapRacial"],
                                        desc = L["Widget_WrapRacial_Desc"],
                                        type = "toggle",
                                        width = 0.6,
                                        get = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local fp = ah and ah.framePulse
                                            return fp and fp.wrapRacial
                                        end,
                                        set = function(info, val)
                                            local profile = info.handler.db.profile
                                            profile.auraHighlight = profile.auraHighlight or {}
                                            profile.auraHighlight.framePulse = profile.auraHighlight.framePulse or {}
                                            profile.auraHighlight.framePulse.wrapRacial = val
                                            if val then profile.auraHighlight.framePulse.wrapTrinket = false end
                                            info.handler:RefreshAllAuraHighlights()
                                        end,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local fp = ah and ah.framePulse
                                            return not (ah and ah.enabled and fp and fp.enabled)
                                        end,
                                    },
                                },
                            },
                            pixelClassIconGroup = {
                                order = 5,
                                name = L["AuraHighlight_PixelClassIcon"],
                                type = "group",
                                inline = true,
                                hidden = function() return isMidnight end,
                                get = function(info)
                                    local ah = info.handler.db.profile.auraHighlight
                                    local p = ah and ah.pixelClassIcon
                                    return p and p[info[#info]]
                                end,
                                set = function(info, val)
                                    local profile = info.handler.db.profile
                                    profile.auraHighlight = profile.auraHighlight or {}
                                    profile.auraHighlight.pixelClassIcon = profile.auraHighlight.pixelClassIcon or {}
                                    profile.auraHighlight.pixelClassIcon[info[#info]] = val
                                    info.handler:RefreshAllAuraHighlights()
                                end,
                                args = {
                                    enabled = {
                                        order = 1,
                                        name = L["AuraHighlight_PixelClassIcon_Enable"],
                                        desc = L["AuraHighlight_PixelClassIcon_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            return not (ah and ah.enabled)
                                        end,
                                    },
                                    lines = {
                                        order = 2,
                                        name = L["AuraHighlight_Lines"],
                                        type = "range",
                                        min = 1, max = 30, step = 1,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pi = ah and ah.pixelClassIcon
                                            return not (ah and ah.enabled and pi and pi.enabled)
                                        end,
                                    },
                                    frequency = {
                                        order = 3,
                                        name = L["AuraHighlight_Speed"],
                                        type = "range",
                                        min = -2, max = 2, step = 0.05,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pi = ah and ah.pixelClassIcon
                                            return not (ah and ah.enabled and pi and pi.enabled)
                                        end,
                                    },
                                    length = {
                                        order = 4,
                                        name = L["AuraHighlight_Length"],
                                        type = "range",
                                        min = 1, max = 30, step = 1,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pi = ah and ah.pixelClassIcon
                                            return not (ah and ah.enabled and pi and pi.enabled)
                                        end,
                                    },
                                    thickness = {
                                        order = 5,
                                        name = L["AuraHighlight_Thickness"],
                                        type = "range",
                                        min = 1, max = 20, step = 1,
                                        disabled = function(info)
                                            local ah = info.handler.db.profile.auraHighlight
                                            local pi = ah and ah.pixelClassIcon
                                            return not (ah and ah.enabled and pi and pi.enabled)
                                        end,
                                    },
                                },
                            },
                        },
                    },
                    classIconGroup = {
                        order = 3,
                        name = L["Category_ClassIcon"],
                        type = "group",
                        args = {
                            options = {
                                order = 1,
                                name = L["Options"],
                                type = "group",
                                inline = true,
                                args = {
                                    onlyShowAuras = {
                                        order = 1,
                                        name = L["Option_HideClassIconShowAurasOnly"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["ClassIcon_HideAndShowOnlyAuras_Desc"],
                                        disabled = function(info) return info.handler.db.profile.hideClassIcon end,
                                        get = function(info) return info.handler.db.profile.onlyShowAuras end,
                                        set = function(info, val)
                                            info.handler.db.profile.onlyShowAuras = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                if val then
                                                    info.handler["arena" .. i].ClassIcon.Texture:SetTexture(nil)
                                                else
                                                    if info.handler["arena" .. i].replaceClassIcon then
                                                        info.handler["arena" .. i].ClassIcon.Texture:SetTexture(info.handler["arena" .. i].tempSpecIcon)
                                                    else
                                                        info.handler["arena" .. i].ClassIcon.Texture:SetTexture(info.handler.classIcons[info.handler["arena" .. i].tempClass])
                                                    end
                                                end
                                            end
                                            info.handler:Test()
                                        end,
                                    },
                                    onlyShowCCAuras = {
                                        order = 2.5,
                                        name = L["Option_OnlyShowCCAuras"],
                                        type = "toggle",
                                        width = "full",
                                        disabled = function(info) return info.handler.db.profile.hideClassIcon or info.handler.db.profile.disableAurasOnClassIcon end,
                                        get = function(info) return info.handler.db.profile.onlyShowCCAuras end,
                                        set = function(info, val)
                                            info.handler.db.profile.onlyShowCCAuras = val
                                            info.handler:Test()
                                        end,
                                    },
                                    disableAurasOnClassIcon = {
                                        order = 3,
                                        name = L["Option_DisableAurasOnClassIcon"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["ClassIcon_DontShowAuras_Desc"],
                                        disabled = function(info) return info.handler.db.profile.hideClassIcon end,
                                        get = function(info) return info.handler.db.profile.disableAurasOnClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableAurasOnClassIcon = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if frame then
                                                    frame:SetUnitAuraRegistration()
                                                end
                                            end
                                            info.handler:Test()
                                        end,
                                    },
                                    replaceHealerIcon = {
                                        order = 4,
                                        name = L["Option_ReplaceHealerIcon"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Icon_ReplaceHealerWithHealerIcon_Desc"],
                                        get = function(info) return info.handler.db.profile.replaceHealerIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.replaceHealerIcon = val
                                            info.handler:Test()
                                        end,
                                    },
                                    hideClassIcon = {
                                        order = 5,
                                        name = L["Option_HideClassIcon"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Option_HideClassIcon_Desc"],
                                        get = function(info) return info.handler.db.profile.hideClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.hideClassIcon = val
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if frame then
                                                    frame:SetUnitAuraRegistration()
                                                    if val then
                                                        frame.ClassIcon.Texture:SetTexture(nil)
                                                        frame.ClassIcon.Cooldown:Clear()
                                                    end
                                                end
                                            end
                                            info.handler:Test()
                                        end,
                                    },
                                    showDecimalsClassIcon = {
                                        order = 6,
                                        name = L["Option_ShowDecimalsOnClassIcon"],
                                        desc = L["Option_ShowDecimalsOnClassIcon_Desc"],
                                        type = "toggle",
                                        width = 1.4,
                                        confirm = function() return isMidnight and L["Option_HideDRs_Reload_Desc"] or false end,
                                        get = function(info) return info.handler.db.profile.showDecimalsClassIcon end,
                                        set = function(info, val)
                                            info.handler.db.profile.showDecimalsClassIcon = val
                                            info.handler:SetupCustomCD()
                                            if isMidnight then
                                                sArena_ReloadedDB.reOpenOptions = true
                                                ReloadUI()
                                            end
                                        end
                                    },
                                    decimalThreshold = {
                                        order = 7,
                                        name = L["Option_DecimalThreshold"],
                                        desc = L["Cooldown_ShowDecimalsThreshold_Desc"],
                                        type = "range",
                                        min = 1,
                                        max = 10,
                                        step = 0.1,
                                        width = 0.75,
                                        disabled = function(info) return not info.handler.db.profile.showDecimalsClassIcon end,
                                        get = function(info) return info.handler.db.profile.decimalThreshold or 6 end,
                                        set = function(info, val)
                                            info.handler.db.profile.decimalThreshold = val
                                            info.handler:UpdateDecimalThreshold()
                                            info.handler:SetupCustomCD()
                                        end
                                    },
                                },
                            },
                            sorting = {
                                order = 2,
                                name = L["AuraSort_Sorting"],
                                type = "group",
                                inline = true,
                                hidden = not isMidnight,
                                args = {
                                    ccSort = {
                                        order = 1,
                                        name = L["AuraSort_CC_Sort"],
                                        type = "select",
                                        width = 1.5,
                                        values = {
                                            last = L["AuraSort_LastAdded"],
                                            blizzDefault = L["AuraSort_Default"],
                                            lastending = L["AuraSort_LastEnding"],
                                            firstending = L["AuraSort_FirstEnding"],
                                        },
                                        sorting = { "last", "blizzDefault", "lastending", "firstending" },
                                        get = function(info) return info.handler.db.profile.ccSort or "last" end,
                                        set = function(info, val)
                                            info.handler.db.profile.ccSort = val
                                            info.handler:UpdateAuraSortSettings()
                                        end,
                                    },
                                    sep2 = { order = 2.5, type = "description", name = "", width = "full" },
                                    defensiveSort = {
                                        order = 3,
                                        name = L["AuraSort_Defensive_Sort"],
                                        type = "select",
                                        width = 1.5,
                                        values = {
                                            last = L["AuraSort_LastAdded"],
                                            blizzDefault = L["AuraSort_Default"],
                                            lastending = L["AuraSort_LastEnding"],
                                            firstending = L["AuraSort_FirstEnding"],
                                        },
                                        sorting = { "last", "blizzDefault", "lastending", "firstending" },
                                        get = function(info) return info.handler.db.profile.defensiveSort or "last" end,
                                        set = function(info, val)
                                            info.handler.db.profile.defensiveSort = val
                                            info.handler:UpdateAuraSortSettings()
                                        end,
                                    },
                                    sep3 = { order = 3.5, type = "description", name = "", width = "full" },
                                    importantSort = {
                                        order = 4,
                                        name = L["AuraSort_Important_Sort"],
                                        type = "select",
                                        width = 1.5,
                                        values = {
                                            last = L["AuraSort_LastAdded"],
                                            blizzDefault = L["AuraSort_Default"],
                                            lastending = L["AuraSort_LastEnding"],
                                            firstending = L["AuraSort_FirstEnding"],
                                        },
                                        sorting = { "last", "blizzDefault", "lastending", "firstending" },
                                        get = function(info) return info.handler.db.profile.importantSort or "last" end,
                                        set = function(info, val)
                                            info.handler.db.profile.importantSort = val
                                            info.handler:UpdateAuraSortSettings()
                                        end,
                                    },
                                },
                            },
                        },
                    },
                    clickActionsGroup = {
                        order = 4,
                        name = L["Category_ClickActions"],
                        desc = L["Category_ClickActions_Desc"],
                        type = "group",
                        args = (function()
                            local CLICK_BUTTONS = {
                                ["1"] = L["ClickAction_Left"],
                                ["2"] = L["ClickAction_Right"],
                                ["3"] = L["ClickAction_Middle"],
                                ["4"] = L["ClickAction_Button4"],
                                ["5"] = L["ClickAction_Button5"],
                            }
                            local CLICK_MODIFIERS = {
                                [""] = L["ClickAction_ModNone"],
                                ["ctrl-"] = L["ClickAction_ModCtrl"],
                                ["shift-"] = L["ClickAction_ModShift"],
                                ["alt-"] = L["ClickAction_ModAlt"],
                            }
                            local CLICK_ACTIONS = {
                                ["target"] = L["ClickAction_Target"],
                                ["focus"] = L["ClickAction_Focus"],
                                ["macro"] = L["ClickAction_Macro"],
                                ["spell"] = L["ClickAction_Spell"],
                            }

                            local addAttrButton = "1"
                            local addAttrMod = ""
                            local petAddAttrButton = "1"
                            local petAddAttrMod = ""

                            local function GetAttrDisplayName(modifier, button)
                                local modName = CLICK_MODIFIERS[modifier] or ""
                                local btnName = CLICK_BUTTONS[button] or button
                                if modifier ~= "" then
                                    return modName .. "-" .. btnName
                                end
                                return btnName
                            end

                            function sArenaMixin:BuildClickActionOption(key, orderStart, dbKey)
                                dbKey = dbKey or "clickAttributes"
                                return {
                                    type = "group",
                                    name = key,
                                    inline = true,
                                    order = orderStart,
                                    args = {
                                        action = {
                                            order = 1,
                                            name = L["ClickAction_Action"],
                                            type = "select",
                                            width = 0.7,
                                            values = CLICK_ACTIONS,
                                            get = function(info)
                                                local attrs = info.handler.db.profile[dbKey]
                                                return attrs[key] and attrs[key].action or "target"
                                            end,
                                            set = function(info, value)
                                                local attrs = info.handler.db.profile[dbKey]
                                                if attrs[key] then
                                                    attrs[key].action = value
                                                    info.handler:ApplyAllClickActions()
                                                end
                                            end,
                                        },
                                        macrotext = {
                                            order = 2,
                                            name = L["ClickAction_MacroText"],
                                            desc = L["ClickAction_MacroText_Desc"],
                                            type = "input",
                                            width = "full",
                                            multiline = 4,
                                            hidden = function(info)
                                                local attrs = info.handler.db.profile[dbKey]
                                                local action = attrs[key] and attrs[key].action
                                                return action ~= "macro"
                                            end,
                                            get = function(info)
                                                local attrs = info.handler.db.profile[dbKey]
                                                return attrs[key] and attrs[key].macro or ""
                                            end,
                                            set = function(info, value)
                                                local attrs = info.handler.db.profile[dbKey]
                                                if attrs[key] then
                                                    attrs[key].macro = value
                                                    info.handler:ApplyAllClickActions()
                                                end
                                            end,
                                        },
                                        spellname = {
                                            order = 2.5,
                                            name = L["ClickAction_SpellName"],
                                            desc = L["ClickAction_SpellName_Desc"],
                                            type = "input",
                                            width = 1.5,
                                            hidden = function(info)
                                                local attrs = info.handler.db.profile[dbKey]
                                                local action = attrs[key] and attrs[key].action
                                                return action ~= "spell"
                                            end,
                                            get = function(info)
                                                local attrs = info.handler.db.profile[dbKey]
                                                return attrs[key] and attrs[key].macro or ""
                                            end,
                                            set = function(info, value)
                                                local attrs = info.handler.db.profile[dbKey]
                                                if attrs[key] then
                                                    attrs[key].macro = value
                                                    info.handler:ApplyAllClickActions()
                                                end
                                            end,
                                        },
                                        delete = {
                                            order = 3,
                                            name = L["ClickAction_Delete"],
                                            desc = L["ClickAction_Delete_Desc"],
                                            type = "execute",
                                            width = 0.5,
                                            confirm = function() return sArenaMixin.popupHeader..L["ClickAction_Delete_Confirm"] end,
                                            func = function(info)
                                                info.handler.db.profile[dbKey][key] = nil
                                                info.handler:ApplyAllClickActions()
                                                info.handler:RebuildClickActionsOptions()
                                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                            end,
                                        },
                                    },
                                }
                            end

                            local isCliqueLoaded = C_AddOns.IsAddOnLoaded("Clique")

                            local args = {
                                description = {
                                    order = 0,
                                    type = "description",
                                    name = L["ClickAction_Desc"],
                                    fontSize = "medium",
                                },
                                cliqueDescription = {
                                    order = 0.1,
                                    type = "description",
                                    name = "\n" .. L["ClickAction_CliqueDetected"],
                                    fontSize = "medium",
                                    hidden = not isCliqueLoaded,
                                },
                                enableCliqueSupport = {
                                    order = 0.2,
                                    type = "toggle",
                                    name = L["ClickAction_EnableClique"],
                                    width = "full",
                                    hidden = not isCliqueLoaded,
                                    get = function(info) return info.handler.db.profile.enableCliqueSupport end,
                                    set = function(info, value)
                                        info.handler.db.profile.enableCliqueSupport = value
                                        info.handler:ApplyAllClickActions()
                                    end,
                                },
                                addGroup = {
                                    order = 1,
                                    type = "group",
                                    name = L["ClickAction_Add"],
                                    inline = true,
                                    disabled = function(info) return info.handler.db.profile.enableCliqueSupport or info.handler.db.profile.clickthroughFrames end,
                                    args = {
                                        addButton = {
                                            order = 1,
                                            name = L["ClickAction_Button"],
                                            type = "select",
                                            width = 0.6,
                                            values = CLICK_BUTTONS,
                                            get = function() return addAttrButton end,
                                            set = function(_, value) addAttrButton = value end,
                                        },
                                        addModifier = {
                                            order = 2,
                                            name = L["ClickAction_Modifier"],
                                            type = "select",
                                            width = 0.6,
                                            values = CLICK_MODIFIERS,
                                            get = function() return addAttrMod end,
                                            set = function(_, value) addAttrMod = value end,
                                        },
                                        addExecute = {
                                            order = 3,
                                            name = L["ClickAction_AddButton"],
                                            desc = L["ClickAction_AddButton_Desc"],
                                            type = "execute",
                                            width = 0.5,
                                            func = function(info)
                                                local displayName = GetAttrDisplayName(addAttrMod, addAttrButton)
                                                local attrs = info.handler.db.profile.clickAttributes
                                                if not attrs[displayName] then
                                                    attrs[displayName] = {
                                                        button = addAttrButton,
                                                        modifier = addAttrMod,
                                                        action = "target",
                                                    }
                                                    info.handler:ApplyAllClickActions()
                                                    info.handler:RebuildClickActionsOptions()
                                                    LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                                end
                                            end,
                                        },
                                    },
                                },
                                attributeList = {
                                    order = 2,
                                    type = "group",
                                    name = L["ClickAction_Existing"],
                                    inline = true,
                                    disabled = function(info) return info.handler.db.profile.enableCliqueSupport or info.handler.db.profile.clickthroughFrames end,
                                    args = {},
                                },
                                petFrameGroup = {
                                    order = 3,
                                    type = "group",
                                    name = L["ClickAction_PetFrames"],
                                    inline = true,
                                    disabled = function(info) return info.handler.db.profile.enableCliqueSupport or info.handler.db.profile.clickthroughFrames end,
                                    args = {
                                        usePetFrameClickActions = {
                                            order = 1,
                                            type = "toggle",
                                            name = L["ClickAction_UsePetFrameClickActions"],
                                            desc = L["ClickAction_UsePetFrameClickActions_Desc"],
                                            width = "full",
                                            get = function(info) return info.handler.db.profile.usePetFrameClickActions end,
                                            set = function(info, value)
                                                info.handler.db.profile.usePetFrameClickActions = value
                                                info.handler:ApplyAllClickActions()
                                            end,
                                        },
                                        petAddGroup = {
                                            order = 2,
                                            type = "group",
                                            name = L["ClickAction_Add"],
                                            inline = true,
                                            hidden = function(info) return not info.handler.db.profile.usePetFrameClickActions end,
                                            args = {
                                                addButton = {
                                                    order = 1,
                                                    name = L["ClickAction_Button"],
                                                    type = "select",
                                                    width = 0.6,
                                                    values = CLICK_BUTTONS,
                                                    get = function() return petAddAttrButton end,
                                                    set = function(_, value) petAddAttrButton = value end,
                                                },
                                                addModifier = {
                                                    order = 2,
                                                    name = L["ClickAction_Modifier"],
                                                    type = "select",
                                                    width = 0.6,
                                                    values = CLICK_MODIFIERS,
                                                    get = function() return petAddAttrMod end,
                                                    set = function(_, value) petAddAttrMod = value end,
                                                },
                                                addExecute = {
                                                    order = 3,
                                                    name = L["ClickAction_AddButton"],
                                                    desc = L["ClickAction_AddButton_Desc"],
                                                    type = "execute",
                                                    width = 0.5,
                                                    func = function(info)
                                                        local displayName = GetAttrDisplayName(petAddAttrMod, petAddAttrButton)
                                                        local attrs = info.handler.db.profile.petFrameClickAttributes
                                                        if not attrs[displayName] then
                                                            attrs[displayName] = {
                                                                button = petAddAttrButton,
                                                                modifier = petAddAttrMod,
                                                                action = "target",
                                                            }
                                                            info.handler:ApplyAllClickActions()
                                                            info.handler:RebuildClickActionsOptions()
                                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                                        end
                                                    end,
                                                },
                                            },
                                        },
                                        attributeList = {
                                            order = 3,
                                            type = "group",
                                            name = L["ClickAction_Existing"],
                                            inline = true,
                                            hidden = function(info) return not info.handler.db.profile.usePetFrameClickActions end,
                                            args = {},
                                        },
                                        resetPet = {
                                            order = 4,
                                            name = L["ClickAction_ResetAll"],
                                            desc = L["ClickAction_ResetAll_Desc"],
                                            type = "execute",
                                            width = 0.7,
                                            hidden = function(info) return not info.handler.db.profile.usePetFrameClickActions end,
                                            confirm = function() return L["ClickAction_ResetAll_Confirm"] end,
                                            func = function(info)
                                                local defaults = sArenaMixin.defaultSettings.profile.petFrameClickAttributes
                                                local copy = {}
                                                for k, v in pairs(defaults) do
                                                    copy[k] = { button = v.button, modifier = v.modifier, action = v.action, macro = v.macro }
                                                end
                                                info.handler.db.profile.petFrameClickAttributes = copy
                                                info.handler:ApplyAllClickActions()
                                                info.handler:RebuildClickActionsOptions()
                                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                            end,
                                        },
                                    },
                                },
                                clickthroughFrames = {
                                    order = 98,
                                    type = "toggle",
                                    name = L["ClickAction_Clickthrough"],
                                    desc = L["ClickAction_Clickthrough_Desc"],
                                    width = "full",
                                    get = function(info) return info.handler.db.profile.clickthroughFrames end,
                                    set = function(info, value)
                                        info.handler.db.profile.clickthroughFrames = value
                                        info.handler:SetMouseState(not info.handler:IsInArena())
                                    end,
                                },
                                resetAll = {
                                    order = 99,
                                    name = L["ClickAction_ResetAll"],
                                    desc = L["ClickAction_ResetAll_Desc"],
                                    type = "execute",
                                    width = 0.7,
                                    disabled = function(info) return info.handler.db.profile.enableCliqueSupport or info.handler.db.profile.clickthroughFrames end,
                                    confirm = function() return L["ClickAction_ResetAll_Confirm"] end,
                                    func = function(info)
                                        local defaults = sArenaMixin.defaultSettings.profile.clickAttributes
                                        local copy = {}
                                        for k, v in pairs(defaults) do
                                            copy[k] = { button = v.button, modifier = v.modifier, action = v.action, macro = v.macro }
                                        end
                                        info.handler.db.profile.clickAttributes = copy
                                        info.handler:ApplyAllClickActions()
                                        info.handler:RebuildClickActionsOptions()
                                        LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                    end,
                                },
                            }

                            local order = 1
                            for key, _ in pairs(sArenaMixin.defaultSettings.profile.clickAttributes) do
                                args.attributeList.args[key] = sArenaMixin:BuildClickActionOption(key, order, "clickAttributes")
                                order = order + 1
                            end

                            local petOrder = 1
                            for key, _ in pairs(sArenaMixin.defaultSettings.profile.petFrameClickAttributes or {}) do
                                args.petFrameGroup.args.attributeList.args[key] = sArenaMixin:BuildClickActionOption(key, petOrder, "petFrameClickAttributes")
                                petOrder = petOrder + 1
                            end

                            sArenaMixin.ClickActionsArgs = args

                            return args
                        end)(),
                    },
                    drGroup = {
                        order = 5,
                        name = L["Category_DiminishingReturns"],
                        type = "group",
                        args = {
                            drOptions = {
                                order = 1,
                                type = "group",
                                name = L["Option_Miscellaneous"],
                                inline = true,
                                args = {
                                    drResetTime = {
                                        order = 1,
                                        name = L["Option_DRResetTime"],
                                        desc = isMidnight and L["Option_DRResetTime_Desc_Midnight"] or L["Option_DRResetTime_Desc"],
                                        type = "range",
                                        min = isMidnight and 20 or 15,
                                        max = isMidnight and 20.5 or 20,
                                        step = 0.1,
                                        width = "normal",
                                        get = function(info)
                                            return info.handler.db.profile.drResetTime or (isMidnight and 20.1 or 20)
                                        end,
                                        set = function(info, val)
                                            info.handler.db.profile.drResetTime = val
                                            info.handler:UpdateDRTimeSetting()
                                        end,
                                    },
                                    drResetTime_break = {
                                        order = 1.1,
                                        type = "description",
                                        name = " ",
                                        width = "full",
                                    },
                                    showDecimalsDR = {
                                        order = 2,
                                        name = L["Option_ShowDecimalsOnDRs"],
                                        desc = L["Option_ShowDecimalsOnDRs_Desc"],
                                        type = "toggle",
                                        width = 1.2,
                                        get = function(info) return info.handler.db.profile.showDecimalsDR end,
                                        set = function(info, val)
                                            info.handler.db.profile.showDecimalsDR = val
                                            info.handler:SetupCustomCD()
                                        end
                                    },
                                    decimalThresholdDR = {
                                        order = 2.5,
                                        name = L["Option_DecimalThreshold"],
                                        desc = L["Cooldown_ShowDecimalsThreshold_Desc"],
                                        type = "range",
                                        min = 1,
                                        max = 10,
                                        step = 0.1,
                                        width = 0.75,
                                        disabled = function(info) return not info.handler.db.profile.showDecimalsDR end,
                                        get = function(info) return info.handler.db.profile.decimalThreshold or 6 end,
                                        set = function(info, val)
                                            info.handler.db.profile.decimalThreshold = val
                                            info.handler:UpdateDecimalThreshold()
                                            info.handler:SetupCustomCD()
                                        end
                                    },
                                    colorDRCooldownText = {
                                        order = 3,
                                        name = L["Option_ColorDRCooldownText"],
                                        desc = isMidnight and L["Option_ColorDRCooldownText_Desc_Midnight"] or L["Option_ColorDRCooldownText_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.colorDRCooldownText end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorDRCooldownText = val
                                            if not val then
                                                for i = 1, info.handler.maxArenaOpponents do
                                                    local frame = info.handler["arena" .. i]
                                                    frame:ResetDRCooldownTextColors()
                                                end
                                            end
                                            info.handler:SetupCustomCD()
                                            info.handler:Test()
                                        end
                                    },
                                    disableInstantDRCooldown = {
                                        order = 4,
                                        name = L["Option_DisableInstantDRCooldown"],
                                        desc = L["Option_DisableInstantDRCooldown_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        hidden = not isMidnight,
                                        get = function(info) return info.handler.db.profile.disableInstantDRCooldown end,
                                        set = function(info, val)
                                            info.handler.db.profile.disableInstantDRCooldown = val
                                        end,
                                    },
                                    drBugFixMidnight = {
                                        order = 5,
                                        name = L["Option_DrBugFixMidnight"],
                                        desc = L["Option_DrBugFixMidnight_Desc"],
                                        type = "toggle",
                                        width = 1.3,
                                        hidden = not isMidnight,
                                        disabled = function(info) return info.handler.db.profile.disableInstantDRCooldown end,
                                        get = function(info) return info.handler.db.profile.drBugFixMidnight end,
                                        set = function(info, val)
                                            info.handler.db.profile.drBugFixMidnight = val
                                        end,
                                    },
                                    drBugFixLonger = {
                                        order = 5.5,
                                        name = L["Option_DrBugFixLonger"],
                                        desc = L["Option_DrBugFixLonger_Desc"],
                                        type = "toggle",
                                        width = 1.6,
                                        hidden = not isMidnight,
                                        disabled = function(info) return info.handler.db.profile.disableInstantDRCooldown or not info.handler.db.profile.drBugFixMidnight end,
                                        get = function(info) return info.handler.db.profile.drBugFixLonger end,
                                        set = function(info, val)
                                            info.handler.db.profile.drBugFixLonger = val
                                        end,
                                    },
                                },
                            },
                            categories = {
                                order = 2,
                                name = L["Option_DRCategories"],
                                type = "group",
                                inline = true,
                                args = {
                                    hideMidnightDRs = {
                                        order = 0.1,
                                        name = L["Option_HideDRs"],
                                        desc = L["Option_HideDRs_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        hidden = function() return not isMidnight end,
                                        confirm = function(info, val) info.handler.db.profile.hideMidnightDRs = val;return L["Option_HideDRs_Reload_Desc"] end,
                                        get = function(info) return info.handler.db.profile.hideMidnightDRs end,
                                        set = function(info, val)
                                            info.handler.db.profile.hideMidnightDRs = val
                                            sArena_ReloadedDB.reOpenOptions = true
                                            ReloadUI()
                                        end,
                                    },
                                    onlyTriggerableDRs = {
                                        order = 0.2,
                                        name = L["Option_OnlyTriggerableDRs"],
                                        desc = L["Option_OnlyTriggerableDRs_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        hidden = function() return not isMidnight end,
                                        disabled = function(info) return info.handler.db.profile.hideMidnightDRs end,
                                        get = function(info)
                                            return C_CVar.GetCVarBool("spellDiminishPVPOnlyTriggerableByMe")
                                        end,
                                        set = function(info, val)
                                            if InCombatLockdown() then return end
                                            C_CVar.SetCVar("spellDiminishPVPOnlyTriggerableByMe", val and "1" or "0")
                                        end,
                                    },
                                    midnightDRSpacer = {
                                        order = 0.3,
                                        type = "description",
                                        name = " ",
                                        width = "full",
                                        hidden = function() return not isMidnight end,
                                    },
                                    drCategoriesPerClass = {
                                        order = 1,
                                        name = L["Option_PerClass"],
                                        desc = L["DR_ClassSpecific_Desc"],
                                        type = "toggle",
                                        disabled = function() return isMidnight end,
                                        get = function(info) return info.handler.db.profile.drCategoriesPerClass end,
                                        set = function(info, val)
                                            info.handler.db.profile.drCategoriesPerClass = val
                                            if val then
                                                info.handler.db.profile.drCategoriesPerSpec = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    drCategoriesPerSpec = {
                                        order = 2,
                                        name = L["Option_PerSpec"],
                                        desc = L["DR_SpecSpecific_Desc"],
                                        type = "toggle",
                                        disabled = function() return isMidnight end,
                                        get = function(info) return info.handler.db.profile.drCategoriesPerSpec end,
                                        set = function(info, val)
                                            info.handler.db.profile.drCategoriesPerSpec = val
                                            if val then
                                                info.handler.db.profile.drCategoriesPerClass = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },

                                    categoriesMultiselect = {
                                        order = 4,
                                        disabled = function() return isMidnight end,
                                        name = function(info)
                                            local db = info.handler.db
                                            if db.profile.drCategoriesPerSpec then
                                                local className = select(1, UnitClass("player")) or L["Unknown"]
                                                local classKey = select(2, UnitClass("player"))
                                                local specName = info.handler.playerSpecName or L["Unknown"]
                                                local classColor = C_ClassColor.GetClassColor(classKey)
                                                local coloredText = specName .. " " .. className
                                                if classColor then
                                                    coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                                                end
                                                return string.format(L["DR_CategoriesPerSpec"], coloredText)
                                            elseif db.profile.drCategoriesPerClass then
                                                local className = select(1, UnitClass("player")) or L["Unknown"]
                                                local classKey = select(2, UnitClass("player"))
                                                local classColor = C_ClassColor.GetClassColor(classKey)
                                                local coloredText = className
                                                if classColor then
                                                    coloredText = "|c" .. classColor.colorStr .. coloredText .. "|r"
                                                end
                                                return string.format(L["DR_CategoriesPerClass"], coloredText)
                                            else
                                                return L["DR_CategoriesGlobal"]
                                            end
                                        end,
                                        type = "multiselect",
                                        get = function(info, key) 
                                            local db = info.handler.db
                                            if db.profile.drCategoriesPerSpec then
                                                local specKey = info.handler.playerSpecID or 0
                                                local perSpec = db.profile.drCategoriesSpec or {}
                                                local specCategories = perSpec[specKey] or {}
                                                if specCategories[key] ~= nil then
                                                    return specCategories[key]
                                                else
                                                    return db.profile.drCategories[key]
                                                end
                                            elseif db.profile.drCategoriesPerClass then
                                                local classKey = info.handler.playerClass
                                                local perClass = db.profile.drCategoriesClass or {}
                                                local classCategories = perClass[classKey] or {}
                                                if classCategories[key] ~= nil then
                                                    return classCategories[key]
                                                else
                                                    return db.profile.drCategories[key]
                                                end
                                            else
                                                return db.profile.drCategories[key]
                                            end
                                        end,
                                        set = function(info, key, val) 
                                            local db = info.handler.db
                                            if db.profile.drCategoriesPerSpec then
                                                db.profile.drCategoriesSpec = db.profile.drCategoriesSpec or {}
                                                local specKey = info.handler.playerSpecID or 0
                                                db.profile.drCategoriesSpec[specKey] = db.profile.drCategoriesSpec[specKey] or {}
                                                db.profile.drCategoriesSpec[specKey][key] = val
                                            elseif db.profile.drCategoriesPerClass then
                                                db.profile.drCategoriesClass = db.profile.drCategoriesClass or {}
                                                local classKey = info.handler.playerClass
                                                db.profile.drCategoriesClass[classKey] = db.profile.drCategoriesClass[classKey] or {}
                                                db.profile.drCategoriesClass[classKey][key] = val
                                            else
                                                db.profile.drCategories[key] = val
                                            end
                                        end,
                                        values = drCategoryDisplay,
                                    },
                                },
                            },
                            dynamicIcons = {
                                order = 3,
                                name = L["Option_DRIcons"],
                                disabled = function() return isMidnight end,
                                type = "group",
                                inline = true,
                                args = {
                                    midnightDisclaimer = {
                                        order = 0,
                                        type = "description",
                                        name = isMidnight and L["DR_MidnightDisclaimer"] or "",
                                        fontSize = "medium",
                                        hidden = function() return not isMidnight end,
                                    },
                                    drStaticIcons = {
                                        order = 1,
                                        name = L["Option_EnableStaticIcons"],
                                        desc = L["DR_FixedIcons_Desc"],
                                        type = "toggle",
                                        get = function(info) return info.handler.db.profile.drStaticIcons end,
                                        set = function(info, val)
                                            info.handler.db.profile.drStaticIcons = val
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    dynamicIconsPerClass = {
                                        order = 2,
                                        name = L["Option_PerClass"],
                                        desc = L["DR_ClassSpecificIcons_Desc"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.drStaticIcons end,
                                        get = function(info) return info.handler.db.profile.drStaticIconsPerClass end,
                                        set = function(info, val)
                                            info.handler.db.profile.drStaticIconsPerClass = val
                                            if val then
                                                info.handler.db.profile.drStaticIconsPerSpec = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    dynamicIconsPerSpec = {
                                        order = 3,
                                        name = L["Option_PerSpec"],
                                        desc = L["DR_SpecSpecificIcons_Desc"],
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.drStaticIcons end,
                                        get = function(info) return info.handler.db.profile.drStaticIconsPerSpec end,
                                        set = function(info, val)
                                            info.handler.db.profile.drStaticIconsPerSpec = val
                                            if val then
                                                info.handler.db.profile.drStaticIconsPerClass = false
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    },
                                    staticIconsSeparator = {
                                        order = 4,
                                        name = "",
                                        type = "header",
                                    },
                                    drIconsSection = {
                                        order = 4,
                                        type = "group",
                                        name = "",
                                        inline = true,
                                        disabled = function(info) return not info.handler.db.profile.drStaticIcons end,
                                        get = function(info)
                                            local key = info[#info]
                                            local db = info.handler.db
                                            if db.profile.drStaticIconsPerSpec then
                                                local specKey = info.handler.playerSpecID or 0
                                                local perSpec = db.profile.drIconsPerSpec or {}
                                                local specIcons = perSpec[specKey] or {}
                                                return tostring(specIcons[key] or "")
                                            elseif db.profile.drStaticIconsPerClass then
                                                local classKey = info.handler.playerClass
                                                local perClass = db.profile.drIconsPerClass or {}
                                                local classIcons = perClass[classKey] or {}
                                                return tostring(classIcons[key] or "")
                                            else
                                                return tostring(db.profile.drIcons[key] or drIcons[key])
                                            end
                                        end,
                                        set = function(info, value)
                                            local key = info[#info]
                                            local db = info.handler.db
                                            local num = tonumber(value)
                                            if db.profile.drStaticIconsPerSpec then
                                                db.profile.drIconsPerSpec = db.profile.drIconsPerSpec or {}
                                                local specKey = info.handler.playerSpecID or 0
                                                db.profile.drIconsPerSpec[specKey] = db.profile.drIconsPerSpec[specKey] or {}
                                                db.profile.drIconsPerSpec[specKey][key] = num or value
                                            elseif db.profile.drStaticIconsPerClass then
                                                db.profile.drIconsPerClass = db.profile.drIconsPerClass or {}
                                                local classKey = info.handler.playerClass
                                                db.profile.drIconsPerClass[classKey] = db.profile.drIconsPerClass[classKey] or {}
                                                db.profile.drIconsPerClass[classKey][key] = num or value
                                            else
                                                db.profile.drIcons = db.profile.drIcons or {}
                                                db.profile.drIcons[key] = num or value
                                            end
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                        args = setDRIcons(),
                                    },
                                },
                            },
                            midnightDisclaimerBottom = {
                                order = 4,
                                type = "description",
                                name = isMidnight and L["DR_MidnightDisclaimer"] or "",
                                fontSize = "medium",
                                hidden = function() return not isMidnight end,
                            },
                            drDebug = {
                                order = 5,
                                name = L["Category_Debug"],
                                type = "group",
                                inline = true,
                                hidden = function() return not isMidnight end,
                                args = {
                                    newMidnightDRHandling = {
                                        order = 1,
                                        name = L["Option_NewMidnightDRHandling"],
                                        desc = L["Option_NewMidnightDRHandling_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.newMidnightDRHandling end,
                                        set = function(info, val)
                                            info.handler.db.profile.newMidnightDRHandling = val
                                            sArena_ReloadedDB.reOpenOptions = true
                                            ReloadUI()
                                        end,
                                    },
                                },
                            },
                        },
                    },
                    dispelGroup = {
                        order = 6,
                        name = L["Category_Dispels"],
                        hidden = function() return isMidnight end,
                        type = "group",
                        args = (function()
                            local args = {
                                showDispels = {
                                    order = 0,
                                    name = L["Option_ShowDispels"],
                                    desc = L["Option_ShowDispels_Desc"],
                                    type = "toggle",
                                    width = "full",
                                    get = function(info) return info.handler.db.profile.showDispels end,
                                    set = function(info, val)
                                        info.handler.db.profile.showDispels = val
                                        info.handler:Test()
                                    end,
                                },
                                spacer0 = {
                                    order = 0.5,
                                    type = "description",
                                    name = "",
                                    width = "full",
                                },
                            }

                            local healerDispels = {}
                            local dpsDispels = {}

                            for spellID, data in pairs(sArenaMixin.dispelData or {}) do
                                if data.healer or data.sharedSpecSpellID then
                                    healerDispels[spellID] = data
                                end
                                if not data.healer or data.sharedSpecSpellID then
                                    dpsDispels[spellID] = data
                                end
                            end

                            local order = 1

                            if next(healerDispels) then
                                args["healer_dispels"] = {
                                    order = order,
                                    name = L["Option_HealerDispels"],
                                    type = "group",
                                    inline = true,
                                    disabled = function(info) return not info.handler.db.profile.showDispels end,
                                    args = {}
                                }
                                order = order + 1

                                local healerOrder = 1
                                for spellID, data in pairs(healerDispels) do
                                    -- For MoP shared spells, use separate setting key
                                    local settingKey = spellID
                                    if not isRetail and data.sharedSpecSpellID then
                                        settingKey = spellID .. "_healer"
                                    end

                                    args["healer_dispels"].args["spell_" .. spellID] = {
                                        order = healerOrder,
                                        name = function()
                                            local spellName = GetSpellInfoCompat(spellID)
                                            return "|T" .. (data.texture or "") .. ":16|t " .. (spellName or data.name)
                                        end,
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.showDispels end,
                                        get = function(info) return info.handler.db.profile.dispelCategories[settingKey] end,
                                        set = function(info, val)
                                            info.handler.db.profile.dispelCategories[settingKey] = val
                                            for i = 1, 3 do
                                                local frame = info.handler["arena" .. i]
                                                if frame then
                                                    frame:UpdateDispel()
                                                end
                                            end
                                        end,
                                        desc = function()
                                            local spellName = GetSpellInfoCompat(spellID)
                                            local spellDesc = GetSpellDescriptionCompat(spellID)

                                            spellName = spellName or data.name or L["Unknown_Spell"]
                                            local cooldownText = data.cooldown and string.format(L["Cooldown_Seconds"], data.cooldown) or ""

                                            local tooltipLines = {}
                                            table.insert(tooltipLines, "|cFFFFD700" .. spellName .. "|r")
                                            table.insert(tooltipLines, "|cFF87CEEB" .. data.classes .. "|r")
                                            if spellDesc and spellDesc ~= "" then
                                                table.insert(tooltipLines, spellDesc)
                                            end
                                            if cooldownText ~= "" then
                                                table.insert(tooltipLines, "|cFF00FF00" .. cooldownText .. "|r")
                                            end
                                            table.insert(tooltipLines, "|cFF808080Spell ID: " .. spellID .. "|r")

                                            return table.concat(tooltipLines, "\n\n")
                                        end,
                                    }
                                    healerOrder = healerOrder + 1
                                end
                            end

                            if next(dpsDispels) then
                                args["dps_dispels"] = {
                                    order = order,
                                    name = L["Option_DPSDispels"],
                                    type = "group",
                                    inline = true,
                                    disabled = function(info) return not info.handler.db.profile.showDispels end,
                                    args = {
                                        description = {
                                            order = 1,
                                            type = "description",
                                            name = L["Option_DPSDispelsNote"],
                                            fontSize = "medium",
                                        }
                                    }
                                }
                                order = order + 1

                                local dpsOrder = 2
                                for spellID, data in pairs(dpsDispels) do

                                    local settingKey = spellID
                                    if not sArenaMixin.isRetail and data.sharedSpecSpellID then
                                        settingKey = spellID .. "_dps"
                                    end

                                    args["dps_dispels"].args["spell_" .. spellID] = {
                                        order = dpsOrder,
                                        name = function()
                                            local spellName = GetSpellInfoCompat(spellID)
                                            return "|T" .. (data.texture or "134400") .. ":16|t " .. (spellName or data.name)
                                        end,
                                        type = "toggle",
                                        disabled = function(info) return not info.handler.db.profile.showDispels end,
                                        get = function(info) return info.handler.db.profile.dispelCategories[settingKey] end,
                                        set = function(info, val)
                                            info.handler.db.profile.dispelCategories[settingKey] = val
                                            for i = 1, 3 do
                                                local frame = info.handler["arena" .. i]
                                                if frame then
                                                    frame:UpdateDispel()
                                                end
                                            end
                                        end,
                                        desc = function()
                                            local spellName = GetSpellInfoCompat(spellID)
                                            local spellDesc = GetSpellDescriptionCompat(spellID)

                                            spellName = spellName or data.name or L["Unknown_Spell"]
                                            local cooldownText = data.cooldown and string.format(L["Cooldown_Seconds"], data.cooldown) or ""

                                            local tooltipLines = {}
                                            table.insert(tooltipLines, "|cFFFFD700" .. spellName .. "|r")
                                            table.insert(tooltipLines, "|cFF87CEEB" .. data.classes .. "|r")
                                            if spellDesc and spellDesc ~= "" then
                                                table.insert(tooltipLines, spellDesc)
                                            end
                                            if cooldownText ~= "" then
                                                table.insert(tooltipLines, "|cFF00FF00" .. cooldownText .. "|r")
                                            end
                                            table.insert(tooltipLines, "|cFF808080Spell ID: " .. spellID .. "|r")
                                            table.insert(tooltipLines, "|cFFFFA500" .. L["Dispel_ShowsAfterUse"] .. "|r")

                                            return table.concat(tooltipLines, "\n\n")
                                        end,
                                    }
                                    dpsOrder = dpsOrder + 1
                                end
                            end

                            args["betaNotice"] = {
                                order = 999,
                                type = "description",
                                name = L["Option_DispelsBetaNotice"],
                                fontSize = "medium",
                                width = "full",
                            }

                            return args
                        end)(),
                    },
                    racialGroup = {
                        order = 7,
                        name = L["Category_Racials"],
                        type = "group",
                        args = (function()
                            local args = {
                                midnightTextureNotice = {
                                    order = 0,
                                    type = "description",
                                    name = isMidnight and L["Racial_MidnightTextureNotice"] or "",
                                    fontSize = "medium",
                                    hidden = function() return not isMidnight end,
                                },
                                midnightDisclaimerSpacer = {
                                    order = 0.1,
                                    type = "description",
                                    name = " ",
                                    hidden = function() return not isMidnight end,
                                },
                                categories = {
                                    order = 1,
                                    name = L["Option_Categories"],
                                    type = "group",
                                    inline = true,
                                    disabled = function() return isMidnight end,
                                    args = (function()
                                        local toggles = {}
                                        local sortedKeys = {}
                                        for raceKey in pairs(racialCategories) do
                                            sortedKeys[#sortedKeys + 1] = raceKey
                                        end
                                        table.sort(sortedKeys)
                                        if C_Spell and C_Spell.RequestLoadSpellData then
                                            for _, raceKey in ipairs(sortedKeys) do
                                                local d = sArenaMixin.racialData and sArenaMixin.racialData[raceKey]
                                                if d and d.spellID then
                                                    C_Spell.RequestLoadSpellData(d.spellID)
                                                end
                                            end
                                        end
                                        for idx, raceKey in ipairs(sortedKeys) do
                                            local displayName = racialCategories[raceKey]
                                            local data = sArenaMixin.racialData and sArenaMixin.racialData[raceKey]
                                            local spellID = data and data.spellID
                                            local capturedSpellID = spellID
                                            local capturedData = data
                                            toggles[raceKey] = {
                                                order = idx,
                                                name = displayName,
                                                type = "toggle",
                                                desc = function()
                                                    if not capturedSpellID then return "" end
                                                    local spellName = GetSpellInfoCompat(capturedSpellID)
                                                    local spellDesc = GetSpellDescriptionCompat(capturedSpellID)
                                                    spellName = spellName or raceKey
                                                    local lines = {}
                                                    table.insert(lines, "|cFFFFD700" .. spellName .. "|r")
                                                    if spellDesc and spellDesc ~= "" then
                                                        table.insert(lines, spellDesc)
                                                    end
                                                    local cd = capturedData and capturedData.sharedCD
                                                    if cd and cd > 0 then
                                                        table.insert(lines, "|cFF00FF00" .. string.format(L["Cooldown_Shared_Seconds"], cd) .. "|r")
                                                    end
                                                    table.insert(lines, "|cFF808080Spell ID: " .. capturedSpellID .. "|r")
                                                    return table.concat(lines, "\n\n")
                                                end,
                                                get = function(info) return info.handler.db.profile.racialCategories[raceKey] end,
                                                set = function(info, val) info.handler.db.profile.racialCategories[raceKey] = val end,
                                            }
                                        end
                                        return toggles
                                    end)(),
                                },
                                enableAll = {
                                    order = 1.1,
                                    name = L["Racial_EnableAll"],
                                    type = "execute",
                                    width = 1.2,
                                    disabled = function() return isMidnight end,
                                    func = function(info)
                                        for key in pairs(racialCategories) do
                                            info.handler.db.profile.racialCategories[key] = true
                                        end
                                    end,
                                },
                                disableAll = {
                                    order = 1.2,
                                    name = L["Racial_DisableAll"],
                                    type = "execute",
                                    width = 1.2,
                                    disabled = function() return isMidnight end,
                                    func = function(info)
                                        for key in pairs(racialCategories) do
                                            info.handler.db.profile.racialCategories[key] = false
                                        end
                                    end,
                                },
                            }
                            args.racialOptions = {
                                order = 2,
                                type = "group",
                                name = L["Options"],
                                inline = true,
                                disabled = function() return isMidnight end,
                                args = {
                                    swapRacialTrinket = {
                                        order = 1,
                                        name = L["Option_SwapMissingTrinketWithRacial"],
                                        desc = L["Racial_ShowInTrinketSlot_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.swapRacialTrinket end,
                                        set = function(info, val)
                                            info.handler.db.profile.swapRacialTrinket = val
                                        end,
                                    },
                                    forceShowTrinketOnHuman = {
                                        order = 2,
                                        name = L["Option_ForceShowTrinketOnHuman"],
                                        desc = L["Human_AlwaysShowTrinket_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        hidden = function() return isRetail or isTBC end,
                                        get = function(info) return info.handler.db.profile.forceShowTrinketOnHuman end,
                                        set = function(info, val)
                                            info.handler.db.profile.forceShowTrinketOnHuman = val
                                            if val then
                                                info.handler.db.profile.replaceHumanRacialWithTrinket = false
                                            end
                                        end,
                                    },
                                    replaceHumanRacialWithTrinket = {
                                        order = 3,
                                        name = L["Option_ReplaceHumanRacialWithTrinket"],
                                        desc = L["Option_ReplaceHumanRacialWithTrinket_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        hidden = function() return isRetail or isTBC end,
                                        get = function(info) return info.handler.db.profile.replaceHumanRacialWithTrinket end,
                                        set = function(info, val)
                                            info.handler.db.profile.replaceHumanRacialWithTrinket = val
                                            if val then
                                                info.handler.db.profile.forceShowTrinketOnHuman = false
                                            end
                                        end,
                                    },
                                }
                            }

                            return args
                        end)(),
                    },
                    rangeCheckGroup = {
                        order = 8,
                        name = L["Category_RangeCheck"],
                        desc = L["Category_RangeCheck_Desc"],
                        type = "group",
                        args = {
                            rangeCheckSettings = {
                                order = 1,
                                name = L["Widget_RangeCheck"],
                                type = "group",
                                inline = true,
                                args = {
                                    enabled = {
                                        order = 1,
                                        name = L["Widget_RangeCheck_Enable"],
                                        desc = L["Widget_RangeCheck_Desc"],
                                        type = "toggle",
                                        width = "full",
                                        get = function(info) return info.handler.db.profile.rangeCheck.enabled end,
                                        set = function(info, val)
                                            info.handler.db.profile.rangeCheck.enabled = val
                                            info.handler:UnregisterRangeCheckEvents()
                                            if not val then
                                                info.handler:ResetRangeChecks()
                                            end
                                            info.handler:Test()
                                        end,
                                    },
                                    mode = {
                                        order = 2,
                                        name = L["Mode"],
                                        desc = L["Widget_RangeCheck_Mode_Desc"],
                                        type = "select",
                                        width = 1,
                                        values = {
                                            ["transparency"] = L["Transparency"],
                                            ["icon"] = L["Icon"],
                                            ["both"] = L["Widget_RangeCheck_Mode_Both"],
                                        },
                                        get = function(info) return info.handler.db.profile.rangeCheck.mode end,
                                        set = function(info, val)
                                            info.handler.db.profile.rangeCheck.mode = val
                                            info.handler:UpdateRangeSettings()
                                            info.handler:Test()
                                        end,
                                        disabled = function(info) return not info.handler.db.profile.rangeCheck.enabled end,
                                    },
                                    notInRangeAlpha = {
                                        order = 3,
                                        name = L["Widget_RangeCheck_NotInRangeAlpha"],
                                        desc = L["Widget_RangeCheck_NotInRangeAlpha_Desc"],
                                        type = "range",
                                        min = 0,
                                        max = 1,
                                        step = 0.01,
                                        isPercent = true,
                                        width = 1.2,
                                        get = function(info) return info.handler.db.profile.rangeCheck.notInRangeAlpha end,
                                        set = function(info, val)
                                            info.handler.db.profile.rangeCheck.notInRangeAlpha = val
                                            info.handler.rangeNotInRangeAlpha = val
                                            local frame = info.handler["arena3"]
                                            if frame and frame:IsShown() and frame.notInRange then
                                                frame:SetAlpha(val)
                                            end
                                        end,
                                        disabled = function(info)
                                            local rc = info.handler.db.profile.rangeCheck
                                            return not rc.enabled or rc.mode == "icon"
                                        end,
                                    },
                                    notInRangeGroup = {
                                        order = 5,
                                        name = L["Widget_RangeCheck_NotInRange"],
                                        type = "group",
                                        inline = true,
                                        disabled = function(info)
                                            local rc = info.handler.db.profile.rangeCheck
                                            return not rc.enabled or rc.mode == "transparency"
                                        end,
                                        args = {
                                            notInRangeAtlas = {
                                                order = 1,
                                                name = L["Widget_RangeCheck_NotInRangeTexture"],
                                                desc = L["Widget_RangeCheck_NotInRangeTexture_Desc"],
                                                type = "select",
                                                width = 1.2,
                                                values = sArenaMixin.rangeTextures,
                                                sorting = sArenaMixin.rangeTexturesSorting,
                                                get = function(info) return info.handler.db.profile.rangeCheck.notInRangeAtlas end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.notInRangeAtlas = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                    info.handler:Test()
                                                end,
                                            },
                                            notInRangeCustomAtlas = {
                                                order = 2,
                                                name = L["Widget_RangeCheck_CustomAtlas"],
                                                desc = L["Widget_RangeCheck_CustomAtlas_Desc"],
                                                type = "input",
                                                width = 1.0,
                                                get = function(info) return info.handler.db.profile.rangeCheck.notInRangeCustomAtlas end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.notInRangeCustomAtlas = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                    info.handler:Test()
                                                end,
                                                hidden = function(info) return info.handler.db.profile.rangeCheck.notInRangeAtlas ~= "custom" end,
                                            },
                                            notInRangeColorEnabled = {
                                                order = 3,
                                                name = L["Color"],
                                                desc = L["Widget_RangeCheck_ColorEnabled_Desc"],
                                                type = "toggle",
                                                width = 0.4,
                                                get = function(info) return info.handler.db.profile.rangeCheck.notInRangeColorEnabled end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.notInRangeColorEnabled = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                    info.handler:Test()
                                                end,
                                                hidden = function(info) return info.handler.db.profile.rangeCheck.notInRangeAtlas == "" end,
                                            },
                                            notInRangeColor = {
                                                order = 4,
                                                name = "",
                                                type = "color",
                                                hasAlpha = true,
                                                width = 0.3,
                                                get = function(info)
                                                    local c = info.handler.db.profile.rangeCheck.notInRangeColor
                                                    return c[1], c[2], c[3], c[4]
                                                end,
                                                set = function(info, r, g, b, a)
                                                    info.handler.db.profile.rangeCheck.notInRangeColor = { r, g, b, a }
                                                    info.handler:ApplyRangeCheckTextures()
                                                    info.handler:Test()
                                                end,
                                                disabled = function(info)
                                                    local rc = info.handler.db.profile.rangeCheck
                                                    return not rc.enabled or rc.mode == "transparency" or not rc.notInRangeColorEnabled
                                                end,
                                                hidden = function(info) return info.handler.db.profile.rangeCheck.notInRangeAtlas == "" end,
                                            },
                                            notInRangeSpacer = {
                                                order = 5,
                                                name = "",
                                                type = "description",
                                                width = "full",
                                            },
                                            notInRangePosX = {
                                                order = 6,
                                                name = L["Horizontal"],
                                                type = "range",
                                                min = -200,
                                                max = 200,
                                                step = 0.1,
                                                bigStep = 1,
                                                width = 0.95,
                                                get = function(info) return info.handler.db.profile.rangeCheck.notInRangePosX end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.notInRangePosX = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                end,
                                            },
                                            notInRangePosY = {
                                                order = 7,
                                                name = L["Vertical"],
                                                type = "range",
                                                min = -200,
                                                max = 200,
                                                step = 0.1,
                                                bigStep = 1,
                                                width = 0.95,
                                                get = function(info) return info.handler.db.profile.rangeCheck.notInRangePosY end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.notInRangePosY = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                end,
                                            },
                                            notInRangeScale = {
                                                order = 8,
                                                name = L["Scale"],
                                                type = "range",
                                                min = 0.1,
                                                max = 3.0,
                                                step = 0.01,
                                                bigStep = 0.01,
                                                isPercent = true,
                                                width = 0.95,
                                                get = function(info) return info.handler.db.profile.rangeCheck.notInRangeScale end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.notInRangeScale = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                end,
                                            },
                                        },
                                    },
                                    inRangeGroup = {
                                        order = 4,
                                        name = L["Widget_RangeCheck_InRange"],
                                        type = "group",
                                        inline = true,
                                        disabled = function(info)
                                            local rc = info.handler.db.profile.rangeCheck
                                            return not rc.enabled or rc.mode == "transparency"
                                        end,
                                        args = {
                                            inRangeAtlas = {
                                                order = 1,
                                                name = L["Widget_RangeCheck_InRangeTexture"],
                                                desc = L["Widget_RangeCheck_InRangeTexture_Desc"],
                                                type = "select",
                                                width = 1.2,
                                                values = sArenaMixin.rangeTextures,
                                                sorting = sArenaMixin.rangeTexturesSorting,
                                                get = function(info) return info.handler.db.profile.rangeCheck.inRangeAtlas end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.inRangeAtlas = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                    info.handler:Test()
                                                end,
                                            },
                                            inRangeCustomAtlas = {
                                                order = 2,
                                                name = L["Widget_RangeCheck_CustomAtlas"],
                                                desc = L["Widget_RangeCheck_CustomAtlas_Desc"],
                                                type = "input",
                                                width = 1.0,
                                                get = function(info) return info.handler.db.profile.rangeCheck.inRangeCustomAtlas end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.inRangeCustomAtlas = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                    info.handler:Test()
                                                end,
                                                hidden = function(info) return info.handler.db.profile.rangeCheck.inRangeAtlas ~= "custom" end,
                                            },
                                            inRangeColorEnabled = {
                                                order = 3,
                                                name = L["Color"],
                                                desc = L["Widget_RangeCheck_ColorEnabled_Desc"],
                                                type = "toggle",
                                                width = 0.4,
                                                get = function(info) return info.handler.db.profile.rangeCheck.inRangeColorEnabled end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.inRangeColorEnabled = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                    info.handler:Test()
                                                end,
                                                hidden = function(info) return info.handler.db.profile.rangeCheck.inRangeAtlas == "" end,
                                            },
                                            inRangeColor = {
                                                order = 4,
                                                name = "",
                                                type = "color",
                                                hasAlpha = true,
                                                width = 0.3,
                                                get = function(info)
                                                    local c = info.handler.db.profile.rangeCheck.inRangeColor
                                                    return c[1], c[2], c[3], c[4]
                                                end,
                                                set = function(info, r, g, b, a)
                                                    info.handler.db.profile.rangeCheck.inRangeColor = { r, g, b, a }
                                                    info.handler:ApplyRangeCheckTextures()
                                                    info.handler:Test()
                                                end,
                                                disabled = function(info)
                                                    local rc = info.handler.db.profile.rangeCheck
                                                    return not rc.enabled or rc.mode == "transparency" or not rc.inRangeColorEnabled
                                                end,
                                                hidden = function(info) return info.handler.db.profile.rangeCheck.inRangeAtlas == "" end,
                                            },
                                            inRangeSpacer = {
                                                order = 5,
                                                name = "",
                                                type = "description",
                                                width = "full",
                                            },
                                            inRangePosX = {
                                                order = 6,
                                                name = L["Horizontal"],
                                                type = "range",
                                                min = -200,
                                                max = 200,
                                                step = 0.1,
                                                bigStep = 1,
                                                width = 0.95,
                                                get = function(info) return info.handler.db.profile.rangeCheck.inRangePosX end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.inRangePosX = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                end,
                                            },
                                            inRangePosY = {
                                                order = 7,
                                                name = L["Vertical"],
                                                type = "range",
                                                min = -200,
                                                max = 200,
                                                step = 0.1,
                                                bigStep = 1,
                                                width = 0.95,
                                                get = function(info) return info.handler.db.profile.rangeCheck.inRangePosY end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.inRangePosY = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                end,
                                            },
                                            inRangeScale = {
                                                order = 8,
                                                name = L["Scale"],
                                                type = "range",
                                                min = 0.1,
                                                max = 3.0,
                                                step = 0.01,
                                                bigStep = 0.01,
                                                isPercent = true,
                                                width = 0.95,
                                                get = function(info) return info.handler.db.profile.rangeCheck.inRangeScale end,
                                                set = function(info, val)
                                                    info.handler.db.profile.rangeCheck.inRangeScale = val
                                                    info.handler:ApplyRangeCheckTextures()
                                                end,
                                            },
                                        },
                                    },
                                    resetRangeCheck = {
                                        order = 6,
                                        name = L["Reset"],
                                        width = 0.4,
                                        type = "execute",
                                        func = function(info)
                                            local defaults = sArenaMixin.defaultSettings.profile.rangeCheck
                                            local rc = info.handler.db.profile.rangeCheck
                                            local currentEnabled = rc.enabled
                                            for k, v in pairs(defaults) do
                                                if k ~= "enabled" then
                                                    if type(v) == "table" then
                                                        rc[k] = { unpack(v) }
                                                    else
                                                        rc[k] = v
                                                    end
                                                end
                                            end
                                            rc.enabled = currentEnabled
                                            info.handler:ApplyRangeCheckTextures()
                                            info.handler:Test()
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                        disabled = function(info) return not info.handler.db.profile.rangeCheck.enabled end,
                                    },
                                },
                            },
                            rangeSpellSettings = {
                                order = 2,
                                name = "Range Check Spells",
                                type = "group",
                                inline = true,
                                disabled = function(info) return not info.handler.db.profile.rangeCheck.enabled end,
                                args = (function()
                                    local rangeClassOrder = {
                                        "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
                                        "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK",
                                        "MONK", "DRUID", "DEMONHUNTER", "EVOKER",
                                    }
                                    local rangeClassSpecs = {
                                        WARRIOR     = { 71, 72, 73 },
                                        PALADIN     = { 65, 66, 70 },
                                        HUNTER      = { 253, 254, 255 },
                                        ROGUE       = { 259, 260, 261 },
                                        PRIEST      = { 256, 257, 258 },
                                        DEATHKNIGHT = { 250, 251, 252 },
                                        SHAMAN      = { 262, 263, 264 },
                                        MAGE        = { 62, 63, 64 },
                                        WARLOCK     = { 265, 266, 267 },
                                        MONK        = { 268, 269, 270 },
                                        DRUID       = { 102, 103, 104, 105 },
                                        DEMONHUNTER = { 577, 581, 1480 },
                                        EVOKER      = { 1467, 1468, 1473 },
                                    }
                                    local hiddenClasses = {}
                                    local hiddenSpecs = {}
                                    if sArenaMixin.isTBC then
                                        hiddenClasses = { DEATHKNIGHT = true, MONK = true, DEMONHUNTER = true, EVOKER = true }
                                        hiddenSpecs = { [104] = true } -- Guardian Druid
                                    elseif sArenaMixin.isWrath then
                                        hiddenClasses = { MONK = true, DEMONHUNTER = true, EVOKER = true }
                                    elseif sArenaMixin.isMoP then
                                        hiddenClasses = { DEMONHUNTER = true, EVOKER = true }
                                    end
                                    local classIDs = {
                                        WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5,
                                        DEATHKNIGHT = 6, SHAMAN = 7, MAGE = 8, WARLOCK = 9,
                                        MONK = 10, DRUID = 11, DEMONHUNTER = 12, EVOKER = 13,
                                    }
                                    local function getClassName(classKey)
                                        if LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classKey] then
                                            return LOCALIZED_CLASS_NAMES_MALE[classKey]
                                        end
                                        return classKey
                                    end

                                    local useClassIDLookup = sArenaMixin.isTBC or sArenaMixin.isWrath or sArenaMixin.isMoP

                                    local function getSpecName(specID, classKey, specIndex)
                                        if useClassIDLookup and classKey and specIndex and GetSpecializationInfoForClassID then
                                            local classID = classIDs[classKey]
                                            if classID then
                                                local _, name = GetSpecializationInfoForClassID(classID, specIndex)
                                                if name then return name end
                                            end
                                        end
                                        if specID and GetSpecializationInfoByID then
                                            local _, name = GetSpecializationInfoByID(specID)
                                            if name then return name end
                                        end
                                        return tostring(specID or "?")
                                    end

                                    local function specIconLabel(specID, classKey, specIndex)
                                        if not specID then return "" end
                                        if useClassIDLookup and classKey and specIndex and GetSpecializationInfoForClassID then
                                            local classID = classIDs[classKey]
                                            if classID then
                                                local _, _, _, specTexture = GetSpecializationInfoForClassID(classID, specIndex)
                                                if specTexture then
                                                    return "|T" .. specTexture .. ":14|t "
                                                end
                                            end
                                        end
                                        if GetSpecializationInfoByID then
                                            local _, _, _, specTexture = GetSpecializationInfoByID(specID)
                                            if specTexture then
                                                return "|T" .. specTexture .. ":14|t "
                                            end
                                        end
                                        return ""
                                    end

                                    local function spellTooltip(activeID, defaultID)
                                        if not activeID then return L["Widget_RangeCheck_SpellID_Desc"] end
                                        local spellName, _, _, _, minRange, maxRange = GetSpellInfoCompat(activeID)
                                        local tip = (spellName or "Unknown") .. " (" .. activeID .. ")"
                                        if minRange and maxRange then
                                            if minRange > 0 then
                                                tip = tip .. "\nRange: " .. minRange .. "-" .. maxRange .. " yd"
                                            elseif maxRange > 0 then
                                                tip = tip .. "\nRange: " .. maxRange .. " yd"
                                            else
                                                tip = tip .. "\nRange: Melee"
                                            end
                                        end
                                        if defaultID then
                                            local defName = GetSpellInfoCompat(defaultID)
                                            tip = tip .. "\n\n|cff888888(default: " .. (defName or "Unknown") .. " (" .. defaultID .. "))|r"
                                        end
                                        return tip
                                    end

                                    local function spellNameByID(spellID)
                                        if not spellID then return nil end
                                        local name = GetSpellInfoCompat(spellID)
                                        return name
                                    end

                                    local function validateSpellID(info, value)
                                        if value == "" then return true end
                                        local num = tonumber(value)
                                        if not num or num <= 0 then
                                            return L["Widget_RangeCheck_SpellID_Desc"]
                                        end
                                        return true
                                    end

                                    local args = {}
                                    local orderCounter = 1

                                    for classIdx, classKey in ipairs(rangeClassOrder) do
                                      if not hiddenClasses[classKey] then
                                        local displayName = getClassName(classKey)
                                        local classColor = C_ClassColor.GetClassColor(classKey)
                                        local coloredName = displayName
                                        if classColor then
                                            coloredName = classColor:WrapTextInColorCode(displayName)
                                        end

                                        args["header_" .. classKey] = {
                                            order = orderCounter,
                                            name = coloredName,
                                            type = "description",
                                            fontSize = "medium",
                                            width = "full",
                                        }
                                        orderCounter = orderCounter + 1

                                        local specs = rangeClassSpecs[classKey]
                                        if specs then
                                            local gameSpecIdx = 0
                                            for specIdx, specID in ipairs(specs) do
                                              if not hiddenSpecs[specID] then
                                                gameSpecIdx = gameSpecIdx + 1
                                                local currentSpecIdx = gameSpecIdx
                                                local specName = getSpecName(specID, classKey, currentSpecIdx)
                                                local defaultSpecID = sArenaMixin.defaultRangeSpellsPerSpec[specID]

                                                args["spec_" .. specID] = {
                                                    order = orderCounter,
                                                    name = function(info)
                                                        local icon = specIconLabel(specID, classKey, currentSpecIdx)
                                                        local perSpec = info.handler.db.profile.rangeCheckSpellsPerSpec or {}
                                                        local activeID = perSpec[specID] or defaultSpecID
                                                        local sName = spellNameByID(activeID) or tostring(activeID or "?")
                                                        return icon .. specName .. "  |cff666666(" .. sName .. ")|r"
                                                    end,
                                                    desc = function(info)
                                                        local perSpec = info.handler.db.profile.rangeCheckSpellsPerSpec or {}
                                                        local activeID = perSpec[specID] or defaultSpecID
                                                        return spellTooltip(activeID, defaultSpecID)
                                                    end,
                                                    type = "input",
                                                    width = 0.8,
                                                    get = function(info)
                                                        local perSpec = info.handler.db.profile.rangeCheckSpellsPerSpec or {}
                                                        local id = perSpec[specID]
                                                        if id then return tostring(id) end
                                                        return defaultSpecID and tostring(defaultSpecID) or ""
                                                    end,
                                                    set = function(info, value)
                                                        local db = info.handler.db
                                                        local num = tonumber(value)
                                                        db.profile.rangeCheckSpellsPerSpec = db.profile.rangeCheckSpellsPerSpec or {}
                                                        if num and num ~= defaultSpecID then
                                                            db.profile.rangeCheckSpellsPerSpec[specID] = num
                                                        else
                                                            db.profile.rangeCheckSpellsPerSpec[specID] = nil
                                                        end
                                                        info.handler:UpdatePlayerRangeSpell()
                                                        info.handler:UpdateAllRangeChecks()
                                                        info.handler:Test()
                                                    end,
                                                    validate = validateSpellID,
                                                }
                                                orderCounter = orderCounter + 1
                                              end
                                            end
                                        end
                                      end
                                    end

                                    args["resetAllSpells"] = {
                                        order = 999,
                                        name = L["Reset"],
                                        width = 0.5,
                                        type = "execute",
                                        func = function(info)
                                            info.handler.db.profile.rangeCheckSpellsPerSpec = {}
                                            info.handler:UpdatePlayerRangeSpell()
                                            info.handler:UpdateAllRangeChecks()
                                            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                        end,
                                    }

                                    return args
                                end)(),
                            },
                        },
                    },
                    trinketsGroup = {
                        order = 9,
                        name = L["Category_Trinkets"],
                        type = "group",
                        args = {
                            trinketSound = {
                                order = 1,
                                name = L["Option_TrinketSound"],
                                type = "group",
                                inline = true,
                                args = {
                                    playTrinketSound = {
                                        order = 1,
                                        name = L["Option_PlayTrinketSound"],
                                        desc = L["Option_PlayTrinketSound_Desc"],
                                        type = "toggle",
                                        width = 0.9,
                                        get = function(info) return info.handler.db.profile.playTrinketSound end,
                                        set = function(info, val)
                                            info.handler.db.profile.playTrinketSound = val
                                            if val then
                                                local channel = info.handler.db.profile.trinketSoundChannel or "Master"
                                                local fileID = info.handler.db.profile.trinketSoundFileID
                                                if fileID and fileID ~= 0 then
                                                    PlaySound(fileID, channel)
                                                else
                                                    local path = LSM:Fetch(LSM.MediaType.SOUND, info.handler.db.profile.trinketSoundName)
                                                    if path then PlaySoundFile(path, channel) end
                                                end
                                            end
                                        end,
                                    },
                                    trinketSoundChannel = {
                                        order = 1.5,
                                        name = L["Option_TrinketSoundChannel"],
                                        desc = L["Option_TrinketSoundChannel_Desc"],
                                        type = "select",
                                        width = 0.5,
                                        values = {
                                            ["Master"] = "Master",
                                            ["SFX"] = "SFX",
                                            ["Music"] = "Music",
                                            ["Ambience"] = "Ambience",
                                            ["Dialog"] = "Dialog",
                                        },
                                        disabled = function(info) return not info.handler.db.profile.playTrinketSound end,
                                        get = function(info) return info.handler.db.profile.trinketSoundChannel or "Master" end,
                                        set = function(info, val)
                                            info.handler.db.profile.trinketSoundChannel = val
                                        end,
                                    },
                                    trinketSoundChannelSpacer = {
                                        order = 1.6,
                                        name = "",
                                        type = "description",
                                        width = "full",
                                    },
                                    trinketSoundName = {
                                        order = 2,
                                        width = 1.3,
                                        name = L["Option_TrinketSoundName"],
                                        desc = L["Option_TrinketSoundName_Desc"],
                                        type = "select",
                                        dialogControl = "LSM30_Sound",
                                        values = SoundValues,
                                        disabled = function(info) return not info.handler.db.profile.playTrinketSound end,
                                        get = function(info) return info.handler.db.profile.trinketSoundName end,
                                        set = function(info, val)
                                            info.handler.db.profile.trinketSoundName = val
                                            local channel = info.handler.db.profile.trinketSoundChannel or "Master"
                                            local path = LSM:Fetch(LSM.MediaType.SOUND, val)
                                            if path then PlaySoundFile(path, channel) end
                                        end,
                                    },
                                    trinketSoundFileID = {
                                        order = 3,
                                        name = L["Option_TrinketSoundFileID"],
                                        desc = L["Option_TrinketSoundFileID_Desc"],
                                        type = "input",
                                        width = 1.3,
                                        disabled = function(info) return not info.handler.db.profile.playTrinketSound end,
                                        get = function(info)
                                            local val = info.handler.db.profile.trinketSoundFileID
                                            return (val and val ~= 0) and tostring(val) or ""
                                        end,
                                        set = function(info, val)
                                            local id = tonumber(val) or 0
                                            info.handler.db.profile.trinketSoundFileID = id
                                            if id ~= 0 then PlaySound(id, info.handler.db.profile.trinketSoundChannel or "Master") end
                                        end,
                                    },
                                    trinketSoundFileIDSpacer = {
                                        order = 3.5,
                                        name = "",
                                        type = "description",
                                        width = "full",
                                    },
                                    healerTrinketSoundName = {
                                        order = 4,
                                        width = 1.3,
                                        name = L["Option_HealerTrinketSoundName"],
                                        desc = L["Option_HealerTrinketSoundName_Desc"],
                                        type = "select",
                                        dialogControl = "LSM30_Sound",
                                        values = SoundValues,
                                        disabled = function(info) return not info.handler.db.profile.playTrinketSound end,
                                        get = function(info) return info.handler.db.profile.healerTrinketSoundName end,
                                        set = function(info, val)
                                            info.handler.db.profile.healerTrinketSoundName = val
                                            local channel = info.handler.db.profile.trinketSoundChannel or "Master"
                                            local path = LSM:Fetch(LSM.MediaType.SOUND, val)
                                            if path then PlaySoundFile(path, channel) end
                                        end,
                                    },
                                    healerTrinketSoundFileID = {
                                        order = 5,
                                        name = L["Option_HealerTrinketSoundFileID"],
                                        desc = L["Option_HealerTrinketSoundFileID_Desc"],
                                        type = "input",
                                        width = 1.3,
                                        disabled = function(info) return not info.handler.db.profile.playTrinketSound end,
                                        get = function(info)
                                            local val = info.handler.db.profile.healerTrinketSoundFileID
                                            return (val and val ~= 0) and tostring(val) or ""
                                        end,
                                        set = function(info, val)
                                            local id = tonumber(val) or 0
                                            info.handler.db.profile.healerTrinketSoundFileID = id
                                            if id ~= 0 then PlaySound(id, info.handler.db.profile.trinketSoundChannel or "Master") end
                                        end,
                                    },
                                },
                            },
                            trinketGlow = {
                                order = 1.5,
                                name = L["Option_TrinketGlow"],
                                type = "group",
                                inline = true,
                                args = {
                                    trinketUseGlow = {
                                        order = 1,
                                        name = L["Option_TrinketUseGlow"],
                                        desc = L["Option_TrinketUseGlow_Desc"],
                                        type = "toggle",
                                        width = 1.1,
                                        get = function(info) return info.handler.db.profile.trinketUseGlow end,
                                        set = function(info, val)
                                            info.handler.db.profile.trinketUseGlow = val
                                            if val then
                                                local LCG = LibStub("LibCustomGlow-1.0", true)
                                                if LCG then
                                                    local color = info.handler.db.profile.trinketUseGlowColorEnabled and info.handler.db.profile.trinketUseGlowColor or nil
                                                    local healerOnly = info.handler.db.profile.trinketUseGlowHealerOnly
                                                    for i = 1, info.handler.maxArenaOpponents do
                                                        local frame = info.handler["arena" .. i]
                                                        if frame and frame.Trinket and frame.Trinket:IsVisible() and (not healerOnly or frame.isHealer) then
                                                            LCG.ButtonGlow_Start(frame.Trinket, color)
                                                            if frame.trinketGlowTimer then frame.trinketGlowTimer:Cancel() end
                                                            frame.trinketGlowTimer = C_Timer.NewTimer(1, function()
                                                                LCG.ButtonGlow_Stop(frame.Trinket)
                                                                frame.trinketGlowTimer = nil
                                                            end)
                                                        end
                                                    end
                                                end
                                            end
                                        end,
                                    },
                                    trinketUseGlowHealerOnly = {
                                        order = 2,
                                        name = L["Option_TrinketUseGlowHealerOnly"],
                                        desc = L["Option_TrinketUseGlowHealerOnly_Desc"],
                                        type = "toggle",
                                        width = "normal",
                                        disabled = function(info) return not info.handler.db.profile.trinketUseGlow end,
                                        get = function(info) return info.handler.db.profile.trinketUseGlowHealerOnly end,
                                        set = function(info, val)
                                            info.handler.db.profile.trinketUseGlowHealerOnly = val
                                        end,
                                    },
                                    spacer = {
                                        order = 2.5,
                                        type = "description",
                                        name = "",
                                    },
                                    trinketUseGlowColorEnabled = {
                                        order = 3,
                                        name = L["Option_TrinketUseGlowColorEnabled"],
                                        desc = L["Option_TrinketUseGlowColorEnabled_Desc"],
                                        type = "toggle",
                                        width = "normal",
                                        disabled = function(info) return not info.handler.db.profile.trinketUseGlow end,
                                        get = function(info) return info.handler.db.profile.trinketUseGlowColorEnabled end,
                                        set = function(info, val)
                                            info.handler.db.profile.trinketUseGlowColorEnabled = val
                                            if info.handler.db.profile.trinketUseGlow then
                                                local LCG = LibStub("LibCustomGlow-1.0", true)
                                                if LCG then
                                                    local healerOnly = info.handler.db.profile.trinketUseGlowHealerOnly
                                                    local glowColor = val and info.handler.db.profile.trinketUseGlowColor or nil
                                                    for i = 1, info.handler.maxArenaOpponents do
                                                        local frame = info.handler["arena" .. i]
                                                        if frame and frame.Trinket and frame.Trinket:IsVisible() and (not healerOnly or frame.isHealer) then
                                                            LCG.ButtonGlow_Start(frame.Trinket, glowColor)
                                                            if frame.trinketGlowTimer then frame.trinketGlowTimer:Cancel() end
                                                            frame.trinketGlowTimer = C_Timer.NewTimer(1, function()
                                                                LCG.ButtonGlow_Stop(frame.Trinket)
                                                                frame.trinketGlowTimer = nil
                                                            end)
                                                        end
                                                    end
                                                end
                                            end
                                        end,
                                    },
                                    trinketUseGlowColor = {
                                        order = 4,
                                        name = L["Option_TrinketUseGlowColor"],
                                        type = "color",
                                        hasAlpha = true,
                                        width = "normal",
                                        disabled = function(info) return not info.handler.db.profile.trinketUseGlow or not info.handler.db.profile.trinketUseGlowColorEnabled end,
                                        get = function(info)
                                            local c = info.handler.db.profile.trinketUseGlowColor or { 1, 1, 1, 1 }
                                            return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
                                        end,
                                        set = function(info, r, g, b, a)
                                            info.handler.db.profile.trinketUseGlowColor = { r, g, b, a }
                                            if info.handler.db.profile.trinketUseGlow then
                                                local LCG = LibStub("LibCustomGlow-1.0", true)
                                                if LCG then
                                                    local healerOnly = info.handler.db.profile.trinketUseGlowHealerOnly
                                                    for i = 1, info.handler.maxArenaOpponents do
                                                        local frame = info.handler["arena" .. i]
                                                        if frame and frame.Trinket and frame.Trinket:IsVisible() and (not healerOnly or frame.isHealer) then
                                                            LCG.ButtonGlow_Start(frame.Trinket, { r, g, b, a })
                                                            if frame.trinketGlowTimer then frame.trinketGlowTimer:Cancel() end
                                                            frame.trinketGlowTimer = C_Timer.NewTimer(1, function()
                                                                LCG.ButtonGlow_Stop(frame.Trinket)
                                                                frame.trinketGlowTimer = nil
                                                            end)
                                                        end
                                                    end
                                                end
                                            end
                                        end,
                                    },
                                },
                            },
                            trinketColors = {
                                order = 2,
                                name = L["Option_ColorTrinket"],
                                type = "group",
                                inline = true,
                                args = {
                                    colorTrinket = {
                                        order = 1,
                                        name = L["Option_ColorTrinket"],
                                        type = "toggle",
                                        width = 0.6,
                                        desc = L["Trinket_MinimalistDesign_Desc"],
                                        get = function(info) return info.handler.db.profile.colorTrinket end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorTrinket = val
                                            local colors = info.handler.db.profile.trinketColors
                                            local keepTexture = info.handler.db.profile.colorTrinketKeepTexture
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if val then
                                                    if keepTexture then
                                                        frame.Trinket.Texture:SetDesaturated(true)
                                                    else
                                                        frame.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                                                    end
                                                    if i <= 2 then
                                                        frame.Trinket.Texture:SetVertexColor(unpack(colors.available))
                                                        frame.Trinket.Cooldown:Clear()
                                                    else
                                                        frame.Trinket.Texture:SetVertexColor(unpack(colors.used))
                                                    end
                                                else
                                                    frame.Trinket.Texture:SetTexture(info.handler.trinketTexture)
                                                    frame.Trinket.Texture:SetDesaturated(false)
                                                    frame.Trinket.Texture:SetVertexColor(1, 1, 1)
                                                end
                                            end
                                        end,
                                    },
                                    trinketColorAvailable = {
                                        order = 2,
                                        type = "color",
                                        name = L["Option_TrinketColorAvailable"],
                                        width = 0.5,
                                        disabled = function(info) return not info.handler.db.profile.colorTrinket end,
                                        get = function(info)
                                            return unpack(info.handler.db.profile.trinketColors.available)
                                        end,
                                        set = function(info, r, g, b)
                                            info.handler.db.profile.trinketColors.available = {r, g, b}
                                            local used = info.handler.db.profile.trinketColors.used
                                            local keepTexture = info.handler.db.profile.colorTrinketKeepTexture
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if frame and info.handler.db.profile.colorTrinket then
                                                    if not keepTexture then
                                                        frame.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                                                    end
                                                    if i <= 2 then
                                                        frame.Trinket.Texture:SetVertexColor(r, g, b)
                                                    else
                                                        frame.Trinket.Texture:SetVertexColor(unpack(used))
                                                    end
                                                end
                                            end
                                        end,
                                    },
                                    trinketColorUsed = {
                                        order = 3,
                                        type = "color",
                                        name = L["Option_TrinketColorUsed"],
                                        width = 0.6,
                                        disabled = function(info) return not info.handler.db.profile.colorTrinket end,
                                        get = function(info)
                                            return unpack(info.handler.db.profile.trinketColors.used)
                                        end,
                                        set = function(info, r, g, b)
                                            info.handler.db.profile.trinketColors.used = {r, g, b}
                                            local available = info.handler.db.profile.trinketColors.available
                                            local keepTexture = info.handler.db.profile.colorTrinketKeepTexture
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if frame and info.handler.db.profile.colorTrinket then
                                                    if not keepTexture then
                                                        frame.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                                                    end
                                                    if i <= 2 then
                                                        frame.Trinket.Texture:SetVertexColor(unpack(available))
                                                    else
                                                        frame.Trinket.Texture:SetVertexColor(r, g, b)
                                                    end
                                                end
                                            end
                                        end,
                                    },
                                    colorTrinketKeepTextureSpacer = {
                                        order = 4,
                                        type = "description",
                                        name = "",
                                    },
                                    colorTrinketKeepTexture = {
                                        order = 5,
                                        name = L["Option_ColorTrinketKeepTexture"],
                                        type = "toggle",
                                        width = "full",
                                        desc = L["Option_ColorTrinketKeepTexture_Desc"],
                                        disabled = function(info) return not info.handler.db.profile.colorTrinket end,
                                        get = function(info) return info.handler.db.profile.colorTrinketKeepTexture end,
                                        set = function(info, val)
                                            info.handler.db.profile.colorTrinketKeepTexture = val
                                            local colors = info.handler.db.profile.trinketColors
                                            for i = 1, info.handler.maxArenaOpponents do
                                                local frame = info.handler["arena" .. i]
                                                if info.handler.db.profile.colorTrinket then
                                                    if val then
                                                        frame.Trinket.Texture:SetTexture(info.handler.trinketTexture)
                                                        frame.Trinket.Texture:SetDesaturated(true)
                                                    else
                                                        frame.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                                                        frame.Trinket.Texture:SetDesaturated(false)
                                                    end
                                                    if i <= 2 then
                                                        frame.Trinket.Texture:SetVertexColor(unpack(colors.available))
                                                    else
                                                        frame.Trinket.Texture:SetVertexColor(unpack(colors.used))
                                                    end
                                                end
                                            end
                                        end,
                                    },
                                },
                            },
                        },
                    },
                    importOtherForkSettings = {
                        order = 10,
                        name = L["Option_OthersArena"],
                        desc = L["Option_OthersArena_Desc"],
                        type = "group",
                        args = {
                            description = {
                                order = 1,
                                type = "description",
                                name = L["Option_ImportDescription"],
                                fontSize = "medium",
                            },
                            convertButton = {
                                order = 2,
                                type = "execute",
                                name = L["Option_ImportSettings"],
                                desc = L["Option_ImportSettings_Desc"],
                                func = "ImportOtherForkSettings",
                                width = "normal",
                                disabled = function(info) return info.handler.conversionInProgress end,
                            },
                            conversionStatus = {
                                order = 2.5,
                                type = "description",
                                name = function(info) return info.handler.conversionStatusText or "" end,
                                fontSize = "medium",
                                hidden = function(info) return not info.handler.conversionStatusText or info.handler.conversionStatusText == "" end,
                            },
                        },
                    },
                },
            },
            streamerProfiles = {
                order = 8,
                name = L["Option_StreamerProfilesHeader"],
                desc = L["Option_StreamerProfiles_Desc_Tab"],
                type = "group",
                args = {
                    streamerProfilesDesc = {
                        order = 1,
                        type = "description",
                        name = function(info)
                            local name, realm = UnitName("player")
                            realm = realm or GetRealmName()
                            local fullKey = name .. " - " .. realm
                            local currentProfileKey = sArena_ReloadedDB.profileKeys[fullKey] or "Default"
                            return string.format(L["Option_StreamerProfiles_Desc"], currentProfileKey)
                        end,
                        fontSize = "medium",
                    },
                    streamerProfilesGroup = {
                        order = 2,
                        type = "group",
                        name = "",
                        inline = true,
                        args = sArenaMixin:BuildStreamerProfileArgs(),
                    },
                    streamerProfilesSpacer = {
                        order = 3,
                        type = "description",
                        name = " ",
                    },
                    streamerProfilesMissing = {
                        order = 4,
                        type = "description",
                        name = L["Option_StreamerProfiles_Missing"],
                        fontSize = "medium",
                    },
                    discordSpacer = {
                        order = 5,
                        type = "description",
                        name = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n",
                    },
                    discordTitle = {
                        order = 5.5,
                        type = "description",
                        name = L["Option_DiscordLink"],
                        fontSize = "large",
                    },
                    discordLink = {
                        order = 6,
                        name = "",
                        type = "input",
                        width = 1.5,
                        dialogControl = "EditBox",
                        get = function()
                            return "https://discord.gg/cjqVaEMm25"
                        end,
                        set = function() end,
                    },
                    discordTitleTip = {
                        order = 6.5,
                        type = "description",
                        name = L["Option_DiscordLink_Desc"],
                        fontSize = "medium",
                    },
                    discordTitleAddons = {
                        order = 6.6,
                        type = "description",
                        name = L["Option_DiscordLink_Addons"],
                        fontSize = "medium",
                    },
                },
            },
            importExport = {
                order = 9,
                name = L["Option_ImportExport"],
                desc = L["Option_ImportExport_Desc"],
                type = "group",
                args = {
                    exportHeader = {
                        order = 0,
                        type = "description",
                        name = L["Option_ExportProfileHeader"],
                        fontSize = "large",
                    },
                    exportButton = {
                        order = 1,
                        name = L["Option_ExportCurrentProfile"],
                        type = "execute",
                        func = function(info)
                            local exportString, err = info.handler:ExportProfile()
                            if not err then
                                info.handler.exportString = exportString
                                info.handler.importInputText = ""
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
                                C_Timer.After(0.1, function()
                                    local AceGUI = LibStub("AceGUI-3.0")
                                    for i = 1, AceGUI:GetWidgetCount("MultiLineEditBox") do
                                        local editBox = _G[("MultiLineEditBox%dEdit"):format(i)]
                                        if editBox and editBox:IsVisible() then
                                            local text = editBox:GetText()
                                            if text and text:match("^!sArena:") then
                                                editBox:SetFocus()
                                                editBox:HighlightText(0, text:len())
                                                break
                                            end
                                        end
                                    end
                                end)
                            else
                                info.handler:Print(L["Message_ExportFailed"] .. " " .. err)
                            end
                        end,
                        width = "normal",
                    },
                    exportText = {
                        order = 2,
                        name = L["Option_ExportString"],
                        type = "input",
                        desc = L["Option_ExportString_Desc"],
                        width = "full",
                        multiline = 5,
                        get = function(info)
                            return info.handler.exportString or ""
                        end,
                        set = function() end,
                    },
                    spacer = {
                        order = 3,
                        type = "description",
                        name = " ",
                    },
                    importHeader = {
                        order = 4,
                        type = "description",
                        name = L["Option_ImportProfileHeader"],
                        fontSize = "large",
                    },
                    importInput = {
                        order = 5,
                        name = L["Option_PasteProfileString"],
                        desc = L["Option_PasteProfileString_Desc"],
                        type = "input",
                        width = "full",
                        multiline = 5,
                        get = function(info)
                            return info.handler.importInputText or ""
                        end,
                        set = function(info, val)
                            info.handler.importInputText = val
                            local str = info.handler.importInputText
                            local success, err = info.handler:ImportProfile(str)
                            if not success then
                                info.handler:Print(L["Message_ImportFailed"] .. " " .. err)
                            else
                                sArena_ReloadedDB.reOpenOptions = true
                            end
                        end,
                    },
                },
            }
        },
    }
end
