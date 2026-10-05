# Production manager, native controls and validated file readers in one isolated fixture.
# No installed game, Steam launch, Apply, removal or save mutation is performed.
param([Parameter(Mandatory=$true)][string]$EvidenceRoot)
$ErrorActionPreference='Stop'
$devRoot=Split-Path -Parent $PSScriptRoot
$source=Join-Path $devRoot 'ui/p0158.ps1'
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$root=Join-Path ([IO.Path]::GetTempPath()) ('hrs130-manager-return-'+[guid]::NewGuid().ToString('N'))
$stage=Join-Path $root 'stage'; $fixture=Join-Path $root 'game'; $evidence=[IO.Path]::GetFullPath($EvidenceRoot)
foreach($p in @($evidence,(Join-Path $stage 'dev/ui'),(Join-Path $stage 'dev/src/launcher'),(Join-Path $stage 'dev/verified/main'),(Join-Path $fixture '7DaysToDie_Data/Managed'),(Join-Path $fixture 'Saves/Sentinel'))) { [void][IO.Directory]::CreateDirectory($p) }
Copy-Item (Join-Path $devRoot 'src/launcher/*.psm1') (Join-Path $stage 'dev/src/launcher')
Copy-Item -LiteralPath (Join-Path $devRoot 'ui/logo.ico') -Destination (Join-Path $stage 'dev/ui/logo.ico')
Copy-Item (Join-Path $devRoot 'verified/main/*') (Join-Path $stage 'dev/verified/main')
[IO.File]::WriteAllText((Join-Path $fixture '7DaysToDie.exe'),'inert fixture, never executed')
[IO.File]::WriteAllText((Join-Path $fixture '7DaysToDie_Data/Managed/Assembly-CSharp.dll'),'existence fixture, not loaded')
[IO.File]::WriteAllText((Join-Path $fixture 'Saves/Sentinel/keep.txt'),'save preserved')
$text=[IO.File]::ReadAllText($source).Replace('$useDevCandidate = $true','$useDevCandidate = $false')
$modal='[void][Windows.Forms.MessageBox]::Show($form,$text,''Check settings'',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information)'
if($text.Split(@($modal),[StringSplitOptions]::None).Length -ne 2){throw 'Check popup anchor changed'}
$text=$text.Replace($modal,'$script:checkPopupText=$text; $script:checkPopupCount++')
$tail='(?s)if \(\$SmokeTest\) \{\r?\n    \$form\.Show\(\).*?\r?\n\}\r?\n\[void\]\$form\.ShowDialog\(\)\s*$'
if([regex]::Matches($text,$tail).Count -ne 1){throw 'Manager entry anchor changed'}
$driver=@'
$script:testGame='Closed'; $script:testSteam='Running'; $script:checkPopupCount=0
function Get-HrsProcessState { [pscustomobject]@{Game=$script:testGame;Steam=$script:testSteam;Reason='FIXTURE_PROCESS'} }
function Start-Process { throw 'Process start forbidden in this fixture' }
$script:checks=New-Object Collections.Generic.List[object]
function Assert-Return([bool]$Condition,[string]$Name) { if(!$Condition){throw "FAILED: $Name; popup=$script:checkPopupText; state=$script:managerConfigurationState; details=$($details.Text)"};[void]$script:checks.Add([pscustomobject]@{name=$Name;status='Pass'}); [IO.File]::AppendAllText((Join-Path $evidenceRoot 'progress.txt'),$Name+"`r`n") }
function Get-Footprint {
    $roots=@($gameRoot,(Join-Path $managerRoot 'HistoricalRandomStart_State'))
    return (@(foreach($r in $roots){if([IO.Directory]::Exists($r)){Get-ChildItem -LiteralPath $r -Recurse -File | Sort-Object FullName | ForEach-Object { $_.FullName+'|'+$_.Length+'|'+(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }}}) -join ';')
}
function Check-ReadOnly([string]$Name,[string]$Expected) {
    $before=Get-Footprint; $draft=@($gameNameBox.Text,$randomRadio.Checked,$standardRadio.Checked,$biomeProtectCheck.Checked,(Get-HrsFormSelection).Selection,$chosenCombo.SelectedItem,(@($biomes|ForEach-Object{$weights[$_]}) -join ',')) -join '|'
    Invoke-HrsCheckSettings
    $afterDraft=@($gameNameBox.Text,$randomRadio.Checked,$standardRadio.Checked,$biomeProtectCheck.Checked,(Get-HrsFormSelection).Selection,$chosenCombo.SelectedItem,(@($biomes|ForEach-Object{$weights[$_]}) -join ',')) -join '|'
    Assert-Return ($script:checkPopupText -match $Expected) ($Name+'-message')
    Assert-Return ((Get-Footprint) -ceq $before -and $draft -ceq $afterDraft) ($Name+'-preserves-all-bytes-and-draft')
}
try {
$form.Show(); [Windows.Forms.Application]::DoEvents()
Assert-Return ($gameRoot -ceq $expectedFixtureRoot) 'isolated-game-root-enforced'
Assert-Return ($biomeProtectCheck.Checked -and $standardRadio.Checked) 'fresh-standard-remembers-default-on'
Assert-Return ($version.Text -ceq 'Tech Demo | 1.3.0') 'front-tech-demo-identity'
Assert-Return ($gameLabel.Text -ceq 'Game Name' -and $script:checkSettingsButton.TabIndex -eq 1 -and [bool]$script:checkSettingsButton.AccessibleDescription) 'name-and-check-accessibility'
$gameNameBox.Text='Future Save'; $randomRadio.Checked=$true
Check-ReadOnly 'no-save-no-policy' 'No settings are saved'
Assert-Return (![IO.Directory]::Exists((Join-Path $gameRoot 'Saves/Future Save'))) 'check-does-not-create-save'
$paths=Get-HrsBridgePaths -GameRoot $gameRoot
[void][IO.Directory]::CreateDirectory($paths.BridgeRoot)
Copy-Item (Join-Path $verifiedPayloadRoot '*') $paths.ReleaseRoot
$p=New-HrsPolicy -Revision ([UInt64]1) -GameName 'Future Save' -Mode RandomSafe
[void](Write-HrsPolicyFile -Path $paths.PolicyPath -AllowedRoot $paths.BridgeRoot -Policy $p)
Check-ReadOnly 'verified-matching-before-save' 'Saved settings and verified mod files match'
Assert-Return ($script:managerConfigurationState -ceq 'Applied' -and $launchButton.Enabled) 'matching-full-options-and-installation-applied'
$script:testSteam='Closed'; Check-ReadOnly 'steam-closed-disk-check' 'verified mod files match'
Assert-Return ($script:managerConfigurationState -ceq 'Applied' -and !$launchButton.Enabled) 'steam-requirement-separate-from-saved-settings'
$script:testSteam='Running'; $script:testGame='Running'; Check-ReadOnly 'game-running-disk-check' 'Files currently on disk only'
Assert-Return (!$applyButton.Enabled -and !$launchButton.Enabled) 'game-running-operation-guards-preserved'
$script:testGame='Closed'; $gameNameBox.Text='Other Name'; Check-ReadOnly 'another-name' "Saved settings target 'Future Save', not 'Other Name'"
Assert-Return ($script:managerConfigurationState -ceq 'Pending' -and !$launchButton.Enabled) 'name-match-required'
$gameNameBox.Text='Future Save'; $biomeProtectCheck.Checked=$false; Check-ReadOnly 'same-name-different-options' 'different options'
$biomeProtectCheck.Checked=$true; Set-HrsSelectionMethod Chosen; $chosenCombo.SelectedItem='Forest'
Assert-Return (!$biomeProtectCheck.Visible -and $biomeProtectCheck.Checked -and (Get-HrsFormSelection).ChosenBiome -eq 3) 'forest-hides-without-clearing-intent'
Set-HrsSelectionMethod Weighted; Assert-Return ($biomeProtectCheck.Visible -and $biomeProtectCheck.Checked -and !$chosenCombo.Visible -and $editWeights.Visible) 'weighted-retains-protection-and-hides-inactive-choice'
$biomeProtectCheck.Checked=$false; $standardRadio.Checked=$true; $randomRadio.Checked=$true; Set-HrsSelectionMethod Chosen; $chosenCombo.SelectedItem='Forest'; Set-HrsSelectionMethod Any
Assert-Return (!$biomeProtectCheck.Checked -and $biomeProtectCheck.Visible) 'challenge-opt-out-survives-hidden-transitions'
foreach($mode in @('Standard','RandomSafe','Random')) {
    $restore=New-HrsPolicy -Revision ([UInt64]2) -GameName 'Restored intent' -Mode $mode
    Set-HrsFormFromPolicy $restore
    Assert-Return ($biomeProtectCheck.Checked -eq ($mode -cne 'Random')) ('restored-'+$mode+'-preference')
}
Set-HrsFormFromPolicy $p
$dll=Join-Path $paths.ReleaseRoot 'd0163.dll'; $dllBytes=[IO.File]::ReadAllBytes($dll)
[IO.File]::WriteAllText($dll,'changed fixture')
Check-ReadOnly 'drifted-installation' 'installed mod files are not verified'
Assert-Return (!$launchButton.Enabled -and $details.Text -match 'DEPLOYMENT_STATIC_FILE_DRIFT' -and $script:nextAction.Text -notmatch 'DEPLOYMENT_') 'raw-drift-only-in-details'
[IO.File]::WriteAllBytes($dll,$dllBytes)
$foreign=Join-Path $paths.ReleaseRoot 'unknown.txt'; [IO.File]::WriteAllText($foreign,'unknown fixture, preserve')
Check-ReadOnly 'conflicting-installation' 'Cannot verify installed mod files'
Assert-Return ($script:checkPopupText -notmatch 'Use Apply Settings' -and !$launchButton.Enabled) 'conflict-keeps-support-guidance-and-launch-guard'
[IO.File]::Delete($foreign)
$packageDll=Join-Path $verifiedPayloadRoot 'd0163.dll'; $packageBytes=[IO.File]::ReadAllBytes($packageDll)
[IO.File]::WriteAllText($packageDll,'broken package fixture'); [IO.File]::Delete($paths.PolicyPath)
Check-ReadOnly 'missing-policy-broken-package' 'Redownload and extract the complete mod package'
Assert-Return ($script:checkPopupText -notmatch 'Use Apply Settings') 'broken-package-needs-redownload-before-apply'
[IO.File]::WriteAllBytes($packageDll,$packageBytes)
[void](Write-HrsPolicyFile -Path $paths.PolicyPath -AllowedRoot $paths.BridgeRoot -Policy $p)
$script:inventoryReader=(Get-Command Test-HrsDeploymentInventory -Module m0162).ScriptBlock
$script:injectMembershipChange=$true
function Test-HrsDeploymentInventory {
    param($GameRoot,$Manifest)
    $inventory=& $script:inventoryReader -GameRoot $GameRoot -Manifest $Manifest
    if ($script:injectMembershipChange) { [IO.File]::WriteAllText((Join-Path (Get-HrsBridgePaths $GameRoot).ReleaseRoot 'race-added.txt'),'membership changed after inventory') }
    return $inventory
}
Invoke-HrsCheckSettings
Assert-Return ($script:checkPopupText -match 'Cannot verify') 'concurrent-membership-change-rejected'
Assert-Return (!$launchButton.Enabled -and $details.Text -match 'SETTINGS_CHANGED_DURING_CHECK') 'concurrent-membership-change-closes-verification'
$script:injectMembershipChange=$false
[IO.File]::Delete((Join-Path $paths.ReleaseRoot 'race-added.txt'))
$result=New-HrsResult -PolicyRevision $p.revision -PolicyDigest $p.policyDigest -Outcome COMPLETED -Reason RELOCATION_COMPLETED -MarkerState COMPLETED
[void](Write-HrsAtomicUtf8File -Path $paths.ResultPath -AllowedRoot $paths.BridgeRoot -Text (ConvertTo-HrsResultJson $result))
Update-HrsStatus
Assert-Return ($script:resultSummary.Text -match "Last recorded start for 'Future Save'" -and $resultStatus.Text -match 'COMPLETED') 'result-attributed-to-applied-policy'
$gameNameBox.Text='Edited Name'
Assert-Return ($script:resultSummary.Text -match "Previous applied settings for 'Future Save'" -and $script:resultSummary.Text -notmatch 'Edited Name') 'edit-does-not-reattribute-old-outcome'
$gameNameBox.Text='Future Save'; [IO.File]::WriteAllText($dll,'drift again'); Update-HrsStatus
Assert-Return ($script:resultSummary.Text -match 'Previous applied settings') 'matching-draft-unverified-installation-is-previous-evidence'
[IO.File]::WriteAllBytes($dll,$dllBytes)
$newPolicy=New-HrsPolicy -Revision ([UInt64]2) -GameName 'Future Save' -Mode RandomSafe
[void](Write-HrsPolicyFile -Path $paths.PolicyPath -AllowedRoot $paths.BridgeRoot -Policy $newPolicy); Update-HrsStatus
Assert-Return ($script:resultSummary.Text -match 'earlier applied settings' -and $script:resultSummary.Text -notmatch 'Future Save') 'stale-result-does-not-guess-old-name'
[IO.File]::Delete($paths.ResultPath)
[IO.File]::WriteAllText($paths.PolicyPath,'invalid policy')
Check-ReadOnly 'invalid-policy' 'Cannot verify'
Assert-Return (!$applyButton.Enabled -and !$launchButton.Enabled -and $details.Text -match 'POLICY_') 'invalid-policy-guard-and-diagnostic'
[IO.File]::Delete($paths.PolicyPath)
$legacy=& (Get-Module m0161) { New-HrsLegacyPolicy -Revision ([UInt64]3) -GameName 'Legacy Save' -Mode Random }
$legacyText=& (Get-Module m0161) { param($Policy) ConvertTo-HrsLegacyPolicyJson -Policy $Policy } $legacy
[IO.File]::WriteAllText($paths.LegacyPolicyPath,$legacyText,(New-Object Text.UTF8Encoding($false)))
Check-ReadOnly 'legacy-policy' "Earlier settings target 'Legacy Save'"
Assert-Return (!$launchButton.Enabled -and [IO.File]::Exists($paths.LegacyPolicyPath) -and ![IO.File]::Exists($paths.PolicyPath)) 'check-does-not-migrate-legacy-policy'
[IO.File]::Delete($paths.LegacyPolicyPath)
[void](Write-HrsPolicyFile -Path $paths.PolicyPath -AllowedRoot $paths.BridgeRoot -Policy $newPolicy)
$script:launchBlockedUntilApply=$true; Check-ReadOnly 'failed-apply-latch' 'Launch remains blocked'
Assert-Return (!$launchButton.Enabled -and $script:launchBlockedUntilApply -and $script:applyBadge.Text -ceq 'Changes not applied.') 'check-cannot-clear-failed-apply-latch'
foreach($operation in @('Applying','Uninstalling','AwaitingAcknowledgement')) {
    $script:managerOperation=$operation; Update-HrsStatus; $beforeCount=$script:checkPopupCount; $before=Get-Footprint
    Invoke-HrsCheckSettings
    Assert-Return (!$script:checkSettingsButton.Enabled -and $script:checkPopupCount -eq $beforeCount -and (Get-Footprint) -ceq $before -and $script:launchBlockedUntilApply) ('check-guard-'+$operation)
}
$script:managerOperation='Idle'; $script:launchBlockedUntilApply=$false; $gameNameBox.Text='CON'; Check-ReadOnly 'invalid-input' 'valid save name'
$gameNameBox.Text='Future Save'
$baseBounds=$form.Bounds
for($i=0;$i -lt 6;$i++) { foreach($method in @('Any','Chosen','Weighted')) { Set-HrsSelectionMethod $method; [Windows.Forms.Application]::DoEvents(); Assert-Return ($form.Size -eq $baseBounds.Size) ('method-'+$i+'-'+$method+'-preserves-outer-size') } }
$width=$form.Width
for($i=0;$i -lt 3;$i++){Show-WeightEditor -TestAction Cancel; Assert-Return ($form.Width -eq $width) ('editor-return-'+$i+'-preserves-width')}
Set-HrsSelectionMethod Any
Update-HrsStatus
Assert-Return ($script:nextAction.Text -notmatch 'Apply Settings to use this start' -and !$script:managerStatePanel.Visible) 'ordinary-pending-has-no-redundant-row'
Assert-Return ((Get-HrsCustomerErrorText 'Settings blocked: UNRECOGNIZED_INTERNAL_REASON') -notmatch 'UNRECOGNIZED_INTERNAL_REASON') 'prefixed-raw-error-never-leaks-to-main-copy'
Assert-Return ((Get-HrsCustomerErrorText 'Use a valid save name without reserved names or characters.') -ceq 'Use a valid save name without reserved names or characters.') 'plain-input-guidance-preserved'
function Save-ReturnCapture([string]$Name) { $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height);try{$form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)));$bitmap.Save((Join-Path $evidenceRoot $Name),[Drawing.Imaging.ImageFormat]::Png)}finally{$bitmap.Dispose()} }
$form.ActiveControl=$null; $form.AutoScrollPosition=[Drawing.Point]::Empty; [Windows.Forms.Application]::DoEvents(); Save-ReturnCapture 'manager-top.png'
$form.ScrollControlIntoView($script:detailsToggle); [Windows.Forms.Application]::DoEvents(); Save-ReturnCapture 'manager-bottom.png'
$normalBounds=$form.Bounds; $form.Size=$form.MinimumSize; $script:managerUserResized=$true; [Windows.Forms.Application]::DoEvents()
$minimumBounds=$form.Bounds
foreach($method in @('Any','Chosen','Weighted','Any')) { Set-HrsSelectionMethod $method; [Windows.Forms.Application]::DoEvents(); Assert-Return ($form.Size -eq $minimumBounds.Size) ('minimum-'+$method+'-preserves-user-size') }
$form.ActiveControl=$null; $form.AutoScrollPosition=[Drawing.Point]::Empty; [Windows.Forms.Application]::DoEvents(); Save-ReturnCapture 'minimum-top.png'
$form.ScrollControlIntoView($script:detailsToggle); [Windows.Forms.Application]::DoEvents(); Save-ReturnCapture 'minimum-bottom.png'
$linkBounds=$form.RectangleToClient($script:detailsToggle.RectangleToScreen($script:detailsToggle.ClientRectangle))
Assert-Return ($linkBounds.Left -ge 0 -and $linkBounds.Right -le $form.ClientRectangle.Right -and $linkBounds.Top -ge 0 -and $linkBounds.Bottom -le $form.ClientRectangle.Bottom) 'minimum-last-link-reachable-by-scroll'
$form.ScrollControlIntoView($script:checkSettingsButton); [Windows.Forms.Application]::DoEvents()
$checkBounds=$form.RectangleToClient($script:checkSettingsButton.RectangleToScreen($script:checkSettingsButton.ClientRectangle))
Assert-Return ($checkBounds.Left -ge 0 -and $checkBounds.Right -le $form.ClientRectangle.Right -and $checkBounds.Top -ge 0 -and $checkBounds.Bottom -le $form.ClientRectangle.Bottom) 'minimum-check-settings-reachable-by-scroll'
$form.Bounds=$normalBounds; $script:managerUserResized=$false; $form.ActiveControl=$null; $form.AutoScrollPosition=[Drawing.Point]::Empty; [Windows.Forms.Application]::DoEvents(); Save-ReturnCapture 'manager-return.png'
$script:checks.ToArray() | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $evidenceRoot 'assertions.json') -Encoding UTF8
[ordered]@{status='Pass';assertionCount=$script:checks.Count;scope='Production native manager in isolated fixture; actual current host display only. No gameplay, actual OS-scale matrix, Narrator, High Contrast or newcomer qualification.';outer=@{width=$form.Width;height=$form.Height};contentHeight=$script:managerFrame.Height;workArea=@{width=([Windows.Forms.Screen]::FromControl($form).WorkingArea.Width);height=([Windows.Forms.Screen]::FromControl($form).WorkingArea.Height)};checkBounds=@{left=$script:checkSettingsButton.Left;top=$script:checkSettingsButton.Top;width=$script:checkSettingsButton.Width;height=$script:checkSettingsButton.Height}} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $evidenceRoot 'geometry.json') -Encoding UTF8
'PASS manager QA return assertions: '+$script:checks.Count
} finally { $form.Dispose() }
'@
$driver='$evidenceRoot='+"'"+$evidence.Replace("'","''")+"'`r`n"+'$expectedFixtureRoot='+"'"+$fixture.Replace("'","''")+"'`r`n"+$driver
$text=[regex]::Replace($text,$tail,[Text.RegularExpressions.MatchEvaluator]{param($m)$driver})
$staged=Join-Path $stage 'dev/ui/p0158.ps1'; [IO.File]::WriteAllText($staged,$text,(New-Object Text.UTF8Encoding($false)))
$savedPreference=$ErrorActionPreference
try { $ErrorActionPreference='Continue'; $output=& powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File $staged -SmokeTest -GameRootOverride $fixture 2>&1; $code=$LASTEXITCODE }
finally { $ErrorActionPreference=$savedPreference }
$output | Set-Content -LiteralPath (Join-Path $evidence 'output.txt') -Encoding UTF8
if($code -ne 0){throw "Manager QA-return fixture failed: $($output | Out-String)"}
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $sourceHash){throw 'Source changed during QA-return fixture'}
$assertions=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $evidence 'assertions.json')))
[ordered]@{schema='hrs-manager-qa-return-dev/v1';status='Pass';completedUtc=[DateTime]::UtcNow.ToString('o');sourceSha256=$sourceHash;harnessSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash;assertionCount=@($assertions).Count;fixtureRoot=$root;independentQa='Pending'} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $evidence 'verification.json') -Encoding UTF8
$output
