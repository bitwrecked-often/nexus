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
    $packageRoot = $root
    if (Test-Path -LiteralPath (Join-Path $root 'qa-workspace.json')) {
        $release = Read-HrsQaJson (Join-Path $root 'dev/qa/rel.json')
        $packageRoot = Join-Path (Split-Path -Parent $root) ('customer/' + (Get-HrsCustomerFolder ([string]$release.version)))
    }
    return [pscustomobject][ordered]@{
        LaneRoot = $root
        PackageRoot = $packageRoot
        ReleasePath = [System.IO.Path]::Combine($root, 'dev', 'qa', 'rel.json')
        ContractPath = [System.IO.Path]::Combine($root, 'dev', 'qa', 'cases.json')
        PayloadRoot = [System.IO.Path]::Combine($packageRoot, 'dev', 'verified', 'main')
        ManagerPath = [System.IO.Path]::Combine($packageRoot, 'dev', 'ui', 'p0158.ps1')
        RuntimeLogSourcePath = [System.IO.Path]::Combine($root, 'dev', 'src', 'runtime', 'main', 'c0217.cs')
        CatalogSourcePath = [System.IO.Path]::Combine($root, 'dev', 'src', 'runtime', 'main', 'c0213.cs')
        PlacedPoiSourcePath = [System.IO.Path]::Combine($root, 'dev', 'src', 'runtime', 'main', 'PlacedPoiResolver.cs')
        PlacedTraderSourcePath = [System.IO.Path]::Combine($root, 'dev', 'src', 'runtime', 'main', 'PlacedTraderResolver.cs')
        PendingSourcePath = [System.IO.Path]::Combine($root, 'dev', 'src', 'runtime', 'main', 'c0185.cs')
        RuntimeSourcePath = [System.IO.Path]::Combine($root, 'dev', 'src', 'runtime', 'main', 'c0167.cs')
        ModInfoPath = [System.IO.Path]::Combine($packageRoot, 'dev', 'verified', 'main', 'ModInfo.xml')
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

function Test-HrsQaSpawnScope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $Catalog,
        [Parameter(Mandatory = $true)] [object[]] $ApprovedPoints,
        [Parameter(Mandatory = $true)] [string] $Selection
    )

    $findings = New-Object System.Collections.Generic.List[object]
    if ($Selection -cne 'random-among-approved') {
        return $findings.ToArray()
    }

    $declaredIds = @($ApprovedPoints | ForEach-Object { [string]$_.id })
    if ($declaredIds.Count -eq 0 -or @($declaredIds | Sort-Object -Unique).Count -ne $declaredIds.Count) {
        [void]$findings.Add([pscustomobject]@{
            severity = 'Error'
            code = 'SPAWN_SCOPE'
            message = 'The release scope must contain at least one unique approved spawn ID.'
        })
        return $findings.ToArray()
    }

    $Catalog = [regex]::Replace($Catalog, '(?s)/\*.*?\*/|//[^\r\n]*', '')
    if ($Catalog.Contains('private const int SurveyPointIndex') -or
        $Catalog.Contains('int pointIndex = SurveyPointIndex;')) {
        [void]$findings.Add([pscustomobject]@{
            severity = 'Error'
            code = 'SPAWN_SELECTOR_FIXED'
            message = 'Runtime selection is fixed to one survey point; it does not randomize across the declared approved scope.'
        })
        return $findings.ToArray()
    }

    $selectorText = [regex]::Replace($Catalog, '(?s)/\*.*?\*/|//[^\r\n]*', '')
    $randomCallCount = @([regex]::Matches($selectorText, 'world\.GetGameRandom\(\)\.RandomRange\s*\(')).Count
    $selectorCallValid = [regex]::IsMatch(
        $selectorText,
        'int\s+approvedSlot\s*=\s*world\.GetGameRandom\(\)\.RandomRange\(\s*ApprovedPointIndices\.Length\s*\)\s*;',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    $indexSelectionValid = [regex]::IsMatch(
        $selectorText,
        'int\s+pointIndex\s*=\s*ApprovedPointIndices\s*\[\s*approvedSlot\s*\]\s*;',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if ($randomCallCount -ne 1 -or -not $selectorCallValid -or -not $indexSelectionValid -or
        $selectorText.Contains('world.GetGameRandom().RandomRange(Points.Length)')) {
        [void]$findings.Add([pscustomobject]@{
            severity = 'Error'
            code = 'SPAWN_SELECTOR_APPROVED'
            message = 'Runtime selection does not use one game-owned RNG draw over an explicit approved-index allowlist.'
        })
        return $findings.ToArray()
    }

    $pointMatches = [regex]::Matches($Catalog, 'new CuratedStartPoint\("([^"]+)"')
    $pointIds = @($pointMatches | ForEach-Object { [string]$_.Groups[1].Value })
    $arrayMatch = [regex]::Match(
        $Catalog,
        'ApprovedPointIndices\s*=\s*\{(?<values>[^}]*)\}',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $arrayMatch.Success -or
        $arrayMatch.Groups['values'].Value -cnotmatch '^\s*-?\d+(?:\s*,\s*-?\d+)*\s*,?\s*$') {
        [void]$findings.Add([pscustomobject]@{
            severity = 'Error'
            code = 'SPAWN_SELECTOR_APPROVED'
            message = 'The runtime does not declare ApprovedPointIndices.'
        })
        return $findings.ToArray()
    }

    $selectedIndices = @([regex]::Matches($arrayMatch.Groups['values'].Value, '-?\d+') |
        ForEach-Object { [int]$_.Value })
    if ($selectedIndices.Count -eq 0 -or @($selectedIndices | Sort-Object -Unique).Count -ne $selectedIndices.Count) {
        [void]$findings.Add([pscustomobject]@{
            severity = 'Error'
            code = 'SPAWN_SELECTOR_SCOPE'
            message = 'ApprovedPointIndices must contain unique selectable indices.'
        })
        return $findings.ToArray()
    }

    $selectedIds = New-Object System.Collections.Generic.List[string]
    foreach ($index in $selectedIndices) {
        if ($index -lt 0 -or $index -ge $pointIds.Count) {
            [void]$findings.Add([pscustomobject]@{
                severity = 'Error'
                code = 'SPAWN_SELECTOR_SCOPE'
                message = "ApprovedPointIndices contains out-of-range index $index."
            })
            continue
        }
        [void]$selectedIds.Add($pointIds[$index])
    }
    if (@($findings | Where-Object { $_.severity -eq 'Error' }).Count -gt 0) {
        return $findings.ToArray()
    }

    $missing = @($declaredIds | Where-Object { $selectedIds -notcontains $_ })
    $unexpected = @($selectedIds | Where-Object { $declaredIds -notcontains $_ })
    if ($missing.Count -gt 0 -or $unexpected.Count -gt 0 -or
        $selectedIds.Count -ne $declaredIds.Count) {
        $missingText = if ($missing.Count -eq 0) { 'none' } else { $missing -join ', ' }
        $unexpectedText = if ($unexpected.Count -eq 0) { 'none' } else { $unexpected -join ', ' }
        [void]$findings.Add([pscustomobject]@{
            severity = 'Error'
            code = 'SPAWN_SELECTOR_SCOPE'
            message = "Runtime allowlist does not match the release scope. Missing: $missingText; unexpected: $unexpectedText."
        })
        return $findings.ToArray()
    }

    [void]$findings.Add([pscustomobject]@{
        severity = 'Pass'
        code = 'SPAWN_SELECTOR_APPROVED'
        message = "Runtime selection uses one game-owned RNG draw over the $($declaredIds.Count)-point approved scope."
    })
    return $findings.ToArray()
}

function Test-HrsQaPlacedWorldScope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $PoiSource,
        [Parameter(Mandatory = $true)] [string] $TraderSource,
        [Parameter(Mandatory = $true)] [string] $PendingSource,
        [Parameter(Mandatory = $true)] [string] $RuntimeSource,
        [Parameter(Mandatory = $true)] [string] $LogSource,
        [Parameter(Mandatory = $true)] [object[]] $ApprovedPrefabNames,
        [Parameter(Mandatory = $true)] [int] $MaxPoiAttempts,
        [Parameter(Mandatory = $true)] [int] $RetryDelaySeconds,
        [Parameter(Mandatory = $true)] [string] $StarterQuestId
    )

    $findings = New-Object System.Collections.Generic.List[object]
    $declared = @($ApprovedPrefabNames | ForEach-Object { [string]$_ })
    $match = [regex]::Match($PoiSource,
        'private static readonly HashSet<string> Names\s*=\s*new HashSet<string>\(StringComparer\.Ordinal\)\s*\{(?<body>[^}]+)\}',
        [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if (-not $match.Success) {
        Add-HrsQaFinding $findings Error PLACED_POI_ALLOWLIST 'Placed-POI source allowlist is missing.'
    }
    else {
        $actual = @([regex]::Matches($match.Groups['body'].Value,
            '"(?<name>[^"]+)"') | ForEach-Object { $_.Groups['name'].Value })
        $missing = @($declared | Where-Object { $actual -cnotcontains $_ })
        $unexpected = @($actual | Where-Object { $declared -cnotcontains $_ })
        if ($declared.Count -eq 0 -or
            @($declared | Where-Object { $_ -cnotmatch '^[a-z0-9_]+$' }).Count -gt 0 -or
            @($declared | Sort-Object -CaseSensitive -Unique).Count -ne $declared.Count -or
            @($actual | Sort-Object -CaseSensitive -Unique).Count -ne $actual.Count -or
            $missing.Count -gt 0 -or $unexpected.Count -gt 0 -or
            $actual.Count -ne $declared.Count) {
            Add-HrsQaFinding $findings Error PLACED_POI_ALLOWLIST 'Contract prefab names do not exactly match the runtime placed-POI allowlist.'
        }
        else {
            Add-HrsQaFinding $findings Pass PLACED_POI_ALLOWLIST "Contract matches $($actual.Count) placed-prefab names."
        }
    }

    $poiCode = [regex]::Replace($PoiSource, '(?s)/\*.*?\*/|//[^\r\n]*', '')
    $traderCode = [regex]::Replace($TraderSource, '(?s)/\*.*?\*/|//[^\r\n]*', '')
    $pendingCode = [regex]::Replace($PendingSource, '(?s)/\*.*?\*/|//[^\r\n]*', '')
    $runtimeCode = [regex]::Replace($RuntimeSource, '(?s)/\*.*?\*/|//[^\r\n]*', '')
    if (-not $poiCode.Contains('decorator.GetWorldPrefabs(placed)') -or
        -not $poiCode.Contains('if (!IsAllowedName(name)) continue;') -or
        -not $poiCode.Contains('world.GetBiomeInWorld(x, z)') -or
        -not $poiCode.Contains('instance.GetAABB()') -or
        $poiCode.Contains('GetPOIPrefabs(')) {
        Add-HrsQaFinding $findings Error PLACED_POI_SOURCE 'Placed-POI source no longer indexes eligible active-world placements with world-wide biome and rotated bounds.'
    }
    else { Add-HrsQaFinding $findings Pass PLACED_POI_SOURCE 'Placed-POI source uses the active-world index and geometry.' }

    if ($MaxPoiAttempts -lt 1 -or $RetryDelaySeconds -lt 0 -or
        -not $pendingCode.Contains("private const int MaximumPoiAttempts = $MaxPoiAttempts;") -or
        -not $runtimeCode.Contains("private const float RetryDelaySeconds = $RetryDelaySeconds") -or
        -not $runtimeCode.Contains('player.SetPosition(attempt.OriginalPosition, true)') -or
        -not $runtimeCode.Contains('attempt.AdoptNextPoi(next,')) {
        Add-HrsQaFinding $findings Error PLACED_POI_RETRY 'Declared retry bound, delay or original-start rollback differs from source.'
    }
    else { Add-HrsQaFinding $findings Pass PLACED_POI_RETRY 'Retry bound, delay and rollback markers match source.' }

    if (-not $traderCode.Contains('decorator.GetWorldPrefabs(placed)') -or
        -not $traderCode.Contains('instance.prefab.bTraderArea') -or
        -not $traderCode.Contains('candidate.BiomeId == startingBiome') -or
        -not $traderCode.Contains('crossedBiome = selected != null && !sameFound') -or
        -not $runtimeCode.Contains('PlacedTraderResolver.TrySelect') -or
        -not $runtimeCode.Contains($StarterQuestId) -or
        -not $runtimeCode.Contains('objective.SetLocation(trader.Location, trader.Size)')) {
        Add-HrsQaFinding $findings Error PLACED_TRADER_SOURCE 'Placed-trader or starter-objective source markers differ from the declared route.'
    }
    else { Add-HrsQaFinding $findings Pass PLACED_TRADER_SOURCE 'Placed-trader and starter-objective markers match source.' }

    if (-not $LogSource.Contains('reason=POI_ATTEMPT_SELECTED') -or
        -not $LogSource.Contains('reason=POI_LANDING_COMPLETED') -or
        -not $LogSource.Contains('reason=TRADER_ROUTE_SELECTED')) {
        Add-HrsQaFinding $findings Error PLACED_IDENTITY_LOG 'The dynamic placement and trader identity log fields are missing.'
    }
    else { Add-HrsQaFinding $findings Pass PLACED_IDENTITY_LOG 'Dynamic placement and trader identity log fields are present.' }

    return $findings.ToArray()
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
    if ($release.PSObject.Properties.Name -contains 'sourceSnapshot') {
        foreach ($source in @($release.sourceSnapshot.sourceHashes)) {
            try {
                $sourcePath = Resolve-HrsContainedFile (Join-Path $paths.LaneRoot 'dev/src/runtime/main') $source.path
                if ((Get-HrsQaSha256 $sourcePath) -cne $source.sha256) { throw 'Source bytes differ from contract.' }
            }
            catch { Add-HrsQaFinding $findings Error SOURCE_IDENTITY ($source.path + ': ' + $_.Exception.Message) }
        }
    }

    $artifactCount = 0
    $artifactIdentityValid = $true
    $artifactPaths = New-Object System.Collections.Generic.List[string]
    foreach ($artifact in @($release.artifacts)) {
        $artifactCount++
        $relative = [string]$artifact.path
        if ([string]::IsNullOrWhiteSpace($relative) -or [System.IO.Path]::IsPathRooted($relative) -or
            $relative.Contains('..')) {
            Add-HrsQaFinding $findings Error ARTIFACT_PATH "Unsafe artifact path: $relative"
            $artifactIdentityValid = $false
            continue
        }
        if ($artifactPaths -contains $relative) {
            Add-HrsQaFinding $findings Error ARTIFACT_DUPLICATE "Duplicate artifact path: $relative"
            $artifactIdentityValid = $false
        }
        else { [void]$artifactPaths.Add($relative) }
        $absolute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($paths.PackageRoot, $relative))
        $prefix = $paths.PackageRoot + [System.IO.Path]::DirectorySeparatorChar
        if (-not $absolute.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            Add-HrsQaFinding $findings Error ARTIFACT_PATH_ESCAPE "Artifact escapes the lane: $relative"
            $artifactIdentityValid = $false
            continue
        }
        if (-not [System.IO.File]::Exists($absolute)) {
            Add-HrsQaFinding $findings Error ARTIFACT_MISSING "Artifact is missing: $relative"
            $artifactIdentityValid = $false
            continue
        }
        $info = New-Object System.IO.FileInfo($absolute)
        $actualHash = Get-HrsQaSha256 -Path $absolute
        if ([UInt64]$artifact.bytes -ne [UInt64]$info.Length) {
            Add-HrsQaFinding $findings Error ARTIFACT_SIZE "Artifact size differs: $relative"
            $artifactIdentityValid = $false
        }
        if (-not [string]::Equals([string]$artifact.sha256, $actualHash, [System.StringComparison]::Ordinal)) {
            Add-HrsQaFinding $findings Error ARTIFACT_HASH "Artifact hash differs: $relative"
            $artifactIdentityValid = $false
        }
    }
    $expectedArtifactPaths = @('dev/verified/main/d0163.dll', 'dev/verified/main/ModInfo.xml')
    if ($artifactCount -ne $expectedArtifactPaths.Count) {
        Add-HrsQaFinding $findings Error ARTIFACT_SET 'The release must identify exactly the DLL and ModInfo.xml.'
        $artifactIdentityValid = $false
    }
    foreach ($expectedPath in $expectedArtifactPaths) {
        if ($artifactPaths -notcontains $expectedPath) {
            Add-HrsQaFinding $findings Error ARTIFACT_SET "The release artifact set is missing: $expectedPath"
            $artifactIdentityValid = $false
        }
    }
    if ($artifactIdentityValid) {
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

    if ([string]$release.scope.selection -ceq 'random-among-placed-world') {
        $requiredSources = @($paths.PlacedPoiSourcePath,
            $paths.PlacedTraderSourcePath, $paths.PendingSourcePath,
            $paths.RuntimeSourcePath, $paths.RuntimeLogSourcePath)
        $missingSources = @($requiredSources | Where-Object {
            -not [System.IO.File]::Exists($_)
        })
        if ($missingSources.Count -gt 0) {
            Add-HrsQaFinding $findings Error PLACED_SOURCE_MISSING 'A required placed-world release source file is missing.'
        }
        else {
            try {
                $worldCategories = @($release.scope.worldCategories |
                    ForEach-Object { [string]$_ })
                if ($worldCategories.Count -eq 0 -or
                    @($worldCategories | Sort-Object -CaseSensitive -Unique).Count -ne $worldCategories.Count -or
                    @($worldCategories | Where-Object {
                        $_ -cnotin @('Navezgane', 'RandomGen', 'Pregen', 'Custom')
                    }).Count -gt 0) {
                    Add-HrsQaFinding $findings Error PLACED_WORLD_SCOPE 'Declared supported world categories are missing, duplicated or invalid.'
                }
                else { Add-HrsQaFinding $findings Pass PLACED_WORLD_SCOPE 'Declared supported world categories are explicit.' }
                if ($worldCategories -ccontains 'RandomGen') {
                    $minimumGeneratedWorldSize = 0
                    if (-not [int]::TryParse([string]$release.scope.minimumGeneratedWorldSize,
                        [ref]$minimumGeneratedWorldSize) -or $minimumGeneratedWorldSize -lt 8192) {
                        Add-HrsQaFinding $findings Error PLACED_WORLD_SIZE 'Random Gen support must declare a minimum world size of at least 8192.'
                    }
                    else {
                        Add-HrsQaFinding $findings Pass PLACED_WORLD_SIZE 'Random Gen minimum world size is explicit and at least 8192.'
                    }
                }
                foreach ($placedFinding in (Test-HrsQaPlacedWorldScope `
                    -PoiSource ([System.IO.File]::ReadAllText($paths.PlacedPoiSourcePath)) `
                    -TraderSource ([System.IO.File]::ReadAllText($paths.PlacedTraderSourcePath)) `
                    -PendingSource ([System.IO.File]::ReadAllText($paths.PendingSourcePath)) `
                    -RuntimeSource ([System.IO.File]::ReadAllText($paths.RuntimeSourcePath)) `
                    -LogSource ([System.IO.File]::ReadAllText($paths.RuntimeLogSourcePath)) `
                    -ApprovedPrefabNames @($release.scope.approvedPrefabNames) `
                    -MaxPoiAttempts ([int]$release.scope.maxPoiAttempts) `
                    -RetryDelaySeconds ([int]$release.scope.retryDelaySeconds) `
                    -StarterQuestId ([string]$release.scope.starterQuestId))) {
                    Add-HrsQaFinding $findings $placedFinding.severity $placedFinding.code $placedFinding.message
                }
            }
            catch {
                Add-HrsQaFinding $findings Error PLACED_SCOPE_INVALID $_.Exception.Message
            }
        }
    }
    else {
    $approved = @($release.scope.approvedSpawnPoints)
    if ($approved.Count -lt 1 -or @($approved | ForEach-Object { [string]$_.id } | Sort-Object -Unique).Count -ne $approved.Count) {
        Add-HrsQaFinding $findings Error SPAWN_SCOPE 'The release contract must contain at least one unique approved spawn point.'
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
            foreach ($spawnFinding in (Test-HrsQaSpawnScope -Catalog $catalog -ApprovedPoints $approved -Selection ([string]$release.scope.selection))) {
                Add-HrsQaFinding $findings $spawnFinding.severity $spawnFinding.code $spawnFinding.message
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

    }

    try {
        $contract = Read-HrsQaJson -Path $paths.ContractPath
        if ([string]$contract.schema -cne 'hrs-qa-contract/v1' -or
            [string]$contract.releaseVersion -cne [string]$release.version) {
            Add-HrsQaFinding $findings Error QA_CONTRACT_IDENTITY 'QA contract does not match this release.'
        }
        $ids = @($contract.requiredCases | ForEach-Object { [string]$_.id })
        if (@($ids | Sort-Object -Unique).Count -ne $ids.Count) { Add-HrsQaFinding $findings Error QA_CASE_DUPLICATE 'Case IDs must be unique.' }
        if ($release.PSObject.Properties.Name -contains 'candidateId' -and $contract.candidateId -cne $release.candidateId) {
            Add-HrsQaFinding $findings Error QA_CANDIDATE_MISMATCH 'Release and case contract candidate IDs must agree.'
        }
        foreach ($requiredId in @('HRS-QA-001','HRS-QA-002','HRS-QA-003A','HRS-QA-003B','HRS-QA-004','HRS-QA-005','HRS-QA-006','HRS-QA-007','HRS-QA-008')) {
            if ($ids -cnotcontains $requiredId) {
                Add-HrsQaFinding $findings Error QA_CASE_MISSING "Required QA case is missing: $requiredId"
            }
        }
        if ([string]$release.scope.selection -ceq 'random-among-placed-world') {
            foreach ($requiredId in @('HRS-QA-003A','HRS-QA-003B','HRS-QA-004')) {
                $placedCase = @($contract.requiredCases | Where-Object { [string]$_.id -ceq $requiredId })
                if ($placedCase.Count -ne 1 -or
                    $placedCase[0].PSObject.Properties.Name -notcontains 'requiresPlacedIdentity' -or
                    $placedCase[0].requiresPlacedIdentity -ne $true -or
                    $placedCase[0].PSObject.Properties.Name -contains 'expectedPointIds') {
                    Add-HrsQaFinding $findings Error QA_PLACED_CASE "Placed-world identity evidence is not required correctly in $requiredId."
                }
            }
            $traderCase = @($contract.requiredCases | Where-Object { [string]$_.id -ceq 'HRS-QA-004' })
            if ($traderCase.Count -ne 1 -or
                $traderCase[0].PSObject.Properties.Name -notcontains 'requiresPlacedTrader' -or
                $traderCase[0].requiresPlacedTrader -ne $true) {
                Add-HrsQaFinding $findings Error QA_PLACED_TRADER_CASE 'The placed-trader identity case is missing.'
            }
            foreach ($pair in @(@('HRS-QA-003A','Navezgane'), @('HRS-QA-003B','RandomGen'))) {
                $mapCase = @($contract.requiredCases | Where-Object { [string]$_.id -ceq $pair[0] })
                if ($mapCase.Count -ne 1 -or
                    $mapCase[0].PSObject.Properties.Name -notcontains 'expectedWorldCategory' -or
                    [string]$mapCase[0].expectedWorldCategory -cne [string]$pair[1]) {
                    Add-HrsQaFinding $findings Error QA_PLACED_WORLD_CASE "Map category is not pinned in $($pair[0])."
                }
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
        $absolute = [System.IO.Path]::Combine($paths.PackageRoot, ([string]$artifact.path).Replace('/', [System.IO.Path]::DirectorySeparatorChar))
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
        $match = [regex]::Match($line, '\[HRS\]\s+v=(?<version>[^\s]+)\s+build=(?<build>[^\s]+)\s+reason=(?<reason>[A-Z0-9_-]+)(?<tail>.*)$')
        if ($match.Success) {
            $reason = $match.Groups['reason'].Value
            $tail = $match.Groups['tail'].Value.Trim()
            $details = $null
            if ($reason -in @('BIOME_SELECTED','REQUESTED_BIOME_ABSENT','WEIGHTED_POOL_EMPTY','POI_POOL_EMPTY')) {
                $selection = [regex]::Match($tail, '\Arequested=(?<kind>Any|Chosen|Weighted):(?<chosen>[013589]):(?<forest>\d{1,3}):(?<burnt>\d{1,3}):(?<desert>\d{1,3}):(?<snow>\d{1,3}):(?<wasteland>\d{1,3}) eligible=(?<eligible>none|[13589](?:,[13589]){0,4}) selected=(?<selected>[013589])\z')
                if ($selection.Success) {
                    $details = [pscustomobject][ordered]@{
                        selection=$selection.Groups['kind'].Value
                        chosenBiome=$selection.Groups['chosen'].Value
                        weights=@('forest','burnt','desert','snow','wasteland' | ForEach-Object { [int]$selection.Groups[$_].Value })
                        eligible=$selection.Groups['eligible'].Value
                        selectedBiome=$selection.Groups['selected'].Value
                    }
                }
            }
            elseif ($reason -ceq 'POI_ATTEMPT_SELECTED') {
                $identity = [regex]::Match($tail, '^attempt=(?<attempt>\d+) prefab=(?<prefab>[a-zA-Z0-9_]+) placedId=(?<placedId>\d+) biome=(?<biome>\d+) origin=(?<origin>[-\d.,]+) size=(?<size>[-\d.,]+) rotation=(?<rotation>\d+)$')
                if ($identity.Success) {
                    $details = [pscustomobject][ordered]@{
                        attempt = $identity.Groups['attempt'].Value
                        prefab = $identity.Groups['prefab'].Value
                        placedId = $identity.Groups['placedId'].Value
                        biome = $identity.Groups['biome'].Value
                        origin = $identity.Groups['origin'].Value
                        size = $identity.Groups['size'].Value
                        rotation = $identity.Groups['rotation'].Value
                    }
                }
            }
            elseif ($reason -ceq 'POI_LANDING_COMPLETED') {
                $identity = [regex]::Match($tail, '^attempt=(?<attempt>\d+) prefab=(?<prefab>[a-zA-Z0-9_]+) placedId=(?<placedId>\d+) biome=(?<biome>\d+) position=(?<position>[-\d.,]+)$')
                if ($identity.Success) {
                    $details = [pscustomobject][ordered]@{
                        attempt = $identity.Groups['attempt'].Value
                        prefab = $identity.Groups['prefab'].Value
                        placedId = $identity.Groups['placedId'].Value
                        biome = $identity.Groups['biome'].Value
                        position = $identity.Groups['position'].Value
                    }
                }
            }
            elseif ($reason -ceq 'TRADER_ROUTE_SELECTED') {
                $identity = [regex]::Match($tail, '^placedId=(?<placedId>\d+) biome=(?<biome>\d+) crossBiome=(?<crossBiome>[01]) origin=(?<origin>[-\d.,]+) size=(?<size>[-\d.,]+)$')
                if ($identity.Success) {
                    $details = [pscustomobject][ordered]@{
                        placedId = $identity.Groups['placedId'].Value
                        biome = $identity.Groups['biome'].Value
                        crossBiome = $identity.Groups['crossBiome'].Value
                        origin = $identity.Groups['origin'].Value
                        size = $identity.Groups['size'].Value
                    }
                }
            }
            [void]$events.Add([pscustomobject][ordered]@{
                sequence = $sequence
                version = $match.Groups['version'].Value
                buildId = $match.Groups['build'].Value
                event = $reason
                details = $details
            })
        }
    }
    return $events.ToArray()
}

function Test-HrsQaPlacedObservation {
    param(
        [object[]] $Events,
        [object] $Observation,
        [object] $Scope,
        [object] $Case
    )

    $issues = New-Object System.Collections.Generic.List[string]
    if ($Case.PSObject.Properties.Name -contains 'expectedSelection') {
        $draws=@($Events | Where-Object { $_.event -ceq 'BIOME_SELECTED' -and $null -ne $_.details })
        if ($draws.Count -ne 1) { [void]$issues.Add('BIOME_SELECTION_EVIDENCE_MISSING') }
        else {
            $draw=$draws[0].details
            if ($draw.selection -cne $Case.expectedSelection) { [void]$issues.Add('BIOME_SELECTION_METHOD_MISMATCH') }
            if ($Case.PSObject.Properties.Name -contains 'expectedChosenBiome' -and
                ($draw.chosenBiome -cne $Case.expectedChosenBiome -or $draw.selectedBiome -cne $Case.expectedChosenBiome)) {
                [void]$issues.Add('BIOME_SELECTION_CHOSEN_MISMATCH')
            }
            if ($null -eq $Observation -or $draw.selectedBiome -cne $Observation.startingBiome) { [void]$issues.Add('BIOME_SELECTION_ARRIVAL_MISMATCH') }
            if (@($draw.eligible -split ',') -cnotcontains $draw.selectedBiome) { [void]$issues.Add('BIOME_SELECTION_INELIGIBLE') }
            $slot = @('3','9','5','1','8').IndexOf([string]$draw.selectedBiome)
            if ($draw.selection -ceq 'Weighted' -and ($slot -lt 0 -or $draw.weights[$slot] -le 0 -or
                @($draw.weights | Where-Object { $_ -lt 0 -or $_ -gt 100 }).Count -gt 0)) {
                [void]$issues.Add('BIOME_SELECTION_WEIGHT_INVALID')
            }
            if ($Case.PSObject.Properties.Name -contains 'expectedWeightFixture') {
                $ids=@('3','9','5','1','8')
                $eligibleIds=@($draw.eligible -split ',')
                $positive=@(0..4 | Where-Object { $draw.weights[$_] -gt 0 })
                $eligiblePositive=@($positive | Where-Object { $eligibleIds -ccontains $ids[$_] })
                $eligibleZero=@(0..4 | Where-Object { $draw.weights[$_] -eq 0 -and $eligibleIds -ccontains $ids[$_] })
                $absentPositive=@($positive | Where-Object { $eligibleIds -cnotcontains $ids[$_] })
                $fixtureValid=switch([string]$Case.expectedWeightFixture) {
                    'Mixed' { $positive.Count -eq 5 -and @($draw.weights | Sort-Object -Unique).Count -gt 1 }
                    'ZeroExclusion' { $eligibleZero.Count -gt 0 -and $eligiblePositive.Count -ge 2 }
                    'SinglePositive' { $positive.Count -eq 1 -and $eligiblePositive.Count -eq 1 }
                    'AbsentRenormalized' { $absentPositive.Count -gt 0 -and $eligiblePositive.Count -gt 0 }
                    default { $false }
                }
                if ($draw.selection -cne 'Weighted' -or -not $fixtureValid) {
                    [void]$issues.Add('BIOME_WEIGHT_FIXTURE_MISMATCH')
                }
            }
        }
    }
    if ($null -eq $Observation -or [string]$Observation.schema -cne 'hrs-qa-observation/v2') {
        [void]$issues.Add('PLACED_OBSERVATION_MISSING')
        return $issues.ToArray()
    }
    if ([string]::IsNullOrWhiteSpace([string]$Observation.gameName) -or
        [string]::IsNullOrWhiteSpace([string]$Observation.worldName)) {
        [void]$issues.Add('WORLD_IDENTITY_NOT_RECORDED')
    }
    $category = [string]$Observation.worldCategory
    if (@($Scope.worldCategories | ForEach-Object { [string]$_ }) -cnotcontains $category -or
        ($Case.PSObject.Properties.Name -contains 'expectedWorldCategory' -and
        [string]$Case.expectedWorldCategory -cne $category)) {
        [void]$issues.Add('WORLD_OUTSIDE_RELEASE_SCOPE')
    }
    if ($category -ceq 'Navezgane' -and [string]$Observation.worldName -cne 'Navezgane') {
        [void]$issues.Add('WORLD_IDENTITY_CONTRADICTION')
    }
    if ($category -ceq 'RandomGen' -and
        [int]$Observation.worldSize -lt [int]$Scope.minimumGeneratedWorldSize) {
        [void]$issues.Add('WORLD_SIZE_OUTSIDE_RELEASE_SCOPE')
    }
    if ([string]$Observation.landingResult -cne 'Safe') {
        [void]$issues.Add('SAFE_LANDING_NOT_OBSERVED')
    }

    $attempts = @($Events | Where-Object { [string]$_.event -ceq 'POI_ATTEMPT_SELECTED' })
    $landings = @($Events | Where-Object { [string]$_.event -ceq 'POI_LANDING_COMPLETED' })
    if ($attempts.Count -lt 1 -or $attempts.Count -gt [int]$Scope.maxPoiAttempts) {
        [void]$issues.Add('POI_ATTEMPT_COUNT_INVALID')
    }
    $placedIds = New-Object System.Collections.Generic.List[string]
    $selectedBiome = ''
    for ($index = 0; $index -lt $attempts.Count; $index++) {
        $detail = $attempts[$index].details
        if ($null -eq $detail -or [string]$detail.attempt -cne [string]($index + 1) -or
            @($Scope.approvedPrefabNames | ForEach-Object { [string]$_ }) -cnotcontains [string]$detail.prefab -or
            [string]$detail.placedId -notmatch '^\d+$' -or
            [string]$detail.rotation -notmatch '^[0-3]$') {
            [void]$issues.Add('POI_ATTEMPT_IDENTITY_INVALID')
            continue
        }
        $sizeParts = @(([string]$detail.size).Split(','))
        $validSize = $sizeParts.Count -eq 3
        if ($validSize) {
            foreach ($part in $sizeParts) {
                $dimension = 0.0
                if (-not [double]::TryParse($part,
                    [System.Globalization.NumberStyles]::Float,
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [ref]$dimension) -or $dimension -le 0) {
                    $validSize = $false
                }
            }
        }
        if (-not $validSize) {
            [void]$issues.Add('POI_GEOMETRY_INVALID')
        }
        if ($index -eq 0) { $selectedBiome = [string]$detail.biome }
        elseif ([string]$detail.biome -cne $selectedBiome) {
            [void]$issues.Add('POI_RETRY_BIOME_CHANGED')
        }
        $placedIds.Add([string]$detail.placedId)
    }
    if (@($placedIds | Select-Object -Unique).Count -ne $placedIds.Count) {
        [void]$issues.Add('POI_RETRY_REUSED_INSTANCE')
    }
    if (@($Events | Where-Object { [string]$_.event -ceq 'POI_RETRY' }).Count -ne
        [Math]::Max(0, $attempts.Count - 1)) {
        [void]$issues.Add('POI_RETRY_TRACE_MISMATCH')
    }
    if ($landings.Count -ne 1 -or $attempts.Count -eq 0 -or
        $null -eq $landings[0].details -or $null -eq $attempts[-1].details) {
        [void]$issues.Add('POI_LANDING_IDENTITY_MISSING')
    }
    else {
        $finalAttempt = $attempts[-1].details
        $landing = $landings[0].details
        if ([string]$landing.attempt -cne [string]$finalAttempt.attempt -or
            [string]$landing.prefab -cne [string]$finalAttempt.prefab -or
            [string]$landing.placedId -cne [string]$finalAttempt.placedId -or
            [string]$landing.biome -cne [string]$finalAttempt.biome -or
            [string]$Observation.selectedPrefabName -cne [string]$landing.prefab -or
            [string]$Observation.placedInstanceId -cne [string]$landing.placedId -or
            [string]$Observation.placedRotation -cne [string]$finalAttempt.rotation -or
            [string]$Observation.startingBiome -cne [string]$landing.biome -or
            [int]$Observation.retryAttemptCount -ne $attempts.Count) {
            [void]$issues.Add('POI_LANDING_IDENTITY_MISMATCH')
        }
        $positionParts = @(([string]$landing.position).Split(','))
        if ($null -eq $Observation.finalPosition -or $positionParts.Count -ne 3) {
            [void]$issues.Add('POI_LANDING_POSITION_MISSING')
        }
        else {
            $observedCoordinates = @([double]$Observation.finalPosition.x,
                [double]$Observation.finalPosition.y, [double]$Observation.finalPosition.z)
            for ($axis = 0; $axis -lt 3; $axis++) {
                $loggedCoordinate = 0.0
                if (-not [double]::TryParse($positionParts[$axis],
                    [System.Globalization.NumberStyles]::Float,
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [ref]$loggedCoordinate) -or
                    [Math]::Abs($loggedCoordinate - $observedCoordinates[$axis]) -gt 1.0) {
                    [void]$issues.Add('POI_LANDING_POSITION_MISMATCH')
                    break
                }
            }
        }
    }
    if ($Case.PSObject.Properties.Name -contains 'requiresPlacedTrader' -and
        $Case.requiresPlacedTrader -eq $true) {
        $traders = @($Events | Where-Object { [string]$_.event -ceq 'TRADER_ROUTE_SELECTED' })
        if ($traders.Count -ne 1 -or $null -eq $traders[0].details) {
            [void]$issues.Add('PLACED_TRADER_IDENTITY_MISSING')
        }
        else {
            $trader = $traders[0].details
            if ([string]$Observation.selectedTraderPlacedId -cne [string]$trader.placedId -or
                [string]$Observation.observedTraderBiome -cne [string]$trader.biome -or
                ([string]$trader.crossBiome -ceq '0' -and [string]$trader.biome -cne $selectedBiome) -or
                ([string]$trader.crossBiome -ceq '1' -and [string]$trader.biome -ceq $selectedBiome)) {
                [void]$issues.Add('PLACED_TRADER_IDENTITY_MISMATCH')
            }
        }
    }
    return $issues.ToArray()
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

. (Join-Path $PSScriptRoot 'HrsIdentity.ps1')
Export-ModuleMember -Function @(
    'Resolve-HrsContainedFile','Get-HrsStreamHash','Get-HrsRegistryRecord',
    'Get-HrsCustomerFiles','Get-HrsCustomerFolder','Read-HrsVerifiedZip','Assert-HrsTree',
    'Get-HrsPublicPackageIdentity','New-HrsPublicArchiveReceipt',
    'Assert-HrsFrozenRun','Assert-HrsEvidence','Assert-HrsWorkspace',
    'Get-HrsQaSha256', 'Write-HrsQaJson', 'Read-HrsQaJson',
    'Get-HrsQaLanePaths', 'Test-HrsQaSpawnScope', 'Test-HrsQaPlacedWorldScope', 'Test-HrsQaRelease', 'Get-HrsQaPackageInventory',
    'Get-HrsQaInstalledInventory', 'Get-HrsQaEnvironment', 'Get-HrsQaLatestLog',
    'Get-HrsQaRuntimeEvents', 'Test-HrsQaPlacedObservation', 'Get-HrsQaHistoryEvents', 'Get-HrsQaResultSummary', 'Test-HrsCandidateArchive',
    'New-HrsQaEvidenceManifest'
)
