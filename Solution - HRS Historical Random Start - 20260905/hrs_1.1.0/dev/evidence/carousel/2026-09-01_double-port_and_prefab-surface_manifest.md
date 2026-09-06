# Carousel landing-model correction

The apparent NVG-0174–NVG-0178 failure streak exposed two separate test-state
and runtime issues. Ground results collected with player collision disabled are
invalid, because `onGround` cannot be trusted. NVG-0174 through NVG-0177 were
therefore removed from the rejection record pending clean collision-on retest.

Collision-on baseline run `6058b0e683ee4635acae7be7e22deef9` showed
NVG-0174 landing near Y 60 and then falling below Y 57 about 1.8 seconds later.
The carousel was changed to teleport to the catalog anchor, wait two seconds
after the chunk exists, recalculate the landing, and teleport again two metres
above it. Comparison run `7175af700eb24ab4be6286193c82d547` then passed
NVG-0174 and NVG-0175.

The same run placed NVG-0176 on a formed prefab surface several metres above
the terrain result. The validator was corrected to baseline the actual grounded
surface near the catalog elevation. Clean run
`163a044065cf425690c6c2eadb9a22ed` still could not ground NVG-0176. Human
observation confirmed unstable floating beneath a surface made from full prefab
blocks, so NVG-0176 is a genuine `SETTLE_FAILED_BELOW_PREFAB_BLOCKS` rejection.
No motion-only fallback was added because it could falsely approve this exact
hazard.

Current runtime invariants are: God mode ON, collision ON, fly OFF; primed
two-second double teleport; two-metre elevated second landing; actual grounded
surface baseline; strict health, position, elevation, and renewed-ground checks;
and human visual veto for hazards telemetry cannot represent.

## Preserved artifacts

- `2026-09-01_run_6058b0e6_nvg-0174_collision-on-baseline_events.tsv` — 888
  bytes, SHA-256
  `00B6CD80A7B36AC18B9D7AF557C5742DD3BD608F9039D7AF93C7F45C9F5F96CE`
- `2026-09-01_run_6058b0e6_nvg-0174_collision-on-baseline_result.json` — 349
  bytes, SHA-256
  `6AC6B2E05C935F7AEAEEA09382FE475335323278187270EB598CF4518BDB60E6`
- `2026-09-01_run_7175af70_double-port-comparison_events.tsv` — 2,188
  bytes, SHA-256
  `FCF761FA0F99171225FA3637F596A384AD8D9577DAF4183B11B508C0BD874915`
- `2026-09-01_run_7175af70_double-port-comparison_result.json` — 341 bytes,
  SHA-256
  `4AD17BFFC0C703FE73D22054424F6E411958D8A14B40F70595137F88EE732702`
- `2026-09-01_run_163a0440_nvg-0176_below-prefab_events.tsv` — 907 bytes,
  SHA-256
  `23A889E85B323E30101FBE5147DD31E8CD397435A50E43C5AEFDA6A8E392C3E4`
- `2026-09-01_run_163a0440_nvg-0176_below-prefab_result.json` — 344 bytes,
  SHA-256
  `11A6AB3A9D8DE29006ED3B9AA441E1786CBB825C035E0AE7B97399E1B0378E7E`

At the 2026-09-01T03:22:07Z snapshot, continuation run
`66539b363e0c47b99933fc23632801b9` had passed 37 consecutive points from
NVG-0177 through NVG-0213 and was dwelling at NVG-0214. The active catalog has
738 points and seven confirmed rejects. The installed 81,408-byte QA DLL
SHA-256 is
`E1798A6A9769892177427936D9CE24AB780416C25EB09CE5B890549F3364A7DB`;
active-ID-list SHA-256 is
`062AC14B2E017A0E222072C848D05CAF196F88FB4D65423674B4AFD53C0CC975`;
runtime-source SHA-256 is
`BC4D1A7E55977D4C460865A4468BB0CA7ED8A6ED01CAE9AC107ED32AC2B81508`.
