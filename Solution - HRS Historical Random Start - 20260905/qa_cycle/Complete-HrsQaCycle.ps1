[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [ValidateSet('Approve', 'Reject')] [string] $Decision,
    [string] $LaneRoot = '',
    [string] $RunRoot = '',
    [string] $ApproverRole = 'ReleaseOwner',
    [string] $Notes = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($LaneRoot)) {
    $LaneRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'hrs_1.1.0'
}
if ([string]::IsNullOrWhiteSpace($RunRoot)) {
    $RunRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'qa_runs'
}
if ($ApproverRole -cnotmatch '^[A-Za-z][A-Za-z0-9_-]{2,31}$') { throw 'HRS_QA_APPROVER_ROLE_INVALID' }
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force

$paths = Get-HrsQaLanePaths -LaneRoot $LaneRoot
$release = Read-HrsQaJson -Path $paths.ReleasePath
$contract = Read-HrsQaJson -Path $paths.ContractPath
$validation = Test-HrsQaRelease -LaneRoot $paths.LaneRoot
$releaseDigest = Get-HrsQaSha256 -Path $paths.ReleasePath
$versionRunRoot = [System.IO.Path]::Combine([System.IO.Path]::GetFullPath($RunRoot), [string]$release.version)
$coverage = New-Object System.Collections.Generic.List[object]

foreach ($case in @($contract.requiredCases)) {
    $candidates = New-Object System.Collections.Generic.List[object]
    if ([System.IO.Directory]::Exists($versionRunRoot)) {
        foreach ($directory in Get-ChildItem -LiteralPath $versionRunRoot -Directory) {
            $runPath = Join-Path $directory.FullName 'run.json'
            $resultPath = Join-Path $directory.FullName 'qa-result.json'
            $zipPath = $directory.FullName + '.zip'
            if (-not [System.IO.File]::Exists($runPath) -or -not [System.IO.File]::Exists($resultPath) -or
                -not [System.IO.File]::Exists($zipPath)) { continue }
            try {
                $run = Read-HrsQaJson -Path $runPath
                $result = Read-HrsQaJson -Path $resultPath
                if ([string]$run.caseId -cne [string]$case.id -or
                    [string]$run.releaseRecordSha256 -cne $releaseDigest -or
                    [string]$run.status -cne 'Completed' -or
                    [string]$result.declaredOutcome -cne 'Pass' -or
                    [string]$result.automatedEventAssessment -cne 'Consistent' -or
                    [string]$result.kind -ceq 'DEV') { continue }
                if ([string]$case.id -ceq 'HRS-QA-008' -and [string]$result.kind -cne 'Rollback') { continue }
                [void]$candidates.Add([pscustomobject][ordered]@{
                    completedUtc = [string]$result.completedUtc
                    runId = [string]$run.runId
                    kind = [string]$result.kind
                    zipName = [System.IO.Path]::GetFileName($zipPath)
                    zipSha256 = Get-HrsQaSha256 -Path $zipPath
                })
            }
            catch { }
        }
    }
    $selected = @($candidates | Sort-Object completedUtc -Descending | Select-Object -First 1)
    [void]$coverage.Add([pscustomobject][ordered]@{
        caseId = [string]$case.id
        title = [string]$case.title
        covered = ($selected.Count -eq 1)
        runId = $(if ($selected.Count -eq 1) { [string]$selected[0].runId } else { '' })
        evidenceZip = $(if ($selected.Count -eq 1) { [string]$selected[0].zipName } else { '' })
        evidenceZipSha256 = $(if ($selected.Count -eq 1) { [string]$selected[0].zipSha256 } else { '' })
    })
}

$missing = @($coverage | Where-Object { -not $_.covered } | ForEach-Object { [string]$_.caseId })
if ($Decision -eq 'Approve' -and (-not $validation.readyForQa -or $missing.Count -gt 0)) {
    throw "HRS_QA_APPROVAL_BLOCKED: readiness=$($validation.readyForQa); missing=$($missing -join ',')"
}

$decidedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$cycle = [pscustomobject][ordered]@{
    schema = 'hrs-qa-cycle-decision/v1'
    releaseVersion = [string]$release.version
    buildId = [string]$release.buildId
    releaseRecordSha256 = $releaseDigest
    decision = $Decision
    approverRole = $ApproverRole
    decidedUtc = $decidedUtc
    releaseReady = [bool]$validation.readyForQa
    missingCases = $missing
    coverage = $coverage.ToArray()
    notes = $Notes
}
if (-not [System.IO.Directory]::Exists($versionRunRoot)) { [void][System.IO.Directory]::CreateDirectory($versionRunRoot) }
$stamp = [datetime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$decisionPath = Join-Path $versionRunRoot ("cycle-$stamp.json")
Write-HrsQaJson -Path $decisionPath -Value $cycle

$markdownPath = [System.IO.Path]::ChangeExtension($decisionPath, '.md')
$lines = New-Object System.Collections.Generic.List[string]
[void]$lines.Add("# HRS $($release.version) QA cycle decision")
[void]$lines.Add('')
[void]$lines.Add("- Decision: $Decision")
[void]$lines.Add("- Build: $($release.buildId)")
[void]$lines.Add("- Release record SHA-256: $releaseDigest")
[void]$lines.Add("- Release gate ready: $($validation.readyForQa)")
[void]$lines.Add("- Decided: $decidedUtc")
[void]$lines.Add("- Approver role: $ApproverRole")
[void]$lines.Add('')
[void]$lines.Add('| Case | Covered | Evidence |')
[void]$lines.Add('| --- | --- | --- |')
foreach ($item in $coverage) {
    [void]$lines.Add("| $($item.caseId) | $($item.covered) | $($item.evidenceZip) |")
}
[void]$lines.Add('')
[void]$lines.Add('## Notes')
[void]$lines.Add('')
[void]$lines.Add($(if ([string]::IsNullOrWhiteSpace($Notes)) { 'No notes supplied.' } else { $Notes }))
[System.IO.File]::WriteAllText($markdownPath, ($lines -join "`n") + "`n", (New-Object System.Text.UTF8Encoding($false)))

Write-Output "QA cycle decision recorded: $decisionPath"
Write-Output "Decision: $Decision; missing cases: $(if ($missing.Count -eq 0) { 'none' } else { $missing -join ', ' })"
