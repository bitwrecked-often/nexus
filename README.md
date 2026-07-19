# Nexus Mod Workshop

This repository is a workshop for creating, testing, packaging, and publishing
open-source Nexus mod solutions. Root and governance-document license scope is
recorded separately instead of being inferred from the solution license. The
workshop is intentionally organized as infrastructure rather than a loose
collection of experiments.

## Two-Layer Structure

### Governance

`AGENTS.md`, `VERSION`, `RELEASING.md`, and `governance/` define how humans and AI handle versioning, safety, evidence, private testing, and publication. Historical release artifacts remain immutable. Reproducibility and source correspondence must be proven separately for each release.

### Solutions

`solutions/` contains field-derived mod packages. Each solution connects a real gameplay need to a readable implementation, validation process, user-facing controls, rollback path, and release packet.

The governing principle is simple: private observations become structured evidence; structured evidence becomes a tested solution; only an explicitly approved solution becomes a public release.

Current active version projection: see `VERSION`.

## Current 4.1.0 Route

- Current execution phase: `governance/EXECUTION_PLAN.md`
- Accepted release-readiness review: `governance/RELEASE_READINESS_4.1.0.md`
- Reconciled authority and blocker map: `governance/REPOSITORY_TRUTH_MAP.md`
- Repository-health controls and live-setting boundaries:
  `governance/GITHUB_REPOSITORY_HEALTH.md`
- Contribution and privacy boundary: `CONTRIBUTING.md`
- Active solution contract:
  `solutions/7dtd_wasteland_animal_population_tuning_files/release-manifest.json`
- Safe offline check (PowerShell 7.4 or later):

```powershell
pwsh -NoProfile -File tools/release/Invoke-NexusPackage.ps1 `
  -ManifestPath solutions/7dtd_wasteland_animal_population_tuning_files/release-manifest.json `
  -Action Validate
```

The default check is offline and read-only. It does not launch the mod tool,
read a game installation, build or stage a candidate, publish, or change Nexus.
P4 is technically authorized, but no candidate ZIP has been built or promoted.

The broader repository test suite also uses owned system-temp clones. Its
source-staging fixture uses a production-shaped path but creates no ZIP or
`final-upload`; its package/GUI-smoke fixture is routed to the guarded
`dist/.test-fixtures/` namespace. Both clones are deleted after the check, carry
no candidate authority, and do not consume the one authorized P4 candidate
cycle.
