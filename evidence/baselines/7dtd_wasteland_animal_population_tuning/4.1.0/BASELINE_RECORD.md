# 4.1.0 Source Baseline Record

## Record Status

- Evidence state: captured and frozen
- Capture date: 2026-07-12
- Repository solution key: `7dtd_wasteland_animal_population_tuning`
- Solution path: `solutions/7dtd_wasteland_animal_population_tuning_files/`
- Intended candidate version: `4.1.0`
- Release state: development; no candidate or publication authority implied

This record identifies the exact solution tree that the owner described as QA-complete for copy-forward preparation. The statement about QA is an owner attestation; this repository does not invent test scenarios, environments, dates, or results that were not retained as evidence.

## Lineage Anchors

- Immutable working parent tag: `v4.0.1`
- Parent tag commit: `c90f5f7f27d84343b95971a54486b88aa1022c00`
- Owner-approved copy-forward commit: `b3c3551c0c5bfc8d24c68d3036da4c8045a90b54`
- Solution subtree at that commit: `010454d19b10f46c71d9150335905766b946176e`
- File count: 32
- File modes: 32 regular files at Git mode `100644`
- Comparison HEAD at capture: `4167c5139629ddb15386e221e67f6e159a9797bc`

At capture, the solution subtree at comparison HEAD resolved to the same tree ID and `git diff` reported no solution-path changes from the copy-forward commit. Intervening changes were confined to root/governance files.

## Hash Scope And Method

`SOURCE_SHA256SUMS.txt` covers every file in the anchored solution subtree, including documentation, source, assets, and the three grandfathered historical ZIPs.

The hashes are SHA-256 digests of the raw Git blob streams at the anchored commit. They do not describe platform-specific checkout or archive newline conversion. Independent checking found that `git archive` under the capture machine's Windows Git configuration converted some text to CRLF, so `git archive` output must not be substituted for the raw-blob digest domain. Candidate construction must define and validate its own staged-byte contract rather than assuming that a checkout, an archive export, and the Git object are byte-identical.

## Historical Artifact Guard

| Historical artifact | SHA-256 |
| --- | --- |
| `7DTD_WastelandAnimalPopulationTuning_FullPackage.zip` | `52E32D5CC0A0E8D073BB421AEB2BB681D744FEE0F9E5985551EEDB15F8B96901` |
| `7DTD_WastelandAnimalPopulationTuning_Nexus_NoScripts.zip` | `96F0796845DBE53773B445C364CB66A46CD046C1519ED778BFDE3BD066008DA5` |
| `7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip` | `BC64A2F71B09395D62DF3BC6482C5299756F063C10C87B454D7850548BC25485` |

These values matched both the anchored Git content and the current working tree at capture. The archives remain historical evidence and must not be renamed, rebuilt, repaired, or used as writable packaging destinations.

## Known Provenance Boundaries

- The working parent is authoritative because the owner reports it works; that does not make it reproducible from its tag.
- The historical full-package GUI bytes differ from the GUI bytes in tagged `v4.0.1` source. Preserve the known exception described in the deep-audit addendum.
- The historical no-scripts ZIP contains known documentation defects. Preserve it, but do not validate a future edition against that legacy contract.
- This baseline freezes runtime, gameplay, GUI, install/remove, cap-management, and modlet behavior. It does not freeze authorized `4.1.0` documentation, licensing, identity metadata, manifests, staging, non-mutating validation, or release evidence.

## Change Comparison Rule

Before solution-facing preparation begins, use this record as the before-state. Every later solution-path change must be classified as:

1. authorized non-behavioral preparation;
2. generated candidate output kept outside Git; or
3. blocked technical behavior change requiring new owner authority.

The release-readiness report must link the resulting diff and reconfirm the three historical archive hashes.
