# Phase 1A AddCustomVar — Source Amendment

Date: 2026-08-20  
Decision: Source/static tests PASS; compile/stage/live/save/run NO-GO

After runtime evidence and installed IL inspection proved that direct
`SetCustomVarNetwork` only sends a network package and does not update the
local CVar dictionary, the owner authorized a narrow source amendment.

The sole reservation call is now:

```text
player.Buffs.AddCustomVar(Name, 1f)
```

The absent-marker guard and immediate read-back remain unchanged. Installed IL
proves `AddCustomVar` calls the full setter with the network flag enabled; that
setter updates `EntityBuffs.CVars` locally before following the synchronized
send path.

Static tests now require exactly one `AddCustomVar` call and prohibit every
direct `SetCustomVarNetwork` call. They also retain the strict branch order,
exact metadata, and zero-relocation checks. Static tests passed under
PowerShell 7 and Windows PowerShell 5.1. The semantic suite remained 22/22 in
both environments.

Updated source values:

- `MarkerState.cs`: 1,087 bytes,
  `B3ED1971B0873D3D2F6B71568C759243AA24AD6F9FCDDEEB4D46A81DC1B21767`
- six-file source aggregate:
  `8A8CCD76060D5540214A38BDBE21FE1ADD26961B9BACD5033E3CA5F9E22D2E8F`

No compiler ran. External/live DLLs and payloads remain unchanged. The exact
disposable save from the failed marker attempt remains preserved in place; it
was not moved or reset. Compilation and every later mutation remain separate
authorization gates.
