7DTD 3.0 Wasteland Animal Population Tuning
Advanced command-line fallback tools

Purpose

This folder is for fallback console installs only.

Most users should go back one folder and double-click:

7DTD_WastelandAnimalTuning.bat

Operational model

Normal path

The graphical tool is the normal installer. It writes the animal values
chosen with the checkboxes and sliders.

Fallback path

The command-line installer is a fallback. It is intentionally simple.

It does not:

- use the GUI sliders
- remember GUI choices
- accept tuning switches
- calculate new animal values
- merge with other mods

It does:

- find or ask for the 7 Days to Die game folder
- create the game's Mods folder if needed
- copy the packaged modlet exactly as shipped

Input

..\BitWrecked_7DTD_WastelandAnimalPopulationTuning

Output

<7 Days To Die>\Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning

Reinstall behavior

If the target mod folder already exists, the installer overwrites files
inside that same target mod folder.

It does not remove other mod folders.

Rollback

Use:

Uninstall_7DTD_WastelandAnimalPopulationTuning.bat

That removes only:

<7 Days To Die>\Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning

Files

Install_7DTD_WastelandAnimalPopulationTuning.bat
Runs the fallback installer.

Uninstall_7DTD_WastelandAnimalPopulationTuning.bat
Runs the fallback uninstaller.

Safety boundary

These scripts do not edit:

Data\Config
saves
world files
7DaysToDie.exe
other game EXEs
the Windows registry
network settings

They only copy or remove:

<7 Days To Die>\Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning
