# Contributing

Thanks for helping improve the Nexus mod workshop. Small, focused changes with
clear evidence are easiest to review and safest for players.

## Before You Change Anything

- Read `AGENTS.md` and the active solution's release manifest.
- Base work on the active development branch named in the manifest, then use a
  focused branch and pull request. Do not target or push `main` unless a
  maintainer explicitly requests the release path.
- Open one issue or pull request per coherent purpose.
- Do not change a frozen runtime/gameplay baseline unless the owner has explicitly
  reopened that technical scope.
- Never modify a published tag or the three committed `4.0.1` ZIPs.
- Do not add generated ZIPs or anything under `dist/`.

## Keep Private And Proprietary Material Out

Do not commit credentials, tokens, private messages, tester identities, machine
names, IP addresses, saves, server files, commercial game files, extracted game
assets, or raw logs containing personal paths. Use small synthetic fixtures and
sanitized evidence.

Image, audio, font, and branding contributions need recorded ownership, license,
redistribution authority, and preferred editable source before distribution.

## Describe The Change

Every material change should state:

- player-visible purpose and affected edition;
- files or game state read, written, copied, backed up, restored, or removed;
- compatibility assumptions and evidence level;
- validation performed and exact result;
- removal or rollback behavior;
- known limitations and live checks still pending.

Use `not applicable` when a small documentation change does not affect one of
these areas. Do not invent a test result or promote an observation to verified.

## Local Check

Use PowerShell 7.4 or later from the repository root:

```powershell
pwsh -NoProfile -File tests/release/Invoke-OfflineTests.ps1
```

This suite includes the manifest-driven source validator. It is an offline
repository check; live-game, server, accessibility, Vortex, and field results
must be reported separately and accurately.

## Licensing

Contributions to files already carrying `GPL-3.0-or-later` notices are submitted
under that license. Preserve applicable copyright, license, modification, and
no-warranty notices. Do not add restrictions that conflict with GPL rights.

This statement does not silently license every root/governance document or
asset. Follow the notice and provenance record applicable to the file you change,
and ask before contributing material whose rights are unclear.

## Publication Boundary

A pull request, review, passing check, merge, or staged artifact does not by
itself authorize a GitHub Release, Nexus upload, or archival of an existing file.
Public actions remain explicit owner decisions.
