# Recipe: 7DTD 3.0 Wasteland Animal Population Tuning

Version: 4.0.1

Tune Wasteland animal density and animal mix in 7 Days to Die.

This can make Wasteland animal pressure lower, normal, higher, or intentionally absurd. Animals stay inside the normal Wasteland open-world spawn system.

Dense and Absurd settings can add extra Bit Wrecked route handles for selected animals. That gives high settings real density leverage instead of only changing one vanilla spawn line.

This recipe is for Windows 11 / Steam / current 7 Days to Die 3.0-era installs like the Bit Wrecked test machine.

It is not written for console, old Alpha versions, or non-Steam installs.

## Legal And Use Notes

This is an unofficial XML-only fan mod for 7 Days to Die.

License baseline:

```text
GPL-3.0-or-later
```

You may copy, change, and share it. If you redistribute it, keep the same license freedoms. Credit to Bit Wrecked is appreciated.

Use it at your own risk. Keep a backup of saves you care about, and follow server rules for multiplayer.

Full license, plain-language notes, and upload history are here:

```text
LICENSE_NOTICE.md
LICENSE.txt
LEGAL_AND_USE.md
RELEASE_NOTES.md
CHANGELOG.md
BUILD_STORY_AND_QA_RUNBOOK.md
```

Known issues, current review notes, and community-feedback copy are in:

```text
PUBLISHING_SEO.md
```

Please include a known-issues note when uploading publicly. The tone should be transparent and welcoming: this is a community mod, not a competition. Reports from different machines, servers, and mod lists are useful.

## Publishing / SEO

Use this if you post the download on YouTube, GitHub, Facebook, or a mod page.

Title:

```text
7DTD 3.0 Wasteland Animal Population Tuning - XML Mod
```

Short description:

```text
7DTD 3.0 Wasteland Animal Population Tuning is a small XML-only mod that lets you tune Wasteland animal density and animal mix. Built for Windows 11, Steam, and current 7 Days to Die 3.0-era installs.
```

Search tags:

```text
7 Days to Die mod, 7DTD mod, 7 Days to Die 3.0 mod, Wasteland animal population tuning, Wasteland animal tuning, fewer dire wolves, fewer zombie bears, reduce dire wolf spawns, reduce zombie bear spawns, 7DTD XML mod, 7DTD modlet, Bit Wrecked
```

Download wording:

```text
Download the zip, unzip it, double-click 7DTD_WastelandAnimalTuning.bat, check the animals you want to tune, then click Install Mod. Use `Scan Values` to compare current and selected values. For single-player modded play, launch without Easy Anti-Cheat.

**Default:** vanilla baseline values. Sliders start at game values.
```

## Ingredients

You need:

- Windows 11
- Steam
- Notepad
- 7 Days to Die
- About 10 minutes

You will make:

```text
7 Days To Die/
+-- Mods/
    +-- BitWrecked_7DTD_WastelandAnimalPopulationTuning/
        +-- ModInfo.xml
        +-- Config/
            +-- entitygroups.xml
            +-- spawning.xml
```

## What This Recipe Does

The game uses text files for many rules.

This recipe adds a small mod folder. When the game starts, it reads that folder and changes Wasteland animal density plus the animal mix.

The tool writes two XML files:

```text
entitygroups.xml = which Wasteland animals are picked
spawning.xml     = how many Wasteland animal rolls can happen
```

At `Dense` and `Absurd`, `spawning.xml` can also append extra Bit Wrecked selected-animal routes with `bw_` IDs.

## What The Slider Words Mean

The tool has five positions:

```text
Absent  = removes selected animal pressure
Sparse  = about half selected animal pressure
Default = vanilla baseline
Dense   = strong selected animal pressure
Absurd  = extreme selected animal pressure
```

`Default` installed should feel like no mod for the tuned Wasteland animal routes. It writes the same live game baseline numbers back through the modlet.

`Remove Mod` is different. It deletes the Bit Wrecked mod folder. That changes
the effective XML configuration by making the affected routes use the game's
default files directly. It does not restore `serverconfig.xml`.

`Sparse` was retuned from an older quarter-strength value to a half-strength value. That keeps it from acting like "almost gone" while still reducing pressure.

## Step 1: Open The Game Folder

1. Close 7 Days to Die.
2. Open Steam.
3. Right-click `7 Days to Die`.
4. Click `Manage`.
5. Click `Browse local files`.

You should now be in the main game folder.

Common location:

```text
C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die
```

## Easiest Install: Use The Installer

Use this file for the normal Windows download:

```text
7DTD_WastelandAnimalPopulationTuning_FullPackage.zip
```

It includes the graphical tool, docs, license files, and the modlet.

1. Unzip the download.
2. Read `README_FIRST.txt`.
3. Double-click the graphical tool:

```text
7DTD_WastelandAnimalTuning.bat
```

That is the only top-level file normal users need to click.

The support files are kept here:

```text
Support_Files_Do_Not_Edit
```

Most users do not need to open that folder.

4. Look at the animal tuning table.
5. Check one or more animals to install or retune them.
6. Use `All` to select and tune every listed animal together.
7. Move sliders left toward `Absent` or right toward `Absurd`.
8. Click `Install Mod`.
9. Read the verification message. It tells you the XML numbers that were written and what the choice means for gameplay.
10. If it is already installed, the same button will say `Reinstall Mod`.
11. Click `Validate Current Game Settings` any time to read and compare the
    current configuration. It does not modify game, mod, or server settings.
    If Persistent log is enabled, the displayed report is also written to the
    chosen text log.

**Default:** vanilla baseline values.

The middle slider position, `Default`, uses the current game XML value as the baseline.

For density timing, `Default` preserves the game's live `respawndelay` decimal strings exactly. It does not round or normalize those values.

An unchecked installed animal is pending uninstall and will return to its
game-default values when the bottom action is confirmed. An unchecked animal
that is not installed stays unchanged. Checking or clearing a box alone does
not write files.

The tool shows day and night XML numbers before install and verifies the written numbers after install.

The Bit Wrecked tool can also remove the mod, open your `Mods` folder, or close without changing anything.

If a saved global-limit backup differs from the current value, the bottom action
can become `Restore Global Limit Only`. Confirming it replaces
`serverconfig.xml` with the newest matching Bit Wrecked backup and verifies the
restored value. It is not a generic reset to 50.

Most users should ignore `Advanced_CommandLine`. It is only a fallback.

### What The BAT Files Do

```text
7DTD_WastelandAnimalTuning.bat
```

Opens the graphical tool. This is the normal path. It writes the animal values you choose with the checkboxes and sliders.

```text
Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.bat
```

Fallback only. It copies the packaged modlet exactly as shipped. It does not read GUI slider choices and does not accept tuning switches.

Think of this as a fixed package deploy:

```text
Input:
Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning

Output:
7 Days To Die/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

If the target mod folder already exists, it overwrites files inside that same mod folder. It does not merge with other mods and does not remove other mod folders.

```text
Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.bat
```

Fallback only. It removes only this folder from `Mods`:

```text
BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

If the graphical tool does not work, use the advanced command-line installer:

```text
Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.bat
```

If Windows asks, allow it to run. The installer will look for the normal Steam install folder. If it cannot find it, paste your 7 Days to Die folder path.

To remove the mod later, double-click:

```text
Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.bat
```

The manual steps below do the same thing by hand.

## Vortex / Mod Manager Download

Use this file for Vortex or other mod managers:

```text
7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip
```

It contains only the modlet folder:

```text
BitWrecked_7DTD_WastelandAnimalPopulationTuning/
+-- ModInfo.xml
+-- Config/
    +-- entitygroups.xml
    +-- spawning.xml
```

That is the shape mod managers want: `ModInfo.xml` directly inside the mod folder, with XML patch files under `Config`.

If you want the Bit Wrecked graphical installer, use the full package instead.

## Why Vortex, Nexus, Or Antivirus May Warn

The modlet itself is XML-only. The Vortex/mod-manager zip contains only:

```text
ModInfo.xml
Config/entitygroups.xml
Config/spawning.xml
```

Those files are text files. They do not execute code.

The full Windows package is different. It includes convenience helper files so normal Windows users can install, remove, scan, and tune the mod without manually copying XML:

```text
7DTD_WastelandAnimalTuning.bat
Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1
Support_Files_Do_Not_Edit/Advanced_CommandLine/*.bat
Support_Files_Do_Not_Edit/Advanced_CommandLine/*.ps1
```

Some upload scanners and antivirus systems treat `.bat` and `.ps1` files as suspicious even when the scripts are plain text and harmless. That is usually heuristic detection: the scanner sees "a script that can change files" and warns before it understands the specific purpose.

This package can trigger that kind of warning because the helper scripts do normal installer work:

- launch PowerShell from a batch file
- use `ExecutionPolicy Bypass` for this one process so the local unsigned script can run
- open a Windows Forms graphical interface
- find the Steam 7 Days to Die folder
- create or update `Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning`
- copy XML modlet files into the game's `Mods` folder
- remove that mod folder if you choose uninstall
- optionally back up and edit `serverconfig.xml` when Brutal Science animal cap is enabled
- optionally restore `serverconfig.xml` from the newest Bit Wrecked animal-cap backup
- rebuild release zips when the maintainer validation harness is run

Those behaviors are expected for a mod installer, but they overlap with behaviors that scanners watch closely. That is why a mod site may label the full package as a possible virus or "suspicious script" even though the shipped mod content is XML.

What this package does not include:

- no `.exe` file
- no `.dll` file
- no Harmony patch
- no compiled binary payload
- no network downloader
- no hidden updater
- no game executable patcher
- no save-file editor
- no registry edits

What you can do before running it:

1. Open the `.bat` and `.ps1` files in Notepad.
2. Confirm they are readable text scripts.
3. Use the Vortex/mod-manager zip if you only want XML and do not want helper scripts.
4. Download only from the official Bit Wrecked upload location you trust.
5. Do not run repacked copies from random mirrors.

If your security tool blocks the full package and you do not want to allow it, use the Vortex/mod-manager zip or install manually from the XML files. The game mod itself does not require the Windows helper tool.

## Brutal Science Animal Cap

`Brutal Science: lift global animal cap` is optional.

When enabled, the tool can set this server setting:

```text
serverconfig.xml
MaxSpawnedAnimals = 999
```

Brutal Science does not create animals by itself. It removes a global throttle so eligible Wasteland animal routes are less likely to be capped.

At Default tuning, lifting the cap may not feel very different because vanilla routes are still modest.

At Dense or Absurd, especially over time in loaded Wasteland areas, pressure can become much stronger. The game still has normal despawn, timer, and cleanup behavior, but the lifted cap gives the world more room to keep active animals around before throttling. Treat this as an event/testing switch, not a normal default.

Before changing `serverconfig.xml`, the tool creates a timestamped backup beside it:

```text
serverconfig.BitWreckedAnimalCapBackup-yyyyMMdd-HHmmss.xml
```

`Remove Mod` deletes the Bit Wrecked modlet folder, returning affected Wasteland
routes to game-default XML behavior. It does not change `serverconfig.xml`.

To undo the tool's global-limit change, uncheck
`Raise Animal Spawn Cap - Brutal Science` and
use `Restore Global Limit Only` when offered. The tool replaces
`serverconfig.xml` with the newest matching Bit Wrecked backup, then verifies
`MaxSpawnedAnimals`.

This is separate on purpose: removing XML mod files and restoring a server/world cap are different operations.

## Step 2: Make The Mods Folder

1. Look for a folder named `Mods`.
2. If it already exists, open it.
3. If it does not exist, right-click empty space.
4. Click `New`.
5. Click `Folder`.
6. Name it `Mods`.
7. Open `Mods`.

## Step 3: Make The Mod Folder

Inside `Mods`:

1. Right-click empty space.
2. Click `New`.
3. Click `Folder`.
4. Name it `BitWrecked_7DTD_WastelandAnimalPopulationTuning`.
5. Open `BitWrecked_7DTD_WastelandAnimalPopulationTuning`.

You should be here:

```text
7 Days To Die/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning/
```

## Step 4: Make ModInfo.xml

This file tells the game the mod exists.

Inside `BitWrecked_7DTD_WastelandAnimalPopulationTuning`:

1. Right-click empty space.
2. Click `New`.
3. Click `Text Document`.
4. Name it `ModInfo.xml`.
5. If Windows warns you about changing the file extension, click `Yes`.
6. Right-click `ModInfo.xml`.
7. Click `Open with`.
8. Click `Notepad`.
9. Delete anything already in the file.
10. Paste this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xml>
  <Name value="BitWrecked_7DTD_WastelandAnimalPopulationTuning"/>
  <DisplayName value="7DTD 3.0 Wasteland Animal Population Tuning"/>
  <Description value="Tunes Wasteland animal density and animal mix using XML-only spawn and entitygroup patches."/>
  <Author value="Bit Wrecked"/>
  <Version value="4.0.1"/>
  <Website value=""/>
</xml>
```

11. Click `File`.
12. Click `Save`.
13. Close Notepad.

Important: the file must be named:

```text
ModInfo.xml
```

Not:

```text
ModInfo.xml.txt
```

## Step 5: Make The Config Folder

Inside `BitWrecked_7DTD_WastelandAnimalPopulationTuning`:

1. Right-click empty space.
2. Click `New`.
3. Click `Folder`.
4. Name it `Config`.
5. Open `Config`.

You should be here:

```text
7 Days To Die/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/
```

## Step 6: Make entitygroups.xml

This file holds the Wasteland animal mix numbers.

Inside `Config`:

1. Right-click empty space.
2. Click `New`.
3. Click `Text Document`.
4. Name it `entitygroups.xml`.
5. If Windows warns you about changing the file extension, click `Yes`.
6. Right-click `entitygroups.xml`.
7. Click `Open with`.
8. Click `Notepad`.
9. Delete anything already in the file.
10. Paste this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configs>
  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalSnake']/@p">10</set>
  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieVulture']/@p">5</set>
  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieDog']/@p">15</set>
  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieBear']/@p">5</set>
  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalDireWolf']/@p">2</set>

  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalDireWolf']/@p">4</set>
  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalZombieBear']/@p">10</set>
</configs>
```

11. Click `File`.
12. Click `Save`.
13. Close Notepad.

Those numbers are the game baseline animal-mix values. Use the graphical tool for density tuning.

## Step 6B: Make spawning.xml

This file changes Wasteland animal density.

Inside `Config`, make another file named:

```text
spawning.xml
```

Paste this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configs>
  <set xpath="/spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWasteland']/@maxcount">1</set>
  <set xpath="/spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWasteland']/@respawndelay">0.9,1.575,1.215,0.9,0.585,0.315</set>

  <set xpath="/spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWastelandNight']/@maxcount">1</set>
  <set xpath="/spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWastelandNight']/@respawndelay">0.6,1.05,0.81,0.6,0.39,0.21</set>
</configs>
```

The graphical tool may add an `<append>` block to this file for high-density selected-animal choices.

Important: the file must be named:

```text
spawning.xml
```

Not:

```text
spawning.xml.txt
```

## Step 7: Check Your Work

Your folders should look like this:

```text
7 Days To Die/
+-- Mods/
    +-- BitWrecked_7DTD_WastelandAnimalPopulationTuning/
        +-- ModInfo.xml
            +-- Config/
            +-- entitygroups.xml
            +-- spawning.xml
```

Correct:

```text
Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml
Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml
Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/spawning.xml
```

Wrong:

```text
Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning/BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml
Mods/Config/entitygroups.xml
Mods/ModInfo.xml
ModInfo.xml.txt
entitygroups.xml.txt
```

## Step 8: Start The Game

Start 7 Days to Die.

The Wasteland animal pressure should follow your chosen density and mix.

If the game shows XML errors when it starts, close the game and delete this folder:

```text
Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

Then start the game again. That removes the mod.

## Install Mode Guide

Use the block that matches how you play.

### Mode 1: Single-Player On Your PC

Environment:

```text
Your PC runs the game and the world.
```

Install here:

```text
Your 7 Days To Die/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

What to do:

1. Put `BitWrecked_7DTD_WastelandAnimalPopulationTuning` in your local `Mods` folder.
2. Launch the game without Easy Anti-Cheat for the simplest modded setup.
3. Play your world.

Result:

```text
Your local Wasteland animal rolls use the mod.
```

### Mode 2: You Host A Multiplayer Game From Your PC

Environment:

```text
Your PC is the host.
Friends join your game.
```

Install here:

```text
Your 7 Days To Die/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

What to do:

1. The host installs the mod.
2. The host launches without Easy Anti-Cheat for the simplest modded setup.
3. Friends join using settings that match the host.

Result:

```text
The hosted world uses the mod.
```

### Mode 3: Dedicated Server

Environment:

```text
A separate server runs the world.
Players connect to that server.
```

Install here:

```text
Server 7 Days To Die/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

What to do:

1. Stop the server.
2. Put `BitWrecked_7DTD_WastelandAnimalPopulationTuning` in the server's `Mods` folder.
3. Start the server.
4. Make sure player Easy Anti-Cheat settings match the server.

Result:

```text
The server controls the Wasteland animal rolls.
```

Because this mod is XML-only and adds no custom assets, DLLs, or scripts, players usually should not need to install it separately when joining a properly configured server. The server's rules still win.

### Mode 4: You Are Joining Someone Else's Server

Environment:

```text
Someone else controls the server.
```

Install here:

```text
Do not install locally expecting it to change their server.
```

What to do:

1. Ask the server owner to install it server-side.
2. Use whatever Easy Anti-Cheat setting the server requires.

Result:

```text
Your local copy does not control another person's server spawns.
```

## How To Change The Strength

Open:

```text
Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml
```

Lower number means less likely.

Example:

```xml
<set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalDireWolf']/@p">2</set>
```

Change `2` to `1` to make daytime Wasteland dire wolves even less common.

Raise the number to make them more common again.

## Dire Wolf Only Version

If you only want fewer dire wolves, use this as the whole `entitygroups.xml` file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configs>
  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalDireWolf']/@p">2</set>
  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalDireWolf']/@p">4</set>
</configs>
```

## Zombie Bear Only Version

If you only want fewer zombie bears, use this as the whole `entitygroups.xml` file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configs>
  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieBear']/@p">5</set>
  <set xpath="/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalZombieBear']/@p">10</set>
</configs>
```

## How To Undo It

1. Close the game.
2. Open the `Mods` folder.
3. Delete this folder:

```text
BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

4. Start the game again.

## What This Does Not Change

This changes Wasteland open-world animal routes.

It does not change:

- animals placed inside a POI
- sleeper animals
- quest-triggered spawns
- blood moon hordes
- zombie spawn rates
- animal spawns in other biomes
- someone else's multiplayer server

For multiplayer, this needs to be installed on the server.

## Anti-Cheat Note

The game modlet is XML-only.

It does not include:

- DLL files
- EXE files
- Harmony code
- custom scripts

That makes it much safer than code-based mods.

For the simplest modded single-player setup, launch 7 Days to Die without Easy Anti-Cheat.

In Steam, use the launcher option that starts the game without EAC.

Do not promise that every server will allow every mod. For multiplayer, the server's rules win, and your EAC setting must match the server.

If Easy Anti-Cheat complains, close the game and delete:

```text
Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

Then start the game again.

If joining a server, use whatever EAC setting that server requires.

## Admin Validation Harness

For maintainers, this packet includes a PowerShell harness:

```text
validate_and_package.ps1
```

Run it from the game folder:

```powershell
.\_game_dev_ai_tracking\solutions\7dtd_wasteland_animal_population_tuning_files\Support_Files_Do_Not_Edit\validate_and_package.ps1 -RebuildZip
```

It checks:

- mod folder shape
- XML parse
- `ModInfo.xml` metadata
- live Wasteland spawn routes
- patch XPath matches live `Data/Config/entitygroups.xml`
- locked `e/n/p` XPath shape
- zip contents

## Maintainer Metadata

Internal routing, baseline intent, validation date, and AI helper notes are stored here:

```text
PACKAGE_METADATA.md
```

Technical proofing notes for every shipped file are stored here:

```text
TECHNICAL_FILE_MANIFEST.md
```
