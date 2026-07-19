# 7DTD 3.0 Wasteland Animal Population Tuning - Release Notes

> Status: Historical `4.0.1` full-helper release record. It is not shared
> `4.1.0` documentation and must not be copied into another edition.

Version: 4.0.1
Release Date: 2026-07-07
Game Version Target: 7 Days to Die 3.0-era Windows / Steam installs
Package Type: Full Windows helper package plus XML modlet

## Product / Mod Summary

This package tunes Wasteland animal density and animal mix in 7 Days to Die. It can make Wasteland open-world animal pressure quieter, baseline, denser, or intentionally absurd.

The game-facing modlet is XML-only. It uses `ModInfo.xml`, `Config/entitygroups.xml`, and `Config/spawning.xml`.

The full Windows package also includes readable helper scripts for installing, removing, scanning, tuning, packaging validation, and optional Brutal Science animal-cap backup/restore.

## What Is New

- Retuned Sparse so it reduces Wasteland animal pressure without making low-base animals feel nearly removed.
- Default installed state was field-checked against live Wasteland baseline values.
- Documentation now explains that Remove Mod is the clean untouched comparison state.
- Documentation now separates Brutal Science cap lifting from actual animal creation and explains the role of vanilla cleanup/despawn behavior.
- Added selected-animal Dense and Absurd pressure routes for stronger high-end Wasteland animal behavior.
- Added Scan Values so users can compare installed XML against selected settings.
- Added Brutal Science animal cap handling for extreme testing.
- Added Restore Cap to restore `serverconfig.xml` from the newest Bit Wrecked animal-cap backup.
- Fixed Default precision so live game decimal spawn timing values are preserved exactly.
- Added full-package extracted smoke validation to the release validator.
- Added known-issues and community-feedback public copy.
- Added booklet-style player note for slower, clearer public explanation.

## Compatibility And Requirements

- Game: current 7 Days to Die 3.0-era install used for Bit Wrecked testing.
- Platform: Windows 11 / Steam path tested.
- Install style: full package for normal Windows users; modlet folder for manual/mod-manager installs.
- EAC: for simple single-player modded play, launch without Easy Anti-Cheat. Server rules win in multiplayer.
- Server/client: install on the host or dedicated server that controls the world. Local install does not change someone else's server.
- Mod managers: users may prefer to install only `BitWrecked_7DTD_WastelandAnimalPopulationTuning`.

## Installation Notes

1. Extract the full package zip.
2. Keep `Support_Files_Do_Not_Edit` beside `7DTD_WastelandAnimalTuning.bat`.
3. Double-click `7DTD_WastelandAnimalTuning.bat`.
4. Select animals, move sliders, and click Install Mod.
5. Use Scan Values to verify installed XML.

The installed modlet target is:

```text
7 Days To Die/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

## Upgrade Notes

- Use the new full package for normal Windows installs.
- Reinstall Mod replaces the installed Bit Wrecked modlet folder with the current selected XML.
- If using a mod manager, replace the previous modlet folder/package with the new one.
- If Brutal Science was previously enabled, decide whether to keep or restore the global animal cap.

## Remove / Rollback Notes

Remove Mod removes:

```text
7 Days To Die/Mods/BitWrecked_7DTD_WastelandAnimalPopulationTuning
```

Remove Mod does not silently restore `serverconfig.xml`.

If Brutal Science changed `MaxSpawnedAnimals`, use Restore Cap. Restore Cap copies the newest Bit Wrecked `serverconfig.xml` animal-cap backup back into place and verifies `MaxSpawnedAnimals`.

The safest untouched game state is Remove Mod plus any desired manual/serverconfig restore.

## Resolved Issues

| ID | Severity | Summary | Resolution |
| --- | --- | --- | --- |
| BW-001 | Medium | Default tuning could lose exact live decimal spawn timing precision. | Default values now preserve live game decimal strings exactly; validator checks live XML targets. |
| BW-002 | High | Brutal Science could raise `MaxSpawnedAnimals` without an obvious GUI restore path. | Added Restore Cap with backup discovery and post-restore verification. |
| BW-003 | Low | "XML-only" wording could be read as applying to the full helper package. | Docs now say the game modlet is XML-only and separately explain helper scripts. |
| BW-004 | Medium | Source validation was stronger than downloaded full-zip validation. | Validator now extracts the rebuilt full package and smoke-tests the GUI from the extracted copy. |

## Known Issues

| ID | Severity | Summary | Workaround / Next Action |
| --- | --- | --- | --- |
| BW-KI-001 | Medium | Clean Default gameplay still deserves one more field confirmation after Absurd/Brutal Science stress testing. | Reinstall Default, account for unrelated mods, decide cap state, and run a clean Wasteland observation. |
| BW-KI-002 | Medium | Vortex/mod-manager behavior for the full helper package is not fully proven. | Use the included modlet folder for mod-manager installs unless current testing proves the full package deploys cleanly. |
| BW-KI-003 | Low | Screenshot gallery is not fully curated yet. | Use the live capture tracker and select final images for the public page. |

## Operational Caveats

- Dense and Absurd can be hardware/server heavy.
- Brutal Science can lift `MaxSpawnedAnimals` to `999`; this removes a safety rail and may stress hardware, servers, saves, or judgment.
- Raising the global animal cap does not create animals by itself. It reduces throttling when spawn routes are already eligible.
- Vanilla despawn, timer, and cleanup behavior still exists, but extreme route pressure plus a lifted cap can still become heavy over time in loaded Wasteland areas.
- Other spawn/gameplay mods can change field results.
- Multiplayer worlds are controlled by the host/server install, not by a joining player's local copy.

## Validation Performed

- PowerShell parser checks passed for GUI, validator, install script, and uninstall script.
- GUI `-SmokeTest` passed.
- Sandbox Restore Cap test passed: `MaxSpawnedAnimals 999 -> 50`.
- Package validator passed against live XML.
- Full package zip was rebuilt.
- Full package was extracted to a temporary folder and GUI smoke-tested from the extracted copy.
- Vortex/modlet zip shape was validated.

## Support / Feedback Data To Include

When reporting an issue, please include:

- game version
- mod package version
- single-player, peer-hosted, or dedicated server
- other spawn/gameplay mods
- selected animal settings
- whether Brutal Science was enabled
- current `MaxSpawnedAnimals` if relevant
- expected behavior
- observed behavior
- screenshot or log if available

Feedback is welcome. This is a community mod, not a competition.

## Files In This Release

Full package:

```text
Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_FullPackage.zip
```

Modlet-only package:

```text
Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip
```

Current archive hashes are tracked outside the archive in the Nexus archive contents report. This avoids putting a zip file's own changing hash inside the zip.
