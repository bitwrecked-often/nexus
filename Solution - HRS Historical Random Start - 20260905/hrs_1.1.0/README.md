# Historical Random Start 1.1.0

Use `START.bat` to open the functional manager.

Everything required for normal use starts through `START.bat`. Development
source, tests, evidence, history, generated output, and the legacy preview are
kept under the collapsed `dev` folder so they do not clutter the user-facing
root.

This is the `1.1.0` development/release lane. Random now selects once between
the two approved Navezgane points, NG01 and NG02, using the game-owned random
generator and an explicit two-entry allowlist. The other ten catalog entries
remain non-selectable survey data.

The lane preserves one-shot relocation, safe-landing verification, optional
protection from the initial snow-biome hazard, and nearest opening-trader
routing that follows the relocated player instead of forcing the Pine Forest
trader.

Optional Random-start safeguard: check `Protect the arrival biome hazard` to
suppress the snow hazard for the relocated NG01 character. This snow-first QA
proof does not disable enemies, weather, temperature, ordinary damage, or
hazards in other biomes. Leave it unchecked for fully vanilla biome hazards.

The opening-trader feature was proven end to end in `HRS_TRADER_006`: relocation,
normal tutorial completion, nearest-trader selection, native objective update,
and one-time route completion all succeeded without fallback.

Release notes: [1.1.0 release manifest](dev/docs/n0236.md).

Nexus base-build evidence and remaining promotion gates:
[Nexus evidence baseline](dev/docs/n0240.md).

QA and DEV handoff: [1.1.0 DEV and QA status](dev/docs/n0237.md).

Release identity, acceptance cases, and evidence capture:
[QA cycle records](dev/qa/README.md).

Engineering history: [0.0.8.1 to 0.1.0 development log](dev/docs/n0233.md).

Spawn-pool scouting and new-AI resumption:
[AI context handoff](dev/scouting/AI_CONTEXT_HANDOFF.md).

QA-only deterministic full-POI placement-health screening:
[carousel contract and commands](dev/docs/n0238.md).
