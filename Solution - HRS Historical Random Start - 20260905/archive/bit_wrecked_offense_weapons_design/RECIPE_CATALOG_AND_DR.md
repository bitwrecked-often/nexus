# Bit Wrecked Modlet Recipe and Disaster-Recovery Archive

Date: 2026-07-19
Reference implementation: Wasteland Animal Population Tuning 4.0.1
Status: Archived production recipe
Purpose: Preserve the repeatable build, validation, release, and recovery
framework for future Bit Wrecked tuning modules.

This archive describes the reusable framework. It does not approve any new
gameplay feature and does not copy animal-module claims into a weapon module.

## Reference package

Source package:

`_game_dev_ai_tracking/solutions/7dtd_wasteland_animal_population_tuning_files/versions/4.0.1/`

The package contains:

* A root launcher and first-read instructions
* A `ModInfo.xml` identity file
* A modlet payload under `Config/`
* A GUI tool for install, scan, verify, and removal
* Advanced command-line install and uninstall scripts
* A validation and packaging script
* A technical file manifest
* A build story and QA runbook
* Windows usage, release, legal, license, and publishing documents
* Nexus, Vortex, and no-script distribution archives
* Visual assets and release metadata

The reference module's gameplay files are:

* `BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml`
* `BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml`
* `BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/spawning.xml`

## The recipe

The production recipe has seven layers.

## Reusable recipe catalog

The GUI is a framework containing several independent point-and-do recipes.
Archive and reuse these recipes as named units for future modules.

### Recipe 1 — Choose Game Folder

Input: A user-selected 7 Days to Die game root.

Actions: Open a folder chooser, verify the selected root, locate `Mods` and
`serverconfig.xml`, and show the selected path.

Must not: Install, launch, modify, or open an unrelated Mods folder merely
because the user selected or edited the path.

Reusable substitution: None, except the future module's expected game-version
checks.

### Recipe 2 — Inspect and Validate Current State

Input: A selected game root and the module's XML targets/settings.

Actions: Read current files, compare them with defaults and the module's known
targets, and open a read-only report.

Must not: Change files, refresh displayed values unexpectedly, or append action
instructions to a validation report.

Reusable substitution: Module-specific files, XPath targets, defaults, and
comparison rules.

### Recipe 3 — Select Settings

Input: User-selected rows, levels, toggles, and optional stress-test controls.

Actions: Keep selections pending in memory, show current and result values, and
summarize exactly what the next action will affect.

Must not: Write files when the user only checks a box or edits a control.

Reusable substitution: Rows, sliders, controls, and setting vocabulary.

### Recipe 4 — Install or Reinstall

Input: A validated game root and confirmed pending settings.

Actions: Back up owned files or server settings where required, write the
module's XML payload, remove stale owned fragments when necessary, verify the
result, and report the outcome.

Must not: Touch unrelated mods, settings, or files outside the module's owner
boundary.

Reusable substitution: Payload files, XPath operations, ownership markers, and
backup names.

### Recipe 5 — Selective Uninstall

Input: Installed module state and user-cleared or explicitly removed rows.

Actions: Remove only the selected module-owned behavior, delete an empty owned
folder when appropriate, restore effective defaults, verify, and report mixed
keep/remove outcomes.

Must not: Restore unrelated global settings or silently remove unselected
installed behavior.

Reusable substitution: Ownership map and default-restoration targets.

### Recipe 6 — Independent Cap or Stress-Test Action

Input: An explicit stress-test selection, possibly without any module rows.

Actions: Back up the relevant global setting, apply the requested stress value,
verify it, and report that it does not install gameplay XML.

Must not: Spawn entities, install the module, or depend on an unrelated row
selection.

Reusable substitution: Only future modules that genuinely need a separate global
stress control should include this recipe.

### Recipe 7 — Restore Saved Global State

Input: A matching known-good backup and an explicit restore action.

Actions: Select the newest matching backup, restore the saved value or file,
verify the restored setting, and report the source backup.

Must not: Pretend restore means “reset to a hard-coded default,” remove the
module, or require the stress-test checkbox to remain selected.

Reusable substitution: Backup filename pattern, setting path, and verification
rule.

### Recipe 8 — Runtime and Persistent Logging

Input: Runtime events and optional explicit consent to write a log file.

Actions: Show timestamped facts, file effects, consequences, outcomes, and
failures in a runtime pane. If the user separately consents, save the session
to the chosen path and keep later entries current.

Must not: Write a file silently, reuse game-folder wiring, or delete a saved log
when persistence is turned off.

Reusable substitution: Module event vocabulary and validation lines.

### Recipe 9 — Confirmation and Local Assessment

Input: An exact pending settings combination.

Actions: Show deterministic selected values and a locally generated, bounded
assessment of likely gameplay pressure. Cache identical combinations during the
session.

Must not: Call an API, use telemetry, or store complete generated commentary as
if it were a gameplay fact.

Reusable substitution: Module-specific intensity variables and assessment
fragments.

### Recipe 10 — Validate, Package, and Release

Input: A completed source package and version.

Actions: Parse XML, check metadata, verify targets, run smoke tests, inspect
archive shapes, record hashes, and produce supported distribution archives.

Must not: Package an unvalidated gameplay claim or publish externally without
explicit authorization.

Reusable substitution: Module name, version, payload, archive names, and test
expectations.

### Recipe 11 — Disaster Recovery

Input: A dated known-good package, backups, and recovery evidence.

Actions: Stop the game, preserve the failed state, isolate the smallest affected
layer, restore only the intended package or setting, validate, launch-test, and
record the recovery result.

Must not: Overwrite the whole installation or configuration tree blindly.

Reusable substitution: Module-owned paths, backup pattern, and acceptance test.

These recipes are independent. A future weapon module may reuse Recipes 1–5,
8, 10, and 11 while omitting Recipes 6, 7, or 9 if it has no global cap,
restoreable setting, or generated assessment.

### 1. Discovery and boundary

Define one plain-language gameplay promise. Identify the exact vanilla targets,
the observed change, the files involved, the exclusions, and the rollback
shape. Do not begin with packaging or copy a broad working-tree diff.

### 2. Gameplay payload

Place only the smallest XML patch needed to express the validated behavior.
Keep the payload in a dedicated modlet folder. Use stable XPath targets and
avoid unrelated files. Every target must have a baseline reference and a
removal path.

### 3. Identity and public explanation

Create `ModInfo.xml` with a stable internal name, display name, author, version,
and one-sentence description. Public documentation must state what the module
changes and what it intentionally leaves alone.

### 4. Operator tools

Provide a simple launcher for normal users plus advanced command-line scripts
for explicit installation and removal. The tools must locate the game, inspect
the current state, create safety backups, apply the payload, verify the result,
and remove only the module's changes.

### 5. Validation and packaging

The validation script checks package shape, metadata, payload files, XML syntax,
expected XPath targets, version information, and generated archive contents.
It produces the supported distribution archives without changing the gameplay
source by hand.

### 6. QA and evidence

The runbook records the build story, clean-install test, upgrade test, removal
test, default-state test, gameplay test matrix, failure conditions, and final
evidence. XML parsing is one gate, not the complete QA result.

### 7. Release and recovery

Publish the supported archives with release notes, legal material, checksums or
equivalent identity evidence, and a known-good reference package. Preserve the
source package and the validation output so a later recovery does not depend on
memory.

## What is reusable for weapons

Clone the framework, not the animal conclusions.

Reusable unchanged or nearly unchanged:

* Folder layout
* Modlet identity pattern
* GUI and command-line workflow shape
* Backup-before-change behavior
* Validation and packaging flow
* Documentation sections
* Release and rollback structure

Must be replaced for a weapon module:

* Internal and public names
* Gameplay promise
* XML targets and source files
* Exclusions
* Settings and defaults
* Compatibility checks
* Gameplay test matrix
* Screenshots, descriptions, release notes, and archive names

Do not retain animal-specific XPath, terminology, claims, or test conclusions
after cloning.

## Minimum recipe record for each new module

Before packaging, record:

* Stable module name and public display name
* One-sentence promise
* Supported game version
* Exact source files and XML targets
* Vanilla/baseline values
* Current validated values
* Evidence source for each value
* Exposed controls and defaults
* Explicit exclusions
* Installation behavior
* Removal behavior
* Validation commands and expected results
* Gameplay test matrix
* Acceptance criteria
* Rollback plan
* Evidence returned by the test owner

## Disaster-recovery model

Recovery is layered. Restore the smallest affected layer first.

### Layer A — Package source

Preserve the complete reference source directory, including scripts,
documentation, payload, assets, and generated archives. This is the rebuild
source of truth.

### Layer B — Installed modlet

Record whether the modlet exists under the game's `Mods` directory, its exact
folder name, payload file hashes, and installed version. Remove or restore only
that folder when the problem is isolated to the modlet.

### Layer C — Game configuration

If a direct game configuration file was edited during testing, snapshot it
before any repair. Compare it with the clean or known-good copy. Never overwrite
a current Steam configuration blindly with an old backup.

### Layer D — Save and world data

Back up saves and generated worlds separately before any reinstall, verify-file
operation, or configuration repair. A modlet rollback must not be treated as a
save rollback.

## Pre-change DR checklist

1. Stop the game and dedicated server.
2. Record the game install path and game version.
3. Record root and nested repository status, if present.
4. Copy the current installed modlet to a dated backup location.
5. Record hashes for payload XML, `ModInfo.xml`, and generated archives.
6. Back up saves and generated worlds to a separate dated location.
7. Record active neighboring mods that may touch the same XML targets.
8. Capture the current log before changing anything.

## Recovery paths

### Modlet-only failure

1. Stop the game/server.
2. Move the affected modlet folder to a dated quarantine or backup location.
3. Start once with the modlet absent and inspect the log.
4. If the game is healthy, keep the modlet isolated and investigate its payload.

### Bad update or partial installation

1. Stop the game/server.
2. Preserve the failed package and its logs.
3. Remove the incomplete installed folder only after verifying its exact path.
4. Restore the last known-good modlet folder from the dated backup.
5. Run the validator and a clean launch check.

### Configuration collision

1. Do not overwrite the whole `Data/Config` directory.
2. Identify the exact file and XPath collision.
3. Compare the current file with a clean baseline and the modlet's intended
   target.
4. Disable the conflicting mod or adjust the new module's target only after
   preserving both versions.
5. Parse XML and launch-test before restoring gameplay use.

### Steam repair or reinstall

1. Snapshot the fresh install before changing it.
2. Preserve saves and generated worlds separately.
3. Verify the clean game state and logs.
4. Reinstall only the intended modlet package.
5. Validate and launch-test before restoring additional mods.

## Recovery acceptance checks

Recovery is complete only when:

* The intended modlet folder is the only restored package.
* `ModInfo.xml` and payload XML parse successfully.
* Expected XPath targets exist in the supported game version.
* The validator reports pass.
* The game launches without XML loader errors.
* The module's gameplay promise still passes its bounded smoke test.
* Saves and worlds remain present and loadable.
* The recovery record names the backup used and the evidence collected.

## Archive rule

For every future module, preserve:

* The validated source package
* The exact payload and metadata
* The validator output
* The gameplay evidence
* The release archives
* The rollback instructions
* A dated known-good backup

This document is the framework archive. A future weapon module should add its
own evidence and QA record beside it rather than silently modifying the animal
module's history.

## New-module recipe worksheet

Copy this worksheet for each future mod. Keep the framework recipes that apply;
omit the rest explicitly.

### Module identity

* Internal name:
* Public display name:
* Version:
* One-sentence promise:
* Supported game version:
* License and attribution:

### Gameplay layer

* Source files:
* XML targets:
* Baseline values:
* Validated values:
* Evidence location:
* Exclusions:
* Owned files and folders:

### Selected framework recipes

Mark each as `included`, `omitted`, or `not applicable`:

* Choose Game Folder:
* Inspect and Validate Current State:
* Select Settings:
* Install or Reinstall:
* Selective Uninstall:
* Independent Cap or Stress-Test Action:
* Restore Saved Global State:
* Runtime and Persistent Logging:
* Confirmation and Local Assessment:
* Validate, Package, and Release:
* Disaster Recovery:

### Completion checks

* [ ] Payload is limited to the stated gameplay promise.
* [ ] Every XML target has a baseline and evidence source.
* [ ] Installation writes only owned files or reversible targets.
* [ ] Removal restores the affected behavior and leaves unrelated settings alone.
* [ ] Validation is read-only and reports exact detected state.
* [ ] Any global setting has an independent backup and restore rule.
* [ ] XML parser and target checks pass.
* [ ] Clean install, reinstall, removal, and failure paths are tested.
* [ ] Gameplay acceptance tests pass.
* [ ] Package metadata, license notices, and source are complete.
* [ ] Release archives are shape-checked and hashed.
* [ ] A dated known-good package and recovery record are archived.

## Archive status

The recipe catalog is complete as a reusable framework record. It is not a
claim that every candidate gameplay module is complete. Each new module must
complete its own worksheet and evidence record before release.
