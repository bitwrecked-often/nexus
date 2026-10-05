[CmdletBinding()]
param()
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'HrsQaTools.psm1') -Force
$repo=Split-Path -Parent $PSScriptRoot
$temp=Join-Path ([IO.Path]::GetTempPath()) ('hrs bytes '+[guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temp)
[IO.File]::Copy((Join-Path $repo '.gitattributes'),(Join-Path $temp '.gitattributes'),$false)
$names=@()
foreach($lane in @('hrs_1.2.3','hrs_1.2.5','hrs_1.2.6')) {
    $release=Read-HrsQaJson (Join-Path $repo ($lane+'/dev/qa/rel.json'))
    $laneFiles=@(Get-HrsCustomerFiles -CandidateId $release.candidateId)+@('dev/qa/rel.json','dev/qa/cases.json',$release.build.recordPath)
    $laneFiles+=@($release.sourceSnapshot.sourceHashes | ForEach-Object { 'dev/src/runtime/main/'+$_.path })
    $names+=@($laneFiles | ForEach-Object { $lane+'/'+$_ })
}
$names+=@('qa_cycle/candidates/1.2.5-qa.002.zip.receipt.json')
$names+=@('qa_cycle/candidates/1.2.6-qa.001.zip.receipt.json','qa_cycle/candidates/1.2.6-qa.002.zip.receipt.json')
if (Test-Path -LiteralPath (Join-Path $repo 'qa_cycle/candidates/1.2.6-qa.003.zip.receipt.json')) {
    $names+='qa_cycle/candidates/1.2.6-qa.003.zip.receipt.json'
}
$names=@($names | Sort-Object -Unique)
foreach ($relative in $names) {
    $to=Resolve-HrsContainedFile $temp $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
    [IO.File]::Copy((Join-Path $repo $relative),$to,$false)
}
& git -C $temp init --quiet
if ($LASTEXITCODE) { throw 'GIT_INIT_FAILED' }
& git -C $temp -c core.autocrlf=true add -- .gitattributes hrs_1.2.3 hrs_1.2.5 hrs_1.2.6 qa_cycle
if ($LASTEXITCODE) { throw 'GIT_ADD_FAILED' }
$checkout=Join-Path $temp 'checkout'
[void][IO.Directory]::CreateDirectory($checkout)
& git -C $temp -c core.autocrlf=true checkout-index --all ('--prefix='+$checkout.Replace('\','/')+'/')
if ($LASTEXITCODE) { throw 'GIT_CHECKOUT_FAILED' }
foreach ($relative in $names) {
    if ((Get-HrsQaSha256 (Join-Path $repo $relative)) -cne
        (Get-HrsQaSha256 (Join-Path $checkout $relative))) { throw "CHECKOUT_BYTES_CHANGED: $relative" }
}
Write-Output "Exact-byte staging/checkout passed: $($names.Count) hashed inputs; real repository index untouched."
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $assembly=[Reflection.Assembly]::ReflectionOnlyLoad([IO.File]::ReadAllBytes((Join-Path $repo 'hrs_1.2.3/dev/verified/main/d0163.dll')))
    Write-Output "Runtime MVID: $($assembly.ManifestModule.ModuleVersionId)"
}
Write-Output "PowerShell: $($PSVersionTable.PSVersion)"
