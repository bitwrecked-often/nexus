# Nexus Upload Notes - No-Scripts Package

This package is the scanner-friendly Nexus upload variant.

Contents:
- XML-only 7 Days to Die modlet folder
- Readme, release notes, changelog, and license text
- No PowerShell scripts
- No batch files
- No DLLs
- No EXEs
- No installers

Recommended Nexus file:
`7DTD_WastelandAnimalPopulationTuning_Nexus_NoScripts.zip`

The earlier full package included optional Windows helper scripts and batch launchers. Those files are not required for the modlet itself and can trigger automated pre-publish malware heuristics even when the script content is benign.

For Nexus, publish the no-scripts archive as the main file. If helper tools are still desired, publish them separately only after manual review, or move that workflow to documentation instead of bundled executable scripts.
