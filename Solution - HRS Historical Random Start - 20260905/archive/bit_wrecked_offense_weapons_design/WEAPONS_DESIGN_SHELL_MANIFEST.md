# Offense Weapons Design Shell Manifest

## Purpose

This workspace is the full framework clone used to design the independent
Offense Weapons mod. Its runnable shell deliberately mirrors the visual
language and layout of the completed Wasteland Animal Population Tuning 4.1.1
tool, while containing no animal logic and no weapons payload.

## What is mirrored

* Bit Wrecked header and compact cream-panel visual language.
* Status card and main game-folder chooser.
* Five-column center workspace with the same dimensions and hierarchy.
* Optional-capability panel, action bar, and expandable layered-reasoning log.
* Read-only folder validation and an existing-Mods-folder opener.

## What is intentionally empty or disabled

* The center has no effect groups, weapons, controls, current values, or result
  rows.
* The capability slot is disabled and has no defined behavior.
* Install and Remove Mod are disabled.
* No modlet, XML, game setting, folder, archive, or package is created.
* Persistent logging is opt-in and writes only to a path the user explicitly
  selects.

## Design source and next insertion point

The source design reference is the frozen completed tool at:

`framework_reference_4.1.1/Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1`

The existing owner-locked weapons evidence is retained separately at:

`../bit_wrecked_offense_weapons_solution/versions/0.0.1/OFFENSE_WEAPONS_LINE_ITEM_MAP_0.0.1.md`

Do not add center rows until the relevant effect group has an approved,
evidence-backed line-item-map entry. When rows are added, preserve the current
table structure: **Weapon Effect | Control | Action | Current | Result**.

## Certification boundary

This clone inherited a verified framework baseline. Once design changes extend
beyond this shell, its recovery snapshot and checksums must be refreshed before
this workspace is described as a current recoverable release baseline.
