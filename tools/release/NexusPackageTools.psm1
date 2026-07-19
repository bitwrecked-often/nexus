Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Throw-NexusPackageError {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Message
    )

    throw "BW-PKG-$Id`: $Message"
}

function Invoke-NexusGit {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [switch]$AllowFailure
    )

    $output = @(& git -C $RepositoryRoot @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $safeMessage = (@($output | ForEach-Object { "$_" }) -join " ").Trim()
        Throw-NexusPackageError -Id "GIT" -Message "Git command failed (exit $exitCode). $safeMessage"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output | ForEach-Object { "$_" })
    }
}

function Get-NexusRepositoryRoot {
    param(
        [Parameter(Mandatory)]
        [string]$StartPath
    )

    $resolved = [IO.Path]::GetFullPath($StartPath)
    if (Test-Path -LiteralPath $resolved -PathType Leaf) {
        $resolved = Split-Path -Parent $resolved
    }

    $result = Invoke-NexusGit -RepositoryRoot $resolved -Arguments @("rev-parse", "--show-toplevel")
    if ($result.Output.Count -ne 1) {
        Throw-NexusPackageError -Id "ROOT" -Message "Could not identify one repository root."
    }

    return [IO.Path]::GetFullPath($result.Output[0])
}

function Assert-NexusRelativePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Field
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Throw-NexusPackageError -Id "PATH" -Message "$Field must not be empty."
    }
    if ($Path -ne $Path.Normalize([Text.NormalizationForm]::FormC)) {
        Throw-NexusPackageError -Id "PATH" -Message "$Field must use Unicode NFC normalization."
    }
    if ($Path.Contains("\")) {
        Throw-NexusPackageError -Id "PATH" -Message "$Field must use forward slashes."
    }
    if ([IO.Path]::IsPathRooted($Path) -or $Path.StartsWith("/", [StringComparison]::Ordinal)) {
        Throw-NexusPackageError -Id "PATH" -Message "$Field must be repository-relative."
    }
    if ($Path.Contains(":")) {
        Throw-NexusPackageError -Id "PATH" -Message "$Field must not contain a drive, URI, or alternate data stream."
    }
    if ($Path.IndexOfAny([char[]](0..31)) -ge 0 -or $Path.Contains([char]127)) {
        Throw-NexusPackageError -Id "PATH" -Message "$Field contains a control character."
    }
    if ($Path.IndexOfAny([char[]]'<>"|?*') -ge 0) {
        Throw-NexusPackageError -Id "PATH" -Message "$Field contains a character that is unsafe in a Windows archive path."
    }

    $reserved = "^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$"
    foreach ($segment in $Path.Split("/")) {
        if ([string]::IsNullOrEmpty($segment) -or $segment -eq "." -or $segment -eq "..") {
            Throw-NexusPackageError -Id "PATH" -Message "$Field contains an unsafe path segment."
        }
        if ($segment.EndsWith(" ", [StringComparison]::Ordinal) -or $segment.EndsWith(".", [StringComparison]::Ordinal)) {
            Throw-NexusPackageError -Id "PATH" -Message "$Field contains a segment ending in a dot or space."
        }
        if ($segment -match $reserved) {
            Throw-NexusPackageError -Id "PATH" -Message "$Field contains a reserved Windows device name."
        }
    }

    return $Path
}

function Resolve-NexusContainedPath {
    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string]$RelativePath,

        [switch]$RequireFile
    )

    [void](Assert-NexusRelativePath -Path $RelativePath -Field "path")
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    if (Test-Path -LiteralPath $rootFull) {
        $rootItem = Get-Item -LiteralPath $rootFull -Force
        if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Throw-NexusPackageError -Id "REPARSE" -Message "A declared containment root is a reparse point."
        }
    }
    $nativeRelative = $RelativePath.Replace("/", [IO.Path]::DirectorySeparatorChar)
    $candidate = [IO.Path]::GetFullPath((Join-Path $rootFull $nativeRelative))
    $boundary = $rootFull + [IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($boundary, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-NexusPackageError -Id "CONTAINMENT" -Message "A resolved path escaped its declared root."
    }

    $current = $rootFull
    foreach ($segment in $RelativePath.Split("/")) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) {
            break
        }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Throw-NexusPackageError -Id "REPARSE" -Message "A declared path contains a reparse point: $RelativePath"
        }
    }

    if ($RequireFile) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            Throw-NexusPackageError -Id "MISSING" -Message "A required tracked source file is missing: $RelativePath"
        }
    }

    return $candidate
}

function Assert-NoDuplicateJsonProperties {
    param(
        [Parameter(Mandatory)]
        [System.Text.Json.JsonElement]$Element,

        [string]$JsonPath = "$"
    )

    if ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Object) {
        $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($property in $Element.EnumerateObject()) {
            if (-not $names.Add($property.Name)) {
                Throw-NexusPackageError -Id "JSON-DUPLICATE" -Message "Duplicate or case-colliding JSON property at $JsonPath.$($property.Name)."
            }
            Assert-NoDuplicateJsonProperties -Element $property.Value -JsonPath "$JsonPath.$($property.Name)"
        }
    }
    elseif ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Array) {
        $index = 0
        foreach ($item in $Element.EnumerateArray()) {
            Assert-NoDuplicateJsonProperties -Element $item -JsonPath "$JsonPath[$index]"
            $index++
        }
    }
}

function Read-NexusManifest {
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath
    )

    if ($PSVersionTable.PSVersion -lt [version]"7.4") {
        Throw-NexusPackageError -Id "POWERSHELL" -Message "Maintainer release tooling requires PowerShell 7.4 or later. The customer GUI remains Windows PowerShell compatible."
    }

    $manifestFull = [IO.Path]::GetFullPath($ManifestPath)
    if (-not (Test-Path -LiteralPath $manifestFull -PathType Leaf)) {
        Throw-NexusPackageError -Id "MANIFEST" -Message "Manifest not found."
    }

    $repositoryRoot = Get-NexusRepositoryRoot -StartPath $manifestFull
    $json = [IO.File]::ReadAllText($manifestFull, [Text.UTF8Encoding]::new($false, $true))

    $document = [System.Text.Json.JsonDocument]::Parse($json)
    $archiveTimestampUtc = $null
    try {
        Assert-NoDuplicateJsonProperties -Element $document.RootElement
        $archiveTimestampUtc = $document.RootElement.GetProperty("distribution").GetProperty("archiveTimestampUtc").GetString()
    }
    finally {
        $document.Dispose()
    }

    $data = $json | ConvertFrom-Json -Depth 100
    $data.distribution.archiveTimestampUtc = $archiveTimestampUtc
    $declaredSchema = [string]$data.'$schema'
    $schemaFull = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $manifestFull) $declaredSchema))
    $expectedSchema = [IO.Path]::GetFullPath((Join-Path $repositoryRoot "governance/schemas/solution-release-manifest.schema.json"))
    if (-not $schemaFull.Equals($expectedSchema, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-NexusPackageError -Id "SCHEMA" -Message "Manifest must use the repository's reviewed release-manifest schema."
    }
    if (-not (Test-Path -LiteralPath $schemaFull -PathType Leaf)) {
        Throw-NexusPackageError -Id "SCHEMA" -Message "Declared manifest schema is missing."
    }

    $schemaJson = [IO.File]::ReadAllText($schemaFull, [Text.UTF8Encoding]::new($false, $true))
    $schemaDocument = [System.Text.Json.JsonDocument]::Parse($schemaJson)
    try {
        Assert-NoDuplicateJsonProperties -Element $schemaDocument.RootElement
    }
    finally {
        $schemaDocument.Dispose()
    }
    if (-not (Test-Json -Json $json -SchemaFile $schemaFull)) {
        Throw-NexusPackageError -Id "SCHEMA" -Message "Manifest failed JSON Schema validation."
    }

    $solutionRoot = Resolve-NexusContainedPath -Root $repositoryRoot -RelativePath ([string]$data.solution.sourceRoot)
    $manifestDirectory = [IO.Path]::GetFullPath((Split-Path -Parent $manifestFull))
    if (-not $solutionRoot.Equals($manifestDirectory, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-NexusPackageError -Id "MANIFEST-LOCATION" -Message "Manifest must be stored at its declared solution root."
    }

    return [pscustomobject]@{
        Data = $data
        Json = $json
        ManifestPath = $manifestFull
        RepositoryRoot = $repositoryRoot
        SolutionRoot = $solutionRoot
        SchemaPath = $schemaFull
    }
}

function Get-NexusTopLevelEntries {
    param(
        [Parameter(Mandatory)]
        [object[]]$Mappings
    )

    $entries = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($mapping in $Mappings) {
        [void]$entries.Add(([string]$mapping.stage).Split("/")[0])
    }
    return @(Sort-NexusOrdinalStrings -Values ([string[]]@($entries)))
}

function Assert-NexusExactStringList {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Actual,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Expected,

        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $actualStrings = @(Sort-NexusOrdinalStrings -Values ([string[]]@($Actual | ForEach-Object { [string]$_ })))
    $expectedStrings = @(Sort-NexusOrdinalStrings -Values ([string[]]@($Expected)))
    if ($actualStrings.Count -ne $expectedStrings.Count -or ($actualStrings -join "`n") -cne ($expectedStrings -join "`n")) {
        Throw-NexusPackageError -Id $Id -Message $Message
    }
}

function Get-NexusExpectedDirectories {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Files
    )

    $directories = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($file in $Files) {
        [void](Assert-NexusRelativePath -Path $file -Field "inventory file")
        $segments = $file.Split("/")
        for ($length = 1; $length -lt $segments.Count; $length++) {
            [void]$directories.Add(($segments[0..($length - 1)] -join "/"))
        }
    }
    return @(Sort-NexusOrdinalStrings -Values ([string[]]@($directories)))
}

function Sort-NexusOrdinalByProperty {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Items,

        [Parameter(Mandatory)]
        [string]$Property
    )

    $ordered = [Collections.Generic.SortedDictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($item in $Items) {
        $key = [string]$item.$Property
        if ($ordered.ContainsKey($key)) {
            Throw-NexusPackageError -Id "ORDER" -Message "Ordinal ordering received a duplicate key: $key"
        }
        $ordered.Add($key, $item)
    }
    return @($ordered.Values)
}

function Sort-NexusOrdinalStrings {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Values
    )

    $copy = [string[]]@($Values)
    [Array]::Sort($copy, [StringComparer]::Ordinal)
    return @($copy)
}

function Get-NexusApprovedP2Contract {
    $support = "Support_Files_Do_Not_Edit"
    $mod = "$support/BitWrecked_7DTD_WastelandAnimalPopulationTuning"
    $sourceRoot = "solutions/7dtd_wasteland_animal_population_tuning_files"

    return [pscustomobject][ordered]@{
        Solution = [ordered]@{
            id = "7dtd_wasteland_animal_population_tuning"
            displayName = "7DTD 3.0 Wasteland Animal Population Tuning"
            author = "Bit Wrecked"
            officialRepository = "https://github.com/bitwrecked-often/nexus"
            sourceRoot = $sourceRoot
            runtimeModId = "BitWrecked_7DTD_WastelandAnimalPopulationTuning"
            installedFolder = "BitWrecked_7DTD_WastelandAnimalPopulationTuning"
        }
        Release = [ordered]@{
            intendedVersion = "4.1.0"
            workspaceVersion = "4.1.0-dev"
            channel = "development"
            lifecycle = "development"
            publicationState = "unreleased"
            branch = "develop/4.1.0"
        }
        WorkingParent = [ordered]@{
            version = "4.0.1"
            tag = "v4.0.1"
            commit = "c90f5f7f27d84343b95971a54486b88aa1022c00"
            state = "immutable-historical"
        }
        Baseline = [ordered]@{
            commit = "b3c3551c0c5bfc8d24c68d3036da4c8045a90b54"
            tree = "010454d19b10f46c71d9150335905766b946176e"
            fileCount = 32
            acceptanceBasis = "owner-qa-attestation"
            record = "evidence/baselines/7dtd_wasteland_animal_population_tuning/4.1.0/BASELINE_RECORD.md"
            checksums = "evidence/baselines/7dtd_wasteland_animal_population_tuning/4.1.0/SOURCE_SHA256SUMS.txt"
        }
        TechnicalUnchanged = @(
            "7DTD_WastelandAnimalTuning.bat",
            "$mod/Config/entitygroups.xml",
            "$mod/Config/spawning.xml",
            "$support/LICENSE.txt"
        )
        TechnicalProjections = @(
            "powershell-package-version|$support/7DTD_WastelandAnimalPopulationTuning_Tool.ps1|4.0.1|4.1.0|<null>|<null>",
            "mod-info-version-website|$mod/ModInfo.xml|4.0.1|4.1.0||https://github.com/bitwrecked-often/nexus"
        )
        PrimaryMappings = @(
            "README_FIRST.txt|README_FIRST.txt|text",
            "7DTD_WastelandAnimalTuning.bat|7DTD_WastelandAnimalTuning.bat|batch",
            "$support/7DTD_WastelandAnimalPopulationTuning_Tool.ps1|$support/7DTD_WastelandAnimalPopulationTuning_Tool.ps1|powershell",
            "$mod/ModInfo.xml|$mod/ModInfo.xml|modinfo",
            "$mod/Config/entitygroups.xml|$mod/Config/entitygroups.xml|config-xml",
            "$mod/Config/spawning.xml|$mod/Config/spawning.xml|config-xml",
            "$support/LICENSE.txt|$support/LICENSE.txt|license",
            "$support/CHANGELOG.md|$support/CHANGELOG.md|text"
        )
        VersionSurfaces = @(
            "plain-exact|repository|VERSION|4.1.0-dev|4.1.0",
            "mod-info-xml|solution|$mod/ModInfo.xml|4.1.0|4.1.0",
            "powershell-package-version|solution|$support/7DTD_WastelandAnimalPopulationTuning_Tool.ps1|4.1.0|4.1.0",
            "readme-version-line|solution|README_FIRST.txt|Version 4.1.0|Version 4.1.0",
            "changelog-heading|solution|$support/CHANGELOG.md|## Version 4.1.0 - Unreleased|<null>"
        )
        ProtectedArtifacts = @(
            "$sourceRoot/Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_FullPackage.zip",
            "$sourceRoot/Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_Nexus_NoScripts.zip",
            "$sourceRoot/Upload_To_Nexus/7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip"
        )
        PrimaryCapabilities = @(
            "graphical-animal-selection-and-tuning",
            "modlet-install-reinstall-and-remove",
            "installed-versus-selected-value-scan",
            "optional-server-animal-cap-backup-change-and-restore"
        )
        PrimaryExclusions = @(
            "direct-game-data-config-edit",
            "game-executable-patching",
            "save-or-world-edit",
            "registry-persistence",
            "service-or-scheduled-task",
            "hidden-downloader-or-updater",
            "avatar-and-publishing-art",
            "maintainer-packaging-tools",
            "advanced-command-line-tools"
        )
        PrimaryGates = @(
            "identity-and-version-projections",
            "readme-license-source-and-safety-contract",
            "exact-eight-file-candidate",
            "staged-byte-smoke-and-archive-validation",
            "checksum-inventory-and-provenance",
            "owner-release-acceptance"
        )
    }
}

function Resolve-NexusReleaseProfile {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [ValidateSet("Auto", "Development", "Candidate")]
        [string]$Profile = "Auto"
    )

    if ($Profile -cne "Auto") {
        return $Profile
    }

    switch ([string]$Context.Data.release.channel) {
        "development" { return "Development" }
        "release-candidate" { return "Candidate" }
        default {
            Throw-NexusPackageError -Id "RELEASE-STATE" -Message "The manifest does not map to a supported validation profile."
        }
    }
}

function Get-NexusExpectedReleaseState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Development", "Candidate")]
        [string]$Profile,

        [Parameter(Mandatory)]
        [string]$Version
    )

    if ($Profile -ceq "Development") {
        return [ordered]@{
            intendedVersion = $Version
            workspaceVersion = "$Version-dev"
            channel = "development"
            lifecycle = "development"
            publicationState = "unreleased"
            branch = "develop/4.1.0"
        }
    }

    return [ordered]@{
        intendedVersion = $Version
        workspaceVersion = $Version
        channel = "release-candidate"
        lifecycle = "release-candidate"
        publicationState = "candidate"
        branch = "develop/4.1.0"
    }
}

function Assert-NexusManifestContract {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [ValidateSet("Auto", "Development", "Candidate")]
        [string]$Profile = "Auto"
    )

    $manifest = $Context.Data
    $approved = Get-NexusApprovedP2Contract
    $resolvedProfile = Resolve-NexusReleaseProfile -Context $Context -Profile $Profile

    foreach ($property in $approved.Solution.Keys) {
        if ([string]$manifest.solution.$property -cne [string]$approved.Solution[$property]) {
            Throw-NexusPackageError -Id "IDENTITY" -Message "Development solution identity differs from the owner-approved P2 contract: $property"
        }
    }
    $version = [string]$manifest.release.intendedVersion
    $expectedRelease = Get-NexusExpectedReleaseState -Profile $resolvedProfile -Version $version
    foreach ($property in $expectedRelease.Keys) {
        if ([string]$manifest.release.$property -cne [string]$expectedRelease[$property]) {
            Throw-NexusPackageError -Id "RELEASE-STATE" -Message "$resolvedProfile release state differs from the approved contract: $property"
        }
    }
    foreach ($property in $approved.WorkingParent.Keys) {
        if ([string]$manifest.lineage.workingParent.$property -cne [string]$approved.WorkingParent[$property]) {
            Throw-NexusPackageError -Id "LINEAGE" -Message "Working-parent lineage differs from the approved contract: $property"
        }
    }
    foreach ($property in $approved.Baseline.Keys) {
        if ([string]$manifest.lineage.sourceBaseline.$property -cne [string]$approved.Baseline[$property]) {
            Throw-NexusPackageError -Id "LINEAGE" -Message "Source-baseline lineage differs from the approved contract: $property"
        }
    }

    if ([string]$manifest.solution.runtimeModId -cne [string]$manifest.solution.installedFolder) {
        Throw-NexusPackageError -Id "MOD-ID" -Message "Runtime mod ID and installed folder must remain identical for this release."
    }
    if ([string]$manifest.technicalFreeze.baselineCommit -cne [string]$manifest.lineage.sourceBaseline.commit) {
        Throw-NexusPackageError -Id "FREEZE" -Message "Technical-freeze and lineage baseline commits must agree."
    }
    if ([bool]$manifest.release.approvedForPublication -or $null -ne $manifest.release.releaseSourceCommit -or $null -ne $manifest.release.releaseTag -or $null -ne $manifest.release.approvalRecord) {
        Throw-NexusPackageError -Id "AUTHORITY" -Message "$resolvedProfile manifest must not claim a release commit, tag, or publication approval."
    }
    $parentCommit = (Invoke-NexusGit -RepositoryRoot $Context.RepositoryRoot -Arguments @("rev-list", "-n", "1", [string]$manifest.lineage.workingParent.tag)).Output[0]
    if ($parentCommit -cne [string]$manifest.lineage.workingParent.commit) {
        Throw-NexusPackageError -Id "LINEAGE" -Message "Working-parent tag does not resolve to its declared commit."
    }
    [void](Get-NexusTrackedPath -RepositoryRoot $Context.RepositoryRoot -RepositoryRelativePath ([string]$manifest.lineage.sourceBaseline.record))
    [void](Get-NexusTrackedPath -RepositoryRoot $Context.RepositoryRoot -RepositoryRelativePath ([string]$manifest.lineage.sourceBaseline.checksums))

    Assert-NexusExactStringList -Actual @($manifest.technicalFreeze.unchangedPaths) -Expected $approved.TechnicalUnchanged -Id "FREEZE" -Message "Technical-freeze byte-identical paths differ from the approved P2 contract."
    $actualProjections = @($manifest.technicalFreeze.metadataProjections | ForEach-Object {
        $fromWebsite = if ($null -eq $_.fromWebsite) { "<null>" } else { [string]$_.fromWebsite }
        $toWebsite = if ($null -eq $_.toWebsite) { "<null>" } else { [string]$_.toWebsite }
        "$($_.type)|$($_.path)|$($_.fromVersion)|$($_.toVersion)|$fromWebsite|$toWebsite"
    })
    Assert-NexusExactStringList -Actual $actualProjections -Expected $approved.TechnicalProjections -Id "FREEZE" -Message "Metadata-only projection rules differ from the approved P2 contract."

    if ([string]$manifest.license.expression -cne "GPL-3.0-or-later") {
        Throw-NexusPackageError -Id "LICENSE" -Message "The declared license must remain GPL-3.0-or-later."
    }
    if ([string]$manifest.license.fullTextSource -cne "Support_Files_Do_Not_Edit/LICENSE.txt" -or
        [string]$manifest.license.primaryStagePath -cne "Support_Files_Do_Not_Edit/LICENSE.txt" -or
        [string]$manifest.license.officialSourceRepository -cne [string]$manifest.solution.officialRepository -or
        [string]$manifest.license.baselineSourceUrl -cne "https://github.com/bitwrecked-often/nexus/tree/b3c3551c0c5bfc8d24c68d3036da4c8045a90b54/solutions/7dtd_wasteland_animal_population_tuning_files" -or
        $null -ne $manifest.license.releaseSourceUrl) {
        Throw-NexusPackageError -Id "LICENSE" -Message "Development license/source routing differs from the approved GPL contract."
    }
    Assert-NexusExactStringList -Actual @($manifest.license.customerDocuments) -Expected @("README_FIRST.txt", "Support_Files_Do_Not_Edit/CHANGELOG.md") -Id "LICENSE" -Message "GPL-covered customer-document set differs from the approved contract."

    if ($null -eq $manifest.compatibility.game.exactTestedBuild -and [string]$manifest.compatibility.game.evidence -cne "unverified") {
        Throw-NexusPackageError -Id "COMPATIBILITY" -Message "Game-build evidence must remain unverified while the exact build is unknown."
    }
    if ([string]$manifest.compatibility.game.name -cne "7 Days to Die" -or
        [string]$manifest.compatibility.game.targetLabel -cne "7DTD 3.0" -or
        [string]$manifest.compatibility.game.retainedDescription -cne "3.0-era" -or
        $null -ne $manifest.compatibility.game.exactTestedBuild) {
        Throw-NexusPackageError -Id "COMPATIBILITY" -Message "Game target differs from the bounded P2 evidence record."
    }
    $expectedEnvironments = @{
        "windows-11-steam-client" = "observed"
        "windows-dedicated-server" = "unverified"
        "non-steam-windows" = "unverified"
        "linux" = "unverified"
        "console" = "unsupported"
        "vortex" = "unverified"
    }
    if (@($manifest.compatibility.environments).Count -ne $expectedEnvironments.Count) {
        Throw-NexusPackageError -Id "COMPATIBILITY" -Message "Compatibility environment set differs from the bounded P2 record."
    }
    foreach ($environment in @($manifest.compatibility.environments)) {
        $id = [string]$environment.id
        if (-not $expectedEnvironments.ContainsKey($id) -or [string]$environment.evidence -cne [string]$expectedEnvironments[$id]) {
            Throw-NexusPackageError -Id "COMPATIBILITY" -Message "Compatibility evidence differs from the bounded P2 record: $id"
        }
        if ([string]$environment.evidence -in @("observed", "verified", "unsupported")) {
            if ([string]::IsNullOrWhiteSpace([string]$environment.basis)) {
                Throw-NexusPackageError -Id "COMPATIBILITY" -Message "Observed, verified, or unsupported compatibility requires a basis: $id"
            }
        }
        elseif ($null -ne $environment.basis) {
            Throw-NexusPackageError -Id "COMPATIBILITY" -Message "Unverified compatibility must not carry an invented basis: $id"
        }
    }

    $expectedRuntime = [ordered]@{
        basis = "frozen-source-inspection"
        networkUsed = $false
        telemetryUsed = $false
        elevationRequested = $false
        userWritePermissionRequired = $true
        bundledCompiledCode = $false
        bundledExecutableBinary = $false
        scriptsIncluded = $true
        processLocalExecutionPolicyBypass = $true
    }
    foreach ($property in $expectedRuntime.Keys) {
        if ([string]$manifest.runtimeFacts.$property -cne [string]$expectedRuntime[$property]) {
            Throw-NexusPackageError -Id "RUNTIME-FACT" -Message "Runtime fact differs from the reviewed frozen-source contract: $property"
        }
    }
    $actualProcesses = @($manifest.runtimeFacts.externalProcesses | ForEach-Object { "$($_.name)|$($_.automatic)" })
    Assert-NexusExactStringList -Actual $actualProcesses -Expected @("powershell.exe|True", "explorer.exe|False") -Id "RUNTIME-FACT" -Message "External-process facts differ from the reviewed frozen-source contract."

    $actualSurfaceBases = @($manifest.versionSurfaces | ForEach-Object {
        "$($_.type)|$($_.scope)|$($_.path)|$($_.developmentValue)"
    })
    $expectedSurfaceBases = @($approved.VersionSurfaces | ForEach-Object {
        $parts = $_.Split("|")
        ($parts[0..3] -join "|")
    })
    Assert-NexusExactStringList -Actual $actualSurfaceBases -Expected $expectedSurfaceBases -Id "VERSION-SURFACE" -Message "Version surfaces differ from the exact approved projection set."

    $candidateExpectations = @{
        "plain-exact|repository|VERSION" = $version
        "mod-info-xml|solution|Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml" = $version
        "powershell-package-version|solution|Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1" = $version
        "readme-version-line|solution|README_FIRST.txt" = "Version $version"
    }
    foreach ($surface in @($manifest.versionSurfaces)) {
        $key = "$($surface.type)|$($surface.scope)|$($surface.path)"
        if ($candidateExpectations.ContainsKey($key) -and [string]$surface.candidateValue -cne [string]$candidateExpectations[$key]) {
            Throw-NexusPackageError -Id "VERSION-SURFACE" -Message "Candidate projection differs from the approved value: $($surface.path)"
        }
        if ([string]$surface.type -ceq "changelog-heading" -and $resolvedProfile -ceq "Candidate") {
            if ([string]$surface.candidateValue -cne "## Version 4.1.0") {
                Throw-NexusPackageError -Id "VERSION-SURFACE" -Message "Candidate changelog heading must use the release-neutral approved value."
            }
        }
    }

    $expectedStages = @{
        candidateStage = "dist/$($manifest.solution.id)/$version/candidate"
        finalUploadStage = "dist/$($manifest.solution.id)/$version/final-upload"
        workingEvidenceStage = "dist/$($manifest.solution.id)/$version/evidence"
        durableEvidenceRoot = "evidence/releases/$($manifest.solution.id)/$version"
    }
    foreach ($property in $expectedStages.Keys) {
        if ([string]$manifest.distribution.$property -cne [string]$expectedStages[$property]) {
            Throw-NexusPackageError -Id "STAGE" -Message "$property does not match the derived solution/version path."
        }
    }
    $expectedArchivePolicy = [ordered]@{
        archiveFormat = "zip"
        archiveCompression = "store"
        archiveEntryOrder = "ordinal-stage-path"
        archiveTimestampUtc = "2000-01-01T00:00:00Z"
        archivePathSeparator = "forward-slash"
        reproducibilityBuildCount = 2
    }
    foreach ($property in $expectedArchivePolicy.Keys) {
        if ([string]$manifest.distribution.$property -cne [string]$expectedArchivePolicy[$property]) {
            Throw-NexusPackageError -Id "ARCHIVE-POLICY" -Message "$property differs from the deterministic archive contract."
        }
    }

    $editionIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $filenames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($edition in @($manifest.editions)) {
        if (-not $editionIds.Add([string]$edition.id)) {
            Throw-NexusPackageError -Id "EDITION" -Message "Edition IDs must be unique ignoring case."
        }
        if (-not $filenames.Add([string]$edition.plannedFilename)) {
            Throw-NexusPackageError -Id "FILENAME" -Message "Planned archive filenames must be unique ignoring case."
        }
        if (-not ([string]$edition.plannedFilename).Contains($version, [StringComparison]::Ordinal)) {
            Throw-NexusPackageError -Id "FILENAME" -Message "Every planned archive filename must contain the exact version."
        }
        if (-not ([string]$edition.plannedFilename).Contains([string]$edition.id, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-NexusPackageError -Id "FILENAME" -Message "Every planned archive filename must contain its edition ID."
        }
        if ([string]$edition.state -ceq "blocked") {
            if ([bool]$edition.publishable -or @($edition.blockers).Count -eq 0) {
                Throw-NexusPackageError -Id "BLOCKED" -Message "Blocked editions must be non-publishable and carry a blocker."
            }
        }
        if ($null -ne $edition.sha256) {
            Throw-NexusPackageError -Id "EDITION-HASH" -Message "Development editions must not claim an artifact hash."
        }
    }
    $expectedEditionIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    [void]$expectedEditionIds.UnionWith([string[]]@("windows-gui", "no-scripts", "vortex"))
    if (-not $editionIds.SetEquals($expectedEditionIds)) {
        Throw-NexusPackageError -Id "EDITION" -Message "P2 requires exactly windows-gui, no-scripts, and vortex edition records."
    }

    $primary = @($manifest.editions | Where-Object { [string]$_.role -ceq "primary" })
    if ($primary.Count -ne 1 -or [string]$primary[0].id -cne "windows-gui") {
        Throw-NexusPackageError -Id "PRIMARY" -Message "Exactly one windows-gui primary edition is required."
    }
    $expectedPrimaryState = if ($resolvedProfile -ceq "Candidate") { "candidate" } else { "development" }
    if ([bool]$primary[0].publishable -or [string]$primary[0].state -cne $expectedPrimaryState) {
        Throw-NexusPackageError -Id "PRIMARY" -Message "The primary edition must be non-publishable $expectedPrimaryState work for this profile."
    }
    if ([string]$primary[0].plannedFilename -cne "7DTD_WastelandAnimalPopulationTuning-4.1.0-windows-gui.zip") {
        Throw-NexusPackageError -Id "PRIMARY" -Message "Primary planned filename differs from the approved P2 contract."
    }
    Assert-NexusExactStringList -Actual @($primary[0].capabilities) -Expected $approved.PrimaryCapabilities -Id "PRIMARY" -Message "Primary capability claims differ from the reviewed frozen source."
    Assert-NexusExactStringList -Actual @($primary[0].requiredCapabilities) -Expected @() -Id "PRIMARY" -Message "The current primary must not carry unresolved required capabilities."
    Assert-NexusExactStringList -Actual @($primary[0].exclusions) -Expected $approved.PrimaryExclusions -Id "PRIMARY" -Message "Primary exclusions differ from the approved package boundary."
    Assert-NexusExactStringList -Actual @($primary[0].requiredGates) -Expected $approved.PrimaryGates -Id "PRIMARY" -Message "Primary release gates differ from the approved P2 contract."

    $mappings = @($primary[0].sourceToStage)
    if ($mappings.Count -ne 8) {
        Throw-NexusPackageError -Id "ALLOWLIST" -Message "The primary edition must contain exactly eight mapped files."
    }
    $sources = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $stages = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($mapping in $mappings) {
        $source = Assert-NexusRelativePath -Path ([string]$mapping.source) -Field "sourceToStage.source"
        $stage = Assert-NexusRelativePath -Path ([string]$mapping.stage) -Field "sourceToStage.stage"
        if (-not $sources.Add($source)) {
            Throw-NexusPackageError -Id "ALLOWLIST" -Message "Primary source paths must be unique ignoring case."
        }
        if (-not $stages.Add($stage)) {
            Throw-NexusPackageError -Id "ALLOWLIST" -Message "Primary stage paths must be unique ignoring case."
        }
    }
    $actualMappings = @($mappings | ForEach-Object { "$($_.source)|$($_.stage)|$($_.kind)" })
    Assert-NexusExactStringList -Actual $actualMappings -Expected $approved.PrimaryMappings -Id "ALLOWLIST" -Message "Primary mappings differ from the exact owner-approved eight-file source/stage/kind table."

    $declaredRoots = @(Sort-NexusOrdinalStrings -Values ([string[]]@($primary[0].archiveRootEntries)))
    $derivedRoots = @(Get-NexusTopLevelEntries -Mappings $mappings)
    if (($declaredRoots -join "`n") -cne ($derivedRoots -join "`n")) {
        Throw-NexusPackageError -Id "ROOT-SHAPE" -Message "Declared and derived primary archive roots differ."
    }
    $expectedRoots = @(Sort-NexusOrdinalStrings -Values @("7DTD_WastelandAnimalTuning.bat", "README_FIRST.txt", "Support_Files_Do_Not_Edit"))
    if (($declaredRoots -join "`n") -cne ($expectedRoots -join "`n")) {
        Throw-NexusPackageError -Id "ROOT-SHAPE" -Message "Primary archive must expose the approved three-item root."
    }

    $blockedExpectations = @{
        "no-scripts" = [pscustomobject]@{
            Filename = "7DTD_WastelandAnimalPopulationTuning-4.1.0-no-scripts.zip"
            RequiredCapabilities = @("static-intent-inspection", "manual-installation")
            RequiredGates = @("meaningful-static-outcome", "exact-no-scripts-allowlist-and-document-contract", "license-source-inventory-and-checksum", "exact-candidate-manual-install-verify-remove")
        }
        "vortex" = [pscustomobject]@{
            Filename = "7DTD_WastelandAnimalPopulationTuning-4.1.0-vortex.zip"
            RequiredCapabilities = @("vortex-import-install-enable-disable-and-remove", "game-recognition")
            RequiredGates = @("complete-license-and-source-route", "candidate-hash-vortex-version-and-game-build-record", "import-install-enable-recognize-disable-remove-audit")
        }
    }
    foreach ($id in @("no-scripts", "vortex")) {
        $edition = @($manifest.editions | Where-Object { [string]$_.id -ceq $id })[0]
        if ([string]$edition.role -cne "optional" -or [string]$edition.state -cne "blocked" -or [bool]$edition.publishable -or
            [string]$edition.plannedFilename -cne [string]$blockedExpectations[$id].Filename -or
            @($edition.sourceToStage).Count -ne 0 -or @($edition.archiveRootEntries).Count -ne 0 -or @($edition.capabilities).Count -ne 0) {
            Throw-NexusPackageError -Id "BLOCKED" -Message "$id must remain an empty, optional, blocked, non-publishable P2 edition record."
        }
        Assert-NexusExactStringList -Actual @($edition.requiredCapabilities) -Expected @($blockedExpectations[$id].RequiredCapabilities) -Id "BLOCKED" -Message "$id required capabilities differ from its bounded future gate."
        Assert-NexusExactStringList -Actual @($edition.requiredGates) -Expected @($blockedExpectations[$id].RequiredGates) -Id "BLOCKED" -Message "$id required gates differ from its bounded future gate."
    }

    $actualProtectedPaths = @($manifest.protectedArtifacts | ForEach-Object { [string]$_.path })
    Assert-NexusExactStringList -Actual $actualProtectedPaths -Expected $approved.ProtectedArtifacts -Id "HISTORICAL-REGISTRY" -Message "Protected-artifact registry differs from the exact three historical ZIP paths."
    $protectedNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($artifact in @($manifest.protectedArtifacts)) {
        $path = Assert-NexusRelativePath -Path ([string]$artifact.path) -Field "protectedArtifacts.path"
        $objectId = Get-NexusGitBlobObjectId -RepositoryRoot $Context.RepositoryRoot -Commit ([string]$manifest.lineage.sourceBaseline.commit) -RepositoryRelativePath $path
        $baselineHash = Get-NexusGitBlobSha256 -RepositoryRoot $Context.RepositoryRoot -ObjectId $objectId
        if ([string]$artifact.state -cne "immutable-historical" -or ([string]$artifact.sha256).ToUpperInvariant() -cne $baselineHash) {
            Throw-NexusPackageError -Id "HISTORICAL-REGISTRY" -Message "Historical ZIP state/hash differs from the anchored raw Git blob: $path"
        }
        [void]$protectedNames.Add([IO.Path]::GetFileName($path))
    }
    foreach ($edition in @($manifest.editions)) {
        if ($protectedNames.Contains([string]$edition.plannedFilename)) {
            Throw-NexusPackageError -Id "HISTORICAL-TARGET" -Message "A planned filename collides with immutable historical evidence."
        }
    }
}

function Get-NexusTrackedPath {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory)]
        [string]$RepositoryRelativePath
    )

    $result = Invoke-NexusGit -RepositoryRoot $RepositoryRoot -Arguments @("ls-files", "--", $RepositoryRelativePath)
    $matches = @($result.Output | Where-Object { $_ -ceq $RepositoryRelativePath })
    if ($matches.Count -ne 1 -or $result.Output.Count -ne 1) {
        Throw-NexusPackageError -Id "TRACKED-CASE" -Message "Source must be one exactly cased tracked file: $RepositoryRelativePath"
    }
    return $matches[0]
}

function Start-NexusGitBlobProcess {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory)]
        [string]$ObjectId
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = "git"
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    [void]$startInfo.ArgumentList.Add("-C")
    [void]$startInfo.ArgumentList.Add($RepositoryRoot)
    [void]$startInfo.ArgumentList.Add("cat-file")
    [void]$startInfo.ArgumentList.Add("blob")
    [void]$startInfo.ArgumentList.Add($ObjectId)

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    [void]$process.Start()
    return $process
}

function Get-NexusGitBlobObjectId {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory)]
        [string]$Commit,

        [Parameter(Mandatory)]
        [string]$RepositoryRelativePath
    )

    return (Invoke-NexusGit -RepositoryRoot $RepositoryRoot -Arguments @("rev-parse", "$Commit`:$RepositoryRelativePath")).Output[0]
}

function Get-NexusGitBlobSha256 {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory)]
        [string]$ObjectId
    )

    $process = $null
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $process = Start-NexusGitBlobProcess -RepositoryRoot $RepositoryRoot -ObjectId $ObjectId
        $hashBytes = $algorithm.ComputeHash($process.StandardOutput.BaseStream)
        $errorText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            Throw-NexusPackageError -Id "GIT-BLOB" -Message "Could not hash a tracked source blob. $errorText"
        }
        return ([Convert]::ToHexString($hashBytes))
    }
    finally {
        $algorithm.Dispose()
        if ($null -ne $process) {
            if (-not $process.HasExited) {
                $process.Kill($true)
                $process.WaitForExit()
            }
            $process.Dispose()
        }
    }
}

function Get-NexusGitBlobText {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory)]
        [string]$ObjectId
    )

    $process = $null
    $reader = $null
    try {
        $process = Start-NexusGitBlobProcess -RepositoryRoot $RepositoryRoot -ObjectId $ObjectId
        $reader = [IO.StreamReader]::new($process.StandardOutput.BaseStream, [Text.UTF8Encoding]::new($false, $true), $false)
        $text = $reader.ReadToEnd()
        $reader.Dispose()
        $reader = $null
        $errorText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            Throw-NexusPackageError -Id "GIT-BLOB" -Message "Could not read a tracked source blob. $errorText"
        }
        return $text
    }
    finally {
        if ($null -ne $reader) {
            $reader.Dispose()
        }
        if ($null -ne $process) {
            if (-not $process.HasExited) {
                $process.Kill($true)
                $process.WaitForExit()
            }
            $process.Dispose()
        }
    }
}

function Test-NexusBaselineFingerprint {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context
    )

    $baseline = $Context.Data.lineage.sourceBaseline
    $commit = [string]$baseline.commit
    $sourceRoot = [string]$Context.Data.solution.sourceRoot
    $actualTree = (Invoke-NexusGit -RepositoryRoot $Context.RepositoryRoot -Arguments @("rev-parse", "$commit`:$sourceRoot")).Output[0]
    if ($actualTree -cne [string]$baseline.tree) {
        Throw-NexusPackageError -Id "BASELINE-TREE" -Message "Anchored solution tree does not match the manifest."
    }

    $checksumPath = Resolve-NexusContainedPath -Root $Context.RepositoryRoot -RelativePath ([string]$baseline.checksums) -RequireFile
    $expected = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
    foreach ($line in [IO.File]::ReadAllLines($checksumPath, [Text.UTF8Encoding]::new($false, $true))) {
        if ($line -notmatch '^([A-Fa-f0-9]{64})  (.+)$') {
            Throw-NexusPackageError -Id "BASELINE-MANIFEST" -Message "Malformed baseline checksum line."
        }
        if (-not $expected.TryAdd($Matches[2], $Matches[1].ToUpperInvariant())) {
            Throw-NexusPackageError -Id "BASELINE-MANIFEST" -Message "Duplicate baseline checksum path."
        }
    }

    $treeEntries = @(Invoke-NexusGit -RepositoryRoot $Context.RepositoryRoot -Arguments @("ls-tree", "-r", "--format=%(objectname) %(path)", $commit, "--", $sourceRoot) | Select-Object -ExpandProperty Output)
    if ($treeEntries.Count -ne [int]$baseline.fileCount -or $expected.Count -ne [int]$baseline.fileCount) {
        Throw-NexusPackageError -Id "BASELINE-COUNT" -Message "Baseline tree and checksum file counts differ."
    }
    foreach ($entry in $treeEntries) {
        if ($entry -notmatch '^([A-Fa-f0-9]{40}) (.+)$') {
            Throw-NexusPackageError -Id "BASELINE-TREE" -Message "Could not parse a baseline tree entry."
        }
        $objectId = $Matches[1]
        $path = $Matches[2]
        if (-not $expected.ContainsKey($path)) {
            Throw-NexusPackageError -Id "BASELINE-MANIFEST" -Message "Baseline checksum file is missing a tree path."
        }
        $actual = Get-NexusGitBlobSha256 -RepositoryRoot $Context.RepositoryRoot -ObjectId $objectId
        if ($actual -cne $expected[$path]) {
            Throw-NexusPackageError -Id "BASELINE-HASH" -Message "Raw Git blob does not match the baseline checksum: $path"
        }
        [void]$expected.Remove($path)
    }
    if ($expected.Count -ne 0) {
        Throw-NexusPackageError -Id "BASELINE-MANIFEST" -Message "Baseline checksum file contains a path outside the anchored tree."
    }

    return [pscustomobject][ordered]@{
        commit = $commit
        tree = $actualTree
        fileCount = [int]$baseline.fileCount
        digestDomain = "raw-git-blob"
        status = "match"
    }
}

function Test-NexusTechnicalFreeze {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context
    )

    $policy = $Context.Data.technicalFreeze
    $commit = [string]$policy.baselineCommit
    $sourceRoot = [string]$Context.Data.solution.sourceRoot
    $results = @()

    foreach ($path in @(Sort-NexusOrdinalStrings -Values ([string[]]@($policy.unchangedPaths)))) {
        [void](Assert-NexusRelativePath -Path ([string]$path) -Field "technicalFreeze.unchangedPaths")
        $repositoryRelative = "$sourceRoot/$path"
        $objectId = Get-NexusGitBlobObjectId -RepositoryRoot $Context.RepositoryRoot -Commit $commit -RepositoryRelativePath $repositoryRelative
        $expected = Get-NexusGitBlobSha256 -RepositoryRoot $Context.RepositoryRoot -ObjectId $objectId
        $currentPath = Resolve-NexusContainedPath -Root $Context.SolutionRoot -RelativePath ([string]$path) -RequireFile
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $currentPath).Hash.ToUpperInvariant()
        if ($actual -cne $expected) {
            Throw-NexusPackageError -Id "TECHNICAL-FREEZE" -Message "Frozen technical source changed outside metadata authority: $path"
        }
        $results += [pscustomobject][ordered]@{
            path = [string]$path
            treatment = "byte-identical"
            status = "match"
        }
    }

    foreach ($projection in @(Sort-NexusOrdinalByProperty -Items @($policy.metadataProjections) -Property "path")) {
        $path = [string]$projection.path
        [void](Assert-NexusRelativePath -Path $path -Field "technicalFreeze.metadataProjections.path")
        $repositoryRelative = "$sourceRoot/$path"
        $objectId = Get-NexusGitBlobObjectId -RepositoryRoot $Context.RepositoryRoot -Commit $commit -RepositoryRelativePath $repositoryRelative
        $baselineText = Get-NexusGitBlobText -RepositoryRoot $Context.RepositoryRoot -ObjectId $objectId
        $expectedText = $baselineText
        switch ([string]$projection.type) {
            "powershell-package-version" {
                $from = '$script:PackageVersion = "' + [string]$projection.fromVersion + '"'
                $to = '$script:PackageVersion = "' + [string]$projection.toVersion + '"'
                if ($baselineText.IndexOf($from, [StringComparison]::Ordinal) -lt 0) {
                    Throw-NexusPackageError -Id "TECHNICAL-FREEZE" -Message "Baseline PowerShell version projection was not found."
                }
                $expectedText = $baselineText.Replace($from, $to)
            }
            "mod-info-version-website" {
                $fromVersion = '<Version value="' + [string]$projection.fromVersion + '"/>'
                $toVersion = '<Version value="' + [string]$projection.toVersion + '"/>'
                $fromWebsite = '<Website value="' + [string]$projection.fromWebsite + '"/>'
                $toWebsite = '<Website value="' + [string]$projection.toWebsite + '"/>'
                if ($baselineText.IndexOf($fromVersion, [StringComparison]::Ordinal) -lt 0 -or $baselineText.IndexOf($fromWebsite, [StringComparison]::Ordinal) -lt 0) {
                    Throw-NexusPackageError -Id "TECHNICAL-FREEZE" -Message "Baseline ModInfo projections were not found."
                }
                $expectedText = $baselineText.Replace($fromVersion, $toVersion).Replace($fromWebsite, $toWebsite)
            }
            default {
                Throw-NexusPackageError -Id "TECHNICAL-FREEZE" -Message "Unknown metadata projection type."
            }
        }

        $currentPath = Resolve-NexusContainedPath -Root $Context.SolutionRoot -RelativePath $path -RequireFile
        $actualText = [IO.File]::ReadAllText($currentPath, [Text.UTF8Encoding]::new($false, $true))
        if ($actualText -cne $expectedText) {
            Throw-NexusPackageError -Id "TECHNICAL-FREEZE" -Message "Metadata-only source contains an additional change: $path"
        }
        $results += [pscustomobject][ordered]@{
            path = $path
            treatment = [string]$projection.type
            status = "metadata-only"
        }
    }

    return @(Sort-NexusOrdinalByProperty -Items $results -Property "path")
}

function Test-NexusProtectedArtifacts {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context
    )

    $results = @()
    foreach ($artifact in @(Sort-NexusOrdinalByProperty -Items @($Context.Data.protectedArtifacts) -Property "path")) {
        $relative = [string]$artifact.path
        [void](Get-NexusTrackedPath -RepositoryRoot $Context.RepositoryRoot -RepositoryRelativePath $relative)
        $full = Resolve-NexusContainedPath -Root $Context.RepositoryRoot -RelativePath $relative -RequireFile
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash.ToUpperInvariant()
        if ($actual -cne ([string]$artifact.sha256).ToUpperInvariant()) {
            Throw-NexusPackageError -Id "HISTORICAL-HASH" -Message "Immutable historical artifact hash changed: $relative"
        }
        $results += [pscustomobject][ordered]@{
            path = $relative
            sha256 = $actual
            status = "match"
        }
    }
    return $results
}

function Get-NexusPrimaryInventory {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context
    )

    $primary = @($Context.Data.editions | Where-Object { [string]$_.role -ceq "primary" })[0]
    $inventory = @()
    foreach ($mapping in @(Sort-NexusOrdinalByProperty -Items @($primary.sourceToStage) -Property "stage")) {
        $source = [string]$mapping.source
        $repositoryRelative = "$($Context.Data.solution.sourceRoot)/$source"
        [void](Get-NexusTrackedPath -RepositoryRoot $Context.RepositoryRoot -RepositoryRelativePath $repositoryRelative)
        $full = Resolve-NexusContainedPath -Root $Context.SolutionRoot -RelativePath $source -RequireFile
        $bytes = [IO.File]::ReadAllBytes($full)
        if ([Array]::IndexOf($bytes, [byte]0) -ge 0) {
            Throw-NexusPackageError -Id "BINARY" -Message "Primary allowlist contains unexpected NUL bytes: $source"
        }
        if ([Array]::IndexOf($bytes, [byte]13) -ge 0) {
            Throw-NexusPackageError -Id "LINE-ENDINGS" -Message "Primary source must use repository-canonical LF bytes: $source"
        }
        [void][Text.UTF8Encoding]::new($false, $true).GetString($bytes)

        $inventory += [pscustomobject][ordered]@{
            source = $repositoryRelative
            stage = [string]$mapping.stage
            kind = [string]$mapping.kind
            bytes = [long]$bytes.Length
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash.ToUpperInvariant()
        }
    }
    return @(Sort-NexusOrdinalByProperty -Items $inventory -Property "stage")
}

function Read-NexusXmlSecurely {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $settings = [Xml.XmlReaderSettings]::new()
    $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
    $settings.XmlResolver = $null
    $reader = [Xml.XmlReader]::Create($Path, $settings)
    try {
        $document = [Xml.XmlDocument]::new()
        $document.XmlResolver = $null
        $document.Load($reader)
        return $document
    }
    finally {
        $reader.Dispose()
    }
}

function Test-NexusPowerShellSource {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$ExpectedVersion
    )

    $tokens = $null
    $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
    if (@($errors).Count -gt 0) {
        $message = (@($errors | ForEach-Object { $_.Message }) -join "; ")
        Throw-NexusPackageError -Id "PS-PARSE" -Message "PowerShell source did not parse: $message"
    }

    $assignments = @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.AssignmentStatementAst] -and
        $node.Left.Extent.Text -ceq '$script:PackageVersion'
    }, $true))
    if ($assignments.Count -ne 1) {
        Throw-NexusPackageError -Id "PS-VERSION" -Message "Expected exactly one PackageVersion assignment."
    }
    $right = $assignments[0].Right
    if ($right -is [Management.Automation.Language.CommandExpressionAst]) {
        $right = $right.Expression
    }
    if ($right -isnot [Management.Automation.Language.StringConstantExpressionAst] -or [string]$right.Value -cne $ExpectedVersion) {
        Throw-NexusPackageError -Id "PS-VERSION" -Message "PowerShell PackageVersion does not match the manifest."
    }
}

function Test-NexusVersionAndContent {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [ValidateSet("Development", "Candidate")]
        [string]$Profile = "Development"
    )

    $manifest = $Context.Data
    $version = [string]$manifest.release.intendedVersion
    foreach ($surface in @($manifest.versionSurfaces)) {
        $root = if ([string]$surface.scope -ceq "repository") { $Context.RepositoryRoot } else { $Context.SolutionRoot }
        $full = Resolve-NexusContainedPath -Root $root -RelativePath ([string]$surface.path) -RequireFile
        $expectedValue = if ($Profile -ceq "Candidate") { $surface.candidateValue } else { $surface.developmentValue }
        if ($null -eq $expectedValue) {
            Throw-NexusPackageError -Id "VERSION-SURFACE" -Message "$Profile projection is not finalized: $($surface.path)"
        }
        $expected = [string]$expectedValue
        switch ([string]$surface.type) {
            "plain-exact" {
                $actual = [IO.File]::ReadAllText($full, [Text.UTF8Encoding]::new($false, $true)).Trim()
                if ($actual -cne $expected) {
                    Throw-NexusPackageError -Id "VERSION-SURFACE" -Message "Plain version projection does not match: $($surface.path)"
                }
            }
            "mod-info-xml" {
                $xml = Read-NexusXmlSecurely -Path $full
                if ($xml.DocumentElement.LocalName -cne "xml") {
                    Throw-NexusPackageError -Id "MODINFO" -Message "ModInfo root must be xml."
                }
                $checks = @{
                    Name = [string]$manifest.solution.runtimeModId
                    DisplayName = [string]$manifest.solution.displayName
                    Author = [string]$manifest.solution.author
                    Version = $expected
                    Website = [string]$manifest.solution.officialRepository
                }
                foreach ($name in $checks.Keys) {
                    $node = $xml.SelectSingleNode("/xml/$name/@value")
                    if ($null -eq $node -or [string]$node.Value -cne [string]$checks[$name]) {
                        Throw-NexusPackageError -Id "MODINFO" -Message "ModInfo $name does not match the manifest."
                    }
                }
            }
            "powershell-package-version" {
                Test-NexusPowerShellSource -Path $full -ExpectedVersion $expected
            }
            "readme-version-line" {
                $text = [IO.File]::ReadAllText($full, [Text.UTF8Encoding]::new($false, $true))
                $matches = [regex]::Matches($text, "(?m)^" + [regex]::Escape($expected) + "$")
                if ($matches.Count -ne 1) {
                    Throw-NexusPackageError -Id "README-VERSION" -Message "README must contain exactly one anchored active version line."
                }
                $required = @(
                    "Copyright (C) 2026 Bit Wrecked",
                    "SPDX-License-Identifier: GPL-3.0-or-later",
                    "https://github.com/bitwrecked-often/nexus",
                    "without warranty",
                    "Support_Files_Do_Not_Edit/LICENSE.txt"
                )
                foreach ($literal in $required) {
                    if (-not $text.Contains($literal, [StringComparison]::OrdinalIgnoreCase)) {
                        Throw-NexusPackageError -Id "README-CONTRACT" -Message "README is missing required release text: $literal"
                    }
                }
                $forbidden = @("Advanced_CommandLine", "validate_and_package.ps1", "Upload_To_Nexus", "PUBLISHING_SEO.md", "Assets/")
                foreach ($literal in $forbidden) {
                    if ($text.Contains($literal, [StringComparison]::OrdinalIgnoreCase)) {
                        Throw-NexusPackageError -Id "README-CAPABILITY" -Message "README references an excluded package path: $literal"
                    }
                }
            }
            "changelog-heading" {
                $text = [IO.File]::ReadAllText($full, [Text.UTF8Encoding]::new($false, $true))
                $matches = [regex]::Matches($text, "(?m)^" + [regex]::Escape($expected) + "$")
                if ($matches.Count -ne 1) {
                    Throw-NexusPackageError -Id "CHANGELOG" -Message "Changelog must contain exactly one anchored current heading."
                }
            }
            default {
                Throw-NexusPackageError -Id "VERSION-SURFACE" -Message "Unsupported version-surface type."
            }
        }
    }

    $primary = @($manifest.editions | Where-Object { [string]$_.role -ceq "primary" })[0]
    foreach ($mapping in @($primary.sourceToStage)) {
        $full = Resolve-NexusContainedPath -Root $Context.SolutionRoot -RelativePath ([string]$mapping.source) -RequireFile
        switch ([string]$mapping.kind) {
            "config-xml" {
                $xml = Read-NexusXmlSecurely -Path $full
                if ($xml.DocumentElement.LocalName -cne "configs") {
                    Throw-NexusPackageError -Id "CONFIG-XML" -Message "Packaged config XML root must be configs."
                }
            }
            "batch" {
                $text = [IO.File]::ReadAllText($full, [Text.UTF8Encoding]::new($false, $true))
                $target = 'Support_Files_Do_Not_Edit\7DTD_WastelandAnimalPopulationTuning_Tool.ps1'
                if (-not $text.Contains($target, [StringComparison]::OrdinalIgnoreCase) -or -not $text.Contains("powershell -NoProfile", [StringComparison]::OrdinalIgnoreCase)) {
                    Throw-NexusPackageError -Id "BATCH" -Message "Launcher does not reference the staged support tool as expected."
                }
            }
            "license" {
                $text = [IO.File]::ReadAllText($full, [Text.UTF8Encoding]::new($false, $true))
                if (-not $text.Contains("GNU GENERAL PUBLIC LICENSE", [StringComparison]::Ordinal) -or -not $text.Contains("Version 3, 29 June 2007", [StringComparison]::Ordinal)) {
                    Throw-NexusPackageError -Id "LICENSE" -Message "Full GPLv3 text is missing or changed unexpectedly."
                }
            }
        }
    }
}

function Test-NexusReleaseSource {
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,

        [ValidateSet("Auto", "Development", "Candidate")]
        [string]$Profile = "Auto"
    )

    $context = Read-NexusManifest -ManifestPath $ManifestPath
    $resolvedProfile = Resolve-NexusReleaseProfile -Context $context -Profile $Profile
    Assert-NexusManifestContract -Context $context -Profile $resolvedProfile
    $baselineFingerprint = Test-NexusBaselineFingerprint -Context $context
    $technicalFreeze = @(Test-NexusTechnicalFreeze -Context $context)
    $protected = @(Test-NexusProtectedArtifacts -Context $context)
    $inventory = @(Get-NexusPrimaryInventory -Context $context)
    Test-NexusVersionAndContent -Context $context -Profile $resolvedProfile

    $head = (Invoke-NexusGit -RepositoryRoot $context.RepositoryRoot -Arguments @("rev-parse", "HEAD")).Output[0]
    $branchResult = Invoke-NexusGit -RepositoryRoot $context.RepositoryRoot -Arguments @("branch", "--show-current")
    if ($branchResult.Output.Count -gt 1) {
        Throw-NexusPackageError -Id "BRANCH" -Message "Git returned more than one current branch."
    }
    $branch = if ($branchResult.Output.Count -eq 0) { "" } else { [string]$branchResult.Output[0] }
    $status = Invoke-NexusGit -RepositoryRoot $context.RepositoryRoot -Arguments @("status", "--porcelain=v1", "--untracked-files=normal")
    $manifestHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $context.ManifestPath).Hash.ToUpperInvariant()

    return [pscustomobject][ordered]@{
        schemaVersion = 1
        operation = "validate"
        mutated = $false
        result = "pass"
        profile = $resolvedProfile.ToLowerInvariant()
        solutionId = [string]$context.Data.solution.id
        version = [string]$context.Data.release.intendedVersion
        lifecycle = [string]$context.Data.release.lifecycle
        edition = "windows-gui"
        manifestSha256 = $manifestHash
        source = [pscustomobject][ordered]@{
            commit = $head
            branch = $branch
            clean = ($status.Output.Count -eq 0)
            baselineCommit = [string]$context.Data.lineage.sourceBaseline.commit
            baselineTree = [string]$context.Data.lineage.sourceBaseline.tree
        }
        baselineFingerprint = $baselineFingerprint
        technicalFreeze = $technicalFreeze
        files = $inventory
        protectedArtifacts = $protected
        candidateBuilt = $false
        promoted = $false
        ownerApproval = "not-recorded"
    }
}

function Get-NexusPrimaryStagePath {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context
    )

    $relative = "$($Context.Data.distribution.candidateStage)/primary-tree"
    return Resolve-NexusContainedPath -Root $Context.RepositoryRoot -RelativePath $relative
}

function Write-NexusGitBlob {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory)]
        [string]$Commit,

        [Parameter(Mandatory)]
        [string]$RepositoryRelativePath,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    $object = Get-NexusGitBlobObjectId -RepositoryRoot $RepositoryRoot -Commit $Commit -RepositoryRelativePath $RepositoryRelativePath
    $process = $null
    $stream = $null
    try {
        $process = Start-NexusGitBlobProcess -RepositoryRoot $RepositoryRoot -ObjectId $object
        $stream = [IO.File]::Open($Destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $process.StandardOutput.BaseStream.CopyTo($stream)
        $stream.Dispose()
        $stream = $null
        $errorText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            Throw-NexusPackageError -Id "GIT-BLOB" -Message "Could not materialize a tracked source blob. $errorText"
        }
    }
    finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
        if ($null -ne $process) {
            if (-not $process.HasExited) {
                $process.Kill($true)
                $process.WaitForExit()
            }
            $process.Dispose()
        }
    }
}

function Write-NexusNewUtf8File {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    $writer = $null
    try {
        $writer = [IO.StreamWriter]::new($stream, [Text.UTF8Encoding]::new($false))
        $stream = $null
        $writer.Write($Content)
    }
    finally {
        if ($null -ne $writer) {
            $writer.Dispose()
        }
        elseif ($null -ne $stream) {
            $stream.Dispose()
        }
    }
}

function Remove-NexusOwnedWorkRoot {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [Parameter(Mandatory)]
        [string]$RelativePath,

        [Parameter(Mandatory)]
        [string]$WorkId,

        [ValidateSet("stage", "prepare")]
        [string]$Kind = "stage"
    )

    $full = Resolve-NexusContainedPath -Root $Context.RepositoryRoot -RelativePath $RelativePath
    if (-not (Test-Path -LiteralPath $full)) {
        return
    }
    $expectedSuffix = "/.nexus-$Kind-work-$WorkId"
    if (-not $RelativePath.EndsWith($expectedSuffix, [StringComparison]::Ordinal)) {
        Throw-NexusPackageError -Id "CLEANUP" -Message "Owned work path does not match its transaction identity."
    }
    $marker = Join-Path $full ".nexus-stage-owner"
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) {
        if (@(Get-ChildItem -LiteralPath $full -Force).Count -eq 0) {
            [IO.Directory]::Delete($full, $false)
            return
        }
        Throw-NexusPackageError -Id "CLEANUP" -Message "Owned work marker is missing from a nonempty directory."
    }
    if ([IO.File]::ReadAllText($marker) -cne $WorkId) {
        Throw-NexusPackageError -Id "CLEANUP" -Message "Owned work marker is missing or does not match."
    }
    $reparse = @(Get-ChildItem -LiteralPath $full -Force -Recurse | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 })
    if ($reparse.Count -ne 0) {
        Throw-NexusPackageError -Id "CLEANUP" -Message "Owned work contains a reparse point; refusing recursive cleanup."
    }
    [IO.Directory]::Delete($full, $true)
}

function New-NexusPrimaryStage {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath
    )

    $context = Read-NexusManifest -ManifestPath $ManifestPath
    $candidateRelative = [string]$context.Data.distribution.candidateStage
    $stageRelative = "$candidateRelative/primary-tree"
    if (-not $PSCmdlet.ShouldProcess($stageRelative, "Stage exact primary source tree from clean HEAD")) {
        return [pscustomobject][ordered]@{
            operation = "stage-primary"
            mutated = $false
            result = "what-if"
            stagePath = $stageRelative
        }
    }

    $evidence = Test-NexusReleaseSource -ManifestPath $ManifestPath -Profile Auto
    if (-not $evidence.source.clean) {
        Throw-NexusPackageError -Id "DIRTY" -Message "Explicit staging requires a clean committed worktree."
    }
    if ([string]$evidence.source.branch -cne [string]$context.Data.release.branch) {
        Throw-NexusPackageError -Id "BRANCH" -Message "Explicit development staging requires the manifest-declared branch."
    }

    $evidenceRootRelative = [string]$context.Data.distribution.workingEvidenceStage
    $evidencePathRelative = "$evidenceRootRelative/primary-source-stage.json"
    $versionRootRelative = "dist/$($context.Data.solution.id)/$($context.Data.release.intendedVersion)"
    $versionRoot = Resolve-NexusContainedPath -Root $context.RepositoryRoot -RelativePath $versionRootRelative
    if (Test-Path -LiteralPath $versionRoot) {
        Throw-NexusPackageError -Id "OVERWRITE" -Message "The versioned release root already exists; refusing a stale or mixed stage."
    }

    $ignored = Invoke-NexusGit -RepositoryRoot $context.RepositoryRoot -Arguments @("check-ignore", "--no-index", "-q", $stageRelative) -AllowFailure
    if ($ignored.ExitCode -ne 0) {
        Throw-NexusPackageError -Id "IGNORE" -Message "Derived dist stage is not protected by .gitignore."
    }

    $workId = [guid]::NewGuid().ToString("N")
    $workRootRelative = "dist/$($context.Data.solution.id)/.nexus-stage-work-$workId"
    $workRoot = Resolve-NexusContainedPath -Root $context.RepositoryRoot -RelativePath $workRootRelative
    $workVersion = Join-Path $workRoot "version"
    $workCandidate = Join-Path $workVersion "candidate"
    $workStage = Join-Path $workCandidate "primary-tree"
    $workEvidence = Join-Path $workVersion "evidence/primary-source-stage.json"
    $primary = @($context.Data.editions | Where-Object { [string]$_.role -ceq "primary" })[0]
    $expectedStageFiles = @(Sort-NexusOrdinalStrings -Values ([string[]]@($primary.sourceToStage | ForEach-Object { [string]$_.stage })))

    try {
        [void][IO.Directory]::CreateDirectory($workRoot)
        Write-NexusNewUtf8File -Path (Join-Path $workRoot ".nexus-stage-owner") -Content $workId
        [void][IO.Directory]::CreateDirectory($workStage)

        foreach ($mapping in @(Sort-NexusOrdinalByProperty -Items @($primary.sourceToStage) -Property "stage")) {
            $destination = Resolve-NexusContainedPath -Root $workStage -RelativePath ([string]$mapping.stage)
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
            $repositoryRelative = "$($context.Data.solution.sourceRoot)/$($mapping.source)"
            Write-NexusGitBlob -RepositoryRoot $context.RepositoryRoot -Commit $evidence.source.commit -RepositoryRelativePath $repositoryRelative -Destination $destination
            $objectId = Get-NexusGitBlobObjectId -RepositoryRoot $context.RepositoryRoot -Commit $evidence.source.commit -RepositoryRelativePath $repositoryRelative
            $expectedHash = Get-NexusGitBlobSha256 -RepositoryRoot $context.RepositoryRoot -ObjectId $objectId
            $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash.ToUpperInvariant()
            if ($actualHash -cne $expectedHash) {
                Throw-NexusPackageError -Id "STAGE-BYTES" -Message "Staged bytes differ from their clean-HEAD Git blob."
            }
        }

        $actualStageFiles = @(Sort-NexusOrdinalStrings -Values ([string[]]@(Get-ChildItem -LiteralPath $workStage -Recurse -File | ForEach-Object {
            [IO.Path]::GetRelativePath($workStage, $_.FullName).Replace("\", "/")
        })))
        Assert-NexusExactStringList -Actual $actualStageFiles -Expected $expectedStageFiles -Id "STAGE-INVENTORY" -Message "Staged file inventory differs from the exact allowlist."

        [void](Test-NexusProtectedArtifacts -Context $context)

        $evidence.operation = "stage-primary"
        $evidence.mutated = $true
        $evidence.result = "pass"
        $json = ($evidence | ConvertTo-Json -Depth 20).Replace("`r`n", "`n") + "`n"
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $workEvidence))
        Write-NexusNewUtf8File -Path $workEvidence -Content $json

        $expectedPayloadFiles = @($expectedStageFiles | ForEach-Object { "candidate/primary-tree/$_" }) + @("evidence/primary-source-stage.json")
        $expectedPayloadDirectories = @(Get-NexusExpectedDirectories -Files $expectedPayloadFiles)
        $payloadItems = @(Get-ChildItem -LiteralPath $workVersion -Force -Recurse)
        if (@($payloadItems | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -ne 0) {
            Throw-NexusPackageError -Id "STAGE-REPARSE" -Message "Prepared version payload contains a reparse point."
        }
        $actualPayloadFiles = @(Sort-NexusOrdinalStrings -Values ([string[]]@($payloadItems | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
            [IO.Path]::GetRelativePath($workVersion, $_.FullName).Replace("\", "/")
        })))
        $actualPayloadDirectories = @(Sort-NexusOrdinalStrings -Values ([string[]]@($payloadItems | Where-Object { $_.PSIsContainer } | ForEach-Object {
            [IO.Path]::GetRelativePath($workVersion, $_.FullName).Replace("\", "/")
        })))
        Assert-NexusExactStringList -Actual $actualPayloadFiles -Expected $expectedPayloadFiles -Id "STAGE-INVENTORY" -Message "Prepared version payload file inventory is not exact."
        Assert-NexusExactStringList -Actual $actualPayloadDirectories -Expected $expectedPayloadDirectories -Id "STAGE-INVENTORY" -Message "Prepared version payload directory inventory is not exact."

        $versionRoot = Resolve-NexusContainedPath -Root $context.RepositoryRoot -RelativePath $versionRootRelative
        if (Test-Path -LiteralPath $versionRoot) {
            Throw-NexusPackageError -Id "OVERWRITE" -Message "The versioned release root appeared during staging; refusing to overwrite it."
        }

        [IO.Directory]::Move($workVersion, $versionRoot)

        return [pscustomobject]@{
            Evidence = $evidence
            StagePath = $stageRelative
            EvidencePath = $evidencePathRelative
        }
    }
    finally {
        try {
            Remove-NexusOwnedWorkRoot -Context $context -RelativePath $workRootRelative -WorkId $workId
        }
        catch {
            Write-Warning "Owned staging work could not be cleaned automatically: $($_.Exception.Message)"
        }
    }
}

function Get-NexusBytesSha256 {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return [Convert]::ToHexString($algorithm.ComputeHash($Bytes))
    }
    finally {
        $algorithm.Dispose()
    }
}

function Get-NexusBytesCrc32 {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    [uint32]$crc = [uint32]::MaxValue
    [uint32]$polynomial = 3988292384
    foreach ($byte in $Bytes) {
        $crc = [uint32]($crc -bxor [uint32]$byte)
        for ($bit = 0; $bit -lt 8; $bit++) {
            if (($crc -band 1) -ne 0) {
                $crc = [uint32](($crc -shr 1) -bxor $polynomial)
            }
            else {
                $crc = [uint32]($crc -shr 1)
            }
        }
    }
    return [uint32]($crc -bxor [uint32]::MaxValue)
}

function New-NexusPrimaryStageSnapshot {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [Parameter(Mandatory)]
        [string]$Commit,

        [Parameter(Mandatory)]
        [string]$StageRoot
    )

    [void][IO.Directory]::CreateDirectory($StageRoot)
    $primary = @($Context.Data.editions | Where-Object { [string]$_.role -ceq "primary" })[0]
    $snapshot = @()
    foreach ($mapping in @(Sort-NexusOrdinalByProperty -Items @($primary.sourceToStage) -Property "stage")) {
        $stage = [string]$mapping.stage
        $destination = Resolve-NexusContainedPath -Root $StageRoot -RelativePath $stage
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
        $repositoryRelative = "$($Context.Data.solution.sourceRoot)/$($mapping.source)"
        Write-NexusGitBlob -RepositoryRoot $Context.RepositoryRoot -Commit $Commit -RepositoryRelativePath $repositoryRelative -Destination $destination

        $bytes = [IO.File]::ReadAllBytes($destination)
        if ($bytes.Length -gt 2MB) {
            Throw-NexusPackageError -Id "ARCHIVE-SIZE" -Message "A primary archive entry exceeds the reviewed two-megabyte ceiling: $stage"
        }
        $sha256 = Get-NexusBytesSha256 -Bytes $bytes
        $objectId = Get-NexusGitBlobObjectId -RepositoryRoot $Context.RepositoryRoot -Commit $Commit -RepositoryRelativePath $repositoryRelative
        $expectedSha256 = Get-NexusGitBlobSha256 -RepositoryRoot $Context.RepositoryRoot -ObjectId $objectId
        if ($sha256 -cne $expectedSha256) {
            Throw-NexusPackageError -Id "STAGE-BYTES" -Message "Prepared source bytes differ from their clean-HEAD Git blob: $stage"
        }

        $snapshot += [pscustomobject][ordered]@{
            Path = $stage
            Source = $repositoryRelative
            Kind = [string]$mapping.kind
            Bytes = $bytes
            Length = [long]$bytes.Length
            Sha256 = $sha256
        }
    }

    $expectedFiles = @($snapshot | ForEach-Object { [string]$_.Path })
    $expectedDirectories = @(Get-NexusExpectedDirectories -Files $expectedFiles)
    $items = @(Get-ChildItem -LiteralPath $StageRoot -Force -Recurse)
    if (@($items | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -ne 0) {
        Throw-NexusPackageError -Id "STAGE-REPARSE" -Message "Prepared primary source contains a reparse point."
    }
    $actualFiles = @($items | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
        [IO.Path]::GetRelativePath($StageRoot, $_.FullName).Replace("\", "/")
    })
    $actualDirectories = @($items | Where-Object { $_.PSIsContainer } | ForEach-Object {
        [IO.Path]::GetRelativePath($StageRoot, $_.FullName).Replace("\", "/")
    })
    Assert-NexusExactStringList -Actual $actualFiles -Expected $expectedFiles -Id "STAGE-INVENTORY" -Message "Prepared primary source file inventory is not exact."
    Assert-NexusExactStringList -Actual $actualDirectories -Expected $expectedDirectories -Id "STAGE-INVENTORY" -Message "Prepared primary source directory inventory is not exact."
    return @(Sort-NexusOrdinalByProperty -Items $snapshot -Property "Path")
}

function Get-NexusArchiveTimestamp {
    param(
        [Parameter(Mandatory)]
        [string]$TimestampUtc
    )

    if ($TimestampUtc -cne "2000-01-01T00:00:00Z") {
        Throw-NexusPackageError -Id "ARCHIVE-POLICY" -Message "The archive timestamp differs from the reviewed fixed timestamp."
    }
    return [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
}

function New-NexusStoredZip {
    param(
        [Parameter(Mandatory)]
        [object[]]$Entries,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter(Mandatory)]
        [DateTimeOffset]$Timestamp
    )

    $stream = $null
    $archive = $null
    try {
        $stream = [IO.File]::Open($Destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $archive = [IO.Compression.ZipArchive]::new(
            $stream,
            [IO.Compression.ZipArchiveMode]::Create,
            $true,
            [Text.UTF8Encoding]::new($false, $true)
        )
        foreach ($item in @(Sort-NexusOrdinalByProperty -Items $Entries -Property "Path")) {
            $path = Assert-NexusRelativePath -Path ([string]$item.Path) -Field "archive entry"
            $entry = $archive.CreateEntry($path, [IO.Compression.CompressionLevel]::NoCompression)
            $entry.LastWriteTime = $Timestamp
            $entry.ExternalAttributes = 0
            $entryStream = $null
            try {
                $entryStream = $entry.Open()
                $entryStream.Write([byte[]]$item.Bytes, 0, [int]$item.Bytes.Length)
            }
            finally {
                if ($null -ne $entryStream) {
                    $entryStream.Dispose()
                }
            }
        }
        $archive.Dispose()
        $archive = $null
        $stream.Flush($true)
    }
    finally {
        if ($null -ne $archive) {
            $archive.Dispose()
        }
        if ($null -ne $stream) {
            $stream.Dispose()
        }
    }
}

function Compare-NexusFilesExact {
    param(
        [Parameter(Mandatory)]
        [string]$First,

        [Parameter(Mandatory)]
        [string]$Second
    )

    $firstInfo = Get-Item -LiteralPath $First -Force
    $secondInfo = Get-Item -LiteralPath $Second -Force
    $firstHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $First).Hash.ToUpperInvariant()
    $secondHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Second).Hash.ToUpperInvariant()
    if ($firstInfo.Length -ne $secondInfo.Length -or $firstHash -cne $secondHash) {
        Throw-NexusPackageError -Id "REPRODUCIBILITY" -Message "The two archive builds have different lengths or SHA-256 digests."
    }

    $firstBytes = [IO.File]::ReadAllBytes($First)
    $secondBytes = [IO.File]::ReadAllBytes($Second)
    for ($index = 0; $index -lt $firstBytes.Length; $index++) {
        if ($firstBytes[$index] -ne $secondBytes[$index]) {
            Throw-NexusPackageError -Id "REPRODUCIBILITY" -Message "The two archive builds are not byte-identical."
        }
    }
    return [pscustomobject][ordered]@{
        bytes = [long]$firstInfo.Length
        build1Sha256 = $firstHash
        build2Sha256 = $secondHash
        digestsMatch = $true
        byteCompare = $true
    }
}

function Read-NexusZipContainerMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$ArchivePath,

        [Parameter(Mandatory)]
        [int]$ExpectedEntryCount,

        [Parameter(Mandatory)]
        [DateTimeOffset]$Timestamp
    )

    try {
        $bytes = [IO.File]::ReadAllBytes($ArchivePath)
        if ($bytes.Length -lt 22) {
            Throw-NexusPackageError -Id "ARCHIVE-READ" -Message "The candidate ZIP is shorter than its required end record."
        }

        $minimum = [Math]::Max(0, $bytes.Length - 65557)
        $eocd = -1
        for ($offset = $bytes.Length - 22; $offset -ge $minimum; $offset--) {
            if ([BitConverter]::ToUInt32($bytes, $offset) -eq 0x06054B50) {
                $commentLength = [BitConverter]::ToUInt16($bytes, $offset + 20)
                if ($offset + 22 + $commentLength -eq $bytes.Length) {
                    $eocd = $offset
                    break
                }
            }
        }
        if ($eocd -lt 0) {
            Throw-NexusPackageError -Id "ARCHIVE-READ" -Message "The candidate ZIP end record is missing or ambiguous."
        }

        $disk = [BitConverter]::ToUInt16($bytes, $eocd + 4)
        $centralDisk = [BitConverter]::ToUInt16($bytes, $eocd + 6)
        $entriesOnDisk = [BitConverter]::ToUInt16($bytes, $eocd + 8)
        $entryCount = [BitConverter]::ToUInt16($bytes, $eocd + 10)
        $centralSize = [uint64][BitConverter]::ToUInt32($bytes, $eocd + 12)
        $centralOffset = [uint64][BitConverter]::ToUInt32($bytes, $eocd + 16)
        $commentLength = [BitConverter]::ToUInt16($bytes, $eocd + 20)
        if ($disk -ne 0 -or $centralDisk -ne 0 -or $entriesOnDisk -ne $entryCount -or
            $entryCount -ne $ExpectedEntryCount -or $commentLength -ne 0) {
            Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "The candidate ZIP must be a single-disk, comment-free archive with the exact entry count."
        }
        if ($entryCount -eq 0xFFFF -or $centralSize -eq 0xFFFFFFFFL -or $centralOffset -eq 0xFFFFFFFFL) {
            Throw-NexusPackageError -Id "ARCHIVE-ZIP64" -Message "ZIP64 metadata is not permitted for this bounded package."
        }
        if ($centralOffset + $centralSize -ne [uint64]$eocd) {
            Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "The candidate ZIP central-directory bounds are not exact."
        }

        $timestampValue = $Timestamp.DateTime
        $expectedDosTime = [uint16](($timestampValue.Hour -shl 11) -bor ($timestampValue.Minute -shl 5) -bor [Math]::Floor($timestampValue.Second / 2))
        $expectedDosDate = [uint16]((($timestampValue.Year - 1980) -shl 9) -bor ($timestampValue.Month -shl 5) -bor $timestampValue.Day)
        $utf8 = [Text.UTF8Encoding]::new($false, $true)
        $records = @()
        $cursor = [int]$centralOffset
        $expectedLocalOffset = [uint64]0
        for ($index = 0; $index -lt $entryCount; $index++) {
            if ($cursor + 46 -gt $eocd -or [BitConverter]::ToUInt32($bytes, $cursor) -ne 0x02014B50) {
                Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "The candidate ZIP central directory is malformed."
            }
            $flags = [BitConverter]::ToUInt16($bytes, $cursor + 8)
            $method = [BitConverter]::ToUInt16($bytes, $cursor + 10)
            $dosTime = [BitConverter]::ToUInt16($bytes, $cursor + 12)
            $dosDate = [BitConverter]::ToUInt16($bytes, $cursor + 14)
            $crc32 = [BitConverter]::ToUInt32($bytes, $cursor + 16)
            $compressed = [uint64][BitConverter]::ToUInt32($bytes, $cursor + 20)
            $uncompressed = [uint64][BitConverter]::ToUInt32($bytes, $cursor + 24)
            $nameLength = [BitConverter]::ToUInt16($bytes, $cursor + 28)
            $extraLength = [BitConverter]::ToUInt16($bytes, $cursor + 30)
            $entryCommentLength = [BitConverter]::ToUInt16($bytes, $cursor + 32)
            $entryDisk = [BitConverter]::ToUInt16($bytes, $cursor + 34)
            $externalAttributes = [BitConverter]::ToUInt32($bytes, $cursor + 38)
            $localOffset = [uint64][BitConverter]::ToUInt32($bytes, $cursor + 42)
            $recordLength = 46 + $nameLength + $extraLength + $entryCommentLength
            if ($nameLength -eq 0 -or $cursor + $recordLength -gt $eocd) {
                Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "The candidate ZIP central entry exceeds its declared bounds."
            }
            if ($flags -notin @(0, 0x0800)) {
                $id = if (($flags -band 1) -ne 0) { "ARCHIVE-ENCRYPTED" } else { "ARCHIVE-FLAGS" }
                Throw-NexusPackageError -Id $id -Message "The candidate ZIP entry uses prohibited general-purpose flags."
            }
            if ($method -ne 0) {
                Throw-NexusPackageError -Id "ARCHIVE-COMPRESSION" -Message "The candidate ZIP must use stored entries only."
            }
            if ($compressed -eq 0xFFFFFFFFL -or $uncompressed -eq 0xFFFFFFFFL -or $localOffset -eq 0xFFFFFFFFL) {
                Throw-NexusPackageError -Id "ARCHIVE-ZIP64" -Message "ZIP64 entry metadata is not permitted."
            }
            if ($extraLength -ne 0 -or $entryCommentLength -ne 0 -or $entryDisk -ne 0 -or $externalAttributes -ne 0) {
                Throw-NexusPackageError -Id "ARCHIVE-METADATA" -Message "The candidate ZIP entry carries undeclared metadata."
            }

            $nameBytes = [byte[]]::new($nameLength)
            [Array]::Copy($bytes, $cursor + 46, $nameBytes, 0, $nameLength)
            $name = $utf8.GetString($nameBytes)
            if ($localOffset + 30 -gt [uint64]$centralOffset -or [BitConverter]::ToUInt32($bytes, [int]$localOffset) -ne 0x04034B50) {
                Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "The candidate ZIP local entry header is missing or out of bounds."
            }
            $localFlags = [BitConverter]::ToUInt16($bytes, [int]$localOffset + 6)
            $localMethod = [BitConverter]::ToUInt16($bytes, [int]$localOffset + 8)
            $localDosTime = [BitConverter]::ToUInt16($bytes, [int]$localOffset + 10)
            $localDosDate = [BitConverter]::ToUInt16($bytes, [int]$localOffset + 12)
            $localCrc32 = [BitConverter]::ToUInt32($bytes, [int]$localOffset + 14)
            $localCompressed = [uint64][BitConverter]::ToUInt32($bytes, [int]$localOffset + 18)
            $localUncompressed = [uint64][BitConverter]::ToUInt32($bytes, [int]$localOffset + 22)
            $localNameLength = [BitConverter]::ToUInt16($bytes, [int]$localOffset + 26)
            $localExtraLength = [BitConverter]::ToUInt16($bytes, [int]$localOffset + 28)
            if ($localFlags -ne $flags -or $localMethod -ne $method -or $localNameLength -ne $nameLength -or $localExtraLength -ne 0 -or
                $localOffset + 30 + $localNameLength -gt [uint64]$centralOffset) {
                Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "The candidate ZIP local and central entry metadata disagree."
            }
            if ($localDosTime -ne $dosTime -or $localDosDate -ne $dosDate -or $localCrc32 -ne $crc32 -or
                $localCompressed -ne $compressed -or $localUncompressed -ne $uncompressed) {
                Throw-NexusPackageError -Id "ARCHIVE-LOCAL-METADATA" -Message "The candidate ZIP local and central size, CRC, or timestamp metadata disagree."
            }
            if ($dosTime -ne $expectedDosTime -or $dosDate -ne $expectedDosDate) {
                Throw-NexusPackageError -Id "ARCHIVE-TIMESTAMP" -Message "The candidate ZIP raw timestamp differs from the fixed policy."
            }
            $localNameBytes = [byte[]]::new($localNameLength)
            [Array]::Copy($bytes, [int]$localOffset + 30, $localNameBytes, 0, $localNameLength)
            if (-not [Linq.Enumerable]::SequenceEqual([byte[]]$nameBytes, [byte[]]$localNameBytes)) {
                Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "The candidate ZIP local and central entry names disagree."
            }

            $dataOffset = $localOffset + 30 + $localNameLength
            $dataEnd = $dataOffset + $compressed
            if ($localOffset -ne $expectedLocalOffset -or $dataEnd -gt [uint64]$centralOffset) {
                Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "The candidate ZIP local entry layout is not exact."
            }
            $storedBytes = [byte[]]::new([int]$compressed)
            [Array]::Copy($bytes, [int]$dataOffset, $storedBytes, 0, [int]$compressed)
            if ((Get-NexusBytesCrc32 -Bytes $storedBytes) -ne $crc32) {
                Throw-NexusPackageError -Id "ARCHIVE-CRC" -Message "The candidate ZIP raw CRC-32 differs from its stored entry bytes."
            }
            $expectedLocalOffset = $dataEnd

            $records += [pscustomobject][ordered]@{
                Name = $name
                Flags = [int]$flags
                Method = [int]$method
                DosTime = [uint16]$dosTime
                DosDate = [uint16]$dosDate
                Crc32 = [uint32]$crc32
                CompressedLength = [long]$compressed
                Length = [long]$uncompressed
                ExternalAttributes = [uint32]$externalAttributes
                LocalHeaderOffset = [long]$localOffset
            }
            $cursor += $recordLength
        }
        if ($cursor -ne $eocd -or $expectedLocalOffset -ne $centralOffset) {
            Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "The candidate ZIP central directory has undeclared trailing bytes."
        }
        return @($records)
    }
    catch {
        if ($_.Exception.Message.Contains("BW-PKG-", [StringComparison]::Ordinal)) {
            throw
        }
        Throw-NexusPackageError -Id "ARCHIVE-READ" -Message "The candidate ZIP container could not be parsed safely."
    }
}

function Read-NexusValidatedStoredZip {
    param(
        [Parameter(Mandatory)]
        [string]$ArchivePath,

        [Parameter(Mandatory)]
        [object[]]$ExpectedEntries,

        [Parameter(Mandatory)]
        [DateTimeOffset]$Timestamp
    )

    $archiveItem = Get-Item -LiteralPath $ArchivePath -Force
    if (($archiveItem.Attributes -band ([IO.FileAttributes]::ReparsePoint -bor [IO.FileAttributes]::Encrypted)) -ne 0) {
        Throw-NexusPackageError -Id "ARCHIVE-ATTRIBUTES" -Message "The candidate archive has a prohibited filesystem attribute."
    }
    if ($archiveItem.Length -gt 4MB) {
        Throw-NexusPackageError -Id "ARCHIVE-SIZE" -Message "The candidate archive exceeds the reviewed four-megabyte ceiling."
    }

    $expected = @(Sort-NexusOrdinalByProperty -Items $ExpectedEntries -Property "Path")
    $containerEntries = @(Read-NexusZipContainerMetadata -ArchivePath $ArchivePath -ExpectedEntryCount $expected.Count -Timestamp $Timestamp)
    $stream = $null
    $archive = $null
    try {
        $stream = [IO.File]::Open($ArchivePath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        $archive = [IO.Compression.ZipArchive]::new(
            $stream,
            [IO.Compression.ZipArchiveMode]::Read,
            $true,
            [Text.UTF8Encoding]::new($false, $true)
        )
        $archiveEntries = @($archive.Entries)
        if ($archiveEntries.Count -ne $expected.Count) {
            Throw-NexusPackageError -Id "ARCHIVE-INVENTORY" -Message "The candidate archive entry count is not exact."
        }

        $ordinalNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $foldedNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $validated = @()
        for ($index = 0; $index -lt $archiveEntries.Count; $index++) {
            $entry = $archiveEntries[$index]
            $expectedItem = $expected[$index]
            $path = [string]$entry.FullName
            if ([string]$containerEntries[$index].Name -cne $path) {
                Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "Raw ZIP metadata and decoded entry order disagree."
            }
            try {
                [void](Assert-NexusRelativePath -Path $path -Field "archive entry")
            }
            catch {
                Throw-NexusPackageError -Id "ARCHIVE-PATH" -Message "The candidate archive contains an unsafe entry path."
            }
            if ([string]::IsNullOrEmpty([string]$entry.Name) -or $path.EndsWith("/", [StringComparison]::Ordinal)) {
                Throw-NexusPackageError -Id "ARCHIVE-INVENTORY" -Message "Explicit directory entries are not permitted."
            }
            if (-not $ordinalNames.Add($path) -or -not $foldedNames.Add($path)) {
                Throw-NexusPackageError -Id "ARCHIVE-DUPLICATE" -Message "The candidate archive contains duplicate or case-colliding paths."
            }
            if ($path -cne [string]$expectedItem.Path) {
                Throw-NexusPackageError -Id "ARCHIVE-ORDER" -Message "The candidate archive path order or inventory differs from the manifest."
            }
            $encryptedProperty = $entry.PSObject.Properties["IsEncrypted"]
            if (($containerEntries[$index].Flags -band 1) -ne 0 -or ($null -ne $encryptedProperty -and [bool]$encryptedProperty.Value)) {
                Throw-NexusPackageError -Id "ARCHIVE-ENCRYPTED" -Message "Encrypted archive entries are prohibited."
            }
            if ([int]$entry.ExternalAttributes -ne 0) {
                Throw-NexusPackageError -Id "ARCHIVE-ATTRIBUTES" -Message "Archive entries must use the reviewed zero external-attribute policy."
            }
            if ($entry.LastWriteTime.DateTime -ne $Timestamp.DateTime) {
                Throw-NexusPackageError -Id "ARCHIVE-TIMESTAMP" -Message "Archive entry timestamp differs from the fixed policy."
            }
            if ([long]$entry.Length -ne [long]$expectedItem.Length -or [long]$entry.CompressedLength -ne [long]$entry.Length) {
                Throw-NexusPackageError -Id "ARCHIVE-SIZE" -Message "Archive entry length or stored-compression policy differs from the source snapshot."
            }
            if ([long]$containerEntries[$index].Length -ne [long]$entry.Length -or
                [long]$containerEntries[$index].CompressedLength -ne [long]$entry.CompressedLength) {
                Throw-NexusPackageError -Id "ARCHIVE-CONTAINER" -Message "Raw ZIP size metadata and decoded entry sizes disagree."
            }

            $entryStream = $null
            $memory = [IO.MemoryStream]::new([int]$expectedItem.Length)
            try {
                $entryStream = $entry.Open()
                $buffer = [byte[]]::new(81920)
                $total = 0L
                while (($read = $entryStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $total += $read
                    if ($total -gt [long]$expectedItem.Length) {
                        Throw-NexusPackageError -Id "ARCHIVE-SIZE" -Message "Archive entry expanded beyond its declared source length."
                    }
                    $memory.Write($buffer, 0, $read)
                }
                $bytes = $memory.ToArray()
            }
            catch {
                if ($_.Exception.Message.Contains("BW-PKG-", [StringComparison]::Ordinal)) {
                    throw
                }
                Throw-NexusPackageError -Id "ARCHIVE-READ" -Message "An archive entry could not be read safely."
            }
            finally {
                if ($null -ne $entryStream) {
                    $entryStream.Dispose()
                }
                $memory.Dispose()
            }
            $sha256 = Get-NexusBytesSha256 -Bytes $bytes
            if ($sha256 -cne [string]$expectedItem.Sha256) {
                Throw-NexusPackageError -Id "ARCHIVE-BYTES" -Message "Archive entry bytes differ from the staged source: $path"
            }
            $computedCrc32 = Get-NexusBytesCrc32 -Bytes $bytes
            if ($computedCrc32 -ne [uint32]$containerEntries[$index].Crc32) {
                Throw-NexusPackageError -Id "ARCHIVE-CRC" -Message "The candidate ZIP decoded entry CRC-32 differs from its raw metadata: $path"
            }
            $crc32 = ([uint32]$containerEntries[$index].Crc32).ToString("X8")
            $validated += [pscustomobject][ordered]@{
                Path = $path
                Bytes = $bytes
                Length = [long]$bytes.Length
                CompressedLength = [long]$entry.CompressedLength
                Sha256 = $sha256
                Crc32 = $crc32
            }
        }
        return @($validated)
    }
    catch {
        if ($_.Exception.Message.Contains("BW-PKG-", [StringComparison]::Ordinal)) {
            throw
        }
        Throw-NexusPackageError -Id "ARCHIVE-READ" -Message "The candidate ZIP entries could not be inspected safely."
    }
    finally {
        if ($null -ne $archive) {
            $archive.Dispose()
        }
        if ($null -ne $stream) {
            $stream.Dispose()
        }
    }
}

function Expand-NexusValidatedEntries {
    param(
        [Parameter(Mandatory)]
        [object[]]$Entries,

        [Parameter(Mandatory)]
        [string]$DestinationRoot
    )

    if (Test-Path -LiteralPath $DestinationRoot) {
        Throw-NexusPackageError -Id "EXTRACT-OVERWRITE" -Message "The guarded extraction root already exists."
    }
    [void][IO.Directory]::CreateDirectory($DestinationRoot)
    foreach ($entry in @(Sort-NexusOrdinalByProperty -Items $Entries -Property "Path")) {
        $destination = Resolve-NexusContainedPath -Root $DestinationRoot -RelativePath ([string]$entry.Path)
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
        $stream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $stream.Write([byte[]]$entry.Bytes, 0, [int]$entry.Bytes.Length)
            $stream.Flush($true)
        }
        finally {
            $stream.Dispose()
        }
        $written = Get-Item -LiteralPath $destination -Force
        $writtenHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash.ToUpperInvariant()
        if ([long]$written.Length -ne [long]$entry.Length -or $writtenHash -cne [string]$entry.Sha256) {
            Throw-NexusPackageError -Id "EXTRACT-BYTES" -Message "Extracted bytes failed read-back verification: $($entry.Path)"
        }
    }

    $expectedFiles = @($Entries | ForEach-Object { [string]$_.Path })
    $expectedDirectories = @(Get-NexusExpectedDirectories -Files $expectedFiles)
    $items = @(Get-ChildItem -LiteralPath $DestinationRoot -Force -Recurse)
    if (@($items | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -ne 0) {
        Throw-NexusPackageError -Id "EXTRACT-REPARSE" -Message "The guarded extraction contains a reparse point."
    }
    $actualFiles = @($items | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
        [IO.Path]::GetRelativePath($DestinationRoot, $_.FullName).Replace("\", "/")
    })
    $actualDirectories = @($items | Where-Object { $_.PSIsContainer } | ForEach-Object {
        [IO.Path]::GetRelativePath($DestinationRoot, $_.FullName).Replace("\", "/")
    })
    Assert-NexusExactStringList -Actual $actualFiles -Expected $expectedFiles -Id "EXTRACT-INVENTORY" -Message "Extracted file inventory is not exact."
    Assert-NexusExactStringList -Actual $actualDirectories -Expected $expectedDirectories -Id "EXTRACT-INVENTORY" -Message "Extracted directory inventory is not exact."
}

function Test-NexusExtractedPrimaryContent {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [Parameter(Mandatory)]
        [string]$ExtractedRoot
    )

    $extractedContext = [pscustomobject]@{
        Data = $Context.Data
        Json = $Context.Json
        ManifestPath = $Context.ManifestPath
        RepositoryRoot = $Context.RepositoryRoot
        SolutionRoot = $ExtractedRoot
        SchemaPath = $Context.SchemaPath
    }
    Test-NexusVersionAndContent -Context $extractedContext -Profile Candidate
}

function Invoke-NexusExtractedGuiSmokeTest {
    param(
        [Parameter(Mandatory)]
        [string]$ExtractedRoot,

        [Parameter(Mandatory)]
        [string]$IsolationRoot,

        [int]$TimeoutSeconds = 30
    )

    if (-not [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([Runtime.InteropServices.OSPlatform]::Windows)) {
        Throw-NexusPackageError -Id "SMOKE-PLATFORM" -Message "The packaged GUI smoke test requires Windows."
    }
    $scriptRelative = "Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1"
    $scriptPath = Resolve-NexusContainedPath -Root $ExtractedRoot -RelativePath $scriptRelative -RequireFile
    $scriptLaunchPath = ".\" + $scriptRelative.Replace("/", "\")
    if ($scriptPath.Length -ge 240) {
        Throw-NexusPackageError -Id "SMOKE-PATH" -Message "The packaged GUI smoke-test path exceeds the conservative Windows PowerShell path limit."
    }
    $windowsPowerShell = Join-Path $env:SystemRoot "System32/WindowsPowerShell/v1.0/powershell.exe"
    if (-not (Test-Path -LiteralPath $windowsPowerShell -PathType Leaf)) {
        Throw-NexusPackageError -Id "SMOKE-RUNTIME" -Message "Windows PowerShell was not found for the packaged GUI smoke test."
    }
    $emptyProgramFiles = Join-Path $IsolationRoot "empty-program-files-x86"
    [void][IO.Directory]::CreateDirectory($emptyProgramFiles)

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $windowsPowerShell
    $startInfo.WorkingDirectory = $ExtractedRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @("-NoLogo", "-NoProfile", "-NonInteractive", "-STA", "-ExecutionPolicy", "Bypass", "-File", $scriptLaunchPath, "-SmokeTest")) {
        [void]$startInfo.ArgumentList.Add($argument)
    }
    $startInfo.Environment["ProgramFiles(x86)"] = $emptyProgramFiles

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $started = $false
    try {
        [void]$process.Start()
        $started = $true
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill($true)
            $process.WaitForExit()
            [void]$stdoutTask.GetAwaiter().GetResult()
            [void]$stderrTask.GetAwaiter().GetResult()
            Throw-NexusPackageError -Id "SMOKE-TIMEOUT" -Message "The packaged GUI smoke test exceeded $TimeoutSeconds seconds."
        }
        [void]$stdoutTask.GetAwaiter().GetResult()
        [void]$stderrTask.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) {
            Throw-NexusPackageError -Id "SMOKE-FAIL" -Message "The packaged GUI smoke test exited with code $($process.ExitCode)."
        }
        return [pscustomobject][ordered]@{
            status = "pass"
            runtime = "windows-powershell"
            mode = "SmokeTest"
            timeoutSeconds = $TimeoutSeconds
            exitCode = 0
            gameDiscoveryIsolated = $true
        }
    }
    catch {
        if ($_.Exception.Message.Contains("BW-PKG-", [StringComparison]::Ordinal)) {
            throw
        }
        Throw-NexusPackageError -Id "SMOKE-RUNTIME" -Message "The packaged GUI smoke-test process could not be started or observed safely."
    }
    finally {
        if ($started -and -not $process.HasExited) {
            $process.Kill($true)
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Invoke-NexusValidatedGuiSmokeTest {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [Parameter(Mandatory)]
        [object[]]$Entries,

        [int]$TimeoutSeconds = 30
    )

    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $smokeId = [guid]::NewGuid().ToString("N")
    $smokeRoot = Join-Path $tempBase ("nexus-package-smoke-" + $smokeId)
    $requiredPrefix = $tempBase + [IO.Path]::DirectorySeparatorChar + "nexus-package-smoke-"
    $packageRoot = Join-Path $smokeRoot "package"

    try {
        [void][IO.Directory]::CreateDirectory($smokeRoot)
        $rootItem = Get-Item -LiteralPath $smokeRoot -Force
        if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Throw-NexusPackageError -Id "SMOKE-ISOLATION" -Message "The temporary GUI smoke-test root is a reparse point."
        }
        Write-NexusNewUtf8File -Path (Join-Path $smokeRoot ".nexus-smoke-owner") -Content $smokeId

        Expand-NexusValidatedEntries -Entries $Entries -DestinationRoot $packageRoot
        Test-NexusExtractedPrimaryContent -Context $Context -ExtractedRoot $packageRoot
        $result = Invoke-NexusExtractedGuiSmokeTest -ExtractedRoot $packageRoot -IsolationRoot $smokeRoot -TimeoutSeconds $TimeoutSeconds
        Test-NexusExtractedPrimaryContent -Context $Context -ExtractedRoot $packageRoot
        $expectedFiles = @($Entries | ForEach-Object { [string]$_.Path })
        $expectedDirectories = @(Get-NexusExpectedDirectories -Files $expectedFiles)
        $packageItems = @(Get-ChildItem -LiteralPath $packageRoot -Force -Recurse)
        if (@($packageItems | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -ne 0) {
            Throw-NexusPackageError -Id "SMOKE-MUTATION" -Message "The temporary GUI smoke-test package contains a reparse point after execution."
        }
        $actualFiles = @($packageItems | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
            [IO.Path]::GetRelativePath($packageRoot, $_.FullName).Replace("\", "/")
        })
        $actualDirectories = @($packageItems | Where-Object { $_.PSIsContainer } | ForEach-Object {
            [IO.Path]::GetRelativePath($packageRoot, $_.FullName).Replace("\", "/")
        })
        Assert-NexusExactStringList -Actual $actualFiles -Expected $expectedFiles -Id "SMOKE-MUTATION" -Message "The temporary GUI smoke-test file inventory changed during execution."
        Assert-NexusExactStringList -Actual $actualDirectories -Expected $expectedDirectories -Id "SMOKE-MUTATION" -Message "The temporary GUI smoke-test directory inventory changed during execution."
        foreach ($entry in $Entries) {
            $path = Resolve-NexusContainedPath -Root $packageRoot -RelativePath ([string]$entry.Path) -RequireFile
            $item = Get-Item -LiteralPath $path -Force
            $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToUpperInvariant()
            if ([long]$item.Length -ne [long]$entry.Length -or $hash -cne [string]$entry.Sha256) {
                Throw-NexusPackageError -Id "SMOKE-MUTATION" -Message "The temporary GUI smoke-test changed packaged bytes: $($entry.Path)"
            }
        }

        return [pscustomobject][ordered]@{
            status = [string]$result.status
            runtime = [string]$result.runtime
            mode = [string]$result.mode
            timeoutSeconds = [int]$result.timeoutSeconds
            exitCode = [int]$result.exitCode
            gameDiscoveryIsolated = [bool]$result.gameDiscoveryIsolated
            shortPathIsolation = $true
            temporaryPackageRevalidatedAfterSmoke = $true
            temporaryMaterialRemoved = $true
        }
    }
    finally {
        $resolvedSmokeRoot = [IO.Path]::GetFullPath($smokeRoot)
        if (Test-Path -LiteralPath $resolvedSmokeRoot) {
            if (-not $resolvedSmokeRoot.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                Throw-NexusPackageError -Id "SMOKE-CLEANUP" -Message "Refusing to clean a temporary GUI smoke-test path outside its owned namespace."
            }
            $rootItem = Get-Item -LiteralPath $resolvedSmokeRoot -Force
            if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
                @(Get-ChildItem -LiteralPath $resolvedSmokeRoot -Force -Recurse | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -ne 0) {
                Throw-NexusPackageError -Id "SMOKE-CLEANUP" -Message "Refusing to clean temporary GUI smoke-test material containing a reparse point."
            }
            $ownerPath = Join-Path $resolvedSmokeRoot ".nexus-smoke-owner"
            if (-not (Test-Path -LiteralPath $ownerPath -PathType Leaf)) {
                Throw-NexusPackageError -Id "SMOKE-CLEANUP" -Message "Refusing to clean temporary GUI smoke-test material without its ownership marker."
            }
            $ownerValue = [IO.File]::ReadAllText($ownerPath, [Text.UTF8Encoding]::new($false, $true))
            if ($ownerValue -cne $smokeId) {
                Throw-NexusPackageError -Id "SMOKE-CLEANUP" -Message "Refusing to clean temporary GUI smoke-test material with a mismatched ownership marker."
            }
            [IO.Directory]::Delete($resolvedSmokeRoot, $true)
        }
    }
}

function Assert-NexusDisposableTestContext {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [Parameter(Mandatory)]
        [string]$Token
    )

    if ($Token -cnotmatch '^[0-9a-f]{32}$') {
        Throw-NexusPackageError -Id "TEST-CONTEXT" -Message "Disposable preparation requires its exact 32-character ownership token."
    }
    $repositoryRoot = [IO.Path]::GetFullPath($Context.RepositoryRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $testRoot = Split-Path -Parent $repositoryRoot
    $testRootName = [IO.Path]::GetFileName($testRoot)
    if ([IO.Path]::GetFileName($repositoryRoot) -cne "repository" -or
        $testRootName -cnotmatch '^nexus-offline-prepare-[0-9a-f]{32}$' -or
        (Split-Path -Parent $testRoot) -cne $tempBase) {
        Throw-NexusPackageError -Id "TEST-CONTEXT" -Message "Disposable preparation is allowed only in the offline test harness's owned system-temp clone."
    }
    foreach ($path in @($testRoot, $repositoryRoot)) {
        $item = Get-Item -LiteralPath $path -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Throw-NexusPackageError -Id "TEST-CONTEXT" -Message "The disposable preparation root cannot be a reparse point."
        }
    }

    $gitDirectoryResult = Invoke-NexusGit -RepositoryRoot $repositoryRoot -Arguments @("rev-parse", "--absolute-git-dir")
    if ($gitDirectoryResult.Output.Count -ne 1) {
        Throw-NexusPackageError -Id "TEST-CONTEXT" -Message "The disposable preparation clone did not report exactly one Git metadata directory."
    }
    $gitDirectory = [IO.Path]::GetFullPath($gitDirectoryResult.Output[0]).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if (-not $gitDirectory.StartsWith(($repositoryRoot + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) {
        Throw-NexusPackageError -Id "TEST-CONTEXT" -Message "The disposable preparation clone does not own its Git metadata directory."
    }
    $marker = Join-Path $gitDirectory "nexus-disposable-test-owner"
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) {
        Throw-NexusPackageError -Id "TEST-CONTEXT" -Message "The disposable preparation clone is missing its Git-scoped ownership marker."
    }
    $markerItem = Get-Item -LiteralPath $marker -Force
    if (($markerItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        Throw-NexusPackageError -Id "TEST-CONTEXT" -Message "The disposable preparation ownership marker cannot be a reparse point."
    }
    $markerValue = [IO.File]::ReadAllText($marker, [Text.UTF8Encoding]::new($false, $true))
    if ($markerValue -cne $Token) {
        Throw-NexusPackageError -Id "TEST-CONTEXT" -Message "The disposable preparation ownership marker does not match its invocation token."
    }
    return [pscustomobject][ordered]@{
        type = "owned-system-temp-clone"
        namespace = "nexus-offline-prepare-<guid>/repository"
        gitScopedOwnershipMarker = $true
    }
}

function Get-NexusP4AuthorityRecord {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context,

        [Parameter(Mandatory)]
        [ValidateSet("candidate", "disposable-test-fixture")]
        [string]$ExecutionClass,

        [AllowNull()]
        [pscustomobject]$TestContext
    )

    $relative = "governance/EXECUTION_PLAN.md"
    $readinessRelative = "governance/RELEASE_READINESS_4.1.0.md"
    [void](Get-NexusTrackedPath -RepositoryRoot $Context.RepositoryRoot -RepositoryRelativePath $relative)
    [void](Get-NexusTrackedPath -RepositoryRoot $Context.RepositoryRoot -RepositoryRelativePath $readinessRelative)
    $path = Resolve-NexusContainedPath -Root $Context.RepositoryRoot -RelativePath $relative -RequireFile
    $readinessPath = Resolve-NexusContainedPath -Root $Context.RepositoryRoot -RelativePath $readinessRelative -RequireFile
    $text = [IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false, $true))
    $readinessText = [IO.File]::ReadAllText($readinessPath, [Text.UTF8Encoding]::new($false, $true))
    if ($text -notmatch '(?m)^\| P4 \|.*\| (Active|Complete) \|' -or
        -not $text.Contains("publication remains separately authorized", [StringComparison]::OrdinalIgnoreCase) -or
        -not $readinessText.Contains("The owner accepted this planning set", [StringComparison]::Ordinal) -or
        -not $readinessText.Contains("authorized one", [StringComparison]::Ordinal) -or
        -not $readinessText.Contains('It does not authorize merge to `main`, a tag', [StringComparison]::Ordinal)) {
        Throw-NexusPackageError -Id "AUTHORITY" -Message "The durable execution plan and accepted readiness record do not authorize P4 technical preparation while withholding publication authority."
    }
    return [pscustomobject][ordered]@{
        record = $relative
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToUpperInvariant()
        acceptedReadinessRecord = $readinessRelative
        acceptedReadinessSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $readinessPath).Hash.ToUpperInvariant()
        executionClass = $ExecutionClass
        scope = if ($ExecutionClass -ceq "candidate") { "P4 technical preparation only" } else { "disposable integration-test fixture only" }
        ownerCandidateCycleConsumed = ($ExecutionClass -ceq "candidate")
        disposableTestContext = $TestContext
        publicationApproved = $false
        publicationPerformed = $false
    }
}

function Write-NexusJsonEvidence {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Value
    )

    $json = ($Value | ConvertTo-Json -Depth 40).Replace("`r`n", "`n") + "`n"
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    Write-NexusNewUtf8File -Path $Path -Content $json
    $readBack = [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false, $true))
    $document = [System.Text.Json.JsonDocument]::Parse($readBack)
    try {
        Assert-NoDuplicateJsonProperties -Element $document.RootElement
    }
    finally {
        $document.Dispose()
    }
    [void]($readBack | ConvertFrom-Json -Depth 100)
}

function Remove-NexusPrepareTemporaryMaterial {
    param(
        [Parameter(Mandatory)]
        [string]$WorkRoot
    )

    foreach ($relative in @("build-2.zip", "extracted", "empty-program-files-x86")) {
        $path = Resolve-NexusContainedPath -Root $WorkRoot -RelativePath $relative
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }
        $item = Get-Item -LiteralPath $path -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Throw-NexusPackageError -Id "CLEANUP" -Message "Temporary preparation material is a reparse point."
        }
        if ($item.PSIsContainer) {
            $children = @(Get-ChildItem -LiteralPath $path -Force -Recurse)
            if (@($children | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -ne 0) {
                Throw-NexusPackageError -Id "CLEANUP" -Message "Temporary preparation material contains a reparse point."
            }
            [IO.Directory]::Delete($path, $true)
        }
        else {
            [IO.File]::Delete($path)
        }
    }

    $remaining = @(Get-ChildItem -LiteralPath $WorkRoot -Force | ForEach-Object { $_.Name } | Sort-Object)
    $expected = @(".nexus-stage-owner", "version") | Sort-Object
    if (($remaining -join "`n") -cne ($expected -join "`n")) {
        Throw-NexusPackageError -Id "CLEANUP" -Message "Owned preparation work contains undeclared temporary material."
    }
}

function New-NexusPreparedPrimary {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,

        [ValidateSet("candidate", "disposable-test-fixture")]
        [string]$ExecutionClass = "candidate",

        [string]$DisposableTestToken
    )

    $context = Read-NexusManifest -ManifestPath $ManifestPath
    $testContext = $null
    if ($ExecutionClass -ceq "disposable-test-fixture") {
        $testContext = Assert-NexusDisposableTestContext -Context $context -Token $DisposableTestToken
        $solutionOutputRelative = "dist/.test-fixtures/$($context.Data.solution.id)"
    }
    else {
        if (-not [string]::IsNullOrEmpty($DisposableTestToken)) {
            Throw-NexusPackageError -Id "TEST-CONTEXT" -Message "A disposable ownership token cannot be used for a candidate preparation."
        }
        $solutionOutputRelative = "dist/$($context.Data.solution.id)"
    }
    $versionRootRelative = "$solutionOutputRelative/$($context.Data.release.intendedVersion)"
    if (-not $PSCmdlet.ShouldProcess($versionRootRelative, "Prepare and atomically promote the complete primary technical candidate")) {
        return [pscustomobject][ordered]@{
            operation = "prepare-primary"
            mutated = $false
            result = "what-if"
            versionRoot = $versionRootRelative
            executionClass = $ExecutionClass
        }
    }

    $validation = Test-NexusReleaseSource -ManifestPath $ManifestPath -Profile Candidate
    if (-not $validation.source.clean) {
        Throw-NexusPackageError -Id "DIRTY" -Message "Primary preparation requires a clean committed worktree."
    }
    if ([string]$validation.source.branch -cne [string]$context.Data.release.branch) {
        Throw-NexusPackageError -Id "BRANCH" -Message "Primary preparation requires the manifest-declared candidate branch."
    }
    $authority = Get-NexusP4AuthorityRecord -Context $context -ExecutionClass $ExecutionClass -TestContext $testContext
    $versionRoot = Resolve-NexusContainedPath -Root $context.RepositoryRoot -RelativePath $versionRootRelative
    if (Test-Path -LiteralPath $versionRoot) {
        Throw-NexusPackageError -Id "OVERWRITE" -Message "The versioned release root already exists; refusing to merge or replace prepared output."
    }
    $ignored = Invoke-NexusGit -RepositoryRoot $context.RepositoryRoot -Arguments @("check-ignore", "--no-index", "-q", $versionRootRelative) -AllowFailure
    if ($ignored.ExitCode -ne 0) {
        Throw-NexusPackageError -Id "IGNORE" -Message "The prepared release root is not protected by .gitignore."
    }

    $primary = @($context.Data.editions | Where-Object { [string]$_.role -ceq "primary" })[0]
    $filename = [string]$primary.plannedFilename
    [void](Assert-NexusRelativePath -Path $filename -Field "primary plannedFilename")
    $timestamp = Get-NexusArchiveTimestamp -TimestampUtc ([string]$context.Data.distribution.archiveTimestampUtc)
    $workId = [guid]::NewGuid().ToString("N")
    $workRootRelative = "$solutionOutputRelative/.nexus-prepare-work-$workId"
    $workRoot = Resolve-NexusContainedPath -Root $context.RepositoryRoot -RelativePath $workRootRelative
    $workVersion = Join-Path $workRoot "version"
    $workStage = Join-Path $workVersion "candidate/primary-tree"
    $finalUploadRoot = Join-Path $workVersion "final-upload"
    $finalArchive = Join-Path $finalUploadRoot $filename
    $secondArchive = Join-Path $workRoot "build-2.zip"
    $extractRoot = Join-Path $workRoot "extracted"
    $sourceEvidenceRelative = "evidence/primary-source-stage.json"
    $buildEvidenceRelative = "evidence/primary-package-build.json"
    $uploadEvidenceRelative = "evidence/primary-final-upload.json"
    $sourceEvidencePath = Join-Path $workVersion $sourceEvidenceRelative
    $buildEvidencePath = Join-Path $workVersion $buildEvidenceRelative
    $uploadEvidencePath = Join-Path $workVersion $uploadEvidenceRelative

    try {
        [void][IO.Directory]::CreateDirectory($workRoot)
        Write-NexusNewUtf8File -Path (Join-Path $workRoot ".nexus-stage-owner") -Content $workId
        $snapshot = @(New-NexusPrimaryStageSnapshot -Context $context -Commit ([string]$validation.source.commit) -StageRoot $workStage)
        [void][IO.Directory]::CreateDirectory($finalUploadRoot)
        New-NexusStoredZip -Entries $snapshot -Destination $finalArchive -Timestamp $timestamp
        New-NexusStoredZip -Entries $snapshot -Destination $secondArchive -Timestamp $timestamp
        $reproducibility = Compare-NexusFilesExact -First $finalArchive -Second $secondArchive
        $archiveEntries = @(Read-NexusValidatedStoredZip -ArchivePath $finalArchive -ExpectedEntries $snapshot -Timestamp $timestamp)
        Expand-NexusValidatedEntries -Entries $archiveEntries -DestinationRoot $extractRoot
        Test-NexusExtractedPrimaryContent -Context $context -ExtractedRoot $extractRoot
        $smoke = Invoke-NexusValidatedGuiSmokeTest -Context $context -Entries $archiveEntries -TimeoutSeconds 30
        $protected = @(Test-NexusProtectedArtifacts -Context $context)

        $archiveHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $finalArchive).Hash.ToUpperInvariant()
        $archiveInfo = Get-Item -LiteralPath $finalArchive -Force
        $entryEvidence = @($archiveEntries | ForEach-Object {
            [pscustomobject][ordered]@{
                path = [string]$_.Path
                bytes = [long]$_.Length
                compressedBytes = [long]$_.CompressedLength
                sha256 = [string]$_.Sha256
                crc32 = $_.Crc32
            }
        })
        $generatedAtUtc = [DateTimeOffset]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", [Globalization.CultureInfo]::InvariantCulture)
        $revalidationTriggers = @(
            "source commit changes",
            "manifest or manifest schema changes",
            "release tooling or archive policy changes",
            "candidate artifact bytes change"
        )
        $sourceFiles = @($snapshot | ForEach-Object {
            [pscustomobject][ordered]@{
                source = [string]$_.Source
                stage = [string]$_.Path
                kind = [string]$_.Kind
                bytes = [long]$_.Length
                sha256 = [string]$_.Sha256
            }
        })
        $archiveEvidence = [pscustomobject][ordered]@{
            filename = $filename
            relativePath = "final-upload/$filename"
            bytes = [long]$archiveInfo.Length
            sha256 = $archiveHash
            entryCount = $entryEvidence.Count
            rootEntries = @(Sort-NexusOrdinalStrings -Values @($primary.archiveRootEntries))
            entries = $entryEvidence
            format = "zip"
            compression = "store"
            entryOrder = "ordinal-stage-path"
            timestampUtc = "2000-01-01T00:00:00Z"
            pathSeparator = "forward-slash"
            entryNameEncoding = "utf-8-ascii-compatible"
            directoryEntries = $false
            archiveComment = $false
            encrypted = $false
            externalAttributes = 0
            zip64 = $false
        }
        $toolchain = [pscustomobject][ordered]@{
            tool = "NexusPackageTools"
            powershellVersion = $PSVersionTable.PSVersion.ToString()
            dotnetVersion = [Environment]::Version.ToString()
            osDescription = [Runtime.InteropServices.RuntimeInformation]::OSDescription
            processArchitecture = [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString()
            zipImplementation = "System.IO.Compression.ZipArchive"
        }
        $sourceEvidence = [pscustomobject][ordered]@{
            schemaVersion = 1
            generatedAtUtc = $generatedAtUtc
            executionClass = $ExecutionClass
            operation = "stage-primary-source"
            result = "pass"
            mutated = $true
            profile = "candidate"
            solutionId = [string]$context.Data.solution.id
            version = [string]$context.Data.release.intendedVersion
            edition = [string]$primary.id
            manifestSha256 = [string]$validation.manifestSha256
            source = $validation.source
            baselineFingerprint = $validation.baselineFingerprint
            technicalFreeze = $validation.technicalFreeze
            protectedArtifacts = $protected
            stagingBytePolicy = "clean-head-git-blob-bytes"
            files = $sourceFiles
            authority = $authority
            revalidationTriggers = $revalidationTriggers
            candidateBuilt = $false
            promoted = $false
            approvedForPublication = $false
            publicationPerformed = $false
        }
        $buildEvidence = [pscustomobject][ordered]@{
            schemaVersion = 1
            generatedAtUtc = $generatedAtUtc
            executionClass = $ExecutionClass
            operation = "build-and-validate-primary-package"
            result = "pass"
            solutionId = [string]$context.Data.solution.id
            version = [string]$context.Data.release.intendedVersion
            edition = [string]$primary.id
            manifestSha256 = [string]$validation.manifestSha256
            sourceCommit = [string]$validation.source.commit
            archive = $archiveEvidence
            reproducibility = $reproducibility
            validation = [pscustomobject][ordered]@{
                stagedGitBlobBytesMatch = $true
                zipContainerMetadataPassed = $true
                archiveInventoryExact = $true
                archiveEntryHashesMatch = $true
                safeExtractionPassed = $true
                extractedDiskReadBackPassed = $true
                extractedContentPassed = $true
                historicalArtifactsMatch = $true
                smokeTest = $smoke
            }
            toolchain = $toolchain
            authority = $authority
            revalidationTriggers = $revalidationTriggers
            candidateBuilt = $true
            promoted = $false
            technicallyReady = $false
            approvedForPublication = $false
            publicationPerformed = $false
            blockedEditions = @($context.Data.editions | Where-Object { [string]$_.state -ceq "blocked" } | ForEach-Object {
                [pscustomobject][ordered]@{ id = [string]$_.id; state = [string]$_.state; publishable = [bool]$_.publishable }
            })
        }
        Write-NexusJsonEvidence -Path $sourceEvidencePath -Value $sourceEvidence
        Write-NexusJsonEvidence -Path $buildEvidencePath -Value $buildEvidence
        $sourceEvidenceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceEvidencePath).Hash.ToUpperInvariant()
        $buildEvidenceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $buildEvidencePath).Hash.ToUpperInvariant()
        $uploadEvidence = [pscustomobject][ordered]@{
            schemaVersion = 1
            generatedAtUtc = $generatedAtUtc
            executionClass = $ExecutionClass
            operation = "promote-primary-to-final-upload"
            result = "pass"
            solutionId = [string]$context.Data.solution.id
            version = [string]$context.Data.release.intendedVersion
            edition = [string]$primary.id
            manifestSha256 = [string]$validation.manifestSha256
            sourceCommit = [string]$validation.source.commit
            sourceEvidenceSha256 = $sourceEvidenceHash
            packageBuildEvidenceSha256 = $buildEvidenceHash
            finalUpload = [pscustomobject][ordered]@{
                relativePath = "final-upload/$filename"
                filename = $filename
                bytes = [long]$archiveInfo.Length
                sha256 = $archiveHash
                inventory = @($filename)
            }
            authority = $authority
            revalidationTriggers = $revalidationTriggers
            temporaryMaterialRemovedBeforePromotion = $true
            candidateBuilt = $true
            promoted = $true
            technicallyReady = $true
            candidateAuthority = ($ExecutionClass -ceq "candidate")
            approvedForPublication = $false
            publicationAuthorized = $false
            publicationPerformed = $false
        }
        Write-NexusJsonEvidence -Path $uploadEvidencePath -Value $uploadEvidence
        $uploadEvidenceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $uploadEvidencePath).Hash.ToUpperInvariant()
        $prepareEvidence = [pscustomobject][ordered]@{
            sourceStage = $sourceEvidence
            packageBuild = $buildEvidence
            finalUpload = $uploadEvidence
        }

        Remove-NexusPrepareTemporaryMaterial -WorkRoot $workRoot
        $expectedPayloadFiles = @($snapshot | ForEach-Object { "candidate/primary-tree/$($_.Path)" }) + @(
            $sourceEvidenceRelative,
            $buildEvidenceRelative,
            $uploadEvidenceRelative,
            "final-upload/$filename"
        )
        $expectedPayloadDirectories = @(Get-NexusExpectedDirectories -Files $expectedPayloadFiles)
        $payloadItems = @(Get-ChildItem -LiteralPath $workVersion -Force -Recurse)
        if (@($payloadItems | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -ne 0) {
            Throw-NexusPackageError -Id "PREPARE-REPARSE" -Message "The prepared version payload contains a reparse point."
        }
        $actualPayloadFiles = @($payloadItems | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
            [IO.Path]::GetRelativePath($workVersion, $_.FullName).Replace("\", "/")
        })
        $actualPayloadDirectories = @($payloadItems | Where-Object { $_.PSIsContainer } | ForEach-Object {
            [IO.Path]::GetRelativePath($workVersion, $_.FullName).Replace("\", "/")
        })
        Assert-NexusExactStringList -Actual $actualPayloadFiles -Expected $expectedPayloadFiles -Id "PREPARE-INVENTORY" -Message "Prepared version file inventory is not exact."
        Assert-NexusExactStringList -Actual $actualPayloadDirectories -Expected $expectedPayloadDirectories -Id "PREPARE-INVENTORY" -Message "Prepared version directory inventory is not exact."
        $uploadFiles = @(Get-ChildItem -LiteralPath $finalUploadRoot -Force -File)
        if ($uploadFiles.Count -ne 1 -or $uploadFiles[0].Name -cne $filename) {
            Throw-NexusPackageError -Id "FINAL-UPLOAD" -Message "Final upload must contain exactly the manifest-named primary ZIP."
        }
        foreach ($item in $snapshot) {
            $stagedPath = Resolve-NexusContainedPath -Root $workStage -RelativePath ([string]$item.Path) -RequireFile
            $stagedInfo = Get-Item -LiteralPath $stagedPath -Force
            $stagedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $stagedPath).Hash.ToUpperInvariant()
            if ([long]$stagedInfo.Length -ne [long]$item.Length -or $stagedHash -cne [string]$item.Sha256) {
                Throw-NexusPackageError -Id "PREPARE-BYTES" -Message "Prepared source bytes changed before atomic promotion: $($item.Path)"
            }
        }
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $finalArchive).Hash.ToUpperInvariant() -cne $archiveHash -or
            (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceEvidencePath).Hash.ToUpperInvariant() -cne $sourceEvidenceHash -or
            (Get-FileHash -Algorithm SHA256 -LiteralPath $buildEvidencePath).Hash.ToUpperInvariant() -cne $buildEvidenceHash -or
            (Get-FileHash -Algorithm SHA256 -LiteralPath $uploadEvidencePath).Hash.ToUpperInvariant() -cne $uploadEvidenceHash) {
            Throw-NexusPackageError -Id "PREPARE-BYTES" -Message "Prepared archive or evidence bytes changed before atomic promotion."
        }

        $headNow = (Invoke-NexusGit -RepositoryRoot $context.RepositoryRoot -Arguments @("rev-parse", "HEAD")).Output[0]
        $branchNowResult = Invoke-NexusGit -RepositoryRoot $context.RepositoryRoot -Arguments @("branch", "--show-current")
        $branchNow = if ($branchNowResult.Output.Count -eq 0) { "" } else { [string]$branchNowResult.Output[0] }
        $statusNow = Invoke-NexusGit -RepositoryRoot $context.RepositoryRoot -Arguments @("status", "--porcelain=v1", "--untracked-files=normal")
        $manifestHashNow = (Get-FileHash -Algorithm SHA256 -LiteralPath $context.ManifestPath).Hash.ToUpperInvariant()
        if ($headNow -cne [string]$validation.source.commit -or $branchNow -cne [string]$validation.source.branch -or
            $statusNow.Output.Count -ne 0 -or $manifestHashNow -cne [string]$validation.manifestSha256) {
            Throw-NexusPackageError -Id "SOURCE-CHANGED" -Message "Source identity changed during primary preparation."
        }
        [void](Test-NexusProtectedArtifacts -Context $context)
        $versionRoot = Resolve-NexusContainedPath -Root $context.RepositoryRoot -RelativePath $versionRootRelative
        if (Test-Path -LiteralPath $versionRoot) {
            Throw-NexusPackageError -Id "OVERWRITE" -Message "The versioned release root appeared during preparation."
        }
        [IO.Directory]::Move($workVersion, $versionRoot)

        return [pscustomobject]@{
            Evidence = $prepareEvidence
            ExecutionClass = $ExecutionClass
            VersionRoot = $versionRootRelative
            StagePath = "$versionRootRelative/candidate/primary-tree"
            EvidencePaths = [pscustomobject][ordered]@{
                SourceStage = "$versionRootRelative/$sourceEvidenceRelative"
                PackageBuild = "$versionRootRelative/$buildEvidenceRelative"
                FinalUpload = "$versionRootRelative/$uploadEvidenceRelative"
            }
            FinalUploadPath = "$versionRootRelative/final-upload/$filename"
        }
    }
    finally {
        try {
            Remove-NexusOwnedWorkRoot -Context $context -RelativePath $workRootRelative -WorkId $workId -Kind prepare
        }
        catch {
            Write-Warning "Owned preparation work could not be cleaned automatically: $($_.Exception.Message)"
        }
    }
}

Export-ModuleMember -Function @(
    "Read-NexusManifest",
    "Assert-NexusManifestContract",
    "Test-NexusBaselineFingerprint",
    "Test-NexusTechnicalFreeze",
    "Test-NexusProtectedArtifacts",
    "Get-NexusPrimaryInventory",
    "Test-NexusVersionAndContent",
    "Test-NexusReleaseSource",
    "Get-NexusPrimaryStagePath",
    "New-NexusPrimaryStage",
    "New-NexusPreparedPrimary"
)
