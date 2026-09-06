# HRS 1.2.0 UX and Installation Management Planner Packet

Status: active durable planning packet
Owner decision date: 2026-09-02

## Current known-good state

- User entry point:
  - START.bat
  - launches dev\ui\p0158.ps1
- Current UX supports:
  - exact New Game Name
  - Standard / Random
  - optional arrival-biome protection
  - Apply
  - Launch Game
- Current verified runtime promoted into:
  - dev\verified\main\d0163.dll
- Verified runtime SHA-256:
  - DA32165FA443C3FF17FA7902B851FF437F1892BBA395D22F39167291F0DF0507
- Verified ModInfo.xml SHA-256:
  - 81A59FCE042FECAEF13102458517A28385BFC18947219CFD289C672BFB6013E8
- Verified game Assembly-CSharp MVID:
  - 229796d0-95ca-4662-b426-1a6f1f1596ed
- p0158.ps1 hash pin was updated to the new verified runtime.
- p0158.ps1 parses cleanly after the edit.
- The real START.bat -> p0158.ps1 UX path launches successfully.
- Random policy was successfully applied through the real UX.
- Installed game inventory was verified as:
  - Valid = True
  - State = InstalledValid
  - Reason = DEPLOYMENT_INVENTORY_VALID

## Important packaging identity

The verified UX package currently uses ModInfo.xml version 1.2.0.

The primed-landing build output carried a ModInfo.xml version 1.1.0.
Do not replace the verified 1.2.0 ModInfo.xml with that older build-output copy unless separately approved.

## Known upgrade-path issue

Existing installed HRS users can retain an older runtime DLL.

Observed behavior:
- the UX sees an existing Bridge directory;
- Apply skips the install/deployment branch;
- the policy can update successfully;
- the older installed d0163.dll can remain in place.

This was observed on the development machine.

The stale installed runtime was manually replaced with the verified DA32165... DLL and then Test-HrsDeploymentInventory returned InstalledValid.

Do not treat an arbitrary mismatched DLL as safe to overwrite.

## Existing deployment capabilities

dev\src\launcher\m0162.psm1 already provides:

- New-HrsDeploymentManifest
- Test-HrsDeploymentManifest
- Test-HrsDeploymentInventory
- Invoke-HrsRemoveFromGame

It currently does not expose an owned update/replace operation.

Inventory can distinguish states including:

- NotInstalled
- InstalledValid
- Drift
- Conflict
- Incomplete

Destructive lifecycle behavior should remain fail-closed.

## UX design direction

HRS is now treated as a compact full application stack around the mod.

Borrow the interaction model from mature Windows administration tools and mod managers, but use gamer/Windows-user terminology.

### Main Play rail

Keep simple:

- New Game Name
- Standard / Random
- optional Random-only arrival protection
- Apply
- Launch Game

Do not overload Apply with uninstall semantics.

### Status rail

Future compact status should communicate plain-language state such as:

- Installed / Not Installed
- Ready / Needs Attention
- Installed Version
- Current Start Mode

Avoid exposing backend terms such as:

- bridge
- manifest
- payload
- runtime
- deployment

unless in an Advanced/Details surface.

### Manage Mod rail

Planned maintenance concepts:

- Check Installation
- Repair Installation
- Update Mod
- Uninstall Mod

These should be visually secondary to the Play rail.

Use Windows/gamer terminology.

Preferred destructive label:
- Uninstall Mod

Confirmation should make clear that saved games and game progress are not deleted.

## Update safety rule

Future Update Mod behavior must not blindly overwrite drift.

Preferred model:

1. Detect installed state.
2. Verify that installed files are recognized as HRS-owned and the transition is explicitly supported.
3. Confirm the update.
4. Replace only approved owned files.
5. Preserve policy/settings where appropriate.
6. Read back and validate the installation.
7. Fail closed on unknown files, unknown hashes, identity collision, or unsupported transition.

Until an owned update path exists, uninstall/reinstall is the safe upgrade path.

## Backend compatibility note

RandomSafe still exists in the backend policy contract.

The product-facing UX should continue to present exactly two primary start choices:

- Standard
- Random

Arrival protection may remain a Random-only checkbox rather than becoming a third primary mode.

## Current repository change boundary

Expected tracked changes from the 2026-09-02 wiring session:

- hrs_1.2.0\dev\ui\p0158.ps1
- hrs_1.2.0\dev\verified\main\d0163.dll

A temporary UX rollback copy was moved outside the repository.

## Deferred testing decision

The owner approved packaging the current primed-landing runtime with the remaining fresh live release QA deferred to a later revision.

Do not silently reinterpret deferred testing as completed evidence.

## Next work order

Customer usability and lifecycle management.

First implementation target:

- design and expose a clear Manage Mod rail;
- prefer existing backend removal behavior rather than inventing uninstall logic;
- then evaluate Check Installation / Repair / Update as separate bounded increments.

Do not perform broad launcher-module refactoring as part of the first UX increment.

## Decision rule

Before changing the system, answer:

1. What do we like about the proposal?
2. What do we not like or distrust?
3. What is the next smallest useful experiment?
4. What can source, logs, tests, inventory, or the game answer directly?
5. What does the resulting evidence prove and not prove?
6. What is the correct next work order?
