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
    if ($Path.IndexOfAny([char[]](0..31)) -ge 0) {
        Throw-NexusPackageError -Id "PATH" -Message "$Field contains a control character."
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
    try {
        Assert-NoDuplicateJsonProperties -Element $document.RootElement
    }
    finally {
        $document.Dispose()
    }

    $data = $json | ConvertFrom-Json -Depth 100
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

    return @($Mappings | ForEach-Object { ([string]$_.stage).Split("/")[0] } | Sort-Object -Unique)
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

    $actualStrings = @($Actual | ForEach-Object { [string]$_ } | Sort-Object)
    $expectedStrings = @($Expected | Sort-Object)
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
    return @($directories | Sort-Object)
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

function Assert-NexusManifestContract {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context
    )

    $manifest = $Context.Data
    $approved = Get-NexusApprovedP2Contract

    foreach ($property in $approved.Solution.Keys) {
        if ([string]$manifest.solution.$property -cne [string]$approved.Solution[$property]) {
            Throw-NexusPackageError -Id "IDENTITY" -Message "Development solution identity differs from the owner-approved P2 contract: $property"
        }
    }
    foreach ($property in $approved.Release.Keys) {
        if ([string]$manifest.release.$property -cne [string]$approved.Release[$property]) {
            Throw-NexusPackageError -Id "RELEASE-STATE" -Message "Development release state differs from the owner-approved P2 contract: $property"
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

    $version = [string]$manifest.release.intendedVersion
    if ([string]$manifest.release.workspaceVersion -cne "$version-dev") {
        Throw-NexusPackageError -Id "VERSION" -Message "workspaceVersion must equal intendedVersion plus -dev."
    }
    if ([string]$manifest.solution.runtimeModId -cne [string]$manifest.solution.installedFolder) {
        Throw-NexusPackageError -Id "MOD-ID" -Message "Runtime mod ID and installed folder must remain identical for this release."
    }
    if ([string]$manifest.technicalFreeze.baselineCommit -cne [string]$manifest.lineage.sourceBaseline.commit) {
        Throw-NexusPackageError -Id "FREEZE" -Message "Technical-freeze and lineage baseline commits must agree."
    }
    if ([bool]$manifest.release.approvedForPublication -or $null -ne $manifest.release.releaseSourceCommit -or $null -ne $manifest.release.releaseTag -or $null -ne $manifest.release.approvalRecord) {
        Throw-NexusPackageError -Id "AUTHORITY" -Message "Development manifest must not claim a release commit, tag, or publication approval."
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

    $actualSurfaces = @($manifest.versionSurfaces | ForEach-Object {
        $candidate = if ($null -eq $_.candidateValue) { "<null>" } else { [string]$_.candidateValue }
        "$($_.type)|$($_.scope)|$($_.path)|$($_.developmentValue)|$candidate"
    })
    Assert-NexusExactStringList -Actual $actualSurfaces -Expected $approved.VersionSurfaces -Id "VERSION-SURFACE" -Message "Version surfaces differ from the exact P2 projection set."

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
    if ([bool]$primary[0].publishable -or [string]$primary[0].state -cne "development") {
        Throw-NexusPackageError -Id "PRIMARY" -Message "The primary edition must remain non-publishable Development work during P2."
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

    $declaredRoots = @($primary[0].archiveRootEntries | Sort-Object)
    $derivedRoots = @(Get-NexusTopLevelEntries -Mappings $mappings)
    if (($declaredRoots -join "`n") -cne ($derivedRoots -join "`n")) {
        Throw-NexusPackageError -Id "ROOT-SHAPE" -Message "Declared and derived primary archive roots differ."
    }
    $expectedRoots = @("7DTD_WastelandAnimalTuning.bat", "README_FIRST.txt", "Support_Files_Do_Not_Edit") | Sort-Object
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

    foreach ($path in @($policy.unchangedPaths | Sort-Object)) {
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

    foreach ($projection in @($policy.metadataProjections | Sort-Object path)) {
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

    return @($results | Sort-Object path)
}

function Test-NexusProtectedArtifacts {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context
    )

    $results = @()
    foreach ($artifact in @($Context.Data.protectedArtifacts | Sort-Object path)) {
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
    foreach ($mapping in @($primary.sourceToStage | Sort-Object stage)) {
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
    return @($inventory | Sort-Object stage)
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

        [ValidateSet("Development")]
        [string]$Profile = "Development"
    )

    $manifest = $Context.Data
    $version = [string]$manifest.release.intendedVersion
    foreach ($surface in @($manifest.versionSurfaces)) {
        $root = if ([string]$surface.scope -ceq "repository") { $Context.RepositoryRoot } else { $Context.SolutionRoot }
        $full = Resolve-NexusContainedPath -Root $root -RelativePath ([string]$surface.path) -RequireFile
        $expected = [string]$surface.developmentValue
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

        [ValidateSet("Development")]
        [string]$Profile = "Development"
    )

    $context = Read-NexusManifest -ManifestPath $ManifestPath
    Assert-NexusManifestContract -Context $context
    $baselineFingerprint = Test-NexusBaselineFingerprint -Context $context
    $technicalFreeze = @(Test-NexusTechnicalFreeze -Context $context)
    $protected = @(Test-NexusProtectedArtifacts -Context $context)
    $inventory = @(Get-NexusPrimaryInventory -Context $context)
    Test-NexusVersionAndContent -Context $context -Profile $Profile

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
        profile = $Profile.ToLowerInvariant()
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
        [string]$WorkId
    )

    $full = Resolve-NexusContainedPath -Root $Context.RepositoryRoot -RelativePath $RelativePath
    if (-not (Test-Path -LiteralPath $full)) {
        return
    }
    $expectedSuffix = "/.nexus-stage-work-$WorkId"
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

    $evidence = Test-NexusReleaseSource -ManifestPath $ManifestPath -Profile Development
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
    $expectedStageFiles = @($primary.sourceToStage | ForEach-Object { [string]$_.stage } | Sort-Object)

    try {
        [void][IO.Directory]::CreateDirectory($workRoot)
        Write-NexusNewUtf8File -Path (Join-Path $workRoot ".nexus-stage-owner") -Content $workId
        [void][IO.Directory]::CreateDirectory($workStage)

        foreach ($mapping in @($primary.sourceToStage | Sort-Object stage)) {
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

        $actualStageFiles = @(Get-ChildItem -LiteralPath $workStage -Recurse -File | ForEach-Object {
            [IO.Path]::GetRelativePath($workStage, $_.FullName).Replace("\", "/")
        } | Sort-Object)
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
        $actualPayloadFiles = @($payloadItems | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
            [IO.Path]::GetRelativePath($workVersion, $_.FullName).Replace("\", "/")
        } | Sort-Object)
        $actualPayloadDirectories = @($payloadItems | Where-Object { $_.PSIsContainer } | ForEach-Object {
            [IO.Path]::GetRelativePath($workVersion, $_.FullName).Replace("\", "/")
        } | Sort-Object)
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
    "New-NexusPrimaryStage"
)
