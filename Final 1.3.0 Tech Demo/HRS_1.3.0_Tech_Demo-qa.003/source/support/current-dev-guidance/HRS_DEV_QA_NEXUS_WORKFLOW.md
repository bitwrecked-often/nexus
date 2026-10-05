# Historical Random Start routing doctrine

Status: governing repository and release-routing policy  
Effective: 2026-08-30

Full public-package amendment: owner-selected 2026-10-04

Development decisions, scouting, implementation evidence, and the order of
work are governed by [the development-cycle doctrine](DEVELOPMENT_CYCLE_DOCTRINE.md).
For AI handoffs, follow its
[cost-conscious implementation and review method](DEVELOPMENT_CYCLE_DOCTRINE.md#cost-conscious-ai-implementation-and-review).
Implementation completion and release promotion remain separate evidence decisions.

## One public package

QA, customers, Nexus and the project site receive one complete ZIP with the
same bytes and SHA-256. Its product, redistributable project source, build
instructions, history, lore, contracts, tools and evidence are available to
every recipient. The normal product entry stays simple; readers may explore
the supporting material and use it as a foundation for future development.

The archive is self-contained. A DEV delivery receipt can separately record
the complete archive hash, but public review does not depend on an unpublished
engineering companion. The former smaller customer ZIP plus QA-only companion
and transfer arrangement remains preserved for older candidates. New exports
follow this complete public-package policy.

All included evidence retains its original candidate, environment and DEV/QA
scope. The material is a snapshot at export. Fresh QA observations and release
decisions are recorded outside that frozen archive and may be included in a
later candidate; approval never causes a post-QA archive refresh.

## Canonical workspace

This QA Git repository is the canonical Historical Random Start development,
release-coordination, QA-contract, evidence, and history workspace going
forward. A separate repository that mirrors the live game installation is not
required for ordinary project work.

The repository may contain:

- mutable DEV source and tests inside the active version lane;
- immutable prior version lanes and rejected-candidate records;
- verified release payloads;
- release and QA contracts;
- the reusable `qa_cycle` tooling;
- changelogs, handoffs, and release decisions; and
- sanitized QA evidence references.

DEV and QA remain separate roles even when their records share this repository.
Sharing a repository does not authorize QA to repair or rebuild a candidate.

## Live game boundary

The live 7 Days to Die installation is a runtime and observation target, not a
development repository, evidence archive, or source of release truth.

Only the exact verified runtime payload may be installed under the owned mod
directory:

```text
Mods/
└── BitWrecked_HistoricalRandomStart/
    ├── d0163.dll
    ├── ModInfo.xml
    └── Bridge/
        ├── policy.v1.json
        └── result.v1.json
```

`Bridge` contains bounded runtime state generated through the established
manager/runtime contracts. The game installation must not receive source,
tests, QA scripts, release notes, evidence bundles, build output, temporary
files, or repository metadata.

Game-provided files, saves, worlds, unrelated mods, Harmony files, global XML,
executables, anti-cheat files, registry state, services, and server
configuration are outside project ownership. They may be observed when a test
requires it but are not project storage and are not modified by routine DEV or
QA work.

## Version-lane lifecycle

Every change proceeds through a new versioned lane:

1. DEV creates the new lane and records the intended scope.
2. DEV implements the bounded change and produces one verified payload.
3. `qa_cycle/New-HrsCycle.ps1` initializes the release and QA contracts from
   the new lane's verified artifacts.
4. `qa_cycle/Test-HrsRelease.ps1` verifies version identity, hashes, manager
   pins, supported environment, scope markers, and required QA cases.
5. Any readiness error remains in DEV. The candidate cannot enter QA.
6. QA tests the exact immutable artifact by case ID and exports sanitized,
   hash-manifested evidence.
7. A QA defect returns to DEV. QA does not edit, re-pin, rebuild, or repackage
   the failed candidate.
8. Any byte, dependency, metadata, or approved-scope change creates another
   versioned candidate and another QA cycle.
9. `qa_cycle/Complete-HrsQaCycle.ps1` approves only a clean release gate with
   complete passing evidence for the same release-record digest.
10. Promotion distributes the exact bytes QA approved. There is no post-QA
    rebuild or package refresh.

## Role authority

### DEV

DEV owns source changes, tests, builds, package construction, version changes,
and defect repair. DEV may use the explicit development-gap option to capture
diagnostic evidence, but that evidence cannot approve a release.

### QA

QA owns independent execution of the acceptance contract, environment and
artifact verification, observations, evidence export, pass/fail reporting, and
rollback testing. QA consumes candidates and never repairs them in place.

### Release owner

The release owner confirms scope, resolves release blockers, records approval
or rejection, and promotes only the exact approved artifact digest. Approval is
for identified bytes, not merely a version label or folder name.

### Nexus/publication

Nexus or other public distribution is a promotion destination, not a build or
repair lane. Publication receives the exact complete public ZIP tested by QA,
including its source, history, lore and evidence, along with the necessary
user-facing release information. Customer and Nexus review never substitute a
smaller package for the archive admitted to QA. Included project material must
carry its licensing notices; proprietary game assemblies and private local
state remain outside the public archive.

## Evidence and rollback

Each QA case must be traceable to:

- the canonical `rel.json` digest;
- DLL and `ModInfo.xml` identities;
- the supported game fingerprint;
- one QA contract case;
- bounded runtime and manager events;
- structured QA observations where required;
- installed state before and after; and
- a rollback receipt for removal testing.

Evidence is stored outside the live game. Generated `qa_runs` content remains
local or is transferred through the chosen evidence channel; it is not normal
source content and is ignored by Git in this repository.

Removal targets only verified project-owned files. Unknown or changed files are
preserved and reported. Rollback succeeds only when the owned release path is
absent afterward and unrelated state remains untouched.

## Current routing decision

The current DEV lane is `hrs_1.2.7`, publicly named **New Player Random Start**.
The complete public package **1.2.7-qa.003** is exported, registered and frozen;
implementation and verification are tracked in the
[lane manifest](../../../history/versions/DEV-1.2.7.md) and
closeout.
Its canonical archive is `qa_cycle/candidates/1.2.7-qa.003.zip`. The root
`START.bat` opens the product in `customer/HistoricalRandomStart_1.2.7`;
`source/hrs_1.2.7`, history, lore, evidence, context and tools are available
inside that same ZIP. No nested product ZIP or adjacent companion is required.
Standalone QA verifies the trusted published complete archive SHA-256 and uses
the bundled `New-HrsQaWorkspace.ps1 -ExpectedArchiveSha256` to create local QA
records without another required download.
The earlier **1.2.7-qa.002** archives and records remain frozen. All 46
independent cases remain Pending. Publication awaits actual independent QA
and release-owner approval; exporting this package does not pass QA.

The following 1.2.3 paragraph records the preserved routing checkpoint.
`CURRENT_RELEASE.json` remains its informational release map. It identifies the
1.2.3 mechanics and tested runtime while recording that the reported promotion
ZIP has not been located and reconciled in this checkout. The physical source
lane is now `hrs_1.2.3`, with candidate `1.2.3-qa.003` and an immutable export
plus engineering companion. Follow [the candidate workflow](../../qa_cycle/CANDIDATE_WORKFLOW.md)
to prepare a separate QA extraction. `hrs_1.2.1/dev/qa/rel.json` remains a
preserved historical 1.2.0 contract.

`hrs_1.1.0` remains the historical two-point NG01/NG02 QA fixture, and `hrs_1.0.1`
remains the packaging-identification repair fixture. Commands that validate or
start QA require an explicit `-LaneRoot`; no older lane is selected implicitly.
The current 80-point selector is an observed source scope, not a claim that all
80 points have been recertified by this repository-health review.

## Exception rule

If a separate source repository is later introduced, it does not become
authoritative merely because it contains similar files. Authority moves only
through an explicit migration that records the source commit, artifact hashes,
history boundary, ownership, and new routing links. Until then, this repository
and this doctrine govern Historical Random Start release work.
