# Real production callbacks in disposable fixture installations. Captured modal decisions/process
# providers and an inert executable isolate writes from the installed game. Fixture assembly pins
# apply only to the staged manager. These checks do not qualify gameplay, OS DPI or Narrator.
param(
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [ValidateSet('DevDispatch','Verified')][string]$Branch='DevDispatch',
    [switch]$FailureProbe,
    [ValidateSet('BeforeDllCopy','AfterDllCopy','AfterModInfoCopy','DuringPolicyReadback','AfterPolicyWrite','AfterLegacyDelete')][string]$FailurePoint='AfterDllCopy',
    [switch]$RecoveryFail,
    [switch]$LaunchProbe,
    [switch]$Upgrade,
    [switch]$MigrationMatrix,
    [switch]$ResultProbe,
    [switch]$UninstallProbe,
    [switch]$ApplyRejectProbe,
    [switch]$StorageProbe,
    [switch]$StartupProbe,
    [string]$StartupSavedPolicyPath='',
    [switch]$SelectionProbe,
    [switch]$EditorProbe,
    [switch]$SteamRefreshProbe,
    [switch]$UxStateProbe,
    [switch]$Round2Probe
)

$ErrorActionPreference='Stop'
$devRoot=Split-Path -Parent $PSScriptRoot
$repoRoot=Split-Path -Parent (Split-Path -Parent $devRoot)
$managerSource=Join-Path $devRoot 'ui/p0158.ps1'
$payloadSource=Join-Path $devRoot 'verified/main'
$oldPayloadSource=Join-Path $repoRoot 'hrs_1.2.4/dev/verified/main'
$gameAssembly='C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die\7DaysToDie_Data\Managed\Assembly-CSharp.dll'
$tempRoot=Join-Path ([IO.Path]::GetTempPath()) ('hrs127-callback-'+[guid]::NewGuid().ToString('N'))
$evidence=[IO.Path]::GetFullPath($EvidenceRoot)
[void][IO.Directory]::CreateDirectory($evidence)
[void][IO.Directory]::CreateDirectory($tempRoot)
$records=New-Object System.Collections.Generic.List[object]

if(([int][bool]$FailureProbe+[int][bool]$LaunchProbe+[int][bool]$Upgrade+[int][bool]$MigrationMatrix+[int][bool]$ResultProbe+[int][bool]$UninstallProbe+[int][bool]$ApplyRejectProbe+[int][bool]$StorageProbe+[int][bool]$StartupProbe+[int][bool]$SelectionProbe+[int][bool]$EditorProbe+[int][bool]$SteamRefreshProbe+[int][bool]$UxStateProbe+[int][bool]$Round2Probe) -gt 1){throw 'Select one probe'}
if($RecoveryFail -and (-not $FailureProbe -or $FailurePoint -ne 'AfterDllCopy')){throw 'RecoveryFail requires AfterDllCopy FailureProbe'}
if($StartupSavedPolicyPath -and -not $StartupProbe){throw 'StartupSavedPolicyPath requires StartupProbe'}
$scenarios=if($FailureProbe){@('UpgradeFailure')}elseif($LaunchProbe){@('Launch','TamperDll','TamperModInfo','TamperDigest','LegacyPolicy','MissingPolicy','WrongSchema','MalformedPolicy','AmbiguousPolicy','StaleResult','GameRunning','SteamClosed','ProcessUnknown')}elseif($Upgrade){@('Upgrade')}elseif($MigrationMatrix){@('MigrateStandard','MigrateRandom','MigrateRandomSafe')}elseif($ResultProbe){@('ResultCurrentThenStale')}elseif($UninstallProbe){@('UninstallOwned','UninstallV1','UninstallCancel','UninstallUnknown','UninstallRunning','UninstallProcessUnknown')}elseif($ApplyRejectProbe){@('InvalidName','ZeroWeights','GameRunning','ProcessUnknown','MalformedV2','TamperedDigest','WrongFilenameSchema','PolicyBom','PolicyNoncanonical','AmbiguousPolicy','UnknownReleaseFile','UnknownReleaseDirectory','ReparseReleaseDirectory','UnknownBridgeEntry','ExhaustedRevision','TamperedDll','TamperedModInfo','ChangedAssembly')}elseif($StartupProbe){if($StartupSavedPolicyPath){@('StartupFromEditor')}else{@('StartupFresh','StartupV2','StartupV1','StartupMalformed')}}elseif($SelectionProbe){@('Any','ChosenForest','ChosenBurnt','ChosenDesert','ChosenSnow','ChosenWasteland','WeightedMixed','WeightedSingle')}elseif($EditorProbe){@('EditorSave','EditorCancel')}else{@('Cancel','Apply')}
if($LaunchProbe){$scenarios=@($scenarios)+@('ChangedAssembly','UntestedApply','BeforeApply')}
if($ApplyRejectProbe){$scenarios=@($scenarios|Where-Object {$_ -ne 'ChangedAssembly'})}
if($StorageProbe){$scenarios=@('StorageLinkedRoot','StorageLinkedState','StorageUnavailable')}
if($SteamRefreshProbe){$scenarios=@('SteamRefresh')}
if($UxStateProbe){$scenarios=@('FreshValidation','DirtyRevert','WeightedInactive','SteamDirtyRefresh','PopupActivation','FailedApplySticky','VerifiedReopen','RevisionFreshness','UninstallState')}
if($Round2Probe){$scenarios=@('SelectionProjection','BusyGuard','CopyMatrix','OwnershipAvailability','HelpState','AckRejected')}
foreach($scenario in $scenarios) {
    $scenarioRoot=Join-Path $tempRoot ($Branch+'-'+$scenario)
    $stage=Join-Path $scenarioRoot 'stage'
    $fixture=Join-Path $scenarioRoot 'game'
    $ui=Join-Path $stage 'dev/ui'
    $launcher=Join-Path $stage 'dev/src/launcher'
    $verified=Join-Path $stage 'dev/verified/main'
    $candidate=Join-Path $stage 'candidate/mod'
    $build=Join-Path $stage 'dev/src/runtime'
    foreach($dir in @($ui,$launcher,$verified,$candidate,$build,$fixture,
        (Join-Path $fixture 'Mods/OtherMod'),(Join-Path $fixture 'Saves/TestSave'))) {
        [void][IO.Directory]::CreateDirectory($dir)
    }
    Copy-Item (Join-Path $devRoot 'src/launcher/*.psm1') $launcher
    Copy-Item -LiteralPath (Join-Path $devRoot 'ui/logo.ico') -Destination $ui
    if($UxStateProbe -and $scenario -eq 'FailedApplySticky') {
        $deploymentModule=Join-Path $launcher 'm0162.psm1'
        $moduleText=[IO.File]::ReadAllText($deploymentModule)
        $copyAnchor='$written=Write-HrsAppliedPolicy -GameRoot $GameRoot -Policy $Policy'
        if($moduleText.Split(@($copyAnchor),[StringSplitOptions]::None).Length -ne 2){throw 'UX failure injection anchor changed'}
        $moduleText=$moduleText.Replace($copyAnchor,$copyAnchor+"`r`n            if (`$Policy.revision -gt 1) { throw 'INJECTED_UX_APPLY_FAILURE' }")
        [IO.File]::WriteAllText($deploymentModule,$moduleText,(New-Object Text.UTF8Encoding($false)))
    }
    if($FailureProbe) {
        $moduleName=if($FailurePoint -in @('DuringPolicyReadback','AfterLegacyDelete')){'m0161.psm1'}else{'m0162.psm1'}
        $deploymentModule=Join-Path $launcher $moduleName
        $moduleText=[IO.File]::ReadAllText($deploymentModule)
        $copyAnchor=switch($FailurePoint) {
            'BeforeDllCopy' { '$mutationStarted=$true' }
            'AfterDllCopy' { "[IO.File]::Copy((Join-Path `$PayloadRoot 'd0163.dll'),`$targets[0],`$overwrite)" }
            'AfterModInfoCopy' { "[IO.File]::Copy((Join-Path `$PayloadRoot 'ModInfo.xml'),`$targets[1],`$overwrite)" }
            'DuringPolicyReadback' { '$readback = Read-HrsPolicyFile -Path $readbackPath' }
            'AfterPolicyWrite' { '$written=Write-HrsAppliedPolicy -GameRoot $GameRoot -Policy $Policy' }
            'AfterLegacyDelete' { 'if($legacy){[IO.File]::Delete($paths.LegacyPolicyPath)}' }
        }
        if($moduleText.Split(@($copyAnchor),[StringSplitOptions]::None).Length -ne 2){throw "$FailurePoint anchor changed"}
        $moduleText=$moduleText.Replace($copyAnchor,$copyAnchor+"`r`n            throw 'INJECTED_$($FailurePoint.ToUpperInvariant())'")
        if($RecoveryFail) {
            $restoreAnchor='[IO.File]::Copy($snapshot.Backup,$snapshot.Target,$true)'
            if($moduleText.Split(@($restoreAnchor),[StringSplitOptions]::None).Length -ne 2){throw 'Recovery copy anchor changed'}
            $moduleText=$moduleText.Replace($restoreAnchor,"throw 'INJECTED_RESTORE_FAILURE'`r`n                        "+$restoreAnchor)
        }
        [IO.File]::WriteAllText($deploymentModule,$moduleText,(New-Object Text.UTF8Encoding($false)))
    }
    Copy-Item (Join-Path $payloadSource '*') $verified
    Copy-Item (Join-Path $payloadSource '*') $candidate
    [IO.File]::WriteAllText((Join-Path $fixture '7DaysToDie.exe'),'fixture only; never run')
    [IO.File]::WriteAllText((Join-Path $fixture 'Mods/OtherMod/sentinel.txt'),'unrelated sentinel')
    [IO.File]::WriteAllText((Join-Path $fixture 'Saves/TestSave/sentinel.txt'),'save sentinel')
    if($FailureProbe -or $Upgrade -or $MigrationMatrix -or ($UninstallProbe -and $scenario -eq 'UninstallV1')) {
        $oldRelease=Join-Path $fixture 'Mods/BitWrecked_HistoricalRandomStart'
        [void][IO.Directory]::CreateDirectory($oldRelease)
        Copy-Item (Join-Path $oldPayloadSource '*') $oldRelease
        $oldBridge=Join-Path $oldRelease 'Bridge'
        [void][IO.Directory]::CreateDirectory($oldBridge)
        if($MigrationMatrix) {
            Import-Module (Join-Path $devRoot 'src/launcher/m0161.psm1') -Force
            $legacyMode=$scenario.Substring('Migrate'.Length)
            $legacyPolicy=& (Get-Module m0161) {param($m) New-HrsLegacyPolicy -Revision ([UInt64]1) -GameName 'Fresh Start' -Mode $m} $legacyMode
            $legacyJson=ConvertTo-HrsPolicyJson -Policy $legacyPolicy
        } else {
            $legacyVector=(Get-Content (Join-Path $devRoot 'src/runtime/main/j0148.json') -Raw | ConvertFrom-Json).policyVectors[0]
            $legacyJson=$legacyVector.canonicalJson
        }
        [IO.File]::WriteAllText((Join-Path $oldBridge 'policy.v1.json'),$legacyJson,(New-Object Text.UTF8Encoding($false)))
        $legacyBeforeHash=(Get-FileHash (Join-Path $oldBridge 'policy.v1.json') -Algorithm SHA256).Hash
    }
    $managed=Join-Path $fixture '7DaysToDie_Data/Managed'
    [void][IO.Directory]::CreateDirectory($managed)
    Copy-Item -LiteralPath $gameAssembly -Destination (Join-Path $managed 'Assembly-CSharp.dll')
    if($ApplyRejectProbe) {
        $releaseFixture=Join-Path $fixture 'Mods/BitWrecked_HistoricalRandomStart'
        $bridgeFixture=Join-Path $releaseFixture 'Bridge'
        switch($scenario) {
            'MalformedV2' { [void][IO.Directory]::CreateDirectory($bridgeFixture); [IO.File]::WriteAllText((Join-Path $bridgeFixture 'policy.v2.json'),'{}') }
            {$_ -in @('TamperedDigest','WrongFilenameSchema','PolicyBom','PolicyNoncanonical')} {
                [void][IO.Directory]::CreateDirectory($bridgeFixture)
                $policyPath=Join-Path $bridgeFixture 'policy.v2.json'
                if($scenario -eq 'WrongFilenameSchema') {
                    $vector=(Get-Content (Join-Path $devRoot 'src/runtime/main/j0148.json') -Raw | ConvertFrom-Json).policyVectors[0]
                    [IO.File]::WriteAllText($policyPath,$vector.canonicalJson,(New-Object Text.UTF8Encoding($false)))
                } else {
                    Import-Module (Join-Path $devRoot 'src/launcher/m0161.psm1') -Force
                    $p=New-HrsPolicy -Revision ([UInt64]1) -GameName 'Callback Fixture 125' -Mode Standard
                    [void](Write-HrsPolicyFile -Path $policyPath -AllowedRoot $bridgeFixture -Policy $p)
                    $raw=[IO.File]::ReadAllText($policyPath)
                    if($scenario -eq 'TamperedDigest') {
                        $i=$raw.Length-3
                        $replacement=if($raw[$i] -eq '0'){'1'}else{'0'}
                        $raw=$raw.Substring(0,$i)+$replacement+$raw.Substring($i+1)
                        [IO.File]::WriteAllText($policyPath,$raw,(New-Object Text.UTF8Encoding($false)))
                    } elseif($scenario -eq 'PolicyBom') {
                        [IO.File]::WriteAllText($policyPath,$raw,(New-Object Text.UTF8Encoding($true)))
                    } else {
                        [IO.File]::WriteAllText($policyPath,($raw+' '),(New-Object Text.UTF8Encoding($false)))
                    }
                }
            }
            'AmbiguousPolicy' {
                [void][IO.Directory]::CreateDirectory($bridgeFixture)
                Import-Module (Join-Path $devRoot 'src/launcher/m0161.psm1') -Force
                $p=New-HrsPolicy -Revision ([UInt64]1) -GameName 'Callback Fixture 125' -Mode Standard
                [void](Write-HrsPolicyFile -Path (Join-Path $bridgeFixture 'policy.v2.json') -AllowedRoot $bridgeFixture -Policy $p)
                $vector=(Get-Content (Join-Path $devRoot 'src/runtime/main/j0148.json') -Raw | ConvertFrom-Json).policyVectors[0]
                [IO.File]::WriteAllText((Join-Path $bridgeFixture 'policy.v1.json'),$vector.canonicalJson,(New-Object Text.UTF8Encoding($false)))
            }
            'UnknownReleaseFile' { [void][IO.Directory]::CreateDirectory($releaseFixture); [IO.File]::WriteAllText((Join-Path $releaseFixture 'unknown.txt'),'keep') }
            'UnknownReleaseDirectory' { [void][IO.Directory]::CreateDirectory((Join-Path $releaseFixture 'Unrecognized')) }
            'ReparseReleaseDirectory' {
                [void][IO.Directory]::CreateDirectory($releaseFixture)
                $linkTarget=Join-Path $scenarioRoot 'reparse-target'
                [void][IO.Directory]::CreateDirectory($linkTarget)
                [IO.File]::WriteAllText((Join-Path $linkTarget 'sentinel.txt'),'reparse target unchanged')
                [void](New-Item -ItemType Junction -Path (Join-Path $releaseFixture 'ForeignLink') -Target $linkTarget)
            }
            'UnknownBridgeEntry' { [void][IO.Directory]::CreateDirectory($bridgeFixture); [IO.File]::WriteAllText((Join-Path $bridgeFixture 'unknown.txt'),'keep') }
            'ExhaustedRevision' {
                [void][IO.Directory]::CreateDirectory($bridgeFixture)
                Copy-Item (Join-Path $payloadSource '*') $releaseFixture
                Import-Module (Join-Path $devRoot 'src/launcher/m0161.psm1') -Force
                $p=New-HrsPolicy -Revision ([UInt64]::MaxValue) -GameName 'Callback Fixture 125' -Mode Standard
                [void](Write-HrsPolicyFile -Path (Join-Path $bridgeFixture 'policy.v2.json') -AllowedRoot $bridgeFixture -Policy $p)
            }
            'TamperedDll' { [IO.File]::AppendAllText((Join-Path $verified 'd0163.dll'),'tamper') }
            'TamperedModInfo' { [IO.File]::AppendAllText((Join-Path $verified 'ModInfo.xml'),'tamper') }
            'ChangedAssembly' { [IO.File]::AppendAllText((Join-Path $fixture '7DaysToDie_Data/Managed/Assembly-CSharp.dll'),'tamper') }
        }
    }
    if($StartupProbe -and $scenario -ne 'StartupFresh') {
        $bridgeFixture=Join-Path $fixture 'Mods/BitWrecked_HistoricalRandomStart/Bridge'
        [void][IO.Directory]::CreateDirectory($bridgeFixture)
        if($scenario -eq 'StartupV2') {
            Import-Module (Join-Path $devRoot 'src/launcher/m0161.psm1') -Force
            $p=New-HrsPolicy -Revision ([UInt64]7) -GameName 'Saved Weighted 125' -Mode RandomSafe -Selection Weighted -Weights @(0,10,20,30,40)
            [void](Write-HrsPolicyFile -Path (Join-Path $bridgeFixture 'policy.v2.json') -AllowedRoot $bridgeFixture -Policy $p)
        } elseif($scenario -eq 'StartupV1') {
            $vector=(Get-Content (Join-Path $devRoot 'src/runtime/main/j0148.json') -Raw | ConvertFrom-Json).policyVectors[0]
            [IO.File]::WriteAllText((Join-Path $bridgeFixture 'policy.v1.json'),$vector.canonicalJson,(New-Object Text.UTF8Encoding($false)))
        } elseif($scenario -eq 'StartupFromEditor') {
            Copy-Item -LiteralPath $StartupSavedPolicyPath -Destination (Join-Path $bridgeFixture 'policy.v2.json')
        } else {
            [IO.File]::WriteAllText((Join-Path $bridgeFixture 'policy.v2.json'),'{}')
        }
    }
    if($UxStateProbe -and $scenario -eq 'VerifiedReopen') {
        $releaseFixture=Join-Path $fixture 'Mods/BitWrecked_HistoricalRandomStart'
        $bridgeFixture=Join-Path $releaseFixture 'Bridge'
        [void][IO.Directory]::CreateDirectory($bridgeFixture)
        Copy-Item (Join-Path $payloadSource '*') $releaseFixture
        Import-Module (Join-Path $devRoot 'src/launcher/m0161.psm1') -Force
        $p=New-HrsPolicy -Revision ([UInt64]7) -GameName 'Saved Weighted 125' -Mode RandomSafe -Selection Weighted -Weights @(0,10,20,30,40)
        [void](Write-HrsPolicyFile -Path (Join-Path $bridgeFixture 'policy.v2.json') -AllowedRoot $bridgeFixture -Policy $p)
    }
    $footprintBefore=@(Get-ChildItem -LiteralPath (Join-Path $fixture 'Mods') -Recurse -File | ForEach-Object {
        $_.FullName.Substring($fixture.Length+1)+'|'+(Get-FileHash $_.FullName -Algorithm SHA256).Hash
    }) -join ';'
    $stub='param([string]$GameRoot)'+"`r`n"+'[pscustomobject]@{candidateRoot='+"'"+(Join-Path $stage 'candidate').Replace("'","''")+"'"+'}'
    [IO.File]::WriteAllText((Join-Path $build 'p0143.ps1'),$stub)

    $fixtureSourceSha256=(Get-FileHash -LiteralPath $managerSource -Algorithm SHA256).Hash
    $original=[IO.File]::ReadAllText($managerSource)
    $edited=$original
    # Only the staged test manager receives the copied fixture assembly's identity.
    $fixtureAssembly=Join-Path $fixture '7DaysToDie_Data/Managed/Assembly-CSharp.dll'
    $fixtureMvid=[System.Reflection.Assembly]::ReflectionOnlyLoadFrom($gameAssembly).ManifestModule.ModuleVersionId.ToString()
    $fixtureSha=(Get-FileHash -Algorithm SHA256 -LiteralPath $fixtureAssembly).Hash
    $mvidPattern='(?m)^\$verifiedAssemblyCSharpMvid = \[guid\]''[0-9a-f-]+'''
    $shaPattern='(?m)^\$verifiedAssemblyCSharpSha256 = ''[0-9A-F]{64}'''
    if([regex]::Matches($edited,$mvidPattern).Count -ne 1 -or
        [regex]::Matches($edited,$shaPattern).Count -ne 1){throw 'Manager game build pin anchors changed'}
    $edited=[regex]::Replace($edited,$mvidPattern,[Text.RegularExpressions.MatchEvaluator]{param($m) "`$verifiedAssemblyCSharpMvid = [guid]'$fixtureMvid'"})
    $edited=[regex]::Replace($edited,$shaPattern,[Text.RegularExpressions.MatchEvaluator]{param($m) "`$verifiedAssemblyCSharpSha256 = '$fixtureSha'"})
    if($Branch -eq 'Verified') {
        $flag='$useDevCandidate = $true'
        if($edited.Split(@($flag),[StringSplitOptions]::None).Length -ne 2){throw 'Manager branch anchor changed'}
        $edited=$edited.Replace($flag,'$useDevCandidate = $false')
    }
    $confirmPattern='(?s)\$confirm = \[Windows\.Forms\.MessageBox\]::Show\(\$form,.*?\[Windows\.Forms\.MessageBoxIcon\]::Question(?:,\s*\[(?:System\.)?Windows\.Forms\.MessageBoxDefaultButton\]::Button2)?\)'
    $matches=[regex]::Matches($edited,$confirmPattern)
    if($matches.Count -ne 1){throw "Confirmation anchor changed: $($matches.Count)"}
    $decision=if($scenario -eq 'Cancel'){'No'}else{'Yes'}
    $edited=[regex]::Replace($edited,$confirmPattern,('[IO.File]::WriteAllText((Join-Path $gameRoot ''confirmation-notice.txt''),[string]$gameBuildNotice); [IO.File]::WriteAllText((Join-Path $gameRoot ''confirmation-text.txt''),$confirmationText); $confirm = [Windows.Forms.DialogResult]::'+$decision))
    $successPattern='(?s)(?:\$acknowledgement\s*=\s*)?\[System\.Windows\.Forms\.MessageBox\]::Show\(\s*\$form,\s*\$successText,\s*''New Player Random Start - Settings Applied'',\s*\[System\.Windows\.Forms\.MessageBoxButtons\]::OK,\s*\[System\.Windows\.Forms\.MessageBoxIcon\]::Information\s*\)(?: \| Out-Null)?'
    if([regex]::Matches($edited,$successPattern).Count -ne 1){throw 'Settings Applied popup anchor changed'}
    $successCapture='[IO.File]::WriteAllText((Join-Path $gameRoot ''success-notice.txt''),$successText); [IO.File]::WriteAllText((Join-Path $gameRoot ''success-during-popup.txt''),(''launchEnabled=''+$launchButton.Enabled+'';policyExists=''+[IO.File]::Exists((Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/Bridge/policy.v2.json''))))'
    if($UxStateProbe -and $scenario -eq 'PopupActivation') {
        $successCapture += '; Assert-HrsUx (!$launchButton.Enabled -and $script:launchBlockedUntilApply) ''popup-blocked-before-activation''; Invoke-HrsUxActivation; Assert-HrsUx (!$launchButton.Enabled -and $script:launchBlockedUntilApply) ''popup-blocked-after-activation''; Invoke-HrsFixtureClick $launchButton; Assert-HrsUx (![IO.File]::Exists((Join-Path $gameRoot ''launch-request.txt''))) ''popup-direct-launch-blocked'''
    }
    if($Round2Probe -and $scenario -eq 'BusyGuard') {
        $successCapture += '; Assert-HrsUx ($script:managerOperation -ceq ''AwaitingAcknowledgement'' -and !$launchButton.Enabled -and $script:launchBlockedUntilApply) ''acknowledgement-holds-operation-guard''; Invoke-HrsFixtureClick $applyButton; Invoke-HrsFixtureClick $uninstallButton; Invoke-HrsFixtureClick $launchButton; Invoke-HrsUxActivation; Assert-HrsUx ($script:testInstallCalls -eq 1 -and $script:managerOperation -ceq ''AwaitingAcknowledgement'' -and !$launchButton.Enabled) ''acknowledgement-blocks-conflicting-callbacks'''
    }
    $successCapture += '; $acknowledgement = [Windows.Forms.DialogResult]::'+$(if($Round2Probe -and $scenario -eq 'AckRejected'){'Cancel'}else{'OK'})
    $edited=[regex]::Replace($edited,$successPattern,[Text.RegularExpressions.MatchEvaluator]{param($m) $successCapture})
    if($FailureProbe -or $LaunchProbe -or $ResultProbe -or $UninstallProbe -or $ApplyRejectProbe -or $StorageProbe -or $UxStateProbe -or $Round2Probe) {
        $warningPattern='(?s)\[System\.Windows\.Forms\.MessageBox\]::Show\(\s*\$form,\s*(?:\$_\.Exception\.Message|\$applyError),\s*''New Player Random Start'',\s*\[(?:System\.)?Windows\.Forms\.MessageBoxButtons\]::OK,\s*\[(?:System\.)?Windows\.Forms\.MessageBoxIcon\]::Warning(?:,\s*\[(?:System\.)?Windows\.Forms\.MessageBoxDefaultButton\]::Button2)?\s*\) \| Out-Null'
        if([regex]::Matches($edited,$warningPattern).Count -lt 1){throw 'Warning anchor changed'}
        $warningCapture='[IO.File]::WriteAllText((Join-Path $gameRoot ''warning-notice.txt''),[string]$(if(Get-Variable applyError -ErrorAction SilentlyContinue){$applyError}else{$_.Exception.Message})); ''WARNING_NOTICE=''+[IO.File]::ReadAllText((Join-Path $gameRoot ''warning-notice.txt''))'
        $edited=[regex]::Replace($edited,$warningPattern,[Text.RegularExpressions.MatchEvaluator]{param($m) $warningCapture})
    }
    if($LaunchProbe -or $UxStateProbe -or $Round2Probe) {
        $launchAnchor='Start-Process -FilePath $launch.Executable -WorkingDirectory $launch.WorkingDirectory -WindowStyle Normal'
        if($edited.Split(@($launchAnchor),[StringSplitOptions]::None).Length -ne 2){throw 'Launch anchor changed'}
        $capture='[IO.File]::WriteAllText((Join-Path $gameRoot ''launch-request.txt''),($launch.Executable+''|''+$launch.WorkingDirectory))'
        $edited=$edited.Replace($launchAnchor,$capture)
    }
    if($UninstallProbe -or ($UxStateProbe -and $scenario -eq 'UninstallState') -or ($Round2Probe -and $scenario -in @('BusyGuard','OwnershipAvailability'))) {
        $uninstallPattern='(?s)\$confirm = \[System\.Windows\.Forms\.MessageBox\]::Show\(\s*\$form,\s*"Uninstall New Player Random Start.*?\[System\.Windows\.Forms\.MessageBoxIcon\]::Warning(?:,\s*\[(?:System\.)?Windows\.Forms\.MessageBoxDefaultButton\]::Button2)?\s*\)'
        if([regex]::Matches($edited,$uninstallPattern).Count -ne 1){throw 'Uninstall confirmation anchor changed'}
        $uninstallDecision=if($scenario -eq 'UninstallCancel'){'No'}else{'Yes'}
        $edited=[regex]::Replace($edited,$uninstallPattern,('$confirm = [Windows.Forms.DialogResult]::'+$uninstallDecision))
    }
    $tailPattern='(?s)if \(\$SmokeTest\) \{\r?\n    \$form\.Show\(\).*?\r?\n\}\r?\n\[void\]\$form\.ShowDialog\(\)\s*$'
    $matches=[regex]::Matches($edited,$tailPattern)
    if($matches.Count -ne 1){throw "Smoke driver anchor changed: $($matches.Count)"}
    $driver=@'
__STEAM_SETUP__
$form.Show()
[Windows.Forms.Application]::DoEvents()
$gameNameBox.Text='Callback Fixture 125'
$standardRadio.Checked=$true
__PREF_DRIVER__
__REJECT_DRIVER__
$applyButton.PerformClick()
[Windows.Forms.Application]::DoEvents()
__STEAM_DRIVER__
__LAUNCH_DRIVER__
__RESULT_DRIVER__
__UNINSTALL_DRIVER__
'STATUS='+$status.Text
'BADGE_STATE='+$script:applyBadge.Text
'POLICY_EXISTS='+[IO.File]::Exists((Join-Path $gameRoot 'Mods/BitWrecked_HistoricalRandomStart/Bridge/policy.v2.json'))
'FORM_SELECTION='+(Get-HrsFormSelection).Selection
'FORM_CHOSEN='+(Get-HrsFormSelection).ChosenBiome
'APPLY_ENABLED='+$applyButton.Enabled
'LAUNCH_ENABLED='+$launchButton.Enabled
'LAUNCH_BLOCKED='+$script:launchBlockedUntilApply
$form.Dispose()
'@
    if($StartupProbe) {
        $driver=@'
$form.Show()
[Windows.Forms.Application]::DoEvents()
'STARTUP_NAME='+$gameNameBox.Text
'STARTUP_MODE='+$(if($randomRadio.Checked){if($biomeProtectCheck.Checked){'RandomSafe'}else{'Random'}}else{'Standard'})
'STARTUP_SELECTION='+(Get-HrsFormSelection).Selection
'STARTUP_WEIGHTS='+((Get-HrsFormSelection).Weights -join ',')
'STARTUP_STATUS='+$status.Text
'STARTUP_APPLY_ENABLED='+$applyButton.Enabled
$form.Dispose()
'@
    }
    if($MigrationMatrix) {
        $driver=$driver.Replace("`$gameNameBox.Text='Callback Fixture 125'", "'STARTUP_NAME='+`$gameNameBox.Text")
        $driver=$driver.Replace('$standardRadio.Checked=$true',"'STARTUP_MODE='+`$(if(`$randomRadio.Checked){if(`$biomeProtectCheck.Checked){'RandomSafe'}else{'Random'}}else{'Standard'})")
    }
    $prefDriver=''
    if($SelectionProbe) {
        $prefDriver=switch($scenario) {
            'Any' { '$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Any; $biomeProtectCheck.Checked=$false' }
            'ChosenForest' { '$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Chosen; $chosenCombo.SelectedItem=''Forest''; $biomeProtectCheck.Checked=$true' }
            'ChosenBurnt' { '$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Chosen; $chosenCombo.SelectedItem=''Burnt Forest''; $biomeProtectCheck.Checked=$true' }
            'ChosenDesert' { '$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Chosen; $chosenCombo.SelectedItem=''Desert''; $biomeProtectCheck.Checked=$true' }
            'ChosenSnow' { '$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Chosen; $chosenCombo.SelectedItem=''Snow''; $biomeProtectCheck.Checked=$true' }
            'ChosenWasteland' { '$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Chosen; $chosenCombo.SelectedItem=''Wasteland''; $biomeProtectCheck.Checked=$true' }
            'WeightedMixed' { '$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Weighted; $weights[''Forest'']=0; $weights[''Burnt Forest'']=10; $weights[''Desert'']=20; $weights[''Snow'']=30; $weights[''Wasteland'']=40; $biomeProtectCheck.Checked=$false' }
            'WeightedSingle' { '$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Weighted; $weights[''Forest'']=0; $weights[''Burnt Forest'']=0; $weights[''Desert'']=100; $weights[''Snow'']=0; $weights[''Wasteland'']=0; $biomeProtectCheck.Checked=$true' }
        }
    }
    if($EditorProbe) {
        $action=if($scenario -eq 'EditorSave'){'Save'}else{'Cancel'}
        $prefDriver='$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Weighted; Show-WeightEditor -TestAction '+$action+'; Set-HrsSelectionMethod -Selection Any; Set-HrsSelectionMethod -Selection Weighted'
    }
    if($SteamRefreshProbe) {
        $prefDriver='$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Any; $biomeProtectCheck.Checked=$false'
        $steamSetup=@'
$script:testSteamState='Closed'
function Get-HrsProcessState { [pscustomobject]@{Game='Closed';Steam=$script:testSteamState;Reason='TEST_PROCESS_PROVIDER'} }
'@
        $steamDriver=@'
'LAUNCH_BEFORE_STEAM='+$launchButton.Enabled
$script:testSteamState='Running'
$activate=[Windows.Forms.Form].GetMethod('OnActivated',([Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic))
[void]$activate.Invoke($form,@([EventArgs]::Empty))
'LAUNCH_AFTER_STEAM='+$launchButton.Enabled
'@
    } else { $steamSetup=''; $steamDriver='' }
    $resultDriver=''
    $uninstallDriver=''
    $rejectDriver=''
    if($ResultProbe) {
        $resultDriver=@'
$configured=Read-HrsConfiguredPolicy -GameRoot $gameRoot
$observed=New-HrsResult -PolicyRevision $configured.revision -PolicyDigest $configured.policyDigest -Outcome COMPLETED -Reason RELOCATION_COMPLETED -MarkerState COMPLETED
[IO.File]::WriteAllText((Join-Path $gameRoot 'Mods/BitWrecked_HistoricalRandomStart/Bridge/result.v1.json'),(ConvertTo-HrsResultJson -Result $observed),(New-Object Text.UTF8Encoding($false)))
Update-HrsResultStatus
'RESULT_CURRENT='+$resultStatus.Text
$selected=New-HrsResult -PolicyRevision $configured.revision -PolicyDigest $configured.policyDigest -Outcome RESERVED -Reason PLACEMENT_DEFERRED -MarkerState RESERVED
[IO.File]::WriteAllText((Join-Path $gameRoot 'Mods/BitWrecked_HistoricalRandomStart/Bridge/result.v1.json'),(ConvertTo-HrsResultJson -Result $selected),(New-Object Text.UTF8Encoding($false)))
Update-HrsResultStatus
'RESULT_SELECTED='+$resultStatus.Text
$failed=New-HrsResult -PolicyRevision $configured.revision -PolicyDigest $configured.policyDigest -Outcome FAILED -Reason PLACEMENT_FAILED -MarkerState RESERVED
[IO.File]::WriteAllText((Join-Path $gameRoot 'Mods/BitWrecked_HistoricalRandomStart/Bridge/result.v1.json'),(ConvertTo-HrsResultJson -Result $failed),(New-Object Text.UTF8Encoding($false)))
Update-HrsResultStatus
'RESULT_FAILED='+$resultStatus.Text
$wrongDigest=New-HrsResult -PolicyRevision $configured.revision -PolicyDigest ('1'*64) -Outcome COMPLETED -Reason RELOCATION_COMPLETED -MarkerState COMPLETED
[IO.File]::WriteAllText((Join-Path $gameRoot 'Mods/BitWrecked_HistoricalRandomStart/Bridge/result.v1.json'),(ConvertTo-HrsResultJson -Result $wrongDigest),(New-Object Text.UTF8Encoding($false)))
Update-HrsResultStatus
'RESULT_WRONG_DIGEST='+$resultStatus.Text
$wrongRevision=New-HrsResult -PolicyRevision ([UInt64]($configured.revision+1)) -PolicyDigest $configured.policyDigest -Outcome COMPLETED -Reason RELOCATION_COMPLETED -MarkerState COMPLETED
[IO.File]::WriteAllText((Join-Path $gameRoot 'Mods/BitWrecked_HistoricalRandomStart/Bridge/result.v1.json'),(ConvertTo-HrsResultJson -Result $wrongRevision),(New-Object Text.UTF8Encoding($false)))
Update-HrsResultStatus
'RESULT_WRONG_REVISION='+$resultStatus.Text
[IO.File]::WriteAllText((Join-Path $gameRoot 'Mods/BitWrecked_HistoricalRandomStart/Bridge/result.v1.json'),(ConvertTo-HrsResultJson -Result $observed),(New-Object Text.UTF8Encoding($false)))
$applyButton.PerformClick()
[Windows.Forms.Application]::DoEvents()
'RESULT_STALE='+$resultStatus.Text
'@
    }
    if($UninstallProbe) {
        $uninstallDriver=@'
__UNINSTALL_SETUP__
Invoke-HrsFixtureClick $uninstallButton
[Windows.Forms.Application]::DoEvents()
'UNINSTALL_STATUS='+$status.Text
'@
        $uninstallSetup=switch($scenario) {
            'UninstallUnknown' { '[IO.File]::WriteAllText((Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/unknown.txt''),''keep'')' }
            'UninstallRunning' { 'function Get-HrsProcessState { [pscustomobject]@{Game=''Running'';Steam=''Running'';Reason=''TEST_PROCESS_PROVIDER''} }' }
            'UninstallProcessUnknown' { 'function Get-HrsProcessState { [pscustomobject]@{Game=''Unknown'';Steam=''Unknown'';Reason=''TEST_PROCESS_PROVIDER''} }' }
            default { '' }
        }
        $uninstallDriver=$uninstallDriver.Replace('__UNINSTALL_SETUP__',$uninstallSetup)
    }
    if($ApplyRejectProbe) {
        $rejectDriver=switch($scenario) {
            'InvalidName' { '$gameNameBox.Text=''Bad/Name''' }
            'ZeroWeights' { '$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Weighted; foreach($b in $biomes){$weights[$b]=0}; Update-HrsBiomePreview' }
            'GameRunning' { 'function Get-HrsProcessState { [pscustomobject]@{Game=''Running'';Steam=''Running'';Reason=''TEST_PROCESS_PROVIDER''} }' }
            'ProcessUnknown' { 'function Get-HrsProcessState { [pscustomobject]@{Game=''Unknown'';Steam=''Unknown'';Reason=''TEST_PROCESS_PROVIDER''} }' }
            default { '' }
        }
    }
    $launchDriver=''
    if($LaunchProbe) {
        if($scenario -eq 'UntestedApply') {
            $prefDriver='[IO.File]::AppendAllText((Join-Path $gameRoot ''7DaysToDie_Data/Managed/Assembly-CSharp.dll''),''untested fixture'')'
        }
        $launchDriver=@'
function Get-HrsProcessState { [pscustomobject]@{ Game='__GAME_STATE__';Steam='__STEAM_STATE__';Reason='TEST_PROCESS_PROVIDER' } }
__TAMPER_DRIVER__
Invoke-HrsFixtureClick $launchButton
[Windows.Forms.Application]::DoEvents()
'LAUNCH_REQUEST_EXISTS='+[IO.File]::Exists((Join-Path $gameRoot 'launch-request.txt'))
'RESULT_LABEL='+$resultStatus.Text
'@
        $tamperDriver=switch($scenario) {
            {$_ -in @('ChangedAssembly','BeforeApply')} { '[IO.File]::AppendAllText((Join-Path $gameRoot ''7DaysToDie_Data/Managed/Assembly-CSharp.dll''),''untested fixture'')' }
            'TamperDll' { '[IO.File]::AppendAllText((Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/d0163.dll''),''tamper'')' }
            'TamperModInfo' { '[IO.File]::AppendAllText((Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/ModInfo.xml''),''tamper'')' }
            'TamperDigest' { '$p=Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/Bridge/policy.v2.json''; $raw=[IO.File]::ReadAllText($p); $i=$raw.Length-66; $c=if($raw[$i] -eq ''0''){''1''}else{''0''}; $raw=$raw.Substring(0,$i)+$c+$raw.Substring($i+1); [IO.File]::WriteAllText($p,$raw,(New-Object Text.UTF8Encoding($false)))' }
            'LegacyPolicy' { '$bridge=Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/Bridge''; $vector=(Get-Content ''__VECTOR_PATH__'' -Raw | ConvertFrom-Json).policyVectors[0]; [IO.File]::WriteAllText((Join-Path $bridge ''policy.v1.json''),$vector.canonicalJson,(New-Object Text.UTF8Encoding($false))); [IO.File]::Delete((Join-Path $bridge ''policy.v2.json''))' }
            'MissingPolicy' { '[IO.File]::Delete((Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/Bridge/policy.v2.json''))' }
            'WrongSchema' { '$bridge=Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/Bridge''; $vector=(Get-Content ''__VECTOR_PATH__'' -Raw | ConvertFrom-Json).policyVectors[0]; [IO.File]::WriteAllText((Join-Path $bridge ''policy.v2.json''),$vector.canonicalJson,(New-Object Text.UTF8Encoding($false)))' }
            'MalformedPolicy' { '[IO.File]::WriteAllText((Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/Bridge/policy.v2.json''),''{}'')' }
            'AmbiguousPolicy' { '$bridge=Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/Bridge''; $vector=(Get-Content ''__VECTOR_PATH__'' -Raw | ConvertFrom-Json).policyVectors[0]; [IO.File]::WriteAllText((Join-Path $bridge ''policy.v1.json''),$vector.canonicalJson,(New-Object Text.UTF8Encoding($false)))' }
            'StaleResult' { '$bridge=Join-Path $gameRoot ''Mods/BitWrecked_HistoricalRandomStart/Bridge''; $old=New-HrsResult -PolicyRevision ([UInt64]1) -PolicyDigest (''1''*64) -Outcome COMPLETED -Reason RELOCATION_COMPLETED -MarkerState COMPLETED; [IO.File]::WriteAllText((Join-Path $bridge ''result.v1.json''),(ConvertTo-HrsResultJson -Result $old),(New-Object Text.UTF8Encoding($false))); Update-HrsResultStatus' }
            default { '' }
        }
        $tamperDriver=$tamperDriver.Replace('__VECTOR_PATH__',(Join-Path $devRoot 'src/runtime/main/j0148.json').Replace("'","''"))
        $gameState=if($scenario -eq 'GameRunning'){'Running'}elseif($scenario -eq 'ProcessUnknown'){'Unknown'}else{'Closed'}
        $steamState=if($scenario -eq 'SteamClosed'){'Closed'}elseif($scenario -eq 'ProcessUnknown'){'Unknown'}else{'Running'}
        $launchDriver=$launchDriver.Replace('__TAMPER_DRIVER__',$tamperDriver).Replace('__GAME_STATE__',$gameState).Replace('__STEAM_STATE__',$steamState)
    }
    $driver=$driver.Replace('__LAUNCH_DRIVER__',$launchDriver)
    $driver=$driver.Replace('__STEAM_SETUP__',$steamSetup).Replace('__STEAM_DRIVER__',$steamDriver)
    $driver=$driver.Replace('__PREF_DRIVER__',$prefDriver).Replace('__RESULT_DRIVER__',$resultDriver).Replace('__UNINSTALL_DRIVER__',$uninstallDriver).Replace('__REJECT_DRIVER__',$rejectDriver)
    if($scenario -eq 'UninstallV1'){$driver=$driver.Replace('$applyButton.PerformClick()','$null = $applyButton')}
    if($LaunchProbe -and $scenario -eq 'BeforeApply'){$driver=$driver.Replace('$applyButton.PerformClick()','$null = $applyButton')}
    if($ApplyRejectProbe){$driver=$driver.Replace('$applyButton.PerformClick()','Invoke-HrsFixtureClick $applyButton')}
    if($UxStateProbe -or $Round2Probe) {
        $uxBody=if($Round2Probe) { switch($scenario) {
            'SelectionProjection' {@'
$gameNameBox.Text='Callback Fixture 125'
$randomRadio.Checked=$true
$chosenCombo.SelectedItem='Wasteland'
$originalWeights=@($biomes|ForEach-Object{$weights[$_]})
$before=Get-HrsUxPolicyHash
foreach($selection in @('Any','Chosen','Weighted','Chosen','Any','Weighted')) {
    Set-HrsSelectionMethod -Selection $selection
    Assert-HrsUx ($script:selectionMethod -ceq $selection -and (Get-HrsFormSelection).Selection -ceq $selection) ('one-authoritative-selection-'+$selection)
    Assert-HrsUx ($randomRadio.Checked -and !$standardRadio.Checked) ('method-radio-independent-of-random-'+$selection)
}
Assert-HrsUx ($chosenCombo.SelectedItem -ceq 'Wasteland' -and (@($biomes|ForEach-Object{$weights[$_]}) -join ',') -ceq ($originalWeights -join ',')) 'switching-retains-unsaved-dependent-values'
$invalidRejected=$false
try { Set-HrsSelectionMethod -Selection 'Unknown' } catch { $invalidRejected=$true }
Assert-HrsUx ($invalidRejected -and $script:selectionMethod -ceq 'Weighted') 'invalid-method-refused-without-changing-selection'
Set-HrsSelectionMethod -Selection Chosen
$chosenCombo.SelectedIndex=-1
$invalidRejected=$false
try { [void](Get-HrsFormSelection) } catch { $invalidRejected=$true }
Assert-HrsUx $invalidRejected 'invalid-chosen-index-refused'
$chosenCombo.SelectedItem='Wasteland'
$saved=New-HrsPolicy -Revision ([UInt64]7) -GameName 'Restored Chosen' -Mode RandomSafe -Selection Chosen -ChosenBiome 8
Set-HrsFormFromPolicy -Policy $saved
Assert-HrsUx ($gameNameBox.Text -ceq 'Restored Chosen' -and $randomRadio.Checked -and $biomeProtectCheck.Checked -and (Get-HrsFormSelection).ChosenBiome -eq 8) 'complete-policy-load-projected-consistently'
$saved=New-HrsPolicy -Revision ([UInt64]8) -GameName 'Restored Weighted' -Mode Random -Selection Weighted -Weights @(0,10,20,30,40)
Set-HrsFormFromPolicy -Policy $saved
Assert-HrsUx ($script:selectionMethod -ceq 'Weighted' -and ((Get-HrsFormSelection).Weights -join ',') -ceq '0,10,20,30,40') 'complete-weighted-policy-load-projected-consistently'
$standardRadio.Checked=$true
Assert-HrsUx ((Get-HrsFormSelection).Selection -ceq 'Any' -and $script:selectionMethod -ceq 'Weighted') 'standard-policy-does-not-destroy-unsaved-random-choice'
$randomRadio.Checked=$true
Assert-HrsUx ((Get-HrsFormSelection).Selection -ceq 'Weighted') 'random-return-restores-method'
Assert-HrsUx ((Get-HrsUxPolicyHash) -ceq $before) 'selection-and-policy-projection-write-no-game-policy'
'@
            }
            'BusyGuard' {@'
$script:testInstallCalls=0
$script:testRealInstall=(Get-Command Invoke-HrsInstallAndApply -Module m0162).ScriptBlock
function Invoke-HrsInstallAndApply {
    [CmdletBinding()]
    param([string]$GameRoot,[string]$PayloadRoot,[psobject]$Policy,[string]$ReleaseVersion)
    $script:testInstallCalls++
    if($script:testInstallCalls -gt 1){throw 'DUPLICATE_INSTALL_CALLBACK_ENTERED'}
    Assert-HrsUx ($script:managerOperation -ceq 'Applying' -and !$applyButton.Enabled -and !$launchButton.Enabled -and !$uninstallButton.Enabled) 'guard-visible-before-backend-write'
    Invoke-HrsFixtureClick $applyButton; Invoke-HrsFixtureClick $uninstallButton; Invoke-HrsFixtureClick $launchButton
    Invoke-HrsUxActivation
    Assert-HrsUx ($script:testInstallCalls -eq 1 -and $script:managerOperation -ceq 'Applying' -and !$applyButton.Enabled -and !$launchButton.Enabled) 'conflicting-callbacks-blocked-before-backend-write'
    return (& $script:testRealInstall @PSBoundParameters)
}
$gameNameBox.Text='Callback Fixture 125'; $randomRadio.Checked=$true
$applyButton.PerformClick()
$saved=Read-HrsConfiguredPolicy -GameRoot $gameRoot
Assert-HrsUx ($saved.revision -eq 1 -and $script:testInstallCalls -eq 1) 'one-confirmed-operation-one-actual-write'
Assert-HrsUx ($script:managerOperation -ceq 'Idle' -and !$script:launchBlockedUntilApply -and $launchButton.Enabled -and $script:applyBadge.Text -ceq 'Changes applied.') 'acknowledgement-releases-guard-after-verification'
Assert-HrsUx ($script:lastOperationDurationMs -ge 0) 'measured-operation-duration-recorded'
'OPERATION_DURATION_MS='+$script:lastOperationDurationMs
Assert-HrsUx (![IO.File]::Exists((Join-Path $gameRoot 'launch-request.txt'))) 'guarded-conflicting-launch-not-dispatched'
$script:testSteamState='Closed'; Invoke-HrsUxActivation
Assert-HrsUx ($script:managerConfigurationState -ceq 'Applied' -and $script:applyBadge.Text -ceq 'Changes applied.' -and !$launchButton.Enabled -and $script:nextAction.Text -ceq 'Open Steam to launch the game.') 'steam-closed-does-not-revoke-applied-state'
$script:testSteamState='Running'; Invoke-HrsUxActivation
Assert-HrsUx ($launchButton.Enabled -and $script:testInstallCalls -eq 1 -and $saved.revision -eq 1) 'steam-return-needs-no-reapply'
'@
            }
            'CopyMatrix' {@'
$notice='Do not log out until your first trader is assigned. Complete the opening tasks in this session and wait for the Journey to Settlement trader marker. Leaving earlier may send the quest to Pine Forest when you return.'
$rows=@(@{mode='Standard';selection='Any';protect=$false})
foreach($selection in @('Any','Chosen','Weighted')) { foreach($protect in @($false,$true)){ $rows+=@{mode='Random';selection=$selection;protect=$protect} } }
$revision=0
foreach($row in $rows) {
    $revision++
    $gameNameBox.Text='Copy Matrix '+$revision
    $randomRadio.Checked=($row.mode -ceq 'Random'); $standardRadio.Checked=($row.mode -ceq 'Standard')
    Set-HrsSelectionMethod -Selection $row.selection
    $chosenCombo.SelectedItem='Desert'; $biomeProtectCheck.Checked=$row.protect
    $applyButton.PerformClick()
    $confirmed=[IO.File]::ReadAllText((Join-Path $gameRoot 'confirmation-text.txt'))
    $ack=[IO.File]::ReadAllText((Join-Path $gameRoot 'success-notice.txt'))
    $saved=Read-HrsConfiguredPolicy -GameRoot $gameRoot
    Assert-HrsUx ($saved.gameName -ceq $gameNameBox.Text -and $saved.revision -eq $revision -and $confirmed.Contains($gameNameBox.Text) -and $ack.Contains($gameNameBox.Text)) ('exact-game-name-policy-popup-agreement-'+$revision)
    if($row.mode -ceq 'Standard') {
        Assert-HrsUx ($saved.mode -ceq 'Standard' -and !$confirmed.Contains('If no safe landing') -and !$ack.Contains($notice)) 'standard-omits-random-only-copy'
    } else {
        Assert-HrsUx ($saved.selection -ceq $row.selection -and $saved.mode -ceq $(if($row.protect){'RandomSafe'}else{'Random'})) ('method-protection-policy-agreement-'+$revision)
        Assert-HrsUx ($confirmed.Contains('If no safe landing is available, HRS keeps the usual start.') -and $ack.Contains($notice)) ('conditional-fallback-and-exact-trader-notice-'+$revision)
    }
    $protection=if($row.mode -ceq 'Random' -and $row.protect){'On'}else{'Off'}
    Assert-HrsUx ($confirmed.Contains('Starting-biome protection: '+$protection) -and $ack.Contains('Starting-biome protection: '+$protection)) ('protection-summary-agreement-'+$revision)
    Assert-HrsUx ($script:managerOperation -ceq 'Idle' -and $launchButton.Enabled) ('matrix-verified-acknowledgement-completed-'+$revision)
}
'@
            }
            'OwnershipAvailability' {@'
$gameNameBox.Text='Callback Fixture 125'; Invoke-HrsUxActivation
Assert-HrsUx (!$uninstallButton.Enabled -and [bool]$script:managerUninstallReason) 'absent-install-removal-unavailable-with-reason'
$applyButton.PerformClick(); Invoke-HrsUxActivation
Assert-HrsUx $uninstallButton.Enabled 'owned-install-removal-available'
$paths=Get-HrsBridgePaths -GameRoot $gameRoot
$extra=Join-Path $paths.ReleaseRoot 'unknown.txt'; [IO.File]::WriteAllText($extra,'keep')
$before=Get-HrsUxPolicyHash; Invoke-HrsUxActivation
Assert-HrsUx (!$uninstallButton.Enabled -and [bool]$script:managerUninstallReason) 'unknown-files-removal-unavailable-with-reason'
Invoke-HrsFixtureClick $uninstallButton
Assert-HrsUx ([IO.File]::ReadAllText($extra) -ceq 'keep' -and (Get-HrsUxPolicyHash) -ceq $before) 'unknown-install-authoritative-click-preserves-bytes'
[IO.File]::Delete($extra); Invoke-HrsUxActivation
Assert-HrsUx $uninstallButton.Enabled 'owned-availability-refreshes-after-fixture-cleared'
$dll=Join-Path $paths.ReleaseRoot 'ModInfo.xml'; $otherMod=[IO.File]::ReadAllText($dll).Replace('BitWrecked_HistoricalRandomStart','Unrelated_Mod'); [IO.File]::WriteAllText($dll,$otherMod)
$dllHash=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash
Invoke-HrsUxActivation
Assert-HrsUx (!$uninstallButton.Enabled -and [bool]$script:managerUninstallReason) 'mismatched-files-removal-unavailable-with-reason'
Invoke-HrsFixtureClick $uninstallButton
Assert-HrsUx ((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -ceq $dllHash -and (Get-HrsUxPolicyHash) -ceq $before) 'unowned-install-authoritative-click-preserves-bytes'
'@
            }
            'AckRejected' {@'
$gameNameBox.Text='Callback Fixture 125'; $applyButton.PerformClick()
$saved=Read-HrsConfiguredPolicy -GameRoot $gameRoot
Assert-HrsUx ($null -ne $saved -and $saved.revision -eq 1) 'non-ok-acknowledgement-keeps-verified-write'
Assert-HrsUx ($script:managerOperation -ceq 'Idle' -and $script:launchBlockedUntilApply -and !$launchButton.Enabled) 'non-ok-acknowledgement-fails-closed'
Invoke-HrsUxActivation; Invoke-HrsFixtureClick $launchButton
Assert-HrsUx ($script:launchBlockedUntilApply -and !$launchButton.Enabled -and ![IO.File]::Exists((Join-Path $gameRoot 'launch-request.txt'))) 'non-ok-acknowledgement-activation-cannot-unlock-launch'
'@
            }
            'HelpState' {@'
$before=Get-HrsUxPolicyHash
$helpControls=@(Get-HrsFixtureDescendants $form|Where-Object { $_.Text -ceq 'Help' })
Assert-HrsUx ($helpControls.Count -eq 1 -and $helpControls[0].TabStop -and $helpControls[0].AccessibleName -match 'Help') 'local-help-keyboard-and-accessibility-name-present'
Assert-HrsUx (@(Get-HrsFixtureDescendants $form|Where-Object { $_.Text -match '^Restore' }).Count -eq 0) 'manual-restore-removed-from-live-controls'
$helpSource=(Get-Command Show-HrsHelp).Definition
foreach($phrase in @('Game Name','world','0 to 100','zero','environmental','Apply','Launch','Journey to Settlement')) {
    Assert-HrsUx ($helpSource -match [regex]::Escape($phrase)) ('local-help-source-covers-'+$phrase)
}
Assert-HrsUx ((Get-HrsUxPolicyHash) -ceq $before) 'help-state-discovery-writes-no-game-policy'
'HELP_SCOPE=Source text and native control discovery; actual Help keyboard/Narrator and popup dismissal remain independent QA Pending.'
'@
            }
        } } else { switch($scenario) {
            'FreshValidation' {@'
Assert-HrsUx (!$applyButton.Enabled -and !$launchButton.Enabled -and !$uninstallButton.Enabled) 'fresh-disabled-actions'
Assert-HrsUx ($script:nextAction.Text -match 'Game Name') 'fresh-name-guidance'
Save-HrsUxCapture 'fresh'
$gameNameBox.Text='Bad/Name'
Assert-HrsUx (!$applyButton.Enabled -and !$launchButton.Enabled) 'invalid-name-blocked-inline'
Assert-HrsUx ($script:nextAction.Text -match 'name|character') 'invalid-name-guidance'
$gameNameBox.Text='Callback Fixture 125'
Assert-HrsUx ($applyButton.Enabled -and !$launchButton.Enabled) 'valid-name-apply-only'
Assert-HrsUx ($script:applyBadge.Text -ceq 'Changes not applied.') 'fresh-valid-status'
Invoke-HrsFixtureClick $launchButton
Assert-HrsUx (![IO.File]::Exists((Join-Path $gameRoot 'launch-request.txt'))) 'fresh-direct-launch-blocked'
'@
            }
            'DirtyRevert' {@'
$gameNameBox.Text='Callback Fixture 125'
$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Chosen; $chosenCombo.SelectedItem='Wasteland'; $biomeProtectCheck.Checked=$true
$applyButton.PerformClick()
$saved=Read-HrsConfiguredPolicy -GameRoot $gameRoot
$before=Get-HrsUxPolicyHash
Assert-HrsUx ($launchButton.Enabled -and (Test-HrsFormMatchesPolicy -Policy $saved)) 'chosen-applied-ready'
Save-HrsUxCapture 'chosen-applied'
$gameNameBox.Text='callback Fixture 125'
Assert-HrsUx (!$launchButton.Enabled -and $script:applyBadge.Text -ceq 'Changes not applied.') 'case-sensitive-name-dirty'
Save-HrsUxCapture 'name-dirty'
$gameNameBox.Text=$saved.gameName
Assert-HrsUx $launchButton.Enabled 'name-revert-restores-readiness'
Save-HrsUxCapture 'name-reverted'
$biomeProtectCheck.Checked=$false
Assert-HrsUx (!$launchButton.Enabled -and !(Test-HrsFormMatchesPolicy -Policy $saved)) 'protection-dirty'
$biomeProtectCheck.Checked=$true
Assert-HrsUx $launchButton.Enabled 'protection-revert-ready'
$chosenCombo.SelectedItem='Desert'
Assert-HrsUx (!$launchButton.Enabled -and !(Test-HrsFormMatchesPolicy -Policy $saved)) 'chosen-biome-dirty'
$chosenCombo.SelectedItem='Wasteland'
Assert-HrsUx $launchButton.Enabled 'chosen-biome-revert-ready'
Set-HrsSelectionMethod -Selection Any
Assert-HrsUx (!$launchButton.Enabled -and !(Test-HrsFormMatchesPolicy -Policy $saved)) 'selection-method-dirty'
Set-HrsSelectionMethod -Selection Chosen
Assert-HrsUx $launchButton.Enabled 'selection-method-revert-ready'
$standardRadio.Checked=$true
Assert-HrsUx (!$launchButton.Enabled -and !(Test-HrsFormMatchesPolicy -Policy $saved)) 'mode-dirty'
$randomRadio.Checked=$true
Assert-HrsUx $launchButton.Enabled 'mode-revert-ready'
$gameNameBox.Text='callback Fixture 125'; Invoke-HrsFixtureClick $launchButton
Assert-HrsUx (![IO.File]::Exists((Join-Path $gameRoot 'launch-request.txt'))) 'dirty-direct-launch-blocked'
$gameNameBox.Text=$saved.gameName
Assert-HrsUx ((Get-HrsUxPolicyHash) -ceq $before) 'edit-and-revert-do-not-write-policy'
'@
            }
            'WeightedInactive' {@'
$gameNameBox.Text='Callback Fixture 125'
$randomRadio.Checked=$true; Set-HrsSelectionMethod -Selection Weighted; $biomeProtectCheck.Checked=$false
$applyButton.PerformClick()
$saved=Read-HrsConfiguredPolicy -GameRoot $gameRoot
$before=Get-HrsUxPolicyHash
$originalWeights=@($biomes|ForEach-Object{$weights[$_]})
Save-HrsUxCapture 'weighted-applied'
for($i=0;$i -lt 5;$i++) {
    $weights[$biomes[$i]]=($originalWeights[$i]+1)%101; Update-HrsBiomePreview
    Assert-HrsUx (!$launchButton.Enabled -and !(Test-HrsFormMatchesPolicy -Policy $saved)) ('individual-weight-dirty-'+$i)
    $weights[$biomes[$i]]=$originalWeights[$i]; Update-HrsBiomePreview
    Assert-HrsUx $launchButton.Enabled ('individual-weight-revert-ready-'+$i)
}
Show-WeightEditor -TestAction Save
Assert-HrsUx (!$launchButton.Enabled -and !(Test-HrsFormMatchesPolicy -Policy $saved)) 'saved-editor-values-are-unapplied'
Save-HrsUxCapture 'weights-edited'
for($i=0;$i -lt 5;$i++){$weights[$biomes[$i]]=$originalWeights[$i]}; Update-HrsBiomePreview
Assert-HrsUx $launchButton.Enabled 'weight-values-revert-ready'
$chosenCombo.SelectedItem='Desert'
Assert-HrsUx $launchButton.Enabled 'inactive-chosen-value-does-not-dirty-weighted'
Assert-HrsUx ((Get-HrsUxPolicyHash) -ceq $before) 'weight-editor-and-revert-do-not-write-policy'
Set-HrsSelectionMethod -Selection Any
$applyButton.PerformClick()
$any=Read-HrsConfiguredPolicy -GameRoot $gameRoot
$weights['Forest']=77; Update-HrsBiomePreview
Assert-HrsUx ($launchButton.Enabled -and (Test-HrsFormMatchesPolicy -Policy $any)) 'inactive-weights-do-not-dirty-any'
$standardRadio.Checked=$true; $applyButton.PerformClick()
$standard=Read-HrsConfiguredPolicy -GameRoot $gameRoot
$biomeProtectCheck.Checked=$true; Set-HrsSelectionMethod -Selection Chosen; $chosenCombo.SelectedItem='Snow'; $weights['Desert']=33; Update-HrsBiomePreview
Assert-HrsUx ($launchButton.Enabled -and (Test-HrsFormMatchesPolicy -Policy $standard)) 'inactive-random-preferences-do-not-dirty-standard'
Assert-HrsUx ($standard.revision -eq 3 -and $saved.revision -eq 1) 'only-explicit-applies-advance-revision'
'@
            }
            'SteamDirtyRefresh' {@'
$script:testSteamState='Closed'
$gameNameBox.Text='Callback Fixture 125'; $applyButton.PerformClick()
Assert-HrsUx (!$launchButton.Enabled -and !$script:launchBlockedUntilApply -and $script:nextAction.Text -match 'Steam') 'acknowledged-steam-closed-guidance'
Save-HrsUxCapture 'steam-closed'
$script:testSteamState='Running'; Invoke-HrsUxActivation
Assert-HrsUx $launchButton.Enabled 'steam-start-reactivation-ready'
Save-HrsUxCapture 'steam-open'
$gameNameBox.Text='Different Save'
Assert-HrsUx (!$launchButton.Enabled -and $script:applyBadge.Text -ceq 'Changes not applied.') 'dirty-before-reactivation'
Invoke-HrsUxActivation
Assert-HrsUx (!$launchButton.Enabled -and $script:applyBadge.Text -ceq 'Changes not applied.') 'reactivation-keeps-dirty-blocked'
$gameNameBox.Text='Callback Fixture 125'
Assert-HrsUx $launchButton.Enabled 'revert-with-steam-ready'
$script:testGameState='Running'; Invoke-HrsUxActivation
Assert-HrsUx (!$launchButton.Enabled -and !$applyButton.Enabled -and !$uninstallButton.Enabled) 'running-game-blocks-actions-on-activation'
$script:testGameState='Unknown'; $script:testSteamState='Unknown'; Invoke-HrsUxActivation
Assert-HrsUx (!$launchButton.Enabled -and !$applyButton.Enabled) 'unknown-process-state-blocks-actions'
'@
            }
            'PopupActivation' {@'
$gameNameBox.Text='Callback Fixture 125'; $randomRadio.Checked=$true; $applyButton.PerformClick()
Assert-HrsUx ($launchButton.Enabled -and !$script:launchBlockedUntilApply) 'launch-ready-only-after-popup-return'
'@
            }
            'FailedApplySticky' {@'
$gameNameBox.Text='Callback Fixture 125'; $applyButton.PerformClick()
$before=Get-HrsUxPolicyHash
Assert-HrsUx $launchButton.Enabled 'initial-success-ready-before-failure'
$gameNameBox.Text='Failed Attempt'; $applyButton.PerformClick()
Assert-HrsUx (!$launchButton.Enabled -and $script:launchBlockedUntilApply -and $status.Text -match 'Settings could not be applied') 'failed-apply-latched-with-error'
Save-HrsUxCapture 'apply-failed'
$errorAfterFailure=$status.Text
$gameNameBox.Text='Another Edit'; $randomRadio.Checked=$true; Invoke-HrsUxActivation
Assert-HrsUx (!$launchButton.Enabled -and $script:launchBlockedUntilApply -and $status.Text -ceq $errorAfterFailure) 'error-survives-edit-and-activation'
$gameNameBox.Text='Callback Fixture 125'; $standardRadio.Checked=$true; Invoke-HrsUxActivation
Assert-HrsUx (!$launchButton.Enabled -and $script:launchBlockedUntilApply -and $status.Text -ceq $errorAfterFailure) 'revert-does-not-clear-failure-latch'
Invoke-HrsFixtureClick $launchButton
Assert-HrsUx (![IO.File]::Exists((Join-Path $gameRoot 'launch-request.txt'))) 'failed-apply-direct-launch-blocked'
Assert-HrsUx ((Get-HrsUxPolicyHash) -ceq $before) 'failed-apply-restored-previous-policy-bytes'
'@
            }
            'VerifiedReopen' {@'
$saved=Read-HrsConfiguredPolicy -GameRoot $gameRoot
Assert-HrsUx ($gameNameBox.Text -ceq 'Saved Weighted 125' -and $randomRadio.Checked -and $biomeProtectCheck.Checked -and (Get-HrsFormSelection).Selection -ceq 'Weighted' -and ((Get-HrsFormSelection).Weights -join ',') -ceq '0,10,20,30,40') 'reopen-binds-exact-policy'
Assert-HrsUx (Test-HrsFormMatchesPolicy -Policy $saved) 'reopen-policy-matches-form'
Assert-HrsUx ($launchButton.Enabled -eq !$useDevCandidate) 'only-verified-reopen-ready-to-launch'
if($useDevCandidate){
    Assert-HrsUx ($script:nextAction.Text -match 'Apply Settings.*verify') 'dev-reopen-distinguishes-saved-from-ready'
} else {
    Assert-HrsUx ($script:applyBadge.Text -ceq 'Changes applied.') 'verified-reopen-confirms-ready'
}
Save-HrsUxCapture 'reopened'
$before=Get-HrsUxPolicyHash
Invoke-HrsUxActivation
Assert-HrsUx ((Get-HrsUxPolicyHash) -ceq $before) 'reopen-and-reactivation-are-read-only'
'@
            }
            'RevisionFreshness' {@'
$gameNameBox.Text='Callback Fixture 125'; $applyButton.PerformClick()
$saved=Read-HrsConfiguredPolicy -GameRoot $gameRoot
$observed=New-HrsResult -PolicyRevision $saved.revision -PolicyDigest $saved.policyDigest -Outcome COMPLETED -Reason RELOCATION_COMPLETED -MarkerState COMPLETED
$paths=Get-HrsBridgePaths -GameRoot $gameRoot
[IO.File]::WriteAllText($paths.ResultPath,(ConvertTo-HrsResultJson -Result $observed),(New-Object Text.UTF8Encoding($false)))
Update-HrsResultStatus
Assert-HrsUx ($resultStatus.Text -match 'Last start for current settings') 'result-current-before-revision-change'
Save-HrsUxCapture 'result-current'
$selectionArgs=Get-HrsSelectionArguments $saved
$next=New-HrsPolicy -Revision ([UInt64]($saved.revision+1)) -GameName $saved.gameName -Mode $saved.mode @selectionArgs
[void](Write-HrsPolicyFile -Path $paths.PolicyPath -AllowedRoot $paths.BridgeRoot -Policy $next)
Invoke-HrsUxActivation; Update-HrsResultStatus
Assert-HrsUx ((Test-HrsFormMatchesPolicy -Policy $next) -and $launchButton.Enabled) 'same-effective-settings-new-revision-stays-ready'
Assert-HrsUx ($resultStatus.Text -match 'earlier settings' -and $script:resultSummary.Text -notmatch 'completed|applied successfully') 'previous-result-stale-despite-matching-form'
Save-HrsUxCapture 'result-stale'
$runtimeUnavailable=New-HrsResult -PolicyRevision $next.revision -PolicyDigest $next.policyDigest -Outcome INCOMPATIBLE -Reason RUNTIME_LANE_UNCONFIRMED -MarkerState NOT_APPLICABLE
[IO.File]::WriteAllText($paths.ResultPath,(ConvertTo-HrsResultJson -Result $runtimeUnavailable),(New-Object Text.UTF8Encoding($false)))
Update-HrsResultStatus
Assert-HrsUx ($resultStatus.Text -match 'INCOMPATIBLE / RUNTIME_LANE_UNCONFIRMED' -and $script:resultSummary.Text -ceq 'Last start: HRS could not run. See Game details.') 'unconfirmed-runtime-does-not-blame-game-build'
Save-HrsUxCapture 'runtime-unconfirmed'
$buildMismatch=New-HrsResult -PolicyRevision $next.revision -PolicyDigest $next.policyDigest -Outcome INCOMPATIBLE -Reason BUILD_MISMATCH -MarkerState NOT_APPLICABLE
[IO.File]::WriteAllText($paths.ResultPath,(ConvertTo-HrsResultJson -Result $buildMismatch),(New-Object Text.UTF8Encoding($false)))
Update-HrsResultStatus
Assert-HrsUx ($script:resultSummary.Text -ceq 'Last start: HRS could not run with this game build.') 'confirmed-build-mismatch-summary'
[IO.File]::AppendAllText((Join-Path $paths.ReleaseRoot 'd0163.dll'),'fixture tamper')
$managerState=Get-HrsManagerStatePaths -ManagerRoot $managerRoot
[IO.File]::WriteAllText($managerState.RecoveryIndexPath,'{}',(New-Object Text.UTF8Encoding($false)))
Invoke-HrsUxActivation
Assert-HrsUx (!$launchButton.Enabled -and $script:managerInstallationReason -match 'Installed files need verification' -and $script:nextAction.Text -match 'Installed files need verification') 'installation-error-takes-priority-over-recovery-error'
Save-HrsUxCapture 'installation-and-recovery-errors'
'@
            }
            'UninstallState' {@'
$gameNameBox.Text='Callback Fixture 125'; $applyButton.PerformClick()
Assert-HrsUx $uninstallButton.Enabled 'owned-install-can-uninstall'
$uninstallButton.PerformClick()
Assert-HrsUx (!$launchButton.Enabled -and !$uninstallButton.Enabled) 'removal-clears-action-readiness'
Assert-HrsUx ($status.Text -ceq 'New Player Random Start uninstalled') 'removal-success-notice-visible'
Save-HrsUxCapture 'uninstalled'
Invoke-HrsUxActivation
Assert-HrsUx (!$launchButton.Enabled -and $applyButton.Enabled) 'reactivation-after-removal-requires-apply'
Assert-HrsUx ($status.Text -ceq 'New Player Random Start uninstalled') 'removal-notice-survives-reactivation'
$gameNameBox.Text='Another Save'
Assert-HrsUx (!$script:managerNotice -and $script:applyBadge.Text -ceq 'Changes not applied.' -and $applyButton.Enabled -and !$launchButton.Enabled) 'deliberate-edit-clears-removal-notice'
Invoke-HrsFixtureClick $launchButton
Assert-HrsUx (![IO.File]::Exists((Join-Path $gameRoot 'launch-request.txt'))) 'removed-install-direct-launch-blocked'
'@
            }
        } }
        $driver=@'
$script:testGameState='Closed'; $script:testSteamState='Running'
function Get-HrsProcessState { [pscustomobject]@{Game=$script:testGameState;Steam=$script:testSteamState;Reason='TEST_PROCESS_PROVIDER'} }
function Assert-HrsUx { param([bool]$Condition,[string]$Label) if(!$Condition){throw "UX_ASSERT_FAILED: $Label; status=$($status.Text); next=$($script:nextAction.Text); apply=$($applyButton.Enabled); launch=$($launchButton.Enabled); latch=$script:launchBlockedUntilApply"}; 'UX_ASSERT='+$Label }
function Invoke-HrsUxActivation { $activate=[Windows.Forms.Form].GetMethod('OnActivated',([Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic)); [void]$activate.Invoke($form,@([EventArgs]::Empty)); [Windows.Forms.Application]::DoEvents() }
function Get-HrsUxPolicyHash { $p=Get-HrsBridgePaths -GameRoot $gameRoot; if([IO.File]::Exists($p.PolicyPath)){return (Get-FileHash -LiteralPath $p.PolicyPath -Algorithm SHA256).Hash}; return '' }
function Get-HrsFixtureDescendants { param([Windows.Forms.Control]$Control) foreach($child in $Control.Controls){$child; Get-HrsFixtureDescendants $child} }
function Save-HrsUxCapture {
    param([string]$Label)
    $captureRoot=Join-Path $gameRoot 'ux-captures'
    [void][IO.Directory]::CreateDirectory($captureRoot)
    $previousScroll=$form.AutoScrollPosition
    try {
        foreach($view in @('top','actions')) {
            $form.AutoScrollPosition=New-Object Drawing.Point(0,0)
            if($view -eq 'actions'){$form.ScrollControlIntoView($script:resultSummary)}
            [Windows.Forms.Application]::DoEvents()
            $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height)
            try {
                $form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)))
                $bitmap.Save((Join-Path $captureRoot ($Label+'-'+$view+'.png')),[Drawing.Imaging.ImageFormat]::Png)
            } finally {$bitmap.Dispose()}
        }
    } finally {$form.AutoScrollPosition=New-Object Drawing.Point(-$previousScroll.X,-$previousScroll.Y)}
    'UX_CAPTURE='+$Label
}
$form.Show()
[Windows.Forms.Application]::DoEvents()
__UX_BODY__
'UX_SCENARIO_PASS=__UX_SCENARIO__'
'STATUS='+$status.Text
'BADGE_STATE='+$script:applyBadge.Text
'APPLY_ENABLED='+$applyButton.Enabled
'LAUNCH_ENABLED='+$launchButton.Enabled
'LAUNCH_BLOCKED='+$script:launchBlockedUntilApply
$form.Dispose()
'@
        $driver=$driver.Replace('__UX_BODY__',$uxBody).Replace('__UX_SCENARIO__',$scenario)
    }
    $clickDriver=@'
function Invoke-HrsFixtureClick {
    param([Windows.Forms.Button]$Button)
    $click=[Windows.Forms.Button].GetMethod('OnClick',([Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic))
    [void]$click.Invoke($Button,@([EventArgs]::Empty))
}
function Invoke-HrsFixtureActivation {
    $activate=[Windows.Forms.Form].GetMethod('OnActivated',([Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic))
    [void]$activate.Invoke($form,@([EventArgs]::Empty))
    [Windows.Forms.Application]::DoEvents()
}
'@
    $driver=$clickDriver+"`r`n"+$driver
    $edited=[regex]::Replace($edited,$tailPattern,[System.Text.RegularExpressions.MatchEvaluator]{param($m) $driver})
    $stagedManager=Join-Path $ui 'p0158.ps1'
    [IO.File]::WriteAllText($stagedManager,$edited,(New-Object Text.UTF8Encoding($false)))
    if($StorageProbe) {
        if($scenario -eq 'StorageLinkedRoot') {
            $linkedStage=Join-Path $scenarioRoot 'linked-stage'
            [void](New-Item -ItemType Junction -Path $linkedStage -Target $stage)
            $stagedManager=Join-Path $linkedStage 'dev/ui/p0158.ps1'
        } elseif($scenario -eq 'StorageLinkedState') {
            $stateTarget=Join-Path $scenarioRoot 'state-target'
            [void][IO.Directory]::CreateDirectory($stateTarget)
            [IO.File]::WriteAllText((Join-Path $stateTarget 'sentinel.txt'),'state target unchanged')
            [void](New-Item -ItemType Junction -Path (Join-Path $ui 'HistoricalRandomStart_State') -Target $stateTarget)
        } else {
            [IO.File]::WriteAllText((Join-Path $ui 'HistoricalRandomStart_State'),'state path is a file; preserve it')
        }
    }
    $previousPreference=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        $stdout=& powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File $stagedManager -SmokeTest -GameRootOverride $fixture 2>&1 | Out-String
        $exit=$LASTEXITCODE
    } finally { $ErrorActionPreference=$previousPreference }
    [IO.File]::WriteAllText((Join-Path $evidence ($Branch+'-'+$scenario+'-output.txt')),$stdout)
    $release=Join-Path $fixture 'Mods/BitWrecked_HistoricalRandomStart'
    $policy=Join-Path $release 'Bridge/policy.v2.json'
    $dll=Join-Path $release 'd0163.dll'
    $modInfo=Join-Path $release 'ModInfo.xml'
    $uxCapturePaths=@()
    if(($UxStateProbe -or $Round2Probe) -and (Test-Path -LiteralPath (Join-Path $fixture 'ux-captures') -PathType Container)) {
        $scenarioEvidence=Join-Path $evidence $scenario
        [void][IO.Directory]::CreateDirectory($scenarioEvidence)
        foreach($capture in @(Get-ChildItem -LiteralPath (Join-Path $fixture 'ux-captures') -Filter '*.png' -File)) {
            $destination=Join-Path $scenarioEvidence $capture.Name
            Copy-Item -LiteralPath $capture.FullName -Destination $destination
            $uxCapturePaths+=$destination
        }
    }
    $record=[ordered]@{
        branch=$Branch;scenario=$scenario;fixtureRoot=$fixture;stagedManager=$stagedManager
        sourceSha256=$fixtureSourceSha256
        sourceAfterSha256=(Get-FileHash $managerSource -Algorithm SHA256).Hash
        logoSha256=(Get-FileHash (Join-Path $devRoot 'ui/logo.ico') -Algorithm SHA256).Hash
        stagedSha256=(Get-FileHash $stagedManager -Algorithm SHA256).Hash
        deploymentModuleSha256=(Get-FileHash (Join-Path $devRoot 'src/launcher/m0162.psm1') -Algorithm SHA256).Hash
        stagedDeploymentModuleSha256=(Get-FileHash (Join-Path $launcher 'm0162.psm1') -Algorithm SHA256).Hash
        substitutions=@('Apply confirmation expression','final SmokeTest driver')+$(if($Branch -eq 'Verified'){@('DEV branch flag')}else{@()})+$(if($FailureProbe){@("throw at $FailurePoint",'suppress warning modal')}else{@()})+$(if($LaunchProbe){@('capture Start-Process','script process provider','suppress warning modal','optional installed DLL tamper','direct callback invocation despite disabled control')}else{@()})+$(if($ResultProbe){@('write bounded result fixture','second Apply and result-label driver')}else{@()})+$(if($UninstallProbe){@('Uninstall confirmation expression','suppress warning modal','optional unknown file or running process')}else{@()})+$(if($ApplyRejectProbe){@('invalid precondition','suppress warning modal','optional process provider')}else{@()})+$(if($UxStateProbe){@('controlled process provider','state transition assertions','capture Start-Process','suppress warning modal','optional second-Apply failure or reopening fixture')}else{@()})
        buildStub=$($Branch -eq 'DevDispatch');exitCode=$exit;output=$stdout.Trim()
        policyExists=[IO.File]::Exists($policy);dllExists=[IO.File]::Exists($dll);modInfoExists=[IO.File]::Exists($modInfo)
        policySha256=$(if([IO.File]::Exists($policy)){(Get-FileHash $policy -Algorithm SHA256).Hash}else{''})
        dllSha256=$(if([IO.File]::Exists($dll)){(Get-FileHash $dll -Algorithm SHA256).Hash}else{''})
        modInfoSha256=$(if([IO.File]::Exists($modInfo)){(Get-FileHash $modInfo -Algorithm SHA256).Hash}else{''})
        oldDllSha256=$(if($FailureProbe -or $Upgrade -or $MigrationMatrix){(Get-FileHash (Join-Path $oldPayloadSource 'd0163.dll') -Algorithm SHA256).Hash}else{''})
        oldModInfoSha256=$(if($FailureProbe -or $Upgrade -or $MigrationMatrix){(Get-FileHash (Join-Path $oldPayloadSource 'ModInfo.xml') -Algorithm SHA256).Hash}else{''})
        legacyPolicySha256=$(if([IO.File]::Exists((Join-Path $release 'Bridge/policy.v1.json'))){(Get-FileHash (Join-Path $release 'Bridge/policy.v1.json') -Algorithm SHA256).Hash}else{''})
        expectedLegacyPolicySha256=$(if($FailureProbe -or $Upgrade -or $MigrationMatrix){$legacyBeforeHash}else{''})
        policyJson=$(if([IO.File]::Exists($policy)){[IO.File]::ReadAllText($policy)}else{''})
        recoveryIndexExists=[IO.File]::Exists((Join-Path $stage 'dev/ui/HistoricalRandomStart_State/recovery-index.v1.json'))
        recoveryIndexJson=$(if([IO.File]::Exists((Join-Path $stage 'dev/ui/HistoricalRandomStart_State/recovery-index.v1.json'))){[IO.File]::ReadAllText((Join-Path $stage 'dev/ui/HistoricalRandomStart_State/recovery-index.v1.json'))}else{''})
        historyExists=[IO.File]::Exists((Join-Path $stage 'dev/ui/HistoricalRandomStart_State/history.v1.jsonl'))
        historyText=$(if([IO.File]::Exists((Join-Path $stage 'dev/ui/HistoricalRandomStart_State/history.v1.jsonl'))){[IO.File]::ReadAllText((Join-Path $stage 'dev/ui/HistoricalRandomStart_State/history.v1.jsonl'))}else{''})
        launchRequest=$(if([IO.File]::Exists((Join-Path $fixture 'launch-request.txt'))){[IO.File]::ReadAllText((Join-Path $fixture 'launch-request.txt'))}else{''})
        confirmationText=$(if([IO.File]::Exists((Join-Path $fixture 'confirmation-text.txt'))){[IO.File]::ReadAllText((Join-Path $fixture 'confirmation-text.txt'))}else{''})
        uxCapturePaths=$uxCapturePaths
        uxCaptureMethod=$(if($UxStateProbe -or $Round2Probe){'Native form DrawToBitmap after actual fixture UI events and callbacks, top/actions scroll positions; controlled process state and disposable installation with explicit result/recovery/payload fixtures; no live game or actual DPI certification.'}else{''})
        warningNotice=$(if([IO.File]::Exists((Join-Path $fixture 'warning-notice.txt'))){[IO.File]::ReadAllText((Join-Path $fixture 'warning-notice.txt'))}else{''})
        successNotice=$(if([IO.File]::Exists((Join-Path $fixture 'success-notice.txt'))){[IO.File]::ReadAllText((Join-Path $fixture 'success-notice.txt'))}else{''})
        successDuringPopup=$(if([IO.File]::Exists((Join-Path $fixture 'success-during-popup.txt'))){[IO.File]::ReadAllText((Join-Path $fixture 'success-during-popup.txt'))}else{''})
        saveSentinel=[IO.File]::ReadAllText((Join-Path $fixture 'Saves/TestSave/sentinel.txt'))
        unrelatedSentinel=[IO.File]::ReadAllText((Join-Path $fixture 'Mods/OtherMod/sentinel.txt'))
        footprintBefore=$footprintBefore
        footprintAfter=(@(Get-ChildItem -LiteralPath (Join-Path $fixture 'Mods') -Recurse -File | ForEach-Object {
            $_.FullName.Substring($fixture.Length+1)+'|'+(Get-FileHash $_.FullName -Algorithm SHA256).Hash
        }) -join ';')
    }
    [void]$records.Add([pscustomobject]$record)
    $records.ToArray() | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence 'observed-scenarios.json') -Encoding UTF8
    if($record.sourceSha256 -cne $record.sourceAfterSha256){throw "Source changed during $Branch/$scenario; preserve this attempt and rerun on stable source"}
    if($exit -ne 0){throw "$Branch/$scenario manager exited $exit : $stdout"}
    if(($UxStateProbe -or $Round2Probe) -and $stdout -notmatch ('UX_SCENARIO_PASS='+[regex]::Escape($scenario))) {throw "$Branch/$scenario UX state driver did not complete"}
    if(($UxStateProbe -or $Round2Probe) -and $record.launchRequest){throw "$Branch/$scenario requested a launch unexpectedly"}
    if($UxStateProbe -and $scenario -eq 'VerifiedReopen' -and $record.footprintBefore -cne $record.footprintAfter){throw "$Branch reopening modified the existing installation"}
    if($record.successNotice -and $record.successDuringPopup -cne 'launchEnabled=False;policyExists=True') {
        throw "$Branch/$scenario showed success before verified policy or while Launch was enabled"
    }
    if($scenario -eq 'Apply' -and ($record.successNotice -notmatch 'Settings applied and verified for: Callback Fixture 125' -or $record.successNotice -match 'Do not log out')) {
        throw "$Branch Standard Apply popup was missing or included the Random warning"
    }
    if($scenario -eq 'Cancel' -and $record.successNotice) { throw "$Branch canceled Apply showed success" }
    if($FailureProbe -and ($record.successNotice -or $stdout -notmatch 'LAUNCH_ENABLED=False' -or $stdout -notmatch 'LAUNCH_BLOCKED=True')) {
        throw "$Branch failed Apply showed success or left Launch available: $stdout"
    }
    if($SelectionProbe -and ($record.successNotice -notmatch 'Do not log out until your first trader is assigned' -or $record.successNotice -notmatch 'Journey to Settlement trader marker')) {
        throw "$Branch Random Apply popup lacked trader-session notice"
    }
    if($SteamRefreshProbe -and ($stdout -notmatch 'LAUNCH_BEFORE_STEAM=False' -or $stdout -notmatch 'LAUNCH_AFTER_STEAM=True' -or $record.successNotice -notmatch 'Do not log out')) {
        throw "$Branch Steam refresh failed after Random Apply: $stdout"
    }
    if($StorageProbe) {
        $record.substitutions += @('suppress warning modal','manager storage path fixture')
        if($record.footprintBefore -cne $record.footprintAfter -or $record.recoveryIndexExists -or $record.historyExists -or
            $stdout -notmatch 'HRS cannot save recovery settings in this folder' -or
            $stdout -notmatch 'No game files were changed' -or $stdout -match 'STATUS=Ready') {
            throw "$scenario did not block before installed/recovery mutation: $stdout"
        }
        if($scenario -eq 'StorageLinkedState' -and
            ([IO.File]::ReadAllText((Join-Path $stateTarget 'sentinel.txt')) -cne 'state target unchanged' -or
             @(Get-ChildItem -LiteralPath $stateTarget).Count -ne 1)) {throw 'Linked state target changed'}
        if($scenario -eq 'StorageUnavailable' -and
            [IO.File]::ReadAllText((Join-Path $ui 'HistoricalRandomStart_State')) -cne 'state path is a file; preserve it') {throw 'Unavailable state target changed'}
    }
    if($scenario -eq 'Cancel' -and ($record.policyExists -or $record.dllExists -or $record.modInfoExists -or $record.recoveryIndexExists -or $record.historyExists -or $stdout -notmatch 'Settings canceled')){throw "$Branch cancel mutated fixture or lacked cancel status"}
    if($scenario -eq 'Apply' -and (!$record.policyExists -or !$record.dllExists -or !$record.modInfoExists -or $stdout -notmatch 'Changes applied\.')){throw "$Branch Apply incomplete: $stdout"}
    if($scenario -eq 'Apply' -and (-not $record.recoveryIndexExists -or $record.recoveryIndexJson -notmatch 'APPLY_SUCCEEDED')){throw "$Branch Apply lacked recovery snapshot: $stdout"}
    if($Upgrade) {
        $readback=$record.policyJson | ConvertFrom-Json
        if(!$record.policyExists -or $record.legacyPolicySha256 -or
            $record.dllSha256 -cne (Get-FileHash (Join-Path $payloadSource 'd0163.dll') -Algorithm SHA256).Hash -or
            $readback.schema -cne 'hrs-policy/v2' -or $readback.revision -ne 2 -or
            $readback.gameName -cne 'Callback Fixture 125') {
            throw "Upgrade/migration invalid: $stdout"
        }
    }
    if($MigrationMatrix) {
        $saved=$record.policyJson|ConvertFrom-Json
        $expectedMode=$scenario.Substring('Migrate'.Length)
        $index=$record.recoveryIndexJson|ConvertFrom-Json
        if($saved.schema -cne 'hrs-policy/v2' -or $saved.revision -ne 2 -or $saved.gameName -cne 'Fresh Start' -or
            $saved.mode -cne $expectedMode -or $saved.selection -cne 'Any' -or $record.legacyPolicySha256 -or
            $record.dllSha256 -cne (Get-FileHash (Join-Path $payloadSource 'd0163.dll') -Algorithm SHA256).Hash -or
            @($index.attempts).Count -ne 2 -or $record.saveSentinel -cne 'save sentinel' -or
            $record.unrelatedSentinel -cne 'unrelated sentinel' -or $record.launchRequest) {
            throw "$scenario did not preserve v1 intent during migration: $stdout"
        }
    }
    if($FailureProbe -and $stdout -notmatch ('INJECTED_'+$FailurePoint.ToUpperInvariant())){throw "Failure probe did not reach injected point: $stdout"}
    if($FailureProbe -and (-not $record.historyExists -or $record.historyText -notmatch '"outcome":"Failed"' -or $record.historyText -notmatch '"reason":"APPLY_FAILED"' -or $record.recoveryIndexExists)){throw "Confirmed failure lacked Failed history or wrote recovery snapshot: $stdout"}
    if($FailureProbe -and ($stdout -match 'STATUS=Ready for' -or $record.launchRequest)){throw "Failure probe claimed Ready or requested launch: $stdout"}
    if($FailureProbe -and -not $RecoveryFail -and ($record.dllSha256 -cne $record.oldDllSha256 -or
        $record.modInfoSha256 -cne $record.oldModInfoSha256 -or
        $record.legacyPolicySha256 -cne $record.expectedLegacyPolicySha256 -or
        $record.policyExists -or $stdout -notmatch 'APPLY_ROLLED_BACK')) {
        throw "Failure probe left a mixed installation: $stdout"
    }
    if($RecoveryFail) {
        $match=[regex]::Match($stdout,'APPLY_RECOVERY_FAILED:.*?backup: (?<path>[^;]+); restore: INJECTED_RESTORE_FAILURE')
        if(-not $match.Success -or $stdout -match 'Ready for Callback Fixture 125'){throw "Recovery failure was not blocked: $stdout"}
        $retained=$match.Groups['path'].Value
        if(-not [IO.Directory]::Exists($retained) -or
            (Get-FileHash (Join-Path $retained '0.bin') -Algorithm SHA256).Hash -cne $record.oldDllSha256 -or
            (Get-FileHash (Join-Path $retained '1.bin') -Algorithm SHA256).Hash -cne $record.oldModInfoSha256 -or
            (Get-FileHash (Join-Path $retained '3.bin') -Algorithm SHA256).Hash -cne $record.expectedLegacyPolicySha256) {
            throw "Recovery failure did not preserve original bytes: $stdout"
        }
        $record | Add-Member -NotePropertyName retainedBackupPath -NotePropertyValue $retained
    }
    if($LaunchProbe -and @('Launch','StaleResult','ChangedAssembly','UntestedApply') -ccontains $scenario -and $record.launchRequest -cne ((Join-Path $fixture '7DaysToDie.exe')+'|'+$fixture)){throw "$scenario valid launch request not captured: $stdout"}
    if($LaunchProbe -and @('Launch','StaleResult','ChangedAssembly','UntestedApply') -cnotcontains $scenario -and $record.launchRequest){throw "$scenario requested launch: $stdout"}
    if($LaunchProbe -and @('Launch','StaleResult','ChangedAssembly','UntestedApply') -cnotcontains $scenario -and $stdout -notmatch 'STATUS=Launch blocked:'){throw "$scenario did not show a blocked launch state: $stdout"}
    if($LaunchProbe -and $scenario -in @('ChangedAssembly','UntestedApply') -and
        $stdout -notmatch 'Launching game - untested build; HRS will attempt compatible hooks') {
        throw "Untested build did not launch with the compatibility notice: $stdout"
    }
    if($LaunchProbe -and $scenario -eq 'UntestedApply' -and
        [IO.File]::ReadAllText((Join-Path $fixture 'confirmation-notice.txt')) -notmatch 'Untested game build') {throw 'Untested Apply lacked confirmation notice'}
    if($LaunchProbe -and $scenario -eq 'BeforeApply' -and ($stdout -notmatch 'Apply Settings before launching' -or $record.policyExists -or $record.dllExists)) {throw 'Launch before Apply gave wrong guidance or installed files'}
    if($LaunchProbe -and $scenario -eq 'StaleResult' -and $stdout -notmatch 'RESULT_LABEL=Last start belongs to earlier settings'){throw 'Stale success was presented as current'}
    if($ResultProbe -and ($stdout -notmatch 'RESULT_CURRENT=Last start for current settings: COMPLETED / RELOCATION_COMPLETED' -or
        $stdout -notmatch 'RESULT_SELECTED=Last start for current settings: RESERVED / PLACEMENT_DEFERRED' -or
        $stdout -notmatch 'RESULT_FAILED=Last start for current settings: FAILED / PLACEMENT_FAILED' -or
        $stdout -notmatch 'RESULT_WRONG_DIGEST=Last start belongs to earlier settings' -or
        $stdout -notmatch 'RESULT_WRONG_REVISION=Last start belongs to earlier settings' -or
        $stdout -notmatch 'RESULT_STALE=Last start belongs to earlier settings')) {
        throw "Current/stale result was not distinguished: $stdout"
    }
    if($ResultProbe) {
        $second=$record.policyJson|ConvertFrom-Json
        $index=$record.recoveryIndexJson|ConvertFrom-Json
        if($second.revision -ne 2 -or @($index.attempts).Count -ne 2){throw "Repeated Apply did not advance once: $stdout"}
    }
    if($UninstallProbe) {
        if($scenario -eq 'UninstallOwned' -or $scenario -eq 'UninstallV1') {
            if($record.dllExists -or $record.modInfoExists -or $record.policyExists -or $stdout -notmatch 'UNINSTALL_STATUS=New Player Random Start uninstalled') {throw "Owned uninstall incomplete: $stdout"}
        } elseif(-not $record.dllExists -or -not $record.modInfoExists -or -not $record.policyExists) {
            throw "$scenario removed owned files: $stdout"
        }
        if($scenario -eq 'UninstallCancel' -and $stdout -notmatch 'Uninstall canceled') {throw 'Cancel not observed'}
        if($scenario -eq 'UninstallUnknown' -and $stdout -notmatch 'REMOVAL_UNKNOWN_FILE') {throw 'Unknown file was not blocked'}
        if($scenario -in @('UninstallRunning','UninstallProcessUnknown') -and $stdout -notmatch 'Close 7 Days to Die') {throw 'Running or unconfirmed game was not blocked'}
    }
    if($ApplyRejectProbe) {
        if($record.footprintBefore -cne $record.footprintAfter -or $record.recoveryIndexExists) {
            throw "$scenario changed installed or recovery bytes: $stdout"
        }
        $expectedRejection=switch($scenario) {
            'InvalidName' { 'Use a valid save name' }
            'ZeroWeights' { 'APPLY_ENABLED=False' }
            'GameRunning' { 'Close 7 Days to Die' }
            'ProcessUnknown' { 'Game state unavailable' }
            'MalformedV2' { 'POLICY_JSON_SHAPE' }
            'TamperedDigest' { 'POLICY_REJECTED' }
            'WrongFilenameSchema' { 'POLICY_FILENAME_SCHEMA' }
            'PolicyBom' { 'POLICY_BOM_FORBIDDEN' }
            'PolicyNoncanonical' { 'POLICY_JSON_SHAPE' }
            'AmbiguousPolicy' { 'POLICY_AMBIGUOUS' }
            'UnknownReleaseFile' { 'DEPLOYMENT_UNKNOWN_FILE' }
            'UnknownReleaseDirectory' { 'DEPLOYMENT_UNKNOWN_DIRECTORY' }
            'ReparseReleaseDirectory' { 'DEPLOYMENT_REPARSE_POINT' }
            'UnknownBridgeEntry' { 'BRIDGE_UNKNOWN_ENTRY' }
            'ExhaustedRevision' { 'Policy revision is exhausted' }
            'TamperedDll' { 'Verified QA runtime hash mismatch' }
            'TamperedModInfo' { 'Verified QA ModInfo hash mismatch' }
            'ChangedAssembly' { 'Game build hash mismatch' }
        }
        if(-not $expectedRejection -or $stdout -notmatch [regex]::Escape($expectedRejection)) {
            throw "$scenario did not show its expected rejection: $stdout"
        }
    }
    if($record.saveSentinel -cne 'save sentinel' -or $record.unrelatedSentinel -cne 'unrelated sentinel'){throw 'Sentinel changed'}
    if($StartupProbe) {
        if($record.footprintBefore -cne $record.footprintAfter -or $record.recoveryIndexExists){throw "$scenario mutated fixture during startup"}
        $expected=switch($scenario) {
            'StartupFresh' { @('STARTUP_NAME=','STARTUP_MODE=Standard','STARTUP_SELECTION=Any') }
            'StartupV2' { @('STARTUP_NAME=Saved Weighted 125','STARTUP_MODE=RandomSafe','STARTUP_SELECTION=Weighted','STARTUP_WEIGHTS=0,10,20,30,40') }
            'StartupV1' { @('STARTUP_NAME=Fresh Start','STARTUP_MODE=Standard','STARTUP_SELECTION=Any') }
            'StartupFromEditor' { @('STARTUP_NAME=Callback Fixture 125','STARTUP_MODE=Random','STARTUP_SELECTION=Weighted','STARTUP_WEIGHTS=0,0,0,0,100') }
            'StartupMalformed' { @('STARTUP_STATUS=Settings blocked:','STARTUP_APPLY_ENABLED=False') }
        }
        foreach($line in $expected){if($stdout -notmatch [regex]::Escape($line)){throw "$scenario startup readback mismatch: $stdout"}}
    }
    if($SelectionProbe) {
        if(-not $record.policyExists -or -not $record.recoveryIndexExists -or $stdout -notmatch 'Changes applied\.'){throw "$scenario Apply incomplete: $stdout"}
        $saved=$record.policyJson | ConvertFrom-Json
        $wantMode=if($scenario -in @('Any','WeightedMixed')){'Random'}else{'RandomSafe'}
        $wantSelection=if($scenario -eq 'Any'){'Any'}elseif($scenario -like 'Chosen*'){'Chosen'}else{'Weighted'}
        $wantBiome=switch($scenario){'ChosenForest'{3};'ChosenBurnt'{9};'ChosenDesert'{5};'ChosenSnow'{1};'ChosenWasteland'{8};default{0}}
        $wantWeights=if($scenario -eq 'WeightedMixed'){'0,10,20,30,40'}elseif($scenario -eq 'WeightedSingle'){'0,0,100,0,0'}else{'0,0,0,0,0'}
        $actualWeights=@($saved.forest,$saved.burntForest,$saved.desert,$saved.snow,$saved.wasteland) -join ','
        if($saved.schema -cne 'hrs-policy/v2' -or $saved.revision -ne 1 -or $saved.mode -cne $wantMode -or $saved.selection -cne $wantSelection -or $saved.chosenBiome -ne $wantBiome -or $actualWeights -cne $wantWeights){throw "$scenario serialized wrong selection: $($record.policyJson)"}
        Import-Module (Join-Path $devRoot 'src/launcher/m0161.psm1') -Force
        $validated=Read-HrsPolicyFile -Path (Join-Path $release 'Bridge/policy.v2.json')
        if($validated.policyDigest -cne $saved.policyDigest){throw "$scenario digest mismatch"}
    }
    if($EditorProbe) {
        if(-not $record.policyExists -or -not $record.recoveryIndexExists){throw "$scenario did not Apply"}
        $saved=$record.policyJson|ConvertFrom-Json
        $want=if($scenario -eq 'EditorSave'){'0,0,0,0,100'}else{'10,20,20,25,25'}
        $actual=@($saved.forest,$saved.burntForest,$saved.desert,$saved.snow,$saved.wasteland) -join ','
        if($saved.mode -cne 'Random' -or $saved.selection -cne 'Weighted' -or $actual -cne $want){throw "$scenario editor policy mismatch: $($record.policyJson)"}
    }
}
$suffix=if($FailureProbe){'-failure-'+$FailurePoint.ToLowerInvariant()+$(if($RecoveryFail){'-recoveryfailed'}else{''})}elseif($LaunchProbe){'-launch'}elseif($Upgrade){'-upgrade'}elseif($MigrationMatrix){'-migration-matrix'}elseif($ResultProbe){'-result'}elseif($UninstallProbe){'-uninstall'}elseif($ApplyRejectProbe){'-apply-reject'}elseif($StartupProbe){if($StartupSavedPolicyPath){'-startup-from-editor'}else{'-startup'}}elseif($SelectionProbe){'-selection'}elseif($SteamRefreshProbe){'-steam-refresh'}elseif($EditorProbe){'-editor'}else{''}
if($StorageProbe){$suffix='-storage'}
if($UxStateProbe){$suffix='-ux-state'}
if($Round2Probe){$suffix='-round2'}
$resultPath=Join-Path $evidence ('callback-'+$Branch.ToLowerInvariant()+$suffix+'.json')
$records.ToArray() | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resultPath -Encoding UTF8
if($FailureProbe){
    $probe=$records[0]
    if($RecoveryFail){"PROBE: $Branch $FailurePoint restore failure blocked and original backup retained; evidence $resultPath"}
    else{"PROBE: $Branch $FailurePoint; old DLL restored=$($probe.dllSha256 -ceq $probe.oldDllSha256); old ModInfo preserved=$($probe.modInfoSha256 -ceq $probe.oldModInfoSha256); v1 preserved=$($probe.legacyPolicySha256 -ceq $probe.expectedLegacyPolicySha256); evidence $resultPath"}
} elseif($LaunchProbe) {
    "PASS: $Branch four valid/untested launches captured and twelve invalid/unapplied launches blocked; evidence $resultPath"
} elseif($Upgrade) {
    "PASS: $Branch owned 1.2.4 upgrade and v1 to v2 migration; evidence $resultPath"
} elseif($MigrationMatrix) {
    "PASS: $Branch migrated Standard/Random/RandomSafe v1 with saved intent intact; evidence $resultPath"
} elseif($ResultProbe) {
    "PASS: $Branch manager labels current result and rejects stale success; evidence $resultPath"
} elseif($UninstallProbe) {
    "PASS: $Branch owned Uninstall plus cancel/unknown/running refusals; evidence $resultPath"
} elseif($ApplyRejectProbe) {
    "PASS: $Branch rejected $($records.Count) invalid Apply fixtures without mutation; evidence $resultPath"
} elseif($StorageProbe) {
    "PASS: $Branch rejected $($records.Count) linked/unavailable storage fixtures before game mutation; evidence $resultPath"
} elseif($StartupProbe) {
    if($StartupSavedPolicyPath){"PASS: $Branch reopened editor-saved policy with exact values; evidence $resultPath"}
    else{"PASS: $Branch startup fresh, v2, v1, and malformed readback; evidence $resultPath"}
} elseif($SelectionProbe) {
    "PASS: $Branch eight Any/Chosen/Weighted selection callbacks; evidence $resultPath"
} elseif($SteamRefreshProbe) {
    "PASS: $Branch Steam-closed Apply and activation refresh; evidence $resultPath"
} elseif($EditorProbe) {
    "PASS: $Branch weight-editor save/cancel through Apply; evidence $resultPath"
} elseif($UxStateProbe) {
    "PASS: $Branch $($records.Count) UX state scenarios, dirty/revert and fail-closed actions; evidence $resultPath"
} elseif($Round2Probe) {
    "PASS: $Branch $($records.Count) native UX round-two scenarios, selection/guard/copy/ownership/help/non-OK acknowledgement; evidence $resultPath"
} else {
    "PASS: $Branch cancel and Apply callback in disposable fixture; evidence $resultPath"
}
