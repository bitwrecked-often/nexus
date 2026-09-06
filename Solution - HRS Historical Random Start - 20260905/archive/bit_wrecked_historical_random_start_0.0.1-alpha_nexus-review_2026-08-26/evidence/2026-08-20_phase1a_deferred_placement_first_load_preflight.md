# Phase 1A Deferred-Placement Relocation — First-Load Preflight

Date: 2026-08-20  
Decision: Non-launching preflight PASS; launch NO-GO

The owner authorized the deferred-placement first-load preflight. It confirmed:

- game/server closed and Steam running;
- exact live and staged payload aggregate
  `2BADF2BE5BB1972CB55CF49A7EEB25FD499D642E54FBCC40D3F6E1F243AF863C`;
- pinned game assembly fingerprint;
- EAC disabled;
- marker-only probe absent;
- exact target absent; and
- semantic harness passing 7/7.

The aggregate-only baseline is stored at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\phase1a-deferred-placement-baseline-2026-08-20.json`

| Protected tree | Files | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| Game managed | 154 | 49,094,936 | `2EA9679D59A7DC759DC4F582A6673B0F2106CE475DA4F7FF998DE907BFCD5C4C` |
| Foreign Mods | 117 | 21,845,646 | `B56FE9701B98231617DBED2431865CA077AF4B84105C26388496A336D056BD51` |
| Foreign saves | 12,526 | 5,362,081,455 | `163843D68515F8F9A1A0D6BDEA6B8777E5A48D7C6792738A59E1B998695A4945` |

Nothing was launched or changed in game, mod, or save state.

Next gate: authorize deferred-placement Phase 1A relocation first-load launch.
