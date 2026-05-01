# sArena Reloaded 2.5.0
## New
- Trinket Glow: Adds a glow animation around the Trinket icon when it gets used. Settings in Global -> Trinket,
## Tweak
- Tweak lingo about Glad Tracker requirement being 2400 when its supposed to be 2300.
![sArenaTrinketGlow](https://github.com/user-attachments/assets/898fde7b-3e77-4209-b52c-f2fb3284b6db)

# sArena Reloaded 2.4.9b
## New
- Midnight: Glad Tracker (same as in BetterBlizzFrames). This will add tracking of your Arena/Shuffle/BG elite achievements to your honor panel and display number of wins and required for the achievement. One win above elite rating is required for it to display. It is enabled by default but can be turned off at the very bottom of Global -> Arena Frames -> Misc.
## Bugfix
- Fix new Cooldown Swipe Color setting on Classic versions of WoW causing a lua error due to the function accidentally being left out on Classic versions.
- Fix potential errors caused from old custom code tweaking sArena's aura priority.

# sArena Reloaded 2.4.9
## New
- Midnight: Added back DR leeway adjustments (due to Blizzard bug). Tldr is Blizzards DR frames can sometimes be inaccurate by around 0.3sec. This lets you set a safer value than the original intended 16 seconds. By default its set to 16.1 but 16.3 might be safer. (Global -> Diminishing Returns)
## Tweak
- Tweak frame strata & levels of stuff.
- Make sure statusbar text is hidden between shuffle rounds on all frames.
## Bugfix
- Fix Aura Highlights potentially getting stuck on between shuffle rounds in spawn room if class icon was set to hidden.

# sArena Reloaded 2.4.8
### New
- Cooldown Swipe Color setting (Global -> Cooldown Swipe Color)
### Tweak
- Support for ShadowedUnitFrames partyframes for Party/Arena Targets by void-ow@GitHub. Thank you!
- Update Dissonance profle (www.twitch.tv/dissonancewow)
- Tweak Spec Icon Button and Widgets FrameStrata & Levels (to avoid it showing on top of talent frame for example)
- Midnight: Tweak handling of Party/Arena Targets so icons properly stack in one direction (no gaps or starting in wrong end)

# sArena Reloaded 2.4.7c
## Tweak
- Added Arena Target Indicator support for ElvUI, Cell, Grid2, DandersFrames, VuhDo and default Blizzard non-raidstyle PartyFrames. If theres an addon you miss let me know.
- Aura logic reworked a little bit so Aura Highlights can now work alone on its own if Class Icon is hidden or Auras on Class Icon is disabled.
- Aura Highlight around Class Icon disabled while "Hide Class Icon" is enabled.
![sArenaAuraHighlight](https://github.com/user-attachments/assets/0aa1e574-7de5-434f-9fb0-7a18e9a224d1)

# sArena Reloaded 2.4.7b
## Tweak
- Add back Masque support for Frame & Castbar (the bar itself) as a subsetting in Global -> Misc at the bottom (off by default).
- Fix test mode title text being anchored to the wrong frame when growth direction of arena frames was set to up.

# sArena Reloaded 2.4.7
## New
- Aura Highlight: Shows a glow/pixel highlight on arena frames during CC/Defensives/Important auras. (Global -> Aura Highlights). Classics: For classics this offers much more customizeability but I want to keep it similar to Midnight so whats expected from it is the same. If you have feedback on the spells on TBC/Wrath/MoP please let me hear it!
- Healer Indicator: New Widget that just shows a cross on the healer frame (Layout -> Widgets -> Healer Indicator)
- New "Arena/Party Target Text" setting in Widgets section. Show target name of arena/party unit.
- Midnight: Workaround setting for Blizzard DR Bug (Global -> Diminishing Returns). This setting will to a crude workaround so you wont get fooled by a bug related to Mass Invis and DR frames not updating properly because of it. Thank Blizzard for this, I wish I could fix it properly.
- Added "Minimalist" texture as option due to demand.
## Tweak
- Midnight: New workaround for Party/Arena Target Indicators (the icons from before, not the new target text).
- Remove Masque categories for "Castbar" (not the Icon, but the bar itself) and "Frame". I don't think these are needed or wanted but if you were using them let me know.
## Bugfix
- Fix mistake in Masque support code after earlier refactor causing a lua error now.
- Fix Masque support showing Masque border on Dispel Icons in Midnight (which shouldve been hidden since dispels are not supported on Midnight)