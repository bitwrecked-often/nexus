# Bit Wrecked Framework — Self-Certification

**Status:** Self-signed framework certification

**Issued:** 2026-07-19

**Issued by:** Bit Wrecked project steward

This is a project-owned attestation, not an external audit, legal opinion,
security warranty, or platform endorsement.

## Attested baseline

At issuance, the template contains:

* a neutral blank working example with no gameplay payload;
* a retained reference framework, clearly marked as reference rather than a
  current installer;
* the eleven operational recipes and disaster-recovery guidance;
* reusable release, license, copyright, documentation, and publishing
  templates;
* recovery instructions, a structured portable snapshot, integrity hashes, and
  offline Git-history bundles;
* a documented public-export boundary; and
* local integrity checks for required policy files and PowerShell parsing.

## Verification performed at issuance

The local audit verified recovery-artifact SHA-256 values, structured snapshot
contents, PowerShell parseability, and the two offline Git bundles. See
`RECOVERY_START_HERE.md` and `recovery_artifacts/` for the recovery evidence.

## Limits

This certification does not mean every future mod payload is safe, compatible,
or approved. Each payload must earn its own evidence map, testing, release
approval, and recovery record. This certification also does not create an
OpenSSF badge; that requires a public-project self-assessment after publication.
