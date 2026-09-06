# Phase 1A Read-Only Reload and CVar IL Finding

Date: 2026-08-20  
Decision: Marker persistence FAIL; root cause confirmed; source change NO-GO

The owner authorized one read-only reload of the exact disposable target. The
probe emitted exactly:

```text
[HRS-P1A-MARKER] v=0.0.1 build=b14 reason=MARKER_READY
[HRS-P1A-MARKER] v=0.0.1 build=b14 reason=MARKER_RELOAD_ABSENT
```

There was no Reserved, Completed, Invalid, target-rejected, or internal-failure
result. The user exited normally. The game is closed. The post-reload target
contains 74 files with aggregate SHA-256:

`FAFE33B0E12F536CC717551F23BDF0F0D8E509D5036348B01B5CDC6B27E8E256`

Read-only Cecil inspection of the pinned installed `Assembly-CSharp.dll`
confirmed the root cause:

- `SetCustomVarNetwork(String, Single, CVarOperation)` constructs a
  `NetPackageModifyCVar` and calls `ConnectionManager.SendPackage` on the
  server or `SendToServer` on a client. It contains no local CVar dictionary
  update.
- `AddCustomVar(String, Single)` calls
  `SetCustomVar(String, Single, true, CVarOperation.set, false)`.
- That full setter updates `EntityBuffs.CVars` first and, when appropriate,
  subsequently calls `SetCustomVarNetwork`.

The observed immediate-readback failure and reload absence therefore match the
installed implementation: the probe called the network-send helper directly
instead of the game’s local-and-synchronized setter path.

A future narrow source amendment may replace the sole direct network call with
`AddCustomVar(Name, 1f)` while preserving absent-marker guards, immediate
read-back, read-only LoadedGame observation, exact target/authority controls,
and the prohibition on retries/removal/relocation. That source amendment,
rebuild, payload replacement, target backup/reset, and rerun each remain gated.
