# Historical Random Start: biome selection dev manifest

Status: **UX prototype approved for development handoff**
Baseline: **1.2.4-qa.001** (7 Days to Die V3.3.0 b14; Windows, PowerShell 5.1, local single-player)
Purpose: Let a new Random-mode character start in any eligible biome with equal biome odds, in a requested biome, or according to player-set biome weights.

## Why this work exists

The 1.2.4 QA tester confirmed that Standard and Random starts work. Two of three Random trials landed in Forest. Three trials do not establish a probability defect, but they showed a product issue: players cannot choose whether the first day should be broadly unpredictable or favor a harsher biome. The next candidate needs explicit, visible control over the biome draw.

## Approved Windows UX

Use the existing native WinForms manager style and launch path. `START.bat` invokes `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File` for the manager. The approved standalone prototype is at:

`Solution - HRS Historical Random Start v1.2.4 - 20260926/biome-selection-prototype/START.bat`

Its form source is `biome-selection-prototype/dev/ui/BiomeSelectionPrototype.ps1`. It is a visual and interaction reference only; its Apply Settings button does not write a policy or install a mod.

Keep the current **Standard** and **Random** radio buttons and exact **New game name** field. Under Random, add a compact **Random starting biome** section with these selection methods:

| Selection | UI behavior | Runtime meaning |
| --- | --- | --- |
| Any biome (equal chance) | Default choice; no extra controls | Draw uniformly from biomes with an eligible placed POI in the active world. |
| Choose a biome | Show Forest, Burnt Forest, Desert, Snow, Wasteland dropdown | Attempt only the requested biome. |
| Set custom weights | Open the separate native **Edit weights...** dialog | Draw among eligible biomes in proportion to their positive weights. |

The custom dialog has five integer controls, each from 0 through 100, and shows the normalized percentage beside each biome. Its prototype defaults are **Forest 10, Burnt Forest 20, Desert 20, Snow 25, Wasteland 25**. A zero weight excludes that biome. Block saving an all-zero set. Retain edited values while the manager stays open, including when switching selection methods. When opening an already configured game, show its saved selection rather than silently resetting the form to Standard.

Keep **Protect from hazards in starting biome** as a separate checkbox. It affects protection after a completed arrival and never changes selection odds. Preserve the manager's confirmation popup, Apply Settings, Launch Game, Uninstall Mod, and game-root display. Main and weight-dialog controls must remain readable at Windows display scaling of 100%, 150%, and 200%; fit the main form within the available screen height or provide working scroll access.

## Runtime selection contract

1. Use the existing curated historical catalog and actual placed POIs in the active world. Resolve each candidate placement to one of the five supported biome categories. Keep the current supported map scope: Navezgane and Random Gen worlds of at least 8K.
2. A biome is eligible for the draw only when at least one catalog-approved placed POI exists there. Do not substitute map area, raw biome area, or total POI count for biome odds.
3. **Any biome:** each eligible biome has probability `1 / eligibleBiomeCount`. **Chosen biome:** its probability is 1 if eligible. **Custom weights:** for each eligible biome with a positive weight, probability is `weight / sum(eligible positive weights)`. Ignore absent biomes and zero weights when normalizing.
4. Select one biome first. Then retain the 1.2.4 within-biome behavior: attempt at most five distinct placed POI instances in that biome, with the same guarded placement, rollback, and verification. A failed attempt does not silently move the player into another biome.
5. If the chosen biome is absent, the weighted eligible pool is empty, all attempts fail, or no usable trader route can be established, keep the ordinary start. Report a specific sanitized reason. Never report a requested-biome arrival unless placement completed there.
6. Preserve the one-shot completed marker: reload, ordinary respawn, and changing manager settings for an already started character do not draw another destination. Preserve current trader behavior, including a real trader in another biome when needed, and current starting-biome hazard protection semantics.
7. Log the selection method, requested biome or weights, eligible biome pool, selected biome, attempted POI biome, and final outcome in the existing sanitized diagnostic style. These fields must let QA distinguish biome selection from later safety fallback.

The application-level biome IDs and the mapping from game biome names need an explicit table in source. Verify that mapping against the 1.2.4 runtime and both supported world types; do not rely on display labels alone.

## Policy, upgrade, and deployment contract

The current manager and DLL accept only `Standard`, `Random`, and `RandomSafe` in exact-shape `hrs-policy/v1` JSON. Both sides validate the canonical field order and SHA-256 policy digest. The new controls therefore require a coordinated policy revision and newly built runtime. Keep the top-level mode/protection meaning and add a separate biome-selection setting; do not encode biome choices as additional `mode` values.

Define a versioned policy with these logical fields: exact Game Name, revision, Standard/Random/RandomSafe mode, selection kind (`Any`, `Chosen`, `Weighted`), chosen biome when applicable, all five integer weights, timestamp, and digest. The manager and DLL must agree on canonical serialization, digest input, valid ranges, and the mapping to runtime biome IDs. Update policy readback, atomic writing, bridge ownership, deployment inventory, recovery history/snapshots, and result correlation where the revised policy affects them. Ensure only one policy is authoritative after upgrade; reject ambiguous or malformed bridge state.

On an explicit upgrade Apply Settings action, migrate an existing 1.2.4 policy as follows: `Standard` remains Standard; `Random` becomes Random with Any biome; `RandomSafe` becomes Random with Any biome and protection on. Preserve exact Game Name and advance the revision. Do not discard saves, progress, unrelated files, or completed one-shot markers. Reject unsupported game builds and mismatched package/runtime hashes as the current manager does.

The extracted `1.2.4-qa.001` package contains PowerShell manager modules and a verified `d0163.dll`, but not the matching C# source for its 1.2.4 POI resolver. Its verified DLL SHA-256 is `D0B4F6EC8E7E17042869484AAC608BFB8472F0C348C2063FA08245BDEDA08617`. The C# source visible in the older `nexus1` prototype predates the 1.2.4 resolver. Locate the matching source or reconstruct and validate the current runtime before extending it; changing the GUI alone cannot change landings.

## Verification before a new QA package

- Policy round trips through manager and DLL with identical digest; malformed schema, unknown biome, invalid weight, all-zero Weighted selection, reordered fields, and tampered digest fail closed.
- Deterministic selector tests cover equal biome odds independent of placement counts, weighted normalization after absent biomes are removed, zero weights, a single positive weight, and a chosen biome absent from the world.
- Manager tests cover reopening a saved selection, switching modes without losing entered weights, canceling the weight dialog, protection independent of biome odds, and the existing confirmation, upgrade, uninstall, and ownership checks.
- In-game QA covers Standard, Any, each chosen biome available in the world, custom weights, safe fallback, trader route, protection, reload, and respawn on Navezgane and supported Random Gen worlds.
- Visual QA at 100%, 150%, and 200% scaling checks the main popup and the separate weight dialog for clipped controls, overlap, and access to bottom buttons.
- Package a new candidate ID and version with updated DLL/ModInfo hashes, manifest, README, and a clean ZIP. Test the extracted ZIP through its own `START.bat`. Do not change the approved `1.2.4-qa.001` artifact in place.

## Handoff output

Return the source changes, reproducible build instructions, new QA ZIP, package/file hashes, test results, and a short list of any behavior that differs from this manifest. Bring that new candidate back to this QA workspace for installation and live game testing.
