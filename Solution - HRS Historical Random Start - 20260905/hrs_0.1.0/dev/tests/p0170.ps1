[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$corePath = Join-Path $projectRoot 'src\launcher\m0161.psm1'
$managementPath = Join-Path $projectRoot 'src\launcher\m0164.psm1'
Import-Module $managementPath -Force
Import-Module $corePath

$script:Pass = 0
$script:Fail = 0

function Invoke-HrsManagementCase {
    param(
        [Parameter(Mandatory = $true)] [string] $Id,
        [Parameter(Mandatory = $true)] [scriptblock] $Test
    )

    try {
        & $Test
        $script:Pass++
        Write-Output "PASS $Id"
    }
    catch {
        $script:Fail++
        Write-Output "FAIL $Id :: $($_.Exception.Message)"
        Write-Output "TRACE $Id :: $($_.ScriptStackTrace)"
    }
}

function Assert-HrsManagement {
    param(
        [Parameter(Mandatory = $true)] [bool] $Condition,
        [Parameter(Mandatory = $true)] [string] $Message
    )

    if (-not $Condition) { throw $Message }
}

$testParent = $projectRoot
$testRoot = Join-Path $testParent 't'
if (Test-Path -LiteralPath $testRoot) { throw 'The bounded management test root already exists.' }
$expectedPrefix = (Get-HrsManagerStatePaths -ManagerRoot $testRoot).ManagerRoot
[void][System.IO.Directory]::CreateDirectory((Join-Path $testRoot 'ui'))

try {
    $paths = Get-HrsManagerStatePaths -ManagerRoot $testRoot

    Invoke-HrsManagementCase -Id 'MGMT-001-read-empty-without-creating-state' -Test {
        $history = Read-HrsHistory -ManagerRoot $testRoot
        $index = Read-HrsRecoveryIndex -ManagerRoot $testRoot
        Assert-HrsManagement ($history.Entries.Count -eq 0 -and -not $history.TornFinalLine) 'Empty history was not safe.'
        Assert-HrsManagement ($index.attempts.Count -eq 0 -and $index.highestRevision -eq 0) 'Empty recovery index was not safe.'
        Assert-HrsManagement (-not [System.IO.Directory]::Exists($paths.StateRoot)) 'A read-only first view created management state.'
    }

    $failedAttempt = $null
    Invoke-HrsManagementCase -Id 'MGMT-002-failed-attempt-visible-without-snapshot-directory' -Test {
        $failedAttempt = Add-HrsRecoveryAttempt `
            -ManagerRoot $testRoot `
            -Outcome 'Failed' `
            -Reason 'SNAPSHOT_FAILED'
        $view = Get-HrsRecoveryView -ManagerRoot $testRoot
        $failedView = @($view.Items | Where-Object { $_.Id -ceq $failedAttempt.Attempt.correlationId })
        Assert-HrsManagement (-not [System.IO.Directory]::Exists($paths.SnapshotRoot)) 'A failed-only attempt created the snapshot directory.'
        Assert-HrsManagement ($view.Items.Count -eq 2 -and $view.Items[0].Id -ceq 'Default') 'Default plus the failed attempt were not both visible.'
        Assert-HrsManagement ($failedView.Count -eq 1 -and -not $failedView[0].Available -and $failedView[0].Reason -ceq 'SNAPSHOT_FAILED') 'The failed attempt did not remain visibly disabled.'
    }

    $successfulAttempts = New-Object System.Collections.Generic.List[object]
    Invoke-HrsManagementCase -Id 'MGMT-003-newest-five-known-good-attempts' -Test {
        for ($revision = 1; $revision -le 6; $revision++) {
            $mode = if (($revision % 2) -eq 0) { 'Standard' } else { 'Random' }
            $policy = New-HrsPolicy `
                -Revision ([UInt64]$revision) `
                -GameName "Management Test $revision" `
                -Mode $mode `
                -WrittenUtc ([datetime]"2026-08-21T12:00:0$revision`Z")
            $result = Add-HrsRecoveryAttempt `
                -ManagerRoot $testRoot `
                -Outcome 'Succeeded' `
                -Reason 'SNAPSHOT_CAPTURED' `
                -KnownGood `
                -Policy $policy `
                -CapturedUtc ([datetime]"2026-08-21T12:01:0$revision`Z")
            [void]$successfulAttempts.Add($result.Attempt)
        }
        $index = Read-HrsRecoveryIndex -ManagerRoot $testRoot
        $view = Get-HrsRecoveryView -ManagerRoot $testRoot
        $snapshotFiles = @(Get-ChildItem -LiteralPath $paths.SnapshotRoot -File -Filter 'snapshot-*.json')
        Assert-HrsManagement ($index.attempts.Count -eq 5 -and $index.highestRevision -eq 6) 'Recovery did not retain exactly the newest five attempts and highest revision.'
        Assert-HrsManagement ($index.attempts[0].correlationId -ceq $successfulAttempts[5].correlationId) 'Newest recovery attempt was not first.'
        Assert-HrsManagement (@($index.attempts | Where-Object { $_.correlationId -ceq $successfulAttempts[0].correlationId }).Count -eq 0) 'The sixth-oldest recovery target was retained.'
        Assert-HrsManagement ($view.Items.Count -eq 6 -and @($view.Items | Where-Object { $_.Available }).Count -eq 6) 'Default plus five revalidated targets were not available.'
        Assert-HrsManagement ($snapshotFiles.Count -eq 5) 'Dropped known-good snapshots were not bounded to five files.'
    }

    Invoke-HrsManagementCase -Id 'MGMT-004-complete-history-remains-correlated' -Test {
        $history = Read-HrsHistory -ManagerRoot $testRoot
        Assert-HrsManagement ($history.Entries.Count -eq 7 -and -not $history.TornFinalLine) 'Complete event history did not retain all seven attempts.'
        Assert-HrsManagement (@($history.Entries | Where-Object { $_.action -cne 'Snapshot' }).Count -eq 0) 'Recovery attempts did not use the Snapshot history action.'
        Assert-HrsManagement (@($history.Entries | Select-Object -ExpandProperty correlationId -Unique).Count -eq 7) 'Correlation IDs were not unique.'
        $historyText = [System.IO.File]::ReadAllText($paths.HistoryPath)
        Assert-HrsManagement ($historyText.IndexOf($testRoot, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) 'A private management path leaked into history.'
    }

    $restoreAttempt = $successfulAttempts[2]
    Invoke-HrsManagementCase -Id 'MGMT-005-diff-and-monotonic-restore-plan' -Test {
        $current = New-HrsPolicy `
            -Revision 10 `
            -GameName 'Current Management Game' `
            -Mode 'Standard' `
            -WrittenUtc ([datetime]'2026-08-21T13:00:00Z')
        $plan = Get-HrsRestorePlan `
            -ManagerRoot $testRoot `
            -AttemptId $restoreAttempt.correlationId `
            -CurrentPolicy $current
        Assert-HrsManagement ($plan.Valid -and -not $plan.NoWrite) 'A retained known-good snapshot did not produce a restore plan.'
        Assert-HrsManagement ($plan.Policy.revision -eq 11) 'Restored policy revision was not monotonic above current and historical revisions.'
        Assert-HrsManagement ($plan.Diff.Changed -and $plan.Diff.Changes.Count -eq 2) 'Simple diff did not show game and mode changes.'
    }

    Invoke-HrsManagementCase -Id 'MGMT-006-default-is-virtual-and-monotonic' -Test {
        $current = New-HrsPolicy `
            -Revision 20 `
            -GameName 'Default Recovery Game' `
            -Mode 'Random' `
            -WrittenUtc ([datetime]'2026-08-21T13:10:00Z')
        $plan = Get-HrsRestorePlan `
            -ManagerRoot $testRoot `
            -AttemptId 'Default' `
            -CurrentPolicy $current
        Assert-HrsManagement ($plan.Valid -and $plan.Policy.mode -ceq 'Standard' -and -not $plan.Policy.enabled) 'Default did not produce a Standard disabled policy.'
        Assert-HrsManagement ($plan.Policy.revision -eq 21) 'Default revision was not monotonic.'
        $alreadyDefault = Get-HrsRestorePlan -ManagerRoot $testRoot -AttemptId 'Default'
        Assert-HrsManagement ($alreadyDefault.Valid -and $alreadyDefault.NoWrite -and $alreadyDefault.Reason -ceq 'DEFAULT_ALREADY_ACTIVE') 'Default was not always available as a safe no-op.'
    }

    Invoke-HrsManagementCase -Id 'MGMT-007-tampered-snapshot-stays-visible-unavailable' -Test {
        $index = Read-HrsRecoveryIndex -ManagerRoot $testRoot
        $attempt = @($index.attempts | Where-Object { $_.correlationId -ceq $restoreAttempt.correlationId })[0]
        $snapshotPath = Join-Path $paths.SnapshotRoot "$($attempt.snapshotId).json"
        $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
        [System.IO.File]::WriteAllText($snapshotPath, '{"schema":"tampered"}', $utf8)
        $view = Get-HrsRecoveryView -ManagerRoot $testRoot
        $item = @($view.Items | Where-Object { $_.Id -ceq $restoreAttempt.correlationId })[0]
        $plan = Get-HrsRestorePlan -ManagerRoot $testRoot -AttemptId $restoreAttempt.correlationId
        Assert-HrsManagement (-not $item.Available -and $item.Reason -ceq 'SNAPSHOT_UNAVAILABLE') 'Tampered snapshot disappeared or remained enabled.'
        Assert-HrsManagement (-not $plan.Valid -and $plan.Reason -ceq 'SNAPSHOT_UNAVAILABLE') 'Restore did not immediately revalidate the tampered snapshot.'
    }

    Invoke-HrsManagementCase -Id 'MGMT-008-torn-final-history-line-is-reported-not-trusted' -Test {
        $bytes = (New-Object System.Text.UTF8Encoding($false, $true)).GetBytes('{"schema":')
        $stream = New-Object System.IO.FileStream($paths.HistoryPath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush() } finally { $stream.Dispose() }
        $history = Read-HrsHistory -ManagerRoot $testRoot
        Assert-HrsManagement ($history.Entries.Count -eq 7) 'The torn fragment displaced confirmed history.'
        Assert-HrsManagement ($history.TornFinalLine -and $history.Reason -ceq 'HISTORY_TORN_FINAL_LINE') 'The torn final line was not reported.'
    }
}
finally {
    if (Test-Path -LiteralPath $testRoot -PathType Container) {
        $resolved = (Resolve-Path -LiteralPath $testRoot).Path
        $safeParent = [System.IO.Path]::GetFullPath($testParent).TrimEnd('\') + '\'
        if (-not $resolved.StartsWith($safeParent, [System.StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals($resolved, $expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'Refusing unsafe management-test cleanup.'
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
    if ((Test-Path -LiteralPath $testParent -PathType Container) -and
        @(Get-ChildItem -LiteralPath $testParent -Force).Count -eq 0) {
        Remove-Item -LiteralPath $testParent -Force
    }
}

Write-Output "HRS_MANAGEMENT_SUMMARY pass=$script:Pass fail=$script:Fail"
if ($script:Fail -gt 0) { exit 1 }
exit 0
