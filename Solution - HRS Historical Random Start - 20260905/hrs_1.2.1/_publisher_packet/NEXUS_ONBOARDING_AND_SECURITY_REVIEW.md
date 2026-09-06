# Nexus Mods Onboarding and Security Review

## Purpose

This document is the Nexus-specific publication guide for Historical Random Start (HRS).

Use it together with:

- `PUBLISHING_CONTRACT.md`
- `PUBLISH_RELEASE_CHECKLIST.md`
- `PUBLISH_PAYLOAD_MANIFEST_TEMPLATE.md`

The general publisher packet defines what HRS considers a valid publication.

This file records the Nexus-specific entry path.

## Desired Release Strategy

HRS should not make its first public appearance while its release file is still waiting on
security review.

Preferred sequence:

FINAL RELEASE CANDIDATE
    ->
ASSEMBLE CLEAN PUBLICATION PACKAGE
    ->
KEEP NEXUS MOD PAGE UNPUBLISHED / HIDDEN
    ->
UPLOAD FINAL ARCHIVE
    ->
ALLOW NEXUS SECURITY SCANNERS TO RUN
    ->
IF QUARANTINED, REQUEST MODERATOR REVIEW
    ->
WAIT FOR ACCEPTABLE SECURITY STATUS
    ->
ONLY THEN MAKE MOD PAGE PUBLIC

The objective is to let Nexus inspect the real release bytes before the mod becomes publicly
discoverable.

## Current Nexus Guidance

As of this guide's creation, Nexus Mods states that all uploaded mod files pass through
multiple security checks before being made available for download.

Security status may include:

- green checkmark: passed internal checks and VirusTotal;
- blue checkmark: passed internal checks but VirusTotal could not scan it;
- yellow question mark: scanning is still in progress and the file is unavailable;
- red cross: security checks failed or VirusTotal generated enough positives to require
  moderator review.

A red-cross/quarantined state does not by itself establish that a file is malicious.

It means Nexus requires closer review before allowing it to be downloaded.

## Unpublished / Hidden Staging

Nexus File Submission Guidelines state that public placeholder pages are prohibited and that
pages without functioning public files should remain unpublished, hidden, or removed.

For HRS, this is useful.

The release may be uploaded to an unpublished/hidden mod page so the actual file can enter the
Nexus security process without intentionally launching the mod publicly first.

Do not deliberately publish the page merely to cause the scanner to run.

Use the hidden/unpublished staging state until the security gate is satisfied.

## Nexus Pre-Upload Security Checklist

Nexus does not currently publish a separate mandatory pre-review security questionnaire for
ordinary mod uploads.

Therefore HRS uses the following internal preflight before upload.

### Archive Format

Use:

- ZIP; or
- 7z.

ZIP is preferred for the simplest review path.

Avoid unusual archive formats.

Nexus notes that archive formats which cannot be decoded reliably may be blocked because the
scanner cannot inspect their contents.

### No Password Protection

The publication archive must NOT be password protected.

Password protection prevents Nexus from scanning the contents and is not acceptable for the
upload path.

### No Nested Archives

Do not place another ZIP, 7z, RAR, or similar archive inside the main publication archive.

Nested archives can prevent complete scanning and may cause the upload to be rejected.

If separate downloadable components are ever required, use separate Nexus file entries rather
than nesting opaque archives.

### Executable / DLL Awareness

HRS contains executable runtime code in a DLL.

Assume that automated scanners may inspect this more closely than a data-only mod.

The package and public description should accurately explain why executable code exists and
what it does.

Do not attempt to disguise:

- DLLs;
- runtime hooks;
- deployment logic;
- relocation behavior;
- configuration/state writes.

Transparency is part of the security posture.

### Functional State

Nexus requires uploads to be presented in good faith and in a functional state, subject to
clearly disclosed requirements and caveats.

Do not upload a knowingly broken publication package merely to obtain a scanner result.

The uploaded file should be the actual intended release candidate.

### Accurate Description

The Nexus page should accurately describe:

- what HRS changes;
- how it is installed;
- what executable/runtime component it contains;
- game-version requirements;
- anti-cheat limitations if applicable;
- uninstall behavior;
- known limitations.

Do not exaggerate capabilities.

Do not conceal requirements.

### Network Behavior

Current HRS release behavior is not intended to require internet communication for runtime mod
functionality.

If a future HRS release introduces executable code that connects to the internet, STOP and
review Nexus File Submission Guidelines before publication.

Nexus gives internet-connected executables additional scrutiny and specifically directs
authors of tools/apps requiring such communication to contact staff with their reasoning and
source code.

Do not assume a future network-enabled HRS build is covered by this guide.

## HRS Security Evidence To Have Ready

Before Nexus upload, retain locally:

- final archive filename;
- archive byte count;
- archive SHA256;
- exact payload inventory;
- runtime DLL filename;
- runtime DLL byte count;
- runtime DLL SHA256;
- runtime DLL MVID;
- deterministic build evidence;
- source Git commit;
- live-test evidence;
- promoted-artifact evidence;
- security/scanner manifest;
- source/repository location if staff requests review material.

Do not send all of this unsolicited unless useful.

Have it ready so support can receive precise evidence quickly if they ask.

## If Nexus Quarantines The File

If Nexus shows the uploaded file as quarantined / requiring moderator review:

DO NOT PANIC.

DO NOT DELETE THE FILE MERELY TO TRY AGAIN.

Nexus specifically advises authors, where possible, not to delete a blocked file while waiting
for moderator review because doing so can disrupt version history and updates.

First inspect the Nexus security result.

Determine whether the issue appears to be:

- archive decoding;
- nested archive;
- suspicious file type;
- VirusTotal detections;
- another security check.

If the problem is clearly packaging-related and Nexus guidance identifies a legitimate fix,
return to the publication authority, rebuild the package correctly, and document why.

Do not mutate an already-promoted binary merely to avoid detections.

## Requesting Nexus Review

Nexus states that moderators periodically review quarantined files, but contacting them is
faster and more convenient.

Official support address:

support@nexusmods.com

A moderator may also be contacted through the website.

When requesting review, Nexus asks authors to include a link to the mod page.

For HRS, provide a concise factual request.

Recommended information:

- hidden/unpublished Nexus mod-page link;
- HRS version;
- uploaded filename;
- statement that the file is the intended release candidate;
- brief explanation that the mod contains a C# runtime DLL;
- brief description of the DLL's purpose;
- statement that the page is intentionally being kept unpublished pending security review;
- archive SHA256;
- DLL SHA256;
- link to source repository if appropriate;
- offer to provide build/security evidence if needed.

Do not bury staff in development history unless they request it.

The objective is to make review easy.

## Suggested Support Note Structure

This is not a Nexus-required form.

It is an HRS internal template for contacting support if review is required.

Subject:

Historical Random Start - security review request - HRS <VERSION>

Body should communicate:

1. The file has been uploaded to an unpublished/hidden Nexus mod page.
2. The author intends to keep the page private until Nexus security review is complete.
3. The package contains a C# DLL because the mod must integrate with the 7 Days to Die runtime.
4. The mod performs its documented random-start / relocation functionality.
5. The release is not intended to download remote payloads, modify unrelated applications, or
   interact with unrelated processes.
6. The exact uploaded archive and runtime DLL hashes are available.
7. Source/build evidence can be provided if staff wants it.
8. Include the mod-page link Nexus requests for quarantine review.

Do not claim Nexus has approved anything until Nexus actually has.

## Support Contact Trigger

Do not necessarily email support before there is an actual review condition.

Preferred sequence:

UPLOAD
    ->
WAIT FOR AUTOMATED SECURITY RESULT
    ->
IF NORMAL PASS, CONTINUE
    ->
IF QUARANTINED / BLOCKED, CONTACT SUPPORT

This avoids creating unnecessary support work.

Exception:

If the release introduces a behavior that Nexus's own guidelines explicitly say should be
discussed with staff beforehand, contact support before publication.

An example would be executable functionality that must communicate with the internet.

## Security Status Gate

Before making HRS public, record the Nexus security result in the publication manifest.

Suggested fields:

Nexus upload completed:

Nexus security status:

VirusTotal status:

Quarantined:

Moderator review requested:

Moderator/support response:

Security gate considered satisfied:

Date/time:

Evidence/link:

The project should not record "Nexus security cleared" unless the actual Nexus state supports
that statement.

## Public Launch Gate

Preferred HRS public-launch condition:

- publication package passed local publisher checks;
- exact upload identity is recorded;
- Nexus scanning has completed;
- no unresolved quarantine/security hold remains;
- Nexus page content is ready;
- human author approves public launch.

Then:

MAKE MOD PAGE PUBLIC.

This separates:

NEXUS SECURITY ONBOARDING

from:

PUBLIC RELEASE.

## Official Nexus References

Current Nexus guidance used when preparing this document:

Nexus Mods File Submission Guidelines
https://help.nexusmods.com/article/28-file-submission-guidelines

Nexus Mods - Why has my mod been quarantined?
https://help.nexusmods.com/article/117-why-has-my-mod-been-quarantined

Nexus Mods - Virus Scanning at Nexus Mods
https://help.nexusmods.com/article/128-anti-virus-false-positives

Nexus Mods - Best Practices for Mod Authors
https://help.nexusmods.com/article/136-best-practices-for-mod-authors

Nexus Mods - Contact Us
https://help.nexusmods.com/article/125-contact-us

These references should be rechecked before a future publication if substantial time has
passed, because publisher policies can change.

## Final HRS Nexus Rule

UPLOAD THE REAL RELEASE.

KEEP IT HIDDEN WHILE THE SECURITY GATE IS UNRESOLVED.

LET NEXUS SCAN THE ACTUAL BYTES.

IF QUARANTINED, PRESERVE THE FILE AND REQUEST REVIEW WITH THE MOD-PAGE LINK.

DO NOT MAKE THE FIRST PUBLIC IMPRESSION AN UNRESOLVED SECURITY HOLD.

PASS THE PUBLISHER GATE FIRST.

THEN GO PUBLIC.