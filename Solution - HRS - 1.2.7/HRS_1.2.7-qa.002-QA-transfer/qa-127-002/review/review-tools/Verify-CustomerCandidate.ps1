[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$WorkspacePath,
      [string]$CandidateId='1.2.7-qa.002')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
Import-Module (Join-Path $repo 'qa_cycle/HrsQaTools.psm1') -Force
if ($PSVersionTable.PSVersion.Major -ne 5) { throw 'Use Windows PowerShell5.1.' }
$root=[IO.Path]::GetFullPath($WorkspacePath)
$evidence=Join-Path $PSScriptRoot 'packaging'
[void][IO.Directory]::CreateDirectory($evidence)
$archive=Join-Path $root ($CandidateId+'.zip')
$sourceArchive=Join-Path $repo ('qa_cycle/candidates/'+$CandidateId+'.zip')
$source=Join-Path $repo 'hrs_1.2.7'
$customer=Join-Path $root 'customer/HistoricalRandomStart_1.2.7'
$checks=New-Object 'Collections.Generic.List[string]'
function Require { param([bool]$Condition,[string]$Name); if (!$Condition) { throw ('CANDIDATE_VERIFY: '+$Name) }; $checks.Add($Name) }
function ByteHash { param([byte[]]$Value); $sha=[Security.Cryptography.SHA256]::Create(); try { ([BitConverter]::ToString($sha.ComputeHash($Value))).Replace('-','') } finally { $sha.Dispose() } }

[void](Assert-HrsWorkspace $root $archive)
Require ((Get-HrsQaSha256 $archive) -ceq (Get-HrsQaSha256 $sourceArchive)) 'unchanged-customer-archive-after-independent-extraction'
$record=Get-HrsRegistryRecord $CandidateId
$check=Test-HrsCandidateArchive $archive $CandidateId $record.releaseRecordSha256 $record.contractSha256
Require $check.valid 'registered-candidate-receipt-archive-manifest-cross-bindings'
$receipt=$check.receipt
$manifest=Read-HrsQaJson (Join-Path $customer 'package-manifest.json')
$customerFiles=@(Get-ChildItem -LiteralPath $customer -Recurse -File)
Require ($customerFiles.Count -eq 13 -and $manifest.files.Count -eq 12) 'twelve-customer-files-plus-manifest'
foreach ($entry in $manifest.files) {
    $file=Resolve-HrsContainedFile $customer $entry.path
    Require ((Get-HrsQaSha256 $file) -ceq $entry.sha256 -and (Get-Item -LiteralPath $file).Length -eq $entry.bytes) ('customer-file-'+$entry.path)
    if ($entry.path -cne 'dev/ui/p0158.ps1') {
        Require ((Get-HrsQaSha256 $file) -ceq (Get-HrsQaSha256 (Resolve-HrsContainedFile $source $entry.path))) ('source-byte-equality-'+$entry.path)
    }
}
$sourceText=[IO.File]::ReadAllText((Join-Path $source 'dev/ui/p0158.ps1'))
$customerManager=Join-Path $customer 'dev/ui/p0158.ps1'
$customerText=[IO.File]::ReadAllText($customerManager)
$expected='# Candidate '+$CandidateId+[Environment]::NewLine+$sourceText.Replace('$useDevCandidate = $true','$useDevCandidate = $false').Replace('Release | 1.2.7 DEV','Release | 1.2.7 QA')
Require ((ByteHash ([Text.Encoding]::UTF8.GetBytes($expected))) -ceq (Get-HrsQaSha256 $customerManager)) 'exact-established-customer-mode-and-label-transformation'
Require ($customerText -notmatch '\$selectionCombo|\$restoreButton|Get-HrsPreviousSettingsPlan') 'obsolete-selection-and-manual-restore-absent'
Require ($customerText.Contains("'Any','Chosen','Weighted'")) 'one-explicit-method-model'
Require ($customerText.Contains('Start-HrsManagerOperation -Operation Applying') -and $customerText.Contains('Start-HrsManagerOperation -Operation Uninstalling')) 'real-operation-guards-shipped'
Require ($customerText.Contains('$acknowledgement -eq [System.Windows.Forms.DialogResult]::OK')) 'acknowledgement-result-checked-before-launch-unlock'
Require ($customerText.Contains('function Show-HrsHelp {')) 'local-read-only-help-shipped'
Require ($customerText.Contains('If no safe landing is available, HRS keeps the usual start.')) 'conditional-fallback-copy-shipped'
Require ($customerText.Contains('Do not log out until your first trader is assigned. Complete the opening tasks in this session and wait for the Journey to Settlement trader marker. Leaving earlier may send the quest to Pine Forest when you return.')) 'exact-random-trader-notice-preserved'
$privacyPatterns=[ordered]@{
    localUserPaths='(?i)(?:[A-Z]:[\\/]+Users[\\/]+|/Users/|/home/)[^\s"''<>]+'
    email='(?i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}'
    credentialMarkers='(?i)(?:sk-[A-Za-z0-9]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|Bearer\s+[A-Za-z0-9._-]{12,}|(?:api[_-]?key|password|client[_-]?secret|access[_-]?token)\s*[:=]\s*["'']?[A-Za-z0-9/+_.-]{8,})'
}
foreach ($file in $customerFiles) {
    if ($file.Extension -notin @('.ps1','.psm1','.md','.bat','.xml','.json')) { continue }
    $text=[IO.File]::ReadAllText($file.FullName)
    foreach ($name in $privacyPatterns.Keys) {
        Require (![regex]::IsMatch($text,$privacyPatterns[$name])) ('customer-privacy-'+$name+'-'+$file.Name)
    }
}
$embedding = & (Join-Path $source 'dev/tools/NativeGraphics/Sync-ManagerDesign.ps1') -Check
Require ($embedding.Status -ceq 'Current' -and $embedding.Embedded -eq $true -and $embedding.Changed -eq $false) 'actual-embedded-controls-and-recipe-match-generator-inputs'
foreach ($binding in @(@('hrsDesignRecipeSha256','tools/NativeGraphics/recipes/bitwrecked-quiet.json'),@('hrsDesignControlsSha256','tools/NativeGraphics/NativeControls.cs'))) {
    $hash=Get-HrsQaSha256 (Join-Path $source ('dev/'+$binding[1]))
    Require ($customerText.Contains('$script:'+$binding[0]+" = '"+$hash+"'")) ('embedded-provenance-'+$binding[0])
}
$contract=Read-HrsQaJson (Join-Path $root 'context/dev/qa/cases.json')
Require ($contract.candidateId -ceq $CandidateId -and $contract.requiredCases.Count -eq 46) 'current-candidate-forty-six-independent-cases'
Require (@($contract.requiredCases | Where-Object {$_.status -cne 'Pending'}).Count -eq 0) 'unperformed-independent-qa-remains-pending'
$release=Read-HrsQaJson (Join-Path $root 'context/dev/qa/rel.json')
Require ($release.build.status -ceq 'built-from-current-lane') 'current-lane-qualified-runtime-build'
Require ($receipt.runtimeSha256 -ceq $release.artifacts[0].sha256) 'qualified-runtime-matches-frozen-contract'

$gatePath=Join-Path $evidence 'extracted-release-gate.json'
& (Join-Path $repo 'qa_cycle/Test-HrsRelease.ps1') -LaneRoot (Join-Path $root 'context') -ReportPath $gatePath | Out-Null
$gate=Read-HrsQaJson $gatePath
Require ($gate.readyForQa -and $gate.errorCount -eq 0 -and $gate.warningCount -eq 0) 'clean-extracted-release-gate'

# Exercise the freshly extracted customer's own START entry with an inert game
# fixture. Its executable is zero bytes and never executed in SmokeTest mode.
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('hrs-r2-customer-smoke-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($fixture)
[IO.File]::WriteAllBytes((Join-Path $fixture '7DaysToDie.exe'),[byte[]]@())
$before=@($customerFiles | ForEach-Object { [pscustomobject]@{path=$_.FullName;sha256=(Get-HrsQaSha256 $_.FullName)} })
$start=Join-Path $customer 'START.bat'
$png=Join-Path $evidence 'customer-manager.png'
$info=New-Object Diagnostics.ProcessStartInfo
$info.FileName=$env:ComSpec
$info.Arguments='/d /s /c ""'+$start+'" -SmokeTest -GameRootOverride "'+$fixture+'" -ScreenshotPath "'+$png+'""'
$info.WorkingDirectory=$customer; $info.UseShellExecute=$false; $info.CreateNoWindow=$true
$info.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
$info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
$process=[Diagnostics.Process]::Start($info)
try {
    $stdoutTask=$process.StandardOutput.ReadToEndAsync(); $stderrTask=$process.StandardError.ReadToEndAsync()
    if (!$process.WaitForExit(60000)) { $process.Kill(); throw 'Customer START smoke timed out.' }
    $stdout=$stdoutTask.Result; $stderr=$stderrTask.Result
    Require ($process.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($stderr)) 'actual-extracted-start-smoke-exit-zero'
    Require ($stdout.Contains('PASS: real manager controls and selection binding')) 'actual-real-manager-controls-and-weights-smoke'
} finally { $process.Dispose() }
[IO.File]::WriteAllText((Join-Path $evidence 'customer-smoke-stdout.txt'),$stdout,(New-Object Text.UTF8Encoding($false)))
foreach ($entry in $before) { Require ((Get-HrsQaSha256 $entry.path) -ceq $entry.sha256) ('smoke-preserved-'+[IO.Path]::GetFileName($entry.path)) }
Require (@(Get-ChildItem -LiteralPath $fixture -Recurse -File).Count -eq 1) 'inert-game-fixture-not-installed-or-launched'
Require ((Get-HrsQaSha256 $archive) -ceq $receipt.archiveSha256) 'archive-remains-frozen-after-smoke'

Write-HrsQaJson (Join-Path $evidence 'verification.json') ([pscustomobject][ordered]@{
    schema='hrs-customer-candidate-verification/v1';status='Pass';candidateId=$CandidateId
    sourceManagerSha256=(Get-HrsQaSha256 (Join-Path $source 'dev/ui/p0158.ps1'))
    customerManagerSha256=(Get-HrsQaSha256 $customerManager);archiveSha256=$receipt.archiveSha256
    archiveBytes=(Get-Item -LiteralPath $archive).Length;receiptSha256=(Get-HrsQaSha256 ($archive+'.receipt.json'))
    companionSha256=$receipt.companionSha256;runtimeSha256=$receipt.runtimeSha256
    checkCount=$checks.Count;checks=$checks.ToArray();workspace=$root;smokeFixture=$fixture
    independentCasesPending=46;gameInstalled=$false;gameLaunched=$false;publicationApproved=$false
})
'Candidate package verified: '+$checks.Count+' checks. Independent QA remains Pending.'
