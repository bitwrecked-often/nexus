# Phase 1A Atomic-Semantic Relocation — First-Load Preflight

Date: 2026-08-20  
Decision: Non-launching preflight PASS; launch NO-GO

The owner authorized the atomic-semantic first-load preflight. It confirmed:

- game/server closed and Steam running;
- exact live and staged payload aggregate
  `4F5F5189E3F89CC259C39233FB5762529BE9CB178C3CE9508E94056E4641EAE6`;
- live DLL SHA-256
  `632208686E0C5A2156DC27B32FD3579F80A0AC9E60171B262E1147AEEE8EFCE2`;
- pinned `Assembly-CSharp.dll` fingerprint;
- EAC disabled in launcher settings;
- marker-only probe absent;
- exact target save absent; and
- semantic harness passing 7/7.

The aggregate-only baseline is stored at:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\phase1a-atomic-semantic-baseline-2026-08-20.json`

| Protected tree | Files | Bytes | SHA-256 |
| --- | ---: | ---: | --- |
| Game managed | 154 | 49,094,936 | `2EA9679D59A7DC759DC4F582A6673B0F2106CE475DA4F7FF998DE907BFCD5C4C` |
| Foreign Mods | 117 | 21,845,646 | `B56FE9701B98231617DBED2431865CA077AF4B84105C26388496A336D056BD51` |
| Foreign saves | 12,526 | 5,362,081,455 | `163843D68515F8F9A1A0D6BDEA6B8777E5A48D7C6792738A59E1B998695A4945` |

Nothing was launched or changed in game, mod, or save state. The only new
artifact is the external aggregate-only preflight baseline.

Next gate: **authorize atomic-semantic Phase 1A relocation first-load launch**.
