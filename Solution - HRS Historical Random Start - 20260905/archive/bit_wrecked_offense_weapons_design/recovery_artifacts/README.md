# Recovery Artifacts

This folder makes the template recoverable if the working repository, its
untracked template files, or its normal Git metadata are lost.

## Contents

- `bit_wrecked_mod_framework_template_snapshot.zip` — a portable copy of the
  complete template as it existed at capture time, with its directory layout
  preserved.  It contains the blank working example, frozen 4.1.1 framework
  reference, release templates, recovery guide, and recipe catalog.  It
  intentionally does **not** contain this `recovery_artifacts` folder,
  preventing a recursive archive.
- `root-repository-history.bundle` — an offline Git bundle of all reachable
  history and refs in the outer 7 Days To Die workspace repository.  It is
  large by design; it is the history escape hatch, not a release package.
- `data-config-history.bundle` — an offline Git bundle for the separate
  `Data/Config` repository.
- `RECOVERY_ARTIFACTS_SHA256.txt` — the recorded SHA-256 values for the three
  artifacts above.

## Verify before recovery

From this directory, calculate a SHA-256 value for each artifact and compare
it with `RECOVERY_ARTIFACTS_SHA256.txt`:

```powershell
Get-FileHash -Algorithm SHA256 .\bit_wrecked_mod_framework_template_snapshot.zip
Get-FileHash -Algorithm SHA256 .\root-repository-history.bundle
Get-FileHash -Algorithm SHA256 .\data-config-history.bundle
```

To verify that Git can read the retained history:

```powershell
git bundle verify .\root-repository-history.bundle
git bundle verify .\data-config-history.bundle
```

For the full restore order and the meaning of each recovery layer, read
`..\RECOVERY_START_HERE.md` first.  Do not run the frozen 4.1.1 animal-mod
scripts as part of template recovery; they remain reference material only.
