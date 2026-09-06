# [Mod Name]

## What it does

[One short paragraph describing the exact player-facing promise.]

## What it does not do

* [Explicit exclusion]
* [Explicit exclusion]
* [Explicit exclusion]

## Requirements

* 7 Days to Die `[supported version/build]`
* Windows `[supported version]`, if the helper tool is Windows-only
* [Server/client or EAC facts; do not make unsupported universal promises]

## Quick install — XML modlet

1. Close the game and any dedicated server.
2. Extract `[No-scripts archive]`.
3. Place the folder containing `ModInfo.xml` directly inside:

   ```text
   [7 Days to Die game folder]/Mods/
   ```

4. Start the game/server and inspect the log for mod/XML errors.

## Optional helper tool

[Describe the optional GUI/tool and exactly what it can write. State that it
does not download content, use hidden network calls, or require elevation if
those facts have been validated.]

## Removal

1. Close the game/server.
2. Remove only this mod's owned folder:

   ```text
   [game folder]/Mods/[InternalName]
   ```

3. Start once and check the log.

[Describe any separate owned setting restore procedure.]

## Compatibility

[List exact XML targets and known conflicts. Explain server/client requirements
without guessing.]

## Support information to include in a report

* Mod version
* Game version/build
* Single-player, peer-hosted, or dedicated server
* Other mods touching the same target files
* Relevant log lines
* Exact steps that led to the problem
