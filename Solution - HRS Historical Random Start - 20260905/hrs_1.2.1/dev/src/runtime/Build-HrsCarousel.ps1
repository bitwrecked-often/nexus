[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $GameRoot,
    [string[]] $AdditionalExcludedPointIds = @()
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') {
    throw 'Run the pinned carousel build with Windows PowerShell 5.1.'
}
if (@(Get-Process -Name '7DaysToDie', '7DaysToDieServer', '7DaysToDie_EAC' -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'Game process is running; carousel build stopped.'
}

$runtimeRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceRoot = Join-Path $runtimeRoot 'carousel'
$projectRoot = Split-Path -Parent (Split-Path -Parent $runtimeRoot)
$outputRoot = Join-Path $projectRoot 'out\carousel'
$qaRoot = Join-Path $projectRoot 'qa'
$scoutingRoot = Join-Path $projectRoot 'scouting'
$dotnetPath = 'C:\Program Files\dotnet\dotnet.exe'
$compilerPath = 'C:\Program Files\dotnet\sdk\10.0.400\Roslyn\bincore\csc.dll'
$expectedDotnetSha256 = 'AB1B71FD3DD71062E074C9FAB8312081A81B7F2B3E0327C48C4D249C8D1A3135'
$expectedAssemblyCSharpMvid = [guid]'229796d0-95ca-4662-b426-1a6f1f1596ed'

function Get-Sha256([string] $Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$game = [System.IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
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
$gameAssembly = [System.Reflection.Assembly]::ReflectionOnlyLoadFrom(
    (Join-Path $managed 'Assembly-CSharp.dll'))
if ($gameAssembly.ManifestModule.ModuleVersionId -ne $expectedAssemblyCSharpMvid) {
    throw 'Assembly-CSharp MVID changed.'
}

[void][System.IO.Directory]::CreateDirectory($outputRoot)
$catalogBuild = & (Join-Path $qaRoot 'New-HrsCarouselCatalog.ps1') `
    -CatalogCsv (Join-Path $scoutingRoot 'navezgane_poi_catalog_v3.2-b9.csv') `
    -RejectionsJson (Join-Path $qaRoot 'carousel-rejections.json') `
    -OutputDirectory $outputRoot `
    -AdditionalExcludedPointIds $AdditionalExcludedPointIds
$sources = @(
    (Join-Path $sourceRoot 'CarouselMod.cs'),
    (Join-Path $outputRoot 'GeneratedCarouselCatalog.cs')
)
$dll = Join-Path $outputRoot 'hrs_carousel_qa.dll'
$buildOne = Join-Path $outputRoot 'build-1'
$buildTwo = Join-Path $outputRoot 'build-2'
[void][System.IO.Directory]::CreateDirectory($buildOne)
[void][System.IO.Directory]::CreateDirectory($buildTwo)
$dllOne = Join-Path $buildOne 'hrs_carousel_qa.dll'
$dllTwo = Join-Path $buildTwo 'hrs_carousel_qa.dll'

function Invoke-CarouselBuild([string] $Destination) {
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
    foreach ($source in $sources) { [void]$arguments.Add($source) }
    & $dotnetPath $compilerPath @arguments
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        throw "Carousel build failed with exit code $LASTEXITCODE."
    }
}
Invoke-CarouselBuild $dllOne
Invoke-CarouselBuild $dllTwo
$hashOne = Get-Sha256 $dllOne
$hashTwo = Get-Sha256 $dllTwo
if ($hashOne -cne $hashTwo) {
    throw 'Deterministic carousel double build mismatch.'
}
[System.IO.File]::Copy($dllOne, $dll, $true)
[System.IO.Directory]::Delete($buildOne, $true)
[System.IO.Directory]::Delete($buildTwo, $true)
Copy-Item -LiteralPath (Join-Path $sourceRoot 'ModInfo.xml') -Destination $outputRoot -Force
[pscustomobject][ordered]@{
    artifact = $dll
    bytes = (Get-Item -LiteralPath $dll).Length
    sha256 = Get-Sha256 $dll
    runtimeSourceSha256 = Get-Sha256 $sources[0]
    generatedCatalogSha256 = Get-Sha256 $sources[1]
    activePointIdsSha256 = Get-Sha256 (Join-Path $outputRoot 'active-point-ids.txt')
    sourcePointCount = $catalogBuild.sourceCount
    engineSmallPointCount = $catalogBuild.engineSmallPointCount
    rejectedPointCount = $catalogBuild.rejectedCount
    activePointCount = $catalogBuild.activeCount
    firstPoint = $catalogBuild.firstPoint
    lastPoint = $catalogBuild.lastPoint
    assemblyCSharpMvid = $gameAssembly.ManifestModule.ModuleVersionId.ToString()
    deterministicDoubleBuild = $true
}
