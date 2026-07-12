# Next AI Work Packet: 4.1.0 Baseline Infrastructure

## Mission

Strengthen the Nexus mod workshop baseline so reliability, evidence, reversibility, and readable user support are enforced by software rather than dependent on memory.

This is infrastructure work for the backward-compatible `4.1.0` development line. Do not add speculative gameplay features during this assignment.

## Start Here

Read these files completely before making changes:

1. `AGENTS.md`
2. `README.md`
3. `VERSION`
4. `RELEASING.md`
5. `governance/PRIVATE_TEST_PROGRAM.md`
6. `solutions/README.md`
7. This packet
8. The active solution's `PACKAGE_METADATA.md`, `TECHNICAL_FILE_MANIFEST.md`, `CHANGELOG.md`, and validation script

Active solution root:

```text
solutions/7dtd_wasteland_animal_population_tuning_files/
```

## Repository State At Handoff

- The public baseline is preserved by annotated Git tag `v4.0.1`.
- Development occurs on `develop/4.1.0`.
- Root `VERSION` is `4.1.0-dev`.
- The published `4.0.1` archives are historical artifacts and must remain byte-for-byte unchanged during this assignment.
- The no-scripts `4.1.0` source manuals are under:

```text
Support_Files_Do_Not_Edit/Nexus_NoScripts/
```

- `validate_and_package.ps1` contains initial construction and validation support for the no-scripts archive.
- Nexus support may inspect this repository. Do not commit private tester data, credentials, machine identifiers, or internal conversation transcripts.

Confirm the branch and clean working tree before starting. If unexpected user changes exist, preserve them and report any overlap.

## Required Deliverables

Implement the following in priority order.

### 1. Machine-Readable Release Manifest

Add a single structured manifest in a broadly supported format such as JSON. It must describe:

- schema version;
- package name and stable package ID;
- repository development version;
- release channel;
- license identifier;
- supported game name and exact tested build when known;
- platform/install-mode support using explicit states such as `verified`, `observed`, `expected`, and `unsupported`;
- canonical archive names;
- mod folder name;
- XML files and target areas owned by the mod;
- prohibited archive extensions;
- whether network, telemetry, elevation, compiled code, or external processes are used.

Do not invent an exact game build. Represent unknown information honestly.

Document which values remain authoritative in `ModInfo.xml` and which are governed by the manifest. Avoid creating competing sources of truth.

### 2. Version-Consistency Enforcement

Extend validation so release mode fails when release-facing versions disagree among:

- root `VERSION`;
- manifest;
- modlet `ModInfo.xml`;
- package metadata;
- release notes;
- changelog release heading;
- archive metadata or names where versions are encoded.

Development suffixes such as `-dev` must be supported without falsely declaring the historical `4.0.1` archives invalid. Clearly separate development validation from final-release validation.

### 3. External Release Report

Generate a deterministic report outside all archives containing, for each release artifact:

- archive filename;
- byte size;
- SHA-256 checksum;
- source commit when available;
- package version;
- supported/tested game baseline;
- sorted archive entry inventory;
- validation status.

Never place an archive's own checksum inside itself. Avoid nondeterministic data unless explicitly labeled operational metadata.

### 4. Package-Level Smoke Tests

For every archive type, test the artifact after construction:

- extract to a safely created temporary directory;
- verify top-level shape and required entries;
- parse every packaged XML file;
- detect incorrect double nesting of the mod folder;
- confirm documentation does not instruct users to use absent files or features;
- ensure no-scripts and Vortex packages contain no prohibited executable-style files;
- simulate manual copying into a disposable fake `Mods` folder;
- verify that the documented removal target is only this mod folder.

All temporary deletion must remain guarded so it cannot escape the system temp directory.

### 5. CI Validation

Add a GitHub Actions workflow appropriate for this Windows/PowerShell project. On pushes and pull requests it should perform all checks that do not require a locally installed commercial game.

Requirements:

- use least permissions, normally read-only repository contents;
- pin action versions to stable major releases or immutable commits according to repository policy;
- parse PowerShell and XML;
- validate the manifest and documentation;
- inspect committed archive shapes without mutating historical artifacts;
- run offline smoke tests;
- clearly report checks skipped because live game files are unavailable;
- never upload to Nexus, create releases, push commits, or hide files.

If live-baseline validation cannot run in CI, separate it cleanly from offline validation rather than weakening or faking it.

### 6. Compatibility Matrix

Add a concise, human-readable compatibility document generated from or checked against the manifest. Cover:

- exact game build status;
- Windows client;
- dedicated server;
- Linux status if untested;
- Steam and non-Steam layouts;
- manual installation;
- Vortex/mod-manager status;
- EAC expectations;
- overhaul and overlapping XML-mod status.

Use evidence labels from `governance/PRIVATE_TEST_PROGRAM.md`. Do not use a generic check mark for unverified environments.

### 7. Conflict Target Inventory

Create a machine-readable inventory of the XML patch targets owned by the solution. Prefer deriving it from the actual packaged XML during validation. At minimum, report:

- source XML filename;
- operation type;
- XPath;
- affected biome/entity group;
- whether another mod targeting the same node may combine, override, or conflict.

Do not claim definitive load-order outcomes without field evidence.

### 8. Support, Security, And Accessibility Baselines

Add concise standards or templates covering:

- troubleshooting decision tree;
- privacy-safe diagnostic collection;
- known-issues structure;
- files read, written, copied, backed up, restored, and deleted;
- network, telemetry, privilege, process-launch, and log-retention behavior;
- keyboard access, readable type, contrast, non-color status cues, plain-language warnings, and copyable errors for future front ends.

Reuse existing documentation where possible. Avoid duplicating long passages that will drift.

### 9. Release Acceptance Record

Add a reusable template containing:

```text
Version:
Source commit:
Supported/tested game build:
Validation result:
Field-test result:
Known release risks:
Rollback verified:
Archive hashes:
Approved for publication by:
Publication date:
```

The validator may create a draft, but it must never invent owner approval or publication status.

## Engineering Standards

- Use `apply_patch` for repository edits.
- Prefer small, readable PowerShell functions with actionable failure messages.
- Keep offline checks runnable without 7 Days to Die installed.
- Keep live-game validation available as an explicit additional stage.
- Use ordinal or clearly defined sorting when producing deterministic inventories.
- Normalize archive paths to `/` in reports and validation.
- Parse structured files instead of relying only on regular expressions.
- Do not silently rewrite user-authored documents or historical archives.
- Do not add dependencies unless they provide clear value and are documented.
- Do not add telemetry or network calls to mod tools.

## Required Tests

At minimum, demonstrate:

1. PowerShell parser success for every `.ps1` file.
2. XML parse success for source and packaged XML.
3. Manifest schema/field validation.
4. Offline archive validation for all committed archive types.
5. A deliberate missing-entry fixture or temporary mutation is rejected.
6. A deliberate prohibited-extension fixture is rejected for no-scripts packaging.
7. A deliberate documentation reference to an absent launcher is rejected.
8. Development version handling passes on `develop/4.1.0`.
9. Final-release consistency mode rejects mismatched versions.
10. `git diff --check` passes.

Do not modify the committed `4.0.1` archives to create negative tests. Use temporary fixtures.

## Acceptance Criteria

The assignment is complete when:

- CI can enforce all offline guarantees on a clean clone;
- live-game checks remain explicit and cannot be mistaken for completed CI checks;
- one manifest drives or verifies release identity and package policy;
- every archive receives post-build inspection;
- checksums and inventories are produced outside archives;
- compatibility claims show their evidence level;
- conflicts and operational effects are discoverable;
- a release candidate cannot pass while versions disagree;
- the current historical `4.0.1` tag and archives are unchanged;
- documentation explains how maintainers run the checks;
- all changes are recorded under `4.1.0 - Unreleased` in the solution changelog.

## Publication Boundary

This packet authorizes repository implementation and local/offline verification only. It does not authorize:

- merging to `main`;
- creating a public release tag;
- uploading files to Nexus;
- changing Nexus metadata;
- hiding or archiving the current Nexus file;
- claiming public compatibility or owner approval.

Commit and push to `develop/4.1.0` only if the user has asked for repository changes to be published there and the working tree is clean after verification. Otherwise, leave a clear local handoff.

## Final Report Format

Report:

- outcome first;
- files added or materially changed;
- guarantees now enforced;
- tests run and their exact results;
- checks skipped and why;
- unresolved risks or decisions;
- current branch, commit, and working-tree state;
- the next safest action requiring owner approval.
