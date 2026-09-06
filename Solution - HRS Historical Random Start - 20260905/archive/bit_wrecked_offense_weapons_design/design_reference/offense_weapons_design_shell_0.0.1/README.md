# Offense Weapons Design Shell

This is a runnable, payload-free weapons-design shell. It mirrors the visual
structure of the completed Wasteland Animal Population Tuning 4.1.1 tool:
brand header, status card, game-folder chooser, five-column central workspace,
lower action bar, and expandable layered-reasoning log.

It demonstrates the safe starting state for the new Offense Weapons mod:

* Choose a 7 Days to Die game folder
* Inspect that folder without modifying it
* Show a runtime activity log
* Preserve the exact empty row space where future effect groups and weapon rows
  will be built
* Explain why installation is disabled until a line-item map and payload exist

It intentionally does not:

* Create a modlet
* Write XML
* Create a Mods folder
* Install, uninstall, package, or publish anything
* Include any animal, weapon, loot, trader, or other gameplay feature

The visible empty center is intentional. It is not a missing implementation;
it is the reserved design surface for the future weapon tool set.

## Run

Double-click `Blank_BitWreckedMod.bat`, or run
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
