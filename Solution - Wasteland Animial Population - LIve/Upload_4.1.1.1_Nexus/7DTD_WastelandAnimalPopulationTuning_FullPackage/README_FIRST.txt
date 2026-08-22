7DTD 3.0 Wasteland Animal Population Tuning
Version 4.1.1

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
Remove Mod deletes this tool's installed mod folder. That removal changes the
game's effective XML configuration by returning these Wasteland routes to the
game defaults. It does not restore serverconfig.xml or the global animal limit.

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

File-operation accountability:

- Choose Game Folder only selects a location; it does not install or run anything.
- Install/Reinstall writes generated XML in this tool's owned Mods subfolder.
- Uninstalling selected animals rewrites that generated XML; uninstalling the
  final tuned animal removes the generated XML and owned mod folder. The affected
  routes then use game-default values.
- Remove Mod deletes this tool's owned mod folder. It does not restore the global cap.
- Apply Global Limit backs up and then writes serverconfig.xml.
- Restore Global Limit replaces serverconfig.xml with the newest matching backup.
- Validate reads configuration. It does not modify game, mod, or server settings.
  If Persistent log is explicitly enabled, displayed log entries are also written
  to the user-selected text file.
- Open Mods Folder creates the selected game's Mods folder if it is missing, then
  opens it in Explorer.

If a mod site only allows one upload, use the full package zip. It includes the XML modlet plus Windows helper scripts for installing, uninstalling, scanning, tuning, and optional Brutal Science serverconfig backup/restore. Some sites or antivirus tools may warn because the package contains readable .bat and .ps1 helper scripts. The game mod itself is still XML-only. If you do not want to run scripts, install only the BitWrecked_7DTD_WastelandAnimalPopulationTuning folder into your 7 Days To Die/Mods folder.

For the simplest single-player modded setup, launch 7 Days to Die without Easy Anti-Cheat.
For servers, the server's rules and EAC setting win.

License: GPL-3.0-or-later
Unofficial fan mod. Use at your own risk.
