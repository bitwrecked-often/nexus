[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'm0206.psm1') -Force

$gameRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$saveRoot = (Resolve-Path (Join-Path $env:APPDATA '7DaysToDie\Saves')).Path
$targetRelative = 'Navezgane\HRS_Phase1A_Test_001\'
$modsRoot = Join-Path $gameRoot 'Mods'
$managedRoot = Join-Path $gameRoot '7DaysToDie_Data\Managed'

$snapshot = [ordered]@{
    schemaVersion = 1
    privacy = 'aggregate-only-no-identity-no-coordinates'
    gameManaged = Get-Phase1ATreeDigest -Root $managedRoot
    foreignMods = Get-Phase1ATreeDigest -Root $modsRoot -ExcludedRelativePrefixes @(
        'mod_PHASE1A_DEV\',
        'mod_PHASE1A_RELOC_DEV\')
    foreignSaves = Get-Phase1ATreeDigest -Root $saveRoot -ExcludedRelativePrefixes @($targetRelative)
    target = Get-Phase1ATreeDigest -Root (Join-Path $saveRoot 'Navezgane\HRS_Phase1A_Test_001')
}

$snapshot | ConvertTo-Json -Depth 5
