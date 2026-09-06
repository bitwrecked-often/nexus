# Phase 1 Observation Probe — Source Scaffold Gate

Date: 2026-08-20  
Decision: Source-scaffold GO; compile/copy/load not yet executed

## Exact private target

- Deployment: owner-designated installed Steam observation lab
- Game root: `C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die`
- Save root: `C:\Users\mobil\AppData\Roaming\7DaysToDie\Saves`
- Target: `Navezgane / HRS_Phase1_Test_001`
- Execution: local single-player, EAC disabled, new game only
- External stage: `C:\BitWreckedDisposable\HRS_Phase1\BuildStage`
- Absence baseline: target save absent and owned DEV Mod folder absent
- Baseline SHA-256: `8532E676455D025F338D03C267A92F7D54FA413288EBC0039DA41341B471C4C0`
- Target record validation: `TARGET_OK`
- Target-record SHA-256: `9AFB0F01B0590DF0FE085FF0171EE367B33DD19C76C223D4C4F6936FE5883AD0`

The external path uses `C:` because this machine has no `D:` volume. It is a
normal local directory, not a reparse point, and is outside the game, Mods,
save, backup, and project roots.

## Source review

The exact seven-file source/metadata set implements only the Phase 1
observation boundary: `IModApi` registration, build and target guards,
authoritative lifecycle classification, entity resolution, bounded in-memory
duplicate suppression, and sanitized game logging. It contains no spawnpoint
selection, placement, CVar, buff, quest, inventory, file-write, process,
network, command, or Harmony path.

Source manifest:
`src/runtime/BitWrecked.HistoricalRandomStart.DevProbe/source_manifest.json`

Aggregate source SHA-256:
`0F283071EE534B44E68679F63AAF5EBF733CDB19145D89A3DDF1732078F7B3B3`

## Toolchain and dependency review

- Pinned compiler version and SHA-256 match the installed compiler.
- All seven direct reference sizes and SHA-256 values match the pinned
  dependency inventory.
- References remain game/runtime-provided and are not distribution payloads.
- No external packages, restore, downloads, or bundled third-party binaries
  are used.
- Microsoft Defender is enabled with real-time protection; signature version
  `1.457.265.0`, updated 2026-08-20.

The exact source has not yet been compiled. No DLL or payload exists, and no
file has been copied into `Mods`. Compile, copy, and first load remain distinct
review gates.
