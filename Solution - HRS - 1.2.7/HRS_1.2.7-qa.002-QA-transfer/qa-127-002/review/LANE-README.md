# HRS 1.2.7 development lane

Public name: **New Player Random Start**. It changes the starting location for
a fresh 7 Days to Die character. HRS technical names and saved settings retain
their existing identities. Draft Nexus/site copy is in
public-copy.json.

This is the owner-requested new version of the completed native UX work
returned from QA. The active work manifest
and `BASELINE_PROVENANCE.json` identify its origin in 1.2.6 candidate 003.
DEV runs in this `QA_fresh` checkout by explicit owner selection.

```text
hrs_1.2.7/
  START.bat                 Native DEV manager entry
  README.md                 Draft customer guidance
  LICENSE.md
  LANE_README.md
  BASELINE_PROVENANCE.json   Original copy hashes and protected inputs
  dev/
    ui/                     Real manager, picture logo and assets
    src/launcher/           Existing policy, deployment and launch modules
    src/runtime/main/       Runtime source; version/log identity is 1.2.7/r127
    src/runtime/            Pinned deterministic build scripts
    tools/NativeGraphics/   Recipes, native controls and graphical workbench
    tests/                  Current reusable callback/policy/ownership tests
    verified/main/          Freshly double-built DLL and 1.2.7 ModInfo
    builds/1.2.7-qa.001/     Preserved original draft build record
    builds/1.2.7-qa.002/     Current repaired deterministic build record
    qa/                     New release contract, 46 Pending cases, fixtures
    qa/lane-bootstrap/      New-version DEV checks and visual review
    tmp/                    Ignored reference-only inputs and scratch work
    out/                    Ignored native build outputs
```

## Review

Run `START.bat` to view **Release | 1.2.7 DEV**. Its compact light surface,
56px picture-only logo, outlined Apply, small state badge, native method radios,
Help and repaired sizing come from the completed 1.2.6 implementation.
It reads existing configuration; a saved Game Name containing an earlier
version is still the exact save name, not the manager's release identity.
The field is **Game Name**. A supported existing world can be used for a fresh
character; already-played characters keep their positions on reload.

The top-to-bottom review
records the original two runtime defects and two bounded manager UX issues.
The completed repairs close those
findings in frozen candidate 002. The review and its original evidence are
preserved; independent display/accessibility/gameplay checks remain Pending.

The owner-review window was opened without Apply, removal or game actions.
The current native capture
shows **New Player Random Start** and **7 Days to Die v3.3.0 · Random Player Start**, with
the doubled 56px logo, sharper 64px icon frame and circular presentation
matching the owner's supplied YouTube avatar.
The owner confirmed ownership of that picture-only artwork.
The original bootstrap capture
and its checks retain their original source identity and scope.

## Build and evidence

Read the foundational setup architecture
before changing the build or configuration path. Apply persists exact Game
Name intent before a save/world needs to exist; runtime matches that name
and resolves the active world at an eligible fresh character's first spawn.
This bridge was the first complete increment recorded on 2026-08-21.
The reference distinguishes the single active policy from recovery history
and records the source boundaries and invariants future builds must preserve.

The repaired candidate 002 DLL was compiled twice with the existing pinned
.NET/Roslyn toolchain and all eight authenticated b17 references. Both outputs
match. Its current build record is `dev/builds/1.2.7-qa.002/build-record.json`;
the qualification receipt
binds all fifteen sources, payload and manager pin. The original bootstrap
changed log prefixes and ModInfo version, and the public rename changed its
DisplayName/Description. Those stages' original qa.001 build and metadata
receipts remain history. Candidate 002 additionally repairs c0167/c0185 and
authenticates the current XML with its fresh complete build.

The build reference root under `dev/tmp/reference-b17` combines preserved
b17 Assembly-CSharp bytes with the other seven matching references and an
inert marker. It is not a runnable game installation or a gameplay QA target.
The installed game's Assembly-CSharp fingerprint still differs from b17;
the pinned builder refuses that mismatch. Do not repin it to force a build.

Useful native checks from repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\hrs_1.2.7\dev\tools\NativeGraphics\Sync-ManagerDesign.ps1 -Check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\qa_cycle\Test-HrsRelease.ps1 -LaneRoot .\hrs_1.2.7
```

Historical 1.2.6 callback, geometry, workbench and customer-package evidence
remains at its original paths and retains its original scope. Stale old
presentation/startup/reuse tests were not copied as active new-version tests.
Fresh 1.2.7 bootstrap checks are recorded in `dev/qa/lane-bootstrap/`;
the later rename checks are under `dev/qa/public-name-20261004/` and
subtitle/Unicode checks under `dev/qa/game-subtitle-20261004/`.
None constitutes independent customer QA.

## Next handoff

**1.2.7-qa.002 is frozen and independently package-verified.** The
readiness record identifies the customer ZIP,
receipt, engineering companion and portable QA transfer. Copy that transfer
to QA, extract locally and open `qa-127-002/START-HERE.md`.
All 46 cases remain Pending. First reproduce the three sizing failures with
equivalent physical/OS sequences, then complete the frozen customer contract.
After QA and release approval, Nexus receives that same customer ZIP unchanged.
Candidate 001, all 1.2.6 artifacts and the public-release map remain preserved.
