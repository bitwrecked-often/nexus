[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$managerPath = Join-Path $projectRoot 'Support_Files_Do_Not_Edit\HistoricalRandomStart_Tool_2026-08-21.ps1'
$batPath = Join-Path $projectRoot '7DTD_HistoricalRandomStart_2026-08-21.bat'
$manager = [System.IO.File]::ReadAllText($managerPath)
$bat = [System.IO.File]::ReadAllText($batPath)
$passed = 0

function Assert-True {
    param([bool] $Condition, [string] $Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:passed++
    Write-Output "PASS: $Name"
}

$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $managerPath,
    [ref]$tokens,
    [ref]$parseErrors
)
Assert-True ($parseErrors.Count -eq 0) 'manager parses without errors'
Assert-True ($manager.Contains("VERIFIED_ARTIFACTS_2026-08-27")) 'manager recognizes stamped verified-artifact boundary'
Assert-True ($manager.Contains("main_runtime")) 'manager selects main runtime payload only'
Assert-True ($manager.Contains("96AFCBD7D967B45C58F8B4A8728439909A30A66CBBC9F56269896E2444DF3FFD")) 'main runtime hash is pinned'
Assert-True ($manager.Contains("B6812606D072B0392DE7643C11EFF8B10C0B3253C24DF16ECDC0D3DD3A1BD355")) 'ModInfo hash is pinned'
Assert-True ($manager.Contains("326ffd03-1d6d-4efb-a7dc-79201537b1c3")) 'supported Assembly-CSharp MVID is pinned'
Assert-True ($manager.Contains('[System.Reflection.Assembly]::ReflectionOnlyLoadFrom')) 'QA install checks installed Assembly-CSharp metadata'
Assert-True ($manager.Contains('Game build mismatch.')) 'QA game mismatch fails closed'
Assert-True ($manager.Contains('Verified QA payload hash mismatch.')) 'QA payload mismatch fails closed'
Assert-True ($manager.Contains('Verified QA payload is incomplete.')) 'incomplete QA payload fails closed'
Assert-True ($manager.IndexOf('if (Test-Path -LiteralPath $verifiedArtifactsRoot', [System.StringComparison]::Ordinal) -lt $manager.IndexOf("Build-AlphaCoreRelease.ps1", [System.StringComparison]::Ordinal)) 'verified package path precedes DEV build fallback'
Assert-True ($manager.Contains('$payloadRoot = $verifiedPayloadRoot')) 'verified files feed established deployment manifest'
Assert-True ($manager.Contains("New-HrsDeploymentManifest")) 'existing deployment manifest remains authoritative'
Assert-True ($manager.Contains("Test-HrsDeploymentInventory")) 'existing bounded inventory verification remains authoritative'
Assert-True (-not $manager.Contains('DevProbe.dll')) 'manager does not stage DevProbe'
Assert-True (-not $manager.Contains('MarkerProbe.dll')) 'manager does not stage MarkerProbe'
Assert-True ($bat.Contains('HistoricalRandomStart_Tool_2026-08-21.ps1')) 'dated BAT routes to functional manager'
Assert-True ($bat.Contains('-ExecutionPolicy Bypass')) 'downloaded QA BAT uses process-only execution-policy bypass'

Write-Output "Portable QA manager static tests passed: $passed/$passed"
