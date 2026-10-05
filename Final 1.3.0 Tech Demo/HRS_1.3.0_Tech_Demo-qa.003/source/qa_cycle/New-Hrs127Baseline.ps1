[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2.0
$repo=[IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$origin=Join-Path $repo 'hrs_1.2.6'
$destination=Join-Path $repo 'hrs_1.2.7'
if(Test-Path -LiteralPath $destination){throw 'HRS127_DESTINATION_EXISTS: preserve the existing lane.'}
$head=(& git -C $repo rev-parse HEAD).Trim()
if($LASTEXITCODE -ne 0){throw 'Cannot identify source base.'}
$utf8=New-Object Text.UTF8Encoding($false)
$allowlist=New-Object 'Collections.Generic.List[string]'
foreach($relative in @('LICENSE.md','README.md','START.bat')){$allowlist.Add($relative)}
foreach($relativeRoot in @('dev/src','dev/ui','dev/tools/NativeGraphics')){
    foreach($file in Get-ChildItem -LiteralPath (Join-Path $origin $relativeRoot) -File -Recurse){
        $relative=$file.FullName.Substring($origin.Length+1).Replace('\','/')
        if($relative -match '/HistoricalRandomStart_State/' -or $relative -match '/(bin|obj)/'){continue}
        $allowlist.Add($relative)
    }
}
# Reusable fixture and current callback entry points; stale historical test
# campaigns and 1.2.6-specific qualified-reuse tooling remain at their origin.
foreach($relative in @('dev/tests/Test-ManagerCallbackWiring.ps1',
    'dev/tests/Replay-NativeUxRound2.ps1','dev/tests/Test-ManagerOwnership.ps1',
    'dev/tests/Test-PolicyV2.ps1','dev/tests/Test-PolicyInvalidFixtures.ps1',
    'dev/tests/Test-CompiledPolicy.ps1','dev/tests/PolicyProbe.cs',
    'dev/qa/POLICY_V2_VECTORS.json')){$allowlist.Add($relative)}
foreach($relative in $allowlist){
    if(-not [IO.File]::Exists((Join-Path $origin $relative))){throw ('Missing baseline input: '+$relative)}
}
$protectedPaths=@(& git -C $repo ls-files -- 'hrs_1.2.6' 'QA Return 20260410' 'QA Return 20260410 DEV Work' 'QA Return 20261004 - After QA did Devs work on accident' 'qa_cycle/candidates' 'qa_cycle/handoffs/*.zip' 'qa_cycle/handoffs/*.zip.receipt.json' 'qa_cycle/candidate-registry.json' 'CURRENT_RELEASE.json')
if($LASTEXITCODE -ne 0){throw 'Cannot inventory protected inputs.'}
$protected=@($protectedPaths | ForEach-Object {
    $path=Join-Path $repo $_
    [pscustomobject]@{path=$_;bytes=(Get-Item -LiteralPath $path).Length;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
})
$entries=@()
foreach($relative in $allowlist){
    $source=Join-Path $origin $relative
    $target=Join-Path $destination $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    [IO.File]::Copy($source,$target,$false)
    $entries+= [pscustomobject]@{path=$relative;origin=('hrs_1.2.6/'+$relative);originBytes=(Get-Item -LiteralPath $source).Length;originSha256=(Get-FileHash -LiteralPath $source).Hash;copiedSha256=(Get-FileHash -LiteralPath $target).Hash}
}
foreach($relative in @('START.bat','README.md','dev/ui/p0158.ps1',
    'dev/src/runtime/main/ModInfo.xml','dev/src/runtime/main/c0217.cs',
    'dev/tools/NativeGraphics/Show-GraphicsWorkbench.ps1',
    'dev/tools/NativeGraphics/recipes/bitwrecked-quiet.json',
    'dev/tools/NativeGraphics/recipes/bitwrecked-contrast.json')){
    $target=Join-Path $destination $relative
    $text=[IO.File]::ReadAllText($target).Replace('1.2.6','1.2.7')
    if($relative -eq 'dev/src/runtime/main/c0217.cs'){$text=$text.Replace('build=r126','build=r127')}
    if($relative -eq 'dev/ui/p0158.ps1'){
        $text=$text.Replace('# HRS 1.2.7 native UX round 2 development source; differs from frozen 1.2.7-qa.002.', '# HRS 1.2.7 DEV source; carries completed native UX from frozen 1.2.6-qa.003.')
        $text=$text.Replace("`$verifiedRuntimeSha256 = 'E5EA99BBD4DBAE122264835CC2090157F3A549C0E6FB379EB5DF5860EEF56D7B'", "`$verifiedRuntimeSha256 = 'UNBUILT'")
        $text=$text.Replace("`$verifiedModInfoSha256 = '3D23E282875296A3FD4AEBCF3DE31A9DFE9464737CA361F192AC03C16846A5B3'", "`$verifiedModInfoSha256 = 'UNBUILT'")
    }
    [IO.File]::WriteAllText($target,$text,$utf8)
}
$ownerTest=Join-Path $destination 'dev/tests/Test-ManagerOwnership.ps1'
$text=[IO.File]::ReadAllText($ownerTest).Replace('hrs_1.2.5/dev/verified/main','hrs_1.2.6/dev/verified/main').Replace("-ReleaseVersion '1.2.6'","-ReleaseVersion '1.2.7'")
[IO.File]::WriteAllText($ownerTest,$text,$utf8)
$callback=Join-Path $destination 'dev/tests/Test-ManagerCallbackWiring.ps1'
$text=[IO.File]::ReadAllText($callback).Replace('hrs126-callback-','hrs127-callback-')
[IO.File]::WriteAllText($callback,$text,$utf8)
foreach($relative in @('dev/verified/main','dev/builds','dev/qa/lane-bootstrap','dev/tmp','dev/out')){[void][IO.Directory]::CreateDirectory((Join-Path $destination $relative))}
$provenance=[ordered]@{
    schema='hrs-lane-provenance/v2';sourceHead=$head;createdUtc=[DateTime]::UtcNow.ToString('o')
    baseline='1.2.6-qa.003';baselineZipSha256='5A11D13A15CACD74752EC4F7FB9BAC3BFCDD80733EB741CD3B467917C314446B'
    returnSha256='671AC934D0564F89F800E05B2BD73A3E9B3FD5FF1FD198F111E2A8B31794117D'
    semanticVersion='1.2.7';buildId='r127';status='source-copied-runtime-unbuilt';copiedInputs=$entries
    protectedBefore=$protected
    excluded='Historical QA campaigns/contracts, builds, verified DLLs, generated output/state and version-specific qualified-reuse tests remain at their original 1.2.6 paths.'
}
[IO.File]::WriteAllText((Join-Path $destination 'BASELINE_PROVENANCE.json'),($provenance|ConvertTo-Json -Depth 8),$utf8)
foreach($entry in $protected){if((Get-FileHash -LiteralPath (Join-Path $repo $entry.path)).Hash -cne $entry.sha256){throw ('Protected input changed: '+$entry.path)}}
Write-Output ("Created hrs_1.2.7: {0} copied inputs; {1} protected files unchanged. Runtime remains unbuilt until the new pinned double build." -f $entries.Count,$protected.Count)
