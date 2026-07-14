# Release Process

This repository separates preparation, candidate construction, technical
promotion, and public publication. Passing one stage never grants authority for
the next.

## Sources Of Truth

- Each active solution's `release-manifest.json` owns its package version,
  lifecycle intent, edition contracts, exact allowlists, and planned filenames.
- Root `VERSION` is a checked projection for the currently active solution
  line. It is not permanent multi-solution version authority.
- `ModInfo.xml` owns the game-facing runtime ID. Its display name and version,
  the GUI version, README, changelog, release evidence, archive filename, and
  Nexus draft metadata must agree with the solution manifest before a candidate
  can pass.
- `governance/EXECUTION_PLAN.md` owns workflow phase only. It cannot prove a
  release, compatibility result, or external publication.
- A Git tag, GitHub Release, and Nexus served file each prove only their own
  recorded external state.

During development, root `VERSION` uses `MAJOR.MINOR.PATCH-dev`. Candidate
source uses the exact intended `MAJOR.MINOR.PATCH` while lifecycle fields retain
the non-public release-candidate state. Frozen payload metadata may remain at
the parent version only until the before-state is fingerprinted and the release
projections are authorized for preparation.

## Protected History

- Annotated tag `v4.0.1` and its three committed ZIPs are grandfathered immutable
  evidence.
- Never rebuild, repair, rename, replace, or move those archives or their tag.
- The legacy validator's `-RebuildZip` mode is disabled because its defaults
  target those historical paths.
- New archives are generated only below ignored `dist/<solution>/<version>/` and
  become release attachments, not Git blobs.

## Development And Validation

1. Work on the active development branch with the technical behavior boundary
   recorded in governance.
2. Capture the exact baseline before editing solution-facing metadata or docs.
3. Reconcile the per-solution manifest, version projections, customer guide,
   edition allowlists, compatibility evidence, and release gates.
4. Run the manifest-driven offline validation command. It must not launch the
   customer tool, read a game installation, use the network, rebuild ZIPs, or
   write to `dist/`.
5. Keep unsupported optional editions blocked rather than borrowing another
   edition's claims or inventing evidence.

The current safe command is:

```powershell
pwsh -NoProfile -File tools/release/Invoke-NexusPackage.ps1 `
  -ManifestPath solutions/7dtd_wasteland_animal_population_tuning_files/release-manifest.json `
  -Action Validate
```

### Disposable integration coverage

`tests/release/Invoke-OfflineTests.ps1` is deliberately broader than the
read-only `Validate` action. On Windows it creates owned local clones under the
system temporary directory and exercises exact staging, two deterministic test
ZIP builds, a test-only technical promotion, and packaged GUI smoke. Test
receipts are machine-labeled `disposable-test-fixture`; every authority record
sets `ownerCandidateCycleConsumed` false, and the final test-promotion receipt
sets `candidateAuthority` false. They live only under the clone's
`dist/.test-fixtures/` namespace, and the harness deletes the entire clone after
the check.

The test-only `ExecutionClass` and ownership-token parameters are reserved for
that harness. Any mutating use rejects them outside an exact owned
`nexus-offline-prepare-<guid>/repository` system-temp clone with a matching
Git-scoped marker. A CLI `-WhatIf` may preview the derived fixture namespace
without that marker, but it writes nothing and grants no authority. Fixture
execution cannot write the real candidate path. These tests do not consume the
one owner-authorized P4 cycle and do not edit a game installation, rebuild a
historical ZIP, use the network, contact Nexus, or publish anything.

## Source Staging

`StagePrimary` is a diagnostic source-staging action, not the P4 release path.
After offline validation passes, an explicit maintainer may use it to exercise
the primary eight-file source stage under the manifest-derived ignored candidate
path. Diagnostic staging:

- requires a clean committed worktree;
- materializes exact Git-blob bytes from the clean current `HEAD`;
- refuses any existing output for that solution/version;
- rechecks historical hashes;
- promotes the staged tree and working evidence together with one same-volume
  version-root move;
- writes only under ignored `dist/`;
- does not create a ZIP, touch `final-upload/`, or authorize publication.

Use `-WhatIf` before a diagnostic staging action. `StagePrimary` and
`PreparePrimary` are mutually exclusive for a solution/version output root:
choose the diagnostic stage or the authorized atomic P4 path, never both. Do not
run `StagePrimary` before `PreparePrimary`; existing output must cause the P4
path to fail closed.

## Release-Readiness Gate

Before candidate construction, present one concise report containing:

- exact version, source commit, edition, filename, and eight-file inventory;
- validation and historical-hash results;
- compatibility evidence levels and live checks still pending;
- known risks, rollback/removal behavior, and blocked optional editions;
- confirmation that no public action has occurred.

The owner must accept this planning set before the one controlled candidate
cycle begins.

## Atomic P4 Candidate Preparation

After recorded owner acceptance of the P3 planning set, `PreparePrimary` is the
sole supported mutating P4 path. It owns source staging, two-build
reproducibility comparison, candidate inspection, and technical promotion as
one guarded transaction. Preview the authorized path with:

```powershell
pwsh -NoProfile -File tools/release/Invoke-NexusPackage.ps1 `
  -ManifestPath solutions/7dtd_wasteland_animal_population_tuning_files/release-manifest.json `
  -Action PreparePrimary `
  -WhatIf
```

Remove `-WhatIf` only for the recorded owner-authorized P4 cycle. The action
must require a clean candidate-profile `HEAD`, an absent solution/version output
root, exact protected-history hashes, and the manifest's eight-file mapping.

The archive contract is fixed and machine-readable:

- format: standard non-password-protected ZIP with no nested archive;
- compression: `store` (no compression);
- entry order: ordinal sort by stage path;
- entry timestamp: `2000-01-01T00:00:00Z`;
- archive path separator: `/`;
- reproducibility builds: exactly two independent temporary builds.

`PreparePrimary` must compare the two archive digests, extract and inspect the
candidate, reject any entry outside the exact allowlist, and prove every archive
file equals its staged source bytes. It may retain only the manifest-named
candidate and may promote only those same validated bytes into:

```text
dist/7dtd_wasteland_animal_population_tuning/4.1.0/final-upload/
```

That directory contains the exact uploadable ZIP only. Checksums, inventories,
provenance, and receipts remain outside it under:

```text
dist/7dtd_wasteland_animal_population_tuning/4.1.0/evidence/
|-- primary-source-stage.json
|-- primary-package-build.json
`-- primary-final-upload.json
```

A failed check must leave no promoted artifact and return the work to planning;
it does not authorize changing frozen technical behavior. A successful receipt
may report `technicallyReady: true`, but must retain
`approvedForPublication: false`. Presence in `final-upload/` never authorizes a
merge, tag, GitHub Release, Nexus upload, served-file change, or prior-file
archival.

## Durable P4 Evidence Checkpoint

After a successful candidate-class `PreparePrimary`, preserve the ignored JSON
receipts as working evidence and create a sanitized tracked record under the
manifest-declared durable root:

```text
evidence/releases/7dtd_wasteland_animal_population_tuning/4.1.0/
|-- RELEASE_ACCEPTANCE.md
|-- SHA256SUMS.txt
|-- INVENTORY.json
`-- PROVENANCE.json
```

The durable record must bind the candidate execution class, exact source
commit, manifest digest, execution-plan and accepted-readiness digests, working
receipt digests, archive filename/size/SHA-256, exact entry inventory/hashes,
toolchain, compatibility limits, rollback/removal notes, and every remaining
public gate. Remove machine names, user paths, private tester identity, and raw
diagnostics. Do not copy the ZIP into Git, change its bytes, fill publication
fields, or treat a disposable fixture receipt as release evidence.

Commit and validate this record separately after candidate preparation. P4 is
complete only when the source commit, promoted ZIP, ignored receipts, and
tracked durable record cross-bind without contradiction. Publication remains a
later owner decision.

## Public Release Dependencies

Each public action requires explicit owner authorization. Before public work,
the owner must select and record whether `main` represents release-accepted
source or Nexus-served source, the permitted merge method, the merge/tag order,
and the exact future tag naming rule. No current document infers those choices.

Regardless of that selected repository lifecycle, the following dependencies
must hold:

1. Finalize every in-archive version and any date/state wording in the README and
   changelog before the one candidate build, then freeze that source commit.
2. Record approval and the actual source commit outside the committed manifest;
   a commit cannot contain its own SHA. Use the selected merge/tag order to
   create an immutable tag at the exact approved source commit.
3. Prove that the tag tree, staged source, and packaged bytes correspond.
4. Create the GitHub Release and attach the exact checksum-verified promoted ZIP.
5. Upload the same ZIP bytes to Nexus unless a channel-specific variant is
   explicitly declared, named, and independently evidenced.
6. Download or inspect the newly served Nexus file and verify its identity,
   contents, and checksum.
7. Only after the new file is confirmed should the owner hide or archive the
   prior Nexus file.
8. Record GitHub and Nexus URLs, served hashes, publication date, and final
   lifecycle state in durable sanitized evidence excluded from the archive.

No CI workflow may merge, tag, create a release, upload to Nexus, or hide a
served file. Corrections after publication require a new semantic version; never
move a published tag or silently replace bytes under an existing identity.
