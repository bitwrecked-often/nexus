# Phase 1A Relocation — Semantic Harness Scaffold Gate

Date: 2026-08-20  
Decision: Read-only harness/pure tests PASS; installation/execution NO-GO

The owner authorized read-only semantic-harness scaffolding. Offline player
save parsing was rejected because the binary paths and contents are
identity-bearing. The scaffold instead emits only aggregate presence, file
count, byte count, and SHA-256 values; it never emits raw paths, platform IDs,
coordinates, save contents, or per-player hashes.

The filesystem snapshot protects:

- installed managed game files;
- all foreign Mod files, excluding only the exact owned marker/relocation DEV
  folders; and
- all foreign saves, excluding only the exact disposable target.

The target receives its own aggregate. The sanitized log reader accepts only
fixed `[HRS-P1A-RELOC]` reason lines from the approved game log directory.

Comparison fails closed if any protected aggregate changes, relocation does not
complete, a failure reason appears, or runtime does not emit the single
allowlisted result `RELOC_SEMANTIC_UNCHANGED`.

Seven pure cases pass under PowerShell 7 and Windows PowerShell 5.1:

- complete plus semantic/protected equality passes;
- missing runtime semantic proof fails;
- foreign Mod change fails;
- runtime failure reason fails;
- tree digest is deterministic;
- prefix exclusion reduces the protected set; and
- missing tree is represented as absent.

All harness scripts parse cleanly in both supported environments.

The currently staged relocation DLL does **not** emit
`RELOC_SEMANTIC_UNCHANGED`. It therefore cannot satisfy this harness and must
not be installed or executed. A new source-only amendment must capture the
allowlisted quest, inventory, progression, health/food/water, and unrelated
active-buff state in memory before placement and compare it after verified
placement. It may emit only the equality result, never underlying values or
identity. That amendment, recompilation, payload restaging, and runtime work
remain separately gated.
