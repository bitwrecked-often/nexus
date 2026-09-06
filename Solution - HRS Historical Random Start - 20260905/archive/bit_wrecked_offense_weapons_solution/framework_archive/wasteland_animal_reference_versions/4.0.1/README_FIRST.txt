7DTD 3.0 Wasteland Animal Population Tuning
Version 4.0.1

Start here

Double-click:

7DTD_WastelandAnimalTuning.bat

Then:

1. Pick the animals you want to tune.
2. Move sliders left toward Absent or right toward Absurd.
3. Click Install Mod.

The Support_Files_Do_Not_Edit folder must stay next to the launcher.
Most users do not need to open it.

The game modlet is XML-only and tunes Wasteland animal density and mix.
Dense and Absurd settings can add extra route handles for selected animals.
The modlet does not include EXE files, DLL files, Harmony code, or custom game scripts.
It does not edit Data/Config, saves, or game EXEs.

Default means the mod writes the same Wasteland animal values as the live game baseline.
Default installed should feel like no mod for the tuned Wasteland animal routes.
Remove Mod is the clean untouched state.

Current slider curve:

Absent  = removes selected animal pressure
Sparse  = about half selected animal pressure
Default = vanilla baseline
Dense   = strong selected animal pressure
Absurd  = extreme selected animal pressure

Brutal Science is separate. It can lift MaxSpawnedAnimals in serverconfig.xml
after making a backup. It does not create animals by itself, but it removes a
global safety rail so Dense and Absurd are less likely to be throttled. Vanilla
despawn and cleanup behavior still exists, but extreme settings can stress
hardware, servers, saves, and judgment.

If a mod site only allows one upload, use the full package zip. It includes the XML modlet plus Windows helper scripts for installing, uninstalling, scanning, tuning, and optional Brutal Science serverconfig backup/restore. Some sites or antivirus tools may warn because the package contains readable .bat and .ps1 helper scripts. The game mod itself is still XML-only. If you do not want to run scripts, install only the BitWrecked_7DTD_WastelandAnimalPopulationTuning folder into your 7 Days To Die/Mods folder.

For the simplest single-player modded setup, launch 7 Days to Die without Easy Anti-Cheat.
For servers, the server's rules and EAC setting win.

License: GPL-3.0-or-later
Unofficial fan mod. Use at your own risk.
