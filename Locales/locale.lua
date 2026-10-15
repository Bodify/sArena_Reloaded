-- Locale system for sArena Reloaded
-- enUS.lua fills L. The other locale files fill L_native, which ApplyLocale merges into L
-- once saved variables are loaded, unless Force English GUI is on.

sArenaMixin.L = sArenaMixin.L or {}
sArenaMixin.L_native = {}
sArenaMixin.locale = GetLocale()

-- Missing keys show the key name
setmetatable(sArenaMixin.L, {
	__index = function(t, key)
		return key
	end
})

sArenaMixin.englishClassNames = {
	WARRIOR = "Warrior",
	PALADIN = "Paladin",
	HUNTER = "Hunter",
	ROGUE = "Rogue",
	PRIEST = "Priest",
	DEATHKNIGHT = "Death Knight",
	SHAMAN = "Shaman",
	MAGE = "Mage",
	WARLOCK = "Warlock",
	MONK = "Monk",
	DRUID = "Druid",
	DEMONHUNTER = "Demon Hunter",
	EVOKER = "Evoker",
}

function sArenaMixin:IsForceEnglish()
	return sArena_ReloadedDB and sArena_ReloadedDB.forceEnglish and true or false
end

-- Class name for the settings, English when Force English GUI is on
function sArenaMixin:GetClassDisplayName(classToken)
	if self:IsForceEnglish() then
		return self.englishClassNames[classToken] or classToken
	end
	return LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken] or classToken
end

function sArenaMixin:ApplyLocale()
	local native = sArenaMixin.L_native
	if not native then return end
	if not sArenaMixin:IsForceEnglish() then
		local L = sArenaMixin.L
		for key, value in pairs(native) do
			L[key] = value
		end
	end
	sArenaMixin.L_native = nil
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, addonName)
	if addonName ~= "sArena_Reloaded" then return end
	self:UnregisterEvent("ADDON_LOADED")
	sArenaMixin:ApplyLocale()
end)
