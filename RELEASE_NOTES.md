# sArena Reloaded 2.4.4
## New
- Click Actions (Global). You can now add new and customize existing Click Actions like Left Click to Target and Right Click to Focus. For example Shift+RightClick to use a macro.
- Midnight only: New castbar setting "Highlight Casts on Me" that puts a bright border around the castbar if the spell is being casted on you. (Layout -> Cast Bar)
## Tweak
- Fix Castbar TargetText/ID not getting proper font sometimes.
- Castbar color tweaks to be more consistent.
- Midnight: Fix castbar interrupt detection so now castbars will immediately hide again when a cast is over except for when they get interrupted and it will say who interrupted it and fade out slowly.
## Bugfix
- Midnight: Fix percent display on manabars being stuck at 0-1 instead of 0-100.
- Midnight: Fix DR Black Border setting being white.

# sArena Reloaded 2.4.3b
## New
- Color Trinket: Keep Original Texture; Instead of replacing the texture entirely with a solid color keep the original texture but tinted in a color.
## Bugfix
- Midnight: Fix Color Trinket setting not working due to a last minute change and mistake in the logic for it.

# sArena Reloaded 2.4.3
## New
- Show Target Text on Castbar setting (Layout -> Castbars). On Midnight this shows True Target with new API, on older classic versions this will just show the units target and not neccesarily where the spell is going due to macros etc so I would only use this on Midnight tbh but the option is there anyway.
- Trinket used sound effect (Global -> Trinkets). Can be customized for healer/dps.
- Hide Manabar and Hide Manabar: Keep healer mana shown settings. (Layout -> Arena Frames)
- Added DR setting for "Only show DR's I can trigger" (Global -> DR)
- Hide castbars setting (Layout -> Castbars).
- Midnight: Added setting to hide DR's (Global -> DR). (On classics you can do this by unchecking DR categories)
- Added "Enable/Disable all" buttons for Racials (Global -> Racials). Also noted down on Midnight that racial cd's cannot be tracked anymore, only shared CD with trinket can be tracked (if trinket is used first).
- Allow negative spacing value on frame spacing setting for some layouts having a little gap even with 0 set as spacing.
- Force Castbar Text Width setting, on by default now and makes it so castbar text doesnt overflow the width of the castbar. (Layout -> Text Settings)
## Tweak
- On stealth player healthbar no longer jump up to 100% but instead remain at what they were when they stealthed.
## Bugfix
- Fix issues with Trinket etc not working properly due to ElvUI's setting to disable default arena frames. Will be fixed automatically but require a reload.
- Fix some problems with the frames not being fully visible in spawn room all the time.
- Fix some issues with trinket cooldown going off despite enemy not having trinket
- Fix some issues with racial cooldown (when triggered by shared CD) kept triggering multiple times.
- Fix some misconfiguration issues behind the scenes. This is a lot of small changes everywhere in the addon so potential for a little mishap if there's something I've missed.