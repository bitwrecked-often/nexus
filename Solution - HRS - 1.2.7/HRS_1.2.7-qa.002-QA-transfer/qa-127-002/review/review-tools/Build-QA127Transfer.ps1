[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$WorkspacePath,
      [ValidateSet('1.2.7-qa.002')][string]$CandidateId='1.2.7-qa.002')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
if($PSVersionTable.PSVersion.Major -ne 5){throw 'Use Windows PowerShell 5.1.'}
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$lane=Join-Path $repo 'hrs_1.2.7'
$root=[IO.Path]::GetFullPath($WorkspacePath).TrimEnd('\','/')
$folder=[IO.Path]::GetFileName($root)
$archive=Join-Path $root ($CandidateId+'.zip')
$packaging=Join-Path $PSScriptRoot 'packaging'
$destination=Join-Path $repo ('qa_cycle/handoffs/HRS_'+$CandidateId+'-QA-transfer.zip')
$partial=$destination+'.partial.zip'
$transferReceipt=Join-Path $packaging 'transfer-verification.json'
$portableGate=Join-Path $packaging 'portable-release-gate.json'
foreach($path in @($destination,$partial,$transferReceipt,$portableGate,
    (Join-Path $root 'review'),(Join-Path $root 'START-HERE.md'),
    (Join-Path $root 'PACKAGE-IDENTITY.json'),(Join-Path $root 'QA-RUNBOOK.md'),
    (Join-Path $root 'QA-REVIEW-CHECKLIST.md'),(Join-Path $root 'transfer-manifest.json'))){
    if(Test-Path -LiteralPath $path){throw 'Preserve existing transfer input/output: '+$path}
}

# Authenticate the isolated workspace with its own frozen tools and registry.
# Adding engineering review material must not change context, tools or customer.
Import-Module (Join-Path $root 'tools/HrsQaTools.psm1') -Force
$verification=Read-HrsQaJson (Join-Path $packaging 'verification.json')
if($verification.status -cne 'Pass' -or $verification.candidateId -cne $CandidateId -or
    ![string]::Equals([IO.Path]::GetFullPath($verification.workspace).TrimEnd('\','/'),$root,[StringComparison]::OrdinalIgnoreCase) -or
    $verification.archiveSha256 -cne (Get-HrsQaSha256 $archive) -or
    $verification.receiptSha256 -cne (Get-HrsQaSha256 ($archive+'.receipt.json')) -or
    $verification.companionSha256 -cne (Get-HrsQaSha256 ($archive+'.companion.zip')) -or
    $verification.sourceManagerSha256 -cne (Get-HrsQaSha256 (Join-Path $lane 'dev/ui/p0158.ps1'))){
    throw 'Fresh verification of this exact isolated candidate and final source is required.'
}
$workspaceCheck=Assert-HrsWorkspace $root $archive
$receipt=$workspaceCheck.receipt
$contract=Read-HrsQaJson (Join-Path $root 'context/dev/qa/cases.json')
if($contract.candidateId -cne $CandidateId -or $contract.requiredCases.Count -ne 46 -or
    @($contract.requiredCases|Where-Object{$_.status -cne 'Pending'}).Count){throw 'Expected 46 independent Pending cases for candidate 002.'}
$customer=Join-Path $root 'customer/HistoricalRandomStart_1.2.7'
if(@(Get-ChildItem -LiteralPath $customer -Recurse -File -Force).Count -ne 13 -or
    $verification.customerManagerSha256 -cne (Get-HrsQaSha256 (Join-Path $customer 'dev/ui/p0158.ps1'))){
    throw 'Customer extraction must contain exactly the verified 13 distribution files, with no private QA state.'
}
$frozenBefore=@(Get-ChildItem -LiteralPath $root -Recurse -File -Force | ForEach-Object{
    $relative=$_.FullName.Substring($root.Length+1).Replace('\','/')
    [void](Resolve-HrsContainedFile $root $relative)
    [pscustomobject]@{path=$relative;bytes=$_.Length;sha256=(Get-HrsQaSha256 $_.FullName)}
})
$reviewCopies=New-Object 'Collections.Generic.List[object]'
function Copy-Review {
    param([string]$From,[string]$To,[switch]$KeepPortableLinks)
    $fromFull=[IO.Path]::GetFullPath($From)
    if(![IO.File]::Exists($fromFull)){throw 'Required review input missing: '+$fromFull}
    $target=Resolve-HrsContainedFile $root $To
    if(Test-Path -LiteralPath $target){throw 'Review destination already exists: '+$To}
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    $stripped=$false
    if([IO.Path]::GetExtension($fromFull) -ieq '.md' -and !$KeepPortableLinks){
        $text=[IO.File]::ReadAllText($fromFull)
        # Supplemental prose stays useful without DEV-checkout-relative links.
        # Keep external primary-source URLs; root entry/runbook links are portable.
        $portableText=[regex]::Replace($text,'\[([^\]]+)\]\((?!https?://)[^)]+\)','$1')
        $stripped=$portableText -cne $text
        [IO.File]::WriteAllText($target,$portableText,(New-Object Text.UTF8Encoding($false)))
    }else{[IO.File]::Copy($fromFull,$target,$false)}
    [void]$reviewCopies.Add([pscustomobject]@{
        source=$fromFull.Substring($repo.Length+1).Replace('\','/');path=$To
        sourceSha256=(Get-HrsQaSha256 $fromFull);portableSha256=(Get-HrsQaSha256 $target)
        repositoryLinksRemoved=$stripped
    })
}

# These records are outside the sealed customer and frozen engineering context.
Copy-Review (Join-Path $repo ('qa_cycle/handoffs/HRS_'+$CandidateId+'_START-HERE.md')) 'START-HERE.md' -KeepPortableLinks
Copy-Review (Join-Path $lane 'dev/qa/QA_RUNBOOK.md') 'QA-RUNBOOK.md' -KeepPortableLinks
Copy-Review (Join-Path $lane 'dev/BUILD_SETUP_FOUNDATION.md') 'review/BUILD_SETUP_FOUNDATION.md'
Copy-Review (Join-Path $repo 'HRS_1.2.7_LANE_WORK_MANIFEST.md') 'review/DEV-WORK-MANIFEST.md'
Copy-Review (Join-Path $lane 'LANE_README.md') 'review/LANE-README.md'
Copy-Review (Join-Path $lane 'dev/qa/QA_BUNDLE_READINESS.md') 'review/QA-BUNDLE-READINESS.md'
Copy-Review (Join-Path $lane 'dev/qa/game-name-20261004/public-copy.json') 'review/public-copy.json'
Copy-Review (Join-Path $lane 'dev/qa/public-name-20261004/metadata-change-verification.json') 'review/public-name/metadata-change-verification.json'
Copy-Review (Join-Path $lane 'dev/qa/public-name-20261004/ModInfo.before.xml') 'review/public-name/ModInfo.before.xml'
Copy-Review (Join-Path $packaging 'verification.json') 'review/candidate-verification.json'
Copy-Review (Join-Path $packaging 'customer-manager.png') 'review/customer-manager-smoke.png'
Copy-Review (Join-Path $packaging 'customer-smoke-stdout.txt') 'review/customer-smoke-stdout.txt'
Copy-Review (Join-Path $lane 'dev/qa/top-to-bottom-review-20261004/REVIEW.md') 'review/top-to-bottom-review/REVIEW.md'

# Preserve the original customer-QA sizing failures and their exact sequences.
# This is historical 1.2.6 QA, not a passing result for the new candidate.
$sizingReturn=Join-Path $repo 'QA Return 20260410'
$sizingEvidence=Join-Path $sizingReturn 'qa-review/1.2.6-qa.002/ui-sizing'
$sizingTarget='review/history/qa126-sizing-failures'
Copy-Review (Join-Path $sizingReturn 'QA-REVIEW-1.2.6-qa.002.md') ($sizingTarget+'/QA-REVIEW-1.2.6-qa.002.md')
foreach($name in @('sizing-findings.json','qa-result.json','09-minimum-maintenance-geometry.json')){
    Copy-Review (Join-Path $sizingEvidence $name) ($sizingTarget+'/ui-sizing/'+$name)
}
foreach($sequence in @('06-scale150-weighted-settled','06-cycle1-chosen','06-cycle1-weighted',
    '06-cycle2-chosen','06-cycle2-weighted','09-real-drag-top','09-real-drag-wheel-bottom')){
    foreach($extension in @('.json','.png')){
        Copy-Review (Join-Path $sizingEvidence ($sequence+$extension)) ($sizingTarget+'/ui-sizing/'+$sequence+$extension)
    }
}

# Keep the complete four-profile geometry matrix as historical DEV evidence.
# Only prose, original JSON receipts and PNGs are copied; no old payload/tool.
$geometryBaseline=Join-Path $repo 'hrs_1.2.6/dev/qa/native-ux-round2'
$geometryTarget='review/history/native-ux126-dev'
Copy-Review (Join-Path $geometryBaseline 'ACCEPTANCE.md') ($geometryTarget+'/ACCEPTANCE.md')
foreach($name in @('FINDINGS.md','INTEGRATION.md','verification.json','embedding-verification.json')){
    Copy-Review (Join-Path $geometryBaseline ('geometry/'+$name)) ($geometryTarget+'/geometry/'+$name)
}
foreach($profile in @('100','150','200','225')){
    Copy-Review (Join-Path $geometryBaseline ('geometry/integrated/verification-'+$profile+'.json')) ($geometryTarget+'/geometry/integrated/verification-'+$profile+'.json')
    foreach($capture in @('geometry-cycled-weighted','geometry-minimum-after-dialog-bottom',
        'geometry-minimum-bottom','geometry-minimum-bottom-before-check','geometry-minimum-expanded-bottom',
        'geometry-near-bottom-fitted','geometry-restored-normal')){
        $name=$capture+'-'+$profile+'.png'
        Copy-Review (Join-Path $geometryBaseline ('geometry/integrated/'+$name)) ($geometryTarget+'/geometry/integrated/'+$name)
    }
}

# Retain original draft provenance without carrying old executable payloads.
foreach($item in @(
    @('before/dev/builds/1.2.7-qa.001/build-record.json','review/history/qa001/build-record.json'),
    @('before/dev/qa/rel.json','review/history/qa001/rel.json'),
    @('before/dev/qa/cases.json','review/history/qa001/cases.json'),
    @('before/dev/verified/main/ModInfo.xml','review/history/qa001/ModInfo.xml')
)){Copy-Review (Join-Path $PSScriptRoot $item[0]) $item[1]}

# These short policy-check stdout records are authenticated by their receipt.
# Other stdout, stderr and noisy build/fixture outputs stay excluded below.
foreach($name in @('compiled-policy-stdout.txt','policy-v2-stdout.txt','invalid-writer-stdout.txt',
    'embedding-stdout.txt','parser-stdout.txt')){
    Copy-Review (Join-Path $PSScriptRoot ('integration-policy/'+$name)) ('review/review-repairs/integration-policy/'+$name)
}
foreach($file in @(Get-ChildItem -LiteralPath $PSScriptRoot -Recurse -File -Force)){
    $relative=$file.FullName.Substring($PSScriptRoot.Length+1).Replace('\','/')
    if($relative -match '(^|/)(before|before-source|fixture-bin|fixture-obj|bin|obj|tmp|temp)(/|$)' -or
        $relative -match '^packaging/' -or $relative -match '(?i)stdout|stderr|fixture-build|(?:^|/)driver|(?:^|/)\.' -or
        $relative -match '(?i)-output\.txt$' -or $file.Extension -notin @('.json','.md','.png','.txt')){continue}
    Copy-Review $file.FullName ('review/review-repairs/'+$relative)
}
# Source code is an engineering review input, never an installed/test DLL.
foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $lane 'dev/tests') -Recurse -File -Force)){
    $relative=$file.FullName.Substring((Join-Path $lane 'dev/tests').Length+1).Replace('\','/')
    if($relative -match '(^|/)(bin|obj|tmp|temp)(/|$)' -or $file.Extension -notin @('.ps1','.cs','.csproj')){continue}
    Copy-Review $file.FullName ('review/test-sources/'+$relative)
}
foreach($name in @('Build-QA127Transfer.ps1','Verify-CustomerCandidate.ps1','Qualify-Build.ps1','Verify-ProtectedHistory.ps1')){
    Copy-Review (Join-Path $PSScriptRoot $name) ('review/review-tools/'+$name)
}
foreach($name in @('Check-NativeInputs.ps1','Run-IntegrationPolicy.ps1')){
    Copy-Review (Join-Path $PSScriptRoot ('integration-policy/'+$name)) ('review/review-tools/integration-policy/'+$name)
}
foreach($name in @('NativeControls.cs','Sync-ManagerDesign.ps1','recipes/bitwrecked-quiet.json')){
    Copy-Review (Join-Path $lane ('dev/tools/NativeGraphics/'+$name)) ('review/native-graphics/'+$name)
}

# Carry historical foundation rationale as portable prose for cold-start review.
foreach($name in @('n0009.md','n0010.md','n0138.md','n0192.md')){
    Copy-Review (Join-Path $repo ('hrs_0.0.8.1/dev/docs/'+$name)) ('review/history/foundation-20260821/'+$name)
}
foreach($entry in $frozenBefore){
    $file=Resolve-HrsContainedFile $root $entry.path
    if((Get-HrsQaSha256 $file) -cne $entry.sha256 -or (Get-Item -LiteralPath $file).Length -ne $entry.bytes){
        throw 'FROZEN_WORKSPACE_CHANGED: '+$entry.path
    }
}
[void](Assert-HrsWorkspace $root $archive)
Write-HrsQaJson (Join-Path $root 'review/portable-review-inputs.json') ([pscustomobject]@{
    schema='hrs-portable-review-inputs/v1';candidateId=$CandidateId;copies=$reviewCopies.ToArray()
    boundary='Supplemental engineering-only material. Markdown repository links were removed as recorded. Frozen customer/context/tools and nested archives are unchanged.'
})
$reviewReadme=@'
# Engineering review material

These files support review of New Player Random Start 1.2.7 candidate 002.
The active release/case authority remains the frozen context directory; the
customer distribution remains the original nested ZIP. Test sources are
inspection inputs requiring a DEV checkout and its recorded toolchain to run.
Do not run them against the QA game installation or use injected fixtures as
customer evidence. No executable fixture payloads are supplied under review.

Current changes and verification are in review-repairs; current setup reasoning
is in BUILD_SETUP_FOUNDATION.md. Public wording is public-copy.json. The
public-name receipt and original ModInfo XML explain the presentation-only
rename while retaining HRS file/state identities. History/qa001 preserves the
unexported original build/contract provenance. History/foundation-20260821 is
historical design rationale, not current policy or release authority.

History/qa126-sizing-failures contains the original failed customer-QA report,
structured findings, outcome and seven PNG/JSON pairs covering HRS-UX-001/002/003.
Read its report for the original two Chosen/Weighted keyboard cycles at actual
150% Windows scaling, normal-window/taskbar bounds, and actual 200% minimum mouse
drag plus maximum scrolling. Its findings JSON also lists other historical
captures; those extra captures, the gallery and old evidence ZIP are not copied.
Apply the equivalent sequences to the current radio choices and verify all
current actions and Game details; the old Restore action is no longer present.
The current root QA-RUNBOOK.md and frozen case contract define fresh acceptance.

History/native-ux126-dev contains the preserved 1.2.6 acceptance record and full
four-profile geometry matrix: 224 assertions, four receipts and 28 captures.
These used Form.Scale 1/1.5/2/2.25 and API-driven resize events in an inert fixture.
They are historical DEV checks, not actual Windows display-profile or physical
mouse retests and not fresh 1.2.7 QA. Absolute paths in original JSON are provenance;
their corresponding portable profile/capture files are beside the copied records.
Top-to-bottom-review/REVIEW.md is the original read-only review before the repairs;
review-repairs records their implementation and bounded DEV verification.

Repository-relative links were removed from supplemental Markdown so no DEV
checkout is needed to read the prose. Portable root entry/runbook links are
preserved. portable-review-inputs.json records original and copied hashes.
All 46 independent QA cases remain Pending. Publication needs independent QA
and owner approval; Nexus and customers then receive the exact customer ZIP.
'@
[IO.File]::WriteAllText((Join-Path $root 'review/README.md'),$reviewReadme,(New-Object Text.UTF8Encoding($false)))
$identity=[pscustomobject][ordered]@{
    schema='hrs-qa-review-package/v1';candidateId=$CandidateId;releaseVersion='1.2.7';publicName='New Player Random Start'
    customerZip=$CandidateId+'.zip';archiveSha256=$receipt.archiveSha256;archiveBytes=(Get-Item -LiteralPath $archive).Length
    receiptSha256=(Get-HrsQaSha256 ($archive+'.receipt.json'));companionSha256=$receipt.companionSha256
    runtimeSha256=$receipt.runtimeSha256;sourceManagerSha256=$verification.sourceManagerSha256
    customerManagerSha256=$verification.customerManagerSha256;customerFileCount=13
    releaseRecordSha256=$receipt.releaseRecordSha256;contractSha256=$receipt.contractSha256
    independentQaPending=$contract.requiredCases.Count;publicationApproved=$false
    qualification='DEV fixtures, compiled source, package verification and simulated geometry are supporting evidence. Actual customer gameplay/display/accessibility/newcomer QA remains Pending.'
    distributionRule='After independent QA and owner approval, publish the exact customer ZIP unchanged. The outer transfer and review directory are engineering support.'
}
Write-HrsQaJson (Join-Path $root 'PACKAGE-IDENTITY.json') $identity
$lines=New-Object 'Collections.Generic.List[string]'
$lines.Add('# '+$CandidateId+' independent QA checklist');$lines.Add('')
$lines.Add('All 46 cases are Pending. Follow QA-RUNBOOK.md and frozen context/dev/qa/cases.json. DEV fixtures do not pass independent QA.');$lines.Add('')
$lines.Add('| Case | Review | Handoff status |');$lines.Add('| --- | --- | --- |')
foreach($case in $contract.requiredCases){$lines.Add('| '+$case.id+' | '+$case.title+' | '+$case.status+' |')}
$lines.Add('');$lines.Add('Start with the three preserved sizing failure sequences on actual Windows display profiles, then the runbook priorities and remaining contract cases. Preserve incomplete/failed attempts.');$lines.Add('')
foreach($case in $contract.requiredCases){
    $lines.Add('## '+$case.id);$lines.Add('');$lines.Add($case.requirement);$lines.Add('')
    foreach($check in $case.requiredChecks){$lines.Add('- [ ] '+$check)}
    $lines.Add('')
}
[IO.File]::WriteAllLines((Join-Path $root 'QA-REVIEW-CHECKLIST.md'),$lines.ToArray(),(New-Object Text.UTF8Encoding($false)))

# Hash every outer-transfer path, including the unchanged nested customer ZIP,
# receipt, engineering companion, context, own tools and all review inputs.
$files=@(Get-ChildItem -LiteralPath $root -Recurse -File -Force|Sort-Object FullName|ForEach-Object{
    $relative=$_.FullName.Substring($root.Length+1).Replace('\','/')
    [void](Resolve-HrsContainedFile $root $relative)
    [pscustomobject]@{path=$relative;bytes=$_.Length;sha256=(Get-HrsQaSha256 $_.FullName)}
})
$manifest=[pscustomobject]@{schema='hrs-qa-transfer/v1';candidateId=$CandidateId;customerArchiveSha256=$receipt.archiveSha256;files=$files}
Write-HrsQaJson (Join-Path $root 'transfer-manifest.json') $manifest
$manifestHash=Get-HrsQaSha256 (Join-Path $root 'transfer-manifest.json')
Compress-Archive -LiteralPath $root -DestinationPath $partial
[void](Read-HrsVerifiedZip $partial ($folder+'/transfer-manifest.json') @($files.path) ($folder+'/') $manifestHash)

# Independently extract outside the workspace/repository. Verify every path,
# then use only the extracted workspace's tools for its own release gate.
$portable=Join-Path ([IO.Path]::GetTempPath()) ('hrs127-qa002-portable-'+[guid]::NewGuid().ToString('N'))
if(Test-Path -LiteralPath $portable){throw 'Portable extraction must be new.'}
Expand-Archive -LiteralPath $partial -DestinationPath $portable
$portableRoot=Join-Path $portable $folder
Import-Module (Join-Path $portableRoot 'tools/HrsQaTools.psm1') -Force
$portableManifest=Read-HrsQaJson (Join-Path $portableRoot 'transfer-manifest.json')
if((Get-HrsQaSha256 (Join-Path $portableRoot 'transfer-manifest.json')) -cne $manifestHash){throw 'Portable manifest bytes changed.'}
[void](Assert-HrsTree $portableRoot $portableManifest.files @('transfer-manifest.json'))
[void](Assert-HrsWorkspace $portableRoot (Join-Path $portableRoot ($CandidateId+'.zip')))
& (Join-Path $portableRoot 'tools/Test-HrsRelease.ps1') -LaneRoot (Join-Path $portableRoot 'context') -ReportPath $portableGate | Out-Null
$gate=Read-HrsQaJson $portableGate
if(!$gate.readyForQa -or $gate.errorCount -or $gate.warningCount){throw 'Portable own-tools release gate failed.'}
if((Get-HrsQaSha256 (Join-Path $portableRoot ($CandidateId+'.zip'))) -cne $receipt.archiveSha256 -or
    (Get-HrsQaSha256 $archive) -cne $receipt.archiveSha256 -or
    (Get-HrsQaSha256 (Join-Path $portableRoot ($CandidateId+'.zip.receipt.json'))) -cne $identity.receiptSha256 -or
    (Get-HrsQaSha256 (Join-Path $portableRoot ($CandidateId+'.zip.companion.zip'))) -cne $receipt.companionSha256){
    throw 'Portable nested archive, receipt or companion identity changed.'
}
$partialHash=Get-HrsQaSha256 $partial
[void][IO.File]::Move($partial,$destination)
if((Get-HrsQaSha256 $destination) -cne $partialHash){throw 'Final transfer identity changed.'}
Write-HrsQaJson $transferReceipt ([pscustomobject][ordered]@{
    schema='hrs-qa-transfer-verification/v1';status='Pass';candidateId=$CandidateId;verifiedUtc=[DateTime]::UtcNow.ToString('o')
    destination=$destination;bytes=(Get-Item -LiteralPath $destination).Length;sha256=$partialHash
    customerArchiveSha256=$receipt.archiveSha256;receiptSha256=$identity.receiptSha256;companionSha256=$receipt.companionSha256
    transferManifestSha256=$manifestHash;manifestFiles=$files.Count;reviewCopies=$reviewCopies.Count
    customerFileCount=13;frozenWorkspacePathsPreserved=$frozenBefore.Count
    independentWorkspace=$portableRoot;ownToolsVerified=$true;readyForQa=$gate.readyForQa
    errors=$gate.errorCount;warnings=$gate.warningCount;independentCasesPending=$contract.requiredCases.Count
    gameInstalled=$false;gameLaunched=$false;publicationApproved=$false
})
'Portable QA transfer verified: '+$destination
