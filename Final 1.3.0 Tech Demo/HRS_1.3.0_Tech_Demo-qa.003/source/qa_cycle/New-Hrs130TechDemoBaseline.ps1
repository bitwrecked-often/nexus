[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$origin=Join-Path $repo 'hrs_1.2.7'
$lane=Join-Path $repo 'hrs_1.3.0_Tech_Demo'
if(Test-Path -LiteralPath $lane){throw 'HRS130_DESTINATION_EXISTS'}
$utf8=New-Object Text.UTF8Encoding($false)
$head=(& git -C $repo rev-parse HEAD).Trim()
if($LASTEXITCODE -ne 0){throw 'Cannot authenticate the source base'}
$protectedPaths=@(& git -C $repo ls-files -- 'hrs_1.2.7' 'qa_cycle/candidates' 'qa_cycle/handoffs' 'CURRENT_RELEASE.json')
$protected=@($protectedPaths | ForEach-Object {
    $file=Join-Path $repo $_
    [pscustomobject]@{path=$_;bytes=(Get-Item -LiteralPath $file).Length;sha256=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash}
})
$files=@('START.bat','README.md','LICENSE.md','dev/BUILD_SETUP_FOUNDATION.md','dev/qa/POLICY_V2_VECTORS.json')
foreach($relative in @('dev/src','dev/ui','dev/tools/NativeGraphics','dev/tests')){
    $files+=@(Get-ChildItem -LiteralPath (Join-Path $origin $relative) -Recurse -File -Force |
        Where-Object{$_.FullName -notmatch '[\\/](?:HistoricalRandomStart_State|bin|obj)[\\/]'} |
        ForEach-Object{$_.FullName.Substring($origin.Length+1).Replace('\','/')})
}
$copied=@(foreach($relative in ($files|Sort-Object -Unique)){
    $from=Join-Path $origin $relative
    $to=Join-Path $lane $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $to))
    [IO.File]::Copy($from,$to,$false)
    [pscustomobject]@{path=$relative;origin=('hrs_1.2.7/'+$relative);originSha256=(Get-FileHash -LiteralPath $from -Algorithm SHA256).Hash;copiedSha256=(Get-FileHash -LiteralPath $to -Algorithm SHA256).Hash}
})
foreach($relative in @('START.bat','README.md','dev/ui/p0158.ps1','dev/src/runtime/main/ModInfo.xml','dev/src/runtime/main/c0217.cs','dev/tools/NativeGraphics/Show-GraphicsWorkbench.ps1','dev/tools/NativeGraphics/recipes/bitwrecked-quiet.json','dev/tools/NativeGraphics/recipes/bitwrecked-contrast.json')){
    $file=Join-Path $lane $relative
    $text=[IO.File]::ReadAllText($file).Replace('1.2.7','1.3.0')
    if($relative -ceq 'dev/src/runtime/main/c0217.cs'){$text=$text.Replace('build=r127','build=r130')}
    if($relative -ceq 'dev/ui/p0158.ps1'){
        $text=$text.Replace('Release | 1.3.0 DEV','Tech Demo | 1.3.0')
        $text=[regex]::Replace($text,"(?m)^\`$verifiedRuntimeSha256 = '[A-F0-9]+'","`$verifiedRuntimeSha256 = 'UNBUILT'")
        $text=[regex]::Replace($text,"(?m)^\`$verifiedModInfoSha256 = '[A-F0-9]+'","`$verifiedModInfoSha256 = 'UNBUILT'")
    }
    if($relative -like 'dev/tools/NativeGraphics/recipes/*'){$text=$text.Replace('"highlight": "1.3.0"','"highlight": "Tech Demo | 1.3.0"')}
    [IO.File]::WriteAllText($file,$text,$utf8)
}
$ownerTest=Join-Path $lane 'dev/tests/Test-ManagerOwnership.ps1'
$text=[IO.File]::ReadAllText($ownerTest).Replace("-ReleaseVersion '1.2.7'","-ReleaseVersion '1.3.0'")
[IO.File]::WriteAllText($ownerTest,$text,$utf8)
foreach($relative in @('dev/verified/main','dev/builds','dev/qa/intake-20261005','dev/tmp','dev/out')){[void][IO.Directory]::CreateDirectory((Join-Path $lane $relative))}
$provenance=[ordered]@{
    schema='hrs-lane-provenance/v3';sourceHead=$head;createdUtc=[datetime]::UtcNow.ToString('o')
    baseline='1.2.7-qa.003';baselineZipSha256='8527F11CAAFF4173AB9880FD906E9E7DF4F6C56E45E2B81098F5688C94B27881'
    semanticVersion='1.3.0';buildId='r130';edition='Tech Demo';status='source-copied-runtime-unbuilt'
    copiedInputs=$copied;protectedBefore=$protected
    scope='Corresponding source/workbench/tests only. Previous campaigns/contracts/builds/verified payloads and returns remain at original paths.'
}
[IO.File]::WriteAllText((Join-Path $lane 'BASELINE_PROVENANCE.json'),($provenance|ConvertTo-Json -Depth 12)+[Environment]::NewLine,$utf8)
foreach($entry in $protected){if((Get-FileHash -LiteralPath (Join-Path $repo $entry.path) -Algorithm SHA256).Hash -cne $entry.sha256){throw ('Protected input changed: '+$entry.path)}}
'Created hrs_1.3.0_Tech_Demo: '+$copied.Count+' inputs copied; '+$protected.Count+' historical paths preserved.'
