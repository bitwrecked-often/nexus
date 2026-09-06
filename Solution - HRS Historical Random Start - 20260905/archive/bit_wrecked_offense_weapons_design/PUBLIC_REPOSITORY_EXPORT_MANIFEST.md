# Public Repository Export Manifest

This local folder is a disaster-recovery workspace. It is **not** the folder to
push wholesale to a public Git hosting service.

Create a separate clean repository for the public framework. Start with a
fresh copy and include only reviewed material.

## Include in the initial public framework repository

* `README.md`, `LICENSE.md`, `SECURITY.md`, `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, `MAINTAINERS.md`, `SELF_CERTIFICATION.md`, and
  `OPENSSF_READINESS.md`.
* `FRAMEWORK_NORMALIZATION_TEMPLATE.md` and `RECIPE_CATALOG_AND_DR.md`.
* `blank_working_example/`, after its files are reviewed in the exported copy.
* `release_templates/`, including the full GPL license text.
* `tools/Test-FrameworkIntegrity.ps1`, `.github/workflows/`, and
  `.github/dependabot.yml`.

## Exclude from the initial public repository

* `recovery_artifacts/` — it contains large offline Git history and a local
  snapshot. Preserve it privately and in backup storage instead.
* Game installs, game saves, player data, credentials, logs, and anything from
  the Steam directory outside the framework export.
* Any active or unfinished mod payload, including the offense-weapons solution.
* Any third-party material or historical reference file whose ownership and
  release rights have not been explicitly reviewed.

## Conditional material: frozen 4.1.1 reference

`framework_reference_4.1.1/` is valuable recovery and learning material, but
it must be reviewed as a separate publication decision. Do not include it by
default in the first public export because it contains historical packages,
assets, and previous release material. If later published, strip obsolete
archives and re-check every file for ownership, licensing, private paths, and
unsupported claims.

## Final owner checks before the first push

1. Replace maintainer placeholders with the public repository identity.
2. Enable GitHub private vulnerability reporting.
3. Enable protected default-branch rules requiring pull-request review where
   the hosting plan permits it.
4. Confirm GPL-3.0-or-later is the intended license for every included file.
5. Run `pwsh -File .\tools\Test-FrameworkIntegrity.ps1` in the clean export.
6. Review `git status --ignored` and the staged file list before the first
   commit; the public repository must contain only the files approved above.
