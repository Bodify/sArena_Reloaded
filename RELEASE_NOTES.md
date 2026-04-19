# sArena Reloaded 2.4.6
## New
- Hide Class Icon setting. Hide it entirely, no class or aura.
## Tweak
- Split all the global Class Icon settings into its own section so it's easier to navigate.
- Raise frame level of Widget: Target/Focus border so it shows above MiniCC icons.
- Fix Shadowsight timer for Midnight. (Wont accurately detect pickup, only spawn time then auto hide after 35 sec. Not active in Solo Shuffle)

# sArena Reloaded 2.4.5
## New
- New Range Check settings in Global. You can now enable icons/colors/transparency settings for range and set a specific range depending on the spell you pick. (Global -> Range Check)
- Castbar background can now also be changed texture and set color for (Layout -> Castbar)
- Stealth Alpha slider (Global -> Arena Frames)
- New disconnected icon on healthbar similar to death icon when disconnected.
## Tweak
- Midnight: Make sure Racial Shared CD does not reset an already active Racial CD when Trinket gets used 2nd.
- Midnight: Mention Blizzards new API restriction bricking the current Party/Arena Targets feature in its section (and that a new similar feature is inc).
- Midnight: Add missing Warlock Pet Spell Lock ID to interrupt list so castbars color properly.
- Tweak healthbar size for Blizz Retail layout when hiding powerbars to not leave a small gap on the bottom left side.
- Add a dark background texture for "Hide Class Icon (Show Auras Only)" setting on layouts that have a circle border around class icon to make it look less strange with it being see through.
## Bugfix
- Fix test mode running into an error on Classic clients due to some Midnight-only code accidentally being run.