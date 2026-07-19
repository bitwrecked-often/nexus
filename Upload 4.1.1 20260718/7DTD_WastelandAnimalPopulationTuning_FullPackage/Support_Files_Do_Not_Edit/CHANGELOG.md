# 7DTD 3.0 Wasteland Animal Population Tuning - Changelog

Copyright (C) 2026 Bit Wrecked
SPDX-License-Identifier: GPL-3.0-or-later

This changelog tracks public upload versions. It separates gameplay XML changes from installer, packaging, documentation, and publishing changes.

## Version 4.1.1 - GUI Clarity Review

Development status: owner-approved release-ready build. All three 4.1.1 upload
archives were rebuilt and validated on 2026-07-18. Not uploaded, tagged, or
published.

This is a major GUI clarity and presentation update built on the unchanged
4.0.1 gameplay/XML foundation.

- Clarified that `Choose Game Folder` selects the main 7 Days to Die folder,
  not its `Mods` subfolder, and does not run the mod.
- Renamed `Compare Values` to `Validate Current Game Settings`. It freshly reads
  configuration without modifying game, mod, or server settings; when the user
  enables Persistent log, its displayed report is written to that chosen file.
- Removed `Next:` action instructions from validation results so the report
  returns only the detected state and comparison information.
- Added a labeled global-limit history to Brutal Science validation: game
  default, newest backed-up setting, current setting, and selected test result.
- Mirrored validation results into the Layered Reasoning Log as deduplicated
  `VALIDATION` entries; repeated checks add only new or changed report lines.
- Kept logging memory-only by default and added an opt-in `Persistent log`
  checkbox with an independent Windows `Choose Log File` dialog. The GUI warns
  that runtime history clears on restart; opted-in files receive the visible
  session history and subsequent entries through an independent user-selected
  text path, without reusing or altering game/mod path selections.
- Added an explicit persistent-file consent dialog. File selection requires the
  prominent dark-red, yellow-outlined Comic Sans confirmation button labeled
  `I want to write a log file to my computer`; Cancel keeps runtime-only logging.
- Added pre-write summaries for every actionable animal/global-limit setting
  combination, with original blunt systems-programmer Easter-egg humor built by
  a weighted context-aware fragment generator instead of complete canned quips.
  Clean `CONFIRM` data and generated `EASTER EGG` lines are logged separately,
  once per exact combination per session.
- Tuned generated asides to recognize each combination's intent with comfortable,
  wry, almost-judgmental humor that remains constructive rather than dismissive.
- Added real-time positive, cautious-negative, neutral, and surprised weighting
  based on count, average intensity, level diversity, and Brutal Science. Full
  replies are assembled locally from reusable fragments with no network calls;
  an offline reply-simulation switch supports distribution and tone review.
- Calibrated low-intensity choices toward neutral-positive reactions and shifted
  increasingly extreme combinations toward surprised/cautious responses. The
  offline simulator now runs 500 rolls per representative case and reports tone
  distributions plus samples.
- Added a second weighted local generator for validation-time gameplay judgment.
  It derives a difficulty rating and blunt opinion from animal intensity,
  selection breadth, and global-cap pressure; complete responses are assembled
  at runtime rather than stored as canned lines. The assessment is cached per
  exact state and mirrored into the Layered Reasoning Log through validation.
- Centered the complete validation area. The button and its label are centered,
  with the dynamic selection summary centered on a separate line above it to
  prevent rendering overlap.
- Defined the global-limit apply/restore states, animal selection, and the difference
  between restoring server settings and removing mod files directly in the GUI.
- Labeled the visible cap control
  `Raise Animal Spawn Cap - Brutal Science` and removed
  its separate Restore button. Checked uses `Apply Limit Cap Only`; after the
  cap changes, unchecking exposes `Restore Global Limit Only` on the bottom
  action using the newest saved previous value.
- Added the normal game animal spawn limit of `50` to the GUI label, tooltips,
  validation report, stress-test confirmation, and restore confirmation while
  preserving backup-based restore for customized prior values.
- Clarified that `MaxSpawnedAnimals` is a global game/server limit across all
  biomes; only the mod's separate XML route tuning is Wasteland-specific.
- Allowed the cap setting to run as a standalone `Apply Limit Cap Only` action
  without selecting animals or installing/changing Wasteland XML mod files.
- Reduced the standalone `Apply Limit Cap Only` label from 10-point to
  8-point for a cleaner fit.
- Added default/current/result global-limit tracking to the visible selection
  summary whenever Brutal Science is checked; validation reports retain the
  same comparison.
- Renamed `Mods Folder` to `Open Mods Folder` and centered the five animal-table
  headings over their columns.
- Changed the no-selection primary action from `Select Animals` to
  `Check any Box Above to Install Here..`.
- Removed the redundant idle `No changes selected.` note while retaining active
  animal-selection summaries.
- Removed redundant global-limit wording from the centered selection summary;
  detailed cap values remain available in validation, confirmations, and logs.
- Added a large upward-looking no-selection indicator that changes back to the
  normal action arrow after animals are selected.
- Simplified active Install/Reinstall styling to a centered gray button with a
  green outline and subtle iridescent highlight, without a separate circle.
- Added a translucent molded-plastic treatment with layered gloss, subtle
  lower-edge depth, and a small pixel-art paw/glint signature.
- Moved supplemental folder, validation, table-column, animal-selection,
  Brutal Science, restore, remove, and Mods-folder explanations into targeted
  long-lived tooltips and tightened the now-cleaner layout.
- Tuned tooltips to appear after 200 ms, close after four seconds, and move
  between controls with a 50 ms reshow delay.
- Enabled lightweight native fade-in/fade-out animation for tooltips.
- Added lightweight three-frame chat-style text streaming to every explanatory
  tooltip; the complete wrapped message remains visible before fading out.
- Added completed tooltip explanations to the Layered Reasoning Log as indexed `TIP`
  entries. Each unique explanation is recorded only once per session, so
  repeated hovers do not clutter the log.
- Formalized the sidebar as `Layered Reasoning Log / Recent Actions`: verified
  facts and file effects lead, gameplay consequences follow, and weighted
  generated commentary comes last. Persistent saves use a matching default
  filename while remaining explicit opt-in behavior.
- Fully routed animal-row `TIP` entries by animal and table column. Entries now
  identify Action, Current, or Result instead of using an ambiguous displayed
  value such as `day 2 / night 4` as their source name.
- Removed repetitive tooltips from animal checkboxes/names, level sliders, and
  the matching All controls; retained routed Action, Current, and Result help.
- Removed the redundant animal-selection section heading and reclaimed its
  vertical spacing, reducing the window height by 30 pixels.
- Changed the master label to `All` and moved its checkbox, shared slider, and
  `Custom` action into the first normal table row directly above Dire wolf.
- Unchecking `All` now clears every individual animal choice
  while leaving the independent Brutal Science selection unchanged.
- Added installed-state-aware animal removal. Unchecked installed animals show
  `Uninstall` with their default result; single and multiple removal-only actions
  are named clearly, mixed confirmations list removals, and removing the final
  tuned animals removes generated mod XML and the empty mod folder, returning
  the game's effective XML configuration to defaults.
- Fixed single-animal removal naming so the bottom action shows the complete
  animal name instead of treating it as a scalar character sequence.
- Added a centered list of pending uninstall animals above the bottom action and
  reduced the multi-object action label from 10-point to 6-point.
- Replaced the generic multi-animal removal label with a compact two-line
  `Remove Only:` action that lists every pending animal directly on the button.
- Reworded per-animal removal as `Uninstall`. The bottom action now reads
  `Uninstall Mod -` followed by affected animals, and confirmations state that
  unchecked installed animals return to game-default values.
- Removed the redundant centered selection-summary wording above validation;
  affected animals remain named directly on the bottom action.
- Aligned the grouped checkbox with the individual animal checkboxes below it.
- Horizontally aligned the grouped slider track with the animal sliders below.
- Lowered the grouped slider into the grouped-selection row and moved its
  `Custom` value clear of the aligned slider.
- Raised the grouped slider five pixels for final row alignment.
- Removed the grouped-slider artifact beside the `Animal` heading and shifted
  the `Action` heading three pixels left.
- Shifted the `Current` and `Result` headings three pixels left for matching
  column alignment.
- Replaced the clipped single-line status area with a full-height right-side
  activity console. It records timestamped task starts, choices, cancellations,
  results, and failures, auto-follows new entries, and wraps long entries within
  the narrower pane with vertical scrolling.
- Made the activity console collapsed by default with a slim side-mounted debug
  arrow; expanding and collapsing preserves the complete session history.
- Converted the open console into a draggable split partition. The arrow snaps
  it open at approximately half the main GUI width or closed, its divider can
  be pulled sideways, and resizing the open window gives additional width to
  the activity-log side while preserving the main GUI width.
- Replaced the activity pane's resizing rounded border with a stable single
  border to prevent repeated outline trails while expanding or dragging it.
- No gameplay tuning, XML generation, install/remove, animal-cap, backup, or
  restore behavior changed.

## Version 4.1.0 - DEV GUI Review

- No runtime, gameplay tuning, XML generation, install/remove, animal cap,
  backup, restore, or modlet behavior changed.
- Refined GUI labels, inline cap guidance, tooltips, and accessible descriptions
  so folder selection, value comparison, mod removal, cap restoration, and
  animal selection describe their existing behavior directly.

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
- Clarified at that stage that `Remove Mod` deletes the generated modlet. Current
  wording additionally states the resulting effective XML/default behavior and
  separates it from serverconfig.xml restoration.
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
