# Phase 1A Unchecked-Semantic Relocation — Live Payload Replacement

Date: 2026-08-20  
Decision: Recoverable live replacement PASS; target reset/run NO-GO

The owner authorized replacement of exactly:

`Mods\BitWrecked_HistoricalRandomStart_PHASE1A_RELOC_DEV`

The superseded native-aligned payload was moved recoverably to:

`C:\BitWreckedDisposable\HRS_Phase1A\Backup\BitWrecked_HistoricalRandomStart_PHASE1A_RELOC_DEV.pre-unchecked-semantic-replacement-2026-08-20`

Its preserved aggregate is:

`49713BD3E5717FCEB5A5DD2DF68C72982FE55A5B82A12B8DFD524057539BA9B1`

The new live folder contains exactly:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe.dll` | 14,336 | `1F68045943DACF40DA579D3F62C3D5BD48F2D20F3F31521203F04D93EADF5F54` |
| `ModInfo.xml` | 407 | `CAD31EA6025B7F520933A28E776E03996CFD4AA4E3F73F266DBC8AFE63D40884` |

The independently calculated live aggregate is:

`32CE68EB996957865E5B76F3909AB8F1AF13EFD5BC33D84D78BA2AFAA72CA227`

The game remained closed. The exact failed Reserved target remains present and
unchanged; it cannot be reused. Target backup/reset and later execution remain
separately gated.
