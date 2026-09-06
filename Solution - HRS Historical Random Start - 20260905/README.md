# Solutions Index

This folder holds reusable answer packets for common gameplay/modding questions.

Use these docs when answering players, preparing Qwen32 prompts, or rebuilding a known fix into a clean modlet.

Version history and the verified differences between release lanes are recorded
in [CHANGELOG.md](CHANGELOG.md).

Every DEV and QA cycle uses the release-evidence process in
[qa_cycle/README.md](qa_cycle/README.md). It validates the exact candidate and
produces a sanitized, hash-manifested evidence bundle for each QA case.

## Current Solutions

| Solution | Use When |
| --- | --- |
| `hrs_1.1.0/README.md` | Active Historical Random Start feature lane with approved NG01/NG02 random selection. |
| `hrs_1.0.1/README.md` | Preserved packaging-identification repair and fixed-NG01 predecessor. |
| `hrs_1.0.0/README.md` | Preserved failed-QA candidate for the `ModInfo.xml` thumbprint mismatch record. |
| `hrs_0.1.0/README.md` | Saved Historical Random Start `0.1.0-tech-demo` lane with curated Perishton start and optional snow-first biome protection. |
| `hrs_0.0.8.1/README.md` | Immediate development predecessor retained for comparison and rollback. |
| `archive/` | Preserved inactive solution folders, including older Historical Random Start, Wasteland, framework, and offense-weapons work. Read/hash unless deliberately reactivated. |

Historical Random Start now has an explicit DEV -> QA -> Nexus lifecycle. Read
[the routing doctrine](HRS_DEV_QA_NEXUS_WORKFLOW.md) before choosing a lane.
Use [the development-cycle doctrine](DEVELOPMENT_CYCLE_DOCTRINE.md) to challenge
proposals, scout candidates, and decide what evidence is required before a
change advances.
Release identity, QA cases, and evidence are governed by the repository's
`qa_cycle` process rather than by files stored in the live game installation.
Active spawn scouting resumes from the compact
[AI context handoff](hrs_1.1.0/dev/scouting/AI_CONTEXT_HANDOFF.md), which routes
the complete generated Navezgane POI catalog without requiring it all to be
loaded into a model context window.

## Routing Rules

- Treat each solution as an explanation layer, not the live payload.
- Verify live XML before claiming exact current values.
- Prefer a modlet for sharing with other players.
- Use direct `Data/Config` edits only for local DEV testing or when the user explicitly chooses that route.
- Keep POI sleeper spawns separate from biome/open-world spawn weighting.
- For the current Historical Random Start release candidate, begin at
  `hrs_1.1.0/README.md`, then `hrs_1.1.0/dev/docs/n0236.md`.
  Keep all routine work within that complete version lane, preserve the
  established main pipeline, and implement new behavior as bounded features.
- Before QA handoff, run `qa_cycle/Test-HrsRelease.ps1`. Do not create a QA run
  while the release gate reports an error. DEV-only evidence requires the
  script's explicit development-gap override and cannot approve a release.
- QA consumes the immutable artifact under `../QA_Testing/`, fingerprints its
  environment, observes behavior, and reports evidence. It does not edit,
  rebuild, refresh pins, clear markers, or repair the candidate.
- A QA pass permits preparation of a separate minimal Nexus-review candidate;
  it does not promote the full-context QA ZIP directly.
- Keep the archived `0.0.1-alpha` Nexus-review baseline frozen and read-only.
