# Phase 1A Observer-Predecessor Target — Backup and Reset

Date: 2026-08-20  
Decision: Exact failed target reset recoverably; preflight/run NO-GO

The owner authorized backup and reset of exactly:

`%APPDATA%\7DaysToDie\Saves\Navezgane\HRS_Phase1A_Test_001`

Preflight matched the recorded observer-predecessor chunk-timeout target:

- files: 74;
- bytes: 19,511,339; and
- aggregate: `B8524BE2C216798C6A36FD7AAF7EE5BB71A30E575C2C00E5FBA44640DD770F30`.

The target was moved intact and recoverably to:

`C:\BitWreckedDisposable\HRS_Phase1A\Backup\HRS_Phase1A_Test_001.observer-predecessor-chunk-timeout-2026-08-20`

The backup retains the same file count, byte count, and aggregate. The live
target is absent. No other save or mod was moved or replaced during this step.

The installed observer-synchronized DLL remains:

`9FBF9CDEBAB108633E916D338F6D9571D282533A4E6E3FBC51AB529EB1825FAB`

The game remained closed. First-load preflight and launch remain separately
gated.

Next gate: authorize observer-synchronized Phase 1A relocation first-load preflight.
