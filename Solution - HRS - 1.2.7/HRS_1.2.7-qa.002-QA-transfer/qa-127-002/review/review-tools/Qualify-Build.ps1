param([string]$BuildRecordPath)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$lane=Join-Path $repo 'hrs_1.2.7'
if(!$BuildRecordPath){throw 'Supply the existing successful native build record; this script does not rebuild.'}
$recordFile=(Resolve-Path -LiteralPath $BuildRecordPath).Path
$record=Get-Content -LiteralPath $recordFile -Raw | ConvertFrom-Json
if(!$record.deterministicDoubleBuild -or $record.sourceHashes.Count -ne 15 -or $record.references.Count -ne 8){throw 'Build qualification incomplete'}
foreach($entry in $record.sourceHashes){
    if((Get-FileHash -LiteralPath (Join-Path $lane ('dev/src/runtime/main/'+$entry.path)) -Algorithm SHA256).Hash -cne $entry.sha256){throw ('Current source changed: '+$entry.path)}
}
$oldRel=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'before/dev/qa/rel.json') -Raw | ConvertFrom-Json
$oldBuild=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'before/dev/builds/1.2.7-qa.001/build-record.json') -Raw | ConvertFrom-Json
foreach($pin in @('dotnetSha256','cscSha256')){
    if($record.compiler.$pin -cne $oldBuild.compiler.$pin){throw ('Pinned compiler changed: '+$pin)}
}
if($record.assemblyCSharpMvid -cne $oldRel.supportedEnvironment.assemblyCSharpMvid){throw 'Qualified engine identity changed'}
foreach($entry in $record.references){
    $pinned=@($oldBuild.references | Where-Object {$_.name -ceq $entry.name})
    if($pinned.Count -ne 1 -or $pinned[0].sha256 -cne $entry.sha256){throw ('Pinned reference changed: '+$entry.name)}
}
$dll=Join-Path $record.candidateRoot 'mod/d0163.dll'
$xml=Join-Path $record.candidateRoot 'mod/ModInfo.xml'
if((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -cne $record.dllSha256 -or (Get-Item -LiteralPath $dll).Length -ne $record.dllBytes){throw 'Build output mismatch'}
if((Get-FileHash -LiteralPath $xml -Algorithm SHA256).Hash -cne $oldRel.artifacts[1].sha256){throw 'Presentation metadata changed during build'}
$destination=Join-Path $lane 'dev/builds/1.2.7-qa.002/build-record.json'
if(Test-Path -LiteralPath $destination){throw 'Reserved new build record already exists'}
[void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
Copy-Item -LiteralPath $recordFile -Destination $destination
Copy-Item -LiteralPath $dll -Destination (Join-Path $lane 'dev/verified/main/d0163.dll')
Copy-Item -LiteralPath $xml -Destination (Join-Path $lane 'dev/verified/main/ModInfo.xml')
$oldRel.candidateId='1.2.7-qa.002'
$oldRel.sourceSnapshot.sourceHashes=$record.sourceHashes
$oldRel.artifacts[0].sha256=$record.dllSha256
$oldRel.artifacts[0].bytes=$record.dllBytes
$oldRel.build.candidateId='1.2.7-qa.002'
$oldRel.build.recordPath='dev/builds/1.2.7-qa.002/build-record.json'
$oldRel.build.recordSha256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
$oldRel.PSObject.Properties.Remove('metadataProvenance')
# The former presentation-only claim belongs to qa.001 history. The new
# complete build authenticates the current XML and repaired runtime together.
$utf8=New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $lane 'dev/qa/rel.json'),(($oldRel | ConvertTo-Json -Depth 20)+[Environment]::NewLine),$utf8)
$manager=Join-Path $lane 'dev/ui/p0158.ps1'
$text=[IO.File]::ReadAllText($manager)
$expected="`$verifiedRuntimeSha256 = '"+$oldRel.artifacts[0].sha256+"'"
$oldPin="`$verifiedRuntimeSha256 = '56DE4592317DB1E114BA3C1D5FED4AF8F22DB05D88B1808B3D005479ADAFBD38'"
if(([regex]::Matches($text,[regex]::Escape($oldPin))).Count -ne 1){throw 'Expected one original manager runtime pin'}
[IO.File]::WriteAllText($manager,$text.Replace($oldPin,$expected),$utf8)
[ordered]@{
    schema='hrs-review-build-qualification/v1';status='Pass';candidateId='1.2.7-qa.002'
    buildAttempt=$record.attempt;buildRecordSha256=$oldRel.build.recordSha256
    runtimeSha256=$record.dllSha256;runtimeBytes=$record.dllBytes;deterministicDoubleBuild=$true
    sourceCount=15;referenceCount=8;managerSha256=(Get-FileHash -LiteralPath $manager -Algorithm SHA256).Hash
    originalDraft='before/dev/qa/rel.json';historicalMetadataReceipt='../public-name-20261004/metadata-change-verification.json'
    activeMetadataQualification='Fresh complete build includes current ModInfo.xml; the old unchanged-runtime claim remains preserved history.'
    completedUtc=[DateTime]::UtcNow.ToString('o');independentQaPassed=$false
}|ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'build-qualification.json') -Encoding UTF8
'PASS: deterministic build, fifteen sources, eight pinned references, payload, contract and manager pin qualified together.'
