# Offense Weapons 0.0.1 — Framework Normalization Manifest

Status: Planning and conversion guide
Scope: Convert the copied Wasteland Animal Population Tuning framework into a
neutral framework capable of accepting an Offense Weapons payload
Implementation authorization: Framework normalization only; no weapon payload
or public release is authorized by this document

## Purpose

The Offense Weapons solution began as a complete copy of the proven Wasteland
Animal Population Tuning framework. That is intentional: the copy preserves the
working GUI, installation, validation, removal, packaging, and recovery shape.

Before a weapon payload is added, the copied framework must be normalized. In
this context, normalization means removing animal-specific identity and
assumptions from the active working files while keeping the reusable operational
recipes intact.

Normalization does not mean deleting history. The original animal solution
remains authoritative, and copied historical version lanes are retained under
`framework_archive/` for reference and disaster recovery.

## Desired end state

After normalization:

* `versions/0.0.1` is the only active Offense Weapons version lane.
* The active source carries no animal-specific product identity.
* Framework behaviors remain reusable and explicit.
* The active tool is neutral until its weapon rows and payload are implemented.
* A future launcher starts only the new weapon tool, never the copied animal
  tool.
* The normal XML modlet remains the core product; GUI tooling remains optional.
* Archived animal materials remain available but cannot be mistaken for an
  Offense Weapons release.

## Non-goals

This pass must not:

* Implement the Electric, Explosive, or Burn/Fire payload.
* Invent new weapon values.
* Change the live game installation.
* Change the finished animal solution.
* Package, upload, publish, tag, or release the weapon mod.
* Delete the framework archive.
* Convert the tool into a general XML editor.

## Source-of-truth structure

```text
_game_dev_ai_tracking/solutions/
├── 7dtd_wasteland_animal_population_tuning_files/
│   └── authoritative completed reference solution
└── bit_wrecked_offense_weapons_solution/
    ├── versions/
    │   └── 0.0.1/                         active Offense Weapons lane
    ├── framework_archive/
    │   └── wasteland_animal_reference_versions/
    │       └── 4.x copies for reference and DR only
    ├── Support_Files_Do_Not_Edit/          copied framework, to normalize
    └── Upload_To_Nexus/                    inactive until a weapon release
```

The original animal solution is the authoritative record of animal behavior.
The `framework_archive` copies are secondary recovery/reference material. The
new Offense Weapons active lane is independent; it inherits a framework, not
the animal mod's release history or gameplay claim.

## Preserve these eleven framework recipes

The following recipe behaviors are the reusable framework contract. Preserve
their purpose and safety boundaries even when their labels and payload-specific
rules change.

1. Choose Game Folder
2. Inspect and Validate Current State
3. Select Settings
4. Install or Reinstall
5. Selective Uninstall
6. Independent Cap or Stress-Test Action, only when a future payload needs it
7. Restore Saved Global State, only when a future payload needs it
8. Runtime and Persistent Logging
9. Confirmation and Local Assessment
10. Validate, Package, and Release
11. Disaster Recovery

Recipes 6 and 7 are not automatically part of Offense Weapons. The current
animal-specific global spawn-cap flow must be removed from the active weapon
tool unless a separately validated weapon-owned global setting later justifies
an equivalent feature.

## Normalization sequence

Perform these steps in order. Complete and verify each step before beginning the
next one.

### Step 1 — Freeze the reference boundary

* Confirm the animal solution remains untouched.
* Confirm `framework_archive/README.md` identifies the copied 4.x lanes as
  reference/DR only.
* Confirm `versions/` contains only `0.0.1` as an active weapon lane.
* Record the copied source files used as the framework basis.

Acceptance: A reviewer can tell which files are active weapons work and which
files are animal history without reading source code.

### Step 2 — Create neutral product identity

Replace animal-specific identity in active root files with temporary neutral
Offense Weapons identity:

* Folder and internal package names
* Launcher name
* GUI tool filename
* Script filenames
* `ModInfo.xml` name, display name, description, and version
* README title and first-read text
* Validation pass/fail messages
* Archive names
* Logs, backup names, and generated-folder names
* Documentation titles and metadata

Use a temporary internal identifier if the public product name is not yet
chosen. Do not retain `WastelandAnimal`, `AnimalPopulation`, or animal-specific
package names in any active executable path or public-facing label.

Acceptance: Invoking an active launcher or reading active metadata cannot imply
that the user is installing an animal mod.

### Step 3 — Separate generic UI from animal UI

Retain generic UI behavior:

* Game-folder selection
* Open Mods Folder
* Read-only validation entry point
* Pending-selection model
* Confirmation dialog pattern
* Activity log pane
* Persistent-log consent flow
* Install/reinstall and selective-uninstall action model
* Error display and close behavior

Remove or disable animal-only UI behavior:

* Animal selection rows
* Population-level sliders
* Animal-specific All selection
* Wasteland animal wording
* Global animal-cap display
* Brutal Science control and related explanations
* Animal-cap restore controls
* Animal-specific local assessment inputs

Until weapon rows exist, the normalized UI should state that the weapon payload
is not installed or configured. It must not present empty animal controls or a
misleading active install action.

Acceptance: The neutral tool can open and inspect a chosen game folder without
writing game files or presenting animal-specific actions.

### Step 4 — Replace payload assumptions with a line-item contract

The normalized framework must not hard-code animal XML targets. Replace its
payload model with a neutral row contract:

| Field | Meaning |
|---|---|
| Row ID | Stable internal identifier |
| Effect heading | UI grouping only |
| User row label | Exact player-facing target name |
| Source file | XML file to patch |
| XPath/patch target | Exact owned target |
| Baseline shape | Default/current-game reference |
| Fixed value set | Validated payload values |
| Dependencies | Shared buffs, cooldowns, requirements, tags, or effects |
| Installed state | Detected presence/absence of this row |
| Removal state | Exact default-restoration behavior |

The `OFFENSE_WEAPONS_LINE_ITEM_MAP_0.0.1.md` is the first source for this
contract. It currently covers the Electric spear and shotgun rows only.

Acceptance: Every future active UI row can be traced to a line-item-map entry.
No UI heading or row is allowed to create universal behavior by inference.

### Step 5 — Normalize install and selective-uninstall ownership

The animal framework writes and removes an owned mod folder. Retain that owned
folder model, but replace animal-specific payload generation with row-aware
ownership.

Install/reinstall must:

* Generate only selected Offense Weapons patches.
* Include shared dependencies only when selected rows reference them.
* Back up only the files/settings the tool owns or must safely restore.
* Verify the generated modlet before reporting success.

Selective uninstall must:

* Remove only deselected Offense Weapons rows.
* Keep a shared buff or cooldown while any installed row still references it.
* Remove a shared dependency only after its last dependent row is removed.
* Remove the owned mod folder only when no installed weapon rows remain.
* Never alter unrelated mods, vanilla files, animal tuning, loot, trader,
  crafting, or progression files.

Acceptance: A mixed selection can add one row, retain one row, and remove one
row without breaking shared electrical dependencies.

### Step 6 — Normalize validation

Validation must remain read-only and should report exact row state, not generic
weapon-family conclusions.

For each row, report:

* Row label and internal Row ID
* Source file and XPath/target
* Baseline/default shape
* Current detected shape
* Installed generated-patch state
* Shared dependency state
* Selected pending action, if applicable
* Expected result: install, keep, remove, or unavailable

Validation must also report missing XML targets and version incompatibilities as
facts. It must not direct the user to take a next action inside the report.

Acceptance: A user can distinguish “not installed,” “installed,” “partially
installed,” “target changed upstream,” and “shared dependency still required.”

### Step 7 — Normalize confirmation, logging, and assessment

Retain:

* Explicit confirmation before writing files
* Clear list of pending add/keep/remove actions
* Runtime action history
* Optional persistent log with explicit consent
* Deterministic file facts separated from optional local commentary

Replace animal-specific confirmation text and assessment variables with exact
weapon row names and effect descriptions. Any future generated assessment must
be local, non-networked, non-telemetry, and secondary to the factual summary.

Acceptance: The confirmation says exactly which weapon effects will change and
does not mention animals, Wasteland population, or a global animal cap.

### Step 8 — Normalize packaging and release artifacts

Keep the existing package recipe but make all output weapon-specific:

* Full package archive
* No-scripts modlet archive
* Vortex-compatible archive, if retained after compatibility review
* Hash file
* Release notes
* Readme and install instructions
* License and attribution material
* Package metadata

The no-scripts XML modlet must remain the core public package. The GUI helper is
optional and must not be required for a manual or server install.

Do not generate or publish final archives during normalization.

Acceptance: Validation scripts and package names describe only the neutral/new
weapon product, not the animal product.

### Step 9 — Normalize disaster recovery

Keep the DR pattern, but replace animal-specific targets with an ownership map
for Offense Weapons.

The normalized recovery documentation must state:

* The exact owned modlet folder
* Generated payload files
* Backup location and naming pattern
* How to isolate a failed weapon modlet
* How to return to game defaults by removing the owned modlet
* How to keep saves/worlds separate from modlet recovery
* How to restore a known-good package without overwriting the entire game

Acceptance: A user can recover from a failed Offense Weapons install without
consulting animal-mod instructions.

## File disposition guide

| Current copied material | Normalization disposition |
|---|---|
| Animal 4.x version lanes | Preserve under `framework_archive/` only |
| Animal launcher `.bat` | Replace with a neutral/new weapon launcher after the new tool exists |
| Animal GUI PowerShell tool | Keep as code reference until a weapon-named tool is created; do not expose as active launcher |
| Animal XML payload | Keep as reference only; replace with weapon payload generated from line-item map |
| Animal manifests and feedback | Preserve as reference/DR material; do not treat as active weapon requirements |
| Generic license material | Preserve, then update names/attribution where product identity appears |
| Generic validation/package mechanics | Preserve and retarget to weapon identity and line-item validation |
| Upload archives | Preserve as historical framework examples; do not publish or relabel them as weapons |

## Normalization verification checklist

Before weapon payload implementation begins, verify:

* [ ] `versions/` contains only Offense Weapons lanes.
* [ ] Archived animal lanes are outside the active version history.
* [ ] Active identity does not use an animal product name.
* [ ] Active launcher does not start an animal tool.
* [ ] Active UI contains no animal selection, population slider, or animal-cap flow.
* [ ] Normalized UI is safe to open and validate without writing files.
* [ ] A neutral row contract exists and points to the line-item map.
* [ ] Install/uninstall ownership rules account for shared dependencies.
* [ ] Validation is row-specific and read-only.
* [ ] Package/DR documentation uses weapon-neutral or weapon-specific language.
* [ ] No release archive is created or published.

## Handoff after normalization

Once the checklist passes, the next implementation manifest may:

1. Convert the Electric line-item map into exact modlet patches.
2. Add the seven initial Electric rows to the normalized GUI.
3. Implement shared-buff ownership handling.
4. Validate install, selective uninstall, and removal.
5. Add Explosive and Burn/Fire rows only after their own exact maps are complete.

This order protects the point-and-click simplicity of the framework while
keeping the technical payload exact and reversible.
