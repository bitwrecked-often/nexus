# 1.2.5-qa.002 QA finding: opening trader route stayed in Pine Forest

Observed on 2026-09-29 during an end-user test of `1.2.5-qa.002`.

## Observed behavior

- Game log reports `V 3.3.0 (b17)`. Installed `Assembly-CSharp.dll` SHA-256 is `AA4275991736D276EC75BB4047E45F76E0242AA47D9895890F3761098D4CC146`, the release record's tested build. Installed HRS `d0163.dll` SHA-256 is `D8C73D5A4126D1BC7826C0E507A946B53FA3F79E6DD3053E90F3BB593CF33EF8`, the frozen candidate runtime.
- Applied policy revision 12: `Test_Random_Spawn_Wasteland_01`, `RandomSafe`, `Chosen`, biome 8 (Wasteland).
- HRS selected biome 8 and completed a landing at placed prefab `lot_vacant_02`, placed ID 1776, position `(619.0, 50.1, 1890.0)`.
- The user's screenshot shows the opening **Journey to Settlement** quest pointing to a trader in Pine Forest. The user reached that trader.
- The HRS log records `TRADER_ROUTE_READY` at 19:31:03, but no `TRADER_ROUTE_QUEST_SEEN`, `TRADER_ROUTE_SELECTED`, `TRADER_ROUTE_SAME_BIOME`, `TRADER_ROUTE_CROSS_BIOME`, or `TRADER_ROUTE_COMPLETED` through 19:47. Thus this was not an HRS-recorded cross-biome fallback.
- The game log shows player unregistered at 19:36:50 and registered again at 19:37:31 in the same process. No second `TRADER_ROUTE_READY` was logged.
- Tester confirmed the sequence: log out after the Wasteland landing, log back in, finish the starter tasks, then receive the opening trader quest. The quest pointed to Pine Forest.

## Leading hypothesis for DEV to verify

`AttachTraderRoute` returns immediately while the static `traderRouteSubscribed` flag is true. On re-entry, `OnPlayerSpawned` attempts to attach the pending route, but may leave `traderRoutePlayer` and its `QuestAccepted` subscription bound to the old player object. `ObservePendingTraderRoute` then observes the old journal. Check this against the actual quest lifecycle before changing code.

The runtime also recognizes `quest_whiteRiverCitizen1` and its phase-1 `trader` objective, both present in b17 `Data/Config/quests.xml`. Its route should prefer a placed trader in biome 8 and log the selection, or explicitly log a cross-biome fallback if no usable Wasteland trader exists.

## Follow-up

Reproduce once without leaving the world and once after a world exit/re-entry before reaching the opening trader. In both runs, require a route decision and verify the quest marker matches the logged placed trader. Inspect trader index availability and the quest-acceptance callback if a no-reload run also fails. Preserve the frozen customer ZIP; any runtime repair needs a new candidate and QA cycle.

Evidence source: `%APPDATA%\7DaysToDie\BacktraceLogs\Player-2026-09-30_02-27-53.719.log`, installed Bridge policy and result files, and the tester's screenshot in this conversation.

## No-logout control and Steam timing

The tester then used a fresh game name `Test_Random_Spawn_Wasteland_02` (policy revision 13) and stayed in the world. Log `Player-2026-09-30_02-52-55.947.log` records a Wasteland landing followed by `TRADER_ROUTE_RESERVED`, `TRADER_ROUTE_SAME_BIOME`, `TRADER_ROUTE_SELECTED placedId=1626 biome=8 crossBiome=0`, and `TRADER_ROUTE_COMPLETED`. This directly narrows the failure to the logout/re-entry path.

The manager history does show an earlier apply snapshot at 19:26:02, shortly before Steam started at 19:26:09. However the failing game run used policy revision 12, applied at 19:27:42 after Steam started; the game then loaded the exact candidate mod and completed the Wasteland relocation. The pre-Steam apply attempt does not explain the missing trader route in that run.

Current mitigation: the user chose a visible Random-mode UX notice and public known-issue text, while leaving the runtime repair deferred. The working manager and README prototype is in `prototypes/hrs-1.2.5-trader-session-notice` for the next DEV candidate. The issue remains open; if DEV later repairs it, use the existing saved route marker with session-scoped listener cleanup and re-test no logout, world exit/re-entry before the quest, and interaction with other mods. Any repair or customer UX change requires a new candidate and QA identity.

The user clarified the intended session boundary: the trader visit itself need not be completed before logout; the destination only needs to be assigned. The public and manager notice now says to stay until the Journey to Settlement trader marker appears. A logout after `TRADER_ROUTE_COMPLETED` but before visiting the trader should be checked once to confirm that the assigned objective survives re-entry.
