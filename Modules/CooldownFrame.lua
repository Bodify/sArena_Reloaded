local LSM = LibStub("LibSharedMedia-3.0")
local decimalThreshold = 6 -- Default value, will be updated from db

local AURA_COOLDOWN_FONT = "sArenaReloadedAuraCooldownFont"

function sArenaMixin:GetAuraCooldownFont()
    return _G[AURA_COOLDOWN_FONT] or self:UpdateAuraCooldownFont()
end

function sArenaMixin:UpdateAuraCooldownFont(size)
    local font = _G[AURA_COOLDOWN_FONT]
    if not font then
        font = CreateFont(AURA_COOLDOWN_FONT)
        font:CopyFontObject(NumberFontNormal)
    end

    local layoutdb = self.layoutdb
    size = size or (layoutdb and layoutdb.classIconFontSize) or 12

    local classIconCD = self.arena1 and self.arena1.ClassIcon and self.arena1.ClassIcon.Cooldown
    local countdownString = classIconCD and classIconCD:GetCountdownFontString()
    local path = countdownString and countdownString.fontFile
    if layoutdb and layoutdb.changeFont and layoutdb.cdFont then
        path = LSM:Fetch(LSM.MediaType.FONT, layoutdb.cdFont) or path
    end
    path = path or NumberFontNormal:GetFont() or STANDARD_TEXT_FONT

    font:SetFont(path, size, self:GetFontFlags("OUTLINE"))
    font:SetShadowOffset(0, 0)

    return font
end

function sArenaMixin:UpdateDecimalThreshold()
    decimalThreshold = self.db.profile.decimalThreshold or 6
end

function sArenaMixin:UpdateCooldownThresholds(cooldown, showDecimals, hideText)
    cooldown:SetHideCountdownNumbers(hideText and true or false)
    cooldown:SetMinimumCountdownDuration(0)
    cooldown:SetCountdownMillisecondsThreshold(showDecimals and decimalThreshold or 0)
end

function sArenaMixin:CustomizeDefaultCD()
    local omniCC = C_AddOns.IsAddOnLoaded("OmniCC")
    local profile = self.db.profile

    local function CustomizeCooldown(cooldown, showDecimals, hideText)
        if omniCC then
            cooldown:SetMinimumCountdownDuration(0)
        else
            self:UpdateCooldownThresholds(cooldown, showDecimals, hideText)
        end
    end

    for i = 1, self.maxArenaOpponents do
        local frame = self["arena" .. i]

        -- Class icon cooldown
        CustomizeCooldown(frame.ClassIcon.Cooldown, profile.showDecimalsClassIcon, profile.disableCDTextClassIcon)

        -- Trinket cooldown
        CustomizeCooldown(frame.Trinket.Cooldown, profile.showDecimalsClassIcon, profile.disableCDTextTrinket)

        -- DR cooldowns
        local useDrFrames = frame.drFrames ~= nil
        local drList = frame.drFrames or self.drCategories
        if drList then
            for i = 1, #drList do
                local drFrame = useDrFrames and drList[i] or frame[drList[i]]
                if drFrame then
                    CustomizeCooldown(drFrame.Cooldown, profile.showDecimalsDR, profile.disableCDTextDR)
                end
            end
        end
    end
end
