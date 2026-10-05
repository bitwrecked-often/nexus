# 1.2.7-qa.002 independent QA checklist

All 46 cases are Pending. Follow QA-RUNBOOK.md and frozen context/dev/qa/cases.json. DEV fixtures do not pass independent QA.

| Case | Review | Handoff status |
| --- | --- | --- |
| HRS-QA-001 | Customer package identity | Pending |
| HRS-QA-002 | Standard-mode control | Pending |
| HRS-QA-003A | Navezgane placed-world landing | Pending |
| HRS-QA-003B | Random Gen placed-world landing | Pending |
| HRS-QA-004 | Placed trader route | Pending |
| HRS-QA-005 | Intro and ordinary work | Pending |
| HRS-QA-006 | One-shot reload | Pending |
| HRS-QA-007 | Arrival protection boundary | Pending |
| HRS-QA-008 | Owned removal and availability | Pending |
| HRS-QA-009 | Owned upgrade | Pending |
| HRS-QA-010 | Manager identity rejection | Pending |
| HRS-QA-011 | Exact Game Name guard | Pending |
| HRS-BIOME-Navezgane-Forest | Chosen Forest in Navezgane | Pending |
| HRS-BIOME-Navezgane-BurntForest | Chosen BurntForest in Navezgane | Pending |
| HRS-BIOME-Navezgane-Desert | Chosen Desert in Navezgane | Pending |
| HRS-BIOME-Navezgane-Snow | Chosen Snow in Navezgane | Pending |
| HRS-BIOME-Navezgane-Wasteland | Chosen Wasteland in Navezgane | Pending |
| HRS-BIOME-Navezgane-Weighted-Mixed | Weighted Mixed in Navezgane | Pending |
| HRS-BIOME-Navezgane-Weighted-ZeroExclusion | Weighted ZeroExclusion in Navezgane | Pending |
| HRS-BIOME-Navezgane-Weighted-SinglePositive | Weighted SinglePositive in Navezgane | Pending |
| HRS-BIOME-Navezgane-Respawn | Respawn and changed preference in Navezgane | Pending |
| HRS-BIOME-RandomGen-Forest | Chosen Forest in RandomGen | Pending |
| HRS-BIOME-RandomGen-BurntForest | Chosen BurntForest in RandomGen | Pending |
| HRS-BIOME-RandomGen-Desert | Chosen Desert in RandomGen | Pending |
| HRS-BIOME-RandomGen-Snow | Chosen Snow in RandomGen | Pending |
| HRS-BIOME-RandomGen-Wasteland | Chosen Wasteland in RandomGen | Pending |
| HRS-BIOME-RandomGen-Weighted-Mixed | Weighted Mixed in RandomGen | Pending |
| HRS-BIOME-RandomGen-Weighted-ZeroExclusion | Weighted ZeroExclusion in RandomGen | Pending |
| HRS-BIOME-RandomGen-Weighted-SinglePositive | Weighted SinglePositive in RandomGen | Pending |
| HRS-BIOME-RandomGen-Respawn | Respawn and changed preference in RandomGen | Pending |
| HRS-BIOME-Weighted-AbsentRenormalized | Weighted absent eligible biome | Pending |
| HRS-BIOME-REQUESTED_BIOME_ABSENT | Safe fallback: REQUESTED_BIOME_ABSENT | Pending |
| HRS-BIOME-WEIGHTED_POOL_EMPTY | Safe fallback: WEIGHTED_POOL_EMPTY | Pending |
| HRS-BIOME-POI_SAFETY_EXHAUSTED | Safe fallback: POI_SAFETY_EXHAUSTED | Pending |
| HRS-BIOME-TRADER_POOL_EMPTY | Safe fallback: TRADER_POOL_EMPTY | Pending |
| HRS-BIOME-Manager | Saved biome selection, native presentation and accessibility | Pending |
| HRS-UX-OPERATIONS | Operation guards and automatic recovery | Pending |
| HRS-UX-COPY | Confirmation and truthful outcome copy | Pending |
| HRS-UX-GEOMETRY | Returned sizing defects and user sizing | Pending |
| HRS-UX-HELP | Discoverable setup help | Pending |
| HRS-UX-NEWCOMER | Scoped newcomer usability review | Pending |
| HRS-QA-TRADER-NOTICE | Post-Apply trader-session notice | Pending |
| HRS-QA-TRADER-FIRST-SESSION | Uninterrupted first trader assignment | Pending |
| HRS-QA-TRADER-EARLY-LOGOUT | Known early-logout route limitation | Pending |
| HRS-QA-TRADER-POST-ASSIGNMENT | Trader marker survives return before visit | Pending |
| HRS-QA-TRADER-CROSS-BIOME | Legitimate cross-biome trader fallback | Pending |

Start with the three preserved sizing failure sequences on actual Windows display profiles, then the runbook priorities and remaining contract cases. Preserve incomplete/failed attempts.

## HRS-QA-001

Install the exact extracted candidate with the manager; match environment, installed hashes and ownership. With the game closed, apply a new exact Game Name before its save exists. Verify the policy persists without the manager creating or requiring that save, and reopen the customer manager to verify the same saved intent before starting the game. In a setup requiring manual game-folder selection, reject a wrong folder, retry a valid folder without restarting, and verify Cancel exits cleanly without mutations.

- [ ] fresh-install-verified
- [ ] game-environment-matches
- [ ] prepared-before-save
- [ ] manager-does-not-create-save
- [ ] pre-save-policy-restored
- [ ] manual-folder-retry-and-cancel

## HRS-QA-002

Fresh named Standard save keeps the ordinary start and does not mutate trader routing.

- [ ] standard-spawn-unchanged

## HRS-QA-003A

Fresh Random Navezgane save lands safely at an approved placed prefab, with matching dynamic identity.

- [ ] fresh-character
- [ ] safe-ground-landing
- [ ] semantic-state-preserved

## HRS-QA-003B

Use a previously generated supported Random Gen world of at least 8192 with a fresh exact Game Name and character. Confirm the world existed before setup, then observe safe landing at an approved placed prefab from that active world, with matching dynamic identity. Do not delete or edit existing player/save data to create this fixture.

- [ ] fresh-character
- [ ] safe-ground-landing
- [ ] semantic-state-preserved
- [ ] existing-generated-world-reused
- [ ] fresh-game-name-distinct-from-world
- [ ] active-world-identity-matches

## HRS-QA-004

From a fresh landing, follow the marker to the logged real placed trader, in the final biome or the recorded cross-biome fallback.

- [ ] real-placed-trader-reached
- [ ] trader-marker-usable

## HRS-QA-005

Finish or retry the intro with the real trader and accept ordinary Tier 1 work.

- [ ] intro-quest-completed-or-reoffered
- [ ] vanilla-jobs-resume

## HRS-QA-006

After a fresh-process Continue, preserve an HRS-completed character's landing and quest without another placement. Separately load an already-played character created with Standard before enabling Random for its exact Game Name; preserve its position and ordinary quest state. A previously generated world with a fresh character is a separate positive scenario in HRS-QA-003B. Do not reset or edit player data.

- [ ] reload-no-relocation
- [ ] quest-state-preserved
- [ ] already-played-unmarked-character-preserved

## HRS-QA-007

Compare protection off/on, protected reload, and a later biome hazard with disposable saves.

- [ ] protection-off-hazards-active
- [ ] protection-on-starting-family
- [ ] protection-restored-on-reload
- [ ] later-biome-hazards-active

## HRS-QA-008

Check read-only removal availability for owned, absent, unowned and unknown installations. Confirmed Uninstall repeats ownership and process checks, removes only HRS-owned files and preserves saves, settings and unrelated mods. Manual Restore is absent; Uninstall does not reverse a saved landing or quest.

- [ ] owned-removal
- [ ] unrelated-files-preserved
- [ ] saves-preserved
- [ ] absent-removal-unavailable
- [ ] unowned-removal-unavailable
- [ ] unknown-removal-unavailable
- [ ] removal-cancel-no-write
- [ ] removal-final-checks
- [ ] manual-restore-absent

## HRS-QA-009

Upgrade an owned prior installation and verify exact candidate hashes and preserved user state.

- [ ] owned-upgrade
- [ ] candidate-hashes-match
- [ ] saves-preserved

## HRS-QA-010

A disposable altered package and unknown install footprint are rejected without overwriting game files.

- [ ] tampered-package-blocked
- [ ] unknown-install-blocked

## HRS-QA-011

With Random policy prepared for exact Game Name A, starting a different fresh Game Name B leaves a safe ordinary start with no HRS placement. Separately load a disposable HRS-completed Game B whose next opening quest is pending; advancing its normal quest must not invoke Game A's cached trader route or alter its objective because of HRS. Preserve the documented early-logout limitation as the fixture's baseline. Match Game Name rather than the generated world name; keep each process/log boundary explicit.

- [ ] name-mismatch-no-warp
- [ ] completed-character-wrong-name-quest-unchanged
- [ ] world-name-not-used-as-game-name

## HRS-BIOME-Navezgane-Forest

Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.

- [ ] chosen-biome-arrival
- [ ] requested-eligible-selected-completed-recorded
- [ ] safe-ground-landing
- [ ] trader-marker-usable

## HRS-BIOME-Navezgane-BurntForest

Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.

- [ ] chosen-biome-arrival
- [ ] requested-eligible-selected-completed-recorded
- [ ] safe-ground-landing
- [ ] trader-marker-usable

## HRS-BIOME-Navezgane-Desert

Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.

- [ ] chosen-biome-arrival
- [ ] requested-eligible-selected-completed-recorded
- [ ] safe-ground-landing
- [ ] trader-marker-usable

## HRS-BIOME-Navezgane-Snow

Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.

- [ ] chosen-biome-arrival
- [ ] requested-eligible-selected-completed-recorded
- [ ] safe-ground-landing
- [ ] trader-marker-usable

## HRS-BIOME-Navezgane-Wasteland

Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.

- [ ] chosen-biome-arrival
- [ ] requested-eligible-selected-completed-recorded
- [ ] safe-ground-landing
- [ ] trader-marker-usable

## HRS-BIOME-Navezgane-Weighted-Mixed

Use a distinct fresh exact Game Name for this weight fixture. Record configured weights and eligible/selected/final biome. This run covers only its named fixture.

- [ ] requested-eligible-selected-completed-recorded
- [ ] weighted-Mixed

## HRS-BIOME-Navezgane-Weighted-ZeroExclusion

Use a distinct fresh exact Game Name for this weight fixture. Record configured weights and eligible/selected/final biome. This run covers only its named fixture.

- [ ] requested-eligible-selected-completed-recorded
- [ ] weighted-ZeroExclusion

## HRS-BIOME-Navezgane-Weighted-SinglePositive

Use a distinct fresh exact Game Name for this weight fixture. Record configured weights and eligible/selected/final biome. This run covers only its named fixture.

- [ ] requested-eligible-selected-completed-recorded
- [ ] weighted-SinglePositive

## HRS-BIOME-Navezgane-Respawn

After a completed start, change the preference, reload, then die/respawn. No second HRS draw or placement.

- [ ] reload-no-relocation
- [ ] respawn-no-relocation
- [ ] changed-preference-no-second-start

## HRS-BIOME-RandomGen-Forest

Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.

- [ ] chosen-biome-arrival
- [ ] requested-eligible-selected-completed-recorded
- [ ] safe-ground-landing
- [ ] trader-marker-usable

## HRS-BIOME-RandomGen-BurntForest

Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.

- [ ] chosen-biome-arrival
- [ ] requested-eligible-selected-completed-recorded
- [ ] safe-ground-landing
- [ ] trader-marker-usable

## HRS-BIOME-RandomGen-Desert

Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.

- [ ] chosen-biome-arrival
- [ ] requested-eligible-selected-completed-recorded
- [ ] safe-ground-landing
- [ ] trader-marker-usable

## HRS-BIOME-RandomGen-Snow

Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.

- [ ] chosen-biome-arrival
- [ ] requested-eligible-selected-completed-recorded
- [ ] safe-ground-landing
- [ ] trader-marker-usable

## HRS-BIOME-RandomGen-Wasteland

Choose this biome for a fresh exact Game Name. If absent, record Blocked and the absent-biome case; do not invent a successful arrival.

- [ ] chosen-biome-arrival
- [ ] requested-eligible-selected-completed-recorded
- [ ] safe-ground-landing
- [ ] trader-marker-usable

## HRS-BIOME-RandomGen-Weighted-Mixed

Use a distinct fresh exact Game Name for this weight fixture. Record configured weights and eligible/selected/final biome. This run covers only its named fixture.

- [ ] requested-eligible-selected-completed-recorded
- [ ] weighted-Mixed

## HRS-BIOME-RandomGen-Weighted-ZeroExclusion

Use a distinct fresh exact Game Name for this weight fixture. Record configured weights and eligible/selected/final biome. This run covers only its named fixture.

- [ ] requested-eligible-selected-completed-recorded
- [ ] weighted-ZeroExclusion

## HRS-BIOME-RandomGen-Weighted-SinglePositive

Use a distinct fresh exact Game Name for this weight fixture. Record configured weights and eligible/selected/final biome. This run covers only its named fixture.

- [ ] requested-eligible-selected-completed-recorded
- [ ] weighted-SinglePositive

## HRS-BIOME-RandomGen-Respawn

After a completed start, change the preference, reload, then die/respawn. No second HRS draw or placement.

- [ ] reload-no-relocation
- [ ] respawn-no-relocation
- [ ] changed-preference-no-second-start

## HRS-BIOME-Weighted-AbsentRenormalized

On a suitable Navezgane or Random Gen world, give positive weight to a biome absent from the placed-POI eligible pool and another positive weight to an eligible biome. Record the eligible set, draw and safe arrival in one distinct run; if no suitable world is available, record Blocked.

- [ ] absent-biome-excluded
- [ ] requested-eligible-selected-completed-recorded

## HRS-BIOME-REQUESTED_BIOME_ABSENT

On a suitable disposable world, observe this exact terminal reason and the ordinary-start fallback. Record missing fixture as Blocked, never as Pass. Preserve absent versus reserved marker semantics.

- [ ] ordinary-start-preserved
- [ ] failure-not-completed
- [ ] no-redraw-on-reload

## HRS-BIOME-WEIGHTED_POOL_EMPTY

On a suitable disposable world, observe this exact terminal reason and the ordinary-start fallback. Record missing fixture as Blocked, never as Pass. Preserve absent versus reserved marker semantics.

- [ ] ordinary-start-preserved
- [ ] failure-not-completed
- [ ] no-redraw-on-reload

## HRS-BIOME-POI_SAFETY_EXHAUSTED

On a naturally suitable disposable world, observe this exact terminal reason and the ordinary-start fallback. Compare position, inventory, health and quest state with the ordinary-start baseline, and preserve absent versus reserved marker semantics. Record whether placement actually began; a failure before movement does not prove restoration after movement. Record missing fixtures as Blocked, never as Pass. Precise movement/observer/semantic exceptions and replacement world/entity identities are injected DEV checks, not substitutes for customer gameplay or reasons to edit the customer DLL or saves.

- [ ] ordinary-start-preserved
- [ ] failure-not-completed
- [ ] no-redraw-on-reload

## HRS-BIOME-TRADER_POOL_EMPTY

On a suitable disposable world, observe this exact terminal reason and the ordinary-start fallback. Record missing fixture as Blocked, never as Pass. Preserve absent versus reserved marker semantics.

- [ ] ordinary-start-preserved
- [ ] failure-not-completed
- [ ] no-redraw-on-reload

## HRS-BIOME-Manager

Open the extracted customer START.bat. Check independent Standard/Random and Any/Chosen/Weighted radio groups, exact saved-policy restoration, stable disabled picker/editor positions, cancel/commit weight edits, exact confirmation, compact header, readable 10pt state badge, outlined actions, visible focus and native Tab/arrows/Space/Enter/Escape. At actual primary 100/150/200/225 percent and secondary 300 percent Windows display scaling, verify narrow/maximized reachability, OS High Contrast, Narrator names/states and native popups. Component scaling simulations do not qualify actual display profiles.

- [ ] saved-selection-restored
- [ ] weight-cancel-discarded
- [ ] weight-switch-retained
- [ ] all-zero-blocked
- [ ] confirmation-before-mutation
- [ ] keyboard-access
- [ ] scaling-100
- [ ] scaling-150
- [ ] scaling-200
- [ ] scaling-225
- [ ] secondary-scaling-300
- [ ] rounded-actions-readable
- [ ] weights-dialog-readable
- [ ] focus-disabled-readable
- [ ] os-high-contrast
- [ ] narrator-controls
- [ ] scroll-reachability
- [ ] native-popups-readable
- [ ] independent-native-radio-groups
- [ ] selection-load-batched
- [ ] dependent-controls-stable
- [ ] compact-header-readable
- [ ] status-badge-readable

## HRS-UX-OPERATIONS

Use the exact extracted customer manager in disposable installations. During confirmed Apply, readback, Settings Applied acknowledgement and Uninstall, attempt duplicate/conflicting actions and activation refresh. Measure operation duration. Verify safe induced write failures recover prior installation bytes; uncertain recovery preserves backup/diagnostic and blocks Launch. Selection-only changes write nothing. Steam availability changes Launch without changing verified configuration state. After a transient launch blocker clears, refresh the current next-action guidance while retaining its diagnostic in Game details; a failed-Apply latch still requires a successful acknowledged Apply.

- [ ] busy-before-mutation
- [ ] duplicate-apply-blocked
- [ ] conflicting-uninstall-blocked
- [ ] busy-through-readback
- [ ] busy-through-acknowledgement
- [ ] busy-cleared-safely
- [ ] operation-duration-recorded
- [ ] verified-recovery-bytes
- [ ] uncertain-recovery-backup-retained
- [ ] failed-apply-launch-blocked
- [ ] selection-only-no-write
- [ ] steam-independent-applied-state
- [ ] launch-blocker-guidance-refresh
- [ ] launch-diagnostic-retained

## HRS-UX-COPY

Check Standard and Any/Chosen/Weighted with protection off/on. Exact Game Name, method/biome/weights and protection agree in confirmation, saved policy and acknowledgement. Standard omits Random fallback/trader warning; Random uses conditional fallback and the exact first-session notice. Test safe native default/Enter/Escape/window-close behavior on the actual host. Rejection, verified recovery and uncertain recovery show their specific next action without false success.

- [ ] exact-summary-agreement
- [ ] standard-omits-random-copy
- [ ] random-any-protection-off-on
- [ ] random-chosen-protection-off-on
- [ ] random-weighted-protection-off-on
- [ ] conditional-fallback-copy
- [ ] safe-confirmation-default
- [ ] native-dismissal-contract
- [ ] cancel-no-write
- [ ] rejection-copy-truthful
- [ ] verified-recovery-copy-truthful
- [ ] uncertain-recovery-copy-truthful

## HRS-UX-GEOMETRY

Reproduce HRS-UX-001 repeated selection/editor switching including the original 150 percent sequence; outer width never cumulatively shrinks. Reproduce HRS-UX-002 near screen bottom and after monitor changes; final outer bounds fit the current monitor work area. Reproduce HRS-UX-003 genuine minimum resize/scroll at actual 100/150/200/225 percent including the original 200 percent sequence, selection changes and dialog returns; every action, Help and Game details is reachable. Intentional user resize, normal restoration and maximize/minimize survive refresh.

- [ ] outer-width-stable
- [ ] work-area-bounds
- [ ] minimum-scroll-all-controls
- [ ] editor-return-scroll-settled
- [ ] user-size-preserved
- [ ] maximize-minimize-preserved
- [ ] monitor-move-qualified

## HRS-UX-HELP

From the compact extracted manager, find Help using keyboard and Narrator. Read the exact Game Name/world distinction, equal-chance/weight meaning, preview/eligibility/safety limits, protection boundary, Apply then acknowledgement then separate Launch, one-time landing and the first Random session trader-marker boundary. Help opens without install/removal/launch writes and remains reachable at supported real scales.

- [ ] help-discoverable
- [ ] help-keyboard-reachable
- [ ] help-narrator-reachable
- [ ] help-game-name-world
- [ ] help-weight-meaning
- [ ] help-protection-limits
- [ ] help-operation-order
- [ ] help-trader-boundary
- [ ] help-no-mutation

## HRS-UX-NEWCOMER

Observe one new user with the exact newly extracted customer package and realistic fresh-character goals without coaching, including preparing before a save exists and reusing a supported generated world. Record Game Name versus world-name comprehension, ordinary Help use, assistance and confusion, Apply/acknowledgement/Launch understanding, and the Random first-session boundary. Keep observations and targeted retests attached to this candidate; prototype or developer familiarity is not a substitute.

- [ ] uncoached-task-observed
- [ ] help-use-observed
- [ ] assistance-confusion-recorded
- [ ] operation-order-understood
- [ ] game-name-world-understood
- [ ] trader-boundary-understood
- [ ] targeted-retests-recorded

## HRS-QA-TRADER-NOTICE

From the extracted manager, verify the saved policy precedes Settings Applied. Random Any, Chosen, and Weighted show the first-session warning; Standard omits it. Launch stays disabled until OK and requires running Steam.

- [ ] policy-readback-before-popup
- [ ] random-any-notice
- [ ] random-chosen-notice
- [ ] random-weighted-notice
- [ ] standard-omits-notice
- [ ] launch-gate

## HRS-QA-TRADER-FIRST-SESSION

In a fresh Random save, complete opening tasks in the same session until Journey to Settlement assigns a trader marker. Record the route decision before any logout; the trader visit can occur later.

- [ ] opening-tasks-same-session
- [ ] destination-marker-before-logout
- [ ] route-completed

## HRS-QA-TRADER-EARLY-LOGOUT

In a separate disposable Random save, exit before trader assignment and return. Record whether the landing persists and which destination appears; a Pine Forest marker is the documented known limitation, not proof that the runtime issue is repaired.

- [ ] logout-before-assignment
- [ ] landing-persists-on-return
- [ ] return-destination-recorded

## HRS-QA-TRADER-POST-ASSIGNMENT

After assignment but before visiting the trader, exit and return. Verify the same assigned destination remains. A lost marker blocks release.

- [ ] assignment-before-logout
- [ ] same-marker-on-return

## HRS-QA-TRADER-CROSS-BIOME

In a world with no usable trader in the landing biome, verify the logged route selects a real placed trader in another biome. Record a missing natural fixture as Blocked.

- [ ] local-trader-unavailable
- [ ] placed-cross-biome-trader
- [ ] marker-matches-selected-trader

