local isMidnight = sArenaMixin.isMidnight
local decimalThreshold = 6 -- Default value, will be updated from db
local decimalCurve
local decimalCurveInverse

function sArenaMixin:UpdateDecimalThreshold()
    decimalThreshold = self.db.profile.decimalThreshold or 6
    if isMidnight then
        self:UpdateDecimalCurve()
    end
end

function sArenaMixin:CreateCustomCooldown(cooldown, showDecimals)
    if isMidnight and cooldown.SetCountdownMillisecondsThreshold then
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
        if isMidnight then
            cooldown:SetHideCountdownNumbers(false)
            cooldown:SetScript("OnUpdate", function(_, elapsed)
                if not cooldown.durationObj then return end
                lastUpdate = lastUpdate + elapsed
                if lastUpdate < 0.05 then return end
                lastUpdate = 0

                text:SetAlpha(cooldown.durationObj:EvaluateRemainingDuration(decimalCurve))
                if cooldown.Text then
                    cooldown.Text:SetAlpha(cooldown.durationObj:EvaluateRemainingDuration(decimalCurveInverse))
                end

                text:SetText(string.format("%.1f", cooldown.durationObj:GetRemainingDuration()))
            end)
        else
            cooldown:SetScript("OnUpdate", function(self, elapsed)
                lastUpdate = lastUpdate + elapsed
                if lastUpdate < 0.05 then return end
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
        end
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

if not isMidnight then return end

function sArenaMixin:UpdateDecimalCurve()
    decimalCurve = C_CurveUtil.CreateCurve()
    decimalCurve:SetType(Enum.LuaCurveType.Step)
    decimalCurve:AddPoint(0.0, 1)
    decimalCurve:AddPoint(decimalThreshold, 0)

    decimalCurveInverse = C_CurveUtil.CreateCurve()
    decimalCurveInverse:SetType(Enum.LuaCurveType.Step)
    decimalCurveInverse:AddPoint(0.0, 0)
    decimalCurveInverse:AddPoint(decimalThreshold, 1)
end