# sArena Reloaded 2.6.3
## New
- New "Thick Outline" setting for the Arena/Party Target Icons in Layouts: Widgets. Thanks to Mo for tweaking the texture and suggesting it!
## Tweak
- Update JFarm profile (www.twitch.tv/jfarm_)
- Midnight: Add a few extra debuffs to track on auras (Havoc, Scorpid Sting (Hunter Chimereal Sting 90% slow leading up to silence after) and Dark Simulacrum)

# sArena Reloaded 2.6.2e
## Tweak
- Fix a Blizzard bug causing breath bar (and other similar bars) to stay hidden with sArena Reloaded enabled due to sArena opening Edit Mode on login. Blizzard hides this bar when opening Edit Mode and they never re-show it... GG.
- Improve cooldown text on auras, should now always display no matter how short the aura is (ancient bug with really short auras not showing duration now easily fixable with new API)
- Cleanup old cooldown text handling in sArena but mostly for classics. No longer uses workarounds for milliseconds but instead uses proper new API from Blizzard.
- OmniCC Headsup: The cooldown changes/fixes for classics probably wont be in effect if you are using OmniCC. Unsure how that handles it but it is added from my side here at least, might need changes in OmniCC for it to be sorted there as well /shrug.