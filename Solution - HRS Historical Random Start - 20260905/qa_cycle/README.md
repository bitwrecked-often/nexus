# Historical Random Start QA cycle

This directory provides the repeatable DEV-to-QA evidence process for every
Historical Random Start release. It keeps one release contract, one QA contract,
and one immutable evidence bundle tied to the exact bytes that QA tested.

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
manager/deployment versions, game MVID, runtime-log identity, approved spawn
points, two-point random-selection requirement, nearest-trader markers,
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
bundle. Do not rebuild, edit, re-pin, or repackage after QA. Any byte or scope
change creates a new version and a new QA cycle.

## Tool self-test

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Test-HrsQaTools.ps1
```

The self-test uses a uniquely named temporary directory, verifies the current
known selector gap is detected, creates a DEV evidence ZIP, confirms private
local state is excluded, and removes only that temporary directory.
