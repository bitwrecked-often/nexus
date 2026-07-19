# Solutions Index

This folder holds field-derived answer packets and releasable mod solutions for common gameplay and modding needs.

Use these documents when answering players, reviewing a package, or rebuilding a known fix into a clean modlet.

## Field-to-Solution Standard

Each solution should preserve the path from real-world need to supportable package:

1. State the player or server problem in observable terms.
2. Identify the live game files and version used as the baseline.
3. Separate verified behavior from observations and inference.
4. Implement the smallest readable mod change that addresses the need.
5. Put operational safety in front of risky actions: validation, preview, backup, verification, restore, and removal.
6. Test the packaged artifact, not only the source tree.
7. Document compatibility, consequences, known issues, and rollback.
8. Promote privately tested work to public release only through the repository governance and release process.

A solution is not considered complete merely because it works once. It should remain understandable, testable, reversible, and supportable under ordinary field conditions.

## Current Solutions

| Solution | Use When |
| --- | --- |
| `7dtd_wasteland_animal_population_tuning.md` | Someone needs the current Wasteland animal density/mix solution, its Windows wrapper, exact package contract, or `4.1.0` release status. |

## Routing Rules

- Treat each solution overview as a checked routing layer, not the live payload or release authority.
- Use the solution's machine-readable release manifest for current identity and edition contracts.
- Verify live XML before claiming exact current values.
- Prefer a modlet for sharing with other players.
- Use direct `Data/Config` edits only for local DEV testing or when the user explicitly chooses that route.
- Keep POI sleeper spawns separate from biome/open-world spawn weighting.
