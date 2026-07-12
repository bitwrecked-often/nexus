# Project Manifest: Reliable Nexus Mod Infrastructure

## Purpose

This repository turns small, field-derived mod ideas into open-source packages that Nexus can review and players can understand, verify, use, and remove safely.

The project is intentionally modest in size and professional in control. It does not imitate enterprise paperwork for appearance. It adopts the parts of mature software practice that make identity, behavior, evidence, and rollback clear.

## Governing Promise

Reliable first, feature-rich second.

If a feature cannot be explained, verified, supported, and reversed, it is not ready to ship.

## The Twelve Facets

Every solution and release must make these facets visible.

### 1. Identity

State the package name, stable ID, version, source commit, release channel, and artifact names. Never distribute different content under the same identity.

### 2. Provenance

Record where the artifact came from, which source and workflow produced it, and how a reviewer can connect the download to that source.

### 3. Scope

State exactly what the package reads, writes, copies, backs up, restores, and deletes. State what it never touches.

### 4. Compatibility

Separate verified, observed, expected, and unsupported environments. Do not turn a reasonable expectation into a tested claim.

### 5. Lifecycle

Label work as Development, Private Test, Release Candidate, Supported, Maintenance, Superseded, or Archived. Each state must have an understood audience and support promise.

### 6. Safety

Use conservative defaults, validate targets, preview sensitive changes, warn about real consequences, fail safely, and keep extreme options separate.

### 7. Reversibility

Define installation, upgrade, downgrade, removal, configuration restoration, backup ownership, and recovery from interrupted operations.

### 8. Evidence

Classify claims as verified, observed, inferred, or unverified. Connect important requirements and risks to tests and retained evidence.

### 9. Integrity

Provide archive inventories, cryptographic checksums, deterministic builds where practical, and provenance or attestations appropriate to the release channel.

### 10. Supportability

Provide recognizable error identifiers, corrective actions, known issues, a troubleshooting path, and privacy-safe diagnostic instructions.

### 11. Ownership

State who may approve publication and which source, tags, channels, and artifacts are official. Automation and AI must never invent approval.

### 12. Restraint

Avoid hidden behavior, unnecessary privileges, unsolicited network access, telemetry, persistence, obfuscation, unrelated files, and unsupported promises.

## Two Audiences

### Vendor View: Nexus And Reviewers

The vendor view must make review efficient:

- exact archive contents;
- source commit and build identity;
- checksum and provenance;
- license and redistribution terms;
- script, process, privilege, network, and telemetry behavior;
- file-system effects and rollback;
- package-specific documentation;
- immutable release history;
- validation and known limitations.

### Customer View: Players And Server Operators

The customer view must make operation predictable:

- requirements first;
- a short, correct installation path;
- plain-language effects and limits;
- confirmation that installation worked;
- conflict and performance warnings;
- safe removal and restoration;
- recognizable troubleshooting steps;
- honest support boundaries.

Neither audience should need to reverse-engineer documentation written for the other.

## Three Views Of One Truth

Every public release should present the same facts through three layers:

1. **Player quick guide** — the shortest safe path to install, verify, and remove.
2. **Support and operations guide** — requirements, compatibility, conflicts, security behavior, upgrade, recovery, troubleshooting, and evidence.
3. **Machine-readable manifest and release evidence** — identity, policy, archive inventory, checksums, test results, and provenance.

Automation must check that these layers agree on identity, requirements, behavior, and available features.

## Repository Shape

```text
Governance
+-- Identity and lifecycle
+-- Security and privacy
+-- Build and provenance
+-- Release acceptance
+-- Support policy

Solutions
+-- User need
+-- Supported environment
+-- Mod payload
+-- Front-end safety
+-- Validation evidence
+-- Install and rollback
+-- Release packet
```

Governance defines the gates. Solutions provide the implementation and evidence. A solution does not bypass governance because it is small or because it worked once.

## Progressive Disclosure

Put the smallest useful instruction first and deeper evidence behind it. Completeness does not mean forcing every player to read every technical detail. It means every important fact exists at the right layer and remains consistent across layers.

## GitHub Repository Health

Repository health is part of the product's evidence surface. Policies written in prose express intent; GitHub controls, pull requests, checks, releases, and community files demonstrate that the intent is practiced.

The repository should make these facts visible from its front door:

- purpose, current lifecycle state, and supported scope;
- open-source license recognized at repository root;
- contribution and conduct expectations appropriate to the project's size;
- private security-reporting route and supported-version policy;
- ownership and review responsibility;
- issue and compatibility-report intake that protects private data;
- pull-request evidence for material changes;
- required offline validation before changes reach `main`;
- protected release branches and `v*` tags where GitHub capabilities permit;
- official releases connected to source, checksums, and provenance;
- an explicit distinction between repository evidence and claims that still require live-game testing.

For a small owner-led project, lightweight controls are appropriate. One accountable owner approval may be sufficient. The project should not copy large-organization ceremony, but it should preserve the mature pattern that support level, ownership, checks, and evidence are explicit.

### Evidence Versus Inference

Use these distinctions during repository-health reviews:

- **Policy evidence:** a committed document states the intended rule.
- **Automation evidence:** a check demonstrates that a technical rule passed.
- **Review evidence:** a pull request records scope, discussion, approval, and status checks.
- **Release evidence:** an immutable tag/release connects source to published artifacts.
- **Platform evidence:** GitHub settings enforce branch, tag, security, or merge policy.
- **Field evidence:** testing proves behavior in the supported game environment.

Never report a policy as enforcement, a successful CI run as live-game compatibility, or an uninspected GitHub setting as enabled. Unknown settings remain unknown until verified.

### Recommended Delivery Path

```text
development branch
        |
        v
pull request + offline CI
        |
        v
owner review + release acceptance
        |
        v
protected main + protected version tag
        |
        v
release artifacts + checksums + provenance
        |
        v
manual live-game evidence and Nexus approval
        |
        v
new Nexus file verified before prior file is archived
```

Automation may prepare and prove artifacts. It must not publish to Nexus, approve its own release, hide an older file, or convert unknown compatibility into a supported claim.

## Definition Of Infrastructure

This project has moved from experimentation to infrastructure when actions have visible state, predictable results, bounded effects, tested recovery, and enough evidence to explain what happened under ordinary field conditions.

The intended public signal is:

> This is a small community project with professional control over identity, behavior, evidence, and rollback.
