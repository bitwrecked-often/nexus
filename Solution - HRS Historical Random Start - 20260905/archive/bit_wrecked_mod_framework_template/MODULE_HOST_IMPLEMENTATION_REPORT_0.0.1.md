# Bit Wrecked Module Host 0.0.1 — Implementation Report

Copyright (C) 2026 Bit Wrecked contributors  
SPDX-License-Identifier: GPL-3.0-or-later

Date: 2026-07-19  
Build classification: local native PowerShell/WinForms, read-only
infrastructure  
Acceptance decision: **accepted for read-only infrastructure, design, and
testing use**

This report records what was built, what was verified, and what remains
outside the approval boundary. It does not certify payload processing, game
modification, release readiness, or human accessibility conformance.

## Delivered files

The implementation is contained under `module_host/`:

- `7DTD_BitWreckedModuleHost.bat` — relative-path Windows launcher.
- `BitWrecked_ModuleHost_Tool.ps1` — native WinForms host and the only
  production logging writer.
- `MODULE_HOST_README.md` — operating and safety notes.
- `modules/ModuleContract.ps1` — contract validation, literal registry, and
  local-path boundary.
- `modules/BlankFramework.Module.ps1` — read-only blank adapter.
- `modules/OffenseWeaponsDesign.Module.ps1` — empty design-only adapter.
- `modules/WastelandAnimals411.ReadOnly.Module.ps1` — isolated read adapter.
- `tests/Test-ModuleHost.ps1` — repeatable Windows PowerShell 5.1 acceptance
  harness.
- `tests/MANUAL_ACCESSIBILITY_CHECKLIST_0.0.1.md` — honest human-observation
  gate.

The required pre-adaptation evidence is in
`MODULE_HOST_COMPARISON_MATRIX_0.0.1.md`. No standalone GUI was dot-sourced,
embedded, or copied into the host.

## Architecture and contract

The host uses a literal, reviewed three-module allowlist. It does not scan for
or execute arbitrary scripts. Each adapter is loaded into an isolated dynamic
module and must pass strict definition and action-result contract validation.
Results are correlated to module ID, request ID, context generation, and
canonical local game root before the UI may apply them.

Module selection is navigation only. Pages are created lazily, then cached.
Validation is an explicit user action and runs in a fixed local
`powershell.exe` worker. Polling keeps the WinForms message loop responsive;
stale, forged, mismatched, or late results are rejected.

The activity history remains in memory by default. Visible history is bounded
while the full session history remains available. Every physical activity-log
line is sanitized and tagged.

## Module state

- **Blank Framework 0.0.1:** neutral read-only page with no payload or mod
  actions.
- **Offense Weapons 0.0.1:** design-only empty workspace. It contains no
  weapon rows, inferred features, or payload.
- **Wasteland Animals 4.1.1:** a read-only adapter based on the comparison
  matrix. It performs bounded, hardened local reads and never calls the
  4,000-line standalone GUI.

The Wasteland adapter distinguishes these states rather than polishing
uncertainty into a false completion claim:

- `Missing` — no candidate package is present.
- `ExactReference` — the frozen default 4.1.1 package is verified exactly.
- `PresentRecognizedUnverified` — a shaped/custom package is present, but its
  current values are not claimed as verified.
- `PresentInvalid` — identity or structure is malformed or contradictory.
- `Drift` — a verified package differs from the recognized live setting.

Live XML can similarly be recognized as `Live` or rejected as
`ShapeMismatch`. XML reads prohibit DTD processing, disable external
resolution, and enforce an 8 MiB input ceiling. Unknown or extra animal rows,
wrong append routes, duplicate structure, custom pressure, malformed backup
evidence, and other ambiguous shapes produce bounded, honest results.

## Safety boundary

Production code does not install, remove, restore, package, create a `Mods`
folder, edit game/mod files, change caps, open the Mods folder, elevate, use
the network, emit telemetry, use accounts, bypass policy, use encoded
commands, or discover arbitrary adapters.

The sole permitted production write is optional persistent logging. The user
must choose an existing local folder and separately confirm logging. Merely
choosing a path writes nothing. Network, device, mapped-network, and
selected-game-root destinations are rejected.

## Automated acceptance evidence

The self-contained suite was run under Windows PowerShell 5.1 in STA mode
after the implementation report, accessibility checklist, and template index
were added. It recorded **175 passed, 0 failed** and ended with
`MODULE_HOST_ACCEPTANCE_PASS`.

Measured evidence from that acceptance run:

- Cold shell construction: 355.32 ms.
- Maximum module switch: 57.69 ms.
- 600 tagged log events: 91.77 ms.
- Validation acknowledgement: 28.46 ms.
- Validation worker: 2809.22 ms, including a deliberate 1500 ms test delay.
- UI heartbeat count during delayed validation: 44.
- Launcher smoke from a different working directory: 2230.75 ms.
- GUI smoke: all three pages created, four navigation events, automatic close.

Coverage includes parsing and license headers, exact registry membership,
contract forgery rejection, rogue-script non-discovery, local-only root
enforcement, Wasteland fixtures, no-write inventories, page caching,
navigation timing, stale asynchronous-result rejection, logging boundaries,
static safety, accessibility structure, protected-tree preservation, recovery
hashes, and launcher execution.

## Preservation evidence

The acceptance harness inventories files and directories with native relative
paths, ordinal sorting, SHA-256 per-file records, and a deterministic aggregate
SHA-256. Before/after fingerprints matched for every protected tree:

| Protected tree | Files | File-record fingerprint |
|---|---:|---|
| `blank_working_example` | 5 | `1FB39FEB46968BFD2959C7C6DD9DB85859A2E2CDD33B443D216325FA843D7150` |
| `framework_reference_4.1.1` | 67 | `8EA1D17329DC40ACDAC80BD0D83E38797C1317897C3776880EA5E540FF9D6388` |
| `offense_weapons_design` | 111 | `5BC91F51EF0C14812EDEC0A3AC6CBAA3ADC025971BE0E0696EC962DDEF834FD3` |
| `offense_weapons_solution` | 71 | `805609D690C1653D0C19083854081FB671A427A6CB5D372F27E33993FEF71673` |
| `release_templates` | 11 | `9228CF040E3B8F2FC3128D30F8304D114AD37B2258C2E9120B84A3FD5F56FAAD` |

The preserved standalone Wasteland tool SHA-256 is
`168F333A8D5A4C9CA150A40205DF2E148207DE2D1D3F978E7884E45B7C425FEF`.
Existing recovery artifact hashes also matched their ledger. The sealed Module
Host snapshot is recorded separately in
`recovery_artifacts/RECOVERY_ARTIFACTS_SHA256.txt` to avoid a circular
self-hash dependency.

## Open evidence and known limitation

Manual keyboard-only, Narrator, Windows High Contrast, and 100%/150% DPI
observations remain pending in
`module_host/tests/MANUAL_ACCESSIBILITY_CHECKLIST_0.0.1.md`. Automated
structure passed; this report does not claim that a human performed those
observations.

The older generic `tools/Test-FrameworkIntegrity.ps1` has a pre-existing
Windows PowerShell limitation: its default-root expression is not portable
there, and an explicit-root run encounters MAX_PATH in two archived 4.0.1
files. Its PowerShell 7 run passes. The Module Host's own Windows PowerShell
5.1 harness uses extended-path-safe deterministic inventory and passes the
protected-tree checks. The frozen generic tool and protected archives were
not changed to conceal that limitation.

## Final boundary

This build is approved as the read-only host shell requested by the manifest.
It is not approval for payload code or any install/remove/restore/package
capability. The Offense Weapons module remains intentionally empty. Public
accessibility signoff remains pending the named manual checklist. Any future
write action requires a new design, explicit review, and a new acceptance
decision.
