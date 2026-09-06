[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$testRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $testRoot
$launcherRoot = Join-Path $projectRoot 'src\launcher'
$corePath = Join-Path $launcherRoot 'm0161.psm1'
$statePath = Join-Path $launcherRoot 'm0166.psm1'
$copyPath = Join-Path $launcherRoot 'm0160.psm1'
$deploymentPath = Join-Path $launcherRoot 'm0162.psm1'

foreach ($requiredPath in @($corePath, $statePath, $copyPath, $deploymentPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required Alpha Core module is missing: $requiredPath"
    }
}

Import-Module -Name $corePath -Force
Import-Module -Name $statePath -Force
Import-Module -Name $copyPath -Force
Import-Module -Name $deploymentPath -Force
# Deployment imports Core into its own module scope with -Force. Re-import Core
# last so the fixture builder also has the public bridge serializers available.
Import-Module -Name $corePath -Force

$script:PassCount = 0
$script:FailCount = 0
$script:SkipCount = 0
$script:FailureDetails = New-Object System.Collections.Generic.List[string]
$script:CreatedReparsePaths = New-Object System.Collections.Generic.List[string]

function Assert-HrsTrue {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Assert-HrsFalse {
    param([bool] $Condition, [string] $Message)
    if ($Condition) { throw $Message }
}

function Assert-HrsEqual {
    param($Actual, $Expected, [string] $Message)
    if ($Actual -ne $Expected) { throw "$Message Expected '$Expected'; actual '$Actual'." }
}

function Assert-HrsThrows {
    param([scriptblock] $Action, [string] $ExpectedMessage = '')

    $caught = $null
    try { $null = & $Action } catch { $caught = $_ }
    if ($null -eq $caught) { throw 'Expected an exception, but the operation succeeded.' }
    if (-not [string]::IsNullOrEmpty($ExpectedMessage) -and
        $caught.Exception.Message.IndexOf($ExpectedMessage, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "Expected exception containing '$ExpectedMessage'; actual '$($caught.Exception.Message)'."
    }
}

function Invoke-HrsCase {
    param([string] $Id, [scriptblock] $Test)
    try {
        & $Test
        $script:PassCount++
        Write-Output "PASS $Id"
    }
    catch {
        $script:FailCount++
        $detail = "FAIL $Id :: $($_.Exception.Message)"
        [void] $script:FailureDetails.Add($detail)
        Write-Output $detail
    }
}

function Write-HrsSkip {
    param([string] $Id, [string] $Reason)
    $script:SkipCount++
    Write-Output "SKIP $Id :: $Reason"
}

function New-HrsDecisionCase {
    param([hashtable] $Changes = @{})

    $values = [ordered]@{
        buildCompatible = $true
        authorityConfirmed = $true
        localSinglePlayer = $true
        runtimeLaneConfirmed = $true
        policyValid = $true
        targetMatch = $true
        lifecycle = 'NewGame'
        markerState = 'Absent'
        mode = 'Random'
        entityResolved = $true
        markerApiAvailable = $true
    }
    foreach ($key in $Changes.Keys) { $values[$key] = $Changes[$key] }
    return [pscustomobject] $values
}

function Copy-HrsShallowObject {
    param([psobject] $Value)
    $copy = [ordered]@{}
    foreach ($property in $Value.PSObject.Properties) { $copy[$property.Name] = $property.Value }
    return [pscustomobject] $copy
}

function Copy-HrsManifest {
    param([psobject] $Manifest)

    $files = @()
    foreach ($entry in @($Manifest.files)) {
        $files += [pscustomobject][ordered]@{
            path = $entry.path
            bytes = $entry.bytes
            sha256 = $entry.sha256
        }
    }
    return [pscustomobject][ordered]@{
        schema = $Manifest.schema
        releaseVersion = $Manifest.releaseVersion
        releaseFolder = $Manifest.releaseFolder
        files = $files
    }
}

function Assert-HrsNoGameplayAction {
    param([psobject] $Decision, [string] $Context)

    Assert-HrsFalse ([bool]$Decision.reserveMarker) "$Context reserved a marker."
    Assert-HrsFalse ([bool]$Decision.selectCandidate) "$Context selected a candidate."
    Assert-HrsFalse ([bool]$Decision.placePlayer) "$Context placed a player."
}

function Write-HrsFixtureText {
    param([string] $Path, [AllowEmptyString()] [string] $Text)
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}

function Get-HrsFixtureHash {
    param([string] $Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '') }
    finally { $stream.Dispose(); $sha.Dispose() }
}

function Get-HrsFixtureTreeDigest {
    param([string] $Root)

    if (-not [System.IO.Directory]::Exists($Root)) { return 'ABSENT' }
    $resolved = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
    $rows = New-Object System.Collections.Generic.List[string]
    foreach ($file in @([System.IO.Directory]::EnumerateFiles($resolved, '*', [System.IO.SearchOption]::AllDirectories) | Sort-Object)) {
        $relative = $file.Substring($resolved.Length).TrimStart('\').Replace('\', '/')
        $info = New-Object System.IO.FileInfo($file)
        [void] $rows.Add("$relative|$($info.Length)|$(Get-HrsFixtureHash $file)")
    }
    $text = $rows -join "`n"
    $bytes = (New-Object System.Text.UTF8Encoding($false, $true)).GetBytes($text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '') }
    finally { $sha.Dispose() }
}

function New-HrsFakeGameRoot {
    param([string] $Path)
    [void] [System.IO.Directory]::CreateDirectory($Path)
    [System.IO.File]::WriteAllBytes((Join-Path $Path '7DaysToDie.exe'), [byte[]]@(0x48, 0x52, 0x53))
    return $Path
}

function New-HrsDeploymentFixture {
    param(
        [string] $Root,
        [switch] $Installed,
        [switch] $WithBridge
    )

    [void] [System.IO.Directory]::CreateDirectory($Root)
    $payloadRoot = Join-Path $Root 'p'
    $gameRoot = Join-Path $Root 'g'
    [void] [System.IO.Directory]::CreateDirectory($payloadRoot)
    $null = New-HrsFakeGameRoot $gameRoot
    [System.IO.File]::WriteAllBytes((Join-Path $payloadRoot 'd0163.dll'), [byte[]](1..32))
    Write-HrsFixtureText -Path (Join-Path $payloadRoot 'ModInfo.xml') -Text '<xml><Name value="BitWrecked_HistoricalRandomStart" /></xml>'
    $constructorSucceeded = $true
    try {
        $manifest = New-HrsDeploymentManifest -PayloadRoot $payloadRoot -ReleaseVersion '0.0.1-alpha.1'
    }
    catch {
        # Keep later inventory/removal cases independent when the constructor
        # itself is the defect under test. This fallback is an exact test-only
        # manifest made from the same bounded fixture bytes.
        $constructorSucceeded = $false
        $dllPath = Join-Path $payloadRoot 'd0163.dll'
        $modInfoPath = Join-Path $payloadRoot 'ModInfo.xml'
        $dllInfo = New-Object System.IO.FileInfo($dllPath)
        $modInfo = New-Object System.IO.FileInfo($modInfoPath)
        $manifest = [pscustomobject][ordered]@{
            schema = 'hrs-deployment-manifest/v1'
            releaseVersion = '0.0.1-alpha.1'
            releaseFolder = 'BitWrecked_HistoricalRandomStart'
            files = @(
                [pscustomobject][ordered]@{ path='d0163.dll'; bytes=[UInt64]$dllInfo.Length; sha256=Get-HrsFixtureHash $dllPath },
                [pscustomobject][ordered]@{ path='ModInfo.xml'; bytes=[UInt64]$modInfo.Length; sha256=Get-HrsFixtureHash $modInfoPath }
            )
        }
    }
    $paths = Get-HrsBridgePaths -GameRoot $gameRoot

    if ($Installed) {
        [void] [System.IO.Directory]::CreateDirectory($paths.ReleaseRoot)
        [System.IO.File]::Copy((Join-Path $payloadRoot 'd0163.dll'), (Join-Path $paths.ReleaseRoot 'd0163.dll'))
        [System.IO.File]::Copy((Join-Path $payloadRoot 'ModInfo.xml'), (Join-Path $paths.ReleaseRoot 'ModInfo.xml'))
    }
    if ($WithBridge) {
        if (-not $Installed) { throw 'Fixture WithBridge requires Installed.' }
        [void] [System.IO.Directory]::CreateDirectory($paths.BridgeRoot)
        $fixedUtc = [datetime]::SpecifyKind([datetime]'2026-08-21T12:34:56.789', [System.DateTimeKind]::Utc)
        $policy = New-HrsPolicy -Revision 1 -GameName 'HRS Fixture' -Mode Standard -WrittenUtc $fixedUtc
        $policyJson = ConvertTo-HrsPolicyJson -Policy $policy
        $result = New-HrsResult -PolicyRevision 1 -PolicyDigest $policy.policyDigest -Outcome BYPASSED -Reason STANDARD_BYPASS -MarkerState NOT_APPLICABLE -ObservedUtc $fixedUtc
        Write-HrsFixtureText -Path $paths.PolicyPath -Text $policyJson
        Write-HrsFixtureText -Path $paths.ResultPath -Text (ConvertTo-HrsResultJson -Result $result)
    }

    return [pscustomobject]@{
        Root = $Root
        PayloadRoot = $payloadRoot
        GameRoot = $gameRoot
        Manifest = $manifest
        Paths = $paths
        ConstructorSucceeded = $constructorSucceeded
    }
}

$fixtureParent = Join-Path $projectRoot '_s'
$fixtureLeaf = [guid]::NewGuid().ToString('N').Substring(0, 8)
$fixtureRoot = Join-Path $fixtureParent $fixtureLeaf
[void] [System.IO.Directory]::CreateDirectory($fixtureRoot)

try {
    # Canonical PEG decision grid and strict one-shot permission boundary.
    $pegCases = @(
        @{ Id='PEG-01-build'; Changes=@{buildCompatible=$false}; Peg='PEG-01'; Outcome='INCOMPATIBLE'; Reason='ENVIRONMENT_INCOMPATIBLE'; Marker='NOT_APPLICABLE' },
        @{ Id='PEG-01-authority'; Changes=@{authorityConfirmed=$false}; Peg='PEG-01'; Outcome='INCOMPATIBLE'; Reason='ENVIRONMENT_INCOMPATIBLE'; Marker='NOT_APPLICABLE' },
        @{ Id='PEG-01-locality'; Changes=@{localSinglePlayer=$false}; Peg='PEG-01'; Outcome='INCOMPATIBLE'; Reason='ENVIRONMENT_INCOMPATIBLE'; Marker='NOT_APPLICABLE' },
        @{ Id='PEG-01-entity'; Changes=@{entityResolved=$false}; Peg='PEG-01'; Outcome='REJECTED'; Reason='ENTITY_UNRESOLVED'; Marker='NOT_APPLICABLE' },
        @{ Id='PEG-01-marker-api'; Changes=@{markerApiAvailable=$false}; Peg='PEG-01'; Outcome='REJECTED'; Reason='MARKER_API_UNAVAILABLE'; Marker='NOT_APPLICABLE' },
        @{ Id='PEG-01E-runtime-lane'; Changes=@{runtimeLaneConfirmed=$false}; Peg='PEG-01E'; Outcome='INCOMPATIBLE'; Reason='RUNTIME_LANE_UNCONFIRMED'; Marker='NOT_APPLICABLE' },
        @{ Id='PEG-02-policy-invalid'; Changes=@{policyValid=$false}; Peg='PEG-02'; Outcome='REJECTED'; Reason='POLICY_REJECTED'; Marker='NOT_APPLICABLE' },
        @{ Id='PEG-02-mode-invalid'; Changes=@{mode='Chaos'}; Peg='PEG-02'; Outcome='REJECTED'; Reason='POLICY_REJECTED'; Marker='NOT_APPLICABLE' },
        @{ Id='PEG-03-name-mismatch'; Changes=@{targetMatch=$false}; Peg='PEG-03'; Outcome='REJECTED'; Reason='GAME_NAME_MISMATCH'; Marker='ABSENT' },
        @{ Id='PEG-04-standard'; Changes=@{mode='Standard'}; Peg='PEG-04'; Outcome='BYPASSED'; Reason='STANDARD_BYPASS'; Marker='NOT_APPLICABLE' },
        @{ Id='PEG-05-random'; Changes=@{}; Peg='PEG-05'; Outcome='PERMITTED'; Reason='RANDOM_FIRST_ARRIVAL_PERMITTED'; Marker='ABSENT'; Permitted=$true },
        @{ Id='PEG-08-loaded'; Changes=@{lifecycle='LoadedGame'}; Peg='PEG-08'; Outcome='REJECTED'; Reason='LIFECYCLE_REJECTED'; Marker='Absent' },
        @{ Id='PEG-08-death'; Changes=@{lifecycle='Died'}; Peg='PEG-08'; Outcome='REJECTED'; Reason='LIFECYCLE_REJECTED'; Marker='Absent' },
        @{ Id='PEG-08-reconnect'; Changes=@{lifecycle='Reconnect'}; Peg='PEG-08'; Outcome='REJECTED'; Reason='LIFECYCLE_REJECTED'; Marker='Absent' },
        @{ Id='PEG-11-reserved'; Changes=@{markerState='Reserved'}; Peg='PEG-11'; Outcome='RESERVED'; Reason='MARKER_CONSUMED'; Marker='RESERVED' },
        @{ Id='PEG-12-completed'; Changes=@{markerState='Completed'}; Peg='PEG-12'; Outcome='COMPLETED'; Reason='MARKER_CONSUMED'; Marker='COMPLETED' },
        @{ Id='PEG-13-invalid'; Changes=@{markerState='Invalid'}; Peg='PEG-13'; Outcome='REJECTED'; Reason='MARKER_INVALID'; Marker='INVALID' },
        @{ Id='PEG-13-unknown'; Changes=@{markerState='Unknown'}; Peg='PEG-13'; Outcome='REJECTED'; Reason='MARKER_INVALID'; Marker='INVALID' }
    )
    foreach ($pegCase in $pegCases) {
        Invoke-HrsCase "STATE-$($pegCase.Id)" {
            $actual = Get-HrsCoreDecision -Case (New-HrsDecisionCase $pegCase.Changes)
            Assert-HrsEqual $actual.peg $pegCase.Peg 'PEG routing differed.'
            Assert-HrsEqual $actual.outcome $pegCase.Outcome 'Decision outcome differed.'
            Assert-HrsEqual $actual.reason $pegCase.Reason 'Decision reason differed.'
            Assert-HrsEqual $actual.markerState $pegCase.Marker 'Decision marker differed.'
            if ($pegCase.ContainsKey('Permitted') -and [bool]$pegCase['Permitted']) {
                Assert-HrsTrue $actual.reserveMarker 'Permitted Random did not reserve.'
                Assert-HrsTrue $actual.selectCandidate 'Permitted Random did not select.'
                Assert-HrsTrue $actual.placePlayer 'Permitted Random did not grant placement.'
            }
            else { Assert-HrsNoGameplayAction $actual $pegCase.Id }
        }
    }

    Invoke-HrsCase 'STATE-CASE-missing-field-fails-closed' {
        $case = New-HrsDecisionCase
        $case.PSObject.Properties.Remove('targetMatch')
        $actual = Get-HrsCoreDecision -Case $case
        Assert-HrsEqual $actual.peg 'PEG-02' 'Missing case field did not route to PEG-02.'
        Assert-HrsEqual $actual.reason 'CASE_FIELD_MISSING' 'Missing-field reason differed.'
        Assert-HrsNoGameplayAction $actual 'Missing field'
    }
    Invoke-HrsCase 'STATE-CASE-unknown-field-fails-closed' {
        $case = New-HrsDecisionCase
        $case | Add-Member -NotePropertyName requestedCoordinate -NotePropertyValue '1,2,3'
        $actual = Get-HrsCoreDecision -Case $case
        Assert-HrsEqual $actual.peg 'PEG-02' 'Unknown case field did not route to PEG-02.'
        Assert-HrsNoGameplayAction $actual 'Unknown field'
    }
    Invoke-HrsCase 'STATE-CASE-boolean-string-fails-closed' {
        $case = New-HrsDecisionCase @{ buildCompatible = 'false' }
        $actual = Get-HrsCoreDecision -Case $case
        Assert-HrsFalse ($actual.peg -eq 'PEG-05') 'A string boolean reached Random permission.'
        Assert-HrsNoGameplayAction $actual 'String boolean'
    }
    Invoke-HrsCase 'STATE-RANDOM-every-negated-gate-is-zero-action' {
        $negations = @(
            @{buildCompatible=$false}, @{authorityConfirmed=$false}, @{localSinglePlayer=$false},
            @{runtimeLaneConfirmed=$false}, @{policyValid=$false}, @{targetMatch=$false},
            @{lifecycle='LoadedGame'}, @{entityResolved=$false}, @{markerApiAvailable=$false},
            @{markerState='Reserved'}, @{markerState='Completed'}, @{markerState='Invalid'}
        )
        foreach ($negation in $negations) {
            Assert-HrsNoGameplayAction (Get-HrsCoreDecision -Case (New-HrsDecisionCase $negation)) 'Negated Random gate'
        }
    }
    Invoke-HrsCase 'STATE-STANDARD-always-zero-custom-action' {
        $variations = @(
            @{}, @{buildCompatible=$false}, @{authorityConfirmed=$false}, @{localSinglePlayer=$false},
            @{runtimeLaneConfirmed=$false}, @{policyValid=$false}, @{targetMatch=$false},
            @{lifecycle='LoadedGame'}, @{entityResolved=$false}, @{markerApiAvailable=$false},
            @{markerState='Reserved'}, @{markerState='Completed'}, @{markerState='Invalid'}
        )
        foreach ($variation in $variations) {
            $variation['mode'] = 'Standard'
            Assert-HrsNoGameplayAction (Get-HrsCoreDecision -Case (New-HrsDecisionCase $variation)) 'Standard variation'
        }
    }
    Invoke-HrsCase 'STATE-denial-precedence-environment-before-policy' {
        $actual = Get-HrsCoreDecision -Case (New-HrsDecisionCase @{buildCompatible=$false; runtimeLaneConfirmed=$false; policyValid=$false; targetMatch=$false})
        Assert-HrsEqual $actual.peg 'PEG-01' 'Environment denial did not precede later gates.'
        Assert-HrsNoGameplayAction $actual 'Denial precedence'
    }

    # Manager capabilities: game-off mutations, Steam-only launch prerequisite,
    # and visible read-only state in every process condition.
    $closedSteam = [pscustomobject]@{ Game='Closed'; Steam='Running' }
    $closedNoSteam = [pscustomobject]@{ Game='Closed'; Steam='Closed' }
    $closedUnknownSteam = [pscustomobject]@{ Game='Closed'; Steam='Unknown' }
    $running = [pscustomobject]@{ Game='Running'; Steam='Running' }
    $unknown = [pscustomobject]@{ Game='Unknown'; Steam='Running' }

    function Get-FullCapabilities {
        param([psobject] $ProcessState)
        return Get-HrsManagerCapabilities -ProcessState $ProcessState -GameRootValid $true -ExactNameValid $true -CapsuleInstalled $true -CapsuleOwnershipValid $true -PolicyValid $true -RestoreTargetValid $true
    }

    Invoke-HrsCase 'CAP-001-complete-closed-state' {
        $actual = Get-FullCapabilities $closedSteam
        foreach ($name in @('canView','canValidate','canApply','canRestore','canRestoreDefault','canRemoveFromGame','launchVisible','canLaunch','configurationComplete')) {
            Assert-HrsTrue ([bool]$actual.$name) "Capability $name was unexpectedly false."
        }
        Assert-HrsEqual $actual.mutationBlockReason '' 'Closed mutation block reason was not empty.'
        Assert-HrsEqual $actual.launchBlockReason '' 'Available launch block reason was not empty.'
    }
    Invoke-HrsCase 'CAP-002-running-game-blocks-mutations-not-view' {
        $actual = Get-FullCapabilities $running
        Assert-HrsTrue $actual.canView 'Running game hid read-only state.'
        Assert-HrsTrue $actual.launchVisible 'Running game hid Launch Game.'
        foreach ($name in @('canValidate','canApply','canRestore','canRestoreDefault','canRemoveFromGame','canLaunch')) {
            Assert-HrsFalse ([bool]$actual.$name) "Running game allowed $name."
        }
        Assert-HrsEqual $actual.mutationBlockReason 'GAME_RUNNING' 'Running mutation reason differed.'
        Assert-HrsEqual $actual.launchBlockReason 'GAME_ALREADY_RUNNING' 'Running launch reason differed.'
    }
    Invoke-HrsCase 'CAP-003-unknown-game-fails-closed' {
        $actual = Get-FullCapabilities $unknown
        Assert-HrsTrue $actual.canView 'Unknown process state hid read-only state.'
        foreach ($name in @('canValidate','canApply','canRestore','canRestoreDefault','canRemoveFromGame','canLaunch')) {
            Assert-HrsFalse ([bool]$actual.$name) "Unknown process state allowed $name."
        }
        Assert-HrsEqual $actual.mutationBlockReason 'GAME_STATE_UNCONFIRMED' 'Unknown mutation reason differed.'
    }
    Invoke-HrsCase 'CAP-004-steam-is-only-a-launch-gate' {
        $closed = Get-FullCapabilities $closedNoSteam
        $unknownSteam = Get-FullCapabilities $closedUnknownSteam
        foreach ($actual in @($closed, $unknownSteam)) {
            Assert-HrsTrue $actual.canApply 'Steam state blocked Apply.'
            Assert-HrsTrue $actual.canRestore 'Steam state blocked Restore.'
            Assert-HrsTrue $actual.canRemoveFromGame 'Steam state blocked Remove from Game.'
            Assert-HrsFalse $actual.canLaunch 'Unavailable Steam allowed Launch.'
        }
        Assert-HrsEqual $closed.launchBlockReason 'STEAM_NOT_RUNNING' 'Closed-Steam reason differed.'
        Assert-HrsEqual $unknownSteam.launchBlockReason 'STEAM_STATE_UNCONFIRMED' 'Unknown-Steam reason differed.'
    }
    Invoke-HrsCase 'CAP-005-incomplete-configuration-does-not-hide-launch' {
        $actual = Get-HrsManagerCapabilities -ProcessState $closedSteam -GameRootValid $false -ExactNameValid $false -CapsuleInstalled $false -CapsuleOwnershipValid $false -PolicyValid $false -RestoreTargetValid $false
        Assert-HrsTrue $actual.launchVisible 'Incomplete configuration hid Launch Game.'
        Assert-HrsTrue $actual.canLaunch 'Incomplete configuration blocked otherwise-valid direct launch availability.'
        Assert-HrsFalse $actual.configurationComplete 'Incomplete state claimed completion.'
    }
    Invoke-HrsCase 'CAP-006-root-and-name-belong-to-completion' {
        $badRoot = Get-HrsManagerCapabilities -ProcessState $closedSteam -GameRootValid $false -ExactNameValid $true -CapsuleInstalled $true -CapsuleOwnershipValid $true -PolicyValid $true -RestoreTargetValid $true
        $badName = Get-HrsManagerCapabilities -ProcessState $closedSteam -GameRootValid $true -ExactNameValid $false -CapsuleInstalled $true -CapsuleOwnershipValid $true -PolicyValid $true -RestoreTargetValid $true
        Assert-HrsFalse $badRoot.configurationComplete 'Invalid game root claimed complete configuration.'
        Assert-HrsFalse $badName.configurationComplete 'Invalid exact game name claimed complete configuration.'
    }
    Invoke-HrsCase 'CAP-007-prerequisite-negation' {
        $badRoot = Get-HrsManagerCapabilities -ProcessState $closedSteam -GameRootValid $false -ExactNameValid $true -CapsuleInstalled $true -CapsuleOwnershipValid $true -PolicyValid $true -RestoreTargetValid $true
        foreach ($name in @('canApply','canRestore','canRestoreDefault','canRemoveFromGame')) { Assert-HrsFalse ([bool]$badRoot.$name) "Invalid root allowed $name." }
        $badName = Get-HrsManagerCapabilities -ProcessState $closedSteam -GameRootValid $true -ExactNameValid $false -CapsuleInstalled $true -CapsuleOwnershipValid $true -PolicyValid $true -RestoreTargetValid $true
        Assert-HrsFalse $badName.canApply 'Invalid exact name allowed Apply.'
        Assert-HrsTrue $badName.canRestoreDefault 'An irrelevant in-memory name blocked Default recovery.'
        $notInstalled = Get-HrsManagerCapabilities -ProcessState $closedSteam -GameRootValid $true -ExactNameValid $true -CapsuleInstalled $false -CapsuleOwnershipValid $true -PolicyValid $true -RestoreTargetValid $true
        foreach ($name in @('canApply','canRestore','canRestoreDefault','canRemoveFromGame')) { Assert-HrsFalse ([bool]$notInstalled.$name) "Missing capsule allowed $name." }
        $drift = Get-HrsManagerCapabilities -ProcessState $closedSteam -GameRootValid $true -ExactNameValid $true -CapsuleInstalled $true -CapsuleOwnershipValid $false -PolicyValid $true -RestoreTargetValid $true
        foreach ($name in @('canApply','canRestore','canRestoreDefault','canRemoveFromGame')) { Assert-HrsFalse ([bool]$drift.$name) "Invalid ownership allowed $name." }
        $badRestore = Get-HrsManagerCapabilities -ProcessState $closedSteam -GameRootValid $true -ExactNameValid $true -CapsuleInstalled $true -CapsuleOwnershipValid $true -PolicyValid $true -RestoreTargetValid $false
        Assert-HrsFalse $badRestore.canRestore 'Invalid recovery target allowed Restore.'
        Assert-HrsTrue $badRestore.canRestoreDefault 'Invalid snapshot target blocked Default.'
    }

    # One project-specific copy catalog supplies labels, visible status,
    # concise tooltips, and matching accessible descriptions.
    Invoke-HrsCase 'COPY-001-catalog-self-validation' {
        $actual = Test-HrsCopyCatalog
        Assert-HrsTrue $actual.Valid 'Copy catalog self-validation failed.'
        Assert-HrsEqual $actual.Reason 'COPY_VALID' 'Copy catalog validation reason differed.'
        Assert-HrsEqual $actual.Count 17 'Copy catalog count differed.'
    }
    Invoke-HrsCase 'COPY-002-required-keys-exactly-once' {
        $items = @(Get-HrsCopyCatalog)
        $required = @('GameName','Standard','Random','ArrivalBiome','Apply','LaunchGame','Recovery','ShowChanges','RestoreLast','RestoreDefault','RemoveFromGame','StatusIncomplete','StatusStandard','StatusRandom','StatusRunning','StatusConflict','StatusLane')
        foreach ($key in $required) { Assert-HrsEqual @($items | Where-Object { $_.Key -ceq $key }).Count 1 "Copy key $key count differed." }
        Assert-HrsEqual $items.Count $required.Count 'Unexpected copy keys were present.'
    }
    Invoke-HrsCase 'COPY-003-control-tooltips-and-accessibility' {
        foreach ($item in @(Get-HrsCopyCatalog | Where-Object { -not $_.Essential })) {
            Assert-HrsTrue (-not [string]::IsNullOrWhiteSpace([string]$item.Tooltip)) "Control $($item.Key) lacked a tooltip."
            Assert-HrsTrue (([string]$item.Tooltip).Length -le 75) "Control $($item.Key) tooltip exceeded 75 characters."
            Assert-HrsTrue (-not [string]::IsNullOrWhiteSpace([string]$item.AccessibleDescription)) "Control $($item.Key) lacked an accessible description."
        }
    }
    Invoke-HrsCase 'COPY-004-essential-state-is-visible-not-hover-only' {
        foreach ($item in @(Get-HrsCopyCatalog | Where-Object { $_.Essential })) {
            Assert-HrsEqual $item.Placement 'UpperStatus' "Essential state $($item.Key) was not in upper status."
            Assert-HrsEqual $item.Tooltip '' "Essential state $($item.Key) was hidden or duplicated in a tooltip."
            Assert-HrsTrue (-not [string]::IsNullOrWhiteSpace([string]$item.AccessibleDescription)) "Essential state $($item.Key) lacked accessible meaning."
        }
    }
    Invoke-HrsCase 'COPY-005-frozen-action-meaning' {
        $byKey = @{}
        foreach ($item in @(Get-HrsCopyCatalog)) { $byKey[$item.Key] = $item }
        Assert-HrsEqual $byKey['LaunchGame'].Label 'Launch Game' 'Launch label differed.'
        Assert-HrsTrue ($byKey['LaunchGame'].AccessibleDescription -match 'direct user action') 'Launch accessibility omitted direct-user agency.'
        Assert-HrsTrue ($byKey['LaunchGame'].AccessibleDescription -match 'Steam must already be running') 'Launch accessibility omitted Steam prerequisite.'
        Assert-HrsEqual $byKey['RemoveFromGame'].Label 'Remove from Game' 'Removal used system-uninstall wording.'
        Assert-HrsEqual $byKey['RemoveFromGame'].Placement 'Details' 'Removal was not under Details.'
        Assert-HrsTrue ($byKey['RemoveFromGame'].AccessibleDescription -match 'retaining the portable manager and history') 'Removal accessibility omitted retained management state.'
        Assert-HrsTrue ($byKey['RestoreDefault'].AccessibleDescription -match 'without changing saves, worlds, or progress') 'Default recovery omitted its non-impact boundary.'
        Assert-HrsTrue ($byKey['Apply'].AccessibleDescription -match 'without launching the game') 'Apply accessibility implied launch.'
    }
    Invoke-HrsCase 'COPY-006-deferred-and-unbounded-controls-absent' {
        $text = (Get-HrsCopyCatalog | ConvertTo-Json -Depth 5 -Compress)
        foreach ($forbidden in @('Open Mods Folder','DiscoveredGame','AllGames','Random Distance','Starting biome only','All dangerous biomes','Uninstall')) {
            Assert-HrsFalse ($text.IndexOf($forbidden, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "Deferred or misleading copy appeared: $forbidden"
        }
    }
    Invoke-HrsCase 'COPY-007-callers-receive-fresh-catalog' {
        $first = @(Get-HrsCopyCatalog)
        $first[0].Label = 'MUTATED'
        $second = @(Get-HrsCopyCatalog)
        Assert-HrsEqual $second[0].Label 'New Game Name' 'A caller mutation changed the shared copy catalog.'
    }

    # Deployment manifest construction and strict schema validation.
    $manifestFixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'm0')
    $manifest = $manifestFixture.Manifest
    Invoke-HrsCase 'DEPLOY-MANIFEST-000-constructor-completes' {
        $constructed = New-HrsDeploymentManifest -PayloadRoot $manifestFixture.PayloadRoot -ReleaseVersion '0.0.1-alpha.1'
        Assert-HrsTrue (Test-HrsDeploymentManifest -Manifest $constructed).Valid 'New-HrsDeploymentManifest did not return a valid manifest.'
    }
    Invoke-HrsCase 'DEPLOY-MANIFEST-001-construction-and-hashes' {
        Assert-HrsEqual $manifest.schema 'hrs-deployment-manifest/v1' 'Deployment schema differed.'
        Assert-HrsEqual $manifest.releaseVersion '0.0.1-alpha.1' 'Release version differed.'
        Assert-HrsEqual $manifest.releaseFolder 'BitWrecked_HistoricalRandomStart' 'Release folder differed.'
        Assert-HrsEqual @($manifest.files).Count 2 'Static manifest file count differed.'
        foreach ($entry in @($manifest.files)) {
            $source = Join-Path $manifestFixture.PayloadRoot $entry.path
            Assert-HrsEqual $entry.sha256 (Get-HrsFixtureHash $source) "Manifest hash differed for $($entry.path)."
            Assert-HrsEqual $entry.bytes ([UInt64](New-Object System.IO.FileInfo($source)).Length) "Manifest size differed for $($entry.path)."
        }
        Assert-HrsTrue (Test-HrsDeploymentManifest -Manifest $manifest).Valid 'Constructed manifest failed validation.'
    }
    Invoke-HrsCase 'DEPLOY-MANIFEST-002-version-grammar' {
        Assert-HrsThrows { New-HrsDeploymentManifest -PayloadRoot $manifestFixture.PayloadRoot -ReleaseVersion '1.0' } 'DEPLOYMENT_VERSION_INVALID'
        Assert-HrsThrows { New-HrsDeploymentManifest -PayloadRoot $manifestFixture.PayloadRoot -ReleaseVersion '1.0.0-ALPHA' } 'DEPLOYMENT_VERSION_INVALID'
        $null = New-HrsDeploymentManifest -PayloadRoot $manifestFixture.PayloadRoot -ReleaseVersion '1.2.3'
    }
    Invoke-HrsCase 'DEPLOY-MANIFEST-003-static-files-required' {
        $root = Join-Path $fixtureRoot 'mm'
        [void] [System.IO.Directory]::CreateDirectory($root)
        Write-HrsFixtureText -Path (Join-Path $root 'ModInfo.xml') -Text '<xml />'
        Assert-HrsThrows { New-HrsDeploymentManifest -PayloadRoot $root -ReleaseVersion '1.0.0' } 'DEPLOYMENT_FILE_MISSING_D0163_DLL'
        [System.IO.File]::WriteAllBytes((Join-Path $root 'd0163.dll'), [byte[]]@(1))
        [System.IO.File]::Delete((Join-Path $root 'ModInfo.xml'))
        Assert-HrsThrows { New-HrsDeploymentManifest -PayloadRoot $root -ReleaseVersion '1.0.0' } 'DEPLOYMENT_FILE_MISSING_MODINFO_XML'
    }
    Invoke-HrsCase 'DEPLOY-MANIFEST-004-top-level-hostile-shapes' {
        $extra = Copy-HrsManifest $manifest
        $extra | Add-Member -NotePropertyName command -NotePropertyValue 'DELETE'
        Assert-HrsFalse (Test-HrsDeploymentManifest $extra).Valid 'Manifest accepted an extra command field.'
        $missing = Copy-HrsManifest $manifest
        $missing.PSObject.Properties.Remove('releaseFolder')
        Assert-HrsFalse (Test-HrsDeploymentManifest $missing).Valid 'Manifest accepted a missing field.'
        foreach ($change in @(
            @{Field='schema'; Value='hrs-deployment-manifest/v2'},
            @{Field='releaseVersion'; Value='latest'},
            @{Field='releaseFolder'; Value='OtherMod'}
        )) {
            $changed = Copy-HrsManifest $manifest
            $changed.($change.Field) = $change.Value
            Assert-HrsFalse (Test-HrsDeploymentManifest $changed).Valid "Manifest accepted invalid $($change.Field)."
        }
    }
    Invoke-HrsCase 'DEPLOY-MANIFEST-005-file-set-and-entry-shape' {
        $one = Copy-HrsManifest $manifest
        $one.files = @($one.files | Select-Object -First 1)
        Assert-HrsFalse (Test-HrsDeploymentManifest $one).Valid 'Manifest accepted a missing static entry.'
        $duplicate = Copy-HrsManifest $manifest
        $duplicate.files = @($duplicate.files[0], $duplicate.files[0])
        Assert-HrsFalse (Test-HrsDeploymentManifest $duplicate).Valid 'Manifest accepted a duplicate static entry.'
        $extra = Copy-HrsManifest $manifest
        $extra.files[0] | Add-Member -NotePropertyName owner -NotePropertyValue 'foreign'
        Assert-HrsFalse (Test-HrsDeploymentManifest $extra).Valid 'Manifest accepted an extra entry field.'
    }
    Invoke-HrsCase 'DEPLOY-MANIFEST-006-bytes-and-hash-strict' {
        $zero = Copy-HrsManifest $manifest
        $zero.files[0].bytes = 0
        Assert-HrsFalse (Test-HrsDeploymentManifest $zero).Valid 'Manifest accepted a zero-byte static file.'
        $lower = Copy-HrsManifest $manifest
        $lower.files[0].sha256 = ([string]$lower.files[0].sha256).ToLowerInvariant()
        Assert-HrsFalse (Test-HrsDeploymentManifest $lower).Valid 'Manifest accepted a noncanonical lowercase hash.'
        $stringSize = Copy-HrsManifest $manifest
        $stringSize.files[0].bytes = [string]$stringSize.files[0].bytes
        Assert-HrsFalse (Test-HrsDeploymentManifest $stringSize).Valid 'Manifest accepted a string byte count.'
    }

    # Installed inventory is all-or-nothing: exact files, valid dynamic bridge,
    # no unknowns, no drift, and no reparse-point ownership ambiguity.
    Invoke-HrsCase 'DEPLOY-INVENTORY-001-not-installed' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'i1')
        $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest
        Assert-HrsTrue $actual.Valid 'Absent release root was not a valid NotInstalled state.'
        Assert-HrsEqual $actual.State 'NotInstalled' 'Absent release root state differed.'
        Assert-HrsEqual @($actual.RemovalPlan).Count 0 'NotInstalled returned a removal plan.'
    }
    Invoke-HrsCase 'DEPLOY-INVENTORY-002-static-only-valid' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'i2') -Installed
        $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest
        Assert-HrsTrue $actual.Valid 'Exact static deployment was invalid.'
        Assert-HrsEqual $actual.State 'InstalledValid' 'Static deployment state differed.'
        Assert-HrsEqual @($actual.RemovalPlan).Count 2 'Static removal plan count differed.'
    }
    Invoke-HrsCase 'DEPLOY-INVENTORY-003-valid-bridge' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'i3') -Installed -WithBridge
        $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest
        Assert-HrsTrue $actual.Valid 'Valid policy/result bridge was rejected.'
        Assert-HrsEqual @($actual.RemovalPlan).Count 4 'Full removal plan did not contain four owned files.'
        foreach ($path in @($actual.RemovalPlan)) { Assert-HrsTrue ($path.StartsWith($fixture.Paths.ReleaseRoot, [System.StringComparison]::OrdinalIgnoreCase)) 'Removal plan escaped release root.' }
    }
    Invoke-HrsCase 'DEPLOY-INVENTORY-004-unknown-root-file-conflict' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'i4') -Installed
        [System.IO.File]::WriteAllBytes((Join-Path $fixture.Paths.ReleaseRoot 'unknown.bin'), [byte[]]@(1))
        $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest
        Assert-HrsFalse $actual.Valid 'Unknown release-root file was accepted.'
        Assert-HrsEqual $actual.Reason 'DEPLOYMENT_UNKNOWN_FILE' 'Unknown root-file reason differed.'
        Assert-HrsEqual @($actual.RemovalPlan).Count 0 'Conflict returned a partial removal plan.'
    }
    Invoke-HrsCase 'DEPLOY-INVENTORY-005-unknown-bridge-file-conflict' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'i5') -Installed -WithBridge
        [System.IO.File]::WriteAllBytes((Join-Path $fixture.Paths.BridgeRoot 'extra.tmp'), [byte[]]@(1))
        $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest
        Assert-HrsFalse $actual.Valid 'Unknown Bridge file was accepted.'
        Assert-HrsEqual $actual.Reason 'DEPLOYMENT_UNKNOWN_BRIDGE_FILE' 'Unknown Bridge-file reason differed.'
    }
    Invoke-HrsCase 'DEPLOY-INVENTORY-006-unknown-directory-conflict' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'i6') -Installed
        [void] [System.IO.Directory]::CreateDirectory((Join-Path $fixture.Paths.ReleaseRoot 'Foreign'))
        $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest
        Assert-HrsFalse $actual.Valid 'Unknown release directory was accepted.'
        Assert-HrsEqual $actual.Reason 'DEPLOYMENT_UNKNOWN_DIRECTORY' 'Unknown-directory reason differed.'
    }
    Invoke-HrsCase 'DEPLOY-INVENTORY-007-static-drift' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'i7') -Installed
        [System.IO.File]::WriteAllBytes((Join-Path $fixture.Paths.ReleaseRoot 'd0163.dll'), [byte[]]@(9,9,9))
        $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest
        Assert-HrsFalse $actual.Valid 'Drifted static DLL was accepted.'
        Assert-HrsEqual $actual.State 'Drift' 'Static drift state differed.'
        Assert-HrsEqual $actual.Reason 'DEPLOYMENT_STATIC_FILE_DRIFT' 'Static drift reason differed.'
        Assert-HrsEqual @($actual.RemovalPlan).Count 0 'Drift returned a partial removal plan.'
    }
    Invoke-HrsCase 'DEPLOY-INVENTORY-008-static-missing' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'i8') -Installed
        [System.IO.File]::Delete((Join-Path $fixture.Paths.ReleaseRoot 'ModInfo.xml'))
        $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest
        Assert-HrsFalse $actual.Valid 'Missing static file was accepted.'
        Assert-HrsEqual $actual.State 'Incomplete' 'Missing static state differed.'
        Assert-HrsEqual $actual.Reason 'DEPLOYMENT_STATIC_FILE_MISSING' 'Missing static reason differed.'
    }
    Invoke-HrsCase 'DEPLOY-INVENTORY-009-invalid-policy-and-result' {
        $policyFixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'i9p') -Installed -WithBridge
        Write-HrsFixtureText -Path $policyFixture.Paths.PolicyPath -Text '{}'
        $policyResult = Test-HrsDeploymentInventory -GameRoot $policyFixture.GameRoot -Manifest $policyFixture.Manifest
        Assert-HrsEqual $policyResult.Reason 'DEPLOYMENT_POLICY_INVALID' 'Invalid policy reason differed.'
        $resultFixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'i9r') -Installed -WithBridge
        Write-HrsFixtureText -Path $resultFixture.Paths.ResultPath -Text '{}'
        $resultResult = Test-HrsDeploymentInventory -GameRoot $resultFixture.GameRoot -Manifest $resultFixture.Manifest
        Assert-HrsEqual $resultResult.Reason 'DEPLOYMENT_RESULT_INVALID' 'Invalid result reason differed.'
    }
    Invoke-HrsCase 'DEPLOY-INVENTORY-010-invalid-manifest-stops-before-files' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'ia') -Installed
        $bad = Copy-HrsManifest $fixture.Manifest
        $bad.releaseFolder = 'OtherMod'
        $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $bad
        Assert-HrsFalse $actual.Valid 'Invalid manifest reached inventory authorization.'
        Assert-HrsEqual $actual.State 'ManifestInvalid' 'Invalid-manifest state differed.'
        Assert-HrsEqual @($actual.RemovalPlan).Count 0 'Invalid manifest returned a removal plan.'
    }

    $junctionSupported = $true
    $junctionProbeTarget = Join-Path $fixtureRoot 'jt'
    $junctionProbeLink = Join-Path $fixtureRoot 'jl'
    [void] [System.IO.Directory]::CreateDirectory($junctionProbeTarget)
    try {
        $null = New-Item -ItemType Junction -Path $junctionProbeLink -Target $junctionProbeTarget -ErrorAction Stop
        [void] $script:CreatedReparsePaths.Add($junctionProbeLink)
    }
    catch {
        $junctionSupported = $false
        Write-HrsSkip 'DEPLOY-REPARSE-SETUP' "Junction creation unavailable: $($_.Exception.Message)"
    }

    if ($junctionSupported) {
        Invoke-HrsCase 'DEPLOY-INVENTORY-011-release-root-reparse-rejected' {
            $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'ib')
            [void] [System.IO.Directory]::CreateDirectory((Join-Path $fixture.GameRoot 'Mods'))
            $target = Join-Path $fixtureRoot 'ibt'
            [void] [System.IO.Directory]::CreateDirectory($target)
            [System.IO.File]::Copy((Join-Path $fixture.PayloadRoot 'd0163.dll'), (Join-Path $target 'd0163.dll'))
            [System.IO.File]::Copy((Join-Path $fixture.PayloadRoot 'ModInfo.xml'), (Join-Path $target 'ModInfo.xml'))
            $link = $fixture.Paths.ReleaseRoot
            $null = New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop
            [void] $script:CreatedReparsePaths.Add($link)
            $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest
            Assert-HrsFalse $actual.Valid 'Reparse release root was accepted.'
            Assert-HrsTrue ($actual.Reason -match 'REPARSE_POINT') 'Reparse release-root reason was not categorical.'
        }
        Invoke-HrsCase 'DEPLOY-INVENTORY-012-unknown-reparse-directory-rejected' {
            $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'ic') -Installed
            $target = Join-Path $fixtureRoot 'ict'
            [void] [System.IO.Directory]::CreateDirectory($target)
            $link = Join-Path $fixture.Paths.ReleaseRoot 'Foreign'
            $null = New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop
            [void] $script:CreatedReparsePaths.Add($link)
            $actual = Test-HrsDeploymentInventory -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest
            Assert-HrsFalse $actual.Valid 'Unknown reparse directory was accepted.'
            Assert-HrsEqual $actual.Reason 'DEPLOYMENT_REPARSE_POINT' 'Unknown reparse-directory reason differed.'
        }
    }

    # Remove from Game is confirmed, game-off, exact-manifest deletion only.
    Invoke-HrsCase 'REMOVE-001-confirmation-required' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'r1') -Installed -WithBridge
        Assert-HrsThrows { Invoke-HrsRemoveFromGame -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest -ProcessState ([pscustomobject]@{Game='Closed';Steam='Closed'}) } 'REMOVE_CONFIRMATION_REQUIRED'
        Assert-HrsTrue ([System.IO.Directory]::Exists($fixture.Paths.ReleaseRoot)) 'Unconfirmed removal changed the release root.'
    }
    Invoke-HrsCase 'REMOVE-002-running-and-unknown-game-block' {
        foreach ($case in @(
            @{Root='r2a'; Game='Running'; Reason='GAME_RUNNING'},
            @{Root='r2b'; Game='Unknown'; Reason='GAME_STATE_UNCONFIRMED'}
        )) {
            $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot $case.Root) -Installed -WithBridge
            Assert-HrsThrows { Invoke-HrsRemoveFromGame -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest -ProcessState ([pscustomobject]@{Game=$case.Game;Steam='Running'}) -Confirmed } $case.Reason
            Assert-HrsTrue ([System.IO.Directory]::Exists($fixture.Paths.ReleaseRoot)) "$($case.Game) removal changed the release root."
        }
    }
    Invoke-HrsCase 'REMOVE-003-conflict-causes-zero-deletion' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'r3') -Installed -WithBridge
        $unknown = Join-Path $fixture.Paths.ReleaseRoot 'unknown.bin'
        [System.IO.File]::WriteAllBytes($unknown, [byte[]]@(1,2,3))
        $before = Get-HrsFixtureTreeDigest $fixture.Paths.ReleaseRoot
        Assert-HrsThrows { Invoke-HrsRemoveFromGame -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest -ProcessState ([pscustomobject]@{Game='Closed';Steam='Running'}) -Confirmed } 'DEPLOYMENT_UNKNOWN_FILE'
        Assert-HrsEqual (Get-HrsFixtureTreeDigest $fixture.Paths.ReleaseRoot) $before 'Conflict removal partially changed the capsule.'
    }
    Invoke-HrsCase 'REMOVE-004-exact-capsule-only-manager-retained' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'r4') -Installed -WithBridge
        $foreignMod = Join-Path $fixture.GameRoot 'Mods\ForeignMod'
        [void] [System.IO.Directory]::CreateDirectory($foreignMod)
        Write-HrsFixtureText -Path (Join-Path $foreignMod 'foreign.txt') -Text 'FOREIGN-UNCHANGED'
        $gameData = Join-Path $fixture.GameRoot 'Data'
        [void] [System.IO.Directory]::CreateDirectory($gameData)
        Write-HrsFixtureText -Path (Join-Path $gameData 'game.txt') -Text 'GAME-UNCHANGED'
        $manager = Join-Path $fixture.Root 'manager'
        $managerSupport = Join-Path $manager 'ui\HistoricalRandomStart_State'
        [void] [System.IO.Directory]::CreateDirectory($managerSupport)
        Write-HrsFixtureText -Path (Join-Path $manager 'r0136.bat') -Text 'portable manager'
        Write-HrsFixtureText -Path (Join-Path $managerSupport 'history.v1.jsonl') -Text '{"history":"retained"}'
        $managerBefore = Get-HrsFixtureTreeDigest $manager
        $foreignBefore = Get-HrsFixtureTreeDigest $foreignMod
        $gameBefore = Get-HrsFixtureTreeDigest $gameData

        $actual = Invoke-HrsRemoveFromGame -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest -ProcessState ([pscustomobject]@{Game='Closed';Steam='Closed'}) -Confirmed
        Assert-HrsTrue $actual.Removed 'Confirmed removal did not report Removed.'
        Assert-HrsEqual $actual.Reason 'REMOVED_FROM_GAME' 'Removal success reason differed.'
        Assert-HrsEqual $actual.RemovedFiles 4 'Removal did not report exactly four owned files.'
        Assert-HrsFalse ([System.IO.Directory]::Exists($fixture.Paths.ReleaseRoot)) 'Owned release root remained after removal.'
        Assert-HrsEqual (Get-HrsFixtureTreeDigest $manager) $managerBefore 'Remove from Game changed portable manager/history.'
        Assert-HrsEqual (Get-HrsFixtureTreeDigest $foreignMod) $foreignBefore 'Remove from Game changed a foreign mod.'
        Assert-HrsEqual (Get-HrsFixtureTreeDigest $gameData) $gameBefore 'Remove from Game changed game-managed fixture data.'
        Assert-HrsTrue ([System.IO.File]::Exists((Join-Path $fixture.GameRoot '7DaysToDie.exe'))) 'Remove from Game deleted the game executable fixture.'
    }
    Invoke-HrsCase 'REMOVE-005-already-removed-idempotent' {
        $fixture = New-HrsDeploymentFixture -Root (Join-Path $fixtureRoot 'r5')
        $actual = Invoke-HrsRemoveFromGame -GameRoot $fixture.GameRoot -Manifest $fixture.Manifest -ProcessState ([pscustomobject]@{Game='Closed';Steam='Closed'}) -Confirmed
        Assert-HrsTrue $actual.Removed 'Already-removed state did not succeed safely.'
        Assert-HrsEqual $actual.Reason 'ALREADY_REMOVED' 'Already-removed reason differed.'
        Assert-HrsEqual $actual.RemovedFiles 0 'Already-removed state reported deletions.'
    }
}
finally {
    foreach ($reparsePath in @($script:CreatedReparsePaths | Sort-Object Length -Descending)) {
        try {
            if ([System.IO.Directory]::Exists($reparsePath)) { [System.IO.Directory]::Delete($reparsePath, $false) }
        }
        catch { Write-Output "CLEANUP_WARNING path=$reparsePath category=$($_.Exception.GetType().Name)" }
    }

    $resolvedParent = [System.IO.Path]::GetFullPath($fixtureParent).TrimEnd('\')
    $resolvedRun = [System.IO.Path]::GetFullPath($fixtureRoot).TrimEnd('\')
    $prefix = $resolvedParent + [System.IO.Path]::DirectorySeparatorChar
    if ($resolvedRun.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase) -and
        [System.IO.Path]::GetFileName($resolvedRun) -eq $fixtureLeaf) {
        if ([System.IO.Directory]::Exists($resolvedRun)) { [System.IO.Directory]::Delete($resolvedRun, $true) }
        if ([System.IO.Directory]::Exists($resolvedParent) -and [System.IO.Directory]::GetFileSystemEntries($resolvedParent).Count -eq 0) {
            [System.IO.Directory]::Delete($resolvedParent, $false)
        }
    }
    else { Write-Output 'CLEANUP_WARNING bounded fixture path validation failed; no recursive cleanup attempted.' }
}

Write-Output "ALPHA_CORE_STATE_DEPLOYMENT_SUMMARY pass=$script:PassCount fail=$script:FailCount skip=$script:SkipCount"
if ($script:FailCount -gt 0) {
    Write-Output 'ALPHA_CORE_STATE_DEPLOYMENT_FAILURES_BEGIN'
    foreach ($failure in $script:FailureDetails) { Write-Output $failure }
    Write-Output 'ALPHA_CORE_STATE_DEPLOYMENT_FAILURES_END'
    exit 1
}

exit 0
