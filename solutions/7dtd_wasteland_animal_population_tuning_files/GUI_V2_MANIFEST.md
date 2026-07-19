# GUI V2 Work Manifest

## Review Status

**Ready for owner GUI review.** The minimalist 4.1.x clarity pass is implemented
and its non-mutating checks pass. It is not yet a release candidate: the
technical-freeze gate correctly detects the authorized GUI source change and
must be reconciled in a separately approved release-governance step after owner
acceptance.

No build, promotion, upload, tag, or publication was performed.

## Purpose And Scope

This pass answers direct user questions through labels, visible guidance,
tooltips, and accessible descriptions. It does not change XML, tuning values,
cap behavior, backup behavior, restore behavior, removal behavior, or package
contracts. Historical 4.0.1 artifacts were not modified.

## User Question Results

| User question | Result | Verified answer |
|---|---|---|
| Does the check action refresh the visible Current values? | PASS | `Compare Values` performs a fresh read and opens a read-only report. It does not refresh the visible table or write files. |
| What does Brutal Science mean? | PASS | It is an explicit stress-test option that confirms the risk, backs up `serverconfig.xml`, and raises `MaxSpawnedAnimals` to `999`. It does not create animals by itself. |
| Does clicking the directory run the mod? | PASS | Clicking or editing the path field only focuses or changes the selected path. It does not install, launch, or run anything. |
| Where does Browse go? | PASS | `Choose Game Folder` opens a Windows folder chooser for the 7 Days to Die game root, starting at the current valid path when available. |
| Is Restore Cap tied to the Brutal Science checkbox or game defaults? | PASS | No current checkbox selection is required. Restore Cap uses the newest matching Bit Wrecked backup and does not force a hard-coded default. |
| Do Choose Game Folder and Mods Folder go to the same place? | PASS | No. Choose Game Folder selects the game root; Mods Folder opens `<game root>\Mods` in Explorer and creates it first when absent. |
| What is Remove Mod versus Restore Cap? | PASS | Remove Mod deletes only this solution's mod folder. Restore Cap restores `serverconfig.xml` from the newest matching backup. Neither action silently performs the other. |
| What is the purpose of Select animals to tune? | PASS | The animal checkboxes choose the entities included in the next install/reinstall; selecting one enables its tuning slider, and All applies one shared level to all. |

## Final Labels And Clarity Changes

- `Choose Game Folder`
- `Compare Values` (replaces the potentially misleading `Check Current`)
- `Brutal Science`
- `Restore Cap`
- `Remove Mod`
- `Mods Folder`
- `Select animals to tune`

The folder chooser was widened for label fit. The cap panel now states that
Brutal Science creates a backup before setting the cap to 999 and that Restore
Cap and Remove Mod are separate actions. Concise tooltips and accessible
names/descriptions explain the clarified controls and animal checkboxes.

## Layout And Accessibility Review

- Current-system visual capture: all controls and explanatory text are visible;
  no label clipping or overlap was observed at approximately 175% scaling on a
  3840 x 2160 display.
- DPI-adjusted WinForms text measurement left at least 54 physical pixels of
  horizontal control width beyond the measured text for the two longest action
  labels (`Choose Game Folder` and `Compare Values`) on the current system.
- Spacing and action grouping keep folder selection, comparison, cap restore,
  mod removal, and Mods-folder navigation distinct.
- Keyboard-only navigation, Narrator, high contrast, and smaller-screen display
  configurations still require owner/manual validation. No broad layout rewrite
  was made in this clarity-only pass.

## Validation Commands And Results

| Validation | Result |
|---|---|
| PowerShell parser on both GUI source copies | PASS: zero parse errors |
| `-SmokeTest` against the repo-side GUI | PASS: exit code 0 |
| `-SmokeTest` against the game-side DEV GUI | PASS: exit code 0 |
| SHA256 comparison of repo-side and game-side DEV GUI files | PASS: both `669F675BC6D827A264B40B13AE50D57B0695F9C6CBC72E5EE612E6C1C3798EF9` |
| WinForms label measurement and visual capture | PASS on the current display; no clipping or overlap observed |
| `pwsh -NoProfile -File tests/release/Invoke-OfflineTests.ps1` | 27 PASS, 2 expected gate failures |

The two full-suite failures are both caused by
`BW-PKG-TECHNICAL-FREEZE`: the frozen package contract currently permits only
version-metadata changes in the GUI source. All other schema, semantic,
historical-hash, baseline, parser, XML, line-ending, deterministic ZIP,
malicious-ZIP, `WhatIf`, staging, atomic-prepare, and legacy-rebuild checks
passed. The freeze result is a governance handoff, not a runtime or GUI defect.

## Exact Files Changed For This Pass

Repo-side review record and source:

- `GUI_FEEDBACK_V2.md`
- `GUI_V2_MANIFEST.md`
- `Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1`
- `Support_Files_Do_Not_Edit/CHANGELOG.md`

Matching game-side DEV working copy:

- `_game_dev_ai_tracking/solutions/7dtd_wasteland_animal_population_tuning_files/GUI_FEEDBACK_V2.md`
- `_game_dev_ai_tracking/solutions/7dtd_wasteland_animal_population_tuning_files/GUI_V2_MANIFEST.md`
- `_game_dev_ai_tracking/solutions/7dtd_wasteland_animal_population_tuning_files/Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1`
- `_game_dev_ai_tracking/solutions/7dtd_wasteland_animal_population_tuning_files/Support_Files_Do_Not_Edit/CHANGELOG.md`

## Owner Handoff

Review the rendered GUI and the question-by-question answers. If accepted,
authorize the separate governance/freeze update needed to admit this GUI-only
delta, then rerun the full offline gate before any candidate preparation.
