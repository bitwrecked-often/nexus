# Phase 1A Semantic Harness 0.0.1

Date: 2026-08-20  
Status: Ready for corrected semantic-enabled relocation first-load observation

The filesystem snapshot emits only aggregate counts, byte totals, and SHA-256
values for game managed files, foreign Mods, foreign saves, and the exact target.
It never emits relative paths, platform identifiers, coordinates, file content,
or individual player hashes. Owned marker/relocation DEV folders and the exact
target are excluded from their corresponding protected aggregates.

The sanitized-log reader accepts only fixed `[HRS-P1A-RELOC]` reason lines from
the approved game log root. Comparison fails unless protected aggregates are
unchanged, relocation completed, no failure reason exists, and runtime reports
`RELOC_SEMANTIC_UNCHANGED`.

The corrected reviewed relocation DLL emits `RELOC_SEMANTIC_UNCHANGED` only
after its allowlisted in-memory before/after digest matches. A mismatch emits
`RELOC_SEMANTIC_CHANGED`, leaves the marker Reserved, and blocks completion.
The underlying values, identities, and coordinates are not logged.
