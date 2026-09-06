# HRS carousel handoff catalog

This is the canonical compact handoff for the full-catalog landing campaign.
Read **Current state** and the last relevant table rows; open raw evidence only
when diagnosing a stop. Existing narrative manifests remain historical
evidence. Do not create another per-run manifest unless a genuinely new runtime
failure mode or design decision needs explanation.

## Current state

- Save: `HRS_CAROUSEL_110_007`
- Required state: God ON; collision ON; fly/noclip OFF; player stationary
- Screening passes: 422 (provisional; earlier setup-state audit required)
- Final state-certified points: 171 (both controlled certification batches complete)
- Rejected points: 33
- Active engine-eligible points: 712
- Armed start: none; certification complete
- Armed run: none
- Certified ranges: NVG-0281..0443 active survivors (161) plus NVG-0446..0455 (10); total 171
- DLL: 79,872 bytes; SHA-256
  `0C116FF05DCFB808DA655E25C9EE4F277992884D8233F057FA9FB47F285BD3D8`
- Active-ID list: 7,120 bytes; SHA-256
  `D0AC604D0A4E9D250FA809CB4328CEC87AFDD9FF2CE6DB9A2DC39F6F86835C10`
- Runtime source SHA-256
  `BC4D1A7E55977D4C460865A4468BB0CA7ED8A6ED01CAE9AC107ED32AC2B81508`

## Run ledger

| Date | Run | Tested/result | Observation and decision | Next | Raw evidence |
| --- | --- | --- | --- | --- | --- |
| 2026-09-01 | `66539b363e0c47b99933fc23632801b9` | NVG-0177..0255 PASS 79; NVG-0256 `SETTLE_FAILED` | Health 100; restored; review only pending clean visual retry | NVG-0256 | [events](2026-09-01_run_66539b36_79-pass_nvg-0256-review_events.tsv), [result](2026-09-01_run_66539b36_79-pass_nvg-0256-review_result.json) |
| 2026-09-01 | `a33e3860313a4da7b98b51db1f61c48a` | NVG-0256 `SETTLE_FAILED`; 0 pass | Depressed area with swollen terrain; REJECT `SETTLE_FAILED_TERRAIN_DEPRESSION`; restored at health 100 | NVG-0257 | [events](2026-09-01_run_a33e3860_nvg-0256_terrain-depression_events.tsv), [result](2026-09-01_run_a33e3860_nvg-0256_terrain-depression_result.json) |
| 2026-09-01 | `f009ae3a18f143568ef93c3518bcf7ee` | NVG-0257 `SETTLE_FAILED`; 0 pass | Gravestowne rough landing area; REJECT `SETTLE_FAILED_ROUGH_TERRAIN`; restored at health 100 | NVG-0258 | [events](2026-09-01_run_f009ae3a_nvg-0257_review_events.tsv), [result](2026-09-01_run_f009ae3a_nvg-0257_review_result.json) |
| 2026-09-01 | `a8650f63ad2a41c3a4fdb1dde9471b32` | NVG-0258 PASS; NVG-0259 `SETTLE_FAILED` | Bounced several times on hill; first prime partly below terrain, final teleport visibly above ground and appeared usable; health 100; exact restore; RETRY, no rejection | NVG-0259 | [events](2026-09-01_run_a8650f63_nvg-0259_review_events.tsv), [result](2026-09-01_run_a8650f63_nvg-0259_review_result.json) |
| 2026-09-01 | `904d906f7d2244a99a08b2bc3a5afef6` | NVG-0259 `SETTLE_FAILED`; 0 pass | Clean retry reproduced final `-326.081,63.116,-621.484`; operator saw janky landing directly overlapping an attacking hostile; REJECT `UNSAFE_LANDING_HOSTILE_OVERLAP`; health 100; exact restore | NVG-0260 | [events](2026-09-01_run_904d906f_nvg-0259_retry_events.tsv), [result](2026-09-01_run_904d906f_nvg-0259_retry_result.json) |
| 2026-09-01 | `de53a2e7d9b1421499d365389285d243` | Point `NONE`; `PREFLIGHT_CHANGED` | Health fell to 20 before testing; INVALID SETUP; no rejection; owner chose fresh enemy-free save | NVG-0260 | [events](2026-09-01_run_de53a2e7_preflight-health_events.tsv), [result](2026-09-01_run_de53a2e7_preflight-health_result.json) |
| 2026-09-01 | `48b621a2c852428c85cbaab26087190f` | NVG-0260 PASS; NVG-0261 `SETTLE_FAILED` | `gravestowne_street_crater_01`; second port recovered visually but game never confirmed stable ground; REJECT `SETTLE_FAILED_NO_GROUND`; health 100; exact restore | NVG-0262 | [events](2026-09-01_run_48b621a2_nvg-0261_review_events.tsv), [result](2026-09-01_run_48b621a2_nvg-0261_review_result.json) |
| 2026-09-01 | `afd7886cb0d44d2b98dc4c6c419449f4` | Point `NONE`; `PREFLIGHT_CHANGED` | Player moved while selecting a flat origin; INVALID SETUP; no rejection; new save `HRS_CAROUSEL_110_004` created on verified flat road | NVG-0262 | [events](2026-09-01_run_afd7886c_preflight-movement_events.tsv), [result](2026-09-01_run_afd7886c_preflight-movement_result.json) |
| 2026-09-01 | `aa69115b8f4d420db965a9fd9442756e` | NVG-0262 `SETTLE_FAILED`; 0 pass | Second consecutive `gravestowne_street_crater_01` no-ground failure; owner approved exact-ID family exclusion NVG-0261..0280 (20 crater instances) | NVG-0281 | [events](2026-09-01_run_aa69115b_nvg-0262_review_events.tsv), [result](2026-09-01_run_aa69115b_nvg-0262_review_result.json) |
| 2026-09-01 | `561f632dd1f44874935da491f54165c9` | NVG-0281..0415 PASS 135; NVG-0416 `SETTLE_FAILED` | `oldwest_business_07` / Eric's Stuff; operator saw foot partly embedded in terrain; REJECT approved; health 100; exact restore | NVG-0417 | [events](2026-09-01_run_561f632d_135-pass_nvg-0416_events.tsv), [result](2026-09-01_run_561f632d_135-pass_nvg-0416_result.json) |
| 2026-09-01 | `ae77bed911504c44807e7f3324765fd9` | NVG-0417..0436 PASS 20; NVG-0437 `DWELL_GROUND_FAILED` | `park_basketball` / Hoops Pavilion; health 100; exact restore; REVIEW pending visual | NVG-0437 | [events](2026-09-01_run_ae77bed9_20-pass_nvg-0437_events.tsv), [result](2026-09-01_run_ae77bed9_20-pass_nvg-0437_result.json) |
| 2026-09-01 | `3849c2de4a8b4e75844835477fc95ba8` | NVG-0437 `DWELL_GROUND_FAILED`; 0 pass | Retry reproduced; unsafe narrow court edge beside steep drop/fence; retire exact anchor as `ANCHOR_UNSAFE_ADJUST_CANDIDATE`; preserve `park_basketball` for later rotation-aware court-center offset | NVG-0438 | [events](2026-09-01_run_3849c2de_nvg-0437_visual-retry_events.tsv), [result](2026-09-01_run_3849c2de_nvg-0437_visual-retry_result.json) |
| 2026-09-01 | `77eacf53f2ec42fcacad267bc6d6179b` | NVG-0438..0443 PASS 6; NVG-0444 `SETTLE_FAILED` | Operator observed a roughly 10-block lift followed by a drop; REJECT `UNSAFE_VERTICAL_DROP_FALL_HAZARD`; health 100; exact restore | NVG-0445 | [events](2026-09-01_run_77eacf53_6-pass_nvg-0444_fall-hazard_events.tsv), [result](2026-09-01_run_77eacf53_6-pass_nvg-0444_fall-hazard_result.json) |
| 2026-09-01 | `15462cc0c7c045bf8dd66ab9961520e0` | NVG-0445..0455 PASS 11; NVG-0456 `SETTLE_FAILED` | NVG-0445 visually dramatic and held out of clear-good set; NVG-0456 unresolved pending visual, no rejection; health 100; exact restore | Certification of 171 clear survivors | [events](2026-09-01_run_15462cc0_11-pass_nvg-0456-review_events.tsv), [result](2026-09-01_run_15462cc0_11-pass_nvg-0456-review_result.json) |
| 2026-09-01 | `c363809706cc4bb1b24e8812881fd8fe` | Point `NONE`; `ENVIRONMENT_REJECTED`; 0 pass | INVALID SETUP before testing, likely wrong loaded save; no point rejection | Re-arm exact `HRS_CAROUSEL_110_006` batch | no events created; [result](2026-09-01_run_c3638097_environment-rejected_result.json) |
| 2026-09-01 | `9c3d7de63ece4f60a8537cad43264175` | Point `NONE`; `ENVIRONMENT_REJECTED`; 0 pass | INVALID SETUP confirmed exact-name mismatch: runtime GameName was `HRS_CAROUSEL_110_007` while arm required `006`; no point rejection | Re-arm exact `007` batch | no events created; [result](2026-09-01_run_9c3d7de6_save-mismatch_result.json) |
| 2026-09-01 | `b5dc7a1013294c14b092683ea22a6182` | NVG-0281..0443 PASS 161/161; `ALL_POINTS_PASSED` | Controlled certification on enemy-free `007`: God on, collision on, fly off; health 100; exact restore | Final ten NVG-0446..0455 | [events](2026-09-01_run_b5dc7a10_certification-161-pass_events.tsv), [result](2026-09-01_run_b5dc7a10_certification-161-pass_result.json) |
| 2026-09-01 | `d9b934503be548e081e719df0d8a44fd` | NVG-0446..0455 PASS 10/10; `ALL_POINTS_PASSED` | Controlled certification batch 2 on enemy-free `007`: God on, collision on, fly off; health 100; exact restore; combined survivor certification 171/171 | Certification complete | [events](2026-09-01_run_d9b93450_certification-10-pass_events.tsv), [result](2026-09-01_run_d9b93450_certification-10-pass_result.json) |

## Evidence integrity

| Run | Events SHA-256 | Result SHA-256 |
| --- | --- | --- |
| `66539b363e0c47b99933fc23632801b9` | `226FC94C33081BCB4B3ED4017F219E6F1F772234DC26205D1810A17357306D42` | `2308797D2E04C624A28A26AC1F9870EC701C423606CB1202171C3D31071C81F7` |
| `a33e3860313a4da7b98b51db1f61c48a` | `6D08C7601D75F87B5AD495A2DDECAAF271A460AAF3139663C1614D6AFED09D7D` | `2D050499E110BF870DEEC4BC23C994AE4263A46C90EE4C716E0959FE8ABCD0F0` |
| `f009ae3a18f143568ef93c3518bcf7ee` | `8289A38F25A3600989B404B172331EC3E5D3CEADCFE525A6DB61F6D18BA6C3DB` | `53574BE8B32C42751EF0DE4BF391B2D10B4DF36B9020080D6E5336BC29E90D79` |
| `a8650f63ad2a41c3a4fdb1dde9471b32` | `313678728DD6D8EE5CF4B5B6662DD51D9A7B1334E6C81D0B2FED5AB53B3DB9EA` | `B272ED6B27A54E7739F5BDCB6D2C84335F07B566D867174C622978EA855DA63F` |
| `904d906f7d2244a99a08b2bc3a5afef6` | `A50C8F84A1EB676B527CDF3B27D20AD8E1EC8D58F7C7BD0B5AEE5E38AD08EEA2` | `D457B46D8AF90F4F8FBD8D5C2313B159918A217558E1CEE13FAF1043E3C3C351` |
| `de53a2e7d9b1421499d365389285d243` | `EDAD6C01A9BD0434B2189263CA0E3198864E4F533D1F183C273DA27E07C61B85` | `760F50C1D53945EFCD8E851063378ABC3DEB90BE8294DC9A3F1396214B87F72E` |
| `48b621a2c852428c85cbaab26087190f` | `6EA4B5934B0FC6841FA3A3988C6AC8195815F2068C4FF696D22AFAA6997D1021` | `97CBB9380B14E72E8C2B1B51EF980D0344566E12D17A64A56083FE10F04C5F05` |
| `afd7886cb0d44d2b98dc4c6c419449f4` | `8B0D4544BA7CCCA10952941336EBF73939B920165EA3B46B8087515528C57261` | `0EFE1712F5769F74ADDB19B9BE114075C1493E883A6031B951953EAC9A383FA3` |
| `aa69115b8f4d420db965a9fd9442756e` | `08DE8FEF22EAC8436EFFC319872811D498CC965538B2E126588A081166081613` | `383F2BC98D211FF446D0FA80ED8C4A73B317678955317DA2FCBEF65A1E0721BB` |
| `561f632dd1f44874935da491f54165c9` | `BF5D6BA6D4EBF98F0329AF74A60AA62610434D8CEFE8BE8919FC3350F46FF420` | `8A38A534A73AC2235FBCEC19DC57E83A5CB912A91F266F770F3C80CB5DE33750` |
| `ae77bed911504c44807e7f3324765fd9` | `C29E5CD5B28D992F9277B97A26AFBC0FDC839FD54FB4C1D6B8FC9041F238A4EA` | `4FCBF55E063D9A6C56571DF7DEBFED6286A9C0B4AC1BE57887C659FAB50D066A` |
| `3849c2de4a8b4e75844835477fc95ba8` | `261FFABD2A0DBE435738875BF4CB6BB2EF0667637460E6954DB7BF18351D42FB` | `524E60CC2A45D4B18DFEFFCEC3A43CF85481D9EA893A57F3662856F70800E91D` |
| `77eacf53f2ec42fcacad267bc6d6179b` | `F158BAC9487AA38D1FBE77CC62EB768DF357BBC5A487C34733D67E8F9CB3E1AE` | `EECD5EF9802D93D8335BA2C5167B0F83F74F62D516DECF60D93D0933C193B0AB` |
| `15462cc0c7c045bf8dd66ab9961520e0` | `CEC9A58CA43D936D7661BD0A0DD69AFB54D0E817F8FDFAB5B157546519268A72` | `A1D441E9E866955CDC6D4EF279DE5D9D9BEF28E88824BE39C00D39037BBC7500` |
| `c363809706cc4bb1b24e8812881fd8fe` | N/A (preflight created no event stream) | `3721E2C7BB64FFE0141B08219E80567008697EB13156A8A735D6D174387ACFA1` |
| `9c3d7de63ece4f60a8537cad43264175` | N/A (preflight created no event stream) | `23430FE5241FBBF381B428469E771DF58BC629BC5A2CD982ADAF211CDD87C816` |
| `b5dc7a1013294c14b092683ea22a6182` | `2E0280A625430519959DE0D4C8CE15810044E5F5B83A03B083A86BF6775B76B5` | `4F4F387E975FD2720BCFC10D2D4AFC6CE4C97F4203C40A93D5EA7CACC905DACD` |
| `d9b934503be548e081e719df0d8a44fd` | `61E2E5488BABE7389278B38CB2E93778870DE7F810C5B8506E356DEEA06852E8` | `94852807C13C55591ED74BC21949730FE4DFF71C6773BD30E063438157898593` |

## Row rule

After a completed or failed run, preserve raw bridge files, append one ledger
row and one integrity row, then update Current state. Record the stable range,
pass count, stop ID/reason, short visual observation, decision, next stable ID,
and evidence links. Keep detailed telemetry in the raw files rather than
copying it into this catalog.

Normalized reporting mode: during routine testing, report only pass span/count
or stop ID/reason and the next action. Do not restate established rules.

Final certification gate: after the screening pool is large enough, re-run
every surviving point on a fresh enemy-free save with God ON, collision ON,
fly/noclip OFF, and no movement. Earlier passes with uncertain fly/collision
state remain provisional and must not be represented as final proof.

RWG architecture rule: players generate their own worlds, so never reuse
Navezgane coordinates. Reuse an allowlist of common safe prefab identities;
discover their placed instances and rotations from the loaded world, derive
world-local candidates, then require the same chunk-prime, terrain, grounded,
and fallback checks. A prefab's prior pass qualifies its design as a candidate,
not every placement in every generated world as pre-certified.
