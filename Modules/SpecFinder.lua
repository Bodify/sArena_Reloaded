-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

function sArenaMixin:GetSpecNameFromSpell(spellID)
    local spec = self.specCasts[spellID] or self.specBuffs[spellID]
    return spec
end

function sArenaFrameMixin:CheckForSpecSpell(spellID)
    if self.specName then return end
    if not self.class then return end

    local detectedSpec = self.parent:GetSpecNameFromSpell(spellID)
    if not detectedSpec then return end

    local classSpecs = self.parent.specIconTextures[self.class]
    if not classSpecs or not classSpecs[detectedSpec] then
        return false
    end

    self.specName = detectedSpec
    self.isHealer = self.parent.healerSpecNames[detectedSpec] or false
    self.specTexture = classSpecs[detectedSpec]

    self.SpecNameText:SetText(detectedSpec)
    local db = self.parent.db
    if db then
        self.SpecNameText:SetShown(db.profile.layoutSettings[db.profile.currentLayout].showSpecManaText)
    end
    self:UpdateSpecNameColor()

    self:UpdateSpecIcon()
    self:UpdateClassIcon(true)
    self:UpdateFrameColors()
    self.parent:UpdateTextures()

    if db then
        local currentLayout = self.parent.layouts[db.profile.currentLayout]
        if currentLayout and currentLayout.UpdateHealthbarOrientation then
            currentLayout:UpdateHealthbarOrientation(self)
        end
    end

    return true
end
