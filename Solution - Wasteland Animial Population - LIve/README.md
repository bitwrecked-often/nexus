# Solutions Index

This folder holds reusable answer packets for common gameplay/modding questions.

Use these docs when answering players, preparing Qwen32 prompts, or rebuilding a known fix into a clean modlet.

## Current Solutions

| Solution | Use When |
| --- | --- |
| `7dtd_wasteland_animal_population_tuning.md` | Someone wants Wasteland animal roll weights tuned without removing animals, especially for Windows 11 / Steam / current 7DTD 3.0-era installs. |

## Routing Rules

- Treat each solution as an explanation layer, not the live payload.
- Verify live XML before claiming exact current values.
- Prefer a modlet for sharing with other players.
- Use direct `Data/Config` edits only for local DEV testing or when the user explicitly chooses that route.
- Keep POI sleeper spawns separate from biome/open-world spawn weighting.
