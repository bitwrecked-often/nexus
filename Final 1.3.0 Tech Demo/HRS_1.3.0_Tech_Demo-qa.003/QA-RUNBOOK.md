# New Player Random Start 1.3.0 Tech Demo customer QA runbook

Prepared 2026-10-05 for complete public candidate **1.3.0-qa.003**. The frozen `context/dev/qa/cases.json` supplied in this archive
is authoritative; all **46 cases are Pending**. DEV fixtures are supporting
evidence, not customer QA Pass. This runbook performs no game action by itself.

## Open the one complete public package

Everyone receives **HRS_1.3.0_Tech_Demo-qa.003.zip** with the same files and SHA-256. Preserve
that original downloaded ZIP. It contains the product, source, history, lore,
evidence, complete GPL text, frozen contracts and the same QA tools for everyone.

For play, extract locally outside synced/linked folders and use root START.bat.
For independent QA, prepare a separate unused local workspace using the bundled
tools. Supply the exact final publisher checksum in `$publishedSha256` below;
obtain it from the delivery record/public listing, not from an edited copy.

```powershell
$publishedSha256 = '<publisher SHA-256 for this complete ZIP>'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\New-HrsQaWorkspace.ps1 -CandidateId 1.3.0-qa.003 -ArchivePath 'C:\Downloads\HRS_1.3.0_Tech_Demo-qa.003.zip' -Destination 'C:\HRS QA\qa-130-001' -ExpectedArchiveSha256 $publishedSha256
```

This verifies the one archive, extracts its entire identical public tree and
creates local archive-bound QA receipts/registry from embedded identities. Those
local records are not another product package. Keep the downloaded ZIP unchanged.
The bootstrap preserves those same ZIP bytes inside the workspace using its
canonical identity filename `1.3.0-qa.003.zip`; later tool examples use that local
archive. This creates no second public release or companion download.
Use Windows PowerShell 5.1 (`powershell.exe`). Close the game for Apply/Uninstall;
open Steam for Launch. Run product through the workspace's root START.bat.

From `C:\HRS QA\qa-130-001`, verify using its own supplied tools:

```powershell
& .\tools\Test-HrsRelease.ps1 -LaneRoot .\context
```

Put all newly recorded QA runs OUTSIDE the frozen public workspace, for example
`C:\HRS QA\runs-130-001`. The full source/evidence/tool tree is now checked for
drift, in addition to product and contracts. Manager private state is the defined
exception; do not alter shipped source or historical records to repair QA.

Formal gameplay requires **V3.3.0 b17**, local single-player, EAC disabled and
supplied `0_TFP_Harmony`. Expected Assembly-CSharp SHA-256:
`AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146`;
Harmony: `C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF`.
A different build cannot pass the pinned gameplay cases. The DEV reference-only
root is not a playable game, and no proprietary game DLLs are bundled.

## Accept the product before the full campaign

This is a new **1.3.0 Tech Demo** candidate. The returned 1.2.7 GUI feedback,
DEV component checks and native-host smoke do not pass its customer cases.
First review the main window, choices, weights, action states, Help, native
confirmations and **Check settings** with the owner. Record feature and visual
acceptance before starting the full validation matrix. The frozen candidate
identity and playable game environment must be qualified before its gameplay
campaign. The [returned human plan](evidence/current/qa-return/HUMAN-TEST.md)
and [workstation plan](evidence/current/qa-return/DEV-WORKSTATION.md) retain
their original baseline scope; internal/raw-return links have been removed
from their public projection.

During targeted setup review, confirm the Tech Demo label and readable subtitle,
short action guidance, complete exact-name comparison, protection default on
for an unsaved Random setup, and retention of explicit saved preferences.
Exercise protection preferences while their control is hidden for chosen Forest
or Standard, then return to another Random choice and verify the preference is
retained. Forest remains selectable. Check settings must inspect the typed Game Name and choices without
writing a policy, changing installation/manager state or scanning/creating a
save. It cannot clear a failed-Apply latch or bypass Apply acknowledgement.
Record mismatched, missing, legacy, invalid and installation-conflict guidance
on disposable fixtures, along with the applied-policy attribution of outcomes.

Plan **21 fresh-save scenarios**: nine selection scenarios each on Navezgane
and an existing supported Random Gen world of at least 8192, one Standard
played-character Continue control, one fresh wrong-name start, and one dedicated
early-logout/pending-quest fixture. Keep each of the 46
case records separate while sharing compatible gameplay/login sessions. Trader
assignment, return before visiting, jobs, protected return and later-biome
hazards can reuse suitable saves. Natural fallback/cross-biome fixtures, real
OS scales, accessibility and newcomer observations remain additional work.
Missing prerequisites remain Blocked; this budget is not a guarantee of full
coverage or release approval.

## Prioritized observations

1. **Sizing regressions first: HRS-UX-GEOMETRY.** Repeat the original 150%
   selection/editor sequence; record outer width before/after repetitions.
   Place near the bottom/taskbar, move between monitors and verify final work
   area bounds. At actual Windows 100/150/200/225%, genuinely resize to the
   minimum and scroll through every action, Help and Game details. Include the
   original 200% sequence, editor returns and selection changes. Preserve
   intentional user sizing and normal/maximized/minimized restoration. A
   simulated control scale does not qualify an OS display profile.
2. **Setup before a save: HRS-QA-001.** Choose a new exact Game Name whose save
   does not exist. Record that absence before/after Apply. Confirm and
   acknowledge Settings Applied; verify the installed files and saved policy,
   then reopen the extracted customer manager before creating the game. The
   name/settings must restore and the manager must not create the save. On a
   manual-selection setup, first choose an unrelated folder, retry the valid
   game folder without restarting, then verify a separate Cancel attempt exits
   cleanly. If that UI path cannot be exposed, record the missing fixture rather
   than attributing the DEV chooser check to customer QA.
3. **Fresh character on an existing world: HRS-QA-003B.** Select a previously
   generated supported Random Gen world of at least 8192 and a fresh Game Name.
   Record the world's prior existence, its world name and the distinct Game
   Name. Apply before starting that character. Observe its first safe HRS
   landing and the active world's logged POI/biome/instance identity. Use the
   real world and fresh character; do not reset a played character's files.
   HRS-QA-003A separately retains the Navezgane positive path.
4. **Already-played characters: HRS-QA-006.** Continue a completed HRS landing
   in a fresh process and confirm no second placement and preserved quest
   progress. Also use a disposable character previously played in Standard,
   then apply Random for the same exact Game Name and Continue it. Its existing
   position and ordinary quest state must remain. Keep the two fixture
   observations/process boundaries attached to this case.
5. **Wrong-name quest context: HRS-QA-011.** Prepare Random policy for Game A,
   then create a different fresh Game B and verify an ordinary start. Also use
   an existing disposable HRS-completed Game B with its next opening quest
   pending. With policy still targeting A, continue B and advance the normal
   quest; HRS must not inject A's cached trader route/objective. Use an existing
   pending-quest fixture, including one retained by the early-logout case; do
   not edit quest/save files to create it. Record the disclosed early-logout
   baseline separately so a known ordinary return route is not mistaken for a
   successful HRS rewrite. If no suitable fixture exists, record Blocked.
6. **Operation and guidance repairs: HRS-UX-OPERATIONS.** Retest guarded
   Apply/readback/acknowledgement/removal, automatic file recovery and retained
   uncertain-recovery diagnostics on disposable installations. Open Steam
   after applying with it closed: unchanged verified settings should become
   launchable without another Apply. If a transient Launch blocker occurs,
   clear that condition and return to the manager; current guidance must
   refresh, while Game details retains the diagnostic. Failed Apply still
   requires a successful acknowledged Apply. Do not inject writes into a live
   game installation to force a failure.

Then complete every remaining contract requirement: Standard, placed trader
and starter work, all chosen/weighted cases and protection boundaries, owned
upgrade/removal/rejection, safe fallbacks, actual native popups, keyboard,
Narrator/OS High Contrast, Help and uncoached newcomer review. For Random,
complete opening tasks in the same session and wait for the Journey to
Settlement trader marker before leaving. The separate early-logout case tests
the disclosed limitation; normal successful setup does not use it as a shortcut.

For natural `POI_SAFETY_EXHAUSTED`, compare ordinary position, health, inventory
and quest state and record whether movement actually began. Preserve result and
marker semantics across reload. A pre-movement fallback does not establish
post-movement rollback. Precise movement/observer exceptions and replacement
world/entity identities are scoped injected **DEV** evidence; do not edit the
customer DLL, player files or world to manufacture a QA Pass. Missing natural
fallback fixtures are Blocked with the missing condition recorded.

## Record each case

Start before taking the case's actions, using the actual game folder. This
captures package/environment/installed-before identity and excludes old events:

```powershell
& .\tools\Start-HrsQaRun.ps1 -LaneRoot .\context -CandidateArchivePath .\1.3.0-qa.003.zip -CaseId HRS-QA-001 -Mode Standard -GameRoot 'C:\Games\7 Days To Die' -RunRoot 'C:\HRS QA\runs-130-001'
```

Use `NotApplicable` mode for pure manager/display cases, and the actual
Standard/Random/RandomSafe mode for gameplay. Note the returned evidence path.
Record only checks actually observed, using that case's exact check IDs:

```powershell
$qaRun = 'C:\HRS QA\runs-130-001\1.3.0\<returned-run-id>'
& .\tools\Record-HrsQaObservation.ps1 -RunPath $qaRun -ConfirmedChecks @('fresh-install-verified','game-environment-matches','prepared-before-save','manager-does-not-create-save','pre-save-policy-restored','manual-folder-retry-and-cancel','one-public-archive','source-history-lore-evidence-included','full-license-included','root-start-entry','payload-only-installation','tech-demo-edition-visible','utf8-subtitle-correct')
& .\tools\Export-HrsQaRun.ps1 -RunPath $qaRun -Outcome Pass -Kind QA -Notes 'Record the actual names, fixture/process boundaries, observations and any limitations.'
```

Those check IDs belong only to HRS-QA-001, and the Pass example requires every
listed observation to have occurred. Otherwise use Fail for an observed defect
or Blocked for missing environment/fixture/evidence. Do not use
`-AllowDevelopmentGap` for independent QA. Use `Kind Rollback` for HRS-QA-008.

For placed-world cases, supply actual `WorldCategory`, `WorldName`, `GameName`,
`WorldSize`, `SelectedPrefabName`, `PlacedInstanceId`, `PlacedRotation`, final
coordinates and `RetryAttemptCount` to Record-HrsQaObservation. For traders also
record the observed placed trader/biomes and quest destination/progression; for
reload record its actual result. No single matching event establishes a whole
case. Export-HrsQaRun assesses one selected log (the newest by default); use its
`-LogPath` argument when selecting a particular completed process. For a case
with multiple fixture variants, retain sanitized additional runtime-event JSON
and observations for the earlier phases before freezing the run, and describe
the process boundaries in Notes. Do not assume the tool merges multiple logs or
turn a final-process event into proof of every variant.

Keep incomplete/failed runs. An exported run is immutable; retest in a fresh
run rather than editing its sidecars. The latest complete matching evidence is
selected by the cycle tool. Operator checks remain attestations to actual
observations, not measurements inferred from the software.

## Return and release boundary

Return the frozen run ZIPs plus a concise case/outcome/environment ledger and
the preserved candidate identity. Keep local/private session metadata out of
public distribution. Every one of the 46 cases requires admissible evidence;
reviewing DEV screenshots or a passed fixture does not complete it. A Blocked
case is unfinished qualification, while a Fail records an observed defect.

Complete-HrsQaCycle evaluates the exact candidate, frozen contracts, required
checks and evidence. A release-owner approval decision follows actual coverage;
it is not granted by this runbook or the transfer. After independent QA and
approval, customers, Nexus and the project site receive the **same customer ZIP
bytes and SHA-256**. This complete public archive is the distribution tested by QA and delivered unchanged to customers and Nexus.
