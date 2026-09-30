# Trader-session notice prototype for the next HRS candidate

This folder contains only the two changed customer files. `p0158.ps1` is the native WinForms manager; `README.md` is its customer instructions. Both were copied from the frozen `1.2.5-qa.002` extracted package and changed only to display the accepted known-issue notice. The frozen customer ZIP and extracted QA package remain unchanged.

For the next DEV candidate, use these files as the starting point for `dev/ui/p0158.ps1` and the customer `README.md`, then rebuild the package, manifests, receipts, and QA identity. The note appears only for Random mode, including RandomSafe, and is repeated in the Apply Settings confirmation. It does not change biome selection, policy writing, installation, or launch behavior.

The source parses with Windows PowerShell 5.1. The real-manager `-SmokeTest` path passed against a temporary package copy without installing or launching the game, and the Random-mode notice was visually checked in the normal-size WinForms screenshot.
