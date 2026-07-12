# 7DTD 3.0 Wasteland Animal Population Tuning - Changelog

Copyright (C) 2026 Bit Wrecked
SPDX-License-Identifier: GPL-3.0-or-later

This changelog tracks public upload versions. It separates gameplay XML changes from installer, packaging, documentation, and publishing changes.

## Version 4.1.0 - Unreleased

Development status: feature development based on the immutable `v4.0.1` release.

### Planned Changes

- Record new backward-compatible features here as they are implemented and verified.

### Repository Infrastructure

- Added repository-wide AI governance for privacy, release immutability, semantic versioning, evidence, safety, and publication authority.
- Defined the front end as an operational safety layer with validation, preview, backup, verification, restore, removal, and privacy-safe diagnostics.
- Added an anonymized private field-test process and evidence classification model.
- Expanded the solutions standard so packages are derived from recorded field behavior and tested as distributed artifacts.
- Added a bounded next-AI implementation packet for CI, release manifests, version enforcement, package smoke tests, compatibility evidence, conflict inventory, and release acceptance records.

### Nexus No-Scripts Edition

- Added a package-specific first-read manual that describes only files and features present in the no-scripts archive.
- Added a complete requirements, manual installation, multiplayer, verification, conflict, removal, troubleshooting, and privacy-safe support guide.
- Clarified that the no-scripts edition contains fixed XML values and does not include interactive tuning or server-cap controls.
- Added deterministic no-scripts archive construction to the validation harness.
- Added archive checks for required documentation, required modlet files, prohibited executable-style extensions, and references to absent package paths.

### Release Guardrails

- Preserve the published 4.0.1 archives and source tag unchanged.
- Replace `Unreleased` with the publication date only after validation succeeds.
- Rebuild and verify all release archives before publishing the Nexus file.
- Update `VERSION`, `ModInfo.xml`, package metadata, release notes, and archive metadata together.

## Version 4.0.1 - 2026-07-07

Public upload status: scale retune and documentation update.

### Nexus Review And Transparency

- Documented the Nexus pre-publish virus/heuristic scan hold in plain language for support review.
- Rebuilt a scanner-friendly no-scripts archive for Nexus main-file use:
  - includes the XML modlet and text documentation/license files
  - excludes `.ps1`, `.bat`, `.cmd`, `.exe`, `.dll`, `.vbs`, `.js`, `.jar`, `.msi`, and `.scr`
- Kept the full Windows helper package as the transparent GPL source/tool package rather than hiding how it works.
- Clarified that the full package helper scripts are readable local Windows scripts used for install, uninstall, scan/verify, validation, and optional `serverconfig.xml` animal-cap backup/restore.
- Clarified that the helper scripts are not downloaders, hidden updaters, registry editors, scheduled tasks, services, startup entries, Harmony patches, or game executable patchers.
- Documented the scanner-sensitive pattern: batch launchers call local PowerShell scripts with `-NoProfile` and process-local `ExecutionPolicy Bypass` so normal Windows users can run the readable local tool.
- Documented that source review found no use of `Invoke-Expression`, `EncodedCommand`, Base64 decode helpers, web download helpers, Defender preference changes, registry commands, scheduled tasks, `bitsadmin`, or `certutil`.
- Added external archive inspection notes and SHA256 tracking outside the zips so hashes stay meaningful and do not chase themselves.
- Updated support routing to explain that GPL-3.0-or-later is intentional: the mod, helper scripts, build notes, and validation logic are visible for review, modification, and redistribution under the license.

### Gameplay XML

- Retuned `Sparse` from 0.25x animal weight to 0.5x animal weight.
- Retuned Sparse route delay from 2.5x to 1.75x.
- Retuned Sparse `none` weight from 2.0x to 1.5x.
- Kept `Dense` and `Absurd` unchanged after field testing confirmed the top end is useful.

### Documentation

- Clarified that `Default` installed writes live vanilla Wasteland animal baseline values and should feel like no mod for the tuned routes.
- Clarified that `Remove Mod` is the true untouched comparison state.
- Clarified that `Brutal Science` lifts a global animal cap and does not create animals by itself.
- Added warning that vanilla despawn/timer/cleanup behavior still exists, but Dense/Absurd plus a lifted cap can build serious pressure over time.

## Version 4.0.0 - 2026-07-05

Public upload status: current release candidate.

### Gameplay XML

- Added high-density pressure-route scaling.
- Dense and Absurd settings can now append extra Bit Wrecked selected-animal spawn routes with `bw_` IDs.
- The original Wasteland animal routes are still tuned with `maxcount` and `respawndelay`.
- Extra route handles are only generated for high-pressure choices:
  - `Dense` adds one extra route for each selected animal's active Wasteland time bucket.
  - `Absurd` adds three extra routes for each selected animal's active Wasteland time bucket.
  - Routes use the game's single-animal entitygroups, such as `animalDireWolf` and `animalZombieBear`.
- Lower settings remain conservative:
  - `Absent`, `Sparse`, and `Default` do not append extra pressure routes.
- Kept the patch XML-only and inside the modlet `Config` folder.

### Installer And User Experience

- Install verification now checks appended pressure route handles as well as normal `<set>` values.
- Install feedback now says whether the selected density uses vanilla routes only or extra pressure routes.
- Default density now preserves the live `respawndelay` strings exactly instead of reformatting decimal values.
- Added `Restore Cap` for Brutal Science users. It restores `serverconfig.xml` from the newest Bit Wrecked animal-cap backup and verifies `MaxSpawnedAnimals`.

### Packaging

- Full package and Vortex package remain the same top-level shape as version 3.
- `Config/spawning.xml` is still the density source of truth.
- Validation accepts and audits pressure-route append nodes when present.
- Validation now fails if packaged default XML drifts from the live game's baseline values.
- Validation now extracts the rebuilt full package to a temporary folder, checks the simple top-level user view, and smoke-tests the GUI from the extracted package.

### Upgrade Notes

- Users coming from version 3.0.0 should click `Reinstall Mod`.
- Testing high density still requires a restart and fresh Wasteland spawn activity.
- Existing saves are not edited directly.

## Version 3.0.0 - 2026-07-05

Public upload status: superseded by 4.0.0.

### Gameplay XML

- Changed the product behavior from roll-weight-only tuning to Wasteland animal density plus animal mix tuning.
- Added `Config/spawning.xml` to patch the live Wasteland animal spawn routes:
  - `EnemyAnimalsWasteland`
  - `EnemyAnimalsWastelandNight`
- Added density control through route `maxcount` and `respawndelay`.
- Added `none` entry tuning in `entitygroups.xml` so high-density choices produce fewer empty animal rolls and low-density choices produce more empty rolls.
- Changed slider labels and factors:
  - `Absent` = 0x animal weight
  - `Sparse` = 0.5x animal weight
  - `Default` = 1x animal weight
  - `Dense` = 3x animal weight
  - `Absurd` = 8x animal weight
- Kept the mod XML-only: no DLL, EXE, Harmony, custom scripts, or direct `Data/Config` edits.

### Installer And User Experience

- The graphical installer now writes and verifies both:
  - `Config/entitygroups.xml`
  - `Config/spawning.xml`
- Post-install feedback now reports selected density and animal mix.
- Scan/verify logic now treats generated `none` density rows as expected rows instead of extra drift.

### Packaging

- Full package and Vortex package now include `Config/spawning.xml`.
- Validation now checks spawning patch XPath targets against live `Data/Config/spawning.xml`.

### Upgrade Notes

- Users coming from version 2.0.0 should reinstall through the graphical tool.
- Existing saves are still not edited directly.
- For testing, restart the game and move through Wasteland terrain so the spawn system can make fresh rolls.

## Version 2.0.0 - 2026-07-05

Public upload status: superseded by 3.0.0.

### Gameplay XML

- No gameplay tuning change from version 1.0.0.
- Packaged default XML still targets the same Wasteland animal groups:
  - `EnemyAnimalsWasteland`
  - `EnemyAnimalsWastelandNight`
- XPath shape remains locked to the verified 7DTD 3.0-era structure:
  - `/e[@n='animalDireWolf']/@p`
  - `/e[@n='animalZombieBear']/@p`
- Packaged default values remain game-baseline values unless the graphical tool writes user-selected values.

### Installer And User Experience

- Changed the full package zip to open with only two visible top-level files and one support folder:
  - `README_FIRST.txt`
  - `7DTD_WastelandAnimalTuning.bat`
  - `Support_Files_Do_Not_Edit/`
- Updated `7DTD_WastelandAnimalTuning.bat` so it can launch the graphical installer from either:
  - the developer folder layout
  - the release zip support-folder layout
- Moved advanced command-line fallback tools under `Support_Files_Do_Not_Edit/Advanced_CommandLine/` in the full package.
- Added `README_FIRST.txt` for a short, human-first install path.
- Added a VMware-style operation note for the advanced command-line fallback tools.
- Clarified that the advanced command-line installer:
  - copies the packaged modlet as shipped
  - does not read GUI slider choices
  - does not remember previous GUI state
  - does not accept tuning switches
  - does not merge with other mods
  - removes only this mod folder when uninstalled
- Fixed the graphical installer target builder so unchecked animals are not written as default-value XML rows.
- Added a guard that blocks install/reinstall when no animals are selected, instead of creating a hidden no-op patch.

### Packaging

- Full package zip now enforces a human-facing top-level shape:
  - exactly one top-level `.bat`
  - exactly one top-level first-read file
  - support files contained under `Support_Files_Do_Not_Edit/`
- Vortex package remains modlet-only:
  - `BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml`
  - `BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml`
- Added validation rules to reject confusing full-package top-level entries.
- Added validation rules to keep full-package helper files out of the Vortex zip.

### Documentation

- Added this changelog.
- Updated `README_WINDOWS.md` with a clear explanation of each `.bat` file.
- Updated `TECHNICAL_FILE_MANIFEST.md` to describe the new release zip layout.
- Updated package metadata and solution-library routing notes for version 2.

### Upgrade Notes

- Users who installed version 1.0.0 can install version 2.0.0 over it.
- If using the graphical tool, choose the desired animal values and click `Reinstall Mod`.
- If using Vortex, replace the old modlet zip with the new version.
- Existing saves are not directly edited by the mod or installer.

## Version 1.0.0 - 2026-07-04

Public upload status: initial release baseline.

### Gameplay XML

- Added XML-only modlet for 7 Days to Die 3.0-era Wasteland animal roll tuning.
- Targeted verified Wasteland animal groups:
  - `EnemyAnimalsWasteland`
  - `EnemyAnimalsWastelandNight`
- Used verified live XPath shape:
  - `/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalSnake']/@p`
  - `/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieVulture']/@p`
  - `/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieDog']/@p`
  - `/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieBear']/@p`
  - `/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalDireWolf']/@p`
  - `/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalDireWolf']/@p`
  - `/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalZombieBear']/@p`

### Installer And User Experience

- Added a Windows PowerShell WinForms graphical tool.
- Added animal checkboxes and sliders for Wasteland animal tuning.
- Added `Scan Values` to compare game baseline, installed mod values, and selected target values.
- Added install, reinstall, remove, open Mods folder, and close controls.
- Added Bit Wrecked branding and channel avatar.

### Packaging

- Added full Windows package zip.
- Added Vortex/mod-manager modlet-only zip.
- Added validation and package harness.

### Documentation

- Added beginner-facing Windows README.
- Added publishing/SEO copy.
- Added package metadata.
- Added technical file manifest.
- Added GPL-3.0-or-later license files and plain-language legal/use notes.
