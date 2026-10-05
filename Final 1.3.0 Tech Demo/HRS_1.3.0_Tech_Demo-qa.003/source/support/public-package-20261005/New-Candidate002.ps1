# Preserve candidate 001 and reuse its authenticated current-version build.
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$lane=Join-Path $repo 'hrs_1.3.0_Tech_Demo'
$oldArchive=Join-Path $repo 'qa_cycle/candidates/HRS_1.3.0_Tech_Demo-qa.001.zip'
if((Get-FileHash -LiteralPath $oldArchive -Algorithm SHA256).Hash -cne '1E6DA4C88682508FD74E6A83011D74A86BD90B26C5CFAAFEC0EDB5A5FDC97ADC'){throw 'Preserved candidate 001 identity changed.'}
$registry=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $repo 'qa_cycle/candidate-registry.json')))
if(@($registry.records|Where-Object{$_.candidateId -ceq '1.3.0-qa.002'}).Count){throw 'Candidate 002 is already reserved.'}
$releasePath=Join-Path $lane 'dev/qa/rel.json'
$contractPath=Join-Path $lane 'dev/qa/cases.json'
$release=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($releasePath))
$cases=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($contractPath))
if($release.candidateId -cne '1.3.0-qa.001' -or $cases.candidateId -cne '1.3.0-qa.001'){throw 'Current contract is not candidate 001.'}
$checkpoint=Join-Path $PSScriptRoot 'candidate-001-checkpoint'
if(Test-Path -LiteralPath $checkpoint){throw 'Preserve previous checkpoint.'}
[void][IO.Directory]::CreateDirectory($checkpoint)
[IO.File]::Copy($releasePath,(Join-Path $checkpoint 'rel.json'),$false)
[IO.File]::Copy($contractPath,(Join-Path $checkpoint 'cases.json'),$false)
$oldBuild=Join-Path $lane $release.build.recordPath
if((Get-FileHash -LiteralPath $oldBuild -Algorithm SHA256).Hash -cne $release.build.recordSha256){throw 'Qualified build record changed.'}
$build=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($oldBuild))
foreach($pin in $build.sourceHashes){if((Get-FileHash -LiteralPath (Join-Path $lane ('dev/src/runtime/main/'+$pin.path)) -Algorithm SHA256).Hash -cne $pin.sha256){throw 'Qualified runtime source changed.'}}
foreach($artifact in $release.artifacts){if((Get-FileHash -LiteralPath (Join-Path $lane $artifact.path) -Algorithm SHA256).Hash -cne $artifact.sha256){throw 'Qualified artifact changed.'}}
$newBuildRelative='dev/builds/1.3.0-qa.002/build-record.json'
$newBuild=Join-Path $lane $newBuildRelative
[void][IO.Directory]::CreateDirectory((Split-Path -Parent $newBuild))
if(Test-Path -LiteralPath $newBuild){throw 'New qualified build record path already exists.'}
[IO.File]::Copy($oldBuild,$newBuild,$false)
$release.candidateId='1.3.0-qa.002';$release.build.candidateId='1.3.0-qa.002';$release.build.recordPath=$newBuildRelative
$cases.candidateId='1.3.0-qa.002'
$utf8=New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText($releasePath,($release | ConvertTo-Json -Depth 40)+[Environment]::NewLine,$utf8)
[IO.File]::WriteAllText($contractPath,($cases | ConvertTo-Json -Depth 40)+[Environment]::NewLine,$utf8)
[ordered]@{schema='hrs-qualified-current-build-reuse/v1';candidateId='1.3.0-qa.002';originCandidateId='1.3.0-qa.001';originArchiveSha256=(Get-FileHash -LiteralPath $oldArchive -Algorithm SHA256).Hash;originBuildRecord=$build.attempt;qualifiedBuildRecordSha256=(Get-FileHash -LiteralPath $newBuild -Algorithm SHA256).Hash;runtimeSha256=$build.dllSha256;runtimeSourcesUnchanged=$true;managerSourceUnchanged=$true;runtimeRebuiltForThisPackagingCorrection=$false;reason='Correct optional public DEV verifier path normalization and shorten its disposable workspace. Product/runtime/manager/tool behavior unchanged; candidate 001 preserved.';independentCasesPending=46} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'candidate-002-build-reuse.json') -Encoding UTF8
'Prepared candidate 002 contracts with unchanged authenticated fresh 1.3.0 build; no reservation/export performed.'
