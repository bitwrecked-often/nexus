# Phase 1A Authoritative Chunk-Observer Lifecycle Analysis

Date: 2026-08-20  
Decision: Narrow native observer synchronization identified; no state changed

The owner authorized read-only analysis of the categorical
`RELOC_VERIFY_CHUNK_TIMEOUT` result.

Pinned `Assembly-CSharp.dll` IL establishes:

- `EntityPlayer.ChunkObserver` is a public
  `ChunkManager.ChunkObserver` field assigned by native player creation.
- `EntityPlayer.Update` normally calls
  `ChunkObserver.SetPosition(player.GetPosition())` when that field is non-null.
- `ChunkObserver.SetPosition(Vector3)` performs only one operation: it updates
  the observer's desired `position` field. It does not directly load, generate,
  write, or request a chunk.
- `ChunkManager.DetermineChunksToLoad` converts each observer's desired position
  to a chunk coordinate, detects a change from `curChunkPos`, rebuilds its
  normal `chunksAround`/`chunksToLoad` sets, and wakes the existing chunk
  calculation pipeline.
- `ChunkManager.AddChunkObserver` is not needed: the player already owns the
  native observer, and creating a second observer would add unnecessary
  lifecycle/removal obligations.

The runtime proof shows that plain post-spawn `SetPosition` and local
`Origin.Reposition` were insufficient to propagate the distant jump through the
existing authoritative observer before the 30-second deadline. The precise
scheduler ordering is not externally observable from privacy-safe logs, so the
analysis does not claim an unproven internal race as fact.

## Smallest native-aligned correction

1. Resolve and require the existing `player.ChunkObserver` before placement. If
   absent, leave Reserved and stop with a fixed sanitized reason.
2. Preserve the one semantic-before capture and one virtual
   `player.SetPosition(candidate, true)` call.
3. Immediately call the existing observer's
   `SetPosition(candidate)` exactly once, matching the operation normally
   performed by `EntityPlayer.Update`.
4. Preserve the 30-second monotonic verifier and all context, bounds, loaded
   chunk, safety, position, semantic, and Completed gates.

This adds no new observer, explicit chunk-provider request, retry, reroll,
second player placement, rollback, teleport, respawn, or marker repair/removal.
The chunk manager remains solely responsible for normal loading/generation.

No source, compiled artifact, staged payload, live Mod, or save was changed by
this analysis. The timeout target remains Reserved and must not be reused.
