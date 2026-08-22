# Phase 1A Atomic-Semantic Relocation — Live Payload Replacement

Date: 2026-08-20  
Decision: Recoverable live replacement PASS; target reset/run NO-GO

The owner authorized replacement of exactly:

`Mods\BitWrecked_HistoricalRandomStart_PHASE1A_RELOC_DEV`

The superseded deferred-placement payload was moved intact to:

`C:\BitWreckedDisposable\HRS_Phase1A\Backup\BitWrecked_HistoricalRandomStart_PHASE1A_RELOC_DEV.pre-atomic-semantic-replacement-2026-08-20`

Its preserved aggregate is:

`2BADF2BE5BB1972CB55CF49A7EEB25FD499D642E54FBCC40D3F6E1F243AF863C`

The new live inventory is exactly:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe.dll` | 15,360 | `632208686E0C5A2156DC27B32FD3579F80A0AC9E60171B262E1147AEEE8EFCE2` |
| `ModInfo.xml` | 407 | `CAD31EA6025B7F520933A28E776E03996CFD4AA4E3F73F266DBC8AFE63D40884` |

The live aggregate is
`4F5F5189E3F89CC259C39233FB5762529BE9CB178C3CE9508E94056E4641EAE6`,
exactly matching staging. Installed metadata validates the relocation DEV name
and `SkipWithAntiCheat=true`; Microsoft Defender returned exit code `0`.

The game remained closed. The exact semantic-changed Reserved target remains
present and untouched with 68 files and 19,377,481 bytes. Nothing was reset or
executed.

Next gate: **authorize backup and reset of exact semantic-changed Phase 1A target**.
