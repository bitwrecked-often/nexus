# Phase 1A Marker-Only Probe Design 0.0.1

Date: 2026-08-20  
Status: Source scaffold only; not compiled, installed, or executed

This private probe tests only whether the game-owned player CVar
`bitwrecked_hrs_state_v1` can be reserved with value `1` and read back during
the exact approved local-single-player `NewGame` callback.

The callback fails closed unless the pinned Assembly-CSharp MVID, installed
game root, save root, `Navezgane / HRS_Phase1A_Test_001`, EAC-disabled state,
authoritative server state, local player, and `NewGame` lifecycle all match.
It rejects any existing marker value before writing.

The only authorized future mutation represented in this source is one
`EntityBuffs.AddCustomVar` reservation followed immediately by a read-back.
Installed IL proves this API updates the local CVar dictionary through the full
setter and then follows its synchronized send path. Direct calls to the
network-send-only `SetCustomVarNetwork` helper are prohibited. The scaffold
contains no candidate selection, position read/write,
teleport, respawn, Harmony, command, file-write, process, or network-client
path. It cannot set `Completed=2`.

For the exact same target and authority lane, `LoadedGame` may resolve the
player and read the marker once to report Reserved, Completed, Absent, or
Invalid. That branch returns before the `NewGame` gate and cannot call the
reservation writer. All other lifecycle values are rejected without a marker
write. This read-only reload lane exists solely to prove ordinary save/reload
persistence.

Compilation, installation, target creation, first launch, reload persistence
test, and removal each remain separate approval gates. Relocation source must
not be added or compiled until the marker-only save/sync result is reviewed.
