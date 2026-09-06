[CmdletBinding()]
param(
    [string] $LaneRoot = '',
    [string] $ReportPath = '',
    [switch] $NoFail
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
if ([string]::IsNullOrWhiteSpace($LaneRoot)) {
    $LaneRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'hrs_1.1.0'
}

$report = Test-HrsQaRelease -LaneRoot $LaneRoot
if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
    Write-HrsQaJson -Path $ReportPath -Value $report
}

foreach ($finding in $report.findings) {
    Write-Output ("{0}: {1}: {2}" -f $finding.severity.ToUpperInvariant(), $finding.code, $finding.message)
}
Write-Output ("Release {0} readiness: readyForQa={1}; errors={2}; warnings={3}" -f
    $report.version, $report.readyForQa, $report.errorCount, $report.warningCount)

if (-not $report.readyForQa -and -not $NoFail) { throw 'HRS_RELEASE_NOT_READY_FOR_QA' }
