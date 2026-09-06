# Module Host Comparison Matrix 0.0.1

**Status:** Phase 0 comparison gate complete.

**Decision boundary:** This document authorizes only the read-only host and
adapter work in `MODULE_HOST_INFRASTRUCTURE_BUILD_HANDOFF_0.0.1.md`. It does not
authorize installation, removal, restore, packaging, or gameplay payload work.

## Sources compared

- Generic shell:
  `blank_working_example/Blank_BitWreckedMod_Tool.ps1`
- Wasteland reference:
  `framework_reference_4.1.1/Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1`
- Wasteland product contract:
  `framework_reference_4.1.1/README_FIRST.txt` and
  `framework_reference_4.1.1/GUI_V3_MANIFEST_4.1.1.md`
- Weapons shell:
  `../bit_wrecked_offense_weapons_design/blank_working_example/Blank_BitWreckedMod_Tool.ps1`
- Weapons design contract:
  `../bit_wrecked_offense_weapons_design/WEAPONS_DESIGN_SHELL_MANIFEST.md`
- Future weapons evidence boundary:
  `../bit_wrecked_offense_weapons_solution/versions/0.0.1/OFFENSE_WEAPONS_LINE_ITEM_MAP_0.0.1.md`

The Wasteland reference script was read in full. Its SHA-256 at this gate is:

```text
168F333A8D5A4C9CA150A40205DF2E148207DE2D1D3F978E7884E45B7C425FEF
```

The weapons shell is the same 753-line shell as the generic example except for
the intended product identity and empty-state wording. This supports one host
shell with small module definitions rather than copied GUIs.

## Three-way interface and behavior matrix

| Concern | Generic template shell | Wasteland 4.1.1 standalone | Weapons design shell | Host decision |
| --- | --- | --- | --- | --- |
| Header and identity | Bit Wrecked, `7DTD Mod Framework`, neutral 0.0.1 design state. | Bit Wrecked, Wasteland product name, 4.1.1, What's New link. | Same geometry with Offense Weapons identity and design state. | **Host-owned.** Stable brand plus active-module name/version/state from metadata. No copied form per module. |
| Selected game-folder handling | One textbox/chooser; recognizes `7DaysToDie.exe`; selecting does not write. | Same base recognition, but path text changes immediately rebuild/read visible state. | Same as generic. | **Host-owned.** Store one path. Explicit selection may recognize the executable; module switching never validates. Module reads require Validate. |
| Status presentation | Status card plus recent-action line; design/no-payload wording. | Installed/not-installed card plus action status and log. | Status card with weapons/no-payload wording. | **Host-owned chrome; module-owned result text.** State always includes module name and `design`/`read_only`. |
| Center table/rows | Empty `Feature Group | Control | Action | Current | Result`. | Dynamic `Animal Selection | Population Level | Action | Current | Result` with All plus five animal rows. | Empty `Weapon Effect | Control | Action | Current | Result`. | **Adapter renderers.** Blank and Weapons remain empty. Wasteland shows the five evidence-backed reference animals as non-actionable read-only rows and applies explicit validation snapshots. |
| Validation reads | Only verifies `7DaysToDie.exe`; no payload exists. | Reads live entitygroups, installed entitygroups, cap/backup state; existing report mixes GUI state and generated commentary and does not fully verify spawning/version. | Same folder-only recognition as generic. | **Adapter read-only.** Use deterministic structured results. Wasteland checks live shape, installed ModInfo/version, entitygroups, spawning, cap, and provenance without silent fallback claims. |
| Install/reinstall | Disabled; no implementation. | Copies modlet, generates two XML files, verifies, and may also modify cap. | Disabled; no implementation. | **Adapter actionable later.** Entirely absent from host 0.0.1. |
| Selective removal | None. | Unchecked installed rows can rewrite XML or remove final owned folder. | None. | **Adapter actionable later.** Withheld until a separately approved ownership/parity phase. |
| Full removal | Disabled. | Deletes only the owned Wasteland mod folder after confirmation. | Disabled. | **Adapter actionable later.** Standalone 4.1.1 remains the approved path. |
| Optional global-cap behavior | Undefined reserved control. | Reads, backs up, raises, and verifies `MaxSpawnedAnimals`; cap-only path exists. | Undefined reserved control. | Cap reads are **Adapter read-only**. Backup/write/apply behavior is **Adapter actionable later**. No reserved host control. |
| Restore behavior | None. | Replaces `serverconfig.xml` from newest matching backup and verifies saved value. | None. | **Adapter actionable later.** Host may report backup/current state but exposes no restore action. |
| Runtime log | Expandable RichTextBox; runtime only by default. | Expandable layered log with validation, confirmation, tooltip, and change entries. | Same as generic with weapons identity. | **Host-owned.** One bounded visible session log; every entry tagged Host or module. No generated opinions in 0.0.1. |
| Persistent-log consent | User chooses path; persistence checkbox controls writes. | Explicit consent, independent Save dialog, saved history kept current; disabling does not delete file. | Same generic mechanism. | **Host-owned.** Sole permitted write. Off by default; explicit consent and user-chosen file required; disabling never deletes it. |
| Open Mods Folder | Opens only an existing Mods folder and refuses to create it. | Creates Mods if missing and opens Explorer. | Opens only an existing Mods folder. | **Standalone-only initially.** Omitted from host 0.0.1 so the host has no folder-creation path or unrelated process action. |
| Release/recovery boundary | Template and DR source, not a release. | Independent release-ready 4.1.1 package/reference. | Independent design clone with frozen reference. | **Independent.** Host is a new layer. Existing products, archives, and release histories remain untouched. |

## Wasteland function and UI classification

Line numbers refer to the frozen 4.1.1 PowerShell reference named above.

| Behavior or source block | Evidence | Classification for host 0.0.1 |
| --- | --- | --- |
| Common game-root recognition | `Get-DefaultGameRoot`, `Test-GameRoot` (23-37) | **Host-owned** common recognition. Do not auto-scan at startup. |
| Target mod path and folder presence | `Get-TargetModPath`, `Test-ModInstalled` (39-50) | **Adapter read-only**, but folder presence alone is not a verified installation. |
| Cap and backup reads | 52-129 | **Adapter read-only**, with explicit missing/malformed results. |
| Cap backup/write | `Set-BrutalScienceAnimalCap` (131-189) | **Adapter actionable later**; excluded from host. |
| Cap restore | `Restore-BrutalScienceAnimalCapBackup` (191-229) | **Adapter actionable later**; excluded from host. |
| Tuning calculations | 231-351 | **Standalone-only for this phase.** Deterministic reference logic, but no host tuning controls are authorized. |
| Frozen row/route references | 353-427 | **Adapter read-only reference data**, clearly labeled reference when live shape is unavailable. |
| Live baseline readers | 459-577 | **Adapter read-only**, rewritten with provenance and strict error reporting. |
| XML generation and pressure-route calculation | 591-861 | **Adapter actionable later**; not needed to render/read current state. |
| XML/config writes and install | 863-941 | **Adapter actionable later**; excluded from host. |
| Full uninstall | 943-956 | **Adapter actionable later**; excluded from host. |
| Standalone log and persistent writer | 958-1088, 2174-2472 | **Host-owned concept.** Do not reuse GUI globals. |
| Generated confirmation/opinion/assessment | 1090-1360 | **Standalone-only initially.** Random/cached commentary is not read-only parity evidence. |
| Header/status/path UI | 1602-1868 | **Host-owned shell.** Module supplies identity and result data only. |
| Animal table schema and dynamic rows | 1863-2011, 2474-2829 | **Adapter read-only renderer.** No checkboxes/sliders that imply an available action. |
| Install/remove/cap controls | 2013-2172, 3308-3665 | **Adapter actionable later.** Not rendered in host 0.0.1. |
| Installed entitygroup value reader | `Get-InstalledPatchValueMap` (3049-3066) | **Adapter read-only**, made strict: duplicates and malformed files must be reported. |
| Existing validation report | 3068-3279 | **Adapter read-only concept, refactor required.** Do not copy wholesale. |
| Validate click orchestration | 3673-3695 | **Host-owned invocation plus adapter read result.** No modal generated-opinion dependency. |
| Remove, restore, Open Mods handlers | 3702-3785 | **Standalone-only in 0.0.1.** |

## Why the standalone validation cannot be copied wholesale

The existing `New-ScanValuesReport` is useful reference behavior, but it is not
a pure adapter seam:

- It calls GUI-dependent `Get-ChoiceImpactText`.
- It calls randomized/cached gameplay assessment code.
- Visible-current helpers depend on `$pathBox` and suppress installed-config
  read errors, sometimes presenting base values instead.
- Mod presence is inferred from a directory, not verified ModInfo/config shape.
- Installed spawning XML and pressure routes are not fully included in its
  current/drift conclusion.
- Installed `ModInfo.xml` and exact version 4.1.1 are not checked.
- Duplicate installed XPath entries can collapse into a hashtable.
- Missing live XML silently activates fallback rows; the host must identify
  fallback data as `4.1.1 reference baseline`, not live evidence.

The host adapter therefore uses this deterministic seam:

```text
Get-Wasteland411ReferenceRows()
Read-Wasteland411LiveBaseline(GameRoot)
Read-Wasteland411InstalledState(GameRoot)
Read-Wasteland411GlobalCapState(GameRoot)
Compare-Wasteland411State(Baseline, Installed)
New-Wasteland411ReadOnlySnapshot(GameRoot)
```

The returned snapshot names its provenance and distinguishes `Missing`,
`Missing`, `ExactReference`, `PresentRecognizedUnverified`, `PresentInvalid`,
and `Drift`. Live XML separately reports `Live` or `ShapeMismatch`; the host
result reports `success`, `invalid`, or honest `unavailable`. Only the frozen
reviewed 4.1.1 package can be `ExactReference`. A structurally recognized
custom generation is never promoted to verified parity by this adapter.
The renderer and log remain outside these readers.

## Complete standalone mutation inventory

These reference-tool operations are deliberately excluded from the host:

| Reference line | Mutation |
| ---: | --- |
| 158 | Copy `serverconfig.xml` to a backup. |
| 177 | Overwrite `serverconfig.xml`. |
| 218 | Restore `serverconfig.xml` from backup. |
| 882, 908 | Write generated mod XML. |
| 935 | Create `Mods`. |
| 936 | Copy the modlet. |
| 952 | Recursively delete the owned mod folder. |
| 3777 | Create `Mods` from Open Mods Folder. |
| 3778 | Launch Explorer. |

Reference line 996 writes the explicitly selected persistent activity log. An
isolated equivalent is the sole permitted host write.

## Compatibility declaration

Host runtime target:

```text
Windows 10/11; Windows PowerShell 5.1; STA; local WinForms/System.Drawing.
```

Wasteland adapter reference scope:

```text
7 Days to Die 3.0-era Windows/Steam reference. Exact compatibility requires
live e/n/p entitygroup shape and Wasteland spawning-route shape validation.
```

The existence of `7DaysToDie.exe` recognizes a candidate game root. It does not
prove an exact compatible game build. The adapter must report shape/version
evidence separately.

## Required parity fixtures

1. Invalid root: no executable sentinel; unavailable; zero writes.
2. Valid live baseline, mod absent: five animals, exact day/night reference
   values and spawn routes, cap 50, source `Live`, zero writes.
3. Valid packaged 4.1.1 install: ModInfo 4.1.1, nine entitygroup set rows, four
   spawning set rows, no pressure routes, current.
4. Folder present but missing/malformed config: `PresentInvalid`, never current.
5. Valid config with wrong installed version: detected version is reported and
   parity is not claimed.
6. Entitygroup-only drift: exact XPath/value difference reported.
7. Spawning-only drift: spawning drift reported even when entitygroups match.
8. Cap history: current 999 plus newest readable backup 50; the difference is
   informational and does not claim that a restore is pending. No restore
   control exists. A malformed newest backup is explicitly unavailable.
9. Switching Blank -> Weapons -> Wasteland -> Blank: only center workspace and
   identity change; folder/log survive; no validation begins.
10. Full before/after fixture inventory: zero file or directory changes and no
    `Mods` directory creation when absent.
11. Unreviewed live animals, DTD-bearing XML, duplicate/unknown set targets,
    and foreign pressure-route append targets: unavailable or invalid, never
    parity-complete.
12. A reviewed-shape custom pressure route: recognized but unverified; its
    current values remain unavailable in the host.

## Gate conclusion

The comparison supports implementation. Blank and Weapons are thin render-only
definitions. Wasteland has a safe read-only data seam, but not a reusable
standalone validation function. Build a small strict adapter, preserve the
monolithic tool unchanged as reference/fallback, and withhold every action.
