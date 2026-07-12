# Private Field-Test Program

Use this process while a mod is shared only with a small invited testing group. Keep tester identities and private communications outside this repository.

## Purpose

Private testing turns subjective impressions into reproducible evidence without pretending that a small test group proves universal compatibility. The goal is to discover sharp edges, improve the front end, and establish honest support boundaries before public promotion.

## Build Identity

Every test package must have:

- a unique semantic pre-release version or build identifier;
- the source commit that produced it;
- a package checksum;
- the intended game version and platform;
- a short list of changes since the prior test build.

Never distribute two different archives under the same version and filename.

## Test Brief

Give testers a short brief containing:

- what changed;
- what should remain unchanged;
- install and rollback instructions;
- risky or high-load options;
- specific scenarios to exercise;
- known issues;
- the information needed in a useful report.

## Anonymized Field Report Template

```text
Build/version:
Source commit:
Game version/build:
Platform and install type:
Single-player, peer host, or dedicated server:
Relevant mods or configuration:
Feature and settings tested:
Steps performed:
Expected result:
Observed result:
Install verification result:
Restore/remove verification result:
Performance or stability observation:
Shareable log or screenshot reference:
Reproducible: yes / no / not yet
Severity: low / medium / high / release-blocking
Notes:
```

Do not record names, account handles, IP addresses, machine names, save data, or private messages.

## Evidence Classification

- **Verified:** reproduced with recorded inputs and a clear pass/fail result.
- **Observed:** seen in the field but not yet reproduced reliably.
- **Inferred:** technically plausible explanation awaiting a focused test.
- **Unverified:** expectation or report without sufficient evidence.

Public documentation must not promote an observation or inference to a verified claim.

## Triage

For every meaningful report:

1. Remove personal or machine-identifying data.
2. Confirm the build and environment.
3. Attempt reproduction against the supported baseline.
4. Record impact, likelihood, workaround, and rollback safety.
5. Decide whether to fix, document, defer, or reject as out of scope.
6. Add public-facing consequences to the changelog or known issues when appropriate.

## Release Readiness

A build is ready for public consideration when normal installation is predictable, destructive mistakes fail safely, restoration is proven, diagnostics are useful, known limitations are honest, archives are reproducible, and no release-blocking report remains unresolved.

Publication still requires explicit owner approval. Upload the new file and verify it before hiding or archiving the prior Nexus file.
