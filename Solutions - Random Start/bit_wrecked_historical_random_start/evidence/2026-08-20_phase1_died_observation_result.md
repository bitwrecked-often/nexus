# Phase 1 Observation Probe — Died Result

Date: 2026-08-20  
Decision: Ordinary-death rejection case PASS

## Sanitized sequence

```text
[HRS-P1] v=0.0.1 build=b14 authority=pending locality=pending lifecycle=init entity=false count=0 elapsedMs=0 reason=OBS_READY
[HRS-P1] v=0.0.1 build=b14 authority=server locality=local lifecycle=LoadedGame entity=true count=1 elapsedMs=1 reason=OBS_LIFECYCLE_REJECTED
[HRS-P1] v=0.0.1 build=b14 authority=server locality=local lifecycle=Died entity=true count=2 elapsedMs=0 reason=OBS_LIFECYCLE_REJECTED
```

The owner performed one ordinary death and normal respawn in only the approved
disposable target. No console, Developer Mode, cheat, or manual teleport was
used. The extractor passed, unexpected reason count was zero, and the game
closed normally.

## State comparison

- Target files: 73 before, 74 after; ordinary death/save state changed within
  the disposable target as expected.
- Target aggregate before:
  `D24D59A1FF77BE7B9A6C788D365EFF21CB4B3D100EF939E4F64CE787B003C903`
- Target aggregate after:
  `6B8ED5C59F535F557FC7DA702E9DA2DDF1EE9D176DEED47D7296220A06C3067C`
- `newGameOptions.sdf` content hash: unchanged.
- `serveradmin.xml` content hash: unchanged; base-game timestamp touched.
- DLL and `ModInfo.xml` hashes: unchanged.
- No existing world/save file changed.

The exact authoritative `Died` callback was rejected without a probe action.
Duplicate suppression and clean-removal testing remain pending.
