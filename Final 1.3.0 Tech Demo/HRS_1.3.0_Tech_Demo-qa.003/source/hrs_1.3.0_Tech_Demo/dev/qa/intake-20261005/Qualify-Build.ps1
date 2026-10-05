[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$BuildRecordPath)
$ErrorActionPreference='Stop'
$lane=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$repo=Split-Path -Parent $lane
$nativePath=(Resolve-Path -LiteralPath $BuildRecordPath).Path
$record=Get-Content -LiteralPath $nativePath -Raw | ConvertFrom-Json
$old=Get-Content -LiteralPath (Join-Path $repo 'hrs_1.2.7/dev/builds/1.2.7-qa.002/build-record.json') -Raw | ConvertFrom-Json
if(!$record.deterministicDoubleBuild -or $record.sourceHashes.Count -ne 15 -or $record.references.Count -ne 8){throw 'Incomplete deterministic build record'}
foreach($key in @('dotnetSha256','cscSha256')){if($record.compiler.$key -cne $old.compiler.$key){throw 'Pinned compiler changed'}}
if($record.assemblyCSharpMvid -cne $old.assemblyCSharpMvid){throw 'Pinned game identity changed'}
foreach($entry in $record.references){
    $prior=@($old.references|Where-Object{$_.name -ceq $entry.name})
    if($prior.Count -ne 1 -or $prior[0].sha256 -cne $entry.sha256){throw ('Reference changed: '+$entry.name)}
}
foreach($entry in $record.sourceHashes){
    $source=Join-Path $lane ('dev/src/runtime/main/'+$entry.path)
    if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $entry.sha256){throw ('Built source changed: '+$entry.path)}
    if($entry.path -ceq 'c0217.cs'){
        $expected=[IO.File]::ReadAllText((Join-Path $repo ('hrs_1.2.7/dev/src/runtime/main/'+$entry.path))).Replace('v=1.2.7 build=r127','v=1.3.0 build=r130')
        if([IO.File]::ReadAllText($source) -cne $expected){throw 'Runtime diagnostics change exceeds version identity'}
    }else{
        $prior=@($old.sourceHashes|Where-Object{$_.path -ceq $entry.path})
        if($prior.Count -ne 1 -or $prior[0].sha256 -cne $entry.sha256){throw ('Runtime behavior unexpectedly changed: '+$entry.path)}
    }
}
$dll=Join-Path $record.candidateRoot 'mod/d0163.dll'
$xml=Join-Path $record.candidateRoot 'mod/ModInfo.xml'
if((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -cne $record.dllSha256 -or (Get-Item -LiteralPath $dll).Length -ne $record.dllBytes){throw 'Native build output mismatch'}
[xml]$metadata=[IO.File]::ReadAllText($xml)
if($metadata.SelectSingleNode('/xml/Version').GetAttribute('value') -cne '1.3.0' -or $metadata.SelectSingleNode('/xml/Name').GetAttribute('value') -cne 'BitWrecked_HistoricalRandomStart'){throw 'ModInfo identity mismatch'}
$buildRoot=Join-Path $lane 'dev/builds/1.3.0-qa.001'
[void][IO.Directory]::CreateDirectory($buildRoot)
$buildPath=Join-Path $buildRoot 'build-record.json'
if(Test-Path -LiteralPath $buildPath){throw 'Preserve existing candidate build record'}
$nativeHash=(Get-FileHash -LiteralPath $nativePath -Algorithm SHA256).Hash
[IO.File]::Copy($nativePath,(Join-Path $buildRoot 'native-build-record.private.json'),$false)
$record.candidateRoot='dev/out/'+$record.attempt
$record | Add-Member -NotePropertyName publicPathProjection -NotePropertyValue ([pscustomobject]@{
    nativeBuildRecordSha256=$nativeHash;changedMetadataOnly=@('candidateRoot');runtimeRebuilt=$true
    reason='Fresh native 1.3.0 deterministic build; only the private workstation output path is projected for public portability.'
})
$utf8=New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText($buildPath,($record|ConvertTo-Json -Depth 12)+[Environment]::NewLine,$utf8)
[IO.File]::Copy($dll,(Join-Path $lane 'dev/verified/main/d0163.dll'),$false)
[IO.File]::Copy($xml,(Join-Path $lane 'dev/verified/main/ModInfo.xml'),$false)
$proof=[pscustomobject][ordered]@{
    schema='hrs130-native-build-qualification/v1';status='Pass';candidateId='1.3.0-qa.001'
    nativeBuildRecordSha256=$nativeHash;publicBuildRecordSha256=(Get-FileHash -LiteralPath $buildPath -Algorithm SHA256).Hash
    runtimeSha256=$record.dllSha256;runtimeBytes=$record.dllBytes;modInfoSha256=(Get-FileHash -LiteralPath $xml -Algorithm SHA256).Hash
    deterministicDoubleBuild=$true;runtimeSourceCount=15;referenceCount=8
    behaviorSourceChanges=0;runtimeLogIdentity='v=1.3.0 build=r130';compiledGameMvid=$record.assemblyCSharpMvid
    independentGameplayQaPassed=$false
}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'build-qualification.json'),($proof|ConvertTo-Json -Depth 10)+[Environment]::NewLine,$utf8)
$proof | ConvertTo-Json -Depth 10
