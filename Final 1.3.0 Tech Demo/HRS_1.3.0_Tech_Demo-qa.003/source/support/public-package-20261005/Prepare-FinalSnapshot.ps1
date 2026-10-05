# Curated final DEV evidence inputs; creates content only, not an export.
param([string]$ContentName='public-content-qa003-final')
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
if($ContentName -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Use a simple unused content folder name.'}
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$prefix='hrs_1.3.0_Tech_Demo/dev/qa/'
$callbacks=$prefix+'ux-return-20261005/callbacks-final-20261005/'
$summary=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $repo ($callbacks+'callbacks-verification.json'))))
$deltaPath=$prefix+'game-name-label-20261005/run-002/verification.json'
$delta=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $repo $deltaPath)))
if($delta.status -cne 'Pass' -or $delta.sourceSha256 -cne (Get-FileHash -LiteralPath (Join-Path $repo 'hrs_1.3.0_Tech_Demo/dev/ui/p0158.ps1') -Algorithm SHA256).Hash -or !$delta.managerLabelOnlyEquality -or !$delta.recipeLabelOnlyEquality -or !$delta.embeddingCurrent){throw 'Current presentation-only source qualification is not accepted.'}
if($summary.status -cne 'Pass' -or $summary.callbackCount -ne 97 -or $summary.groupCount -ne 18 -or $summary.sourceAfterSha256 -cne $delta.baselineManagerSha256){throw 'Carried callback aggregation must bind the verified sealed presentation baseline.'}
$callbackPaths=@($callbacks+'callbacks-verification.json')
foreach($group in $summary.groups){$callbackPaths+=($callbacks+$group.receipt)}
foreach($case in $summary.callbackCases){$callbackPaths+=($callbacks+$case.evidence)}
$callbackPaths=@($callbackPaths | Sort-Object -Unique)
$extra=@(
    ($prefix+'ux-return-20261005/TASK-DISPOSITIONS.md'),
    ($prefix+'ux-return-20261005/history-failure-r002/history-failure-verification.json'),
    ($prefix+'FEATURE_VISUAL_REVIEW.md'),
    ($prefix+'public-package-20261005/candidate-002-build-reuse.json'),
    ($prefix+'public-package-20261005/candidate-003-build-reuse.json'),
    ($prefix+'public-package-20261005/candidate-003-bookkeeping-verification.json'),
    ($prefix+'game-name-label-20261005/WORK.md'),
    ($prefix+'public-package-20261005/final-package-r003/verification.json'),
    ($prefix+'public-package-20261005/final-candidate002-r001/verification.json'),
    ($prefix+'public-package-20261005/final-candidate002-r001/post-export-observations.json'),
    ($prefix+'public-package-20261005/final-candidate002-post-export/post-export-verification.json'),
    ($prefix+'intake-20261005/source-release-gate-candidate003.json'))
$history=Join-Path $repo ($prefix+'ux-return-20261005/history-failure-r002')
if(!(Test-Path -LiteralPath $history -PathType Container)){throw 'Controlled history-failure evidence is missing.'}
# Bind the actual callback case ledger regardless of its narrow file name.
$extra=@($extra | Where-Object{[IO.File]::Exists((Join-Path $repo $_))})
foreach($directory in @('ux-return-20261005/history-failure-r002','ux-return-20261005/layout-comparison-final')){
    foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $repo ($prefix+$directory)) -Recurse -File)){
        if($file.Extension -in @('.json','.txt') -and $file.FullName -ne (Join-Path $repo $deltaPath)){$extra+=($file.FullName.Substring($repo.Length+1).Replace('\','/'))}
    }
}
$images=@(
    ($prefix+'native-event-loop-20261005/run-006/normal-event-loop.png'),
    ($prefix+'native-event-loop-20261005/run-006/normal-event-loop-logo.png'))
$content=Join-Path $repo ('hrs_1.3.0_Tech_Demo/dev/tmp/'+$ContentName)
$receipt=& (Join-Path $PSScriptRoot 'Prepare-PublicContent.ps1') -RepoRoot $repo -PublicContentRoot $content `
    -FocusedEvidenceDirectory ($prefix+'ux-return-20261005/focused-r008') `
    -ManagerReviewEvidencePath ($prefix+'ux-return-20261005/manager-review-r004/verification.json') `
    -NativeEventLoopEvidenceDirectory ($prefix+'native-event-loop-20261005/run-006') `
    -PresentationDeltaReceiptPath $deltaPath `
    -CallbackEvidencePaths $callbackPaths -AdditionalEvidencePaths @($extra|Sort-Object -Unique) -ApprovedImagePaths $images
[IO.File]::WriteAllText((Join-Path $PSScriptRoot ($ContentName+'.json')),($receipt | ConvertTo-Json -Depth 6)+[Environment]::NewLine,(New-Object Text.UTF8Encoding($false)))
$receipt
