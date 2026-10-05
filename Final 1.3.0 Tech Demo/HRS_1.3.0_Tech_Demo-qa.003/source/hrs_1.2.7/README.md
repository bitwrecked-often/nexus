# New Player Random Start for 7 Days to Die

*By Bit Wrecked. Version 1.2.7.*

7 Days to Die v3.3.0 · Random Player Start

Start your new 7 Days to Die character in a random location. Choose a biome, let the mod pick, or set your own weights. Standard keeps the usual start.

## Requirements

- Windows, Windows PowerShell 5.1 and local single-player.
- **Navezgane**; for **Random Gen**, use worlds of **8192 or larger**.
- **Anti-cheat (EAC) disabled**, with the game's supplied **0_TFP_Harmony** retained.

Target: **7 Days to Die V3.3.0 b17**. Other builds are best-effort and need their
own compatibility checks. Bundled pregens and custom maps are outside the tested
scope. HRS does not replace game DLLs.

## Get started

1. Extract the complete ZIP to a writable local folder outside OneDrive or other synced or linked folders. Keep all included files and folders together.
2. Close 7 Days to Die, open Steam and run **START.bat** from the extracted package. Select the game installation if asked.
3. Enter the save's exact **Game Name**, distinct from the generated world's name. A supported existing world can be used; random placement happens on a fresh character's first spawn.
4. Choose Standard or Random. For Random, select Any biome, Choose a biome or Custom weights. Starting-biome protection is optional.
5. Select **Apply Settings**, review the settings and confirm. Wait for **Settings Applied**, then acknowledge it.
6. Select **Launch Game** and open or create the game with that exact Game Name. An already-played character stays in place when loaded. Keep EAC disabled if you launch through Steam instead.

**Help** opens local setup guidance and explains the choices without an internet connection. **Game details** shows the game folder and technical information about recorded results.

Changes applied means the installation and selected settings have been verified. Launch also requires Steam running and the game closed. If Steam was closed during Apply, open it and return to the manager; unchanged verified settings do not need to be applied again merely because Steam was closed.

If you edit the name or settings, apply them again before launching. Last start reports the latest recorded game outcome; applying settings alone does not mean a character has landed.

## Before leaving your first Random session

**Do not log out until your first trader is assigned. Complete the opening tasks in the same session and wait for the Journey to Settlement trader marker.** You can visit the trader later.

Leaving earlier, including an unexpected session end, may point the quest to a Pine Forest trader when you return. Your landing remains saved and will not repeat. If you already left early, follow the trader marker you receive on return. Standard starts use the game's normal route.

## Choose your beginning

| Setting | Meaning |
| --- | --- |
| Standard | Keeps the usual starting location |
| Any biome | Gives each eligible biome an equal chance |
| Choose a biome | Tries a start in the selected biome |
| Custom weights | Relative values from 0 to 100; zero excludes a biome and at least one weight must be positive |
| Starting-biome protection | Covers recognized environmental hazards in the starting biome; enemies, hazards elsewhere and unrecognized debuffs remain active |

Displayed custom-weight shares are previews. The game excludes ineligible biomes and normalizes the remaining weights. World availability and placement safety can affect the outcome. Random selection can choose the same biome on consecutive fresh starts.

Random starts use placed points of interest in the world. HRS tries safe placements in the selected biome. If no safe destination can be completed, it keeps the usual start.

The opening objective uses a real trader, preferring one in the landing biome. It may choose another biome when needed and does not guarantee a nearby trader. HRS does not create or move traders. If no usable trader exists anywhere, it keeps the usual start. A valid cross-biome trader selection does not redraw the starting biome.

## Upgrade and remove

Previously named Historical Random Start, this mod keeps its existing HRS installation and save compatibility.

A completed HRS landing happens once. Reloading, normal respawns and changing settings do not give an already started character another random landing.

To upgrade, close the game and use the new package's manager. From 1.2.4 it retains Game Name, mode and protection, defaulting to Any biome; from 1.2.5 or later it also loads the saved selection and weights. Review those settings, then select Apply Settings. Keep the complete extracted folder together so settings and diagnostics remain available.

To remove HRS, close the game and select **Uninstall Mod**. It removes verified HRS-owned files for later launches while preserving saves, player progress and unrelated files. It does not reverse a landing or quest already saved in the game.

## If setup is blocked

| Situation | Next action |
| --- | --- |
| Launch is unavailable because Steam is closed | Open Steam and return to the manager |
| Settings were edited after Apply | Review and apply the current settings |
| The game is running | Close it before applying settings or uninstalling |
| All weights are zero | Give at least one biome a positive weight |
| The package folder is unwritable | Extract the complete ZIP to a writable local folder |
| Apply or file verification fails | Read the reported outcome and keep the diagnostic |

If a write fails after changes begin, HRS attempts automatic recovery. If recovery or file ownership cannot be verified, keep the backup and diagnostic for support. Do not clear the Mods folder or replace game DLLs to resolve an HRS verification message. Other game builds may be untested; an untested-build warning does not by itself establish an incompatibility.
