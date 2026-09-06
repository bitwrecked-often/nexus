# Historical Random Start - Alpha 6 Method — Phase 0A Installed-Build and API Fingerprint

Date: 2026-08-14  
Evidence class: Read-only local inspection  
Installed target: Windows public build  
Result: Static API evidence is sufficient to design the Phase 1 observation
probe. It is not runtime evidence and does not authorize a DLL build or load.

## Inspection boundary

The inspection read the installed executable, managed assemblies, TFP Harmony
metadata, Steam app manifest, and one sanitized version line from the normal
game log. It did not start the game, compile code, copy a payload, enumerate
player identities, or modify `Mods`, saves, worlds, XML, Harmony, registry,
services, or game files.

The game process was not running during the inspection. Private app-manifest
owner data and private log paths were deliberately excluded from this record.

## Pinned installed target

| Item | Observed value |
| --- | --- |
| 7 Days to Die display version | `V 3.1.0 (b14)` |
| Compatibility version | `V 3.1.0` |
| Player build | `WindowsPlayer 64 Bit` |
| Unity player version | `2022.3.62f2` |
| Steam build ID | `24436778` |
| Steam branch | `public` |
| `Assembly-CSharp.dll` MVID | `acb580d9-e1ab-497d-a8dc-47e47c1fc300` |

### Primary file hashes

| File | Size (bytes) | SHA-256 |
| --- | ---: | --- |
| `Assembly-CSharp.dll` | 11,805,696 | `B13862E30D8B28F42B83FE6A36BF074D155A6C43164E7B0797A6E4F77BD7DEA3` |
| `UnityEngine.CoreModule.dll` | 1,393,576 | `68D360251A7AEA19CBA74626D5E9D55E801C51DDA1F4B153B5BA4825C19C9E35` |
| `UnityEngine.dll` | 126,896 | `F03B83C7F79969406CF6FCB1D20BC99C15AD123BD0F7A9856ADEFF0766041649` |
| `LogLibrary.dll` | 10,752 | `A9CC17C698D5586CCE168080ABFD37D61C1F3F2EA8C73487B360164ADC2FB71B` |
| `7DaysToDie.exe` | 666,624 | `9062C57F7C742DD175D78934941D2F30BEEDDD70B01DD8CCC95EC73F22E21AB3` |

## Loader and Harmony fingerprint

The installed TFP Harmony wrapper declares version `1.1.0.4` and
`SkipWithAntiCheat=true`. The future DEV probe will use the game's `IModApi`
loader contract and ordinary mod event API. It does not need or authorize a
Harmony patch.

| File | Size (bytes) | SHA-256 | Planned role |
| --- | ---: | --- | --- |
| `TfpHarmony.dll` | 7,168 | `71D78B990A29ECC0E0C575227E7933E2BFEDCA802108D8A30E8D9EB91CEC1AC8` | Loader-environment fingerprint only |
| `0Harmony.dll` | 290,304 | `C349E1A3FD13FA5A9FACC9805A5E160161B14489F46F6BDD38202B8E124F78DF` | Environment fingerprint only; no patch planned |
| `Mono.Cecil.dll` | 360,448 | `71C8B01208AB37A5164F5BACD69054899DB9FC00F2DA87DBD07DC1EE40FC06A8` | Read-only inspection tool already supplied by the game; not a runtime dependency |

No listed game, Unity, Harmony, or inspection binary may be bundled in a DEV or
release payload.

## Compiler and managed-profile fingerprint

No .NET SDK is installed on this machine and `MSBuild` is not on `PATH`. The
available pinned compiler is the 64-bit .NET Framework C# compiler:

| Item | Value |
| --- | --- |
| Compiler | `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe` |
| File version | `4.8.9221.0` |
| SHA-256 | `46809206887326D2D24DB1EFF1F3064DE972C3451ABE766B49111450A5E08E00` |
| Planned language level | C# `7.3` |
| Planned output architecture | AnyCPU managed IL; test process is Windows x64 |

`Assembly-CSharp.dll` has no `TargetFrameworkAttribute`. Its observed assembly
references include `mscorlib 4.0.0.0` and `netstandard 2.1.0.0`. The build must
therefore compile against the staged game's own managed profile with
`/nostdlib+`; it must not silently substitute a .NET SDK reference pack.

| Reference | File version | SHA-256 |
| --- | --- | --- |
| `mscorlib.dll` | `4.6.57.0` | `98C9B62133DB5DD33B22BC6AAB6F28E4F04F5B5BE6559B28BA5C2738241434D0` |
| `netstandard.dll` | `2.1.0.0` | `6AE62E082DC494A2433984177F60CA4DB5FAE69B1F360A8B33754172B310B8C5` |
| `System.dll` | `4.6.57.0` | `ACE2DD6A7D534B581BF4A9D316E743D64508CA2135DB73DBFF0DDB9365FC454E` |
| `System.Core.dll` | `4.6.57.0` | `F1B33EB1AE8522EDCF9BA4C2B85F532D4BAB68BFA2A51527264BB61619BED4EA` |

## Spawn-event API evidence

The installed build exposes:

- `IModApi.InitMod(Mod)`;
- `ModEvents.PlayerSpawnedInWorld` as
  `ModEvent<SPlayerSpawnedInWorldData>`;
- a handler delegate with the shape `void Handler(ref
  SPlayerSpawnedInWorldData data)`; and
- `RegisterHandler(...)` / `UnregisterHandler(...)` on the mod event.

`SPlayerSpawnedInWorldData` contains these public fields:

- `ClientInfo ClientInfo`;
- `bool IsLocalPlayer`;
- `int EntityId`;
- `RespawnType RespawnType`; and
- `Vector3i Position`.

The exact `RespawnType` values are:

| Value | Name | Core eligibility design |
| ---: | --- | --- |
| 0 | `NewGame` | Eligible only after every other gate passes |
| 1 | `LoadedGame` | Reject |
| 2 | `Died` | Reject |
| 3 | `Teleport` | Reject |
| 4 | `EnterMultiplayer` | Potential new-character event; eligible only after staged proof |
| 5 | `JoinMultiplayer` | Reject |
| 6 | `Unknown` | Reject |

The event is invoked before `GameManager.PlayerSpawnedInWorld(...)` performs its
own `ConnectionManager.Instance.IsServer` branch. Therefore the same mod event
can be observed in client and server contexts. A future handler must check
`ConnectionManager.Instance.IsServer` before any server-authoritative logic.
`GameManager.World.GetEntity(int)` provides the entity-resolution route.

## Native authored-spawnpoint evidence

The installed build exposes:

- `GameManager.GetSpawnPointList()`;
- `SpawnPointList.GetRandomSpawnPosition(World, Nullable<Vector3>, int, int)`;
- `SpawnPosition.position`, `.heading`, and `.bInvalid`;
- `SpawnPosition.IsUndef()`; and
- `SpawnPosition.ToBlockPos()`.

`GameManager.GetSpawnPointList()` obtains the current list from the active
world's chunk provider. With no reference position,
`GetRandomSpawnPosition(...)`:

1. returns `SpawnPosition.Undef` when the list is empty;
2. obtains `WorldBase.GetGameRandom()` from the active world; and
3. chooses one list index with `GameRandom.RandomRange(count)`.

This is direct installed-build evidence for a bounded, native authored-point
route. It does not prove that every world has a non-empty list or that two runs
will produce different points. Those remain runtime observations.

## Ground and headroom validation evidence

The current world API exposes:

- `World.IsPositionInBounds(Vector3)`;
- `World.IsChunkAreaLoaded(Vector3)`;
- `World.CanPlayersSpawnAtPos(Vector3, bool)`;
- `World.GetHeight(int, int)`; and
- `World.GetTerrainHeight(int, int)`.

The installed implementation of `CanPlayersSpawnAtPos(position, false)`
rejects a missing chunk, an invalid vertical range, a support block that is not
spawnable, water at the candidate, collision in the player block, and solid
collision in the block above. It is the preferred current-build native check
for directly grounded support and two-block occupancy. Phase 1A must still
verify the observed final position after the authoritative placement call.

## Authority and placement API evidence

The installed build exposes:

- `ConnectionManager.Instance.IsServer` and `.IsClient`;
- `GameManager.IsDedicatedServer`;
- `Entity.SetPosition(Vector3, bool)`; and
- `EntityPlayer.Teleport(Vector3, float)`.

`EntityPlayer.Teleport(...)` calls `SetPosition(...)` and then
`Respawn(RespawnType.Teleport)`. That means it can cause another spawn lifecycle
callback. It is not a console command, but it is not approved for Phase 1 and
must not be considered for Phase 1A until duplicate suppression and progression
effects are tested. No placement API was called during this inspection.

## Exactly-once marker API decision

The selected installed-build marker candidate for a later Phase 1A proof is a
namespaced nonzero player CVar stored on the game-owned `EntityBuffs` record:

`bitwrecked_hrs_state_v1`

Proposed allowlisted values are:

- `1.0` — `Reserved`;
- `2.0` — `Completed`; and
- `3.0` — `Invalid`.

Absence is tested with `EntityBuffs.HasCustomVar(...)`; the implementation must
never create or remove a raw platform-identity record.

Static installed-build evidence shows:

- `EntityAlive.SetCVar(name, value)` delegates to
  `EntityBuffs.SetCustomVar(...)` with synchronization enabled;
- `EntityBuffs.Write(...)` serializes nonzero CVar names and float values while
  excluding names that begin with `.`; and
- `EntityBuffs.Read(...)` reads each name/value pair and restores it through
  `SetCustomVar(...)`.

The proposed key is nonzero and does not begin with `.`. This establishes a
credible game-owned persistence route without player identity. It does not yet
prove save timing, crash-window durability, reload survival, reconnect survival,
or server/client synchronization. The observation-only Phase 1 probe will not
write this marker. Phase 1A remains fail-closed until those runtime properties
are directly proven in a disposable target.

## Static conclusion

Static design GO:

- exact build guard via `Assembly-CSharp` MVID;
- exact target guard via `GamePrefs.GameWorld`, `GamePrefs.GameName`,
  `World.Guid`, execution type, and approved canonical roots;
- server-authority classification;
- exact lifecycle classification;
- entity resolution and bounded in-memory duplicate observation;
- one native authored-point selection route; and
- a current-build grounded/headroom validation route.

Runtime and build NO-GO remains in force until the pre-build packet has an
owner-approved disposable staged target, recoverable backup, source review,
scanner plan, and explicit build/copy authorization. Static inspection cannot
prove event count, gameplay neutrality, save durability, EAC behavior,
clean-client behavior, listen/dedicated behavior, or rollback.

