# sArena Reloaded 2.6.2d
## Bugfix
- TBC: Add fix for reload in arenas causing the pre-gates mystery player icon to override the class icon.

# sArena Reloaded 2.6.2c
## Tweak
- TBC: Add fallback for health numbers to avoid a nil error.

# sArena Reloaded 2.6.2b
## Tweak
- Midnight: Tweak to auras to try avoid Mind Control issues (need bugfixes from Blizzard here)
- Minor clean up, esp related to bugfixes below.
## Bugfix
- Classics: Fix DR frames sticking around between games after recent changes mostly aimed for Midnight.
- Classics: Fix lua error in DR gui when spec specific DRs were enabled due to old API call to get class color.

# sArena Reloaded 2.6.2
## New
- Added "Show Dampening" setting, optional in the new section mentioned below.
- Added a new section "Arena Widgets" in Global Settings for things not directly related to the arena frames itself but to arena. It contains the new Dampening setting, Shadowsight timer and Gladiator Tracker for now.
## Tweak
- Fix performance issues with "Target Text" setting with "Always on" setting enabled during raids. This feature is now both improved generally speaking but also disabled entirely in raids and bgs where they dont need to be shown.
- TBC: Add support for MiniHealthNumbers' API to show calculated health instead of just percentage. This requires the MiniHealthNumbers addon by Verz.
- Minor cleanup and improvements here and there.