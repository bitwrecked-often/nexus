# Phase 1A Unchecked-Semantic Relocation — External Build Record

Date: 2026-08-20  
Decision: Deterministic build/opcode/static review PASS; stage/live/run NO-GO

The owner authorized recompilation of source aggregate
`506C47B830026A777D230AF42E647E16B9994D7921E9DACEC4061C03EEABABD4`.
The pinned Roslyn compiler and seven explicit game/runtime references matched
their recorded hashes. The game/server were closed.

| Build | Exit | Files | Bytes | SHA-256 |
| --- | ---: | ---: | ---: | --- |
| `build-15-relocation-unchecked-semantic` | 0 | 1 | 14,336 | `1F68045943DACF40DA579D3F62C3D5BD48F2D20F3F31521203F04D93EADF5F54` |
| `build-16-relocation-unchecked-semantic` | 0 | 1 | 14,336 | `1F68045943DACF40DA579D3F62C3D5BD48F2D20F3F31521203F04D93EADF5F54` |

The DLLs are byte-identical. Assembly name is
`BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe`, version `0.0.0.0`,
MVID `d29d7b9d-b873-4d98-b4d5-7dddd8d4a603`.

Mono.Cecil inspected all four compiled FNV multiplication sites across the
string, float, and integer digest overloads:

- ordinary wrapping `mul`: 4; and
- `mul.ovf` / `mul.ovf.un`: 0.

Reviewed relocation counts remain:

- semantic captures: 2;
- `AddCustomVar`: 2;
- native random selection: 1;
- `SetPosition`: 1;
- post-placement chunk check: 1;
- post-placement safety check: 1;
- distance verification: 1; and
- direct `SetCustomVarNetwork`: 0.

There are zero reviewed Harmony, file/directory mutation, process-launch,
teleport, respawn, marker-removal, or explicit chunk-request calls. Microsoft
Defender scanned both DLLs and found no threats with exit code `0`.

The live DLL remains the older superseded
`91665756F96640D08F31F744B3C12E09236A189BD91EF4F4E972D46416AB6290`
artifact, and the failed Reserved target remains present. Neither was changed.
