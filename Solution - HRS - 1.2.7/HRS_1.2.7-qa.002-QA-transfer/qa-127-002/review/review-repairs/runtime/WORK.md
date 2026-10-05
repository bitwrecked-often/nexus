# Runtime review repairs — 2026-10-04

F1/F2 and the related world/entity recovery guard are repaired in `c0167.cs`
and `c0185.cs`. No other runtime source changed in this task; the main source
count remains 15. Qualified builds, payload pins and candidate export belong
to the root handoff work, separate from these isolated DEV fixtures.

## Changes

- `PendingPlacement.ArmPositionRecovery` enables restoration before the first
  player/observer position mutation. `BeginPlacement` still starts the
  verification deadline after the semantic comparison. Retries retain their
  existing reset, delay and five-instance bound.
- The pending transaction retains its original world and player references.
  Update and recovery require that world reference, its GUID and the same
  player object; a reused entity ID alone is insufficient. A context failure
  still restores the original player when its owning world/entity remains
  active, while replacement worlds/entities remain untouched.
- The global intro quest prefix calls the existing
  `RuntimeEnvironmentGuard.IsStillApproved` before modifying its objective.
  Exact-name, case and supported-context rules therefore agree with placement.
- Durable Reserved/Completed markers and trader/first-spawn behavior are
  preserved. Recovery does not grant a reroll or undo a previously saved start.

## Executed DEV evidence

comparison.json binds the final identical harness and
before/after source identities:

| Source | Result | Receipt |
| --- | --- | --- |
| Preserved original source | 20 scenarios: 8 Pass, 12 Fail | before-r003/verification.json |
| Repaired source | 20 scenarios: 20 Pass, 0 Fail | after-r001/verification.json |

The harness links nine actual runtime files, including the consumer callbacks,
pending transaction, environment guard, MarkerStore and SemanticSnapshot.
It supplies controlled engine/resolver/file-writer seams and invokes actual
spawn, update, trader-acceptance and intro-prefix entrypoints. It does not
replace the affected decision functions with a test implementation.

The 12 baseline failures cover exceptions after player movement and observer
movement, an actual semantic digest mismatch, two replacement-world cases
(including equal GUIDs), a replaced player with the same entity ID, and six
intro quest name/context exclusions. All pass after repair.

The eight passing baseline checks remain passing: fifth-attempt placement and
trader completion, five unsafe attempts falling back, same-owner context
recovery, valid intro filtering, unmarked intro exclusion, wrong-name spawn
rejection, unmarked character reload rejection and normal respawn rejection.
Assertions check actual player/observer positions, result reasons, durable
markers, no-repeat behavior, distinct retry instances, retry delays and quest
objective state. The semantic mismatch intentionally changes fixture health
to exercise detection; the fixture does not claim to undo that injected health
change.

`before-source/` preserves the original linked source bytes. Earlier
`before-r001/fixture-build.txt` preserves an initial fixture compilation failure
from a missing resolver-stub property; `before-r002/` preserves the first
executable baseline. Neither is hidden or counted as a passing source test.

## Final source identities

- `c0167.cs`: `E3A476531E3895DEA60931EA7D175F8666D7D3DF579D5592C664CA9B965C3A1D`
- `c0185.cs`: `356416731D1DC0CBC6E052D45ED886750498AAB5A54EFB873BB8D60959181E60`

The final source diff was reviewed and whitespace checked with CR line endings
recognized. Runtime source remained idle after these identities were released
to the root build task.

This is isolated DEV source control-flow evidence, not engine integration or
independent customer gameplay QA. No game installation writes, game launches,
qualified customer builds, exports or publication were performed by this task.
Independent QA dispositions were not changed.
