# Phase 1A Native-Aligned Relocation — External Build Record

Date: 2026-08-20  
Decision: Deterministic external build/static review PASS; stage/live/run NO-GO

The owner authorized recompilation of source aggregate
`222E35A7AD8DB8118BD3B4A0C673D4F458C3954275DFA8640BBAA340EDB51D65`.
The pinned Roslyn compiler and all seven explicit read-only game/runtime
references matched their recorded SHA-256 values. The game/server were closed.

| Build | Exit | Files | Bytes | SHA-256 |
| --- | ---: | ---: | ---: | --- |
| `build-13-relocation-native-aligned` | 0 | 1 | 14,336 | `91665756F96640D08F31F744B3C12E09236A189BD91EF4F4E972D46416AB6290` |
| `build-14-relocation-native-aligned` | 0 | 1 | 14,336 | `91665756F96640D08F31F744B3C12E09236A189BD91EF4F4E972D46416AB6290` |

The DLLs are byte-identical. Assembly name is
`BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe`, version `0.0.0.0`,
MVID `9e50255c-7321-48da-b38e-eb23f408f988`.

Mono.Cecil inspection found 217 calls and 102 distinct call signatures. Exact
reviewed counts are:

- `SemanticSnapshot.Capture`: 2;
- `EntityBuffs.AddCustomVar`: 2;
- `SpawnPointList.GetRandomSpawnPosition`: 1;
- `Entity.SetPosition`: 1;
- `World.IsChunkAreaLoaded`: 1;
- `World.CanPlayersSpawnAtPos`: 1;
- `Vector3.Distance`: 1; and
- direct `EntityBuffs.SetCustomVarNetwork`: 0.

The two semantic result strings are present. The obsolete pre-placement
`RELOC_CHUNK_NOT_READY` and `RELOC_CANDIDATE_UNSAFE` strings are absent. There
are zero reviewed Harmony, file/directory mutation, process-launch, teleport,
respawn, marker-removal, or explicit chunk-request calls.

Microsoft Defender scanned both DLLs individually and found no threats with exit
code `0`.

The live DLL remains the older superseded
`CC70A8B04DD54A14E0CBBF59C7EA1B6F7969C4F747DBF47DC735CB870EF013BB`
artifact. No payload was staged, no live file or save changed, and nothing was
executed. Restaging and live replacement require separate authorization.
