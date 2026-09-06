[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$testRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $testRoot
$toolPath = Join-Path $projectRoot 'Support_Files_Do_Not_Edit\HistoricalRandomStart_Tool.ps1'

$script:passCount = 0
$script:failureCount = 0

function Assert-PreviewCondition {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-PreviewTestCase {
    param(
        [string]$Id,
        [scriptblock]$Test
    )

    try {
        & $Test
        $script:passCount++
        Write-Output "PASS $Id"
    }
    catch {
        $script:failureCount++
        Write-Output "FAIL $Id :: $($_.Exception.Message)"
    }
}

function Get-DialogSlice {
    param([int]$Start)

    if ($script:CapturedDialogs.Count -le $Start) {
        return @()
    }
    return @($script:CapturedDialogs | Select-Object -Skip $Start)
}

. $toolPath -PreviewWorkflowTestHost

try {
    $validRootA = 'C:\Preview Test Fixtures\Valid A'
    $validRootB = 'D:\Preview Test Fixtures\Valid B'
    $invalidRoot = 'E:\Preview Test Fixtures\Invalid'
    $script:ValidTestRootKeys = @(
        (Get-PreviewGameRootKey -GameRoot $validRootA),
        (Get-PreviewGameRootKey -GameRoot $validRootB)
    )
    $script:GameRootValidator = {
        param([string]$RootKey)
        return $script:ValidTestRootKeys -contains $RootKey
    }

    $script:CapturedDialogs = New-Object System.Collections.Generic.List[object]
    $script:DialogResponses = New-Object 'System.Collections.Generic.Queue[System.Windows.Forms.DialogResult]'
    $script:PreviewDialogHandler = {
        param($Text, $Caption, $Buttons, $Icon)

        [void]$script:CapturedDialogs.Add([pscustomobject]@{
            Text = [string]$Text
            Caption = [string]$Caption
            Buttons = $Buttons
            Icon = $Icon
        })
        if ($Buttons -eq [System.Windows.Forms.MessageBoxButtons]::YesNo) {
            if ($script:DialogResponses.Count -eq 0) {
                throw 'The deterministic confirmation response queue is empty.'
            }
            return $script:DialogResponses.Dequeue()
        }
        return [System.Windows.Forms.DialogResult]::OK
    }

    $activityLog.Clear()
    $script:AppliedPreviewSettings = $null
    $script:FolderValidationState = 'Required'
    $script:ValidatedGameRootKey = ''
    $pathBox.Text = $validRootA
    [void](Update-DesignState)
    $initialSnapshotWasNull = $null -eq $script:AppliedPreviewSettings

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-001-initial-valid-folder' -Test {
        $validated = Set-CurrentGameRootValidation -ShowDialog $false
        Assert-PreviewCondition -Condition $validated -Message 'The first deterministic root did not validate.'
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'NotApplied') -Message "Expected NotApplied, got $script:CurrentPreviewState."
        Assert-PreviewCondition -Condition $applyButton.Enabled -Message 'Apply was not enabled after current-folder validation.'
        Assert-PreviewCondition -Condition ($stateValue.Text -match 'not applied') -Message 'The main state did not say not applied.'
        Assert-PreviewCondition -Condition $initialSnapshotWasNull -Message 'A prior session snapshot appeared at startup.'
    }

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-002-first-apply-no' -Test {
        $dialogStart = $script:CapturedDialogs.Count
        $script:DialogResponses.Enqueue([System.Windows.Forms.DialogResult]::No)
        $result = Apply-PreviewSelection
        $dialogs = @(Get-DialogSlice -Start $dialogStart)

        Assert-PreviewCondition -Condition ($result -eq 'Canceled') -Message "Expected Canceled result, got $result."
        Assert-PreviewCondition -Condition ($null -eq $script:AppliedPreviewSettings) -Message 'Canceling the first Apply created a snapshot.'
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'NotApplied') -Message 'Canceling the first Apply changed the not-applied truth.'
        Assert-PreviewCondition -Condition ($stateValue.Text -match 'canceled' -and $stateValue.Text -match 'not applied') -Message 'The first-Apply cancel outcome was not visible.'
        Assert-PreviewCondition -Condition ($dialogs.Count -eq 1 -and $dialogs[0].Caption -eq 'Confirm Preview Settings') -Message 'Canceling the first Apply showed a success dialog or skipped confirmation.'
        Assert-PreviewCondition -Condition ($activityLog.Text -match 'apply canceled.*remain not applied') -Message 'The first-Apply cancellation was not logged accurately.'
    }

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-003-first-apply-yes' -Test {
        $dialogStart = $script:CapturedDialogs.Count
        $script:DialogResponses.Enqueue([System.Windows.Forms.DialogResult]::Yes)
        $result = Apply-PreviewSelection
        $dialogs = @(Get-DialogSlice -Start $dialogStart)

        Assert-PreviewCondition -Condition ($result -eq 'Applied') -Message "Expected Applied result, got $result."
        Assert-PreviewCondition -Condition ($null -ne $script:AppliedPreviewSettings) -Message 'The first confirmed snapshot was not recorded.'
        Assert-PreviewCondition -Condition ($script:AppliedPreviewSettings.StartType -eq 'Standard') -Message 'The first snapshot did not record Standard.'
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'Applied') -Message 'The first confirmed Apply did not render Applied.'
        Assert-PreviewCondition -Condition ($dialogs.Count -eq 2) -Message "Expected confirmation and success dialogs, got $($dialogs.Count)."
        Assert-PreviewCondition -Condition ($dialogs[0].Caption -eq 'Confirm Preview Settings') -Message 'The first dialog was not the confirmation.'
        Assert-PreviewCondition -Condition ($dialogs[0].Text -match '^Create preview-session snapshot\?' -and $dialogs[0].Text -match 'Not yet applied' -and $dialogs[0].Text -match 'Start: Standard' -and $dialogs[0].Text -match 'Game folder: checked' -and $dialogs[0].Text -match 'Random safeguards: inactive' -and $dialogs[0].Text -match 'Preview only - game files, saves, and runtime settings will not change') -Message 'The minimal first-Apply confirmation did not show its action, compact selection summary, and safety boundary.'
        Assert-PreviewCondition -Condition ($dialogs[1].Caption -eq 'Preview Settings Applied') -Message 'The success dialog was not shown after Yes.'
        Assert-PreviewCondition -Condition ($script:IsActivityLogExpanded -and -not $workspaceSplit.Panel2Collapsed) -Message 'Successful Apply did not expand the activity pane.'
        Assert-PreviewCondition -Condition ($activityLog.Text -match 'Applied session value: Start type = Standard' -and $activityLog.Text -match 'Applied session value: Starting biome only = Off' -and $activityLog.Text -match 'Applied session value: All dangerous biomes = Off') -Message 'The activity log did not record all first-Apply values.'
    }

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-004-each-setting-change-becomes-pending' -Test {
        $randomRadio.Checked = $true
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'Pending') -Message 'Changing Standard to Random did not produce Pending.'
        Assert-PreviewCondition -Condition ($script:AppliedPreviewSettings.StartType -eq 'Standard') -Message 'A live mode edit mutated the last applied snapshot.'
        Assert-PreviewCondition -Condition ($stateValue.Text -match 'Pending' -and $previewOnlyLabel.Text -match 'Pending') -Message 'Pending was not visible in both the main state and preview notice.'
        $standardRadio.Checked = $true
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'Applied') -Message 'Reverting the start type did not restore Applied.'

        $startingBiomeOnlyCheck.Checked = $true
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'Pending' -and $startingBiomeOnlyCheck.Checked) -Message 'Starting-biome-only did not independently produce Pending.'
        $startingBiomeOnlyCheck.Checked = $false
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'Applied') -Message 'Reverting starting-biome-only did not restore Applied.'

        $allDangerousBiomesCheck.Checked = $true
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'Pending' -and $allDangerousBiomesCheck.Checked) -Message 'All-dangerous-biomes did not independently produce Pending.'
        $allDangerousBiomesCheck.Checked = $false
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'Applied') -Message 'Reverting all-dangerous-biomes did not restore Applied.'

        $randomRadio.Checked = $true
        $startingBiomeOnlyCheck.Checked = $true
        $allDangerousBiomesCheck.Checked = $true
        Assert-PreviewCondition -Condition (-not $startingBiomeOnlyCheck.Checked -and $allDangerousBiomesCheck.Checked) -Message 'The safeguards were not mutually exclusive.'
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'Pending') -Message 'The final changed settings did not remain Pending.'
    }

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-005-no-cancel-preserves-pending-snapshot' -Test {
        Set-ActivityLogExpanded -Expanded $false
        $dialogStart = $script:CapturedDialogs.Count
        $script:DialogResponses.Enqueue([System.Windows.Forms.DialogResult]::No)
        $result = Apply-PreviewSelection
        $dialogs = @(Get-DialogSlice -Start $dialogStart)

        Assert-PreviewCondition -Condition ($result -eq 'Canceled') -Message "Expected Canceled result, got $result."
        Assert-PreviewCondition -Condition ($script:AppliedPreviewSettings.StartType -eq 'Standard' -and -not $script:AppliedPreviewSettings.AllDangerousBiomes) -Message 'No changed the applied snapshot.'
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'Pending') -Message 'No did not preserve the pending truth.'
        Assert-PreviewCondition -Condition ($stateValue.Text -match 'canceled' -and $stateValue.Text -match 'pending') -Message 'The visible cancel outcome did not retain pending truth.'
        Assert-PreviewCondition -Condition ($dialogs.Count -eq 1 -and $dialogs[0].Caption -eq 'Confirm Preview Settings') -Message 'Cancel showed a success dialog or skipped confirmation.'
        Assert-PreviewCondition -Condition (-not $script:IsActivityLogExpanded -and $workspaceSplit.Panel2Collapsed) -Message 'Cancel unexpectedly expanded the activity pane.'
        Assert-PreviewCondition -Condition ($activityLog.Text -match 'apply canceled.*remain pending') -Message 'The pending cancellation was not logged accurately.'
    }

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-006-reapply-changed-settings' -Test {
        $dialogStart = $script:CapturedDialogs.Count
        $script:DialogResponses.Enqueue([System.Windows.Forms.DialogResult]::Yes)
        $result = Apply-PreviewSelection
        $dialogs = @(Get-DialogSlice -Start $dialogStart)

        Assert-PreviewCondition -Condition ($result -eq 'Applied' -and $script:CurrentPreviewState -eq 'Applied') -Message 'Changed settings were not reapplied.'
        Assert-PreviewCondition -Condition ($script:AppliedPreviewSettings.StartType -eq 'Random' -and $script:AppliedPreviewSettings.AllDangerousBiomes -and -not $script:AppliedPreviewSettings.StartingBiomeOnly) -Message 'The changed snapshot did not replace the old values.'
        Assert-PreviewCondition -Condition ($dialogs[0].Text -match '^Apply pending preview changes\?' -and $dialogs[0].Text -match 'Pending changes:' -and $dialogs[0].Text -match 'Start type: Standard -> Random' -and $dialogs[0].Text -match 'All dangerous biomes: Off -> On' -and $dialogs[0].Text -match 'Game folder: checked') -Message 'The changed reapply confirmation omitted its compact pending summary or actual before/after values.'
        Assert-PreviewCondition -Condition ($script:IsActivityLogExpanded -and -not $workspaceSplit.Panel2Collapsed) -Message 'Changed reapply did not expand the activity pane.'
    }

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-007-unchanged-cancel-and-reapply' -Test {
        Set-ActivityLogExpanded -Expanded $false
        $cancelDialogStart = $script:CapturedDialogs.Count
        $script:DialogResponses.Enqueue([System.Windows.Forms.DialogResult]::No)
        $cancelResult = Apply-PreviewSelection
        $cancelDialogs = @(Get-DialogSlice -Start $cancelDialogStart)
        Assert-PreviewCondition -Condition ($cancelResult -eq 'Canceled' -and $script:CurrentPreviewState -eq 'Applied') -Message 'Canceling an unchanged Apply changed the Applied truth.'
        Assert-PreviewCondition -Condition ($stateValue.Text -match 'canceled' -and $stateValue.Text -match 'snapshot is unchanged') -Message 'The unchanged-Applied cancel outcome was not visible.'
        Assert-PreviewCondition -Condition ($cancelDialogs.Count -eq 1 -and -not $script:IsActivityLogExpanded) -Message 'Canceling an unchanged Apply showed success or expanded activity.'
        Assert-PreviewCondition -Condition ($activityLog.Text -match 'apply canceled.*applied session snapshot is unchanged') -Message 'The unchanged-Applied cancellation was not logged accurately.'

        $dialogStart = $script:CapturedDialogs.Count
        $script:DialogResponses.Enqueue([System.Windows.Forms.DialogResult]::Yes)
        $result = Apply-PreviewSelection
        $dialogs = @(Get-DialogSlice -Start $dialogStart)

        Assert-PreviewCondition -Condition ($result -eq 'Applied' -and $script:CurrentPreviewState -eq 'Applied') -Message 'Unchanged reapply did not remain Applied.'
        Assert-PreviewCondition -Condition ($dialogs[0].Text -match '^Refresh applied preview snapshot\?' -and $dialogs[0].Text -match 'No changes detected' -and $dialogs[0].Text -match 'Start: Random' -and $dialogs[0].Text -match 'Random safeguard: All dangerous biomes') -Message 'Unchanged reapply did not use the minimal refresh wording and current selection summary.'
        Assert-PreviewCondition -Condition ($activityLog.Text -match 'snapshot refreshed; no setting values changed') -Message 'Unchanged reapply refresh was not logged.'
    }

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-008-invalid-folder-blocks-apply' -Test {
        $folderChangeCountBefore = ([regex]::Matches($activityLog.Text, 'Game folder changed\.')).Count
        $pathBox.Text = $invalidRoot
        $pathBox.Text = "$invalidRoot typing"
        $pathBox.Text = $invalidRoot
        $folderChangeCountAfter = ([regex]::Matches($activityLog.Text, 'Game folder changed\.')).Count

        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'FolderCheckRequired' -and -not $applyButton.Enabled) -Message 'A direct invalid edit did not immediately require a folder check and disable Apply.'
        Assert-PreviewCondition -Condition ($null -ne $script:AppliedPreviewSettings -and $stateValue.Text -match 'stale') -Message 'The prior snapshot was not retained as visibly stale.'
        Assert-PreviewCondition -Condition (($folderChangeCountAfter - $folderChangeCountBefore) -eq 1) -Message 'Typing in the path field produced duplicate folder-change log entries.'
        Assert-PreviewCondition -Condition ($activityLog.Text -match 'last applied session snapshot is stale; click Check Game Folder before Apply') -Message 'The sanitized stale-folder transition was not logged.'

        $dialogStart = $script:CapturedDialogs.Count
        $blockedBeforeCheck = Apply-PreviewSelection
        Assert-PreviewCondition -Condition ($blockedBeforeCheck -eq 'BlockedFolderCheckRequired') -Message 'Direct Apply bypassed the required folder check.'
        Assert-PreviewCondition -Condition ((Get-DialogSlice -Start $dialogStart)[0].Buttons -eq [System.Windows.Forms.MessageBoxButtons]::OK) -Message 'Blocked Apply incorrectly opened a Yes/No confirmation.'

        $validated = Set-CurrentGameRootValidation -ShowDialog $false
        Assert-PreviewCondition -Condition (-not $validated -and $script:CurrentPreviewState -eq 'InvalidFolder' -and -not $applyButton.Enabled) -Message 'The invalid-folder check did not fail closed.'
        $blockedAfterCheck = Apply-PreviewSelection
        Assert-PreviewCondition -Condition ($blockedAfterCheck -eq 'BlockedInvalidFolder') -Message 'Apply did not remain blocked after invalid validation.'
        Assert-PreviewCondition -Condition ($script:AppliedPreviewSettings.GameRoot -eq $validRootA) -Message 'Invalid-folder attempts changed the last applied snapshot.'
    }

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-009-another-valid-folder-requires-check' -Test {
        $pathBox.Text = $validRootB
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'FolderCheckRequired' -and -not $applyButton.Enabled) -Message 'The second valid path bypassed explicit current-folder validation.'
        Assert-PreviewCondition -Condition ($stateValue.Text -match 'stale') -Message 'The second folder did not visibly stale the prior snapshot.'

        $validated = Set-CurrentGameRootValidation -ShowDialog $false
        Assert-PreviewCondition -Condition $validated -Message 'The second deterministic root did not validate.'
        Assert-PreviewCondition -Condition ($script:CurrentPreviewState -eq 'Pending' -and $applyButton.Enabled) -Message 'A checked second folder did not become a pending path-only change.'

        $dialogStart = $script:CapturedDialogs.Count
        $script:DialogResponses.Enqueue([System.Windows.Forms.DialogResult]::Yes)
        $result = Apply-PreviewSelection
        $dialogs = @(Get-DialogSlice -Start $dialogStart)
        Assert-PreviewCondition -Condition ($result -eq 'Applied' -and $script:AppliedPreviewSettings.GameRoot -eq $validRootB) -Message 'The checked second folder did not replace the session snapshot.'
        Assert-PreviewCondition -Condition ($dialogs[0].Text -match 'Game folder: changed since last Apply \(paths omitted\)') -Message 'The folder-only reapply confirmation did not identify the change.'
    }

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-010-activity-log-and-pane' -Test {
        $logText = $activityLog.Text
        Assert-PreviewCondition -Condition ($logText -match 'Current selections are pending' -and $logText -match 'apply canceled' -and $logText -match 'Game folder check failed' -and $logText -match 'Game folder check passed') -Message 'Required pending/cancel/folder activity entries were missing.'
        Assert-PreviewCondition -Condition ($logText.IndexOf($validRootA, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 -and $logText.IndexOf($validRootB, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 -and $logText.IndexOf($invalidRoot, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) -Message 'A raw test root leaked into the activity log.'
        Assert-PreviewCondition -Condition (-not $script:PersistentLogEnabled -and [string]::IsNullOrWhiteSpace($script:PersistentLogPath)) -Message 'Persistent activity saving did not remain opt-in and off.'
        Assert-PreviewCondition -Condition ($script:IsActivityLogExpanded -and -not $workspaceSplit.Panel2Collapsed) -Message 'The final successful Apply did not leave the activity pane expanded.'
    }

    Invoke-PreviewTestCase -Id 'PREVIEW-APPLY-011-session-only-initialization' -Test {
        Assert-PreviewCondition -Condition $initialSnapshotWasNull -Message 'The test host did not begin without an applied snapshot.'
        Assert-PreviewCondition -Condition ($script:AppliedPreviewSettings.GameRoot -eq $validRootB) -Message 'The confirmed snapshot was not confined to current in-memory state.'
        Assert-PreviewCondition -Condition (-not (Test-Path -LiteralPath $validRootA) -and -not (Test-Path -LiteralPath $validRootB)) -Message 'The test seam unexpectedly created a game-root fixture on disk.'
    }
}
finally {
    if ($null -ne $form -and -not $form.IsDisposed) {
        $form.Dispose()
    }
    if ($null -ne $script:LogoImageToDispose) {
        $script:LogoImageToDispose.Dispose()
        $script:LogoImageToDispose = $null
    }
}

Write-Output "PREVIEW_WORKFLOW_SUMMARY pass=$script:passCount fail=$script:failureCount"
if ($script:failureCount -gt 0) {
    exit 1
}

exit 0
