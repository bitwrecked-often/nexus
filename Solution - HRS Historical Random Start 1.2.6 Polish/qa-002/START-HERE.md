# Historical Random Start 1.2.6-qa.002 — QA review

Extract the whole QA transfer ZIP into a writable local folder outside OneDrive
or other synced or linked folders. Open `qa-002` and keep its contents together.
The customer distribution ZIP is `1.2.6-qa.002.zip`. The surrounding context,
receipt, tools and review documents support engineering QA.

`PACKAGE-IDENTITY.json` records the frozen customer ZIP SHA-256, receipt,
companion and file inventory. After independent QA and release-owner approval,
Nexus and the project site receive this same customer ZIP without rebuilding,
editing or recompressing it. The engineering transfer ZIP is separate.

## Begin review

1. Open Windows PowerShell 5.1 in `qa-002` and run:

   ```powershell
   & .\tools\Test-HrsRelease.ps1 -LaneRoot .\context
   ```

2. Verify the actual game environment before starting a gameplay case. The
   qualified target is **7 Days to Die V3.3.0 b17**, local single-player,
   **EAC off**, with the game's supplied `0_TFP_Harmony`. Use Navezgane or
   Random Gen worlds of at least 8192.
3. With the game closed and Steam open, run
   `customer/HistoricalRandomStart_1.2.6/START.bat`. Begin with package identity
   (`HRS-QA-001`), then manager presentation (`HRS-BIOME-Manager`) and the
   post-Apply notice (`HRS-QA-TRADER-NOTICE`). The complete requirements are
   in `context/dev/qa/cases.json`; `QA-REVIEW-CHECKLIST.md` provides an index.

The development box's installed game assembly has changed since the b17
qualification. Its SHA-256 differs from the candidate target. Formal gameplay
QA therefore needs a matching b17 installation. The manager's best-effort
behavior on another game build is not b17 QA or compatibility certification.
The transfer contains no game DLLs or instructions to modify game files.

## Record actual cases

Start evidence collection before performing a case. Replace the game folder
and case ID with the actual values:

```powershell
& .\tools\Start-HrsQaRun.ps1 -LaneRoot .\context -CandidateArchivePath .\1.2.6-qa.002.zip -CaseId HRS-QA-001 -Mode Standard -GameRoot 'C:\Games\7 Days To Die' -RunRoot .\runs
```

Use the returned run path with `Record-HrsQaObservation.ps1` and
`Export-HrsQaRun.ps1`. Each case lists its evidence and explicit tester checks.
Only record what was observed. Use Fail or Blocked for a failed check or missing
fixture; repeated cases use new runs. The supplied `QA-WORKFLOW.md` explains
the commands; older candidate IDs in its examples are historical. Use this
candidate's ID, context and case IDs.

All **41 independent QA cases are Pending** at handoff. Source checks, simulated
scaling and a no-install startup smoke do not complete these cases.

## Presentation review

Check Standard, Any, Chosen and Weighted with the real extracted manager.
Review the picture-only logo, white Apply action, short status and last-start
summary. Check the weights dialog's Save/Cancel behavior, zero-total refusal
and normalized shares. Inspect keyboard focus, disabled buttons, Tab order,
Space, Enter and Escape, narrow scrolling, maximized windows and native popups.
Perform actual Windows 100%, 150%, 200% and 225% scaling, high-contrast and
Narrator review. Record only the settings actually exercised.

## First Random session

Complete the opening tasks in the same session until **Journey to Settlement
assigns a trader marker**. The trader visit can happen later. Leaving earlier,
including an unexpected session end, may send the quest to Pine Forest on
return. The landing remains saved. This known issue is unchanged.

The contract separately checks uninterrupted assignment, early logout,
post-assignment return and a legitimate cross-biome trader fallback.

## Evidence and release boundary

The runtime is identical to the qualified `.001` payload. The new candidate
contains the polished manager, picture-only icon and customer instructions.
Its contracts authenticate reuse of the frozen prior build; there was no new
runtime build or qualification of the changed installed game.

Offline callbacks, geometry probes and startup smoke are recorded as DEV and
packaging evidence. Actual OS presentation and gameplay remain independent QA.
Publication awaits complete QA and approval of the exact customer ZIP.
The intended public listing label is **Tech Demo**. If a customer byte needs
repair, return it to DEV and create a new candidate.
