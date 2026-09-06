# Historical Random Start - Security & Scanner Manifest

## Welcome

This file is provided specifically for automated security scanners, malware-analysis systems,
hosting-platform review tools, and human moderators reviewing:

Historical Random Start - Alpha 6 Method

The purpose of this manifest is to make the mod's behavior, file ownership, runtime actions,
and build provenance easy to inspect.

This software is a 7 Days to Die gameplay mod.

It intentionally changes the player's initial spawn behavior for a newly armed game.

It is not designed to hide its behavior.

## What This Mod Does

Historical Random Start restores a classic-style randomized starting experience.

For a specifically armed new game, the runtime may:

1. Select one approved starting location.
2. Relocate the player to that location.
3. Allow the destination area/chunk to resolve.
4. Adjust the player to a safe ground/surface position.
5. Record the arrival biome.
6. Optionally suppress the initial arrival-biome hazard.
7. Redirect the opening trader objective appropriately.
8. Return control to normal game progression.

The current production landing pool contains:

- 16 Pine Forest locations
- 16 Desert locations
- 16 Snow locations
- 16 Burnt Forest locations
- 16 Wasteland locations

Total selectable production locations: 80.

A larger certified landing library is retained in source/evidence for auditing and development.

## Why A Security Scanner May Notice This Mod

This package contains behavior that can look unusual to generic malware heuristics because it:

- contains a managed DLL;
- uses game runtime hooks;
- changes player position during gameplay;
- includes a launcher/manager;
- reads and writes mod-owned policy/result files;
- installs files into its own 7 Days to Die Mods directory;
- checks game/runtime compatibility before certain actions.

These actions are part of the mod's documented gameplay and deployment design.

They are not intended for persistence, credential access, surveillance, remote control,
data theft, or operating-system modification.

## Runtime Boundary

The runtime component operates as a 7 Days to Die mod.

Primary release folder:

`Mods\BitWrecked_HistoricalRandomStart`

Expected release payload:

- `d0163.dll`
- `ModInfo.xml`

Mod-owned bridge/state files may also exist under the mod's own controlled paths.

The mod is designed to fail closed when expected runtime, policy, deployment, or compatibility
conditions are not satisfied.

## File Ownership And Removal

The manager uses ownership checks before uninstalling the mod.

Removal is restricted to the Historical Random Start release location and expected
mod-owned files.

The uninstall path checks the contents of the target directory before deletion.

Unexpected files or ownership conflicts are intended to stop automatic removal rather than
delete unknown content.

The mod does not intentionally delete unrelated user files, game files, saves, or other mods.

## Files This Mod Does Not Intentionally Modify

Historical Random Start does not require permanent modification of vanilla world files.

The landing catalog uses mod-owned coordinates and runtime placement logic.

It does not use vanilla world files as persistent storage for its own state.

The mod is not intended to patch or overwrite:

- Windows system files;
- browser files;
- user documents;
- unrelated game installations;
- unrelated mods;
- account credentials.

## Network Behavior

The Historical Random Start gameplay runtime does not require a remote command-and-control
service.

It is not designed to:

- open a listening network service;
- exfiltrate player data;
- transmit credentials;
- download executable payloads;
- contact advertising networks;
- perform cryptocurrency mining;
- participate in botnets.

Any normal network activity performed by Steam, 7 Days to Die, Nexus Mods, GitHub, or the
operating system is outside this mod's runtime responsibility.

## Process Behavior

The mod is intended to execute inside the normal 7 Days to Die mod/runtime environment.

Its player-relocation behavior is a gameplay action.

The presence of teleport/relocation logic should not be interpreted as arbitrary operating
system process manipulation.

The project does not intentionally provide:

- process injection into unrelated applications;
- credential dumping;
- keylogging;
- screen capture;
- persistence mechanisms;
- privilege escalation;
- ransomware behavior.

## Deterministic Build Evidence

Release candidates are built using a deterministic double-build process.

A candidate is accepted by the build process only when repeated builds produce matching
output.

The build system records information including:

- source file hashes;
- compiler identity;
- compiler hashes;
- game assembly compatibility identity;
- candidate DLL size;
- candidate DLL SHA256;
- assembly MVID;
- deterministic double-build result.

This allows reviewers to compare source state with generated artifacts.

## Development Build Evidence

The following identity was captured during development of the balanced 80-point runtime. It is retained as development evidence and is not the final published-package identity:

Candidate:

`alpha-core-9c424a54f321420d9dc4175992bd7b10`

DLL:

`d0163.dll`

Size:

`56832 bytes`

SHA256:

`C732AC84E47B8E0A4FBBD0F2B89401C1597D181A5A32EC1B1A1B4A8664142222`

MVID:

`f65efba4-1a77-4e9b-b51a-31050e506118`

Deterministic double build:

`True`

Game Assembly-CSharp compatibility MVID:

`229796d0-95ca-4662-b426-1a6f1f1596ed`

IMPORTANT:

Development candidate identities may differ from the final published Nexus release.

The hash published with the final release package should be treated as authoritative for that
specific uploaded version.

## Source Manifest

The source tree contains a manifest that records controlled runtime source files using:

- path;
- byte length;
- SHA256.

An aggregate SHA256 is also calculated from the ordered source-manifest entries.

The release verifier rejects source drift when a controlled file no longer matches its
recorded size or hash.

This is intentional anti-drift behavior.

## Runtime Version Identity

Current runtime line:

`[HRS] v=1.2.1 build=r120`

The version identifies the Historical Random Start runtime.

Build identifiers are maintained separately from gameplay behavior and should not be treated
as network identifiers, machine identifiers, or tracking identifiers.

## Landing Location Safety

The production selector uses an explicitly approved location list.

The full certified location library is preserved separately.

Current production selection uses exactly 80 approved locations.

Runtime placement does not blindly rely on a fixed stored elevation.

The destination is resolved against the live game world and the existing landing/surface
settlement logic adjusts the final player position as necessary.

## Example Verified Runtime Behavior

During a live Navezgane smoke test:

Game:

`test222`

Mode:

`RandomSafe`

Arrival-biome protection:

`Enabled`

Selected certified location:

`NVG-0286`

Prefab:

`hotel_ostrich`

Display name:

`Ostrich Hotel`

Biome:

`wasteland`

Certified anchor:

`(-1923, 61, -1912)`

Observed settled player position:

approximately `(-1920.4, 61.1, -1915.1)`

Runtime reached:

`RELOCATION_COMPLETED`

This demonstrates the intended relocation and surface-settlement behavior.

## Anti-Cheat / Compatibility

The mod relies on the supported 7 Days to Die mod/runtime environment.

Compatibility checks may include known game assembly identities.

Failure to meet expected compatibility or deployment conditions is intended to prevent the
mod from mutating or deploying rather than forcing execution.

## Transparency

This project intentionally retains:

- source code;
- source hashes;
- deterministic-build evidence;
- landing-location evidence;
- deployment validation;
- runtime verification;
- development notes;
- release manifests.

These artifacts exist so that a reviewer does not need to infer the purpose of the DLL from
behavior alone.

## Scanner Guidance

If an automated scanner flags this package because it observes:

- a DLL;
- runtime hooks;
- player relocation;
- file deployment;
- compatibility checks;
- PowerShell management code;

please evaluate those behaviors in the context of the documented 7 Days to Die mod workflow
described above.

Those behaviors are expected features of Historical Random Start.

A detection should be evaluated against the actual file hashes, source code, deployment
scope, and runtime behavior before classifying the package as malicious.

## Reviewer Summary

Historical Random Start is intended to:

`choose approved start -> relocate player -> settle safely -> establish biome context ->
repair opening trader routing -> continue normal gameplay`

It is not intended to:

`persist outside the mod -> steal data -> control unrelated processes -> alter Windows ->
download payloads -> hide execution -> delete unrelated files`

Thank you for reviewing the package.
