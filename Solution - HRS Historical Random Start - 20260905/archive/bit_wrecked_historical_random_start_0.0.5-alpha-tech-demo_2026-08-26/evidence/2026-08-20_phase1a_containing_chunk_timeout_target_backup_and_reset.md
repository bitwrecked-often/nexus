# Phase 1A Containing-Chunk Timeout Target — Backup and Reset

Date: 2026-08-20  
Decision: Exact failed target reset recoverably; preflight/run NO-GO

The owner authorized backup and reset of exactly
`%APPDATA%\7DaysToDie\Saves\Navezgane\HRS_Phase1A_Test_001`.

Preflight matched the recorded containing-chunk-timeout target:

- files: 74;
- bytes: 19,295,385; and
- aggregate: `13D6773CC3DB13F35B0AEDFCB769685D2767784758DA5CF9B375D8A1C97FF909`.

The target was moved intact and recoverably to:

`C:\BitWreckedDisposable\HRS_Phase1A\Backup\HRS_Phase1A_Test_001.containing-chunk-timeout-2026-08-20`

The backup retains the same file count, byte count, and aggregate. The live
target is absent. No other save or mod was moved or changed.

The installed deferred-placement DLL remains
`3BB52A412C6B156D849FEC1D2843BF9CD32A0ED0F44BC0CB39E152E2CD37D611`.
The game remained closed. Preflight and launch remain separately gated.

Next gate: authorize deferred-placement Phase 1A relocation first-load preflight.
