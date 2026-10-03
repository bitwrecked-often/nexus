# Record QA for 1.2.6-qa.002

Run these commands in Windows PowerShell 5.1 from `qa-002`. Verify the matching
b17 environment first. The game is a runtime target; evidence goes in `runs`.

```powershell
& .\tools\Test-HrsRelease.ps1 -LaneRoot .\context
& .\tools\Start-HrsQaRun.ps1 -LaneRoot .\context -CandidateArchivePath .\1.2.6-qa.002.zip -CaseId HRS-QA-001 -Mode Standard -GameRoot 'C:\Games\7 Days To Die' -RunRoot .\runs
```

Replace the game folder with the real matching installation. Start the run
before performing the case. Use its returned evidence path in subsequent commands.
After observing the required checks, record only the checks actually confirmed:

```powershell
& .\tools\Record-HrsQaObservation.ps1 -RunPath '.\runs\1.2.6\<returned-run-id>' -ConfirmedChecks @('fresh-install-verified','game-environment-matches')
& .\tools\Export-HrsQaRun.ps1 -RunPath '.\runs\1.2.6\<returned-run-id>' -Outcome Pass -Kind QA -Notes 'Actual observations and limits.'
```

Those checks belong to HRS-QA-001. For other cases, use their own requiredChecks
and actual observations. Gameplay records may require position, prefab/instance,
biome, trader, quest and reload fields from Record-HrsQaObservation.ps1. Never
copy example values as observations. Use Fail or Blocked for failed checks or
missing fixtures. Each repeated attempt gets a new run.

Export freezes the evidence. Keep the exact candidate, receipt, companion,
context and tools together. Customer repairs return to DEV for another candidate.
After all required cases have complete passing evidence, the release owner can
record the local cycle decision:

```powershell
& .\tools\Complete-HrsQaCycle.ps1 -LaneRoot .\context -RunRoot .\runs -Decision Approve -Notes 'Complete actual QA evidence reviewed.'
```

That decision is not an upload. Publication separately distributes only the
unchanged customer ZIP after approval.