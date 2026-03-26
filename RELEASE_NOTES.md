2.4.2c
- Add new Dissonance profile (www.twitch.tv/dissonancewow). Thank you for sharing.
- Tweak interrupt tracker logic to be more consistent. Midnight only: Include priests Silence as an "interrupt" for interrupt color.
- Tweak default position of Party Target Indicators on BlizzRaid layout.
- Clean up cooldown text settings a bit. Shouldnt make a difference to anything ingame.

2.4.2b
- Midnight: New setting in Global -> DR to Disable Instant DR Cooldown. (DR cooldown spiral wont show until cc ends/breaks)
- Midnight: Fix pixel border DR colors sometimes not applying.

2.4.2
- Fix lua error in pixel border DR coloring logic.
- Add version number to title top of /sarena

2.4.1e
- Midnight: Minor tweak to DR's due to reports of funky business that I could not replicate.

2.4.1d
- Midnight: Minor tweak to fix a DR issue.

2.4.1c
- Fix Color Trinket setting putting available color on people without a found trinket on MoP. And this color still being hardcoded green instead of respecting new settings.

2.4.1b
- Add new color settings for Color Trinket instead of just green/red.
- Fix Color Trinket on TBC/MoP not going green again when trinket is up.
- Midnight: Fix stuff for new Midnight changes.

2.4.1
- Add Jazggz profile (www.twitch.tv/jazggz). Thank you for sharing <3
- The "Party Target Indicators" Widget now also has options to show who Enemy Arena Units are targeting on your PartyFrame. Also fixed for 5v5.
- Midnight: DR Frames now show the DR cooldown immediately (and updates proper time later, similar to how Diminish used to work)
- Midnight: Fix an issue potentially causing a DR frame to disappear until DR reset.
- Midnight: Add new Reload UI warning if your Edit Mode settings did not have "Arena Frames" checked; This needs to be enabled and sArena will automatically enable it if it isnt and request a reload to avoid issues.
- Midnight: Fix potential error caused by Blizzard Edit Mode and some rare times data returning slow.
- Tweak "Show Arena Number" setting to show "Arena 1" instead of "arena1". Also add a sub-setting "ID Only" to only show the number itself.
- Added FrameSort support for "Show Arena Number" settings.
- Update and fix Saul & Snupy profile import string. Apologies :x

2.4.0b
- Fix typo causing a lua error related to the colored DR CD Text setting.

2.4.0
- You can adjust DR spacing again on Midnight.
- Refactor Midnight DR Frames handling towards a more permanent solution. (Still wish Blizzard improved on this)
  They are now custom frames again and can be adjusted the spacing of properly how they used to.
  The icons are still unfortunately super secret stuff and impossible to do anything with.
- Fix some trinket texture issues on Midnight.
- Tweak BlizzRaid default profile to use the new Target Highlight Border by default instead of icon. Slighlty tweak posiiton of some stuff too.