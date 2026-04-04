local isRetail = sArenaMixin.isRetail
local isMidnight = sArenaMixin.isMidnight
local isTBC = sArenaMixin.isTBC
local L = sArenaMixin.L

-- Older clients dont show opponents in spawn
local noEarlyFrames = sArenaMixin.isTBC or sArenaMixin.isWrath

sArenaMixin.playerClass = select(2, UnitClass("player"))
sArenaMixin.maxArenaOpponents = (isRetail and 3) or 5
sArenaMixin.noTrinketTexture = (isTBC and 132311) or 638661 --temp texture for tbc. todo: export retail and include in sarena
sArenaMixin.trinketTexture = (isRetail and 1322720) or 133453
sArenaMixin.trinketID = (isRetail and 336126) or 42292

local LSM = LibStub("LibSharedMedia-3.0")
local decimalThreshold = 6 -- Default value, will be updated from db
LSM:Register("statusbar", "Blizzard RetailBar", [[Interface\AddOns\sArena_Reloaded\Textures\BlizzardRetailBar]])
LSM:Register("statusbar", "sArena Default", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaDefault]])
LSM:Register("statusbar", "sArena Stripes", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaHealer]])
LSM:Register("statusbar", "sArena Stripes 2", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaRetailHealer]])
LSM:Register("sound", "Lossa Trinket", [[Interface\AddOns\sArena_Reloaded\Textures\LossaTrinket.ogg]])
LSM:Register("sound", "Lossa Healer Trinket", [[Interface\AddOns\sArena_Reloaded\Textures\LossaHealerTrinket.ogg]])
-- Prototype font only supports western languages and Russian, so LSM will automatically reject registration on unsupported locales
LSM:Register("font", "Prototype", "Interface\\Addons\\sArena_Reloaded\\Textures\\Prototype.ttf", LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU)
LSM:Register("font", "PT Sans Narrow Bold", "Interface\\Addons\\sArena_Reloaded\\Textures\\PTSansNarrow-Bold.ttf", LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU)
-- Fetch pFont through LSM: use Prototype if registered, otherwise fall back to LSM's default font for the current locale
sArenaMixin.pFont = LSM:Fetch(LSM.MediaType.FONT, "Prototype") or LSM:Fetch(LSM.MediaType.FONT, LSM:GetDefault(LSM.MediaType.FONT))
sArenaMixin.hiddenFrame = CreateFrame("Frame")
sArenaMixin.hiddenFrame:Hide()

local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local stealthAlpha = 0.4
local shadowsightStartTime = 95
local shadowsightResetTime = 122
local shadowSightID = 34709

sArenaMixin.shadowsightTimers = {0, 0}
sArenaMixin.shadowsightAvailable = 2


-- Track which arena units we've seen (to work around UnitExists returning false for stealthed units)
if noEarlyFrames then
    sArenaMixin.seenArenaUnits = {}
end

sArenaMixin.healerSpecNames = {
    ["Discipline"] = true,
    ["Restoration"] = true,
    ["Mistweaver"] = true,
    ["Holy"] = true,
    ["Preservation"] = true,
}

sArenaMixin.classPowerType = {
    WARRIOR = "RAGE",
    ROGUE = "ENERGY",
    DRUID = "MANA",
    PALADIN = "MANA",
    HUNTER = "FOCUS",
    DEATHKNIGHT = "RUNIC_POWER",
    SHAMAN = "MANA",
    MAGE = "MANA",
    WARLOCK = "MANA",
    PRIEST = "MANA",
    DEMONHUNTER = "FURY",
    EVOKER = "ESSENCE",
}

function sArenaMixin:Print(msg)
    if msg then
        print("|cffffffffsArena |cffff8000Reloaded|r |T135884:13:13|t: " .. msg)
    end
end

local function IsSoloShuffle()
    return C_PvP and C_PvP.IsSoloShuffle and C_PvP.IsSoloShuffle()
end

sArenaMixin.classIcons = {
    ["DRUID"] = 625999,
    ["HUNTER"] = 135495, -- 626000
    ["MAGE"] = 135150, -- 626001
    ["MONK"] = 626002,
    ["PALADIN"] = 626003,
    ["PRIEST"] = 626004,
    ["ROGUE"] = 626005,
    ["SHAMAN"] = 626006,
    ["WARLOCK"] = 626007,
    ["WARRIOR"] = 135328, -- 626008
    ["DEATHKNIGHT"] = 135771,
    ["DEMONHUNTER"] = 1260827,
	["EVOKER"] = 4574311,
}

sArenaMixin.healerSpecIDs = {
    [65] = true,    -- Holy Paladin
    [105] = true,   -- Restoration Druid
    [256] = true,   -- Discipline Priest
    [257] = true,   -- Holy Priest
    [264] = true,   -- Restoration Shaman
    [270] = true,   -- Mistweaver Monk
    [1468] = true   -- Preservation Evoker
}

local castToAuraMap -- Spellcasts with non-duration aura spell ids

if isRetail then
    castToAuraMap = {
        [212182] = 212183, -- Smoke Bomb
        [359053] = 212183, -- Smoke Bomb
        [198838] = 201633, -- Earthen Wall Totem
        [62618]  = 81782,  -- Power Word: Barrier
        [204336] = 8178,   -- Grounding Totem
        [443028] = 456499, -- Celestial Conduit (Absolute Serenity)
        [289655] = 289655, -- Sanctified Ground
    }
    sArenaMixin.nonDurationAuras = {
        [212183] = {duration = 5, helpful = false, texture = 458733}, -- Smoke Bomb
        [201633] = {duration = 18, helpful = true, texture = 136098}, -- Earthen Wall Totem
        [81782]  = {duration = 10, helpful = true, texture = 253400}, -- Power Word: Barrier
        [8178]   = {duration = 3,  helpful = true, texture = 136039}, -- Grounding Totem
        [456499] = {duration = 4,  helpful = true, texture = 988197}, -- Celestial Conduit (Absolute Serenity)
        [289655] = {duration = 5,  helpful = true, texture = 237544}, -- Sanctified Ground
    }
else
    castToAuraMap = {
        [212182] = 212183, -- Smoke Bomb
        [359053] = 212183, -- Smoke Bomb
        [198838] = 201633, -- Earthen Wall Totem
        [62618]  = 81782,  -- Power Word: Barrier
        [204336] = 8178,   -- Grounding Totem
        [443028] = 456499, -- Celestial Conduit (Absolute Serenity)
        [289655] = 289655, -- Sanctified Ground
    }
        sArenaMixin.nonDurationAuras = {
        [212183] = {duration = 5, helpful = false, texture = 458733}, -- Smoke Bomb
        [201633] = {duration = 18, helpful = true, texture = 136098}, -- Earthen Wall Totem
        [81782]  = {duration = 10, helpful = true, texture = 253400}, -- Power Word: Barrier
        [8178]   = {duration = 3,  helpful = true, texture = 136039}, -- Grounding Totem
        [456499] = {duration = 4,  helpful = true, texture = 988197}, -- Celestial Conduit (Absolute Serenity)
        [289655] = {duration = 5,  helpful = true, texture = 237544}, -- Sanctified Ground
    }
end

sArenaMixin.activeNonDurationAuras = {}

local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID
local GetTime = GetTime
local UnitHealthMax = UnitHealthMax
local UnitHealth = UnitHealth
local UnitPowerMax = UnitPowerMax
local UnitPower = UnitPower
local UnitPowerType = UnitPowerType
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GetSpellName = GetSpellName or C_Spell.GetSpellName
local feignDeathID = 5384
local FEIGN_DEATH = GetSpellName(feignDeathID) -- Localized name for Feign Death

local db
local emptyLayoutOptionsTable = {
    notice = {
        name = L["Message_NoLayoutSettings"],
        type = "description",
    }
}

local MAX_INCOMING_HEAL_OVERFLOW = 1.0;
function sArenaFrameMixin:UpdateHealPrediction()
    if isMidnight then return end
	if ( not self.myHealPredictionBar and not self.otherHealPredictionBar and not self.healAbsorbBar and not self.totalAbsorbBar ) then
		return;
	end

	local _, maxHealth = self.healthbar:GetMinMaxValues();
	local health = self.healthbar:GetValue();
	if ( maxHealth <= 0 ) then
		return;
	end

	local myIncomingHeal = UnitGetIncomingHeals(self.unit, "player") or 0;
	local allIncomingHeal = UnitGetIncomingHeals(self.unit) or 0;
	local totalAbsorb = UnitGetTotalAbsorbs(self.unit) or 0;

	local myCurrentHealAbsorb = 0;
	if ( self.healAbsorbBar ) then
		myCurrentHealAbsorb = UnitGetTotalHealAbsorbs(self.unit) or 0;

		--We don't fill outside the health bar with healAbsorbs.  Instead, an overHealAbsorbGlow is shown.
		if ( health < myCurrentHealAbsorb ) then
			self.overHealAbsorbGlow:Show();
			myCurrentHealAbsorb = health;
		else
			self.overHealAbsorbGlow:Hide();
		end
	end

	--See how far we're going over the health bar and make sure we don't go too far out of the self.
	if ( health - myCurrentHealAbsorb + allIncomingHeal > maxHealth * MAX_INCOMING_HEAL_OVERFLOW ) then
		allIncomingHeal = maxHealth * MAX_INCOMING_HEAL_OVERFLOW - health + myCurrentHealAbsorb;
	end

	local otherIncomingHeal = 0;

	--Split up incoming heals.
	if ( allIncomingHeal >= myIncomingHeal ) then
		otherIncomingHeal = allIncomingHeal - myIncomingHeal;
	else
		myIncomingHeal = allIncomingHeal;
	end

	--We don't fill outside the the health bar with absorbs.  Instead, an overAbsorbGlow is shown.
	local overAbsorb = false;
	if ( health - myCurrentHealAbsorb + allIncomingHeal + totalAbsorb >= maxHealth or health + totalAbsorb >= maxHealth ) then
		if ( totalAbsorb > 0 ) then
			overAbsorb = true;
		end

		if ( allIncomingHeal > myCurrentHealAbsorb ) then
			totalAbsorb = max(0,maxHealth - (health - myCurrentHealAbsorb + allIncomingHeal));
		else
			totalAbsorb = max(0,maxHealth - health);
		end
	end

	if ( overAbsorb ) then
		self.overAbsorbGlow:Show();
	else
		self.overAbsorbGlow:Hide();
	end

	local healthTexture = self.healthbar:GetStatusBarTexture();
	local myCurrentHealAbsorbPercent = 0;
	local healAbsorbTexture = nil;

	if ( self.healAbsorbBar ) then
		myCurrentHealAbsorbPercent = myCurrentHealAbsorb / maxHealth;

		--If allIncomingHeal is greater than myCurrentHealAbsorb, then the current
		--heal absorb will be completely overlayed by the incoming heals so we don't show it.
		if ( myCurrentHealAbsorb > allIncomingHeal ) then
			local shownHealAbsorb = myCurrentHealAbsorb - allIncomingHeal;
			local shownHealAbsorbPercent = shownHealAbsorb / maxHealth;

			healAbsorbTexture = self.healAbsorbBar:UpdateFillPosition(healthTexture, shownHealAbsorb, -shownHealAbsorbPercent);

			--If there are incoming heals the left shadow would be overlayed by the incoming heals
			--so it isn't shown.
			-- self.healAbsorbBar.LeftShadow:SetShown(allIncomingHeal <= 0);

			-- The right shadow is only shown if there are absorbs on the health bar.
			-- self.healAbsorbBar.RightShadow:SetShown(totalAbsorb > 0)
		else
			self.healAbsorbBar:Hide();
		end
	end

	--Show myIncomingHeal on the health bar.
	local incomingHealTexture;
	if ( self.myHealPredictionBar ) then
		incomingHealTexture = self.myHealPredictionBar:UpdateFillPosition(healthTexture, myIncomingHeal, -myCurrentHealAbsorbPercent);
	end

	local otherHealLeftTexture = (myIncomingHeal > 0) and incomingHealTexture or healthTexture;
	local xOffset = (myIncomingHeal > 0) and 0 or -myCurrentHealAbsorbPercent;

	--Append otherIncomingHeal on the health bar
	if ( self.otherHealPredictionBar ) then
		incomingHealTexture = self.otherHealPredictionBar:UpdateFillPosition(otherHealLeftTexture, otherIncomingHeal, xOffset);
	end

	--Append absorbs to the correct section of the health bar.
	local appendTexture = nil;
	if ( healAbsorbTexture ) then
		--If there is a healAbsorb part shown, append the absorb to the end of that.
		appendTexture = healAbsorbTexture;
	else
		--Otherwise, append the absorb to the end of the the incomingHeals or health part;
		appendTexture = incomingHealTexture or healthTexture;
	end

	if ( self.totalAbsorbBar ) then
		self.totalAbsorbBar:UpdateFillPosition(appendTexture, totalAbsorb);
	end
end

local ABSORB_GLOW_ALPHA = 0.6
local ABSORB_GLOW_OFFSET = -5
function sArenaFrameMixin:UpdateAbsorb()
    if isMidnight then return end

    local unit     = self.unit
    local healthBar     = self.HealthBar
    local absorbBar     = self.totalAbsorbBar
    local absorbOverlay = self.totalAbsorbBarOverlay
    local glow          = self.overAbsorbGlow

    local maxHealth = UnitHealthMax(unit)
    local totalAbsorb   = UnitGetTotalAbsorbs(unit) or 0

    if maxHealth <= 0 or totalAbsorb <= 0 then
        absorbBar:Hide()
        absorbOverlay:Hide()
        glow:Hide()
        return
    end

    local currentHealth = UnitHealth(unit)
    local healthWidth  = healthBar:GetWidth()
    local healthHeight = healthBar:GetHeight()
    local isReversed   = self.parent.db.profile.reverseBarsFill or false

    -- Default, no Overshields.
    if self.parent.db.profile.disableOvershields then
        local isOverAbsorb = (currentHealth + totalAbsorb >= maxHealth)

        -- Clamp absorbs to actual missing health
        local missingHealth = maxHealth - currentHealth
        totalAbsorb = math.min(totalAbsorb, missingHealth)

        if isOverAbsorb then
            glow:Show()
        else
            glow:Hide()
        end

        if totalAbsorb > 0 then
            local absorbWidth        = healthWidth * (totalAbsorb / maxHealth)
            local missingHealthWidth = (maxHealth - currentHealth) / maxHealth * healthWidth
            local absorbBarWidth     = math.min(absorbWidth, missingHealthWidth)

            absorbBar:ClearAllPoints()
            absorbOverlay:ClearAllPoints()
            if isReversed then
                absorbBar:SetPoint("TOPRIGHT", healthBar, "TOPLEFT", missingHealthWidth, 0)
                absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0)
                absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0)
                if absorbOverlay.tileSize then
                    absorbOverlay:SetTexCoord(0, absorbBarWidth / absorbOverlay.tileSize, 0, healthHeight / absorbOverlay.tileSize)
                end
            else
                absorbBar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", currentHealth / maxHealth * healthWidth, 0)
                absorbOverlay:SetPoint("TOPLEFT", absorbBar, "TOPLEFT", 0, 0)
                absorbOverlay:SetPoint("BOTTOMLEFT", absorbBar, "BOTTOMLEFT", 0, 0)
                if absorbOverlay.tileSize then
                    absorbOverlay:SetTexCoord(1 - (absorbBarWidth / absorbOverlay.tileSize), 1, 0, healthHeight / absorbOverlay.tileSize)
                end
            end

            absorbBar:SetSize(absorbBarWidth, healthHeight)
            absorbBar:Show()
            absorbOverlay:SetSize(absorbBarWidth, healthHeight)
            absorbOverlay:Show()
        else
            absorbBar:Hide()
            absorbOverlay:Hide()
        end
    else
        -- Overshields: wrapping overlay + overshield glow
        local isOverAbsorb = false

        if totalAbsorb > maxHealth then
            isOverAbsorb = true
            totalAbsorb = maxHealth
        else
            isOverAbsorb = (currentHealth + totalAbsorb > maxHealth)
        end

        local absorbWidth        = totalAbsorb / maxHealth * healthWidth
        local missingHealthWidth = (maxHealth - currentHealth) / maxHealth * healthWidth
        local absorbBarWidth     = math.min(absorbWidth, missingHealthWidth)

        -- Show absorb bar only for missing health
        if absorbBarWidth > 0 then
            absorbBar:ClearAllPoints()
            if isReversed then
                absorbBar:SetPoint("TOPRIGHT", healthBar, "TOPLEFT", missingHealthWidth, 0)
            else
                absorbBar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", currentHealth / maxHealth * healthWidth, 0)
            end
            absorbBar:SetSize(absorbBarWidth, healthHeight)
            absorbBar:Show()
        else
            absorbBar:Hide()
        end

        -- Show striped overlay for full absorb width (wraps onto filled health if needed)
        if absorbWidth > 0 then
            absorbOverlay:SetParent(healthBar)
            absorbOverlay:ClearAllPoints()
            if isReversed then
                if isOverAbsorb then
                    absorbOverlay:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMLEFT", 0, 0)
                else
                    absorbOverlay:SetPoint("TOPLEFT", absorbBar, "TOPLEFT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMLEFT", absorbBar, "BOTTOMLEFT", 0, 0)
                end
            else
                if isOverAbsorb then
                    absorbOverlay:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
                else
                    absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0)
                    absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0)
                end
            end

            absorbOverlay:SetSize(absorbWidth, healthHeight)

            if absorbOverlay.tileSize then
                if isReversed then
                    absorbOverlay:SetTexCoord(0, absorbWidth / absorbOverlay.tileSize, 0, healthHeight / absorbOverlay.tileSize)
                else
                    absorbOverlay:SetTexCoord(1 - (absorbWidth / absorbOverlay.tileSize), 1, 0, healthHeight / absorbOverlay.tileSize)
                end
            end

            absorbOverlay:Show()
        else
            absorbOverlay:Hide()
        end

        -- Glow if over-absorb occurs
        glow:ClearAllPoints()
        if isOverAbsorb then
            if isReversed then
                glow:SetPoint("TOPRIGHT", absorbOverlay, "TOPRIGHT", -ABSORB_GLOW_OFFSET, 0)
                glow:SetPoint("BOTTOMRIGHT", absorbOverlay, "BOTTOMRIGHT", -ABSORB_GLOW_OFFSET, 0)
            else
                glow:SetPoint("TOPLEFT", absorbOverlay, "TOPLEFT", ABSORB_GLOW_OFFSET, 0)
                glow:SetPoint("BOTTOMLEFT", absorbOverlay, "BOTTOMLEFT", ABSORB_GLOW_OFFSET, 0)
            end
            glow:SetAlpha(ABSORB_GLOW_ALPHA)
            glow:Show()
        else
            glow:Hide()
        end
    end
end

function sArenaMixin:HandleArenaStart()
    self.arenaMatchStarted = true
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame:IsShown() then break end
        if UnitExists("arena"..i) then
            if noEarlyFrames then
                self.seenArenaUnits[i] = true
            end
            frame:UpdateVisible()
            frame:UpdatePlayer("seen")
        end
    end
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not UnitIsVisible("arena"..i) then
            frame:SetAlpha(stealthAlpha)
        end
    end
end

local matchStartedMessages = {
    ["The Arena battle has begun!"] = true, -- English / Default
    ["¡La batalla en arena ha comenzado!"] = true, -- esES / esMX
    ["A batalha na Arena começou!"] = true, -- ptBR
    ["Der Arenakampf hat begonnen!"] = true, -- deDE
    ["Le combat d'arène commence\194\160!"] = true, -- frFR
    ["Бой начался!"] = true, -- ruRU
    ["투기장 전투가 시작되었습니다!"] = true, -- koKR
    ["竞技场战斗开始了！"] = true, -- zhCN
    ["竞技场的战斗开始了！"] = true, -- zhCN (Wotlk)
    ["競技場戰鬥開始了！"] = true, -- zhTW
}

local function IsMatchStartedMessage(msg)
    return matchStartedMessages[msg]
end

-- Parent Frame
function sArenaMixin:OnLoad()
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    if not isMidnight then
        self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    elseif isMidnight then
        self:RegisterEvent("PVP_MATCH_ACTIVE")
        self:RegisterEvent("PVP_MATCH_STATE_CHANGED")
    end
end

local combatEvents = {
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_INTERRUPT"] = true,
    ["SPELL_AURA_REMOVED"] = true,
    ["SPELL_AURA_BROKEN"] = true,
    ["SPELL_AURA_REFRESH"] = true,
    ["SPELL_DISPEL"] = true,
}

function sArenaMixin:OnEvent(event, ...)
    if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        local _, combatEvent, _, sourceGUID, sourceName, _, _, destGUID, _, _, _, spellID, _, _, auraType = CombatLogGetCurrentEventInfo()
        if not combatEvents[combatEvent] then return end

        if combatEvent == "SPELL_CAST_SUCCESS" or combatEvent == "SPELL_AURA_APPLIED" then

            -- Old Arena Spec Detection
            if noEarlyFrames then

                if (self.specCasts[spellID] or self.specBuffs[spellID]) then
                    for i = 1, self.maxArenaOpponents do
                        if (sourceGUID == UnitGUID("arena" .. i)) then
                            local ArenaFrame = self["arena" .. i]
                            if ArenaFrame:CheckForSpecSpell(spellID) then
                                break
                            end
                        end
                    end
                end
            end

            -- Shadowsight
            if spellID == shadowSightID and db.profile.shadowSightTimer and not IsSoloShuffle() then
                self:OnShadowsightTaken()
            end

            -- Non-duration auras
            if castToAuraMap[spellID] and combatEvent == "SPELL_CAST_SUCCESS" then
                local auraID = castToAuraMap[spellID]
                self.activeNonDurationAuras[auraID] = GetTime()

                for i = 1, self.maxArenaOpponents do
                    local ArenaFrame = self["arena" .. i]
                    ArenaFrame:FindAura()
                end

                C_Timer.After(self.nonDurationAuras[auraID].duration, function()
                    self.activeNonDurationAuras[auraID] = nil
                end)
            end

            -- Racials
            if self.racialSpells[spellID] then
                for i = 1, self.maxArenaOpponents do
                    if (sourceGUID == UnitGUID("arena" .. i)) then
                        local ArenaFrame = self["arena" .. i]
                        ArenaFrame:FindRacial(spellID)
                    end
                end
            end

            -- TBC Stance Auras (not actual auras in TBC so needs to be manually tracked)
            if isTBC and self.stanceAuras[spellID] then
                for i = 1, self.maxArenaOpponents do
                    local unit = "arena" .. i
                    if (sourceGUID == UnitGUID(unit)) then
                        self.activeStanceAuras[unit] = spellID
                        local ArenaFrame = self[unit]
                        ArenaFrame:FindAura()
                        break
                    end
                end
            end
        end

        -- Dispels
        if combatEvent == "SPELL_DISPEL" then
            if self.dispelData[spellID] and db.profile.showDispels then
                for i = 1, self.maxArenaOpponents do
                    local ArenaFrame = self["arena" .. i]

                    local arenaGUID = UnitGUID("arena" .. i)
                    local petGUID = UnitGUID("arena" .. i .. "pet")

                    -- Check if dispel was cast by arena player or their pet
                    if sourceGUID == arenaGUID or (sourceGUID == petGUID and spellID == 119905) then
                        ArenaFrame:FindDispel(spellID)
                        break
                    end
                end
            end
        end

        -- DRs
        if self.drList[spellID] then
            for i = 1, self.maxArenaOpponents do
                if ( destGUID == UnitGUID("arena" .. i) and (auraType == "DEBUFF") ) then
                    local ArenaFrame = self["arena" .. i]
                    ArenaFrame:FindDR(combatEvent, spellID)
                    break
                end
            end
        end

        -- Interrupts
        if self.interruptList[spellID] then
            if combatEvent == "SPELL_INTERRUPT" or combatEvent == "SPELL_CAST_SUCCESS" then
                for i = 1, self.maxArenaOpponents do
                    if (destGUID == UnitGUID("arena" .. i)) then
                        local ArenaFrame = self["arena" .. i]
                        ArenaFrame:FindInterrupt(combatEvent, spellID, sourceName, sourceGUID)
                        break
                    end
                end
            end
        end

    elseif (event == "PLAYER_TARGET_CHANGED") then
        for i = 1, self.maxArenaOpponents do
            local frame = self["arena" .. i]
            frame:UpdateTarget(frame.unit)
        end

    elseif (event == "PLAYER_FOCUS_CHANGED") then
        for i = 1, self.maxArenaOpponents do
            local frame = self["arena" .. i]
            frame:UpdateFocus(frame.unit)
        end

    elseif (event == "UNIT_TARGET") then
        for i = 1, self.maxArenaOpponents do
            local frame = self["arena" .. i]
            frame:UpdateArenaTargets(frame.unit)
        end
        self:UpdateArenaTargetsOnPartyFrames()
    elseif (event == "PLAYER_LOGIN") then
        if isMidnight then
            C_CVar.SetCVar("spellDiminishPVPEnemiesEnabled", "1")
            self:EnsureArenaFramesEnabled()
            self:RegisterCVarListener()
        end
        self:Initialize()
        if self:CompatibilityIssueExists() then return end
        self:UpdatePlayerSpec()
        self:SetupGrayTrinket()
        self:AddMasqueSupport()

        if sArena_ReloadedDB.reOpenOptions then
            sArena_ReloadedDB.reOpenOptions = nil
            C_Timer.After(0.5, function()
                LibStub("AceConfigDialog-3.0"):Open("sArena")
            end)
        end


        self:UnregisterEvent("PLAYER_LOGIN")
    elseif (event == "PLAYER_ENTERING_WORLD") then
        local _, instanceType = IsInInstance()
        self:UpdateBlizzArenaFrameVisibility(instanceType)
        self:SetMouseState(instanceType ~= "arena")
        self.testMode = nil
        self.arenaMatchStarted = nil

        if noEarlyFrames then
            self.seenArenaUnits = {}
            if instanceType == "arena" then
                self.justEnteredArena = true
                C_Timer.After(6, function()
                    self.justEnteredArena = nil
                end)
            else
                self.justEnteredArena = nil
            end
        end

        if isMidnight then
            self:InitializeMidnightDRFrames()
            self:CheckMatchStatus(event)
        end

        self:SetupCustomCD()
        self:UpdateArenaTargetsOnPartyFrames()

        if (instanceType == "arena") then
            if not isMidnight then
                self:ResetDetectedDispels()
                if isTBC then
                    wipe(self.activeStanceAuras)
                end
                self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
            end
            self:RegisterWidgetEvents()
            self:RegisterInterruptEvents()
            self:UpdatePlayerSpec()
            if self.TestTitle then
                self.TestTitle:Hide()
                for i = 1, self.maxArenaOpponents do
                    local frame = self["arena" .. i]
                    frame.tempName = nil
                    frame.tempSpecName = nil
                    frame.tempClass = nil
                    frame.tempSpecIcon = nil
                    frame.isHealer = nil

                    if frame.drFrames then
                        for n = 1, #frame.drFrames do
                            local drFrame = frame.drFrames[n]
                            if drFrame then
                                drFrame:Hide()
                            end
                        end
                    end
                end
            end
        else
            if not isMidnight then
                self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
            end
            self:UnregisterWidgetEvents()
            self:UnregisterInterruptEvents()
            self:ResetShadowsightTimer()
        end
    elseif event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        local msg = ...
        if IsMatchStartedMessage(msg) then
            C_Timer.After(0.5, function()
                self:HandleArenaStart()
            end)
            if db.profile.shadowSightTimer and not IsSoloShuffle() then
                self:StartShadowsightTimer(shadowsightStartTime)
            end
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdatePlayerSpec()
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        self:ResetDetectedDispels()
        if isTBC then
            wipe(self.activeStanceAuras)
        end
    elseif event == "PVP_MATCH_STATE_CHANGED" or event == "PVP_MATCH_ACTIVE" then
        self:CheckMatchStatus(event)
    end
end

function sArenaMixin:ChatCommand(input)
    local cmd = (input or ""):trim():lower()
    if cmd == "" then
        LibStub("AceConfigDialog-3.0"):Open("sArena")
    elseif cmd == "convert" then
        self:ImportOtherForkSettings()
    elseif cmd == "ver" or cmd == "version" then
        self:Print(string.format(L["Print_CurrentVersion"], C_AddOns.GetAddOnMetadata("sArena_Reloaded", "Version")))
    elseif cmd:match("^test%s*[1-5]$") then
        self.testUnits = tonumber(cmd:match("(%d)"))
        input = "test"
        LibStub("AceConfigCmd-3.0").HandleCommand("sArena", "sarena", "sArena", input)
    else
        LibStub("AceConfigCmd-3.0").HandleCommand("sArena", "sarena", "sArena", input)
    end
end

function sArenaMixin:UpdatePlayerSpec()
    local currentSpec = isRetail and GetSpecialization() or C_SpecializationInfo.GetSpecialization()
    if currentSpec and currentSpec > 0 then
        local specID, specName
        if isRetail then
            specID, specName = GetSpecializationInfo(currentSpec)
        else
            specID, specName = C_SpecializationInfo.GetSpecializationInfo(currentSpec)
        end

        -- Only update if we actually got valid spec data
        if specID and specID > 0 and specName then
            self.playerSpecID = specID
            self.playerSpecName = specName
            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
        end
    end
end

function sArenaMixin:UpdateNoTrinketTexture()
    if self.db.profile.removeUnequippedTrinketTexture then
        self.noTrinketTexture = nil
    else
        self.noTrinketTexture = "Interface\\AddOns\\sArena_Reloaded\\Textures\\inv_pet_exitbattle.tga"
    end
end

function sArenaMixin:Initialize()
    if (db) then return end

    local compatIssue = self:CompatibilityIssueExists()

    self.db = LibStub("AceDB-3.0"):New("sArena_ReloadedDB", self.defaultSettings, true)
    db = self.db

    db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    self.optionsTable.handler = self
    self.optionsTable.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("sArena", self.optionsTable)
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("sArena", compatIssue and 520 or 860, compatIssue and 300 or 690)
    LibStub("AceConsole-3.0"):RegisterChatCommand("sarena", function(input) self:ChatCommand(input) end)
    self:InterruptTracker()
    if not compatIssue then
        self:DatabaseCleanup(db)
        if not isMidnight then
            self:UpdateDRTimeSetting()
        else
            self:UpdateAuraPrioImportant()
        end
        self:UpdateDecimalThreshold()
        self:UpdateNoTrinketTexture()
        self:RebuildClickActionsOptions()
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("sArena", "sArena |cffff8000Reloaded|r |T135884:13:13|t")
        self:SetLayout(_, db.profile.currentLayout)
    else
        C_Timer.After(5, function()
            self:Print(L["Print_MultipleVersionsLoaded"])
        end)
    end
end

function sArenaMixin:RefreshConfig()
    self:RebuildClickActionsOptions()
    self:SetLayout(_, db.profile.currentLayout)
end

function sArenaMixin:ResetShadowsightTimer()
    if self.shadowsightTicker then
        self.shadowsightTicker:Cancel()
        self.shadowsightTicker = nil
    end
    if self.ShadowsightTimer then
        if self.ShadowsightTimer.Text then
            self.ShadowsightTimer.Text:SetText("")
        end
        self.ShadowsightTimer:Hide()
    end
    self.shadowsightTimers = {0, 0}
    self.shadowsightAvailable = 2
end

function sArenaMixin:StartShadowsightTimer(time)
    if self.shadowsightTicker then
        self.shadowsightTicker:Cancel()
        self.shadowsightTicker = nil
    end

    self.ShadowsightTimer:ClearAllPoints()
    if UIWidgetTopCenterContainerFrame then
        self.ShadowsightTimer:SetParent(UIWidgetTopCenterContainerFrame)
        self.ShadowsightTimer:SetPoint("TOP", UIWidgetTopCenterContainerFrame, "BOTTOM", 0, 5)
    else
        self.ShadowsightTimer:SetPoint("TOP", UIParent, "TOP", 0, -100)
    end

    self.ShadowsightTimer:Show()

    local currentTime = GetTime()
    if isMidnight then
        -- On Midnight, just track spawn time and when to hide (35s after spawn)
        self.shadowsightTimers[1] = currentTime + time -- Time when eyes spawn
        self.shadowsightTimers[2] = currentTime + time + 35 -- Time to hide (35s after spawn)
        self.shadowsightAvailable = 0
    else
        self.shadowsightTimers[1] = currentTime + time
        self.shadowsightTimers[2] = currentTime + time
        self.shadowsightAvailable = 0
    end

    self.shadowsightTicker = C_Timer.NewTicker(0.1, function()
        self:UpdateShadowsightDisplay()
    end)
end

function sArenaMixin:OnShadowsightTaken()
    local currentTime = GetTime()
    local resetTime = currentTime + shadowsightResetTime

    if self.shadowsightTimers[1] <= 1 and self.shadowsightTimers[2] <= 1 then
        self.shadowsightTimers[1] = resetTime
        self.shadowsightTimers[2] = 0

        if not self.shadowsightTicker then
            self.ShadowsightTimer:ClearAllPoints()
            if UIWidgetTopCenterContainerFrame then
                self.ShadowsightTimer:SetParent(UIWidgetTopCenterContainerFrame)
                self.ShadowsightTimer:SetPoint("TOP", UIWidgetTopCenterContainerFrame, "BOTTOM", 0, -10)
            else
                self.ShadowsightTimer:SetPoint("TOP", UIParent, "TOP", 0, -100)
            end
            self.ShadowsightTimer:Show()

            self.shadowsightTicker = C_Timer.NewTicker(0.1, function()
                self:UpdateShadowsightDisplay()
            end)
        end
    else
        if self.shadowsightAvailable > 0 then
            self.shadowsightAvailable = self.shadowsightAvailable - 1
        end

        if self.shadowsightTimers[1] <= currentTime then
            self.shadowsightTimers[1] = resetTime
        elseif self.shadowsightTimers[2] <= currentTime then
            self.shadowsightTimers[2] = resetTime
        end
    end

    self:UpdateShadowsightDisplay()
end

function sArenaMixin:UpdateShadowsightDisplay()
    local currentTime = GetTime()

    if isMidnight then
        -- On Midnight: Show countdown until spawn, then hide after 45 seconds
        local spawnTime = self.shadowsightTimers[1]
        local hideTime = self.shadowsightTimers[2]

        if currentTime >= hideTime then
            -- Hide after 35 seconds from spawn
            self:ResetShadowsightTimer()
            return
        elseif currentTime >= spawnTime then
            local iconTexture = "|T136155:15:15|t"
            self.ShadowsightTimer.Text:SetText(L["Shadowsight_Ready"] .. " " .. iconTexture .. " " .. iconTexture)
        else
            local timeLeft = math.ceil(spawnTime - currentTime)
            self.ShadowsightTimer.Text:SetText(string.format(L["Shadowsight_SpawnsIn"], timeLeft))
        end
        return
    end

    local availableCount = 0
    local shortestTimer = math.huge

    for i = 1, 2 do
        if self.shadowsightTimers[i] <= currentTime then
            availableCount = availableCount + 1
        else
            shortestTimer = math.min(shortestTimer, self.shadowsightTimers[i])
        end
    end

    self.shadowsightAvailable = availableCount

    local iconTexture = "|T136155:15:15|t"
    local text = ""

    if availableCount == 2 then
        text = "Shadowsights Ready " .. iconTexture .. " " .. iconTexture
    elseif availableCount == 1 then
        text = "Shadowsight Ready " .. iconTexture
    elseif shortestTimer < math.huge then
        local timeLeft = math.ceil(shortestTimer - currentTime)
        text = string.format("Shadowsight spawns in %d sec", timeLeft)
    else
        text = "Shadowsight"
    end

    self.ShadowsightTimer.Text:SetText(text)
end

function sArenaFrameMixin:SetTextureCrop(texture, crop, type)
    if not texture then return end
    if type == "aura" then
        texture:SetTexCoord(0.03, 0.97, 0.03, 0.93)
    elseif type == "healer" then
        texture:SetTexCoord(0.205, 0.765, 0.22, 0.745)
    else
        if crop then
            texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            if type == "class" and db and ((db.profile.currentLayout == "BlizzRetail") or (db.profile.currentLayout == "BlizzArena")) then -- TODO: Fix this mess
                texture:SetTexCoord(0.05, 0.95, 0.1, 0.9)
            else
                texture:SetTexCoord(0, 1, 0, 1)
            end
        end
    end
end

function sArenaMixin:SetupGrayTrinket()
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        local cooldown = frame.Trinket.Cooldown
        cooldown:HookScript("OnCooldownDone", function()
            frame.Trinket.Texture:SetDesaturated(false)
        end)
        local dispelCooldown = frame.Dispel.Cooldown
        dispelCooldown:HookScript("OnCooldownDone", function()
            if (frame.Dispel.spellID or 1) ~= 527 then
                frame.Dispel.Texture:SetDesaturated(false)
            end
        end)
    end
end

function sArenaMixin:UpdateDecimalThreshold()
    decimalThreshold = self.db.profile.decimalThreshold or 6
end

function sArenaMixin:CreateCustomCooldown(cooldown, showDecimals)
    if isMidnight then
        cooldown:SetHideCountdownNumbers(false)
        if showDecimals and cooldown.SetCountdownMillisecondsThreshold then
            cooldown:SetCountdownMillisecondsThreshold(decimalThreshold)
        end
        return
    end

    local text = cooldown.sArenaText or cooldown:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    if not cooldown.sArenaText then
        cooldown.sArenaText = text

        if not cooldown.Text then
            for _, region in next, { cooldown:GetRegions() } do
                if region:GetObjectType() == "FontString" then
                    cooldown.Text = region;
                    cooldown.Text.fontFile = region:GetFont();
                end
            end
        end

        local f, s, o = cooldown.Text:GetFont()
        text:SetFont(f, s, o)

        local r, g, b, a = cooldown.Text:GetShadowColor()
        local x, y = cooldown.Text:GetShadowOffset()
        text:SetShadowColor(r, g, b, a)
        text:SetShadowOffset(x, y)

        text:SetPoint("CENTER", cooldown, "CENTER", 0, -1)
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
    end

    cooldown:SetHideCountdownNumbers(showDecimals)

    if showDecimals then
        cooldown.hideDefaultCD = true
        local lastUpdate = 0
        cooldown:SetScript("OnUpdate", function(self, elapsed)
            lastUpdate = lastUpdate + elapsed
            if lastUpdate < 0.1 then return end
            lastUpdate = 0

            local start, duration = cooldown:GetCooldownTimes()
            start, duration = start / 1000, duration / 1000
            local remaining = (start + duration) - GetTime()

            if remaining > 0 then
                if remaining < decimalThreshold then
                    text:SetFormattedText("%.1f", remaining)
                elseif remaining < 60 then
                    text:SetFormattedText("%d", remaining)
                elseif remaining < 3600 then
                    local m, s = math.floor(remaining / 60), math.floor(remaining % 60)
                    text:SetFormattedText("%d:%02d", m, s)
                else
                    text:SetFormattedText("%dh", math.floor(remaining / 3600))
                end
            else
                text:SetText("")
            end
        end)
    else
        cooldown.hideDefaultCD = nil
        cooldown:SetScript("OnUpdate", nil)
        text:SetText(nil)
    end
end

function sArenaMixin:SetupCustomCD()
    if C_AddOns.IsAddOnLoaded("OmniCC") then return end
    if self.customCDText then return end

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        -- Class icon cooldown
        self:CreateCustomCooldown(frame.ClassIcon.Cooldown, self.db.profile.showDecimalsClassIcon)

        local useDrFrames = frame.drFrames ~= nil
        local drList = frame.drFrames or self.drCategories
        if drList then
            for i = 1, #drList do
                local drFrame = useDrFrames and drList[i] or frame[drList[i]]
                if drFrame then
                    self:CreateCustomCooldown(drFrame.Cooldown, self.db.profile.showDecimalsDR)
                end
            end
        end
    end

    self.customCDText = true
end


function sArenaMixin:DarkMode()
    return db.profile.darkMode
end

function sArenaMixin:DarkModeColor()
    return db.profile.darkModeValue
end

function sArenaFrameMixin:DarkModeFrame()
    if not self.parent:DarkMode() then return end

    local darkModeColor = self.parent:DarkModeColor()
    local lighter = darkModeColor + 0.1
    local shouldDesaturate = db.profile.darkModeDesaturate
    local skipClassIcon = db.profile.classColorFrameTexture

    local frameTexture = self.frameTexture
    local specBorder = self.SpecIcon.Border
    local trinketBorder = self.Trinket.Border
    local trinketCircleBorder = self.Trinket.CircleBorder
    local racialBorder = self.Racial.Border
    local dispelBorder = self.Dispel.Border
    local castBorder = self.CastBar.Border
    local classIconBorder = self.ClassIcon.Texture.Border
    local castBackground = self.CastBar.Background

    if frameTexture then
        frameTexture:SetDesaturated(shouldDesaturate)
        frameTexture:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if specBorder then
        specBorder:SetDesaturated(shouldDesaturate)
        specBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
        if db.profile.currentLayout == "BlizzCompact" then
            local darkerCol = darkModeColor - 0.25
            specBorder:SetVertexColor(darkerCol, darkerCol, darkerCol)
        else
            specBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
        end
    end
    if classIconBorder and not skipClassIcon then
        classIconBorder:SetDesaturated(shouldDesaturate)
        classIconBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if castBorder then
        castBorder:SetDesaturated(shouldDesaturate)
        castBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if castBackground then
        castBackground:SetDesaturated(shouldDesaturate)
        castBackground:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if trinketBorder then
        trinketBorder:SetDesaturated(shouldDesaturate)
        trinketBorder:SetVertexColor(lighter, lighter, lighter)
    end
    if trinketCircleBorder then
        trinketCircleBorder:SetDesaturated(shouldDesaturate)
        trinketCircleBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
    end
    if racialBorder then
        racialBorder:SetDesaturated(shouldDesaturate)
        racialBorder:SetVertexColor(lighter, lighter, lighter)
    end
    if dispelBorder then
        dispelBorder:SetDesaturated(shouldDesaturate)
        dispelBorder:SetVertexColor(lighter, lighter, lighter)
    end

end

function sArenaFrameMixin:ClassColorFrameTexture()
    if not db.profile.classColorFrameTexture then return end

    local class = self.class or self.tempClass
    local color = RAID_CLASS_COLORS[class]

    if not color then return end

    local onlyClassIcon = db.profile.classColorFrameTextureOnlyClassIcon and db.profile.currentLayout == "BlizzCompact"
    local healerGreen = db.profile.classColorFrameTextureHealerGreen
    local isHealerGreen = healerGreen and self.isHealer

    local finalColor = color
    if isHealerGreen then
        finalColor = { r = 0, g = 1, b = 0 }
    end

    local frameTexture = self.frameTexture
    local specBorder = self.SpecIcon.Border
    local trinketBorder = self.Trinket.Border
    local racialBorder = self.Racial.Border
    local dispelBorder = self.Dispel.Border
    local castBorder = self.CastBar.Border
    local classIconBorder = self.ClassIcon.Texture.Border

    if classIconBorder then
        classIconBorder:SetDesaturated(true)
        classIconBorder:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
    end

    if onlyClassIcon then
        if self.parent:DarkMode() then
            local darkModeColor = self.parent:DarkModeColor()
            local lighter = darkModeColor + 0.1
            local shouldDesaturate = db.profile.darkModeDesaturate

            if frameTexture then
                frameTexture:SetDesaturated(shouldDesaturate)
                frameTexture:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
            end
            if specBorder then
                specBorder:SetDesaturated(shouldDesaturate)
                if db.profile.currentLayout == "BlizzCompact" then
                    local darkerCol = darkModeColor - 0.25
                    specBorder:SetVertexColor(darkerCol, darkerCol, darkerCol)
                else
                    specBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
                end
            end
            if castBorder then
                castBorder:SetDesaturated(shouldDesaturate)
                castBorder:SetVertexColor(darkModeColor, darkModeColor, darkModeColor)
            end
            if trinketBorder then
                trinketBorder:SetDesaturated(shouldDesaturate)
                trinketBorder:SetVertexColor(lighter, lighter, lighter)
            end
            if racialBorder then
                racialBorder:SetDesaturated(shouldDesaturate)
                racialBorder:SetVertexColor(lighter, lighter, lighter)
            end
            if dispelBorder then
                dispelBorder:SetDesaturated(shouldDesaturate)
                dispelBorder:SetVertexColor(lighter, lighter, lighter)
            end
        end
    else
        if frameTexture then
            frameTexture:SetDesaturated(true)
            frameTexture:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if specBorder then
            specBorder:SetDesaturated(true)
            specBorder:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if castBorder then
            castBorder:SetDesaturated(true)
            castBorder:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if trinketBorder then
            trinketBorder:SetDesaturated(true)
            local lighter_r = math.min(1, finalColor.r + 0.2)
            local lighter_g = math.min(1, finalColor.g + 0.2)
            local lighter_b = math.min(1, finalColor.b + 0.2)
            trinketBorder:SetVertexColor(lighter_r, lighter_g, lighter_b)
        end
        if racialBorder then
            racialBorder:SetDesaturated(true)
            local lighter_r = math.min(1, finalColor.r + 0.2)
            local lighter_g = math.min(1, finalColor.g + 0.2)
            local lighter_b = math.min(1, finalColor.b + 0.2)
            racialBorder:SetVertexColor(lighter_r, lighter_g, lighter_b)
        end
        if dispelBorder then
            dispelBorder:SetDesaturated(true)
            local lighter_r = math.min(1, finalColor.r + 0.2)
            local lighter_g = math.min(1, finalColor.g + 0.2)
            local lighter_b = math.min(1, finalColor.b + 0.2)
            dispelBorder:SetVertexColor(lighter_r, lighter_g, lighter_b)
        end
    end

    if self.PixelBorders and self.parent.showPixelBorder then
        local pixelBorders = self.PixelBorders
        if pixelBorders.main then
            pixelBorders.main:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if pixelBorders.classIcon then
            pixelBorders.classIcon:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if pixelBorders.trinket then
            pixelBorders.trinket:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if pixelBorders.racial then
            pixelBorders.racial:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if pixelBorders.dispel then
            pixelBorders.dispel:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if self.SpecIcon and self.SpecIcon.specIcon then
            self.SpecIcon.specIcon:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
        end
        if self.CastBar then
            if self.CastBar.castBar then
                self.CastBar.castBar:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
            end
            if self.CastBar.castBarIcon then
                self.CastBar.castBarIcon:SetVertexColor(finalColor.r, finalColor.g, finalColor.b)
            end
        end
    end
end

function sArenaFrameMixin:ResetPixelBorders()
    if self.PixelBorders and self.parent.showPixelBorder then
        local pixelBorders = self.PixelBorders

        if pixelBorders.main then
            pixelBorders.main:SetVertexColor(0, 0, 0)
        end
        if pixelBorders.classIcon then
            pixelBorders.classIcon:SetVertexColor(0, 0, 0)
        end
        if pixelBorders.trinket then
            pixelBorders.trinket:SetVertexColor(0, 0, 0)
        end
        if pixelBorders.racial then
            pixelBorders.racial:SetVertexColor(0, 0, 0)
        end
        if pixelBorders.dispel then
            pixelBorders.dispel:SetVertexColor(0, 0, 0)
        end
        if self.SpecIcon and self.SpecIcon.specIcon then
            self.SpecIcon.specIcon:SetVertexColor(0, 0, 0)
        end
        if self.CastBar then
            if self.CastBar.castBar then
                self.CastBar.castBar:SetVertexColor(0, 0, 0)
            end
            if self.CastBar.castBarIcon then
                self.CastBar.castBarIcon:SetVertexColor(0, 0, 0)
            end
        end
    end
end

function sArenaFrameMixin:UpdateFrameColors()
    if db.profile.classColorFrameTexture then
        self:ClassColorFrameTexture()
    elseif self.parent:DarkMode() then
        self:DarkModeFrame()
        self:ResetPixelBorders()
    else
        if self.frameTexture then
            self.frameTexture:SetDesaturated(false)
            self.frameTexture:SetVertexColor(1, 1, 1)
        end
        if self.SpecIcon.Border then
            if db.profile.currentLayout == "BlizzCompact" then
                self.SpecIcon.Border:SetDesaturated(true)
                self.SpecIcon.Border:SetVertexColor(0, 0, 0)
            else
                self.SpecIcon.Border:SetDesaturated(false)
                self.SpecIcon.Border:SetVertexColor(1, 1, 1)
            end
        end
        if self.ClassIcon.Texture.Border then
            self.ClassIcon.Texture.Border:SetDesaturated(false)
            self.ClassIcon.Texture.Border:SetVertexColor(1, 1, 1)
        end
        if self.CastBar.Border then
            self.CastBar.Border:SetDesaturated(false)
            self.CastBar.Border:SetVertexColor(1, 1, 1)
        end
        if self.Trinket.Border then
            self.Trinket.Border:SetDesaturated(false)
            self.Trinket.Border:SetVertexColor(1, 1, 1)
        end
        if self.Racial.Border then
            self.Racial.Border:SetDesaturated(false)
            self.Racial.Border:SetVertexColor(1, 1, 1)
        end
        self:ResetPixelBorders()
    end
end

function sArenaMixin:SetLayout(_, layout)
    if (InCombatLockdown()) then return end

    if not self.db then
        self.db = db
    end
    if not self.arena1 then
        for i = 1, self.maxArenaOpponents do
            local globalName = "sArenaEnemyFrame" .. i
            self["arena" .. i] = _G[globalName]
        end
    end

    self.showTrinketCircleBorder = nil

    layout = self.layouts[layout] and layout or "Gladiuish"

    -- Detect if this is a user-initiated layout change (not from addon load)
    local oldLayout = db.profile.currentLayout
    local isUserChange = oldLayout ~= nil and oldLayout ~= layout

    -- Handle BlizzRaid layout hideClassIcon setting
    if isUserChange then
        if layout == "BlizzRaid" then
            -- Store the previous hideClassIcon value before changing to BlizzRaid
            if not db.profile.hideClassIconBeforeBlizzRaid then
                db.profile.hideClassIconBeforeBlizzRaid = db.profile.hideClassIcon
            end
            db.profile.hideClassIcon = true
        elseif oldLayout == "BlizzRaid" then
            -- Restore the previous hideClassIcon value when leaving BlizzRaid
            if db.profile.hideClassIconBeforeBlizzRaid ~= nil then
                db.profile.hideClassIcon = db.profile.hideClassIconBeforeBlizzRaid
                db.profile.hideClassIconBeforeBlizzRaid = nil
            else
                db.profile.hideClassIcon = false
            end
        end
    end

    if layout == "BlizzRaid" or layout == "Pixelated" then
        self.showPixelBorder = true
    else
        self.showPixelBorder = false
    end

    db.profile.currentLayout = layout
    self.layoutdb = self.db.profile.layoutSettings[layout]

    self:RemovePixelBorders()

    self:UpdateTextures()

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        frame:ResetLayout()
        self.layouts[layout]:Initialize(frame)
        frame:SetupTargetFocusBorder()
        frame:UpdatePlayer(UnitExists(frame.unit) and "seen" or "unseen")
        frame:UpdateClassIconCooldownReverse()
        frame:UpdateTrinketRacialCooldownReverse()
        frame:UpdateClassIconSwipeSettings()
        frame:UpdateTrinketRacialSwipeSettings()
        frame:UpdateFrameColors()
        frame:UpdateNameColor()
        frame:UpdateSpecNameColor()
    end

    self:ModernOrClassicCastbar()
    self:UpdateCastBarSettings(self.layoutdb.castBar)
    self:CreateCastbarIDText()
    self:UpdateCastbarIDText()
    self:CreateCastbarHighlight()
    self:CreateCastbarTargetText()
    self:UpdateCastbarTargetText()
    self:UpdateFonts()

    for i = 1, self.maxArenaOpponents do
        self["arena"..i]:ApplyPrototypeFont()
    end

    self:UpdateCDTextVisibility()
    self:UpdateCastbarVisibility()
    self:ApplyAllClickActions()

    self.optionsTable.args.layoutSettingsGroup.args = self.layouts[layout].optionsTable and self.layouts[layout].optionsTable or emptyLayoutOptionsTable
    LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")

    local _, instanceType = IsInInstance()
    if (instanceType ~= "arena" and self.arena1:IsShown()) then
        self:Test()
    end
end

function sArenaMixin:SetupDrag(frameToClick, frameToMove, settingsTable, updateMethod, isWidget, subKey)
    local db = self.db
    if frameToClick.dragSetup then return end

    frameToClick:HookScript("OnMouseDown", function()
        if (InCombatLockdown()) then return end

        if (IsShiftKeyDown() and IsControlKeyDown() and not frameToMove.isMoving) then
            if isWidget then
                frameToMove.dragStartX, frameToMove.dragStartY = frameToMove:GetCenter()
            end
            self:HideTargetFocusBorderForDrag(frameToMove, isWidget)
            frameToMove:StartMoving()
            frameToMove.isMoving = true
        end
    end)

    frameToClick:HookScript("OnMouseUp", function()
        if (InCombatLockdown()) then return end

        if (frameToMove.isMoving) then
            frameToMove:StopMovingOrSizing()
            frameToMove.isMoving = false

            local settings

            if isWidget then
                settings = db.profile.layoutSettings[db.profile.currentLayout].widgets
                if not settings then
                    self:RestoreTargetFocusBorderAfterDrag(frameToMove, isWidget)
                    return
                end
                if not settings[settingsTable] then
                    settings[settingsTable] = {}
                end
                settings = settings[settingsTable]
                if subKey then
                    if not settings[subKey] then settings[subKey] = {} end
                    settings = settings[subKey]
                end
            else
                settings = db.profile.layoutSettings[db.profile.currentLayout]
                if (settingsTable) then
                    settings = settings[settingsTable]
                end
            end

            if isWidget then
                local newX, newY = frameToMove:GetCenter()
                local scale = frameToMove:GetScale()
                local deltaX = ((newX - frameToMove.dragStartX) * scale) / scale
                local deltaY = ((newY - frameToMove.dragStartY) * scale) / scale

                local currentX = settings.posX or 0
                local currentY = settings.posY or 0

                settings.posX = floor((currentX + deltaX) * 10 + 0.5) / 10
                settings.posY = floor((currentY + deltaY) * 10 + 0.5) / 10

                frameToMove.dragStartX = nil
                frameToMove.dragStartY = nil

                local widgetsSettings = db.profile.layoutSettings[db.profile.currentLayout].widgets
                self:UpdateWidgetSettings(widgetsSettings)
            else
                local frameX, frameY = frameToMove:GetCenter()
                local parentX, parentY = frameToMove:GetParent():GetCenter()
                local scale = frameToMove:GetScale()

                frameX = ((frameX * scale) - parentX) / scale
                frameY = ((frameY * scale) - parentY) / scale

                frameX = floor(frameX * 10 + 0.5) / 10
                frameY = floor(frameY * 10 + 0.5) / 10

                settings.posX, settings.posY = frameX, frameY
                self[updateMethod](self, settings)
            end

            self:RestoreTargetFocusBorderAfterDrag(frameToMove, isWidget)
            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
        end
    end)
    frameToClick.dragSetup = true
end

function sArenaMixin:SetMouseState(state)
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if frame.CastBar then
            frame.CastBar:EnableMouse(state)
        end
        if frame.midnightCastBarMoveFrame then
            frame.midnightCastBarMoveFrame:EnableMouse(state)
        end

        local useDrFrames = frame.drFrames ~= nil
        local drList = frame.drFrames or self.drCategories
        if drList then
            local mouseState = useDrFrames and false or state
            for i = 1, #drList do
                local drFrame = useDrFrames and drList[i] or frame[drList[i]]
                if drFrame then
                    drFrame:EnableMouse(mouseState)
                end
            end
        end

        frame.SpecIcon:EnableMouse(state)
        frame.Trinket:EnableMouse(state)
        frame.Racial:EnableMouse(state)
        frame.Dispel:EnableMouse(state)
        frame.ClassIcon:EnableMouse(state)

        for _, child in pairs({frame.WidgetOverlay:GetChildren()}) do
            child:EnableMouse(state)
        end

        if noEarlyFrames and not InCombatLockdown() then
            local shouldEnableMouse
            if state then
                -- Outside arena: always clickable
                shouldEnableMouse = true
            else
                -- Inside arena: only clickable up to party size
                local partySize = GetNumGroupMembers() or 2
                shouldEnableMouse = (i <= partySize)
            end

            frame:EnableMouse(shouldEnableMouse)
        end
    end
end


local function ResetTexture(texturePool, t)
    if (texturePool) then
        t:SetParent(texturePool.parent)
    end

    t:SetTexture(nil)
    t:SetColorTexture(0, 0, 0, 0)
    t:SetVertexColor(1, 1, 1, 1)
    t:SetDesaturated(false)
    t:SetTexCoord(0, 1, 0, 1)
    t:ClearAllPoints()
    t:SetSize(0, 0)
    t:Hide()
end

function sArenaFrameMixin:CreateCastBar()
    self.CastBar = CreateFrame("StatusBar", nil, self, "sArenaCastBarFrameTemplate")
end

function sArenaFrameMixin:CreateDRFrames()
    local id = self:GetID()
    for _, category in ipairs(self.parent.drCategories) do
        local name = "sArenaEnemyFrameDR" .. id .. category
        local drFrame = CreateFrame("Frame", name, self, "sArenaDRFrameTemplate")
        self[category] = drFrame
    end
end

function sArenaFrameMixin:OnLoad()
    local unit = "arena" .. self:GetID()
    self.unit = unit
    self.parent = self:GetParent()
    if self.parent:CompatibilityIssueExists() then return end

    if noEarlyFrames then
        self.ogSetShown = self.SetShown
        self.SetShown = function(self, show)
            local _, instanceType = IsInInstance()
            self.shouldBeShown = show
            if show then
                self:SetAlpha(1)
            else
                self:SetAlpha(0)
            end
            if not InCombatLockdown() and instanceType ~= "arena" then
                self.ogSetShown(self, show)
            end
        end
        self.ogShow = self.Show
        self.Show = function(self)
            local _, instanceType = IsInInstance()
            self.shouldBeShown = true
            self:SetAlpha(1)
            if not InCombatLockdown() and instanceType ~= "arena" then
                self.ogShow(self)
            end
        end

        self.ogHide = self.Hide
        self.Hide = function(self)
            local _, instanceType = IsInInstance()
            self.shouldBeShown = false
            self:SetAlpha(0)
            if not InCombatLockdown() and instanceType ~= "arena" then
                self.ogHide(self)
            end
        end

        self.ogSetAlpha = self.SetAlpha
        self.SetAlpha = function(self, alpha)
            if self.shouldBeShown == false then
                self.ogSetAlpha(self, 0)
            else
                self.ogSetAlpha(self, alpha)
            end
        end
    end

    if not isMidnight then
        self:CreateCastBar()
        self:CreateDRFrames()
        if isTBC then
            self.CastBar.empoweredFix = true
            self.CastBar:SetUnit(unit, false, true)
        else
            CastingBarFrame_SetUnit(self.CastBar, unit, false, true)
        end
    else
        local blizzArenaFrame = _G["CompactArenaFrameMember" .. self:GetID()]
        self.CastBar = blizzArenaFrame.CastingBarFrame
        self.CastBar:SetFrameStrata("HIGH")
        self.totalAbsorbBar:Hide()
        self.overAbsorbGlow:Hide()
        self.overHealAbsorbGlow:Hide()
        self.otherHealPredictionBar:Hide()
        self.totalAbsorbBarOverlay:Hide()
        self.myHealPredictionBar:Hide()

        self:NormalEmpoweredCastbar()
        self:HookMidnightTrinket()
    end

    self:RegisterForClicks("AnyDown", "AnyUp")
    self:SetAttribute("unit", unit)
    self:ApplyClickActions()
    self:RegisterFrameEvents()

    local CastStopEvents  = {
        UNIT_SPELLCAST_STOP                = true,
        UNIT_SPELLCAST_CHANNEL_STOP        = true,
        UNIT_SPELLCAST_INTERRUPTED         = true,
        UNIT_SPELLCAST_EMPOWER_STOP        = true,
    }

    local CastStartEvents = {
        UNIT_SPELLCAST_START                = true,
        UNIT_SPELLCAST_CHANNEL_START        = true,
        UNIT_SPELLCAST_EMPOWER_START        = true,
    }

    self.CastBar:HookScript("OnEvent", function(castBar, event, eventUnit, castGUID, spellID, interruptedByOrCastBarID)
        if CastStopEvents[event] and eventUnit == unit then
            if event == "UNIT_SPELLCAST_INTERRUPTED" then
                castBar.stoppedCast = true
                if isMidnight and interruptedByOrCastBarID ~= nil then
                    castBar.wasKicked = true
                end
            end
            if not (castBar.interruptedBy or castBar.wasKicked) then
                local cast = UnitCastingInfo(unit) or UnitChannelInfo(unit)
                if not cast then
                    castBar:Hide()
                    if isRetail then
                        return
                    end
                end
            end
        elseif CastStartEvents[event] and eventUnit == unit then
            castBar.wasKicked = nil
            castBar.stoppedCast = nil
        end

        self.parent:CastbarOnEvent(self.CastBar, event, interruptedByOrCastBarID)
        self.parent:UpdateCastbarTargetOnEvent(self.CastBar, event)
    end)

    self.healthbar = self.HealthBar

    self.myHealPredictionBar:ClearAllPoints()
    self.otherHealPredictionBar:ClearAllPoints()
    self.totalAbsorbBar:ClearAllPoints()
    self.overAbsorbGlow:ClearAllPoints()
    self.overHealAbsorbGlow:ClearAllPoints()

    self.totalAbsorbBar:SetTexture(self.totalAbsorbBar.fillTexture)
    self.totalAbsorbBar:SetVertexColor(1, 1, 1)
    self.totalAbsorbBar:SetHeight(self.healthbar:GetHeight())

    self.overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
    self.overAbsorbGlow:SetBlendMode("ADD")
    self.overAbsorbGlow:SetPoint("TOPLEFT", self.healthbar, "TOPRIGHT", -7, 0)
    self.overAbsorbGlow:SetPoint("BOTTOMLEFT", self.healthbar, "BOTTOMRIGHT", -7, 0)

    self.overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", self.healthbar, "BOTTOMLEFT", 7, 0)
    self.overHealAbsorbGlow:SetPoint("TOPRIGHT", self.healthbar, "TOPLEFT", 7, 0)

    self.AuraStacks:SetTextColor(1,1,1,1)
    self.AuraStacks:SetJustifyH("LEFT")
    self.AuraStacks:SetJustifyV("BOTTOM")

    self.DispelStacks:SetTextColor(1,1,1,1)
    self.DispelStacks:SetJustifyH("LEFT")
    self.DispelStacks:SetJustifyV("BOTTOM")

    if not self.Dispel.Overlay then
        self.Dispel.Overlay = CreateFrame("Frame", nil, self.Dispel)
        self.Dispel.Overlay:SetFrameStrata("MEDIUM")
        self.Dispel.Overlay:SetFrameLevel(10)
    end

    self.WidgetOverlay.targetIndicator.Texture:SetAtlas("TargetCrosshairs")
    self.WidgetOverlay.focusIndicator.Texture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\Waypoint-MapPin-Untracked.tga")
    self.WidgetOverlay.combatIndicator.Texture:SetAtlas("Food")
    for i = 1, 4 do
        local pt = self.WidgetOverlay["partyTarget" .. i]
        pt.Texture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\GM-icon-headCount.tga")
        pt.Texture:SetDesaturated(true)
    end
    self.WidgetOverlay.targetIndicator:SetFrameLevel(15)
    self.Trinket:SetFrameLevel(7)

    self.DispelStacks:SetParent(self.Dispel.Overlay)

    self.TexturePool = CreateTexturePool(self, "ARTWORK", nil, nil, ResetTexture)

    self:SetupTrinketCooldownDone()
end

function sArenaFrameMixin:OnEvent(event, eventUnit, arg1)
    local unit = self.unit

    if (eventUnit and eventUnit == unit) then
        if (event == "UNIT_NAME_UPDATE") then
            if (db.profile.showArenaNumber) then
                local id = self.unit:match("%d+")
                if FrameSortApi then
                    id = FrameSortApi.v3.Frame:FrameNumberForUnit(self.unit) or id
                end
                if db.profile.arenaNumberIdOnly then
                    self.Name:SetText(id)
                else
                    self.Name:SetText("Arena " .. id)
                end
            elseif (db.profile.showNames) then
                self.Name:SetText(UnitFullName(unit))
            end
            self:UpdateNameColor()
        elseif (event == "ARENA_OPPONENT_UPDATE") then
            self:UpdatePlayer(arg1)
        elseif (event == "ARENA_COOLDOWNS_UPDATE") then
             self:UpdateTrinket()
        elseif (event == "ARENA_CROWD_CONTROL_SPELL_UPDATE") then
            -- arg1 == spellID
            if (arg1 ~= self.Trinket.spellID) then
                if arg1 ~= 0 then
                    local _, spellTextureNoOverride = GetSpellTexture(arg1)

                    -- Check if we had racial on trinket slot before
                    local wasRacialOnTrinketSlot = self.updateRacialOnTrinketSlot

                    self.Trinket.spellID = arg1

                    -- Determine if we should put racial on trinket slot
                    local swapEnabled = db.profile.swapRacialTrinket or db.profile.swapHumanTrinket
                    local shouldPutRacialOnTrinket = swapEnabled and self.race and not spellTextureNoOverride

                    -- Set the trinket texture
                    local trinketTexture
                    if spellTextureNoOverride then
                        if isRetail then
                            trinketTexture = spellTextureNoOverride
                        else
                            trinketTexture = self:GetFactionTrinketIcon()
                        end
                    else
                        if not isRetail and self.race == "Human" and db.profile.forceShowTrinketOnHuman then
                            trinketTexture = self:GetFactionTrinketIcon()
                            self.Trinket.spellID = self.parent.trinketID
                        else
                            trinketTexture = self.parent.noTrinketTexture     -- Surrender flag if no trinket
                        end
                    end

                    -- Handle racial updates based on trinket state (same logic as UpdateTrinket)
                    if spellTextureNoOverride and wasRacialOnTrinketSlot then
                        -- We found a real trinket and had racial on trinket slot, restore racial to its proper place
                        self.updateRacialOnTrinketSlot = nil
                        self.Trinket.Texture:SetTexture(trinketTexture)
                        self:UpdateRacial()
                    elseif shouldPutRacialOnTrinket then
                        -- We should put racial on trinket slot (no real trinket found)
                        self.updateRacialOnTrinketSlot = true
                        -- Don't set trinket texture yet - let UpdateRacial handle it for racial display
                        self:UpdateRacial()
                    else
                        -- Normal case: set trinket texture and clear racial from trinket slot
                        self.updateRacialOnTrinketSlot = nil
                        self.Trinket.Texture:SetTexture(trinketTexture)
                        -- Update racial to ensure it shows in racial slot if needed
                        if wasRacialOnTrinketSlot then
                            self:UpdateRacial()
                        end
                    end

                    self:UpdateTrinketIcon(true)
                else
                    -- No trinket - check if we should put racial on trinket slot
                    local swapEnabled = db.profile.swapRacialTrinket or db.profile.swapHumanTrinket
                    local shouldPutRacialOnTrinket = swapEnabled and self.race

                    if shouldPutRacialOnTrinket then
                        self.updateRacialOnTrinketSlot = true
                        self:UpdateRacial()
                        if isRetail then return end -- Need to test MoP more...
                    else
                        self.updateRacialOnTrinketSlot = nil
                        -- Ensure racial shows in racial slot if it was on trinket before
                        self:UpdateRacial()
                    end

                    if not isRetail and self.race == "Human" and db.profile.forceShowTrinketOnHuman then
                        self.Trinket.spellID = self.parent.trinketID
                        self.Trinket.Texture:SetTexture(self:GetFactionTrinketIcon())
                        self:UpdateTrinketIcon(true)
                    else
                        if db.profile.swapRacialTrinket then
                            self:UpdateRacial()
                        else
                            self.Trinket.Texture:SetTexture(self.parent.noTrinketTexture)
                            self:UpdateTrinketIcon(false)
                        end
                    end
                end
            end
        elseif (event == "UNIT_AURA") then
            self:FindAura(arg1)
        elseif (event == "UNIT_HEALTH") then
            if isMidnight then
                local isDead = UnitIsDeadOrGhost(unit)
                self.hideStatusText = isDead
                self.HealthBar:SetValue(UnitHealth(unit))
                if (isDead) then
                    --self.HealthBar:SetValue(0)
                    self.SpecNameText:SetText("")
                    self.WidgetOverlay:Hide()
                end
                self.DeathIcon:SetShown(isDead)
                self:SetStatusText()
            else
                local currentHealth = UnitHealth(unit)
                if currentHealth ~= 0 then
                    self:SetStatusText()
                    self.HealthBar:SetValue(currentHealth)
                    self:UpdateHealPrediction()
                    self:UpdateAbsorb()
                    self.DeathIcon:SetShown(false)
                    self.hideStatusText = false
                    self.currentHealth = currentHealth
                    if self.isFeigningDeath then
                        self.HealthBar:SetAlpha(1)
                        self.isFeigningDeath = nil
                    end
                else
                    self:SetLifeState()
                end
            end
        elseif (event == "UNIT_MAXHEALTH") then
            self.HealthBar:SetMinMaxValues(0, UnitHealthMax(unit))
            self.HealthBar:SetValue(UnitHealth(unit))
            self:UpdateHealPrediction()
            self:UpdateAbsorb()
        elseif (event == "UNIT_POWER_UPDATE") then
            self:SetStatusText()
            self.PowerBar:SetValue(UnitPower(unit))
        elseif (event == "UNIT_MAXPOWER") then
            self.PowerBar:SetMinMaxValues(0, UnitPowerMax(unit))
            self.PowerBar:SetValue(UnitPower(unit))
        elseif (event == "UNIT_DISPLAYPOWER") then
            local _, powerType = UnitPowerType(unit)
            self:SetPowerType(powerType)
            self.PowerBar:SetMinMaxValues(0, UnitPowerMax(unit))
            self.PowerBar:SetValue(UnitPower(unit))
        elseif (event == "UNIT_ABSORB_AMOUNT_CHANGED") then
            self:UpdateHealPrediction()
            self:UpdateAbsorb()
        elseif (event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED") then
            self:UpdateHealPrediction()
            self:UpdateAbsorb()
        elseif (event == "UNIT_FLAGS") then
            self:UpdateCombatStatus(unit)
        end

    elseif (event == "PLAYER_LOGIN") then
        self:UnregisterEvent("PLAYER_LOGIN")

        if (not db) then
            self.parent:Initialize()
        end

        self:Initialize()
    elseif (event == "PLAYER_ENTERING_WORLD") or (event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS") then
        local _, instanceType = IsInInstance()


        if noEarlyFrames and instanceType == "arena" and self.ogShow then
            self.ogShow(self)
            self:SetAlpha(0)
        end

        self:StopStealthHealthTicker()
        self.Name:SetText("")
        self.CastBar:Hide()
        self.specTexture = nil
        self.class = nil
        self.currentClassIconTexture = nil
        self.currentClassIconStartTime = 0
        self.updateRacialOnTrinketSlot = nil
        self:UpdateVisible()
        self:ResetTrinket()
        self:ResetRacial()
        if not isMidnight then
            self:ResetDispel()
        end
        self:ResetDR()
        self:UpdateHealPrediction()
        self:UpdateAbsorb()
        self:UpdatePlayer(UnitExists(self.unit) and "seen" or "unseen")
        --self:SetAlpha((noEarlyFrames and (UnitExists(self.unit) and 1 or stealthAlpha)) or (UnitIsVisible(self.unit) and 1 or stealthAlpha))
        self.HealthBar:SetAlpha(1)
        if self.parent.TestTitle then
            self.parent.TestTitle:Hide()
        end
    elseif (event == "PLAYER_REGEN_ENABLED") then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UpdateVisible()
        if self.pendingClickActions then
            self.pendingClickActions = nil
            self:ApplyClickActions()
        end
    end
end

function sArenaFrameMixin:Initialize()
    if isMidnight then
        self.parent:CheckMatchStatus("PLAYER_LOGIN")
    end
    self:SetMysteryPlayer()
    self.parent:SetupDrag(self, self.parent, nil, "UpdateFrameSettings")

    local firstDR = self.drFrames and self.drFrames[1] or self[self.parent.drCategories[1]]
    if firstDR then
        self.parent:SetupDrag(firstDR, firstDR, "dr", "UpdateDRSettings")
    end
    if isMidnight then
        self:SetupMidnightCastBarDrag()
    else
        self.parent:SetupDrag(self.CastBar, self.CastBar, "castBar", "UpdateCastBarSettings")
    end

    self.parent:SetupDrag(self.SpecIcon, self.SpecIcon, "specIcon", "UpdateSpecIconSettings")
    self.parent:SetupDrag(self.Trinket, self.Trinket, "trinket", "UpdateTrinketSettings")
    self.parent:SetupDrag(self.Racial, self.Racial, "racial", "UpdateRacialSettings")
    self.parent:SetupDrag(self.Dispel, self.Dispel, "dispel", "UpdateDispelSettings")

    self.parent:SetupDrag(self.WidgetOverlay.combatIndicator, self.WidgetOverlay.combatIndicator, "combatIndicator", nil, true)
    self.parent:SetupDrag(self.WidgetOverlay.targetIndicator, self.WidgetOverlay.targetIndicator, "targetIndicator", nil, true)
    self.parent:SetupDrag(self.WidgetOverlay.focusIndicator, self.WidgetOverlay.focusIndicator, "focusIndicator", nil, true)
    self.parent:SetupDrag(self.WidgetOverlay.partyTarget1, self.WidgetOverlay.partyTarget1, "partyTargetIndicators", nil, true, "partyOnArena")
    self.parent:SetupDrag(self.WidgetOverlay.partyTarget2, self.WidgetOverlay.partyTarget1, "partyTargetIndicators", nil, true, "partyOnArena")
    self.parent:SetupDrag(self.WidgetOverlay.partyTarget3, self.WidgetOverlay.partyTarget1, "partyTargetIndicators", nil, true, "partyOnArena")
end

function sArenaFrameMixin:OnEnter()
    if not isMidnight then
        UnitFrame_OnEnter(self)
    end

    self.HealthText:Show()
    self.PowerText:Show()
end

function sArenaFrameMixin:OnLeave()
    UnitFrame_OnLeave(self)

    self:UpdateStatusTextVisible()
end

function sArenaMixin:IsWaitingForMatch()
    if isMidnight then
        local state = C_PvP.GetActiveMatchState()
        return state ~= state == Enum.PvPMatchState.Engaged
    else
        local inPreparation = C_UnitAuras.GetPlayerAuraBySpellID(32727)
        return inPreparation
    end
end

function sArenaMixin:GetNumArenaOpponentsFallback()
    local count = 0
    for i = 1, self.maxArenaOpponents do
        if UnitExists("arena" .. i) or (noEarlyFrames and self.seenArenaUnits[i]) then
            count = count + 1
        end
    end

    -- TBC: Use party size as fallback, but only after the match has started or we're not in the starting room
    if noEarlyFrames and count < GetNumGroupMembers() then
        local inPreparation = C_UnitAuras.GetPlayerAuraBySpellID(32727)
        if not inPreparation and not self.justEnteredArena and self.arenaMatchStarted then
            count = GetNumGroupMembers() or count
        end
    end

    return count
end

function sArenaFrameMixin:UpdateVisible()
    if InCombatLockdown() then
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    local _, instanceType = IsInInstance()
    if instanceType ~= "arena" then
        self:Hide()
        return
    end

    local id = self:GetID()
    local numSpecs = GetNumArenaOpponentSpecs()
    local numOpponents = (numSpecs == 0) and self.parent:GetNumArenaOpponentsFallback() or numSpecs

    if numOpponents >= id or (noEarlyFrames and self.parent.seenArenaUnits[id]) then
        self:Show()
    else
        self:Hide()
    end
end


function sArenaFrameMixin:UpdateNameColor()
    local class = self.class or self.tempClass
    if not class then return end

    local db = self.parent.db.profile
    local color = RAID_CLASS_COLORS[class]

    if db.colorNameEnabled and db.colorNameColor then
        if not self.oldNameColor then
            local r, g, b, a = self.Name:GetTextColor()
            self.oldNameColor = {r, g, b, a}
        end
        self.Name:SetTextColor(db.colorNameColor.r, db.colorNameColor.g, db.colorNameColor.b, 1)
    elseif db.classColorNames and color then
        if not self.oldNameColor then
            local r, g, b, a = self.Name:GetTextColor()
            self.oldNameColor = {r, g, b, a}
        end
        self.Name:SetTextColor(color.r, color.g, color.b, 1)
    else
        if self.oldNameColor then
            self.Name:SetTextColor(unpack(self.oldNameColor))
            self.oldNameColor = nil
        end
    end
end

function sArenaFrameMixin:UpdateSpecNameColor()
    if not self.SpecNameText then return end

    local class = self.class or self.tempClass
    if not class then return end

    local db = self.parent.db.profile
    local color = RAID_CLASS_COLORS[class]

    if db.colorSpecNameEnabled and db.colorSpecNameColor then
        if not self.oldSpecNameColor then
            local r, g, b, a = self.SpecNameText:GetTextColor()
            self.oldSpecNameColor = {r, g, b, a}
        end
        self.SpecNameText:SetTextColor(db.colorSpecNameColor.r, db.colorSpecNameColor.g, db.colorSpecNameColor.b, 1)
    elseif db.classColorSpecNames and color then
        if not self.oldSpecNameColor then
            local r, g, b, a = self.SpecNameText:GetTextColor()
            self.oldSpecNameColor = {r, g, b, a}
        end
        self.SpecNameText:SetTextColor(color.r, color.g, color.b, 1)
    else
        if self.oldSpecNameColor then
            self.SpecNameText:SetTextColor(unpack(self.oldSpecNameColor))
            self.oldSpecNameColor = nil
        end
    end
end

function sArenaFrameMixin:UpdatePlayer(unitEvent)
    local unit = self.unit

    if noEarlyFrames and UnitExists(unit) then
        self.parent.seenArenaUnits[self:GetID()] = true
    end

    self:GetClass()

    if db and db.profile.disableAurasOnClassIcon then
        self:UpdateClassIcon()
    else
        self:FindAura()
    end

    if (unitEvent and unitEvent ~= "seen") or (UnitGUID(self.unit) == nil) then
        self:SetMysteryPlayer()
        return
    end
    self:StopStealthHealthTicker()
    C_PvP.RequestCrowdControlSpell(unit)

    self:UpdateRacial()
    if not isMidnight then
        self:UpdateDispel()
    end
    self.WidgetOverlay:Show()
    self:UpdateCombatStatus(unit)
    self:UpdateArenaTargets(unit)
    self:UpdateTarget(unit)
    self:UpdateFocus(unit)

    -- Prevent castbar and other frames from intercepting mouse clicks during a match
    if (unitEvent == "seen") then
        self.parent:SetMouseState(false)
    end

    self.hideStatusText = false

    if (db.profile.showNames) then
        self.Name:SetText(UnitFullName(unit))
        self.Name:SetShown(true)
        self:UpdateNameColor()
    elseif (db.profile.showArenaNumber) then
        local id = self.unit:match("%d+")
        if FrameSortApi then
            id = FrameSortApi.v3.Frame:FrameNumberForUnit(self.unit) or id
        end
        if db.profile.arenaNumberIdOnly then
            self.Name:SetText(id)
        else
            self.Name:SetText("Arena " .. id)
        end
        self.Name:SetShown(true)
        self:UpdateNameColor()
    end
    self.SpecNameText:SetText(self.specName or "")
    self:UpdateSpecNameColor()

    self:UpdateStatusTextVisible()
    self:SetStatusText()

    self:OnEvent("UNIT_MAXHEALTH", unit)
    self:OnEvent("UNIT_HEALTH", unit)
    self:OnEvent("UNIT_MAXPOWER", unit)
    self:OnEvent("UNIT_POWER_UPDATE", unit)
    self:OnEvent("UNIT_DISPLAYPOWER", unit)
    if not isMidnight then
        self:OnEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
    end

    local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]

    if (color and db.profile.classColors) then
        self.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1.0)
    else
        self.HealthBar:SetStatusBarColor(0, 1.0, 0, 1.0)
    end

    if noEarlyFrames and not UnitExists(unit) then
        self:SetAlpha(stealthAlpha)
    else
        self:SetAlpha(1)
    end

    -- Workaround to show frames in older arenas in combat.
    -- Does not actually call Show(), but SetAlpha() on older arenas.
    if noEarlyFrames then
        self:Show()
    end
end

function sArenaFrameMixin:SetMysteryPlayer()
    local hp = self.HealthBar
    local pp = self.PowerBar

    local matchActive = self.parent.engagedInMatch or self.parent.arenaMatchStarted

    if matchActive then
        self:StartStealthHealthTicker()
    else
        hp:SetMinMaxValues(0, 100)
        hp:SetValue(100)
        pp:SetMinMaxValues(0, 100)
        pp:SetValue(100)
    end

    if self.parent.db and self.parent.db.profile.colorMysteryGray then -- TODO: Figure out cleaner fix, why db is nil here.
        hp:SetStatusBarColor(0.5, 0.5, 0.5)
        pp:SetStatusBarColor(0.5, 0.5, 0.5)
    else
        local class = self.class or self.tempClass
        local color = class and RAID_CLASS_COLORS[class]

        if color and self.parent.db and self.parent.db.profile.classColors then
            hp:SetStatusBarColor(color.r, color.g, color.b)
        else
            hp:SetStatusBarColor(0, 1.0, 0)
        end

        local powerType
        if class == "DRUID" then
            local specName = self.specName
            if specName == "Feral" then
                powerType = "ENERGY"
            elseif specName == "Guardian" then
                powerType = "RAGE"
            else
                powerType = "MANA"
            end
        elseif class == "MONK" then
            local specName = self.specName
            if specName == "Mistweaver" then
                powerType = "MANA"
            else
                powerType = "ENERGY"
            end
        else
            powerType = class and self.parent.classPowerType[class] or "MANA"
        end

        local powerColor = PowerBarColor[powerType]
        if powerColor then
            pp:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
        else
            pp:SetStatusBarColor(0, 0, 1.0)
        end
    end

    self:SetAlpha(self.parent.waitingForMatch and 1 or stealthAlpha)
    self.hideStatusText = true
    self:SetStatusText()
    self.WidgetOverlay:Hide()

    self.DeathIcon:Hide()
end

function sArenaFrameMixin:GetClass()
    local _, instanceType = IsInInstance()

    if (instanceType ~= "arena") then
        self.specTexture = nil
        self.class = nil
        self.classLocal = nil
        self.specName = nil
        self.specID = nil
        self.isHealer = nil
        self.SpecIcon:Hide()
        self.SpecNameText:SetText("")
    elseif (not self.class) then
        local id = self:GetID()

        if not noEarlyFrames then
            if (GetNumArenaOpponentSpecs() >= id) then
                local specID = GetArenaOpponentSpec(id) or 0
                if (specID > 0) then
                    local _, specName, _, specTexture, _, class, classLocal = GetSpecializationInfoByID(specID)
                    self.class = class
                    self.classLocal = classLocal
                    self.specID = specID
                    self.specName = specName
                    self.isHealer = self.parent.healerSpecIDs[specID] or false
                    self.SpecNameText:SetText(specName)
                    self.SpecNameText:SetShown(db.profile.layoutSettings[db.profile.currentLayout].showSpecManaText)
                    self:UpdateSpecNameColor()
                    self.specTexture = specTexture
                    self.class = class
                    self:UpdateSpecIcon()
                    self:UpdateFrameColors()
                    self.parent:UpdateTextures()

                    local currentLayout = self.parent.layouts[db.profile.currentLayout]
                    if currentLayout and currentLayout.UpdateHealthbarOrientation then
                        currentLayout:UpdateHealthbarOrientation(self)
                    end
                end
            end
        end

        if (not self.class and (noEarlyFrames or UnitExists(self.unit))) then
            self.classLocal, self.class = UnitClass(self.unit)
        end
    end
end


function sArenaFrameMixin:UpdateClassIcon(continue)
	if isMidnight then
		if self.currentAuraSpellID and self.currentAuraDurationObj then
			self.ClassIcon.Cooldown:SetCooldownFromDurationObject(self.currentAuraDurationObj)
		elseif not self.currentAuraSpellID then
			self.ClassIcon.Cooldown:Clear()
		end
	elseif (self.currentAuraSpellID and self.currentAuraDuration > 0 and self.currentClassIconStartTime ~= self.currentAuraStartTime) then
		self.ClassIcon.Cooldown:SetCooldown(self.currentAuraStartTime, self.currentAuraDuration)
		self.currentClassIconStartTime = self.currentAuraStartTime
	elseif (self.currentAuraDuration == 0) then
		self.ClassIcon.Cooldown:Clear()
		self.currentClassIconStartTime = 0
	end

	local texture = self.currentAuraSpellID and self.currentAuraTexture or self.class and "class" or 134400

	if not isMidnight then -- secret
		if (self.currentClassIconTexture == texture) and not continue then return end
	end

	self.currentClassIconTexture = texture

    local useHealerTexture

    if (texture == "class") then

        if db.profile.replaceHealerIcon and self.isHealer then
            useHealerTexture = true
        end

        if db.profile.hideClassIcon then
            texture = nil
            if self.ClassIconMsq then
                self.ClassIconMsq:Hide()
            end
        elseif db.profile.layoutSettings[db.profile.currentLayout].replaceClassIcon and self.specTexture then
            texture = self.specTexture
            if self.ClassIconMsq then
                self.ClassIconMsq:Show()
            end
        else
            texture = self.parent.classIcons[self.class]
            if self.ClassIconMsq then
                self.ClassIconMsq:Show()
            end
        end

        if useHealerTexture then
            self.ClassIcon.Texture:SetAtlas("UI-LFG-RoleIcon-Healer")
        else
            self.ClassIcon.Texture:SetTexture(texture)
        end

        local cropType = useHealerTexture and "healer" or "class"
        self:SetTextureCrop(self.ClassIcon.Texture, db.profile.layoutSettings[db.profile.currentLayout].cropIcons, cropType)
		return
	end
	self:SetTextureCrop(self.ClassIcon.Texture, db and db.profile.layoutSettings[db.profile.currentLayout].cropIcons, "class")
	self.ClassIcon.Texture:SetTexture(texture)
    if self.ClassIconMsq then
        self.ClassIconMsq:Show()
    end
end

-- Returns the spec icon texture based on arena unit ID (1-5)
function sArenaFrameMixin:UpdateSpecIcon()
    if db.profile.layoutSettings[db.profile.currentLayout].replaceClassIcon then
        self.SpecIcon:Hide()
        if self.SpecIconMsq then
            self.SpecIconMsq:Hide()
        end
    elseif db.profile.layoutSettings[db.profile.currentLayout].hideSpecIcon then
        self.SpecIcon:Hide()
        if self.SpecIconMsq then
            self.SpecIconMsq:Hide()
        end
    else
        self.SpecIcon.Texture:SetTexture(self.specTexture)
        self.SpecIcon:Show()
        if self.SpecIconMsq then
            self.SpecIconMsq:Show()
        end
    end
end

local function ResetStatusBar(f)
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f:SetStatusBarColor(1, 1, 1, 1)
    f:SetScale(1)
end

local function ResetFontString(f)
    f:SetDrawLayer("OVERLAY", 1)
    f:SetJustifyH("CENTER")
    f:SetJustifyV("MIDDLE")
    f:SetTextColor(1, 0.82, 0, 1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)
    f:ClearAllPoints()
    f:Hide()
end

function sArenaFrameMixin:ResetLayout()
    self.currentClassIconTexture = nil
    self.currentClassIconStartTime = 0
    self.oldNameColor = nil
    self.oldSpecNameColor = nil

    ResetTexture(nil, self.ClassIcon.Texture)
    ResetStatusBar(self.HealthBar)
    ResetStatusBar(self.PowerBar)
    ResetStatusBar(self.CastBar)
    self.CastBar:SetHeight(16)

    local ogBg = select(1, self.CastBar:GetRegions())
    if ogBg then
        ogBg:Show()
    end

    if self.CastBar.BorderShield then
        self.CastBar.BorderShield:SetTexture(330124)
    end

    self.ClassIcon:SetFrameStrata("MEDIUM")
    self.ClassIcon:SetFrameLevel(7)
    self.ClassIcon.Cooldown:SetUseCircularEdge(false)
    self.ClassIcon.Cooldown:SetSwipeTexture(1)
    self.AuraStacks:SetPoint("BOTTOMLEFT", self.ClassIcon.Texture, "BOTTOMLEFT", 2, 0)
    self.AuraStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 13, "THICKOUTLINE")
    self.DispelStacks:SetPoint("BOTTOMLEFT", self.Dispel.Texture, "BOTTOMLEFT", 2, 0)
    self.DispelStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 15, "THICKOUTLINE")

    self.ClassIcon.Mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    self.ClassIcon.Texture:RemoveMaskTexture(self.ClassIcon.Mask)
    self.ClassIcon.Texture:SetDrawLayer("BORDER", 1)
    self.ClassIcon.Texture:SetAllPoints(self.ClassIcon)
    self.ClassIcon.Texture:Show()
    self.ClassIcon:SetScale(1)
    if self.frameTexture then
        self.frameTexture:SetDrawLayer("ARTWORK", 2)
        self.frameTexture:SetDesaturated(false)
        self.frameTexture:SetVertexColor(1, 1, 1)
        self.frameTexture:Hide()
    end

    if self.CastBar.Border then
        self.CastBar.Border:SetDesaturated(false)
        self.CastBar.Border:SetVertexColor(1, 1, 1)
    end

    if self.Trinket.Border then
        self.Trinket.Border:SetDesaturated(false)
        self.Trinket.Border:SetVertexColor(1, 1, 1)
        self.Trinket.Border:Hide()
        self.Racial.Border:SetDesaturated(false)
        self.Racial.Border:SetVertexColor(1, 1, 1)
        self.Racial.Border:Hide()
        self.Dispel.Border:SetDesaturated(false)
        self.Dispel.Border:SetVertexColor(1, 1, 1)
        self.Dispel.Border:Hide()
    end

    if self.ClassIcon.Texture.Border then
        self.ClassIcon.Texture.Border:Hide()
    end

    self.ClassIcon.Texture.useModernBorder = nil
    self.Trinket.useModernBorder = nil
    self.Racial.useModernBorder = nil
    self.Dispel.useModernBorder = nil

    if self.SpecIcon.Border then
        self.SpecIcon.Border:SetDesaturated(false)
        self.SpecIcon.Border:SetVertexColor(1, 1, 1)
        self.SpecIcon.Border:SetTexture(nil)
    end

    if self.SpecIcon.Mask then
        self.SpecIcon.Texture:RemoveMaskTexture(self.SpecIcon.Mask)
    end
    self.SpecIcon.Texture:SetTexCoord(0, 1, 0, 1)

    if self.NameBackground then
        self.NameBackground:Hide()
    end

    local cropIcons = db.profile.layoutSettings[db.profile.currentLayout].cropIcons

    local f = self.Trinket
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f.Cooldown:SetUseCircularEdge(false)
    if f.Mask then
        f.Texture:RemoveMaskTexture(f.Mask)
        f.Cooldown:SetSwipeTexture(1)
    end
    self:SetTextureCrop(f.Texture, cropIcons)

    local f = self.Dispel
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f.Cooldown:SetUseCircularEdge(false)
    if f.Mask then
        f.Texture:RemoveMaskTexture(f.Mask)
        f.Cooldown:SetSwipeTexture(1)
    end
    self:SetTextureCrop(f.Texture, cropIcons)

    f = self.ClassIcon.Texture
    self:SetTextureCrop(f, cropIcons)

    f = self.Racial
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f.Cooldown:SetUseCircularEdge(false)
    if f.Mask then
        f.Texture:RemoveMaskTexture(f.Mask)
        f.Cooldown:SetSwipeTexture(1)
    end
    self:SetTextureCrop(f.Texture, cropIcons)

    f = self.SpecIcon
    f:ClearAllPoints()
    f:SetSize(0, 0)
    f:SetScale(1)
    f.Texture:RemoveMaskTexture(f.Mask)
    self:SetTextureCrop(f.Texture, cropIcons)

    f = self.Name
    ResetFontString(f)
    f:SetDrawLayer("ARTWORK", 2)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.SpecNameText
    ResetFontString(f)
    f:SetDrawLayer("OVERLAY", 6)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetScale(1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.HealthText
    ResetFontString(f)
    f:SetDrawLayer("ARTWORK", 2)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetTextColor(1, 1, 1, 1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.PowerText
    ResetFontString(f)
    f:SetDrawLayer("ARTWORK", 2)
    f:SetFontObject("SystemFont_Shadow_Small2")
    f:SetTextColor(1, 1, 1, 1)
    f:SetShadowColor(0, 0, 0, 1)
    f:SetShadowOffset(1, -1)

    f = self.CastBar
    f.Icon:SetTexCoord(0, 1, 0, 1)
    local fontName,s,o = f.Text:GetFont()
    f.Text:SetFont(fontName, s, "THINOUTLINE")

    self.TexturePool:ReleaseAll()
end

function sArenaFrameMixin:SetPowerType(powerType)
    local color = PowerBarColor[powerType]
    if color then
        self.PowerBar:SetStatusBarColor(color.r, color.g, color.b)
    end
end

function sArenaFrameMixin:SetLifeState()
    local unit = self.unit
    local isFeigningDeath = self.class == "HUNTER" and AuraUtil.FindAuraByName(FEIGN_DEATH, unit, "HELPFUL")
    local isDead = UnitIsDeadOrGhost(unit) and not isFeigningDeath

    self.DeathIcon:SetShown(isDead)
    self.hideStatusText = isDead
    if (isDead) then
        self:SetStatusText()
        self.HealthBar:SetValue(0)
        self:UpdateHealPrediction()
        self:UpdateAbsorb()
        self.currentHealth = 0
        self.SpecNameText:SetText("")
        self.WidgetOverlay:Hide()
    elseif isFeigningDeath then
        self.HealthBar:SetAlpha(0.55)
        self.isFeigningDeath = true
    end
end

local function FormatLargeNumbers(value)
    if value >= 1000000 then
        -- For millions, show 1 decimal place (e.g., 1.8M)
        return string.format("%.1f M", value / 1000000)
    elseif value >= 1000 then
        -- For thousands, show no decimals (e.g., 392K)
        return string.format("%d K", value / 1000)
    else
        return tostring(value)
    end
end

function sArenaFrameMixin:SetStatusText(unit)
    if (self.hideStatusText) then
        self.HealthText:SetFontObject("SystemFont_Shadow_Small2")
        self.HealthText:SetText("")
        self.PowerText:SetFontObject("SystemFont_Shadow_Small2")
        self.PowerText:SetText("")
        return
    end

    if self.isFeigningDeath then return end

    if (not unit) then
        unit = self.unit
    end

    local hp = UnitHealth(unit)
    local hpMax = UnitHealthMax(unit)
    local pp = UnitPower(unit)
    local ppMax = UnitPowerMax(unit)

    if (db.profile.statusText.usePercentage) then
        if isMidnight then
            self.HealthText:SetFormattedText("%0.f%%", UnitHealthPercent(unit, nil, CurveConstants.ScaleTo100))
            self.PowerText:SetFormattedText("%0.f%%", UnitPowerPercent(unit, nil, nil, CurveConstants.ScaleTo100))
        else
            -- UnitHealth returns percent on TBC
            if isTBC then
                self.HealthText:SetText(hp .. "%")
                self.PowerText:SetText(pp .. "%")
            else
                local hpPercent = (hpMax > 0) and ceil((hp / hpMax) * 100) or 0
                local ppPercent = (ppMax > 0) and ceil((pp / ppMax) * 100) or 0

                self.HealthText:SetText(hpPercent .. "%")
                self.PowerText:SetText(ppPercent .. "%")
            end
        end
    else
        if db.profile.statusText.formatNumbers then
            if isMidnight then
                self.HealthText:SetText(AbbreviateLargeNumbers(hp))
                self.PowerText:SetText(AbbreviateLargeNumbers(pp))
            else
                self.HealthText:SetText(FormatLargeNumbers(hp))
                self.PowerText:SetText(FormatLargeNumbers(pp))
            end
        else
            self.HealthText:SetText(hp)
            self.PowerText:SetText(pp)
        end
    end
end

function sArenaFrameMixin:UpdateStatusTextVisible()
    self.HealthText:SetShown(db.profile.statusText.alwaysShow)
    self.PowerText:SetShown(db.profile.statusText.alwaysShow)
    self.PowerText:SetAlpha(db.profile.hidePowerText and 0 or 1)
end

function sArenaMixin:CastbarOnEvent(castBar, event)
    local colors = self.castbarColors

    local unitToken = castBar.unit
    local castBarTexture = castBar:GetStatusBarTexture()
    local notInterruptible
    local stoppedCast = castBar.stoppedCast

    if unitToken then
        if castBar.casting then
            notInterruptible = select(8, UnitCastingInfo(unitToken))
        elseif castBar.channeling then
            notInterruptible = select(7, UnitChannelInfo(unitToken))
        end
    end

    if isMidnight then
        if self.modernCastbars then
            if stoppedCast then
                castBarTexture:SetDesaturated(false)
                castBar:SetStatusBarColor(1, 1, 1, 1)
                if castBar.ArenaTargetHighlight then
                    castBar.ArenaTargetHighlight:SetAlpha(0)
                end
                return
            end
            if self.highlightCastsOnMe and castBar.ArenaTargetHighlight and PlayerIsSpellTarget and unitToken then
                if (castBar.casting or castBar.channeling) and castBar.spellID ~= nil then
                    castBar.ArenaTargetHighlight:SetAlphaFromBoolean(PlayerIsSpellTarget(unitToken))
                else
                    castBar.ArenaTargetHighlight:SetAlpha(0)
                end
            end
            if not self.keepDefaultModernTextures then
                local textureToUse = self.castTexture
                -- if castBar.barType == "uninterruptable" and self.castUninterruptibleTexture then
                --     textureToUse = self.castUninterruptibleTexture
                -- end
                if textureToUse then
                    castBar:SetStatusBarTexture(textureToUse)
                end
                if colors.enabled then
                    if self.interruptStatusColorOn and self.interruptReady == false then
                        if notInterruptible ~= nil then
                            castBarTexture:SetVertexColorFromBoolean(
                                notInterruptible,
                                colors.colorUninterruptable,
                                colors.colorInterruptNotReady
                            )
                        else
                            castBarTexture:SetVertexColor(unpack(colors.interruptNotReady))
                        end
                    elseif castBar.casting then
                        if notInterruptible ~= nil then
                            castBarTexture:SetVertexColorFromBoolean(
                                notInterruptible,
                                colors.colorUninterruptable,
                                colors.colorStandard
                            )
                        else
                            castBarTexture:SetVertexColor(unpack(colors.standard))
                        end
                    elseif castBar.channeling then
                        if notInterruptible ~= nil then
                            castBarTexture:SetVertexColorFromBoolean(
                                notInterruptible,
                                colors.colorUninterruptable,
                                colors.colorChannel
                            )
                        else
                            castBarTexture:SetVertexColor(unpack(colors.channel))
                        end
                    else
                        castBar:SetStatusBarColor(unpack(colors.standard))
                    end
                else
                    if self.interruptStatusColorOn and self.interruptReady == false then
                        if notInterruptible ~= nil then
                            castBarTexture:SetVertexColorFromBoolean(
                                notInterruptible,
                                colors.defaultUninterruptable,
                                colors.colorInterruptNotReady
                            )
                        else
                            castBarTexture:SetVertexColor(unpack(colors.interruptNotReady))
                        end
                    elseif castBar.casting then
                        if notInterruptible ~= nil then
                            castBarTexture:SetVertexColorFromBoolean(
                                notInterruptible,
                                colors.defaultUninterruptable,
                                colors.defaultStandard
                            )
                        else
                            castBarTexture:SetVertexColor(unpack(colors.standard))
                        end
                    elseif castBar.channeling then
                        if notInterruptible ~= nil then
                            castBarTexture:SetVertexColorFromBoolean(
                                notInterruptible,
                                colors.defaultUninterruptable,
                                colors.defaultChannel
                            )
                        else
                            castBarTexture:SetVertexColor(unpack(colors.channel))
                        end
                    else
                        castBar:SetStatusBarColor(1.0, 0.7, 0.0, 1)
                    end
                end
                castBar.changedBarColor = true
            elseif colors.enabled then
                -- if self.isMoP then
                --     castBar:SetStatusBarTexture(castBar.barType == "uninterruptable" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                -- end
                if castBarTexture then
                    castBarTexture:SetDesaturated(true)
                end
                if self.interruptStatusColorOn and self.interruptReady == false then
                    if notInterruptible ~= nil then
                        castBarTexture:SetVertexColorFromBoolean(
                            notInterruptible,
                            colors.colorUninterruptable,
                            colors.colorInterruptNotReady
                        )
                    else
                        castBarTexture:SetVertexColor(unpack(colors.interruptNotReady))
                    end
                elseif castBar.casting then
                    if notInterruptible ~= nil then
                        castBarTexture:SetVertexColorFromBoolean(
                            notInterruptible,
                            colors.colorUninterruptable,
                            colors.colorStandard
                        )
                    else
                        castBarTexture:SetVertexColor(unpack(colors.standard))
                    end
                elseif castBar.channeling then
                    if notInterruptible ~= nil then
                        castBarTexture:SetVertexColorFromBoolean(
                            notInterruptible,
                            colors.colorUninterruptable,
                            colors.colorChannel
                        )
                    else
                        castBarTexture:SetVertexColor(unpack(colors.channel))
                    end
                else
                    castBar:SetStatusBarColor(unpack(colors.standard))
                end
                castBar.changedBarColor = true
            elseif self.interruptStatusColorOn and self.interruptReady == false then
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(true)
                end
                castBar:SetStatusBarColor(unpack(colors.interruptNotReady))
                castBar.changedBarColor = true
            elseif castBar.changedBarColor or self.keepDefaultModernTextures then
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(false)
                end
                castBar:SetStatusBarColor(1, 1, 1)
                if isRetail then
                    castBar:SetStatusBarTexture(castBar.channeling and "UI-CastingBar-Filling-Channel" or "ui-castingbar-filling-standard")
                else
                    castBar:SetStatusBarTexture(castBar.channeling and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                end
                castBar.changedBarColor = nil
            end
        else
            local textureToUse = self.castTexture
            -- if castBar.barType == "uninterruptable" and self.castUninterruptibleTexture then
            --     textureToUse = self.castUninterruptibleTexture
            -- end
            castBar:SetStatusBarTexture(textureToUse or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
            if stoppedCast then
                castBarTexture:SetDesaturated(false)
                castBar:SetStatusBarColor(1, 0, 0, 1)
                if castBar.ArenaTargetHighlight then
                    castBar.ArenaTargetHighlight:SetAlpha(0)
                end
                return
            end
            if self.highlightCastsOnMe and castBar.ArenaTargetHighlight and PlayerIsSpellTarget and unitToken then
                if (castBar.casting or castBar.channeling) and castBar.spellID ~= nil then
                    castBar.ArenaTargetHighlight:SetAlphaFromBoolean(PlayerIsSpellTarget(unitToken))
                else
                    castBar.ArenaTargetHighlight:SetAlpha(0)
                end
            end
            if colors.enabled then
                if self.interruptStatusColorOn and self.interruptReady == false then
                    if notInterruptible ~= nil then
                        castBarTexture:SetVertexColorFromBoolean(
                            notInterruptible,
                            colors.colorUninterruptable,
                            colors.colorInterruptNotReady
                        )
                    else
                        castBarTexture:SetVertexColor(unpack(colors.interruptNotReady))
                    end
                elseif castBar.casting then
                    if notInterruptible ~= nil then
                        castBarTexture:SetVertexColorFromBoolean(
                            notInterruptible,
                            colors.colorUninterruptable,
                            colors.colorStandard
                        )
                    else
                        castBarTexture:SetVertexColor(unpack(colors.standard))
                    end
                elseif castBar.channeling then
                    if notInterruptible ~= nil then
                        castBarTexture:SetVertexColorFromBoolean(
                            notInterruptible,
                            colors.colorUninterruptable,
                            colors.colorChannel
                        )
                    else
                        castBarTexture:SetVertexColor(unpack(colors.channel))
                    end
                else
                    castBar:SetStatusBarColor(unpack(colors.standard))
                end
            else
                if self.interruptStatusColorOn and self.interruptReady == false then
                    if notInterruptible ~= nil then
                        castBarTexture:SetVertexColorFromBoolean(
                            notInterruptible,
                            colors.defaultUninterruptable,
                            colors.colorInterruptNotReady
                        )
                    else
                        castBarTexture:SetVertexColor(unpack(colors.interruptNotReady))
                    end
                elseif castBar.casting then
                    if notInterruptible ~= nil then
                        castBarTexture:SetVertexColorFromBoolean(
                            notInterruptible,
                            colors.defaultUninterruptable,
                            colors.defaultStandard
                        )
                    else
                        castBarTexture:SetVertexColor(unpack(colors.standard))
                    end
                elseif castBar.channeling then
                    if notInterruptible ~= nil then
                        castBarTexture:SetVertexColorFromBoolean(
                            notInterruptible,
                            colors.defaultUninterruptable,
                            colors.defaultChannel
                        )
                    else
                        castBarTexture:SetVertexColor(unpack(colors.channel))
                    end
                else
                    castBar:SetStatusBarColor(1.0, 0.7, 0.0, 1)
                end
            end
        end
    else
        if self.modernCastbars then
            if not self.keepDefaultModernTextures then
                local textureToUse = self.castTexture
                if castBar.barType == "uninterruptable" and self.castUninterruptibleTexture then
                    textureToUse = self.castUninterruptibleTexture
                end
                if textureToUse then
                    castBar:SetStatusBarTexture(textureToUse)
                end
                if colors.enabled then
                    if castBar.barType == "uninterruptable" then
                        castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                    elseif self.interruptStatusColorOn and self.interruptReady == false then
                        castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                    elseif castBar.barType == "channel" then
                        castBar:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
                    elseif castBar.barType == "interrupted" then
                        castBar:SetStatusBarColor(1, 0, 0)
                    else
                        castBar:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
                    end
                else
                    if castBar.barType == "uninterruptable" then
                        castBar:SetStatusBarColor(0.7, 0.7, 0.7)
                    elseif self.interruptStatusColorOn and self.interruptReady == false then
                        castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                    elseif castBar.barType == "channel" then
                        castBar:SetStatusBarColor(0, 1, 0)
                    elseif castBar.barType == "interrupted" then
                        castBar:SetStatusBarColor(1, 0, 0)
                    else
                        castBar:SetStatusBarColor(1, 0.7, 0)
                    end
                end
                castBar.changedBarColor = true
            elseif colors.enabled then
                if self.isMoP then
                    castBar:SetStatusBarTexture(castBar.barType == "uninterruptable" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                end
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(true)
                end
                if castBar.barType == "uninterruptable" then
                    castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                elseif self.interruptStatusColorOn and self.interruptReady == false then
                    castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif castBar.barType == "channel" then
                    castBar:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
                elseif castBar.barType == "interrupted" then
                    castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
                end
                castBar.changedBarColor = true
            elseif self.interruptStatusColorOn and self.interruptReady == false and castBar.barType ~= "uninterruptable" then
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(true)
                end
                castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                castBar.changedBarColor = true
            elseif castBar.changedBarColor or self.keepDefaultModernTextures then
                local castTexture = castBar:GetStatusBarTexture()
                if castTexture then
                    castTexture:SetDesaturated(false)
                end
                castBar:SetStatusBarColor(1, 1, 1)
                if isRetail then
                    castBar:SetStatusBarTexture(castBar.barType == "uninterruptable" and "UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "UI-CastingBar-Filling-Channel" or "ui-castingbar-filling-standard")
                else
                    castBar:SetStatusBarTexture(castBar.barType == "uninterruptable" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard")
                end
                castBar.changedBarColor = nil
            end
        else
            local textureToUse = self.castTexture
            if castBar.barType == "uninterruptable" and self.castUninterruptibleTexture then
                textureToUse = self.castUninterruptibleTexture
            end
            castBar:SetStatusBarTexture(textureToUse or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
            if colors.enabled then
                if castBar.barType == "uninterruptable" then
                    castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                elseif self.interruptStatusColorOn and self.interruptReady == false then
                    castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif castBar.barType == "channel" then
                    castBar:SetStatusBarColor(unpack(colors.channel or { 0.0, 1.0, 0.0, 1 }))
                elseif castBar.barType == "interrupted" then
                    castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(unpack(colors.standard or { 1.0, 0.7, 0.0, 1 }))
                end
            else
                if castBar.barType == "uninterruptable" then
                    castBar:SetStatusBarColor(0.7, 0.7, 0.7)
                elseif self.interruptStatusColorOn and self.interruptReady == false then
                    castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif castBar.barType == "channel" then
                    castBar:SetStatusBarColor(0, 1, 0)
                elseif castBar.barType == "interrupted" then
                    castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(1, 0.7, 0)
                end
            end
        end
    end
end
