[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$managerPath = Join-Path $projectRoot 'ui\p0158.ps1'
$batPath = Join-Path (Split-Path -Parent $projectRoot) 'START.bat'
$verifiedDllPath = Join-Path $projectRoot 'verified\main\d0163.dll'
$verifiedModInfoPath = Join-Path $projectRoot 'verified\main\ModInfo.xml'
$manager = [System.IO.File]::ReadAllText($managerPath)
$bat = [System.IO.File]::ReadAllText($batPath)
$verifiedDllHash = (Get-FileHash -LiteralPath $verifiedDllPath -Algorithm SHA256).Hash
$verifiedModInfoHash = (Get-FileHash -LiteralPath $verifiedModInfoPath -Algorithm SHA256).Hash
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
Assert-True ($manager.Contains("'verified'")) 'manager recognizes verified-artifact boundary'
Assert-True ($manager.Contains("'main'")) 'manager selects main runtime payload only'
Assert-True ($manager.Contains($verifiedDllHash)) 'main runtime hash matches verified payload'
Assert-True ($manager.Contains($verifiedModInfoHash)) 'ModInfo hash matches verified payload'
Assert-True ($manager.Contains("229796d0-95ca-4662-b426-1a6f1f1596ed")) 'supported Assembly-CSharp MVID is pinned'
Assert-True ($manager.Contains('[System.Reflection.Assembly]::ReflectionOnlyLoadFrom')) 'QA install checks installed Assembly-CSharp metadata'
Assert-True ($manager.Contains('function Test-HrsGameRootCandidate') -and $manager.Contains('function Find-HrsGameRoots')) 'manager discovers the game root without a fixed parent count'
Assert-True ($manager.Contains("'7DaysToDie.exe'") -and $manager.Contains("'7DaysToDie_Data\Managed\Assembly-CSharp.dll'")) 'game-root discovery validates executable and managed assembly'
Assert-True ($manager.Contains('libraryfolders.vdf') -and $manager.Contains('Get-ItemProperty')) 'portable discovery checks Steam and registered library folders'
Assert-True ($manager.Contains('FolderBrowserDialog') -and $manager.Contains('Test-HrsGameRootCandidate -Path $selectedPath')) 'portable discovery provides a validated folder-picker fallback'
Assert-True (-not $manager.Contains('Split-Path -Parent (`r`n    Split-Path -Parent')) 'legacy fixed-parent game-root calculation is absent'
Assert-True ($manager.Contains('Game build mismatch.')) 'QA game mismatch fails closed'
Assert-True ($manager.Contains('Verified QA payload hash mismatch.')) 'QA payload mismatch fails closed'
Assert-True ($manager.Contains('Verified QA payload is incomplete.')) 'incomplete QA payload fails closed'
Assert-True ($manager.IndexOf('if (Test-Path -LiteralPath $verifiedArtifactsRoot', [System.StringComparison]::Ordinal) -lt $manager.IndexOf("p0143.ps1", [System.StringComparison]::Ordinal)) 'verified package path precedes DEV build fallback'
Assert-True ($manager.Contains('$payloadRoot = $verifiedPayloadRoot')) 'verified files feed established deployment manifest'
Assert-True ($manager.Contains("New-HrsDeploymentManifest")) 'existing deployment manifest remains authoritative'
Assert-True ($manager.Contains("Test-HrsDeploymentInventory")) 'existing bounded inventory verification remains authoritative'
Assert-True (-not $manager.Contains('DevProbe.dll')) 'manager does not stage DevProbe'
Assert-True (-not $manager.Contains('MarkerProbe.dll')) 'manager does not stage MarkerProbe'
Assert-True ($bat.Contains('p0158.ps1')) 'dated BAT routes to functional manager'
Assert-True ($bat.Contains('-ExecutionPolicy Bypass')) 'downloaded QA BAT uses process-only execution-policy bypass'
Assert-True ($bat.StartsWith("@echo off`n") -or $bat.StartsWith("@echo off`r`n")) 'BAT begins with an exact echo-off command and no corrupt prefix'

Write-Output "Portable QA manager static tests passed: $passed/$passed"
