Set-StrictMode -Version 2.0

function Get-HrsQaSha256 {
    param([Parameter(Mandatory = $true)] [string] $Path)

    $stream = [System.IO.File]::OpenRead($Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Write-HrsQaJson {
    param(
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [object] $Value
    )

    $parent = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($Path))
    if (-not [System.IO.Directory]::Exists($parent)) {
        [void][System.IO.Directory]::CreateDirectory($parent)
    }
    $json = ConvertTo-Json -InputObject $Value -Depth 12
    [System.IO.File]::WriteAllText(
        $Path,
        $json + "`n",
        (New-Object System.Text.UTF8Encoding($false))
    )
}

function Read-HrsQaJson {
    param([Parameter(Mandatory = $true)] [string] $Path)

    if (-not [System.IO.File]::Exists($Path)) { throw "QA_FILE_MISSING: $Path" }
    return ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Path))
}

function Get-HrsQaLanePaths {
    param([Parameter(Mandatory = $true)] [string] $LaneRoot)

    $root = [System.IO.Path]::GetFullPath($LaneRoot).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    if (-not [System.IO.Directory]::Exists($root)) { throw 'QA_LANE_MISSING' }
    return [pscustomobject][ordered]@{
        LaneRoot = $root
        ReleasePath = [System.IO.Path]::Combine($root, 'dev', 'qa', 'rel.json')
        ContractPath = [System.IO.Path]::Combine($root, 'dev', 'qa', 'cases.json')
        PayloadRoot = [System.IO.Path]::Combine($root, 'dev', 'verified', 'main')
        ManagerPath = [System.IO.Path]::Combine($root, 'dev', 'ui', 'p0158.ps1')
        RuntimeLogSourcePath = [System.IO.Path]::Combine($root, 'dev', 'src', 'runtime', 'main', 'c0217.cs')
        CatalogSourcePath = [System.IO.Path]::Combine($root, 'dev', 'src', 'runtime', 'main', 'c0213.cs')
        RuntimeSourcePath = [System.IO.Path]::Combine($root, 'dev', 'src', 'runtime', 'main', 'c0167.cs')
        ModInfoPath = [System.IO.Path]::Combine($root, 'dev', 'verified', 'main', 'ModInfo.xml')
    }
}

function Add-HrsQaFinding {
    param(
        [Parameter(Mandatory = $true)] [AllowEmptyCollection()] [System.Collections.Generic.List[object]] $Findings,
        [Parameter(Mandatory = $true)] [ValidateSet('Error', 'Warning', 'Pass')] [string] $Severity,
        [Parameter(Mandatory = $true)] [string] $Code,
        [Parameter(Mandatory = $true)] [string] $Message
    )

    [void]$Findings.Add([pscustomobject][ordered]@{
        severity = $Severity
        code = $Code
        message = $Message
    })
}

function Test-HrsQaRelease {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)] [string] $LaneRoot)

    $paths = Get-HrsQaLanePaths -LaneRoot $LaneRoot
    $findings = New-Object System.Collections.Generic.List[object]
    try { $release = Read-HrsQaJson -Path $paths.ReleasePath }
    catch {
        Add-HrsQaFinding $findings Error RELEASE_RECORD_INVALID $_.Exception.Message
        return [pscustomobject][ordered]@{
            schema = 'hrs-release-validation/v1'
            observedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            version = ''
            readyForQa = $false
            errorCount = 1
            warningCount = 0
            findings = $findings.ToArray()
        }
    }

    if ([string]$release.schema -cne 'hrs-release/v1') {
        Add-HrsQaFinding $findings Error RELEASE_SCHEMA 'rel.json must use hrs-release/v1.'
    }
    if ([string]$release.version -cnotmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-[a-z0-9.-]+)?$') {
        Add-HrsQaFinding $findings Error RELEASE_VERSION 'The release version is invalid.'
    }
    if ([string]$release.buildId -cnotmatch '^r[0-9]+$') {
        Add-HrsQaFinding $findings Error RELEASE_BUILD_ID 'The build ID must use r plus digits.'
    }
    if ([string]$release.sourceCommit -cnotmatch '^[0-9a-f]{40}$') {
        Add-HrsQaFinding $findings Error RELEASE_SOURCE_COMMIT 'A full source commit must be recorded before QA starts.'
    }

    $artifactCount = 0
    foreach ($artifact in @($release.artifacts)) {
        $artifactCount++
        $relative = [string]$artifact.path
        if ([string]::IsNullOrWhiteSpace($relative) -or [System.IO.Path]::IsPathRooted($relative) -or
            $relative.Contains('..')) {
            Add-HrsQaFinding $findings Error ARTIFACT_PATH "Unsafe artifact path: $relative"
            continue
        }
        $absolute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($paths.LaneRoot, $relative))
        $prefix = $paths.LaneRoot + [System.IO.Path]::DirectorySeparatorChar
        if (-not $absolute.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            Add-HrsQaFinding $findings Error ARTIFACT_PATH_ESCAPE "Artifact escapes the lane: $relative"
            continue
        }
        if (-not [System.IO.File]::Exists($absolute)) {
            Add-HrsQaFinding $findings Error ARTIFACT_MISSING "Artifact is missing: $relative"
            continue
        }
        $info = New-Object System.IO.FileInfo($absolute)
        $actualHash = Get-HrsQaSha256 -Path $absolute
        if ([UInt64]$artifact.bytes -ne [UInt64]$info.Length) {
            Add-HrsQaFinding $findings Error ARTIFACT_SIZE "Artifact size differs: $relative"
        }
        if (-not [string]::Equals([string]$artifact.sha256, $actualHash, [System.StringComparison]::Ordinal)) {
            Add-HrsQaFinding $findings Error ARTIFACT_HASH "Artifact hash differs: $relative"
        }
    }
    if ($artifactCount -ne 2) {
        Add-HrsQaFinding $findings Error ARTIFACT_SET 'The release must identify exactly the DLL and ModInfo.xml.'
    }
    else {
        Add-HrsQaFinding $findings Pass ARTIFACT_IDENTITY 'The two verified artifact identities match rel.json.'
    }

    try {
        [xml]$modInfo = [System.IO.File]::ReadAllText($paths.ModInfoPath)
        $versionNode = $modInfo.SelectSingleNode('/xml/Version')
        if ($null -eq $versionNode) { throw 'MODINFO_VERSION_MISSING' }
        $metadataVersion = [string]$versionNode.GetAttribute('value')
        if (-not [string]::Equals($metadataVersion, [string]$release.version, [System.StringComparison]::Ordinal)) {
            Add-HrsQaFinding $findings Error MODINFO_VERSION "ModInfo version $metadataVersion does not match release $($release.version)."
        }
        else { Add-HrsQaFinding $findings Pass MODINFO_VERSION 'ModInfo.xml matches the release version.' }
    }
    catch { Add-HrsQaFinding $findings Error MODINFO_INVALID $_.Exception.Message }

    if ([System.IO.File]::Exists($paths.ManagerPath)) {
        $manager = [System.IO.File]::ReadAllText($paths.ManagerPath)
        foreach ($artifact in @($release.artifacts)) {
            if (-not $manager.Contains([string]$artifact.sha256)) {
                Add-HrsQaFinding $findings Error MANAGER_PIN "Manager does not pin $($artifact.path)."
            }
        }
        if (-not $manager.Contains("Release | $($release.version)")) {
            Add-HrsQaFinding $findings Error MANAGER_VERSION 'Manager display does not match the release version.'
        }
        if (-not $manager.Contains("-ReleaseVersion '$($release.version)'")) {
            Add-HrsQaFinding $findings Error DEPLOYMENT_VERSION 'Deployment version does not match rel.json.'
        }
        if (-not $manager.Contains([string]$release.supportedEnvironment.assemblyCSharpMvid)) {
            Add-HrsQaFinding $findings Error GAME_MVID_PIN 'Manager does not contain the supported game MVID.'
        }
    }
    else { Add-HrsQaFinding $findings Error MANAGER_MISSING 'The manager source is missing.' }

    if ([System.IO.File]::Exists($paths.RuntimeLogSourcePath)) {
        $logSource = [System.IO.File]::ReadAllText($paths.RuntimeLogSourcePath)
        $identity = "v=$($release.runtimeLog.version) build=$($release.runtimeLog.buildId)"
        if (-not $logSource.Contains($identity)) {
            Add-HrsQaFinding $findings Error RUNTIME_LOG_IDENTITY 'Runtime log identity does not match rel.json.'
        }
        else { Add-HrsQaFinding $findings Pass RUNTIME_LOG_IDENTITY 'Runtime log version and build ID match rel.json.' }
    }

    $approved = @($release.scope.approvedSpawnPoints)
    if ($approved.Count -ne 2) {
        Add-HrsQaFinding $findings Error SPAWN_SCOPE 'The current release contract requires exactly two approved spawn points.'
    }
    if ([System.IO.File]::Exists($paths.CatalogSourcePath)) {
        $catalog = [System.IO.File]::ReadAllText($paths.CatalogSourcePath)
        foreach ($point in $approved) {
            if ($null -ne $point.PSObject.Properties['y']) {
                $needle = 'new CuratedStartPoint("' + [string]$point.id + '", "' + [string]$point.description + '", ' +
                    [string]$point.x + ', ' + [string]$point.y + ', ' + [string]$point.z + ')'
            }
            else {
                $needle = 'new CuratedStartPoint("' + [string]$point.id + '", "' + [string]$point.description + '", ' +
                    [string]$point.x + ', ' + [string]$point.z + ')'
            }
            if (-not $catalog.Contains($needle)) {
                Add-HrsQaFinding $findings Error SPAWN_POINT_DRIFT "Catalog does not match approved point $($point.id)."
            }
        }
        if ([string]$release.scope.selection -ceq 'random-among-approved') {
            if ($catalog.Contains('private const int SurveyPointIndex') -or
                $catalog.Contains('int pointIndex = SurveyPointIndex;')) {
                Add-HrsQaFinding $findings Error SPAWN_SELECTOR_FIXED 'Runtime selection is fixed to one survey point; it does not randomize between the two approved points.'
            }
            elseif (-not $catalog.Contains(
                'private static readonly int[] ApprovedPointIndices = { 0, 1 };') -or
                -not $catalog.Contains('world.GetGameRandom().RandomRange(') -or
                -not $catalog.Contains('ApprovedPointIndices.Length') -or
                -not $catalog.Contains('int pointIndex = ApprovedPointIndices[approvedSlot];') -or
                $catalog.Contains('world.GetGameRandom().RandomRange(Points.Length)')) {
                Add-HrsQaFinding $findings Error SPAWN_SELECTOR_APPROVED 'Runtime selection does not match the explicit NG01/NG02 allowlist and game-owned RNG contract.'
            }
            else {
                Add-HrsQaFinding $findings Pass SPAWN_SELECTOR_APPROVED 'Runtime selection uses the explicit NG01/NG02 allowlist and game-owned RNG.'
            }
        }
    }

    if ([System.IO.File]::Exists($paths.RuntimeSourcePath)) {
        $runtime = [System.IO.File]::ReadAllText($paths.RuntimeSourcePath)
        if (-not $runtime.Contains([string]$release.scope.starterQuestId) -or
            -not $runtime.Contains('ObjectiveGoto') -or
            -not $runtime.Contains('SetLocation') -or
            -not $runtime.Contains('double distance') -or
            -not $runtime.Contains('if (distance < best)')) {
            Add-HrsQaFinding $findings Error TRADER_CONTRACT 'Nearest-trader or starter-quest implementation markers are missing.'
        }
        else { Add-HrsQaFinding $findings Pass TRADER_CONTRACT 'Nearest-trader and starter-quest implementation markers are present.' }
        $traders = @($release.scope.reviewedTraderPlacements)
        if ($traders.Count -ne 5) {
            Add-HrsQaFinding $findings Error TRADER_PLACEMENT_SET 'The release contract must identify five reviewed Navezgane trader placements.'
        }
        else {
            foreach ($trader in $traders) {
                $locationNeedle = 'new Vector3(' + [string]$trader.sourceX + 'f,'
                $zNeedle = ', ' + [string]$trader.sourceZ + 'f)'
                if (-not $runtime.Contains($locationNeedle) -or -not $runtime.Contains($zNeedle)) {
                    Add-HrsQaFinding $findings Error TRADER_PLACEMENT_DRIFT "Runtime source does not contain reviewed placement $($trader.id)."
                }
                $expectedCenterX = [double]$trader.sourceX + ([double]$trader.sizeX * 0.5)
                $expectedCenterZ = [double]$trader.sourceZ + ([double]$trader.sizeZ * 0.5)
                if ([double]$trader.x -ne $expectedCenterX -or [double]$trader.z -ne $expectedCenterZ) {
                    Add-HrsQaFinding $findings Error TRADER_CENTER_DRIFT "Computed center differs for placement $($trader.id)."
                }
            }
        }
    }

    try {
        $contract = Read-HrsQaJson -Path $paths.ContractPath
        if ([string]$contract.schema -cne 'hrs-qa-contract/v1' -or
            [string]$contract.releaseVersion -cne [string]$release.version) {
            Add-HrsQaFinding $findings Error QA_CONTRACT_IDENTITY 'QA contract does not match this release.'
        }
        $ids = @($contract.requiredCases | ForEach-Object { [string]$_.id })
        foreach ($requiredId in @('HRS-QA-001','HRS-QA-002','HRS-QA-003A','HRS-QA-003B','HRS-QA-004','HRS-QA-005','HRS-QA-006','HRS-QA-007','HRS-QA-008')) {
            if ($ids -cnotcontains $requiredId) {
                Add-HrsQaFinding $findings Error QA_CASE_MISSING "Required QA case is missing: $requiredId"
            }
        }
    }
    catch { Add-HrsQaFinding $findings Error QA_CONTRACT_INVALID $_.Exception.Message }

    $errors = @($findings | Where-Object { $_.severity -eq 'Error' }).Count
    $warnings = @($findings | Where-Object { $_.severity -eq 'Warning' }).Count
    return [pscustomobject][ordered]@{
        schema = 'hrs-release-validation/v1'
        observedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        version = [string]$release.version
        buildId = [string]$release.buildId
        readyForQa = ($errors -eq 0)
        errorCount = $errors
        warningCount = $warnings
        findings = $findings.ToArray()
    }
}

function Get-HrsQaPackageInventory {
    param([Parameter(Mandatory = $true)] [string] $LaneRoot)

    $paths = Get-HrsQaLanePaths -LaneRoot $LaneRoot
    $release = Read-HrsQaJson -Path $paths.ReleasePath
    $files = New-Object System.Collections.Generic.List[object]
    foreach ($artifact in @($release.artifacts)) {
        $absolute = [System.IO.Path]::Combine($paths.LaneRoot, ([string]$artifact.path).Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        if ([System.IO.File]::Exists($absolute)) {
            $info = New-Object System.IO.FileInfo($absolute)
            [void]$files.Add([pscustomobject][ordered]@{
                path = [string]$artifact.path
                bytes = [UInt64]$info.Length
                sha256 = Get-HrsQaSha256 -Path $absolute
            })
        }
    }
    return [pscustomobject][ordered]@{
        schema = 'hrs-package-inventory/v1'
        version = [string]$release.version
        observedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        files = $files.ToArray()
    }
}

function Get-HrsQaInstalledInventory {
    param(
        [Parameter(Mandatory = $true)] [string] $LaneRoot,
        [string] $GameRoot = ''
    )

    $release = Read-HrsQaJson -Path (Get-HrsQaLanePaths -LaneRoot $LaneRoot).ReleasePath
    $record = [ordered]@{
        schema = 'hrs-installed-inventory/v1'
        version = [string]$release.version
        observedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        state = 'NotProvided'
        files = @()
    }
    if ([string]::IsNullOrWhiteSpace($GameRoot)) { return [pscustomobject]$record }
    $root = [System.IO.Path]::GetFullPath($GameRoot)
    $exe = [System.IO.Path]::Combine($root, '7DaysToDie.exe')
    if (-not [System.IO.File]::Exists($exe)) {
        $record.state = 'GameRootInvalid'
        return [pscustomobject]$record
    }
    $releaseRoot = [System.IO.Path]::Combine($root, 'Mods', 'BitWrecked_HistoricalRandomStart')
    if (-not [System.IO.Directory]::Exists($releaseRoot)) {
        $record.state = 'NotInstalled'
        return [pscustomobject]$record
    }
    $items = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($file in [System.IO.Directory]::EnumerateFiles($releaseRoot, '*', [System.IO.SearchOption]::AllDirectories)) {
            $attributes = [System.IO.File]::GetAttributes($file)
            $relative = $file.Substring($releaseRoot.Length).TrimStart('\','/').Replace('\','/')
            if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                [void]$items.Add([pscustomobject][ordered]@{ path=$relative; state='ReparsePoint'; bytes=0; sha256='' })
                continue
            }
            $info = New-Object System.IO.FileInfo($file)
            [void]$items.Add([pscustomobject][ordered]@{
                path = $relative
                state = 'File'
                bytes = [UInt64]$info.Length
                sha256 = Get-HrsQaSha256 -Path $file
            })
        }
        $record.state = 'InstalledObserved'
        $record.files = @($items | Sort-Object path)
    }
    catch { $record.state = 'InventoryFailed' }
    return [pscustomobject]$record
}

function Get-HrsQaEnvironment {
    param(
        [Parameter(Mandatory = $true)] [string] $LaneRoot,
        [string] $GameRoot = ''
    )

    $release = Read-HrsQaJson -Path (Get-HrsQaLanePaths -LaneRoot $LaneRoot).ReleasePath
    $game = [ordered]@{ supplied=$false; executableVersion=''; assemblyCSharpBytes=0; assemblyCSharpSha256=''; assemblyCSharpMvid='' }
    if (-not [string]::IsNullOrWhiteSpace($GameRoot)) {
        $root = [System.IO.Path]::GetFullPath($GameRoot)
        $exe = [System.IO.Path]::Combine($root, '7DaysToDie.exe')
        $assembly = [System.IO.Path]::Combine($root, '7DaysToDie_Data', 'Managed', 'Assembly-CSharp.dll')
        $game.supplied = $true
        if ([System.IO.File]::Exists($exe)) { $game.executableVersion = (Get-Item -LiteralPath $exe).VersionInfo.FileVersion }
        if ([System.IO.File]::Exists($assembly)) {
            $info = New-Object System.IO.FileInfo($assembly)
            $game.assemblyCSharpBytes = [UInt64]$info.Length
            $game.assemblyCSharpSha256 = Get-HrsQaSha256 -Path $assembly
            try { $game.assemblyCSharpMvid = ([System.Reflection.Assembly]::ReflectionOnlyLoadFrom($assembly)).ManifestModule.ModuleVersionId.ToString() }
            catch { $game.assemblyCSharpMvid = 'Unreadable' }
        }
    }
    return [pscustomobject][ordered]@{
        schema = 'hrs-environment/v1'
        observedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        releaseVersion = [string]$release.version
        operatingSystem = [Environment]::OSVersion.VersionString
        processArchitecture = $(if ([Environment]::Is64BitProcess) { 'x64' } else { 'x86' })
        powershellVersion = $PSVersionTable.PSVersion.ToString()
        game = [pscustomobject]$game
    }
}

function Get-HrsQaLatestLog {
    param([string] $ExplicitPath = '')

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        $full = [System.IO.Path]::GetFullPath($ExplicitPath)
        if ([System.IO.File]::Exists($full)) { return $full }
        return ''
    }
    if ([string]::IsNullOrWhiteSpace($env:APPDATA)) { return '' }
    $root = [System.IO.Path]::Combine($env:APPDATA, '7DaysToDie', 'logs')
    if (-not [System.IO.Directory]::Exists($root)) { return '' }
    $latest = Get-ChildItem -LiteralPath $root -File -Filter '*.txt' | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if ($null -eq $latest) { return '' }
    return $latest.FullName
}

function Get-HrsQaRuntimeEvents {
    param(
        [string] $LogPath,
        [int] $SkipHrsLines = 0
    )

    $events = New-Object System.Collections.Generic.List[object]
    if ([string]::IsNullOrWhiteSpace($LogPath) -or -not [System.IO.File]::Exists($LogPath)) { return $events.ToArray() }
    $hrsLines = @([System.IO.File]::ReadAllLines($LogPath) | Where-Object { $_ -match '\[HRS\]' })
    if ($SkipHrsLines -gt 0 -and $SkipHrsLines -lt $hrsLines.Count) { $hrsLines = @($hrsLines | Select-Object -Skip $SkipHrsLines) }
    elseif ($SkipHrsLines -ge $hrsLines.Count) { $hrsLines = @() }
    $sequence = 0
    foreach ($line in $hrsLines) {
        $sequence++
        $match = [regex]::Match($line, '\[HRS\]\s+v=(?<version>[^\s]+)\s+build=(?<build>[^\s]+)\s+reason=(?<reason>[A-Z0-9_-]+)')
        if ($match.Success) {
            [void]$events.Add([pscustomobject][ordered]@{
                sequence = $sequence
                version = $match.Groups['version'].Value
                buildId = $match.Groups['build'].Value
                event = $match.Groups['reason'].Value
            })
        }
    }
    return $events.ToArray()
}

function Get-HrsQaHistoryEvents {
    param(
        [string] $HistoryPath,
        [int] $SkipLines = 0
    )

    $events = New-Object System.Collections.Generic.List[object]
    if ([string]::IsNullOrWhiteSpace($HistoryPath) -or -not [System.IO.File]::Exists($HistoryPath)) { return $events.ToArray() }
    $lines = @([System.IO.File]::ReadAllLines($HistoryPath))
    if ($SkipLines -gt 0 -and $SkipLines -lt $lines.Count) { $lines = @($lines | Select-Object -Skip $SkipLines) }
    elseif ($SkipLines -ge $lines.Count) { $lines = @() }
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $event = ConvertFrom-Json -InputObject $line
            [void]$events.Add([pscustomobject][ordered]@{
                schema = [string]$event.schema
                correlationId = [string]$event.correlationId
                observedUtc = [string]$event.observedUtc
                action = [string]$event.action
                outcome = [string]$event.outcome
                reason = [string]$event.reason
                gameName = '<redacted>'
                revision = [UInt64]$event.revision
                mode = [string]$event.mode
            })
        }
        catch { }
    }
    return $events.ToArray()
}

function Get-HrsQaResultSummary {
    param(
        [object] $InstalledInventory,
        [string] $GameRoot = ''
    )

    $resultEntry = @($InstalledInventory.files | Where-Object { $_.path -ceq 'Bridge/result.v1.json' })
    $summary = [ordered]@{
        schema = 'hrs-result-summary/v1'
        observedUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        available = ($resultEntry.Count -eq 1)
        resultSha256 = $(if ($resultEntry.Count -eq 1) { [string]$resultEntry[0].sha256 } else { '' })
        policyRevision = 0
        policyDigest = ''
        outcome = ''
        reason = ''
        markerState = ''
        resultObservedUtc = ''
        note = 'The result schema contains no game-name or filesystem-path field.'
    }
    if (-not [string]::IsNullOrWhiteSpace($GameRoot)) {
        $resultPath = [System.IO.Path]::Combine(
            [System.IO.Path]::GetFullPath($GameRoot),
            'Mods', 'BitWrecked_HistoricalRandomStart', 'Bridge', 'result.v1.json'
        )
        if ([System.IO.File]::Exists($resultPath)) {
            try {
                $result = Read-HrsQaJson -Path $resultPath
                if ([string]$result.schema -ceq 'hrs-result/v1') {
                    $summary.policyRevision = [UInt64]$result.policyRevision
                    $summary.policyDigest = [string]$result.policyDigest
                    $summary.outcome = [string]$result.outcome
                    $summary.reason = [string]$result.reason
                    $summary.markerState = [string]$result.markerState
                    $summary.resultObservedUtc = [string]$result.observedUtc
                }
            }
            catch { $summary.note = 'The result fingerprint was captured, but its bounded schema could not be parsed.' }
        }
    }
    return [pscustomobject]$summary
}

function New-HrsQaEvidenceManifest {
    param([Parameter(Mandatory = $true)] [string] $RunPath)

    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($file in Get-ChildItem -LiteralPath $RunPath -Recurse -File | Where-Object {
        $_.Name -cne 'session.local.json' -and $_.Name -cne 'evidence-manifest.json'
    } | Sort-Object FullName) {
        $relative = $file.FullName.Substring($RunPath.Length).TrimStart('\','/').Replace('\','/')
        [void]$entries.Add([pscustomobject][ordered]@{
            path = $relative
            bytes = [UInt64]$file.Length
            sha256 = Get-HrsQaSha256 -Path $file.FullName
        })
    }
    return [pscustomobject][ordered]@{
        schema = 'hrs-evidence-manifest/v1'
        createdUtc = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        files = $entries.ToArray()
    }
}

Export-ModuleMember -Function @(
    'Get-HrsQaSha256', 'Write-HrsQaJson', 'Read-HrsQaJson',
    'Get-HrsQaLanePaths', 'Test-HrsQaRelease', 'Get-HrsQaPackageInventory',
    'Get-HrsQaInstalledInventory', 'Get-HrsQaEnvironment', 'Get-HrsQaLatestLog',
    'Get-HrsQaRuntimeEvents', 'Get-HrsQaHistoryEvents', 'Get-HrsQaResultSummary',
    'New-HrsQaEvidenceManifest'
)
