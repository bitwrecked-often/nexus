# Phase 1A Deferred-Placement Relocation — Live Payload Replacement

Date: 2026-08-20  
Decision: Recoverable live replacement PASS; target reset/run NO-GO

The owner authorized replacement of exactly
`Mods\BitWrecked_HistoricalRandomStart_PHASE1A_RELOC_DEV`.

The superseded containing-chunk payload was moved intact to:

`C:\BitWreckedDisposable\HRS_Phase1A\Backup\BitWrecked_HistoricalRandomStart_PHASE1A_RELOC_DEV.pre-deferred-placement-replacement-2026-08-20`

Its preserved aggregate is
`3A0315F27F0450D827D9E07E34603FEF0830CFA305E3F75437ACCEE6CEB119FE`.

The new live inventory is exactly:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe.dll` | 15,872 | `3BB52A412C6B156D849FEC1D2843BF9CD32A0ED0F44BC0CB39E152E2CD37D611` |
| `ModInfo.xml` | 407 | `CAD31EA6025B7F520933A28E776E03996CFD4AA4E3F73F266DBC8AFE63D40884` |

The live aggregate is
`2BADF2BE5BB1972CB55CF49A7EEB25FD499D642E54FBCC40D3F6E1F243AF863C`,
exactly matching staging. Installed metadata validates the relocation DEV name
and `SkipWithAntiCheat=true`; Microsoft Defender returned exit code `0`.

The game remained closed. The exact containing-chunk timeout target remains
present and untouched in its failed Reserved state. Reset and execution remain
separately gated.

Next gate: authorize backup and reset of exact containing-chunk-timeout Phase 1A target.
