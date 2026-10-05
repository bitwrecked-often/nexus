# New Player Random Start DEV work to do

Prepared **2026-10-05**. Owner: **Bit Wrecked**. Baseline: **1.2.7-qa.003**.

The owner approved the twelve DEV tasks below, including today's protection decisions and manual Check settings action. The tasks are open. Their source and screenshot observations establish the current presentation; the [human test plan](HUMAN-TEST.md) records today's guided review and will validate the returning implementation.

## Current source and scope

Use the current upstream 1.2.7 lane. The shipped [manager](<../../Solution - HRS - 1.2.7/Unified Package/1.2.7-qa.003/customer/HistoricalRandomStart_1.2.7/dev/ui/p0158.ps1>) and [public source](<../../Solution - HRS - 1.2.7/Unified Package/1.2.7-qa.003/source/hrs_1.2.7>) provide the review baseline. Edit authoritative source, recipe and generator inputs as applicable, and synchronize the manager embedding through the native graphics tooling.

Preserve Windows PowerShell 5.1, WinForms and native popups. Preserve ownership, hashes, policy validation, readback, verified recovery and the operation guard through acknowledgement. Applied configuration remains independent of Steam availability; Launch additionally requires current verified settings, Steam running and the game closed.

Preserve fresh-character placement and the existing trader-session boundary. These tasks introduce no save reset, additional player tag, result schema change or persistent trader re-entry repair. The source and evidence remain in the single full public ZIP; only its owned runtime payload is installed in the game.

## Work order

1. D01, D02 and D06: make current settings and recorded history unambiguous.
2. D07, D12, D08 and D04: clarify the name, add the manual settings check, and clarify protection and world scope.
3. D03, D05 and D10: complete the customer copy and popup pass.
4. D09: refine fixed spacing using measured screenshots and human observations.
5. D11: preserve exact package bytes before the repository preservation commit.

### D01 Put internal diagnostics in Game details

**Owner decision:** hide the raw drift code in the main view during ordinary setup.

The manager compares installed files with the current candidate. At intake, this laptop's installed 1.2.5 differed from 1.2.7, producing `DEPLOYMENT_STATIC_FILE_DRIFT`. The later monitored round verified qa.003 installations and ended uninstalled. The same code can also mean changed files in the same version; it alone does not prove a safe upgrade.

**Human finding, 2026-10-05:** During guided Test 1, the owner reported that the other controls looked right but did not understand "Installed files need verification: DEPLOYMENT_STATIC_FILE_DRIFT." Read-only inspection still found version 1.2.5 and the same DLL/ModInfo hashes captured before testing. This directly confirms the comprehension problem already covered by D01; it does not establish an installation failure or a safe upgrade. See the [Test 1 observation](../../qa-review/1.2.7-qa.003/human-review-01.json). Keep the full validation gate closed until the agreed corrections and feature/visual review are complete.

**Trigger follow-up:** The owner subsequently reported the message specifically with Choose a biome / Wasteland / protection on. The saved policy is Chosen Wasteland (biome 8), RandomSafe, Game Name `Test_Random_Spawn_Wasteland_02`; a read-only UI snapshot shows that same name. The source displays the cached installation reason in the main view when the form matches the saved policy and installation is unverified, while different draft settings receive pending guidance. The checkbox calls that status update; it does not write the runtime files. DLL, ModInfo and policy hashes remained unchanged. The later expanded-details screenshot also shows the same diagnostic in Game details, its intended technical location. The owner then reported other biomes behave normally while details retain the diagnostic. This supports the saved-policy display explanation; individual off/on results for all four combinations were not supplied. See the [diagnostic follow-up](../../qa-review/1.2.7-qa.003/human-review-04-diagnostic.json).

- [ ] Keep raw inventory reasons and supporting diagnostics in Game details.
- [ ] Use the existing small pending badge or neutral setup guidance for the ordinary update path.
- [ ] Keep ordinary pending presentation consistent for restored/matching settings and changed drafts, including protection off/on and biome changes. Preserve the diagnostic in Game details and all actual Launch guards.
- [ ] Show a plain cause and next action when ownership, paths, policy or installation cannot be verified.
- [ ] Use “Update ready” only if an older release is actually verified. Do not add a version classifier solely for display wording.
- [ ] Preserve Apply validation and keep Launch disabled until the current installation and policy are verified.

**Source:** manager 1700, 1728, 1744; launcher m0162.psm1 119 and 364.
**Retest:** HRS-UX-OPERATIONS, HRS-UX-COPY, HRS-QA-009 and HRS-QA-010.

### D02 Remove the redundant Apply reminder

- [ ] Remove “Apply Settings to use this start.” from the normal pending view.
- [ ] Retain the compact pending/applied badge beside Apply.
- [ ] Retain specific guidance for actual input errors and prerequisites.
- [ ] Remove the unused row space without moving or disabling an unrelated action.

**Source:** manager 1729 and 1741; operator screenshot and manager-smoke.png.
**Retest:** HRS-BIOME-Manager and HRS-UX-GEOMETRY.

### D03 Use customer language for errors

- [ ] Review Apply, Launch and Uninstall status and popups for raw codes and implementation language. Explain the cause and a usable next action.
- [ ] Replace customer-facing “QA package” and “QA payload” with “mod package.”
- [ ] Preserve full technical diagnostics in Game details.
- [ ] Preserve the distinction between a verified restoration and recovery that could not be verified. Keep backup and support instructions.
- [ ] Update every affected exact-message comparison in Get-HrsCurrentOperationError when its English message changes. Clearing a transient blocker must refresh the current guidance while retaining the diagnostic.
- [ ] Verify failed Apply still requires successful Apply and acknowledgement before Launch.

**Source:** manager 1630–1650, 1694, 1798–1804, 1936, 1997, 2139–2163 and 2242–2253.
**Retest:** HRS-UX-OPERATIONS and HRS-UX-COPY with disposable failure fixtures.

### D04 Correct Help world scope

- [ ] Replace the ambiguous combined world/size sentence with: **“Navezgane; for Random Gen, use worlds of 8192 or larger.”**
- [ ] Keep Help and README consistent. The 8192 minimum applies to Random Gen only.

**Source:** manager 1785; customer README Requirements.
**Retest:** HRS-UX-HELP, HRS-UX-NEWCOMER, HRS-QA-003A and HRS-QA-003B.

### D05 Correct the root README character

- [ ] Remove the stray `Â` before the middle dot in the root README subtitle.
- [ ] Verify the actual UTF-8 text and rendered root README. The customer README already has the correct middle dot.

**Source:** root README line 3, original ZIP bytes `C3 82 C2 B7`; intended middle dot `C2 B7`.
**Retest:** HRS-QA-001 package/document inspection.

### D06 Attribute the recorded outcome correctly

The screen can show “Last start: Random start completed” alongside a pending edited name or selection. The outcome describes the installed policy, not the draft form.

**Expanded-details observation:** The owner's latest crop shows the pending badge and disabled Launch alongside "Last start for current settings: COMPLETED / RELOCATION_COMPLETED." Current-result matching refers to the installed saved policy, even when the installation does not match this candidate. Extend the attribution check to that matching-form/unverified-installation state. Keep the recorded outcome available in details, with clear saved/applied-policy wording. This is a screenshot/source concern; the owner has not separately reported misunderstanding the outcome label. The result schema does not identify a producing product version. See the [diagnostic screenshot observation](../../qa-review/1.2.7-qa.003/human-review-04-diagnostic.json).

- [ ] Label the outcome as a recorded or previous applied start when the form differs from the applied settings.
- [ ] When Get-HrsCurrentResultState returns **Current**, identify its matching applied policy's Game Name if needed for clarity. Never use the edited field as the result's name.
- [ ] Preserve that saved/applied-policy attribution when the form matches but installation verification fails. A recorded completed start must not imply verification or gameplay success of this candidate.
- [ ] For **Stale**, use “Earlier applied settings” without guessing the old Game Name from the current policy. Result v1 has no Game Name field.
- [ ] Preserve Unconfigured, no-result, unavailable, pending, bypassed, failed and incompatible meanings. A completed landing does not establish first trader assignment.
- [ ] Keep the attribution current after edits, Apply, cancellation, restoration and activation.
- [ ] Use existing result/policy information. Do not change the result schema or add name/history persistence.

Suggested current-result wording: **“Last recorded start for <applied Game Name>: <outcome>.”** Qualify it as previous applied settings when the form is pending.

**Source:** manager 1807–1836 and 2293; m0161.psm1 820–833; ResultV1.cs.
**Retest:** HRS-BIOME-Manager, HRS-UX-COPY, HRS-QA-006 and HRS-QA-011.

### D07 Explain the Game Name intent

- [ ] Make the existing field label or confirmation clarify that Game Name identifies the save, distinct from the generated world's name. **“Game Name for your save”** is a proposed label to check for fit.
- [ ] Explain in Help that a fresh start can be configured before its save exists: choose the name here, Apply, then create the game with that exact name.
- [ ] Restore prior settings as today, but make their attribution clear. A restored name is prior configured intent, not a shipped default or proof that a new character is ready.
- [ ] Preserve configuration before save creation; Apply must neither require nor create the save.
- [ ] Preserve supported existing worlds and once-only placement. Reusing an already-played character must not trigger a new landing.
- [ ] Verify understanding through a human task without reintroducing a redundant always-visible paragraph.

**Today's related decision:** The owner approved a manual Check settings action beside Game Name. D12 defines its separate read-only scope and acceptance. Configuration before save creation remains supported.

**Source:** manager 1358, 1769–1770, 1910 and 2269–2271; customer README Get started.
**Retest:** HRS-QA-001, HRS-QA-006, HRS-QA-011, HRS-UX-HELP and HRS-UX-NEWCOMER.

### D08 Default protection on and clarify its visibility

**Owner review request:** The owner reported that other biome choices behave normally and suggested omitting protection when Forest is explicitly chosen. The runtime maps a fresh Forest landing to biome 3 with protection family 0; it only enables starting-hazard protection for positive recognized families. Scope this visibility change to **Random / Choose a biome / Forest**. See the [operator follow-up](../../qa-review/1.2.7-qa.003/human-review-04-diagnostic.json).

**Owner default decision:** Protection starts checked when no saved Random preference exists. Users can uncheck it for challenge runs. The current candidate constructs the checkbox unchecked before restoring a saved policy; this default change remains DEV work. Restore saved RandomSafe as checked and saved Random as unchecked. A saved Standard policy contains no separate Random preference: keep Standard selected and initialize the remembered Random preference checked. The current schema cannot preserve a prior Random opt-out across saving Standard and reopening; introduce no new persistence for this presentation change.

- [ ] Use a precise label such as **“Starting biome hazard protection.”** Match the label in confirmations and public setup copy.
- [ ] Default the checkbox on for a new configuration or a restored Standard policy with no encoded Random preference. Preserve Standard behavior; protection becomes relevant only after selecting Random.
- [ ] Restore a saved RandomSafe policy as on and an explicit saved Random opt-out as off, including supported legacy policy restoration. Do not recheck a restored opt-out at launch or after changing the Game Name, selection method or biome.
- [ ] Preserve validation for an invalid or unreadable saved policy. A failed restore must not be treated as a new configuration or bypass existing guards.
- [ ] Hide the protection control when Forest is explicitly chosen; keep it available for other chosen biomes, Any and Custom weights. Standard continues to hide the Random controls.
- [ ] Retain the remembered on/off preference while hidden by Standard or Chosen Forest and restore it when the option becomes visible during the same session. Selection-only changes must not rewrite policy or automatically downgrade RandomSafe to Random.
- [ ] Keep confirmations truthful about the requested preference and its scope: a fresh Forest landing has no recognized HRS starting-hazard protection to apply. Preserve exact saved-intent agreement without implying Forest is free of all hazards.
- [ ] Preserve protection restored for an existing character's original hazardous landing. Changing the requested biome to Forest does not relocate a completed character; clearing the hidden preference could otherwise disable that character's protection on return.
- [ ] Keep Help and the accessible description explicit: recognized environmental hazards in the starting biome only; enemies, other-biome hazards and unrecognized effects remain active.
- [ ] Verify text fitting, keyboard access and human comprehension.
- [ ] Verify new/no-policy and saved Standard defaults, saved RandomSafe and explicit Random opt-out restoration, challenge-run opt-out, Forest/other-biome/Any/Custom transitions, acknowledgement refresh and operation guards. Confirmation, applied policy and readback must agree with the preference. Preserve user sizing and prevent cumulative width changes.
- [ ] Preserve the existing protection toggle, RandomSafe policy and runtime coverage.

**Source:** manager 758–762, 1064, 1436–1437, 1775–1776 and 2269–2271; PlacedPoiResolver.cs 257–285; c0167.cs 278–285 and 449–451.
**Retest:** HRS-BIOME-Manager, HRS-UX-COPY, HRS-UX-GEOMETRY, HRS-UX-HELP, HRS-UX-NEWCOMER and HRS-QA-007. Add precise returning-candidate checks without removing existing coverage.

### D09 Reduce fixed empty space and clarify inactive choices

The native capture fills the laptop's 1344-pixel work height. A disabled previous biome remains visible while Custom weights is active. The control positions were kept stable to avoid earlier sizing defects.

- [ ] Review measured fixed padding and reserved blank space; reduce excess where possible while retaining readable targets and the weight statistics.
- [ ] Make it clear that only the selected method applies. Preserve the chosen biome and custom weights when users switch methods.
- [ ] Preserve stable control geometry and intentional user resizing. Do not automatically resize the outer window on each method selection.
- [ ] Repeat Any/Chosen/Weighted and editor open/cancel/save sequences without cumulative width loss.
- [ ] Verify work-area bounds, minimum-size scrolling, every action/Help/Game details, monitor moves and normal/maximized/minimized restoration at actual OS scales.
- [ ] Record before/after captures and dimensions. Choose final spacing from those measurements and the human observations.

**Source:** manager 842–864 and 1393–1435; root-start-native.json/png and manager-smoke.png.
**Human restoration observation, 2026-10-05:** The owner reported minimize/maximize/restore works, with noticeable layered redraw and rebuild delay. The delay is accepted for the current review; timing and cause were not measured. Keep this observation for DEV to assess when profiling layout or rendering. No animation framework is requested and no functional restoration failure is established.
**Retest:** HRS-UX-GEOMETRY and HRS-BIOME-Manager; original HRS-UX-001/002/003 sequences.

### D10 Make the popups easier to read

- [ ] Keep the pre-write Yes/No confirmation with No as the safe default.
- [ ] Keep the post-write Settings Applied acknowledgement after write, readback and verification. The busy guard lasts through acknowledgement.
- [ ] Keep the configuration summary short and make the Random first-trader instruction prominent.
- [ ] Preserve the boundary: **“Do not log out until your first trader is assigned.”** Complete the opening tasks and wait for the Journey to Settlement marker; visiting can happen later.
- [ ] Preserve Standard-specific copy, Random-only fallback/warning, exact Game Name, active method and protection agreement.
- [ ] Check Enter/Escape/default behavior and whether the human can explain the notice after reading it. Add no artificial wait and remove neither safeguard.

**Source:** manager 1910–1916, 2053–2061 and 2089–2099.
**Retest:** HRS-UX-COPY, HRS-QA-TRADER-NOTICE, HRS-QA-TRADER-FIRST-SESSION and HRS-QA-TRADER-POST-ASSIGNMENT.

### D11 Preserve exact bytes in Git

The original ZIP is intact. The repository extraction has 98 listed newline-only differences plus its manifest; the Git index has 239 differences among 395 archive files.

- [ ] Add scoped `-text` protection for the returned 1.2.7 package/evidence tree.
- [ ] Restore its original extracted bytes from the unchanged ZIP after checking the complete archive inventory and containment.
- [ ] Explicitly restage or renormalize that tree when preparing its preservation commit. Attributes alone do not replace existing normalized index blobs.
- [ ] Verify all archive member lengths and SHA-256 against the actual index blobs before committing.
- [ ] Keep legitimate patch formatting, earlier frozen packages and unrelated work intact.

**Evidence:** [QA intake](../../qa-review/1.2.7-qa.003/intake-review.json).
**Retest:** package/transport identities; ordinary prose uses canonical text identity where declared.

### D12 Add a manual Check settings action

**Owner decision, 2026-10-05:** Add a small **Check settings** button beside Game Name. The owner accepted the proposed manual readback and asked to combine it with today's DEV work. Implementation is pending; this button is absent from qa.003.

Today the manager reads one active installed policy during status updates and compares the exact Game Name plus the active mode, selection, biome and weights. Applied status also requires verified installation and no outstanding Apply/acknowledgement block. Reopening may show Applied without a new Apply in that manager session. The manager does not search saves. The new action gives the user an explicit file check while keeping that distinction clear.

- [ ] Use the established native button and popup style beside Game Name. Validate the entered name with existing exact-name rules and provide plain input guidance.
- [ ] On click, obtain fresh validated policy and current installation information. Assess policy availability/validity, exact name match, full draft match and installation verification separately. Use the existing canonical selection comparison so inactive controls cannot create false differences.
- [ ] Give concise results for matching settings with verified files, same name with different selected options, policy targeting another name, no policy, legacy settings needing Apply, and invalid/unreadable/unverifiable files. Identify the entered name and active policy name where needed. Keep technical reasons in Game details.
- [ ] Make the result and badge use the same assessment and existing state rules. Name agreement alone must not produce Changes applied. A matching policy with unverified files needs truthful verification guidance.
- [ ] Preserve the entire draft. Check reads files without applying settings, restoring controls, migrating policy, repairing files, creating saves, resetting characters or adding persistence. Configuration before save creation remains supported; add no save/player scan or background polling.
- [ ] Disable and guard Check during Applying, Uninstalling and AwaitingAcknowledgement. Preserve failed-Apply, recovery and acknowledgement gates; matching bytes must not clear them.
- [ ] If checking while the game runs is allowed, describe the result as files currently on disk. Preserve game-running guidance and Apply/Launch process guards; a disk check cannot establish what the live player loaded.
- [ ] Treat the result as a point-in-time read. Edits invalidate a retained comparison; interrupted or inconsistent reads report Cannot verify. Apply and Launch still perform their required fresh checks.
- [ ] Keep saved configuration distinct from save existence, fresh-character eligibility, runtime execution and first-trader assignment. A previous result is attributed only through its matching policy revision/digest under D06.
- [ ] Verify keyboard/focus/accessibility, compact placement and real-scale reachability alongside the new control's busy behavior. Preserve user sizing and prevent cumulative width changes.

**Implementation note:** `Update-HrsStatus -RefreshInstallation` currently verifies inventory only for a non-null v2 policy and can exit before that work on a malformed policy. Merely wiring that call does not establish independent current inventory for missing or legacy policy. Build a shared read-only assessment using the existing validated path/policy/inventory readers, with separate results. Unsafe paths remain unverifiable; use no raw-parser fallback. Keep the state badge and operation checks consistent with this assessment.

**Focused DEV checks:** no save yet; exact matching name/options; another name; same name with different options; missing/legacy/invalid policy; older or changed installation; invalid input; Steam closed/game running; repeated clicks; busy/acknowledgement/recovery guards. Use disposable fixtures for invalid files. Repeated Check must leave installed payload, policy/result, saves and recovery files unchanged. Bind delivered component evidence and the returning human tests to the new candidate.

**Source:** manager 1566–1575, 1609–1618, 1684–1711, 2263–2274 and 2293; m0161.psm1 66–102, 490–503, 780–796 and 818–833; m0162.psm1 inventory validation.
**Retest:** HRS-BIOME-Manager, HRS-UX-OPERATIONS, HRS-UX-COPY, HRS-UX-GEOMETRY, HRS-UX-HELP, HRS-UX-NEWCOMER and relevant name/policy cases. Add precise read-only-action checks to the returning contract while retaining existing required coverage.

## Required DEV return

- [ ] Task disposition for D01–D12, including unresolved items and measured D09 values.
- [ ] Source commit/diff, recipe/control revisions, generated manager hash and synchronized public copy.
- [ ] Focused component results for state attribution, error reconciliation, selection retention, verified/uncertain recovery, popup gates, manual settings assessment and geometry.
- [ ] New candidate ID, full public ZIP, manifests, receipts, exact archive SHA-256 and release-validator result.
- [ ] Cases retain all required coverage. Add precise checks if these corrections need them; do not silently remove requirements or grant passes from old screenshots.
- [ ] Screenshots identify candidate, source/hash, actual display profile, state and live versus fixture scope.
- [ ] README, Help, popups and listing copy agree with implemented behavior. Preserve the disclosed trader-session limitation and best-effort hook compatibility.
- [ ] Return a [human test ledger](HUMAN-TEST.md) with baseline observations and distinct retests of the new candidate.

All 46 cases in the current frozen contract are Pending. DEV's matching double build, 20 runtime scenarios and 26 manager assertions remain component evidence. Required independent QA and release-owner approval precede publishing the exact full ZIP unchanged.

## Reference guidance

The classic native Windows [status guidance](https://learn.microsoft.com/en-us/windows/win32/uxguide/ctrl-status-bars) favors task-relevant context, and [confirmation guidance](https://learn.microsoft.com/en-us/windows/win32/uxguide/mess-confirm) supports a meaningful decision and concise essential information. The usability tasks apply those principles to the observed HRS interface; the human checks establish actual comprehension.
