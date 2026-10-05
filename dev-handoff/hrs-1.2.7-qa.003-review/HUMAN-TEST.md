# New Player Random Start human QA plan

Revision **6**, **2026-10-05**. Plan and current guided-session ledger; writing this document performs no tests or case-status changes.

Use this plan with [DEV-TODO.md](DEV-TODO.md) and the [current intake record](../../qa-review/1.2.7-qa.003/intake-review.json). The operator controls the manager, Windows settings and gameplay. QA records observations, screenshots and logs. The later replay harness is separate work.

## Current guided session

These are limited review steps on frozen **1.2.7-qa.003**, distinct from complete formal case outcomes.

| Step | Operator observation and disposition |
| --- | --- |
| [1 — selections](../../qa-review/1.2.7-qa.003/human-review-01.json) | Controls reported as expected; raw drift guidance was not understood. D01 remains open |
| [2 — weights and Cancel](../../qa-review/1.2.7-qa.003/human-review-02.json) | Passed reported step: Cancel discarded edits; relative-weight shares understood |
| [3 — zero guard and retention](../../qa-review/1.2.7-qa.003/human-review-03.json) | Passed reported step: all-zero rejected, single-positive share and retained draft correct |
| [4 — keyboard and Help](../../qa-review/1.2.7-qa.003/human-review-04.json) | Passed reported keyboard/Help step; modal Help blocking parent clicks is expected |
| [5 — small window and scrolling](../../qa-review/1.2.7-qa.003/human-review-05.json) | Functional actions reported working. Captured window is larger than the baseline; reduced viewport image pending at review-05a |
| [6 — repeated editor returns](../../qa-review/1.2.7-qa.003/human-review-06.json) | Passed reported step: no visible GUI distortion during three Cancel returns at the current size/profile. Covered screenshot rejected; full geometry remains pending |
| [7 — window restoration](../../qa-review/1.2.7-qa.003/human-review-07.json) | Passed reported functional restoration; noticeable redraw delay accepted for this review. No timing or cause measured |
| 8 — Apply preview / No | Pending: no cancellation attestation; superseded by owner-authorized Apply/removal exploration |
| [9 — policy transitions](../../qa-review/1.2.7-qa.003/human-review-09.json) | Six successful Apply history records and four removal transitions captured. Every observed installed state had one validated policy and matching candidate files; removed states had none. Final state: uninstalled |

The [diagnostic follow-up](../../qa-review/1.2.7-qa.003/human-review-04-diagnostic.json) combines the saved-policy display explanation, expanded-details observations and Forest/default-protection request. Four manager checks and one Help keyboard check are attested; all **46 formal cases remain Pending**. These reports establish neither other-scale coverage nor a full geometry pass. Steps 1–7 requested no Apply, Launch, Uninstall or gameplay actions. The owner subsequently authorized real Apply/clearing cycles for step 9; the agent observed disk state without operating the product.

Step 9's stopped watcher captured 12 consistent snapshots, including baseline and final state, with no read errors. Observed selections covered Standard, Any with protection on/off, chosen Desert, chosen Wasteland with protection on/off, and custom weights (Forest 15, Burnt Forest 33, others zero). No additive-policy problem appeared in the settled samples. Polling does not prove every intermediate write, agreement with the intended UI draft, acknowledgement timing, save preservation or gameplay behavior. Review 05a's reduced-viewport capture and review 08's cancellation remain open.

The owner stated that the earlier monitored battery was sufficient and declined repeating it. Review 10 was deferred without a new cancellation attestation. No gameplay action followed the proposed fresh Wasteland test. Finish the listed changes and remaining final-candidate coverage on the DEV workstation under the workstation completion plan. Existing observations stay attached to qa.003; publication and formal acceptance remain pending.

The owner approved D12's manual Check settings action during this session. It is DEV work, absent from the current candidate. Complete final-candidate sizing verification on DEV; retain the reduced-viewport capture at review-05a as deferred baseline evidence, and the feature/visual acceptance gate before full validation.

## Feature and visual approval before full validation

The owner has authorized the work needed to validate the build, with the full validation matrix starting once the complete product is accepted for features and appearance. Use targeted review and smoke checks now to settle the open presentation work.

Before starting the full matrix:

1. Review the main window, selections, weights editor, action states, Help and native confirmations. Record the owner's acceptance of the feature behavior and appearance, including the agreed disposition of open DEV items.
2. Receive and identify the final complete candidate after those corrections. Freeze its ZIP, manifests, receipts and contract. Resolve the recorded game-environment qualification gap for formal gameplay.
3. Start fresh case evidence for that candidate before the relevant actions. Prepared baseline records remain attached to their original candidate; they do not qualify a replacement candidate.
4. Run the consolidated matrix and the remaining manager, accessibility and conditional-fixture checks. Publication follows admissible required coverage and release-owner approval.

The owned-upgrade case remains pending: its prepared before-state record has no complete after-state/save-preservation evidence. Later exploratory monitoring independently verified installed qa.003 payloads and successful Apply history, followed by removal. Those observations do not complete the upgrade case or establish a formal case Pass.

## Consolidated gameplay budget

Use **21 planned fresh-save scenarios** as the normal coverage budget. This is a practical plan, not a guaranteed minimum or a fixed total for release approval.

| Fresh-save group | Scenarios |
| --- | --- |
| Navezgane: Any, five chosen biomes, Mixed/ZeroExclusion/SinglePositive weights | 9 |
| Existing Random Gen world of at least 8192: the same selection coverage | 9 |
| Standard control followed by Random Continue on that played character | 1 |
| Fresh wrong-name start with another Game Name's policy active | 1 |
| Dedicated early-logout save, retaining a pending-quest fixture for the completed-character wrong-name check | 1 |
| **Total planned fresh saves** | **21** |

HRS-QA-003A and HRS-QA-003B explicitly require **Any** selection in their respective world categories. Each chosen-biome and weight fixture has its own distinct fresh Game Name. A missing required biome or unsuitable world leaves that case unfinished and needs a suitable fixture.

Attach compatible first-trader assignment, post-assignment return before the visit, trader visit/jobs, protection off/on comparison, protected reload, later-biome hazards, changed preferences and respawn checks to suitable saves. Those checks add login or process sessions within the same saves. Keep the early-logout baseline and pending quest intact until their respective observations are recorded. Most fixtures can stop at their required landing or marker milestone; selected saves carry the longer trader/job sequence.

Collect compatible manager checks during setup and use dedicated display/accessibility, disposable operation-failure and newcomer rounds. Natural absent-weight, terminal-fallback and cross-biome-trader fixtures, defect retests and any missing prerequisites remain additional work.

The **46 case records remain separate**. Start every compatible case before its shared actions; bind each observation to its own required checks and fixture. Preserve distinct process logs before exports. Reload and mismatch case records must isolate the applicable return logs from forbidden fresh-placement events. One shared session does not automatically pass all attached cases.

## Two clearly identified rounds

| Round | Purpose | Result boundary |
| --- | --- | --- |
| Current frozen **1.2.7-qa.003** | Targeted setup, comprehension and behavior review to settle the recorded DEV work | Expected existing copy remains a recorded finding. Do not describe planned fixes as implemented |
| Newly identified candidate returned by DEV | Verify delivered corrections and feature/visual acceptance, then qualify the exact complete ZIP under its own frozen contract | Start fresh evidence. Earlier screenshots, fixtures and passes do not establish that the changed candidate passed |

Preserve the original qa.003 ZIP and shipped files. Any shipped change needs a new candidate identity, archive hash, manifests and receipts. Follow the candidate's [QA runbook](<../../Solution - HRS - 1.2.7/Unified Package/1.2.7-qa.003/QA-RUNBOOK.md>) and [case contract](<../../Solution - HRS - 1.2.7/Unified Package/1.2.7-qa.003/context/dev/qa/cases.json>); this shorter session plan does not replace them.

## Record the environment before actions

- Current verified qa.003 workspace: `C:\Users\mobil\AppData\Local\HRS-QA\1.2.7-qa.003-20261005-intake`. Use its root `START.bat` and bundled tools, not the repository's normalized extraction or a developer shortcut.
- Original archive SHA-256: `8527F11CAAFF4173AB9880FD906E9E7DF4F6C56E45E2B81098F5688C94B27881`. Intake verified it against the supplied DEV ZIP; an independently published checksum was not supplied.
- Laptop HRS installation at intake: **1.2.5**. No upgrade, Apply, Uninstall or game launch was performed in that intake. Capture installed-before identity before an operator performs any of those actions.
- Actual game `Assembly-CSharp.dll` SHA-256: `FCEEC27300FFD3A1F97B097E43B60F3B07597F441E7ECBC6E1B59EEBB234C705`.
- Frozen gameplay target: **V3.3.0 b17**, expected SHA-256 `AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146`. The difference is a qualification gap, not evidence of incompatibility or an exact-version installation refusal. Exploratory play on this laptop can supply observations; it cannot satisfy the pinned gameplay qualification without the required environment.
- Record actual Windows display scale, monitor, work area, window bounds, High Contrast/Narrator use, Steam/game state, EAC/Harmony state and the operator's experience. Record world name, Game Name, world category/size and fresh-character status separately.

Use disposable test saves and the controlled fixtures required by each case. Keep failure injection in disposable installations; do not manufacture it by damaging the live game, customer DLL, quests or player files. If the required environment, second monitor, newcomer or natural fallback fixture is unavailable, record the missing prerequisite.

## Start evidence before each case's actions

Use Windows PowerShell 5.1. Supply an explicit run root **outside** the frozen workspace. The example below starts a Help case; substitute the selected case and actual mode. For the next DEV candidate, replace all candidate/workspace/archive identities with that delivery's verified values.

```powershell
$humanQaWorkspace = 'C:\Users\mobil\AppData\Local\HRS-QA\1.2.7-qa.003-20261005-intake'
$humanQaArchive = Join-Path $humanQaWorkspace '1.2.7-qa.003.zip'
$humanQaGameRoot = 'C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die'
$humanQaRunRoot = 'C:\Users\mobil\AppData\Local\HRS-QA\runs-1.2.7-qa.003-human'
$humanQaLaneRoot = Join-Path $humanQaWorkspace 'context'

& (Join-Path $humanQaWorkspace 'tools\Test-HrsRelease.ps1') -LaneRoot $humanQaLaneRoot
& (Join-Path $humanQaWorkspace 'tools\Start-HrsQaRun.ps1') -LaneRoot $humanQaLaneRoot -CandidateArchivePath $humanQaArchive -CaseId HRS-UX-HELP -Mode NotApplicable -GameRoot $humanQaGameRoot -RunRoot $humanQaRunRoot
```

Continue only after the tools verify the workspace and return the run's evidence path. Use `NotApplicable` for pure manager/display cases and the actual `Standard`, `Random` or `RandomSafe` mode for gameplay. Do not use `-AllowDevelopmentGap` for independent QA. An already-open manager or earlier game log does not retroactively prove case actions that happened before the run started.

Save timestamped native screenshots and task notes inside that active run before export. Start with the relevant initial screen; add the changed settings, confirmation/cancellation, verified acknowledgement and observed game milestone as applicable. For geometry, record actual scale and outer bounds, including minimum-size top/bottom captures. A screenshot of one visible area does not prove all controls are reachable. Component-scaled images do not qualify real Windows display profiles.

## Execution goals after the review gate

Use these goals for the full campaign after feature and visual acceptance. Earlier targeted review can examine individual actions with its own bounded evidence. Give the operator goals, then observe how they accomplish them. The table is an observation plan, not a chat walkthrough. A familiar owner can perform functional QA; **HRS-UX-NEWCOMER** still needs one actual new user without coaching.

| Goal | Observe and preserve | Contract anchors |
| --- | --- | --- |
| Prepare a fresh start before its save exists, using a supported existing world | Exact future Game Name versus world name; restored old name; whether Help is found; save absent before/after Apply; saved intent restored on reopening | HRS-QA-001, HRS-QA-003B, HRS-UX-HELP, HRS-UX-NEWCOMER |
| Explore biome methods and make a deliberate choice | Independent radio groups; inactive remembered biome; retained/cancelled weight edits; zero exclusions; shares understood as previews; no writes from selection-only changes | HRS-BIOME-Manager, HRS-UX-OPERATIONS, HRS-UX-NEWCOMER |
| Decide whether protection fits the desired challenge | Operator explains recognized environmental hazards, enemies and other-biome limits; record any broader expectation | HRS-UX-HELP, HRS-UX-NEWCOMER, HRS-QA-007 |
| Review, cancel once, then apply the intended configuration | Exact name/method/weights/protection; native default and dismissal behavior; cancellation makes no change; readback precedes acknowledgement; duplicate/conflicting actions stay guarded | HRS-UX-COPY, HRS-UX-OPERATIONS, HRS-QA-TRADER-NOTICE |
| Explain the screen and launch prerequisites | Current pending/applied configuration versus previous game result; upgrade guidance versus real blocker; Steam requirement without unnecessary reapply; technical diagnostic remains available | HRS-QA-009, HRS-UX-OPERATIONS, HRS-UX-HELP, HRS-UX-NEWCOMER |
| Play the fresh Random character through first trader assignment | Human plays the opening tasks without leaving the session. Record landing/biome/placed-POI identity and the Journey to Settlement destination marker with matching route events, before logout | HRS-QA-003A or HRS-QA-003B, HRS-QA-004, HRS-QA-005, HRS-QA-TRADER-FIRST-SESSION |

The first-session milestone is **trader assignment**, not the trader visit. Record the observed destination and route; do not assume the trader must be in the landing biome or nearby. A visit can happen later, and any case requiring further quest progression still needs that evidence. An unexpected exit before assignment is an observed session interruption, not successful uninterrupted completion.

Post-assignment return and early-logout testing are separate recipes: use the post-assignment case to verify the marker survives return before visiting, and a separate disposable save for the disclosed early-logout limitation. Do not infer either result from the first-session run or claim the known limitation was repaired.

## Verify the DEV corrections on return

Use [DEV-TODO.md](DEV-TODO.md) as the change list. For each delivered item record the baseline, expected correction, new-candidate observation and evidence. Complete this review and record the owner's feature and visual acceptance before starting the full campaign. Verify:

- Ordinary update/pending presentation is plain and concise; raw codes remain in Game details. Changed, missing or conflicting files retain the actual guards and an actionable visible blocker.
- The redundant Apply reminder is absent. Error copy distinguishes failed Apply, verified recovery and uncertain recovery; package wording and transient-error reconciliation remain correct.
- Help states that the 8192 minimum applies to Random Gen, explains pre-save naming order and retains the actual protection/one-time/trader boundaries. Shipped README subtitles render correctly.
- Earlier results cannot be mistaken for success of a newly edited name or settings. Any protection-label or inactive-control adjustment is understood by the operator and preserves the underlying selection.
- Confirmation and completed-write acknowledgement remain separate, truthful and readable. The Random first-trader instruction is understood; Standard omits it. Launch stays guarded until verification and acknowledgement.
- Copy or spacing adjustments preserve focus, accessible names, real-scale wrapping, user sizing and reachability. Do not trade the recorded geometry fixes for a shorter form.
- D08 defaults protection on when no saved Random preference exists, restores explicit Random opt-outs, and retains the choice through hidden Standard/Chosen Forest controls. Saved Standard encodes no separate Random preference. Verify transitions and existing-character protection without adding persistence.

### Returning-candidate manual settings check

Verify D12 once the button is delivered. Start the returning candidate's applicable case records before actions. Keep this separate from the current qa.003 observations.

- Check a matching policy before any save exists; name, full draft and verified installation agree without requiring or creating the save.
- Check another name and the same name with different options. Results distinguish name agreement from whole-configuration agreement; draft values remain intact and the badge stays truthful.
- Use disposable missing, legacy, invalid/ambiguous-policy and unverified-installation fixtures. Distinguish each condition with plain guidance and technical details; failed reads cannot become a verified result.
- Check invalid input, Steam closed and game running. A disk inspection cannot claim the live character loaded the policy; Apply/Launch keep their process requirements.
- Repeat Check and verify installed payload, policy/result, save and recovery identities remain unchanged. Test guarded conflicting actions and acknowledgement/recovery blocks with controlled operation fixtures.
- Verify keyboard, accessible name/focus, new-control placement and actual-scale reachability. A later field edit invalidates the retained comparison; fresh Apply/Launch checks still apply.

Preserve all existing required cases and add explicit D12 checks to the returned contract. There are no D12 passes in the current frozen ledger.

Usability concerns remain hypotheses until observed. Record hesitation, wrong assumptions, Help use and the operator's own explanation. If assistance is needed, first record the point of difficulty, then the exact assistance and outcome. A coached completion is not uncoached newcomer success.

## Keep the complete release coverage

The current contract has **46 required cases**, all Pending at intake. The first human session is a useful starting point, not full release coverage. In particular retain these five UX cases:

| Case | Additional completion needed |
| --- | --- |
| HRS-UX-OPERATIONS | All busy/readback/acknowledgement guards, measured duration, controlled verified/uncertain recovery, Steam separation and refreshed Launch guidance |
| HRS-UX-COPY | Standard and all three Random methods with protection off/on; real native default/Enter/Escape/close behavior; rejected, recovered and uncertain outcomes |
| HRS-UX-GEOMETRY | Original 150% width sequence, bottom/monitor placement, genuine minimum resize/scroll at actual 100/150/200/225%, editor returns, preserved user size and maximize/minimize |
| HRS-UX-HELP | Discoverability, keyboard/Narrator reachability, all scoped explanations and no install/removal/launch mutation |
| HRS-UX-NEWCOMER | An actual uncoached new user, recorded help/assistance/confusion and candidate-specific targeted retests |

HRS-BIOME-Manager also requires the actual secondary 300% profile, High Contrast, Narrator and its complete native-control checks. Complete the remaining Standard, Navezgane/Random Gen biome/weight, upgrade/removal/rejection, protection, exact-name, reload/respawn, natural fallback and trader cases from the frozen contract. Do not merge distinct cases or fixture variants into a claimed pass from one screenshot or matching event. Missing fixtures are unfinished qualification.

## Observation and outcome record

Keep one short record per task/variant, with links relative to its run:

| Field | Record |
| --- | --- |
| Identity | Round; candidate ID/archive SHA-256; run ID; case/check IDs; UTC time |
| Fixture | Actual game identity; installed-before version; world/Game Name; fresh or played character; process/session boundaries; display profile |
| Human goal | Task given; operator experience; uncoached or assisted |
| Expected / observed | Required behavior; actual actions and result; hesitation or misunderstanding; exact assistance and subsequent recovery |
| Evidence | Native screenshot names; relevant log/process and event range; installed/policy readback; tool observation/export references |
| Disposition | Pass, Fail, Blocked or Pending; missing checks/prerequisites; defect ID; targeted retest needed |

Record only checks actually observed using `Record-HrsQaObservation.ps1` and the selected case's exact `requiredChecks`. For placed-world/trader cases, supply the actual world, coordinates, placed POI/trader IDs, biomes, retries and quest/reload observations required by that case. Confirming a check is a human attestation; it is not a measurement generated by clicking a control.

Export with `Export-HrsQaRun.ps1` using **Pass**, **Fail** or **Blocked** and honest Notes; use `Kind Rollback` for HRS-QA-008. Pending means unperformed work and is not an allowed export outcome. Select the intended completed process explicitly with `-LogPath` where necessary; the tool does not automatically merge multiple game logs. Preserve earlier variants' sanitized evidence before export. Review the automated Consistent/Mismatch assessment separately from the human outcome; Consistent alone does not grant Pass.

Pass requires every required check, event, fixture and environment observation. Fail means an observed violation. Blocked identifies an unavailable prerequisite or required observation. Keep incomplete and failed evidence. Exported runs are immutable; retest in a new run. Do not alter the frozen case ledger to make this plan appear complete.

Return the run exports, concise case/environment ledger and candidate-specific DEV findings. Keep private local session metadata out of the public ZIP. Publication approval remains pending until admissible coverage and the release owner's decision; publish only the exact approved archive bytes and checksum.
