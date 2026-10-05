# Historical Random Start QA cycle

This directory provides the repeatable DEV-to-QA evidence process for every
Historical Random Start release. It keeps one release contract, one QA contract,
and one immutable evidence bundle tied to the exact bytes that QA tested.

For the current repository state, start with [the AI entry point](../AGENTS.md),
[current baseline](../CURRENT_BASELINE.md), and the
[1.2.7 lane manifest](../HRS_1.2.7_LANE_WORK_MANIFEST.md). Current DEV source is
`hrs_1.2.7`, publicly **New Player Random Start**. The owner-selected full
public-package target is **1.2.7-qa.003**, pending implementation and readiness
verification. Candidate 002 and earlier archives stay unchanged. All 46
independent 1.2.7 cases remain Pending.

Use [the candidate workflow](CANDIDATE_WORKFLOW.md) for the complete package
policy. QA, customers, Nexus and the project site receive one self-contained
ZIP with the exact same bytes and SHA-256, including the product, redistributable
source/build instructions, history, lore, contracts, tools and evidence. Its
normal product entry stays simple. No recipient needs an unpublished companion
to explore the project material. Only the verified owned runtime payload is
installed into the game; everything else stays in the extracted package.

The command examples below retain their historical lanes. `CURRENT_RELEASE.json`
is the preserved 1.2.3 release map; `hrs_1.2.1/dev/qa/rel.json` is preserved
historical 1.2.0 metadata. The reported 1.2.3 promotion ZIP is not yet reconciled
in this checkout, so do not create a new approval record or substitute another
archive for that historical release.

All commands support Windows PowerShell 5.1. Run them from the repository root.

## Files of record

Each active version lane contains:

- `dev/qa/rel.json` — canonical version, build, supported environment, feature
  scope, artifact identities, and release rules;
- `dev/qa/cases.json` — required QA cases, expected events, forbidden events,
  and required evidence.

The scripts in this directory validate those records and create sanitized
evidence under the ignored `qa_runs/` directory.

## Start a new development cycle

First create the new version lane and its verified payload. Then initialize the
cycle records from the established contract:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\New-HrsCycle.ps1 `
  -LaneRoot .\hrs_1.0.2 `
  -TemplateLaneRoot .\hrs_1.1.0 `
  -Version 1.0.2 `
  -BuildId r102 `
  -SourceCommit <full-40-character-commit>
```

The initializer reads the new lane's verified DLL and `ModInfo.xml`; it does
not copy or rebuild payload files. Review the generated scope before testing.

Run the release gate:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Test-HrsRelease.ps1 `
  -LaneRoot .\hrs_1.0.2
```

The gate verifies artifact sizes and hashes, `ModInfo.xml`, manager pins,
manager/deployment versions, game MVID, runtime-log identity, the declared
approved spawn scope and its runtime allowlist, nearest-trader markers,
starter-quest markers, and the QA contract. Any error blocks QA handoff.

## Capture a DEV run

DEV can collect evidence while a known readiness gap remains, but must use the
explicit override. Such a bundle is labeled DEV and cannot serve as QA approval.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Start-HrsQaRun.ps1 `
  -LaneRoot .\hrs_1.1.0 `
  -CaseId HRS-QA-003A `
  -Mode Random `
  -GameRoot 'D:\SteamLibrary\steamapps\common\7 Days To Die' `
  -AllowDevelopmentGap
```

Run the game and perform only that case. Then export:

For gameplay cases, first record the bounded observation. This example records
the final position, calculates the expected nearest reviewed trader placement,
and compares it with the placement QA observed:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Record-HrsQaObservation.ps1 `
  -RunPath '<path printed by Start-HrsQaRun.ps1>' `
  -SelectedPointId NG01 `
  -FinalX -1528 `
  -FinalY 74 `
  -FinalZ 1700 `
  -LandingResult Safe `
  -SelectedTraderPlacement TP02 `
  -QuestDestinationResult Confirmed `
  -StarterQuestProgression Works
```

Then export:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Export-HrsQaRun.ps1 `
  -RunPath '<path printed by Start-HrsQaRun.ps1>' `
  -Outcome Pass `
  -Kind DEV `
  -Notes 'Fresh Random game selected NG01; landing and trader route observed.'
```

## Capture a QA run

QA uses the same commands without `-AllowDevelopmentGap`. The start command
refuses to proceed unless the release gate is clean.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Start-HrsQaRun.ps1 `
  -LaneRoot .\hrs_1.0.2 `
  -CaseId HRS-QA-004 `
  -Mode Random `
  -GameRoot 'D:\SteamLibrary\steamapps\common\7 Days To Die'
```

After the case:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Export-HrsQaRun.ps1 `
  -RunPath '<run path>' `
  -Outcome Pass `
  -Kind QA `
  -Notes 'Nearest trader and starter quest destination verified in game.'
```

The export compares expected and forbidden runtime events, but QA's declared
result remains separate. A declared Pass with an event mismatch requires review;
automation does not silently rewrite a tester's observation.

## Complete the cycle

After all required cases have exported passing QA bundles, record the release
decision:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Complete-HrsQaCycle.ps1 `
  -LaneRoot .\hrs_1.0.2 `
  -Decision Approve `
  -ApproverRole ReleaseOwner `
  -Notes 'All required cases passed against the exact release digest.'
```

Approval is refused unless the release gate is clean and every contract case
has a non-DEV passing evidence ZIP for the same `rel.json` digest. HRS-QA-008
must be exported as `Rollback`. A rejection may be recorded at any time and
lists the missing cases and current readiness state.

## Rollback case

Start `HRS-QA-008` before using **Remove from Game**, perform the removal, and
export with `-Kind Rollback`. The bundle includes the before/after installed
inventories and `rollback-receipt.json`. Clean rollback requires the owned
release path to be absent afterward.

## Evidence bundle

Each ZIP contains:

- release and QA contracts;
- release validation and package inventory;
- sanitized environment identity;
- installed inventories before and after the case;
- only `[HRS]` runtime events produced after the run started;
- manager history produced after the run started, with game name redacted;
- result fingerprint summary;
- QA result and human notes;
- rollback receipt when applicable; and
- a SHA-256 evidence manifest.

`session.local.json` contains local source paths needed during capture. It stays
beside the working run and is deliberately excluded from the ZIP. Save contents,
usernames, machine names, full paths, Steam identifiers, and unrestricted game
logs are not exported by tool-generated fields. The `-Notes` value is included
verbatim, so the tester must keep it sanitized and must not paste private paths
or unrestricted logs into that field.

## Promotion rule

Approval applies to the release-record digest and artifact hashes in the QA
bundle and to the complete public archive tested by QA. QA, customers, Nexus
and the site receive that same full ZIP, including the embedded project source,
history, lore and evidence. Compare its complete SHA-256 at every handoff.
Do not rebuild, edit, re-pin, repackage, or substitute a smaller product ZIP
after QA. Any byte or scope change creates a new candidate and a new QA cycle.
Later QA observations remain outside the frozen archive until a later candidate
includes them; publication is a separate authorized action.

## Tool self-test

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Test-HrsQaTools.ps1
```

The self-test uses a uniquely named temporary directory, verifies the current
known selector gap is detected, creates a DEV evidence ZIP, confirms private
local state is excluded, and removes only that temporary directory.
