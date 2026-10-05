[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $PayloadRoot,
    [string] $OldPayloadRoot = ''
)

$ErrorActionPreference = 'Stop'
$lane = Split-Path -Parent $PSScriptRoot
$repo = Split-Path -Parent (Split-Path -Parent $lane)
if ([string]::IsNullOrWhiteSpace($OldPayloadRoot)) {
    $OldPayloadRoot = Join-Path $repo 'hrs_1.2.6/dev/verified/main'
}
$launcher = Join-Path $lane 'src/launcher'
Import-Module (Join-Path $launcher 'm0161.psm1') -Force
Import-Module (Join-Path $launcher 'm0162.psm1') -Force
Import-Module (Join-Path $launcher 'm0161.psm1') -Force

function Check([bool] $condition, [string] $label) {
    if (-not $condition) { throw "FAIL: $label" }
    Write-Output "PASS: $label"
}

$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')
$fixture = [IO.Path]::GetFullPath((Join-Path $tempRoot ('hrs126-manager-fixture-' + [guid]::NewGuid().ToString('N'))))
if (-not $fixture.StartsWith($tempRoot + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture escaped temp root.' }
try {
    $game = Join-Path $fixture 'Game'
    $mods = Join-Path $game 'Mods'
    $release = Join-Path $mods 'BitWrecked_HistoricalRandomStart'
    $other = Join-Path $mods 'UnrelatedMod'
    [void][IO.Directory]::CreateDirectory($other)
    [IO.File]::WriteAllText((Join-Path $game '7DaysToDie.exe'), 'fixture')
    [IO.File]::WriteAllText((Join-Path $other 'ModInfo.xml'), 'unrelated')
    $otherHash = (Get-FileHash -LiteralPath (Join-Path $other 'ModInfo.xml')).Hash

    $manifest = New-HrsDeploymentManifest -PayloadRoot $PayloadRoot -ReleaseVersion '1.2.7'
    $fresh = Test-HrsDeploymentInventory -GameRoot $game -Manifest $manifest
    Check ($fresh.Valid -and $fresh.State -ceq 'NotInstalled') 'fresh installation is detected'

    [void][IO.Directory]::CreateDirectory($release)
    foreach ($name in @('d0163.dll','ModInfo.xml')) {
        [IO.File]::Copy((Join-Path $PayloadRoot $name), (Join-Path $release $name))
    }
    $installed = Test-HrsDeploymentInventory -GameRoot $game -Manifest $manifest
    Check ($installed.Valid -and $installed.State -ceq 'InstalledValid') 'exact payload is recognized'

    foreach ($name in @('d0163.dll','ModInfo.xml')) {
        [IO.File]::Copy((Join-Path $OldPayloadRoot $name),
            (Join-Path $release $name), $true)
    }
    $upgrade = Test-HrsDeploymentInventory -GameRoot $game -Manifest $manifest
    $owned = Test-HrsRemovalOwnership -GameRoot $game
    Check (-not $upgrade.Valid -and $upgrade.State -ceq 'Drift' -and
        $upgrade.Reason -ceq 'DEPLOYMENT_STATIC_FILE_DRIFT' -and
        $owned.Valid -and $owned.State -ceq 'Owned') 'older owned payload is eligible for upgrade'
    foreach ($name in @('d0163.dll','ModInfo.xml')) {
        [IO.File]::Copy((Join-Path $PayloadRoot $name),
            (Join-Path $release $name), $true)
    }
    $upgraded = Test-HrsDeploymentInventory -GameRoot $game -Manifest $manifest
    Check ($upgraded.Valid -and $upgraded.State -ceq 'InstalledValid') 'upgraded payload matches exact manifest'

    $bridge=Get-HrsBridgePaths -GameRoot $game
    [void][IO.Directory]::CreateDirectory($bridge.BridgeRoot)
    $policy=New-HrsPolicy -Revision 1 -GameName 'Owned fixture' -Mode RandomSafe -Selection Chosen -ChosenBiome 8
    [void](Write-HrsAppliedPolicy -GameRoot $game -Policy $policy)
    Check (Test-HrsDeploymentInventory -GameRoot $game -Manifest $manifest).Valid 'v2 policy belongs to exact deployment inventory'

    [IO.File]::WriteAllText((Join-Path $release 'user-note.txt'), 'unowned')
    $conflict = Test-HrsRemovalOwnership -GameRoot $game
    Check (-not $conflict.Valid -and $conflict.State -ceq 'Conflict') 'removal refuses an unknown file'
    [IO.File]::Delete((Join-Path $release 'user-note.txt'))

    $processState = [pscustomobject]@{ Game = 'Closed'; Steam = 'Running' }
    $removed = Invoke-HrsRemoveFromGame -GameRoot $game -Manifest $manifest `
        -ProcessState $processState -Confirmed
    Check ($removed.Removed -and -not [IO.Directory]::Exists($release)) 'owned removal clears only the release directory'
    Check ([IO.File]::Exists((Join-Path $game '7DaysToDie.exe')) -and
        (Get-FileHash -LiteralPath (Join-Path $other 'ModInfo.xml')).Hash -ceq $otherHash) `
        'game executable and unrelated mod remain unchanged'
}
finally {
    if ([IO.Directory]::Exists($fixture)) {
        Remove-Item -LiteralPath $fixture -Recurse -Force
    }
}
