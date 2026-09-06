# Historical Random Start - Alpha 6 Method — Preview Apply Edge-Fix Manifest

Date: 2026-08-14  
Status: Implemented and verified; runtime/release gates remain closed  
Target: Player preview `0.0.7-preview`  
Scope: Session-only Apply workflow, state truth, activity logging, and evidence

Completion evidence:
`evidence/2026-08-14_preview_apply_edge_fix_test_report.md`

## Handoff Objective

Harden the new `Apply Preview Settings` workflow so the player-facing preview
always tells the truth about which values are currently applied in the open
window and which values are still pending.

This is a launcher-preview edge-fix task. It is not authorization to build the
gameplay DLL, write a world policy, install a runtime helper, edit game files,
or make the preview persistent across launches.

## Read Before Action

Read these in order:

1. `README_FIRST.md`
2. `CURRENT_SITUATIONAL_AWARENESS.md`
3. This manifest
4. `Support_Files_Do_Not_Edit/HistoricalRandomStart_Tool.ps1`
5. `UX_0_1_CONTROL_INVENTORY_AND_STATE_MODEL_0.0.1.md`
6. `DEV_TEST_AND_SOFTWARE_ASSURANCE_CONTRACT_0.0.1.md`
7. The current audit findings below

The support script is the current implementation source. The UX/state model
and software-assurance contract remain governing boundaries; this manifest
does not override them.

## Current Truth

The preview currently has:

- exactly two start choices: `Standard` and `Random`;
- two mutually exclusive, default-off Random safeguard choices;
- `Check Game Folder`;
- `Apply Preview Settings`;
- a confirmation popup before applying;
- a success popup listing the current session values; and
- a collapsible Recent activity pane that opens after a successful apply.

Apply is intentionally session-only. It stores the selected values in memory,
updates the visible state, and writes activity only when the player explicitly
chooses a persistent activity-log location and enables saving. It must not
write policy, saves, worlds, game XML, DLLs, executables, registry state,
services, or hidden installer state.

The pre-fix parser, launcher smoke test, and 56-case pure contract suite passed.
The UX manifest's Day 2 hash is explicitly historical and remains preserved;
a separate current implementation fingerprint is required after this edge-fix
implementation and evidence review.

## Audit Findings to Resolve

### Finding A — Applied state can become stale after editing controls

After a successful Apply, the shell changes the preview labels to green and
describes the session as applied. Later changes to Standard/Random or either
safeguard checkbox only add a generic activity message; they do not mark the
current selection as pending.

Required outcome:

- retain the last applied snapshot in memory;
- compare the live controls with that snapshot after every editable change;
- show a clear pending state when the live selection differs;
- never describe a changed, unapplied selection as already applied; and
- preserve the last applied snapshot until a new Apply is confirmed.

The pending state must be visible in the main status area and the preview-only
notice. It must not imply that gameplay or policy changed.

### Finding B — Manual game-folder edits can bypass the visual validation state

The path field can be edited directly. The Apply handler revalidates the path,
but the button and prior session state are not immediately invalidated when
the text changes. A new valid path can therefore be used while the UI still
describes the previous folder/session state.

Required outcome:

- treat direct path edits exactly like folder selection;
- invalidate or mark stale the previous session snapshot when the path changes;
- require a valid current folder before Apply; and
- make the status/log explain whether a folder scan is required.

The fix must not log private machine paths into the activity log. Showing the
selected path in the existing path field and confirmation popup is acceptable.

### Finding C — Automated coverage does not exercise the Apply interaction

The current smoke test checks initialization and control shape, but does not
prove the Yes/No confirmation flow, cancel behavior, pending-state behavior,
success logging, or activity-pane expansion.

Add deterministic coverage that does not require a human to dismiss modal
dialogs. Prefer extracting pure state/summary functions or adding a test-only
prompt seam rather than weakening the production confirmation behavior.

## Required Behavior Matrix

| Case | Expected result |
| --- | --- |
| Initial valid folder, no Apply yet | Apply is available; state says ready/not applied |
| Confirm first Apply | Snapshot is recorded; popup lists values; log records each applied value |
| Cancel Apply confirmation | Snapshot and visible applied state do not change; cancel is logged |
| Change start type after Apply | State becomes pending; no claim that the new value is applied |
| Toggle a safeguard after Apply | State becomes pending; mutual exclusion remains intact |
| Re-Apply changed values | Confirmation lists the actual before/after changes; new snapshot replaces old |
| Re-Apply with no value changes | Popup clearly says the session record is being refreshed; no false change list |
| Edit folder to invalid path | Apply is blocked or disabled; status explains the required correction |
| Edit folder to another valid path | Previous snapshot is stale/cleared; current folder is validated before Apply |
| Successful Apply | Activity pane is visible or clearly indicates the new entries; no game files change |
| Close and reopen preview | No prior session settings are presented as persisted |

## Implementation Boundaries

Allowed:

- `Support_Files_Do_Not_Edit/HistoricalRandomStart_Tool.ps1`;
- preview-specific tests or test seams under `tests/`;
- this manifest and directly related evidence/changelog/current-truth notes;
- updating the UX baseline hash after review; and
- a preview version increment if the larger AI determines the change warrants
  one.

Forbidden in this task:

- live `Mods`, `Data/Config`, XML, DLL, executable, save, world, or Harmony
  changes;
- policy persistence or a world/settings writer;
- gameplay/runtime behavior;
- game launch handoff, install, remove, packaging, publishing, or upload;
- Developer Mode, console commands, cheat paths, telemetry, network, registry,
  services, scheduled tasks, or hidden installers;
- copying behavior from the Wasteland project beyond generic UI/test process;
  and
- deleting or resetting unrelated user work.

The existing explicit persistent activity-log feature may remain. Any write
must remain opt-in, user-selected, and limited to the activity log.

## Acceptance Criteria

The handoff is complete only when all are true:

1. The live selection and last applied selection have an explicit, testable
   comparison.
2. Applied, pending, not-applied, invalid-folder, and canceled states are
   visually distinct and accurately logged.
3. Confirmation text identifies the actual setting changes without claiming
   that the game was modified.
4. Path changes cannot leave an old applied state looking current.
5. The activity pane contains clear apply/cancel/change entries and does not
   leak a private path.
6. Existing Standard/Random and safeguard contract tests still pass.
7. Windows PowerShell 5.1 and PowerShell 7 parsing passes.
8. The direct BAT launcher smoke test passes.
9. New deterministic Apply/state tests pass.
10. A static write scan confirms that no new game/policy write path exists.
11. The updated script hash, test output, and manual verification steps are
    recorded in a dated evidence note.
12. The changelog and current situational awareness agree with the resulting
    behavior and version.

## Manual Verification Required

After automated checks pass, a human must reopen the BAT and verify:

1. Apply is visible with a valid game folder.
2. A first Apply shows the requested values before Yes is selected.
3. No leaves the controls and state unchanged.
4. Yes shows the final values and opens the activity pane.
5. Editing a value after Apply visibly changes the state to pending.
6. Changing the folder visibly invalidates or marks stale the previous state.
7. The game installation remains unchanged.

Record screenshots or a concise observation note if the visual state is
important to the review. Do not call this a gameplay test or release approval.

## Stop Conditions

Stop and report instead of broadening scope if:

- implementing the fix requires a policy writer, runtime helper, or game-file
  mutation;
- the modal confirmation cannot be tested without weakening production
  confirmation;
- the current UI contract conflicts with the approved UX/state model;
- a test requires touching the live game or a real player save; or
- the larger AI cannot distinguish session memory from persistent policy.

## Return Packet for the Larger AI

Return:

- a short implementation summary;
- the exact files changed;
- the state-transition design used for applied versus pending values;
- automated test commands and results;
- static write-scan results;
- the refreshed script hash and evidence path;
- manual verification status; and
- any remaining owner decision or blocked gate.

Do not report the handoff complete merely because the button appears or a
happy-path popup works. The state truth, cancellation path, folder boundary,
logging behavior, tests, and evidence must all agree.

## Implementation Result — 2026-08-14

The 0.0.7 preview now derives one visible state from the live selections, the
last confirmed in-memory snapshot, and an exact checked-folder key. It renders
folder-check-required, invalid-folder, not-applied, pending, and applied truth;
cancel is shown as an outcome without changing that underlying truth. A direct
path edit immediately stales the prior snapshot, disables Apply, and requires
`Check Game Folder`.

Deterministic confirmation, reapply, invalid-folder, alternate-folder,
activity-log, redaction, and pane-expansion coverage passes 11/11 in both
Windows PowerShell 5.1 and PowerShell 7. The existing pure contract suite still
passes 56/56 in both hosts. Production popup and state rendering were also
reviewed directly. The exact commands, hashes, static write accounting, live
tree before/after fingerprint, observations, and remaining limitations are in
the completion evidence linked above.
