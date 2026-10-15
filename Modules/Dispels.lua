-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

local GetTime = GetTime
local isRetail = sArenaMixin.isRetail
local GetSpellName = C_Spell.GetSpellName

local detectedDispels = {}
local dispelStacks = {}
local lastDispelTime = {}

local DISPEL_RECHARGE_TIME = 8
local DISPEL_THROTTLE = 0.2

local function updateDispelStacksForFrame(frame)
	local unit = frame.unit
	local data = dispelStacks[unit]

	if not data then
		if frame.DispelStacks then
			frame.DispelStacks:SetText("")
		end
		return
	end

	local now = GetTime()

	if #data.rechargeTimes > 0 then
		local newRechargeTimes = {}
		for _, rechargeTime in ipairs(data.rechargeTimes) do
			if rechargeTime > now then
				table.insert(newRechargeTimes, rechargeTime)
			else
				data.charges = math.min(data.maxCharges, data.charges + 1)
			end
		end
		data.rechargeTimes = newRechargeTimes
	end

	if frame.DispelStacks then
		if data.hasMultiCharges then
			frame.DispelStacks:SetText(tostring(data.charges))
		else
			frame.DispelStacks:SetText("")
		end
	end

	local db = frame.parent and frame.parent.db
	local desaturateSetting = db and db.profile and db.profile.desaturateDispelCD

	if data.hasMultiCharges then
		frame.Dispel.Texture:SetDesaturated(desaturateSetting and data.charges == 0)
	else
		frame.Dispel.Texture:SetDesaturated(desaturateSetting and data.charges == 0)
	end

	if #data.rechargeTimes > 0 then
		local soonest = math.huge
		for _, rechargeTime in ipairs(data.rechargeTimes) do
			if rechargeTime < soonest then
				soonest = rechargeTime
			end
		end

		local remaining = soonest - now
		if remaining > 0 then
			local startTime = soonest - DISPEL_RECHARGE_TIME
			frame.Dispel.Cooldown:SetCooldown(startTime, DISPEL_RECHARGE_TIME)

			C_Timer.After(remaining + 0.01, function()
				updateDispelStacksForFrame(frame)
			end)
		else
			frame.Dispel.Cooldown:Clear()
		end
	else
		frame.Dispel.Cooldown:Clear()
	end
end

function sArenaFrameMixin:FindDispel(spellID)
	if not self.parent.dispelData[spellID] then return end

	if not detectedDispels[self.unit] then
		detectedDispels[self.unit] = {}
	end
	detectedDispels[self.unit][spellID] = true

	local dispelInfo = self.parent.dispelData[spellID]
	local cooldown = dispelInfo and dispelInfo.cooldown or 8
	local now = GetTime()

	-- Throttle
	local unitKey = self.unit .. "_" .. spellID
	if lastDispelTime[unitKey] and (now - lastDispelTime[unitKey]) < DISPEL_THROTTLE then
		return
	end

	-- Only handle charge tracking for spell ID 527 (Purify - can have 2 charges with talent)
	if spellID == 527 then
		if not dispelStacks[self.unit] then
			dispelStacks[self.unit] = {
				charges = 1,
				maxCharges = 1,
				hasMultiCharges = false,
				rechargeTimes = {}
			}
		end

		local data = dispelStacks[self.unit]
		-- If they used dispel recently (within cooldown period but past throttle window),
		-- they must have the 2-charge talent. Add 1s leeway to avoid edge cases.
		local timeSinceLastDispel = lastDispelTime[unitKey] and (now - lastDispelTime[unitKey]) or math.huge
		local hasUsedDispelOnCooldown = timeSinceLastDispel < (DISPEL_RECHARGE_TIME - 0.5)

		if hasUsedDispelOnCooldown and not data.hasMultiCharges then
			data.hasMultiCharges = true
			data.maxCharges = 2
		end
	end

	lastDispelTime[unitKey] = now

	if spellID == 527 then
		local data = dispelStacks[self.unit]

		if data.charges > 0 then
			data.charges = data.charges - 1
		end

		-- Calculate when this charge should finish recharging
		-- If there are already charges recharging, queue this one after the last one
		local rechargeEndTime
		if #data.rechargeTimes > 0 then
			-- Start recharging after the last charge finishes
			local lastRechargeTime = data.rechargeTimes[#data.rechargeTimes]
			rechargeEndTime = lastRechargeTime + DISPEL_RECHARGE_TIME
		else
			-- No charges recharging, start immediately
			rechargeEndTime = now + DISPEL_RECHARGE_TIME
		end

		table.insert(data.rechargeTimes, rechargeEndTime)

		updateDispelStacksForFrame(self)
	end

	self.Dispel.Cooldown:SetCooldown(now, cooldown)
	self:UpdateDispel()
end

function sArenaFrameMixin:GetDispelData()
	local specID = self.specID
	if not specID then return end

	local spellData = self.parent.specToDispel[specID]
	if not spellData then return end

	local spellIDs = type(spellData) == "table" and spellData or {spellData}

	for _, spellID in ipairs(spellIDs) do
		if self.parent.dispelData[spellID] then
			local dispelInfo = self.parent.dispelData[spellID]
			local isValid = true

			-- For MoP shared spells, DPS specs need to have used the spell first
			if not isRetail and dispelInfo.sharedSpecSpellID then
				local isHealer = self.parent.healerSpecIDs[specID]
				if not isHealer then
					-- DPS specs need to use the spell first
					if not detectedDispels[self.unit] or not detectedDispels[self.unit][spellID] then
						isValid = false
					end
				end
			elseif dispelInfo.showAfterUse then
				-- Regular showAfterUse logic for unique DPS spells
				if not detectedDispels[self.unit] or not detectedDispels[self.unit][spellID] then
					isValid = false
				end
			end

			if isValid then
				local isEnabled = false

				if isRetail then
					-- Retail: use simple spell-based categories
					isEnabled = self.parent.db.profile.dispelCategories[spellID]
				else
					-- MoP: check if this spell is available for this spec type
					local isHealer = self.parent.healerSpecIDs[specID]

					-- For shared spells, use separate settings
					if dispelInfo.sharedSpecSpellID then
						local settingKey = spellID .. (isHealer and "_healer" or "_dps")
						isEnabled = self.parent.db.profile.dispelCategories[settingKey]
					else
						-- For unique spells, use regular spell setting but check spec type match
						isEnabled = self.parent.db.profile.dispelCategories[spellID]
						if isEnabled then
							local availableForSpec = false
							if isHealer and dispelInfo.healer then
								availableForSpec = true
							elseif not isHealer and not dispelInfo.healer then
								availableForSpec = true
							end

							if not availableForSpec then
								isEnabled = false
							end
						end
					end
				end

				if not isEnabled then
					isValid = false
				end
			end

			if isValid then
				return {
					spellID = spellID,
					texture = dispelInfo.texture,
					name = GetSpellName(spellID) or dispelInfo.name,
				}
			end
		end
	end

	return nil
end

function sArenaFrameMixin:GetTestModeDispelData()
	local class = self.tempClass
	if not class then return nil end

	local classToSpellID = {
		["DRUID"] = 88423,   -- Nature's Cure (Resto)
		["EVOKER"] = 360823, -- Naturalize (Preservation)
		["MAGE"] = 475,      -- Remove Curse
		["MONK"] = 115450,   -- Detox (Mistweaver)
		["PALADIN"] = 4987,  -- Cleanse (Holy)
		["PRIEST"] = 527,    -- Purify
		["SHAMAN"] = 77130,  -- Purify Spirit (Resto)
	}

	local classToTestSpec = {
		["DRUID"] = 105,     -- Restoration
		["EVOKER"] = 1468,   -- Preservation
		["MAGE"] = 62,       -- Arcane
		["MONK"] = 270,      -- Mistweaver
		["PALADIN"] = 65,    -- Holy
		["PRIEST"] = 256,    -- Discipline
		["SHAMAN"] = 264,    -- Restoration
	}

	local spellID = classToSpellID[class]
	local testSpecID = classToTestSpec[class]
	if not spellID or not testSpecID then return nil end

	local dispelInfo = self.parent.dispelData[spellID]
	if not dispelInfo then return nil end

	if self.parent and self.parent.db then
		local isEnabled = false

		if isRetail then
			-- Retail: use simple spell-based categories
			isEnabled = self.parent.db.profile.dispelCategories[spellID]
		else
			-- MoP: check if this spell is available for this spec type
			local isHealer = self.parent.healerSpecIDs[testSpecID]

			-- For shared spells, use separate settings
			if dispelInfo.sharedSpecSpellID then
				local settingKey = spellID .. (isHealer and "_healer" or "_dps")
				isEnabled = self.parent.db.profile.dispelCategories[settingKey]
			else
				-- For unique spells, use regular spell setting but check spec type match
				isEnabled = self.parent.db.profile.dispelCategories[spellID]
				if isEnabled then
					local availableForSpec = false
					if isHealer and dispelInfo.healer then
						availableForSpec = true
					elseif not isHealer and not dispelInfo.healer then
						availableForSpec = true
					end

					if not availableForSpec then
						isEnabled = false
					end
				end
			end
		end

		if isEnabled then
			return {
				spellID = spellID,
				texture = dispelInfo.texture,
				name = GetSpellName(spellID) or dispelInfo.name,
			}
		end
	end
end

function sArenaFrameMixin:UpdateDispel()
	local dispel = self.Dispel
	local db = self.parent.db
	local dispelEnabled = db.profile.showDispels
	local dispelInfo = self:GetDispelData()

	local shouldShow = dispelEnabled and dispelInfo ~= nil
	dispel:SetShown(shouldShow)

	if not dispelInfo then
		dispel.Texture:SetTexture(nil)
		return
	end

	dispel.spellID = dispelInfo.spellID
	dispel.Texture:SetTexture(dispelInfo.texture)

	-- Only spell ID 527 (Purify) uses charge tracking
	if dispelInfo.spellID == 527 then
		updateDispelStacksForFrame(self)
	else
		local onCooldown = db.profile.desaturateDispelCD and dispel.Cooldown:GetCooldownDuration() > 0
		dispel.Texture:SetDesaturated(onCooldown)
	end
end


function sArenaMixin:ResetDetectedDispels()
	wipe(detectedDispels)
	wipe(dispelStacks)
	wipe(lastDispelTime)
end

function sArenaFrameMixin:ResetDispel()
	local dispel = self.Dispel

	dispel.spellID = nil
	dispel.Texture:SetTexture(nil)
	dispel.Cooldown:Clear()
	detectedDispels[self.unit] = nil
	dispelStacks[self.unit] = nil
	dispel.Texture:SetDesaturated(false)

	for key in pairs(lastDispelTime) do
		if key:match("^" .. self.unit .. "_") then
			lastDispelTime[key] = nil
		end
	end

	if self.DispelStacks then
		self.DispelStacks:SetText("")
	end
end
