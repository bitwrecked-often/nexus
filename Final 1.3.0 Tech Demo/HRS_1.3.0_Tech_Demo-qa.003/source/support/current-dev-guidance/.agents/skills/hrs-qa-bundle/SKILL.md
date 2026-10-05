---
name: hrs-qa-bundle
description: Prepare and verify one complete Historical Random Start public ZIP shared unchanged by QA, customers, Nexus and the project site. Use for HRS candidate packaging, isolated QA handoff, or exact-byte publication preparation; not for DEV probe DLLs.
---

# HRS shared QA/customer bundle

**Owner-selected policy, 2026-10-04:** one complete public ZIP is the
distribution artifact for QA, customers, Nexus and the project site. Everyone
receives the **same complete archive bytes and SHA-256**, including the product,
redistributable project source, build instructions, history, lore, contracts,
tools and evidence available at export. Keep the ordinary product entry simple;
the supporting material is available for optional reading and future work.

The public archive must be self-contained. A separate DEV delivery receipt may
authenticate its complete hash, but recipients must not require an unpublished
engineering companion or another download to inspect the project material.
Only the exact owned runtime payload is installed in the game; public source,
history and evidence stay in the extracted package, outside the live game.

Do not rebuild, edit, or recompress an approved archive. Later QA observations
remain separate append-only records until a later candidate includes them;
adding those observations to an existing ZIP changes its identity and requires
a new candidate and QA cycle. Preserve earlier split-package candidates and
their original records unchanged; that older layout is historical, not the
forward packaging rule.

Read the repository [entry point](../../../AGENTS.md),
[current baseline](../../../CURRENT_BASELINE.md),
[development doctrine](../../../DEVELOPMENT_CYCLE_DOCTRINE.md), and the active
version manifest before selecting inputs. Use the commands and case lifecycle
in [candidate workflow](../../../../../qa_cycle/CANDIDATE_WORKFLOW.md); use the
[DEV/QA/Nexus routing policy](../../../HRS_DEV_QA_NEXUS_WORKFLOW.md) for role
boundaries. Historical candidate names are examples, not authority for a new
version.

For a new candidate:

1. Check functional scope, source, game fingerprint, pinned toolchain,
   deterministic build record, verified DLL and ModInfo, manager pins, and
   version-specific release/QA contracts. A DEV compile or live probe is not a
   verified candidate build. Stop before export if the release gate is not
   ready; record precise blockers without changing pinned inputs to force a
   pass.
2. Use an unused `X.Y.Z-qa.NNN` ID. Use the full-package export supported by
   `Export-HrsCandidate.ps1 -PublicContentRoot <prepared-public-content>`,
   the matching lane and an unused output path. It
   reserves the ID and writes the single complete public archive. A failed
   reservation is not reusable. Confirm the active manifest and exporter
   implement this layout before exporting; a planned candidate is not a ready
   package. Preserve legacy transport records instead of replacing them.
3. Verify the registry, complete archive SHA-256, embedded manifests, exact
   declared file list and every file hash. Check the project source/build,
   history/lore and evidence inventories, their original evidence scope,
   licensing notices, and the absence of private data or proprietary game
   files. Independently extract the complete public ZIP; run its QA tools and
   product entry from that isolated extraction and preserve the frozen ZIP.
   Record actual game behavior and the required case evidence.
   For a standalone download without a trusted local registry, verify the
   published complete ZIP SHA-256 first, then use the bundled
   `New-HrsQaWorkspace.ps1 -ExpectedArchiveSha256 <trusted-published-SHA256>`.
   The extractor creates local QA receipt/registry records; no adjacent receipt
   or companion download is required.
4. After the release owner approves the complete QA cycle, provide the exact
   tested complete public ZIP to Nexus and the site. Compare the SHA-256 at each
   destination with the approved QA archive. Any changed byte requires a new
   candidate and QA cycle. Publication is a separate authorized action.

The active development lane, 2026-10-05, is `hrs_1.3.0_Tech_Demo`, front label
**Tech Demo | 1.3.0**. Follow the
[Tech Demo manifest](../../../../../../docs/DEV-1.3.0-TECH-DEMO.md) and its
[readiness record](../../../../../hrs_1.3.0_Tech_Demo/dev/qa/QA_BUNDLE_READINESS.md).
Candidate `1.3.0-qa.002` is sealed and package-verified. The owner requested the
visible label **Game Name**; `1.3.0-qa.003` is its planned new immutable identity.
Preserve earlier archives and carry behavioral evidence only through the
explicit verified label-only delta, with fresh native presentation checks. The returned GUI
round and DEV source checks do not pass the 46 formal cases; owner feature and
visual acceptance precedes the full campaign. A qualified playable game target
is needed for formal gameplay. Verify the actual archive/export receipt before
describing the planned candidate as frozen or ready.

The preserved handoff is the exported, frozen single public ZIP
**1.2.7-qa.003**, with implementation and verification recorded in the
closeout and
[1.2.7 manifest](../../../../../../history/versions/DEV-1.2.7.md).
Its root `START.bat` opens the product; source, history, lore and evidence remain
available beside it. There is no nested customer ZIP and no required adjacent
receipt or companion. Candidate 002 remains preserved under the earlier layout.
All 46 independent 1.2.7 cases remain Pending until executed; publication awaits
actual QA and release-owner approval.

For the preserved HRS 1.2.4 cycle, use
QA bundle readiness before
export. Keep the 1.2.3 candidate-003 receipt issue separate from 1.2.4.
