# 0.0.8.1 Compact-Path Baseline

Date: 2026-08-27
Scope: structural rename of the copied DEV lane only
Status: contained PowerShell 5.1 and PowerShell 7 validation passed

## Result

The copied development lane was compacted from:

`bit_wrecked_historical_random_start_0.0.8-alpha-tech-demo_2026-08-27`

to:

`hrs_0.0.8.1`

Every file and directory component beneath the compact lane is fewer than 12
characters, including file extensions. The longest absolute file path in the
actual Steam workspace decreased from 305 characters to 136 characters.

The old-to-new component mapping is preserved in `map.csv`. Old names may
appear as data in that map; they are not live filesystem components.

## Structural contract

- The compact root and every descendant filename/directory name remain fewer
  than 12 characters (11 maximum).
- New files must follow the same limit, including their extension.
- New directories must follow the same limit.
- Renames must update `map.csv` and every executable/document reference in the
  same change.
- Short identifiers are path identities, not product identities. Namespace,
  player-facing branding, schemas, and behavior remain governed by their
  existing contracts.
- The `0.0.5` solution and frozen QA candidate remain unchanged.
- This lane is the structural `0.0.8` development line, but copied internal
  release/version declarations still identify the known-good `0.0.5` baseline
  until a separate version-conversion task updates and validates them.

## Reference validation

- Files: 269 after adding this report and `map.csv`.
- Directories: 40.
- File components of 12 characters or more: 0.
- Directory components of 12 characters or more: 0.
- Unresolved old component references outside `map.csv`: 0.
- No short-name collision was found during projection or rename.

## Windows PowerShell 5.1

The complete renamed non-live suite ran directly from the actual compact Steam
path using `powershell.exe -NoProfile`. No `subst` alias was used.

| Suite | Result |
| --- | --- |
| Alpha Core contract | 88/88 |
| Alpha Core state/deployment | 62/62 |
| Management state | 8/8 |
| Phase 0A pure contract | 66/66 |
| Marker source static | 1/1 |
| Phase 1A pure contract | 30/30 |
| Relocation source static | 1/1 |
| Semantic harness | 7/7 |
| Portable QA manager static | 18/18 |
| Preview Apply workflow | 11/11 |
| Preview static write scan | PASS |
| Release source verification | 1/1 |

Counted assertions: 293/293, plus the passing static write scan.

## PowerShell 7 parity

The same suite passed under PowerShell 7 with the same 293/293 counted
assertions and passing static write scan.

## Structural adjustments required by the rename

Two test assumptions were updated after the first PowerShell 5.1 run:

1. The deployment missing-file expectation now uses the renamed DLL-derived
   error token.
2. The semantic prefix-exclusion fixture now targets the renamed fixture file.

These are structural test updates only. Runtime relocation, selection,
lifecycle, compatibility, semantic snapshot, marker, and settling-verifier
behavior were not edited.

## Claim boundary

This proves that the compact lane can be enumerated and its complete contained
suite can execute under Windows PowerShell 5.1 at the actual Steam workspace
depth. It does not prove live installation, game launch, clean-machine
extraction, MOTW behavior, or runtime gameplay. Those remain separately gated.
