# Release Process

This repository uses semantic versioning and Git tags to keep published Nexus releases reproducible.

## Version Sources

- `VERSION` identifies the active repository development version.
- The modlet `ModInfo.xml` identifies the version presented to 7 Days to Die.
- `PACKAGE_METADATA.md`, `RELEASE_NOTES.md`, and `CHANGELOG.md` identify the public package version.

During development, `VERSION` uses the form `MAJOR.MINOR.PATCH-dev`. Published package files remain at their last released version until a release candidate is built. All public version sources must agree before publication.

## Branches And Tags

- `main` represents published, supportable Nexus content.
- `develop/4.1.0` contains development for the next backward-compatible feature release.
- Annotated tag `v4.0.1` preserves the immutable source baseline for the currently published release.
- Each future public release receives an annotated `vMAJOR.MINOR.PATCH` tag from the exact release commit.

## Publishing Checklist

1. Finish and test the planned feature set on the development branch.
2. Update `VERSION` from the development suffix to the final version.
3. Update `ModInfo.xml`, package metadata, release notes, and changelog to the same version and release date.
4. Run the documented validation and archive rebuild process against the supported game installation.
5. Inspect the rebuilt no-scripts Nexus archive and record its SHA-256 checksum outside the archive.
6. Merge the reviewed release commit to `main`.
7. Create and push an annotated release tag from that exact commit.
8. Upload and verify the new Nexus file before archiving or hiding the previous file.

Never modify or move an existing release tag. Corrections after publication require a new patch version.
