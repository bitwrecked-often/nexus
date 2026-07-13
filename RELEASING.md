# Release Process

This repository separates preparation, candidate construction, technical
promotion, and public publication. Passing one stage never grants authority for
the next.

## Sources Of Truth

- Each active solution's `release-manifest.json` owns its package version,
  lifecycle intent, edition contracts, exact allowlists, and planned filenames.
- Root `VERSION` is a checked projection for the currently active development
  line. It is not permanent multi-solution version authority.
- `ModInfo.xml` owns the game-facing runtime ID. Its display name and version,
  the GUI version, README, changelog, release evidence, archive filename, and
  Nexus draft metadata must agree with the solution manifest before a candidate
  can pass.
- `governance/EXECUTION_PLAN.md` owns workflow phase only. It cannot prove a
  release, compatibility result, or external publication.
- A Git tag, GitHub Release, and Nexus served file each prove only their own
  recorded external state.

During development, root `VERSION` uses `MAJOR.MINOR.PATCH-dev`. Frozen payload
metadata may remain at the parent version only until the before-state is
fingerprinted and the release projections are authorized for preparation.

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

## Source Staging

After offline validation passes, an explicit maintainer action may stage the
primary eight-file source tree under the manifest-derived ignored candidate
path. Staging:

- requires a clean committed worktree;
- materializes exact Git-blob bytes from the clean current `HEAD`;
- refuses any existing output for that solution/version;
- rechecks historical hashes;
- promotes the staged tree and working evidence together with one same-volume
  version-root move;
- writes only under ignored `dist/`;
- does not create a ZIP, touch `final-upload/`, or authorize publication.

Use `-WhatIf` before an authorized staging action. Do not stage during planning
merely to see what happens; the manifest and validation should settle the shape
first.

## Release-Readiness Gate

Before candidate construction, present one concise report containing:

- exact version, source commit, edition, filename, and eight-file inventory;
- validation and historical-hash results;
- compatibility evidence levels and live checks still pending;
- known risks, rollback/removal behavior, and blocked optional editions;
- confirmation that no public action has occurred.

The owner must accept this planning set before the one controlled candidate
cycle begins.

## Candidate And Technical Promotion

Candidate tooling must build from the verified source stage, use deterministic
entry ordering and byte policy, inspect the extracted archive, build twice in
temporary work areas for a digest comparison, and retain only one named
candidate. A failed check returns to preparation; it does not authorize changing
the frozen technical behavior.

Only a fully validated candidate may be copied atomically into
`dist/<solution>/<version>/final-upload/`. That directory contains uploadable ZIP
bytes only. Its presence means technically ready, not publication-approved.

## Public Release Dependencies

Each public action requires explicit owner authorization. Before public work,
the owner must select and record whether `main` represents release-accepted
source or Nexus-served source, the permitted merge method, the merge/tag order,
and the exact future tag naming rule. No current document infers those choices.

Regardless of that selected repository lifecycle, the following dependencies
must hold:

1. Finalize every in-archive version, date, state, README, and changelog
   projection before the one candidate build, then freeze that source commit.
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
