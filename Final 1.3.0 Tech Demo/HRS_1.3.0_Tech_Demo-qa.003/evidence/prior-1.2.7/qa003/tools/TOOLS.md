# Unified public package tooling

The owner requires the complete same ZIP for QA, customers and Nexus, including
source, history, lore and evidence. The new exporter mode implements that
instruction while preserving the sealed split-format candidates and their
legacy tool behavior.

`Export-HrsCandidate.ps1 -PublicContentRoot` creates one ZIP with the runnable
customer payload, frozen `context`, portable QA tools and public development
material. `distribution-manifest.json` records every other shipped file and its
SHA-256. The customer and context manifests retain their separate, exact file
sets within that full distribution. The public customer payload also contains
the full GPL license text required by its existing license notice.

An archive cannot contain its own final archive SHA-256 without creating a
self-reference. The embedded `public-package-receipt.json` therefore records
the runtime, XML, contracts, build and component manifest identities. The
shared `New-HrsPublicArchiveReceipt` function adds the completed archive digest,
outer manifest digest and embedded receipt digest after compression. The DEV
export receipt is reproducible from the sealed public ZIP and is not a separate
required public download.

`New-HrsQaWorkspace.ps1` accepts a registered candidate from the DEV registry. A
standalone copy of the public tools requires `-ExpectedArchiveSha256` from the
release handoff or published checksum. It verifies that digest and every ZIP
entry before extraction, then materializes the archive-bound receipt and local
QA registry beside the unchanged ZIP. These generated local QA files do not
change or recompress the public artifact.

`Test-HrsCandidateArchive` and `Assert-HrsWorkspace` retain the legacy archive,
receipt and companion behavior. For unified distributions they verify the
entire public tree, including source, history, lore, evidence and tools. Only
the local copy of the sealed archive, its derived receipt, the generated tool
registry and the established private manager state directory are additional
allowed files. QA run outputs must be placed outside the frozen public tree.
The existing Start, Record, Export and Complete QA commands work without
special handling for the new format.

## Executed DEV verification

All commands ran in Windows PowerShell 5.1 on disposable fixtures:

- `Test-HrsUnifiedPublicPackage.ps1`: 40/40 checks passed. It exercises the
  actual opt-in exporter, registered and standalone extraction, exact receipt
  reconstruction, malformed ZIP rejection, public tree drift, private manager
  state, and the actual QA Start/Record/Export/Complete entry points. A synthetic
  blocked run cannot approve the missing independent cases.
- `Test-HrsCandidateWorkflow.ps1`: 39/39 legacy workflow checks passed.
- `Test-HrsCandidateBranding.ps1`: 12/12 legacy branding checks passed.
- `Test-HrsQaTools.ps1`: 64/64 native parser and generic tooling checks passed.

The JSON records are `tool-verification.json` and
`legacy-tool-verification.json`. Their source hashes identify the tested tool
bytes. The test harness preserves original candidate 002, its companion and
receipt, and the real registry. All temporary registry mutations and simulated
QA decisions remain in disposable test directories.

These are software tool fixtures. They perform no installed game writes or
game launch, pass no independent customer QA case, and grant no release or
publication approval.
