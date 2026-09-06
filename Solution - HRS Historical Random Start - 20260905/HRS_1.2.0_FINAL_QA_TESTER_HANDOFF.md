# HRS 1.2.0 Final QA Tester Handoff

**Product:** Bit Wrecked Historical Random Start  
**QA Round:** Final release-candidate QA  
**Target:** 7 Days to Die V3.2 b9 / Navezgane  
**Release lane:** HRS 1.2.0  
**Purpose:** Exhaustive final validation of installation, UX, runtime behavior, safety boundaries, uninstall/reinstall lifecycle, persistence, and rollback before release.

## 1. QA Mission

Treat this build as a frozen release candidate.

The goal of this round is not to discover new features or redesign behavior. The goal is to prove that the features already intended for HRS 1.2.0 work consistently, safely, and predictably from a normal user path.

A good final pass means all intended user flows work, all safety gates fail closed, both approved production anchors are observed live, save/reload is stable, uninstall preserves saves/progress, and reinstall works without manual repair.

Any failure in destructive safety, live placement, progression continuity, or install/uninstall lifecycle is a release blocker.

## 2. Expected Release Candidate Identity

Use the exact repository revision handed off for QA.

Expected runtime DLL:
`hrs_1.2.0\dev\verified\main\d0163.dll`

Expected size:
`39936 bytes`

Expected SHA-256:
`DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507`

Expected verified ModInfo SHA-256:
`81A59FCE042FECAEF13102458517A28385BFC18947219CFD289C672BFB6013E8`

Expected supported Assembly-CSharp MVID:
`229796d0-95ca-4662-b426-1a6f1f1596ed`

Expected package identity:
- Name: `BitWrecked_HistoricalRandomStart`
- Display Name: `Historical Random Start - Alpha 6 Method`
- Version: `1.2.0`

Production Random selection is intentionally limited to NG01 and NG02. Additional scouting/catalog positions are not production-supported starts in this QA round.

## 3. User-Facing Entry Point

Always test the customer path first:

`hrs_1.2.0\START.bat`

Expected chain:

`START.bat -> dev\ui\p0158.ps1`

Do not manually copy the runtime into the game folder before normal install tests. Direct module calls may be used only for targeted safety/evidence checks after the user path has been exercised.

## 4. What SHOULD Work

### 4.1 Launcher / UI

Expected controls:
- New Game Name
- Standard
- Random
- Optional Random-only arrival-biome protection checkbox
- Apply
- Launch Game
- Uninstall Mod
- Detected game folder
- Status text

Expected behavior:
- Apply manages the selected start policy.
- Launch Game launches 7 Days to Die.
- Uninstall Mod is a separate destructive lifecycle action.
- Apply never becomes an uninstall button.
- RandomSafe remains backend terminology; the user sees Random plus optional arrival protection.

### 4.2 Standard Mode

With Standard selected and a valid exact new-game name:
- Apply succeeds.
- Policy is written for that exact game name.
- HRS random relocation does not run for that game.
- Normal game start behavior remains intact.
- Save/reload remains normal.

Standard is a policy state, not uninstall.

### 4.3 Random Mode

With Random selected and a valid exact new-game name:
- Apply succeeds.
- Policy binds to that exact game name.
- Matching new game performs the intended one-shot random placement.
- Chosen production location is NG01 or NG02 only.
- Runtime primes the selected catalog anchor after chunk availability.
- Terrain height resolves in a bounded way.
- Player is placed approximately two meters above resolved surface before grounding.
- Runtime requires stable grounded samples near catalog elevation before adopting actual surface.
- Player is not left buried, permanently floating, endlessly falling, or otherwise unusable.

### 4.4 Arrival-Biome Protection

When Random is selected and protection is checked:
- RandomSafe backend path is used.
- UI remains Random + checkbox, not a third primary mode.
- Arrival protection affects only intended safety behavior.
- Production catalog remains NG01/NG02 only.

### 4.5 One-Shot Behavior

For a qualifying new game:
- Relocation occurs once.
- No repeated reroll on later ticks.
- No repeated teleport.
- No new start selection on normal reload.
- Returning to the same save does not re-run the initial relocation transaction.

Any second relocation is a release blocker.

### 4.6 Trader / Starter Quest Continuity

After relocation:
- Opening trader logic completes correctly.
- Starter quest remains valid.
- Trader routing reflects the resulting start.
- Normal progression remains possible.

### 4.7 Health / Progression / Player State

After relocation:
- Health valid.
- Progression valid.
- Normal movement/control works.
- No unexplained death, permanent fall, stuck state, or corrupted spawn state.

### 4.8 Save / Reload

After initial HRS transaction:
- Save normally.
- Exit.
- Reload the same save.

Expected:
- No second relocation.
- No repeated HRS transaction.
- Position/progression sane.
- Starter quest/trader state usable.
- No HRS error loop.

## 5. Installation and Lifecycle Tests

### 5.1 Fresh Install

Start with no:
`Mods\BitWrecked_HistoricalRandomStart`

Expected:
1. Launch START.bat.
2. Enter valid exact new-game name.
3. Select Standard or Random.
4. Click Apply.
5. Confirm.
6. Verified runtime and ModInfo install.
7. Bridge/policy structure is created.
8. Post-install inventory is valid.
9. Status confirms selected policy.

PASS only if normal customer install succeeds without manual file copying.

### 5.2 Existing Valid Install

With current valid HRS already installed:
- UI recognizes setup as ready.
- Applying a new valid policy updates policy state.
- No duplicate/corrupt install.
- Runtime remains usable.

### 5.3 Uninstall

With recognized HRS present:
1. Close 7 Days to Die.
2. Open START.bat.
3. Click Uninstall Mod.
4. Confirmation must clearly state saved games and game progress will not be deleted.
5. On Yes, only owned HRS files are removed.
6. Bridge and release folders are removed when empty.
7. Saves/progress remain.
8. UI reports `Historical Random Start uninstalled`.
9. Readback reports NotInstalled / release root absent.

Normal owned files:
- `d0163.dll`
- `ModInfo.xml`
- `Bridge\policy.v1.json`
- `Bridge\result.v1.json` when present

### 5.4 Cancel Uninstall

At confirmation choose No:
- No files deleted.
- Status says canceled/no change made.
- HRS remains installed.

### 5.5 Reinstall After Uninstall

After successful uninstall:
- Launch START.bat.
- Enter new test game name.
- Select Random.
- Apply and confirm.

Expected:
- Fresh install succeeds.
- Policy writes.
- Runtime works live.
- Uninstall remains available.

This is the safe upgrade path for older installations in this release.

### 5.6 Older Owned HRS Install

Older HRS runtime should still be uninstallable if ownership is clearly established:
- only known HRS directories
- only known HRS file names
- exact ModInfo identity
- no reparse points
- no unknown files

Current DLL hash does not need to match newest release DLL for removal ownership.

## 6. What SHOULD NOT Work

These are required fail-closed behaviors.

### 6.1 Unknown File

Add unrelated file such as:
`DO_NOT_DELETE_ME.txt`

Expected:
- ownership validation fails
- Conflict
- unknown-file reason
- uninstall blocked
- unknown file not deleted
- no blind folder wipe

### 6.2 Unknown Directory

Add unexpected nested directory:
- ownership fails
- uninstall blocked
- no recursive blind delete

### 6.3 Unknown Bridge File

Add unexpected file under Bridge:
- ownership fails
- uninstall blocked

### 6.4 Reparse Point / Junction / Symlink

Any reparse point in the removal tree:
- removal ownership fails
- uninstall blocked
- no traversal
- external target untouched

Critical safety boundary.

### 6.5 Wrong ModInfo Identity

Change ModInfo Name away from:
`BitWrecked_HistoricalRandomStart`

Expected:
- ownership fails
- uninstall blocked
- no deletion

### 6.6 Missing Identity Files

If ModInfo.xml or d0163.dll is missing:
- state incomplete/conflict
- uninstall does not assume ownership
- destructive removal blocked

### 6.7 Game Running

While 7 Days to Die is running:
- Apply disabled
- Uninstall disabled
- changes reported unavailable
- no destructive mutation

Backend mutation must also reject a non-Closed/unconfirmed game state.

### 6.8 Unsupported Game Build

If Assembly-CSharp.dll is missing or MVID mismatched:
- install blocked
- clear compatibility failure
- no unsupported runtime installed

### 6.9 Invalid Verified Payload

If verified DLL/ModInfo missing or hash mismatched:
- install blocked
- no partial install treated as success
- clear payload validation failure

### 6.10 Invalid New Game Name

Malformed/invalid names:
- Apply blocked
- no policy written
- no accidental match to another game

### 6.11 Confirmation = No

For Apply and Uninstall:
- no mutation
- status reflects canceled operation

## 7. Exhaustive Final QA Matrix

Record PASS / FAIL / BLOCKED / NOT TESTED and evidence for every item.

### A. Package / Identity
- [ ] Correct Git revision pulled
- [ ] Working tree clean before test
- [ ] d0163.dll exists
- [ ] DLL length = 39936
- [ ] DLL SHA-256 exact
- [ ] ModInfo version = 1.2.0
- [ ] ModInfo identity correct
- [ ] Supported game MVID matches
- [ ] No unexpected package files

### B. UI Startup
- [ ] START.bat launches UI
- [ ] Correct game folder detected
- [ ] New Game Name visible
- [ ] Standard visible
- [ ] Random visible
- [ ] Arrival protection visible
- [ ] Apply visible
- [ ] Launch Game visible
- [ ] Uninstall Mod visible
- [ ] No layout overlap/cutoff
- [ ] Initial status sensible

### C. Standard
- [ ] Valid exact game name accepted
- [ ] Apply confirmation appears
- [ ] Cancel causes no change
- [ ] Confirm succeeds
- [ ] Policy writes
- [ ] Standard game is not relocated
- [ ] Normal gameplay begins
- [ ] Save/reload remains normal

### D. Random — Anchor Observation 1
- [ ] Valid exact game name accepted
- [ ] Apply confirmation appears
- [ ] Confirm succeeds
- [ ] Matching game starts
- [ ] Relocation occurs once
- [ ] Approved production anchor observed
- [ ] Player appears near intended anchor
- [ ] Terrain height resolves
- [ ] Player becomes grounded
- [ ] No buried spawn
- [ ] No persistent floating
- [ ] No uncontrolled fall
- [ ] Health valid
- [ ] Progression valid
- [ ] Trader route valid
- [ ] Starter quest valid
- [ ] Save/reload does not reroll

### E. Random — Anchor Observation 2
Repeat until the other production anchor is seen:
- [ ] NG01 observed live
- [ ] NG02 observed live
- [ ] Both behave correctly
- [ ] No unsupported catalog position observed
- [ ] No repeated reroll behavior

Both NG01 and NG02 must be observed before final runtime QA is complete.

### F. Random + Arrival Protection
- [ ] Random selected
- [ ] Protection usable only in intended context
- [ ] Apply succeeds
- [ ] New game launches
- [ ] Relocation succeeds
- [ ] Protected arrival works as intended
- [ ] Grounded arrival succeeds
- [ ] No repeated relocation
- [ ] Trader/starter quest intact
- [ ] Reload stable

### G. Game-Running Safety
- [ ] Start 7 Days to Die
- [ ] Open/refresh HRS manager
- [ ] Apply unavailable
- [ ] Uninstall unavailable
- [ ] Changes reported unavailable
- [ ] No destructive mutation
- [ ] Close game
- [ ] Controls recover

### H. Uninstall Happy Path
- [ ] Valid HRS install exists
- [ ] Click Uninstall Mod
- [ ] Correct confirmation appears
- [ ] Saves/progress language present
- [ ] Choose No
- [ ] Nothing removed
- [ ] Repeat and choose Yes
- [ ] Owned HRS files removed
- [ ] Release folder removed when empty
- [ ] Saves still exist
- [ ] Existing game progress still exists
- [ ] UI reports uninstalled
- [ ] Ownership readback = NotInstalled

### I. Reinstall
- [ ] Reopen manager after uninstall
- [ ] Apply Random
- [ ] Fresh install succeeds
- [ ] Verified payload installed
- [ ] Policy written
- [ ] Runtime works live
- [ ] Uninstall available afterward

### J. Unknown File Safety
Prefer controlled copy/test root:
- [ ] Add unknown file
- [ ] Ownership False
- [ ] Conflict returned
- [ ] Unknown-file reason
- [ ] Uninstall blocked
- [ ] Unknown file remains

### K. Unknown Directory Safety
- [ ] Add unknown nested directory
- [ ] Ownership fails
- [ ] Uninstall blocked
- [ ] Directory untouched

### L. Wrong Identity Safety
Controlled copy only:
- [ ] Change ModInfo Name
- [ ] Ownership fails
- [ ] Uninstall blocked
- [ ] No deletion

### M. Missing Identity Safety
Controlled copy only:
- [ ] Remove/rename ModInfo or DLL
- [ ] Ownership fails
- [ ] Uninstall blocked

### N. Reparse Point Safety
Controlled test only:
- [ ] Introduce reparse/junction/symlink
- [ ] Ownership fails
- [ ] Uninstall blocked
- [ ] External target untouched

### O. Persistence / Regression
- [ ] Standard -> Random works
- [ ] Random -> Standard works
- [ ] Random -> Random with new exact name works
- [ ] Existing save not accidentally retargeted
- [ ] Policy revision increments normally
- [ ] No repeated runtime transaction after reload
- [ ] No obvious unrelated 7DTD startup regression

## 8. Live Runtime Observation Requirements

For each Random run record:
- Test case ID
- Exact new-game name
- Selected UI mode
- Arrival protection Yes/No
- Observed anchor NG01/NG02/Unknown
- Initial player coordinates if available
- Final grounded coordinates if available
- Approximate time until grounded
- Whether any second teleport occurred
- Health after arrival
- Starter quest state
- Trader target/route result
- Save/reload result
- Warnings/errors/log anomalies
- Screenshot/video for questionable behavior

Do not infer PASS from “looked okay.” Record evidence.

## 9. Release Blockers

Any one of these fails final QA:
- HRS-caused crash
- buried/permanently floating/repeatedly falling/unusable player
- second relocation/reroll on same qualifying game
- unsupported production anchor
- NG01 or NG02 demonstrably broken
- trader/starter quest progression broken
- save/reload triggers relocation again
- health/progression corruption
- uninstall deletes or threatens non-HRS files
- unknown file/directory does not block uninstall
- reparse point can be traversed
- wrong ModInfo identity still removed
- saves/progress removed by uninstall
- mutation allowed while game running
- unsupported game build installs
- invalid verified payload installs
- fresh install fails
- uninstall fails on clean owned install
- reinstall after uninstall fails
- UI reports success when readback proves failure
- manual repair required for normal supported customer path

## 10. Expected Limitations / Non-Defects

Do not report these as defects:
- Production selection intentionally limited to NG01/NG02.
- Additional scouting positions are not production choices yet.
- RandomSafe is intentionally represented as Random + arrival-protection checkbox.
- Standard means normal start policy, not uninstall.
- Uninstall removes HRS policy/result files with the owned runtime.
- Uninstall intentionally refuses modified/unknown folders.
- Older HRS DLL may be removable if ownership is otherwise proven.
- Unknown ownership requires manual investigation rather than automatic cleanup.
- This QA round is not for catalog expansion or UX redesign.

## 11. Final PASS Definition

HRS 1.2.0 receives final QA PASS only when:

1. Package identity and supported game build are verified.
2. Fresh install succeeds through START.bat.
3. Standard works.
4. Random works.
5. Random + arrival protection works.
6. NG01 observed live and passes.
7. NG02 observed live and passes.
8. Grounded arrival stable.
9. One-shot/no-reroll behavior proven.
10. Trader routing and starter quest functional.
11. Health/progression valid.
12. Save/reload stable.
13. Game-running mutation blocked.
14. Uninstall confirmation/cancel/success paths work.
15. Saves/progress survive uninstall.
16. Removal readback proves NotInstalled.
17. Reinstall after uninstall works.
18. Unknown-file safety passes.
19. Unknown-directory safety passes.
20. Wrong-identity safety passes.
21. Missing-identity safety passes.
22. Reparse-point safety passes.
23. No release-blocking regression remains.
24. Evidence is sufficient to explain every PASS/FAIL.

Anything less must remain FAIL, BLOCKED, or NOT TESTED. Never convert BLOCKED or NOT TESTED to PASS.

## 12. Tester Evidence Format

```text
TEST ID:
RESULT: PASS / FAIL / BLOCKED / NOT TESTED
GAME BUILD:
HRS REVISION:
MODE:
GAME NAME:
ARRIVAL PROTECTION:
OBSERVED ANCHOR:
STEPS:
EXPECTED:
ACTUAL:
SAVE/RELOAD:
TRADER/QUEST:
FILES/HASHES:
LOGS:
SCREENSHOT/VIDEO:
NOTES:
```

For FAIL, preserve save and logs before retrying when practical.

## 13. Tester Rule

When behavior is uncertain, stop and preserve evidence.

Do not manually “fix” an installation and then call the test passed.

Final QA question:

**Can a normal supported user install, configure, play, save, reload, uninstall, and reinstall HRS 1.2.0 safely, while the runtime performs exactly one valid production relocation and refuses unsafe mutations?**

If the complete evidence says yes, the release candidate passes.
