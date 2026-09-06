[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $GameRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Run this pinned build with Windows PowerShell 5.1.' }

$runtimeRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent $runtimeRoot)
$sourceRoot = Join-Path $runtimeRoot 'BitWrecked.HistoricalRandomStart'
$outputRoot = Join-Path $projectRoot 'BUILD_OUTPUT'
$stageRoot = Join-Path $projectRoot 'TEMP_BUILD_STAGE'
$dotnetPath = 'C:\Program Files\dotnet\dotnet.exe'
$compilerPath = 'C:\Program Files\dotnet\sdk\10.0.400\Roslyn\bincore\csc.dll'
$expectedDotnetSha256 = 'AB1B71FD3DD71062E074C9FAB8312081A81B7F2B3E0327C48C4D249C8D1A3135'
$expectedAssemblyCSharpMvid = [guid]'acb580d9-e1ab-497d-a8dc-47e47c1fc300'

function Get-CanonicalPath {
    param([string] $Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Test-ContainedPath {
    param([string] $Parent, [string] $Child)
    $prefix = (Get-CanonicalPath $Parent) + [System.IO.Path]::DirectorySeparatorChar
    return (Get-CanonicalPath $Child).StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-Sha256 {
    param([string] $Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$project = Get-CanonicalPath $projectRoot
$game = Get-CanonicalPath $GameRoot
$output = Get-CanonicalPath $outputRoot
$stage = Get-CanonicalPath $stageRoot
if (-not (Test-ContainedPath -Parent $project -Child $output) -or -not (Test-ContainedPath -Parent $project -Child $stage)) { throw 'Build roots escaped the project.' }
if (-not (Test-Path -LiteralPath (Join-Path $game '7DaysToDie.exe') -PathType Leaf)) { throw 'Game root is not recognized.' }
if (-not (Test-Path -LiteralPath $dotnetPath -PathType Leaf) -or -not (Test-Path -LiteralPath $compilerPath -PathType Leaf)) { throw 'Pinned compiler is missing.' }
if ((Get-Sha256 $dotnetPath) -cne $expectedDotnetSha256) { throw 'Pinned dotnet host hash changed.' }
if (@(Get-Process -Name '7DaysToDie', '7DaysToDieServer', '7DaysToDie_EAC' -ErrorAction SilentlyContinue).Count -gt 0) { throw 'Game process is running; build stopped.' }

$managed = Join-Path $game '7DaysToDie_Data\Managed'
$references = @(
    'mscorlib.dll',
    'netstandard.dll',
    'System.dll',
    'System.Core.dll',
    'Assembly-CSharp.dll',
    'UnityEngine.CoreModule.dll',
    'LogLibrary.dll'
) | ForEach-Object { Join-Path $managed $_ }
foreach ($reference in $references) { if (-not (Test-Path -LiteralPath $reference -PathType Leaf)) { throw "Pinned reference missing: $([System.IO.Path]::GetFileName($reference))" } }

$assemblyCSharp = [System.Reflection.Assembly]::ReflectionOnlyLoadFrom((Join-Path $managed 'Assembly-CSharp.dll'))
if ($assemblyCSharp.ManifestModule.ModuleVersionId -ne $expectedAssemblyCSharpMvid) { throw 'Assembly-CSharp MVID changed.' }

$sourceNames = @(
    'AtomicResultWriter.cs',
    'CompatibilityGuard.cs',
    'HistoricalRandomStartModApi.cs',
    'MarkerState.cs',
    'OwnedBridgePaths.cs',
    'PendingPlacement.cs',
    'PolicyV1.cs',
    'ResultV1.cs',
    'RuntimeEnvironmentGuard.cs',
    'SanitizedRuntimeLog.cs',
    'SemanticSnapshot.cs'
)
$sources = @($sourceNames | ForEach-Object { Join-Path $sourceRoot $_ })
foreach ($source in $sources) { if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Release source missing: $([System.IO.Path]::GetFileName($source))" } }

[void][System.IO.Directory]::CreateDirectory($output)
[void][System.IO.Directory]::CreateDirectory($stage)
$attempt = 'alpha-core-' + [guid]::NewGuid().ToString('N')
$attemptRoot = Join-Path $stage $attempt
$buildOne = Join-Path $attemptRoot 'build-1'
$buildTwo = Join-Path $attemptRoot 'build-2'
[void][System.IO.Directory]::CreateDirectory($buildOne)
[void][System.IO.Directory]::CreateDirectory($buildTwo)

function Invoke-PinnedBuild {
    param([string] $Destination)
    $arguments = New-Object System.Collections.Generic.List[string]
    foreach ($value in @('/nologo','/noconfig','/nostdlib+','/target:library','/platform:anycpu','/langversion:7.3','/optimize+','/checked+','/warn:4','/warnaserror+','/deterministic+','/debug-')) { [void]$arguments.Add($value) }
    [void]$arguments.Add('/out:' + $Destination)
    foreach ($reference in $references) { [void]$arguments.Add('/reference:' + $reference) }
    foreach ($source in $sources) { [void]$arguments.Add($source) }
    & $dotnetPath $compilerPath @arguments
    if ($LASTEXITCODE -ne 0 -or -not [System.IO.File]::Exists($Destination)) { throw "Release build failed with exit code $LASTEXITCODE." }
}

$dllOne = Join-Path $buildOne 'HistoricalRandomStart.dll'
$dllTwo = Join-Path $buildTwo 'HistoricalRandomStart.dll'
Invoke-PinnedBuild -Destination $dllOne
Invoke-PinnedBuild -Destination $dllTwo
$hashOne = Get-Sha256 $dllOne
$hashTwo = Get-Sha256 $dllTwo
if ($hashOne -cne $hashTwo) { throw 'Deterministic double build mismatch.' }

$candidateRoot = Join-Path $output $attempt
$payloadRoot = Join-Path $candidateRoot 'BitWrecked_HistoricalRandomStart'
$bridgeRoot = Join-Path $payloadRoot 'Bridge'
[void][System.IO.Directory]::CreateDirectory($bridgeRoot)
[System.IO.File]::Copy($dllOne, (Join-Path $payloadRoot 'HistoricalRandomStart.dll'), $false)
[System.IO.File]::Copy((Join-Path $sourceRoot 'ModInfo.xml'), (Join-Path $payloadRoot 'ModInfo.xml'), $false)

$record = [pscustomobject][ordered]@{
    schema = 'hrs-release-build/v1'
    attempt = $attempt
    createdUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [System.Globalization.CultureInfo]::InvariantCulture)
    sourceFiles = $sourceNames
    sourceHashes = @($sources | ForEach-Object { [pscustomobject]@{ path=[System.IO.Path]::GetFileName($_); sha256=Get-Sha256 $_ } })
    compiler = [pscustomobject]@{ dotnet=$dotnetPath; dotnetSha256=Get-Sha256 $dotnetPath; csc=$compilerPath; cscSha256=Get-Sha256 $compilerPath }
    references = @($references | ForEach-Object { [pscustomobject]@{ name=[System.IO.Path]::GetFileName($_); sha256=Get-Sha256 $_ } })
    assemblyCSharpMvid = $assemblyCSharp.ManifestModule.ModuleVersionId.ToString()
    dllBytes = (New-Object System.IO.FileInfo($dllOne)).Length
    dllSha256 = $hashOne
    deterministicDoubleBuild = $true
    candidateRoot = $candidateRoot
}
$recordPath = Join-Path $candidateRoot 'build-record.v1.json'
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($recordPath, (ConvertTo-Json -InputObject $record -Depth 6), $utf8)
$record
