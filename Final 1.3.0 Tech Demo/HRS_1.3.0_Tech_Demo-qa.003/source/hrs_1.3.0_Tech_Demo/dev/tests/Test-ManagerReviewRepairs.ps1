param([Parameter(Mandatory=$true)][string]$EvidenceRoot)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'src/launcher/m0161.psm1') -Force
$source=Join-Path (Split-Path -Parent $PSScriptRoot) 'ui/p0158.ps1'
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Manager parse failed'}
foreach($name in @('Test-HrsGameRootCandidate','Select-HrsGameRoot','Set-HrsOperationControls','Get-HrsCurrentOperationError','Get-HrsSettingsReadStamp','Get-HrsSettingsAssessment','Get-HrsCustomerErrorText','Update-HrsResultStatus','Update-HrsStatus')) {
    $fn=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
    if($fn.Count -ne 1){throw "Function not unique: $name"}
    . ([scriptblock]::Create($fn[0].Extent.Text))
}
$rows=New-Object 'Collections.Generic.List[object]'
function Assert-Review([bool]$Condition,[string]$Name) {
    if(!$Condition){throw "FAILED: $Name"}
    [void]$rows.Add([pscustomobject]@{name=$Name;status='Pass'})
}
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('hrs127-manager-review-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($fixture)
try {
    $valid=Join-Path $fixture 'game-a'; $second=Join-Path $fixture 'game-b'; $wrong=Join-Path $fixture 'Steam'
    foreach($path in @($valid,$second)) {
        [void][IO.Directory]::CreateDirectory((Join-Path $path '7DaysToDie_Data/Managed'))
        [IO.File]::WriteAllText((Join-Path $path '7DaysToDie.exe'),'inert fixture; never executed')
        [IO.File]::WriteAllText((Join-Path $path '7DaysToDie_Data/Managed/Assembly-CSharp.dll'),'existence fixture only')
    }
    [void][IO.Directory]::CreateDirectory($wrong)
    function Find-HrsGameRoots { param($StartPath) return $script:discovered }
    function Show-HrsGameRootPicker {
        param($Description,$SelectedPath)
        $script:pickerCalls++; $script:pickerDescription=$Description; $script:pickerSeed=$SelectedPath
        if(!$script:choices.Count){throw 'Picker requested unexpected extra choice'}
        return $script:choices.Dequeue()
    }
    function Show-HrsGameRootSelectionError { $script:pickerErrors++ }
    function Reset-Picker($Discovered,$Choices) {
        $script:discovered=@($Discovered); $script:pickerCalls=0; $script:pickerErrors=0
        $script:choices=New-Object 'Collections.Generic.Queue[object]'
        foreach($item in $Choices){$script:choices.Enqueue($item)}
    }
    Reset-Picker @($valid) @()
    Assert-Review ((Select-HrsGameRoot -StartPath $fixture) -ceq $valid -and $script:pickerCalls -eq 0) 'single-discovered-installation-bypasses-picker'
    Reset-Picker @() @(@{Result=[Windows.Forms.DialogResult]::OK;Path=$wrong},@{Result=[Windows.Forms.DialogResult]::OK;Path=$valid})
    Assert-Review ((Select-HrsGameRoot -StartPath $fixture) -ceq $valid -and $script:pickerCalls -eq 2 -and $script:pickerErrors -eq 1) 'invalid-folder-warning-then-valid-retry'
    Reset-Picker @() @(@{Result=[Windows.Forms.DialogResult]::Cancel;Path=''})
    Assert-Review ($null -eq (Select-HrsGameRoot -StartPath $fixture) -and $script:pickerErrors -eq 0) 'initial-cancel-is-clean'
    Reset-Picker @() @(@{Result=[Windows.Forms.DialogResult]::OK;Path=$wrong},@{Result=[Windows.Forms.DialogResult]::Cancel;Path=$wrong})
    Assert-Review ($null -eq (Select-HrsGameRoot -StartPath $fixture) -and $script:pickerCalls -eq 2 -and $script:pickerErrors -eq 1) 'cancel-after-invalid-selection-is-clean'
    Reset-Picker @($valid,$second) @(@{Result=[Windows.Forms.DialogResult]::OK;Path=$second})
    Assert-Review ((Select-HrsGameRoot -StartPath $fixture) -ceq $second -and $script:pickerSeed -ceq $valid -and $script:pickerDescription -match 'Multiple') 'multiple-installations-preserve-explicit-selection'
    $entry=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq '$gameRoot'},$true))
    $cancelGuard=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Extent.Text.StartsWith('if ([string]::IsNullOrWhiteSpace($gameRoot))')},$true))
    if($entry.Count -ne 1 -or $cancelGuard.Count -ne 1){throw 'Manager cancellation entry not unique'}
    $selectFunction=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Select-HrsGameRoot'},$true))[0].Extent.Text
    $child=@'
Add-Type -AssemblyName System.Windows.Forms
$managerRoot=$PSScriptRoot
function Find-HrsGameRoots { return @() }
function Show-HrsGameRootPicker { 'PICKER_CANCELED' | Write-Host; [pscustomobject]@{Result=[Windows.Forms.DialogResult]::Cancel;Path=''} }
'@ + "`r`n" + $selectFunction + "`r`n" + $entry[0].Extent.Text + "`r`n" + $cancelGuard[0].Extent.Text + "`r`nthrow 'Manager continued after Cancel'"
    $cancelScript=Join-Path $fixture 'cancel-entry.ps1'
    [IO.File]::WriteAllText($cancelScript,$child,(New-Object Text.UTF8Encoding($false)))
    $cancelOutput=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $cancelScript 2>&1
    $cancelExit=$LASTEXITCODE
    Assert-Review ($cancelExit -eq 0 -and ($cancelOutput | Out-String) -match 'PICKER_CANCELED') 'actual-manager-entry-exits-zero-after-cancel'

    # Native control state and real Update-HrsStatus/Launch callbacks. Read-only
    # dependencies are controlled; no Apply, uninstall or process start is allowed.
    foreach($name in @('applyButton','launchButton','uninstallButton','editWeights')) { Set-Variable -Name $name -Value (New-Object Windows.Forms.Button) }
    foreach($name in @('standardRadio','randomRadio')) { Set-Variable -Name $name -Value (New-Object Windows.Forms.RadioButton) }
    $gameNameBox=New-Object Windows.Forms.TextBox; $gameNameBox.Text='Review Fixture'
    $chosenCombo=New-Object Windows.Forms.ComboBox
    $biomeGroup=New-Object Windows.Forms.Panel; $biomeProtectCheck=New-Object Windows.Forms.CheckBox
    $status=New-Object Windows.Forms.Label; $details=New-Object Windows.Forms.Label
    $resultStatus=New-Object Windows.Forms.Label; $script:resultSummary=New-Object Windows.Forms.Label
    function Get-HrsCurrentResultState { param($GameRoot) [pscustomobject]@{State='Unconfigured';Result=$null;Policy=$null} }
    $script:nextAction=New-Object Windows.Forms.Label
    $script:helpLink=New-Object Windows.Forms.LinkLabel
    $script:managerInitialized=$true; $script:loadingSelection=$false; $script:managerOperation='Idle'
    $script:selectionMethod='Any'; $useDevCandidate=$true; $gameRoot=$valid
    $script:appliedManifest=[pscustomobject]@{fixture=$true}; $script:managerNotice=''
    $script:lastOperationDurationMs=$null; $script:launchBlockedUntilApply=$false
    $script:testSaved=[pscustomobject]@{schema='hrs-policy/v2';gameName='Review Fixture'}
    $script:testMatches=$true; $script:testInventoryValid=$true
    $script:testGame='Closed'; $script:testSteam='Running'
    function Get-HrsProcessState { [pscustomobject]@{Game=$script:testGame;Steam=$script:testSteam} }
    function Read-HrsConfiguredPolicy { param($GameRoot) if($script:testPolicyInvalid){throw 'POLICY_INVALID_FIXTURE'}; return $script:testSaved }
    function Test-HrsDeploymentInventory { param($GameRoot,$Manifest) [pscustomobject]@{Valid=$script:testInventoryValid;State='InstalledValid';Reason='FIXTURE_DRIFT'} }
    function Test-HrsFormMatchesPolicy { param($Policy) return $script:testMatches }
    function Test-HrsRemovalOwnership { param($GameRoot) [pscustomobject]@{Valid=$true;State='Owned'} }
    function Test-HrsExactGameName { param($GameName) [pscustomobject]@{Valid=$true} }
    function Get-HrsFormSelection { @{Selection='Any';Weights=@(0,0,0,0,0)} }
    function Render-HrsConfigurationState { }
    function Update-HrsTextWidths { }
    function Start-Process { throw 'Process start forbidden in this fixture' }
    function Test-HrsLaunchInstallation {
        param($GameRoot,$Manifest,$ProcessState)
        if($ProcessState.Game -cne 'Closed'){throw 'GAME_ALREADY_RUNNING'}
        if($ProcessState.Steam -cne 'Running'){throw 'STEAM_NOT_RUNNING'}
        throw 'Process start forbidden in this fixture'
    }
    function Show-ReviewModal { return [Windows.Forms.DialogResult]::OK }
    $launchAst=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.InvokeMemberExpressionAst] -and $node.Expression.Extent.Text -ceq '$launchButton' -and $node.Member.Extent.Text -ceq 'Add_Click'},$true))
    if($launchAst.Count -ne 1){throw 'Launch callback not unique'}
    $launchBody=$launchAst[0].Arguments[0].ScriptBlock.Extent.Text
    $launchBody=$launchBody.Substring(1,$launchBody.Length-2).Replace('[System.Windows.Forms.MessageBox]::Show(','Show-ReviewModal (')
    $launchCallback=[scriptblock]::Create($launchBody)
    $script:testSteam='Closed'
    . $launchCallback
    Assert-Review ($status.Text -ceq 'Open Steam, then try Launch Game again.' -and !$launchButton.Enabled) 'actual-launch-callback-records-active-steam-blocker'
    $originalDiagnostic=$script:managerError
    Update-HrsStatus -RefreshInstallation
    Assert-Review ($status.Text -ceq (Get-HrsCustomerErrorText $originalDiagnostic)) 'unchanged-steam-blocker-remains-main-status'
    $script:testSteam='Running'; Update-HrsStatus -RefreshInstallation
    Assert-Review ($launchButton.Enabled -and $status.Text -notmatch 'STEAM_NOT_RUNNING' -and $details.Text.Contains($originalDiagnostic) -and $script:managerError -ceq $originalDiagnostic) 'resolved-steam-blocker-clears-main-status-retains-diagnostic'
    $script:testPolicyInvalid=$true; Update-HrsStatus -RefreshInstallation
    Assert-Review (!$launchButton.Enabled -and $status.Text -match 'Saved settings could not be verified' -and $details.Text -match 'POLICY_INVALID_FIXTURE' -and $status.Text -notmatch 'STEAM_NOT_RUNNING' -and $details.Text.Contains($originalDiagnostic)) 'resolved-steam-blocker-does-not-mask-new-policy-validation-error'
    $script:testPolicyInvalid=$false
    $script:testSteam='Closed'; Update-HrsStatus -RefreshInstallation
    Assert-Review (!$launchButton.Enabled -and $status.Text -ceq (Get-HrsCustomerErrorText $originalDiagnostic)) 'same-blocker-recurring-is-reported-again'
    $script:testSteam='Running'; $script:testGame='Running'; Update-HrsStatus -RefreshInstallation
    Assert-Review (!$launchButton.Enabled -and $status.Text -match 'Close 7 Days to Die' -and $status.Text -notmatch 'STEAM_NOT_RUNNING') 'resolved-steam-blocker-does-not-hide-new-game-running-guard'
    $script:testGame='Closed'
    foreach($pair in @(@('GAME_ALREADY_RUNNING','Running','Closed'),@('GAME_STATE_UNCONFIRMED','Unknown','Closed'))) {
        $script:managerError='Launch blocked: '+$pair[0]; $script:managerErrorAction='Launch'; $script:testGame=$pair[1]
        Update-HrsStatus -RefreshInstallation
        Assert-Review ($status.Text -ceq (Get-HrsCustomerErrorText $script:managerError) -and !$launchButton.Enabled) ($pair[0]+'-remains-current')
        $script:testGame=$pair[2]; Update-HrsStatus -RefreshInstallation
        Assert-Review ($launchButton.Enabled -and !$status.Visible -and $details.Text.Contains($script:managerError)) ($pair[0]+'-resolved-diagnostic-retained')
    }
    $script:managerError='Launch blocked: STEAM_STATE_UNCONFIRMED'; $script:testSteam='Unknown'
    Update-HrsStatus -RefreshInstallation
    Assert-Review ($status.Text -ceq (Get-HrsCustomerErrorText $script:managerError) -and !$launchButton.Enabled) 'unknown-steam-state-remains-current'
    $script:testSteam='Running'; Update-HrsStatus -RefreshInstallation
    Assert-Review ($launchButton.Enabled -and !$status.Visible) 'unknown-steam-state-clears-after-positive-running-check'
    $script:managerError='Launch blocked: Changes not applied. Select Apply Settings before launching.'
    $script:testMatches=$false; Update-HrsStatus -RefreshInstallation
    Assert-Review ($status.Text -ceq (Get-HrsCustomerErrorText $script:managerError) -and !$launchButton.Enabled) 'dirty-settings-launch-blocker-remains-current'
    $script:testMatches=$true; Update-HrsStatus -RefreshInstallation
    Assert-Review ($launchButton.Enabled -and !$status.Visible) 'reverting-to-applied-settings-refreshes-main-status'
    $script:managerError='Settings blocked: Settings could not be applied. The HRS installation files were returned to their previous state.'
    $script:managerErrorAction='Apply'; $script:launchBlockedUntilApply=$true
    Update-HrsStatus -RefreshInstallation
    Assert-Review (!$launchButton.Enabled -and $status.Text -ceq (Get-HrsCustomerErrorText $script:managerError)) 'failed-apply-latch-and-diagnostic-preserved'
    $script:managerError='Launch blocked: Apply Settings successfully and acknowledge Settings Applied before launching.'
    $script:managerErrorAction='Launch'; Update-HrsStatus -RefreshInstallation
    Assert-Review (!$launchButton.Enabled -and $status.Text -ceq (Get-HrsCustomerErrorText $script:managerError)) 'acknowledgement-blocker-does-not-expire-early'
    $script:launchBlockedUntilApply=$false; Update-HrsStatus -RefreshInstallation
    Assert-Review ($launchButton.Enabled -and !$status.Visible) 'acknowledgement-blocker-resolves-after-latch-clears'
    $script:managerError='Launch blocked: Access denied starting executable.'; Update-HrsStatus -RefreshInstallation
    Assert-Review ($status.Text -ceq (Get-HrsCustomerErrorText $script:managerError)) 'unclassified-process-launch-error-is-not-erased'
    $script:managerError='Launch blocked: LAUNCH_INSTALLATION_INVALID: FIXTURE_DRIFT'
    $script:testInventoryValid=$false; Update-HrsStatus -RefreshInstallation
    Assert-Review (!$launchButton.Enabled -and $status.Text -ceq (Get-HrsCustomerErrorText $script:managerError)) 'installation-drift-remains-blocked'
    $script:testInventoryValid=$true; Update-HrsStatus -RefreshInstallation
    Assert-Review ($launchButton.Enabled -and !$status.Visible -and $details.Text.Contains($script:managerError)) 'restored-installation-clears-main-blocker-retains-diagnostic'
    if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $sourceHash){throw 'Manager source changed during fixtures'}
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($EvidenceRoot))
    [ordered]@{
        schema='hrs-manager-review-repairs/v1';status='Pass';completedUtc=[DateTime]::UtcNow.ToString('o')
        sourceSha256=$sourceHash;harnessSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
        powerShellVersion=$PSVersionTable.PSVersion.ToString();assertionCount=$rows.Count;assertions=$rows.ToArray()
        scope='Actual manager selection/status functions and Launch callback; native controls, captured dialogs, inert temp files and controlled read-only dependencies. No Apply, uninstall, game launch or customer QA.'
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $EvidenceRoot 'verification.json') -Encoding UTF8
    "PASS: $($rows.Count) manager review-repair assertions; $sourceHash"
} finally {
    # Only our verified literal temporary root is removed, in this shell.
    $resolved=[IO.Path]::GetFullPath($fixture)
    $parent=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    if(!$resolved.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolved) -notlike 'hrs127-manager-review-*'){throw 'Fixture cleanup target escaped temp root'}
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
