# Phase 1A Native-Aligned Post-Placement Readiness — Source Amendment

Date: 2026-08-20  
Decision: Source/static/pure tests PASS; compile/stage/live/run NO-GO

The owner authorized the native-aligned source amendment identified by the
chunk-readiness analysis. The two pre-placement checks were removed:

- `World.IsChunkAreaLoaded(candidate.position)`; and
- `World.CanPlayersSpawnAtPos(candidate.position, false)`.

The existing bounded post-placement verifier still requires exactly one
`IsChunkAreaLoaded(attempt.Candidate)` and exactly one
`CanPlayersSpawnAtPos(attempt.Candidate, false)` source call site before
position and semantic equality can complete the marker.

The unused pre-placement `RELOC_CHUNK_NOT_READY` and
`RELOC_CANDIDATE_UNSAFE` reason strings were removed from the sanitized
allowlist. No explicit chunk request, retry, reroll, rollback, teleport,
respawn, marker repair/removal, or new persistence operation was added.

The pure contract now models chunk timeout and unsafe destination as
post-placement verification failures that leave Reserved. Static ordering
requires:

```text
reserve -> one select -> semantic-before -> one SetPosition -> later bounded
chunk readiness -> safety -> position -> semantic-after -> Completed
```

Relocation static tests, semantic harness tests (7/7), and the full Phase 1A
contract (22/22) pass under PowerShell 7 and Windows PowerShell 5.1.

Updated eight-file source aggregate SHA-256:

`222E35A7AD8DB8118BD3B4A0C673D4F458C3954275DFA8640BBAA340EDB51D65`

No compiler ran. The live DLL remains the superseded
`CC70A8B04DD54A14E0CBBF59C7EA1B6F7969C4F747DBF47DC735CB870EF013BB`
artifact and must not be launched. The failed Reserved target remains present
and must not be reused. Recompilation, restaging, live replacement, and target
backup/reset remain separately gated.
