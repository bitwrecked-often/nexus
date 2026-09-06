# Phase 1A Monotonic-Settling Relocation — First-Load Result

Date: 2026-08-20  
Decision: Categorical chunk-timeout proof PASS; relocation acceptance FAIL/NO-GO

The exact reviewed monotonic-settling probe loaded and initialized in the
approved new local single-player Navezgane target. The player reported spawning,
remained still, and exited normally.

Sanitized runtime evidence contains exactly:

```text
[HRS-P1A-RELOC] v=0.0.1 build=b14 reason=RELOC_READY
[HRS-P1A-RELOC] v=0.0.1 build=b14 reason=RELOC_PLACEMENT_CALLED
[HRS-P1A-RELOC] v=0.0.1 build=b14 reason=RELOC_VERIFY_CHUNK_TIMEOUT
```

This proves reservation/selection, semantic-before capture, virtual
`SetPosition`, and local origin repositioning completed, but
`World.IsChunkAreaLoaded(candidate)` did not become true during the 30-second
monotonic settling window. Safety, position acceptance, semantic-after capture,
and Completed were not reached. The marker remains Reserved and the target must
not be retried.

Post-close aggregate evidence was captured at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\phase1a-monotonic-settling-post-chunk-timeout-2026-08-20.json`

Protected aggregates remain identical to baseline:

| Protected tree | Result | SHA-256 |
| --- | --- | --- |
| Game managed | unchanged | `2EA9679D59A7DC759DC4F582A6673B0F2106CE475DA4F7FF998DE907BFCD5C4C` |
| Foreign Mods | unchanged | `B56FE9701B98231617DBED2431865CA077AF4B84105C26388496A336D056BD51` |
| Foreign saves | unchanged | `CE3564E1E1BB04F8348A1570D36CA8302641ABCA2EFE509A495C5366FAC1C23D` |

The timeout target has 74 files, 19,511,339 bytes, and aggregate
`B8524BE2C216798C6A36FD7AAF7EE5BB71A30E575C2C00E5FBA44640DD770F30`.
No coordinates, identities, filenames, or semantic values were published.

Read-only analysis of the authoritative server-side chunk observer/lifecycle is
required before any further source amendment.
