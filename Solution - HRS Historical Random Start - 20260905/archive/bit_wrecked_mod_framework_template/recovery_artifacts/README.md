# Recovery Artifacts

This folder makes the template recoverable if the working repository, its
untracked template files, or its normal Git metadata are lost.

## Contents

- `bit_wrecked_mod_framework_template_snapshot.zip` — the original portable
  template capture, retained unchanged as a recovery point.
- `bit_wrecked_mod_framework_template_snapshot_ux_guidance_0.0.1.zip` — the
  pre-implementation capture containing the module-host handoff and
  UX/performance guidance, retained unchanged as an earlier recovery point.
- `bit_wrecked_mod_framework_template_snapshot_module_host_0.0.1.zip` — the
  current recommended portable capture. It contains the completed read-only
  Module Host, reviewed adapters, comparison matrix, tests, implementation
  report, framework material, and directory layout. It intentionally does
  **not** contain this `recovery_artifacts` folder, preventing a recursive
  archive.
- `root-repository-history.bundle` — an offline Git bundle of all reachable
  history and refs in the outer 7 Days To Die workspace repository.  It is
  large by design; it is the history escape hatch, not a release package.
- `data-config-history.bundle` — an offline Git bundle for the separate
  `Data/Config` repository.
- `RECOVERY_ARTIFACTS_SHA256.txt` — the recorded SHA-256 values for the five
  artifacts above.

## Verify before recovery

From this directory, calculate a SHA-256 value for each artifact and compare
it with `RECOVERY_ARTIFACTS_SHA256.txt`:

```powershell
Get-FileHash -Algorithm SHA256 .\bit_wrecked_mod_framework_template_snapshot_module_host_0.0.1.zip
Get-FileHash -Algorithm SHA256 .\bit_wrecked_mod_framework_template_snapshot_ux_guidance_0.0.1.zip
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
