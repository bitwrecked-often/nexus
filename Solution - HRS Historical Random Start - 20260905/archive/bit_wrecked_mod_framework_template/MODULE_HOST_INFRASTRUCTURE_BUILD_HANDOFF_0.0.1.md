# Module Host Infrastructure Build Handoff 0.0.1

**Audience:** The next implementation-focused AI.

**Task type:** Architecture comparison, local Windows UI infrastructure, and
read-only adapter groundwork.

**Status:** Approved to plan and implement the host infrastructure described
here. This is not authorization to change any live game configuration, publish
anything, merge payloads, or make an unfinished module actionable.

## Mission

Build a local Bit Wrecked **Module Host**: a native Windows GUI with one stable
outer shell, a module dropdown, an interchangeable center workspace, and a
continuous labeled activity log.

The first selectable modules are:

1. **Blank Framework** — neutral, read-only, no payload.
2. **Wasteland Animal Population Tuning 4.1.1** — read-only adapter that loads
   the animal tool's visible items and validation state into the host center
   workspace; no host-driven write actions in this phase.
3. **Offense Weapons** — design-only adapter that displays the intentional
   empty weapons workspace; no payload or write actions.

The result must feel like one familiar local management console whose center
“page” changes by module. It must not become a universal payload, web service,
account system, opaque launcher, or guess-driven installer.

## Read these sources completely before writing code

Read in this order. Do not rely on this handoff as a substitute for the source
material.

1. `MODULE_HOST_MANIFEST_0.0.1.md` — product intent, boundaries, and origin.
2. `RECIPE_CATALOG_AND_DR.md` — the eleven proven operational recipes.
3. `FRAMEWORK_NORMALIZATION_TEMPLATE.md` — how a framework becomes a specific
   mod without carrying old identity or history forward incorrectly.
4. `MODULE_HOST_UX_AND_PERFORMANCE_GUIDANCE_0.0.1.md` — researched extension
   model, local responsiveness, accessibility, and performance requirements.
5. `blank_working_example/Blank_BitWreckedMod_Tool.ps1` — the current generic
   native shell and visual baseline.
6. `framework_reference_4.1.1/Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1`
   — the complete 4.1.1 standalone animal-tool behavior reference.
7. `framework_reference_4.1.1/README_FIRST.txt`, `GUI_V3_MANIFEST_4.1.1.md`,
   and the 4.1.1 support/release documents — user promise and release context.
8. `../bit_wrecked_offense_weapons_design/WEAPONS_DESIGN_SHELL_MANIFEST.md`
   and its active `blank_working_example/` — the weapons-specific empty-shell
   contract.
9. `../bit_wrecked_offense_weapons_solution/versions/0.0.1/OFFENSE_WEAPONS_LINE_ITEM_MAP_0.0.1.md`
   — evidence boundary for future weapons work. It does not authorize a
   weapons payload in this host build.

If a referenced source is missing, stale, contradictory, or cannot be safely
understood, stop that portion and record the gap. Do not invent its behavior.

## Required comparison work

Create this report before or alongside implementation:

`MODULE_HOST_COMPARISON_MATRIX_0.0.1.md`

The matrix must compare the three starting states:

| Concern | Generic template shell | Wasteland 4.1.1 standalone | Weapons design shell | Host decision |
| --- | --- | --- | --- | --- |
| Header and identity | | | | |
| Selected game-folder handling | | | | |
| Status presentation | | | | |
| Center table/rows | | | | |
| Validation reads | | | | |
| Install/reinstall | | | | |
| Selective removal | | | | |
| Full removal | | | | |
| Optional global-cap behavior | | | | |
| Restore behavior | | | | |
| Runtime log | | | | |
| Persistent-log consent | | | | |
| Release/recovery boundary | | | | |

For every Wasteland behavior, label the host decision as one of:

* **Host-owned** — only common UI/session behavior.
* **Adapter read-only** — may be exposed in the first host build.
* **Adapter actionable later** — explicitly withheld until parity approval.
* **Standalone-only** — remains in the original tool; host must not imitate it
  yet.

This comparison is mandatory. The goal is not to copy a 4,000-line script into
another script. The goal is to identify exactly which behavior belongs to the
host and which belongs to the animal adapter.

## Files and scope

Create a new isolated host area inside this template:

```text
module_host/
  7DTD_BitWreckedModuleHost.bat
  BitWrecked_ModuleHost_Tool.ps1
  MODULE_HOST_README.md
  modules/
    ModuleContract.ps1
    BlankFramework.Module.ps1
    WastelandAnimals411.ReadOnly.Module.ps1
    OffenseWeaponsDesign.Module.ps1
  tests/
    Test-ModuleHost.ps1
```

Names may improve only if the replacement is equally explicit and documented.

You may add supporting documentation and tests under `module_host/`. You may
update the template README only to link to the host once the host actually
passes the acceptance tests.

Do **not** delete, rename, replace, or weaken any of these existing assets:

* `blank_working_example/`
* `framework_reference_4.1.1/`
* the standalone Wasteland Animal 4.1.1 tool or its release history
* `../bit_wrecked_offense_weapons_design/`
* `../bit_wrecked_offense_weapons_solution/`
* recovery artifacts, recipe catalog, license, release templates, or archive
  material

The host is a new layer. Existing standalone tools remain runnable reference
and fallback tools.

## Non-negotiable safety rules

Initial host build is **read-only with one exception**: optional persistent
activity logging may write to a local file explicitly chosen by the user.

The initial host and all three initial adapters must not:

* create, copy, overwrite, rename, move, or delete game/mod files;
* create a Mods folder;
* install, uninstall, package, publish, or restore a mod;
* modify `serverconfig.xml`, caps, XML settings, saves, or player data;
* download anything, call a network service, collect telemetry, use an
  account, or require a browser;
* request elevation, bypass execution policy, use encoded commands, or add
  persistence;
* dynamically execute arbitrary module scripts discovered from a folder.

The registry must use an explicit allowlist of shipped module definitions. A
random `.ps1` file placed beside the host must never appear in the dropdown or
run automatically.

## Required user experience

### Stable host shell

The host reuses the polished native layout language already established by the
template: Bit Wrecked header, status card, game-folder selection, five-column
center workspace, lower action area, and expandable reasoning log.

Implement the performance, lazy-rendering, information-architecture, and
accessibility rules in `MODULE_HOST_UX_AND_PERFORMANCE_GUIDANCE_0.0.1.md`.
Those rules are part of acceptance criteria, not optional polish.

Add a clear module selector in the stable shell. It must display both module
name and state, for example:

```text
Module: [ Blank Framework - Read-only             v ]
        [ Wasteland Animals 4.1.1 - Read-only      ]
        [ Offense Weapons - Design / No Payload    ]
```

The selected module name and state must also appear in the status area and
center workspace. A player must never need to infer which module is active.

### Page movement

Selecting a dropdown entry swaps only the center module workspace. The outer
host shell, chosen game folder, and activity log remain alive.

Switching modules must:

1. Add a `[Host]` log entry naming the old and new module.
2. Ask the new module to render itself from its own session state.
3. Never validate, write, install, remove, or carry an action into the new
   module automatically.
4. Preserve each module's in-session selection state separately when that
   module has any state to preserve.

### Continuous log

Every entry must have a label:

```text
[Host] Active module changed: Blank Framework -> Wasteland Animals 4.1.1.
[Wasteland Animals 4.1.1] Read-only validation: selected game folder recognized.
[Offense Weapons] Design workspace loaded: no approved rows exist.
```

The log is runtime-only by default. If persistent logging is enabled, retain
the existing explicit file chooser and consent behavior. The selected log path
is the sole initial host write boundary.

## Module contract

Implement a small, explicit PowerShell module-definition contract. It may be a
`[pscustomobject]` or hashtable, but every registered module must provide the
same required fields and hooks.

Minimum definition:

```text
Id                  Stable internal ID, e.g. wasteland_animals_411
DisplayName         Player-facing name
Version             Module version or reference version
State               design | read_only | actionable
Description         Plain-language purpose and boundary
SupportedGameBuild  Declared supported game build or reference scope
RenderWorkspace     Hook: render center controls only
ValidateReadOnly    Hook: inspect selected game folder with no writes
GetActionState      Hook: explain visible action availability
SessionState        Module-owned in-memory state only
LineItemReference   Relative document path or explicit “none”
WriteBoundary       Human-readable file boundary or “none in this build”
RecoveryReference   Relative recovery/manifest document path
```

The host must validate every definition at startup. If a field or required hook
is missing, the module must not appear as selectable; log a clear host error
instead.

Hooks receive a narrow host context containing only:

```text
SelectedGameRoot
WorkspacePanel
ModuleSessionState
Log(message, severity)
RequestUiRefresh()
```

Module hooks may create controls only inside `WorkspacePanel`. They may not
replace the host header, module selector, main action controls, activity log,
or persistent-log settings directly.

## Initial module definitions

### 1. Blank Framework

* State: `read_only`.
* Center: generic five-column empty workspace.
* Validation: recognize a selected game folder; report that no payload exists.
* Action state: Install/Remove unavailable because no line-item map or payload
  exists.
* Write boundary: none.

### 2. Wasteland Animal Population Tuning 4.1.1

* State: `read_only`.
* Center: load visible animal items/rows and their descriptive columns through
  an adapter. The player must be able to see this is the Wasteland Animals
  module, not a generic list.
* Validation: extract or reproduce only verified read-only behavior from the
  standalone source after comparing it. Reads may inspect the selected game
  folder and relevant installed mod/config state.
* Action state: every write-capable behavior—including Install, Reinstall,
  Remove, cap change, restore, or backup—is visibly unavailable with a plain
  reason: `Standalone 4.1.1 tool remains the approved action path during host
  parity work.`
* Write boundary: none in this host phase.
* Fallback: the standalone 4.1.1 tool remains the only actionable animal tool.

Do not dot-source or launch the monolithic standalone GUI inside the host.
Extract only pure read helpers after reviewing their dependencies. If an animal
read routine cannot be isolated without bringing write behavior or hidden
state with it, do not use it; report the gap and render an honest unavailable
state instead.

### 3. Offense Weapons

* State: `design`.
* Center: the deliberately empty weapons-design workspace with its current
  labels and no feature rows.
* Validation: optional selected-game-folder recognition only.
* Action state: Install and Remove unavailable because no approved payload
  exists.
* Write boundary: none, apart from optional user-selected persistent log.
* Source of future rows:
  `../bit_wrecked_offense_weapons_solution/versions/0.0.1/OFFENSE_WEAPONS_LINE_ITEM_MAP_0.0.1.md`.

Do not turn the weapon evidence map into XML, gameplay, or installer behavior
in this task.

## Build phases

### Phase 0 — Compare and map

Read the required sources. Produce the comparison matrix. List all Wasteland
functions or UI blocks relevant to selection, validation, actions, log,
optional cap, restore, and file boundaries. Mark each as host, read-only
adapter, actionable later, or standalone-only.

**Gate:** No implementation of Wasteland behavior before the matrix exists.

### Phase 1 — Host registry and shell

Build the native host shell, explicit module registry, dropdown, center-panel
swap mechanism, tagged log, per-module in-memory session state, and
`-SmokeTest` support.

Implement Blank Framework first. Confirm dropdown switching is safe even when
only one healthy module is registered.

**Gate:** Selecting modules changes no game/mod files. The host works from the
Steam `Program Files (x86)` path through its `.bat` launcher.

### Phase 2 — Design-only weapons adapter

Register the empty Offense Weapons module. It may render a clean, visibly
design-only workspace and log its state. It must not render imagined weapon
rows or enable actions.

**Gate:** Its central empty state is honest and identical in meaning to the
existing weapons design shell.

### Phase 3 — Wasteland read-only adapter

Implement the animal adapter only after the source comparison. It must render
actual, evidence-backed animal items and read-only validation output. Preserve
the standalone visual/behavior reference for side-by-side comparison.

**Gate:** The host cannot perform any existing animal write action. The animal
adapter's displayed state and warnings agree with the standalone tool for the
tested scenarios.

### Phase 4 — Parity report and decision point

Create `MODULE_HOST_IMPLEMENTATION_REPORT_0.0.1.md` containing:

* files created/changed;
* module contract shape;
* comparison-matrix conclusions;
* test scenarios and results;
* known gaps and intentionally withheld actions;
* an explicit recommendation: continue action parity, keep read-only, or stop.

Do not advance a single write action merely because the UI now resembles the
standalone tool. That requires a separate, module-specific approval.

## Required tests

Create repeatable host tests. At minimum, prove:

| Test | Expected result |
| --- | --- |
| Host parses | All host and adapter PowerShell files parse with zero errors. |
| Smoke test | Host opens, registers available modules, selects/renders them, then closes automatically. |
| Batch launch | Launcher works from a path containing `Program Files (x86)`. |
| Blank module | Renders empty generic workspace; no writes. |
| Weapons module | Renders design state; no rows or write actions. |
| Animal module | Renders read-only animal data or an honest unavailable state; no writes. |
| Module switching | Changes only center workspace; preserves host log and does not write. |
| Invalid game folder | Reports clearly; no exception, no write. |
| Valid game folder | Validates read-only; no Mods folder creation. |
| Persistent log off | No file is written. |
| Persistent log on | Only the explicitly selected log file is written. |
| Performance | Cold start, module switching, and explicit validation are measured against the local targets in the UX/performance guidance. |
| Accessibility | Keyboard-only, high-contrast, DPI, focus-order, and dynamic-control accessible-name checks pass. |
| Static safety scan | Initial host/adapters contain no game-file mutation, network, elevation, encoded command, or auto-discovery path. |
| Standalone preservation | Original animal tool and weapons design shell still exist and remain runnable. |

For every test that touches a real game folder, record the exact expected write
count as **zero**. Use a temporary fixture or explicit read-only checks when
possible; do not use a player's live installation as a destructive test target.

## Acceptance criteria

The infrastructure build is complete only when all of these are true:

* The host starts through its named `.bat` launcher.
* The dropdown visibly selects Blank Framework, Wasteland Animals 4.1.1, and
  Offense Weapons with clear module states.
* Each choice renders only its own center workspace.
* The log persists through module changes and labels every entry.
* The initial host has zero game/mod write paths except optional selected-log
  output.
* The Wasteland module is demonstrably read-only and its original standalone
  tool remains unchanged.
* The weapons module remains design-only.
* The comparison matrix and implementation report exist and contain no
  unsupported parity claim.
* Recovery materials are refreshed only after implementation and verification
  are complete.

## Stop conditions

Stop and report instead of guessing if:

* the Wasteland behavior cannot be split into safe read-only helpers;
* a required source/payload/document cannot be found or its ownership is
  unclear;
* matching the standalone UI would require invoking its write routines;
* an adapter needs a broader file permission than its declared boundary;
* a proposed shared action blurs ownership between modules;
* the work would alter the standalone animal mod, the weapons payload, game
  files, or public release materials.

## Definition of clean work

Clean work means the host can be trusted precisely because it does less than
the standalone tools at first. It earns breadth through explicit adapters and
parity evidence, not through a large script that claims it can manage
everything.
