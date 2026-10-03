[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$CaseId,
    [ValidateSet('Standard','Random','RandomSafe','NotApplicable')][string]$Mode='NotApplicable',
    [string]$LaneRoot='', [string]$GameRoot='', [string]$LogPath='', [string]$RunRoot='',
    [string]$CandidateArchivePath='', [switch]$AllowDevelopmentGap
)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
if (-not $LaneRoot) { throw 'HRS_LANE_REQUIRED' }
if (-not $RunRoot) { $RunRoot=Join-Path (Split-Path -Parent $PSScriptRoot) 'qa_runs' }
$paths=Get-HrsQaLanePaths $LaneRoot
$release=Read-HrsQaJson $paths.ReleasePath
$contract=Read-HrsQaJson $paths.ContractPath
$cases=@($contract.requiredCases | Where-Object { $_.id -ceq $CaseId })
if ($cases.Count -ne 1) { throw 'HRS_QA_CASE_UNKNOWN' }
$validation=Test-HrsQaRelease $LaneRoot
if (-not $validation.readyForQa -and -not $AllowDevelopmentGap) { throw 'HRS_RELEASE_NOT_READY_FOR_QA' }
$releaseDigest=Get-HrsQaSha256 $paths.ReleasePath
$contractDigest=Get-HrsQaSha256 $paths.ContractPath
$candidateId=''
$archive=''
$archiveDigest=''
$workspaceRoot=''
if ($release.PSObject.Properties.Name -contains 'candidateId') { $candidateId=$release.candidateId }
if ($candidateId) {
    if (-not $CandidateArchivePath) { throw 'HRS_CANDIDATE_ARCHIVE_REQUIRED' }
    $archive=[IO.Path]::GetFullPath($CandidateArchivePath)
    $check=Test-HrsCandidateArchive $archive $candidateId $releaseDigest $contractDigest
    if (-not $check.valid) { throw ('HRS_CANDIDATE_ARCHIVE_INVALID: '+($check.errors -join ',')) }
    $archiveDigest=$check.archiveSha256
    if (-not (Test-Path -LiteralPath (Join-Path $paths.LaneRoot 'qa-workspace.json'))) { throw 'HRS_ISOLATED_WORKSPACE_REQUIRED: use New-HrsQaWorkspace.ps1' }
    $workspaceRoot=Split-Path -Parent $paths.LaneRoot
    [void](Assert-HrsWorkspace $workspaceRoot $archive)
}
$runId='hrsqa-'+[datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)
$runPath=[IO.Path]::Combine([IO.Path]::GetFullPath($RunRoot),$release.version,$runId)
if (Test-Path -LiteralPath $runPath) { throw 'HRS_QA_RUN_COLLISION' }
[void][IO.Directory]::CreateDirectory($runPath)
[IO.File]::Copy($paths.ReleasePath,(Join-Path $runPath 'release.json'),$false)
[IO.File]::Copy($paths.ContractPath,(Join-Path $runPath 'qa-contract.json'),$false)
[void][IO.Directory]::CreateDirectory((Join-Path $runPath 'dev/qa'))
[IO.File]::Copy($paths.ReleasePath,(Join-Path $runPath 'dev/qa/rel.json'),$false)
Write-HrsQaJson (Join-Path $runPath 'release-validation.json') $validation
Write-HrsQaJson (Join-Path $runPath 'package-inventory.json') (Get-HrsQaPackageInventory $LaneRoot)
Write-HrsQaJson (Join-Path $runPath 'environment.json') (Get-HrsQaEnvironment -LaneRoot $LaneRoot -GameRoot $GameRoot)
Write-HrsQaJson (Join-Path $runPath 'installed-before.json') (Get-HrsQaInstalledInventory -LaneRoot $LaneRoot -GameRoot $GameRoot)
$selectedLog=Get-HrsQaLatestLog -ExplicitPath $LogPath
$baseline=0
if ($selectedLog) { $baseline=@([IO.File]::ReadAllLines($selectedLog) | Where-Object { $_ -match '\[HRS\]' }).Count }
$historyPath=Join-Path (Split-Path -Parent $paths.ManagerPath) 'HistoricalRandomStart_State/history.v1.jsonl'
$historyBaseline=0
if (Test-Path -LiteralPath $historyPath) { $historyBaseline=[IO.File]::ReadAllLines($historyPath).Count }
$started=[datetime]::UtcNow.ToString('o')
$run=[pscustomobject][ordered]@{
    schema='hrs-qa-run/v1'; runId=$runId; releaseVersion=$release.version; releaseBuildId=$release.buildId
    candidateId=$candidateId; candidateArchiveSha256=$archiveDigest
    releaseRecordSha256=$releaseDigest; contractSha256=$contractDigest; caseId=$CaseId; mode=$Mode
    phase=$(if ($AllowDevelopmentGap) {'DEV'} else {'QA'}); startedUtc=$started; status='Started'
}
Write-HrsQaJson (Join-Path $runPath 'run.json') $run
$session=[pscustomobject][ordered]@{
    schema='hrs-qa-local-session/v1'; laneRoot=$paths.LaneRoot; gameRoot=$GameRoot
    logPath=$selectedLog; baselineHrsCount=$baseline; historyPath=$historyPath; historyBaseline=$historyBaseline
    startedUtc=$started; candidateArchivePath=$archive; candidateArchiveSha256=$archiveDigest; workspaceRoot=$workspaceRoot
}
Write-HrsQaJson (Join-Path $runPath 'session.local.json') $session
Write-Output "QA run started: $runId"
Write-Output "Case: $CaseId ($($cases[0].title))"
Write-Output "Evidence path: $runPath"
if (-not $validation.readyForQa) { Write-Warning 'DEV evidence; release-readiness errors remain.' }
