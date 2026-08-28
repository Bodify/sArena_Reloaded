-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local dampeningSpellId = 110310
local dampeningName = C_Spell.GetSpellName(dampeningSpellId) or "Dampening"

function sArenaMixin:ResetDampening()
    if self.dampeningTicker then
        self.dampeningTicker:Cancel()
        self.dampeningTicker = nil
    end
    if self.DampeningText then
        if self.DampeningText.Text then
            self.DampeningText.Text:SetText("")
        end
        self.DampeningText:Hide()
        self:UpdateTopTextAnchors()
    end
end

function sArenaMixin:UpdateDampeningDisplay()
    local frame = self.DampeningText

    local db = self.db
    if not (db and db.profile.showDampening) then
        self:ResetDampening()
        return
    end

    local percent
    if self:IsInArena() and (self.engagedInMatch or self.arenaMatchStarted) then
        percent = C_Commentator.GetDampeningPercent()
    end

    if not percent or percent <= 0 then
        if frame:IsShown() then
            frame.Text:SetText("")
            frame:Hide()
            self:UpdateTopTextAnchors()
        end
        return
    end

    frame.Text:SetText(dampeningName .. ": " .. percent .. "%")
    if not frame:IsShown() then
        frame:Show()
        self:UpdateTopTextAnchors()
    end
end

function sArenaMixin:StartDampening()
    if not self.DampeningText then return end

    local db = self.db
    if not (db and db.profile.showDampening) then
        self:ResetDampening()
        return
    end

    self:UpdateDampeningDisplay()

    if not self.dampeningTicker then
        self.dampeningTicker = C_Timer.NewTicker(1, function()
            self:UpdateDampeningDisplay()
        end)
    end
end
