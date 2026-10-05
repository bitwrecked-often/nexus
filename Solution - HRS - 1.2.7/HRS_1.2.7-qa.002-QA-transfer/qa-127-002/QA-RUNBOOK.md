# New Player Random Start 1.2.7 customer QA runbook

Prepared 2026-10-04 for frozen **1.2.7-qa.002**. Packaging identities are recorded
in `PACKAGE-IDENTITY.json`. The frozen `context/dev/qa/cases.json` in this transfer
is authoritative; all **46 cases are Pending**. DEV fixtures are supporting
evidence, not customer QA Pass. This runbook performs no game action by itself.

## Open the exact customer package

Extract the complete portable transfer to a writable local folder outside
OneDrive, synced and linked folders. Keep its customer ZIP, receipt, companion,
context and tools together. Open START-HERE and PACKAGE-IDENTITY first. The
customer entry is `customer/HistoricalRandomStart_1.2.7/START.bat`; the historical
folder/internal mod names remain intentional after the public rename.

Use Windows PowerShell 5.1 (`powershell.exe`), not the PowerShell 7 `pwsh` host.
The customer manager uses existing WinForms/GDI+ and needs no new graphics
application. Close the game before Apply/Uninstall and open Steam for Launch.

Verify the package with its own frozen tools from the wrapper folder:

```powershell
& .\tools\Test-HrsRelease.ps1 -LaneRoot .\context
```

Formal gameplay requires **V3.3.0 b17**, local single-player, EAC disabled and
the game's supplied `0_TFP_Harmony`. The expected Assembly-CSharp SHA-256 is
`AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146`; Harmony is
`C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF`.
Record the actual installed environment. A differing build may be observed as
separate compatibility work; it does not pass the pinned gameplay cases. Do not
use the DEV reference-only root as the game folder or replace game DLLs.

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
& .\tools\Start-HrsQaRun.ps1 -LaneRoot .\context -CandidateArchivePath .\1.2.7-qa.002.zip -CaseId HRS-QA-001 -Mode Standard -GameRoot 'C:\Games\7 Days To Die' -RunRoot .\runs
```

Use `NotApplicable` mode for pure manager/display cases, and the actual
Standard/Random/RandomSafe mode for gameplay. Note the returned evidence path.
Record only checks actually observed, using that case's exact check IDs:

```powershell
$qaRun = 'C:\HRS QA\qa-127-002\runs\1.2.7\<returned-run-id>'
& .\tools\Record-HrsQaObservation.ps1 -RunPath $qaRun -ConfirmedChecks @('fresh-install-verified','game-environment-matches','prepared-before-save','manager-does-not-create-save','pre-save-policy-restored','manual-folder-retry-and-cancel')
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
bytes and SHA-256**. The portable transfer and engineering companion are review
support, not the customer distribution archive.
