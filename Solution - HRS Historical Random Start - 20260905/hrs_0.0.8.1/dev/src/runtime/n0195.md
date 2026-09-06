# Phase 1A Relocation Probe Design 0.0.1

Date: 2026-08-20  
Status: Atomic-semantic runtime completion observed; persistence reload pending

This private probe implements one pinned relocation attempt for the exact local
single-player `Navezgane / HRS_Phase1A_Test_001` lane on V3.1.0 (b14).

## Guard and reservation phase

`PlayerSpawnedInWorld` accepts only a local `RespawnType.NewGame` event after
checking the pinned game assembly MVID, canonical game and save roots, exact
world and game names, EAC disabled, nondedicated server mode, local server
authority, single-player mode, and a resolved live world/player entity.

Before selection, the probe requires the persistent player CVar
`bitwrecked_hrs_state_v1` to be absent and writes/read-backs `Reserved=1` via
`EntityBuffs.AddCustomVar`. Once Reserved is established, every later failure
consumes the attempt. The probe never removes or repairs the marker and never
rerolls.

It retrieves the game-owned `SpawnPointList` and calls
`GetRandomSpawnPosition(world, null, 0, 0)` exactly once. Undefined, native-
invalid, or out-of-world-bounds candidates stop as Reserved. A passing result
is stored only in one in-memory `PendingPlacement` containing the exact world
GUID, entity ID, and candidate. The spawn handler then returns without moving
the player.

## Deferred atomic placement phase

On the first later `GameUpdate`, the probe revalidates compatibility, the exact
approved environment, the ordinal world GUID, player entity, and existing
player-owned `ChunkObserver`. It does not create, add, remove, or request an
observer or chunk.

The scheduling contract is tick-ordered rather than tick-perfect. No wall-clock
sleep, frame-rate assumption, or guessed tick number chooses the onramp. The
game signals spawn through `PlayerSpawnedInWorld`; returning from that handler
and receiving a later `GameUpdate` establishes the required lifecycle order.

Inside one uninterrupted handler invocation it performs this exact sequence:

1. capture the comprehensive semantic digest;
2. call `Entity.SetPosition(candidate, true)` once;
3. call the existing `ChunkObserver.SetPosition(candidate)` once;
4. emit the categorical `RELOC_PLACEMENT_CALLED` reason;
5. capture the identical semantic digest again;
6. require 64-bit digest equality;
7. emit `RELOC_SEMANTIC_UNCHANGED`; and
8. mark placement called while setting a deadline of
   `Time.realtimeSinceStartup + 30f`.

If the digest differs, the probe clears only the in-memory pending object,
emits `RELOC_SEMANTIC_CHANGED`, and leaves the persistent marker Reserved. The
atomic boundary means no return to a later game-update callback occurs between
the captures. It is not a CPU atomic operation, thread lock, frozen player, or
database transaction.

## Semantic digest

The digest uses a 64-bit FNV-1a-style accumulator with offset basis
`14695981039346656037` and prime `1099511628211`. Integers and floats are
incorporated bytewise, while strings incorporate UTF-16 code units after their
length. It is a private deterministic representation, not a claim of canonical
FNV serialization. Explicit `unchecked` blocks preserve wrapping multiplication
under the build-wide `/checked+` compiler setting.

The capture includes:

- player health and game stage;
- `EntityStats` health, stamina, food, and water as exact float bytes;
- progression level, experience-to-next-level, deficit, skill points, and
  `Progression.XPGain`;
- every indexed toolbelt and backpack slot;
- item type, metadata, quality, use time, activation state, selected ammunition
  index, and modification/cosmetic trees to the reviewed bounded depth;
- quest ID, current state, phase, active-objective count, and optional-complete
  state in journal order; and
- active buff name, stack-effect multiplier, and flags after ordinal sorting by
  buff name.

Null collections, collection lengths, slot indexes, and null elements receive
explicit sentinels or structural fields so absence and structure contribute to
the digest. Strings are processed as UTF-16 code units, integers as four
little-endian shifted bytes, and floats via `BitConverter.GetBytes`. Raw values,
names, coordinates, and the digest itself are never logged.

## Bounded spatial verifier

The placement callback returns after semantic equality. Subsequent
`GameUpdate` callbacks increment `Ticks`; no verification occurs before tick 2.
The verifier then:

1. revalidates the player and candidate bounds;
2. checks only the candidate's containing chunk through
   `WorldBase.GetChunkFromWorldPos(World.worldToBlockPos(candidate))`;
3. waits read-only until that chunk exists or the 30-second monotonic deadline
   expires;
4. calls `World.CanPlayersSpawnAtPos(candidate, false)` exactly once after
   readiness;
5. requires `Vector3.Distance(player.GetPosition(), candidate) <= 0.25f`; and
6. changes the marker from Reserved to Completed using AddCustomVar plus
   readback.

Only then does it clear pending and emit `RELOC_COMPLETED`. The verifier does
not use a fixed tick-count deadline, the broad neighboring-chunk rectangle, a
second placement, or an explicit chunk request.

## Failure semantics and exclusions

Every categorical failure clears only volatile pending state. Persistent
Reserved remains a one-shot tombstone that suppresses reload, death,
reconnect, or duplicate-event retries. Completed suppresses them as a proven
consumed success. Malformed nonzero marker values are also consumed and never
auto-repaired.

There is no marker removal, direct network CVar mutation, teleport, respawn,
console command, Harmony patch, player freeze, development-mode dependency,
file write, process launch, external network client, observer lifecycle
operation, or reroll path in the runtime artifact.

The successful exact-target runtime emitted
`RELOC_PLACEMENT_DEFERRED`, `RELOC_PLACEMENT_CALLED`,
`RELOC_SEMANTIC_UNCHANGED`, and `RELOC_COMPLETED`. A read-only persistence
reload remains required to prove Completed prevents a second runtime action.

The hard-coded canonical roots, exact game/save name, build MVID, and private
logging lane are laboratory containment controls. They must not be copied into
a distributable mod as player-specific production configuration. A release
implementation requires a reviewed portable policy/compatibility layer while
preserving the proven lifecycle, one-shot, atomic, and verifier invariants.
