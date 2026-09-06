# Historical Random Start spawn-scouting AI handoff

Status: current durable resumption packet  
Owner decision date: 2026-08-30  
Production candidate target: Navezgane, 7 Days to Die V3.2 (b9)
Current installed QA environment: Steam public build `24994517`,
Assembly-CSharp MVID `229796d0-95ca-4662-b426-1a6f1f1596ed`

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

1. For carousel work, read
   `../evidence/carousel/HANDOFF_CATALOG.md` first; its current-state block and
   latest rows are the canonical compact resume packet.
2. Read this file only for broader product, scouting, or release context.
3. Read `2026-08-30_spawn_candidates.md` for current observations and the next
   physical batch.
4. Read `navezgane_poi_catalog_v3.2-b9.meta.json` for catalog provenance.
5. Query only the required rows from `navezgane_poi_catalog_v3.2-b9.csv`; do
   not place the entire catalog into the model context unless necessary.
6. Read `../../../DEVELOPMENT_CYCLE_DOCTRINE.md` when making a new development
   decision.
7. Read `../docs/n0235.md` before opening a new version lane or QA cycle.
8. Read `../docs/n0238.md` when historical design reasoning is needed for the
   QA placement-health carousel.

Repository and release movement are governed by
`../../../HRS_DEV_QA_NEXUS_WORKFLOW.md`. The product manifest is
`../docs/n0008.md`.

## Current truth

- `1.0.1` is the preserved packaging-identification repair and remains fixed to
  NG01.
- `1.1.0 / r110` is the active new lane. It randomizes once between only NG01
  and NG02 through the explicit approved index allowlist `{0,1}`.
- The other ten source entries remain non-selectable survey data.
- Do not modify or relabel the `1.0.1` binary.
- The larger production spawn pool remains scouting/future work. The separate
  QA-only source catalog retains all 1,487 stable Navezgane teleport-index
  instances. The active screen mirrors the game's `Filter small POIs` rule and
  keeps the 745 entries whose prefab bounding-box volume is at least 100. It is
  not part of the shipped `1.1.0` runtime, and a pass does not certify or
  activate a point.
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
$poi = Import-Csv '.\hrs_1.1.0\dev\scouting\navezgane_poi_catalog_v3.2-b9.csv'

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

## Implemented QA health carousel

The separate `BitWrecked_HRS_QA_Carousel` visits an explicitly bounded range of
generated `NVG-####` stable IDs in fixed order, settles, observes for the
configured dwell, and advances. It records requested and actual position,
point ID, health, stage, and runtime reason. The companion runner prints
transitions and a final summary; the stop helper provides emergency stop. On
the first failure or range completion, it returns to the captured starting
position and stops.

The completed 2026-08-31 placement-health pass produced this durable result:

- NG01-NG04 passed. NG03's earlier `CHUNK_TIMEOUT` did not repeat and is
  classified as transient.
- NG05 failed `SETTLE_FAILED` after falling from Y `62` to Y `51`; reject or
  rework that anchor.
- One NG06 resume stopped before teleport because health was already `0`.
  That is a setup failure, not a location result.
- Clean resume `b6b5c11b2bf441e8847cda512e091b8f` passed NG06-NG12 7/7 at
  health `100` and restored the exact origin.
- Consolidated result: 11/12 passed; NG05 is the only rejected survey point.
  None of these DEV results expands the production `{NG01,NG02}` allowlist.

The next screening catalog is `2026-08-31_carousel_40_catalog.md`. NG05 is
retired without renumbering, NG41 replaces it, and the resulting 40 active
points are balanced at eight per biome. Test the 29 additions in five-second
batches NG13-NG20, NG21-NG28, NG29-NG36, and NG37-NG41. Preserve a failure,
retire or adjust its stable ID, then resume at the next active ID.

Batch A is complete: run `788992865a80431fb1997bea273a6e34` passed NG13-NG20
8/8 at health 100 with exact origin restoration. Batch B run
`3a16335b2e774dcca30efd2d254b11eb` passed NG21-NG28 8/8 with the same health
and restoration result. The owner approved larger batches: run the remaining
NG29-NG41 points together, then use roughly 32-point batches for later catalog
growth, retaining first-failure stop and stable-ID resume behavior.

The final run `7414420d053e45e88e49c41bee635274` passed NG29-NG41 13/13 at
health 100 with exact origin restoration. All 29 additions passed their first
automated placement-health screen; all 40 active candidates now have carousel
pass evidence. Do not call them production-approved until street-level visual
review and the remaining acceptance layers are complete.

Owner decision after the 40-point screen: run every teleport-index location.
The first implementation converted all 1,487 rows directly. Live evidence
showed why the game's small-POI filter matters: it eventually traversed a long
street-light sequence. The corrected generator retains the 745 engine-defined
non-small entries and preserves their original stable IDs. Exact location
failures are still recorded in `dev/qa/carousel-rejections.json` without
renumbering survivors. At five seconds, uninterrupted dwell alone is 1:02:05;
allow additional time for loading.

Steam updated the installed game immediately before the first full-catalog run.
The old QA MVID guard correctly blocked installation. A fresh export from build
`24994517` reproduced the prior 1,487-row catalog byte-for-byte, so map anchors
remain valid. Only the QA carousel is repinned to the new MVID; the production
1.1.0 payload remains preserved against its original V3.2 (b9) contract.

Pause, repeat, skip, biome classification, debuff inventory, and an in-game
countdown are not implemented in this first health-test increment. Add them
only if the fixed automatic pass exposes a need; they are not required to
identify the first failing anchor.

Incident `40946e3af00842e3ad81fe282fa0cd26`: the operator observed pole-top
landings and manually stopped at NVG-1392 (`street_light_02`). The old runtime
used `World.GetHeight`, so tallest blocks such as poles and roofs could falsely
pass. Its stop flag also re-entered failure handling during Restore, producing
28,783 duplicate failure/restore pairs before successful restoration. The run's
1,391 reported passes are invalid as street-level evidence and no ID is rejected
from it. The corrected source uses `World.GetTerrainHeight`, carries catalog Y,
requires a maximum 24-block terrain delta after chunk load, excludes prefab volume below 100,
and polls manual stop only before Restore. Static contract passes. Build and
install only after the game is closed, then retest from the first eligible ID.
The first corrected build SHA-256
`163059AF05CC4D457F52FEF9C1501AEFB57B15FAB2783DAAC422A556E77DCB9E`
is retired because it queried terrain before chunk load. The follow-up
deterministic build is 80,384 bytes, SHA-256
`0D5A03AD58A5DB3B3CBB4F9396B9E176BBFB43A9D5014E8D7529F6E2A1BFF442`,
with 745 active IDs and active-list SHA-256
`DA23DB83406C3B49F6C30CD2919BA1D2926FC122BD66A07B7C1D035221006351`.

Run `643fd10861794b72ba4967a0d2561fc0` failed closed at NVG-0001 before
movement because the first correction queried terrain before loading the
destination chunk. Do not reject NVG-0001. The follow-up uses catalog Y for the
load anchor and calls `GetTerrainHeight` only after the chunk is present.
The follow-up artifact double-built byte-identically.

Run `36f31c0104e54be8908b4afba32ec5f2` then passed NVG-0001 through
NVG-0027 at health 100 and failed NVG-0028 (`bombshelter_01`, Bart's Salvage)
with `SETTLE_FAILED`. The player stayed near the landing for the full 15-second
window but never produced three grounded samples; origin restoration succeeded.
This is a confirmed location rejection. NVG-0028 is persisted in
`carousel-rejections.json`, and continuation starts at NVG-0029. The rebuilt
744-point DLL SHA-256 is
`4C3259DCB2D91D4A0F84DCC46BD02923A8ABC10B134E52715524DCB42D847455`;
active-ID-list SHA-256 is
`EF884519A78EC0D9528B75F47B4BB66273FB4DE04B758120648538712DDA4634`.

Continuation `119fc0fe611a4700afd78f2532c334cd` is setup-failure evidence:
the player moved about 59 metres and health fell from 100 to 11 during the
30-second preflight after loading from a roof. Its later NVG-0029
`CHUNK_TIMEOUT` does not reject NVG-0029. The follow-up runtime detects
preflight health loss or movement beyond three metres as `PREFLIGHT_CHANGED`.
The resulting 744-point deterministic DLL SHA-256 is
`DF8217BEB9E1D2370840066F60197DA81FD372970FD2012D0E6E6FEAAE51719D`.

Clean retry `eabb6a792a334e62984e4ee5e3f2f0fd` passed NVG-0029 through
NVG-0123 (95 points) at health 100, proving the earlier NVG-0029 timeout was
setup-related. NVG-0124 (`crater_deco_01`) then failed `SETTLE_FAILED` while
remaining exactly at its terrain landing; restoration succeeded. It is a
confirmed rejection. Cumulative passes are 122; rejected IDs are NVG-0028 and
NVG-0124; resume at NVG-0125. The rebuilt 743-point DLL SHA-256 is
`44720DE8E5698F2D31F8EA2E7B559C89121D7A07DFA9F76F060AE60B51A87546`;
active-ID-list SHA-256 is
`093990BD2A2C6A171875341E62E711CE1255E3423DE40BB3153AAAC407EC0C89`.

Run `57eaa56e86264524be2c0a1c78299cdd` passed NVG-0125 through NVG-0162
(38 points) at health 100. NVG-0163 (`docks_04`, Middleman Docks; `NavOnly`)
then failed `SAFE_LANDING_FAILED` because no native-valid landing existed in
the bounded search; restoration succeeded. Cumulative passes are 160; rejected
IDs are NVG-0028, NVG-0124, and NVG-0163; resume at NVG-0164. The rebuilt
742-point DLL SHA-256 is
`98BA5E11B101232CE23F319FFC51C037D8EA94CD3FF358B73ACFEF8EB364667E`;
active-ID-list SHA-256 is
`9DF8DE8C3720061CD5F24A39EF3AEDA18AF9F6F01E4DA0F7C2F342C9D011DD34`.

Run `b13092e0efa242d09719bac32eb00f8b` exposed that the dwell stage did not
retain the settle invariant: NVG-0167 fell from near Y 60 to Y 17.9 during
dwell and falsely passed. Emergency stop at NVG-0170 restored origin. Auditing
all 166 recorded full-catalog passes found only two landing-to-pass outliers:
NVG-0075 at 47.4 metres and NVG-0167 at 42.1 metres. The other 164 were within
three metres (worst 1.19). Reject NVG-0075 and NVG-0167 from this direct log
evidence after closing the game. The corrected dwell fails on displacement over
three metres and requires final `onGround` before pass.

NVG-0075 and NVG-0167 are now persisted as `DWELL_POSITION_FAILED`. The five
confirmed rejects are NVG-0028, NVG-0075, NVG-0124, NVG-0163, and NVG-0167.
There are 164 validated cumulative passes and 740 active catalog points. Resume
at NVG-0170, which was only the manual-stop point. Corrected deterministic DLL
SHA-256 is
`2F379AC4EC892959F61B18CFB65AD0A7E3F28CE3B4628EEC2FE771687C51D3C3`;
active-ID-list SHA-256 is
`E88264572FCAEB4FB12101B08D59461F3531EF9F037EA0B095B87F0125176F4B`.

Run `5a09a6bb452544988cb9a8b4f77aa63b` stopped at point `NONE` with
`PREFLIGHT_CHANGED` after the operator died/respawned before enabling God mode.
The guard prevented invalid location evidence. Add no rejection; retry
NVG-0170.

Retry `967b85dc505f49b8b8d8f2bc6dd5dff3` passed NVG-0170 and NVG-0171.
NVG-0172 remained within about 0.7 metres at health 100 but had a single-frame
`onGround=false` at dwell deadline. Do not reject it. The corrected check keeps
the continuous three-metre position bound, allows two seconds of ground grace,
and requires three renewed grounded samples. Retest NVG-0172.
The resulting 740-point deterministic DLL SHA-256 is
`E7B283F06AD02CEB25BD89B94B3D5ED7001531532AE7D5E0EA36E5F079D56256`;
active-ID-list SHA-256 remains
`E88264572FCAEB4FB12101B08D59461F3531EF9F037EA0B095B87F0125176F4B`.

Clean retry `be48b68f4f09450982d50ccaf1532097` confirmed NVG-0172 as a
rejection: it grounded near Y 59 then fell beyond tolerance to Y 55.397 within
0.66 seconds. Cumulative passes remain 166; the six rejected IDs are NVG-0028,
NVG-0075, NVG-0124, NVG-0163, NVG-0167, and NVG-0172. Resume at NVG-0173.
The rebuilt 739-point DLL SHA-256 is
`ACFA73527B8DA5C6E7917B1D2C291DE09733F4E3F3127082854A3ACBF173B935`;
active-ID-list SHA-256 is
`C5C99FB5EF0FF83237367E0873AC9CD9695339AB1E3327620B46A9A34A52E845`.

Run `04c0120c07064f4996119400d51f67e1` passed NVG-0173, then rejected
NVG-0174 (`downtown_filler_05`) with `DWELL_GROUND_FAILED` after it failed to
renew stable ground during dwell plus grace. Cumulative passes are 167; there
are seven rejects; resume at NVG-0175. Rebuilt 738-point DLL SHA-256 is
`D98CFA3DFCBFD9960371457263BF37CDBE5249582003BE02A30CB857BD30B74B`;
active-ID-list SHA-256 is
`F6417DE6EBD9BD61D9689E229C982901ECC0CD1D0CB84F05C031FEC0E631926F`.

Run `4bcfeb84f9894b25b56b276faaea9c9e` rejected NVG-0175
(`downtown_filler_06`) with `DWELL_GROUND_FAILED`; restoration succeeded.
Cumulative passes remain 167; there are eight rejects; resume at NVG-0176.
The rebuilt 737-point DLL SHA-256 is
`E6CF56DB8248172DAA4C2A59EFD903693184D365D55CB406EC68135737EA11BE`;
active-ID-list SHA-256 is
`2C247DD84D6491B232DFB30ABF081CD57CA7876270D2E1CED790F381C6C24AF0`.

Owner requested a fresh disposable save because accumulated zombies disrupted
observation. Create Navezgane `HRS_CAROUSEL_110_002` with enemy spawning off,
enter once, stand on ordinary flat ground at health 100, save, and exit. Then
arm NVG-0176 against that exact game name. This is still geometry-only QA.

Fresh-save run `4c8055cdc6ca4713ab6c4e037bd0bacc` rejected NVG-0176
(`downtown_filler_07`) with `DWELL_POSITION_FAILED` after a fall from Y 53 to
below Y 49.2. This proves the downtown cluster is bad geometry, not old-save or
zombie noise. Cumulative passes remain 167; there are nine rejects; resume at
NVG-0177 on `HRS_CAROUSEL_110_002`. Rebuilt 736-point DLL SHA-256 is
`2297653A6FCEBF93D6BFBB0E63A844DCBE58118509BE7100AA8119555675FFA5`;
active-ID-list SHA-256 is
`C67CAE17515D262732968874CBDA45CE550BB17FAAD0077A2A5F2C75E6EE5852`.

Run `1046584d23eb4e9ca5cf1c4e8b61c994` rejected NVG-0177
(`downtown_filler_09`) with `DWELL_GROUND_FAILED`. Cumulative passes remain
167; there are ten rejects; resume at NVG-0178 on the fresh save. Rebuilt
735-point DLL SHA-256 is
`831A1D88BBE4824CC4A83600B6B62E344C1507D4C22870E5281BC257026D04E9`;
active-ID-list SHA-256 is
`CCAE5683E97625E688CC4475B36243279D8C129081E76C68369524322D1E618B`.

The carousel tests placement, immediate geometry/hazards, and runtime stability.
It does not replace fresh-character randomness, distribution, trader,
starter-quest, one-shot, save/reload, survival, package identity, install,
evidence export, or rollback QA.

## Current carousel correction and reusable skill — 2026-09-01

Earlier NVG-0174 through NVG-0177 rejection evidence was invalidated when the
owner reported collision had been disabled. These IDs were restored for clean
testing. Require God mode ON, collision ON, fly OFF, and no player movement for
all carousel runs; otherwise preserve the run only as setup evidence.

The carousel now uses a primed double teleport: load the catalog anchor, wait
two seconds after chunk availability, recalculate landing, teleport two metres
above it, accept only a real grounded surface near catalog elevation, and use
that actual settled position as the dwell baseline. This made NVG-0174 and
NVG-0175 pass. NVG-0176 remained unstable beneath full prefab blocks and was
visually confirmed unsafe, so it is rejected as
`SETTLE_FAILED_BELOW_PREFAB_BLOCKS`. Never replace strict grounding with a
motion-only fallback.

At the 2026-09-01T03:22:07Z snapshot, run
`66539b363e0c47b99933fc23632801b9` had passed NVG-0177 through NVG-0213 and
was dwelling at NVG-0214. Continue monitoring this live run; preserve its bridge
files before any new arm. The active list contains 738 points with seven
confirmed rejects. Current DLL SHA-256 is
`E1798A6A9769892177427936D9CE24AB780416C25EB09CE5B890549F3364A7DB`;
active-ID-list SHA-256 is
`062AC14B2E017A0E222072C848D05CAF196F88FB4D65423674B4AFD53C0CC975`;
runtime-source SHA-256 is
`BC4D1A7E55977D4C460865A4468BB0CA7ED8A6ED01CAE9AC107ED32AC2B81508`.
See
`../evidence/carousel/2026-09-01_double-port_and_prefab-surface_manifest.md`.

The workstation has the discoverable `$hrs-carousel-qa` Codex skill installed
at `C:\Users\mobil\.codex\skills\hrs-carousel-qa`. Load it when continuing this
workflow; the repository handoff remains authoritative for changing run state.

Completed batch `66539b363e0c47b99933fc23632801b9` passed NVG-0177 through
NVG-0255: 79 consecutive points at health 100. It restored and stopped at
NVG-0256 (`gravestowne_city_blk_quarter`) with `SETTLE_FAILED`. The owner calls
the batch a win. Do not reject NVG-0256 without visual confirmation; it remains
the review/resume point. Cumulative validated points are 248, persistent
rejects remain seven, and the active catalog remains 738. Preserve the run at
`../evidence/carousel/2026-09-01_run_66539b36_79-pass_manifest.md`.

NVG-0256 was cleanly retried and visually confirmed in a terrain depression;
it is rejected as `SETTLE_FAILED_TERRAIN_DEPRESSION`. The next clean run,
`f009ae3a18f143568ef93c3518bcf7ee`, failed immediately at NVG-0257
(`gravestowne_city_blk_quarter`, 584 W / 364 S) with health 100 and exact
origin restoration. The owner confirmed another rough landing area, so it is
rejected as `SETTLE_FAILED_ROUGH_TERRAIN`.

Current carousel state: 248 cumulatively validated points, nine persistent
rejects, and 736 active engine-eligible points. Continuation
`a8650f63ad2a41c3a4fdb1dde9471b32` is armed from NVG-0258 through NVG-1487
at five seconds per point on `HRS_CAROUSEL_110_002`. Its DLL SHA-256 is
`CFE44CF0A1F30642A9907C8702983591B092B2867B89489DB89E69E57F787F6F`;
active-ID-list SHA-256 is
`0B7E3B9ADEFAFE4DF48FB156808DC388206077C747E362E4204EB8B26A76C035`.
See the latest rows of `../evidence/carousel/HANDOFF_CATALOG.md`. Routine
carousel handoffs now update that compact catalog and preserve raw event/result
files; narrative per-run manifests are reserved for novel failure modes or
design decisions.

## Primed landing release candidate — 2026-09-01

The game is closed. Carousel findings have been promoted into the release
runtime, but the production selection pool remains exactly NG01/NG02 via
`ApprovedPointIndices = { 0, 1 }`. Do not widen it implicitly.

The release now primes the selected catalog anchor for two seconds after chunk
availability, resolves bounded terrain height, places two metres above it, and
requires three grounded samples near catalog elevation before adopting the
actual surface and completing the existing marker/trader transaction. The
current game MVID pin is `229796d0-95ca-4662-b426-1a6f1f1596ed`.

Statically verified DLL: 39,936 bytes, SHA-256
`DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507`,
MVID `6bd5ed25-0ccc-4688-afea-8c9e6f0f06d4`. All targeted/static contracts
pass; OneDrive-sensitive core/deployment/management suites pass 89/89, 62/62,
and 8/8 from an ordinary isolated filesystem. Full details are in `../docs/n0239.md`.

Next gate: install the exact verified candidate through the owned manager and
run fresh Random no-God-mode live QA until both NG01 and NG02 are observed.
Verify health/progression, grounded arrival, exactly-once behavior, nearest
trader, starter quest, reload, and rollback. Do not package or declare release
approval from static results alone.

## Decision rule

Ask the system before changing the system:

1. What do we like about the proposal?
2. What do we not like or distrust?
3. What is the next smallest useful experiment?
4. What can source, catalog, logs, tests, or the game answer directly?
5. What does the resulting evidence prove and not prove?
6. What is the correct next work order?
