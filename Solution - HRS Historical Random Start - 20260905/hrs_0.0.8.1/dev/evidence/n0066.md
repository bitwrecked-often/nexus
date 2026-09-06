# Phase 1A Deferred-Placement Relocation — External Build Record

Date: 2026-08-20  
Decision: Deterministic build and compiled-IL review PASS; staging/live/run NO-GO

The owner authorized recompilation of source aggregate
`AFC408E535E17E355D0A7C259B416120BB90AEF130B0A3ECEA75E8F9CEC46C55`.
Pinned toolchain and all seven explicit reference hashes matched. The game was
closed.

| Build | Exit | Files | Bytes | SHA-256 |
| --- | ---: | ---: | ---: | --- |
| `build-23-relocation-deferred-placement` | 0 | 1 | 15,872 | `3BB52A412C6B156D849FEC1D2843BF9CD32A0ED0F44BC0CB39E152E2CD37D611` |
| `build-24-relocation-deferred-placement` | 0 | 1 | 15,872 | `3BB52A412C6B156D849FEC1D2843BF9CD32A0ED0F44BC0CB39E152E2CD37D611` |

The outputs are byte-identical. Assembly version is `0.0.0.0`; MVID is
`7e668df5-a829-4f3a-9337-3b5879813db6`. Each build directory contains only the
expected DLL.

Compiled method-level review confirms for both artifacts:

- `OnPlayerSpawned`: zero player placement, observer-position, and semantic
  capture calls;
- `OnGameUpdate`: one player placement, one existing-observer synchronization,
  and one `PendingPlacement.BeginPlacement` transition;
- two semantic captures total in `OnGameUpdate` (before and after);
- one containing-chunk lookup;
- zero broad `IsChunkAreaLoaded` calls; and
- one native safety call.

The previously enforced zero counts for explicit chunk requests, observer
add/remove, teleport, respawn, reroll, and direct network CVar mutation remain
intact. Both DLLs passed Microsoft Defender scans with exit code `0`.

No payload was staged or installed. The live DLL remains
`91C0AE24599088C64485C29851847CD5C703CF4C0ADF7A1D72C3D9C371417CCD`.
The failed Reserved target remains untouched, and nothing was launched.

Next gate: authorize deferred-placement Phase 1A relocation payload staging.
