# sArena Reloaded 2.5.4e
## New
- Add a new "Always On" option for Party Member Target Text Widget so it works outside of Arena as well.
## Bugfix
- Fix lua error on test mode exit if Arena Target Indicators were not enabled
- Fix Arena Target Text Widget forgetting set font size on reload.

# sArena Reloaded 2.5.4d
## New
- Add Simplified and Traditional Chinese localization by vitocichen @ GitHub. Thank you for your contribution!

# sArena Reloaded 2.5.4c
## Bugfix
- Fix "Format Numbers" being turned off accidentally. You may need to double check this value in settings (Global -> Arena Frames: Status Text)
- Fix secret error related to castbar casts on Midnight resulting in various issues like castbar color/highlights/etc being off.

# sArena Reloaded 2.5.4
## New
- Pet Frames. You can now enable Pet Frames for pet classes
- Midnight: Castbar Highlight has its own group now in the Castbar layout settings with a new color setting, icon glow setting, and a "Highlight CC" option. Note that you can only chose either "Cast on me" or "CC" due to restrictions.
## Tweak
- Midnight version has the un-interruptible texture setting working again, but needs a better solution still as this isnt perfect but better than nothing.
- Castbar quick hiding should properly work again for channeled casts again (without hiding it when its been interrupted).
- Update default spell used for range check for survival hunter to hatchet toss (40yard).
## Bugfix
- Fix first time introduction screen reverting layout choice to default Gladiuish layout even after picking a different one.
- Fix an issue of castbar not changing color on gained aura mastery effects like Precog etc.
- Fix click issues in test mode preventing click and drag for widgets etc for things going over the arena frames.
- Fix ctrl+shift drag for Arena/Party Target Text.
- Fix font issue on the Party Target Text not picking up selected font.
- Fix an issue causing aura highlight glows to appear after a shuffle round if unit was stealthed when gates opened.
- Fix an error related to spec updates while in combat on TBC
- 2.5.4b: Fix secret error in castbar highlight code
## Note
- Big patch with a lot of changes to things behind the scenes to accomodate Pet Frames. Please if you run into any issues report it (especially TBC cuz very limited testing has been done there).