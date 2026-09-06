# Phase 1A Containing-Chunk Relocation — Payload Staging Record

Date: 2026-08-20  
Decision: External payload PASS; live replacement/run NO-GO

The owner authorized a fresh external payload at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\payload-0.0.1-dev-relocation-containing-chunk`

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe.dll` | 15,360 | `91C0AE24599088C64485C29851847CD5C703CF4C0ADF7A1D72C3D9C371417CCD` |
| `ModInfo.xml` | 407 | `CAD31EA6025B7F520933A28E776E03996CFD4AA4E3F73F266DBC8AFE63D40884` |

The aggregate SHA-256 of ordinal `name|bytes|sha256` lines joined by LF is:

`3A0315F27F0450D827D9E07E34603FEF0830CFA305E3F75437ACCEE6CEB119FE`

The DLL exactly matches both reviewed deterministic builds. Metadata validates
the exact relocation DEV internal name and `SkipWithAntiCheat=true`. The payload
contains exactly two files and passed a Microsoft Defender scan with exit code
`0`.

The game remained closed. The live DLL remains unchanged at
`9FBF9CDEBAB108633E916D338F6D9571D282533A4E6E3FBC51AB529EB1825FAB`,
and the failed Reserved target remains present and untouched. Nothing was
installed, reset, or executed.

Next gate: authorize containing-chunk Phase 1A live payload replacement.
