-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local LSM = LibStub("LibSharedMedia-3.0")
local isMidnight = sArenaMixin.isMidnight
local isTBC = sArenaMixin.isTBC

local LAYOUT_BORDER_TYPES = {
    BlizzCompact = "modern",
    BlizzRetail  = "modern",
    BlizzArena   = "classic",
    BlizzTarget  = "classic",
    BlizzTourney = "classic",
    BlizzRaid    = "pixel",
    Pixelated    = "pixel",
    -- Gladiuish and Xaryu (no border)
}

local BORDER_TEXTURES = {
    modern = {
        edge = "Interface\\AddOns\\sArena_Reloaded\\Textures\\ModernBorderEdge.tga",
        line = "Interface\\AddOns\\sArena_Reloaded\\Textures\\ModernBorderLine.tga",
    },
    classic = {
        edge = "Interface\\AddOns\\sArena_Reloaded\\Textures\\OldBorderEdge.tga",
        line = "Interface\\AddOns\\sArena_Reloaded\\Textures\\OldBorderLine.tga",
    },
}

local function GetPetTextureBorderSet(borderStyle, currentLayout)
    if borderStyle == "modernBorder" then
        return BORDER_TEXTURES.modern
    elseif borderStyle == "classicBorder" then
        return BORDER_TEXTURES.classic
    elseif borderStyle == "layoutBorders" then
        local variant = LAYOUT_BORDER_TYPES[currentLayout]
        return variant and BORDER_TEXTURES[variant] or nil
    end
    return nil
end

local function IsPixelBorderActive(pf, currentLayout)
    local style = pf.borderStyle or "layoutBorders"
    if style == "pixelBorder" then return true end
    if style == "layoutBorders" then
        return LAYOUT_BORDER_TYPES[currentLayout] == "pixel"
    end
    return false
end

function GetGlobalPetSettings(owner)
    return owner.parent.db and owner.parent.db.profile.petFrames
end

function sArenaMixin:IsPetFramesEnabled()
    return self.db and self.db.profile.petFrames.enabled
end

local function GetLayoutPetSettings(owner)
    local p = owner.parent
    if not (p and p.db) then return nil end
    local profile = p.db.profile
    local layoutSettings = profile.layoutSettings[profile.currentLayout]
    return layoutSettings and layoutSettings.petFrames or nil
end

local function GetLayoutWidgetSettings(owner)
    local p = owner.parent
    if not (p and p.db) then return nil end
    local profile = p.db.profile
    local layoutSettings = profile.layoutSettings[profile.currentLayout]
    return layoutSettings and layoutSettings.widgets or nil
end

local function MergeWidget(layoutWidget, petWidget)
    if not petWidget then
        return layoutWidget
    end
    local merged = {}
    for k, v in pairs(layoutWidget) do merged[k] = v end
    for k, v in pairs(petWidget) do merged[k] = v end
    return merged
end

function sArenaPetFrameMixin:GetWidgetSettings(widgetKey)
    local owner = self.OwnerFrame
    local petLayout = GetLayoutPetSettings(owner)
    local petWidgets = petLayout and petLayout.widgets or nil
    local layoutWidgets = GetLayoutWidgetSettings(owner)

    if widgetKey then
        local lw = layoutWidgets and layoutWidgets[widgetKey] or nil
        local pw = petWidgets and petWidgets[widgetKey] or nil
        return MergeWidget(lw, pw)
    end

    local merged = {}
    if layoutWidgets then
        for k, v in pairs(layoutWidgets) do
            merged[k] = MergeWidget(v, petWidgets and petWidgets[k])
        end
    end
    if petWidgets then
        for k, v in pairs(petWidgets) do
            if merged[k] == nil then
                merged[k] = MergeWidget(nil, v)
            end
        end
    end
    return merged
end

local function ShouldShowPet(owner)
    local pf = GetGlobalPetSettings(owner)
    if not (pf and pf.enabled) then return false end
    if owner.parent.testMode then return true end

    local class = owner.class or owner.tempClass or UnitClassBase(owner.unit)
    if not class or issecretvalue(class) then return true end
    return pf.classes and pf.classes[class] == true
end

function sArenaPetFrameMixin:OnLoad()
    local owner = self:GetParent()
    self.OwnerFrame = owner
    self:SetID(owner:GetID())
    self.unit = "arenapet" .. owner:GetID()
    self:SetIgnoreParentAlpha(true)

    self:RegisterForClicks("AnyDown", "AnyUp")
    self:SetAttribute("unit", self.unit)
    self:SetAttribute("*type1", "target")
    self:SetAttribute("*type2", "focus")

    if isMidnight then
        self.totalAbsorbBar:Hide()
        self.totalAbsorbBarOverlay:Hide()
        self.overAbsorbGlow:SetWidth(13)
        self:CreateOvershieldBar()
        self:CreateAbsorbBar()
    end
end

function sArenaPetFrameMixin:OnEvent(event, eventUnit, arg1)
    local owner = self.OwnerFrame

    if event == "ARENA_OPPONENT_UPDATE" then
        if eventUnit == self.unit then
            self:UpdatePet(arg1)
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        self:UpdatePet()
        self:UpdateAbsorb()
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:UpdatePet()
        return
    elseif event == "UNIT_PET" then
        self:UpdatePet()
        return
    end

    if eventUnit ~= self.unit then return end

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        self:UpdateHealth()
    elseif event == "UNIT_NAME_UPDATE" then
        self:UpdateName()
    elseif event == "UNIT_FLAGS" then
        owner:UpdateCombatStatus(owner.unit)
    elseif event == "UNIT_TARGET" then
        owner:UpdateArenaTargets(owner.unit)
        owner:UpdateArenaTargetText(owner.unit)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        self:UpdateHealth()
    end
end

function sArenaPetFrameMixin:RegisterPetUnitEvents()
    local owner = self.OwnerFrame
    local petUnitEvents = {
        "UNIT_HEALTH",
        "UNIT_MAXHEALTH",
        "UNIT_NAME_UPDATE",
        "UNIT_FLAGS",
        "UNIT_TARGET",
        "UNIT_ABSORB_AMOUNT_CHANGED",
        "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
    }
    for _, ev in ipairs(petUnitEvents) do
        if not self:IsEventRegistered(ev) then
            self:RegisterUnitEvent(ev, self.unit)
        end
    end

    if not self:IsEventRegistered("UNIT_PET") then
        self:RegisterUnitEvent("UNIT_PET", owner.unit)
    end

    local globalEvents = {
        "ARENA_OPPONENT_UPDATE",
        "PLAYER_ENTERING_WORLD",
        "ARENA_PREP_OPPONENT_SPECIALIZATIONS",
        "PLAYER_REGEN_ENABLED",
    }
    for _, ev in ipairs(globalEvents) do
        if not self:IsEventRegistered(ev) then
            self:RegisterEvent(ev)
        end
    end
end

function sArenaPetFrameMixin:UnregisterPetUnitEvents()
    self:UnregisterAllEvents()
end

function sArenaPetFrameMixin:Setup()
    local owner = self.OwnerFrame

    self.OwnerFrame = owner
    self:SetID(owner:GetID())
    self.unit = "arenapet" .. owner:GetID()
    self:SetAttribute("unit", self.unit)

    local bar = self.HealthBar
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(100)

    local pwo = self.WidgetOverlay
    if pwo.targetIndicator and pwo.targetIndicator.Texture then
        pwo.targetIndicator.Texture:SetAtlas("TargetCrosshairs")
    end
    if pwo.focusIndicator and pwo.focusIndicator.Texture then
        pwo.focusIndicator.Texture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\Waypoint-MapPin-Untracked.tga")
    end
    if pwo.combatIndicator and pwo.combatIndicator.Texture then
        pwo.combatIndicator.Texture:SetAtlas("Food")
    end
    for i = 1, 4 do
        local pt = pwo["partyTarget" .. i]
        if pt and pt.Texture then
            pt.Texture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\GM-icon-headCount.tga")
            pt.Texture:SetDesaturated(true)
        end
    end

    self.OwnerFrame.parent:SetTargetFocusBorderEdges(self.TargetFocusBorder, 1, 0)
    owner.parent:SetupDrag(self, self, "petFrames", "RefreshPetFrames", "petBar")

    self:UpdateSettings()
end

local function GetEffectivePetStatusText(profile)
    if not profile then return nil end
    local petSt = profile.petFrames and profile.petFrames.statusText
    local globalSt = profile.statusText
    if not petSt then return globalSt end
    return {
        alwaysShow    = petSt.alwaysShow    ~= nil and petSt.alwaysShow    or (globalSt and globalSt.alwaysShow),
        usePercentage = petSt.usePercentage ~= nil and petSt.usePercentage or (globalSt and globalSt.usePercentage),
        formatNumbers = petSt.formatNumbers ~= nil and petSt.formatNumbers or (globalSt and globalSt.formatNumbers),
    }
end

function sArenaPetFrameMixin:UpdateSettings()
    local owner = self.OwnerFrame
    local bar = self.HealthBar
    local s = GetLayoutPetSettings(owner)
    if not s then return end

    local profile = owner.parent.db.profile
    local layoutObj = owner.parent.layouts[profile.currentLayout]
    local baseOffsets = (layoutObj and layoutObj.petFrameBaseOffsets) or {}

    self:ClearAllPoints()
    self:SetSize(s.width or 160, s.height or 20)
    self:SetScale(s.scale or 1)
    local strata = s.frameStrata or "MEDIUM"
    self:SetFrameStrata(strata)
    self:SetFrameLevel(strata == "MEDIUM" and 5 or 0)
    local anchor = owner.HealthBar or owner
    self:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", (baseOffsets.posX or 0) + (s.posX or 0), (baseOffsets.posY or 0) + (s.posY or 0))

    local layout = profile.layoutSettings[profile.currentLayout]
    local texKey = layout and layout.textures and layout.textures.generalStatusBarTexture or "sArena Default"
    local tex = LSM:Fetch(LSM.MediaType.STATUSBAR, texKey)
    bar:SetStatusBarTexture(tex)

    local bgKey = layout and layout.textures and layout.textures.bgTexture or "Solid"
    local bgTex = LSM:Fetch(LSM.MediaType.STATUSBAR, bgKey) or "Interface\\Buttons\\WHITE8X8"
    local bgColor = (layout and layout.textures and layout.textures.bgColor) or {0, 0, 0, 0.6}
    bar.hpUnderlay:SetTexture(bgTex)
    bar.hpUnderlay:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    local txt = s.textSettings or {}
    self.Name:ClearAllPoints()
    local nameAnchor = txt.nameAnchor or "LEFT"
    local ox, oy = (txt.nameOffsetX or 0), (txt.nameOffsetY or 0)
    if nameAnchor == "LEFT" then
        self.Name:SetPoint("LEFT", self, "LEFT", 3 + ox, oy)
    elseif nameAnchor == "RIGHT" then
        self.Name:SetPoint("RIGHT", self, "RIGHT", -3 + ox, oy)
    else
        self.Name:SetPoint("CENTER", self, "CENTER", ox, oy)
    end
    self.Name:SetScale(txt.nameSize or 1)

    self.HealthText:ClearAllPoints()
    local hAnchor = txt.healthAnchor or "RIGHT"
    local ox, oy = (txt.healthOffsetX or 0), (txt.healthOffsetY or 0)
    if hAnchor == "LEFT" then
        self.HealthText:SetPoint("LEFT", self, "LEFT", 3 + ox, oy)
    elseif hAnchor == "RIGHT" then
        self.HealthText:SetPoint("RIGHT", self, "RIGHT", -3 + ox, oy)
    else
        self.HealthText:SetPoint("CENTER", self, "CENTER", ox, oy)
    end
    self.HealthText:SetScale(txt.healthSize or 1)
    self.Name:SetTextColor(owner.Name:GetTextColor())
    self.HealthText:SetTextColor(owner.HealthText:GetTextColor())
    local fontPath, fontSize, fontFlags = owner.HealthText:GetFont()
    self.HealthText:SetFont(fontPath, fontSize, fontFlags)
    local sx, sy = owner.HealthText:GetShadowOffset()
    self.HealthText:SetShadowOffset(sx, sy)


    self:UpdateBorderAnchors()
    self:UpdateColor()
    self:UpdateWidgetPositions()
    self:UpdatePetBorderStyle()
    self:UpdateVisibility()
    self:UpdateStatusTextVisible()
    self:UpdateName()
    self:UpdateHealth()
end

function sArenaPetFrameMixin:UpdateTextureBorder(texSet)
    if not texSet then
        self.texBorderEnabled = false
        if self.texBorderTopLeft then
            self.texBorderTopLeft:Hide()
            self.texBorderTopRight:Hide()
            self.texBorderBottomLeft:Hide()
            self.texBorderBottomRight:Hide()
            self.texBorderLeft:Hide()
            self.texBorderRight:Hide()
            self.texBorderTop:Hide()
            self.texBorderBottom:Hide()
        end
        return
    end

    local edge = texSet.edge
    local line = texSet.line

    if not self.texBorderTopLeft then
        local corners = {
            { key = "texBorderTopLeft", anchor = "TOPLEFT",     texCoord = {0,1,0,1} },
            { key = "texBorderTopRight", anchor = "TOPRIGHT",    texCoord = {1,0,0,1} },
            { key = "texBorderBottomLeft", anchor = "BOTTOMLEFT",  texCoord = {0,1,1,0} },
            { key = "texBorderBottomRight", anchor = "BOTTOMRIGHT", texCoord = {1,0,1,0} },
        }
        for _, c in ipairs(corners) do
            local t = self:CreateTexture(nil, "OVERLAY", nil, 5)
            t:SetTexelSnappingBias(0)
            t:SetSnapToPixelGrid(false)
            t:SetTexCoord(unpack(c.texCoord))
            t:SetPoint("CENTER", self, c.anchor, 0, 0)
            self[c.key] = t
        end

        self.texBorderLeft = self:CreateTexture(nil, "OVERLAY", nil, 5)
        self.texBorderLeft:SetTexelSnappingBias(0)
        self.texBorderLeft:SetSnapToPixelGrid(false)
        self.texBorderLeft:SetTexCoord(1,0, 0,0, 1,1, 0,1)
        self.texBorderLeft:SetPoint("TOPLEFT",     self.texBorderTopLeft, "BOTTOMLEFT", 0, 0)
        self.texBorderLeft:SetPoint("BOTTOMRIGHT", self.texBorderBottomLeft, "TOPRIGHT",   0, 0)

        self.texBorderRight = self:CreateTexture(nil, "OVERLAY", nil, 5)
        self.texBorderRight:SetTexelSnappingBias(0)
        self.texBorderRight:SetSnapToPixelGrid(false)
        self.texBorderRight:SetTexCoord(0,1, 1,1, 0,0, 1,0)
        self.texBorderRight:SetPoint("TOPLEFT",     self.texBorderTopRight, "BOTTOMLEFT", 0, 0)
        self.texBorderRight:SetPoint("BOTTOMRIGHT", self.texBorderBottomRight, "TOPRIGHT",   0, 0)

        self.texBorderTop = self:CreateTexture(nil, "OVERLAY", nil, 5)
        self.texBorderTop:SetTexelSnappingBias(0)
        self.texBorderTop:SetSnapToPixelGrid(false)
        self.texBorderTop:SetTexCoord(0,1, 0,1)
        self.texBorderTop:SetPoint("LEFT",  self.texBorderTopLeft, "RIGHT", 0, 0)
        self.texBorderTop:SetPoint("RIGHT", self.texBorderTopRight, "LEFT",  0, 0)

        self.texBorderBottom = self:CreateTexture(nil, "OVERLAY", nil, 5)
        self.texBorderBottom:SetTexelSnappingBias(0)
        self.texBorderBottom:SetSnapToPixelGrid(false)
        self.texBorderBottom:SetTexCoord(0,1, 1,0)
        self.texBorderBottom:SetPoint("LEFT",  self.texBorderBottomLeft, "RIGHT", 0, 0)
        self.texBorderBottom:SetPoint("RIGHT", self.texBorderBottomRight, "LEFT",  0, 0)
    end

    for _, t in ipairs({self.texBorderTopLeft, self.texBorderTopRight, self.texBorderBottomLeft, self.texBorderBottomRight}) do
        t:SetTexture(edge)
        t:SetDrawLayer("OVERLAY", 5)
        t:Show()
    end
    for _, t in ipairs({self.texBorderLeft, self.texBorderRight, self.texBorderTop, self.texBorderBottom}) do
        t:SetTexture(line)
        t:SetDrawLayer("OVERLAY", 5)
        t:Show()
    end
    self.texBorderEnabled = true
    self:UpdateTextureBorderColor()
end

function sArenaPetFrameMixin:UpdateTextureBorderColor()
    if not self.texBorderEnabled then return end
    if not self.texBorderTopLeft then return end

    local owner   = self.OwnerFrame
    local profile = owner.parent.db.profile
    local desaturate, r, g, b

    if profile.classColorFrameTexture then
        local class = owner.class or owner.tempClass or UnitClassBase(owner.unit)
        local color = class and C_ClassColor.GetClassColor(class)
        if color then
            desaturate = true
            r, g, b = color.r, color.g, color.b
        else
            desaturate = false
            r, g, b = 1, 1, 1
        end
    elseif owner.parent:DarkMode() then
        local v = owner.parent:DarkModeColor()
        local lighter = math.min(1, v + 0.1)
        desaturate = profile.darkModeDesaturate
        r, g, b = lighter, lighter, lighter
    else
        desaturate = false
        r, g, b = 1, 1, 1
    end

    for _, t in ipairs({
        self.texBorderTopLeft, self.texBorderTopRight,
        self.texBorderBottomLeft, self.texBorderBottomRight,
        self.texBorderLeft,  self.texBorderRight,
        self.texBorderTop, self.texBorderBottom,
    }) do
        t:SetDesaturated(desaturate)
        t:SetVertexColor(r, g, b)
    end
end

function sArenaPetFrameMixin:UpdatePetBorderStyle()
    local owner = self.OwnerFrame
    local pf = GetGlobalPetSettings(owner)
    if not pf then return end

    local currentLayout = owner.parent.db.profile.currentLayout
    local pixelActive = IsPixelBorderActive(pf, currentLayout)

    if pixelActive and not owner.parent.showPixelBorder then
        local layoutSettings = owner.parent.db.profile.layoutSettings[currentLayout]
        local size   = (layoutSettings and layoutSettings.pixelBorderSize)   or 1.5
        local offset = (layoutSettings and layoutSettings.pixelBorderOffset) or 0
        owner.parent:CreatePixelTextureBorder(self, self, "pixelBorder", size, offset)
    end

    if self.pixelBorder then
        self.pixelBorder:SetShown(pixelActive)
    end

    local useTexture = not pixelActive
    local texSet = useTexture and GetPetTextureBorderSet(pf.borderStyle or "layoutBorders", currentLayout) or nil
    self:UpdateTextureBorder(texSet)
end

function sArenaPetFrameMixin:UpdateStatusTextVisible()
    local owner = self.OwnerFrame
    local profile = owner.parent.db and owner.parent.db.profile
    local statusText = GetEffectivePetStatusText(profile)
    self.HealthText:SetShown(not statusText or statusText.alwaysShow ~= false)
end

function sArenaPetFrameMixin:HandlePetUnitWatch()
    local owner = self.OwnerFrame
    local shouldShow = ShouldShowPet(owner)
    local isInArena = owner.parent:IsInArena()

    local desired
    if shouldShow and owner.parent and owner.parent.testMode then
        desired = "show"
    elseif shouldShow and isInArena then
        desired = "watch"
    else
        desired = "hide"
    end

    if self.appliedVisibility == desired then
        self.pendingVisibility = nil
        return
    end

    if InCombatLockdown() then
        self.pendingVisibility = desired
        self:SetAlpha(desired == "hide" and 0 or 1)
        return
    end

    if desired == "watch" and isInArena then
        RegisterUnitWatch(self)
    elseif desired == "show" then
        UnregisterUnitWatch(self)
        self:Show()
    else
        UnregisterUnitWatch(self)
        self:Hide()
    end

    if desired ~= "hide" and self:GetAlpha() ~= 1 then
        local parent = self.OwnerFrame.parent
        if parent.rangeUseAlpha then
            self:ApplyRangeAlpha()
        else
            self:SetAlpha(1)
        end
    end

    self.appliedVisibility = desired
    self.pendingVisibility = nil
end

function sArenaPetFrameMixin:UpdateVisibility()
    local owner = self.OwnerFrame

    self:HandlePetUnitWatch()

    local testMode = owner.parent.testMode
    local petUnitExists = testMode or (self.unit and UnitExists(self.unit))

    if not ShouldShowPet(owner) or not petUnitExists then
        return
    end

    owner:UpdateTarget(owner.unit)
    owner:UpdateFocus(owner.unit)
    owner:UpdateCombatStatus(owner.unit)
    owner:UpdateArenaTargets(owner.unit)

    if testMode then
        self:ApplyTestModeWidgets()
    end
end

function sArenaPetFrameMixin:UpdateColor()
    local owner = self.OwnerFrame
    local pf = GetGlobalPetSettings(owner)
    if not pf then return end

    local class = owner.class or owner.tempClass or UnitClassBase(owner.unit)
    local color = class and C_ClassColor.GetClassColor(class)
    if pf.classColors and color then
        self.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
    else
        local c = pf.customColor or {0.5, 0.5, 0.5, 1}
        self.HealthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
    end
    self:UpdateTextureBorderColor()
end

function sArenaPetFrameMixin:UpdateName()
    local owner = self.OwnerFrame
    local pf = GetGlobalPetSettings(owner)
    if not pf then return end

    local id = owner:GetID()
    if FrameSortApi then
        id = FrameSortApi.v3.Frame:FrameNumberForUnit(owner.unit) or id
    end

    if pf.showPetName then
        local name
        if owner.parent.testMode then
            local testNames = { "Petson", "Peter", "Pettle", "Petpet", "Wolfy" }
            name = testNames[id] or testNames[1]
        elseif UnitExists(self.unit) then
            name = UnitName(self.unit)
        end
        if self.Name then
            self.Name:SetText(name or "")
            self.Name:Show()
        end
    elseif pf.showPetNumber then
        if self.Name then
            if pf.petNumberIdOnly then
                self.Name:SetText(id)
            else
                self.Name:SetText("Pet " .. id)
            end
            self.Name:Show()
        end
    else
        if self.Name then
            self.Name:SetText("")
            self.Name:Hide()
        end
    end
end

function sArenaPetFrameMixin:UpdatePet(unitEvent)
    local owner = self.OwnerFrame
    local pf = GetGlobalPetSettings(owner)
    if not (pf and pf.enabled) then return end

    self:UpdateColor()
    self:UpdateVisibility()

    if unitEvent ~= "seen" then
        return
    end

    self:UpdateName()
    self:UpdateHealth()
    self:UpdateAbsorb()
end

local function FormatLargeNumbers(value)
    if value >= 1000000 then
        return string.format("%.1f M", value / 1000000)
    elseif value >= 1000 then
        return string.format("%d K", value / 1000)
    else
        return tostring(value)
    end
end

local function FormatPetHealthText(pet, profile, unit)
    local owner = pet.OwnerFrame

    if owner.hideStatusText or not (owner.parent.engagedInMatch or owner.parent.arenaMatchStarted) then
        pet.HealthText:SetText("")
        return
    end

    if owner.isFeigningDeath then return end

    if (not unit) then
        unit = pet.unit
    end

    local curHp = UnitHealth(unit)
    local curHpMax = UnitHealthMax(unit)

    local statusText = GetEffectivePetStatusText(profile)
    if statusText and statusText.usePercentage then
        if isMidnight then
            pet.HealthText:SetFormattedText("%0.f%%", UnitHealthPercent(unit, nil, CurveConstants.ScaleTo100))
        else
            if isTBC then
                pet.HealthText:SetText(curHp .. "%")
            else
                local hpPercent = (curHpMax > 0) and math.ceil((curHp / curHpMax) * 100) or 0
                pet.HealthText:SetText(hpPercent .. "%")
            end
        end
    else
        if statusText and statusText.formatNumbers then
            if isMidnight then
                pet.HealthText:SetText(AbbreviateLargeNumbers(curHp))
            else
                pet.HealthText:SetText(FormatLargeNumbers(curHp))
            end
        else
            pet.HealthText:SetText(curHp)
        end
    end
end

function sArenaPetFrameMixin:UpdateHealth()
    local owner = self.OwnerFrame
    local bar = self.HealthBar
    if owner.parent.testMode then return end
    local petUnit = self.unit
    if not UnitExists(petUnit) then
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(0)
        self.HealthText:SetText("")
        self:UpdateAbsorb()
        return
    end
    local hpMax = UnitHealthMax(petUnit)
    local hp    = UnitHealth(petUnit)
    bar:SetMinMaxValues(0, hpMax)
    bar:SetValue(hp)
    local profile = owner.parent.db and owner.parent.db.profile
    FormatPetHealthText(self, profile, petUnit)
    self:UpdateAbsorb()
end

function sArenaPetFrameMixin:UpdateBorderAnchors()
    local border  = self.TargetFocusBorder
    if not border then return end
    local owner   = self.OwnerFrame
    local widgets = owner.parent.db.profile.layoutSettings[owner.parent.db.profile.currentLayout].widgets
    local ti = widgets and widgets.targetIndicator
    local borderSize = (ti and ti.borderSize) or 1
    local offset     = (ti and ti.borderOffset) or 0

    border:ClearAllPoints()
    border:SetPoint("TOPLEFT",     self, "TOPLEFT",     -(offset + borderSize),  (offset + borderSize))
    border:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT",  (offset + borderSize), -(offset + borderSize))

    border.top:ClearAllPoints()
    border.top:SetPoint("TOPLEFT",  border, "TOPLEFT")
    border.top:SetPoint("TOPRIGHT", border, "TOPRIGHT")
    border.top:SetHeight(borderSize)

    border.bottom:ClearAllPoints()
    border.bottom:SetPoint("BOTTOMLEFT",  border, "BOTTOMLEFT")
    border.bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    border.bottom:SetHeight(borderSize)

    border.left:ClearAllPoints()
    border.left:SetPoint("TOPLEFT",    border, "TOPLEFT")
    border.left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
    border.left:SetWidth(borderSize)

    border.right:ClearAllPoints()
    border.right:SetPoint("TOPRIGHT",    border, "TOPRIGHT")
    border.right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
    border.right:SetWidth(borderSize)
end

function sArenaPetFrameMixin:UpdateWidgetPositions()
    local owner = self.OwnerFrame
    local pwo = self.WidgetOverlay
    local pws = self:GetWidgetSettings()
    if not pws then return end

    local defaultSize = {
        targetIndicator = 28,
        focusIndicator  = 18,
        combatIndicator = 14,
        partyTargetSize = 12,
    }
    local defaultPos = {
        targetIndicator = { "CENTER", "LEFT",   7, -5.5 },
        focusIndicator  = { "CENTER", "LEFT",   0, 0 },
        combatIndicator = { "CENTER", "CENTER", 0, 0 },
    }

    for _, key in ipairs({ "targetIndicator", "focusIndicator", "combatIndicator" }) do
        local ind = pwo[key]
        if ind then
            local pw   = pws[key] or {}
            local def  = defaultPos[key]
            local size = defaultSize[key] or 16
            ind:ClearAllPoints()
            ind:SetSize(size, size)
            ind:SetScale(pw.scale or 1)
            ind:SetPoint(def[1], self, def[2], def[3] + (pw.posX or 0), def[4] + (pw.posY or 0))
        end
    end

    local pti     = pws.partyTargetIndicators or {}
    local dir     = pti.direction or "LEFT"
    local spacing = pti.spacing or 1
    local ptScale = pti.scale or 1
    local first   = pwo.partyTarget1
    if first then
        first:ClearAllPoints()
        first:SetSize(12, 12)
        first:SetScale(ptScale)
        first:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", (pti.posX or 0), -12 + (pti.posY or 0))
        for i = 2, 4 do
            local cur, prev = pwo["partyTarget" .. i], pwo["partyTarget" .. (i - 1)]
            if cur and prev then
                cur:SetSize(12, 12)
                cur:SetScale(ptScale)
                owner.parent:ChainIndicator(cur, prev, dir, -1 + spacing)
            end
        end
    end
end

function sArenaPetFrameMixin:UpdateTargetFocusBorderVisibility()
    local border = self.TargetFocusBorder
    if not border then return end
    local pws = self:GetWidgetSettings()
    local ti = pws and pws.targetIndicator
    local fi = pws and pws.focusIndicator

    self:UpdateBorderAnchors()

    local color
    if self.isTarget and ti and ti.enabled and ti.useBorder then
        color = ti.borderColor or {1, 0.7, 0, 1}
    elseif self.isFocus and fi and fi.enabled and fi.useBorder then
        color = fi.borderColor or {0, 0, 1, 1}
    end

    if color then
        for _, edge in ipairs({border.top, border.right, border.bottom, border.left}) do
            edge:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
        end
        border:Show()
    else
        border:Hide()
    end
end

function sArenaPetFrameMixin:ApplyTestModeWidgets()
    local owner = self.OwnerFrame
    if not (owner.parent and owner.parent.testMode) then return end

    local pwo = self.WidgetOverlay
    if not pwo then return end

    local pws  = self:GetWidgetSettings()
    local lw   = GetLayoutWidgetSettings(owner)
    local pTi  = pws and pws.targetIndicator
    local pFi  = pws and pws.focusIndicator
    local pCi  = pws and pws.combatIndicator
    local pPti = pws and pws.partyTargetIndicators

    local lTi  = lw and lw.targetIndicator
    local lFi  = lw and lw.focusIndicator
    local lCi  = lw and lw.combatIndicator
    local lPti = lw and lw.partyTargetIndicators

    local pTiEnabled   = lTi and lTi.enabled and pTi and pTi.enabled
    local pTiUseBorder = pTiEnabled and pTi.useBorder
    local pTiUseBoth   = pTiEnabled and pTi.useBorderWithIcon
    local pFiEnabled   = lFi and lFi.enabled and pFi and pFi.enabled
    local pFiUseBorder = pFiEnabled and pFi.useBorder
    local pFiUseBoth   = pFiEnabled and pFi.useBorderWithIcon
    local pCiEnabled   = lCi and lCi.enabled and pCi and pCi.enabled
    local pPtiEnabled  = lPti and lPti.enabled and pPti and pPti.enabled

    pwo.targetIndicator:Hide()
    pwo.focusIndicator:Hide()
    self.isTarget = false
    self.isFocus  = false

    local i = self:GetID()
    if i == 1 then
        pwo.focusIndicator:SetShown(pFiEnabled and (not pFiUseBorder or pFiUseBoth) or false)
        self.isFocus = pFiEnabled and true or false
    elseif i == 2 then
        pwo.targetIndicator:SetShown(pTiEnabled and (not pTiUseBorder or pTiUseBoth) or false)
        self.isTarget = pTiEnabled and true or false
    end

    self:UpdateTargetFocusBorderVisibility()

    pwo.combatIndicator:SetShown(pCiEnabled and true or false)

    if pPtiEnabled then
        local classColors = {}
        for _, color in pairs(RAID_CLASS_COLORS) do
            table.insert(classColors, color)
        end
        for j = 1, 4 do
            local indicator = pwo["partyTarget" .. j]
            if indicator then
                if j <= 2 then
                    local c = classColors[math.random(#classColors)]
                    indicator.Texture:SetVertexColor(c.r, c.g, c.b)
                    indicator:Show()
                    indicator:SetAlpha(1)
                else
                    indicator:Hide()
                    indicator:SetAlpha(0)
                end
            end
        end
    else
        for j = 1, 4 do
            local indicator = pwo["partyTarget" .. j]
            if indicator then
                indicator:Hide()
                indicator:SetAlpha(0)
            end
        end
    end
end

function sArenaMixin:RegisterPetFrameEvents()
    local pf = self.db and self.db.profile.petFrames
    if not pf then return end

    if pf.enabled then
        self.petFramesOn = true
        for i = 1, self.maxArenaOpponents do
            local frame = self["arena" .. i]
            frame.PetFrame:RegisterPetUnitEvents()
            frame.PetFrame:UpdatePet("seen")
            frame.PetFrame:HandlePetUnitWatch()
            if self.testMode then
                self:Test()
            end
        end
    else
        self:UnregisterPetFrameEvents()
    end
end

function sArenaMixin:UnregisterPetFrameEvents()
    self.petFramesOn = false
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame.PetFrame:UnregisterPetUnitEvents()
        frame.PetFrame:UpdateVisibility()
    end
end

function sArenaMixin:RefreshPetFrames()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame.PetFrame:UpdateSettings()
    end
    self:RegisterPetFrameEvents()
end

function sArenaMixin:RefreshPetFrameSettings()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame.PetFrame:UpdateSettings()
    end
    self:ApplyRangeCheckTextures()
end
