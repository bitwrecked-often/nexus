# Phase 1A Reload-Observation Amendment — External Build Record

Date: 2026-08-20  
Decision: External deterministic rebuild/static review PASS; stage/replace/run NO-GO

The owner authorized recompilation of amended source aggregate
`5D23A4791B9B188C661EE1028313F07B3ED375472CE05E64BC664E3F050658C8`.
Two new clean external directories were used; the prior builds, payload, and
installed DLL were not overwritten.

The pinned `dotnet.exe`, Roslyn `csc.dll`, and all seven explicit
game/runtime-provided reference hashes matched before compilation. The same
no-config, no-standard-library, no-restore, explicit-reference deterministic
compiler profile was used.

| Build | Exit | Output | Files | Bytes | SHA-256 |
| --- | ---: | ---: | ---: | ---: | --- |
| `build-03-amended` | 0 | 0 lines | 1 DLL | 8,704 | `3D7395FEF5D98EB8B456442F5BA2037443B981E760E090031A223277D3E143D5` |
| `build-04-amended` | 0 | 0 lines | 1 DLL | 8,704 | `3D7395FEF5D98EB8B456442F5BA2037443B981E760E090031A223277D3E143D5` |

The DLLs are byte-identical. Assembly name is
`BitWrecked.HistoricalRandomStart.Phase1A.MarkerProbe`, version `0.0.0.0`, MVID
`39c7ae99-ec4e-41a8-bf60-09412536bc81`.

Cecil inspection found 80 method calls, 44 distinct. There is exactly one
compiled `EntityBuffs.SetCustomVarNetwork` call site, all five expected
reload/lifecycle reason strings are present, and there are zero references to
spawnpoint selection, `SetPosition`, teleport, respawn, marker removal, file
writes/deletion, process launch, or Harmony.

Microsoft Defender scanned both amended DLLs and reported no threats with exit
`0`. The installed DLL remains the prior SHA-256
`FCC012FC8841FC1D7285C108D15EDDC4DD62BED5500B0C3F387F918AFE4F37E3`.
The game was not launched and the Phase 1A target save remains absent.

Creating a new amended external payload and replacing the exact owned live DLL
require later explicit authorization. Execution remains a separate gate.
