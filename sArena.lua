local isRetail = sArenaMixin.isRetail
local isMidnight = sArenaMixin.isMidnight
local isTBC = sArenaMixin.isTBC
local isMoP = sArenaMixin.isMoP
local L = sArenaMixin.L

-- Older clients dont show opponents in spawn
local noEarlyFrames = sArenaMixin.noEarlyFrames

local LSM = LibStub("LibSharedMedia-3.0")
LSM:Register("statusbar", "Blizzard RetailBar", [[Interface\AddOns\sArena_Reloaded\Textures\BlizzardRetailBar]])
LSM:Register("statusbar", "sArena Default", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaDefault]])
LSM:Register("statusbar", "sArena Stripes", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaHealer]])
LSM:Register("statusbar", "sArena Stripes 2", [[Interface\AddOns\sArena_Reloaded\Textures\sArenaRetailHealer]])
LSM:Register("statusbar", "Minimalist", [[Interface\AddOns\sArena_Reloaded\Textures\Minimalist]])
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

function sArenaMixin:IsInArena()
    local _, instanceType = IsInInstance()
    return instanceType == "arena"
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
    ["DEATHKNIGHT"] = isTBC and 136119 or 135771,
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

local MAX_INCOMING_HEAL_OVERFLOW = 1
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

function sArenaMixin:UpdatePreGatesFrames()
    if not db then return end
    if self.engagedInMatch or self.arenaMatchStarted then return end

    local partySize = GetNumGroupMembers()
    for i = 1, partySize do
        local frame = self["arena" .. i]
        frame:SetPreGatesUnknownPlayer()
    end
end

function sArenaMixin:HandleArenaStart()
    self.arenaMatchStarted = true
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not frame:IsShown() and UnitExists("arena"..i) then
            if noEarlyFrames then
                self.seenArenaUnits[i] = true
            end
            frame:UpdateVisible()
            frame:UpdatePlayer("seen")
            frame.PetFrame:UpdatePet("seen")
        end
    end
    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]
        if not UnitIsVisible("arena"..i) then
            frame:SetAlpha(self.stealthAlpha)
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
        self:RegisterEvent("ARENA_OPPONENT_UPDATE")
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
                        local unit = "arena" .. i
                        if (sourceGUID == UnitGUID(unit)) then
                            local ArenaFrame = self[unit]
                            if ArenaFrame:CheckForSpecSpell(spellID) then
                                break
                            end
                        end
                    end
                end
            end

            -- Shadowsight
            if spellID == self.shadowSightID and db.profile.shadowSightTimer and not IsSoloShuffle() then
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
                    local unit = "arena" .. i
                    if (sourceGUID == UnitGUID(unit)) then
                        local ArenaFrame = self[unit]
                        ArenaFrame:FindRacial(spellID)
                    end
                end
            end

            -- Trinket (Event doesnt trigger on MoP sometimes because yes)
            if spellID == self.trinketID and self.useHardcodedTrinketDuration then
                for i = 1, self.maxArenaOpponents do
                    local unit = "arena" .. i
                    if (sourceGUID == UnitGUID(unit)) then
                        local ArenaFrame = self[unit]
                        --ArenaFrame:UpdateTrinket()
                        ArenaFrame:FindTrinket()
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
                    local unit = "arena" .. i
                    local ArenaFrame = self[unit]

                    local arenaGUID = UnitGUID(unit)
                    local petGUID = UnitGUID(unit .. "pet")

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
                local unit = "arena" .. i
                if ( destGUID == UnitGUID(unit) and (auraType == "DEBUFF") ) then
                    local ArenaFrame = self[unit]
                    ArenaFrame:FindDR(combatEvent, spellID)
                    break
                end
            end
        end

        -- Interrupts
        if self.interruptList[spellID] then
            if combatEvent == "SPELL_INTERRUPT" or combatEvent == "SPELL_CAST_SUCCESS" then
                for i = 1, self.maxArenaOpponents do
                    local unit = "arena" .. i
                    if (destGUID == UnitGUID(unit)) then
                        local ArenaFrame = self[unit]
                        ArenaFrame:FindInterrupt(combatEvent, spellID, sourceName, sourceGUID)
                        break
                    end
                end
            end
        end

    elseif (event == "PLAYER_TARGET_CHANGED") then
        for i = 1, self.maxArenaOpponents do
            local unit = "arena" .. i
            local frame = self[unit]
            frame:UpdateTarget(frame.unit)
        end

    elseif (event == "PLAYER_FOCUS_CHANGED") then
        for i = 1, self.maxArenaOpponents do
            local unit = "arena" .. i
            local frame = self[unit]
            frame:UpdateFocus(frame.unit)
        end

    elseif (event == "UNIT_TARGET") then
        for i = 1, self.maxArenaOpponents do
            local unit = "arena" .. i
            local frame = self[unit]
            frame:UpdateArenaTargets(frame.unit)
            frame:UpdateArenaTargetText(frame.unit)
        end
        self:UpdateArenaTargetsOnPartyFrames()
        self:UpdateArenaTargetTextOnPartyFrames()

    elseif (event == "PLAYER_LOGIN") then
        if isMidnight then
            C_CVar.SetCVar("spellDiminishPVPEnemiesEnabled", "1")
            self:EnsureArenaFramesEnabled()
            self:RegisterCVarListener()
            self:GladTracker()
        end
        self:Initialize()
        if self:ConflictCheck() then return end
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
        self:UpdatePartyFrameReferences(true)
        self:UpdateBlizzArenaFrameVisibility()
        self:SetMouseState(not self:IsInArena())
        self.testMode = nil
        self.arenaMatchStarted = nil
        self:RefreshAllAuraHighlights()

        if noEarlyFrames then
            self.seenArenaUnits = {}
            if self:IsInArena() then
                self.justEnteredArena = true
                C_Timer.After(6, function()
                    self.justEnteredArena = nil
                end)
                self:UpdatePreGatesFrames()
            else
                self.justEnteredArena = nil
            end
        end

        if isMidnight then
            self:InitializeMidnightDRFrames()
        end
        self:CheckMatchStatus(event)

        self:SetupCustomCD()
        self:UpdateArenaTargetsOnPartyFrames()
        self:PositionArenaTargetTextOnPartyFrames()
        self:UpdateArenaTargetTextOnPartyFrames()

        if self:IsInArena() then
            self:PrintConflictMessage()
            if not isMidnight then
                self:ResetDetectedDispels()
                if isTBC then
                    wipe(self.activeStanceAuras)
                end
                self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
            end
            if noEarlyFrames then
                self:RegisterEvent("GROUP_ROSTER_UPDATE")
            end
            self:RegisterWidgetEvents()
            self:RegisterInterruptEvents()
            self:RegisterRangeCheckEvents()
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
            if noEarlyFrames then
                self:UnregisterEvent("GROUP_ROSTER_UPDATE")
            end
            self:UnregisterWidgetEvents()
            self:UnregisterInterruptEvents()
            self:UnregisterRangeCheckEvents()
            self:ResetShadowsightTimer()
        end
    elseif event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        local msg = ...
        if IsMatchStartedMessage(msg) then
            C_Timer.After(0.5, function()
                self:HandleArenaStart()
            end)
            if db and db.profile.shadowSightTimer and not IsSoloShuffle() then
                self:StartShadowsightTimer(self.shadowsightStartTime)
            end
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdatePlayerSpec()
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        self:CheckMatchStatus(event)
        self:ResetDetectedDispels()
        if isTBC then
            wipe(self.activeStanceAuras)
        end
    elseif event == "ARENA_OPPONENT_UPDATE" then
        self:CheckMatchStatus(event)
        self:UnregisterEvent(event)
    elseif event == "GROUP_ROSTER_UPDATE" then
        self:UpdatePreGatesFrames()
    elseif event == "PVP_MATCH_STATE_CHANGED" or event == "PVP_MATCH_ACTIVE" then
        self:CheckMatchStatus(event)
        if self:IsInArena() then
            if db and db.profile.shadowSightTimer and self.engagedInMatch and not IsSoloShuffle() then
                self:StartShadowsightTimer(self.shadowsightStartTime)
            end
        else
            self:ResetShadowsightTimer()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        if self.pendingClickActions then
            self:ApplyAllClickActions()
        end
        if self.pendingMouseState ~= nil then
            local pendingState = self.pendingMouseState
            self.pendingMouseState = nil
            self:SetMouseState(pendingState)
        end
    end
end

function sArenaMixin:HandleFirstUse()
    if sArena_ReloadedDB and sArena_ReloadedDB.isFirstUse then
        sArena_ReloadedDB.isFirstUse = nil
        LibStub("AceConfigDialog-3.0"):Close("sArena")
        if SettingsPanel and SettingsPanel:IsShown() then
            SettingsPanel:Hide()
        end
        self:ShowWelcomePopup()
        self:Test()
    end
end

function sArenaMixin:ChatCommand(input)
    if sArena_ReloadedDB.isFirstUse then
        self:HandleFirstUse()
        return
    end
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
            self:UpdatePlayerRangeSpell()
            self:UpdateShadowWordDeathInterrupt()
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

    local conflictType = self:ConflictCheck()

    self.isFirstUse = (sArena_ReloadedDB == nil)

    self.db = LibStub("AceDB-3.0"):New("sArena_ReloadedDB", self.defaultSettings, true)
    db = self.db

    if self.isFirstUse then
        sArena_ReloadedDB.isFirstUse = true
    end

    self:CleanupStaleProfilePreview()

    db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    self.optionsTable.handler = self
    self.optionsTable.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("sArena", self.optionsTable)
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("sArena", conflictType and 520 or 860, conflictType and 300 or 690)
    LibStub("AceConsole-3.0"):RegisterChatCommand("sarena", function(input) self:ChatCommand(input) end)
    if not conflictType then
        self:InterruptTracker()
        self:DatabaseCleanup(db)
        if isMidnight then
            self:UpdateAuraSortSettings()
        end
        self:UpdateDRTimeSetting()
        self:UpdateDecimalThreshold()
        self:UpdateNoTrinketTexture()
        self:UpdateStealthAlpha()
        self:ApplyAllClickActions()
        self:RebuildClickActionsOptions()
        self:CreateRangeCheckFrames()
        local optionsPanel = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("sArena", "sArena |cffff8000Reloaded|r |T135884:13:13|t")
        if optionsPanel and sArena_ReloadedDB.isFirstUse then
            optionsPanel:HookScript("OnShow", function()
                self:HandleFirstUse()
            end)
        end
        self:SetLayout(_, db.profile.currentLayout)
    else
        self:PrintConflictMessage(conflictType)
    end
end

function sArenaMixin:RefreshConfig()
    self:RebuildClickActionsOptions()
    self:SetLayout(_, db.profile.currentLayout)
end

function sArenaMixin:PreviewLayout(layout)
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
        frame:CreateAuraHighlight()
        frame:UpdateAuraHighlightLayout()
        frame:RefreshAuraHighlight()

        if frame.SetupAuraDisplay then
            frame:SetupAuraDisplay()
        end

        frame:UpdatePlayer(UnitExists(frame.unit) and "seen" or "unseen")
        frame:UpdateClassIconCooldownReverse()
        frame:UpdateTrinketRacialCooldownReverse()
        frame:UpdateClassIconSwipeSettings()
        frame:UpdateTrinketRacialSwipeSettings()
        frame:UpdateFrameColors()
        frame:UpdateNameColor()
        frame:UpdateSpecNameColor()
        frame.PetFrame:Setup()
        frame.PetFrame:UpdateSettings()
    end

    self:RegisterPetFrameEvents()
    self:CreateCastbarHighlight()
    self:CreateCastbarTargetText()
    self:UpdateCastbarTargetText()
    self:ModernOrClassicCastbar()
    self:UpdateCastBarSettings(self.layoutdb.castBar)
    self:CreateCastbarIDText()
    self:UpdateCastbarIDText()
    self:UpdateFonts()

    for i = 1, self.maxArenaOpponents do
        self["arena" .. i]:ApplyPrototypeFont()
    end

    self:UpdateCDTextVisibility()
    self:UpdateCastbarVisibility()
    self:ApplyAllClickActions()
    self:UpdateCooldownSwipeColor()

    local _, instanceType = IsInInstance()
    if (instanceType ~= "arena" and self.arena1:IsShown()) then
        self:Test()
    end
end

function sArenaMixin:SetLayout(_, layout)
    if (InCombatLockdown()) then return end

    layout = self.layouts[layout] and layout or "Gladiuish"

    -- Detect if this is a user-initiated layout change (not from addon load)
    local oldLayout = db and db.profile and db.profile.currentLayout
    local isUserChange = oldLayout ~= nil and oldLayout ~= layout

    -- Handle BlizzRaid layout onlyShowAuras setting
    if isUserChange then
        if layout == "BlizzRaid" then
            -- Store the previous onlyShowAuras value before changing to BlizzRaid
            if not db.profile.onlyShowAurasBeforeBlizzRaid then
                db.profile.onlyShowAurasBeforeBlizzRaid = db.profile.onlyShowAuras
            end
            db.profile.onlyShowAuras = true
        elseif oldLayout == "BlizzRaid" then
            -- Restore the previous onlyShowAuras value when leaving BlizzRaid
            if db.profile.onlyShowAurasBeforeBlizzRaid ~= nil then
                db.profile.onlyShowAuras = db.profile.onlyShowAurasBeforeBlizzRaid
                db.profile.onlyShowAurasBeforeBlizzRaid = nil
            else
                db.profile.onlyShowAuras = false
            end
        end
    end

    self:PreviewLayout(layout)

    self.optionsTable.args.layoutSettingsGroup.args = self.layouts[layout].optionsTable and self.layouts[layout].optionsTable or emptyLayoutOptionsTable
    LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
end

function sArenaMixin:SetupDrag(frameToClick, frameToMove, settingsTable, updateMethod, dragType, subKey, textContext)
    local db = self.db
    local onDragUpdate

    if textContext == true then
        -- Arena frame text widget: frameToClick is the arena frame mixin
        local arenaFrame = frameToClick
        arenaFrame:CreateArenaTargetText()
        frameToClick = arenaFrame.WidgetOverlay.arenaTargetTextFrame
        frameToMove = frameToClick
        onDragUpdate = function(moveFrame)
            local fs = arenaFrame.WidgetOverlay.arenaTargetText
            if not fs or not moveFrame.isMoving then return end
            local db = arenaFrame.parent.db
            local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
            local ptt = widgetSettings and widgetSettings.partyTargetText
            local poa = ptt and ptt.partyOnArena
            if not poa then return end
            local anchorMap = { LEFT = "TOPLEFT", CENTER = "TOP", RIGHT = "TOPRIGHT" }
            local anchor = anchorMap[poa.anchor] or "TOPRIGHT"
            local newX, newY = moveFrame:GetCenter()
            local deltaX = newX - (moveFrame.dragStartX or newX)
            local deltaY = newY - (moveFrame.dragStartY or newY)
            fs:ClearAllPoints()
            fs:SetPoint(anchor, arenaFrame.HealthBar, anchor, (poa.posX or 0) + deltaX, (poa.posY or 0) + deltaY)
        end
    elseif textContext then
        -- Party frame text widget: textContext is the partyFrame
        local partyFrame = textContext
        self:CreatePartyFrameTargetText(partyFrame)
        frameToClick = partyFrame.WidgetOverlay.partyTargetTextFrame
        frameToMove = frameToClick
        frameToMove.useCursorDelta = true
        frameToMove.suppressTextOnDrop = true
        local ov = partyFrame.WidgetOverlay
        onDragUpdate = function(moveFrame)
            local fs = ov.partyTargetText
            if not fs or not moveFrame.isMoving then return end
            local db = self.db
            local widgetSettings = db and db.profile.layoutSettings[db.profile.currentLayout].widgets
            local ptt = widgetSettings and widgetSettings.partyTargetText
            local aop = ptt and ptt.arenaOnParty
            if not aop then return end
            local anchorMap = { LEFT = "TOPLEFT", CENTER = "TOP", RIGHT = "TOPRIGHT" }
            local anchor = anchorMap[aop.anchor] or "TOPRIGHT"
            local curX, curY = GetCursorPosition()
            local uiScale = UIParent:GetEffectiveScale()
            local deltaX = (curX - (moveFrame.dragStartCursorX or curX)) / uiScale
            local deltaY = (curY - (moveFrame.dragStartCursorY or curY)) / uiScale
            fs:ClearAllPoints()
            fs:SetPoint(anchor, ov, anchor, (aop.posX or 0) + deltaX, (aop.posY or 0) + deltaY)
        end
    end

    if frameToClick.dragSetup then return end

    frameToClick:HookScript("OnMouseDown", function()
        if (InCombatLockdown()) then return end

        if (IsShiftKeyDown() and IsControlKeyDown() and not frameToMove.isMoving) then
            if dragType then
                if frameToMove.useCursorDelta then
                    frameToMove.dragStartCursorX, frameToMove.dragStartCursorY = GetCursorPosition()
                else
                    frameToMove.dragStartX, frameToMove.dragStartY = frameToMove:GetCenter()
                end
            end
            self:HideTargetFocusBorderForDrag(frameToMove, dragType ~= nil)
            frameToMove:StartMoving()
            frameToMove.isMoving = true
            if onDragUpdate then
                frameToMove:SetScript("OnUpdate", onDragUpdate)
            end
        end
    end)

    frameToClick:HookScript("OnMouseUp", function()
        if (InCombatLockdown()) then return end

        if (frameToMove.isMoving) then
            if onDragUpdate then
                frameToMove:SetScript("OnUpdate", nil)
            end
            frameToMove:StopMovingOrSizing()
            frameToMove.isMoving = false

            local settings

            if dragType == "global" then
                if not db.profile[settingsTable] then
                    db.profile[settingsTable] = {}
                end
                settings = db.profile[settingsTable]
            elseif dragType == "petBar" then
                settings = db.profile.layoutSettings[db.profile.currentLayout]
                if not settings then
                    self:RestoreTargetFocusBorderAfterDrag(frameToMove, true)
                    return
                end
                settings.petFrames = settings.petFrames or {}
                settings = settings.petFrames
            elseif dragType == "widget" then
                settings = db.profile.layoutSettings[db.profile.currentLayout].widgets
                if not settings then
                    self:RestoreTargetFocusBorderAfterDrag(frameToMove, true)
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

            if dragType then
                local deltaX, deltaY
                if frameToMove.useCursorDelta then
                    local curX, curY = GetCursorPosition()
                    local uiScale = UIParent:GetEffectiveScale()
                    deltaX = (curX - (frameToMove.dragStartCursorX or curX)) / uiScale
                    deltaY = (curY - (frameToMove.dragStartCursorY or curY)) / uiScale
                    frameToMove.dragStartCursorX = nil
                    frameToMove.dragStartCursorY = nil
                else
                    local newX, newY = frameToMove:GetCenter()
                    local scale = frameToMove:GetScale()
                    deltaX = ((newX - frameToMove.dragStartX) * scale) / scale
                    deltaY = ((newY - frameToMove.dragStartY) * scale) / scale
                    frameToMove.dragStartX = nil
                    frameToMove.dragStartY = nil
                end

                if dragType == "widget" then
                    local currentX = settings.posX or 0
                    local currentY = settings.posY or 0
                    settings.posX = floor((currentX + deltaX) * 10 + 0.5) / 10
                    settings.posY = floor((currentY + deltaY) * 10 + 0.5) / 10
                    local widgetsSettings = db.profile.layoutSettings[db.profile.currentLayout].widgets
                    if frameToMove.suppressTextOnDrop then self.suppressPartyTextUpdate = true end
                    self:UpdateWidgetSettings(widgetsSettings)
                    self.suppressPartyTextUpdate = nil
                elseif dragType == "petBar" then
                    local currentX = settings.posX or 0
                    local currentY = settings.posY or 0
                    settings.posX = floor((currentX + deltaX) * 10 + 0.5) / 10
                    settings.posY = floor((currentY + deltaY) * 10 + 0.5) / 10
                    self:RefreshPetFrameSettings()
                elseif dragType == "global" then
                    local posXKey = subKey and (subKey .. "PosX") or "posX"
                    local posYKey = subKey and (subKey .. "PosY") or "posY"
                    local currentX = settings[posXKey] or 0
                    local currentY = settings[posYKey] or 0
                    settings[posXKey] = floor((currentX + deltaX) * 10 + 0.5) / 10
                    settings[posYKey] = floor((currentY + deltaY) * 10 + 0.5) / 10
                    self:ApplyRangeCheckTextures()
                end
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

            self:RestoreTargetFocusBorderAfterDrag(frameToMove, dragType ~= nil)
            LibStub("AceConfigRegistry-3.0"):NotifyChange("sArena")
        end
    end)
    frameToClick.dragSetup = true
end

function sArenaMixin:SetMouseState(state)
    local clickthroughEnabled = db and db.profile.clickthroughFrames
    local needsFrameMouseUpdate = noEarlyFrames or clickthroughEnabled

    if needsFrameMouseUpdate and InCombatLockdown() then
        self.pendingMouseState = state
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
    end

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        if frame.midnightCastBarMoveFrame then
            frame.midnightCastBarMoveFrame:EnableMouse(state)
        end

        local useDrFrames = frame.drFrames ~= nil
        local drList = frame.drFrames or self.drCategories
        if drList then
            local mouseState = useDrFrames and false or state
            for j = 1, #drList do
                local drFrame = useDrFrames and drList[j] or frame[drList[j]]
                if drFrame then
                    drFrame:EnableMouse(mouseState)
                end
            end
        end

        frame.CastBar:EnableMouse(state)
        frame.SpecIcon:EnableMouse(state)
        frame.Trinket:EnableMouse(state)
        frame.Racial:EnableMouse(state)
        frame.Dispel:EnableMouse(state)
        frame.ClassIcon:EnableMouse(state)

        for _, child in pairs({frame.WidgetOverlay:GetChildren()}) do
            child:EnableMouse(state)
        end

        for _, child in pairs({frame.PetFrame.WidgetOverlay:GetChildren()}) do
            child:EnableMouse(state)
        end

        if needsFrameMouseUpdate and not InCombatLockdown() then
            local shouldEnableMouse
            if state then
                -- Outside arena: always clickable
                shouldEnableMouse = true
            elseif clickthroughEnabled then
                -- Clickthrough mode: disable all frames in arena
                shouldEnableMouse = false
            else
                -- noEarlyFrames: only clickable up to party size
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
    if self.parent:ConflictCheck() then return end

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
        if CastingBarFrame_SetUnit then
            CastingBarFrame_SetUnit(self.CastBar, unit, false, true)
        else
            self.CastBar.empoweredFix = true
            self.CastBar:SetUnit(unit, false, true)
            self.CastBar.Spark:SetWidth(4)
        end
    else
        local blizzArenaFrame = _G["CompactArenaFrameMember" .. self:GetID()]
        self:HookPlayerConnectionStatus()
        self.CastBar = blizzArenaFrame.CastingBarFrame
        self.CastBar:SetFrameStrata("HIGH")
        self.totalAbsorbBar:Hide()
        self.overHealAbsorbGlow:Hide()
        self.otherHealPredictionBar:Hide()
        self.totalAbsorbBarOverlay:Hide()
        self.myHealPredictionBar:Hide()
        self.overAbsorbGlow:SetWidth(13)

        self:NormalEmpoweredCastbar()
        self:HookMidnightTrinket()
        self:CreateOvershieldBar()
        self:CreateAbsorbBar()
    end

    self:RegisterForClicks("AnyDown", "AnyUp")
    self:SetAttribute("unit", unit)
    self:SetAttribute("*type1", "target")
    self:SetAttribute("*type2", "focus")
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
        if CastStopEvents[event] then
            if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
                castBar.stoppedCast = true
                if isMidnight and interruptedByOrCastBarID ~= nil then
                    castBar.wasKicked = true
                end
            end
            if not (castBar.interruptedBy or castBar.wasKicked) then
                local cast = UnitCastingInfo(unit) or UnitChannelInfo(unit)
                if not cast then
                    castBar:Hide()
                    if sArenaDebug then
                        print("CBE: Hiding Castbar")
                    end
                end
            end
        elseif CastStartEvents[event] then
            castBar.wasKicked = nil
            castBar.stoppedCast = nil
        end

        self.parent:CastbarOnEvent(self.CastBar, event, interruptedByOrCastBarID)
        self.parent:UpdateCastbarTargetOnEvent(self.CastBar, event)

        if sArenaDebug then
            print("CBE: ", event, eventUnit, spellID, interruptedByOrCastBarID, castBar.interruptedBy, castBar.wasKicked)
        end
    end)

    hooksecurefunc(self.CastBar.BorderShield, "SetShown", function()
        self.parent:CastbarOnEvent(self.CastBar)
    end)

    if self.CastBar.PlayFinishAnim then
        hooksecurefunc(self.CastBar, "PlayFinishAnim", function(castBar)
            if not (castBar.interruptedBy or castBar.wasKicked) then
                local cast = UnitCastingInfo(unit) or UnitChannelInfo(unit)
                if not cast then
                    castBar:Hide()
                    if sArenaDebug then
                        print("CBE: Hiding Castbar2")
                    end
                end
            end
            if not castBar.activeTexture then return end
            self.parent:CastbarOnEvent(castBar)
        end)
    end

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
    self.WidgetOverlay.healerIndicator.Texture:SetAtlas("bags-icon-addslots")
    for i = 1, 4 do
        local pt = self.WidgetOverlay["partyTarget" .. i]
        pt.Texture:SetTexture("Interface\\AddOns\\sArena_Reloaded\\Textures\\GM-icon-headCount.tga")
        pt.Texture:SetDesaturated(true)
    end
    self.Trinket:SetFrameLevel(7)

    self.DispelStacks:SetParent(self.Dispel.Overlay)

    self.TexturePool = CreateTexturePool(self, "ARTWORK", nil, nil, ResetTexture)

    self:SetupTrinketCooldownDone()
end

function sArenaFrameMixin:OnEvent(event, eventUnit, arg1)
    local unit = self.unit

    -- No wonder this didnt work when eventUnit is nil.
    -- Do it for TBC only atm since thats the only version that needs it right now and others need more testing.
    if event == "ARENA_COOLDOWNS_UPDATE" and isTBC then
        self:UpdateTrinket()
    end

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
                        if not isRetail and not isTBC and self.race == "Human" and db.profile.forceShowTrinketOnHuman then
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

                    if not isRetail and not isTBC and self.race == "Human" and db.profile.forceShowTrinketOnHuman then
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
            if not isMidnight then
                self:FindAura(arg1)
            end
        elseif (event == "UNIT_HEALTH") then
            if isMidnight then
                local isDead = UnitIsDeadOrGhost(unit)
                self.hideStatusText = isDead
                self.isDead = isDead
                self.HealthBar:SetValue(UnitHealth(unit))
                self:UpdateAbsorb()
                if (isDead) then
                    --self.HealthBar:SetValue(0)
                    self.WidgetOverlay:Hide()
                else
                    if not self.WidgetOverlay:IsShown() then
                        self.WidgetOverlay:Show()
                    end
                end
                self.DeathIcon:SetShown(self.isDead)
                self.DisconnectedIcon:SetShown(not UnitIsConnected(unit))
                self:SetStatusText()
            else
                local currentHealth = UnitHealth(unit)
                if currentHealth ~= 0 then
                    self.isDead = UnitIsDeadOrGhost(unit) -- (Released Spirit might show as 1hp, need to confirm)
                    self:SetStatusText()
                    self.HealthBar:SetValue(currentHealth)
                    self:UpdateHealPrediction()
                    self:UpdateAbsorb()
                    self.DeathIcon:SetShown(self.isDead)
                    self.DisconnectedIcon:SetShown(not UnitIsConnected(unit))
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
        if noEarlyFrames and self.parent:IsInArena() and self.ogShow then
            self.ogShow(self)
            self:SetAlpha(0)
        end

        self:StopStealthHealthTicker()
        self:ResetUnitInfo()
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
        self.HealthBar:SetAlpha(1)
        if self.parent.TestTitle then
            self.parent.TestTitle:Hide()
        end
    elseif (event == "PLAYER_REGEN_ENABLED") then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:UpdateVisible()
        if self.needsHealthbarOrientationUpdate then
            self.needsHealthbarOrientationUpdate = nil
            if db then
                local currentLayout = self.parent.layouts[db.profile.currentLayout]
                if currentLayout and currentLayout.UpdateHealthbarOrientation then
                    currentLayout:UpdateHealthbarOrientation(self)
                end
            end
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

    self.parent:SetupDrag(self.WidgetOverlay.combatIndicator, self.WidgetOverlay.combatIndicator, "combatIndicator", nil, "widget")
    self.parent:SetupDrag(self.WidgetOverlay.healerIndicator, self.WidgetOverlay.healerIndicator, "healerIndicator", nil, "widget")
    self.parent:SetupDrag(self.WidgetOverlay.targetIndicator, self.WidgetOverlay.targetIndicator, "targetIndicator", nil, "widget")
    self.parent:SetupDrag(self.WidgetOverlay.focusIndicator, self.WidgetOverlay.focusIndicator, "focusIndicator", nil, "widget")
    self.parent:SetupDrag(self.WidgetOverlay.inRangeIcon, self.WidgetOverlay.inRangeIcon, "rangeCheck", nil, "global", "inRange")
    self.parent:SetupDrag(self.WidgetOverlay.notInRangeIcon, self.WidgetOverlay.notInRangeIcon, "rangeCheck", nil, "global", "notInRange")
    self.parent:SetupDrag(self.WidgetOverlay.partyTarget1, self.WidgetOverlay.partyTarget1, "partyTargetIndicators", nil, "widget", "partyOnArena")
    self.parent:SetupDrag(self.WidgetOverlay.partyTarget2, self.WidgetOverlay.partyTarget1, "partyTargetIndicators", nil, "widget", "partyOnArena")
    self.parent:SetupDrag(self.WidgetOverlay.partyTarget3, self.WidgetOverlay.partyTarget1, "partyTargetIndicators", nil, "widget", "partyOnArena")
    self.parent:SetupDrag(self, self, "partyTargetText", nil, "widget", "partyOnArena", true)
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

    local db = self.parent.db.profile
    local color = class and C_ClassColor.GetClassColor(class)

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

    if db.petFrames.enabled then
        self.PetFrame.Name:SetTextColor(self.Name:GetTextColor())
        self.PetFrame.HealthText:SetTextColor(self.HealthText:GetTextColor())
    end
end

function sArenaFrameMixin:UpdateSpecNameText(specName)
    if not self.SpecNameText then return end

    specName = specName or self.specName or ""

    local db = self.parent and self.parent.db
    local settings = db and db.profile.layoutSettings[db.profile.currentLayout]

    if not (settings and settings.showRaceManaText) then
        self.SpecNameText:SetText(specName)
        return
    end

    local race = self.localizedRace

    if race then
        self.SpecNameText:SetFormattedText("%s %s", specName, race)
    else
        self.SpecNameText:SetText(specName)
    end
end

function sArenaFrameMixin:UpdateSpecNameColor()
    if not self.SpecNameText then return end

    local class = self.class or self.tempClass

    local db = self.parent.db.profile
    local color = class and C_ClassColor.GetClassColor(class)

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
    if not self.parent:IsInArena() then return end

    local unit = self.unit

    if noEarlyFrames and UnitExists(unit) then
        self.parent.seenArenaUnits[self:GetID()] = true
    end

    self:GetClass()
    self:FindAura()

    if (unitEvent and unitEvent ~= "seen") or (UnitGUID(self.unit) == nil) then
        self:SetMysteryPlayer(unitEvent)
        return
    end
    self.isDead = UnitIsDeadOrGhost(unit)
    self:StopStealthHealthTicker()
    C_PvP.RequestCrowdControlSpell(unit)

    self:UpdateRacial()
    if not isMidnight then
        self:UpdateDispel()
    end
    self.WidgetOverlay:Show()
    self:UpdateCombatStatus(unit)
    self:UpdateArenaTargets(unit)
    self:UpdateArenaTargetText(unit)
    self:UpdateTarget(unit)
    self:UpdateFocus(unit)

    -- Prevent castbar and other frames from intercepting mouse clicks during a match
    if (unitEvent == "seen") and not InCombatLockdown() then
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
    self:UpdateSpecNameText()
    self:UpdateSpecNameColor()

    self:UpdateStatusTextVisible()
    self:SetStatusText()

    self:OnEvent("UNIT_MAXHEALTH", unit)
    self:OnEvent("UNIT_HEALTH", unit)
    self:OnEvent("UNIT_MAXPOWER", unit)
    self:OnEvent("UNIT_POWER_UPDATE", unit)
    self:OnEvent("UNIT_DISPLAYPOWER", unit)
    self:OnEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)

    if db.profile.classColors then
        local class = UnitClassBase(unit)
        local color = class and C_ClassColor.GetClassColor(class)
        if color then
            self.HealthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
        end
    else
        self.HealthBar:SetStatusBarColor(0, 1, 0, 1)
    end

    -- Workaround to show frames in older arenas in combat.
    -- Does not actually call Show(), but SetAlpha() on older arenas.
    if noEarlyFrames or (not self:IsShown() and not InCombatLockdown()) then
        self:Show()
    end

    if noEarlyFrames and not UnitExists(unit) then
        self:SetAlpha(self.parent.stealthAlpha)
    else
        self:SetAlpha(1)
        self:UpdateRangeCheck(unit)
    end
end

function sArenaFrameMixin:SetPreGatesUnknownPlayer()
    -- Active for noEarlyFrames (TBC & Wrath)
    local id = self:GetID()
    local partySize = GetNumGroupMembers()
    if id <= partySize then
        local hpTex = self.HealthBar:GetStatusBarTexture()
        local classIcon = self.ClassIcon.Texture

        local leaveGray = self.parent.db and self.parent.db.profile.colorMysteryGray

        classIcon:SetDesaturated(true)
        classIcon:SetTexture(134148)
        self.PowerBar:SetValue(100)
        self.HealthBar:SetValue(100)

        self:Show()

        if not leaveGray then
            local black = CreateColor(0, 0, 0)
            local darkRed = CreateColor(0.6, 0, 0)

            hpTex:SetGradient("HORIZONTAL", black, darkRed)
            self.PowerBar:SetStatusBarColor(0, 0, 0, 1)
            classIcon:SetVertexColor(0.55, 0.1, 0.1)
        end
    end
end

function sArenaFrameMixin:SetMysteryPlayer(unitEvent)
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

    if self.parent.db then -- TODO: Figure out cleaner fix, why db is nil here.
        if self.parent.db.profile.colorMysteryGray then
            hp:SetStatusBarColor(0.5, 0.5, 0.5)
            pp:SetStatusBarColor(0.5, 0.5, 0.5)
        else
            local class = self.class or self.tempClass
            local color = class and C_ClassColor.GetClassColor(class)

            if self.parent.db.profile.classColors then
                if color then
                    hp:SetStatusBarColor(color.r, color.g, color.b)
                end
            else
                hp:SetStatusBarColor(0, 1, 0)
            end

            local powerType
            if self.secretClass then
                if UnitHasPowerType(self.unit, Enum.PowerType.Energy) then
                    powerType = "ENERGY"
                elseif UnitHasPowerType(self.unit, Enum.PowerType.Rage) then
                    powerType = "RAGE"
                elseif UnitHasPowerType(self.unit, Enum.PowerType.Focus) then
                    powerType = "FOCUS"
                else
                    powerType = "MANA"
                end
            else
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
            end

            local powerColor = PowerBarColor[powerType]
            if powerColor then
                pp:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b)
            else
                pp:SetStatusBarColor(0, 0, 1)
            end
        end
    end

    if not matchActive and noEarlyFrames then
        self:SetPreGatesUnknownPlayer()
    end

    self:SetAlpha(self.parent.waitingForMatch and 1 or self.parent.stealthAlpha)
    self.hideStatusText = true
    self:SetStatusText()
    self.WidgetOverlay:Hide()

    self.DisconnectedIcon:Hide()
    if self.isDead then
        self:StopStealthHealthTicker()
    end
    if (unitEvent ~= "destroyed" and unitEvent ~= "unseen") or not matchActive then
        self.DeathIcon:Hide()
    end
end

function sArenaFrameMixin:ResetUnitInfo()
    self.isDead = false
    self.Name:SetText("")
    self.CastBar:Hide()
    self.specTexture = nil
    self.specName = nil
    self.isHealer = nil
    self.class = nil
    self.secretClass = nil
    self.currentClassIconTexture = nil
    self.currentClassIconStartTime = 0
    self.updateRacialOnTrinketSlot = nil
    self.classLocal = nil
    self.specID = nil
    self:UpdateAuraHighlightEnabled()
    self.SpecIcon:Hide()
    self.SpecNameText:SetText("")
    self.DeathIcon:Hide()
end

function sArenaFrameMixin:GetClass()
    if self.class then return end

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
                self:UpdateAuraHighlightEnabled()
                self:UpdateHealerStatus()
                --self.SpecNameText:SetText(specName)
                self:UpdateSpecNameText(specName)
                self.SpecNameText:SetShown(db.profile.layoutSettings[db.profile.currentLayout].showSpecManaText)
                self:UpdateSpecNameColor()
                self.specTexture = specTexture
                self.class = class
                self:UpdateSpecIcon()
                self:UpdateFrameColors()
                self.parent:UpdateTextures()

                local currentLayout = self.parent.layouts[db.profile.currentLayout]
                if currentLayout and currentLayout.UpdateHealthbarOrientation then
                    if InCombatLockdown() then
                        self.needsHealthbarOrientationUpdate = true
                        self:RegisterEvent("PLAYER_REGEN_ENABLED")
                    else
                        currentLayout:UpdateHealthbarOrientation(self)
                    end
                end
            end
        elseif UnitIsNPCAsPlayer(self.unit) then
            self.classLocal, self.class = UnitClass(self.unit)
            if self.class then
                self.ClassIcon.Texture:SetDesaturated(false)
                self.ClassIcon.Texture:SetVertexColor(1, 1, 1)
                self.secretClass = true
            end
        end
    else
        self.classLocal, self.class = UnitClass(self.unit)
        if self.class then
            self.ClassIcon.Texture:SetDesaturated(false)
            self.ClassIcon.Texture:SetVertexColor(1, 1, 1)
        end
    end
end


function sArenaFrameMixin:UpdateClassIcon(continue)
	if db and db.profile.hideClassIcon then
		self.ClassIcon.Texture:SetTexture(nil)
		self.ClassIcon.Cooldown:Clear()
		if self.ClassIconMsq then
			self.ClassIconMsq:Hide()
		end
		return
	end

	if isMidnight then
		self.ClassIcon.Cooldown:Clear()
		self.ClassIcon.Cooldown.durationObj = nil
	elseif (self.currentAuraSpellID and self.currentAuraDuration > 0 and self.currentClassIconStartTime ~= self.currentAuraStartTime) then
		self.ClassIcon.Cooldown:SetCooldown(self.currentAuraStartTime, self.currentAuraDuration)
		self.currentClassIconStartTime = self.currentAuraStartTime
	elseif (self.currentAuraDuration == 0) then
		self.ClassIcon.Cooldown:Clear()
		self.currentClassIconStartTime = 0
	end

	local texture
	if isMidnight then
		texture = self.class and "class" or nil
	else
		texture = self.currentAuraSpellID and self.currentAuraTexture or self.class and "class" or nil
	end

	if not isMidnight then -- secret
		if (self.currentClassIconTexture == texture) and not continue then return end
	end

	self.currentClassIconTexture = texture

    local useHealerTexture

    if (texture == "class") then

        if db.profile.replaceHealerIcon and self.isHealer then
            useHealerTexture = true
        end

        if db.profile.onlyShowAuras then
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
            texture = self.secretClass and GetClassAtlas(self.class) or self.parent.classIcons[self.class]
            if self.ClassIconMsq then
                self.ClassIconMsq:Show()
            end
        end

        if useHealerTexture then
            self.ClassIcon.Texture:SetAtlas("UI-LFG-RoleIcon-Healer")
        else
            if self.secretClass then
                self.ClassIcon.Texture:SetAtlas(GetClassAtlas(self.class))
            else
                self.ClassIcon.Texture:SetTexture(texture)
            end
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
    self.AuraStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 13, self.parent:GetFontFlags("THICKOUTLINE"))
    self.DispelStacks:SetPoint("BOTTOMLEFT", self.Dispel.Texture, "BOTTOMLEFT", 2, 0)
    self.DispelStacks:SetFont("Interface\\AddOns\\sArena_Reloaded\\Textures\\arialn.ttf", 15, self.parent:GetFontFlags("THICKOUTLINE"))

    self.ClassIcon.Mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    self.ClassIcon.Texture:RemoveMaskTexture(self.ClassIcon.Mask)
    self.auraSlotMask = nil
    self.ClassIcon.Texture:SetDrawLayer("BORDER", 1)
    if self.ClassIcon.bgTexture then
        self.ClassIcon.bgTexture:RemoveMaskTexture(self.ClassIcon.Mask)
        self.ClassIcon.bgTexture:Hide()
    end
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
    f.Text:SetFont(fontName, s, self.parent:GetFontFlags("OUTLINE"))

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
    local isFeigningDeath
    if isMidnight and not self.secretClass then
        isFeigningDeath = self.class == "HUNTER" and UnitIsFeignDeath(unit)
    else
        isFeigningDeath = self.class == "HUNTER" and AuraUtil.FindAuraByName(FEIGN_DEATH, unit, "HELPFUL")
    end
    local isDead = UnitIsDeadOrGhost(unit) and not isFeigningDeath

    self.hideStatusText = isDead
    if (isDead) then
        self.isDead = isDead
        self:SetStatusText()
        self.HealthBar:SetValue(0)
        self:UpdateHealPrediction()
        self:UpdateAbsorb()
        self.currentHealth = 0
        self.WidgetOverlay:Hide()
    elseif isFeigningDeath then
        self.HealthBar:SetAlpha(0.55)
        self.isFeigningDeath = true
    end
    self.DeathIcon:SetShown(self.isDead)
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

function sArenaFrameMixin:SetStatusText(unit)
    if (self.hideStatusText) or not (self.parent.engagedInMatch or self.parent.arenaMatchStarted) then
        self.HealthText:SetText("")
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

    if (db and db.profile.statusText.usePercentage) then
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
        if (db and db.profile.statusText.formatNumbers) then
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
    if db then
        self.HealthText:SetShown(db.profile.statusText.alwaysShow)
        self.PowerText:SetShown(db.profile.statusText.alwaysShow)
        self.PowerText:SetAlpha(db.profile.hidePowerText and 0 or 1)
    end
end

function sArenaMixin:CastbarOnEvent(castBar, event)
    local colors = self.castbarColors
    if not colors then return end

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
                if castBar.barHighlight then
                    castBar.barHighlight:SetAlpha(0)
                end
                if castBar.iconHighlight then
                    castBar.iconHighlight:SetAlpha(0)
                end
                return
            end
            if not self.keepDefaultModernTextures then
                local textureToUse = self.castTexture
                -- if castBar.barType == "uninterruptable" and self.castUninterruptibleTexture then
                --     textureToUse = self.castUninterruptibleTexture
                -- end
                castBar.activeTexture = textureToUse
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
                        castBar:SetStatusBarColor(1, 0.7, 0, 1)
                    end
                end
                castBar.changedBarColor = true
            elseif colors.enabled then
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
                    castBar.activeTexture = castBar.channeling and "UI-CastingBar-Filling-Channel" or "ui-castingbar-filling-standard"
                else
                    castBar.activeTexture = castBar.channeling and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard"
                end
                castBar.changedBarColor = nil
            end
        else
            local textureToUse = self.castTexture
            castBar.activeTexture = textureToUse or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
            if stoppedCast then
                castBar:SetStatusBarTexture(castBar.activeTexture)
                castBarTexture:SetDesaturated(false)
                castBarTexture:SetVertexColorFromBoolean(
                    castBar.BorderShield:IsShown(),
                    colors.enabled and colors.colorUninterruptable or colors.defaultUninterruptable,
                    colors.colorRed
                )
                if castBar.barHighlight then
                    castBar.barHighlight:SetAlpha(0)
                end
                if castBar.iconHighlight then
                    castBar.iconHighlight:SetAlpha(0)
                end
                return
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
                    castBar:SetStatusBarColor(1, 0.7, 0, 1)
                end
            end
        end
        if self.highlightCastsOnMe and castBar.barHighlight and PlayerIsSpellTarget and unitToken then
            if (castBar.casting or castBar.channeling) and castBar.spellID ~= nil then
                local spellTarget = PlayerIsSpellTarget(unitToken)
                castBar.barHighlight:SetAlphaFromBoolean(spellTarget, 1, 0)
                if self.glowCastbarIcon then
                    castBar.iconHighlight:SetAlphaFromBoolean(spellTarget, 1, 0)
                end
            else
                castBar.barHighlight:SetAlpha(0)
                if castBar.iconHighlight then castBar.iconHighlight:SetAlpha(0) end
            end
        elseif self.highlightCC and castBar.barHighlight and C_Spell.IsSpellCrowdControl then
            if (castBar.casting or castBar.channeling) and castBar.spellID ~= nil then
                local isCC = C_Spell.IsSpellCrowdControl(castBar.spellID)
                castBar.barHighlight:SetAlphaFromBoolean(isCC, 1, 0)
                if self.glowCastbarIcon then
                    castBar.iconHighlight:SetAlphaFromBoolean(isCC, 1, 0)
                end
            else
                castBar.barHighlight:SetAlpha(0)
                castBar.iconHighlight:SetAlpha(0)
            end
        else
            if castBar.barHighlight then
                castBar.barHighlight:SetAlpha(0)
                castBar.iconHighlight:SetAlpha(0)
            end
        end
        if notInterruptible ~= nil and castBar.changeUnint then
            castBar.unintTextureOverlay:SetAllPoints(castBarTexture)
            castBar.unintTextureOverlay:SetAlphaFromBoolean(notInterruptible, 1, 0)
            castBar.unintTextureOverlay:SetVertexColor(castBar:GetStatusBarColor())
        else
            castBar.unintTextureOverlay:SetAlpha(0)
        end
    else
        if self.modernCastbars then
            if not self.keepDefaultModernTextures then
                local textureToUse = self.castTexture
                if castBar.barType == "uninterruptable" and self.castUninterruptibleTexture then
                    textureToUse = self.castUninterruptibleTexture
                end
                castBar.activeTexture = textureToUse
                if colors.enabled then
                    if castBar.barType == "uninterruptable" then
                        castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                    elseif self.interruptStatusColorOn and self.interruptReady == false then
                        castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                    elseif castBar.barType == "channel" then
                        castBar:SetStatusBarColor(unpack(colors.channel or { 0, 1, 0, 1 }))
                    elseif castBar.barType == "interrupted" then
                        castBar:SetStatusBarColor(1, 0, 0)
                    else
                        castBar:SetStatusBarColor(unpack(colors.standard or { 1, 0.7, 0, 1 }))
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
                    castBar.activeTexture = castBar.barType == "uninterruptable" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard"
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
                    castBar:SetStatusBarColor(unpack(colors.channel or { 0, 1, 0, 1 }))
                elseif castBar.barType == "interrupted" then
                    castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(unpack(colors.standard or { 1, 0.7, 0, 1 }))
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
                    castBar.activeTexture = castBar.barType == "uninterruptable" and "UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "UI-CastingBar-Filling-Channel" or "ui-castingbar-filling-standard"
                else
                    castBar.activeTexture = castBar.barType == "uninterruptable" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Uninterruptable" or castBar.barType == "channel" and "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Channel" or "Interface\\AddOns\\sArena_Reloaded\\Textures\\UI-CastingBar-Filling-Standard"
                end
                castBar.changedBarColor = nil
            end
        else
            local textureToUse = self.castTexture
            if castBar.barType == "uninterruptable" and self.castUninterruptibleTexture then
                textureToUse = self.castUninterruptibleTexture
            end
            castBar.activeTexture = textureToUse or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
            if colors.enabled then
                if castBar.barType == "uninterruptable" then
                    castBar:SetStatusBarColor(unpack(colors.uninterruptable or { 0.7, 0.7, 0.7, 1 }))
                elseif self.interruptStatusColorOn and self.interruptReady == false then
                    castBar:SetStatusBarColor(unpack(colors.interruptNotReady or { 0.7, 0.7, 0.7, 1 }))
                elseif castBar.barType == "channel" then
                    castBar:SetStatusBarColor(unpack(colors.channel or { 0, 1, 0, 1 }))
                elseif castBar.barType == "interrupted" then
                    castBar:SetStatusBarColor(1, 0, 0)
                else
                    castBar:SetStatusBarColor(unpack(colors.standard or { 1, 0.7, 0, 1 }))
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
        if self.highlightCastsOnMe and castBar.barHighlight and PlayerIsSpellTarget and unitToken then
            if (castBar.casting or castBar.channeling) and castBar.spellID ~= nil then
                local spellTarget = PlayerIsSpellTarget(unitToken)
                castBar.barHighlight:SetAlphaFromBoolean(spellTarget, 1, 0)
                if self.glowCastbarIcon then
                    castBar.iconHighlight:SetAlphaFromBoolean(spellTarget, 1, 0)
                end
            else
                castBar.barHighlight:SetAlpha(0)
                if castBar.iconHighlight then castBar.iconHighlight:SetAlpha(0) end
            end
        elseif self.highlightCC and castBar.barHighlight and C_Spell.IsSpellCrowdControl then
            if (castBar.casting or castBar.channeling) and castBar.spellID ~= nil then
                local isCC = C_Spell.IsSpellCrowdControl(castBar.spellID)
                castBar.barHighlight:SetAlphaFromBoolean(isCC, 1, 0)
                if self.glowCastbarIcon then
                    castBar.iconHighlight:SetAlphaFromBoolean(isCC, 1, 0)
                end
            else
                castBar.barHighlight:SetAlpha(0)
                castBar.iconHighlight:SetAlpha(0)
            end
        else
            if castBar.barHighlight then
                castBar.barHighlight:SetAlpha(0)
                castBar.iconHighlight:SetAlpha(0)
            end
        end
    end
    if castBar.activeTexture then
        castBar:SetStatusBarTexture(castBar.activeTexture)
    end
end
