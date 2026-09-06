[CmdletBinding()]
param(
    [string] $GameRoot = 'C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die',
    [ValidateSet('Wasteland', 'Desert', 'BurntForest', 'PineForest')] [string] $Biome = 'Wasteland'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'Run the biome QA build with Windows PowerShell 5.1.'
}
if (@(Get-Process -Name '7DaysToDie', '7DaysToDieServer', '7DaysToDie_EAC' `
    -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'Close the game before building a biome QA case.'
}

$case = if ($Biome -ceq 'PineForest') {
    [pscustomobject][ordered]@{
        slug = 'pine'; biomeName = 'pine_forest'; caseId = 'HRS-BIOME-PINE'
        gameName = 'HRS_BIOME_120_PINE_001'; point = 'NVG-0281'
        prefab = 'hospital_01'; displayName = 'Navezgane General Hospital'
        x = 1101; y = 61; z = 587; protectionFamily = 0; trader = 'TP05'
    }
}
elseif ($Biome -ceq 'BurntForest') {
    [pscustomobject][ordered]@{
        slug = 'burnt'; biomeName = 'burnt_forest'; caseId = 'HRS-BIOME-BURNT'
        gameName = 'HRS_BIOME_120_BURNT_001'; point = 'NVG-0285'
        prefab = 'hotel_04'; displayName = 'Calm Inn'
        x = 1828; y = 61; z = -747; protectionFamily = 1; trader = 'TP03'
    }
}
elseif ($Biome -ceq 'Desert') {
    [pscustomobject][ordered]@{
        slug = 'desert'; biomeName = 'desert'; caseId = 'HRS-BIOME-DESERT'
        gameName = 'HRS_BIOME_120_DESERT_002'; point = 'NVG-0282'
        prefab = 'hotel_01'; displayName = 'Hotel Zombona'
        x = 541; y = 61; z = -1434; protectionFamily = 2; trader = 'TP01'
    }
}
else {
    [pscustomobject][ordered]@{
        slug = 'wasteland'; biomeName = 'wasteland'; caseId = 'HRS-BIOME-WASTE'
        gameName = 'HRS_BIOME_120_WASTE_001'; point = 'NVG-0286'
        prefab = 'hotel_ostrich'; displayName = 'Ostrich Hotel'
        x = -1923; y = 61; z = -1912; protectionFamily = 4; trader = 'TP04'
    }
}

$qaRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
$devRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $qaRoot))
$runtimeRoot = Join-Path $devRoot 'src\runtime'
$sourceRoot = Join-Path $runtimeRoot 'main'
$outputRoot = Join-Path $devRoot ('out\biome-' + $case.slug)
$game = [System.IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$dotnetPath = 'C:\Program Files\dotnet\dotnet.exe'
$compilerPath = 'C:\Program Files\dotnet\sdk\10.0.400\Roslyn\bincore\csc.dll'
$expectedDotnetSha256 = 'AB1B71FD3DD71062E074C9FAB8312081A81B7F2B3E0327C48C4D249C8D1A3135'
$expectedAssemblyCSharpMvid = [guid]'229796d0-95ca-4662-b426-1a6f1f1596ed'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Get-Sha256([string] $Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

if (-not (Test-Path -LiteralPath (Join-Path $game '7DaysToDie.exe') -PathType Leaf)) {
    throw 'Game root is not recognized.'
}
if ((Get-Sha256 $dotnetPath) -cne $expectedDotnetSha256) {
    throw 'Pinned dotnet host hash changed.'
}
$managed = Join-Path $game '7DaysToDie_Data\Managed'
$references = @(
    'mscorlib.dll', 'netstandard.dll', 'System.dll', 'System.Core.dll',
    'Assembly-CSharp.dll', 'UnityEngine.CoreModule.dll', 'LogLibrary.dll'
) | ForEach-Object { Join-Path $managed $_ }
foreach ($reference in $references) {
    if (-not (Test-Path -LiteralPath $reference -PathType Leaf)) {
        throw "Pinned reference missing: $([System.IO.Path]::GetFileName($reference))"
    }
}
$assembly = [Reflection.Assembly]::ReflectionOnlyLoadFrom(
    (Join-Path $managed 'Assembly-CSharp.dll'))
if ($assembly.ManifestModule.ModuleVersionId -ne $expectedAssemblyCSharpMvid) {
    throw 'Assembly-CSharp MVID changed.'
}

$attempt = $case.slug + '-case-' + [guid]::NewGuid().ToString('N')
$attemptRoot = Join-Path $outputRoot $attempt
$generatedRoot = Join-Path $attemptRoot 'generated'
$buildOne = Join-Path $attemptRoot 'build-1'
$buildTwo = Join-Path $attemptRoot 'build-2'
$payloadRoot = Join-Path $attemptRoot 'mod'
foreach ($directory in @($generatedRoot, $buildOne, $buildTwo, $payloadRoot,
    (Join-Path $payloadRoot 'Bridge'))) {
    [void][System.IO.Directory]::CreateDirectory($directory)
}

$sourceNames = @(
    'c0140.cs', 'c0147.cs', 'c0167.cs', 'c0181.cs', 'c0184.cs', 'c0185.cs',
    'PolicyV1.cs', 'ResultV1.cs', 'c0213.cs', 'c0217.cs', 'c0218.cs'
)
$generatedSources = New-Object System.Collections.Generic.List[string]
foreach ($name in $sourceNames) {
    $source = Join-Path $sourceRoot $name
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Release source missing: $name"
    }
    $text = [System.IO.File]::ReadAllText($source)
    if ($name -ceq 'c0213.cs') {
        $oldPool = 'private static readonly int[] ApprovedPointIndices = { 0, 1 };'
        $newPool = 'private static readonly int[] ApprovedPointIndices = { 12 };'
        if (-not $text.Contains($oldPool)) { throw 'Release approved-pool token drifted.' }
        $text = $text.Replace($oldPool, $newPool)
        $oldLast = 'new CuratedStartPoint("NG12", "Southern frontier", 0, 74, -2400)'
        $newLast = $oldLast + ",`r`n" +
            ('            new CuratedStartPoint("{0}", "{1}", {2}, {3}, {4})' -f
                $case.point, $case.displayName, $case.x, $case.y, $case.z)
        if (-not $text.Contains($oldLast)) { throw 'Release catalog tail drifted.' }
        $text = $text.Replace($oldLast, $newLast)
    }
    elseif ($name -ceq 'c0217.cs') {
        $oldLog = '"NG06", "NG07", "NG08", "NG09", "NG10", "NG11", "NG12",'
        $newLog = $oldLog + "`r`n" + ('                "{0}",' -f $case.point)
        if (-not $text.Contains($oldLog)) { throw 'Runtime point-log token drifted.' }
        $text = $text.Replace($oldLog, $newLog)
    }
    $generated = Join-Path $generatedRoot $name
    [System.IO.File]::WriteAllText($generated, $text, $utf8)
    [void]$generatedSources.Add($generated)
}

function Invoke-BiomeBuild([string] $Destination) {
    $arguments = New-Object System.Collections.Generic.List[string]
    foreach ($value in @('/nologo','/noconfig','/nostdlib+','/target:library',
        '/platform:anycpu','/langversion:7.3','/optimize+','/checked+',
        '/warn:4','/warnaserror+','/deterministic+','/debug-')) {
        [void]$arguments.Add($value)
    }
    [void]$arguments.Add('/out:' + $Destination)
    foreach ($reference in $references) {
        [void]$arguments.Add('/reference:' + $reference)
    }
    foreach ($source in $generatedSources) { [void]$arguments.Add($source) }
    & $dotnetPath $compilerPath @arguments
    if ($LASTEXITCODE -ne 0 -or -not [System.IO.File]::Exists($Destination)) {
        throw "Biome QA build failed with exit code $LASTEXITCODE."
    }
}

$dllOne = Join-Path $buildOne 'd0163.dll'
$dllTwo = Join-Path $buildTwo 'd0163.dll'
Invoke-BiomeBuild $dllOne
Invoke-BiomeBuild $dllTwo
$hashOne = Get-Sha256 $dllOne
$hashTwo = Get-Sha256 $dllTwo
if ($hashOne -cne $hashTwo) { throw 'Deterministic biome build mismatch.' }

[System.IO.File]::Copy($dllOne, (Join-Path $payloadRoot 'd0163.dll'), $false)
[System.IO.File]::Copy((Join-Path $sourceRoot 'ModInfo.xml'),
    (Join-Path $payloadRoot 'ModInfo.xml'), $false)
$record = [pscustomobject][ordered]@{
    schema = 'hrs-biome-qa-build/v1'
    caseId = $case.caseId
    gameName = $case.gameName
    forcedPoint = $case.point
    prefab = $case.prefab
    catalogPosition = [pscustomobject]@{ x=$case.x; y=$case.y; z=$case.z }
    expectedBiome = $case.biomeName
    expectedProtectionFamily = $case.protectionFamily
    expectedTrader = $case.trader
    attempt = $attempt
    createdUtc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    assemblyCSharpMvid = $assembly.ManifestModule.ModuleVersionId.ToString()
    dllBytes = (Get-Item -LiteralPath $dllOne).Length
    dllSha256 = $hashOne
    modInfoSha256 = Get-Sha256 (Join-Path $payloadRoot 'ModInfo.xml')
    deterministicDoubleBuild = $true
    releaseSourceHashes = @($sourceNames | ForEach-Object {
        [pscustomobject]@{ path=$_; sha256=Get-Sha256 (Join-Path $sourceRoot $_) }
    })
    generatedSourceHashes = @($generatedSources | ForEach-Object {
        [pscustomobject]@{ path=[IO.Path]::GetFileName($_); sha256=Get-Sha256 $_ }
    })
    payloadRoot = $payloadRoot
}
[System.IO.File]::WriteAllText((Join-Path $attemptRoot 'build-record.json'),
    (ConvertTo-Json $record -Depth 6), $utf8)
$record
