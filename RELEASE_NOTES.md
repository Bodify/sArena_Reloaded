# sArena Reloaded 2.5.2
## New
- New intro screen for first time sArena Reloaded users where you can preview and pick a layout/profile.
- All profiles in "Streamer Profiles" section can now be previewed by mousing over the buttons.
## Tweak
- Fix "Force Castbar Text Width" setting to account for text size setting so it doesnt truncate for no reason or go outside.
- Interrupt logic: Replace IsSpellKnown with IsPlayerSpell because IsSpellKnown returns false on known spells on some clients. #Blizzard
## Bugfix
- Fix issues with Arena/Party Target Indicators not showing up on other types of non-default party frames (Danders, ElvUI, etc). Also consider if ElvUI doesnt disable default party frames and use default party frames instead.