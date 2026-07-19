7DTD 3.0 Wasteland Animal Population Tuning
Version 4.1.0

Copyright (C) 2026 Bit Wrecked
SPDX-License-Identifier: GPL-3.0-or-later

START HERE

This is an unofficial, open-source fan mod for tuning Wasteland animal density
and animal mix in 7 Days to Die. The normal customer package contains readable
BAT, PowerShell, and XML source. It has no compiled mod code.

REQUIREMENTS

- A Windows PC with Windows PowerShell 5.1 and Windows Forms.
- An extracted copy of this package. Do not run it from inside the ZIP.
- A 7 Days to Die installation you are allowed to modify.
- Permission to write to that installation's Mods folder.

Windows 11 with a Steam client installation is the owner-observed environment.
The exact tested game build was not retained in repository evidence. The package
targets the documented 7DTD 3.0-era XML shape; dedicated-server, non-Steam,
Linux, console, Vortex, EAC, and overhaul compatibility are not claimed here.

INSTALL OR REINSTALL

1. Extract the entire ZIP to an ordinary folder.
2. Keep Support_Files_Do_Not_Edit beside 7DTD_WastelandAnimalTuning.bat.
3. Double-click 7DTD_WastelandAnimalTuning.bat.
4. Confirm the selected game folder. A normal Steam install may be detected.
5. Select at least one animal and choose its tuning level.
6. Review the settings, then choose Install Mod or Reinstall Mod.
7. Use Scan Values to compare the installed values the tool reports.
8. Restart the game and observe fresh Wasteland activity.

If the launcher or tool reports an error, stop and keep the exact error text.
Do not move individual support files or force an unrecognized game path.

WHAT THE NORMAL MOD CHANGES

The tool creates or replaces only this owned mod folder:

  Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning

The modlet uses readable Config/entitygroups.xml and Config/spawning.xml patch
files. It does not directly edit Data/Config, the game executable, or save/world
files. Other spawn or overhaul mods can overlap the same XML targets and change
the result.

TUNING LEVELS

  Absent  - removes selected animal pressure
  Sparse  - about half selected animal pressure
  Default - writes the documented vanilla baseline for the selected routes
  Dense   - strong selected animal pressure with high-end route support
  Absurd  - extreme selected animal pressure with extra route support

Default installed is intended to match the documented baseline values. Remove
Mod is the clean comparison that stops loading this modlet.

OPTIONAL ANIMAL CAP CONTROL

Brutal Science is separate from the XML tuning. If you explicitly approve it,
the tool backs up serverconfig.xml beside the original and sets
MaxSpawnedAnimals to 999. This removes a global safety rail; it does not create
animals by itself. Dense or Absurd settings with a lifted cap can stress a PC,
server, or save.

Remove Mod does not restore serverconfig.xml. If you used Brutal Science and
want the prior cap back, use Restore Cap and verify the reported value. The tool
uses the newest serverconfig.BitWreckedAnimalCapBackup-*.xml file it finds.

REMOVE THE MOD

1. Close the game or server.
2. Open the tool and choose Remove Mod.
3. Confirm that this folder is gone:

     Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning

4. Restore the animal cap separately if you changed it.
5. Restart and observe fresh Wasteland activity.

You can also remove only that named mod folder manually. Do not delete another
mod folder, Data/Config, saves, or the game installation.

SECURITY AND PRIVACY

- The BAT file launches the local PowerShell tool with NoProfile and a
  process-local ExecutionPolicy Bypass. It does not change the system policy.
- The package does not use the network, collect telemetry, write the registry,
  install a service, create a scheduled task, or add a startup entry.
- The tool can launch explorer.exe only when you ask it to open the Mods folder.
- Installation and cap changes require normal file-write permission. The tool
  does not request elevation for you.
- Do not share saves, raw logs, server files, usernames, machine names, IP
  addresses, or private messages in a public support report.

LICENSE, SOURCE, AND OFFICIAL IDENTITY

This package is free software under GPL-3.0-or-later. In plain language, you may
use, copy, study, modify, and share it, including for a fee. If you distribute a
modified covered version, keep the GPL and applicable notices, identify your
changes, and provide the preferred editable corresponding source. The complete
license in Support_Files_Do_Not_Edit/LICENSE.txt controls if this summary differs.

Support_Files_Do_Not_Edit is a convenience label for casual users, not a limit
on GPL rights. Modified packages must not be presented as official Bit Wrecked
releases. Bit Wrecked support may be limited to unchanged official packages.

Official source and project route:

  https://github.com/bitwrecked-often/nexus

An official released download should have an external SHA-256 checksum and
source commit recorded with it. A differently repacked copy is not the same
artifact unless its checksum matches.

This software is provided without warranty. Use it at your own risk. 7 Days to
Die and related names belong to their respective owners. This project is not an
official game, Nexus Mods, Steam, or platform-vendor product.
