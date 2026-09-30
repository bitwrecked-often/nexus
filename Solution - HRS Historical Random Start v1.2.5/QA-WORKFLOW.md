# Candidate export and isolated QA

Current source: `hrs_1.2.3`. Current candidate: `1.2.3-qa.003`.
The separate 1.2.4 candidate `1.2.4-qa.001` is now exported for independent
QA; use its [laptop runbook](../hrs_1.2.4/dev/qa/QA_LAPTOP_RUNBOOK.md),
`rel.json` and `cases.json` for that cycle. The commands below retain 1.2.3
values as historical examples and must not be used as 1.2.4 point IDs.
Customer ZIP SHA-256:
`DAC526F54473543A5C7EF53503C69AE18E4961C39F8E5543293F3AC55E2F6BAA`.
The adjacent receipt and companion ZIP are required for engineering QA.
Customer installation requires only the customer ZIP.
For future versions, derive the customer top folder from the release version.
QA tests the exact customer ZIP; after approval, Nexus and the project site
receive that same archive hash and bytes. See the
[HRS QA bundle skill](../.agents/skills/hrs-qa-bundle/SKILL.md).

## Prepare an isolated workspace

From the repository root in Windows PowerShell 5.1:

```powershell
& .\qa_cycle\New-HrsQaWorkspace.ps1 -CandidateId 1.2.3-qa.003 -ArchivePath .\qa_cycle\candidates\1.2.3-qa.003.zip -Destination 'C:\HRS QA\candidate-003'
```

Use a new destination each time. Verification checks the registry, receipt,
archive hash, exact file list and every file hash before extraction.
The workspace holds customer/, context/, tools/, and copies of all three
candidate transport files. You can move that whole directory to another machine.
Use its own tools after moving it. Its registry snapshot defines the trusted
candidate; editing the registry is an authority change, not a repair for drift.

context/ contains frozen contracts and source/build evidence. customer/ is the
independent extracted package. Source changes in the development lane do not
alter this workspace. Private manager history is allowed in its defined state
directory and remains outside the customer archive.

## Run an actual case

The following commands prepare and record QA; the tester performs the gameplay
steps from context/dev/qa/cases.json. Use the actual game path and case result.
Run start before performing the case, so existing log events are excluded.

```powershell
Set-Location 'C:\HRS QA\candidate-003'
& .\tools\Test-HrsRelease.ps1 -LaneRoot .\context
& .\tools\Start-HrsQaRun.ps1 -LaneRoot .\context -CandidateArchivePath .\1.2.3-qa.003.zip -CaseId HRS-QA-003A -Mode Random -GameRoot 'C:\Games\7 Days To Die' -RunRoot .\runs
```

Use the returned evidence path below. Replace the point/coordinates with what
you observed; the script rejects excluded points. ConfirmedChecks are explicit
tester attestations, not observations inferred by the tool.

```powershell
$run = 'C:\HRS QA\candidate-003\runs\1.2.3\<returned-run-id>'
& .\tools\Record-HrsQaObservation.ps1 -RunPath $run -SelectedPointId '<observed-approved-ID>' -FinalX 0 -FinalY 0 -FinalZ 0 -LandingResult Safe -ConfirmedChecks @('fresh-character','safe-ground-landing')
& .\tools\Export-HrsQaRun.ps1 -RunPath $run -Outcome Pass -Kind QA -Notes 'Describe the observed result.'
```

For trader checks, also record SelectedTraderPlacement, StartingBiome and
ObservedTraderBiome from the contract's biome names. For intro/reload checks,
record QuestDestinationResult, StarterQuestProgression and ReloadResult.
Every case lists its requiredChecks and requiredEvidence. Use Fail or Blocked
when those outcomes apply. Use Kind Rollback for HRS-QA-008.
One matching event is not proof of protection, upgrade or a complete gameplay
case; those cases require the explicit observations and relevant installed hashes.

After all required cases have actual evidence, request a local cycle decision:

```powershell
& .\tools\Complete-HrsQaCycle.ps1 -LaneRoot .\context -RunRoot .\runs -Decision Approve -Notes 'Actual QA coverage reviewed.'
```

The command rejects missing cases, DEV evidence, registry/contract mismatch,
modified sidecars, missing evidence and damaged ZIPs. Export freezes each run;
repeat a case in a new run instead of overwriting it. Publication is a separate
decision and has not occurred.

## Export a future candidate

Never re-export an existing candidate ID. Preserve failed export reservations
and choose a new ID after repairing the cause. Export stages are retained for
diagnosis; only registered finished archives are admissible.

For a new package using the same runtime build, copy its exact build record to
dev/builds/<new-candidate-id>/build-record.json before generating contracts.
For runtime source changes, first run the pinned build described in
[the source lane](../hrs_1.2.3/LANE_README.md), then identify its exact output
and update the artifact pins deliberately.

```powershell
& .\qa_cycle\New-Hrs123Contract.ps1 -LaneRoot .\hrs_1.2.3 -CandidateId 1.2.3-qa.004 -SourceCommit '<full-base-commit>'
& .\qa_cycle\Export-HrsCandidate.ps1 -LaneRoot .\hrs_1.2.3 -CandidateId 1.2.3-qa.004 -OutputPath .\qa_cycle\candidates\1.2.3-qa.004.zip
```

The source snapshot hashes describe dirty working-tree bytes in addition to the
base commit. Contracts are frozen into the companion; file and archive hashes
are separate identities. ZIP timestamps need not reproduce across builds.

## Tool verification

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Test-HrsQaTools.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Test-HrsCandidateWorkflow.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Test-HrsCheckoutBytes.ps1
```

Workflow tests create temporary simulated games, logs, registries and QA runs.
Any passing cycle there is exclusively a software fixture. None is evidence
that candidate 003 has passed live gameplay.
