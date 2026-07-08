# 7DTD 3.0 Wasteland Animal Population Tuning - Technical File Manifest

This file is for proofing, review, and internal AI routing. It explains every shipped file at a technical level.

## Package Policy

- No compiled EXE files are shipped.
- No DLL files are shipped.
- No Harmony patches are shipped.
- No custom 7 Days to Die game assets are shipped.
- No game executable is patched.
- No files under `Data/Config` are edited by the installer.
- The installer only copies or removes the mod folder under `Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning`.

## Expected Zip Root

Normal Windows users should receive the full package:

```text
Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_FullPackage.zip
+-- README_FIRST.txt
+-- 7DTD_WastelandAnimalTuning.bat
+-- Support_Files_Do_Not_Edit/
    +-- README_WINDOWS.md
    +-- RELEASE_NOTES.md
    +-- CHANGELOG.md
    +-- PUBLISHING_SEO.md
    +-- PACKAGE_METADATA.md
    +-- TECHNICAL_FILE_MANIFEST.md
    +-- LICENSE_NOTICE.md
    +-- LICENSE.txt
    +-- LEGAL_AND_USE.md
    +-- 7DTD_WastelandAnimalPopulationTuning_Tool.ps1
    +-- Advanced_CommandLine/
        +-- README_ADVANCED_COMMANDLINE.txt
        +-- Install_7DTD_WastelandAnimalPopulationTuning.bat
        +-- Install_7DTD_WastelandAnimalPopulationTuning.ps1
        +-- Uninstall_7DTD_WastelandAnimalPopulationTuning.bat
        +-- Uninstall_7DTD_WastelandAnimalPopulationTuning.ps1
    +-- validate_and_package.ps1
    +-- Assets/
        +-- bit-wrecked-channel-avatar.png
        +-- nexus-cover-background-generated.png
        +-- nexus-cover-1280x720.png
        +-- nexus-thumbnail-1024x1024.png
    +-- BitWrecked_7DTD_WastelandAnimalPopulationTuning/
        +-- ModInfo.xml
            +-- Config/
            +-- entitygroups.xml
            +-- spawning.xml
```

Vortex or other mod managers should receive the modlet-only package:

```text
Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip
+-- BitWrecked_7DTD_WastelandAnimalPopulationTuning/
    +-- ModInfo.xml
    +-- Config/
        +-- entitygroups.xml
        +-- spawning.xml
```

The Vortex package intentionally excludes `.bat`, `.ps1`, docs, and license helper files. It is only the game modlet folder.

## User-Facing Documents

### `README_FIRST.txt`

What it is:

```text
Tiny top-level first-read file in the full Windows package.
```

Why it exists:

```text
Gives normal users one short instruction: double-click 7DTD_WastelandAnimalTuning.bat. Keeps the first view of the unzipped package simple.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

### `README_WINDOWS.md`

What it is:

```text
Beginner-facing Windows install guide.
```

Why it exists:

```text
Gives normal users a recipe-style install path, uninstall path, EAC note, server/client install mode guide, and fallback manual steps.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

### `RELEASE_NOTES.md`

What it is:

```text
VMware-style public release notes for the current package version.
```

Why it exists:

```text
Gives users, reviewers, maintainers, and future AI one predictable place for release identity, compatibility, install/upgrade/rollback notes, resolved issues, known issues, validation, and feedback data.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

### `CHANGELOG.md`

What it is:

```text
Version-by-version public upload history.
```

Why it exists:

```text
Tracks exactly what changed between uploads, including gameplay XML changes, installer changes, packaging changes, documentation changes, and upgrade notes.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

### `BUILD_STORY_AND_QA_RUNBOOK.md`

What it is:

```text
Maintainer-facing build story and QA runbook.
```

Why it exists:

```text
Keeps the coherent brick-by-brick history of how the app came together: live XML discovery, XML-only guardrails, slider semantics, Dense/Absurd route scaling, Scan Values, Brutal Science animal cap, default precision QA, one-package upload reality, and scanner-warning context.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

### `PUBLISHING_SEO.md`

What it is:

```text
Copy/paste publishing text for YouTube, GitHub, Facebook, or a mod page.
```

Why it exists:

```text
Keeps public title, description, tags, license wording, and Bit Wrecked branding consistent.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

### `PACKAGE_METADATA.md`

What it is:

```text
Internal package routing and baseline record.
```

Why it exists:

```text
Gives maintainers and AI assistants the version, date, target baseline, source-of-truth files, live XML shape, install routing, and drift warning.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

### `TECHNICAL_FILE_MANIFEST.md`

What it is:

```text
This file.
```

Why it exists:

```text
Explains every shipped file for proofing and trust review.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

### `Advanced_CommandLine/README_ADVANCED_COMMANDLINE.txt`

What it is:

```text
Plain text note inside the advanced fallback folder.
```

Why it exists:

```text
Prevents users from mistaking fallback console launchers for the normal graphical installer. Documents that the fallback installer copies the packaged XML as-is and does not read GUI slider choices or tuning switches.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

## License And Legal Documents

### `LICENSE_NOTICE.md`

What it is:

```text
Short license notice using SPDX identifier GPL-3.0-or-later.
```

Why it exists:

```text
Gives humans and repository tooling a clear license baseline without requiring them to read the full GPL first.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

### `LICENSE.txt`

What it is:

```text
Full GNU General Public License version 3 text.
```

Why it exists:

```text
Ships the complete license text with the package.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

### `LEGAL_AND_USE.md`

What it is:

```text
Plain-language legal, reuse, unofficial fan mod, no-warranty, and redistribution guardrail notes.
```

Why it exists:

```text
Explains the practical rules: unofficial mod, use at your own risk, copy/modify/share allowed under GPL, do not claim modified builds are official Bit Wrecked releases.
```

Technical notes:

```text
Documentation only. Does not execute. Does not change files.
```

## Clickable User Tools

### `7DTD_WastelandAnimalTuning.bat`

What it is:

```text
Small batch launcher for the graphical PowerShell installer.
```

Why it exists:

```text
Gives users one file to double-click while keeping the real logic visible in the `.ps1` file.
```

Technical behavior:

```text
Runs PowerShell with:
- NoProfile
- ExecutionPolicy Bypass for this process only
- STA mode for WinForms
- 7DTD_WastelandAnimalPopulationTuning_Tool.ps1 beside the launcher, or inside Support_Files_Do_Not_Edit in the release package
```

Writes/deletes:

```text
The batch file itself does not copy or delete mod files. It only launches the PowerShell tool.
```

Network:

```text
No network use.
```

### `7DTD_WastelandAnimalPopulationTuning_Tool.ps1`

What it is:

```text
State-aware Bit Wrecked-branded Windows Forms installer/uninstaller.
```

Why it exists:

```text
Gives beginner users a quick visual read: Bit Wrecked, 7DTD 3.0 Wasteland Animal Population Tuning, current install state, Wasteland animal tuning, and one obvious primary action.

The visual motif is intentionally minimal and rounded: rounded action buttons, a rounded status card, a rounded tuning card, and a small circular action cue on the primary install/reinstall button. Visible microcopy is kept out of the main form; legal, anti-cheat, and proofing details live in the README and package docs.
```

Technical behavior:

```text
Loads System.Windows.Forms and System.Drawing.
Draws a local WinForms interface.
Loads Assets/bit-wrecked-channel-avatar.png as a small header logo when the file is present.
Uses local WinForms drawing helpers for rounded regions and rounded borders.
Finds the default Steam game folder if present.
Lets the user browse to a game folder.
Checks for 7DaysToDie.exe before installing or uninstalling.
Shows Not installed, Installed, or Select your 7 Days to Die game folder.
Shows a Scan Values button in the install-state card.
Reads Wasteland animal entries from live Data/Config/entitygroups.xml when available.
Falls back to the known current 3.0-era Wasteland animal rows and spawn routes if live XML cannot be read.
Shows an All animals master checkbox and master slider.
When All animals is checked, all Wasteland animal rows are locked to the master slider.
When All animals is unchecked, each Wasteland animal row has its own checkbox, slider, level label, game baseline value, and selected value preview.
Unchecked animals install at game values.
Known Wasteland animal entries are Snake, Zombie vulture, Zombie dog, Zombie bear, and Dire wolf.
Slider levels are Absent, Sparse, Default, Dense, and Absurd.
Animal mix factors are 0x, 0.5x, 1x, 3x, and 8x.
The selected tuning also writes Wasteland animal spawn-density rows to Config/spawning.xml.
Density changes Wasteland animal route maxcount, respawndelay, and the `none` entry weight in the Wasteland animal groups.
Dense and Absurd can append extra Bit Wrecked selected-animal routes with `bw_` IDs for additional spawn pressure.
The default tool state is no changes selected; sliders start at game values.
Default installed writes the same target values as the live game baseline. Remove Mod is the clean untouched comparison state.
The default is called out in the tuning table labels, scan report, README, publishing copy, and package metadata.
Shows exact day/night p values for each animal row before install.
Changes the primary button between Install Mod and Reinstall Mod based on detected state.
Disables Remove Mod when the mod is not installed.
Asks for confirmation before removing the mod.
Copies BitWrecked_7DTD_WastelandAnimalPopulationTuning into the selected game's Mods folder.
Regenerates the installed Config/entitygroups.xml and Config/spawning.xml from the selected Wasteland animal tuning after copying.
Reads the installed Config XML after install and verifies every generated XPath/value pair.
Shows a post-install summary of the verified XML numbers, selected density, and expected gameplay impact.
Scan Values reads the installed Config/entitygroups.xml without changing files.
Scan Values compares installed XPath/value pairs against the current slider-generated target values.
When the mod is not installed, Scan Values shows live baseline values from Data/Config and the selected slider target that Install Mod would write.
When the mod is installed, Scan Values shows installed values from Mods and the selected slider target that Reinstall Mod would write.
Scan Values reports exact match, installed/slider mismatch, not installed, or invalid game folder through status text and the scan dialog.
Removes Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning when uninstalling.
Opens the selected Mods folder with File Explorer.
Provides a Close button that exits without changing files.
Includes a QA-only `-SmokeTest` switch that opens the real form briefly, forces rounded controls to repaint, and closes it for installer validation.
```

Writes/deletes:

```text
Creates: <game folder>/Mods
Copies: BitWrecked_7DTD_WastelandAnimalPopulationTuning -> <game folder>/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
Writes selected Wasteland animal mix to: <game folder>/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml
Writes selected Wasteland animal density to: <game folder>/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/spawning.xml
Deletes: <game folder>/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning when Remove Mod is confirmed
```

Does not touch:

```text
7DaysToDie.exe
Data/Config
Saves
World files
Registry
Network settings
```

Network:

```text
No network use.
```

### `Assets/bit-wrecked-channel-avatar.png`

What it is:

```text
Bit Wrecked channel avatar image used by the Windows GUI header.
```

Why it exists:

```text
Gives the installer recognizable Bit Wrecked branding without adding compiled code or external network requests.
```

Technical behavior:

```text
Loaded by 7DTD_WastelandAnimalPopulationTuning_Tool.ps1 from the local package folder.
Displayed in a small rounded PictureBox in the form header.
Not copied into the 7 Days to Die Mods folder.
Not referenced by game XML.
```

Writes/deletes:

```text
None.
```

Network:

```text
No network use at runtime.
```

### `Assets/nexus-cover-background-generated.png`

What it is:

```text
Generated wasteland cover-art background with no official logos and no text.
```

Why it exists:

```text
Serves as the source background for public cover and thumbnail images.
```

Technical behavior:

```text
Publishing asset only.
Not copied into the 7 Days to Die Mods folder.
Not referenced by game XML.
```

Writes/deletes:

```text
None.
```

Network:

```text
No network use at runtime.
```

### `Assets/nexus-cover-1280x720.png`

What it is:

```text
1280x720 public cover image for Nexus, GitHub releases, YouTube, or Facebook posts.
```

Why it exists:

```text
Gives users a fast visual read: Bit Wrecked, Wasteland animal tuning, XML-only, no EXE/DLL.
```

Technical behavior:

```text
Publishing asset only.
Not copied into the 7 Days to Die Mods folder.
Not referenced by game XML.
```

Writes/deletes:

```text
None.
```

Network:

```text
No network use at runtime.
```

### `Assets/nexus-thumbnail-1024x1024.png`

What it is:

```text
Square public thumbnail image for cropped mod cards or social previews.
```

Why it exists:

```text
Keeps the product readable when a site crops the cover art to a square.
```

Technical behavior:

```text
Publishing asset only.
Not copied into the 7 Days to Die Mods folder.
Not referenced by game XML.
```

Writes/deletes:

```text
None.
```

Network:

```text
No network use at runtime.
```

### `Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.bat`

What it is:

```text
Fallback batch launcher for the text-mode installer.
```

Why it exists:

```text
Gives users a simple non-GUI fallback if the graphical tool does not work.
```

Technical behavior:

```text
Runs Install_7DTD_WastelandAnimalPopulationTuning.ps1 from the same Advanced_CommandLine folder with PowerShell NoProfile and ExecutionPolicy Bypass for this process only.
```

Writes/deletes:

```text
The batch file itself does not copy or delete mod files. It only launches the PowerShell installer.
```

Network:

```text
No network use.
```

### `Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.ps1`

What it is:

```text
Text-mode installer.
```

Why it exists:

```text
Provides a simple fallback install path that can be read and run without the WinForms UI.
```

Technical behavior:

```text
Runs in advanced command-line fallback mode.
Does not read GUI slider choices.
Does not accept tuning switches.
Finds the default Steam game folder if present.
Allows the user to paste a different 7 Days to Die folder.
Checks for 7DaysToDie.exe.
Checks that the package contains BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml.
Creates the selected game's Mods folder if needed.
Copies BitWrecked_7DTD_WastelandAnimalPopulationTuning into Mods.
```

Writes/deletes:

```text
Creates: <game folder>/Mods
Copies: BitWrecked_7DTD_WastelandAnimalPopulationTuning -> <game folder>/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
Overwrites existing files in that target mod folder during reinstall
```

Does not touch:

```text
7DaysToDie.exe
Data/Config
Saves
World files
Registry
Network settings
```

Network:

```text
No network use.
```

### `Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.bat`

What it is:

```text
Fallback batch launcher for the text-mode uninstaller.
```

Why it exists:

```text
Gives users a simple non-GUI fallback removal path.
```

Technical behavior:

```text
Runs Uninstall_7DTD_WastelandAnimalPopulationTuning.ps1 from the same Advanced_CommandLine folder with PowerShell NoProfile and ExecutionPolicy Bypass for this process only.
```

Writes/deletes:

```text
The batch file itself does not remove files. It only launches the PowerShell uninstaller.
```

Network:

```text
No network use.
```

### `Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.ps1`

What it is:

```text
Text-mode uninstaller.
```

Why it exists:

```text
Provides a clear fallback removal path.
```

Technical behavior:

```text
Finds the default Steam game folder if present.
Allows the user to paste a different 7 Days to Die folder.
Targets only Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning.
Requires the user to type DELETE before removing the folder.
```

Writes/deletes:

```text
Deletes: <game folder>/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

Does not touch:

```text
7DaysToDie.exe
Data/Config
Saves
World files
Registry
Network settings
Other mod folders
```

Network:

```text
No network use.
```

## Maintainer Tool

### `validate_and_package.ps1`

What it is:

```text
Maintainer validation and zip rebuild harness.
```

Why it exists:

```text
Proves the package still matches the live tested 7 Days to Die XML structure and that required release files are present.
```

Technical behavior:

```text
Parses ModInfo.xml.
Parses the mod entitygroups.xml patch.
Parses the mod spawning.xml patch.
Parses live Data/Config/entitygroups.xml.
Parses live Data/Config/spawning.xml.
Verifies Wasteland animal spawn routes.
Verifies patch XPath targets match live entitygroups.xml and spawning.xml.
Rejects drift to entity/name/prob XPath shape.
Checks license files exist.
Checks shipped scripts/XML contain GPL/SPDX and copyright headers.
Optionally rebuilds both zip artifacts with -RebuildZip.
Verifies full package and Vortex modlet zip entries.
Extracts the rebuilt full package to a temporary folder, checks the user-facing top-level shape, and smoke-tests the GUI from the extracted copy.
```

Writes/deletes:

```text
With -RebuildZip:
- deletes the old Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_FullPackage.zip
- writes a new Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_FullPackage.zip
- deletes the old Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip
- writes a new Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip

Without -RebuildZip:
- reads files only
```

Does not touch:

```text
7DaysToDie.exe
Data/Config
Saves
World files
Registry
Network settings
Installed Mods folder
```

Network:

```text
No network use.
```

## Actual Mod Files

### `BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml`

What it is:

```text
7 Days to Die modlet metadata file.
```

Why it exists:

```text
Tells the game this folder is a modlet and identifies the mod as BitWrecked_7DTD_WastelandAnimalPopulationTuning with the public display name 7DTD 3.0 Wasteland Animal Population Tuning.
```

Technical behavior:

```text
Read by 7 Days to Die at startup when placed under the game's Mods folder.
Contains Name, DisplayName, Description, Author, Version, and Website fields.
```

Writes/deletes:

```text
None. Metadata only.
```

Network:

```text
No network use.
```

### `BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml`

What it is:

```text
7 Days to Die XML patch file.
```

Why it exists:

```text
Provides the baseline animal-mix XML patch for the package. The shipped baseline matches current Wasteland animal weighted selection values; tuning happens when the GUI writes selected values.
```

Technical behavior:

```text
Uses <set> patch operations targeting:
- /entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalSnake']/@p
- /entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieVulture']/@p
- /entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieDog']/@p
- /entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieBear']/@p
- /entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalDireWolf']/@p
- /entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalDireWolf']/@p
- /entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalZombieBear']/@p
- /entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='none']/@p
- /entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='none']/@p
```

Writes/deletes:

```text
None by itself. The game reads it at startup as a patch.
```

Network:

```text
No network use.
```

### `BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/spawning.xml`

What it is:

```text
7 Days to Die XML patch file for Wasteland animal route density.
```

Why it exists:

```text
Controls the density side of the tuning by patching Wasteland animal spawn route maxcount and respawndelay. Dense and Absurd can also append extra Bit Wrecked selected-animal pressure routes.
```

Technical behavior:

```text
Uses <set> patch operations targeting:
- /spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWasteland']/@maxcount
- /spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWasteland']/@respawndelay
- /spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWastelandNight']/@maxcount
- /spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWastelandNight']/@respawndelay

At high density, the graphical installer may also generate:
- <append xpath="/spawning/biome[@name='wasteland']">
- <spawn id="bw_adw1" ... entitygroup="animalDireWolf" />
- <spawn id="bw_nzb1" ... entitygroup="animalZombieBear" />
- additional `bw_*` selected-animal routes for Absurd density
```

Writes/deletes:

```text
None by itself. The game reads it at startup as a patch.
```

Does not change:

```text
POI sleeper animals
Quest-triggered spawns
Blood moon hordes
Zombie spawn rates
Other biomes
Game executables
```

Network:

```text
No network use.
```

## Proofing Checklist

Before publishing:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File _game_dev_ai_tracking\solutions\7dtd_wasteland_animal_population_tuning_files\Support_Files_Do_Not_Edit\validate_and_package.ps1 -RebuildZip
```

Expected result:

```text
PASS: 7DTD 3.0 Wasteland Animal Population Tuning modlet is valid for this live install.
```

Optional sandbox QA:

```text
Extract the zip to a temp folder.
Create a fake game folder containing an empty 7DaysToDie.exe.
Run installer against the fake folder.
Confirm Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning is copied.
Run installer again to verify reinstall.
Run uninstaller and confirm only Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning is removed.
```
