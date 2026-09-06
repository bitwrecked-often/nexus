# Phase 1A Corrected Metadata — Payload Staging Record

Date: 2026-08-20  
Decision: Corrected external payload PASS; live/save/run NO-GO

The owner authorized a new external payload at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\payload-0.0.1-dev-amended-metadata-fixed`

Earlier payloads remain preserved. This payload contains exactly:

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `BitWrecked.HistoricalRandomStart.Phase1A.MarkerProbe.dll` | 8,704 | `3D7395FEF5D98EB8B456442F5BA2037443B981E760E090031A223277D3E143D5` |
| `ModInfo.xml` | 395 | `0F7B261BDDE9F7F780882F0BB36937C0E20A46AC06EAF27B8A53E4E4E8337657` |

The two-file aggregate SHA-256 is:

`BAAB0DBE78A4E8C670040E3FB0D0BC993988388B4774B8721B51959269574296`

The DLL is unchanged from both amended deterministic builds. The internal
metadata Name is exactly `BitWrecked_HistoricalRandomStart_PHASE1A_DEV`, passes
the installed game token grammar, and retains `SkipWithAntiCheat=true`.
Microsoft Defender scanned the complete payload and reported no threats with
exit `0`.

No live Mod file was replaced. The game remains closed, and the disposable
save created during the metadata-rejected attempt remains preserved. Live
metadata replacement and exact target reset require separate authorization.
