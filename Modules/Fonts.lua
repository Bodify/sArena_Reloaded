-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local LSM = LibStub("LibSharedMedia-3.0")
local L = sArenaMixin.L

function sArenaMixin:FontValues()
    local t, keys = {}, {}
    for k in pairs(LSM:HashTable(LSM.MediaType.FONT)) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do t[k] = k end
    return t
end

function sArenaMixin:FontOutlineValues()
    return {
        [""] = L["Outline_None"],
        ["OUTLINE"] = L["Outline_Normal"],
        ["THICKOUTLINE"] = L["Outline_Thick"]
    }
end

function sArenaMixin:GetFontFlags(flags)
    flags = flags or ""
    if not (self.db and self.db.profile and self.db.profile.improveTextRendering) then
        return flags
    end
    if flags == "" then
        return "SLUG"
    end
    return flags .. ", SLUG"
end

local function captureFont(fs)
    if not fs or not fs.GetFont then return nil end
    local path, size, flags = fs:GetFont()
    if not path then return nil end
    return { path, size, flags }
end
local function applyFont(fs, fontTbl)
    if fs and fontTbl and fontTbl[1] then
        fs:SetFont(fontTbl[1], fontTbl[2], fontTbl[3])
    end
end
local function applyNameFont(fs, fontTbl)
    if fs and fontTbl and fontTbl[1] then
        sArenaMixin:SetNameFont(fs, fontTbl[1], fontTbl[2], fontTbl[3])
    end
end

function sArenaMixin:UpdateFonts()
    local db = self.db
    local fontCfg  = db.profile.layoutSettings[db.profile.currentLayout]
    if not fontCfg.changeFont then
        local og = self.ogFonts
        if og then
            for i = 1, self.maxArenaOpponents do
                local f = self["arena" .. i]
                applyNameFont(f.Name,        og.Name)
                applyFont(f.HealthText,  og.HealthText)
                applyFont(f.SpecNameText, og.SpecNameText)
                applyFont(f.PowerText,   og.PowerText)
                applyFont(f.CastBar and f.CastBar.Text, og.CastBarText)
                applyNameFont(f.PetFrame.Name,       og.PetName)
                applyFont(f.PetFrame.HealthText, og.PetHealthText)
                local fontName, s, o = f.CastBar.Text:GetFont()
                f.CastBar.Text:SetFont(fontName, s, self:GetFontFlags("OUTLINE"))
                if f.CastBar and f.CastBar.ArenaIDText then
                    applyFont(f.CastBar.ArenaIDText, og.CastBarIDText)
                    local _, cbSize = f.CastBar.Text:GetFont()
                    local idPath, _, idFlags = f.CastBar.ArenaIDText:GetFont()
                    if idPath and cbSize then
                        f.CastBar.ArenaIDText:SetFont(idPath, cbSize, idFlags)
                    end
                end
                if f.CastBar and f.CastBar.ArenaTargetText then
                    applyNameFont(f.CastBar.ArenaTargetText, og.CastBarTargetText)
                    local _, cbSize = f.CastBar.Text:GetFont()
                    local tPath, _, tFlags = f.CastBar.ArenaTargetText:GetFont()
                    if tPath and cbSize then
                        self:SetNameFont(f.CastBar.ArenaTargetText, tPath, cbSize - 2, tFlags)
                    end
                end
                if f.WidgetOverlay and f.WidgetOverlay.arenaTargetText then
                    applyNameFont(f.WidgetOverlay.arenaTargetText, og.ArenaTargetWidgetText)
                end
            end
            self.ogFonts = nil
        else
            for i = 1, self.maxArenaOpponents do
                local f = self["arena" .. i]
                local fontName, s, o = f.CastBar.Text:GetFont()
                f.CastBar.Text:SetFont(fontName, s, self:GetFontFlags("OUTLINE"))
            end
        end
        self:UpdateCastbarTimer()
        return
    end
    local frameKey = fontCfg.frameFont
    local cdKey    = fontCfg.cdFont

    local frameFontPath = frameKey and LSM:Fetch(LSM.MediaType.FONT, frameKey) or nil
    --local cdFontPath    = cdKey   and LSM:Fetch(LSM.MediaType.FONT, cdKey)   or nil

    local size    = fontCfg.size or 10
    local outline = fontCfg.fontOutline
    if outline == nil then
        outline = "OUTLINE"
    end

    -- Check if modern + simple castbar is enabled
    local modernCastbars = fontCfg.castBar and fontCfg.castBar.useModernCastbars
    local simpleCastbar = fontCfg.castBar and fontCfg.castBar.simpleCastbar
    local forceOutlineOnCastbar = modernCastbars and simpleCastbar

    local function setFont(fs, path, isCastbarText, sizeOverride, isName)
        if fs and path and fs.SetFont then
            local _, s = fs:GetFont()
            local outlineToUse = self:GetFontFlags(outline)

            -- Force outline on castbar text if modern + simple castbar is enabled
            if isCastbarText and forceOutlineOnCastbar and (outline == "" or outline == nil) then
                outlineToUse = self:GetFontFlags("OUTLINE")
            end

            if isName then
                self:SetNameFont(fs, path, sizeOverride or size, outlineToUse)
            else
                fs:SetFont(path, sizeOverride or size, outlineToUse)
            end
            if outlineToUse and outlineToUse:find("OUTLINE") then
                fs:SetShadowOffset(0, 0)
            else
                fs:SetShadowOffset(1, -1)
                fs:SetShadowColor(0, 0, 0, 1)
            end
        end
    end

    local widgets = fontCfg.widgets
    local ptt = widgets and widgets.partyTargetText
    local poaFontSize = ptt and ptt.partyOnArena and ptt.partyOnArena.fontSize
    local aopFontSize = ptt and ptt.arenaOnParty and ptt.arenaOnParty.fontSize

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        if frameFontPath then
            if not self.ogFonts then
                self.ogFonts = {
                    Name        = captureFont(frame.Name),
                    HealthText  = captureFont(frame.HealthText),
                    SpecNameText = captureFont(frame.SpecNameText),
                    PowerText   = captureFont(frame.PowerText),
                    CastBarText = captureFont(frame.CastBar and frame.CastBar.Text),
                    CastBarIDText = captureFont(frame.CastBar and frame.CastBar.ArenaIDText),
                    CastBarTargetText = captureFont(frame.CastBar and frame.CastBar.ArenaTargetText),
                    ArenaTargetWidgetText = captureFont(frame.WidgetOverlay and frame.WidgetOverlay.arenaTargetText),
                    PetName       = captureFont(frame.PetFrame.Name),
                    PetHealthText = captureFont(frame.PetFrame.HealthText),
                }
            end
            setFont(frame.Name, frameFontPath, false, nil, true)
            setFont(frame.HealthText, frameFontPath)
            setFont(frame.SpecNameText, frameFontPath)
            setFont(frame.PowerText,  frameFontPath)
            setFont(frame.PetFrame.Name,       frameFontPath, false, nil, true)
            setFont(frame.PetFrame.HealthText, frameFontPath)
            setFont(frame.CastBar.Text, frameFontPath, true)
            if frame.CastBar.ArenaIDText then
                setFont(frame.CastBar.ArenaIDText, frameFontPath, true)
                local _, cbSize = frame.CastBar.Text:GetFont()
                local idPath, _, idFlags = frame.CastBar.ArenaIDText:GetFont()
                if idPath and cbSize then
                    frame.CastBar.ArenaIDText:SetFont(idPath, cbSize, idFlags)
                end
            end
            if frame.CastBar.ArenaTargetText then
                setFont(frame.CastBar.ArenaTargetText, frameFontPath, true, nil, true)
                local _, cbSize = frame.CastBar.Text:GetFont()
                local tPath, _, tFlags = frame.CastBar.ArenaTargetText:GetFont()
                if tPath and cbSize then
                    self:SetNameFont(frame.CastBar.ArenaTargetText, tPath, cbSize - 2, tFlags)
                end
            end
            if frame.WidgetOverlay.arenaTargetText then
                setFont(frame.WidgetOverlay.arenaTargetText, frameFontPath, false, poaFontSize, true)
            end
        end
    end
    for i = 1, 5 do
        local partyFrame = self:GetPartyFrame(i)
        if partyFrame and partyFrame.WidgetOverlay and partyFrame.WidgetOverlay.partyTargetText and frameFontPath then
            setFont(partyFrame.WidgetOverlay.partyTargetText, frameFontPath, false, aopFontSize, true)
        end
    end
    self:UpdateCastbarTimer()
end

function sArenaFrameMixin:ApplyPrototypeFont()
    local db = self.parent.db
    local layout = db.profile.currentLayout
    local isProtoLayout = (layout == "Gladiuish" or layout == "Pixelated")
    local enable = isProtoLayout and not db.profile.layoutSettings[layout].changeFont

    if not enable and (not self.changedFonts or next(self.changedFonts) == nil) then
        return
    end

    if not self.changedFonts then
        self.changedFonts = {}
    end

    local function updateFont(obj, newSize, newFlags, isName)
        if not obj then return end

        local currentFont, currentSize, currentFlags = obj:GetFont()

        if enable then
            -- Save original font only once
            if not self.changedFonts[obj] then
                self.changedFonts[obj] = { currentFont, currentSize, currentFlags }
            end

            if isName then
                self.parent:SetNameFont(obj, self.parent.pFont, newSize or currentSize, newFlags or currentFlags)
            else
                obj:SetFont(self.parent.pFont, newSize or currentSize, newFlags or currentFlags)
            end
        else
            local original = self.changedFonts[obj]
            if original then
                if isName then
                    self.parent:SetNameFont(obj, unpack(original))
                else
                    obj:SetFont(unpack(original))
                end
                self.changedFonts[obj] = nil
            end
        end
    end

    updateFont(self.Name, nil, nil, true)
    updateFont(self.SpecNameText, 9)
    updateFont(self.HealthText)
    updateFont(self.PowerText)
    updateFont(self.PetFrame.Name, nil, nil, true)
    updateFont(self.PetFrame.HealthText)
    updateFont(self.CastBar.Text)
    if self.CastBar.ArenaIDText then
        local _, cbSize = self.CastBar.Text:GetFont()
        updateFont(self.CastBar.ArenaIDText, cbSize or nil)
    end
    if self.CastBar.ArenaTargetText then
        local _, cbSize = self.CastBar.Text:GetFont()
        updateFont(self.CastBar.ArenaTargetText, cbSize and (cbSize - 2) or nil, nil, true)
    end
end