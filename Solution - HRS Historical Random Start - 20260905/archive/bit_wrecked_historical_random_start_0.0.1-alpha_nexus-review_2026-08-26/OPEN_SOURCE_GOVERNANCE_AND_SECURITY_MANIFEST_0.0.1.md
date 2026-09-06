# Open-Source Governance and Security Manifest 0.0.1

Status: Active pre-implementation contract

License: GPL-3.0-or-later

Security model: Linux Foundation OpenSSF-aligned; not certified or badged

## Accurate Standard Name and Claims

The governing security reference is the Open Source Security Foundation
(OpenSSF), a Linux Foundation project. Project records may use “OpenSSF” or
“Linux Foundation/OpenSSF.” They must not claim compliance, certification, an
OpenSSF Best Practices badge, an OpenSSF Scorecard result, SLSA level, provider
approval, or independent audit until the named process has produced evidence.

The first formal baseline target is **OpenSSF OSPS Baseline v2026.02.19**. Pin
that exact version in assessments so later baseline changes do not silently
rewrite the release gate. The first badge target is OpenSSF Best Practices
**Passing**. Both are self-assessment activities; neither replaces technical
testing, provider review, or owner release approval.

## Licensing Contract

- Project-owned source, scripts, documentation, templates, and examples are
  licensed `GPL-3.0-or-later`.
- Every distributed source package must contain the full corresponding GPL
  license text and preserve copyright and SPDX notices.
- Every distributed binary must be accompanied by corresponding source, or a
  GPL-compliant written/source-access mechanism appropriate to that method of
  distribution.
- Build instructions, dependency identities, generated-file provenance, and
  the scripts needed to recreate the distributed binary belong with the source.
- Proprietary 7 Days to Die files, Steam/Valve material, The Fun Pimps assets,
  saves, logs, credentials, and third-party content without redistribution
  permission must never enter the public package.
- “Open source” does not grant trademark rights or make this an official game
  product.

The current `LICENSE.md` is a license summary. Its referenced full GPL text is
not yet present locally. Packaging and publication therefore remain blocked
until `release_templates/LICENSE-GPL-3.0-or-later.txt` is added and verified.

## Security and Supply-Chain Contract

The project must be secure by design, secure by default, least-privileged,
local-only unless explicitly disclosed, and transparent about every write.
Before a releasable DLL or launcher exists, evidence must cover:

- source ownership, review, and narrow change scope;
- deterministic or repeatable build instructions and recorded tool versions;
- dependency inventory, origin, license, version, and SHA-256 hashes;
- an SBOM for the exact release artifact;
- source, dependency, secret, and malware scanning with dated results;
- tests for path validation, path escape, malformed state, partial writes,
  rollback, unsupported versions, and fail-closed behavior;
- hashes linking source commit, build inputs, DLL, package, SBOM, and test log;
- no embedded tokens, telemetry, credential collection, obfuscation, hidden
  downloads, privilege-elevation bypass, or undocumented persistence;
- vulnerability-reporting, maintenance, contribution, and disclosure routes;
- reproducible removal and recovery instructions; and
- a provider-specific review performed against the provider’s current rules at
  submission time.

OpenSSF Scorecard, SLSA, and Sigstore are future hardening/evidence mechanisms,
not present-tense claims. Adopt each only when the repository and build system
can produce honest, inspectable evidence.

## Decision and Release Authority

The Bit Wrecked project steward owns product scope and release approval. A
stronger AI may propose, implement, test, and document choices within the
manifest, but may not waive a safety gate, invent evidence, accept a license,
publish, or represent provider approval.

Any conflict resolves in this order:

1. user safety, law, and third-party rights;
2. GPL obligations and the declared public-source boundary;
3. this project’s manifest and security/write boundaries;
4. pinned OpenSSF assessment controls;
5. current provider submission rules;
6. implementation convenience.

## Evidence States

Each control is one of: `Not assessed`, `Not applicable` with rationale,
`Planned`, `Implemented`, `Verified`, or `Externally reported`. “Implemented”
is not “Verified.” A document’s existence is not proof that its control works.

## Immediate Gate

No compile, live-game copy, package, publication, provider submission, badge
claim, or security claim is authorized by this document. The next governance
work is to complete project-specific reporting, contribution, maintenance, and
readiness records, add the full GPL text, and map evidence to the pinned OSPS
Baseline before the first build.
