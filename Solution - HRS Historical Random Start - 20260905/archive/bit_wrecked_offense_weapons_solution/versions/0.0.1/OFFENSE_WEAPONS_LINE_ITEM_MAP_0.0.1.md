# Offense Weapons 0.0.1 — Exact Line-Item Map

Status: First inventory slice complete — Electric branch
Scope: Current spear and shotgun Arc Lightning effects only
Implementation status: No GUI or weapon payload has been created in this lane

## Evidence position

* Baseline: nested `Data/Config` commit `a3fb144`.
* Current state: live working-tree `Data/Config/items.xml` and
  `Data/Config/buffs.xml`.
* Baseline check: none of the Arc Lightning effect groups or the three
  `buffArcLightning*` buffs exist in `a3fb144`.
* Gameplay status: Eric has validated this behavior in the current game.
* Configuration status: exact current XML shapes recorded below.

This map is an inventory for the future Offense Weapons GUI. It is not an
instruction to copy the live working-tree changes wholesale. Each row must be
rebuilt as a reversible modlet patch after the full target inventory is
reviewed.

## Shared electrical infrastructure

| Exact target | File | Current shape | Baseline | Required by |
|---|---|---|---|---|
| `buffArcLightningProcCooldown` | `buffs.xml` | Hidden replace-stack buff; applied to the attacker for `0.5` seconds | Absent | Every spear and shotgun row |
| `buffArcLightningSpearPin` | `buffs.xml` | Electrical, replace-stack buff; sets run/walk/crouch speed and jump strength to `0`; reduces non-player attacks per minute by `35%` | Absent | Spear rows |
| `buffArcLightningShotgunZap` | `buffs.xml` | Electrical effect-stack buff; 2-second duration, 1-second update, `-12` health change over time, electric particle attach/cleanup | Absent | Shotgun rows |
| `buffShocked` | `buffs.xml` | Existing game shock effect; current spear rows apply it for `3` seconds | Existing game dependency; not modified by this Arc Lightning inventory | Spear rows |

Every current electrical row uses these shared guards before applying its
behavior:

* The attacker does not already have `buffArcLightningProcCooldown`.
* The RandomRoll must meet the row’s fixed threshold.
* The target is not tagged `trader`.
* The target is alive.

The shared cooldown is important: it is one player-side gate across both weapon
families, not a separate cooldown per weapon row.

## Electric — Spears

### User-facing grouping

Heading: `Electric — Spears`

The final GUI may show individual named spear rows. It must not label the group
as a universal effect for every melee weapon.

| User row label | Exact item target | Proc | Direct target result | Shared dependency | Baseline shape | Current source |
|---|---|---:|---|---|---|---|
| Stone Spear — Arc Lightning | `meleeWpnSpearT0StoneSpear` | 20% | 3-second `buffShocked`; 2.5-second `buffArcLightningSpearPin` | 0.5-second shared cooldown | No Arc Lightning effect group | `items.xml`, item Arc Lightning group |
| Iron Spear — Arc Lightning | `meleeWpnSpearT1IronSpear` | 20% | 3-second `buffShocked`; 2.5-second `buffArcLightningSpearPin` | 0.5-second shared cooldown | No Arc Lightning effect group | `items.xml`, item Arc Lightning group |
| Steel Spear — Arc Lightning | `meleeWpnSpearT3SteelSpear` | 20% | 3-second `buffShocked`; 2.5-second `buffArcLightningSpearPin` | 0.5-second shared cooldown | No Arc Lightning effect group | `items.xml`, item Arc Lightning group |

### Exact common spear behavior

Each spear item currently contains an effect group named `Arc Lightning` that:

1. Requires no active `buffArcLightningProcCooldown` on the attacker.
2. Uses `RandomRoll` from `0,100`, `LTE`, value `20`.
3. Excludes trader targets and requires the target to be alive.
4. Applies `buffArcLightningProcCooldown` to self for `.5` seconds.
5. Applies `buffShocked` to the target for `3` seconds.
6. Applies `buffArcLightningSpearPin` to the target for `2.5` seconds.

The spear pin is not merely a visual effect. Its current buff sets movement and
jump values to zero and slows non-player attack rate. It is therefore an exact
behavioral dependency that must travel with any selected spear row.

### Existing systems deliberately left separate

Spear damage, power attack, penetration, bleeding, crafting, loot, books, and
perk behavior remain outside this line item unless later dependency tracing
shows a direct requirement. The Arc Lightning rows are attached to the weapon
entries; they are not currently gated by a new progression tree.

## Electric — Shotguns

### User-facing grouping

Heading: `Electric — Shotguns`

The four rows share the same behavior shape but use fixed tier-specific values.
They must remain separate in the line-item map and validator.

| User row label | Exact item target | Proc | Direct ragdoll | AOE range | AOE ragdoll | Zap result | Baseline shape |
|---|---|---:|---|---:|---|---|---|
| Pipe Shotgun — Arc Lightning | `gunShotgunT0PipeShotgun` | 1% | 0.75 sec, force 650 | 2.0 | 0.75 sec, force 500 | Direct and AOE targets receive 2-sec zap | No Arc Lightning effect group |
| Double Barrel — Arc Lightning | `gunShotgunT1DoubleBarrel` | 3% | 0.9 sec, force 800 | 2.4 | 0.9 sec, force 650 | Direct and AOE targets receive 2-sec zap | No Arc Lightning effect group |
| Pump Shotgun — Arc Lightning | `gunShotgunT2PumpShotgun` | 6% | 1.1 sec, force 950 | 2.8 | 1.1 sec, force 800 | Direct and AOE targets receive 2-sec zap | No Arc Lightning effect group |
| Auto Shotgun — Arc Lightning | `gunShotgunT3AutoShotgun` | 12% | 1.3 sec, force 1150 | 3.2 | 1.3 sec, force 950 | Direct and AOE targets receive 2-sec zap | No Arc Lightning effect group |

### Exact common shotgun behavior

Each shotgun item currently contains an effect group named `Arc Lightning` that:

1. Requires no active `buffArcLightningProcCooldown` on the attacker.
2. Uses its row-specific RandomRoll threshold.
3. Excludes trader targets and requires the direct target to be alive.
4. Applies `buffArcLightningProcCooldown` to self for `.5` seconds.
5. Applies `buffArcLightningShotgunZap` to the direct target for `2` seconds.
6. Applies the row-specific direct `Ragdoll` duration and force.
7. Applies `buffArcLightningShotgunZap` to `otherAOE` targets tagged
   `zombie,animal` within the row-specific range for `2` seconds.
8. Applies the row-specific AOE `Ragdoll` duration and force to those same
   nearby zombie/animal targets.

The zap buff supplies electrical damage-over-time and particle cleanup. The
weapon entries supply the proc, ragdoll, range, and target filtering. Neither
side is sufficient alone.

### Existing systems deliberately left separate

Normal shotgun damage, block damage, Boomstick bonuses, reload speed, rate of
fire, ammunition, crafting, loot, books, normal stun/cripple behavior, and
attachments remain outside this line item unless a later trace proves a direct
dependency.

## GUI translation rule for this slice

For `0.0.1`, the proposed future GUI representation is:

* Two effect headings: `Electric — Spears` and `Electric — Shotguns`.
* Seven exact target rows beneath them.
* Each row is independently on or off.
* Enabling a row applies its entire fixed validated value set.
* Disabling an installed row removes only that row’s owned Arc Lightning patch.
* No raw proc, duration, range, force, damage, or cooldown controls are shown.
* Selecting one row must not silently enable another row or every weapon in a
  family.

The shared buffs must be emitted only when one or more selected rows need them,
and must remain installed while any selected row still references them. Their
ownership/removal logic is therefore a later implementation requirement.

## Remaining work before GUI changes

* Add the exact current explosive line items.
* Add exact current burn/fire line items.
* Confirm whether any additional offense effects belong in the validated scope.
* Decide the mod’s public name after the full inventory is visible.
* Design the ownership map for shared buffs when rows are installed or removed
  independently.
* Create the weapon-specific modlet payload, validator targets, and GUI rows
  only after the line-item map is reviewed.
