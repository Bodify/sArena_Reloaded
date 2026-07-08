-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local L = sArenaMixin.L

local CLASS_COLORS = {
    ROGUE = "|cfffff569", WARRIOR = "|cffc79c6e", MAGE = "|cff40c7eb",
    DRUID = "|cffff7d0a", HUNTER = "|cffabd473", PRIEST = "|cffffffff",
    WARLOCK = "|cff8787ed", SHAMAN = "|cff0070de", PALADIN = "|cfff58cba",
    DEATHKNIGHT = "|cffc41f3b", MONK = "|cff00ff96",
    DEMONHUNTER = "|cffa330c9", EVOKER = "|cff33937f",
}

local CLASS_ICONS = {
    ROGUE = "groupfinder-icon-class-rogue",
    WARRIOR = "groupfinder-icon-class-warrior",
    MAGE = "groupfinder-icon-class-mage",
    DRUID = "groupfinder-icon-class-druid",
    HUNTER = "groupfinder-icon-class-hunter",
    PRIEST = "groupfinder-icon-class-priest",
    WARLOCK = "groupfinder-icon-class-warlock",
    SHAMAN = "groupfinder-icon-class-shaman",
    PALADIN = "groupfinder-icon-class-paladin",
    DEATHKNIGHT = "groupfinder-icon-class-deathknight",
    MONK = "groupfinder-icon-class-monk",
    DEMONHUNTER = "groupfinder-icon-class-demonhunter",
    EVOKER = "groupfinder-icon-class-evoker",
    SKILLCAPPED = "Interface/AddOns/sArena_Reloaded/Textures/scIcon.blp",
}

local function ColorLayout(layoutKey)
    if layoutKey:find("^Blizz") then
        return "|cff00b4ffBlizz|r" .. layoutKey:sub(6)
    end
    return layoutKey
end

local function ProfileDisplayText(profile)
    local color = CLASS_COLORS[profile.class] or "|cffffffff"
    local icon = CLASS_ICONS[profile.class] or "groupfinder-icon-role-leader"
    if profile.class == "SKILLCAPPED" then
        return string.format("|T%s:14:14:0:0|t %s%s|r", icon, color, profile.name)
    end
    return string.format("|A:%s:16:16|a %s%s|r", icon, color, profile.name)
end

local POPUP_DEFAULTS = {
    button1 = "Yes", button2 = "No", timeout = 0,
    whileDead = true, preferredIndex = 3,
    OnAccept = function(_, data) if data and data.func then data.func() end end,
    OnCancel = function(_, data) if data and data.cancel then data.cancel() end end,
    OnHide = function(_, data) if data and data.onHide then data.onHide() end end,
}

function sArenaMixin:ShowWelcomePopup()
    if sArenaMixin.IntroWindow then
        sArenaMixin.IntroWindow:ClearAllPoints()
        sArenaMixin.IntroWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 45)
        sArenaMixin.IntroWindow:Show()
        return
    end

    local versionNumber = C_AddOns.GetAddOnMetadata("sArena_Reloaded", "Version") or ""

    local window = CreateFrame("Frame", "sArenaIntro", UIParent, "PortraitFrameTemplate")
    sArenaMixin.IntroWindow = window
    window:SetSize(470, 550)
    window.Bg:SetDesaturated(true)
    window.Bg:SetVertexColor(0.5, 0.5, 0.5, 0.98)
    window:SetPoint("CENTER", UIParent, "CENTER", -70, 45)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetTitle("sArena |cffff8000Reloaded|r " .. versionNumber)
    window:SetFrameStrata("DIALOG")

    window.textureTop = window:CreateTexture(nil, "BACKGROUND", nil, 3)
    window.textureTop:SetAtlas("communities-widebackground")
    window.textureTop:SetSize(465, 150)
    window.textureTop:SetPoint("TOP", window, "TOP", 0, -15)

    local maskTexture = window:CreateMaskTexture()
    maskTexture:SetAtlas("Azerite-CenterBG-ChannelGlowBar-FillingMask")
    maskTexture:SetSize(665, 300)
    maskTexture:SetPoint("CENTER", window.textureTop, "CENTER", 0, 50)
    window.textureTop:AddMaskTexture(maskTexture)
    window:SetPortraitToAsset(135884)

    local welcomeText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge2")
    welcomeText:SetPoint("TOP", window, "TOP", 0, -45)
    welcomeText:SetText(L["Intro_Welcome"])
    welcomeText:SetJustifyH("CENTER")

    local description = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    description:SetPoint("TOP", welcomeText, "BOTTOM", 0, -10)
    description:SetText(L["Intro_Description"])
    description:SetJustifyH("CENTER")
    description:SetWidth(410)

    local btnWidth, btnHeight, btnGap = 114, 30, -3

    local function CreateIntroButton(parent, displayText, onClick)
        local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
        button:SetSize(btnWidth, btnHeight)
        button:SetText(displayText)
        button:SetNormalFontObject("GameFontNormal")
        button:SetHighlightFontObject("GameFontHighlight")
        local f, s = button.Text:GetFont()
        button.Text:SetFont(f, s, self:GetFontFlags("OUTLINE"))
        local _, b, _, _, e = button.Text:GetPoint()
        button.Text:SetPoint("LEFT", b, "LEFT", 10, e - 0.6)
        button:SetScript("OnClick", function() if onClick then onClick() end end)
        return button
    end

    for _, name in ipairs({ "SARENA_INTRO_CONFIRM_LAYOUT", "SARENA_INTRO_CONFIRM_PROFILE" }) do
        StaticPopupDialogs[name] = {
            text = "",
            button1 = POPUP_DEFAULTS.button1, button2 = POPUP_DEFAULTS.button2,
            OnAccept = POPUP_DEFAULTS.OnAccept, OnCancel = POPUP_DEFAULTS.OnCancel,
            OnHide = POPUP_DEFAULTS.OnHide,
            timeout = POPUP_DEFAULTS.timeout, whileDead = POPUP_DEFAULTS.whileDead,
            preferredIndex = POPUP_DEFAULTS.preferredIndex,
        }
    end

    local originalLayout = sArenaMixin.db and sArenaMixin.db.profile.currentLayout or "Gladiuish"
    local activePreview, hoverTimer, previewLocked = nil, nil, false
    local applied = false

    local function CancelHoverTimer()
        if hoverTimer then hoverTimer:Cancel() hoverTimer = nil end
    end

    local CancelRevertToDefault = function() end
    local ScheduleRevertToDefault = function() end

    local function RevertActivePreview()
        if applied then return end
        CancelHoverTimer()
        CancelRevertToDefault()
        if activePreview == "profile" and _G.sArena and _G.sArena.RevertProfilePreview then
            _G.sArena:RevertProfilePreview()
        end
        if _G.sArena and _G.sArena.PreviewLayout and _G.sArena.db
            and _G.sArena.db.profile.currentLayout ~= originalLayout
        then
            _G.sArena:PreviewLayout(originalLayout)
        end
        activePreview = nil
    end

    local function EnsureTestMode()
        if _G.sArena and not _G.sArena.testMode then _G.sArena:Test() end
    end

    local function ApplyLayoutAndClose(layoutKey)
        sArena_ReloadedDB.isFirstUse = nil
        applied = true
        RevertActivePreview()
        CancelRevertToDefault()
        ;(_G.sArena or sArenaMixin):SetLayout(nil, layoutKey)
        window:Hide()
        LibStub("AceConfigDialog-3.0"):Open("sArena")
    end

    local function ApplyProfileAndClose(profile)
        sArena_ReloadedDB.isFirstUse = nil
        CancelHoverTimer()
        CancelRevertToDefault()
        activePreview = nil
        applied = true
        window:Hide()
        local color = CLASS_COLORS[profile.class] or "|cffffffff"
        ;(_G.sArena or sArenaMixin):ImportStreamerProfile(
            profile.name:gsub(" ", ""), profile.importString,
            profile.name, color, profile.class
        )
    end

    local function ForcePreviewLayout(layoutKey)
        CancelHoverTimer()
        CancelRevertToDefault()
        if InCombatLockdown() or not _G.sArena then return end
        if activePreview == "profile" and _G.sArena.RevertProfilePreview then
            _G.sArena:RevertProfilePreview()
            activePreview = nil
        end
        if _G.sArena.PreviewLayout then _G.sArena:PreviewLayout(layoutKey) end
        EnsureTestMode()
        activePreview = "layout"
    end

    local function ForcePreviewProfile(profile)
        CancelHoverTimer()
        CancelRevertToDefault()
        if InCombatLockdown() or not _G.sArena then return end
        if activePreview == "layout" and _G.sArena.PreviewLayout then
            _G.sArena:PreviewLayout(originalLayout)
        end
        if _G.sArena.PreviewProfile then _G.sArena:PreviewProfile(profile.importString) end
        EnsureTestMode()
        activePreview = "profile"
    end

    local function ShowLayoutConfirmation(layoutKey)
        StaticPopupDialogs["SARENA_INTRO_CONFIRM_LAYOUT"].text =
            string.format(L["Intro_Confirm_Layout"], ColorLayout(layoutKey))
        ForcePreviewLayout(layoutKey)
        previewLocked = true
        StaticPopup_Show("SARENA_INTRO_CONFIRM_LAYOUT", nil, nil, {
            func = function() ApplyLayoutAndClose(layoutKey) end,
            onHide = function()
                if previewLocked then
                    previewLocked = false
                    ScheduleRevertToDefault()
                end
            end,
        })
    end

    local function ShowProfileConfirmation(profile)
        StaticPopupDialogs["SARENA_INTRO_CONFIRM_PROFILE"].text =
            string.format(L["Intro_Confirm_Profile"], ProfileDisplayText(profile))
        ForcePreviewProfile(profile)
        previewLocked = true
        StaticPopup_Show("SARENA_INTRO_CONFIRM_PROFILE", nil, nil, {
            func = function() ApplyProfileAndClose(profile) end,
            onHide = function()
                if previewLocked then
                    previewLocked = false
                    ScheduleRevertToDefault()
                end
            end,
        })
    end

    local HOVER_DELAY = 0.15
    local REVERT_TO_DEFAULT_DELAY = 0.5

    local revertToken = 0
    CancelRevertToDefault = function() revertToken = revertToken + 1 end
    ScheduleRevertToDefault = function()
        if previewLocked or applied then return end
        revertToken = revertToken + 1
        local token = revertToken
        C_Timer.After(REVERT_TO_DEFAULT_DELAY, function()
            if token ~= revertToken then return end
            if applied then return end
            if InCombatLockdown() or not _G.sArena then return end
            if activePreview == "profile" and _G.sArena.RevertProfilePreview then
                _G.sArena:RevertProfilePreview()
            end
            if _G.sArena.PreviewLayout then _G.sArena:PreviewLayout(originalLayout) end
            EnsureTestMode()
            activePreview = "layout"
        end)
    end

    local function PreviewLayoutOnHover(layoutKey)
        if previewLocked then return end
        CancelHoverTimer()
        CancelRevertToDefault()
        hoverTimer = C_Timer.NewTimer(HOVER_DELAY, function()
            hoverTimer = nil
            if InCombatLockdown() or not _G.sArena then return end
            if activePreview == "profile" and _G.sArena.RevertProfilePreview then
                _G.sArena:RevertProfilePreview()
                activePreview = nil
            end
            if _G.sArena.PreviewLayout then _G.sArena:PreviewLayout(layoutKey) end
            EnsureTestMode()
            activePreview = "layout"
        end)
    end

    local function PreviewProfileOnHover(profile)
        if previewLocked then return end
        CancelHoverTimer()
        CancelRevertToDefault()
        hoverTimer = C_Timer.NewTimer(HOVER_DELAY, function()
            hoverTimer = nil
            if InCombatLockdown() or not _G.sArena then return end
            if activePreview == "layout" and _G.sArena.PreviewLayout then
                _G.sArena:PreviewLayout(originalLayout)
                activePreview = nil
            end
            EnsureTestMode()
            if _G.sArena.PreviewProfile and _G.sArena:PreviewProfile(profile.importString) then
                activePreview = "profile"
            end
        end)
    end

    local function NewGrid(anchorTop, columnOffsets, firstRowYOffset)
        return {
            anchors = { anchorTop, anchorTop, anchorTop },
            firstRow = { true, true, true },
            offsets = columnOffsets,
            firstY = firstRowYOffset,
            index = 1,
            place = function(self, btn)
                local i = self.index
                if self.firstRow[i] then
                    btn:SetPoint("TOP", self.anchors[i], "BOTTOM", self.offsets[i], self.firstY)
                    self.firstRow[i] = false
                else
                    btn:SetPoint("TOP", self.anchors[i], "BOTTOM", 0, btnGap)
                end
                self.anchors[i] = btn
                self.index = i + 1
                if self.index > 3 then self.index = 1 end
                return i
            end,
        }
    end

    local function HookTooltip(btn, getText)
        btn:HookScript("OnEnter", function(self)
            local text, subText = getText()
            if text or subText then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if text then
                    GameTooltip:SetText(text, 1, 1, 1, 1, true)
                    if subText then
                        GameTooltip:AddLine(subText, 0.6, 0.6, 0.6, true)
                    end
                else
                    GameTooltip:SetText(subText, 0.6, 0.6, 0.6, true)
                end
                GameTooltip:Show()
            end
        end)
        btn:HookScript("OnLeave", function()
            GameTooltip:Hide()
            ScheduleRevertToDefault()
        end)
    end

    local layoutLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    layoutLabel:SetPoint("TOP", description, "BOTTOM", 0, -15)
    layoutLabel:SetText(L["Intro_LayoutsHeader"])
    layoutLabel:SetJustifyH("CENTER")
    layoutLabel:SetFont(sArenaMixin.pFont, 20, self:GetFontFlags("OUTLINE"))

    local layoutOrder = {}
    for key in pairs(sArenaMixin.layouts) do table.insert(layoutOrder, key) end
    table.sort(layoutOrder)

    local layoutGrid = NewGrid(layoutLabel, { -114, 0, 114 }, -8)

    for _, layoutKey in ipairs(layoutOrder) do
        if layoutKey ~= "Xaryu" then
            local label = ColorLayout(layoutKey)
            if layoutKey == "Gladiuish" then
                label = label .. " |A:transmog-icon-checkmark:16:16|a"
            end
            local btn = CreateIntroButton(window, label, function()
                ShowLayoutConfirmation(layoutKey)
            end)
            btn:HookScript("OnEnter", function() PreviewLayoutOnHover(layoutKey) end)
            HookTooltip(btn, function()
                if layoutKey == "Gladiuish" then return L["Intro_Tooltip_Gladiuish"] end
            end)
            layoutGrid:place(btn)
        end
    end

    local lastCol1Layout = layoutGrid.anchors[1]

    local profileLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    profileLabel:SetPoint("TOP", lastCol1Layout, "BOTTOM", 114, -15)
    profileLabel:SetText(L["Intro_StreamerProfilesHeader"])
    profileLabel:SetJustifyH("CENTER")
    profileLabel:SetFont(sArenaMixin.pFont, 18, self:GetFontFlags("OUTLINE"))

    local sortedProfiles = {}
    for _, profile in ipairs(sArenaMixin.streamProfiles) do
        table.insert(sortedProfiles, profile)
    end
    if sArenaMixin.layouts and sArenaMixin.layouts.Xaryu then
        table.insert(sortedProfiles, { name = "Xaryu", class = "MAGE", isLayout = true, layoutKey = "Xaryu" })
    end
    table.sort(sortedProfiles, function(a, b) return a.name < b.name end)

    local profileGrid = NewGrid(profileLabel, { -114, 0, 114 }, -8)
    local lastProfileCol1Button = profileLabel

    for _, profile in ipairs(sortedProfiles) do
        local btn = CreateIntroButton(window, ProfileDisplayText(profile), function()
            if profile.isLayout then ShowLayoutConfirmation(profile.layoutKey)
            else ShowProfileConfirmation(profile) end
        end)
        btn:HookScript("OnEnter", function()
            if profile.isLayout then PreviewLayoutOnHover(profile.layoutKey)
            else PreviewProfileOnHover(profile) end
        end)
        HookTooltip(btn, function()
            if profile.isLayout then
                return "twitch.tv/xaryu", string.format(L["Intro_UsingLayout"], profile.layoutKey)
            end
            local sub
            if profile.class == "SKILLCAPPED" then
                sub = string.format(L["Intro_UsingLayout"], "Gladiuish")
            elseif _G.sArena and _G.sArena.GetProfileLayoutName then
                local layoutName = _G.sArena:GetProfileLayoutName(profile.importString)
                if layoutName then
                    sub = string.format(L["Intro_UsingLayout"], layoutName)
                end
            end
            if profile.website then return profile.website, sub end
            if profile.twitchName then return "twitch.tv/" .. profile.twitchName, sub end
            return nil, sub
        end)
        if profileGrid:place(btn) == 1 then
            lastProfileCol1Button = btn
        end
    end

    local exitButton = CreateFrame("Button", nil, window, "GameMenuButtonTemplate")
    exitButton:SetSize(btnWidth, btnHeight)
    exitButton:SetText(L["Intro_ExitButton"])
    exitButton:SetPoint("TOP", lastProfileCol1Button, "BOTTOM", 114, -35)
    exitButton:SetNormalFontObject("GameFontNormal")
    exitButton:SetHighlightFontObject("GameFontHighlight")
    exitButton:SetScript("OnClick", function()
        sArena_ReloadedDB.isFirstUse = nil
        RevertActivePreview()
        window:Hide()
        LibStub("AceConfigDialog-3.0"):Open("sArena")
    end)
    HookTooltip(exitButton, function() return L["Intro_Tooltip_ExitNoProfile"] end)
    local f, s = exitButton.Text:GetFont()
    exitButton.Text:SetFont(f, s, self:GetFontFlags("OUTLINE"))

    window.CloseButton:HookScript("OnClick", RevertActivePreview)
    window:HookScript("OnHide", RevertActivePreview)

    local layoutRows = math.ceil(#layoutOrder / 3)
    local profileRows = math.ceil(#sortedProfiles / 3)
    window:SetSize(470, 350 + (layoutRows + profileRows) * 29)
end
