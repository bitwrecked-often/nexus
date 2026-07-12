# Nexus Mod Workshop

This is an open-source workshop for creating, testing, packaging, and publishing Nexus mods. It is intentionally organized as infrastructure rather than a loose collection of experiments.

## Two-Layer Structure

### Governance

`AGENTS.md`, `VERSION`, `RELEASING.md`, and `governance/` define how humans and AI handle versioning, safety, evidence, private testing, and publication. Published releases remain reproducible and immutable.

### Solutions

`solutions/` contains field-derived mod packages. Each solution connects a real gameplay need to a readable implementation, validation process, user-facing controls, rollback path, and release packet.

The governing principle is simple: private observations become structured evidence; structured evidence becomes a tested solution; only an explicitly approved solution becomes a public release.

Current development version: see `VERSION`.
