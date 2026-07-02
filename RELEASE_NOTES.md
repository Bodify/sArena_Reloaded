# sArena Reloaded 2.5.7c
## New
- New "Only show CC Auras" setting (in Global -> Class Icon)
## Tweak
- Revert back to old method to hook Blizzard DR frames (opening Edit Mode) due to a few people reporting issues. The new method is still available as a setting in Global -> Diminishing Returns at the very bottom in the new "Debug" block. Please enable this if you want to help and report any issues. Thank you!

# sArena Reloaded 2.5.7b
## Tweak
- Update Dissonance profile (www.twitch.tv/dissonancewow)

# sArena Reloaded 2.5.7
## New
- Add an option to include Shadow Word: Death in the interrupt list for the interrupt castbar color setting (Layout -> Castbar). Only applied to healers, not Shadow.
## Tweak
- Remove wyvern sting dot spell id from aura list (as opposed to the actual cc) from TBC version.
- Rework Midnight hook into DR frames so it no longer requires to open Edit Mode on login/reload. This will both avoid running into a Blizzard bug that causes the breath bar (swimming) to disappear after opening edit mode and also reduce taint risk in general. If you have addons that introduce taint however you are of course still at risk but less so (if you dont open edit mode manually anyway).
- Remove white castbar flash at end of cast.