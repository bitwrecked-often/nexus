# Historical Random Start 1.2.5-qa.002 — QA transfer

Extract the whole transfer ZIP into a writable local folder outside OneDrive
or other synced/linked folders. Open `qa-002`. Keep its contents together.
The frozen customer ZIP is the release candidate; the surrounding folders
and tools are engineering QA support.

Customer ZIP SHA-256:
`90C404EBE1A974448CA85529C1D1274DE6D2429B0A404BBB8E89323584A5966D`.

## First action

Close 7 Days to Die and leave Steam open. Run
`customer/HistoricalRandomStart_1.2.5/START.bat`.
Use the package-identity case first, then `context/dev/qa/cases.json`.
Enter the exact Game Name, choose settings, and click Apply Settings before
Launch Game. Confirm the name and settings in the confirmation dialog.

QA target: V3.3.0 b17, Windows PowerShell 5.1, local single-player, EAC off,
supplied TFP Harmony; Navezgane and Random Gen >=8192. Other versions receive
best-effort hook handling but need separate compatibility tests.

## Record cases

Open Windows PowerShell 5.1 in `qa-002`. Replace the game root and case ID
with actual values. Start the evidence run before performing its case:

```powershell
& .\tools\Test-HrsRelease.ps1 -LaneRoot .\context
& .\tools\Start-HrsQaRun.ps1 -LaneRoot .\context -CandidateArchivePath .\1.2.5-qa.002.zip -CaseId HRS-QA-001 -Mode Standard -GameRoot 'C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die' -RunRoot .\runs
```

Use the returned run path with `Record-HrsQaObservation.ps1` and
`Export-HrsQaRun.ps1`. The contract lists required evidence and tester checks.
Record only observed outcomes; use Fail or Blocked when appropriate.
See `QA-WORKFLOW.md` for examples; its old candidate names are historical.
Use **1.2.5-qa.002**, this context, and this contract's case IDs.

## DEV boundary

DEV testing is closed for transfer: 42 Pass, 7 Carried, 1 OperatorAttested,
7 Deferred, zero Pending. Carried records preserve prior-build regression;
the operator confirmed prior Weighted testing whose durable run identity was
not recovered. Named 100/150/200% scale checks and unavailable natural-world
repetitions were deferred. Actual 4K/225% keyboard/readability checks and
controlled failure consumers passed. This does not claim every row was a
fresh b17 live run. Do not restart DEV tests to repair historical bookkeeping.

The customer package has **36 Pending independent QA cases**. Its runtime is
byte-identical to the tested r005 DLL. The manager adds clearer launch
guidance, best-effort untested-version handling, recovery-folder preflight,
and the Bit Wrecked icon. The DEV game installation was restored afterward.

After independent QA and release-owner approval, Nexus and the site receive
the unchanged customer `1.2.5-qa.002.zip`. Do not publish this engineering
transfer ZIP. Any customer-byte repair requires a new candidate and QA cycle.
Publication has not been authorized.
