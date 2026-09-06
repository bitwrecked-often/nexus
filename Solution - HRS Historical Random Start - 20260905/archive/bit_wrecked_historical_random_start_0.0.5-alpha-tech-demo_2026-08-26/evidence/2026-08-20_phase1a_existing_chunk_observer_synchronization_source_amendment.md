# Phase 1A existing chunk-observer synchronization source amendment

Date: 2026-08-20 (America/Los_Angeles)

Authorization: Phase 1A existing chunk-observer synchronization source amendment.

## Amendment

- Resolve `player.ChunkObserver` before placement and stop categorically with
  `RELOC_OBSERVER_UNAVAILABLE` when no existing observer is available.
- Preserve exactly one native player placement call:
  `player.SetPosition(candidate.position, true)`.
- Immediately synchronize that same existing observer exactly once with
  `observer.SetPosition(candidate.position)`.
- Do not create, add, remove, or explicitly request a chunk observer.
- Retain the existing monotonic 30-second post-placement verification window.

## Source identity

- Status: `ExistingChunkObserverSynchronizationAmendedUncompiled`
- Source aggregate SHA-256:
  `91B9A998A914C8FB5AEAE04FDA8F09B9C925B5429EC8A56EC41147F34757F4E9`
- `RelocationModApi.cs`: 6460 bytes,
  `423F7B781A6948E8CABD670415A4B88C61097445149CD76A13BAE684043E835E`
- `SanitizedRelocationLog.cs`: 1362 bytes,
  `25CFAAF8ABDC84184713A0E80D5A3C4FDADBB7258B3FA9A3B786777979597875`

## Verification

Both `pwsh.exe` and Windows `powershell.exe` passed:

- relocation static checks: 1 pass, 0 failures;
- semantic harness: 7 passes, 0 failures;
- pure contract suite: 23 passes, 0 failures, including the unavailable-observer
  fail-closed case.

The static checks enforce one player placement, one existing-observer
synchronization, correct ordering, and absence of observer add/remove or explicit
chunk-request calls.

## Execution boundary

- No compilation or payload staging was performed.
- No live payload was replaced; live DLL SHA-256 remains
  `DE273E9216209CA188FA179614D7F4FC19037DB78D92BFB15C6BB985E05F61A6`.
- The game was closed at verification time.
- The exact disposable target save remained present and was not reset or changed
  by this source-amendment step.

Next gate: authorize observer-synchronized Phase 1A relocation recompilation.
