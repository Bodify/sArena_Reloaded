-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local isRetail = sArenaMixin.isRetail
local isMidnight = sArenaMixin.isMidnight
local isTBC = sArenaMixin.isTBC
local noEarlyFrames = sArenaMixin.isTBC or sArenaMixin.isWrath

function sArenaMixin:GetSpecNameByID(specId)
    if GetSpecializationInfoByID then
        local _, name = GetSpecializationInfoByID(specId)
        if name then return name end
    end
    local info = self.specInfo[specId]
    return info and info.name or "Unknown"
end

function sArenaFrameMixin:SetUnitAuraRegistration()
    local db = self.parent and self.parent.db
    if db and db.profile.disableAurasOnClassIcon then
        self:UnregisterEvent("UNIT_AURA")
    else
        self:RegisterUnitEvent("UNIT_AURA", self.unit)
    end
end

function sArenaFrameMixin:RegisterFrameEvents()
    local unit = self.unit

    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_NAME_UPDATE")
    self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    self:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    self:RegisterUnitEvent("UNIT_HEALTH", unit)
    self:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    self:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
    self:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    self:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit)
    self:SetUnitAuraRegistration()

    if not isMidnight then
        self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
        self:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit)
        self:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
    end
end

function sArenaFrameMixin:HookMidnightTrinket()
    local blizzArenaFrame = _G["CompactArenaFrameMember" .. self:GetID()]
    local trinketFrame = blizzArenaFrame.CcRemoverFrame
    if trinketFrame then
        trinketFrame:SetParent(self)
        trinketFrame:SetAlpha(0)
        hooksecurefunc(trinketFrame.Cooldown, "SetCooldown", function(_, start, duration)
            local db = self.parent and self.parent.db
            self.Trinket.Cooldown:SetCooldown(start, duration)
            self.Trinket.Texture:SetDesaturated(db and db.profile.desaturateTrinketCD and not db.profile.colorTrinket)
            if db and db.profile.colorTrinket then
                self.Trinket.Texture:SetColorTexture(1, 0, 0)
            end
        end)

        hooksecurefunc(trinketFrame.Icon, "SetTexture", function(_, texture)
            local db = self.parent and self.parent.db
            if db and db.profile.colorTrinket then
                self.Trinket.Texture:SetColorTexture(0, 1, 0)
            else
                if texture ~= "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK.BLP" then
                    self.Trinket.Texture:SetTexture(texture)
                end
            end
        end)

        trinketFrame.Cooldown:HookScript("OnCooldownDone", function()
            local db = self.parent and self.parent.db
            if db and db.profile.colorTrinket then
                self.Trinket.Texture:SetColorTexture(0, 1, 0)
            end
        end)
    end
end

function sArenaMixin:UpdateBlizzArenaFrameVisibility(instanceType)
    if isRetail and not noEarlyFrames then
        -- Hide Blizzard Arena Frames while in Arena
        if CompactArenaFrame.isHidden then return end
        CompactArenaFrame.isHidden = true
        local ArenaAntiMalware = CreateFrame("Frame")
        ArenaAntiMalware:Hide()

        --Event list
        local events = {
            "PLAYER_ENTERING_WORLD",
            "ZONE_CHANGED_NEW_AREA",
            "ARENA_OPPONENT_UPDATE",
            "ARENA_PREP_OPPONENT_SPECIALIZATIONS",
            "PVP_MATCH_STATE_CHANGED"
        }

        -- Change parent and hide
        local function MalwareProtector()
            if InCombatLockdown() then return end
            local instanceType = select(2, IsInInstance())
            if instanceType == "arena" then
                CompactArenaFrame:SetParent(ArenaAntiMalware)
                CompactArenaFrameTitle:SetParent(ArenaAntiMalware)
            end
        end

        -- Event handler function
        ArenaAntiMalware:SetScript("OnEvent", function(self, event, ...)
            MalwareProtector()
            C_Timer.After(0, MalwareProtector)     --been instances of this god forsaken frame popping up so lets try to also do it one frame later
        end)

        -- Register the events
        for _, event in ipairs(events) do
            ArenaAntiMalware:RegisterEvent(event)
        end

        -- Shouldn't be needed, but you know what, fuck it
        CompactArenaFrame:HookScript("OnLoad", MalwareProtector)
        CompactArenaFrame:HookScript("OnShow", MalwareProtector)
        CompactArenaFrameTitle:HookScript("OnLoad", MalwareProtector)
        CompactArenaFrameTitle:HookScript("OnShow", MalwareProtector)

        MalwareProtector()
    else
        -- Hide Blizzard Arena Frames while in Arena
        if InCombatLockdown() then return end
        local prepFrame = _G["ArenaPrepFrames"]
        local enemyFrame = _G["ArenaEnemyFrames"]

        if (not self.blizzFrame) then
            self.blizzFrame = CreateFrame("Frame")
            self.blizzFrame:Hide()
        end

        if instanceType == "arena" then
            if prepFrame then
                prepFrame:SetParent(self.blizzFrame)
                self.changedDefaultFrameParent = true
            end
            if enemyFrame then
                enemyFrame:SetParent(self.blizzFrame)
                self.changedDefaultFrameParent = true
            end
        else
            if self.changedDefaultFrameParent then
                if prepFrame then
                    prepFrame:SetParent(UIParent)
                end
                if enemyFrame then
                    enemyFrame:SetParent(UIParent)
                end
            end
        end
    end
end

function sArenaMixin:UpdateCDTextVisibility()
    local db = self.db
    if not db then return end

    local hideClassIcon = db.profile.disableCDTextClassIcon
    local hideDR = db.profile.disableCDTextDR
    local hideTrinket = db.profile.disableCDTextTrinket
    local hideRacial = db.profile.disableCDTextRacial
    local isMidnight = sArenaMixin.isMidnight

    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not frame then break end

        -- Class Icon
        local classIconCD = frame.ClassIcon and frame.ClassIcon.Cooldown
        if classIconCD then
            local hideDefaultCD = hideClassIcon or classIconCD.hideDefaultCD
            classIconCD:SetHideCountdownNumbers(hideDefaultCD and true or false)
            if classIconCD.Text then
                classIconCD.Text:SetAlpha(hideDefaultCD and 0 or 1)
            end
            if classIconCD.sArenaText then
                classIconCD.sArenaText:SetAlpha(hideClassIcon and 0 or 1)
            end
        end

        -- Trinket
        local trinketCD = frame.Trinket and frame.Trinket.Cooldown
        if trinketCD then
            trinketCD:SetHideCountdownNumbers(hideTrinket)
            if trinketCD.Text then
                trinketCD.Text:SetAlpha(hideTrinket and 0 or 1)
            end
        end

        -- Racial
        local racialCD = frame.Racial and frame.Racial.Cooldown
        if racialCD then
            racialCD:SetHideCountdownNumbers(hideRacial)
            if racialCD.Text then
                racialCD.Text:SetAlpha(hideRacial and 0 or 1)
            end
        end

        -- DRs
        local useDrFrames = frame.drFrames ~= nil
        local drList = frame.drFrames or sArenaMixin.drCategories
        if drList then
            for j = 1, #drList do
                local drFrame = useDrFrames and drList[j] or frame[drList[j]]
                if drFrame then
                    local hideDefaultCD = hideDR or drFrame.Cooldown.hideDefaultCD
                    drFrame.Cooldown:SetHideCountdownNumbers(hideDefaultCD and true or false)
                    if drFrame.Cooldown.Text then
                        drFrame.Cooldown.Text:SetAlpha(hideDefaultCD and 0 or 1)
                    end
                    if drFrame.Cooldown.sArenaText then
                        drFrame.Cooldown.sArenaText:SetAlpha(hideDR and 0 or 1)
                    end
                end
            end
        end
    end
end

function sArenaMixin:EnsureArenaFramesEnabled()
    local accountSettings = EditModeManagerFrame and EditModeManagerFrame.AccountSettings
    if not accountSettings then return end

    local arenaFramesEnabled = EditModeManagerFrame:GetAccountSettingValueBool(Enum.EditModeAccountSetting.ShowArenaFrames)
    if not arenaFramesEnabled then
        EditModeManagerFrame:OnAccountSettingChanged(Enum.EditModeAccountSetting.ShowArenaFrames, true)
        EditModeManagerFrame.AccountSettings:RefreshArenaFrames()
    end
end

function sArenaFrameMixin:NormalEmpoweredCastbar()
    local castBar = self.CastBar

    if castBar.empoweredFix then return end

    local empowerEvents = {
        ["UNIT_SPELLCAST_EMPOWER_START"] = true,
        ["UNIT_SPELLCAST_EMPOWER_UPDATE"] = true,
        ["UNIT_SPELLCAST_EMPOWER_STOP"] = true,
    }

    local function HideChargeTiers(castBar)
        for _, child in ipairs({castBar:GetChildren()}) do
            if child.BasePip or (child.Normal and child.Disabled) then
                child:SetAlpha(0)
                castBar.empowerHidden = true
            end
        end
    end

    if not castBar.empowerSpark then
        castBar.empowerSpark = castBar:CreateTexture(nil, "OVERLAY")
        castBar.empowerSpark:SetAtlas("UI-CastingBar-Pip")
        castBar.empowerSpark:SetSize(3, 20)
        castBar.empowerSpark:SetPoint("CENTER", castBar.Spark, "CENTER", 0, -4.5)
        castBar.empowerSpark:Hide()
    end

    castBar:HookScript("OnEvent", function(self, event)
        if empowerEvents[event] then
            if not self.empowerHidden then
                HideChargeTiers(castBar)
            end
            if not self.textureChangedNeedsColor then
                self:SetStatusBarTexture("UI-CastingBar-Filling-Standard")
            end
            self.Spark:Hide()
            self.empowerSparkShown = true
            self.empowerSpark:Show()
        else
            if self.empowerSparkShown then
                self.empowerSpark:Hide()
                self.Spark:Show()
                self.empowerSparkShown = false
            end
        end
    end)

    castBar.empoweredFix = true
end

function sArenaMixin:InitializeDRFrames()
    if not sArenaMixin.isMidnight then return end

    if not sArena_ReloadedDB.skipEMDR then
        if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
            ShowUIPanel(EditModeManagerFrame)
        end
    end

    for i = 1, sArenaMixin.maxArenaOpponents do
        local blizzArenaFrame = _G["CompactArenaFrameMember" .. i]
        local arenaFrame = self["arena" .. i]

        if not blizzArenaFrame or not arenaFrame then return end

        local drTray = blizzArenaFrame.SpellDiminishStatusTray
        if not drTray then return end

        local blizzDRFrames = {drTray:GetChildren()}
        local NUM_DR_FRAMES = #blizzDRFrames

        if not arenaFrame.drFrames then
            drTray:SetParent(arenaFrame)
            drTray:SetAlpha(0)
            drTray:EnableMouse(false)
            arenaFrame.drFrames = {}

            for drIndex = 1, NUM_DR_FRAMES do
                local name = "sArenaEnemyFrame" .. i .. "_DR" .. drIndex
                local sArenaDrFrame = CreateFrame("Frame", name, arenaFrame, "sArenaDRFrameTemplate")
                sArenaDrFrame:SetFrameStrata("MEDIUM")
                sArenaDrFrame:SetFrameLevel(11)
                arenaFrame.drFrames[drIndex] = sArenaDrFrame

                local drTextFrame = sArenaDrFrame.DRTextFrame
                local drText = drTextFrame.DRText
                drText:SetText("½")
                drText:SetVertexColor(0, 1, 0)
                local fontFile, fontHeight, fontFlags = drText:GetFont()
                local drTextImmune = drTextFrame:CreateFontString(nil, "OVERLAY")
                drTextImmune:SetFont(fontFile, fontHeight, fontFlags)
                drTextImmune:SetJustifyH("RIGHT")
                drTextImmune:SetJustifyV("BOTTOM")
                drTextImmune:SetPoint("BOTTOMRIGHT", 4, -4)
                drTextImmune:SetText("%")
                drTextImmune:SetTextColor(1, 0, 0)
                drTextImmune:SetAlpha(0)
                drTextFrame.DRTextImmune = drTextImmune

                local blizzDRFrame = blizzDRFrames[drIndex]
                if blizzDRFrame and blizzDRFrame.Icon then
                    sArenaDrFrame.blizzFrame = blizzDRFrame

                    hooksecurefunc(blizzDRFrame.Icon, "SetTexture", function(_, texture)
                        sArenaDrFrame.Icon:SetTexture(texture)
                    end)

                    hooksecurefunc(blizzDRFrame, "Show", function()
                        sArenaDrFrame:Show()
                        arenaFrame:UpdateDRPositions()
                    end)

                    hooksecurefunc(blizzDRFrame, "Hide", function()
                        sArenaDrFrame.Icon:SetTexture(nil)
                        sArenaDrFrame:Hide()
                        arenaFrame:UpdateDRPositions()
                    end)

                    hooksecurefunc(blizzDRFrame.Cooldown, "SetCooldown", function(_, start, duration)
                        sArenaDrFrame.Cooldown:SetCooldown(start, duration)
                    end)

                    local green = CreateColor(0, 1, 0, 1)
                    local red = CreateColor(1, 0, 0, 1)

                    hooksecurefunc(blizzDRFrame.ImmunityIndicator, "SetShown", function(_, shown)
                        local layout = self.db.profile.layoutSettings[self.db.profile.currentLayout]
                        local blackBorder = layout and layout.dr and layout.dr.blackDRBorder
                        local borderHidden = layout and layout.dr and layout.dr.disableDRBorder

                        if not blackBorder and not borderHidden then
                            sArenaDrFrame.Border:SetVertexColorFromBoolean(shown, red, green)
                            if sArenaDrFrame.PixelBorder then
                                sArenaDrFrame.PixelBorder:SetVertexColorFromBoolean(shown, red, green)
                            end
                        end

                        if self.db and self.db.profile.colorDRCooldownText then
                            if sArenaDrFrame.Cooldown.sArenaText then
                                sArenaDrFrame.Cooldown.sArenaText:SetVertexColorFromBoolean(shown, red, green)
                            end
                        end

                        local drText = sArenaDrFrame.DRTextFrame.DRText
                        local drTextImmune = sArenaDrFrame.DRTextFrame.DRTextImmune
                        drText:SetAlphaFromBoolean(shown, 0, 1)
                        drTextImmune:SetAlphaFromBoolean(shown, 1, 0)
                    end)
                end
            end

            self:SetupDrag(arenaFrame.drFrames[1], arenaFrame.drFrames[1], "dr", "UpdateDRSettings")
        end
    end

    -- Apply DR settings after all frames are initialized
    if self.layoutdb and self.layoutdb.dr then
        self:UpdateDRSettings(self.layoutdb.dr)
    end


    if not sArena_ReloadedDB.skipEMDR then
        if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
            HideUIPanel(EditModeManagerFrame)
        end
    end

end

function sArenaMixin:DatabaseCleanup(db)
    if not db then return end
    -- Migrate old swapHumanTrinket setting to new swapRacialTrinket
    if db.profile.swapHumanTrinket ~= nil and db.profile.swapRacialTrinket == nil then
        db.profile.swapRacialTrinket = db.profile.swapHumanTrinket
        db.profile.swapHumanTrinket = nil
    end

    -- Migrate old global DR settings
    if db.profile.drSwipeOff ~= nil then
        -- Migrate drSwipeOff to disableDRSwipe
        if db.profile.disableDRSwipe == nil then
            db.profile.disableDRSwipe = db.profile.drSwipeOff
        end
        db.profile.drSwipeOff = nil
    end

    if db.profile.drTextOn ~= nil then
        local drTextOn = db.profile.drTextOn

        -- Apply drTextOn to all layouts as showDRText
        if db.profile.layoutSettings then
            for layoutName, layoutSettings in pairs(db.profile.layoutSettings) do
                if layoutSettings.dr then
                    -- Only set if the old setting was true (enabled)
                    if drTextOn == true and layoutSettings.dr.showDRText == nil then
                        layoutSettings.dr.showDRText = true
                    end
                end
            end
        end

        -- Remove old global setting
        db.profile.drTextOn = nil
    end

    -- Migrate old global disableDRBorder setting
    if db.profile.disableDRBorder ~= nil then
        local disableDRBorder = db.profile.disableDRBorder

        -- Apply disableDRBorder to all layouts as disableDRBorder
        if db.profile.layoutSettings then
            for layoutName, layoutSettings in pairs(db.profile.layoutSettings) do
                if layoutSettings.dr then
                    -- Only set if the old setting was true (enabled) and new setting doesn't exist
                    if disableDRBorder == true and layoutSettings.dr.disableDRBorder == nil then
                        layoutSettings.dr.disableDRBorder = true
                    end
                end
            end
        end

        -- Remove old global setting
        db.profile.disableDRBorder = nil
    end

    -- Migrate Pixelated layout to use thickPixelBorder setting
    if db.profile.layoutSettings and db.profile.layoutSettings.Pixelated then
        local pixelatedDR = db.profile.layoutSettings.Pixelated.dr
        if pixelatedDR and pixelatedDR.thickPixelBorder == nil then
            -- Enable thickPixelBorder for existing Pixelated layout users
            pixelatedDR.thickPixelBorder = true
        end
    end

    -- Migrate indicator settings (rename customBorder... to border...)
    if db.profile.layoutSettings then
        for _, layoutSettings in pairs(db.profile.layoutSettings) do
            if layoutSettings.widgets then
                local widgets = layoutSettings.widgets
                for _, indicatorName in ipairs({"targetIndicator", "focusIndicator"}) do
                    local indicator = widgets[indicatorName]
                    if indicator then
                        if indicator.customBorderSize ~= nil then
                            indicator.borderSize = indicator.customBorderSize
                            indicator.customBorderSize = nil
                        end
                        if indicator.customBorderOffset ~= nil then
                            indicator.borderOffset = indicator.customBorderOffset
                            indicator.customBorderOffset = nil
                        end
                    end
                end
            end
        end
    end

    -- Fix incorrect Stun DR icon on TBC (was 132298, should be 132092)
    if isTBC and not db.profile.tbcStunIconFix then
        local oldIcon = 132298 -- Kidney Shot icon (incorrect)
        local newIcon = 132092 -- Correct Stun icon

        -- Fix global DR categories
        if db.profile.drCategories and db.profile.drCategories["Stun"] == oldIcon then
            db.profile.drCategories["Stun"] = newIcon
        end

        -- Fix per-spec DR categories
        if db.profile.drCategoriesSpec then
            for specID, categories in pairs(db.profile.drCategoriesSpec) do
                if categories["Stun"] == oldIcon then
                    categories["Stun"] = newIcon
                end
            end
        end

        -- Fix per-class DR categories
        if db.profile.drCategoriesClass then
            for class, categories in pairs(db.profile.drCategoriesClass) do
                if categories["Stun"] == oldIcon then
                    categories["Stun"] = newIcon
                end
            end
        end

        db.profile.tbcStunIconFix = true
    end

    -- Cleanup redundant widget settings at top-level of widgets table
    -- These were accidentally created
    if db.profile.layoutSettings and not db.profile.dbClean1 then
        for _, layoutSettings in pairs(db.profile.layoutSettings) do
            if layoutSettings.widgets then
                local widgets = layoutSettings.widgets
                local keysToRemove = {
                    "posX", "posY", "scale", "enabled", "useBorder", "borderSize", "borderOffset",
                    "useBorderWithIcon", "wrapClass", "wrapTrinket", "wrapRacial",
                    "targetBorderSize", "targetBorderOffset", "targetWrapClass", "targetWrapTrinket", "targetWrapRacial",
                    "focusBorderSize", "focusBorderOffset", "focusWrapClass", "focusWrapTrinket", "focusWrapRacial",
                    "useTargetFocusBorder", "useTargetFocusBorderWithIcons",
                }
                for _, key in ipairs(keysToRemove) do
                    widgets[key] = nil
                end
            end
        end

        local currentLayout = db.profile.currentLayout
        local currentSettings = currentLayout and db.profile.layoutSettings[currentLayout]
        if currentSettings and currentSettings.dr and currentSettings.dr.growthDirection == 3 then
            local addonVersion = C_AddOns.GetAddOnMetadata("sArena_Reloaded", "Version") or ""
            StaticPopupDialogs["SARENA_DR_RIGHT_FIX"] = {
                text = "|T135884:16:16|t sArena |cffff8000Reloaded|r " .. addonVersion .. ":\n\n"
                    .. "Test Mode was showing the position of DR frames incorrectly with grow direction set to right. This is now fixed.\n\n"
                    .. "Please verify your arena frames DR are set up correctly in test mode.",
                button1 = "Test sArena",
                button2 = "Close",
                OnAccept = function()
                    self:Test()
                    LibStub("AceConfigDialog-3.0"):Open("sArena")
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            C_Timer.After(6, function()
                StaticPopup_Show("SARENA_DR_RIGHT_FIX")
            end)
        end

        db.profile.dbClean1 = true
    end
end