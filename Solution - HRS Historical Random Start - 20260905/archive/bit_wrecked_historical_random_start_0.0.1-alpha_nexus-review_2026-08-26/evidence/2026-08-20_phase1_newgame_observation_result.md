# Phase 1 Observation Probe — NewGame Result

Date: 2026-08-20  
Decision: NewGame observation case PASS; full Phase 1 promotion remains pending

## Exact test

- Runtime: owner-designated installed Steam lab
- Execution: local single-player, Steam authenticated, EAC disabled
- World/game: `Navezgane / HRS_Phase1_Test_001`
- Payload: exact two-file owned DEV payload
- Interaction: create the new target, wait for first spawn/starter UI, exit
  normally

The first launch attempt established that Steam authentication is a normal
prerequisite and emitted `OBS_READY`, but created no save. The authenticated
retry created only the approved disposable target and reached first spawn.

## Sanitized probe evidence

```text
[HRS-P1] v=0.0.1 build=b14 authority=pending locality=pending lifecycle=init entity=false count=0 elapsedMs=0 reason=OBS_READY
[HRS-P1] v=0.0.1 build=b14 authority=server locality=local lifecycle=NewGame entity=true count=1 elapsedMs=1 reason=OBS_ELIGIBLE_NEW_CHARACTER
```

The privacy-safe extractor passed. Unexpected build, target, EAC, authority,
entity, duplicate-capacity, or internal-failure reason count was zero. No
BitWrecked load error or exception pattern was present.

## Post-test state

- Game process closed normally.
- Installed payload still contains exactly two files and both SHA-256 values
  match the approved payload.
- The new disposable target exists with 68 files.
- Initial target-tree aggregate SHA-256:
  `BC135E9D8D1E94204247A0614FBEBBD5BB8CF0BCB65E26D1270B28E30062F393`
- No existing world/save folder showed a file modification during the test.

The base game updated ordinary save-root metadata files `newGameOptions.sdf`
and `serveradmin.xml`. Those files are outside the target world but are normal
game-owned launch/config state. Pre-launch hashes were not captured for them,
so this result does not claim byte-zero delta for those two files. Their current
hashes are now recorded for later comparison:

- `newGameOptions.sdf`:
  `B2BAB832AE44C9612703ED2914BDC89854919D97A16DDDF1102543B331425A6B`
- `serveradmin.xml`:
  `19C6F4383DA6093690BDE3482B164BF0F8A8291FD3E0BE3ECCB8BBA41A021774`

Static source and IL review still show no probe file-write or gameplay mutation
path. This runtime result proves the narrow authoritative `NewGame` observation
signal; it does not by itself prove every required reload, death, reconnect,
duplicate, removal, or before/after state case.

## Next gate

Capture a fresh pre-reload manifest, then run the exact target once more and
verify `LoadedGame` is rejected without changing the payload or unrelated
state. Full Phase 1 promotion remains NO-GO until the remaining matrix and
clean-removal case pass.
