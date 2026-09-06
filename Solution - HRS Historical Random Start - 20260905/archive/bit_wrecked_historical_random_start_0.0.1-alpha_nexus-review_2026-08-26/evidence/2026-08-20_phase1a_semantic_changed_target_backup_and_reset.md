# Phase 1A Semantic-Changed Target — Backup and Reset

Date: 2026-08-20  
Decision: Exact failed target reset recoverably; preflight/run NO-GO

The owner authorized backup and reset of exactly:

`%APPDATA%\7DaysToDie\Saves\Navezgane\HRS_Phase1A_Test_001`

PowerShell 7 reproduced the recorded post-runtime target identity:

- files: 68;
- bytes: 19,377,481; and
- aggregate: `9E902ABBAD2FECDEDA365029EFD794FCB44D13FC1F5F6C53525130211148A458`.

Windows PowerShell 5.1 produced a different aggregate solely because its
`Sort-Object FullName` ordering differs for this path set. It reported the same
68 files and byte count. The engine originally used for the recorded snapshot,
PowerShell 7, reproduced the recorded aggregate exactly before mutation.

The exact target was moved intact and recoverably to:

`C:\BitWreckedDisposable\HRS_Phase1A\Backup\HRS_Phase1A_Test_001.semantic-changed-2026-08-20`

The backup retains the recorded file count, byte count, and aggregate. The live
target is absent. The protected foreign-save aggregate remained unchanged at:

`163843D68515F8F9A1A0D6BDEA6B8777E5A48D7C6792738A59E1B998695A4945`

No other save or mod was moved or changed. The game remained closed.

Next gate: **authorize atomic-semantic Phase 1A relocation first-load preflight**.
