# sArena Reloaded 2.6.7
## New
- Search feature. You can now search settings and jump to them at the very top in /sarena
## Bugfix
- Fix Class Icons showing when "Only show Auras" and similar settings were enabled after the 12.1.5 rework due to new Blizzard restrictions.

# sArena Reloaded 2.6.6
## CHANGES:
- With 12.1.5 Blizzard has now also restricted some arena specific API making it so some features can no longer work. Things related to class, and healer specific things.
- Midnight 12.1.5: These settings no longer work (but still work on Classics):
  - Keep Healer Manabar Shown (when hiding manabars for others). Layouts that had both this and Hide Manabars on now show all manabars.
  - Color Healer Green (Class Colored Frames)
  - Aura Highlight "Only on Healer"
  - Healer Texture "Class Stacking Only" (the Healer Texture now always shows on healers)
  - Healer Trinket Sound and Healer Sound File ID (every trinket plays the normal sound)
  - Trinket glow "Only on Healer" (the glow now shows on every trinket)
## Bugfix
- Fix an issue that could cause nil errors on DR updates.
- 2.6.6b: add back 12.1 to toc so addon loads on 12.1