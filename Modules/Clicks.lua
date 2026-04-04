-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

function sArenaFrameMixin:ClearClickActions()
    if self.appliedClickAttributes then
        for _, attr in pairs(self.appliedClickAttributes) do
            local mod = attr.modifier or ""
            self:SetAttribute(mod .. "type" .. attr.button, nil)
            if attr.action == "macro" then
                self:SetAttribute(mod .. "macrotext" .. attr.button, nil)
            elseif attr.action == "spell" then
                self:SetAttribute(mod .. "spell" .. attr.button, nil)
            end
        end
    end
end

function sArenaFrameMixin:ApplyClickActions()
    if InCombatLockdown() then
        self.pendingClickActions = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    self:ClearClickActions()

    local db = self.parent and self.parent.db
    local clickAttributes = db and db.profile.clickAttributes
    if not clickAttributes then
        self:SetAttribute("*type1", "target")
        self:SetAttribute("*type2", "focus")
        return
    end

    for _, attr in pairs(clickAttributes) do
        local mod = attr.modifier or ""
        self:SetAttribute(mod .. "type" .. attr.button, attr.action)
        if attr.action == "macro" and attr.macro and attr.macro ~= "" then
            self:SetAttribute(mod .. "macrotext" .. attr.button, string.gsub(attr.macro, "@arena", self.unit))
        elseif attr.action == "spell" and attr.macro and attr.macro ~= "" then
            self:SetAttribute(mod .. "spell" .. attr.button, attr.macro)
        end
    end

    local snapshot = {}
    for key, attr in pairs(clickAttributes) do
        snapshot[key] = { button = attr.button, modifier = attr.modifier, action = attr.action }
    end
    self.appliedClickAttributes = snapshot
end

function sArenaMixin:ApplyAllClickActions()
    if InCombatLockdown() then
        for i = 1, self.maxArenaOpponents do
            local frame = self["arena" .. i]
            if frame then
                frame.pendingClickActions = true
                frame:RegisterEvent("PLAYER_REGEN_ENABLED")
            end
        end
        return
    end
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame then
            frame:ApplyClickActions()
        end
    end
end

function sArenaMixin:RebuildClickActionsOptions()
    if not self.ClickActionsArgs or not self.BuildClickActionOption then return end
    local listArgs = {}
    local order = 1
    local clickAttributes = self.db and self.db.profile.clickAttributes or {}
    for key, _ in pairs(clickAttributes) do
        listArgs[key] = self:BuildClickActionOption(key, order)
        order = order + 1
    end
    self.ClickActionsArgs.attributeList.args = listArgs
end
