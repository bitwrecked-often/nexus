# Phase 1A Native Authored-Spawnpoint Proof — Pre-Build Packet 0.0.1

Date: 2026-08-20  
Decision: Design/pure-test work GO; mutating source/build/install/run NO-GO

## Objective

For one new disposable local single-player character, prove one
server-authoritative relocation from the already-established vanilla spawn to
one game-owned authored spawnpoint. Do not add arbitrary coordinates, distance
bands, rooftops, drop behavior, protection, biome suppression, trader routing,
or launcher policy.

## Exact eligible lane

All must match before any marker or placement work:

- installed build/API fingerprint already proven in Phase 1;
- exact owner-designated lab and a new target named
  `Navezgane / HRS_Phase1A_Test_001`;
- local single-player, EAC disabled, authoritative server path;
- exact `RespawnType.NewGame`;
- resolved `EntityPlayer`;
- internal test policy `Random` explicitly pinned in the private artifact; and
- marker `bitwrecked_hrs_state_v1` absent.

Standard is an exact zero-action path. `EnterMultiplayer`, `JoinMultiplayer`,
LoadedGame, Died, Teleport, Unknown, client, dedicated, EAC, mismatched build,
and mismatched target all return before marker access.

## One-attempt state machine

1. Read the game-owned player CVar marker.
2. If missing, write `Reserved=1` before candidate selection and immediately
   read it back. Failure stops with vanilla spawn untouched.
3. Obtain the current native `SpawnPointList`.
4. Call `GetRandomSpawnPosition(world, null, 0, 0)` exactly once.
5. Reject undefined, `bInvalid`, or out-of-bounds results.
6. Follow the native respawn lifecycle: placement precedes distant-chunk
   readiness; do not request chunks explicitly or add a pre-placement loaded
   chunk/safety gate.
7. During the spawn event, retain only the validated world/entity context and
   one selected candidate. Defer mutation until the first later GameUpdate so
   native respawn finalization has returned; then revalidate the context and
   existing observer and capture the semantic state snapshot immediately before
   placement.
8. In that deferred GameUpdate, call `Entity.SetPosition(candidate.position,
   true)` exactly once. Do not call
   `EntityPlayer.Teleport`, `Respawn`, a console command, or Harmony.
   Immediately afterward, synchronize the player's existing `ChunkObserver`
   to the same candidate exactly once. Never create, add, remove, or explicitly
   request a chunk observer. In that same callback, immediately capture the
   same full semantic snapshot again and require equality before beginning the
   verification window. Do not recapture or compare semantics across later
   update ticks.
9. After at least two update callbacks, use a 30-second monotonic Unity
   realtime window to wait read-only for the same entity/world target's
   containing chunk to load. Do not require the broader `IsChunkAreaLoaded`
   neighbor rectangle. Once the containing chunk exists, call native spawn
   safety exactly once, then require a small distance tolerance. A terminal
   failure emits only a fixed categorical reason without coordinates or values.
10. Only then write/read back `Completed=2`.

Any failure after successful reservation leaves `Reserved`; it never clears the
marker, selects again, or rerolls on reload/death/reconnect. Malformed or other
nonzero state is treated as consumed/invalid and never repaired automatically.

## Native API basis

- `GameManager.GetSpawnPointList()`
- `SpawnPointList.GetRandomSpawnPosition(World, Nullable<Vector3>, int, int)`
- `SpawnPosition.position`, `heading`, `bInvalid`, `IsUndef()`
- `World.IsChunkAreaLoaded`, `World.IsPositionInBounds`
- `World.CanPlayersSpawnAtPos(Vector3, false)`
- `Entity.GetPosition()`, `Entity.SetPosition(Vector3, true)`
- `EntityPlayer.ChunkObserver`, `ChunkManager.ChunkObserver.SetPosition(Vector3)`
- `EntityBuffs.HasCustomVar`, `GetCustomVar`, and a reviewed network-synced
  set operation for `bitwrecked_hrs_state_v1`

The exact CVar write overload and save/sync timing must be proven in a staged
marker-only subtest before relocation is compiled into an executable artifact.

## Required semantic evidence

Capture allowlisted before/after values without identity or raw save copying:

- position hash/quantized displacement, not raw published coordinates;
- marker state and read-back result;
- lifecycle and authority;
- quest count/state digest;
- inventory slot/item/count digest;
- XP, level, gamestage, health, food, water, and active-buff digest;
- target-save aggregate and protected-tree hashes; and
- selected/final-position safety and verification booleans.

Expected changes are limited to position, the one namespaced marker, and
ordinary base-game save/timestamp data. Quest, reward, XP, level, gamestage,
inventory, health, food, water, unrelated buffs, XML, foreign Mods, and other
saves must remain semantically unchanged.

## Rollback

Create a fresh target-specific save backup before any marker write. A failed
test preserves evidence, removes only the exact owned Phase 1A DEV folder, and
restores only the exact disposable Phase 1A target from that backup after owner
approval. Removing the helper alone does not undo an already completed
relocation.

## Stop conditions

Stop before source/build if marker read-back or save timing is uncertain, if
`SetPosition` cannot be verified without a second mutation, if the authored
candidate is unsafe/unloaded, if semantic snapshots expose private data, or if
any requirement expands into Phase 1B/1C/2 behavior.

## Current gate

Pure state-machine tests exist under `tests/Phase1A.ContractModel.psm1` and
`tests/Invoke-Phase1APureContractTests.ps1`. No Phase 1A runtime source, DLL,
live Mod folder, or new Phase 1A save exists. Source scaffolding requires the
next explicit owner review after pure tests and API details pass.

## Marker-only proof result — 2026-08-20

The corrected marker-only probe passed on the pinned local single-player lane.
`AddCustomVar(Name, 1f)` produced immediate `MARKER_RESERVED_VERIFIED`, and a
normal save/exit/read-only reload produced `MARKER_RELOAD_RESERVED`. Direct
`SetCustomVarNetwork` was rejected by evidence because installed IL and runtime
tests proved it only sends a package and does not update the local dictionary.

Marker API and ordinary save/reload persistence are now GO for relocation
source design. Candidate selection, placement, bounded later-tick verification,
semantic state-delta capture, and Completed transition are still unimplemented
and unproven. Relocation source/build/install/run remain NO-GO pending the next
explicit owner authorization and review.
