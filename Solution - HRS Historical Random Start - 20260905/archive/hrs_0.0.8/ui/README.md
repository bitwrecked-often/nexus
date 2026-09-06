# Support Files — Player Preview 0.0.7

These files support the clickable Historical Random Start - Alpha 6 Method player preview.

- `p0159.ps1` is a retargeted copy of the proven Bit
  Wrecked blank framework shell. Its player guidance covers exactly Standard
  and Random, optional starting-biome-only or all-dangerous-biomes Random
  safeguards, and nearest-opening-trader continuity.
- `Assets/i0141.png` is the local Bit Wrecked window asset.

The shell is intentionally read-only with respect to gameplay and policy. The
new `Apply Preview Settings` action records the selection only in the open
preview session and confirms the result. Live control edits are shown as
pending against the last applied session snapshot, and any game-folder edit
requires a fresh folder check before Apply. It does not persist policy or
change the game. Its only optional disk write is the existing explicit
user-selected persistent activity log. It has no runtime helper, policy
writer, installer, remover, XML payload, or game-file write action.

Do not add runtime behavior here until the Phase 0A capability contract and
state machine are reviewed.
