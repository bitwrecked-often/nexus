# Frozen 4.1.1 Framework Reference

`framework_reference_4.1.1/` is a complete, local recovery snapshot of the
working Wasteland Animal Population Tuning framework that this template was
distilled from.

It preserves the actual working source and release support material, including:

* Main GUI tool source
* Batch launcher
* Advanced command-line installer and uninstaller
* Validation and packaging script
* Modlet metadata and XML payload example
* GUI manifests, QA/build runbook, and technical manifest
* GPL license, copyright notice, legal/use notes, metadata, release notes,
  changelog, README, and publishing/SEO material
* Assets, upload notes, hashes, release archives, and historical version lanes

## Why this is here

The blank working example is the safe neutral starting point for a new mod. The
frozen reference is the complete operational fallback if this template is the
only surviving artifact after a disaster.

Together they preserve both halves of the framework:

* `blank_working_example/` — neutral, runnable, no payload, no writes
* `framework_reference_4.1.1/` — full working implementation and all release
  support material

## Important boundary

The frozen reference is not a new mod, not an active version lane, and not a
payload to relabel and publish. Its animal-specific identity and behavior are
historical reference material.

To begin a new mod:

1. Start from `blank_working_example/` and
   `FRAMEWORK_NORMALIZATION_TEMPLATE.md`.
2. Use the frozen reference only to recover or adapt a specific operational
   recipe.
3. Establish the new mod's identity, evidence map, payload ownership, and
   validation rules before copying implementation code.
4. Never copy an animal gameplay claim or XML target by accident.

## Recovery use

If the rest of the project is lost, this template provides the GPL-covered
source, full package structure, documentation examples, and release patterns
needed to rebuild a new independent mod framework. Verify the target game
version and rebuild all payload-specific behavior before any public release.
