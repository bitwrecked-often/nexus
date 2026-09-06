# Bit Wrecked Mod Framework Template

This is a reusable starting point for a new independent Bit Wrecked mod that
uses an existing completed mod as its operational framework.

It is not a game mod, a release lane, or a package to install.

If this is the only surviving artifact after a disaster, begin with
`RECOVERY_START_HERE.md`.

Use `FRAMEWORK_NORMALIZATION_TEMPLATE.md` to create the new mod's first active
version-lane manifest. It preserves the framework recipes while requiring the
new mod to establish its own identity, payload map, ownership, validation,
packaging, and recovery rules.

`RECIPE_CATALOG_AND_DR.md` contains the detailed eleven-recipe catalog and
disaster-recovery model. It is embedded here so the template remains usable if
the Planner area or completed reference solutions are unavailable.

Keep completed reference mods as separate sibling solutions. Keep copied
historical material in the new mod's `framework_archive/`, not in its active
`versions/` history.

## Public-project readiness

This local template is prepared for eventual publication as a Free/Libre and
Open Source Software framework. It is not yet a public repository, enrolled
in OpenSSF, or awarded an OpenSSF badge.

Before publication, follow `PUBLIC_REPOSITORY_EXPORT_MANIFEST.md` to create a
clean public export. In particular, do not publish recovery-history bundles,
private workspace history, game saves, game files, or any reference material
whose ownership has not been reviewed for release.

Public-facing project policies and evidence live in:

* `LICENSE.md`
* `SECURITY.md`
* `CONTRIBUTING.md`
* `CODE_OF_CONDUCT.md`
* `MAINTAINERS.md`
* `OPENSSF_READINESS.md`
* `SELF_CERTIFICATION.md`
