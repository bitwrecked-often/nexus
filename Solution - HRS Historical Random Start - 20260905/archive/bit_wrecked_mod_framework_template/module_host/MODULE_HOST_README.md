# Bit Wrecked Module Host 0.0.1

Copyright (C) 2026 Bit Wrecked contributors  
SPDX-License-Identifier: GPL-3.0-or-later

This folder contains the local native PowerShell/WinForms Module Host. It is a
read-only infrastructure build, not a combined installer.

Start it with:

    7DTD_BitWreckedModuleHost.bat

The launcher resolves the host relative to its own folder, including from a
Program Files (x86) path. It does not elevate, bypass execution policy, use
encoded commands, or pause behind a hidden console prompt.

## Reviewed modules

- **Blank Framework 0.0.1 — Read-only:** empty neutral workspace.
- **Wasteland Animals 4.1.1 — Read-only:** five evidence-backed reference
  rows and an isolated read adapter. Exact frozen 4.1.1 is distinguishable
  from custom/unverified, drifted, incomplete, or unavailable state.
- **Offense Weapons 0.0.1 — Design / No Payload:** intentionally empty;
  no weapon rows or payload are represented.

The registry is a literal allowlist in modules/ModuleContract.ps1. Dropping
another script beside the adapters does not register or execute it.

## Safety boundary

The host and all three adapters have no install, remove, restore, package, or
game/mod write action. Choosing a module is navigation only. Choosing a game
folder does not validate it. Validation must be requested explicitly and runs
in a fixed local Windows PowerShell worker so the UI stays responsive.

Activity history is in memory by default. The only optional write is a tagged
text log at a local file explicitly chosen and then separately confirmed by
the user. Choosing its path alone does not write. A log path inside the
selected game folder is rejected.

Network paths, device paths, and network drives are rejected. The host uses
no network, telemetry, account, browser, elevation, plug-in discovery, or
remote dependency.

## Tests

Run the self-contained Windows PowerShell 5.1 acceptance harness:

    powershell.exe -NoProfile -STA -File .\tests\Test-ModuleHost.ps1

The automated accessibility gate checks DPI mode, names, descriptions, roles,
tab order, high-contrast code paths, and dynamic rows. Manual keyboard,
Narrator, Windows High Contrast, and 100%/150% DPI observation remain explicit
human checks; automation does not claim those observations occurred.

Design authority and evidence:

- ../MODULE_HOST_MANIFEST_0.0.1.md
- ../MODULE_HOST_INFRASTRUCTURE_BUILD_HANDOFF_0.0.1.md
- ../MODULE_HOST_UX_AND_PERFORMANCE_GUIDANCE_0.0.1.md
- ../MODULE_HOST_COMPARISON_MATRIX_0.0.1.md
