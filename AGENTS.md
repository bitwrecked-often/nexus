# Nexus Repository Governance

This repository is used only to develop, validate, package, and publish open-source Nexus mods. Nexus support may review everything committed here. Keep all content professional, factual, relevant, and safe to disclose.

These instructions apply to the entire repository.

The enduring project principles and vendor/customer views are defined in `governance/PROJECT_MANIFEST.md`. Read it before designing repository-wide infrastructure or a public release packet. For `4.1.0` baseline work, also read `governance/NEXT_AI_DEEP_REPO_AUDIT_ADDENDUM.md` and `governance/OWNER_DECISION_INTERVIEW.md` before running packaging or validation commands.

Before adding, removing, licensing, or packaging an image or branding asset, read `governance/ASSET_PROVENANCE.md`. An owner statement, repository commit, public profile, and license grant are different evidence and must remain distinguishable.

## Repository Model

The repository has two cooperating layers:

1. **Governance layer** — root files and `governance/` define versioning, release evidence, safety rules, private testing, and AI behavior.
2. **Solutions layer** — `solutions/` contains mod-specific explanation packets, source payloads, documentation, validation tools, and release artifacts derived from field evidence.

Governance controls how a solution may advance. A solution supplies the implementation and evidence.

## AI Operating Rules

- Treat all repository content as potentially visible to Nexus staff and future users.
- Never add credentials, personal tester information, private conversations, machine identifiers, save files, or unrelated material.
- Preserve published releases. Never rewrite or move an existing release tag or silently replace a released artifact.
- Treat the committed `4.0.1` ZIPs as grandfathered immutable evidence. Future final ZIPs must stay out of Git history, be promoted only into an ignored versioned `final-upload` stage, and be attached to GitHub Releases after approval; commit their checksums, inventories, provenance, and release references instead of the archive bytes.
- Work on the active development branch. Keep `main` representative of published, supportable content.
- Follow semantic versioning. Backward-compatible features increment MINOR; compatible fixes increment PATCH; breaking changes increment MAJOR.
- Keep `VERSION`, mod metadata, package metadata, release notes, changelog, archive names, and Nexus metadata consistent at release time.
- Make the smallest safe change. Do not mix unrelated cleanup with a feature or fix.
- Keep owner decisions at owner altitude. Use evidence and established project policy for reversible implementation mechanics such as staging paths, checksum placement, and byte-preserving channel transfer. Ask the owner only when a choice materially changes product behavior, customer promises, rights/license scope, public identity, external publication, irreversible state, or accepted release risk.
- Prefer readable source and deterministic packaging. Do not introduce hidden downloaders, telemetry, registry persistence, services, scheduled tasks, startup entries, obfuscation, or unexplained binaries.
- Treat GPL-3.0-or-later compliance as an artifact gate, not merely a repository label. Every distributed edition must carry the full applicable license, preserve copyright, license, modification, and no-warranty notices, and include or provide the exact corresponding source by a GPL-compliant method. When an edition is distributed as BAT, PowerShell, and XML source, keep that preferred editable source in the archive. Do not add restrictions on use, copying, modification, or redistribution; provenance language may distinguish an official project release from a modified version but must not narrow GPL permissions.
- Do not infer ownership or license coverage for images, branding, documentation, or other non-code material. Record the copyright holder, license, redistribution authority, and preferred editable source for each distributed asset before treating it as part of a GPL-covered release.
- Order public surfaces by customer need: user clarity and safety first, applicable legal/vendor/industry obligations second, and project identity or promotional branding only in the remaining surface. This is a presentation priority, not permission to omit mandatory notices, authorship, provenance, or support identity.
- Do not claim compatibility from inspection alone. Record what was actually tested and distinguish observation, inference, and unverified expectation.
- Do not fabricate test results, checksums, game versions, support responses, or user feedback.
- Preserve user control: show intended writes, validate targets, back up sensitive files, verify results, and provide a documented undo path.
- Keep dangerous or high-load options visibly separate from normal controls and explain their consequences in plain language.
- Do not publish, merge to `main`, tag a release, upload a Nexus file, or hide an older Nexus file without explicit user authorization.

## Required Change Record

Every material mod change must identify:

- the user-visible purpose;
- files and game state it reads or writes;
- compatibility assumptions;
- validation performed;
- rollback behavior;
- known limitations or unresolved observations.

Record player-visible payload, package, compatibility, install, and support changes in the applicable solution changelog. Record repository governance and maintainer-infrastructure changes in `governance/CHANGELOG.md`. Record incomplete work under an Unreleased heading. Field-test reports must be anonymized and must not contain tester identities.

## Front-End Standard

The front end is an operational safety layer, not decoration. When applicable, it must provide:

- conservative defaults and understandable presets;
- target and game-version validation before writes;
- conflict or overlapping-mod warnings where detection is practical;
- a preview of intended changes;
- automatic backup before sensitive configuration edits;
- explicit install, verify, restore, and remove paths;
- installed-versus-selected state reporting;
- actionable errors and a shareable, privacy-safe diagnostic log;
- no silent network use, telemetry, or background behavior.

## Evidence Gate

A solution moves from private testing to public release only when:

- its supported environment is explicit;
- installation and removal are verified;
- backups and restoration are tested where applicable;
- compatibility checks fail safely against unsupported input;
- package contents and prohibited-file rules are validated;
- release archives are rebuilt reproducibly and inspected;
- known issues and expected consequences are documented;
- the user explicitly approves publication.

Use `governance/PRIVATE_TEST_PROGRAM.md` for field testing and `RELEASING.md` for publication.
