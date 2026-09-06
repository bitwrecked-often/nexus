# Runtime Development and Station Migration Manifest

Status: ACTIVE EVERGREEN AUTHORITY  
Created: 2026-08-27  
Applies to: `BitWrecked.HistoricalRandomStart` and
`BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe`

## Purpose

This document is the durable runtime-development handoff between development
stations. Read it before interpreting a load failure, refreshing a game-build
pin, rebuilding a runtime DLL, copying the development lane, or running a live
game test.

The workspace is intentionally hybrid: development records can live beneath a
game installation. Folder authority still applies. Project files are not live
game files, and the directory looking like a repository does not make it a Git
branch or authorize changes outside this active lane.

Historical, frozen, and Nexus-review records remain immutable. Add a dated
checkpoint here or a dated evidence record for each later game build; do not
rewrite an old fingerprint to make it appear current.

## Mandatory Order of Operations

For a game update or a move to another development station:

1. fingerprint the station, installed game, compiler, dependencies, and source;
2. perform a read-only compatibility/drift audit;
3. classify the result as pin-only compatible, minimally adaptable, or
   incompatible;
4. test the current mod separately, without first changing it;
5. reconcile observed behavior with the documentation;
6. only after explicit owner authorization, make the smallest source/pin change;
7. rebuild and rerun the full non-live test set;
8. run a separately approved live exact-name New Game test; and
9. harden and verify the transport copy only after the tested behavior is known.

A compatibility manifest is a drift check, not permission to rebuild, deploy,
launch the game, alter saves, or reconstruct the mod.

## Known-Good Live Operator Sequence

The naming-before-creation dependency is part of the runtime contract:

1. Before the new game exists, open the launcher/manager.
2. Enter or arm the exact new game name.
3. Select the spawn policy for that exact target.
4. Create the game in 7 Days to Die using exactly the same name.
5. Let the runtime helper observe the matching New Game/new-player lifecycle.
6. The Random-start path becomes eligible only after all gates match.
7. The player is relocated once; verified placement and no repeat are the proof.

If a later observed sequence differs, preserve the observation as evidence and
reconcile this section deliberately. Tested behavior outranks inferred intent.

## Required Station Fingerprint

Record these values on every development station and after every game update:

| Field | Required value |
| --- | --- |
| Record date and non-sensitive station alias | Date and owner-approved alias |
| Game display version and distribution branch | Exact observed values |
| Steam build ID, when applicable | Numeric build ID |
| `Assembly-CSharp.dll` | Size, SHA-256, and MVID |
| `UnityEngine.CoreModule.dll` | Size, SHA-256, and MVID or reason unavailable |
| `LogLibrary.dll` | Size, SHA-256, and MVID or reason unavailable |
| Compiler and compiler host | Version and SHA-256 |
| Runtime host | OS architecture and PowerShell versions used |
| Source identity | Source-manifest aggregate and exact source list |
| Generated artifact identity | DLL/PDB hashes, or `not built` |

Do not record usernames, account/owner IDs, tokens, keys, save identities, or
unnecessary machine-specific paths. The private target record stays private and
must not travel in a public/Nexus package.

## Compatibility Audit Method

An MVID difference is a reason to audit, not evidence of incompatibility by
itself. A pin refresh is allowed only after all of the following are true:

- every direct game/runtime type, method, event, property, and field used by
  both runtime source sets has been enumerated;
- compiled member references resolve against the target installed assemblies;
- both source sets compile semantically against those assemblies with zero
  errors and zero warnings;
- critical lifecycle and relocation behavior has been checked in current IL or
  equally direct evidence; and
- the result has been classified and recorded.

The minimum API checklist is:

- `IModApi.InitMod(Mod)`;
- `ModEvents.PlayerSpawnedInWorld`, `ModEvents.GameUpdate`, and handler
  registration;
- spawn event data and `RespawnType` values;
- `GamePrefs`, `GameManager`, and `ConnectionManager` authority APIs;
- native `GetRandomSpawnPosition(World, Nullable<Vector3>, int, int)`;
- `SpawnPosition` fields/methods;
- world bounds, `worldToBlockPos`, `GetChunkFromWorldPos`, and
  `CanPlayersSpawnAtPos`;
- `Entity.SetPosition`, `Entity.GetPosition`, `EntityPlayer.ChunkObserver`, and
  `ChunkObserver.SetPosition`;
- marker APIs `EntityBuffs.HasCustomVar`, `GetCustomVar`, and `AddCustomVar`;
- player semantic stats, progression, inventory, quests, buffs, and item state;
- `Log.Out`; and
- the final native placement ordering in `PlayerMoveController.updateRespawn`.

Also confirm that native spawn selection still uses game RNG/list selection,
spawn safety still checks the containing chunk/support/water/collision/headroom,
the marker survives serialization/readback, and `GameUpdate` still reaches the
runtime scheduler.

## Compatibility Checkpoint — 2026-08-27

Observed installed-game transition:

| Property | Prior known-good build | Current installed build |
| --- | --- | --- |
| Steam build ID | `24436778` | `24911213` |
| `Assembly-CSharp.dll` MVID | `acb580d9-e1ab-497d-a8dc-47e47c1fc300` | `326ffd03-1d6d-4efb-a7dc-79201537b1c3` |
| `Assembly-CSharp.dll` SHA-256 | `B13862E30D8B28F42B83FE6A36BF074D155A6C43164E7B0797A6E4F77BD7DEA3` | `4CA8D6490F34F134A952B1A3547131A8C536610EC28BEDE0D35CBFE93F09715D` |
| `Assembly-CSharp.dll` size | `11,805,696` bytes | `11,837,440` bytes |

Unchanged dependency hashes observed:

- `UnityEngine.CoreModule.dll`:
  `68D360251A7AEA19CBA74626D5E9D55E801C51DDA1F4B153B5BA4825C19C9E35`
- `LogLibrary.dll`:
  `A9CC17C698D5586CCE168080ABFD37D61C1F3F2EA8C73487B360164ADC2FB71B`

Observed runtime behavior before any change:

- `HistoricalRandomStart.dll` loaded;
- the Phase 1A relocation probe loaded;
- the main runtime stopped with `BUILD_MISMATCH`;
- the probe stopped with `RELOC_BUILD_MISMATCH`;
- New Game lifecycle observation still worked; and
- no relocation occurred because both compatibility guards failed closed.

Audit result: **not pin-only compatible**. One source-level API shape changed in
both runtime source sets. The prior compiled dependency was the field
`System.Byte ItemValue::Activated`; the current game exposes the property
`System.Boolean ItemValue::get_Activated()`, backed by flags.

Affected source locations:

- `src/runtime/BitWrecked.HistoricalRandomStart/SemanticSnapshot.cs`, current
  line 58;
- `src/runtime/BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe/SemanticSnapshot.cs`,
  current line 58.

All other enumerated direct member references resolved. A non-persistent audit
substitution equivalent to `value.Activated ? 1 : 0` produced zero compiler
errors and zero warnings for both source sets. It was an in-memory audit only;
no project file was changed.

Critical behavior remained structurally compatible. In particular, native
spawn selection and safety rails remained, marker persistence remained, and
`PlayerMoveController.updateRespawn` still calls
`GameManager.PlayerSpawnedInWorld` before the later final native
`Entity.SetPosition`. Its relevant IL offset moved from historical `0x0B71` to
current `0x0B87`; the essential ordering did not change.

Current classification: a narrow semantic adaptation plus MVID refresh appears
sufficient, subject to authorization and the tests below. No refresh or source
change was made by this audit.

## Files in a Future Authorized Refresh

If the owner authorizes the compatibility refresh, limit the initial change to:

- the two `SemanticSnapshot.cs` files named above;
- `src/runtime/BitWrecked.HistoricalRandomStart/CompatibilityGuard.cs`;
- `src/runtime/BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe/CompatibilityGuard.cs`;
- `src/runtime/Build-AlphaCoreRelease.ps1`, currently containing the release
  build pin; and
- both affected `source_manifest.json` files, regenerated from the exact source
  contents and ordering.

Update private target/preflight fixtures only where their current-build role is
explicit. Do not mass-replace the old MVID: DevProbe, MarkerProbe, historical
evidence, and dependency inventories are separate historical scopes. Preserve
the prior checkpoint and add a new dated record.

## Required Tests After an Authorized Refresh

1. Compile both runtime source sets against the exact current references with
   zero errors and zero warnings.
2. Resolve every compiled game/runtime member reference with zero unresolved
   members.
3. Perform the deterministic double-build/hash comparison.
4. Run `src/runtime/BitWrecked.HistoricalRandomStart/Verify-ReleaseSource.ps1`.
5. Run `tests/Invoke-Phase1ARelocationSourceStaticTests.ps1`.
6. Run `tests/Invoke-Phase1APureContractTests.ps1`.
7. Run `tests/Invoke-Phase1ASemanticHarnessPureTests.ps1`.
8. Refresh only the authorized current-build fixtures, then run
   `tests/Invoke-Phase0APureContractTests.ps1`.
9. Run the Alpha Core contract, deployment, and management suites routed by the
   current start document.
10. At a separate live-test checkpoint, perform the exact-name New Game flow
    and prove one relocation, verified placement, marker persistence, and no
    repeat relocation.

## Transport Gate

Before moving this lane to another station, verify that the transport contains
the intended source, scripts, documents, manifests, and approved evidence. It
must not contain development keys, credentials, private target records, account
identifiers, saves, worlds, installed game assemblies, or live manager state.

On the destination station, do not assume compatibility because the directory
is bit-for-bit identical. Re-fingerprint the installed game and toolchain,
compare the source-manifest aggregate, repeat the read-only compatibility
check, and record the result before build or live testing.

## Stop Conditions

Stop and return to the owner if any direct member is unresolved, compilation
warns or fails, critical lifecycle/placement ordering changed, the exact target
build cannot be proven, source identity differs unexpectedly, private material
would cross the transport boundary, or a requested action would mutate the live
game without separate authorization.
