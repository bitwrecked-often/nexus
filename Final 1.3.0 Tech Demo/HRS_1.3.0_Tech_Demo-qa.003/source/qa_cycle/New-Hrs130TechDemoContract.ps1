[CmdletBinding()]
param([string]$LaneRoot='hrs_1.3.0_Tech_Demo',
      [ValidatePattern('^1\.3\.0-qa\.\d{3}$')][string]$CandidateId='1.3.0-qa.001')
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
$repo=Split-Path -Parent $PSScriptRoot
$lane=[IO.Path]::GetFullPath($LaneRoot)
$paths=Get-HrsQaLanePaths $lane
if(Test-Path -LiteralPath $paths.ReleasePath){throw 'Preserve existing release contract'}
if(Test-Path -LiteralPath $paths.ContractPath){throw 'Preserve existing QA contract'}
$registry=Read-HrsQaJson (Join-Path $PSScriptRoot 'candidate-registry.json')
if(@($registry.records|Where-Object{$_.candidateId -ceq $CandidateId}).Count){throw 'Candidate already reserved/exported'}
$buildRelative='dev/builds/'+$CandidateId+'/build-record.json'
$buildPath=Join-Path $lane $buildRelative
$build=Read-HrsQaJson $buildPath
$release=Read-HrsQaJson (Join-Path $repo 'hrs_1.2.7/dev/qa/rel.json')
$contract=Read-HrsQaJson (Join-Path $repo 'hrs_1.2.7/dev/qa/cases.json')
if(!$build.deterministicDoubleBuild -or $build.sourceHashes.Count -ne 15 -or $build.references.Count -ne 8 -or $build.assemblyCSharpMvid -cne $release.supportedEnvironment.assemblyCSharpMvid){throw 'Fresh build qualification incomplete'}
$oldBuild=Read-HrsQaJson (Join-Path $repo 'hrs_1.2.7/dev/builds/1.2.7-qa.002/build-record.json')
foreach($entry in $build.references){
    $prior=@($oldBuild.references|Where-Object{$_.name -ceq $entry.name})
    if($prior.Count -ne 1 -or $prior[0].sha256 -cne $entry.sha256){throw ('Pinned reference changed: '+$entry.name)}
}
foreach($key in @('dotnetSha256','cscSha256')){if($build.compiler.$key -cne $oldBuild.compiler.$key){throw 'Compiler pin changed'}}
foreach($entry in $build.sourceHashes){if((Get-HrsQaSha256 (Join-Path $lane ('dev/src/runtime/main/'+$entry.path))) -cne $entry.sha256){throw 'Built runtime source changed'}}
$dll=Join-Path $lane 'dev/verified/main/d0163.dll'
$xml=Join-Path $lane 'dev/verified/main/ModInfo.xml'
if((Get-HrsQaSha256 $dll) -cne $build.dllSha256){throw 'Qualified runtime changed'}
[xml]$metadata=[IO.File]::ReadAllText($xml)
if($metadata.SelectSingleNode('/xml/Version').GetAttribute('value') -cne '1.3.0' -or $metadata.SelectSingleNode('/xml/Name').GetAttribute('value') -cne 'BitWrecked_HistoricalRandomStart'){throw 'ModInfo identity mismatch'}
$release.version='1.3.0';$release.buildId='r130';$release.candidateId=$CandidateId
$release.sourceCommit=(& git -C $repo rev-parse HEAD).Trim()
$release.releaseDate='2026-10-05'
$release.laneStatus='tech-demo-development'
$release.sourceSnapshot.sourceHashes=$build.sourceHashes
$release.build=[pscustomobject][ordered]@{
    candidateId=$CandidateId;recordPath=$buildRelative;recordSha256=(Get-HrsQaSha256 $buildPath)
    deterministicDoubleBuild=$true;status='built-from-current-lane'
}
$release.artifacts[0].sha256=$build.dllSha256;$release.artifacts[0].bytes=(Get-Item -LiteralPath $dll).Length
$release.artifacts[1].sha256=(Get-HrsQaSha256 $xml);$release.artifacts[1].bytes=(Get-Item -LiteralPath $xml).Length
$release.runtimeLog.version='1.3.0';$release.runtimeLog.buildId='r130'
$release.package=[pscustomobject]@{archivePath='';archiveSha256='';status='not-exported';distributionFormat='unified-public/v1'}
$release | Add-Member -NotePropertyName presentation -NotePropertyValue ([pscustomobject]@{
    edition='Tech Demo';managerReleaseLabel='Tech Demo | 1.3.0';publicName='New Player Random Start'
})
$contract.releaseVersion='1.3.0';$contract.candidateId=$CandidateId
if(@($contract.requiredCases).Count -ne 46){throw 'Baseline coverage differs from the approved 46 cases'}
foreach($case in $contract.requiredCases){$case.status='Pending'}
function Add-Checks{param([string]$Id,[string[]]$Checks,[string]$Requirement)
    $case=@($contract.requiredCases|Where-Object{$_.id -ceq $Id})
    if($case.Count -ne 1){throw ('Missing approved case: '+$Id)}
    $case[0].requiredChecks=@($case[0].requiredChecks)+@($Checks|Where-Object{$_ -cnotin $case[0].requiredChecks})
    if($Requirement){$case[0].requirement+=' '+$Requirement}
}
Add-Checks 'HRS-QA-001' @('tech-demo-edition-visible','utf8-subtitle-correct') 'Verify 1.3.0 Tech Demo is visible and both setup documents render the subtitle correctly.'
Add-Checks 'HRS-BIOME-Manager' @('new-protection-default-on','standard-latent-protection-on','random-opt-out-restored','forest-hidden-preference-retained','settings-check-draft-preserved','settings-check-exact-name-and-options','settings-check-read-only') 'Check the protection default, saved Random opt-outs and hidden Forest/Standard preference; exercise the manual read-only Check settings for exact name and full active options without changing draft or disk.'
Add-Checks 'HRS-UX-OPERATIONS' @('settings-check-busy-guard','settings-check-preserves-apply-latches','settings-check-independent-inventory','settings-check-inconsistent-read-rejected','settings-check-disk-only-while-game-running') 'Check validates policy and inventory independently for absent/legacy/invalid settings, preserves failed-Apply/recovery/acknowledgement gates, rejects inconsistent reads and qualifies game-running results as files on disk.'
Add-Checks 'HRS-UX-COPY' @('diagnostics-details-only','no-redundant-apply-reminder','recorded-outcome-applied-name','recorded-outcome-unverified-attribution','stale-result-no-guessed-name','customer-error-reconciliation','forest-protection-summary-truthful','settings-check-results-truthful') 'Keep full diagnostics in Game details, attribute Current results to matching applied policy, avoid guessing a stale name or implying this candidate passed, and keep Check/protection/native error summaries truthful.'
Add-Checks 'HRS-UX-GEOMETRY' @('method-changes-outer-size-stable','settings-check-real-scale-reachable','measured-spacing-before-after') 'Method/protection/editor changes preserve intentional outer sizing; Check settings and all remaining actions fit and remain reachable at actual OS display scales.'
Add-Checks 'HRS-UX-HELP' @('help-pre-save-intent','help-world-size-scope','help-settings-check-boundary') 'Help explains configuration before save creation, Navezgane versus Random Gen minimum, and Check settings as a point-in-time read with no proof of character eligibility/runtime/trader assignment.'
Add-Checks 'HRS-UX-NEWCOMER' @('settings-check-purpose-understood','tech-demo-known-limit-understood') 'Observe comprehension of Check settings and the Tech Demo first-trader-session limitation without coaching.'
Write-HrsQaJson $paths.ReleasePath $release
Write-HrsQaJson $paths.ContractPath $contract
'Fresh 1.3.0 Tech Demo contracts prepared: '+$CandidateId+', '+$contract.requiredCases.Count+' Pending cases; all baseline requirements retained.'
