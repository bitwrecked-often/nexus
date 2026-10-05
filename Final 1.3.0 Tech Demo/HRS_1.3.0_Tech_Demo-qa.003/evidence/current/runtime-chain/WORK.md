# 1.3.0 Tech Demo runtime chain DEV verification

Date: 2026-10-05, America/Los_Angeles.

The expanded source harness passes **58/58** scenarios: the original 20 repair
checks are retained, and 38 checks exercise additional runtime chain decisions.
Three deliberately broken callback copies are also detected. Production runtime
sources, the installed game and formal QA case states were not changed by this
work.

The authoritative unmodified-source result is
[run-002/verification.json](run-002/verification.json). Its recorded hashes bind
the exact nine runtime files, harness project, Program, Stubs and native runner
to the assertions. The fresh production double build and artifact qualification
are separate evidence; this controlled harness is not the customer DLL.

## What the checks establish

| Group | Added checks | Observed decision and boundary |
| --- | ---: | --- |
| Standard and runtime environment | 9 | Standard leaves the ordinary start and marker intact. EAC, multiplayer, dedicated, client, absent connection, remote player, incompatible build and case-sensitive name mismatch do not move, draw a new location or reserve a marker. |
| Returning characters and marker state | 4 | Completed returns preserve position, original biome and protection family even with a changed preference; a follow-up spawn cannot start another transaction. Reserved and invalid returns do not restart placement. |
| Stored protection families | 5 | Burnt, Desert, Wasteland and Snow return paths remove their five recognized family buffs and maintain that family's timer while retaining another family's hazard and an injury. An explicit protection opt-out retains the hazards and timer. |
| Trader metadata preflight | 5 | Initially empty metadata rejects before movement/reservation. Delayed-ready metadata completes without redrawing the pool. Deadline, becoming-empty and name-change failures leave the original start and absent marker intact. |
| Pending trader route | 5 | A loaded completed character's pending journal route assigns the selected location once. Failed destination writes restore the original objective fields and retry; unavailable traders wait without reserving/editing the objective. Cross-biome fallback is logged. Wrong-name completed returns leave their pending quest untouched. |
| Intro objective ownership and mapping | 8 | Ambiguous, already-positioned, other-phase and ordinary-job objectives remain unchanged. Burnt, Desert, Wasteland and Forest mappings use the stored initial biome; the original suite retains Snow and environment-rejection checks. |
| Placement timeout recovery | 2 | Unavailable chunks and an unstable surface fail by the verification deadline and recover the same player's original position while retaining the consumed reservation. |
| **Total additions** | **38** | **Together with the original 20: 58 Pass, zero failures.** |

The original scenarios continue to cover player/observer partial-move failures,
semantic mismatch recovery, five distinct retries without a biome redraw,
same-world/player ownership of restoration, valid placement/trader routing,
intro environment guards, wrong-name first spawn, loaded unmarked characters
and ordinary respawn.

The linked real source files are `c0167.cs`, `c0185.cs`, `c0213.cs`, `c0181.cs`,
`c0218.cs`, `PolicyV1.cs`, `PolicyV2.cs`, `BiomePreference.cs` and `ResultV1.cs`.
The harness invokes the actual spawn/update/intro-prefix callbacks and marker
operations. Engine state, POI/trader resolver results, compatibility, Harmony,
logging and result I/O use controlled seams. Production resolver weighting,
placed geometry, hooks and filesystem ownership need their own checks.

“Return” here means retained in-memory marker state with reset transient callback
fields and engine subscriptions. It proves callback decisions on that state;
it does **not** prove game save serialization, a real process restart or live
buff/quest persistence. Timer and hazard assertions likewise establish source
behavior under the supplied engine seams, not actual damage immunity.

## Deliberate failure detection

[mutations-003/verification.json](mutations-003/verification.json) records the
three isolated source variants and production-source before/after hashes.

| Deliberate change in a copied c0167.cs | Required detector | Result |
| --- | --- | --- |
| Disable the completed-return branch | CompletedProtectedReturnDoesNotRelocate | Detected; ten scenarios fail in the broken copy. |
| Remove both loaded-return and maintenance opt-out gates | ExplicitProtectionOptOutReturn | Detected; one scenario fails. Both gates are removed because either unchanged gate still protects the opt-out. |
| Omit the original biome-filter restoration after a destination failure | FailedTraderDestinationRestoresAndRetries | Detected; one scenario fails. |

Expected failures of deliberately mutated copies are test-detection evidence,
not product failures. All fifteen production C# files remained byte-identical
through the mutation run. Earlier `mutations-001` and `mutations-002` contain
preserved instrumentation attempts; they are not the acceptance receipt.
`run-001` also passed 58 scenarios before the runner's evidence-scope wording
was finalized. Use `run-002` and `mutations-003` for this checkpoint.

Reproduce with existing Windows PowerShell 5.1 and the installed .NET toolchain;
choose unused output directories to preserve earlier evidence:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File hrs_1.3.0_Tech_Demo/dev/tests/Test-RuntimeReviewRepairs.ps1 -EvidenceRoot hrs_1.3.0_Tech_Demo/dev/qa/runtime-chain-20261005/run-003

powershell.exe -NoProfile -ExecutionPolicy Bypass -File hrs_1.3.0_Tech_Demo/dev/qa/runtime-chain-20261005/Test-MutationDetection.ps1 -EvidenceRoot hrs_1.3.0_Tech_Demo/dev/qa/runtime-chain-20261005/mutations-004
```

## Remaining human runtime chain

The QA return finishes a GUI feedback round. It records no gameplay start and
keeps all 46 formal baseline cases Pending. This new source harness grants no
independent QA passes. The returned HUMAN-TEST and DEV-WORKSTATION plans remain
the human campaign inputs, subject to the final candidate's frozen contract.

1. Record acceptance of the delivered features and appearance, freeze and verify
   the new complete public candidate, and resolve the playable-game identity
   qualification gap before formal gameplay. The preserved b17 reference-only
   root supports builds and contains an inert game-executable sentinel.
2. Exercise Navezgane and existing Random Gen worlds of at least 8192 with Any,
   five chosen biomes and Mixed/ZeroExclusion/SinglePositive weights. Confirm
   real selected/final biome, placed POI identity, stable landing and marker
   events under the production resolvers.
3. Play the opening tasks without logging out until Journey to Settlement
   assigns its first trader destination. Preserve the actual marker and route
   evidence, then return before visiting and verify the destination persists.
   Complete trader visits, intro progression and ordinary jobs on the selected
   deeper fixtures. Cross-biome trader fallback can be legitimate.
4. Verify protection on/off, protected saved return and hazards in another biome
   in actual play. Check changed preferences, a played Standard character loaded
   under Random, ordinary respawn, fresh wrong-name and completed pending-quest
   wrong-name sessions without renewed placement or quest ownership.
5. Keep the early-logout fixture separate and document the known first-trader
   session limitation. The fixture checks do not establish that it was repaired.
   Use suitable additional fixtures for unavailable requested biome, absent
   positive-weight pools and terminal fallback when required by the contract.

The return budgets 21 distinct fresh-save scenarios plus compatible login/process
sessions. Preserve separate case records and start evidence before the relevant
actions. Real geometry, damage behavior, save/quest persistence, production
selection coverage and uncoached newcomer/display/accessibility acceptance
remain separate from these controlled DEV assertions. Publication is not
authorized by this component result.
