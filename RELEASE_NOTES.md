# sArena Reloaded 2.6.1g
## Tweak
- Midnight: Fix an issue with DR frames sticking around between shuffle rounds and not resetting until round started.

# sArena Reloaded 2.6.1f
## Bugfix
- Midnight: Fix DR frames getting hidden on UI hide and not coming back afterwards.

# sArena Reloaded 2.6.1e
## Tweak
- Update Dissonance profile (www.twitch.tv/dissonancewow). Thank you for sharing!

# sArena Reloaded 2.6.1d
## Tweak
- Update Jazggz profile (www.twitch.tv/jazggz). Thank you for sharing!
## Bugfix
- Fix an issue with class color frames in the new NPC Training Grounds Arena.

# sArena Reloaded 2.6.1c
## New
- Add new Ceit profile (www.twitch.tv/ceitxd). Thank you for sharing!
- Add new Rahbekius profile (www.twitch.tv/rahbekius). Thank you for sharing!
## Bugfix
- Fix an issue with the border on Class Icon for some layouts disappearing sometimes.

# sArena Reloaded 2.6.1b
## New
- Add EllesmereUI party frames anchor support for Widgets.

# sArena Reloaded 2.6.1
## New
- New profile: Kaaaz (www.twitch.tv/KaaazTTV). Raidframe style. Thank you for sharing!
- Midnight: Add disarms as CC auras for Midnight. Again ty to Verz for providing the list without me even asking <3
- Midnight: Add a few debuff auras to track (Like Hypo and Forb).
## Bugfix
- Midnight: Fix crop on icons for the new 12.1 auras.
- Fix Class Icon aura highlight glow being too small on BlizzRaid layout.

# sArena Reloaded 2.6.0e
## Bugfix
- Fix Class Icon CD Font Size setting not applying to the cooldown text on the new Midnight 12.1 auras.

# sArena Reloaded 2.6.0d
## Bugfix
- Fix a nil class check causing error on the new class color api

# sArena Reloaded 2.6.0c
## Bugfix
- Fix a secret error
- Fix a nil error for class color frame texture after changes to class colors.

# sArena Reloaded 2.6.0b
## Tweak
- Add mention of racial texture being gone on Midnight 12.1 in that section.
- Support for new Training Grounds NPC arenas.
- Update Dissonance profile (www.twitch.tv/dissonancewow)
## Bugfix
- Fix Class Icon Auras not showing decimals on new Midnight 12.1 auras.
- Fix secret error.
- Fix Class Icon aura highlight glow not scaling with the class icon in layouts that can scale it (BlizzCompact, BlizzRaid, Pixelated).
- Fix Class/Aura Icon showing a red question mark in the new npc arena if class icon was disabled

# sArena Reloaded 2.6.0
## New
- Midnight: Updated for 12.1. Notable change: Racial Texture is gone because races are now secret. However race text is now available instead as mentioned below.
- New Race text next to spec text setting (Layout -> Arena Frames: Options). (I'll tweak this and add some more options in the future)
- TBC: Show arena frames in spawn like on other clients but without any info just a dark mystery player frame.
## Tweak
- Tweak the castbar spark size on Classic versions, was too big.
## Bugfix
- Fix uninterruptible casts showing normal cast/channel color with certain specific settings.
- Fix shadowsight timer starting in BGs
## Notes
- I want to thank Verz and Muleyo for helping me understand some of the new 12.1 API with examples and stuff. Thank you<3
- I am aware of a bug on the classic versions where if someone on the enemy team is casting as the gates open the castbar gets stuck visible at all times. I have no idea why this happens atm and I dont have any classic characters to test with and I cannot replicate it on PTR either. If you are able to test this and get some info my way please contact me on discord.