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