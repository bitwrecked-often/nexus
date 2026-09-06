# Phase 1A AddCustomVar Probe — External Build Record

Date: 2026-08-20  
Decision: External deterministic build/static review PASS; stage/live/save/run NO-GO

The owner authorized recompilation of exact source aggregate
`8A8CCD76060D5540214A38BDBE21FE1ADD26961B9BACD5033E3CA5F9E22D2E8F`.
Two new clean external directories were used. All compiler and seven explicit
game/runtime reference hashes matched the pinned inventory before compilation.

| Build | Exit | Output | Files | Bytes | SHA-256 |
| --- | ---: | ---: | ---: | ---: | --- |
| `build-05-addcustomvar` | 0 | 0 lines | 1 DLL | 8,704 | `C3505D1838B8E2A7114485D0D08C023D3CFE6278FDDBD71D81FCB7D628A3B393` |
| `build-06-addcustomvar` | 0 | 0 lines | 1 DLL | 8,704 | `C3505D1838B8E2A7114485D0D08C023D3CFE6278FDDBD71D81FCB7D628A3B393` |

The outputs are byte-identical. Assembly name is
`BitWrecked.HistoricalRandomStart.Phase1A.MarkerProbe`, version `0.0.0.0`, MVID
`0c9e370d-2d40-4651-9f67-d3ccb1808738`.

Cecil inspection found 80 method calls, 44 distinct. The compiled artifact has
exactly one direct `EntityBuffs.AddCustomVar` call, zero direct
`EntityBuffs.SetCustomVarNetwork` calls, and zero spawnpoint-selection,
position, teleport, respawn, marker-removal, file-write/delete, process, or
Harmony calls.

Microsoft Defender scanned both DLLs and reported no threats with exit `0`.
The live owned DLL remains the prior SHA-256
`3D7395FEF5D98EB8B456442F5BA2037443B981E760E090031A223277D3E143D5`.
The game remained closed and the current disposable save remained in place.

Creating a new external payload, replacing the live DLL, preserving/resetting
the target, and executing a new test are separate authorization gates.
