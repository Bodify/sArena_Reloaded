-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local AceGUI = LibStub("AceGUI-3.0", true)

local LAYOUT_PREVIEW_DROPDOWN = "sArena_LayoutPreviewDropdown"
local PROFILE_PREVIEW_BUTTON = "sArena_ProfilePreviewButton"
local PROFILE_REVERT_DELAY = 0.5

sArenaMixin._layoutPreviewState = { originalLayout = nil, selectionMade = false, revertScheduled = 0 }
sArenaMixin._profilePreviewState = { active = false, revertScheduled = 0 }

function sArenaMixin:ApplyLayoutPreview(layout)
    if not layout then return end
    if not (self.layouts and self.layouts[layout]) then return end
    if InCombatLockdown() then return end
    if self.db and self.db.profile.currentLayout == layout then return end
    self:PreviewLayout(layout)
end

function sArenaMixin:CaptureLayoutPreview()
    local s = self._layoutPreviewState
    s.selectionMade = false
    s.revertScheduled = s.revertScheduled + 1
    s.originalLayout = self.db and self.db.profile.currentLayout or nil
end

function sArenaMixin:RevertLayoutPreview()
    local s = self._layoutPreviewState
    s.revertScheduled = s.revertScheduled + 1
    if s.selectionMade then return end
    if s.originalLayout then self:ApplyLayoutPreview(s.originalLayout) end
end

function sArenaMixin:ScheduleLayoutPreviewRevert()
    local s = self._layoutPreviewState
    s.revertScheduled = s.revertScheduled + 1
    local token = s.revertScheduled
    C_Timer.After(0, function()
        if s.revertScheduled ~= token or s.selectionMade then return end
        if s.originalLayout then self:ApplyLayoutPreview(s.originalLayout) end
    end)
end

function sArenaMixin:CancelLayoutPreviewRevert()
    self._layoutPreviewState.revertScheduled = self._layoutPreviewState.revertScheduled + 1
end

function sArenaMixin:OnLayoutPreviewSelection()
    local s = self._layoutPreviewState
    s.selectionMade = true
    self:CancelLayoutPreviewRevert()
    if self.db and s.originalLayout and self.db.profile.currentLayout ~= s.originalLayout then
        self.db.profile.currentLayout = s.originalLayout
    end
end

function sArenaMixin:ResetLayoutPreviewState()
    self._layoutPreviewState.originalLayout = nil
    self._layoutPreviewState.selectionMade = false
end

function sArenaMixin:PreviewProfileFromString(importString)
    if not importString then return end
    if InCombatLockdown() then return end
    if not self.PreviewProfile then return end
    if self:PreviewProfile(importString) then
        self._profilePreviewState.active = true
    end
end

function sArenaMixin:RevertProfilePreviewNow()
    local s = self._profilePreviewState
    s.revertScheduled = s.revertScheduled + 1
    if not s.active then return end
    s.active = false
    if InCombatLockdown() then return end
    if self.RevertProfilePreview then self:RevertProfilePreview() end
end

function sArenaMixin:CancelProfilePreviewRevert()
    self._profilePreviewState.revertScheduled = self._profilePreviewState.revertScheduled + 1
end

function sArenaMixin:ScheduleProfilePreviewRevert()
    local s = self._profilePreviewState
    s.revertScheduled = s.revertScheduled + 1
    local token = s.revertScheduled
    C_Timer.After(PROFILE_REVERT_DELAY, function()
        if s.revertScheduled ~= token then return end
        self:RevertProfilePreviewNow()
    end)
end

function sArenaMixin:OnProfilePreviewSelection()
    self:CancelProfilePreviewRevert()
    self._profilePreviewState.active = false
end

local function GetImportString(widget)
    local user = widget.GetUserDataTable and widget:GetUserDataTable()
    local option = user and user.option
    return option and option.arg or nil
end

local function LayoutPreviewDropdownConstructor()
    local widget = AceGUI:Create("Dropdown")
    if not widget then return end
    widget.type = LAYOUT_PREVIEW_DROPDOWN

    local origSetList = widget.SetList
    widget.SetList = function(self, list, order, itemType)
        origSetList(self, list, order, itemType)
        if not self.pullout then return end
        for _, item in self.pullout:IterateItems() do
            local value = item.userdata and item.userdata.value
            item:SetCallback("OnEnter", function()
                local frame = _G.sArena
                if not frame then return end
                frame:CancelLayoutPreviewRevert()
                frame:ApplyLayoutPreview(value)
            end)
            item:SetCallback("OnLeave", function()
                local frame = _G.sArena
                if frame then frame:ScheduleLayoutPreviewRevert() end
            end)
        end
    end

    local origFire = widget.Fire
    widget.Fire = function(self, name, ...)
        if name == "OnValueChanged" then
            local frame = _G.sArena
            if frame then frame:OnLayoutPreviewSelection() end
        end
        return origFire(self, name, ...)
    end

    local function InstallPulloutHooks(self)
        local pullout = self.pullout
        if not pullout then return end
        local prevOnOpen = pullout.events and pullout.events.OnOpen
        pullout:SetCallback("OnOpen", function(this, ...)
            local frame = _G.sArena
            if frame then frame:CaptureLayoutPreview() end
            if prevOnOpen then prevOnOpen(this, ...) end
        end)
        local prevOnClose = pullout.events and pullout.events.OnClose
        pullout:SetCallback("OnClose", function(this, ...)
            if prevOnClose then prevOnClose(this, ...) end
            local frame = _G.sArena
            if frame then
                frame:RevertLayoutPreview()
                frame:ResetLayoutPreviewState()
            end
        end)
    end

    local origOnAcquire = widget.OnAcquire
    widget.OnAcquire = function(self)
        origOnAcquire(self)
        InstallPulloutHooks(self)
    end
    InstallPulloutHooks(widget)

    return widget
end

local function ProfilePreviewButtonConstructor()
    local widget = AceGUI:Create("Button")
    if not widget then return end
    widget.type = PROFILE_PREVIEW_BUTTON

    local origFire = widget.Fire
    widget.Fire = function(self, name, ...)
        local frame = _G.sArena
        if frame then
            if name == "OnEnter" then
                frame:CancelProfilePreviewRevert()
                frame:PreviewProfileFromString(GetImportString(self))
            elseif name == "OnLeave" then
                frame:ScheduleProfilePreviewRevert()
            elseif name == "OnClick" then
                frame:OnProfilePreviewSelection()
            end
        end
        return origFire(self, name, ...)
    end

    return widget
end

AceGUI:RegisterWidgetType(LAYOUT_PREVIEW_DROPDOWN, LayoutPreviewDropdownConstructor, 1)
AceGUI:RegisterWidgetType(PROFILE_PREVIEW_BUTTON, ProfilePreviewButtonConstructor, 1)