[CmdletBinding()]
param(
    [string]$ManifestPath = "solutions/7dtd_wasteland_animal_population_tuning_files/release-manifest.json",

    [switch]$SkipDisposableStage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$manifestFull = [IO.Path]::GetFullPath((Join-Path $repositoryRoot $ManifestPath))
$modulePath = Join-Path $repositoryRoot "tools/release/NexusPackageTools.psm1"
$entryPoint = Join-Path $repositoryRoot "tools/release/Invoke-NexusPackage.ps1"
Import-Module $modulePath -Force

$script:Passed = 0
$script:Failed = 0

function Invoke-OfflineCheck {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    try {
        & $Action
        Write-Host "PASS: $Name"
        $script:Passed++
    }
    catch {
        Write-Host "FAIL: $Name"
        Write-Host "  $($_.Exception.Message)"
        if ($env:GITHUB_ACTIONS -ceq "true") {
            $title = $Name.Replace("%", "%25").Replace(":", "%3A").Replace(",", "%2C").Replace("`r", "%0D").Replace("`n", "%0A")
            $message = $_.Exception.Message.Replace("%", "%25").Replace("`r", "%0D").Replace("`n", "%0A")
            Write-Host "::error title=$title::$message"
        }
        $script:Failed++
    }
}

function Assert-ExpectedFailure {
    param(
        [Parameter(Mandatory)]
        [string]$ExpectedId,

        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    $caught = $null
    try {
        & $Action
    }
    catch {
        $caught = $_
    }

    if ($null -eq $caught) {
        throw "Expected failure $ExpectedId, but the action passed."
    }
    if (-not $caught.Exception.Message.Contains($ExpectedId, [StringComparison]::Ordinal)) {
        throw "Expected failure $ExpectedId, got: $($caught.Exception.Message)"
    }
}

function Copy-NexusContext {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Context
    )

    $data = $Context.Data | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
    return [pscustomobject]@{
        Data = $data
        Json = $Context.Json
        ManifestPath = $Context.ManifestPath
        RepositoryRoot = $Context.RepositoryRoot
        SolutionRoot = $Context.SolutionRoot
        SchemaPath = $Context.SchemaPath
    }
}

function Get-OfflineGitBlobSha256 {
    param(
        [Parameter(Mandatory)]
        [string]$Repository,

        [Parameter(Mandatory)]
        [string]$Commit,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $objectId = @(& git -C $Repository rev-parse "$Commit`:$Path")[0]
    if ($LASTEXITCODE -ne 0 -or $objectId -notmatch '^[A-Fa-f0-9]{40}$') {
        throw "Could not resolve a raw Git blob for $Path"
    }
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = "git"
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @("-C", $Repository, "cat-file", "blob", $objectId)) {
        [void]$startInfo.ArgumentList.Add($argument)
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $algorithm = [Security.Cryptography.SHA256]::Create()
    $started = $false
    try {
        [void]$process.Start()
        $started = $true
        $hash = [Convert]::ToHexString($algorithm.ComputeHash($process.StandardOutput.BaseStream))
        $errorText = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "Could not hash a raw Git blob for $Path. $errorText"
        }
        return $hash
    }
    finally {
        $algorithm.Dispose()
        if ($started -and -not $process.HasExited) {
            $process.Kill($true)
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Get-OfflineExpectedDirectories {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Files
    )

    $directories = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($file in $Files) {
        $segments = $file.Split("/")
        for ($length = 1; $length -lt $segments.Count; $length++) {
            [void]$directories.Add(($segments[0..($length - 1)] -join "/"))
        }
    }
    return @($directories | Sort-Object)
}

$context = $null

Invoke-OfflineCheck -Name "Manifest parses and passes JSON Schema" -Action {
    $script:context = Read-NexusManifest -ManifestPath $manifestFull
}

Invoke-OfflineCheck -Name "Manifest and schema reject duplicate or case-colliding properties" -Action {
    $files = @($manifestFull, (Join-Path $repositoryRoot "governance/schemas/solution-release-manifest.schema.json"))
    $module = Get-Module NexusPackageTools
    foreach ($file in $files) {
        $json = [IO.File]::ReadAllText($file, [Text.UTF8Encoding]::new($false, $true))
        $document = [System.Text.Json.JsonDocument]::Parse($json)
        try {
            & $module { param($Element) Assert-NoDuplicateJsonProperties -Element $Element } $document.RootElement
        }
        finally {
            $document.Dispose()
        }
    }
}

Invoke-OfflineCheck -Name "Manifest semantic contract passes" -Action {
    Assert-NexusManifestContract -Context $script:context
}

Invoke-OfflineCheck -Name "Raw 32-file baseline fingerprint matches" -Action {
    $result = Test-NexusBaselineFingerprint -Context $script:context
    if ($result.fileCount -ne 32 -or $result.status -cne "match") {
        throw "Unexpected baseline result."
    }
}

Invoke-OfflineCheck -Name "Frozen technical behavior differs only by approved metadata" -Action {
    $result = @(Test-NexusTechnicalFreeze -Context $script:context)
    if ($result.Count -ne 6) {
        throw "Unexpected technical-freeze result count."
    }
}

Invoke-OfflineCheck -Name "Historical artifact hashes match" -Action {
    $result = @(Test-NexusProtectedArtifacts -Context $script:context)
    if ($result.Count -ne 3 -or @($result | Where-Object status -cne "match").Count -ne 0) {
        throw "Unexpected historical artifact result."
    }
}

Invoke-OfflineCheck -Name "Primary source, versions, XML, scripts, docs, and allowlist pass" -Action {
    $result = Test-NexusReleaseSource -ManifestPath $manifestFull -Profile Development
    if ($result.result -cne "pass" -or @($result.files).Count -ne 8 -or $result.candidateBuilt) {
        throw "Unexpected release-source validation result."
    }
}

Invoke-OfflineCheck -Name "Duplicate or case-colliding JSON property is rejected" -Action {
    $json = [IO.File]::ReadAllText($manifestFull, [Text.UTF8Encoding]::new($false, $true))
    $duplicate = $json.Replace('"schemaVersion": 1,', '"schemaVersion": 1, "SchemaVersion": 1,')
    $document = [System.Text.Json.JsonDocument]::Parse($duplicate)
    try {
        Assert-ExpectedFailure -ExpectedId "BW-PKG-JSON-DUPLICATE" -Action {
            & (Get-Module NexusPackageTools) { param($Element) Assert-NoDuplicateJsonProperties -Element $Element } $document.RootElement
        }
    }
    finally {
        $document.Dispose()
    }
}

Invoke-OfflineCheck -Name "Traversal in a stage path is rejected" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $primary = @($testContext.Data.editions | Where-Object role -eq "primary")[0]
    $primary.sourceToStage[0].stage = "../outside.txt"
    Assert-ExpectedFailure -ExpectedId "BW-PKG-PATH" -Action {
        Assert-NexusManifestContract -Context $testContext
    }
}

Invoke-OfflineCheck -Name "Missing primary allowlist entry is rejected" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $primary = @($testContext.Data.editions | Where-Object role -eq "primary")[0]
    $primary.sourceToStage = @($primary.sourceToStage | Select-Object -First 7)
    Assert-ExpectedFailure -ExpectedId "BW-PKG-ALLOWLIST" -Action {
        Assert-NexusManifestContract -Context $testContext
    }
}

Invoke-OfflineCheck -Name "Blocked edition cannot become publishable" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $blocked = @($testContext.Data.editions | Where-Object state -eq "blocked")[0]
    $blocked.publishable = $true
    Assert-ExpectedFailure -ExpectedId "BW-PKG-BLOCKED" -Action {
        Assert-NexusManifestContract -Context $testContext
    }
}

Invoke-OfflineCheck -Name "Development manifest cannot claim public supported state" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $testContext.Data.release.channel = "public"
    $testContext.Data.release.lifecycle = "supported"
    $testContext.Data.release.publicationState = "published"
    Assert-ExpectedFailure -ExpectedId "BW-PKG-RELEASE-STATE" -Action {
        Assert-NexusManifestContract -Context $testContext
    }
}

Invoke-OfflineCheck -Name "Exact primary and blocked edition set is required" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $testContext.Data.editions = @($testContext.Data.editions | Where-Object id -eq "windows-gui")
    Assert-ExpectedFailure -ExpectedId "BW-PKG-EDITION" -Action {
        Assert-NexusManifestContract -Context $testContext
    }
}

Invoke-OfflineCheck -Name "Primary allowlist rejects a source substitution" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $primary = @($testContext.Data.editions | Where-Object id -eq "windows-gui")[0]
    $mapping = @($primary.sourceToStage | Where-Object stage -eq "Support_Files_Do_Not_Edit/CHANGELOG.md")[0]
    $mapping.source = "Support_Files_Do_Not_Edit/LEGAL_AND_USE.md"
    Assert-ExpectedFailure -ExpectedId "BW-PKG-ALLOWLIST" -Action {
        Assert-NexusManifestContract -Context $testContext
    }
}

Invoke-OfflineCheck -Name "Blocked edition cannot claim an invented artifact hash" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $blocked = @($testContext.Data.editions | Where-Object id -eq "no-scripts")[0]
    $blocked.sha256 = "0" * 64
    Assert-ExpectedFailure -ExpectedId "BW-PKG-EDITION-HASH" -Action {
        Assert-NexusManifestContract -Context $testContext
    }
}

Invoke-OfflineCheck -Name "Historical protection registry cannot be redirected" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $testContext.Data.protectedArtifacts[0].path = "README.md"
    $testContext.Data.protectedArtifacts[0].sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $repositoryRoot "README.md")).Hash
    Assert-ExpectedFailure -ExpectedId "BW-PKG-HISTORICAL-REGISTRY" -Action {
        Assert-NexusManifestContract -Context $testContext
    }
}

Invoke-OfflineCheck -Name "Exact version-surface set is required" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $testContext.Data.versionSurfaces[0].path = "README.md"
    Assert-ExpectedFailure -ExpectedId "BW-PKG-VERSION-SURFACE" -Action {
        Assert-NexusManifestContract -Context $testContext
    }
}

Invoke-OfflineCheck -Name "Changed expected historical hash is rejected without touching the ZIP" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $testContext.Data.protectedArtifacts[0].sha256 = (("0" * 64) -join "")
    Assert-ExpectedFailure -ExpectedId "BW-PKG-HISTORICAL-HASH" -Action {
        [void](Test-NexusProtectedArtifacts -Context $testContext)
    }
}

Invoke-OfflineCheck -Name "Unexpected technical-file change is detected" -Action {
    $testContext = Copy-NexusContext -Context $script:context
    $testContext.Data.technicalFreeze.unchangedPaths = @("README_FIRST.txt")
    $testContext.Data.technicalFreeze.metadataProjections = @()
    Assert-ExpectedFailure -ExpectedId "BW-PKG-TECHNICAL-FREEZE" -Action {
        [void](Test-NexusTechnicalFreeze -Context $testContext)
    }
}

Invoke-OfflineCheck -Name "Every tracked PowerShell file parses without execution" -Action {
    $paths = @(& git -C $repositoryRoot ls-files "*.ps1" "*.psm1" "*.psd1")
    if ($LASTEXITCODE -ne 0 -or $paths.Count -eq 0) {
        throw "Could not enumerate PowerShell files."
    }
    foreach ($path in $paths) {
        $tokens = $null
        $errors = $null
        [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $repositoryRoot $path), [ref]$tokens, [ref]$errors)
        if (@($errors).Count -gt 0) {
            throw "PowerShell parser error in $path"
        }
    }
}

Invoke-OfflineCheck -Name "Every tracked XML file parses with DTDs prohibited" -Action {
    $paths = @(& git -C $repositoryRoot ls-files "*.xml")
    if ($LASTEXITCODE -ne 0 -or $paths.Count -eq 0) {
        throw "Could not enumerate XML files."
    }
    foreach ($path in $paths) {
        $settings = [Xml.XmlReaderSettings]::new()
        $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver = $null
        $reader = [Xml.XmlReader]::Create((Join-Path $repositoryRoot $path), $settings)
        try {
            while ($reader.Read()) { }
        }
        finally {
            $reader.Dispose()
        }
    }
}

Invoke-OfflineCheck -Name "Tracked files obey the canonical LF/binary attribute policy" -Action {
    $lines = @(& git -C $repositoryRoot ls-files --eol)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not inspect Git line-ending policy."
    }
    $bad = @($lines | Where-Object { $_ -match '^(i|w)/crlf' -or $_ -match '\s(i|w)/crlf' })
    if ($bad.Count -gt 0) {
        throw "Tracked text contains CRLF contrary to repository policy."
    }
}

Invoke-OfflineCheck -Name "StagePrimary WhatIf creates no stage" -Action {
    $target = Join-Path $repositoryRoot "dist/7dtd_wasteland_animal_population_tuning/4.1.0/candidate/primary-tree"
    $before = Test-Path -LiteralPath $target
    if ($before) {
        throw "Test requires the candidate source stage to be absent."
    }
    & $entryPoint -ManifestPath $manifestFull -Action StagePrimary -WhatIf | Out-Null
    if (Test-Path -LiteralPath $target) {
        throw "WhatIf created the stage."
    }
}

if (-not $SkipDisposableStage) {
    Invoke-OfflineCheck -Name "Actual staging is exact and isolated in a disposable clone" -Action {
        $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
        $tempRoot = Join-Path $tempBase ("nexus-offline-stage-" + [guid]::NewGuid().ToString("N"))
        $cloneRoot = Join-Path $tempRoot "repository"
        try {
            [void][IO.Directory]::CreateDirectory($tempRoot)
            & git clone --quiet --no-hardlinks --no-checkout $repositoryRoot $cloneRoot
            if ($LASTEXITCODE -ne 0) {
                throw "Could not create the disposable local clone."
            }
            $head = @(& git -C $repositoryRoot rev-parse HEAD)[0]
            & git -C $cloneRoot checkout --quiet --detach $head
            if ($LASTEXITCODE -ne 0) {
                throw "Could not check out the test source commit."
            }
            $cloneManifest = Join-Path $cloneRoot $ManifestPath
            $cloneEntryPoint = Join-Path $cloneRoot "tools/release/Invoke-NexusPackage.ps1"
            $detachedValidation = & $cloneEntryPoint -ManifestPath $cloneManifest -Action Validate -PassThru
            if ($detachedValidation.result -cne "pass" -or [string]$detachedValidation.source.branch -cne "") {
                throw "Detached-HEAD validation did not return a bounded empty branch."
            }
            Assert-ExpectedFailure -ExpectedId "BW-PKG-BRANCH" -Action {
                & $cloneEntryPoint -ManifestPath $cloneManifest -Action StagePrimary -Confirm:$false -PassThru | Out-Null
            }
            & git -C $cloneRoot switch --quiet -C develop/4.1.0 $head
            if ($LASTEXITCODE -ne 0) {
                throw "Could not create the disposable development branch."
            }

            $distRoot = Join-Path $cloneRoot "dist"
            $outside = Join-Path $tempRoot "junction-target"
            [void][IO.Directory]::CreateDirectory($outside)
            [void](New-Item -ItemType Junction -Path $distRoot -Target $outside)
            try {
                Assert-ExpectedFailure -ExpectedId "BW-PKG-REPARSE" -Action {
                    & $cloneEntryPoint -ManifestPath $cloneManifest -Action StagePrimary -Confirm:$false -PassThru | Out-Null
                }
                if (@(Get-ChildItem -LiteralPath $outside -Force).Count -ne 0) {
                    throw "Reparse-path rejection wrote outside the disposable repository."
                }
            }
            finally {
                if (Test-Path -LiteralPath $distRoot) {
                    [IO.Directory]::Delete($distRoot)
                }
            }

            [IO.File]::AppendAllText((Join-Path $cloneRoot "README.md"), "dirty")
            Assert-ExpectedFailure -ExpectedId "BW-PKG-DIRTY" -Action {
                & $cloneEntryPoint -ManifestPath $cloneManifest -Action StagePrimary -Confirm:$false -PassThru | Out-Null
            }
            & git -C $cloneRoot restore --worktree -- README.md
            if ($LASTEXITCODE -ne 0) {
                throw "Could not restore the disposable dirty-tree fixture."
            }

            $preexistingEvidence = Join-Path $cloneRoot "dist/7dtd_wasteland_animal_population_tuning/4.1.0/evidence/primary-source-stage.json"
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $preexistingEvidence))
            [IO.File]::WriteAllText($preexistingEvidence, "preexisting")
            Assert-ExpectedFailure -ExpectedId "BW-PKG-OVERWRITE" -Action {
                & $cloneEntryPoint -ManifestPath $cloneManifest -Action StagePrimary -Confirm:$false -PassThru | Out-Null
            }
            $versionDist = Join-Path $cloneRoot "dist/7dtd_wasteland_animal_population_tuning/4.1.0"
            if (-not ([IO.Path]::GetFullPath($versionDist)).StartsWith(([IO.Path]::GetFullPath($cloneRoot) + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) {
                throw "Disposable cleanup path escaped its clone."
            }
            [IO.Directory]::Delete($versionDist, $true)

            $manifestData = Get-Content -Raw $cloneManifest | ConvertFrom-Json -Depth 100
            $historicalBefore = @{}
            foreach ($artifact in @($manifestData.protectedArtifacts)) {
                $historicalBefore[[string]$artifact.path] = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $cloneRoot ([string]$artifact.path))).Hash
            }

            $stageResult = & $cloneEntryPoint -ManifestPath $cloneManifest -Action StagePrimary -Confirm:$false -PassThru
            if ($stageResult.Evidence.operation -cne "stage-primary" -or -not $stageResult.Evidence.mutated -or $stageResult.Evidence.candidateBuilt) {
                throw "Actual staging returned an unexpected evidence state."
            }
            $stageRoot = Join-Path $cloneRoot ([string]$stageResult.StagePath)
            $expectedFiles = @($manifestData.editions | Where-Object id -eq "windows-gui" | Select-Object -ExpandProperty sourceToStage | ForEach-Object { [string]$_.stage } | Sort-Object)
            $actualFiles = @(Get-ChildItem -LiteralPath $stageRoot -Recurse -File | ForEach-Object {
                [IO.Path]::GetRelativePath($stageRoot, $_.FullName).Replace("\", "/")
            } | Sort-Object)
            if (($actualFiles -join "`n") -cne ($expectedFiles -join "`n")) {
                throw "Disposable stage inventory differs from the manifest."
            }
            foreach ($mapping in @($manifestData.editions | Where-Object id -eq "windows-gui" | Select-Object -ExpandProperty sourceToStage)) {
                $repositoryRelative = "$($manifestData.solution.sourceRoot)/$($mapping.source)"
                $sourceHash = Get-OfflineGitBlobSha256 -Repository $cloneRoot -Commit $head -Path $repositoryRelative
                $stageHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $stageRoot ([string]$mapping.stage))).Hash
                if ($sourceHash -cne $stageHash) {
                    throw "Disposable staged bytes differ from raw clean-HEAD Git blob bytes: $($mapping.stage)"
                }
            }
            $evidenceFile = Join-Path $cloneRoot ([string]$stageResult.EvidencePath)
            if (-not (Test-Path -LiteralPath $evidenceFile -PathType Leaf)) {
                throw "Disposable staging did not create its evidence record."
            }
            $evidenceData = Get-Content -Raw $evidenceFile | ConvertFrom-Json -Depth 100
            if ([string]$evidenceData.operation -cne "stage-primary" -or -not [bool]$evidenceData.mutated -or
                [string]$evidenceData.source.commit -cne $head -or [bool]$evidenceData.candidateBuilt -or
                [bool]$evidenceData.promoted -or [string]$evidenceData.ownerApproval -cne "not-recorded" -or
                @($evidenceData.files).Count -ne 8) {
                throw "Disposable staging evidence is incomplete or inconsistent."
            }
            foreach ($file in @($evidenceData.files)) {
                $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $stageRoot ([string]$file.stage))).Hash
                if ($actualHash -cne [string]$file.sha256) {
                    throw "Disposable staging evidence hash differs from staged bytes: $($file.stage)"
                }
            }
            $versionRoot = Join-Path $cloneRoot "dist/7dtd_wasteland_animal_population_tuning/4.1.0"
            $versionEntries = @(Get-ChildItem -LiteralPath $versionRoot -Force | ForEach-Object { $_.Name } | Sort-Object)
            if (($versionEntries -join "`n") -cne ((@("candidate", "evidence") | Sort-Object) -join "`n") -or
                @(Get-ChildItem -LiteralPath $versionRoot -Recurse -File -Include "*.zip", "*.7z", "*.rar").Count -ne 0) {
                throw "Disposable version root contains an unexpected output or archive."
            }
            $expectedVersionFiles = @($expectedFiles | ForEach-Object { "candidate/primary-tree/$_" }) + @("evidence/primary-source-stage.json")
            $expectedVersionDirectories = @(Get-OfflineExpectedDirectories -Files $expectedVersionFiles)
            $versionItems = @(Get-ChildItem -LiteralPath $versionRoot -Force -Recurse)
            if (@($versionItems | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -ne 0) {
                throw "Disposable version root contains a reparse point."
            }
            $actualVersionFiles = @($versionItems | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
                [IO.Path]::GetRelativePath($versionRoot, $_.FullName).Replace("\", "/")
            } | Sort-Object)
            $actualVersionDirectories = @($versionItems | Where-Object { $_.PSIsContainer } | ForEach-Object {
                [IO.Path]::GetRelativePath($versionRoot, $_.FullName).Replace("\", "/")
            } | Sort-Object)
            if (($actualVersionFiles -join "`n") -cne (($expectedVersionFiles | Sort-Object) -join "`n") -or
                ($actualVersionDirectories -join "`n") -cne (($expectedVersionDirectories | Sort-Object) -join "`n")) {
                throw "Disposable version root file/directory inventory is not exact."
            }
            $solutionDist = Join-Path $cloneRoot "dist/7dtd_wasteland_animal_population_tuning"
            if (@(Get-ChildItem -LiteralPath $solutionDist -Recurse -Filter ".nexus-stage-work-*" -Directory -Force).Count -ne 0) {
                throw "Disposable staging left owned work debris."
            }
            foreach ($artifact in @($manifestData.protectedArtifacts)) {
                $after = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $cloneRoot ([string]$artifact.path))).Hash
                if ($after -cne $historicalBefore[[string]$artifact.path]) {
                    throw "Disposable staging changed a historical artifact."
                }
            }
            $versionHashesBeforeRerun = @{}
            foreach ($file in @(Get-ChildItem -LiteralPath $versionRoot -Recurse -File)) {
                $relative = [IO.Path]::GetRelativePath($versionRoot, $file.FullName)
                $versionHashesBeforeRerun[$relative] = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
            }
            Assert-ExpectedFailure -ExpectedId "BW-PKG-OVERWRITE" -Action {
                & $cloneEntryPoint -ManifestPath $cloneManifest -Action StagePrimary -Confirm:$false -PassThru | Out-Null
            }
            $versionHashesAfterRerun = @{}
            foreach ($file in @(Get-ChildItem -LiteralPath $versionRoot -Recurse -File)) {
                $relative = [IO.Path]::GetRelativePath($versionRoot, $file.FullName)
                $versionHashesAfterRerun[$relative] = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
            }
            if ($versionHashesAfterRerun.Count -ne $versionHashesBeforeRerun.Count -or
                (($versionHashesAfterRerun.Keys | Sort-Object) -join "`n") -cne (($versionHashesBeforeRerun.Keys | Sort-Object) -join "`n")) {
                throw "Failed rerun changed the disposable version file set."
            }
            foreach ($relative in $versionHashesBeforeRerun.Keys) {
                if ($versionHashesAfterRerun[$relative] -cne $versionHashesBeforeRerun[$relative]) {
                    throw "Failed rerun changed disposable version bytes: $relative"
                }
            }
        }
        finally {
            $resolvedTemp = [IO.Path]::GetFullPath($tempRoot)
            $requiredPrefix = $tempBase + [IO.Path]::DirectorySeparatorChar + "nexus-offline-stage-"
            if (Test-Path -LiteralPath $resolvedTemp) {
                if (-not $resolvedTemp.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Refusing to clean a disposable path outside the expected temp namespace."
                }
                [IO.Directory]::Delete($resolvedTemp, $true)
            }
            Import-Module $modulePath -Force
        }
    }
}

Invoke-OfflineCheck -Name "Legacy RebuildZip fails closed before mutation" -Action {
    $legacy = Join-Path $repositoryRoot "solutions/7dtd_wasteland_animal_population_tuning_files/Support_Files_Do_Not_Edit/validate_and_package.ps1"
    $output = @(& powershell.exe -NoProfile -File $legacy -RebuildZip 2>&1)
    if ($LASTEXITCODE -eq 0) {
        throw "Legacy RebuildZip unexpectedly succeeded."
    }
    if (-not ((@($output | ForEach-Object { "$_" }) -join " ").Contains("Legacy -RebuildZip is disabled", [StringComparison]::Ordinal))) {
        throw "Legacy RebuildZip did not fail with the expected guard."
    }
}

Write-Host ""
Write-Host "Offline checks: $script:Passed passed, $script:Failed failed"
if ($script:Failed -ne 0) {
    exit 1
}
