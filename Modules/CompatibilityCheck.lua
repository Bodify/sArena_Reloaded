-- Copyright (c) 2026 Bodify. All rights reserved.
-- This file is part of the sArena Reloaded addon.
-- No portion of this file may be copied, modified, redistributed, or used
-- in other projects without explicit prior written permission from the author.

function sArenaMixin:CompatibilityEnsurer()
    -- Disable any other active sArena versions due to compatibility issues, two sArenas cannot coexist
    -- This is only done with the user's specific consent by choosing to import as thoroughly explained in the GUI
    -- List of known sArena addon variants that needs to be disabled for compatibility's sake
    local otherSArenaVersions = {
        "sArena", -- Original
        "sArena Updated",
        "sArena_MoP",
        "sArena_Pinaclonada",
        "sArena_Updated2_by_sammers",
    }

    -- Ensure compatibility
    for _, addonName in ipairs(otherSArenaVersions) do
        if C_AddOns.IsAddOnLoaded(addonName) then
            C_AddOns.DisableAddOn(addonName)
        end
    end
end

function sArenaMixin:CompatibilityIssueExists()
    -- List of known sArena addon variants that will conflict
    local otherSArenaVersions = {
        "sArena", -- Original
        "sArena Updated",
        "sArena_MoP",
        "sArena_Pinaclonada",
        "sArena_Updated2_by_sammers",
    }

    -- Check each known version to see if it's loaded
    for _, addonName in ipairs(otherSArenaVersions) do
        if C_AddOns.IsAddOnLoaded(addonName) then
            return true
        end
    end

    return false -- No conflicts found
end

function sArenaMixin:IsElvUIActive()
    -- Check if ElvUI is loaded and if it hides default arena frames which causes issues.
    -- Clean this up in a future release and maybe also add a check/warning about ElvUI's own Arena Frames once tested.
    if C_AddOns.IsAddOnLoaded("ElvUI") and ElvUI[1].private.unitframe.disabledBlizzardFrames.arena then
        ElvUI[1].private.unitframe.disabledBlizzardFrames.arena = false
        return true
    end
    return false
end