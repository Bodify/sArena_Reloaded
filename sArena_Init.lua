sArenaMixin = {}
sArenaFrameMixin = {}
sArenaPetFrameMixin = {}

local gameVersion = select(1, GetBuildInfo())
sArenaMixin.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
sArenaMixin.isMidnight = gameVersion:match("^12")
sArenaMixin.isMoP = gameVersion:match("^5%.")
sArenaMixin.isWrath = gameVersion:match("^3%.")
sArenaMixin.isTBC = gameVersion:match("^2%.")
sArenaMixin.noEarlyFrames = sArenaMixin.isTBC or sArenaMixin.isWrath

sArenaMixin.addonName = "|T135884:13:13|t sArena |cffff8000Reloaded|r"
sArenaMixin.addonTitle = sArenaMixin.addonName.. " " .. (C_AddOns.GetAddOnMetadata("sArena_Reloaded", "Version") or "")
sArenaMixin.popupHeader = "\n"..sArenaMixin.addonName.."\n\n"

sArenaMixin.playerClass = select(2, UnitClass("player"))
sArenaMixin.maxArenaOpponents = (sArenaMixin.isRetail and 3) or 5
sArenaMixin.noTrinketTexture = (sArenaMixin.isTBC and 132311) or 638661 --temp texture for tbc. todo: export retail and include in sarena
sArenaMixin.trinketTexture = (sArenaMixin.isRetail and 1322720) or 133453
sArenaMixin.trinketID = (sArenaMixin.isRetail and 336126) or 42292
sArenaMixin.useHardcodedTrinketDuration = sArenaMixin.isMoP-- or sArenaMixin.isTBC

sArenaMixin.shadowsightStartTime = 95
sArenaMixin.shadowsightResetTime = 122
sArenaMixin.shadowSightID = 34709
sArenaMixin.shadowsightTimers = {0, 0}
sArenaMixin.shadowsightAvailable = 2

sArenaMixin.layouts = {}
sArenaMixin.defaultSettings = {
    profile = {
        currentLayout = "Gladiuish",
        classColors = true,
        showNames = true,
        hidePowerText = true,
        showDecimalsDR = true,
        showDecimalsClassIcon = true,
        decimalThreshold = 6,
        drBugFixMidnight = true,
        forceShowTrinketOnHuman = not sArenaMixin.isRetail and true or nil,
        shadowSightTimer = (sArenaMixin.isTBC or sArenaMixin.isWrath) and true or nil,
        trinketSoundName = "Lossa Trinket",
        trinketSoundFileID = 0,
        healerTrinketSoundName = "Lossa Trinket",
        healerTrinketSoundFileID = 0,
        trinketSoundChannel = "Master",
        trinketUseGlowColor = { 1, 1, 1, 1 },
        darkModeValue = 0.2,
        desaturateTrinketCD = true,
        desaturateDispelCD = true,
        gladTracker = true,
        darkModeDesaturate = true,
        statusText = {
            alwaysShow = true,
            formatNumbers = true,
        },
        petFrames = {
            enabled = false,
            classes = {
                WARLOCK     = true,
                HUNTER      = true,
            },
            statusText = {
                alwaysShow = true,
                usePercentage = true,
            },
            classColors = true,
            customColor = { 0, 1, 0, 1 },
            borderStyle     = "layoutBorders",
        },
        trinketColors = {
            available = { 0, 1, 0 },
            used = { 1, 0, 0 },
        },
        castBarColors = {
            standard = { 1.0, 0.7, 0.0, 1 },
            channel = { 0.0, 1.0, 0.0, 1 },
            uninterruptable = { 0.7, 0.7, 0.7, 1 },
            interruptNotReady = { 1.0, 0.0, 0.0, 1 },
        },
        layoutSettings = {},
        invertClassIconCooldown = true,
        ccSort = "last",
        defensiveSort = "last",
        importantSort = "last",
        cooldownSwipeColor = { 0, 0, 0, 0.55 },
        stealthAlpha = 0.4,
        rangeCheckSpellsPerSpec = {},
        rangeCheck = {
            enabled = false,
            mode = "both",
            notInRangeAlpha = 0.7,
            inRangeAtlas = "common-icon-checkmark-yellow",
            inRangeCustomAtlas = "",
            inRangeColorEnabled = true,
            inRangeColor = { 0, 1, 0, 1 },
            inRangeScale = 1,
            inRangePosX = 0,
            inRangePosY = 0,
            notInRangeAtlas = "common-icon-redx",
            notInRangeCustomAtlas = "",
            notInRangeColor = { 1, 0.2, 0.2, 1 },
            notInRangeScale = 1,
            notInRangePosX = 0,
            notInRangePosY = 0,
        },
        clickAttributes = {
            ["Left"] = { button = "1", action = "target" },
            ["Right"] = { button = "2", action = "focus" },
        },
        usePetFrameClickActions = false,
        petFrameClickAttributes = {
            ["Left"] = { button = "1", action = "target" },
            ["Right"] = { button = "2", action = "focus" },
        },
        auraHighlight = {
            cc        = { enabled = true, color = {1, 0.87, 0,    1} },
            important = { enabled = true, color = {0, 1,    0,    1} },
            defensive = { enabled = true, color = {1, 0.66, 0.95, 1} },
            glowClassIcon  = { enabled = true },
            pixelBorder    = { enabled = true,  lines = 8, frequency = 0.2, length = 15, thickness = 2 },
            pixelClassIcon = { enabled = false, lines = 8, frequency = 0.2, length = 15, thickness = 2 },
            framePulse     = { speed = 0.3, size = 1.5, minAlpha = 0, maxAlpha = 1 },
        },
    }
}