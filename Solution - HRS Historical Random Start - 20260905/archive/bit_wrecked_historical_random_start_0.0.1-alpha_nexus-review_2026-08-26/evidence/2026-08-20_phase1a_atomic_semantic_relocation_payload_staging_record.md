# Phase 1A Atomic-Semantic Relocation — Payload Staging Record

Date: 2026-08-20  
Decision: External payload PASS; live replacement/run NO-GO

The owner authorized a fresh external payload at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\payload-0.0.1-dev-relocation-atomic-semantic`

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe.dll` | 15,360 | `632208686E0C5A2156DC27B32FD3579F80A0AC9E60171B262E1147AEEE8EFCE2` |
| `ModInfo.xml` | 407 | `CAD31EA6025B7F520933A28E776E03996CFD4AA4E3F73F266DBC8AFE63D40884` |

The aggregate SHA-256 of ordinal `name|bytes|sha256` lines joined by LF is:

`4F5F5189E3F89CC259C39233FB5762529BE9CB178C3CE9508E94056E4641EAE6`

The DLL exactly matches both reviewed deterministic builds. Metadata validates
the exact relocation DEV internal name and `SkipWithAntiCheat=true`. The payload
contains exactly two files and passed Microsoft Defender with exit code `0`.

The game remained closed. The live DLL remains unchanged at
`3BB52A412C6B156D849FEC1D2843BF9CD32A0ED0F44BC0CB39E152E2CD37D611`,
and the Reserved disposable target remains present with 68 files and
19,377,481 bytes. Nothing was installed, reset, or executed.

Next gate: **authorize atomic-semantic Phase 1A live payload replacement**.
