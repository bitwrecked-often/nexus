[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $LaneRoot,
    [Parameter(Mandatory = $true)] [string] $Version,
    [Parameter(Mandatory = $true)] [string] $BuildId,
    [Parameter(Mandatory = $true)] [string] $SourceCommit,
    [string] $TemplateLaneRoot = '',
    [switch] $Force
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force

if ($Version -cnotmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-[a-z0-9.-]+)?$') { throw 'HRS_CYCLE_VERSION_INVALID' }
if ($BuildId -cnotmatch '^r[0-9]+$') { throw 'HRS_CYCLE_BUILD_ID_INVALID' }
if ($SourceCommit -cnotmatch '^[0-9a-f]{40}$') { throw 'HRS_CYCLE_COMMIT_INVALID' }
if ([string]::IsNullOrWhiteSpace($TemplateLaneRoot)) {
    $TemplateLaneRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'hrs_1.1.0'
}

$target = Get-HrsQaLanePaths -LaneRoot $LaneRoot
$template = Get-HrsQaLanePaths -LaneRoot $TemplateLaneRoot
if (([System.IO.File]::Exists($target.ReleasePath) -or [System.IO.File]::Exists($target.ContractPath)) -and -not $Force) {
    throw 'HRS_CYCLE_RECORD_EXISTS; use -Force only when intentionally regenerating DEV records'
}

$release = Read-HrsQaJson -Path $template.ReleasePath
$contract = Read-HrsQaJson -Path $template.ContractPath
$release.version = $Version
$release.buildId = $BuildId
$release.releaseDate = [datetime]::UtcNow.ToString('yyyy-MM-dd')
$release.sourceCommit = $SourceCommit
$release.laneStatus = 'development'
$release.runtimeLog.version = $Version
$release.runtimeLog.buildId = $BuildId

$dllPath = [System.IO.Path]::Combine($target.LaneRoot, 'dev', 'verified', 'main', 'd0163.dll')
$modInfoPath = [System.IO.Path]::Combine($target.LaneRoot, 'dev', 'verified', 'main', 'ModInfo.xml')
if (-not [System.IO.File]::Exists($dllPath) -or -not [System.IO.File]::Exists($modInfoPath)) {
    throw 'HRS_CYCLE_VERIFIED_PAYLOAD_MISSING'
}
[xml]$metadata = [System.IO.File]::ReadAllText($modInfoPath)
$versionNode = $metadata.SelectSingleNode('/xml/Version')
if ($null -eq $versionNode -or
    -not [string]::Equals([string]$versionNode.GetAttribute('value'), $Version, [System.StringComparison]::Ordinal)) {
    throw 'HRS_CYCLE_MODINFO_VERSION_MISMATCH'
}
$dllInfo = New-Object System.IO.FileInfo($dllPath)
$modInfo = New-Object System.IO.FileInfo($modInfoPath)
$assemblyName = [System.Reflection.AssemblyName]::GetAssemblyName($dllPath)
$release.artifacts = @(
    [pscustomobject][ordered]@{
        path = 'dev/verified/main/d0163.dll'
        bytes = [UInt64]$dllInfo.Length
        sha256 = Get-HrsQaSha256 -Path $dllPath
        assemblyName = [string]$assemblyName.Name
        assemblyVersion = $assemblyName.Version.ToString()
    },
    [pscustomobject][ordered]@{
        path = 'dev/verified/main/ModInfo.xml'
        bytes = [UInt64]$modInfo.Length
        sha256 = Get-HrsQaSha256 -Path $modInfoPath
    }
)

$contract.releaseVersion = $Version
foreach ($case in @($contract.requiredCases)) { $case.status = 'Pending' }
Write-HrsQaJson -Path $target.ReleasePath -Value $release
Write-HrsQaJson -Path $target.ContractPath -Value $contract

Write-Output "Initialized release evidence records for $Version at $($target.LaneRoot)"
Write-Output 'Run Test-HrsRelease.ps1 before creating a QA packet.'
