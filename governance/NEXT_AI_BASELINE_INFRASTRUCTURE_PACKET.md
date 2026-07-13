# Next AI Work Packet: 4.1.0 Baseline Infrastructure

## Mission

Strengthen the Nexus mod workshop baseline so reliability, evidence, reversibility, and readable user support are enforced by software rather than dependent on memory.

This is infrastructure work for the backward-compatible `4.1.0` development line. Do not add speculative gameplay features during this assignment.

### Current Owner Scope Override — 2026-07-12

The owner has declared the current technical package QA-complete and frozen for the `4.1.0` baseline. Do not refactor or alter runtime, gameplay, GUI, install/remove, cap-management, or modlet behavior while executing this packet. Technical hardening tasks in this older packet are retained as future backlog, not current authority.

Current work is limited to non-behavioral release infrastructure: identity/version metadata, documentation, licensing, manifests, artifact quarantine, safe staging/packaging, non-mutating validation, checksums/provenance, evidence, GitHub health, and release controls. Read `governance/OWNER_DECISION_INTERVIEW.md` and the scope override in `governance/NEXT_AI_DEEP_REPO_AUDIT_ADDENDUM.md` before selecting a task.

Use the owner's preparation-dominant sequence: finish and reconcile the baseline identity, manifests, instructions, edition allowlists, version map, acceptance checklist, and evidence templates before candidate execution. Do not repeatedly rebuild by trial and error. After the planning gate is approved, perform one controlled candidate/promotion cycle; no build step grants publication authority.

Q12 locks the primary customer ZIP to three top-level items: `README_FIRST.txt`, `7DTD_WastelandAnimalTuning.bat`, and `Support_Files_Do_Not_Edit/`. Build it from an exact allowlist; never stage `Upload_To_Nexus`, publishing-only assets, candidate archives, validators, or raw maintainer evidence into the customer download. The internal support-folder allowlist remains subject to recorded owner decisions, including Q13.

## Start Here

Read these files completely before making changes:

1. `AGENTS.md`
2. `README.md`
3. `VERSION`
4. `RELEASING.md`
5. `governance/PRIVATE_TEST_PROGRAM.md`
6. `governance/PROJECT_MANIFEST.md`
7. `governance/NEXT_AI_DEEP_REPO_AUDIT_ADDENDUM.md`
8. `solutions/README.md`
9. This packet
10. The active solution's `PACKAGE_METADATA.md`, `TECHNICAL_FILE_MANIFEST.md`, `CHANGELOG.md`, and validation script

Active solution root:

```text
solutions/7dtd_wasteland_animal_population_tuning_files/
```

## Repository State At Handoff

- The public baseline is preserved by annotated Git tag `v4.0.1`.
- Development occurs on `develop/4.1.0`.
- Root `VERSION` is `4.1.0-dev`.
- Q11 anchors the owner-QA-approved solution baseline at commit `b3c3551c0c5bfc8d24c68d3036da4c8045a90b54`, solution Git tree `010454d19b10f46c71d9150335905766b946176e`; capture a per-file SHA-256 manifest before authorized solution-file preparation.
- The published `4.0.1` archives are historical artifacts and must remain byte-for-byte unchanged during this assignment.
- The no-scripts `4.1.0` source manuals are under:

```text
Support_Files_Do_Not_Edit/Nexus_NoScripts/
```

- `validate_and_package.ps1` contains initial construction and validation support for the no-scripts archive.
- Nexus support may inspect this repository. Do not commit private tester data, credentials, machine identifiers, or internal conversation transcripts.

Confirm the branch and clean working tree before starting. If unexpected user changes exist, preserve them and report any overlap.

The deep-audit addendum contains the current dependency order and confirmed repository defects. Follow its slices first; use this packet as the detailed requirement catalog. Do not implement duplicated files or workflows merely because both documents mention them.

## Governing Intent

Implement the spirit of mature vendor software delivery without adding ceremonial paperwork. The result must expose the twelve facets in `PROJECT_MANIFEST.md`: identity, provenance, scope, compatibility, lifecycle, safety, reversibility, evidence, integrity, supportability, ownership, and restraint.

Maintain three consistent views of one release:

1. a short player guide;
2. a detailed support and operations guide;
3. a machine-readable manifest and evidence report.

The Nexus/vendor view needs review evidence. The player/customer view needs a predictable path. Do not force either audience to reconstruct facts from the other audience's documentation.

## Execution Slices For A Mid-Sized Model

Complete these slices in order. Stop after a slice if its verification fails. Do not begin several broad rewrites at once.

### Slice 0: Orient And Protect

Goal: prove the historical baseline will not be changed accidentally.

Actions:

1. Read every required file in the stated order.
2. Confirm branch `develop/4.1.0` and inspect the working tree.
3. Record the current SHA-256 hashes of all committed `4.0.1` archives in temporary test output.
4. Identify which checks require a live commercial-game installation and which can run offline.

Pass condition: repository state is understood, user changes are preserved, and historical hashes are recorded without editing archives.

### Slice 1: Define Release Identity

Goal: create one structured identity and policy record.

Actions:

1. Add the machine-readable release manifest described in Deliverable 1.
2. Represent unknown exact game-build data as unknown, never guessed.
3. Document authoritative versus mirrored fields.
4. Add schema and semantic validation.

Pass condition: malformed, incomplete, or contradictory manifest fixtures fail with actionable messages.

### Slice 2: Enforce Version Truth

Goal: prevent inconsistent public identity.

Actions:

1. Implement distinct development and final-release validation modes.
2. Compare all release-facing version sources.
3. Confirm `4.1.0-dev` can coexist with untouched `4.0.1` historical archives.
4. Add mismatch tests using temporary fixtures.

Pass condition: development validation passes and final-release mode rejects any disagreement.

### Slice 3: Make Artifacts Inspectable

Goal: make every archive explainable to Nexus.

Actions:

1. Generate external inventories and SHA-256 hashes.
2. Record source commit and package identity.
3. Normalize paths and sorting.
4. Keep all reports outside their subject archives.

Pass condition: two reports over identical inputs have identical stable content except fields explicitly labeled operational.

### Slice 4: Test The Downloaded Product

Goal: test what the customer receives rather than only source files.

Actions:

1. Extract each archive to guarded temporary storage.
2. Validate shape, nesting, XML, prohibited files, and package-specific instructions.
3. Simulate manual install and narrowly scoped removal.
4. Add negative temporary fixtures.

Pass condition: valid packages pass and each required corruption is rejected without changing historical archives.

### Slice 5: Add Upgrade And Recovery Semantics

Goal: make repeat use and failure recovery predictable.

Actions:

1. Define fresh install, reinstall, upgrade, downgrade, removal, and restore behavior.
2. Test idempotency: repeating safe operations yields the same state.
3. Define handling for user-modified files and interrupted writes.
4. Prefer staged writes and atomic replacement where practical.
5. Define backup naming, validation, retention, ownership, and damaged-backup behavior.

Pass condition: every state-changing operation has a tested success, repeat, failure, and recovery path.

### Slice 6: Express Compatibility And Conflicts

Goal: keep support claims evidence-based.

Actions:

1. Add the compatibility matrix.
2. Derive the XML conflict-target inventory.
3. Apply verified, observed, expected, unsupported, or unverified labels.
4. Define operational limits for extreme settings without inventing performance numbers.

Pass condition: no broad compatibility claim lacks an evidence label or source.

### Slice 7: Make Support Operational

Goal: make failures recognizable and reportable.

Actions:

1. Add `SECURITY.md` with private reporting guidance and supported-version scope.
2. Define a stable error-code catalog with cause, consequence, corrective action, and state-change status.
3. Add privacy-safe diagnostics, known-issue structure, and troubleshooting routing.
4. Map requirements and risks to test IDs and evidence.

Pass condition: a tester can report a failure precisely without sharing private machine or account data.

### Slice 8: Make Builds Reproducible

Goal: rebuild the same source into byte-identical archives where tooling permits.

Actions:

1. Replace or control nondeterministic ZIP behavior.
2. Use stable entry ordering, normalized paths, defined compression, and normalized timestamps.
3. Derive a source timestamp from version-controlled history or a documented `SOURCE_DATE_EPOCH` input.
4. Build twice in clean temporary locations and compare SHA-256 values.
5. Document any remaining reproducibility limitation honestly.

Pass condition: consecutive clean builds match byte-for-byte, or a precise blocker and bounded fallback are documented.

### Slice 9: Add CI And Provenance

Goal: enforce offline policy and connect release artifacts to source.

Actions:

1. Add least-privilege GitHub Actions validation.
2. Keep live-game checks separate and visibly skipped in CI.
3. Add build provenance or GitHub artifact attestation for actual release artifacts when the repository/channel supports it.
4. Provide verification instructions and state that provenance proves origin, not safety.

Pass condition: CI validates a clean clone without secrets or commercial game files and cannot publish autonomously.

### Slice 10: Complete Lifecycle And Acceptance

Goal: make release status and authority unambiguous.

Actions:

1. Define Development, Private Test, Release Candidate, Supported, Maintenance, Superseded, and Archived states.
2. Define upgrade/support expectations for each state.
3. Add the release acceptance record and owner-approval boundary.
4. Check agreement among the player, operations, and machine-readable views.

Pass condition: automation can prepare evidence but cannot invent approval, support status, or publication.

### Slice 11: Establish GitHub Repository Health

Goal: make repository intent visible and enforceable without importing unnecessary large-project ceremony.

Repository-file actions:

1. Add a root GitHub-recognizable license file consistent with the existing GPL-3.0-or-later package license.
2. Add `SECURITY.md` with a private reporting route, supported-version scope, acknowledgment expectations, and instructions not to disclose sensitive details publicly.
3. Add a concise `CONTRIBUTING.md` covering branch/PR workflow, testing, documentation, privacy, licensing, and owner approval.
4. Add a proportionate `CODE_OF_CONDUCT.md` and enforcement/contact route without inventing an organization or committee.
5. Add `.github/PULL_REQUEST_TEMPLATE.md` with purpose, effects, compatibility assumptions, tests, rollback, risk, and release-impact fields.
6. Add structured issue forms for bugs and compatibility reports with privacy warnings and required environment/version details.
7. Add `CODEOWNERS` assigning actual known ownership only; do not invent reviewers or teams.
8. Add the least-privilege offline validation workflow from Slice 9.
9. Add documentation explaining the chosen merge strategy and release path.

GitHub-setting audit actions:

1. Inspect, but do not assume, current rulesets, branch protection, tag protection, merge settings, security features, and release immutability.
2. Record each setting as verified enabled, verified disabled, unavailable, or unknown.
3. Recommend a `main` ruleset requiring pull requests and successful validation, blocking force pushes and deletion, and applying to administrators unless the owner explicitly chooses a documented emergency bypass.
4. Recommend protection for `v*` release tags against rewriting or deletion.
5. Recommend one normal merge strategy; squash merge is a reasonable default for this small repository, but the owner must choose.
6. Recommend secret scanning, push protection, Dependabot/security alerts, and immutable releases where available and proportionate.
7. Do not mutate repository settings without explicit owner authorization.

Workflow actions:

1. Use pull requests for material changes intended for `main`.
2. Keep `develop/4.1.0` as development evidence until release acceptance is complete.
3. Ensure CI status is visible on the pull request.
4. Keep live-game validation separate from offline CI and record it in the release acceptance evidence.
5. Connect official release artifacts to their exact source commit, tag, checksums, and provenance.

Pass condition: GitHub's repository front door exposes the project's license, ownership, contribution, conduct, security, issue, PR, and validation paths; all platform settings are evidence-labeled; and no AI-only action is mistaken for owner approval or live-game proof.

### Slice 12: Model Threats, Failures, And Tool State

Goal: make local failure and misuse behavior explicit without importing irrelevant cloud-scale controls.

Actions:

1. Create a concise threat model for downloaded package identity, paths, owned directories, XML, backups, junctions/symlinks, other mods, privileges, and diagnostics.
2. Create failure-mode records for install, reinstall, tune, backup/cap change, restore, remove, and packaging.
3. Define the operational state model used by the front end and diagnostics.
4. Map each important threat or failure to prevention, detection, recovery, and a test or explicit unverified status.
5. Verify deletion and restoration cannot escape the intended game instance and owned paths.

Pass condition: every state-changing flow has a bounded target, failure detection, recovery behavior, and evidence route.

### Slice 13: Harden Windows And PowerShell Behavior

Goal: make the helper tooling predictable across supported Windows conditions and usable without a mouse.

Actions:

1. Run PSScriptAnalyzer in CI and document any narrow suppression.
2. Add `ShouldProcess`/`-WhatIf` and confirmation semantics where appropriate for command-line or maintainer state changes.
3. Standardize terminating versus recoverable errors, exit codes, and stable error identifiers.
4. Test non-ASCII and special-character paths, XML encoding, locale-sensitive numeric handling, restricted permissions, and Windows PowerShell 5.1.
5. Test keyboard-only operation, tab order, visible focus, accessible control names, high contrast, display scaling, non-color status, and screen-reader-readable errors.
6. Record automated accessibility inspection plus a manual keyboard and Narrator/assistive-technology release check.

Pass condition: supported Windows scenarios and accessibility behaviors have recorded evidence, and destructive or sensitive command-line actions can be previewed where practical.

### Slice 14: Define Rollout, Hotfix, And Learning

Goal: control exposure and learn from field failures.

Actions:

1. Define entry, observation, stop, rollback, and owner-approval conditions for sandbox, single tester, varied private group, release candidate, Nexus upload, and archive transition.
2. Require inspection of the newly served Nexus file before archiving the prior one.
3. Define emergency pause, warning, rollback, roll-forward, and patch-release criteria.
4. Identify safety checks that may never be skipped during a hotfix.
5. Add a concise blameless incident-learning template covering impact, detection, contributing conditions, correction, prevention, tests, and documentation.

Pass condition: normal and emergency releases have bounded authority, stop conditions, recovery, and retained learning.

### Slice 15: Final Audit

Goal: prove the new infrastructure did not damage the baseline.

Actions:

1. Run all offline tests and `git diff --check`.
2. Recompute historical archive hashes and compare them with Slice 0.
3. Review documentation for vendor/customer separation and progressive disclosure.
4. Record live checks still pending.
5. Update the `4.1.0 - Unreleased` changelog.

Pass condition: all offline gates pass, historical archives are byte-identical, pending live evidence is explicit, and the working tree contains only intended changes.

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

### 10. Upgrade, Recovery, And Backup Contract

Define and test:

- fresh install, repeat install, upgrade, downgrade, removal, and restore;
- behavior when files were edited by the user or another tool;
- detection and recovery from interrupted operations;
- staged or atomic replacement for sensitive writes where practical;
- backup naming, location, retention, ownership, validation, and cleanup;
- refusal to restore a backup belonging to a different game/server instance;
- behavior when the newest backup is missing or damaged.

### 11. Support Lifecycle

Define these states and the gates between them:

```text
Development -> Private Test -> Release Candidate -> Supported
            -> Maintenance -> Superseded -> Archived
```

For each state, specify intended audience, distribution channel, testing expectation, support promise, upgrade policy, and publication authority.

### 12. Security Reporting And Error Catalog

Add a root `SECURITY.md` defining private vulnerability reporting, supported versions, acknowledgment expectations, responsible disclosure, and what not to post publicly.

Define stable error identifiers. Each error record must include:

- identifier;
- trigger/cause;
- user-visible consequence;
- whether state changed;
- corrective action;
- diagnostic evidence safe to share.

### 13. Reproducible Builds And Provenance

Target byte-identical archives from identical source by controlling entry ordering, path format, compression settings, and timestamps. Use a documented source-derived timestamp such as `SOURCE_DATE_EPOCH` where appropriate. Verify reproducibility by comparing two clean builds.

For release artifacts, plan provenance or artifact attestations that connect the digest to the repository, commit, workflow, and builder. Explain that provenance establishes origin and build identity; it does not guarantee that software is defect-free or safe.

### 14. Requirements-To-Test Traceability

Create a small traceability record:

```text
Requirement -> Risk -> Test ID -> Evidence -> Release status
```

Every material safety, compatibility, integrity, and rollback promise must have a test or an explicit unverified status.

### 15. Operational Limits

Document allowed ranges, hard blocks, warnings, and tested limits for high-load features. Do not invent performance thresholds. Identify which limits protect correctness, which protect recoverability, and which are conservative field guidance.

### 16. GitHub Repository Health Contract

Create and maintain:

- root license, security, contribution, and conduct files;
- pull-request and privacy-safe issue templates;
- actual ownership declarations;
- offline CI as a required release signal;
- a documented merge and release workflow;
- an evidence-labeled audit of branch/tag protection, rulesets, security features, merge settings, and release immutability.

Keep five kinds of proof distinct: committed policy, automation result, review history, release identity, and field validation. A mature repository turns as much policy as practical into enforced checks while leaving publication and compatibility approval with the owner.

### 17. Threat And Failure Contract

Maintain a proportionate local threat model, critical-flow failure analysis, and operational state model. Cover package substitution, unsafe paths, junctions/symlinks, malformed XML, partial writes, permission failures, conflicts, damaged backups, and diagnostic privacy where applicable.

Every meaningful failure record must identify detection, impact, whether state changed, mitigation, recovery, and test evidence. Success requires read-back verification; unknown or partial state must never be presented as success.

### 18. Safe Rollout And Incident Contract

Use progressive exposure from maintainer sandbox through private testing and release candidate to a verified Nexus upload. Define observation windows, stop conditions, rollback triggers, and owner approval. Verify the served new file before archiving the previous one.

For hotfixes, never skip identity, scope-safety, XML validation, archive inspection, rollback evidence, or owner approval. Use blameless incident records to convert failures into safeguards and regression tests.

### 19. Windows And Accessibility Contract

Use PSScriptAnalyzer, meaningful PowerShell error semantics, and preview/confirmation behavior where practical. Test supported PowerShell versions, encoding, locale, unusual paths, restricted permissions, keyboard access, accessible names, high contrast, scaling, non-color status cues, and screen-reader-readable errors.

Treat accessibility and environment compatibility as test evidence, not an assumption.

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
