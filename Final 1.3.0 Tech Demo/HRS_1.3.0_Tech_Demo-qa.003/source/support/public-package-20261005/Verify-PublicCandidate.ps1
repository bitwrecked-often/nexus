[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ArchivePath,
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedArchiveSha256,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [string]$CandidateId='1.3.0-qa.003'
)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSEdition -cne 'Desktop'){throw 'Use Windows PowerShell 5.1.'}
$ExpectedArchiveSha256=$ExpectedArchiveSha256.ToUpperInvariant()
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$lane=Join-Path $repo 'hrs_1.3.0_Tech_Demo'
$original=[IO.Path]::GetFullPath($ArchivePath)
$evidence=[IO.Path]::GetFullPath($EvidenceRoot)
if(Test-Path -LiteralPath $evidence){throw 'Preserve previous verification evidence; choose a new evidence folder.'}
if(!(Test-Path -LiteralPath $original -PathType Leaf)){throw 'Candidate archive is missing.'}
Import-Module (Join-Path $repo 'qa_cycle/HrsQaTools.psm1') -Force
$checks=New-Object 'Collections.Generic.List[string]'
function Require([bool]$Condition,[string]$Name){if(!$Condition){throw ('PUBLIC_VERIFY: '+$Name)};[void]$script:checks.Add($Name)}
Require ((Get-HrsQaSha256 $original) -ceq $ExpectedArchiveSha256.ToUpperInvariant()) 'original-archive-matches-explicit-trusted-checksum'
$identity=Get-HrsPublicPackageIdentity $original $CandidateId $ExpectedArchiveSha256
Require ($identity.publicReceipt.schema -ceq 'hrs-public-package-receipt/v1') 'one-complete-public-distribution-identity'
[void][IO.Directory]::CreateDirectory($evidence)
$scratch=Join-Path ([IO.Path]::GetTempPath()) ('hrs130-v-'+[guid]::NewGuid().ToString('N'))
$bootstrap=Join-Path $scratch 'standalone-tools'
[void][IO.Directory]::CreateDirectory($bootstrap)
# Extract only three authenticated bootstrap entries from the one public ZIP.
# No DEV registry, external receipt or companion is copied to this tool root.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead($original)
try{
    foreach($name in @('HrsQaTools.psm1','HrsIdentity.ps1','New-HrsQaWorkspace.ps1')){
        $entry=@($zip.Entries|Where-Object{$_.FullName.Replace('\','/') -ceq ('tools/'+$name)})
        Require ($entry.Count -eq 1) ('authenticated-bootstrap-entry-'+$name)
        $bootstrapInputStream=$entry[0].Open();$bootstrapOutputStream=[IO.File]::Create((Join-Path $bootstrap $name))
        try{$bootstrapInputStream.CopyTo($bootstrapOutputStream)}finally{$bootstrapOutputStream.Dispose();$bootstrapInputStream.Dispose()}
    }
}finally{$zip.Dispose()}
$root=Join-Path $scratch 'w'
$longestRelative=@($identity.distributionManifest.files|ForEach-Object{([string]$_.path).Length}|Sort-Object -Descending|Select-Object -First 1)[0]
Require (($root.Length+1+$longestRelative) -lt 248) 'self-owned-native-temp-workspace-fits-windows-powershell-path-boundary'
& (Join-Path $bootstrap 'New-HrsQaWorkspace.ps1') -CandidateId $CandidateId -ArchivePath $original -Destination $root -ExpectedArchiveSha256 $ExpectedArchiveSha256 | Out-Null
Import-Module (Join-Path $root 'tools/HrsQaTools.psm1') -Force
$archive=Join-Path $root ($CandidateId+'.zip')
$check=Assert-HrsWorkspace $root $archive
Require ($check.receipt.schema -ceq 'hrs-candidate-export/v2') 'standalone-derived-full-archive-receipt'
Require ((Get-HrsQaSha256 $archive) -ceq $ExpectedArchiveSha256.ToUpperInvariant()) 'standalone-workspace-retains-exact-original-zip'
if(Test-Path -LiteralPath ($original+'.receipt.json')){
    Require ((Get-HrsQaSha256 ($archive+'.receipt.json')) -ceq (Get-HrsQaSha256 ($original+'.receipt.json'))) 'standalone-derived-receipt-matches-dev-receipt-exactly'
}
Require (!(Test-Path -LiteralPath ($original+'.companion.zip'))) 'no-companion-required-or-exported'
$distribution=$check.distributionManifest
foreach($entry in $distribution.files){
    $file=Resolve-HrsContainedFile $root $entry.path
    Require ((Get-HrsQaSha256 $file) -ceq $entry.sha256 -and (Get-Item -LiteralPath $file).Length -eq $entry.bytes) ('public-file-'+$entry.path)
}
$customer=Join-Path $root 'customer/HistoricalRandomStart_1.3.0'
$source=Join-Path $root 'source/hrs_1.3.0_Tech_Demo'
$package=Read-HrsQaJson (Join-Path $customer 'package-manifest.json')
Require ($package.candidateId -ceq $CandidateId -and @($package.files).Count -eq 13) 'thirteen-product-files-including-complete-license'
foreach($entry in $package.files){
    if($entry.path -ceq 'dev/ui/p0158.ps1'){continue}
    $from=if($entry.path -ceq 'release_templates/LICENSE-GPL-3.0-or-later.txt'){
        Join-Path $root $entry.path
    }else{Join-Path $lane $entry.path}
    Require ((Get-HrsQaSha256 (Join-Path $customer $entry.path)) -ceq (Get-HrsQaSha256 $from)) ('exact-qualified-product-'+$entry.path)
}
$sourceManager=Join-Path $lane 'dev/ui/p0158.ps1'
$sourceText=[IO.File]::ReadAllText($sourceManager)
$expected='# Candidate '+$CandidateId+[Environment]::NewLine+$sourceText.Replace('$useDevCandidate = $true','$useDevCandidate = $false')
$sha=[Security.Cryptography.SHA256]::Create()
try{$expectedHash=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($expected)))).Replace('-','')}finally{$sha.Dispose()}
$customerManager=Join-Path $customer 'dev/ui/p0158.ps1'
Require ($expectedHash -ceq (Get-HrsQaSha256 $customerManager)) 'customer-manager-changes-only-candidate-header-and-payload-mode'
Require ((Get-HrsQaSha256 (Join-Path $source 'dev/ui/p0158.ps1')) -ceq (Get-HrsQaSha256 $sourceManager)) 'complete-public-manager-source-is-exact-current-source'
$customerText=[IO.File]::ReadAllText($customerManager)
$expectedLabel='$version.Text = ''Tech Demo | 1.3.0'''
Require (@([regex]::Matches($customerText,'(?m)^'+[regex]::Escape($expectedLabel)+'\r?$')).Count -eq 1) 'visible-customer-edition-is-tech-demo-1.3.0'
Require (!($customerText -match 'Release \| 1\.3\.0 (DEV|QA)')) 'visible-customer-version-has-no-dev-or-qa-label'
Require (@([regex]::Matches($customerText,'(?m)^\$useDevCandidate = \$false\r?$')).Count -eq 1 -and !($customerText -match '(?m)^\$useDevCandidate = \$true\r?$')) 'customer-payload-mode-is-exactly-false'
$release=Read-HrsQaJson (Join-Path $root 'context/dev/qa/rel.json')
$contract=Read-HrsQaJson (Join-Path $root 'context/dev/qa/cases.json')
Require ($release.version -ceq '1.3.0' -and $release.candidateId -ceq $CandidateId -and $release.presentation.edition -ceq 'Tech Demo' -and $release.presentation.managerReleaseLabel -ceq 'Tech Demo | 1.3.0') 'frozen-release-contract-identifies-tech-demo'
Require ($contract.candidateId -ceq $CandidateId -and @($contract.requiredCases).Count -eq 46 -and @($contract.requiredCases|Where-Object{$_.status -cne 'Pending'}).Count -eq 0) 'all-forty-six-independent-cases-remain-pending'
foreach($relative in @('dev/qa/rel.json','dev/qa/cases.json',[string]$release.build.recordPath)){
    Require ((Get-HrsQaSha256 (Join-Path $root ('context/'+$relative))) -ceq (Get-HrsQaSha256 (Join-Path $lane $relative))) ('frozen-current-contract-'+$relative)
}
Require (@($release.sourceSnapshot.sourceHashes).Count -eq 15) 'complete-fifteen-source-runtime-contract'
foreach($entry in $release.sourceSnapshot.sourceHashes){
    foreach($location in @((Join-Path $source 'dev/src/runtime/main'),(Join-Path $root 'context/dev/src/runtime/main'))){
        Require ((Get-HrsQaSha256 (Join-Path $location $entry.path)) -ceq $entry.sha256) ('complete-corresponding-runtime-source-'+$location.Substring($root.Length+1).Replace('\','/')+'/'+$entry.path)
    }
}
foreach($file in @(Get-ChildItem -LiteralPath $source -Recurse -File | Where-Object{$_.Extension -in @('.cs','.ps1','.psm1','.csproj','.ico','.png')})){
    $relative=$file.FullName.Substring($source.Length+1).Replace('\','/')
    $current=Resolve-HrsContainedFile $lane $relative
    Require (Test-Path -LiteralPath $current -PathType Leaf) ('corresponding-source-input-present-'+$relative)
    Require ((Get-HrsQaSha256 $file.FullName) -ceq (Get-HrsQaSha256 $current)) ('corresponding-source-exact-'+$relative)
}
foreach($tool in @('Export-HrsCandidate.ps1','HrsIdentity.ps1','HrsQaTools.psm1','New-HrsQaWorkspace.ps1','Test-HrsTechDemoPackaging.ps1')){
    Require ((Get-HrsQaSha256 (Join-Path $root ('source/qa_cycle/'+$tool))) -ceq (Get-HrsQaSha256 (Join-Path $repo ('qa_cycle/'+$tool)))) ('corresponding-package-tool-source-'+$tool)
}
$fullLicense=Join-Path $root 'release_templates/LICENSE-GPL-3.0-or-later.txt'
$authenticLicense=Join-Path $repo 'archive/bit_wrecked_mod_framework_template/release_templates/LICENSE-GPL-3.0-or-later.txt'
Require ((Get-Item -LiteralPath $fullLicense).Length -eq 35823 -and (Get-HrsQaSha256 $fullLicense) -ceq (Get-HrsQaSha256 $authenticLicense)) 'complete-authentic-gpl-text-retained'
Require ((Get-HrsQaSha256 (Join-Path $customer 'release_templates/LICENSE-GPL-3.0-or-later.txt')) -ceq (Get-HrsQaSha256 $fullLicense)) 'installed-payload-license-matches-public-license'
Require (@($distribution.files|Where-Object{$_.path -match '(?i)\.(zip|exe|pdb)$|/(?:Assembly-CSharp|0Harmony|UnityEngine[^/]*|mscorlib|netstandard|System(?:\.Core)?|LogLibrary)\.dll$'}).Count -eq 0) 'no-inner-archives-executables-or-proprietary-game-inputs'
foreach($entry in $distribution.files){
    $file=Resolve-HrsContainedFile $root $entry.path
    if([IO.Path]::GetExtension($file) -notin @('.md','.txt','.json','.jsonl','.ps1','.psm1','.cs','.csproj','.bat','.cmd','.xml','.props','.config','.csv')){continue}
    $text=[IO.File]::ReadAllText($file)
    Require (![regex]::IsMatch($text,'(?i)[A-Z]:[\\/]+Users[\\/]+mobil(?:[\\/]|\b)')) ('public-owner-path-scan-'+$entry.path)
    Require (![regex]::IsMatch($text,'(?:sk-[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9]{24,})')) ('public-credential-scan-'+$entry.path)
}
# Only the current v2 ledger maps this distribution. Prior ledgers are preserved
# historical documents whose original path namespaces must not be reinterpreted.
$projection=Read-HrsQaJson (Join-Path $root 'evidence/PUBLIC-PROJECTION.json')
Require ($projection.schema -ceq 'hrs-public-projection/v2' -and $projection.candidateId -ceq $CandidateId -and $projection.releaseVersion -ceq '1.3.0' -and @($projection.files).Count -gt 0) 'current-v2-public-projection-ledger-is-present-and-nonempty'
Require ($projection.managerSourceSha256 -ceq (Get-HrsQaSha256 $sourceManager) -and $projection.requiredCases -eq 46 -and $projection.independentQa -ceq 'Pending' -and $projection.liveCampaign -ceq 'Pending') 'current-projection-binds-final-source-and-honest-qa-boundary'
$historicalArchive=Join-Path $repo 'qa_cycle/candidates/1.2.7-qa.003.zip'
$historicalSha256='8527F11CAAFF4173AB9880FD906E9E7DF4F6C56E45E2B81098F5688C94B27881'
Require ((Get-HrsQaSha256 $historicalArchive) -ceq $historicalSha256 -and $projection.historicalArchiveSha256 -ceq $historicalSha256) 'historical-projection-source-is-the-authenticated-original-public-archive'
$historicalZip=[IO.Compression.ZipFile]::OpenRead($historicalArchive)
$historicalEntries=@{}
try{
    foreach($entry in $historicalZip.Entries){
        $key=$entry.FullName.Replace('\','/')
        if($historicalEntries.ContainsKey($key)){throw 'Duplicate historical archive entry.'}
        $historicalEntries[$key]=$entry
    }
    $projectionChecks=0;$historicalOriginalChecks=0;$repositoryOriginalChecks=0
    foreach($copy in $projection.files){
        $publicPath=Resolve-HrsContainedFile $root ([string]$copy.path)
        Require ((Get-HrsQaSha256 $publicPath) -ceq $copy.publicSha256 -and (Get-Item -LiteralPath $publicPath).Length -eq $copy.bytes) ('public-projection-identity-and-bytes-'+$copy.path)
        if($copy.exactBytes){Require ($copy.originalSha256 -ceq $copy.publicSha256) ('exact-projection-provenance-'+$copy.path)}
        if(([string]$copy.source).StartsWith('frozen-1.2.7-qa.003.zip:',[StringComparison]::Ordinal)){
            $oldMember=([string]$copy.source).Substring('frozen-1.2.7-qa.003.zip:'.Length)
            Require ($historicalEntries.ContainsKey($oldMember)) ('historical-original-entry-present-'+$copy.path)
            $oldStream=$historicalEntries[$oldMember].Open();$oldHasher=[Security.Cryptography.SHA256]::Create()
            try{$oldHash=([BitConverter]::ToString($oldHasher.ComputeHash($oldStream))).Replace('-','')}finally{$oldHasher.Dispose();$oldStream.Dispose()}
            Require ($oldHash -ceq $copy.originalSha256) ('historical-original-provenance-hash-'+$copy.path)
            $historicalOriginalChecks++
        }else{
            $originalInput=Resolve-HrsContainedFile $repo ([string]$copy.source)
            Require ((Get-HrsQaSha256 $originalInput) -ceq $copy.originalSha256) ('repository-original-provenance-hash-'+$copy.path)
            $repositoryOriginalChecks++
        }
        $projectionChecks++
    }
}finally{$historicalZip.Dispose()}
Require ($projectionChecks -gt 0 -and $historicalOriginalChecks -gt 0 -and $repositoryOriginalChecks -gt 0) 'nonzero-current-and-historical-public-projection-coverage'
$contentManifest=Read-HrsQaJson (Join-Path $root 'evidence/PUBLIC-CONTENT-MANIFEST.json')
Require ($contentManifest.schema -ceq 'hrs-public-content-manifest/v2' -and $contentManifest.candidateId -ceq $CandidateId -and @($contentManifest.files).Count -gt 0) 'current-content-subset-manifest-is-present-and-nonempty'
$contentManifestChecks=0;$contentNames=@{}
foreach($entry in $contentManifest.files){
    Require (!$contentNames.ContainsKey([string]$entry.path)) ('content-subset-member-is-unique-'+$entry.path)
    $contentNames[[string]$entry.path]=$true
    $file=Resolve-HrsContainedFile $root ([string]$entry.path)
    Require ((Get-HrsQaSha256 $file) -ceq $entry.sha256 -and (Get-Item -LiteralPath $file).Length -eq $entry.bytes) ('content-subset-identity-and-bytes-'+$entry.path)
    $contentManifestChecks++
}
foreach($copy in $projection.files){Require ($contentNames.ContainsKey([string]$copy.path)) ('projected-input-is-in-content-subset-'+$copy.path)}
Require ($contentNames.ContainsKey('evidence/PUBLIC-PROJECTION.json')) 'content-subset-includes-its-current-projection-ledger'
$links=New-Object 'Collections.Generic.List[object]'
$criticalMissing=0
$linkPattern='(?<!!)\[[^\]]+\]\((?:<([^>]+)>|([^\)\s]+)(?:\s+"[^"]*")?)\)'
foreach($document in @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.md')){
    $relative=$document.FullName.Substring($root.Length+1).Replace('\','/')
    $critical=($relative -in @('README.md','START-HERE.md','QA-RUNBOOK.md','BUILD-FROM-SOURCE.md','LICENSE.md') -or $relative -match '^docs/' -or $relative -in @('source/hrs_1.3.0_Tech_Demo/LANE_README.md','source/hrs_1.3.0_Tech_Demo/dev/BUILD_SETUP_FOUNDATION.md','source/qa_cycle/README.md','source/qa_cycle/CANDIDATE_WORKFLOW.md'))
    foreach($match in [regex]::Matches([IO.File]::ReadAllText($document.FullName),$linkPattern)){
        $target=if($match.Groups[1].Success){$match.Groups[1].Value}else{$match.Groups[2].Value}
        if($target -match '^(?:[A-Za-z][A-Za-z0-9+.-]*:|#)'){continue}
        $target=([Uri]::UnescapeDataString(($target -split '#',2)[0]))
        if([string]::IsNullOrWhiteSpace($target)){continue}
        $resolved=[IO.Path]::GetFullPath((Join-Path $document.DirectoryName $target))
        $contained=$resolved.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)
        $exists=$contained -and (Test-Path -LiteralPath $resolved)
        [void]$links.Add([pscustomobject]@{document=$relative;target=$target;exists=$exists;criticalCurrentGuide=$critical})
        if($critical -and !$exists){$criticalMissing++}
    }
}
Write-HrsQaJson (Join-Path $evidence 'local-link-audit.json') ([pscustomobject]@{schema='hrs-public-local-links/v1';links=$links.ToArray();criticalMissing=$criticalMissing;historicalMissing=@($links|Where-Object{!$_.exists -and !$_.criticalCurrentGuide}).Count})
Require ($criticalMissing -eq 0) 'current-public-entry-and-source-guides-have-resolvable-local-links'
$gatePath=Join-Path $evidence 'extracted-release-gate.json'
& (Join-Path $root 'tools/Test-HrsRelease.ps1') -LaneRoot (Join-Path $root 'context') -ReportPath $gatePath | Out-Null
$gate=Read-HrsQaJson $gatePath
Require ($gate.readyForQa -and $gate.errorCount -eq 0 -and $gate.warningCount -eq 0) 'own-shipped-tools-clean-extracted-release-gate'

# Invoke the real root START entry with the existing smoke switch. The manager
# briefly displays native controls and renders them; it never enters the ordinary
# interactive ShowDialog path, applies settings or starts a game. Evidence is
# outside the frozen tree. The sole game fixture file is an inert zero-byte EXE.
$gameFixture=Join-Path $scratch 'inert-game-fixture'
[void][IO.Directory]::CreateDirectory($gameFixture)
[IO.File]::WriteAllBytes((Join-Path $gameFixture '7DaysToDie.exe'),[byte[]]@())
$png=Join-Path $evidence 'public-manager.png'
$info=New-Object Diagnostics.ProcessStartInfo
$info.FileName=$env:ComSpec
$info.Arguments='/d /s /c ""'+(Join-Path $root 'START.bat')+'" -SmokeTest -GameRootOverride "'+$gameFixture+'" -ScreenshotPath "'+$png+'""'
$info.WorkingDirectory=$root;$info.UseShellExecute=$false;$info.CreateNoWindow=$true
$info.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
$process=[Diagnostics.Process]::Start($info)
$stdout='';$stderr=''
function Stop-OwnedSmokeTree([Diagnostics.Process]$OwnedProcess){
    if($OwnedProcess.HasExited){return}
    # Windows PowerShell 5.1 lacks Process.Kill(entireProcessTree). Native
    # taskkill is restricted to this owned process ID and its descendants.
    $killInfo=New-Object Diagnostics.ProcessStartInfo
    $killInfo.FileName=Join-Path $env:SystemRoot 'System32/taskkill.exe'
    $killInfo.Arguments='/PID '+$OwnedProcess.Id+' /T /F'
    $killInfo.UseShellExecute=$false;$killInfo.CreateNoWindow=$true
    $killInfo.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $killer=[Diagnostics.Process]::Start($killInfo)
    try{[void]$killer.WaitForExit(10000)}finally{$killer.Dispose()}
    if(!$OwnedProcess.HasExited){$OwnedProcess.Kill()}
}
try{
    $stdoutTask=$process.StandardOutput.ReadToEndAsync();$stderrTask=$process.StandardError.ReadToEndAsync()
    if(!$process.WaitForExit(60000)){
        Stop-OwnedSmokeTree $process
        throw 'Public root START smoke timed out; owned process tree terminated.'
    }
    $stdout=$stdoutTask.Result;$stderr=$stderrTask.Result
    Require ($process.ExitCode -eq 0 -and [string]::IsNullOrWhiteSpace($stderr)) 'actual-public-root-start-smoke-exit-zero'
    Require ($stdout.Contains('PASS: real manager controls and selection binding')) 'actual-manager-controls-through-public-root-launcher'
}finally{
    Stop-OwnedSmokeTree $process
    $process.Dispose()
    [IO.File]::WriteAllText((Join-Path $evidence 'root-smoke-stdout.txt'),$stdout,(New-Object Text.UTF8Encoding($false)))
    [IO.File]::WriteAllText((Join-Path $evidence 'root-smoke-stderr.txt'),$stderr,(New-Object Text.UTF8Encoding($false)))
}
Require ((Test-Path -LiteralPath $png -PathType Leaf) -and (Test-Path -LiteralPath ($png -replace '\.png$','-weights.png') -PathType Leaf)) 'native-smoke-captures-main-window-and-weights-editor'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$capturedImage=[Drawing.Image]::FromFile($png)
try{$capturedDimensions=[pscustomobject]@{width=$capturedImage.Width;height=$capturedImage.Height}}finally{$capturedImage.Dispose()}
Write-HrsQaJson (Join-Path $evidence 'display-capture-profile.json') ([pscustomobject][ordered]@{
    schema='hrs-public-native-smoke-capture/v1';capturedUtc=[datetime]::UtcNow.ToString('o');candidateId=$CandidateId
    customerManagerSha256=Get-HrsQaSha256 $customerManager;captureMethod='Native WinForms DrawToBitmap through actual root START -SmokeTest'
    explicitComponentScaleApplied=$false;image=$capturedDimensions
    monitors=@([Windows.Forms.Screen]::AllScreens|ForEach-Object{[pscustomobject]@{device=$_.DeviceName;primary=$_.Primary;bounds=[string]$_.Bounds;workingArea=[string]$_.WorkingArea}})
    scope='Current workstation monitor snapshot, no OS scale manipulation. Native smoke images are not physical desktop screenshots or independent display/accessibility qualification.'
})
[void](Assert-HrsWorkspace $root $archive)
Require (@(Get-ChildItem -LiteralPath $gameFixture -Recurse -File).Count -eq 1 -and (Get-Item -LiteralPath (Join-Path $gameFixture '7DaysToDie.exe')).Length -eq 0) 'no-game-fixture-installation-or-launch'
Require ((Get-HrsQaSha256 $original) -ceq $ExpectedArchiveSha256.ToUpperInvariant() -and (Get-HrsQaSha256 $archive) -ceq $ExpectedArchiveSha256.ToUpperInvariant()) 'same-complete-public-archive-after-native-smoke'
Write-HrsQaJson (Join-Path $evidence 'verification.json') ([pscustomobject][ordered]@{
    schema='hrs-tech-demo-public-candidate-verification/v1';status='Pass';candidateId=$CandidateId;verifiedUtc=[datetime]::UtcNow.ToString('o')
    archiveSha256=$ExpectedArchiveSha256.ToUpperInvariant();archiveBytes=(Get-Item -LiteralPath $original).Length
    receiptSha256=Get-HrsQaSha256 ($archive+'.receipt.json');distributionManifestSha256=$check.receipt.distributionManifestSha256
    publicFiles=@($distribution.files).Count+1;productFiles=@($package.files).Count+1;projectionFilesVerified=$projectionChecks
    historicalOriginalFilesVerified=$historicalOriginalChecks;repositoryOriginalFilesVerified=$repositoryOriginalChecks;contentSubsetFilesVerified=$contentManifestChecks
    checkCount=$checks.Count;checks=$checks.ToArray();workspace=$root
    sourceManagerSha256=Get-HrsQaSha256 $sourceManager;customerManagerSha256=Get-HrsQaSha256 $customerManager
    runtimeSha256=$check.receipt.runtimeSha256;independentCasesPending=46
    gameInstalled=$false;gameLaunched=$false;publicationApproved=$false
    scope='Independent full archive extraction/bootstrap and native smoke package verification only. DrawToBitmap captures do not qualify actual display profiles, accessibility, newcomer comprehension or gameplay.'
})
'Public package verified: '+$checks.Count+' checks. Independent QA remains Pending.'
