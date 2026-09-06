# Phase 1A Marker Persistence — Success and Decision

Date: 2026-08-20  
Decision: Marker-only proof PASS; relocation source/build/install/run remain NO-GO

The owner authorized one read-only reload of the exact AddCustomVar test target.
The dedicated sanitized log contains exactly:

```text
[HRS-P1A-MARKER] v=0.0.1 build=b14 reason=MARKER_READY
[HRS-P1A-MARKER] v=0.0.1 build=b14 reason=MARKER_RELOAD_RESERVED
```

There are zero Completed, Absent, Invalid, internal-failure, or target-rejected
results. The `LoadedGame` branch performed no marker write. Combined with the
prior `MARKER_RESERVED_VERIFIED` first-load result, this proves for the pinned
local single-player build and exact disposable target that:

1. `EntityBuffs.AddCustomVar(Name, 1f)` updates the server-side marker for
   immediate read-back;
2. Reserved survives a normal save/exit/reload boundary; and
3. reload observation does not reroll, clear, complete, or rewrite the marker.

The user exited normally. The game is closed. The target contains 73 files with
post-reload aggregate SHA-256:

`E29722750EE845646210F5145B1BF0CC55E3F05513613A2DC832235CDA4A23D9`

Both live payload hashes remain exact. The marker-only test has achieved its
narrow objective. It does not authorize or prove candidate selection,
placement, verification ticks, semantic state-delta capture, or Completed
marker behavior.

The next engineering gate may prepare relocation source against the already
approved one-attempt contract, using `AddCustomVar` for Reserved and a reviewed
local-and-synchronized setter path for a future Completed transition only after
verified placement. Compilation, live replacement, target preparation, and
runtime execution remain later independent gates.
