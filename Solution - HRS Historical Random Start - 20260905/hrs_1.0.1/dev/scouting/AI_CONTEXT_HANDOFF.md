# Historical Random Start spawn-scouting AI handoff

Status: current durable resumption packet  
Owner decision date: 2026-08-30  
Current map/build: Navezgane, 7 Days to Die V3.2 (b9)

## Resume objective

Build a balanced future random-start pool with **six certified street-level
points per zone**. The five currently observed Navezgane biome zones are Pine
Forest, Burnt Forest, Desert, Snow, and Wasteland, for an intended final pool
of 30 points if every zone reaches six.

Scout eight to ten candidates per zone and retain only the best six. Work in
batches of three or four within one zone. Selection is intended to choose the
zone first and then a point within that zone so unequal catalog counts do not
silently weight the zones.

## Minimal context-loading order

1. Read this file.
2. Read `2026-08-30_spawn_candidates.md` for current observations and the next
   physical batch.
3. Read `navezgane_poi_catalog_v3.2-b9.meta.json` for catalog provenance.
4. Query only the required rows from `navezgane_poi_catalog_v3.2-b9.csv`; do
   not place the entire catalog into the model context unless necessary.
5. Read `../../../DEVELOPMENT_CYCLE_DOCTRINE.md` when making a new development
   decision.
6. Read `../docs/n0235.md` before opening a new version lane or QA cycle.

Repository and release movement are governed by
`../../../HRS_DEV_QA_NEXUS_WORKFLOW.md`. The product manifest is
`../docs/n0008.md`.

## Current truth

- `1.0.1` is the preserved packaging-identification repair.
- Its runtime selector remains fixed to NG01; its twelve source entries are a
  survey catalog, not twelve selectable release points.
- Do not modify or relabel the `1.0.1` binary.
- Spawn-pool selection and the DEV carousel belong in a new version lane after
  the initial scouting evidence is reviewed.
- DEV scouting may use flight, god mode, developer mode, invulnerability, and
  the Teleport to POIs menu in a disposable save.
- Manual travel and cheats produce discovery evidence only.

Mandatory label:

> DEV scouting only — flight/invulnerability enabled; not live spawn or
> survival proof.

## Authoritative POI catalog

`navezgane_poi_catalog_v3.2-b9.csv` is generated from the installed game's
read-only Navezgane and configuration data by
`../../../qa_cycle/Export-HrsNavezganePoiCatalog.ps1`.

Catalog facts at the current fingerprint:

- 1,487 placed non-`part_*` POI instances;
- 704 unique prefab identifiers;
- 357 Pine Forest instances;
- 339 Burnt Forest instances;
- 297 Desert instances;
- 303 Snow instances; and
- 191 Wasteland instances.

The current CSV SHA-256 is recorded in
`navezgane_poi_catalog_v3.2-b9.meta.json`. That metadata also pins the source
hashes for `prefabs.xml`, `map_info.xml`, `biomes.png`, `biomes.xml`, and
`Localization.csv`. Regenerate the catalog if any source fingerprint changes.

Each row includes:

- stable exported instance ID;
- prefab identifier and player-facing/fallback display name;
- exact POI reference X/Y/Z and directional X/Z;
- biome sampled from the installed Navezgane biome map;
- rotation and ground-level marker;
- difficulty tier, zoning, allowed townships, prefab size, tags, quest tags,
  trader-area flag, and definition path; and
- blank candidate/scouting fields for actual player anchor, screenshots,
  surface, clearance, geometry risks, hazards, trader hypothesis, decision, and
  decision reason.

The POI coordinate is a navigation reference. It is never automatically the
spawn coordinate. The CSV is generated and must not be edited manually; copy a
selected POI reference into `2026-08-30_spawn_candidates.md` and record human
observations there. Regeneration replaces the CSV and its blank scouting fields.

## Efficient catalog queries

From the repository root in PowerShell:

```powershell
$poi = Import-Csv '.\hrs_1.0.1\dev\scouting\navezgane_poi_catalog_v3.2-b9.csv'

# One biome, showing useful selection fields.
$poi |
    Where-Object Biome -eq 'burnt_forest' |
    Select-Object InstanceId, Prefab, DisplayName, DirectionalXZ, Tier, Zoning

# Find a menu entry or place name.
$poi |
    Where-Object { $_.Prefab -like '*diersville*' -or $_.DisplayName -like '*Diersville*' }

# Count candidate sources by biome and zoning.
$poi | Group-Object Biome, Zoning | Sort-Object Count -Descending
```

Prefer city blocks, plazas, parking areas, commercial strips, parks, and road
adjacent landmarks when the product goal is a city street arrival. Use houses,
bridges, caves, craters, military compounds, and isolated wilderness POIs as
comparison or rejection evidence unless their adjacent street is independently
strong.

## Physical scouting method

1. Use Teleport to POIs to search the selected prefab.
2. Teleport to its reference point.
3. Move outside the POI footprint to an ordinary street-level surface.
4. Disable flight and stand normally when practical; keep invulnerability only
   as required and label it.
5. Capture the stationary F3 player view and actual X/Y/Z.
6. Use the POI-menu capture for discovery map context when it clearly shows the
   selected name, coordinates, and biome.
7. Record surface, clearance, water/roof/POI/cliff/collision risks, immediate
   hazards/debuffs, and expected nearest trader.
8. Mark `Accept`, `Adjust`, or `Reject` with a reason.

Author X/Z from the inspected player position. Production Y must be calculated
from the terrain or surface height plus standing offset; do not use a universal
hard-coded Y.

## Current Burnt Forest batch

| ID | Area | POI reference | State |
| --- | --- | --- | --- |
| BF-C01 | Ranger Station Echo entrance | Observed player X/Z `1116.5 / 181.5` | Scouted; needs final decision |
| BF-C02 | Gravestown / Buy-N-Go Apartments | `downtown_building_01`, `385 W / 527 S` | Catalogued; visit next |
| BF-C03 | Navezgane Falls Diner | `diner_07`, `773 E / 322 S` | Catalogued |
| BF-C04 | Joey's Carlot | `carlot_01`, `2160 E / 395 S` | Catalogued |

Next human action: teleport to BF-C02, move to the adjacent ordinary street,
land, and capture the stationary F3 view.

## Planned DEV carousel

After points are accepted, a new-version DEV-only deterministic carousel may
warp through them in fixed order, settle, observe for 30 seconds, and advance.
It must log requested and actual position, point ID, biome, ground state,
hazards/debuffs, and runtime errors; show a countdown; support pause, repeat,
skip, and emergency stop; and emit a final summary.

The carousel tests placement, immediate geometry/hazards, and runtime stability.
It does not replace fresh-character randomness, distribution, trader,
starter-quest, one-shot, save/reload, survival, package identity, install,
evidence export, or rollback QA.

## Decision rule

Ask the system before changing the system:

1. What do we like about the proposal?
2. What do we not like or distrust?
3. What is the next smallest useful experiment?
4. What can source, catalog, logs, tests, or the game answer directly?
5. What does the resulting evidence prove and not prove?
6. What is the correct next work order?
