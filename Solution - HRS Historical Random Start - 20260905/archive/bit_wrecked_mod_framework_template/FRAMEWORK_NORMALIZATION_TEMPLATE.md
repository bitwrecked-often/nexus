# Bit Wrecked Mod Framework Normalization Template

Status: Reusable template
Use when: Starting a new independent mod from a proven Bit Wrecked framework

## How to use this template

1. Copy this file into the new mod's active initial version lane.
2. Replace every `[placeholder]` before implementation begins.
3. Preserve the completed source mod as a separate authoritative solution.
4. Keep inherited copies in a framework archive, not in the new mod's active
   version history.
5. Complete the checklist before adding the new gameplay payload.

---

# [New Mod Name] [Version] — Framework Normalization Manifest

Status: Framework normalization planning
Source framework: [Completed reference mod and version]
New solution: [New independent solution path]
Active version lane: [for example, `0.0.1`]
Implementation authorized: Framework normalization only
Release authorized: No

## Purpose

This mod begins from a copy of the proven [Completed reference mod] framework.
Normalize that copy into a neutral framework for [New Mod Name] before adding
its gameplay payload.

Normalization means replacing inherited product identity and payload assumptions
while preserving the reusable operational recipes. It does not delete history,
change the completed reference mod, or approve a release.

## New mod intent

One-sentence promise: [Plain-language player-facing promise]

Exact scope: [Only the verified current targets/features that belong]

Explicit exclusions:

* [Excluded system or feature]
* [Excluded system or feature]
* [Excluded system or feature]

## Desired end state

* Active development exists only under `[new solution]/versions/[version]`.
* Active identity names only [New Mod Name].
* Inherited material is visibly archived and cannot be mistaken for a new
  release history.
* The normal XML modlet remains the core product.
* The GUI/tooling is optional and player-friendly.
* New rows/payload entries are traceable to an exact evidence map.
* Installation, validation, selective removal, packaging, and DR remain
  reversible and understandable.

## Source-of-truth layout

```text
solutions/
├── [completed_reference_solution]/       authoritative completed reference
└── [new_solution]/
    ├── versions/
    │   └── [new_version]/                active development lane only
    ├── framework_archive/
    │   └── [reference copies]/           inherited reference and DR material
    ├── Support_Files_Do_Not_Edit/        active framework to normalize
    └── Upload_To_Nexus/                  inactive until release authorization
```

## Reusable recipe decision table

Mark each recipe `retain`, `adapt`, `omit`, or `not applicable`.

| Recipe | Decision | New-mod adaptation |
|---|---|---|
| Choose Game Folder | [ ] | [ ] |
| Inspect and Validate Current State | [ ] | [ ] |
| Select Settings | [ ] | [ ] |
| Install or Reinstall | [ ] | [ ] |
| Selective Uninstall | [ ] | [ ] |
| Independent Cap/Stress-Test Action | [ ] | [ ] |
| Restore Saved Global State | [ ] | [ ] |
| Runtime and Persistent Logging | [ ] | [ ] |
| Confirmation and Local Assessment | [ ] | [ ] |
| Validate, Package, and Release | [ ] | [ ] |
| Disaster Recovery | [ ] | [ ] |

Do not retain a specialized control merely because the reference mod had one.
For example, a global animal-cap recipe must be omitted unless the new payload
has its own separately validated need for a global setting.

## Normalization sequence

### 1. Freeze reference and archive boundaries

* Confirm the completed reference solution remains untouched.
* Move inherited historical version lanes outside the active `versions/` area.
* Add a framework-archive README stating that inherited copies are reference and
  disaster-recovery material only.
* Ensure the new solution's active `versions/` directory contains only versions
  of the new mod.

Acceptance: A reviewer can distinguish reference history from active work by
looking at the folder tree.

### 2. Replace active product identity

Replace inherited identity in all active files:

* Solution, package, and generated-modlet folder names
* Internal mod identifier
* `ModInfo.xml` display name, description, version, and author fields
* Launcher, GUI, installer, uninstaller, validator, and package script names
* Logs, backups, archive names, and release metadata
* README, technical manifest, release notes, and public instructions

Use a temporary internal name if the public product name is undecided. Do not
leave the reference mod's public identity in an active launcher or installer.

Acceptance: No active command or user-facing label implies the new mod installs
the reference mod.

### 3. Separate generic UI from reference-specific UI

Retain generic framework behavior:

* Game-folder selection and path checking
* Read-only validation
* Pending selection before writes
* Explicit confirmation
* Activity logging and optional persistent logs
* Install/reinstall and selective-uninstall model
* Error and close behavior

Remove, disable, or replace reference-only controls:

* [Reference-only rows]
* [Reference-only sliders]
* [Reference-only global setting]
* [Reference-only explanations]
* [Reference-only assessment inputs]

Until new rows exist, the tool must be safe to open and validate but must not
present a misleading active installation action.

### 4. Define the payload line-item contract

Before UI or payload implementation, create an exact line-item map.

| Field | Required content |
|---|---|
| Row ID | Stable internal identifier |
| Effect heading | Presentation group only |
| User row label | Exact player-facing target |
| Source file | Target XML/config file |
| XPath/patch target | Exact owned target |
| Baseline shape | Default evidence |
| Fixed values | Validated payload values |
| Dependencies | Shared buffs, cooldowns, tags, requirements, effects |
| Installed state | How validation detects it |
| Removal state | Exact default-restoration behavior |
| Evidence status | Configuration and gameplay evidence |

No UI row may be added without a corresponding map entry. Do not generalize an
effect to a thematic family unless the evidence map proves every included target.

### 5. Define installation and removal ownership

Document:

* Generated modlet folder and owned files
* Per-row patch ownership
* Shared dependency ownership
* Backup locations and naming patterns
* Install/reinstall behavior
* Selective-uninstall behavior
* Last-dependent removal rule for shared dependencies
* Last-row removal rule for the owned mod folder

The tool must never touch unrelated mods, vanilla files, or systems outside its
explicit ownership boundary.

### 6. Retarget validation

Validation is read-only. For each row, report:

* Exact target and Row ID
* Source file and XPath/patch target
* Baseline/default shape
* Current detected shape
* Generated-patch/installed state
* Shared dependency state
* Pending selected action, when applicable
* Expected result: install, keep, remove, unavailable, or incompatible

Missing targets and version incompatibilities must be reported as facts, not
hidden or converted into guessed behavior.

### 7. Retarget confirmation and logging

Confirmation must list exact add, keep, and remove outcomes. Logs must separate
deterministic file facts from any optional local commentary. Persistent logging
requires explicit user consent and must not reuse game-folder wiring.

### 8. Retarget packaging and DR

Before release authorization, update:

* Full-package archive
* No-scripts XML modlet archive
* Optional manager-compatible archive
* Hash output
* Release notes
* Install and removal documentation
* License/attribution material
* Package metadata
* Recovery instructions and known-good backup record

No release archive is created, uploaded, or published during normalization.

## File disposition table

| Inherited material | Required disposition |
|---|---|
| Prior version lanes | Preserve under framework archive only |
| Prior launcher | Replace after new tool exists |
| Prior GUI/tool | Keep as reference until weapon/new tool is created; do not expose as active launcher |
| Prior payload | Reference only; replace with new line-item-map payload |
| Prior manifests/feedback | Reference/DR only; do not inherit as new requirements |
| Generic license files | Preserve, then retarget product-specific naming |
| Generic validation/package mechanics | Preserve and retarget |
| Prior release archives | Historical example only; never relabel as the new mod |

## Normalization checklist

* [ ] Active `versions/` contains only new-mod versions.
* [ ] Reference version lanes are in `framework_archive/`.
* [ ] Active identity is fully retargeted.
* [ ] No active launcher starts the reference tool.
* [ ] Reference-specific UI controls are removed or disabled.
* [ ] New tool can open and validate without writing files.
* [ ] Exact line-item map exists.
* [ ] Installation/removal ownership includes shared dependencies.
* [ ] Validation is exact-row-specific and read-only.
* [ ] Package and DR documentation are retargeted.
* [ ] No release archive or external publication has occurred.

## Handoff after normalization

Only after the checklist passes:

1. Implement the first evidence-backed payload slice.
2. Add its exact UI rows.
3. Test install, mixed selection, selective removal, and full removal.
4. Add later payload slices only after their own line-item maps are complete.
