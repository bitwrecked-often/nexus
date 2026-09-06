# Phase 1A Monotonic-Settling Relocation — Live Payload Replacement

Date: 2026-08-20  
Decision: Recoverable live replacement PASS; target reset/run NO-GO

The owner authorized replacement of exactly
`Mods\BitWrecked_HistoricalRandomStart_PHASE1A_RELOC_DEV`.

The superseded unchecked-semantic payload was moved to:

`C:\BitWreckedDisposable\HRS_Phase1A\Backup\BitWrecked_HistoricalRandomStart_PHASE1A_RELOC_DEV.pre-monotonic-settling-replacement-2026-08-20`

Its preserved aggregate is
`32CE68EB996957865E5B76F3909AB8F1AF13EFD5BC33D84D78BA2AFAA72CA227`.

The new live inventory is exactly:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe.dll` | 14,848 | `DE273E9216209CA188FA179614D7F4FC19037DB78D92BFB15C6BB985E05F61A6` |
| `ModInfo.xml` | 407 | `CAD31EA6025B7F520933A28E776E03996CFD4AA4E3F73F266DBC8AFE63D40884` |

The independently calculated live aggregate is
`2932C8FDF5C52C171A3177FED0040F91BD2D25D7D3C134C38EF78DD18C2FC796`.

The game remained closed. The exact verification-failed Reserved target remains
present and unchanged; it cannot be reused. Target backup/reset and execution
remain separately gated.
