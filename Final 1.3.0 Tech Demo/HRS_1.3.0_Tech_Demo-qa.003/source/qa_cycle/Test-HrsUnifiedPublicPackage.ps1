[CmdletBinding()]
param([string]$ReportPath = '')
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('hrs unified package ' + [guid]::NewGuid().ToString('N'))
$toolRoot = Join-Path $fixture 'bootstrap-tools'
[void][IO.Directory]::CreateDirectory($toolRoot)
$toolFiles = @('HrsQaTools.psm1','HrsIdentity.ps1','New-HrsQaWorkspace.ps1','Start-HrsQaRun.ps1',
    'Record-HrsQaObservation.ps1','Export-HrsQaRun.ps1','Complete-HrsQaCycle.ps1','Test-HrsRelease.ps1')
foreach ($file in $toolFiles) { [IO.File]::Copy((Join-Path $PSScriptRoot $file),(Join-Path $toolRoot $file),$false) }
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
$checks = New-Object 'Collections.Generic.List[object]'
function Check([bool]$Ok,[string]$Name) {
    if (-not $Ok) { throw "FAIL: $Name" }
    [void]$script:checks.Add([pscustomobject]@{name=$Name;status='Pass'})
    Write-Output "PASS: $Name"
}
function Reject([scriptblock]$Action,[string]$Name,[string]$Reason = '') {
    $message = ''
    try { & $Action | Out-Null } catch { $message = $_.Exception.Message }
    Check ($message -and (-not $Reason -or $message.Contains($Reason))) ($Name + ' [observed: ' + $message + ']')
}
function Manifest([string]$Root,[string]$Schema,[string]$CandidateId,[string]$Name) {
    $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Where-Object { $_.FullName -cne (Join-Path $Root $Name) } | Sort-Object FullName | ForEach-Object {
        [pscustomobject][ordered]@{path=$_.FullName.Substring($Root.Length+1).Replace('\','/');bytes=$_.Length;sha256=Get-HrsQaSha256 $_.FullName}
    })
    Write-HrsQaJson (Join-Path $Root $Name) ([pscustomobject][ordered]@{schema=$Schema;candidateId=$CandidateId;files=$files})
}
$protected = @('candidates/1.2.7-qa.002.zip','candidates/1.2.7-qa.002.zip.receipt.json',
    'candidates/1.2.7-qa.002.zip.companion.zip','candidate-registry.json')
$protectedBefore = @($protected | ForEach-Object { [pscustomobject]@{path=$_;sha256=Get-HrsQaSha256 (Join-Path $PSScriptRoot $_)} })
$oldArchive = Join-Path $PSScriptRoot 'candidates/1.2.7-qa.002.zip'
$oldRecord = Get-HrsRegistryRecord '1.2.7-qa.002'
Check (Test-HrsCandidateArchive $oldArchive $oldRecord.candidateId $oldRecord.releaseRecordSha256 $oldRecord.contractSha256).valid 'frozen split-format candidate 002 still verifies'
Check (@(Get-HrsCustomerFiles -CandidateId '1.2.7-qa.002').Count -eq 12) 'legacy customer allowlist remains twelve files'
Check (@(Get-HrsCustomerFiles -CandidateId '1.2.7-qa.997' -UnifiedPublic).Count -eq 13) 'public payload adds the full GPL license'
$stage = Join-Path $fixture 'full-public-stage'
[void][IO.Directory]::CreateDirectory($stage)
Expand-Archive -LiteralPath $oldArchive -DestinationPath (Join-Path $stage 'customer')
Expand-Archive -LiteralPath ($oldArchive+'.companion.zip') -DestinationPath (Join-Path $stage 'context')
$id = '1.2.7-qa.997'
$customer = Join-Path $stage 'customer/HistoricalRandomStart_1.2.7'
$context = Join-Path $stage 'context'
$release = Read-HrsQaJson (Join-Path $context 'dev/qa/rel.json')
$contract = Read-HrsQaJson (Join-Path $context 'dev/qa/cases.json')
$release.candidateId = $id
$release.build.candidateId = $id
$contract.candidateId = $id
Write-HrsQaJson (Join-Path $context 'dev/qa/rel.json') $release
Write-HrsQaJson (Join-Path $context 'dev/qa/cases.json') $contract
Write-HrsQaJson (Join-Path $context 'qa-workspace.json') ([pscustomobject]@{schema='hrs-qa-workspace/v1';candidateId=$id})
$fullLicense = Join-Path $customer 'release_templates/LICENSE-GPL-3.0-or-later.txt'
[void][IO.Directory]::CreateDirectory((Split-Path -Parent $fullLicense))
[IO.File]::Copy((Join-Path $repo 'archive/bit_wrecked_mod_framework_template/release_templates/LICENSE-GPL-3.0-or-later.txt'),$fullLicense,$false)
$manager = Join-Path $customer 'dev/ui/p0158.ps1'
[IO.File]::WriteAllText($manager,([IO.File]::ReadAllText($manager)).Replace('1.2.7-qa.002',$id),(New-Object Text.UTF8Encoding($false)))
Manifest $customer 'hrs-candidate-package-manifest/v1' $id 'package-manifest.json'
Manifest $context 'hrs-qa-context/v1' $id 'context-manifest.json'
foreach ($directory in @('tools','source','history','evidence','lore')) { [void][IO.Directory]::CreateDirectory((Join-Path $stage $directory)) }
foreach ($file in $toolFiles) { [IO.File]::Copy((Join-Path $toolRoot $file),(Join-Path $stage ('tools/'+$file)),$false) }
foreach ($file in @('README.md','START-HERE.md','source/BUILD.md','history/CHECKPOINT.md','evidence/fixture.txt','lore/README.md')) {
    [IO.File]::WriteAllText((Join-Path $stage $file),'SYNTHETIC TOOL FIXTURE ONLY; no customer QA result.',(New-Object Text.UTF8Encoding($false)))
}
[IO.File]::WriteAllText((Join-Path $stage 'START.bat'),'@rem SYNTHETIC TOOL FIXTURE; never launches a game')
$publicReceipt = [pscustomobject][ordered]@{
    schema='hrs-public-package-receipt/v1';candidateId=$id;releaseVersion='1.2.7'
    releaseRecordSha256=Get-HrsQaSha256 (Join-Path $context 'dev/qa/rel.json')
    contractSha256=Get-HrsQaSha256 (Join-Path $context 'dev/qa/cases.json')
    buildRecordSha256=Get-HrsQaSha256 (Join-Path $context $release.build.recordPath)
    buildAttempt='synthetic-layout-fixture';runtimeSha256=$release.artifacts[0].sha256;modInfoSha256=$release.artifacts[1].sha256
    packageManifestSha256=Get-HrsQaSha256 (Join-Path $customer 'package-manifest.json')
    contextManifestSha256=Get-HrsQaSha256 (Join-Path $context 'context-manifest.json')
    exportedUtc='2026-10-05T00:00:00.0000000Z'
}
Write-HrsQaJson (Join-Path $stage 'public-package-receipt.json') $publicReceipt
Manifest $stage 'hrs-public-distribution-manifest/v1' $id 'distribution-manifest.json'
$zipPath = Join-Path $fixture 'single-public-package.zip'
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zipPath
$digest = Get-HrsQaSha256 $zipPath
$identity = Get-HrsPublicPackageIdentity $zipPath $id $digest
Check ($identity.archiveSha256 -ceq $digest -and $identity.manifest.files.Count -eq 13) 'single ZIP verifies runtime plus full public context'
Reject { Get-HrsPublicPackageIdentity $zipPath $id ('0'*64) } 'wrong published ZIP digest rejected' 'HRS_PUBLIC_ARCHIVE_IDENTITY'
Reject { Get-HrsPublicPackageIdentity $zipPath '1.2.7-qa.998' $digest } 'cross-candidate archive rejected' 'HRS_PUBLIC_DISTRIBUTION_SCHEMA'
$receipt = New-HrsPublicArchiveReceipt $zipPath $id
Check ($receipt.schema -ceq 'hrs-candidate-export/v2' -and $receipt.archiveSha256 -ceq $digest) 'external archive receipt derives from embedded identities'
Write-HrsQaJson ($zipPath+'.receipt.json') $receipt
$workspace = Join-Path $fixture 'standalone QA workspace'
$bootstrap = Join-Path $toolRoot 'New-HrsQaWorkspace.ps1'
Reject { & $bootstrap -CandidateId $id -ArchivePath $zipPath -Destination $workspace } 'standalone extraction requires published SHA-256' 'HRS_PUBLIC_EXPECTED_SHA_REQUIRED'
Check (-not (Test-Path -LiteralPath $workspace)) 'rejected unanchored archive creates no workspace'
& $bootstrap -CandidateId $id -ArchivePath $zipPath -Destination $workspace -ExpectedArchiveSha256 $digest | Out-Null
$localArchive = Join-Path $workspace ($id+'.zip')
Check ((Get-HrsQaSha256 $localArchive) -ceq $digest) 'standalone workspace preserves the complete original ZIP bytes'
Check ((Get-HrsQaSha256 ($localArchive+'.receipt.json')) -ceq (Get-HrsQaSha256 ($zipPath+'.receipt.json'))) 'local derived receipt exactly matches external DEV receipt'
Check (Test-Path -LiteralPath (Join-Path $workspace 'tools/candidate-registry.json')) 'standalone workspace materializes its archive-bound QA registry'
[void](Assert-HrsWorkspace $workspace $localArchive)
Check $true 'all extracted public files verify with the workspace own tools'
Reject { & $bootstrap -CandidateId $id -ArchivePath $zipPath -Destination $workspace -ExpectedArchiveSha256 $digest } 'existing workspace is never overwritten' 'HRS_WORKSPACE_EXISTS'
foreach ($relative in @('source/BUILD.md','history/CHECKPOINT.md','evidence/fixture.txt','lore/README.md','tools/Test-HrsRelease.ps1')) {
    $path = Join-Path $workspace $relative
    $saved = [IO.File]::ReadAllBytes($path)
    [IO.File]::AppendAllText($path,'tamper')
    Reject { Assert-HrsWorkspace $workspace $localArchive } ("public file drift rejected: $relative") 'HRS_TREE_DRIFT'
    [IO.File]::WriteAllBytes($path,$saved)
}
$extra = Join-Path $workspace 'evidence/unlisted.txt'
[IO.File]::WriteAllText($extra,'fixture extra')
Reject { Assert-HrsWorkspace $workspace $localArchive } 'unlisted evidence file rejected' 'HRS_TREE_EXTRA'
[IO.File]::Delete($extra)
$private = Join-Path $workspace 'customer/HistoricalRandomStart_1.2.7/dev/ui/HistoricalRandomStart_State/history.v1.jsonl'
[void][IO.Directory]::CreateDirectory((Split-Path -Parent $private))
[IO.File]::WriteAllText($private,'{"fixture":true}')
[void](Assert-HrsWorkspace $workspace $localArchive)
Check $true 'established private manager state remains permitted outside distribution payload'
# Exercise the actual QA commands without game execution or independent QA claims.
$runs = Join-Path $fixture 'SYNTHETIC runs outside frozen workspace'
$game = Join-Path $fixture 'SYNTHETIC inert game'
[void][IO.Directory]::CreateDirectory($game)
[IO.File]::WriteAllText((Join-Path $game '7DaysToDie.exe'),'fixture; never executable')
$log = Join-Path $fixture 'synthetic.log'
[IO.File]::WriteAllText($log,'')
$qaTools = Join-Path $workspace 'tools'
$output = @(& (Join-Path $qaTools 'Start-HrsQaRun.ps1') -LaneRoot (Join-Path $workspace 'context') -CandidateArchivePath $localArchive -CaseId HRS-QA-001 -Mode NotApplicable -GameRoot $game -LogPath $log -RunRoot $runs)
$runPath = ([string]@($output | Where-Object { $_ -like 'Evidence path:*' })[0]).Substring(14).Trim()
$run = Read-HrsQaJson (Join-Path $runPath 'run.json')
Check ($run.candidateArchiveSha256 -ceq $digest) 'actual Start-HrsQaRun records the complete public ZIP identity'
& (Join-Path $qaTools 'Record-HrsQaObservation.ps1') -RunPath $runPath -LandingResult NotApplicable | Out-Null
& (Join-Path $qaTools 'Export-HrsQaRun.ps1') -RunPath $runPath -Outcome Blocked -Kind QA -LogPath $log -Notes 'SYNTHETIC TOOL FIXTURE ONLY; no live QA performed.' | Out-Null
Check (Test-Path -LiteralPath ($runPath+'.zip')) 'actual observation and run export accept the unified package workspace'
Reject { & (Join-Path $qaTools 'Complete-HrsQaCycle.ps1') -Decision Approve -LaneRoot (Join-Path $workspace 'context') -RunRoot $runs } 'missing independent cases cannot receive cycle approval' 'HRS_QA_APPROVAL_BLOCKED'
[void](Assert-HrsWorkspace $workspace $localArchive)
Check $true 'QA outputs outside the frozen workspace preserve public content integrity'
# Mutate only disposable test ZIPs. The supplied expected digest authenticates
# these deliberate mutations, so inner manifest validation must reject them.
foreach ($scenario in @('extra','traversal','duplicate','evidence-tamper')) {
    $bad = Join-Path $fixture ($scenario+'.zip')
    [IO.File]::Copy($zipPath,$bad,$false)
    $archive = [IO.Compression.ZipFile]::Open($bad,[IO.Compression.ZipArchiveMode]::Update)
    try {
        if ($scenario -ceq 'extra') { [void]$archive.CreateEntry('unlisted.txt') }
        elseif ($scenario -ceq 'traversal') { [void]$archive.CreateEntry('../escape.txt') }
        elseif ($scenario -ceq 'duplicate') { [void]$archive.CreateEntry('README.md') }
        else {
            $entry = @($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -ceq 'evidence/fixture.txt' })[0]
            $stream = $entry.Open()
            try { $stream.SetLength(1) } finally { $stream.Dispose() }
        }
    }
    finally { $archive.Dispose() }
    Reject { Get-HrsPublicPackageIdentity $bad $id (Get-HrsQaSha256 $bad) } ("malformed public ZIP rejected: $scenario")
}
# Run the real opt-in exporter from a disposable clone of the authenticated
# frozen candidate. No source, payload or registry in the DEV checkout changes.
$exporter = Join-Path $toolRoot 'Export-HrsCandidate.ps1'
[IO.File]::Copy((Join-Path $PSScriptRoot 'Export-HrsCandidate.ps1'),$exporter,$false)
$lane = Join-Path $fixture 'synthetic export lane'
Copy-Item -LiteralPath $customer -Destination $lane -Recurse
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $context 'dev') -Recurse -File) {
    $relative = $file.FullName.Substring($context.Length+1).Replace('\','/')
    $to = Resolve-HrsContainedFile $lane $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
    [IO.File]::Copy($file.FullName,$to,$false)
}
$sourceManager = Join-Path $lane 'dev/ui/p0158.ps1'
$sourceText = [regex]::Replace([IO.File]::ReadAllText($sourceManager),'\A# Candidate [^\r\n]+\r?\n','')
$sourceText = $sourceText.Replace('$useDevCandidate = $false','$useDevCandidate = $true').Replace('Release | 1.2.7 QA','Release | 1.2.7 DEV')
[IO.File]::WriteAllText($sourceManager,$sourceText,(New-Object Text.UTF8Encoding($false)))
$inputs = Join-Path $fixture 'synthetic public inputs'
foreach ($relative in @('START.bat','README.md','START-HERE.md','source/BUILD.md','history/CHECKPOINT.md','evidence/fixture.txt','lore/README.md')) {
    $to = Resolve-HrsContainedFile $inputs $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
    [IO.File]::Copy((Join-Path $stage $relative),$to,$false)
}
[IO.File]::WriteAllText((Join-Path $inputs 'BUILD-FROM-SOURCE.md'),'SYNTHETIC TOOL FIXTURE; no gameplay QA.')
$inputLicense = Join-Path $inputs 'release_templates/LICENSE-GPL-3.0-or-later.txt'
[void][IO.Directory]::CreateDirectory((Split-Path -Parent $inputLicense))
[IO.File]::Copy($fullLicense,$inputLicense,$false)
Write-HrsQaJson (Join-Path $toolRoot 'candidate-registry.json') ([pscustomobject]@{schema='hrs-candidate-registry/v1';records=@()})
$exported = Join-Path $fixture 'exported-full-public.zip'
$missingRequired = Join-Path $inputs 'BUILD-FROM-SOURCE.md'
[IO.File]::Move($missingRequired,($missingRequired+'.saved'))
Reject { & $exporter -LaneRoot $lane -CandidateId $id -OutputPath $exported -PublicContentRoot $inputs } 'actual unified exporter rejects missing contributor entry' 'HRS_PUBLIC_REQUIRED_INPUT'
[IO.File]::Move(($missingRequired+'.saved'),$missingRequired)
$referenceFixture = Join-Path $inputs 'Assembly-CSharp.dll'
[IO.File]::WriteAllText($referenceFixture,'INERT forbidden reference fixture')
Reject { & $exporter -LaneRoot $lane -CandidateId $id -OutputPath $exported -PublicContentRoot $inputs } 'actual unified exporter rejects game reference redistribution' 'HRS_GAME_REFERENCE_IN_PUBLIC_INPUTS'
[IO.File]::Delete($referenceFixture)
& $exporter -LaneRoot $lane -CandidateId $id -OutputPath $exported -PublicContentRoot $inputs | Out-Null
$exportedRecord = Get-HrsRegistryRecord $id
$exportedCheck = Test-HrsCandidateArchive $exported $id $exportedRecord.releaseRecordSha256 $exportedRecord.contractSha256
Check ($exportedCheck.valid -and $exportedCheck.receipt.distributionFormat -ceq 'unified-public/v1') 'actual unified exporter creates a registered verified full public ZIP'
Check (-not (Test-Path -LiteralPath ($exported+'.companion.zip'))) 'actual unified export needs no separate engineering companion'
Reject { & $exporter -LaneRoot $lane -CandidateId $id -OutputPath (Join-Path $fixture 'reused-candidate.zip') -PublicContentRoot $inputs } 'actual unified exporter rejects reused candidate identity' 'HRS_CANDIDATE_ID_ALREADY_EXPORTED'
$knownWorkspace = Join-Path $fixture 'known registry full workspace'
& $bootstrap -CandidateId $id -ArchivePath $exported -Destination $knownWorkspace | Out-Null
Check ((Get-HrsQaSha256 (Join-Path $knownWorkspace ($id+'.zip'))) -ceq $exportedRecord.archiveSha256) 'registered full ZIP initializes without an additional expected-hash argument'
[void](Assert-HrsWorkspace $knownWorkspace (Join-Path $knownWorkspace ($id+'.zip')))
Check $true 'registered full workspace validates from its own derived receipt and frozen registry'
foreach ($file in $protectedBefore) { Check ((Get-HrsQaSha256 (Join-Path $PSScriptRoot $file.path)) -ceq $file.sha256) ("preserved original $($file.path)") }
if ($ReportPath) {
    Write-HrsQaJson $ReportPath ([pscustomobject][ordered]@{
        schema='hrs-unified-public-tool-verification/v1';status='Pass';checks=$checks.ToArray();passed=$checks.Count
        fixture=$fixture;scope='Disposable software fixtures only. No installed game writes, game launch, independent customer QA, release approval or publication.'
        sourceHashes=@('HrsIdentity.ps1','HrsQaTools.psm1','New-HrsQaWorkspace.ps1','Test-HrsUnifiedPublicPackage.ps1' | ForEach-Object {
            [pscustomobject]@{path=$_;sha256=Get-HrsQaSha256 (Join-Path $PSScriptRoot $_)}
        })
    })
}
Write-Output "Unified public package checks passed: $($checks.Count)/$($checks.Count)"
Write-Output "Disposable fixture: $fixture"
