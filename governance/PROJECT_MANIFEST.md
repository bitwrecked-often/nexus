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

`Vendor` and `customer` are documentation lenses. They do not claim a contractual Nexus partnership, certification, endorsement, paid relationship, or warranty.

## Three Views Of One Truth

Every public release should present the same facts through three layers:

1. **Player quick guide** — the shortest safe path to install, verify, and remove.
2. **Support and operations guide** — requirements, compatibility, conflicts, security behavior, upgrade, recovery, troubleshooting, and evidence.
3. **Machine-readable manifest and release evidence** — identity, policy, archive inventory, checksums, test results, and provenance.

Automation must check that these layers agree on identity, requirements, behavior, and available features.

### Public Surface Priority

When space, attention, or complexity compete, present information in this order:

1. **Respect the user** — purpose, requirements, safe operation, verification, removal, recovery, and help in plain language.
2. **Respect the field** — applicable GPL, Nexus/vendor, security, archive, evidence, and ecosystem obligations stated accurately and proportionately.
3. **Identify the source** — authorship, official-project identity, support route, and restrained branding in the surface that remains.

This is a presentation hierarchy, not a hierarchy of legal authority. Mandatory copyright/license notices, artifact identity, and safety warnings remain. Branding must not crowd out operation or compliance, while user-friendliness must not hide material risks or license duties.

## Artifact Truth And Usefulness

Every public artifact is its own product contract. Its name, description, documentation, payload, behavior, license, and support status must agree.

- A package must not advertise controls, files, automation, or outcomes it does not contain.
- A gameplay package must provide the advertised gameplay outcome on its supported baseline, or identify itself honestly as a baseline, template, source, or documentation artifact.
- Full helper, no-scripts, modlet-only, source, and publishing editions may have different capabilities and policies; model them separately.
- An edition named for a third-party manager makes an integration claim and must pass a versioned install, enable, verification, disable, and removal audit before publication.
- Validate packaged content against authoritative staged source byte-for-byte.
- Preserve historical defects as evidence, but never use them as the contract for a new release.
- Reproducibility and provenance are evidence claims. Immutability alone does not prove either.

### Scanner-Friendly Inspection Surface

When a supported no-scripts edition exists so a distributor or reviewer can inspect gameplay intent:

- its intended changes must be understandable from readable payloads and plain-language documentation without executing code;
- it must contain no executable-style files and must not instruct users to run controls, scripts, or paths absent from that edition;
- its outcome, requirements, identity, license, installation, verification, removal, and support boundaries must form a complete product contract;
- an exact file allowlist, archive inventory, source comparison, and checksum must support static review;
- scanner friendliness does not excuse a vanilla no-op, misleading outcome, or incomplete player package;
- optional Nexus placement does not reduce support obligations, while the primary file should match the primary customer journey;
- platform handling must be recorded as dated evidence for the specific artifact, not generalized into an undocumented permanent policy.

### Minimal Customer Archive Surface

Build customer downloads from exact allowlists rather than repository folders:

- expose the smallest understandable top level that preserves supported operation;
- keep publishing assets, upload notes, validators, raw QA/build material, candidate archives, and maintainer metadata in the repository or release evidence, not the customer package;
- include only runtime/UI dependencies, applicable licensing, and user-facing instructions/support material;
- keep advanced or alternate tools in source or a separately contracted optional artifact when they are not part of the primary customer journey;
- use a standard non-password-protected archive with no nested archives;
- test the staged archive as extracted, including relative-path dependencies and the first-run customer journey;
- treat the exact layout as a project design justified by vendor guidance, not as a Nexus-mandated structure or endorsement.

### Copyleft-Complete Minimal Packaging

Minimal packaging must remove customer-irrelevant material without removing the freedoms or source promised by GPL-3.0-or-later:

- treat license compliance as a per-edition release gate; a license file elsewhere in the repository does not make an incomplete download acceptable;
- retain the preferred editable form of the distributed work. For the current primary package, that means the BAT launcher, PowerShell GUI source, and XML modlet source—not only generated output;
- include the complete applicable GPL text in every distributed edition and preserve applicable copyright, SPDX/license, modification, and no-warranty notices;
- identify the exact public source version and official project source/support location in release-facing documentation and external evidence;
- keep plain-language summaries faithful to the GPL and subordinate to the full license text;
- do not add restrictions on use, copying, modification, or redistribution. Origin, trademark, and support wording may distinguish official releases from downstream modifications, but must not withdraw GPL permissions;
- treat official archive names, folder names, allowlists, and support boundaries as project build/test policy—not conditions that downstream recipients must preserve when exercising GPL rights;
- review each excluded build, packaging, or maintainer file against the GPL definition of Corresponding Source rather than assuming that every repository file belongs in—or outside—the customer archive;
- if a future edition distributes object code, add and validate a GPL-compliant corresponding-source path before publication.

Record every distributed non-code asset in `ASSET_PROVENANCE.md`. Ownership, public use as a brand, copyright license, trademark treatment, and preferred editable source are separate fields; evidence for one must not be silently treated as evidence for the others.

For the Q14/Q16 primary `4.1.0` package, the accepted eight-file source-form allowlist is:

```text
README_FIRST.txt
7DTD_WastelandAnimalTuning.bat
Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1
Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml
Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml
Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/spawning.xml
Support_Files_Do_Not_Edit/LICENSE.txt
Support_Files_Do_Not_Edit/CHANGELOG.md
```

The executable portion is readable source form. Q16 supersedes Q14's planned avatar inclusion and removes that optional decorative personalization from the future primary customer ZIP so the package can move more cleanly between domains. The avatar remains intact in repository history and the immutable `4.0.1` archive. The README/changelog license scope and plain-language license/use notice consolidation into `README_FIRST.txt` remain open. The allowlist authorizes planning and validation rules, not a candidate build or a runtime change.

Cross-domain portability does not silently erase authorship, copyright notices, stable technical identifiers, or official-release provenance. Q17 locks the `4.1.0` boundary: remove only the optional avatar while preserving existing Bit Wrecked legal identity, UI text, mod/folder IDs, install/remove targets, backup names, and diagnostics. Portability comes from readable GPL source and a reusable boundary, not from presenting the official package as anonymous. A domain-neutral or white-label derivative is future feature work with its own identity, migration, tests, and owner approval.

Q18 applies the public-surface priority to the primary README: one concise customer document carries the plain-language GPL freedoms and duties, exact source route, no-warranty statement, and unofficial-origin notice. The complete `LICENSE.txt` and source-file notices remain authoritative and intact. Separate maintainer-oriented legal/use notes stay in the repository rather than increasing customer-package friction.

Q19 licenses both primary customer documents—`README_FIRST.txt` and `CHANGELOG.md`—under `GPL-3.0-or-later`. Their text/Markdown files are their preferred editable source. Carry explicit Bit Wrecked copyright and SPDX notices in both, preserve the complete GPL in the artifact, and require downstream distributed modifications to retain the license and identify changes. This decision is scoped to those solution documents; it does not silently select a license for every governance or repository file.

### Final-Upload Promotion Boundary

Future final archives are release outputs, not source-controlled inputs. Preserve the committed `4.0.1` ZIPs as grandfathered immutable evidence, but do not commit new generated ZIPs to Git history.

Use this logical ignored layout after the planning gate:

```text
dist/<solution-id>/<version>/
|-- candidate/       temporary build and reproducibility outputs
|-- final-upload/    only the exact files approved for upload
`-- evidence/        generated checksums, inventories, and provenance
```

Requirements:

- generate the version/solution directories from authoritative manifest identity rather than hand-typed aliases;
- keep all of `dist/` ignored by Git and prohibit builds from targeting committed historical paths;
- clear or reject stale/mixed-version content before candidate construction;
- validate candidates completely before atomic promotion into `final-upload/`;
- allow only versioned, variant-qualified, checksum-recorded publishable archives in `final-upload/`; never place tools, logs, notes, source folders, or historical ZIPs there;
- treat `dist/.../evidence/` as ignored working output; copy only a sanitized durable release record to tracked `evidence/releases/<solution-id>/<version>/`;
- commit that checksum/inventory/provenance record and attach approved final ZIPs to the corresponding GitHub Release instead of committing the ZIP bytes;
- preserve the release attachment and Nexus-served artifact references in the durable record after publication;
- treat presence in `final-upload/` as technical readiness only. It does not grant merge, tag, GitHub Release, Nexus upload, or prior-file archival authority.

Q21 decides whether one checksum-verified staged byte sequence must be used unchanged for both GitHub and Nexus.

### Wrapper As A Composable Feature-Set Boundary

When a solution accepts independently selectable feature inputs, treat its wrapper as the composition boundary rather than recasting its outputs as mutually exclusive preset packages:

- players receive understandable controls or ready-made choices with a safe generation, installation, verification, and removal path;
- modders can use the wrapper as-is and attach it to broader feature-set work through a documented boundary;
- the wrapper resolves shared values and interactions before emitting one coherent installed result;
- feature inputs, resolution rules, generated payloads, and evidence remain traceable without reverse engineering;
- generated XML is a composed result and must not be mislabeled as though it always came from one exclusive preset;
- every user-facing and modder-facing entry point must use the same authoritative composition rules;
- a testable non-GUI core is not automatically a supported public CLI, API, SDK, or integration product;
- the casual-player interface may remain the primary supported experience while modder tooling matures separately;
- downstream reuse does not guarantee compatibility, vendor endorsement, official-project status, or upstream support for a modified package.

## Multi-Solution Identity

This repository may contain many mods. Each solution owns its version, lifecycle, compatibility, Nexus identity, artifacts, evidence, and release manifest. Repository governance and schema versions are separate from mod versions.

Shared indexes and validators locate and check solution manifests; they do not become a competing global product version. Future branch and tag conventions must avoid collisions across solutions while explicitly grandfathering existing historical identities.

## Documentation Authority

Classify documents as authoritative current source, generated mirror, historical evidence, or retired. Define precedence and generate or validate duplicated facts.

Current filesystem, Git, and artifact evidence overrides a stale handoff statement. Contradictions must be recorded and resolved from evidence or owner direction, not silently harmonized by an AI.

Keep governance/infrastructure history separate from the player-facing solution changelog. Players need payload, packaging, compatibility, install, upgrade, support, and known-issue changes; maintainers need process and governance history.

## Chain Of Custody For Ideals

Preserve how important product and engineering decisions formed. A decision record should connect the original field observation or risk to the governing ideal, owner answer, implementation, tests, artifact, and eventual release claim.

This record exists so users, reviewers, and other makers can study the method, reproduce the reasoning, challenge assumptions, and adapt the work without relying on oral history. Show enough work to make the project useful research while excluding private conversations, tester identities, machine data, and irrelevant personal material.

If a later decision changes an earlier one, retain both and link the superseding relationship. Do not rewrite history to make the final path look inevitable.

## Owner-Accepted Baseline Freeze

An audit or recommendation does not authorize technical change. When the owner identifies a package as QA-complete and freezes its technical baseline:

- record the owner's attestation and distinguish it from retained, reproducible test evidence;
- state exactly which behavior and payload are frozen and which release-support work remains authorized;
- permit documentation, identity, licensing, manifests, checksums, non-mutating validation, safe packaging, and evidence work without treating them as gameplay redesign;
- retain technical findings as observations or future backlog rather than silently implementing them;
- if validation reveals a potential release blocker, stop and report the evidence before changing the accepted baseline;
- require explicit owner authority to reopen runtime, gameplay, UI, install, removal, or configuration behavior.

## Preparation-Dominant Release Work

Treat `95% preparation / 5% execution` as an operating heuristic: settle identity, scope, instructions, artifact contracts, acceptance evidence, and authority before producing a release candidate.

- identify and fingerprint the exact QA-approved baseline before staging;
- distinguish the immutable parent release, the owner-approved working baseline, and the new candidate identity;
- complete the authoritative manifest, edition inventories, version map, requirements, install/verify/remove guidance, allowlists, and acceptance checklist before the candidate build;
- use read-only or dry-run checks to resolve planning defects without repeatedly mutating artifacts;
- perform one controlled candidate/promotion cycle after the planning gate, with any reproducibility comparison confined to temporary candidates and only one artifact promoted per identity;
- return failed checks to planning or owner review instead of patching a frozen baseline by inference;
- keep build, publication, and prior-file archival as separately authorized events.

## Safe Inputs And Evidence

Use minimal synthetic or explicitly redistributable fixtures in source control. Do not commit commercial game binaries, full proprietary configuration files, saves, extracted game assets, server data, private tester communications, or raw logs containing identifying paths unless redistribution and privacy authority are explicitly documented.

Retained evidence should identify source commit, tool/test version, environment classification, result, date, and revalidation trigger. Sanitize usernames, machine names, IP addresses, tokens, and unrelated file paths.

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

## Failure-Aware Engineering

Local mod tools operate in messy environments. Reliability must cover wrong paths, unsupported game versions, conflicting mods, restricted permissions, interrupted writes, damaged backups, unusual Windows settings, and modified packages—not only the successful path.

### Trust Boundaries

Each solution must identify the boundaries relevant to its behavior:

- reviewed source versus downloaded or repacked archive;
- packaged modlet versus installed modlet;
- user-selected game/server directory versus discovered default path;
- owned mod directory versus the rest of `Mods` and the game installation;
- live configuration versus backups;
- this tool versus other installed mods and security software;
- standard-user permissions versus elevated execution;
- diagnostic evidence versus private machine or server data.

Review path traversal, symbolic links and junctions, target substitution, malformed XML, partial copies, damaged backups, and misleading official-package identity where applicable. Do not claim cloud-service threats or controls that do not apply to a local mod package.

### Critical Flows And Failure Modes

For every state-changing flow—install, reinstall, tune, backup, cap change, restore, remove, and package—record proportionate failure analysis:

```text
Flow step -> Failure -> Detection -> User impact -> State changed
          -> Mitigation -> Recovery -> Test evidence
```

Prioritize failures with meaningful likelihood or impact. At minimum consider wrong target, insufficient permission, locked file, disk/write failure, game or server running, invalid XML, interrupted operation, conflicting mod, damaged backup, and unsafe deletion scope.

### Operational State Model

Front ends and diagnostics must use explicit states rather than optimistic messages. Applicable states include:

```text
Not inspected
Ready
Installed and verified
Installed but different
Conflict suspected
Unsupported game structure
Backup available
Restore unsafe
Partial operation detected
Removal verified
```

Each implemented state must define detection, permitted actions, blocked actions, user wording, recorded evidence, and recovery. A success message requires read-back verification.

### Reliability Promises

The baseline targets are:

- no writes or deletions outside declared owned targets;
- sensitive configuration writes require a validated backup;
- successful writes require read-back verification;
- failed operations preserve the prior state or expose a detected partial state;
- removal targets only the owned mod folder;
- unsupported structures fail before modification;
- release archives pass offline inspection;
- identical controlled inputs should produce identical release artifacts;
- no compatibility claim advances beyond its evidence.

These are engineering targets, not guarantees until corresponding tests pass.

## Proportionate Safe Rollout

Use progressive exposure for private and public testing:

```text
maintainer sandbox
-> one trusted tester
-> small varied tester group
-> release candidate
-> verified Nexus upload
-> observation window
-> prior Nexus file archived
```

Each stage must define entry evidence, scenarios, stop conditions, rollback trigger, and owner approval. A new Nexus upload must be downloaded or inspected as served before the prior file is hidden or archived.

### Emergency And Hotfix Path

Urgency does not erase safety. Define which conditions require distribution to pause, a user warning, rollback, or a patch release. Identity, scope safety, XML validation, archive inspection, rollback evidence, and owner approval may not be skipped. Record a concise, blameless incident note for any release-impacting failure and add the missing safeguard or test.

## Windows Tool Quality

For PowerShell and Windows front ends:

- use PowerShell-native confirmation and `ShouldProcess`/`-WhatIf` semantics where practical for maintainer or command-line state changes;
- distinguish recoverable from terminating errors and return meaningful exit status;
- run PSScriptAnalyzer in CI with documented, narrow suppressions;
- preserve XML strings and numeric values independently of user locale;
- test non-ASCII and special-character paths, restricted permissions, Windows PowerShell 5.1, supported display scaling, and package extraction paths;
- provide keyboard operation, logical focus, accessible names, visible focus, high contrast, non-color status cues, and screen-reader-readable errors;
- combine automated accessibility inspection with a short manual keyboard and Narrator/assistive-technology check for release candidates.

Accessibility and unusual-environment results must be recorded as evidence, not assumed from control choice alone.
