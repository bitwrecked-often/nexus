[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [string]$RuntimeSourceRoot='',
    [switch]$AllowFixtureFailures
)
$ErrorActionPreference='Stop'
if([string]::IsNullOrEmpty($RuntimeSourceRoot)){
    $RuntimeSourceRoot=Join-Path (Split-Path -Parent $PSScriptRoot) 'src/runtime/main'
}
if(Test-Path -LiteralPath $EvidenceRoot){throw 'Evidence root already exists; preserve previous runs.'}
$evidencePath=[IO.Path]::GetFullPath($EvidenceRoot)
$runtimeSourcePath=[IO.Path]::GetFullPath($RuntimeSourceRoot)
[void][IO.Directory]::CreateDirectory($evidencePath)
$project=Join-Path $PSScriptRoot 'RuntimeRepairHarness/RuntimeRepairHarness.csproj'
$outputPath=Join-Path $evidencePath 'fixture-bin'
$intermediatePath=(Join-Path $evidencePath 'fixture-obj')+[IO.Path]::DirectorySeparatorChar
$buildOutput=(& dotnet build $project -c Release -o $outputPath `
    "-p:RuntimeSourceRoot=$runtimeSourcePath" "-p:BaseIntermediateOutputPath=$intermediatePath" --nologo 2>&1 | Out-String)
[IO.File]::WriteAllText((Join-Path $evidencePath 'fixture-build.txt'),$buildOutput,[Text.UTF8Encoding]::new($false))
if($LASTEXITCODE -ne 0){throw "Isolated runtime fixture build failed; see $evidencePath/fixture-build.txt"}
$raw=(& dotnet (Join-Path $outputPath 'RuntimeRepairHarness.dll') 2>&1 | Out-String)
$fixtureExitCode=$LASTEXITCODE
[IO.File]::WriteAllText((Join-Path $evidencePath 'fixture-cases.json'),$raw,[Text.UTF8Encoding]::new($false))
$cases=$raw | ConvertFrom-Json
$sourceHashes=@()
foreach($name in @('c0167.cs','c0185.cs','c0213.cs','c0181.cs','c0218.cs','PolicyV1.cs','PolicyV2.cs','BiomePreference.cs','ResultV1.cs')){
    $sourceHashes+=@{path=$name;sha256=(Get-FileHash -LiteralPath (Join-Path $runtimeSourcePath $name) -Algorithm SHA256).Hash}
}
$fixtureHashes=@()
foreach($path in @($PSCommandPath,$project,(Join-Path $PSScriptRoot 'RuntimeRepairHarness/Program.cs'),(Join-Path $PSScriptRoot 'RuntimeRepairHarness/Stubs.cs'))){
    $fixtureHashes+=@{path=[IO.Path]::GetFullPath($path);sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
}
$record=[ordered]@{
    schema='hrs-runtime-review-repairs/v1';generatedUtc=[DateTime]::UtcNow.ToString('o')
    method='Compile nine exact runtime sources against controlled engine/resolver seams; invoke actual spawn/update and intro-prefix entrypoints, actual markers, semantic snapshot and environment guard.'
    scope='Isolated DEV source control-flow evidence. Reload scenarios retain in-memory marker state under reset callback/session fields; they do not test game save serialization. Resolver, engine, Harmony, result I/O and compatibility implementations are controlled seams. No installed game writes, game launch, customer DLL qualification or independent gameplay QA.'
    coverage=[ordered]@{preservedReviewRepairScenarios=20;additionalRuntimeChainScenarios=38;runtimeSourceFiles=9;humanRuntimeChainStatus='Pending';gameplayStarted=$false}
    runtimeSourceRoot=$runtimeSourcePath;sourceHashes=$sourceHashes;fixtureHashes=$fixtureHashes
    fixtureDllSha256=(Get-FileHash -LiteralPath (Join-Path $outputPath 'RuntimeRepairHarness.dll') -Algorithm SHA256).Hash
    fixtureExitCode=$fixtureExitCode;total=$cases.total;passed=$cases.passed;failed=$cases.failed
    cases=$cases.cases;realGameWrites=0;independentQaCasesChanged=0
}
$json=$record | ConvertTo-Json -Depth 12
[IO.File]::WriteAllText((Join-Path $evidencePath 'verification.json'),$json+"`n",[Text.UTF8Encoding]::new($false))
Write-Output ([pscustomobject]@{total=$cases.total;passed=$cases.passed;failed=$cases.failed;fixtureExitCode=$fixtureExitCode;evidence=$evidencePath})
if($fixtureExitCode -ne 0 -and -not $AllowFixtureFailures){throw 'Runtime repair fixtures failed; original results preserved.'}
