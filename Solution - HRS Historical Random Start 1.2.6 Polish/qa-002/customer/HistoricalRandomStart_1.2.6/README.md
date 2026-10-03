# Historical Random Start 1.2.6

*A different beginning in 7 Days to Die. By Bit Wrecked.*

Historical Random Start is a 7 Days to Die mod that gives a new character a
random starting location in the active world. Let the biome surprise you,
choose one, or set your own weights. The normal opening journey continues
from there.

Target: **V3.3.0 b17, Windows, local single-player**. Maps: **Navezgane** or
**Random Gen, 8K or larger**. Keep **anti-cheat (EAC) disabled** and the game's
supplied `0_TFP_Harmony` mod.

## Get started

1. Extract the complete ZIP to a writable local folder outside OneDrive or
   other synced or linked folders. Keep every included folder together.
2. Close 7 Days to Die, keep Steam open, and run **`START.bat`** from the
   extracted folder. Select the game installation if asked.
3. Enter the **exact Game Name** you will use for your new save. This is the
   Game Name, rather than the generated world's name.
4. Choose **Standard** or **Random**. For Random, choose any biome, a specific
   biome, or custom weights. Starting-biome protection is optional.
5. Select **Apply Settings**, review the confirmation, then acknowledge
   **Settings Applied**. Select **Launch Game** and create a new game with that
   exact Game Name. Generate a new world or choose an existing supported world.

The manager saves recovery settings beside its files and checks that location
before changing game files. **Settings Applied** confirms that the installation
and settings have been saved and verified. Steam must be running and the game
closed before **Launch Game** becomes available. If you launch through Steam
instead, configure it to launch without EAC.

If you edit the name or settings, apply them again before launching.
**Last start** shows the latest recorded outcome; applying settings alone does
not mean a character has landed.

## Before leaving your first Random session

**Complete the opening tasks in the same session until the Journey to Settlement
trader marker appears.** You can visit the trader later.

Leaving before a trader is assigned may point the quest to Pine Forest when you
return, even if you landed in another biome. Your landing stays saved and will
not repeat. If you already left early, follow the trader marker you receive on
return. This known issue also applies if the session ends unexpectedly.
Standard starts use the game's normal route.

## Choose your beginning

| Setting | What it does |
| --- | --- |
| Standard | Keeps the usual starting location. |
| Any biome | Gives each eligible biome an equal chance. |
| Choose a biome | Tries a start in your selected biome. |
| Custom weights | Sets relative weights from 0 to 100. Zero excludes a biome; at least one weight must be positive. |
| Starting-biome protection | Covers recognized environmental hazards in the starting biome. Enemies, hazards in other biomes and unrecognized debuffs remain active. |

Custom-weight shares are a preview. The game excludes absent biomes and
normalizes the remaining weights. A selected biome or configured share does
not guarantee a safe landing.

Random starts use actual placed points of interest (POIs). HRS tries up to five
distinct instances in the selected biome, rolling back an unsafe attempt before
trying again. If no safe destination can be completed, it keeps the usual
start. The catalog has 80 selected entries represented by 79 distinct prefab
names; a world may contain fewer eligible placements.

The opening objective uses a real trader in the world, preferring one in the
landing biome. It may choose a trader in another biome when needed; it does not
promise a nearby trader or create or move one. If no usable trader exists
anywhere, HRS keeps the vanilla start. A cross-biome trader does not redraw your
starting biome. Normal trader jobs resume after the opening journey.

## Compatibility

The manager uses Windows PowerShell 5.1. Bundled pregens and custom maps are
outside this version's tested scope. HRS does not replace game DLLs.

Other game builds are best-effort: HRS attempts to use the required hooks and
leaves the usual start in place if they are incompatible. They need their own
compatibility testing. The manager still verifies its package and installed files.

## Upgrade or remove

A completed HRS start happens once. Reloading, normal respawns, or changing
settings will not give an already started character another random landing.

To upgrade, close the game and use the new manager's **Apply Settings**. From
1.2.4, it preserves Game Name, mode and protection, with Any biome as the default.
From 1.2.5, it also restores the saved selection and weights. Review the
confirmation before applying.

**Restore previous settings** recovers earlier settings from the manager's
local history. Keep the extracted folder together so that history remains available.
**Game details** shows the game folder and technical details of the last result.

To remove HRS, close the game and select **Uninstall Mod**. Saves and unrelated
files are preserved. If an ownership or file verification fails, keep the
diagnostic and do not replace files manually.
