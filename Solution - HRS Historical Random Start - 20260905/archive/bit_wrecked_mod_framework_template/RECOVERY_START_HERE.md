# Recovery Start Here — Bit Wrecked Mod Framework Template

Use this document if this template is the only surviving project artifact.

## What survived

This folder contains three different recovery layers:

| Location | Purpose | Safe to run immediately? |
|---|---|---|
| `blank_working_example/` | Neutral, no-payload GUI shell | Yes; it only inspects a selected game folder |
| `framework_reference_4.1.1/` | Frozen full animal-mod framework source and release support | No; reference only until deliberately adapted |
| `release_templates/` | Neutral GPL, legal, package, README, SEO, and release templates | Yes; copy and fill placeholders only |
| `RECIPE_CATALOG_AND_DR.md` | Detailed eleven-recipe and DR reference | Yes; documentation |
| `recovery_artifacts/` | Offline snapshot, Git history bundles, and hashes | Yes; verify before relying on it |

## First ten minutes after a disaster

1. Make a second copy of this complete folder before modifying anything.
2. Read `recovery_artifacts/RECOVERY_ARTIFACTS_SHA256.txt`.
3. Verify every listed recovery artifact with `Get-FileHash -Algorithm SHA256`.
4. Read `RECIPE_CATALOG_AND_DR.md` and
   `FRAMEWORK_NORMALIZATION_TEMPLATE.md`.
5. Run `blank_working_example/Blank_BitWreckedMod.bat` only if you need to
   confirm that the neutral Windows GUI shell still starts. It does not install
   a mod or create a Mods folder.
6. Do not run the animal launcher, installer, uninstaller, or package scripts
   inside `framework_reference_4.1.1/` against a live game installation. They
   are historical working reference, not a neutral new mod.

## Path remapping for frozen reference documents

Some frozen 4.1.1 documents refer to the original project path:

```text
_game_dev_ai_tracking/solutions/7dtd_wasteland_animal_population_tuning_files/
```

When recovering from this template alone, read those references as:

```text
framework_reference_4.1.1/
```

For example, a historical command referring to:

```text
_game_dev_ai_tracking/solutions/7dtd_wasteland_animal_population_tuning_files/Support_Files_Do_Not_Edit/validate_and_package.ps1
```

maps to:

```text
framework_reference_4.1.1/Support_Files_Do_Not_Edit/validate_and_package.ps1
```

Those commands remain animal-framework examples. Adapt paths, product identity,
payload targets, ownership, and tests before using them for a new mod.

## Rebuild a new independent mod

1. Create a new solution folder beside this template.
2. Copy `blank_working_example/` into the new solution as the neutral starting
   shell.
3. Copy `FRAMEWORK_NORMALIZATION_TEMPLATE.md` into the new active version lane.
4. Create an exact line-item map from verified current game configuration.
5. Use the frozen framework only to adapt a required operational recipe.
6. Copy the needed release templates and replace all placeholders.
7. Implement payload, validation, installation, selective removal, and DR from
   the new mod's ownership map.
8. Validate before packaging or publication.

## Environment assumptions

The blank example and frozen framework expect:

* Windows with PowerShell and WinForms available
* A local 7 Days to Die installation for real mod validation
* A supported game version established by the new mod's evidence

No current mod payload, game installation, save, world, or server configuration
is embedded in this template.

## What the history bundles contain

`recovery_artifacts/` contains Git bundles from:

* The root tracking repository
* The nested `Data/Config` repository

They preserve reachable committed history only. The template snapshot archive
preserves the uncommitted template files themselves. To inspect a bundle in a
new repository:

```powershell
git clone [bundle file] [new folder]
```

or verify it from a Git-enabled folder:

```powershell
git bundle verify [bundle file]
```

## Recovery boundary

This is an escape boat for the framework and its evidence/support material. It
does not certify a future mod's gameplay payload. Every new payload still needs
its own target map, evidence, tests, version support decision, and release
authorization.
