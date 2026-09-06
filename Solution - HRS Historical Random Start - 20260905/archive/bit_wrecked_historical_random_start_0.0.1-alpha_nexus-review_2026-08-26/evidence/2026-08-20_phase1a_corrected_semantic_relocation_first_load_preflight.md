# Phase 1A Corrected Semantic Relocation — First-Load Preflight

Date: 2026-08-20  
Decision: Non-launching first-load preflight PASS; launch NO-GO

The owner authorized a read-only/non-launching operational preflight. It
confirmed:

- game/server processes closed;
- Steam build ID `24436778`;
- `Assembly-CSharp.dll` SHA-256
  `B13862E30D8B28F42B83FE6A36BF074D155A6C43164E7B0797A6E4F77BD7DEA3`;
- `Assembly-CSharp.dll` MVID `acb580d9-e1ab-497d-a8dc-47e47c1fc300`;
- EAC disabled in the default launcher configuration;
- installed and staged relocation payload files match their pinned hashes;
- marker probe absent;
- exact `Navezgane\HRS_Phase1A_Test_001` target absent; and
- semantic harness pure tests pass 7/7 in an isolated PowerShell process.

An aggregate-only baseline was captured externally at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\phase1a-relocation-semantic-baseline-2026-08-20.json`

Protected baseline values:

| Tree | Present | Files | Bytes | SHA-256 |
| --- | --- | ---: | ---: | --- |
| Game managed | true | 154 | 49,094,936 | `2EA9679D59A7DC759DC4F582A6673B0F2106CE475DA4F7FF998DE907BFCD5C4C` |
| Foreign Mods | true | 117 | 21,845,646 | `B56FE9701B98231617DBED2431865CA077AF4B84105C26388496A336D056BD51` |
| Foreign saves | true | 12,526 | 5,362,081,455 | `CE3564E1E1BB04F8348A1570D36CA8302641ABCA2EFE509A495C5366FAC1C23D` |
| Exact target | false | 0 | 0 | absent |

The snapshot contains no paths, identities, coordinates, or individual state
values. The game was not launched. First-load launch remains a separate gate.
