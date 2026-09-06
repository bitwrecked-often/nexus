# Phase 1A Marker-Only Probe — Owned DEV Copy Record

Date: 2026-08-20  
Decision: Exact owned installation PASS; execution NO-GO

The owner authorized copying the reviewed external two-file payload into the
new exact owned folder:

`C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die\Mods\BitWrecked_HistoricalRandomStart_PHASE1A_DEV`

Preconditions passed: the game process was closed, the destination did not
exist, the `Mods` root was not a reparse point, and both external payload hashes
matched the staging record.

The installed folder contains exactly:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.MarkerProbe.dll` | 8,192 | `FCC012FC8841FC1D7285C108D15EDDC4DD62BED5500B0C3F387F918AFE4F37E3` |
| `ModInfo.xml` | 407 | `439777B85A3E9288F9DC2F00B5A9DD0527D29CD48EBC3DAACFEA037A540CD6F2` |

The installed two-file aggregate is
`D041F98190EAA46918B0C1C9FD64A8D875EF148E3B02A65C82FA267AA38BF744`,
identical to the reviewed external payload.

No Phase 1A save exists. The game was not launched. No other Mod folder or
game file was written. First-load preflight, creation of the exact disposable
`Navezgane / HRS_Phase1A_Test_001` target, marker observation, normal exit,
reload persistence observation, and clean removal remain gated actions.
