# Phase 1A Relocation Target — Backup and Reset

Date: 2026-08-20  
Decision: Exact disposable target reset recoverably; install/run NO-GO

The owner authorized backup and reset of exactly:

`%APPDATA%\7DaysToDie\Saves\Navezgane\HRS_Phase1A_Test_001`

Preflight resolved that exact non-reparse directory beneath the Navezgane save
root and confirmed the game/server were closed. The target contained 73 files,
19,386,796 bytes. Its aggregate-only fingerprint was:

`C7376604C31C271B580B875F64916BE8985ED7F5295EB13AD2CD04E65479E9C7`

The folder was moved recoverably to:

`C:\BitWreckedDisposable\HRS_Phase1A\Backup\HRS_Phase1A_Test_001.pre-relocation-semantic-2026-08-20`

The backup has the same file count, byte count, and aggregate. The original live
target is absent, allowing a clean game with the same name to be created with an
absent marker.

The marker and relocation probe folders both remain absent from live `Mods`.
The reviewed staged relocation payload was not changed. No other save or Mod was
changed.
