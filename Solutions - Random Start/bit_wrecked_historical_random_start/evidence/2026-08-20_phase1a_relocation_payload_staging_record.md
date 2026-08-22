# Phase 1A Relocation Probe — Payload Staging Record

Date: 2026-08-20  
Decision: External payload PASS; installation/execution NO-GO

The owner authorized a new external two-file payload at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\payload-0.0.1-dev-relocation`

The payload contains exactly:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.RelocationProbe.dll` | 10,752 | `14E101DCA80148D7589E6B7EFE16532F4C22AB94355EA2605469B53A2784378E` |
| `ModInfo.xml` | 407 | `CAD31EA6025B7F520933A28E776E03996CFD4AA4E3F73F266DBC8AFE63D40884` |

The two-file aggregate SHA-256 is:

`CD453C42A2B7FC29996E21E102BFCBED1BDE8907E289518230B270780D50CCC9`

The DLL matches both reviewed deterministic builds. Metadata has the exact
valid relocation DEV Name and `SkipWithAntiCheat=true`. Microsoft Defender
scanned the full payload and reported no threats with exit `0`.

The existing marker probe remains installed. No relocation live folder exists.
No live Mod or save was changed and the game was not launched.

Before installation or execution, the semantic state-delta harness must be
prepared and reviewed, the marker-only live probe must be handled explicitly,
and the persistent-Reserved target must be preserved/reset to an absent-marker
state. Those remain separate authorization gates.
