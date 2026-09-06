# Phase 1A Observer-Synchronized Relocation — External Build Record

Date: 2026-08-20  
Decision: Deterministic build and compiled-boundary review PASS; staging/live/run NO-GO

The owner authorized recompilation of source aggregate
`91B9A998A914C8FB5AEAE04FDA8F09B9C925B5429EC8A56EC41147F34757F4E9`.
The pinned compiler, host, and all seven explicit game/runtime reference hashes
matched before compilation. The game was closed.

| Build | Exit | Files | Bytes | SHA-256 |
| --- | ---: | ---: | ---: | --- |
| `build-19-relocation-observer-synchronized` | 0 | 1 | 15,360 | `9FBF9CDEBAB108633E916D338F6D9571D282533A4E6E3FBC51AB529EB1825FAB` |
| `build-20-relocation-observer-synchronized` | 0 | 1 | 15,360 | `9FBF9CDEBAB108633E916D338F6D9571D282533A4E6E3FBC51AB529EB1825FAB` |

The outputs are byte-identical. Assembly version is `0.0.0.0`; MVID is
`3292ff26-7011-46b3-983a-dbd421a378b7`. Each clean build directory contains
only the expected DLL, with no PDB, configuration file, or copied dependency.

Static source enforcement proves exactly one native random selection, one
player placement, and one synchronization of the existing observer, in this
order:

`reserve -> select -> semantic-before -> player placement -> observer sync -> pending verification`

Compiled metadata/member-reference review confirms references to:

- `EntityPlayer.ChunkObserver`;
- `Entity.SetPosition`; and
- `ChunkObserver.SetPosition`.

It confirms no member references to observer add/remove, explicit chunk
request, teleport, respawn, or direct network CVar mutation APIs. Both DLLs
passed Microsoft Defender custom-file scans with exit code `0`.

No payload was staged or installed. The live DLL remains unchanged at
`DE273E9216209CA188FA179614D7F4FC19037DB78D92BFB15C6BB985E05F61A6`,
and no save reset or game launch occurred.

Next gate: authorize observer-synchronized Phase 1A relocation payload staging.
