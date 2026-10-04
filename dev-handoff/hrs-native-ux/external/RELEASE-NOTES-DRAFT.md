<!-- Draft for the returning UX candidate. Insert release version and actual tested build after qualification; publish only delivered, verified changes. -->
# Historical Random Start release notes

*A different beginning in 7 Days to Die. By Bit Wrecked.*

## Manager changes

- Compact header with the logo, title and release information together.
- Visible biome-selection choices and retained custom-weight statistics.
- Clear Changes not applied and Changes applied feedback beside Apply Settings.
- Consistent enabled, disabled, pressed and keyboard-focus treatment.
- Reachable Help for setup, biome choices and protection limits.
- Apply and Launch remain separate; verified writing completes before the Settings Applied acknowledgement.
- Manual Restore previous settings is removed from the manager. Uninstall remains the maintenance action, and failed writes retain automatic recovery behavior.
- Improved sizing and scrolling across the qualified Windows display profiles.

These changes preserve Standard, biome selection, starting-biome protection, one-time landing and the existing fallback/trader behavior. Settings Applied confirms installation and configuration; Last start reports a recorded game result.

## First-session trader known issue

**Do not log out until your first trader is assigned. Complete the opening tasks in the same session and wait for the Journey to Settlement trader marker.** You can visit the trader later.

Leaving earlier, including an unexpected session end, may point the quest to a Pine Forest trader when you return. Your landing remains saved and will not repeat. If you already left early, follow the trader marker you receive on return. Standard starts use the game's normal route.

The reminder does not repair that early-exit behavior. A valid trader fallback can also select another biome when a usable local trader is unavailable; a nearby or same-biome trader is not guaranteed.

## Compatibility and setup

Windows, PowerShell 5.1 and local single-player. Map scope: **Navezgane**; **Random Gen worlds of 8192 or larger**. Keep **EAC disabled** and the supplied **0_TFP_Harmony**. Bundled pregens and custom maps remain outside the tested scope.

The final release identification states the actually tested game build. Other builds remain best-effort and require separate qualification.

Extract the complete package to a writable local folder, close the game, open Steam and run **START.bat**. Use the exact Game Name for a new save, apply settings, acknowledge the verified result and launch. The README covers choices, troubleshooting, upgrading and removal.

This Tech Demo is a player tryout build. A completed landing remains saved across reloads and normal respawns; changing settings or uninstalling does not reset that character's start or quest.
