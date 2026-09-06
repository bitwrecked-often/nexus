[CmdletBinding()]
param([string] $LaneRoot = '')

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($LaneRoot)) {
    # The fixed-selector predecessor is a permanent negative regression fixture.
    $LaneRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'hrs_1.0.1'
}
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
$passed = 0

function Assert-HrsQa {
    param([bool] $Condition, [string] $Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:passed++
    Write-Output "PASS: $Name"
}

$scripts = Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object { $_.Extension -in @('.ps1','.psm1') }
foreach ($script in $scripts) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors)
    Assert-HrsQa ($errors.Count -eq 0) "$($script.Name) parses"
}

$validation = Test-HrsQaRelease -LaneRoot $LaneRoot
Assert-HrsQa (@($validation.findings | Where-Object code -eq 'ARTIFACT_IDENTITY' | Where-Object severity -eq 'Pass').Count -eq 1) 'verified artifacts match release record'
Assert-HrsQa (@($validation.findings | Where-Object code -eq 'MODINFO_VERSION' | Where-Object severity -eq 'Pass').Count -eq 1) 'ModInfo version matches release record'
Assert-HrsQa (@($validation.findings | Where-Object code -eq 'RUNTIME_LOG_IDENTITY' | Where-Object severity -eq 'Pass').Count -eq 1) 'runtime identity matches release record'
Assert-HrsQa (@($validation.findings | Where-Object code -eq 'TRADER_CONTRACT' | Where-Object severity -eq 'Pass').Count -eq 1) 'trader and starter-quest markers remain present'
Assert-HrsQa (@($validation.findings | Where-Object code -eq 'SPAWN_SELECTOR_FIXED' | Where-Object severity -eq 'Error').Count -eq 1) 'readiness gate detects fixed one-point selector'

$contract = Read-HrsQaJson -Path (Get-HrsQaLanePaths -LaneRoot $LaneRoot).ContractPath
Assert-HrsQa (@($contract.requiredCases).Count -eq 9) 'QA contract has all required cases'

$tempRoot = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), 'hrs-qa-tools-' + [guid]::NewGuid().ToString('N'))
[void][System.IO.Directory]::CreateDirectory($tempRoot)
try {
    $cycleLane = Join-Path $tempRoot 'hrs_1.0.2'
    $cyclePayload = Join-Path $cycleLane 'dev\verified\main'
    [void][System.IO.Directory]::CreateDirectory($cyclePayload)
    $sourcePayload = Join-Path ([System.IO.Path]::GetFullPath($LaneRoot)) 'dev\verified\main'
    [System.IO.File]::Copy((Join-Path $sourcePayload 'd0163.dll'), (Join-Path $cyclePayload 'd0163.dll'), $false)
    [System.IO.File]::Copy((Join-Path $sourcePayload 'ModInfo.xml'), (Join-Path $cyclePayload 'ModInfo.xml'), $false)
    $cycleModInfo = Join-Path $cyclePayload 'ModInfo.xml'
    $cycleModInfoText = [System.IO.File]::ReadAllText($cycleModInfo).Replace('1.0.1', '1.0.2')
    [System.IO.File]::WriteAllText($cycleModInfo, $cycleModInfoText, (New-Object System.Text.UTF8Encoding($false)))
    $newCycleScript = Join-Path $PSScriptRoot 'New-HrsCycle.ps1'
    [void](& $newCycleScript -LaneRoot $cycleLane -Version 1.0.2 -BuildId r102 -SourceCommit ('a' * 40))
    $newRelease = Read-HrsQaJson -Path (Join-Path $cycleLane 'dev\qa\rel.json')
    $newContract = Read-HrsQaJson -Path (Join-Path $cycleLane 'dev\qa\cases.json')
    Assert-HrsQa ([string]$newRelease.version -ceq '1.0.2' -and [string]$newRelease.buildId -ceq 'r102') 'new cycle initializes release identity'
    Assert-HrsQa ([string]$newContract.releaseVersion -ceq '1.0.2') 'new cycle initializes QA contract identity'
    Assert-HrsQa ([string]$newRelease.artifacts[0].sha256 -ceq (Get-HrsQaSha256 -Path (Join-Path $cyclePayload 'd0163.dll'))) 'new cycle computes artifact identity'

    $startScript = Join-Path $PSScriptRoot 'Start-HrsQaRun.ps1'
    $qaStartBlocked = $false
    try { [void](& $startScript -CaseId HRS-QA-001 -Mode NotApplicable -LaneRoot $LaneRoot -RunRoot $tempRoot) }
    catch { $qaStartBlocked = $_.Exception.Message -like 'HRS_RELEASE_NOT_READY_FOR_QA*' }
    Assert-HrsQa $qaStartBlocked 'QA run start is blocked while readiness errors remain'
    $startOutput = @(& $startScript -CaseId HRS-QA-001 -Mode NotApplicable -LaneRoot $LaneRoot -RunRoot $tempRoot -AllowDevelopmentGap)
    $runPathLine = @($startOutput | Where-Object { $_ -like 'Evidence path:*' })
    Assert-HrsQa ($runPathLine.Count -eq 1) 'DEV evidence run starts'
    $runPath = ([string]$runPathLine[0]).Substring('Evidence path:'.Length).Trim()
    Assert-HrsQa ([System.IO.File]::Exists((Join-Path $runPath 'session.local.json'))) 'local session is retained outside export'

    $observationScript = Join-Path $PSScriptRoot 'Record-HrsQaObservation.ps1'
    [void](& $observationScript -RunPath $runPath -SelectedPointId NG01 -FinalX -1528 -FinalY 74 -FinalZ 1700 -LandingResult Safe -SelectedTraderPlacement TP02 -QuestDestinationResult Confirmed -StarterQuestProgression Works)
    $observation = Read-HrsQaJson -Path (Join-Path $runPath 'qa-observation.json')
    Assert-HrsQa ([string]$observation.expectedNearestTraderPlacement -ceq 'TP02' -and $observation.nearestTraderMatches -eq $true) 'observation calculates and confirms nearest trader'

    $exportScript = Join-Path $PSScriptRoot 'Export-HrsQaRun.ps1'
    [void](& $exportScript -RunPath $runPath -Outcome Pass -Kind DEV -Notes 'Automated tooling test.')
    $zipPath = $runPath + '.zip'
    Assert-HrsQa ([System.IO.File]::Exists($zipPath)) 'evidence ZIP is created'

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try { $entryNames = @($zip.Entries | ForEach-Object { $_.FullName }) }
    finally { $zip.Dispose() }
    Assert-HrsQa ($entryNames -cnotcontains 'session.local.json') 'private local session is excluded from ZIP'
    Assert-HrsQa ($entryNames -ccontains 'release-validation.json') 'release validation is included'
    Assert-HrsQa ($entryNames -ccontains 'evidence-manifest.json') 'evidence manifest is included'
    Assert-HrsQa ($entryNames -ccontains 'qa-result.json') 'QA result is included'
    Assert-HrsQa ($entryNames -ccontains 'qa-observation.json') 'bounded QA observation is included'

    $completeScript = Join-Path $PSScriptRoot 'Complete-HrsQaCycle.ps1'
    [void](& $completeScript -Decision Reject -LaneRoot $LaneRoot -RunRoot $tempRoot -ApproverRole ReleaseOwner -Notes 'Automated tooling test rejection.')
    $decisionFiles = @(Get-ChildItem -LiteralPath (Join-Path $tempRoot '1.0.1') -File -Filter 'cycle-*.json')
    Assert-HrsQa ($decisionFiles.Count -eq 1) 'cycle rejection record is created'
    $approvalBlocked = $false
    try { [void](& $completeScript -Decision Approve -LaneRoot $LaneRoot -RunRoot $tempRoot -ApproverRole ReleaseOwner) }
    catch { $approvalBlocked = $_.Exception.Message -like 'HRS_QA_APPROVAL_BLOCKED*' }
    Assert-HrsQa $approvalBlocked 'cycle approval is blocked by readiness and missing QA cases'
}
finally {
    $resolvedTemp = [System.IO.Path]::GetFullPath($tempRoot)
    $systemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedTemp.StartsWith($systemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and
        [System.IO.Directory]::Exists($resolvedTemp)) {
        [System.IO.Directory]::Delete($resolvedTemp, $true)
    }
}

Write-Output "HRS QA-cycle tooling tests passed: $passed/$passed"
