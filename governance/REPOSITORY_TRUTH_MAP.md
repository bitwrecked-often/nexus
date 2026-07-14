# Repository Truth Map

## Purpose And Scope

This file is the reconciled current-truth map for `4.1.0` preparation, opened on
2026-07-12 and updated through the 2026-07-13 P3 acceptance and P4
candidate-source transition. It tells
maintainers and AIs which identity and documents may drive work, which are
projections, and which are historical or blocked.

It does not prove that a candidate ZIP exists, a release occurred, a compatibility result passed, a GitHub setting is enabled, or Nexus state changed. The machine-readable per-solution manifest created in P2 now owns the bounded package contract derived from this map; projections must validate against it.

## Evidence Classes

- **Authoritative current source** — may define the stated fact within its scope.
- **Controlled projection** — must mirror an authority and may not define a competing value.
- **Blocked draft** — intended future surface whose claims are not release-valid yet.
- **Historical evidence** — retained proof of what existed or was released; never silently updated into current truth.
- **Retired/stale** — retained only for history until removed or replaced; must not route current work.

## Product Identity And Version Map

| Fact | Current value | Authority and projection rule |
| --- | --- | --- |
| Repository solution ID | `7dtd_wasteland_animal_population_tuning` | Existing solution slug accepted for the P2 manifest and `dist/` routing; do not invent another alias |
| Canonical display name | `7DTD 3.0 Wasteland Animal Population Tuning` | Recorded owner/product identity; the release manifest owns the release projection |
| Game-facing mod ID | `BitWrecked_7DTD_WastelandAnimalPopulationTuning` | `ModInfo.xml` is runtime authority; the release manifest must equal it |
| Installed mod folder | `BitWrecked_7DTD_WastelandAnimalPopulationTuning` | Frozen technical behavior and Q17; must equal the runtime ID for `4.1.0` |
| Author / official upstream identity | `Bit Wrecked` | Q17 and existing copyright/author metadata |
| Game-target label | `7DTD 3.0` / current retained evidence described as `3.0-era` | Separate from package SemVer; exact build is unverified until evidence exists |
| Intended package version | `4.1.0` | Owner decision and active release-candidate line; the per-solution release manifest owns it |
| Active workspace projection | `4.1.0` | Root `VERSION` is the checked candidate-source projection, not permanent multi-solution authority |
| Lifecycle state | `Release Candidate` / `Candidate` | Owner accepted P3 and authorized one technical-only P4 cycle; no candidate ZIP or publication exists |
| Working parent | `v4.0.1` at `c90f5f7f27d84343b95971a54486b88aa1022c00` | Immutable historical release lineage; not a reproducibility claim |
| QA-approved copy-forward baseline | Commit `b3c3551c0c5bfc8d24c68d3036da4c8045a90b54`, solution tree `010454d19b10f46c71d9150335905766b946176e` | `BASELINE_RECORD.md` and raw-blob checksums are the durable before-state |
| Active branch | `develop/4.1.0` | Candidate-source workflow projection; publication still requires a separate approved release identity |
| Official source repository | `https://github.com/bitwrecked-often/nexus` | Repository origin; exact release/commit route must be projected into release-facing docs |
| Primary edition ID | `windows-gui` | Graphical casual-player package; legacy `FullPackage` is a historical alias, not its new contract |
| Optional static edition ID | `no-scripts` | Blocked/deferred until it has a truthful meaningful outcome without violating the frozen baseline |
| Optional manager edition ID | `vortex` | Blocked until the exact candidate passes the versioned Vortex and GPL-completeness gate |
| Candidate stage | `dist/7dtd_wasteland_animal_population_tuning/4.1.0/candidate/` | Ignored working output; contains candidates only |
| Final-upload stage | `dist/7dtd_wasteland_animal_population_tuning/4.1.0/final-upload/` | Ignored technical-promotion output; never implies publication authority |

The per-solution release manifest owns package version, lifecycle intent, edition IDs and roles, exact allowlists, capabilities, exclusions, filenames, deterministic archive policy, and source-baseline reference. Root `VERSION`, `ModInfo.xml` version/display fields, GUI version text, README, changelog heading, evidence reports, and future Nexus draft copy are generated or validated projections. Historical package metadata and release notes are not current projections. `ModInfo.xml` remains the authority for the runtime ID. A tag, GitHub Release, and Nexus served-file evidence prove their own external states only after authorized publication.

## Edition State

| Edition | Role | Current state | Contract boundary |
| --- | --- | --- | --- |
| `windows-gui` | Primary casual-player Nexus file | Candidate source; non-publishable; no ZIP built | Exactly the accepted eight files; three visible root entries; existing BAT/PowerShell/XML behavior frozen |
| `no-scripts` | Optional readable static-inspection/manual-install file | Blocked/deferred | Must not advertise meaningful tuning while shipping vanilla-equivalent XML; do not invent preset values or borrow GUI/cap capabilities |
| `vortex` | Optional Vortex-supported modlet | Blocked | Requires exact-candidate import, enable, recognition, disable, removal, identity, license, and source-route evidence |
| Legacy three ZIPs | Historical `4.0.1` evidence | Immutable | Validate only against legacy facts and registered hashes; never use as build destinations or new-edition fixtures |

All eight primary source paths exist. Resolve them from the declared solution root with exact case and full relative paths, never by basename:

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

## Document Authority Registry

| Document or group | Class | Current treatment |
| --- | --- | --- |
| `AGENTS.md` | Authoritative current source | Repository-wide AI and release-control rules |
| `governance/PROJECT_MANIFEST.md` | Authoritative current source | Enduring product/reliability policy and accepted package principles |
| `governance/OWNER_DECISION_INTERVIEW.md` | Authoritative current source | Recorded owner decisions; later explicit decisions supersede earlier entries |
| `governance/NEXT_AI_DEEP_REPO_AUDIT_ADDENDUM.md` | Authoritative current source | Current scope override, evidence facts, stop rules, and dependency order; listed work is not completion evidence |
| `governance/NEXT_AI_BASELINE_INFRASTRUCTURE_PACKET.md` | Authoritative current source, bounded | Detailed requirement catalog; older technical-change language is future backlog under the freeze |
| `governance/EXECUTION_PLAN.md` | Controlled projection | Durable mirror of the live planner and the single current phase; creates no authority |
| `governance/PRIVATE_TEST_PROGRAM.md` | Authoritative current source | Field-evidence and privacy method |
| `governance/ASSET_PROVENANCE.md` | Authoritative current source | Asset ownership/provenance status and redistribution gate |
| `governance/CHANGELOG.md` | Historical evidence | Governance/infrastructure history, not product behavior |
| Root `README.md` | Controlled projection | Repository front door; validate against governance |
| Root `VERSION` | Controlled projection | Active-workspace candidate-source label while one solution is active |
| `RELEASING.md` | Authoritative current source, bounded | Separates validation, staging, candidate construction, technical promotion, and later authorized public actions |
| `solutions/README.md` | Controlled projection | Current solution index; routes identity and edition truth to the manifest |
| `solutions/7dtd_wasteland_animal_population_tuning.md` | Controlled projection | Current concise solution overview; contains no rebuild authority |
| Frozen BAT, GUI PS1, and modlet XML at the anchored tree | Authoritative current source | Owner-approved technical behavior only; release identity fields remain controlled projections to update in P2 |
| Primary `README_FIRST.txt` | Controlled projection | Current customer quick guide and accepted ZIP file; validated against the manifest and GPL/source contract |
| Solution `CHANGELOG.md` | Authoritative history plus controlled current projection | Historical release entries remain; the `4.1.0` section records player/package truth only |
| `PACKAGE_METADATA.md` and `TECHNICAL_FILE_MANIFEST.md` | Historical evidence; retired as authority | Visible historical banners prevent current routing; the manifest owns the current contract |
| `README_WINDOWS.md`, `RELEASE_NOTES.md`, `PUBLISHING_SEO.md`, and `BUILD_STORY_AND_QA_RUNBOOK.md` | Historical or maintainer reference | Excluded from the primary ZIP; do not reuse cross-edition claims without validation |
| `LICENSE.txt` | Authoritative current source | Complete applicable GPL text; preserve verbatim in every supported edition |
| `LICENSE_NOTICE.md` and `LEGAL_AND_USE.md` | Maintainer reference | Excluded from primary ZIP; do not turn project publishing preferences into added GPL restrictions |
| `Nexus_NoScripts/README_FIRST.txt` and `REQUIREMENTS_AND_INSTALL.txt` | Blocked drafts | Optional-edition documents only; not valid until the outcome and exact contract are truthful |
| `Upload_To_Nexus/NEXUS_UPLOAD_NOTES_NO_SCRIPTS.md` | Retired/stale | Historical scanner-response note superseded by the graphical-primary decision |
| Three `Upload_To_Nexus/*.zip` files and their internal documents | Historical evidence | Immutable legacy artifacts with known defects; never current truth |
| Baseline evidence under `evidence/baselines/.../4.1.0/` | Historical evidence | Exact before-state and provenance boundary for later diffs |

`governance/GITHUB_REPOSITORY_HEALTH.md` is the controlled status view for committed repository-health controls and unverified live GitHub settings. It cannot prove service enforcement.

## P1 Before-State Contradiction Register

The following rows preserve the defects found before P2. They are historical
findings, not a claim that each defect still exists. Use the P2 disposition table
immediately below for current status.

| ID | Contradiction | Scope and disposition |
| --- | --- | --- |
| TRUTH-001 | No per-solution machine-readable manifest currently owns release identity and edition contracts | Primary P2 gate: create it before version/document/package projections are treated as candidate-ready |
| TRUTH-002 | Primary README, GUI version, and `ModInfo.xml` still show `4.0.1`; README lacks the approved GPL/source/no-warranty/origin treatment | Intentional during P1; primary P2 gate now that the before-state is fingerprinted |
| TRUTH-003 | The `4.1.0` solution changelog draft contains governance history and an unsupported deterministic-build claim | Primary P2 gate: retain historical entries, move current governance truth to the governance changelog, and record only player/package changes |
| TRUTH-004 | The solution overview says `2.0.0`, omits current behavior/files, and gives a hazardous legacy rebuild command; the index routes to it | Repository-routing P2 gate: replace with a checked current overview or clearly retire it |
| TRUTH-005 | Legacy package metadata, technical manifest, release notes, and upload notes claim current authority, roles, layouts, or reports that conflict with Q5-Q20 | Bounded as historical here; P2 must add visible status and prevent validators/AI routing from consuming them as current truth |
| TRUTH-006 | The current validator writes unversioned historical ZIP paths and stages the legacy large package | Primary P2 gate: do not run rebuild mode; replace or safely refactor packaging before any candidate construction |
| TRUTH-007 | Compatibility language uses `current`, `3.0-era`, or unsupported exact-build implications without retained exact-build evidence | Primary P2 gate: label verified/observed/expected/unverified honestly; do not invent a build |
| TRUTH-008 | Exact official release source/support routing is absent from the README and `ModInfo.xml` Website is empty | Primary P2 gate: project the repository and exact source version/commit route without claiming an uncreated release |
| TRUTH-009 | No-scripts is called supported, but its frozen XML is vanilla-equivalent while Q1 requires meaningful tuning | Optional-edition-only block: defer it rather than changing frozen behavior or inventing values |
| TRUTH-010 | Vortex is an intended support claim, but no exact-candidate lifecycle audit exists and the legacy ZIP omits the referenced license | Optional-edition-only block: do not build or advertise it until its independent gate passes |
| TRUTH-011 | `RELEASING.md` does not fully separate candidate, merge, tag, served-file verification, and old-file archival authority | Publication gate: resolve before public actions; does not block offline P2 work |
| TRUTH-012 | Raw Git blobs, Windows checkout bytes, and `git archive` output can differ in newline representation | Primary P2 integrity gate: add explicit attributes/staged-byte policy and validate the digest domain used for candidates |
| TRUTH-013 | Root/governance document licensing is not selected by Q19 | Separate rights decision; does not block the GPL-complete primary solution artifact |

## P2 Disposition Record

This table records what the P2 implementation changed without erasing the original contradictions or converting deferred gates into claims.

| ID | P2 status | Durable disposition |
| --- | --- | --- |
| TRUTH-001 | Resolved offline | The schema-validated per-solution manifest owns release and edition contracts. |
| TRUTH-002 | Resolved offline | README, GUI version text, and `ModInfo.xml` project `4.1.0`; technical validation limits GUI and metadata edits to declared non-behavioral substitutions. |
| TRUTH-003 | Resolved offline | The solution changelog now contains bounded player/package truth; governance work stays in `governance/CHANGELOG.md`. |
| TRUTH-004 | Resolved offline | The solution index and overview now route current work to the manifest and safe validator. |
| TRUTH-005 | Resolved offline | Conflicting legacy documents are visibly historical, retired, or blocked and are excluded from the primary allowlist. |
| TRUTH-006 | Resolved offline | Legacy rebuild mode fails closed; the new entry point validates by default and can stage only the exact primary allowlist under ignored `dist/`. |
| TRUTH-007 | Resolved offline | Compatibility statements distinguish owner-observed Windows use from unverified or unsupported environments and do not invent an exact game build. |
| TRUTH-008 | Bounded/partial | Customer and runtime metadata route to the official repository without claiming a nonexistent release. Exact release-source projection remains a candidate/release gate. |
| TRUTH-009 | Still blocked | No-scripts remains non-publishable pending an owner-authorized meaningful static outcome. |
| TRUTH-010 | Still blocked | Vortex remains non-publishable pending an exact-candidate lifecycle and GPL-completeness audit. |
| TRUTH-011 | Bounded/partial | `RELEASING.md` separates technical phases from owner-authorized public actions. Main lifecycle, merge method, merge/tag order, and exact future tag naming remain owner gates. |
| TRUTH-012 | Resolved for development staging | Attributes declare LF source bytes and P2 staging uses exact clean-`HEAD` Git blob bytes. P4 must bind the candidate source commit to generated evidence; tag binding remains a later public-release gate. |
| TRUTH-013 | Still open, non-blocking | Root/governance license scope remains an explicit owner rights decision. |

The P4 candidate-source projection freezes all content that can enter the ZIP.
The changelog uses release-neutral wording rather than embedding an unknown
publication date or served state. The actual source commit, tag resolution,
approvals, artifact hashes, and served URLs belong in generated
acceptance/provenance evidence; the committed manifest must not require an
impossible self-referential commit SHA.

## P3/P4 Transition Record

- On 2026-07-13 the owner accepted the P3 planning set and authorized one
  technical-only `PreparePrimary` cycle.
- The candidate-source tuple is workspace version `4.1.0`, channel and lifecycle
  `release-candidate`, and publication state `candidate`.
- The primary edition state is `candidate`, with `publishable: false` and no
  artifact hash. `releaseSourceCommit`, tag, publication approval, and exact
  release-source URL remain unset.
- The archive contract is stored ZIP entries, ordinal stage-path order, `/`
  separators, timestamp `2000-01-01T00:00:00Z`, and two reproducibility builds.
- No candidate ZIP has been staged, built, promoted, published, or served. P4
  evidence must prove each technical transition before the plan can close.

## Satisfied Historical P1 Closure Rule

P1 is complete when the raw-blob fingerprint validates, this registry is routed to future AIs, the historical ZIP hashes still match, and every contradiction is either assigned to P2, isolated to an optional edition, or held at a later owner/publication gate. P1 completion does not mean the release is ready; it makes P2 safe to begin without rewriting technical behavior by inference.
