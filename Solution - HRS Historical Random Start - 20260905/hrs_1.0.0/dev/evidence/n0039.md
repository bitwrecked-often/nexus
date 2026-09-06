# Phase 1A Atomic-Semantic — Corrected New Game Relaunch

Date: 2026-08-20  
Decision: Exact New Game atomic relocation PASS; normal-exit checks pending

The owner authorized starting the client again after the stale Continue-path
attempt. Immediate preflight reconfirmed Steam running, game/server closed,
EAC disabled, exact target absent, and live payload aggregate
`4F5F5189E3F89CC259C39233FB5762529BE9CB178C3CE9508E94056E4641EAE6`.

The visible no-EAC client started successfully with dedicated log:

`%APPDATA%\7DaysToDie\logs\output_log_client__phase1a_atomic_semantic_corrected_newgame__2026-08-21__05-32-14.txt`

The menu exposed the older `HRS_Phase1_Test_001` name without the `A`; that
target was loaded first and correctly produced `RELOC_TARGET_REJECTED` without
placement. The exact authorized target was not an existing searchable save. It
had to be created as a new Navezgane game named:

`HRS_Phase1A_Test_001`

On that exact new target, the sanitized runtime sequence was:

1. `RELOC_PLACEMENT_DEFERRED`
2. `RELOC_PLACEMENT_CALLED`
3. `RELOC_SEMANTIC_UNCHANGED`
4. `RELOC_COMPLETED`

The owner visually confirmed a successful relocated spawn. The same client log
contains the earlier categorical target rejection and the later successful
exact-target sequence; they are distinct New Game attempts and must not be
conflated.

The owner exited normally. The post-exit target snapshot is 77 files,
20,815,822 bytes, aggregate
`8593ABDF5D4256F7C5EEFFB2D2E54C52AD27E2EDCCC88BFB8F13D5F642E2EB67`.
It is stored in the aggregate-only post snapshot:

`C:\BitWreckedDisposable\HRS_Phase1A\BuildStage\phase1a-atomic-semantic-post-completed-2026-08-20.json`

Game-managed and foreign-mod aggregates match baseline exactly. The broad
foreign-save aggregate does not: the earlier no-`A` target was opened and saved
in this same client session, and New Game updated root save metadata. Files with
timestamps in the corrected-launch interval were scoped to both HRS target
directories, `newGameOptions.sdf`, and `serveradmin.xml`. Because the baseline
is aggregate-only, this mixed session is not claimed as a strict
all-foreign-saves preservation pass.

Read-only completed-marker persistence reload remains pending.
