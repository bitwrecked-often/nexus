# Mod Framework Design Shell

This is a runnable, payload-free shell for a new Bit Wrecked mod. It carries
the polished visual structure of the completed Wasteland Animal Tuning tool,
but has no mod-specific rows or behavior.

It demonstrates the safe starting state for a new mod:

* Choose a 7 Days to Die game folder
* Inspect that folder without modifying it
* Show a runtime activity log
* Keep a five-column center workspace intentionally empty until a line-item
  map defines the new mod's feature groups and rows
* Explain why installation is disabled until a line-item map and payload exist

It intentionally does not:

* Create a modlet
* Write XML
* Create a Mods folder
* Install, uninstall, package, or publish anything
* Include any animal, weapon, loot, trader, or other gameplay feature

## Run

Double-click `7DTD_ModFrameworkDesign.bat` (preferred) or
`Blank_BitWreckedMod.bat`, or run
`Blank_BitWreckedMod_Tool.ps1` from PowerShell.

The batch launcher uses `powershell.exe -NoProfile -File`; it does not download
anything, use encoded commands, alter execution policy, or request elevation.

## Turn this into a new mod

1. Copy this example into the new independent solution.
2. Copy `FRAMEWORK_NORMALIZATION_TEMPLATE.md` into the new active version lane.
3. Complete the new mod's exact line-item map.
4. Replace the neutral identity and add only the required payload rows.
5. Implement install, selective uninstall, and validation from the line-item
   ownership map.

The disabled installation button is deliberate. It becomes active only after a
new mod has a verified payload and a safe ownership/removal design.
