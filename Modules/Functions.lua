-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local isRetail = sArenaMixin.isRetail
local isMidnight = sArenaMixin.isMidnight
local isTBC = sArenaMixin.isTBC
local L = sArenaMixin.L
local LSM = LibStub("LibSharedMedia-3.0")
local noEarlyFrames = sArenaMixin.isTBC or sArenaMixin.isWrath

function sArenaMixin:GetPartyFrame(i)
    --EditModeManagerFrame:UseRaidStylePartyFrames()
    return _G["CompactPartyFrameMember" .. i] or _G["CompactRaidFrame" .. i]
end

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

function sArenaMixin:CheckMatchStatus(event)
    local state = C_PvP.GetActiveMatchState()

    if state == Enum.PvPMatchState.Engaged then
        self.waitingForMatch = nil
        self.engagedInMatch = true
        -- Small delay on UpdatePlayer because UnitExists return false for all immediately if not
        C_Timer.After(0.3, function()
            for i = 1, self.maxArenaOpponents do
                local frame = self["arena" .. i]
                frame:UpdatePlayer(UnitExists(frame.unit) and "seen" or "unseen")
            end
         end)

         -- Delay reset of this flag so Blizzards SetCooldown doesnt put a CD on Trinket on round start when there isn't a cooldown
         -- from equip swapping in spawn, or potentially accidentally trinketing I suppose.
         C_Timer.After(0.5, function() self.waitingForMatchDelayedReset = nil end)
    else
        self.engagedInMatch = nil
        self.waitingForMatch = true
        self.waitingForMatchDelayedReset = true
        if event == "PVP_MATCH_ACTIVE" then
            for i = 1, self.maxArenaOpponents do
                local frame = self["arena" .. i]
                frame:UpdatePlayer(UnitExists(frame.unit) and "seen" or "unseen")
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

    for i = 1, self.maxArenaOpponents do
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
        local drList = frame.drFrames or self.drCategories
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

        db.profile.dbClean1 = true
    end

    if db.profile.layoutSettings and not db.profile.dbClean2 then
        for _, layoutSettings in pairs(db.profile.layoutSettings) do
            if layoutSettings.widgets then
                local pti = layoutSettings.widgets.partyTargetIndicators
                if pti then
                    local flatKeys = {"posX", "posY", "scale", "direction", "spacing"}
                    local hasFlat = false
                    for _, key in ipairs(flatKeys) do
                        if pti[key] ~= nil then
                            hasFlat = true
                            break
                        end
                    end

                    if hasFlat then
                        if not pti.partyOnArena then
                            pti.partyOnArena = {}
                        end
                        for _, key in ipairs(flatKeys) do
                            if pti[key] ~= nil then
                                if pti.partyOnArena[key] == nil then
                                    pti.partyOnArena[key] = pti[key]
                                end
                                pti[key] = nil
                            end
                        end
                    end
                end
            end
        end
        db.profile.dbClean2 = true
    end
end

-- function sArenaMixin:ToggleObjectivesFrame(instanceType)
--     local ObjectiveTracker = ObjectiveTracker or ObjectiveTrackerFrame
--     if not ObjectiveTracker then return end

--     local inArena = instanceType == "arena"

--     if not ObjectiveTracker.ogParent then
--         ObjectiveTracker.ogParent = ObjectiveTracker:GetParent()
--         ObjectiveTracker:HookScript("OnShow", function()
--             local _, instanceType = GetInstanceInfo()
--             local inArena = instanceType == "arena"

--             if inArena then
--                 ObjectiveTracker:SetParent(self.hiddenFrame)
--             end
--         end)
--     end
--     if inArena then
--         ObjectiveTracker:SetParent(self.hiddenFrame)
--     else
--         ObjectiveTracker:SetParent(ObjectiveTracker.ogParent)
--     end
-- end

function sArenaFrameMixin:StopStealthHealthTicker()
    if self.stealthHealthTicker then
        self.stealthHealthTicker:Cancel()
        self.stealthHealthTicker = nil
    end
end

function sArenaFrameMixin:StartStealthHealthTicker()
    self:StopStealthHealthTicker()

    local hp = self.HealthBar

    if isMidnight then
        self.stealthHealthTicker = C_Timer.NewTimer(16, function()
            hp:SetMinMaxValues(0, 100)
            hp:SetValue(100)
            self.stealthHealthTicker = nil
        end)
    else
        local _, maxHealth = hp:GetMinMaxValues()
        if maxHealth <= 0 then return end

        local totalTicks = 30
        local currentValue = hp:GetValue()
        local incrementPerTick = (maxHealth - currentValue) / totalTicks

        self.stealthHealthTicker = C_Timer.NewTicker(1, function()
            hp:SetValue(hp:GetValue() + incrementPerTick)
        end, totalTicks)
    end
end

function sArenaFrameMixin:SetupTrinketCooldownDone()
    self.Trinket.Cooldown:HookScript("OnCooldownDone", function()
        local db = self.parent and self.parent.db
        if db and db.profile.colorTrinket then
            local colors = db.profile.trinketColors
            if db.profile.colorTrinketKeepTexture then
                self.Trinket.Texture:SetDesaturated(true)
            else
                self.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
            end
            self.Trinket.Texture:SetVertexColor(unpack(colors.available))
        end
    end)
end

function sArenaFrameMixin:CreatePixelTextureBorder(parent, target, key, size, offset, setFrameLevel)
    offset = offset or 0
    size = size or 1
    if setFrameLevel == nil then setFrameLevel = true end

    if not parent[key] then
        local holder = CreateFrame("Frame", nil, parent)
        if setFrameLevel then
            holder:SetFrameLevel(parent:GetFrameLevel() + 5)
        end
        holder:SetIgnoreParentScale(true)
        parent[key] = holder

        local edges = {}
        for i = 1, 4 do
            local tex = holder:CreateTexture(nil, "BORDER", nil, 7)
            tex:SetColorTexture(0,0,0,1)
            tex:SetIgnoreParentScale(true)
            edges[i] = tex
        end
        holder.edges = edges

        function holder:SetVertexColor(r, g, b, a)
            for _, tex in ipairs(self.edges) do
                tex:SetColorTexture(r, g, b, a or 1)
            end
        end
    end

    local holder = parent[key]
    local edges = holder.edges

    local spacing = offset

    holder:ClearAllPoints()
    holder:SetPoint("TOPLEFT", target, "TOPLEFT", -spacing - size, spacing + size)
    holder:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", spacing + size, -spacing - size)

    -- Top
    edges[1]:ClearAllPoints()
    edges[1]:SetPoint("TOPLEFT", holder, "TOPLEFT")
    edges[1]:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
    edges[1]:SetHeight(size)

    -- Right
    edges[2]:ClearAllPoints()
    edges[2]:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
    edges[2]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT")
    edges[2]:SetWidth(size)

    -- Bottom
    edges[3]:ClearAllPoints()
    edges[3]:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT")
    edges[3]:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT")
    edges[3]:SetHeight(size)

    -- Left
    edges[4]:ClearAllPoints()
    edges[4]:SetPoint("TOPLEFT", holder, "TOPLEFT")
    edges[4]:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT")
    edges[4]:SetWidth(size)

    holder:Show()
end

function sArenaFrameMixin:AddPixelBorderToFrame()
    local currentLayout = self.parent.db.profile.currentLayout
    local size = self.parent.db.profile.layoutSettings[currentLayout].pixelBorderSize or 1.5
    local drSize = self.parent.db.profile.layoutSettings[currentLayout].drPixelBorderSize or 1.5
    local offset = self.parent.db.profile.layoutSettings[currentLayout].pixelBorderOffset or 0

    if not self.PixelBorders then
        self.PixelBorders = CreateFrame("Frame", nil, self)
        self.PixelBorders:SetAllPoints()
        self.PixelBorders:SetFrameLevel(self:GetFrameLevel() - 1)
    end

    local borders = self.PixelBorders
    self.PixelBorders.hide = nil

    if self.HealthBar and self.PowerBar then
        local wrapper = borders.mainWrapper
        if not wrapper then
            wrapper = CreateFrame("Frame", nil, borders)
            borders.mainWrapper = wrapper
        end
        wrapper:ClearAllPoints()
        wrapper:SetPoint("TOPLEFT", self.HealthBar, "TOPLEFT")
        wrapper:SetPoint("BOTTOMRIGHT", self.PowerBar, "BOTTOMRIGHT")
        self:CreatePixelTextureBorder(borders, wrapper, "main", size, offset)
    end

    self:CreatePixelTextureBorder(borders, self.ClassIcon, "classIcon", size, offset)
    self:CreatePixelTextureBorder(borders, self.Trinket, "trinket", size, offset)
    self:CreatePixelTextureBorder(borders, self.Racial, "racial", size, offset)
    self:CreatePixelTextureBorder(borders, self.Dispel, "dispel", size, offset)

    if not self.parent.db.profile.showDispels then
        borders.dispel:Hide()
    end

    self:CreatePixelTextureBorder(self.SpecIcon, self.SpecIcon, "specIcon", size, offset)
    self:CreatePixelTextureBorder(self.CastBar, self.CastBar, "castBar", size, offset)
    self:CreatePixelTextureBorder(self.CastBar, self.CastBar.Icon, "castBarIcon", size, offset)
    self:SetTextureCrop(self.CastBar.Icon, true)

    if size == 0 then
        borders:Hide()
        self.PixelBorders.hide = true
        if self.CastBar.castBar then self.CastBar.castBar:Hide() end
        if self.CastBar.castBarIcon then self.CastBar.castBarIcon:Hide() end
        if self.SpecIcon.specIcon then self.SpecIcon.specIcon:Hide() end
        return
    end

    borders:Show()
end

function sArenaMixin:RemovePixelBorders()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not frame.PixelBorders then
            return
        end

        if frame.PixelBorders then
            frame.PixelBorders:Hide()
            frame.PixelBorders.hide = true
        end

        local function hideBorder(parent, key)
            if parent and parent[key] then
                parent[key]:Hide()
            end
        end

        local borders = frame.PixelBorders
        if borders and borders.mainWrapper then
            hideBorder(borders, "main")
        end

        hideBorder(borders, "classIcon")
        hideBorder(borders, "trinket")
        hideBorder(borders, "dispel")
        hideBorder(borders, "racial")
        hideBorder(frame.SpecIcon, "specIcon")
        hideBorder(frame.CastBar, "castBar")
        hideBorder(frame.CastBar, "castBarIcon")

        frame.ClassIcon:SetScale(1)
        frame.CastBar.Icon:ClearAllPoints()
        frame.CastBar.Icon:SetPoint("RIGHT", frame.CastBar, "LEFT", -5, 0)
        local newLayout = self.db and self.db.profile and self.db.profile.currentLayout
        local newLayoutSettings = self.db and self.db.profile and self.db.profile.layoutSettings and self.db.profile.layoutSettings[newLayout]
        local newCropIcons = newLayoutSettings and newLayoutSettings.cropIcons or false
        frame:SetTextureCrop(frame.CastBar.Icon, newCropIcons)

        for n = 1, #self.drCategories do
            local drFrame = frame[self.drCategories[n]]
            if drFrame and drFrame.PixelBorder then
                drFrame.PixelBorder:Hide()
                if drFrame.Border then
                    drFrame.Border:Show()
                end
            end
        end
    end

    if self.UpdateCastBarPixelBorders then
        self:UpdateCastBarPixelBorders()
    end
end

function sArenaMixin:UpdateCastbarVisibility()
    local hide = self.layoutdb.castBar.hideCastbars
    if hide then
        self.hiddenCastbars = true
        for i = 1, self.maxArenaOpponents do
            local frame = isMidnight and _G["sArenaEnemyFrame" .. i] or self["arena" .. i]
            if frame and frame.CastBar then
                frame.CastBar:SetParent(self.hiddenFrame)
                if isMidnight and frame.midnightCastBarMoveFrame then
                    frame.midnightCastBarMoveFrame:Hide()
                end
            end
        end
    else
        if not self.hiddenCastbars then return end
        self.hiddenCastbars = nil
        for i = 1, self.maxArenaOpponents do
            local frame = isMidnight and _G["sArenaEnemyFrame" .. i] or self["arena" .. i]
            if frame and frame.CastBar then
                frame.CastBar:SetParent(frame)
                if isMidnight and frame.midnightCastBarMoveFrame then
                    frame.midnightCastBarMoveFrame:Show()
                end
            end
        end
    end
end

-- Midnight only
if not isMidnight then return end

function sArenaMixin:RegisterCVarListener()
    if self.cvarListenerRegistered then return end
    self.cvarListenerRegistered = true

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CVAR_UPDATE")
    frame:SetScript("OnEvent", function(_, _, cvarName)
        if cvarName == "spellDiminishPVPOnlyTriggerableByMe" then
            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
        end
    end)
end

function sArenaMixin:InitializeMidnightDRFrames()
    if self.drFramesInitialized then return end
    if self.db and self.db.profile.hideMidnightDRs then return end

    if not sArena_ReloadedDB.skipEMDR then
        if EditModeManagerFrame and EditModeManagerFrame.AccountSettings then
            ShowUIPanel(EditModeManagerFrame)
        end
    end

    for i = 1, self.maxArenaOpponents do
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
                local sArenaDRFrame = CreateFrame("Frame", name, arenaFrame, "sArenaDRFrameTemplate")
                sArenaDRFrame:SetFrameStrata("MEDIUM")
                sArenaDRFrame:SetFrameLevel(11)
                arenaFrame.drFrames[drIndex] = sArenaDRFrame

                local drTextFrame = sArenaDRFrame.DRTextFrame
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
                    sArenaDRFrame.blizzFrame = blizzDRFrame

                    hooksecurefunc(blizzDRFrame.Icon, "SetTexture", function(_, texture)
                        sArenaDRFrame.Icon:SetTexture(texture)
                    end)

                    hooksecurefunc(blizzDRFrame, "Show", function()
                        sArenaDRFrame:Show()
                        arenaFrame:UpdateDRPositions()
                    end)

                    hooksecurefunc(blizzDRFrame, "Hide", function()
                        sArenaDRFrame.Icon:SetTexture(nil)
                        sArenaDRFrame.Cooldown:Clear()
                        sArenaDRFrame:Hide()
                        arenaFrame:UpdateDRPositions()
                    end)

                    hooksecurefunc(blizzDRFrame.Cooldown, "SetCooldown", function(_, start, duration)
                        sArenaDRFrame.Cooldown:SetCooldown(GetTime(), 16.1)
                        sArenaDRFrame.Cooldown.trueCD = true
                        --print(i, " DR CD Start")
                        C_Timer.After(16.1, function() sArenaDRFrame.Cooldown.trueCD = nil end)
                    end)

                    local green = CreateColor(0, 1, 0, 1)
                    local red = CreateColor(1, 0, 0, 1)

                    hooksecurefunc(blizzDRFrame.ImmunityIndicator, "SetShown", function(_, shown)
                        local layout = self.db.profile.layoutSettings[self.db.profile.currentLayout]
                        local blackBorder = layout and layout.dr and layout.dr.blackDRBorder
                        local borderHidden = layout and layout.dr and layout.dr.disableDRBorder

                        --print(i, " DR Immune Show:", shown, "IsCDOnDR: ", sArenaDRFrame.Cooldown:IsShown())

                        if not sArenaDRFrame.Cooldown.trueCD and not self.db.profile.disableInstantDRCooldown then
                            sArenaDRFrame.Cooldown:SetCooldown(GetTime(), 20)
                        end

                        if not borderHidden then
                            if blackBorder then
                                sArenaDRFrame.Border:SetVertexColor(0, 0, 0)
                                if sArenaDRFrame.PixelBorder then
                                    sArenaDRFrame.PixelBorder:SetVertexColor(sArenaDRFrame.Border:GetVertexColor())
                                end
                            else
                                sArenaDRFrame.Border:SetVertexColorFromBoolean(shown, red, green)
                                if sArenaDRFrame.PixelBorder then
                                    sArenaDRFrame.PixelBorder:SetVertexColor(sArenaDRFrame.Border:GetVertexColor())
                                end
                            end
                        end

                        if self.db and self.db.profile.colorDRCooldownText then
                            sArenaDRFrame.Cooldown.Text:SetVertexColorFromBoolean(shown, red, green)
                        end

                        local drText = sArenaDRFrame.DRTextFrame.DRText
                        local drTextImmune = sArenaDRFrame.DRTextFrame.DRTextImmune
                        drText:SetAlphaFromBoolean(shown, 0, 1)
                        drTextImmune:SetAlphaFromBoolean(shown, 1, 0)
                    end)
                end
            end

            if arenaFrame.drFrames[1] then
                self:SetupDrag(arenaFrame.drFrames[1], arenaFrame.drFrames[1], "dr", "UpdateDRSettings")
            end
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

    self.drFramesInitialized = true
end

function sArenaFrameMixin:HookMidnightTrinket()
    local blizzArenaFrame = _G["CompactArenaFrameMember" .. self:GetID()]
    local trinketFrame = blizzArenaFrame.CcRemoverFrame
    if trinketFrame then
        trinketFrame:SetParent(self)
        trinketFrame:SetAlpha(0)

        hooksecurefunc(trinketFrame.Cooldown, "SetCooldown", function()
            if not self.Trinket.Texture:GetTexture() then return end
            if self.parent.waitingForMatchDelayedReset then return end

            local db = self.parent and self.parent.db
            local colors = db.profile.trinketColors

            if not self.Trinket.Cooldown:IsShown() then

                if db and db.profile.playTrinketSound then
                    local isHealer = self.isHealer
                    local fileID = isHealer and db.profile.healerTrinketSoundFileID or db.profile.trinketSoundFileID
                    local soundName = isHealer and (db.profile.healerTrinketSoundName or "Lossa Trinket") or (db.profile.trinketSoundName or "Lossa Trinket")
                    local channel = db.profile.trinketSoundChannel or "Master"
                    if fileID and fileID ~= 0 then
                        PlaySound(fileID, channel)
                    else
                        local soundPath = LSM:Fetch(LSM.MediaType.SOUND, soundName)
                        if soundPath then
                            PlaySoundFile(soundPath, channel)
                        end
                    end
                end

                -- Update shared Racial CD
                if self.Racial.Texture:GetTexture() then
                    local sharedCD = self:GetSharedCD()
                    if sharedCD and sharedCD ~= 0 then
                        self.sharedRacialCDActive = true
                        self.Racial.Cooldown:SetCooldown(GetTime(), sharedCD)
                        C_Timer.After(sharedCD, function() self.sharedRacialCDActive = nil end)
                    elseif not self.sharedRacialCDActive then
                        self.Racial.Cooldown:Clear()
                    end
                end

            end

            local durationObj = C_PvP.GetArenaCrowdControlDuration(self.unit)
            self.Trinket.Cooldown:SetCooldownFromDurationObject(durationObj)
            if db and db.profile.colorTrinket and db.profile.colorTrinketKeepTexture then
                self.Trinket.Texture:SetDesaturated(true)
            else
                self.Trinket.Texture:SetDesaturated(db and db.profile.desaturateTrinketCD and not db.profile.colorTrinket)
            end

            if db and db.profile.colorTrinket then
                self.Trinket.Texture:SetVertexColor(unpack(colors.used))
            end
        end)

        hooksecurefunc(trinketFrame.Icon, "SetTexture", function(_, texture)
            local db = self.parent and self.parent.db
            if not issecretvalue(texture) then
                if texture ~= "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK.BLP" then
                    if db and db.profile.colorTrinket then
                        local colors = db.profile.trinketColors
                        if db.profile.colorTrinketKeepTexture then
                            self.Trinket.Texture:SetTexture(texture)
                            self.Trinket.Texture:SetDesaturated(true)
                        else
                            self.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                        end
                        self.Trinket.Texture:SetVertexColor(unpack(colors.available))
                    else
                        self.Trinket.Texture:SetTexture(texture)
                    end
                end
            else
                if db and db.profile.colorTrinket then
                    local colors = db.profile.trinketColors
                    if db.profile.colorTrinketKeepTexture then
                        self.Trinket.Texture:SetTexture(texture)
                        self.Trinket.Texture:SetDesaturated(true)
                    else
                        self.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                    end
                    self.Trinket.Texture:SetVertexColor(unpack(colors.available))
                else
                    self.Trinket.Texture:SetTexture(texture)
                end
            end
        end)

    end
end

function sArenaMixin:EnsureArenaFramesEnabled(attempt)
    attempt = attempt or 1
    local accountSettings = EditModeManagerFrame and EditModeManagerFrame.AccountSettings and EditModeManagerFrame.accountSettingMap
    if not accountSettings then
        if attempt >= 5 then
            self:Print(L["Error_EditModeAccountSettings"])
            return
        end
        C_Timer.After(0.5, function() self:EnsureArenaFramesEnabled(attempt + 1) end)
        return
    end

    local fixedElvUI = self:IsElvUIActive()
    if fixedElvUI then
        C_Timer.After(5, function()
            self:Print(L["ElvUI_ArenaFrames_Fix"])
        end)
    end

    local arenaFramesEnabled = EditModeManagerFrame:GetAccountSettingValueBool(Enum.EditModeAccountSetting.ShowArenaFrames)
    if not arenaFramesEnabled then
        EditModeManagerFrame:OnAccountSettingChanged(Enum.EditModeAccountSetting.ShowArenaFrames, true)
        EditModeManagerFrame.AccountSettings:RefreshArenaFrames()
        self.arenaFramesEnabledNeedReload = true
        self:ReloadRequiredUI()
    end
end

function sArenaMixin:ReloadRequiredUI()
    self.optionsTable = {
        type = "group",
        name = self.addonTitle,
        childGroups = "tab",
        args = {
            reloadRequired = {
                order = 1,
                name = L["Reload_Warning"],
                type = "group",
                args = {
                    warningTitle = {
                        order = 1,
                        type = "description",
                        name = L["Reload_Warning"],
                        fontSize = "large",
                    },
                    spacer1 = {
                        order = 1.1,
                        type = "description",
                        name = " ",
                    },
                    explanation = {
                        order = 2,
                        type = "description",
                        name = L["Reload_Explanation"],
                        fontSize = "medium",
                    },
                    spacer2 = {
                        order = 2.1,
                        type = "description",
                        name = " ",
                    },
                    reloadButton = {
                        order = 3,
                        type = "execute",
                        name = L["Button_ReloadUI"],
                        func = function()
                            sArena_ReloadedDB.reOpenOptions = true
                            ReloadUI()
                        end,
                        width = "full",
                    },
                },
            },
        },
    }
    LibStub("AceConfig-3.0"):RegisterOptionsTable("sArena", self.optionsTable)
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("sArena", 400, 270)
    LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
    C_Timer.After(4, function()
        LibStub("AceConfigDialog-3.0"):Open("sArena")
        self:Print(L["Reload_Explanation"])
    end)
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