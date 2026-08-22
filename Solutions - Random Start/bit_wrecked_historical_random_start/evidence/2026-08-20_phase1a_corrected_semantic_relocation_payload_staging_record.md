# Phase 1A Corrected Semantic Relocation — Payload Staging Record

Date: 2026-08-20  
Decision: External payload PASS; installation/execution NO-GO

The owner authorized a fresh external two-file payload at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\payload-0.0.1-dev-relocation-semantic-corrected`

The payload contains exactly:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe.dll` | 14,848 | `CC70A8B04DD54A14E0CBBF59C7EA1B6F7969C4F747DBF47DC735CB870EF013BB` |
| `ModInfo.xml` | 407 | `CAD31EA6025B7F520933A28E776E03996CFD4AA4E3F73F266DBC8AFE63D40884` |

The aggregate SHA-256 of ordinal `name|bytes|sha256` lines joined by LF is:

`A486F34196EA2ACEB0A2F6AB602DC71FDE3368D02FE456120E8CE04FA28BFC5B`

The staged DLL matches both reviewed deterministic builds. Metadata contains
the exact relocation DEV name
`BitWrecked_HistoricalRandomStart_PHASE1A_RELOC_DEV` and
`SkipWithAntiCheat=true`.

Microsoft Defender scanned the complete payload and found no threats with exit
code `0`. The game remained closed. The existing marker probe remains installed,
the relocation live folder remains absent, and no save was changed.

Live installation, marker-probe handling, target reset, and execution remain
separate authorization gates.
