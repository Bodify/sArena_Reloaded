# sArena Reloaded 2.4.7b
## Tweak
- Add back Masque support for Frame & Castbar (the bar itself) as a subsetting in Global -> Misc at the bottom (off by default).
- Fix test mode title text being anchored to the wrong frame when growth direction of arena frames was set to up.
![sArenaAuraHighlight](https://github.com/user-attachments/assets/0aa1e574-7de5-434f-9fb0-7a18e9a224d1)

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