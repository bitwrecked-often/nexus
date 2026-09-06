# Historical Random Start changelog

This file records why each packaged version exists and distinguishes player
features from packaging, verification, and documentation changes.

## Unreleased

- Added a routed chronological development story explaining the original Alpha
  6 inspiration, modern framework constraints, failed chunk/roof/trader
  approaches, Snow and `HRS_TRADER_006` successes, packaging-identity lesson,
  carousel method, and why 1.2.0 reuses and generalizes those solutions. The
  record distinguishes documented Fun Pimps evolution from installed-build
  observations and project adaptations so future teams do not overstate cause.
- Defined the 1.2.0 arrival-biome protection and same-zone trader cycle as five fresh games using
  certified NVG-0281, 0282, 0283, 0285, and 0286 for Pine Forest control,
  Desert, Snow, Burnt Forest, and Wasteland. Each game proves initial-zone-only
  hazard protection, a one-time route to the nearest valid trader within that
  zone, unchanged routing after later travel/reload, and ordinary hazards in
  every later biome. The manifest pins current game inputs, exact buff/timer
  families, trader placements, evidence requirements, and both inherited gaps:
  Snow-only protection and globally-nearest trader selection.
- Opened `hrs_1.2.0` from the certified 1.1.0 baseline as a separate `r120`
  development lane. Its opening runtime changes identity only and retains the
  NG01/NG02 production pool; expanded certified starts, same-biome/zone trader
  routing, and arrival-biome danger suppression remain explicitly planned.
- Corrected the shared release gate to validate both the legacy X/Z spawn
  constructor and the current X/Y/Z form according to each release record.
  The backward regression fixture and all QA-cycle tooling tests pass 30/30.
- Completed controlled repeat certification of the clear full-catalog survivor
  set: 161/161 and 10/10 deterministic runs passed for 171/171 total, with
  health 100 and exact origin restoration. Raw event/result files and SHA-256
  values are preserved in the canonical carousel handoff catalog.
- Added a Nexus base-build evidence baseline for `1.1.0`. It records the
  `1.0.0` packaging incident, the identity-only `1.0.1` repair, the intentional
  `1.1.0` feature/landing changes, exact candidate identity, accumulated
  carousel evidence, survivor-certification plan, and remaining promotion
  gates without treating QA-only points as shipped player content.
- Added a separate QA-only deterministic carousel for all twelve existing
  Navezgane survey anchors, NG01 through NG12. It dwells for 30 seconds at each
  grounded landing, records requested/actual coordinates and health, and
  restores the starting position on first failure or full completion. The
  shipped selector remains restricted to approved NG01 and NG02.
- Opened `hrs_1.1.0` as the active feature lane. It replaces the temporary
  fixed-NG01 selector with one game-owned random draw over the explicit
  approved NG01/NG02 index allowlist; the other ten entries remain survey-only.
- Built the `1.1.0 / r110` runtime twice with byte-identical output, synchronized
  manager and metadata pins, initialized the release/QA contracts, and extended
  the release gate to verify the exact approved selector contract.
- Added a reproducible Navezgane POI exporter, a hash-manifested catalog of all
  1,487 placed POI instances across 704 unique prefabs, a live scouting ledger,
  and a compact AI context handoff with filtered loading instructions.
- Added the Historical Random Start development-cycle doctrine. It records the
  "ask the system before changing the system" review, separates discovery,
  implementation, and release evidence, defines candidate states, and orders
  street-level scouting, small-batch integration, certification, and release.
- Established the repository-root Historical Random Start routing doctrine.
  The QA repository is now the canonical development, release, QA-contract,
  evidence, and history workspace; the live game is only a runtime target and
  receives the exact verified mod payload.
- Added a reusable DEV-to-QA release-evidence process with a canonical release
  record, formal QA cases, identity/readiness validation, sanitized run capture,
  installed-state snapshots, runtime-event comparison, rollback receipts, and
  hash-manifested ZIP export.
- Added cycle initialization and Windows PowerShell 5.1 self-tests so each new
  version begins with the same release and QA contracts.
- The new gate found that `1.0.1` is still fixed to NG01. It blocks QA approval
  against the requested NG01/NG02 random-selection scope until a later version
  implements and verifies that behavior.

## 1.1.0 — DEV candidate

### Added

- Random selection between the two approved points NG01 and NG02.
- An explicit `{0,1}` approved-index allowlist so extending the twelve-entry
  survey catalog cannot silently expand release behavior.
- Static and release-gate checks requiring exactly one game-owned RNG draw and
  rejecting fixed selection or randomization across the full survey catalog.
- A clean portable `START.bat` header, replacing the inherited leading-space
  and `A/@echo off` corruption found during the final byte audit.

### Preserved

- Standard-mode no-op behavior, one-shot reservation, deferred placement,
  runtime terrain height, safe-landing verification, optional reviewed snow
  protection, nearest-trader routing, and starter-quest continuity.
- `1.0.1` remains immutable as the packaging-identification repair and
  fixed-NG01 predecessor.

### Artifact identity

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `dev/verified/main/d0163.dll` | 38,400 | `5DDDEEF35438D71530DB1FC0AF06201106772E163D1A83FC97162A3290662C7C` |
| `dev/verified/main/ModInfo.xml` | 428 | `D43A8C74EFD1EFA06DD1B44BDD46B995447DEB8EF4E07C3220C7AB10147EE11A` |

Live QA remains required before release approval.

## 1.0.1 — 2026-08-28

### Why this version exists

QA rejected the `1.0.0` package because the packaged `ModInfo.xml` fingerprint
did not match the fingerprint pinned by the manager and release manifest. The
fail-closed integrity check stopped installation as designed. Version `1.0.1`
was created as a separate repair lane so the failed `1.0.0` candidate could
remain available as incident history.

QA also reported an identification mismatch between the DLL version described
by the package and the DLL that actually loaded. The correct DLL functionality
was present; `1.0.1` synchronizes the package, manager, metadata, runtime-log
identity, notes, and verified artifact fingerprints.

### Fixed

- Changed the package and deployment identity from `1.0.0` to `1.0.1`.
- Changed `ModInfo.xml` from version `1.0.0` to `1.0.1` and synchronized its
  verified SHA-256 pin.
- Changed the runtime log identity from `v=1.0.0 build=r100` to
  `v=1.0.1 build=r101` so logs identify the repaired package correctly.
- Rebuilt the runtime twice and confirmed byte-identical output, then updated
  the manager and release manifest to the verified DLL SHA-256.
- Removed `START.lnk`, which contained an absolute path into the old `1.0.0`
  development directory. `START.bat` remains the portable entry point.

### Improved

- Updated the portable-manager regression test to calculate the DLL and
  `ModInfo.xml` hashes from `dev/verified/main` and require the manager to
  contain those exact pins. This guards against another package/pin mismatch.
- Regenerated the release-source manifest with the built-and-verified `1.0.1`
  artifact identity.
- Added the `1.0.1` QA-to-DEV handoff with the incident, validation results,
  observed Apply outcome, limitations, and next steps.

### Artifact identity

| Artifact | 1.0.0 SHA-256 | 1.0.1 SHA-256 |
| --- | --- | --- |
| `dev/verified/main/d0163.dll` | `394C9EF2C2AAA8E30A7268DFA7A33E1CBED80975A4779C6327F6DAE4A45DF72E` | `F9B937E05E914B52DEA9E379EB4EA8C0CAB716764F87E543FA44E5456477CCC6` |
| `dev/verified/main/ModInfo.xml` | `ED14DB4450CB449B3628539BF3D3A9998D9D1709B141D80367C47641C1E5C419` | `E32B4F6D7AE07BA1272EB88ABE7FBDF402E1E6F6B2DA3674B71314DF24E1E94B` |

Both verified DLLs are 38,400 bytes. Their .NET assembly version is `0.0.0.0`;
the package release identity is carried by `ModInfo.xml`, the manager,
runtime-log identity, release notes, and verified fingerprints.

### Functional scope

- No gameplay, relocation, safe-landing, snow-protection, trader-routing,
  policy, result, or launcher-workflow behavior was intentionally changed.
- The runtime source comparison found only the runtime-log version/build label
  changed between the two main source trees.
- Existing `1.0.0` player features remain the functional baseline for `1.0.1`.

### Repository comparison note

A path-and-SHA-256 scan found 261 files in each version lane. There are 258
changed same-path files, one file only in `1.0.0` (`START.lnk`), and one file
only in `1.0.1` (`dev/docs/n0235.md`). After normalizing line endings, 247 of
the same-path text files are identical and four more differ only by the version
label. The remaining differences are release notes, artifact manifests,
identity pins, the pin-regression test, and the runtime-log label.

The QA handoff records the rejected packaged `ModInfo.xml` as SHA-256
`A6DF8103F4CDC6923C01904C378016F9ECA1FE982AB40DB9BA3253AB2608D1C2`.
That exact file is not present in the current repository trees: the checked-in
`1.0.0` verified file hashes to the manager's expected `ED14DB...` value.
Accordingly, the original mismatch is supported by the preserved incident note,
while the present tree comparison verifies the repaired `1.0.1` identity.

## 1.0.0 — 2026-08-28

### Added

- Portable PowerShell 5.1 manager launched through `START.bat`.
- Exact-name Standard mode that preserves normal starting behavior.
- One-shot Random mode using twelve curated Navezgane survey anchors.
- Deferred placement with chunk-load and safe-landing verification.
- Optional suppression of the initial NG01 snow hazard for the relocated
  character and selected game.
- Nearest opening-trader routing across the five reviewed Navezgane trader
  placements while preserving the vanilla quest lifecycle and progression.

### Known packaging issue

- The first QA Apply attempt detected a `ModInfo.xml` fingerprint mismatch and
  stopped before installation.
- Superseded by `1.0.1`; retain `1.0.0` for comparison and incident history,
  not as the current QA candidate.
