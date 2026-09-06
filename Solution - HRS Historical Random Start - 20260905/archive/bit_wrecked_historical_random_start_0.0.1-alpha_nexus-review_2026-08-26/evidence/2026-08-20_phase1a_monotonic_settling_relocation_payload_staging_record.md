# Phase 1A Monotonic-Settling Relocation — Payload Staging Record

Date: 2026-08-20  
Decision: External payload PASS; live replacement/run NO-GO

The owner authorized a fresh external payload at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\payload-0.0.1-dev-relocation-monotonic-settling`

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe.dll` | 14,848 | `DE273E9216209CA188FA179614D7F4FC19037DB78D92BFB15C6BB985E05F61A6` |
| `ModInfo.xml` | 407 | `CAD31EA6025B7F520933A28E776E03996CFD4AA4E3F73F266DBC8AFE63D40884` |

The aggregate SHA-256 of ordinal `name|bytes|sha256` lines joined by LF is:

`2932C8FDF5C52C171A3177FED0040F91BD2D25D7D3C134C38EF78DD18C2FC796`

The DLL matches both deterministic reviewed builds. Metadata retains the exact
relocation DEV name and `SkipWithAntiCheat=true`. Microsoft Defender scanned the
payload and found no threats with exit code `0`.

The live DLL remains the older superseded
`1F68045943DACF40DA579D3F62C3D5BD48F2D20F3F31521203F04D93EADF5F54`
artifact, and the verification-failed Reserved target remains present. Neither
was changed.
