# Phase 0 Discovery Report

Date: 2026-08-13

Method: Read-only local inspection of the installed game, current assemblies,
world/save layouts, framework references, launcher behavior, and test harnesses

Result: Conditional GO

## Executive Result

The project is technically feasible on the inspected build without Developer
Mode, console commands, core-DLL edits, `spawnpoints.xml` edits, or Harmony-file
modification. The preferred route uses current native ModAPI spawn events,
native spawnpoint and terrain APIs, and server-authoritative placement.

The principal unproven areas are arbitrary-coordinate Random placement around
unloaded chunks, temporary-protection behavior, crash durability, clean-client
behavior, and the final launcher-to-runtime policy handoff.

## Inspected Baseline

- Game: 7 Days to Die V3.1.0 b14
- Unity player version: 2022.3.62f2
- Steam build ID: 24436778
- `Assembly-CSharp.dll` SHA-256:
  `B13862E30D8B28F42B83FE6A36BF074D155A6C43164E7B0797A6E4F77BD7DEA3`
- TFP Harmony wrapper: 1.1.0.4
- Harmony library file version: 2.13.0.0
- Current TFP Harmony configuration: skip with anti-cheat
- Inspection method: Mono.Cecil metadata and IL inspection; game assembly code
  was not loaded into or executed by the game

## Runtime Lifecycle Evidence

The preferred hook is `ModEvents.PlayerSpawnedInWorld` with
`SPlayerSpawnedInWorldData`. The current data surface includes `ClientInfo`,
`IsLocalPlayer`, `EntityId`, `RespawnType`, and `Position`.

Current lifecycle classification:

| Situation | Respawn type | Eligible |
| --- | --- | --- |
| New local character | `NewGame` | Yes |
| Existing local save | `LoadedGame` | No |
| New remote character | `EnterMultiplayer` | Yes |
| Remote reconnect | `JoinMultiplayer` | No |
| Death or normal respawn | `Died` | No |
| Teleport-generated event | `Teleport` | No |
| Unclassified state | `Unknown` | No |

The event resolves `EntityId` to an `EntityPlayer`. Listen-server behavior can
produce duplicate client/server observations, so the implementation requires
server-authority gating plus an idempotent per-player relocation transaction.

## Placement Evidence

- `GameManager.GetSpawnPointList()` exposes the native list.
- `SpawnPointList.GetRandomSpawnPosition(...)` permits selection without
  mutating the list or editing XML.
- Random can select broadly from authored spawnpoints.
- Authored spawnpoints are not guaranteed to be globally uniform.
- A future expanded Random search can operate outside the list in principle,
  but its chunk behavior and server cost require dynamic proof. It is not a
  third policy mode.

Relevant world APIs cover bounds, terrain height, terrain variation, support,
headroom, water, POIs, claims, bedrolls, player proximity, radiation, biome,
and loaded chunks. `World.CanPlayersSpawnAtPos` covers only part of the safety
contract; it must not be treated as complete validation by itself.

`World.GetRandomSpawnPositionMinMaxToPosition(...)` provides useful bounded
candidate checks, but its loaded-chunk dependency may reject distant initial
spawn candidates. No forced or blocking chunk-load strategy is approved yet.

## Arrival Protection Evidence

`EntityBuffs.AddBuff`, `RemoveBuff`, and `HasBuff` provide a candidate route for
a project-owned hidden, nonstacking, intrinsically time-limited protection
effect. This avoids Developer Mode and the game's god-mode behavior.

Ground state is observable. The proposed policy is to remove protection after
stable landing, with an absolute 15-second deadline. If the player remains
airborne at the deadline, the runtime must perform a safe emergency placement
before removing protection; it must not simply expose a falling player.

Exact damage coverage, network synchronization, disconnect behavior, and
expiry behavior remain dynamic-test requirements.

## One-Time State Evidence

Namespaced custom CVars are serialized through normal player data. A project-
owned marker can therefore prevent reconnect or duplicate-event rerolls without
an external Steam-ID database.

The marker must contain only bounded state values, not private identity. Crash
timing between claim, relocation, completion, and normal save remains unproven
and requires a documented transaction design.

## Harmony, EAC, and Client Boundary

- No initial Harmony patch is required for the native event route.
- Existing `0_TFP_Harmony` files must remain unmodified.
- Current anti-cheat handling skips or rejects ordinary custom-code DLLs unless
  a separate compatibility condition is met.
- The safe initial code-mod lane is no-EAC and fail closed.
- Native server teleport uses `NetPackageTeleportPlayer`, suggesting clean
  clients may not need this project's DLL.
- Protection/config synchronization must be proven with a genuinely clean
  client before making a clean-client claim.

## Local World and Save Evidence

The inspected machine contained:

- 19 generated worlds with `map_info.xml` and `spawnpoints.xml`;
- 69 save instances across 18 world folders;
- six built-in spawnpoint files and 19 generated-world spawnpoint files; and
- no per-save `spawnpoints.xml` files.

Several recent save instances shared a world while using different game names.
Other game names appeared under more than one world. The launcher policy key
must therefore include at least canonical storage root, world name, and game
name. A world GUID may be used as an additional mismatch check.

Player identity fields exist in `players.xml`. The launcher must not parse,
store, or log them for policy identity.

## Existing Host and Logging Evidence

The current Bit Wrecked module host is a suitable architectural base, but its
0.0.1 contract is deliberately read-only. It has a literal three-module
allowlist, `render` and `validate_read_only` capabilities, one read-only action,
and a `none in this build` write boundary.

Its acceptance harness completed with 175 passed and 0 failed. The harness
confirmed allowlisting, rogue-module rejection, no-write validation, path
rejection, asynchronous-result correlation, bounded visible logging, explicit
persistent-log consent, protected-tree hashes, accessibility automation, and
launcher smoke behavior.

Historical Random Start - Alpha 6 Method requires a new narrowly allowlisted capability contract
for local policy save and explicit launch. The existing contract must not be
broadly relaxed.

## Proposed Write Boundary

Launcher-owned writes are proposed only under the Downloads package:

- `State/world-policy-index.json`
- `State/saved-settings-records.jsonl`
- a same-directory temporary file used for atomic replacement
- an optional user-selected persistent activity log after explicit consent

The launcher must not write to saves. The runtime's only proposed persistent
gameplay state is its namespaced one-time marker through normal game player
serialization. The runtime creates no private activity file and performs no
shell or network operation.

## Risks and Required Gates

Compatibility risks include build API changes, old or modded maps, EAC, and
clean-client synchronization.

Security risks include malformed policy data, out-of-range settings, path
traversal, reparse points, network/device paths, process-state races, forged
coordinates, untrusted packages, and identity leakage.

Performance risks include distant chunk generation, candidate loops,
simultaneous new joins, terrain/POI queries, and unbounded logging.

Rollback risks include the ordinary persistence of an already-relocated player
position, interrupted state transitions, and stale protection. Disabling the
helper restores future vanilla behavior but does not automatically reverse a
completed relocation.

## Open Product Decision

Awaiting owner answer:

> Should Random fail closed to Standard unless the game was started
> through the Bit Wrecked launcher?

The answer affects the launcher-to-runtime policy transport. It must not be
inferred silently.

## Exact Next Action

Create the Phase 0A state machine, configuration allowlist, numeric bounds,
write-capability contract, sanitized log schema, resource limits, and negative-
test matrix. Keep that work documentation-only and staged under this solution.

The first later executable proof should be a no-teleport, sanitized event probe
tested against a disposable world and save backup after explicit authorization.

## No-Change Attestation

Phase 0 changed no gameplay payload, live game file, Harmony file, DLL, XML,
world, save, or live `Mods` content. It did not modify the Wasteland project and
did not commit, push, publish, upload, or distribute anything.
