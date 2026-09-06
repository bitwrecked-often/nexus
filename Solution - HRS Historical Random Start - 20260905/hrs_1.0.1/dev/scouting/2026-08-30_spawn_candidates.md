# Navezgane spawn-candidate scouting — 2026-08-30

Status: DEV discovery evidence; decisions remain provisional until each record
is complete  
Target: six certified street-level points per zone  
Method: scout in batches of three or four; retain only the best candidates

> DEV scouting only — flight/invulnerability enabled; not live spawn or
> survival proof.

## Discovery shortcut confirmed

Use the in-game **Teleport to POIs** menu as the primary candidate generator.
It provides searchable POI names, directional coordinates, biome labels,
filters, and direct travel. This eliminates most manual flight between zones.
The menu coordinate identifies the POI reference point only. Teleport there,
move to the adjacent ordinary street outside the POI footprint, land, and
record the stationary player's actual X/Y/Z as the proposed anchor.

A legible POI-menu screenshot may stand in for the discovery map screenshot if
it visibly identifies the selected POI, its coordinate, and biome. Finalists
still require distribution review and deterministic safe-landing evidence.

## Large-POI index review — pages 1–11

The owner supplied legible captures of large-POI index pages 1 through 11.
They confirm five useful scouting zones in the current Navezgane catalog: Pine
Forest, Burnt Forest, Desert, Snow, and Wasteland. Directional coordinates below
are transcribed from the POI menu and remain navigation references, not final
player anchors.

### Recommended first urban reference per zone

| Priority | Candidate area | POI-menu reference | Zone | Why inspect it |
| ---: | --- | --- | --- | --- |
| 1 | Diersville | `diersville_city_blk_01`, `935 E / 697 N` | Pine Forest | Explicit city block with an established street grid |
| 2 | Gravestown / Buy-N-Go | `downtown_building_01`, `385 W / 527 S` | Burnt Forest | Urban building and street context, geographically separated from BF-C01 |
| 3 | Departure Plaza | `departure_city_blk_plaza`, `1730 E / 1835 S` | Desert | Explicit city plaza with multiple surrounding blocks |
| 4 | Snow downtown parking area | `downtown_parking_lot_01`, `219 W / 1775 N` | Snow | Open urban reference likely to expose a clear adjacent street |
| 5 | Wasteland downtown park | `downtown_filler_park_01`, `1844 W / 1762 S` | Wasteland | Open downtown reference suitable for inspecting road access and hazards |

### Geographic-spread alternatives visible in the same captures

| Candidate area | POI-menu reference | Zone | Separation value |
| --- | --- | --- | --- |
| Country town / Bear Den | `countrytown_business_03`, `771 W / 895 N` | Pine Forest | Western alternative to eastern Diersville |
| Navezgane Falls Diner | `diner_07`, `773 E / 322 S` | Burnt Forest | Secondary burnt-zone road/commercial reference |
| Desert town block | `desert_town_blk_01`, `107 E / 1814 S` | Desert | Far west of Departure's city cluster |
| Seemore Bank area | `bank_02`, `1629 W / 1810 N` | Snow | Far west of the central snow parking reference |
| Shotgun Messiah Factory | `factory_02`, `1633 W / 719 S` | Wasteland | Northern industrial alternative to the southwest downtown cluster |

Do not treat multiple entries from one named city as independent variety merely
because the menu lists separate blocks. First establish one good street anchor
per city/district, then add another only when it creates a materially different
arrival view, road geometry, trader relationship, or hazard profile.

### Next physical scouting batch — Burnt Forest

Keep the first physical batch within one zone so its results are comparable:

1. `BF-C01` — existing Ranger Station Echo observation at player X/Z
   `1116.5 / 181.5`.
2. `BF-C02` — Gravestown / `downtown_building_01`, POI reference
   `385 W / 527 S`.
3. `BF-C03` — Navezgane Falls Diner / `diner_07`, POI reference
   `773 E / 322 S`.
4. `BF-C04` — Joey's Carlot / `carlot_01`, POI reference
   `2160 E / 395 S`.

At BF-C02 through BF-C04, teleport to the named POI, move to the adjacent
ordinary street, land, and capture the stationary player's F3 view. The final
anchor comes from that player position, not the reference above.

## BF-C01 — Ranger Station Echo entrance

| Field | Observation |
| --- | --- |
| State | Scouted; decision pending map screenshot |
| Zone/biome | Burnt Forest / `burnt_forest` |
| World | Navezgane |
| Save | `HRS_TRADER_006` |
| Observed player X/Y/Z | `1116.5 / 61.7 / 181.5` |
| Focused block X/Y/Z | `1116 / 63 / 167` — informational only; not the player anchor |
| Facing/time | Approximately south; Day 1, 09:02 |
| Surface | Road-level paved/gravel approach outside Ranger Station Echo / US Fire Post |
| Clearance | Open overhead at the observed player position |
| Nearby geometry | Guard booth, fence, gate/barrier, sign, streetlights, and adjacent POI structures |
| Immediate hazards | Burnt Forest exposure; visible embers/fire; debug list showed nearby hostile entities at approximately 40–108 m |
| Quest/trader observation | Journey to Settlement displayed `2.6 km`; this does not yet prove the nearest-trader identity |
| Street-level screenshot | Received in chat; not yet copied into repository evidence storage |
| Map screenshot | Required |
| Decision | Pending — do not mark Accept/Adjust/Reject until map placement and anchor clearance are reviewed |

### Initial assessment

The stationary player position is a plausible street-level anchor and has open
headroom. The point is close enough to the Ranger Station Echo gate and POI
geometry that the final X/Z may need adjustment toward the road center. God
mode can conceal biome damage, debuffs, and ordinary survival pressure. Manual
arrival proves observation of the geometry only; it does not prove automated
warp, safe landing, fresh-character behavior, trader routing, or quest routing.

### Required next evidence

1. Capture the map with the player marker visible.
2. If possible, capture a second street-level view looking back along the road
   to show road width and separation from the gate/guard booth.
3. Preserve `1116.5 / 181.5` as the observed X/Z until the map review determines
   whether the anchor should move toward the road center.
4. Record `Accept`, `Adjust`, or `Reject` after that review.
