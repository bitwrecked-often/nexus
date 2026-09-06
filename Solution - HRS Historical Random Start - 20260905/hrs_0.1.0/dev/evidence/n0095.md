# Phase 1A Observer Scheduling-Path Failure Analysis

Date: 2026-08-20  
Decision: Scheduler path operational; verifier neighborhood mismatch identified

The owner authorized read-only analysis after the observer-synchronized run
ended with `RELOC_VERIFY_CHUNK_TIMEOUT`. No source, payload, live mod, save, or
game process was changed.

## Native scheduling path

Pinned `Assembly-CSharp.dll` IL establishes:

- `GameManager.gmUpdate` calls `ChunkManager.DetermineChunksToLoad` every normal
  game update.
- `DetermineChunksToLoad` reads each existing observer's desired `position`,
  converts it to a chunk coordinate, compares it with `curChunkPos`, and rebuilds
  `chunksAround` and server-side `chunksToLoad` when the coordinate changes.
- A position change alone sets the internal calculation/registration change
  flags and signals `calcThreadWaitHandle`. Neither `ForceUpdate`, a new
  observer, nor an explicit provider request is required for this normal path.
- `ChunkObserver.SetPosition` changes the exact desired-position field consumed
  by that method.

The current source performs the one observer synchronization immediately after
the one player placement. The scheduler therefore has the native input it
expects before subsequent `gmUpdate` calls.

## Verification mismatch

`World.IsChunkAreaLoaded(Vector3)` is not a containing-chunk test. Its IL:

1. floors the candidate X/Z coordinates;
2. constructs bounds at X/Z minus 8 and plus 8;
3. converts both bounds to chunk coordinates; and
4. requires every chunk in that inclusive rectangle to exist.

Depending on the candidate's position within a chunk, this can require up to
four chunks. A single missing neighboring chunk therefore produces false even
when the candidate's containing chunk exists.

By contrast, `World.CanPlayersSpawnAtPos(Vector3, false)` converts the candidate
to a block position, obtains only its containing chunk, returns false if that
chunk is absent, and otherwise delegates to that chunk's native spawn-safety
check. This is the narrower authority relevant to the selected position.

The native respawn-point coroutine also uses `IsChunkAreaLoaded`, but only as a
bounded neighborhood wait before it abandons that target and selects a fallback.
Phase 1A deliberately prohibits reroll/fallback, so copying that broad predicate
as a terminal acceptance requirement incorrectly converts incomplete neighbor
settling into permanent failure.

## Runtime corroboration

Both observer-synchronized failed targets contain four region data files, but
only two region identities are common between the predecessor and current run.
Without publishing region names or coordinates, this is consistent with the
scheduler performing work for different destination regions. This is
corroborating inference, not proof that every candidate-neighbor chunk completed.

## Smallest bounded correction

Retain the existing observer synchronization and 30-second monotonic window,
but replace the broad area-loaded gate with containing-chunk readiness:

1. resolve the candidate's containing chunk read-only;
2. while it is absent and before the deadline, continue settling;
3. if still absent at the deadline, emit `RELOC_VERIFY_CHUNK_TIMEOUT`;
4. once present, call the existing native `CanPlayersSpawnAtPos(candidate,
   false)` exactly once and classify false as `RELOC_VERIFY_UNSAFE`;
5. retain position tolerance, semantic equality, and Completed gates unchanged.

This adds no explicit chunk request, second placement, observer lifecycle call,
retry, reroll, rollback, teleport, respawn, or marker repair. The failed target
remains Reserved and must not be reused.

Next gate: authorize Phase 1A containing-chunk readiness verification source amendment.
