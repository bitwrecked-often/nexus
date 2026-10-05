[CmdletBinding()]
param()
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('hrs acceptance '+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($fixture)
$passed=0
function Check([bool]$Ok,[string]$Name) {
    if (-not $Ok) { throw "FAIL: $Name" }
    $script:passed++; Write-Output "PASS: $Name"
}
function Reject([scriptblock]$Action,[string]$Name) {
    $failed=$false
    try { & $Action | Out-Null } catch { $failed=$true }
    Check $failed $Name
}
$toolRoot=Join-Path $fixture 'tools'
[void][IO.Directory]::CreateDirectory($toolRoot)
Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object { $_.Extension -in @('.ps1','.psm1') } | Copy-Item -Destination $toolRoot
Import-Module (Join-Path $toolRoot 'HrsQaTools.psm1') -Force
Check ((Get-HrsCustomerFolder '1.2.4') -ceq 'HistoricalRandomStart_1.2.4') 'customer folder follows release version'
Reject { Get-HrsCustomerFolder '../1.2.4' } 'unsafe customer version rejected'
Write-HrsQaJson (Join-Path $toolRoot 'candidate-registry.json') ([pscustomobject]@{schema='hrs-candidate-registry/v1';records=@()})
$lane=Join-Path $fixture 'lane'
$sourceLane=Join-Path $repo 'hrs_1.2.3'
$release=Read-HrsQaJson (Join-Path $sourceLane 'dev/qa/rel.json')
$copies=@(Get-HrsCustomerFiles)
$copies+=@($release.sourceSnapshot.sourceHashes | ForEach-Object { 'dev/src/runtime/main/'+$_.path })
foreach ($relative in $copies) {
    $target=Resolve-HrsContainedFile $lane $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    [IO.File]::Copy((Join-Path $sourceLane $relative),$target,$false)
}
$id='1.2.3-qa.991'
$build=Join-Path $lane ('dev/builds/'+$id+'/build-record.json')
[void][IO.Directory]::CreateDirectory((Split-Path -Parent $build))
[IO.File]::Copy((Join-Path $sourceLane $release.build.recordPath),$build,$false)
& (Join-Path $toolRoot 'New-Hrs123Contract.ps1') -LaneRoot $lane -CandidateId $id -SourceCommit $release.sourceCommit | Out-Null
$zip=Join-Path $fixture 'exports/candidate.zip'
$export=Join-Path $toolRoot 'Export-HrsCandidate.ps1'
$buildSaved=[IO.File]::ReadAllBytes($build)
$buildValue=Read-HrsQaJson $build
$buildValue.sourceHashes[0].sha256='0'*64
Write-HrsQaJson $build $buildValue
Reject { & $export -LaneRoot $lane -CandidateId $id -OutputPath $zip } 'build source mismatch rejected'
[IO.File]::WriteAllBytes($build,$buildSaved)
$sourceFile=Join-Path $lane 'dev/src/runtime/main/c0140.cs'
$sourceSaved=[IO.File]::ReadAllBytes($sourceFile)
[IO.File]::AppendAllText($sourceFile,'// drift')
Reject { & $export -LaneRoot $lane -CandidateId $id -OutputPath $zip } 'actual source drift rejected'
[IO.File]::WriteAllBytes($sourceFile,$sourceSaved)
& $export -LaneRoot $lane -CandidateId $id -OutputPath $zip | Out-Null
Check (Test-Path -LiteralPath $zip) 'candidate exported with companion'
Reject { & $export -LaneRoot $lane -CandidateId $id -OutputPath (Join-Path $fixture 'different directory/candidate.zip') } 'reuse rejected in different output directory'
$record=Get-HrsRegistryRecord $id
$valid=Test-HrsCandidateArchive $zip $id $record.releaseRecordSha256 $record.contractSha256
Check $valid.valid 'registered archive and exact allowlist verify'
# A disposable 1.2.4 package exercises the version-derived ZIP verifier without
# claiming that the real 1.2.4 source has passed the release gate.
$syntheticId='1.2.4-qa.991'
$syntheticFolder=Get-HrsCustomerFolder '1.2.4'
$syntheticCustomer=Join-Path $fixture ('synthetic 124 stage/'+$syntheticFolder)
foreach ($relative in Get-HrsCustomerFiles) {
    $target=Resolve-HrsContainedFile $syntheticCustomer $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    [IO.File]::Copy((Resolve-HrsContainedFile $lane $relative),$target,$false)
}
$syntheticFiles=@(Get-HrsCustomerFiles | ForEach-Object {
    $file=Resolve-HrsContainedFile $syntheticCustomer $_
    [pscustomobject]@{path=$_;bytes=(Get-Item -LiteralPath $file).Length;sha256=(Get-HrsQaSha256 $file)}
})
$syntheticManifest=Join-Path $syntheticCustomer 'package-manifest.json'
Write-HrsQaJson $syntheticManifest ([pscustomobject]@{schema='hrs-candidate-package-manifest/v1';candidateId=$syntheticId;files=$syntheticFiles})
$syntheticZip=Join-Path $fixture 'synthetic-124.zip'
Compress-Archive -LiteralPath $syntheticCustomer -DestinationPath $syntheticZip
$syntheticReceipt=Read-HrsQaJson ($zip+'.receipt.json')
$syntheticReceipt.candidateId=$syntheticId
$syntheticReceipt.releaseVersion='1.2.4'
$syntheticReceipt.packageManifestSha256=Get-HrsQaSha256 $syntheticManifest
$syntheticReceipt.archiveSha256=Get-HrsQaSha256 $syntheticZip
Write-HrsQaJson ($syntheticZip+'.receipt.json') $syntheticReceipt
$registry=Read-HrsQaJson (Join-Path $toolRoot 'candidate-registry.json')
$registry.records=@($registry.records)+@([pscustomobject]@{
    candidateId=$syntheticId;status='synthetic-test';archiveSha256=$syntheticReceipt.archiveSha256
    receiptSha256=(Get-HrsQaSha256 ($syntheticZip+'.receipt.json'))
    releaseRecordSha256=$record.releaseRecordSha256;contractSha256=$record.contractSha256
})
Write-HrsQaJson (Join-Path $toolRoot 'candidate-registry.json') $registry
Check (Test-HrsCandidateArchive $syntheticZip $syntheticId $record.releaseRecordSha256 $record.contractSha256).valid '1.2.4 package folder and hashes verify'
Check (-not (Test-HrsCandidateArchive $syntheticZip $id $record.releaseRecordSha256 $record.contractSha256).valid) 'cross-version archive identity rejected'
$workspace=Join-Path $fixture 'isolated QA with spaces'
& (Join-Path $toolRoot 'New-HrsQaWorkspace.ps1') -CandidateId $id -ArchivePath $zip -Destination $workspace | Out-Null
$workspace2=Join-Path $fixture 'second extraction'
& (Join-Path $toolRoot 'New-HrsQaWorkspace.ps1') -CandidateId $id -ArchivePath $zip -Destination $workspace2 | Out-Null
Check (Test-Path (Join-Path $workspace 'context/dev/qa/cases.json')) 'portable extraction includes frozen companion'
$nextContext=Join-Path $fixture 'synthetic 124 context'
[void][IO.Directory]::CreateDirectory((Join-Path $nextContext 'dev/qa'))
Write-HrsQaJson (Join-Path $nextContext 'qa-workspace.json') ([pscustomobject]@{schema='hrs-qa-workspace/v1';candidateId='1.2.4-qa.991'})
Write-HrsQaJson (Join-Path $nextContext 'dev/qa/rel.json') ([pscustomobject]@{schema='hrs-release/v1';version='1.2.4'})
Check ((Get-HrsQaLanePaths $nextContext).PackageRoot -ceq (Join-Path $fixture 'customer/HistoricalRandomStart_1.2.4')) 'QA context resolves 1.2.4 customer folder'
$ctx=Join-Path $workspace 'context'
$localZip=Join-Path $workspace ($id+'.zip')
$customer=Join-Path $workspace 'customer/HistoricalRandomStart_1.2.3'
[void](Assert-HrsWorkspace $workspace $localZip)
$dll=Join-Path $customer 'dev/verified/main/d0163.dll'
$saved=[IO.File]::ReadAllBytes($dll)
[IO.File]::AppendAllText($dll,'tamper')
Reject { Assert-HrsWorkspace $workspace $localZip } 'tampered extraction rejected'
[IO.File]::WriteAllBytes($dll,$saved)
$extra=Join-Path $customer 'extra.txt'
[IO.File]::WriteAllText($extra,'fixture')
Reject { Assert-HrsWorkspace $workspace $localZip } 'extra extraction file rejected'
[IO.File]::Delete($extra)
# Mutations operate only on this disposable fixture archive.
$bad=Join-Path $fixture 'bad.zip'
[IO.File]::Copy($zip,$bad,$false)
[IO.File]::Copy(($zip+'.receipt.json'),($bad+'.receipt.json'),$false)
$z=[IO.Compression.ZipFile]::Open($bad,[IO.Compression.ZipArchiveMode]::Update)
[void]$z.CreateEntry('HistoricalRandomStart_1.2.3/extra.txt'); $z.Dispose()
Reject { Read-HrsVerifiedZip $bad 'HistoricalRandomStart_1.2.3/package-manifest.json' (Get-HrsCustomerFiles) 'HistoricalRandomStart_1.2.3/' } 'extra ZIP file rejected'
$badReceipt=Read-HrsQaJson ($bad+'.receipt.json')
$badReceipt.archiveSha256=Get-HrsQaSha256 $bad
Write-HrsQaJson ($bad+'.receipt.json') $badReceipt
Check (-not (Test-HrsCandidateArchive $bad $id $record.releaseRecordSha256 $record.contractSha256).valid) 'archive and matching altered receipt rejected by registry'
$bad2=Join-Path $fixture 'unsafe.zip'
[IO.File]::Copy($zip,$bad2,$false)
$z=[IO.Compression.ZipFile]::Open($bad2,[IO.Compression.ZipArchiveMode]::Update)
[void]$z.CreateEntry('../escape.txt'); $z.Dispose()
Reject { Read-HrsVerifiedZip $bad2 'HistoricalRandomStart_1.2.3/package-manifest.json' } 'ZIP traversal rejected before extraction'
$bad3=Join-Path $fixture 'duplicate.zip'
[IO.File]::Copy($zip,$bad3,$false)
$z=[IO.Compression.ZipFile]::Open($bad3,[IO.Compression.ZipArchiveMode]::Update)
[void]$z.CreateEntry('HistoricalRandomStart_1.2.3/README.md'); $z.Dispose()
Reject { Read-HrsVerifiedZip $bad3 'HistoricalRandomStart_1.2.3/package-manifest.json' } 'duplicate ZIP path rejected'
function Mutate-Manifest([string]$Name,[scriptblock]$Mutation) {
    $target=Join-Path $fixture $Name
    [IO.File]::Copy($zip,$target,$false)
    $z=[IO.Compression.ZipFile]::Open($target,[IO.Compression.ZipArchiveMode]::Update)
    try {
        $entry=@($z.Entries | Where-Object { $_.FullName.Replace('\','/') -ceq 'HistoricalRandomStart_1.2.3/package-manifest.json' })[0]
        $reader=New-Object IO.StreamReader($entry.Open())
        try { $value=$reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        & $Mutation $value
        $entry.Delete()
        $entry=$z.CreateEntry('HistoricalRandomStart_1.2.3/package-manifest.json')
        $writer=New-Object IO.StreamWriter($entry.Open())
        try { $writer.Write(($value | ConvertTo-Json -Depth 8)) } finally { $writer.Dispose() }
    } finally { $z.Dispose() }
    return $target
}
$emptyManifest=Mutate-Manifest 'empty-manifest.zip' { param($m) $m.files=@() }
Reject { Read-HrsVerifiedZip $emptyManifest 'HistoricalRandomStart_1.2.3/package-manifest.json' } 'empty manifest rejected'
$duplicateManifest=Mutate-Manifest 'duplicate-manifest.zip' { param($m) $m.files=@($m.files)+@($m.files[0]) }
Reject { Read-HrsVerifiedZip $duplicateManifest 'HistoricalRandomStart_1.2.3/package-manifest.json' @() 'HistoricalRandomStart_1.2.3/' } 'duplicate manifest path rejected'
$unsafeManifest=Mutate-Manifest 'unsafe-manifest.zip' { param($m) $m.files[0].path='../outside' }
Reject { Read-HrsVerifiedZip $unsafeManifest 'HistoricalRandomStart_1.2.3/package-manifest.json' @() 'HistoricalRandomStart_1.2.3/' } 'unsafe manifest path rejected'

# Real command path, entirely simulated game state and logs.
$qaTools=Join-Path $workspace 'tools'
$start=Join-Path $qaTools 'Start-HrsQaRun.ps1'
$observe=Join-Path $qaTools 'Record-HrsQaObservation.ps1'
$finish=Join-Path $qaTools 'Export-HrsQaRun.ps1'
$complete=Join-Path $qaTools 'Complete-HrsQaCycle.ps1'
$runs=Join-Path $fixture 'SIMULATED runs'
$game=Join-Path $fixture 'SIMULATED game'
[void][IO.Directory]::CreateDirectory($game)
[IO.File]::WriteAllText((Join-Path $game '7DaysToDie.exe'),'fixture; never executable')
$installed=Join-Path $game 'Mods/BitWrecked_HistoricalRandomStart'
[void][IO.Directory]::CreateDirectory($installed)
$log=Join-Path $fixture 'synthetic.log'
[IO.File]::WriteAllText($log,'')
$contract=Read-HrsQaJson (Join-Path $ctx 'dev/qa/cases.json')
$runPaths=@{}
foreach ($case in $contract.requiredCases) {
    foreach ($name in @('d0163.dll','ModInfo.xml')) {
        [IO.File]::Copy((Join-Path $customer ('dev/verified/main/'+$name)),(Join-Path $installed $name),$true)
    }
    $output=@(& $start -LaneRoot $ctx -CandidateArchivePath $localZip -CaseId $case.id -Mode Random -GameRoot $game -LogPath $log -RunRoot $runs)
    $path=([string]@($output | Where-Object { $_ -like 'Evidence path:*' })[0]).Substring(14).Trim()
    $runPaths[$case.id]=$path
    if ($case.id -ceq 'HRS-QA-003A') {
        Reject { & $observe -RunPath $path -SelectedPointId NG01 -LandingResult Safe } 'excluded NG point rejected through observation command'
    }
    & $observe -RunPath $path -SelectedPointId NVG-0281 -FinalX 1101 -FinalY 61 -FinalZ 587 -LandingResult Safe -SelectedTraderPlacement TP01 -StartingBiome desert -ObservedTraderBiome desert -QuestDestinationResult Confirmed -StarterQuestProgression Works -ReloadResult NoRelocation -ConfirmedChecks $case.requiredChecks | Out-Null
    $eventLog=Join-Path $fixture ($case.id+'.log')
    $lines=@($case.expectedEvents | ForEach-Object { '[HRS] v=1.2.3 build=r123 reason='+$_ })
    [IO.File]::WriteAllLines($eventLog,[string[]]$lines)
    $kind='QA'
    if ($case.id -ceq 'HRS-QA-008') {
        $kind='Rollback'
        # Exact fixture files and empty fixture installation only; not a live game.
        [IO.File]::Delete((Join-Path $installed 'd0163.dll'))
        [IO.File]::Delete((Join-Path $installed 'ModInfo.xml'))
        [IO.Directory]::Delete($installed,$false)
    }
    & $finish -RunPath $path -Outcome Pass -Kind $kind -LogPath $eventLog -Notes 'SYNTHETIC TOOL VERIFICATION ONLY' | Out-Null
    $result=Read-HrsQaJson (Join-Path $path 'qa-result.json')
    Check ($result.automatedEventAssessment -ceq 'Consistent') ("real start/observe/export: "+$case.id)
    [void][IO.Directory]::CreateDirectory($installed)
}
& $complete -Decision Approve -LaneRoot $ctx -RunRoot $runs -Notes 'SYNTHETIC TOOL VERIFICATION ONLY; no release authority' | Out-Null
Check $true 'complete positive fixture approves with all required evidence'
$target=$runPaths['HRS-QA-003A']
$resultPath=Join-Path $target 'qa-result.json'
$original=[IO.File]::ReadAllBytes($resultPath)
[IO.File]::AppendAllText($resultPath,' ')
Reject { & $complete -Decision Approve -LaneRoot $ctx -RunRoot $runs } 'modified evidence sidecar cannot approve'
[IO.File]::WriteAllBytes($resultPath,$original)
$evidenceZip=$target+'.zip'
$evidenceBytes=[IO.File]::ReadAllBytes($evidenceZip)
[IO.File]::WriteAllText($evidenceZip,'not a ZIP')
Reject { & $complete -Decision Approve -LaneRoot $ctx -RunRoot $runs } 'invalid evidence ZIP cannot approve'
[IO.File]::WriteAllBytes($evidenceZip,$evidenceBytes)
$runFile=Join-Path $target 'run.json'
$runBytes=[IO.File]::ReadAllBytes($runFile)
$run=Read-HrsQaJson $runFile
$run.candidateArchiveSha256='0'*64
Write-HrsQaJson $runFile $run
Reject { & $complete -Decision Approve -LaneRoot $ctx -RunRoot $runs } 'wrong archive evidence cannot approve'
[IO.File]::WriteAllBytes($runFile,$runBytes)
# A fresh DEV run cannot be exported as QA.
$out=@(& $start -LaneRoot $ctx -CandidateArchivePath $localZip -CaseId HRS-QA-003A -Mode Random -GameRoot $game -LogPath $log -RunRoot (Join-Path $fixture 'DEV runs') -AllowDevelopmentGap)
$devPath=([string]@($out | Where-Object { $_ -like 'Evidence path:*' })[0]).Substring(14).Trim()
Reject { & $finish -RunPath $devPath -Outcome Pass -Kind QA -LogPath $log } 'DEV run cannot become QA evidence'
Reject { & $complete -Decision Approve -LaneRoot $ctx -RunRoot (Join-Path $fixture 'DEV runs') } 'missing cases and DEV evidence cannot approve'
# Source lane mutations after export do not affect isolated context.
[IO.File]::AppendAllText((Join-Path $lane 'dev/qa/cases.json'),'broken source')
[void](Assert-HrsWorkspace $workspace $localZip)
Check $true 'isolated workspace remains valid after source-lane mutation'
Write-Output "Acceptance tests passed: $passed/$passed"
Write-Output "Disposable synthetic evidence: $fixture"
