# 7DTD 3.0 Wasteland Animal Population Tuning - Publishing SEO

Use this text when posting the download on YouTube, GitHub, Facebook, or a mod page.

## Title

```text
7DTD 3.0 Wasteland Animal Population Tuning Harness
```

## Short Description

```text
XML-only 7DTD 3.0 tuning harness for Wasteland animal population, density, and mix. Includes a Windows tool, scan/verify flow, and selected-animal Dense/Absurd pressure routes. No EXE/DLL; built for Windows 11 Steam installs.
```

## Longer Description

```text
This Bit Wrecked tuning harness adjusts Wasteland animal density and animal mix in 7 Days to Die. Dire wolves, zombie bears, zombie dogs, zombie vultures, and snakes can be pushed from absent/sparse up to dense/absurd Wasteland pressure. High-density settings can add extra Bit Wrecked route handles for selected animals.

The full package includes a simple Windows tool for tuning Wasteland animal pressure, plus the XML modlet folder for manual or mod-manager installs. Default is no changes selected; sliders start at game values. Scan Values compares current and selected values. The validation harness checks live XML targets and package shape before upload. If a mod site only allows one file, upload the full package zip. XML-only game mod: no DLL files, EXE files, Harmony code, or compiled game code.

Some mod sites or antivirus tools may warn because the full package contains readable Windows helper scripts, including `.bat` and `.ps1` files. Those scripts launch the installer, copy/remove the modlet folder, scan values, and optionally back up/edit or restore `serverconfig.xml` for the Brutal Science animal cap. The actual 7DTD mod content is XML under `ModInfo.xml` and `Config/`.

Unofficial fan mod. Licensed GPL-3.0-or-later. Use at your own risk. You may copy, change, and share it. Credit to Bit Wrecked is appreciated.
```

## Known Issues / Community Feedback

Use this on the upload page when the site has room for a known-bugs or notes section.

```text
Known issues and current review notes:

This mod is being shared with the work-in-progress trail visible on purpose. It began as a simple Wasteland animal tuning modlet, then grew into a small Windows tuning harness after live testing showed that animal weights, spawn route timing, and the global animal cap all matter.

Current known items:

- Default is designed to preserve the live game baseline. During QA we found and fixed a precision issue where decimal spawn timing could be rounded. Please report anything that still makes Default feel quieter or louder than expected.
- Dense and Absurd are intentionally heavy. They can be limited by the game's global animal cap unless Brutal Science is enabled.
- The global-limit option can raise MaxSpawnedAnimals in serverconfig.xml to 999 after making a timestamped backup. `Restore Global Limit Only` replaces serverconfig.xml from the newest matching Bit Wrecked backup.
- Remove Mod deletes the modlet folder and returns affected routes to game-default XML behavior. Global-limit restore is the separate undo path for the optional serverconfig.xml change.
- Vortex/mod-manager users may prefer to install only the included BitWrecked_7DTD_WastelandAnimalPopulationTuning folder. The full package is built first for normal manual Windows use with the helper tool.
- Screenshot examples are still being curated. The raw testing showed everything from quiet Wasteland behavior to completely unreasonable animal pressure.

Feedback is welcome, especially from people who read this far. This is not a competition and it is not pretending to be perfect. If your machine, server, mod list, or play style reveals a weird edge case, that is useful information. Please include your tuning level, whether Brutal Science was on, single-player or server, other spawn/gameplay mods, and what you expected versus what happened.

The goal is simple: make the Wasteland as peaceful, dangerous, absurd, or comfortable as each player wants, while being honest about the sharp edges.
```

## Booklet-Style Player Note

Use this when you want the mod page to feel more like an old game booklet or field guide. It should slow the reader down just enough to understand the world before they start changing it.

```text
Field note for new Wasteland travelers:

The Wasteland is not just another biome. It is where the game starts to lean forward. The roads are broken, the air is dirty, and the animal table has teeth. This tuning harness does not replace that world. It gives you a few careful handles for deciding how much pressure that world should put on you.

Remove Mod deletes this tool's installed mod folder. The affected Wasteland
routes then use game-default XML behavior; any separate serverconfig.xml change
remains until it is restored separately.

Default means the mod writes the current game baseline back into the generated
modlet. Remove Mod deletes that modlet, changing the effective configuration so
the affected routes use the game's own default XML directly.

Sparse and Absent move the Wasteland toward quiet. Sparse is about half pressure; Absent is the near-removal setting. Use them if you want fewer sudden animal checks while building, filming, learning, or running a server with newer players.

Dense and Absurd move the Wasteland toward danger. They can add extra Bit Wrecked route handles for selected animals, which means the game has more chances to choose those animals when Wasteland animal spawns are eligible.

The global-limit option is different. It does not create animals by itself. It
backs up and writes serverconfig.xml, setting the global animal cap to 999 so
Dense and Absurd are less likely to be stopped by the world's safety rail.
Vanilla despawn and cleanup behavior still exists. `Restore Global Limit Only`
replaces serverconfig.xml with the newest matching Bit Wrecked backup. Treat
this like opening a lab door: useful, loud, and not always polite to hardware.

If something feels strange, that is useful. Tell us what setting you used, whether Brutal Science was on, whether you were in single-player or on a server, and what other spawn or gameplay mods were active. The Wasteland can be tuned many ways. The point is not to prove one correct way to play. The point is to give players a readable map, then let them choose their road.
```

## Tags

```text
7 Days to Die mod
7DTD mod
7 Days to Die 3.0 mod
Wasteland animal density
Wasteland animal spawn density
Wasteland animal population tuning
Wasteland animal tuning
fewer dire wolves
fewer zombie bears
reduce dire wolf spawns
reduce zombie bear spawns
7DTD XML mod
7DTD modlet
Bit Wrecked
```

## YouTube Description

```text
This is a small 7 Days to Die XML modlet that tunes Wasteland animal density and animal mix.

Download the zip, unzip it, read README_FIRST.txt, double-click 7DTD_WastelandAnimalTuning.bat, check the animals you want to tune, and click Install Mod. Default is no changes selected. Use Scan Values to compare current and selected values. It is a small XML tuning harness, not an EXE/DLL mod. For single-player modded play, launch without Easy Anti-Cheat.

If your mod site only allows one upload, the full package is the right upload. It includes the XML modlet and Windows helper scripts. Antivirus or mod-site scanners may warn about the helper scripts because they are `.bat` and `.ps1` files that copy/remove mod files and can optionally back up/edit or restore `serverconfig.xml`. If you do not want to run scripts, install only the `BitWrecked_7DTD_WastelandAnimalPopulationTuning` folder into `7 Days To Die/Mods`.

Built for Windows 11, Steam, and current 7 Days to Die 3.0-era installs.

Unofficial fan mod. Licensed GPL-3.0-or-later. Use at your own risk. You may copy, change, and share it. Credit to Bit Wrecked is appreciated.
```

## Facebook Reply

```text
I made this as a small XML-only mod. It lets you tune Wasteland animal density and animal mix.

Download the zip, unzip it, double-click 7DTD_WastelandAnimalTuning.bat, check what you want to tune, and click Install Mod. The support folder stays next to the launcher but most users do not need to open it. Remove the mod later with Remove Mod.

It is unofficial, XML-only, and licensed GPL-3.0-or-later. You may change/share it. Credit to Bit Wrecked is appreciated.
```

## Site Changelog / Release Story

```text
Version 4.0.1 release story:

Brick 0.5: retuned the quiet side after field testing. Sparse now means about half selected animal pressure instead of the older quarter-strength value, so low-base animals such as dire wolves and zombie bears do not disappear too aggressively.

Brick 0.6: clarified the testing baseline. Remove Mod deletes the owned modlet,
returning affected routes to game-default XML behavior. Default installed still
writes generated XML containing the live baseline values.

Brick 0.7: documented the cap behavior in player language. Brutal Science does not create animals by itself; it lifts the global animal cap so Dense and Absurd pressure is less likely to be throttled. Vanilla despawn, timer, and cleanup behavior still exists, but extreme pressure plus a lifted cap can get heavy over time.

This started as a simple Wasteland animal tuning mod and became a small tuning harness with verification, screenshots, and a proper safety story.

Brick 1: matched the current 7DTD 3.0-era XML shape. The live game uses EnemyAnimalsWasteland and EnemyAnimalsWastelandNight with compact e/n/p entries, so the mod targets that exact shape.

Brick 2: kept the game mod XML-only. The modlet itself is ModInfo.xml plus Config/entitygroups.xml and Config/spawning.xml. No EXE, DLL, Harmony patch, downloader, or game executable patching.

Brick 3: built clear tuning levels: Absent, Sparse, Default, Dense, Absurd.
Default is the live game baseline written through the generated modlet; Remove
Mod deletes that modlet so the game uses its default XML directly.

Brick 4: discovered that bigger weights alone were not enough for high-pressure testing. Dense and Absurd can now append extra Bit Wrecked selected-animal pressure routes, which made the high end visibly different in live Wasteland testing.

Brick 5: added Scan Values and install verification so users can see what XML is installed instead of trusting vibes.

Brick 6: added global animal-cap support. This optional setting backs up and
writes serverconfig.xml and can raise MaxSpawnedAnimals to 999 for extreme
testing. The restore state replaces serverconfig.xml with the newest matching
Bit Wrecked animal-cap backup.

Brick 7: fixed a Default precision bug found during QA. Default respawn delays now preserve the live game decimal strings exactly instead of rounding values such as 1.575 to 1.58.

Brick 8: tightened validation. The package validator now fails if packaged Default XML drifts from the live game baseline.

Brick 9: documented the one-package upload reality. If the mod site allows only one file, upload the full package. It includes the XML modlet plus Windows helper scripts. Manual/mod-manager users can install only the BitWrecked_7DTD_WastelandAnimalPopulationTuning folder if they do not want to run scripts.

Brick 10: added full-package extraction smoke validation. The release validator now extracts the rebuilt full zip to a temporary folder, checks the simple top-level user view, and smoke-tests the GUI from the extracted package.

The package includes RELEASE_NOTES.md for VMware-style release notes and BUILD_STORY_AND_QA_RUNBOOK.md for the full maintainer story.
```

## Images

Use these public images when the site asks for a mod image, thumbnail, or social preview:

```text
Assets/nexus-cover-1280x720.png
Assets/nexus-thumbnail-1024x1024.png
```

The generated background source is kept here for proofing:

```text
Assets/nexus-cover-background-generated.png
```
