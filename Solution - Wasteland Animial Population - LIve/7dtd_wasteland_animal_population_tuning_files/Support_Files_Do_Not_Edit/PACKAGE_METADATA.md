# 7DTD 3.0 Wasteland Animal Population Tuning - Package Metadata

This file is for maintainers, repository routing, and AI assistants. It is not required reading for players.

## Document Control

- Package name: 7DTD 3.0 Wasteland Animal Population Tuning
- Internal package ID: BitWrecked_7DTD_WastelandAnimalPopulationTuning
- Public display name: 7DTD 3.0 Wasteland Animal Population Tuning
- Author / channel: Bit Wrecked
- Package version: 4.0.1
- Documentation baseline date: 2026-07-07
- Validation baseline: Windows 11 / Steam / current 7 Days to Die 3.0-era install
- Primary user guide: `README_WINDOWS.md`
- Release notes: `RELEASE_NOTES.md`
- Publishing copy: `PUBLISHING_SEO.md`
- Technical file manifest: `TECHNICAL_FILE_MANIFEST.md`
- Build story and QA runbook: `BUILD_STORY_AND_QA_RUNBOOK.md`
- Changelog: `CHANGELOG.md`
- License notice: `LICENSE_NOTICE.md`
- Full license: `LICENSE.txt`
- Legal and use notes: `LEGAL_AND_USE.md`
- Validation harness: `validate_and_package.ps1`
- UI branding asset: `Assets/bit-wrecked-channel-avatar.png`
- Public cover image: `Assets/nexus-cover-1280x720.png`
- Public square thumbnail: `Assets/nexus-thumbnail-1024x1024.png`
- Generated cover background source: `Assets/nexus-cover-background-generated.png`
- Full user package: `Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_FullPackage.zip`
- Nexus scanner-friendly package: `Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_Nexus_NoScripts.zip`
- Vortex / mod-manager package: `Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip`

## Baseline Intent

Tune Wasteland animal density and animal mix without directly editing game files.

The solution changes Wasteland animal weighted selection and Wasteland animal spawn-route density. Dense and Absurd settings can add extra Bit Wrecked selected-animal route handles with `bw_` IDs. It does not change POI sleeper placement, blood moon hordes, quest-triggered spawns, or other biomes.

Current five-position scale:

```text
Absent  = 0x selected animal pressure
Sparse  = 0.5x selected animal pressure
Default = live vanilla baseline
Dense   = 3x selected animal pressure plus high-end route support
Absurd  = 8x selected animal pressure plus extreme route support
```

Default installed should match the live Wasteland animal baseline values. Remove Mod is the clean untouched comparison state.

Brutal Science only lifts `MaxSpawnedAnimals`; it does not create animals by itself. It is a separate cap throttle from the XML route and animal-weight tuning.

## Source Of Truth

The verified XML patch is:

```text
BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml
BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/spawning.xml
```

The live game files used for validation are:

```text
Data/Config/entitygroups.xml
Data/Config/spawning.xml
```

Every shipped file is described for proofing here:

```text
TECHNICAL_FILE_MANIFEST.md
```

## Locked Drift Decision

This baseline uses the current 3.0-era entitygroup shape:

```xml
<e n="animalDireWolf" p="2" />
```

Use XPath targets shaped like this:

```text
/e[@n='animalDireWolf']/@p
/e[@n='animalZombieBear']/@p
```

Do not rewrite this package to use older or different shapes unless the target install proves those shapes are live:

```text
/entity[@name='animalDireWolf']/@prob
/entity[@name='animalZombieBear']/@prob
```

## Target Audience

- Windows 11 players
- Steam installs
- Current 7 Days to Die 3.0-era installs matching the Bit Wrecked test machine
- Beginner users who prefer a click-to-install package
- Server owners who understand where their server `Mods` folder lives

## Out Of Scope

- Console installs
- Old Alpha-era installs
- Non-Steam install routing
- Overhaul compatibility guarantees
- Direct editing of live game `Data/Config` files
- Universal Easy Anti-Cheat promises

## Legal Routing

License baseline:

```text
GPL-3.0-or-later
```

Use the plain-language guardrails in:

```text
LICENSE_NOTICE.md
LEGAL_AND_USE.md
```

Public summary:

```text
Unofficial XML-only fan mod for 7 Days to Die. Licensed GPL-3.0-or-later. Use at your own risk. You may copy, change, and share it. Credit to Bit Wrecked is appreciated. Do not claim modified versions are official Bit Wrecked releases.
```

## Install Routing

Full package download:

```text
Use Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_FullPackage.zip for normal Windows users.
It includes the GUI tool, docs, license files, and the modlet folder.
If a site manually approves helper scripts or allows tool packages, this is the complete GPL source/tool package.
If a site's automated scanner holds script archives, use the no-scripts Nexus package as the main public file and offer the full helper package separately only after manual review.
```

Nexus scanner-friendly download:

```text
Use Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_Nexus_NoScripts.zip as the safe main Nexus file when scripts are blocked or pending review.
It contains only the XML modlet plus text documentation and license files.
It intentionally excludes PowerShell scripts, batch launchers, EXE/DLL files, installer binaries, and other executable-style extensions.
```

Vortex / mod-manager download:

```text
Use Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip for Vortex-style installs.
It contains only BitWrecked_7DTD_WastelandAnimalPopulationTuning/ with ModInfo.xml and Config XML patch files.
Use this only when the site allows a separate mod-manager package.
```

Single-player:

```text
Install locally under 7 Days To Die/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

Peer-hosted multiplayer:

```text
Install on the host PC.
```

Dedicated server:

```text
Install server-side under the server's 7 Days To Die/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning folder.
```

Joining someone else's server:

```text
Local install does not control that server. Ask the server owner.
```

## AI Routing Tags

```text
7DTD
7 Days to Die
7 Days to Die 3.0
Bit Wrecked
7DTD 3.0 Wasteland Animal Population Tuning
7DTD 3.0 Wasteland Animal Population Tuning
Wasteland animal tuning
dire wolf
zombie bear
animal weighting
spawn weighting
spawn density
pressure routes
selected-animal route handles
entitygroups.xml
spawning.xml
XML modlet
Windows 11
Steam
Easy Anti-Cheat note
server-side install
client-side install
beginner installer
WinForms tool
```

## Recommended AI Response Behavior

When answering player questions, lead with the simple installer:

```text
Download the zip, unzip it, read README_FIRST.txt, double-click 7DTD_WastelandAnimalTuning.bat, check the animals to tune, move sliders left toward Absent or right toward Absurd, and click Install Mod. Dense and Absurd may add extra route handles for selected animals. The full package opens with one launcher and one support folder. Default is no changes selected; sliders start at game values. Use Scan Values to compare current and selected values. If the mod is already installed, click Reinstall Mod.
```

If asked about Vortex, Nexus, or antivirus warnings:

```text
The actual 7DTD mod content is XML-only: ModInfo.xml plus Config/entitygroups.xml and Config/spawning.xml. There are no EXE files, DLL files, Harmony patches, network downloaders, hidden updaters, registry edits, scheduled tasks, services, startup entries, or game executable patches.

The full helper package includes readable Windows .bat and .ps1 scripts for beginner install/uninstall, scan/verify, package validation, and optional serverconfig.xml backup/edit/restore for the Brutal Science animal cap. Automated scanners may warn because scripts can copy/remove files and one launcher uses process-local ExecutionPolicy Bypass to run the local readable tool without changing the user's system policy.

For Nexus, prefer the no-scripts archive as the main file when a scanner hold occurs. Offer the full helper package only after manual review or as a separate source/tool package. The GPL-3.0-or-later license is intentional: the source, scripts, docs, and validation flow are visible for review and redistribution under the license.
```

If asked about known issues or community feedback:

```text
Be transparent and welcoming. Mention the current known review notes: Default precision was fixed but deserves clean gameplay confirmation, Dense/Absurd can be limited by the global animal cap, Brutal Science edits serverconfig.xml with backup/restore, Remove Mod and Restore Cap are separate actions, Vortex users may prefer the modlet folder only, and screenshot examples are still being curated. Ask users to report tuning level, Brutal Science state, single-player/server, other spawn/gameplay mods, and expected versus observed behavior. This is a community mod, not a competition.
```

When answering admin or maintainer questions, mention:

- XML-only modlet
- validated `e/n/p` XPath shape
- Wasteland groups `EnemyAnimalsWasteland` and `EnemyAnimalsWastelandNight`
- Wasteland spawn routes in `spawning.xml`
- extra selected-animal `bw_` pressure routes at Dense and Absurd
- server-side install for dedicated servers
- EAC setting must match the user's play mode or server

## Validation

Run from the game root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File _game_dev_ai_tracking\solutions\7dtd_wasteland_animal_population_tuning_files\Support_Files_Do_Not_Edit\validate_and_package.ps1 -RebuildZip
```

Expected result:

```text
PASS: 7DTD 3.0 Wasteland Animal Population Tuning modlet is valid for this live install.
```

Optional GUI paint smoke test:

```powershell
powershell -Sta -NoProfile -ExecutionPolicy Bypass -File _game_dev_ai_tracking\solutions\7dtd_wasteland_animal_population_tuning_files\Support_Files_Do_Not_Edit\7DTD_WastelandAnimalPopulationTuning_Tool.ps1 -SmokeTest
```
