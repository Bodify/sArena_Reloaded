-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local isRetail = sArenaMixin.isRetail
local isMidnight = sArenaMixin.isMidnight
local LSM = LibStub("LibSharedMedia-3.0")

function sArenaFrameMixin:GetFactionTrinketIcon()
    local faction, _ = UnitFactionGroup(self.unit)
    if (faction == "Alliance") then
        return 133452
    else
        return 133453
    end
end

-- Helper function to check if we should force trinket display for humans in MoP
function sArenaFrameMixin:ShouldForceHumanTrinket()
    return not isRetail and self.race == "Human" and self.parent.db.profile.forceShowTrinketOnHuman
end

function sArenaFrameMixin:UpdateTrinketIcon(available)
    local colors = self.parent.db.profile.trinketColors
    local keepTexture = self.parent.db.profile.colorTrinketKeepTexture
    if available then
        if self.parent.db.profile.colorTrinket then
            if keepTexture then
                self.Trinket.Texture:SetDesaturated(true)
            else
                self.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
            end
            self.Trinket.Texture:SetVertexColor(unpack(colors.available))
        else
            self.Trinket.Texture:SetDesaturated(false)
        end
    else
        if self.parent.db.profile.colorTrinket then
            if not self.Trinket.spellID then
                self.Trinket.Texture:SetTexture(nil)
            else
                if keepTexture then
                    self.Trinket.Texture:SetDesaturated(true)
                else
                    self.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                end
                self.Trinket.Texture:SetVertexColor(unpack(colors.used))
            end
        else
            local desaturate
            if self.updateRacialOnTrinketSlot then
                desaturate = false
            else
                desaturate = self.parent.db.profile.desaturateTrinketCD
            end
            self.Trinket.Texture:SetDesaturated(desaturate)
        end
    end
end

local function GetArenaCCInfo(unit)
    if isMidnight then
        local durationObj = C_PvP.GetArenaCrowdControlDuration(unit)
        return durationObj
    else
        local spellID, itemID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)
        return spellID, startTime, duration
    end
end

function sArenaFrameMixin:UpdateTrinket()
    local spellID, startTime, duration = GetArenaCCInfo(self.unit)

    if (spellID) then
        local colors = self.parent.db.profile.trinketColors
        if isMidnight then
            -- local db = self.parent and self.parent.db
            -- self.Trinket.Cooldown:SetCooldownFromDurationObject(spellID)
            -- self.Trinket.Texture:SetDesaturated(db and db.profile.desaturateTrinketCD and not db.profile.colorTrinket)
            -- if db and db.profile.colorTrinket then
            --     self.Trinket.Texture:SetColorTexture(unpack(colors.used))
            -- end

            -- -- Update shared Racial CD
            -- if self.Racial.Texture:GetTexture() then
            --     local sharedCD = self:GetSharedCD()
            --     if sharedCD then
            --         self.Racial.Cooldown:SetCooldown(GetTime(), sharedCD)
            --     end
            -- end
        else
            if (startTime ~= 0 and duration ~= 0 and self.Trinket.spellID) then
                if self.Trinket.spellID and (self.Trinket.Texture:GetTexture() ~= self.parent.noTrinketTexture) then
                    if not self.Trinket.Cooldown:IsShown() then
                        local db = self.parent and self.parent.db
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
                    end
                    if self.updateRacialOnTrinketSlot then
                        local racialDuration = self:GetRacialDuration()
                        self.Trinket.Cooldown:SetCooldown(startTime / 1000.0, racialDuration)
                    else
                        self.Trinket.Cooldown:SetCooldown(startTime / 1000.0, duration / 1000.0)
                    end
                end
                if self.parent.db.profile.colorTrinket then
                    if self.parent.db.profile.colorTrinketKeepTexture then
                        self.Trinket.Texture:SetDesaturated(true)
                    else
                        self.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                    end
                    self.Trinket.Texture:SetVertexColor(unpack(colors.used))
                else
                    if not self.updateRacialOnTrinketSlot then
                        self.Trinket.Texture:SetDesaturated(self.parent.db.profile.desaturateTrinketCD)
                    end
                end
            else
                self.Trinket.Cooldown:Clear()
                if self.parent.db.profile.colorTrinket then
                    if self.parent.db.profile.colorTrinketKeepTexture then
                        self.Trinket.Texture:SetDesaturated(true)
                    else
                        self.Trinket.Texture:SetTexture("Interface\\Buttons\\WHITE8X8")
                    end
                    self.Trinket.Texture:SetVertexColor(unpack(colors.available))
                else
                    self.Trinket.Texture:SetDesaturated(false)
                end
            end
        end
    end
end

function sArenaFrameMixin:ResetTrinket()
    -- If racial was on trinket slot, move it back to racial slot
    if self.updateRacialOnTrinketSlot then
        self.updateRacialOnTrinketSlot = nil
        self:UpdateRacial()
    end

    self.Trinket.spellID = nil
    self.Trinket.Texture:SetTexture(nil)
    self.Trinket.Texture:SetVertexColor(1, 1, 1)
    self.Trinket.Texture:SetDesaturated(false)
    self.Trinket.Cooldown:Clear()
end
