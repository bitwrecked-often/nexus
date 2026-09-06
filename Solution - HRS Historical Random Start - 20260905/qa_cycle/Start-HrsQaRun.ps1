[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $CaseId,
    [ValidateSet('Standard', 'Random', 'RandomSafe', 'NotApplicable')] [string] $Mode = 'NotApplicable',
    [string] $LaneRoot = '',
    [string] $GameRoot = '',
    [string] $LogPath = '',
    [string] $RunRoot = '',
    [switch] $AllowDevelopmentGap
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
if ([string]::IsNullOrWhiteSpace($LaneRoot)) {
    $LaneRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'hrs_1.1.0'
}
if ([string]::IsNullOrWhiteSpace($RunRoot)) {
    $RunRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'qa_runs'
}

$lanePaths = Get-HrsQaLanePaths -LaneRoot $LaneRoot
$release = Read-HrsQaJson -Path $lanePaths.ReleasePath
$contract = Read-HrsQaJson -Path $lanePaths.ContractPath
$cases = @($contract.requiredCases | Where-Object { [string]$_.id -ceq $CaseId })
if ($cases.Count -ne 1) { throw 'HRS_QA_CASE_UNKNOWN' }

$validation = Test-HrsQaRelease -LaneRoot $lanePaths.LaneRoot
if (-not $validation.readyForQa -and -not $AllowDevelopmentGap) {
    throw 'HRS_RELEASE_NOT_READY_FOR_QA; use -AllowDevelopmentGap only for DEV evidence'
}

$runId = 'hrsqa-' + [datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$root = [System.IO.Path]::GetFullPath($RunRoot)
$runPath = [System.IO.Path]::Combine($root, [string]$release.version, $runId)
if ([System.IO.Directory]::Exists($runPath)) { throw 'HRS_QA_RUN_COLLISION' }
[void][System.IO.Directory]::CreateDirectory($runPath)

[System.IO.File]::Copy($lanePaths.ReleasePath, (Join-Path $runPath 'release.json'), $false)
[System.IO.File]::Copy($lanePaths.ContractPath, (Join-Path $runPath 'qa-contract.json'), $false)
Write-HrsQaJson -Path (Join-Path $runPath 'release-validation.json') -Value $validation
Write-HrsQaJson -Path (Join-Path $runPath 'package-inventory.json') -Value (Get-HrsQaPackageInventory -LaneRoot $lanePaths.LaneRoot)
Write-HrsQaJson -Path (Join-Path $runPath 'environment.json') -Value (Get-HrsQaEnvironment -LaneRoot $lanePaths.LaneRoot -GameRoot $GameRoot)
Write-HrsQaJson -Path (Join-Path $runPath 'installed-before.json') -Value (Get-HrsQaInstalledInventory -LaneRoot $lanePaths.LaneRoot -GameRoot $GameRoot)

$selectedLog = Get-HrsQaLatestLog -ExplicitPath $LogPath
$baselineHrsCount = 0
if (-not [string]::IsNullOrWhiteSpace($selectedLog)) {
    $baselineHrsCount = @([System.IO.File]::ReadAllLines($selectedLog) | Where-Object { $_ -match '\[HRS\]' }).Count
}
$historyPath = [System.IO.Path]::Combine($lanePaths.LaneRoot, 'dev', 'ui', 'HistoricalRandomStart_State', 'history.v1.jsonl')
$historyBaseline = $(if ([System.IO.File]::Exists($historyPath)) { [System.IO.File]::ReadAllLines($historyPath).Count } else { 0 })
$startedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

$publicRun = [pscustomobject][ordered]@{
    schema = 'hrs-qa-run/v1'
    runId = $runId
    releaseVersion = [string]$release.version
    releaseBuildId = [string]$release.buildId
    releaseRecordSha256 = Get-HrsQaSha256 -Path $lanePaths.ReleasePath
    caseId = $CaseId
    mode = $Mode
    phase = $(if ($AllowDevelopmentGap) { 'DEV' } else { 'QA' })
    startedUtc = $startedUtc
    status = 'Started'
}
Write-HrsQaJson -Path (Join-Path $runPath 'run.json') -Value $publicRun

$localSession = [pscustomobject][ordered]@{
    schema = 'hrs-qa-local-session/v1'
    laneRoot = $lanePaths.LaneRoot
    gameRoot = $GameRoot
    logPath = $selectedLog
    baselineHrsCount = $baselineHrsCount
    historyPath = $historyPath
    historyBaseline = $historyBaseline
    startedUtc = $startedUtc
}
Write-HrsQaJson -Path (Join-Path $runPath 'session.local.json') -Value $localSession

Write-Output "QA run started: $runId"
Write-Output "Case: $CaseId ($($cases[0].title))"
Write-Output "Evidence path: $runPath"
if (-not $validation.readyForQa) {
    Write-Warning 'This is a DEV evidence run because release-readiness errors remain.'
}
