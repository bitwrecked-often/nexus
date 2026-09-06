# Phase 1A ModInfo Internal Name — Source Correction

Date: 2026-08-20  
Decision: Source metadata/static tests PASS; stage/live/save/run NO-GO

After the first-load attempt proved the game rejected a display-style internal
ModInfo Name containing spaces, the owner authorized a source-only correction.
The internal Name is now exactly:

`BitWrecked_HistoricalRandomStart_PHASE1A_DEV`

`DisplayName` remains human-readable and unchanged. `SkipWithAntiCheat` remains
`true`. Static tests now require both the exact owned token and the installed
game grammar `^[0-9a-zA-Z_\-]+$`; they passed under PowerShell 7 and Windows
PowerShell 5.1. The C# source and reviewed amended DLL are unchanged.

Corrected `ModInfo.xml`:

- bytes: 395
- SHA-256: `0F7B261BDDE9F7F780882F0BB36937C0E20A46AC06EAF27B8A53E4E4E8337657`

Updated six-file source aggregate SHA-256:
`3E5E890DF23B9FDF9C7DB78C60100C6D036AABA438FAC572C28BEA2EEDE7AF1A`

The amended external payload and live owned folder still contain the prior
rejected metadata hash
`439777B85A3E9288F9DC2F00B5A9DD0527D29CD48EBC3DAACFEA037A540CD6F2`.
Neither was modified. The game remains closed and the vanilla-created
disposable target remains preserved. Staging and live replacement require
separate authorization; target reset and relaunch remain later explicit gates.
