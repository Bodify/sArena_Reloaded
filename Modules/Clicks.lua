-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local function ClearFrameAttributes(frame)
    if not frame.appliedClickAttributes then return end
    for _, attr in pairs(frame.appliedClickAttributes) do
        local mod = attr.modifier or ""
        frame:SetAttribute(mod .. "type" .. attr.button, nil)
        if attr.action == "macro" then
            frame:SetAttribute(mod .. "macrotext" .. attr.button, nil)
        elseif attr.action == "spell" then
            frame:SetAttribute(mod .. "spell" .. attr.button, nil)
        end
    end
    frame.appliedClickAttributes = nil
end

local function ApplyFrameAttributes(frame, attrs, cliqueEnabled)
    ClearFrameAttributes(frame)
    ClickCastFrames[frame] = cliqueEnabled and true or nil
    if cliqueEnabled then return end

    if not attrs then
        frame:SetAttribute("*type1", "target")
        frame:SetAttribute("*type2", "focus")
        return
    end

    local snapshot = {}
    for key, attr in pairs(attrs) do
        local mod = attr.modifier or ""
        frame:SetAttribute(mod .. "type" .. attr.button, attr.action)
        if attr.action == "macro" and attr.macro and attr.macro ~= "" then
            frame:SetAttribute(mod .. "macrotext" .. attr.button, string.gsub(attr.macro, "@arena", frame.unit))
        elseif attr.action == "spell" and attr.macro and attr.macro ~= "" then
            frame:SetAttribute(mod .. "spell" .. attr.button, attr.macro)
        end
        snapshot[key] = { button = attr.button, modifier = attr.modifier, action = attr.action }
    end
    frame.appliedClickAttributes = snapshot
end

function sArenaMixin:ApplyAllClickActions()
    if InCombatLockdown() then
        self.pendingClickActions = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    self.pendingClickActions = nil

    local profile = self.db and self.db.profile
    local cliqueEnabled = profile and profile.enableCliqueSupport and C_AddOns.IsAddOnLoaded("Clique") or false
    local arenaAttrs = profile and profile.clickAttributes
    local petAttrs = (profile and profile.usePetFrameClickActions) and profile.petFrameClickAttributes or arenaAttrs

    if not ClickCastFrames then ClickCastFrames = {} end

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        ApplyFrameAttributes(frame, arenaAttrs, cliqueEnabled)
        ApplyFrameAttributes(frame.PetFrame, petAttrs, cliqueEnabled)
    end
end

function sArenaMixin:RebuildClickActionsOptions()
    if not self.ClickActionsArgs or not self.BuildClickActionOption then return end
    local profile = self.db and self.db.profile

    local listArgs = {}
    local order = 1
    local clickAttributes = profile and profile.clickAttributes or {}
    for key, _ in pairs(clickAttributes) do
        listArgs[key] = self:BuildClickActionOption(key, order, "clickAttributes")
        order = order + 1
    end
    self.ClickActionsArgs.attributeList.args = listArgs

    if self.ClickActionsArgs.petFrameGroup and self.ClickActionsArgs.petFrameGroup.args.attributeList then
        local petListArgs = {}
        local petOrder = 1
        local petAttrs = profile and profile.petFrameClickAttributes or {}
        for key, _ in pairs(petAttrs) do
            petListArgs[key] = self:BuildClickActionOption(key, petOrder, "petFrameClickAttributes")
            petOrder = petOrder + 1
        end
        self.ClickActionsArgs.petFrameGroup.args.attributeList.args = petListArgs
    end
end
