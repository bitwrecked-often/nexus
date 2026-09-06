# Phase 1A Observer-Synchronized Timeout Target — Backup and Reset

Date: 2026-08-20  
Decision: Exact failed target reset recoverably; preflight/run NO-GO

The owner authorized backup and reset of exactly:

`%APPDATA%\7DaysToDie\Saves\Navezgane\HRS_Phase1A_Test_001`

Preflight matched the recorded observer-synchronized chunk-timeout target:

- files: 78;
- bytes: 19,295,417; and
- aggregate: `132B0E7F390BF061FB11C6B1E133E884342E730220AAA76AE769CCF475EF5799`.

The target was moved intact and recoverably to:

`C:\BitWreckedDisposable\HRS_Phase1A\Backup\HRS_Phase1A_Test_001.observer-synchronized-chunk-timeout-2026-08-20`

The backup retains the same file count, byte count, and aggregate. The live
target is absent. No other save or mod was moved or changed during this step.

The installed containing-chunk DLL remains:

`91C0AE24599088C64485C29851847CD5C703CF4C0ADF7A1D72C3D9C371417CCD`

The game remained closed. First-load preflight and launch remain separately
gated.

Next gate: authorize containing-chunk Phase 1A relocation first-load preflight.
