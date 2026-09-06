# Phase 1A Placement-Failure Isolation Analysis

Date: 2026-08-20  
Decision: Root cause proven in compiled IL; source/live/save unchanged

The owner authorized read-only isolation of the native-aligned first-load
`RELOC_PLACEMENT_FAILED` result.

## Proven root cause

The build recipe intentionally uses Roslyn `/checked+`. `SemanticSnapshot`
implements an FNV-style `ulong` digest whose multiplication must intentionally
wrap modulo 2^64. The integer `Add` overload already encloses its operations in
an `unchecked` block, but the string and float overloads do not.

Mono.Cecil inspection of the exact live DLL
`91665756F96640D08F31F744B3C12E09236A189BD91EF4F4E972D46416AB6290`
found:

| Digest overload | Compiled multiply opcode |
| --- | --- |
| `Add(ref ulong, string)` | `mul.ovf.un` |
| `Add(ref ulong, float)` | `mul.ovf.un` |
| `Add(ref ulong, int)` | ordinary `mul` |

`mul.ovf.un` throws `OverflowException` when the expected FNV wraparound occurs.
`SemanticSnapshot.Capture` begins with `Add(ref hash, player.Health)`, which uses
the float overload. Therefore the semantic-before capture throws before virtual
`SetPosition`, pending-state construction, and `RELOC_PLACEMENT_CALLED`.

This exactly explains the sanitized runtime sequence:

```text
RELOC_READY
RELOC_PLACEMENT_FAILED
```

## Minimal correction

Place the float and string digest loops inside explicit `unchecked` blocks, or
otherwise make their multiply operations compile to ordinary wrapping `mul`.
Retain `/checked+` for the rest of the artifact. Compiled-artifact review must
prove that all three digest overloads use ordinary `mul` and contain no
`mul.ovf`/`mul.ovf.un` opcodes.

No readiness ordering, selection, placement, semantic field set, marker state,
logging payload, or verification behavior needs to change for this correction.

The failed target remains Reserved and must not be reused. No source, compiled
artifact, staged payload, live Mod, or save was changed by this analysis.
