# HRS Publishing Contract

## Purpose

This document defines the authoritative boundary between HRS development and publication.

Development has a large working surface.

Publication must have a deliberately tiny working surface.

The publication process must never be performed by copying the development tree and deleting
things until the result appears clean.

The release package must be ASSEMBLED FROM AN EXPLICIT ALLOWLIST using the exact promoted
release state.

The publishing boundary is:

PROMOTED RELEASE STATE
    ->
ASSEMBLE ALLOWLISTED PAYLOAD
    ->
VERIFY EXACT CONTENTS
    ->
VERIFY EXACT IDENTITIES
    ->
SECURITY / PRIVACY REVIEW
    ->
PACKAGE
    ->
HASH PACKAGE
    ->
PUBLISHER UPLOAD
    ->
RECORD WHAT WAS ACTUALLY PUBLISHED

## Primary Rule

NEVER PUBLISH FROM DEV BY EXCLUSION.

PUBLISH FROM PROMOTED STATE BY INCLUSION.

If a file is not explicitly required for the player-facing release, it does not belong in the
publication payload.

## State Separation

These states must remain distinct:

SOURCE

!=

BUILT CANDIDATE

!=

INSTALLED DEV CANDIDATE

!=

LIVE-TESTED CANDIDATE

!=

VERIFIED / PROMOTED ARTIFACT

!=

ASSEMBLED PUBLICATION PAYLOAD

!=

PUBLISHED RELEASE

A successful build does not authorize publication.

A successful live smoke does not authorize publication.

A promoted DLL does not prove that the ZIP surrounding it is correct.

A locally assembled ZIP does not prove that the file uploaded to the publisher is identical.

Each boundary requires evidence.

## Publication Source Authority

The publication package must be derived only from explicitly promoted release authority.

Do not source release bytes from:

- arbitrary `dev/out` directories;
- old build attempts;
- temporary folders;
- previous version packages;
- installed game files unless their identity is independently proven to match promotion;
- stale `verified` artifacts;
- copied desktop folders;
- Downloads;
- manually renamed DLLs;
- files selected because their timestamp "looks newest."

"Newest" is not authority.

Promotion evidence is authority.

## Exact-Byte Rule

If the release policy requires promotion of exact tested bytes, publication must preserve those
exact bytes.

The DLL selected for publication must have recorded:

- file name;
- byte count;
- SHA256;
- MVID;
- originating deterministic build attempt;
- tested status;
- promoted status.

If the publication DLL does not exactly match the promoted identity, STOP.

Do not rebuild merely to create a cleaner release copy after QA.

A deterministic rebuild may demonstrate reproducibility, but it does not silently replace the
artifact that was explicitly tested and promoted unless release policy says it may.

## Publication Allowlist

The publication package should contain only player-required runtime/deployment files plus
intentionally published documentation.

The exact allowlist must be established for the release before packaging.

Typical categories may include:

- release runtime DLL;
- `ModInfo.xml`;
- required launcher/manager files if the published product includes them;
- required runtime configuration assets;
- player-facing README/instructions;
- license;
- security/scanner disclosure if intentionally included.

A file category being listed above does not automatically authorize every matching file.

The final release manifest must enumerate the exact paths.

## Deny-By-Default Rule

Anything not explicitly allowlisted is denied.

Examples of content that normally MUST NOT enter the publication payload:

- `_planner_packet`;
- `_publisher_packet`, unless a specific public document is intentionally selected;
- DEV evidence;
- QA screenshots;
- test logs;
- deterministic build scratch directories;
- compiler outputs not required by the player;
- source manifests intended only for engineering;
- stale candidate DLLs;
- old release DLLs;
- `.git`;
- `.github` engineering instructions unless deliberately published;
- IDE metadata;
- temporary files;
- editor swap files;
- PowerShell history;
- shell transcripts;
- crash dumps;
- debugging symbols unless intentionally shipped;
- local machine paths;
- user profile paths;
- OneDrive paths;
- private notes;
- unpublished reviewer correspondence;
- credentials;
- secrets;
- tokens;
- API keys;
- cookies;
- certificates/private keys;
- unrelated mods;
- game binaries;
- copyrighted game assemblies;
- decompiled game content;
- arbitrary downloaded dependencies.

## Privacy Boundary

Before packaging, inspect all included text files for local/private information.

At minimum search for patterns such as:

- `C:\Users\`;
- `/Users/`;
- `/home/`;
- email addresses not intentionally public;
- access tokens;
- API keys;
- passwords;
- bearer tokens;
- private repository URLs;
- local network addresses if not intentionally documented;
- machine names;
- temporary build paths.

The presence of development provenance inside the engineering repository is acceptable.

The publication payload is a different trust boundary.

## Security Boundary

Because HRS contains executable code and runtime hooks, assume automated malware/scanner systems
may treat the package as suspicious.

Publication evidence should therefore make expected behavior clear.

Expected HRS behaviors may include:

- loading a runtime DLL inside 7 Days to Die;
- interacting with game runtime APIs;
- player relocation;
- reading/writing HRS-owned configuration/state files;
- installing/removing HRS-owned payload files;
- compatibility/version checks.

HRS is not intended to:

- download arbitrary executable payloads;
- establish persistence in Windows;
- inject into unrelated processes;
- steal data;
- collect credentials;
- hide execution;
- disable security software;
- modify unrelated applications;
- remove unrelated files;
- execute arbitrary remote commands.

If actual release behavior changes this boundary, update the security documentation before
publication.

## Game / Third-Party Boundary

Do not publish game-owned binaries or assets merely because they were useful during build or
testing.

Examples include:

- `Assembly-CSharp.dll`;
- game executables;
- proprietary prefab data not intended for redistribution;
- copied game resources;
- compiler/runtime files supplied by the game or platform.

References, hashes, MVIDs, and compatibility metadata may be recorded as evidence without
shipping the proprietary source artifact itself.

## Version Identity

Before packaging, all player-visible release identity must agree.

Review at minimum:

- package/version folder;
- `ModInfo.xml`;
- runtime log version;
- player-facing README;
- publication title;
- publication filename;
- release notes;
- any build identifier intentionally exposed.

A stale engineering document does not necessarily invalidate the release.

A stale player-facing or runtime release identity does.

Do not invent a build ID to make fields agree.

If build authority is unresolved, STOP.

## No Silent Repair At Publication

Publication is not the phase for opportunistic source repair.

If a publication check reveals:

- stale version metadata;
- unexpected DLL identity;
- missing documentation;
- incorrect uninstall behavior;
- manifest disagreement;
- security-boundary ambiguity;
- package contamination;
- failed validation;

STOP and return to the appropriate earlier gate.

Do not modify the release payload directly and continue publishing.

Fix the authoritative source/state, rebuild or re-promote as required, then re-enter the
publication conveyor.

## Clean-Room Assembly

The release package should be assembled into a NEW EMPTY DIRECTORY.

Do not package directly from:

- the repository root;
- a DEV output directory;
- the installed game Mods folder;
- a previous publication folder.

Preferred shape:

EMPTY STAGING DIRECTORY
    ->
COPY EXACT ALLOWLISTED FILES
    ->
VERIFY INVENTORY
    ->
VERIFY IDENTITIES
    ->
ARCHIVE STAGING DIRECTORY

This substantially reduces accidental file inclusion.

## Package Structure

The archive must unpack into the exact structure expected by the installation method.

Before publication, inspect the archive listing itself.

Do not assume the ZIP contains the same contents as the staging folder merely because the
archive command succeeded.

Check for:

- accidental extra parent directory;
- duplicate nested mod folder;
- missing `ModInfo.xml`;
- duplicate DLL;
- stale DLL;
- hidden files;
- temporary files;
- incorrect filename casing where relevant.

## Archive Identity

Record the final archive:

- filename;
- byte length;
- SHA256;
- creation time;
- included file inventory.

The archive SHA256 is the publication-package identity.

The DLL SHA256 is not sufficient to identify the entire upload.

## Post-Upload Identity

Worst case assumes the upload surface can introduce human error.

After publisher upload, where technically possible, verify that the hosted/downloaded package
matches the local publication package.

If the publisher provides its own hash, compare it.

If a clean download can be performed, compare the downloaded archive or extracted contents to
the local release manifest.

If exact hosted-byte verification is unavailable, record that limitation rather than claiming
it was verified.

## Fresh-Environment Test

Where practical, test the final publication package as a player would receive it.

Preferred test:

FINAL PUBLICATION ARCHIVE
    ->
EXTRACT INTO CLEAN TEST LOCATION
    ->
INSTALL USING PUBLISHED INSTRUCTIONS
    ->
START GAME
    ->
VERIFY MOD LOADS
    ->
VERIFY BASIC PLAYER PATH
    ->
VERIFY UNINSTALL / OWNERSHIP BEHAVIOR IF PART OF RELEASE REQUIREMENTS

Do not substitute a DEV-tree test for final-package validation when release risk warrants a
clean-package test.

## Publisher Metadata

Publication includes more than bytes.

Before release, verify:

- title;
- version;
- game version compatibility;
- dependency requirements;
- anti-cheat requirements/limitations;
- installation instructions;
- uninstall instructions;
- upgrade instructions;
- known limitations;
- security/scanner explanation if appropriate;
- license;
- changelog;
- screenshots/media if used;
- support/contact information if intentionally public.

Do not expose private development information merely because the publisher provides a text
field.

## Rollback / Bad Release Case

Assume a published release can be wrong.

Before publishing, preserve enough authority to answer:

- exactly what was uploaded;
- exact archive SHA256;
- exact DLL SHA256/MVID;
- source Git commit;
- release version;
- promotion evidence;
- build attempt;
- validation evidence;
- publisher release identifier if available.

If a bad release is discovered:

1. stop further promotion/publication;
2. preserve the faulty package as evidence;
3. identify whether the fault originated in source, build, staging, archive, or upload;
4. do not overwrite historical evidence;
5. create a corrected version according to versioning policy;
6. repeat the publication conveyor from authoritative state.

## Human Attention Rule

Publication should have a tiny working surface and few human decisions.

Machines may perform many checks.

The human should primarily decide:

- Is this the intended release?
- Is this the exact tested/promoted artifact?
- Does the player-facing package look correct?
- Are the security/privacy boundaries acceptable?
- Publish or stop?

Do not make the user manually inspect hundreds of irrelevant DEV files.

The allowlist and automated inventory exist specifically to reduce that burden.

## Failure Rule

FAIL CLOSED.

If any authority is unclear, STOP.

If package contents are unexpected, STOP.

If hashes differ, STOP.

If the artifact is not proven promoted, STOP.

If private or unrelated data appears in staging, STOP.

If version identity disagrees, STOP.

If a tool cannot establish an important fact, record the uncertainty and stop at that gate.

DO NOT "CLEAN IT UP AND SHIP IT."

RETURN TO AUTHORITY.
FIX THE CAUSE.
RE-ENTER THE CONVEYOR.

## Publication Conveyor

The authoritative conceptual path is:

PROMOTED RELEASE ARTIFACT
    ->
EMPTY STAGING DIRECTORY
    ->
COPY EXACT ALLOWLIST
    ->
VERIFY FILE INVENTORY
    ->
VERIFY HASHES / MVID / VERSION
    ->
PRIVACY SCAN
    ->
SECURITY-BOUNDARY REVIEW
    ->
ARCHIVE
    ->
VERIFY ARCHIVE INVENTORY
    ->
HASH ARCHIVE
    ->
OPTIONAL CLEAN-PACKAGE INSTALL TEST
    ->
FINAL HUMAN RELEASE GATE
    ->
PUBLISH
    ->
RECORD PUBLISHER IDENTITY
    ->
OPTIONAL POST-UPLOAD VERIFICATION
    ->
CLOSE RELEASE RECORD

This is a one-way conveyor.

Publication should be boring.

Boring is success.