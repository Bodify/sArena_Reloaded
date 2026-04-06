# sArena Reloaded 2.4.4b
## New
- Clique support. If you have Clique theres a new checkbox in the Click Actions tab to let Clique handle all click actions instead.
## Tweak
- Midnight: Decimals are now working again for Midnight. Temporary solution until new proper API in 12.0.5 comes.
- Midnight: Improve the Instant DR Cooldown a little bit by making it consider DR severity and do a lower time if already on DR.
## Bugfix
- Midnight: Fix issue with DR frames disappearing if DR got refreshed just as the first DR was ending. (This is not the Blizzard bug with Mass Invisibility, that one I cannot fix its on Blizzard)

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