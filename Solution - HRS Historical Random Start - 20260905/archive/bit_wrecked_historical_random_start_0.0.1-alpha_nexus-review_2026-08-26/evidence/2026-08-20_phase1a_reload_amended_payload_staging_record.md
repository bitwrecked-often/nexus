# Phase 1A Reload-Observation Amendment — Payload Staging Record

Date: 2026-08-20  
Decision: External amended payload PASS; live replacement/execution NO-GO

The owner authorized a new external two-file payload at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\payload-0.0.1-dev-amended`

The original payload was preserved. The amended payload contains exactly:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.MarkerProbe.dll` | 8,704 | `3D7395FEF5D98EB8B456442F5BA2037443B981E760E090031A223277D3E143D5` |
| `ModInfo.xml` | 407 | `439777B85A3E9288F9DC2F00B5A9DD0527D29CD48EBC3DAACFEA037A540CD6F2` |

The SHA-256 of the two ordinal `path|bytes|sha256` UTF-8 lines joined by LF is:

`9E7E296A6FF4CF7F8D683FF9C264B4C1921D30859CD09498B919F58723ECAFD8`

The DLL matches both amended deterministic builds. The metadata remains the
pinned file with `SkipWithAntiCheat=true`. Microsoft Defender scanned the full
payload and reported no threats with exit `0`.

The installed owned DLL remains the prior SHA-256
`FCC012FC8841FC1D7285C108D15EDDC4DD62BED5500B0C3F387F918AFE4F37E3`.
No live file was replaced, the game was not launched, and the Phase 1A save
remains absent. Replacing the exact owned two-file live payload requires a
separate authorization; execution remains a later gate.
