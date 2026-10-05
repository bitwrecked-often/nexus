# Candidate export and isolated QA

## Current complete public-package policy

Current development, 2026-10-05: `hrs_1.3.0_Tech_Demo` implements the returned
manager corrections and displays **Tech Demo | 1.3.0**. Follow the
[Tech Demo manifest](../../docs/DEV-1.3.0-TECH-DEMO.md) and
[readiness record](../hrs_1.3.0_Tech_Demo/dev/qa/QA_BUNDLE_READINESS.md).
Its 1.3.0-qa.002 package is sealed and independently verified. The owner requested
the visible label **Game Name**; the new full candidate is planned as
`1.3.0-qa.003`. Preserve 001/002 and their evidence. Its frozen bytes and
independent verification are recorded at export. All 46 formal cases remain
Pending. Source fixtures do not establish live gameplay or human acceptance.
The 1.2.7 identities below describe preserved history.

Owner-selected 2026-10-04: **QA, customers, Nexus and the project site receive
one complete ZIP, byte for byte.** The public package contains the product and
redistributable project source, build instructions, history, lore, frozen
contracts, tools and evidence. Its normal product entry remains simple; all
supporting material is available for optional review and future development.

Preserved DEV source is `hrs_1.2.7`, publicly **New Player Random Start**.
Its exported, registered and frozen full package is **1.2.7-qa.003**. Follow the
[lane manifest](../../history/versions/DEV-1.2.7.md) and
closeout for implementation,
export identity and executed verification. Candidate 002 stays preserved under
the earlier split layout. All **46 independent cases remain Pending**;
publication awaits actual independent QA and release-owner approval.

The canonical archive is
1.2.7-qa.003.zip, **5,037,729 bytes**, SHA-256:
`8527F11CAAFF4173AB9880FD906E9E7DF4F6C56E45E2B81098F5688C94B27881`.
Its root `START.bat` opens `customer/HistoricalRandomStart_1.2.7` directly.
`README.md` and `START-HERE.md` explain the product and optional project reading;
`source/hrs_1.2.7`, history, lore, evidence, context and tools are included.
There is no nested product ZIP and no required adjacent receipt or companion.

Use an unused candidate ID and output path. Before export, run the source
release gate, verify the pinned build and product identities, and review the
declared complete package inventory. Include project licensing notices and
retain the original scope of historical evidence. Do not distribute private
local state or proprietary game files. A DEV receipt may record the final
archive digest separately, but every public recipient must be able to inspect
and verify the package without an unpublished companion download.

Independently extract the full archive into an unused directory outside the
live game and use its own frozen contracts and tools for QA. Verify the complete
archive identity and every declared file, including source, history and
evidence. Only the verified owned runtime payload is installed into the game;
the supporting project material remains in the extracted public package.

After all required cases pass and the release owner records approval, promote
that exact full ZIP to Nexus and the site. Compare its complete SHA-256 at each
destination. No post-QA rebuild, edit, recompression or replacement with a
smaller product ZIP is allowed. New observations are append-only external
records until a later candidate includes them; adding them to the frozen ZIP
requires a new candidate and QA cycle.

## Standalone QA from the same public ZIP

Verify the downloaded archive against the trusted published SHA-256 before
running included tools. Extract it into a temporary reading directory outside
the live game, then use its bundled extractor to create an unused QA directory.
From that initial extraction in Windows PowerShell 5.1:

```powershell
& .\tools\New-HrsQaWorkspace.ps1 -CandidateId 1.2.7-qa.003 -ArchivePath 'C:\Downloads\1.2.7-qa.003.zip' -Destination 'C:\HRS QA\qa-127-003' -ExpectedArchiveSha256 '8527F11CAAFF4173AB9880FD906E9E7DF4F6C56E45E2B81098F5688C94B27881'
```

Use the actual download path and a new destination. `-ExpectedArchiveSha256`
provides the explicit trusted archive identity when no matching trusted local
registry exists. The tool verifies the full manifest/file set before extraction
and creates local QA receipt and registry records outside the frozen listed
content. An external DEV receipt is an optional checksum record; it is never
a required extra public download. Use the new workspace's `START-HERE.md`,
frozen contracts and tools for actual cases; keep the ZIP unchanged.

## Export another full public candidate

Prepare the additional public content from the active manifest, then invoke
`Export-HrsCandidate.ps1` with `-PublicContentRoot`, the matching `-LaneRoot`,
unused `-CandidateId` and unused `-OutputPath`. This opt-in writes the single
complete public archive. It does not create a companion ZIP. The exporter may
write a separate DEV receipt for the publishing checksum record. Without
`-PublicContentRoot`, the exporter retains the historical split format only
for legacy workflows; that mode does not satisfy the current public-package
policy. Never re-export the existing candidate 003 or reuse a failed reservation.

See the [HRS QA bundle skill](../support/current-dev-guidance/.agents/skills/hrs-qa-bundle/SKILL.md) and
[routing policy](../support/current-dev-guidance/HRS_DEV_QA_NEXUS_WORKFLOW.md).

## Preserved split-package workflow and command examples

The remainder records the earlier customer ZIP/engineering companion workflow.
Its commands and identifiers are historical examples for the existing legacy
format; they do not define the new full-package format. Use the active lane's
verified runbook and supported exporter/extractor for new candidates.

Preserved source: `hrs_1.2.3`. Preserved candidate: `1.2.3-qa.003`.
The separate 1.2.4 candidate `1.2.4-qa.001` is now exported for independent
QA; use its laptop runbook,
`rel.json` and `cases.json` for that cycle. The commands below retain 1.2.3
values as historical examples and must not be used as 1.2.4 point IDs.
Customer ZIP SHA-256:
`DAC526F54473543A5C7EF53503C69AE18E4961C39F8E5543293F3AC55E2F6BAA`.
The adjacent receipt and companion ZIP are required for engineering QA.
Customer installation requires only the customer ZIP.
For future versions, derive the customer top folder from the release version.
QA tests the exact customer ZIP; after approval, Nexus and the project site
receive that same archive hash and bytes. See the
[HRS QA bundle skill](../support/current-dev-guidance/.agents/skills/hrs-qa-bundle/SKILL.md).

## Legacy: prepare an isolated workspace

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

## Legacy: run an actual case

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

## Legacy: export a candidate

Never re-export an existing candidate ID. Preserve failed export reservations
and choose a new ID after repairing the cause. Export stages are retained for
diagnosis; only registered finished archives are admissible.

For a new package using the same runtime build, copy its exact build record to
dev/builds/<new-candidate-id>/build-record.json before generating contracts.
For runtime source changes, first run the pinned build described in
the source lane, then identify its exact output
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
