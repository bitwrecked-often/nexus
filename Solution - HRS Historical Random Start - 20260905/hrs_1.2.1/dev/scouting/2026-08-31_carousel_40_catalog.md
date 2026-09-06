# HRS 1.1.0 QA carousel — active 40-point catalog

Status: provisional DEV placement-health candidates
World: Navezgane, 7 Days to Die V3.2 (b9)
Production authority: none; production remains limited to NG01 and NG02

## Selection and retirement rules

- IDs are permanent evidence keys and are never renumbered.
- NG05 is retired after `SETTLE_FAILED` evidence and is not active.
- NG41 replaces NG05, leaving 40 active candidates: eight per biome.
- NG01-NG12 retain their historical survey identity. NG13-NG41 are exact
  references from `navezgane_poi_catalog_v3.2-b9.csv`.
- A POI coordinate is a discovery anchor, not proof of a street-level spawn.
  The carousel resolves terrain and searches locally for a native-valid
  landing. Visual review is still required before acceptance.
- On failure, preserve the result, retire or adjust that ID, and resume from
  the next active ID. Do not reuse an ID for a different coordinate.

## Active catalog

| ID | Biome | Candidate/reference | X | Z | Provenance | State |
| --- | --- | --- | ---: | ---: | --- | --- |
| NG01 | Snow | Perishton snow city | -1528 | 1700 | Legacy survey | Carousel pass |
| NG02 | Snow | Remote snow edge | -2100 | 2100 | Legacy survey | Carousel pass |
| NG03 | Pine Forest | National Forest | -900 | 1100 | Legacy survey | Carousel pass; prior timeout transient |
| NG04 | Pine Forest | Forest lake | -1450 | 650 | Legacy survey | Carousel pass |
| NG06 | Pine Forest | Diersville outskirts | 1750 | 500 | Legacy survey | Carousel pass |
| NG07 | Burnt Forest | Army-camp region | 1500 | 50 | Legacy survey | Carousel pass |
| NG08 | Desert | Desert canyon | 650 | -1850 | Legacy survey | Carousel pass |
| NG09 | Desert | Departure | 1750 | -1800 | Legacy survey | Carousel pass |
| NG10 | Wasteland | Southwest city | -1750 | -1800 | Legacy survey | Carousel pass |
| NG11 | Snow | Far northeast snow | 2200 | 1550 | Legacy survey | Carousel pass |
| NG12 | Desert | Southern frontier | 0 | -2400 | Legacy survey | Carousel pass |
| NG13 | Pine Forest | The Bear Den | -771 | 895 | NVG-0114 / `countrytown_business_03` | Carousel pass |
| NG14 | Pine Forest | Diersville block | 935 | 573 | NVG-0153 / `diersville_city_blk_01` | Carousel pass |
| NG15 | Pine Forest | Bob's Cafe | -1910 | 634 | NVG-0157 / `diner_02` | Carousel pass |
| NG16 | Pine Forest | Ranger Station Alpha | -952 | -302 | NVG-0533 / `ranger_station_01` | Carousel pass |
| NG17 | Burnt Forest | O'malley Oats | 577 | 51 | NVG-0054 / `business_burnt_01` | Carousel pass |
| NG18 | Burnt Forest | Navezgane Falls Diner | 773 | -322 | NVG-0159 / `diner_07` | Carousel pass |
| NG19 | Burnt Forest | Joey's Carlot | 2160 | -395 | NVG-0079 / `carlot_01` | Carousel pass |
| NG20 | Burnt Forest | Navezgane Fire District #3 | -491 | -422 | NVG-0232 / `fire_station_03` | Carousel pass |
| NG21 | Burnt Forest | Fiery Farms | 2120 | 388 | NVG-0216 / `farm_05` | Carousel pass |
| NG22 | Burnt Forest | Ranger Station Echo | 1086 | 116 | NVG-0538 / `ranger_station_06` | Carousel pass |
| NG23 | Burnt Forest | Hybrid Energy Substation #2 | -273 | -67 | NVG-1464 / `utility_substation_02` | Carousel pass |
| NG24 | Desert | Eastern bus stop | 1934 | -1670 | NVG-0051 / `bus_stop_01` | Carousel pass |
| NG25 | Desert | Central bus stop | 524 | -1407 | NVG-0050 / `bus_stop_01` | Carousel pass |
| NG26 | Desert | Jerry's Fill | -437 | -1095 | NVG-0245 / `gas_station_11` | Carousel pass |
| NG27 | Desert | Ranger Station Charlie | 2186 | -1546 | NVG-0535 / `ranger_station_03` | Carousel pass |
| NG28 | Desert | Del's Cafe | 81 | -2321 | NVG-0158 / `diner_03` | Carousel pass |
| NG29 | Snow | Federal Appliance | -534 | 1864 | NVG-0113 / `countrytown_business_02` | Carousel pass |
| NG30 | Snow | 4 Ever Video | 610 | 1334 | NVG-0118 / `countrytown_business_09` | Carousel pass |
| NG31 | Snow | Gazebo Park | -419 | 1787 | NVG-0191 / `downtown_filler_park_02` | Carousel pass |
| NG32 | Snow | Pass-N-Gas Store #04 | 933 | 1731 | NVG-0239 / `gas_station_04` | Carousel pass |
| NG33 | Snow | Ranger Station Foxtrot | 1833 | 1603 | NVG-0537 / `ranger_station_05` | Carousel pass |
| NG34 | Wasteland | Hybrid Energy Substation #4 | -1103 | -639 | NVG-1293 / `site_utility_01` | Carousel pass |
| NG35 | Wasteland | Wood bridge | -1194 | -1131 | NVG-0041 / `bridge_wood1` | Carousel pass |
| NG36 | Wasteland | Red Mesa Compound | -1312 | -2206 | NVG-0382 / `installation_red_mesa` | Carousel pass |
| NG37 | Wasteland | ParKing Lot | -1757 | -566 | NVG-0442 / `parking_lot_03` | Carousel pass |
| NG38 | Wasteland | NDC Checkpoint Four | -1812 | -1373 | NVG-0678 / `roadside_checkpoint_04` | Carousel pass |
| NG39 | Wasteland | Western roadblock | -2169 | -1684 | NVG-0660 / `roadblock_01` | Carousel pass |
| NG40 | Wasteland | NDC Checkpoint Five | -934 | -1722 | NVG-0679 / `roadside_checkpoint_05` | Carousel pass |
| NG41 | Pine Forest | Mason Farms | 769 | 888 | NVG-0219 / `farm_13` | Carousel pass; NG05 replacement |

## Initial five-second batches

| Batch | Range | Count |
| --- | --- | ---: |
| A | NG13-NG20 | 8 |
| B | NG21-NG28 | 8 |
| C | NG29-NG36 | 8 |
| D | NG37-NG41 | 5 |

The 11 previously passing active IDs do not need to be repeated merely to
screen the 29 additions. After pruning, run the complete surviving catalog as
one regression series.

## Live screening results

- Batch A, run `788992865a80431fb1997bea273a6e34`: NG13-NG20 passed 8/8 at
  five seconds, health remained 100, and exact origin restoration passed.
- Batch B, run `3a16335b2e774dcca30efd2d254b11eb`: NG21-NG28 passed 8/8 at
  five seconds, health remained 100, and exact origin restoration passed.
- Owner decision after Batch B: combine the remaining NG29-NG41 points into
  one 13-point run. For later catalog growth, screen approximately 32 points
  per batch; fail closed on the first defect and resume at the next active ID.
- Final batch, run `7414420d053e45e88e49c41bee635274`: NG29-NG41 passed
  13/13 at five seconds, health remained 100, and exact origin restoration
  passed. NG41 used the nearby native-valid landing `765 / 61 / 884` for its
  requested `769 / 888` anchor.
- Consolidated expansion result: all 29 additions passed the first automated
  placement-health screen. Together with the 11 retained legacy passes, all
  40 active candidates now have carousel-pass evidence. This is not yet final
  street-level visual approval or production authorization.
