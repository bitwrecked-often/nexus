[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$WorkspacePath,
      [string]$CandidateId='1.2.7-qa.003')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -ne 5){throw 'Use Windows PowerShell 5.1'}
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$root=[IO.Path]::GetFullPath($WorkspacePath)
$evidence=Join-Path $PSScriptRoot 'final-package'
if(Test-Path -LiteralPath $evidence){throw 'Preserve the previous package verification; use a new evidence folder.'}
[void][IO.Directory]::CreateDirectory($evidence)
Import-Module (Join-Path $root 'tools/HrsQaTools.psm1') -Force
$archive=Join-Path $root ($CandidateId+'.zip')
$original=Join-Path $repo ('qa_cycle/candidates/'+$CandidateId+'.zip')
$check=Assert-HrsWorkspace $root $archive
$checks=New-Object 'Collections.Generic.List[string]'
function Require{param([bool]$Condition,[string]$Name);if(!$Condition){throw ('PUBLIC_VERIFY: '+$Name)};$checks.Add($Name)}
Require ($check.receipt.schema -ceq 'hrs-candidate-export/v2') 'one-public-distribution-identity'
Require ((Get-HrsQaSha256 $archive) -ceq (Get-HrsQaSha256 $original)) 'extracted-workspace-retains-exact-original-zip'
Require ((Get-HrsQaSha256 ($archive+'.receipt.json')) -ceq (Get-HrsQaSha256 ($original+'.receipt.json'))) 'standalone-derived-receipt-matches-dev-receipt-exactly'
Require (!(Test-Path -LiteralPath ($original+'.companion.zip'))) 'no-new-companion-archive'
$distribution=$check.distributionManifest
foreach($entry in $distribution.files){
    $file=Resolve-HrsContainedFile $root $entry.path
    Require ((Get-HrsQaSha256 $file) -ceq $entry.sha256 -and (Get-Item -LiteralPath $file).Length -eq $entry.bytes) ('public-file-'+$entry.path)
}
$customer=Join-Path $root 'customer/HistoricalRandomStart_1.2.7'
$package=Read-HrsQaJson (Join-Path $customer 'package-manifest.json')
Require ($package.files.Count -eq 13) 'thirteen-product-files-including-complete-license'
foreach($entry in $package.files){
    if($entry.path -ceq 'dev/ui/p0158.ps1'){continue}
    $from=if($entry.path -ceq 'release_templates/LICENSE-GPL-3.0-or-later.txt'){
        Join-Path $root $entry.path
    }else{Join-Path $repo ('hrs_1.2.7/'+$entry.path)}
    Require ((Get-HrsQaSha256 (Join-Path $customer $entry.path)) -ceq (Get-HrsQaSha256 $from)) ('exact-qualified-product-'+$entry.path)
}
$sourceText=[IO.File]::ReadAllText((Join-Path $repo 'hrs_1.2.7/dev/ui/p0158.ps1'))
$expected='# Candidate '+$CandidateId+[Environment]::NewLine+$sourceText.Replace('$useDevCandidate = $true','$useDevCandidate = $false').Replace('Release | 1.2.7 DEV','Release | 1.2.7 QA')
$sha=[Security.Cryptography.SHA256]::Create()
try{$expectedHash=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($expected)))).Replace('-','')}finally{$sha.Dispose()}
Require ($expectedHash -ceq (Get-HrsQaSha256 (Join-Path $customer 'dev/ui/p0158.ps1'))) 'established-customer-label-transformation-only'
$release=Read-HrsQaJson (Join-Path $root 'context/dev/qa/rel.json')
$contract=Read-HrsQaJson (Join-Path $root 'context/dev/qa/cases.json')
Require ($contract.candidateId -ceq $CandidateId -and @($contract.requiredCases).Count -eq 46 -and @($contract.requiredCases|Where-Object{$_.status -cne 'Pending'}).Count -eq 0) 'all-forty-six-independent-cases-remain-pending'
foreach($entry in $release.sourceSnapshot.sourceHashes){
    Require ((Get-HrsQaSha256 (Join-Path $root ('source/hrs_1.2.7/dev/src/runtime/main/'+$entry.path))) -ceq $entry.sha256) ('complete-corresponding-runtime-source-'+$entry.path)
}
foreach($tool in @('Export-HrsCandidate.ps1','HrsIdentity.ps1','HrsQaTools.psm1','New-HrsQaWorkspace.ps1','Test-HrsUnifiedPublicPackage.ps1')){
    Require ((Get-HrsQaSha256 (Join-Path $root ('source/qa_cycle/'+$tool))) -ceq (Get-HrsQaSha256 (Join-Path $repo ('qa_cycle/'+$tool)))) ('corresponding-package-tool-source-'+$tool)
}
foreach($file in @(Get-ChildItem -LiteralPath $root -Recurse -File -Force)){
    if($file.Extension -notin @('.md','.txt','.json','.ps1','.psm1','.cs','.csproj','.bat','.cmd','.xml')){continue}
    $text=[IO.File]::ReadAllText($file.FullName)
    Require (![regex]::IsMatch($text,'(?i)[A-Z]:[\\/]+Users[\\/]+mobil(?:[\\/]|\b)')) ('public-owner-path-scan-'+$file.FullName.Substring($root.Length+1))
    Require (![regex]::IsMatch($text,'(?:sk-[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9]{24,})')) ('public-credential-scan-'+$file.FullName.Substring($root.Length+1))
}
Require (@($distribution.files|Where-Object{$_.path -match '\.(zip|exe|pdb)$|/(?:Assembly-CSharp|0Harmony|UnityEngine[^/]*)\.dll$'}).Count -eq 0) 'no-inner-archives-or-proprietary-game-inputs'
Require ((Get-Item -LiteralPath (Join-Path $root 'release_templates/LICENSE-GPL-3.0-or-later.txt')).Length -eq 35823) 'complete-gpl-text-retained'
$gatePath=Join-Path $evidence 'extracted-release-gate.json'
& (Join-Path $root 'tools/Test-HrsRelease.ps1') -LaneRoot (Join-Path $root 'context') -ReportPath $gatePath | Out-Null
$gate=Read-HrsQaJson $gatePath
Require ($gate.readyForQa -and $gate.errorCount -eq 0 -and $gate.warningCount -eq 0) 'own-shipped-tools-clean-extracted-release-gate'

# Root entry forwards to the unmodified product launcher. No installation or
# game execution occurs: the disposable fixture contains only an inert EXE.
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('hrs-unified-root-smoke-'+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($fixture)
[IO.File]::WriteAllBytes((Join-Path $fixture '7DaysToDie.exe'),[byte[]]@())
$start=Join-Path $root 'START.bat'
$png=Join-Path $evidence 'public-manager.png'
$info=New-Object Diagnostics.ProcessStartInfo
$info.FileName=$env:ComSpec
$info.Arguments='/d /s /c ""'+$start+'" -SmokeTest -GameRootOverride "'+$fixture+'" -ScreenshotPath "'+$png+'""'
$info.WorkingDirectory=$root;$info.UseShellExecute=$false;$info.CreateNoWindow=$true
$info.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
$process=[Diagnostics.Process]::Start($info)
try{
    $stdoutTask=$process.StandardOutput.ReadToEndAsync();$stderrTask=$process.StandardError.ReadToEndAsync()
    if(!$process.WaitForExit(60000)){$process.Kill();throw 'Public root START smoke timed out'}
    $stdout=$stdoutTask.Result;$stderr=$stderrTask.Result
    Require ($process.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($stderr)) 'actual-public-root-start-smoke-exit-zero'
    Require ($stdout.Contains('PASS: real manager controls and selection binding')) 'actual-manager-controls-through-public-root-launcher'
}finally{$process.Dispose()}
[IO.File]::WriteAllText((Join-Path $evidence 'root-smoke-stdout.txt'),$stdout,(New-Object Text.UTF8Encoding($false)))
[void](Assert-HrsWorkspace $root $archive)
Require (@(Get-ChildItem -LiteralPath $fixture -Recurse -File).Count -eq 1) 'no-game-fixture-installation-or-launch'
Require ((Get-HrsQaSha256 $archive) -ceq $check.receipt.archiveSha256) 'same-public-archive-after-smoke'
Write-HrsQaJson (Join-Path $evidence 'verification.json') ([pscustomobject][ordered]@{
    schema='hrs-unified-public-candidate-verification/v1';status='Pass';candidateId=$CandidateId
    archiveSha256=$check.receipt.archiveSha256;archiveBytes=(Get-Item -LiteralPath $archive).Length
    receiptSha256=(Get-HrsQaSha256 ($archive+'.receipt.json'))
    distributionManifestSha256=$check.receipt.distributionManifestSha256
    publicFiles=@($distribution.files).Count+1;productFiles=@($package.files).Count+1
    checkCount=$checks.Count;checks=$checks.ToArray();workspace=$root
    sourceManagerSha256=(Get-HrsQaSha256 (Join-Path $repo 'hrs_1.2.7/dev/ui/p0158.ps1'))
    runtimeSha256=$check.receipt.runtimeSha256;independentCasesPending=46
    gameInstalled=$false;gameLaunched=$false;publicationApproved=$false
})
'Public package verified: '+$checks.Count+' checks. Independent QA remains Pending.'
