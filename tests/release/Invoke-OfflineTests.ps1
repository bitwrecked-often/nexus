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
    $data.distribution.archiveTimestampUtc = [string]$Context.Data.distribution.archiveTimestampUtc
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

function Get-OfflineTreeState {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @("<absent>")
    }
    $root = [IO.Path]::GetFullPath($Path)
    $state = @("D|.|$((Get-Item -LiteralPath $root -Force).Attributes)")
    foreach ($item in @(Get-ChildItem -LiteralPath $root -Force -Recurse)) {
        $relative = [IO.Path]::GetRelativePath($root, $item.FullName).Replace("\", "/")
        if ($item.PSIsContainer) {
            $state += "D|$relative|$($item.Attributes)"
        }
        else {
            $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.FullName).Hash.ToUpperInvariant()
            $state += "F|$relative|$($item.Length)|$hash|$($item.Attributes)"
        }
    }
    return @($state | Sort-Object)
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
    $result = Test-NexusReleaseSource -ManifestPath $manifestFull -Profile Candidate
    if ($result.result -cne "pass" -or $result.profile -cne "candidate" -or @($result.files).Count -ne 8 -or $result.candidateBuilt) {
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

Invoke-OfflineCheck -Name "Candidate manifest cannot claim public supported state" -Action {
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

Invoke-OfflineCheck -Name "Deterministic stored ZIP helpers build and inspect exact bytes" -Action {
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("nexus-zip-contract-" + [guid]::NewGuid().ToString("N"))
    [void][IO.Directory]::CreateDirectory($tempRoot)
    try {
        $module = Get-Module NexusPackageTools
        $alpha = [Text.Encoding]::UTF8.GetBytes("alpha")
        $beta = [Text.Encoding]::UTF8.GetBytes("beta")
        $entries = @(
            [pscustomobject]@{ Path = "Folder/B.txt"; Bytes = $beta; Length = [long]$beta.Length; Sha256 = (& $module { param($Bytes) Get-NexusBytesSha256 -Bytes $Bytes } $beta) },
            [pscustomobject]@{ Path = "A.txt"; Bytes = $alpha; Length = [long]$alpha.Length; Sha256 = (& $module { param($Bytes) Get-NexusBytesSha256 -Bytes $Bytes } $alpha) }
        )
        $timestamp = & $module { Get-NexusArchiveTimestamp -TimestampUtc "2000-01-01T00:00:00Z" }
        $first = Join-Path $tempRoot "first.zip"
        $second = Join-Path $tempRoot "second.zip"
        & $module { param($Items, $Path, $Time) New-NexusStoredZip -Entries $Items -Destination $Path -Timestamp $Time } $entries $first $timestamp
        & $module { param($Items, $Path, $Time) New-NexusStoredZip -Entries $Items -Destination $Path -Timestamp $Time } $entries $second $timestamp
        $comparison = & $module { param($A, $B) Compare-NexusFilesExact -First $A -Second $B } $first $second
        if (-not $comparison.digestsMatch -or -not $comparison.byteCompare -or $comparison.build1Sha256 -cne $comparison.build2Sha256) {
            throw "Deterministic archive comparison did not prove exact equality."
        }
        $crcVector = & $module { param($Bytes) (Get-NexusBytesCrc32 -Bytes $Bytes).ToString("X8") } ([Text.Encoding]::ASCII.GetBytes("123456789"))
        if ([string]$crcVector -cne "CBF43926") {
            throw "ZIP CRC-32 implementation failed its published check vector."
        }
        $validated = @(& $module { param($Path, $Items, $Time) Read-NexusValidatedStoredZip -ArchivePath $Path -ExpectedEntries $Items -Timestamp $Time } $first $entries $timestamp)
        if ($validated.Count -ne 2 -or [string]$validated[0].Path -cne "A.txt" -or [string]$validated[1].Path -cne "Folder/B.txt") {
            throw "Stored ZIP validation did not preserve exact ordinal entry order."
        }
        $extracted = Join-Path $tempRoot "extracted"
        & $module { param($Items, $Root) Expand-NexusValidatedEntries -Entries $Items -DestinationRoot $Root } $validated $extracted
        foreach ($entry in $validated) {
            $path = Join-Path $extracted ([string]$entry.Path)
            if ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -cne [string]$entry.Sha256) {
                throw "Extracted helper fixture differs from its validated archive bytes."
            }
        }
        [IO.File]::WriteAllBytes($second, [byte[]](0..31))
        Assert-ExpectedFailure -ExpectedId "BW-PKG-REPRODUCIBILITY" -Action {
            & $module { param($A, $B) Compare-NexusFilesExact -First $A -Second $B } $first $second | Out-Null
        }
    }
    finally {
        if (Test-Path -LiteralPath $tempRoot) {
            [IO.Directory]::Delete($tempRoot, $true)
        }
    }
}

Invoke-OfflineCheck -Name "ZIP inspection rejects corrupt, traversal, collision, and byte mismatch cases" -Action {
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("nexus-zip-negative-" + [guid]::NewGuid().ToString("N"))
    [void][IO.Directory]::CreateDirectory($tempRoot)
    try {
        $module = Get-Module NexusPackageTools
        $timestamp = & $module { Get-NexusArchiveTimestamp -TimestampUtc "2000-01-01T00:00:00Z" }
        $payload = [Text.Encoding]::UTF8.GetBytes("fixture")
        $hash = & $module { param($Bytes) Get-NexusBytesSha256 -Bytes $Bytes } $payload

        $corrupt = Join-Path $tempRoot "corrupt.zip"
        [IO.File]::WriteAllBytes($corrupt, [byte[]](0..15))
        Assert-ExpectedFailure -ExpectedId "BW-PKG-ARCHIVE-READ" -Action {
            & $module { param($Path, $Items, $Time) Read-NexusValidatedStoredZip -ArchivePath $Path -ExpectedEntries $Items -Timestamp $Time } $corrupt @([pscustomobject]@{ Path = "A.txt"; Bytes = $payload; Length = 7L; Sha256 = $hash }) $timestamp | Out-Null
        }

        $traversal = Join-Path $tempRoot "traversal.zip"
        $stream = [IO.File]::Open($traversal, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $archive = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create, $false, [Text.UTF8Encoding]::new($false, $true))
        try {
            $entry = $archive.CreateEntry("../escape.txt", [IO.Compression.CompressionLevel]::NoCompression)
            $entry.LastWriteTime = $timestamp
            $entry.ExternalAttributes = 0
            $entryStream = $entry.Open()
            try { $entryStream.Write($payload, 0, $payload.Length) } finally { $entryStream.Dispose() }
        }
        finally {
            $archive.Dispose()
        }
        Assert-ExpectedFailure -ExpectedId "BW-PKG-ARCHIVE-PATH" -Action {
            & $module { param($Path, $Items, $Time) Read-NexusValidatedStoredZip -ArchivePath $Path -ExpectedEntries $Items -Timestamp $Time } $traversal @([pscustomobject]@{ Path = "../escape.txt"; Bytes = $payload; Length = 7L; Sha256 = $hash }) $timestamp | Out-Null
        }

        $collision = Join-Path $tempRoot "collision.zip"
        $stream = [IO.File]::Open($collision, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $archive = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Create, $false, [Text.UTF8Encoding]::new($false, $true))
        try {
            foreach ($name in @("A.txt", "a.txt")) {
                $entry = $archive.CreateEntry($name, [IO.Compression.CompressionLevel]::NoCompression)
                $entry.LastWriteTime = $timestamp
                $entry.ExternalAttributes = 0
                $entryStream = $entry.Open()
                try { $entryStream.Write($payload, 0, $payload.Length) } finally { $entryStream.Dispose() }
            }
        }
        finally {
            $archive.Dispose()
        }
        $collisionExpected = @(
            [pscustomobject]@{ Path = "A.txt"; Bytes = $payload; Length = 7L; Sha256 = $hash },
            [pscustomobject]@{ Path = "a.txt"; Bytes = $payload; Length = 7L; Sha256 = $hash }
        )
        Assert-ExpectedFailure -ExpectedId "BW-PKG-ARCHIVE-DUPLICATE" -Action {
            & $module { param($Path, $Items, $Time) Read-NexusValidatedStoredZip -ArchivePath $Path -ExpectedEntries $Items -Timestamp $Time } $collision $collisionExpected $timestamp | Out-Null
        }

        $valid = Join-Path $tempRoot "valid.zip"
        $expected = @([pscustomobject]@{ Path = "A.txt"; Bytes = $payload; Length = 7L; Sha256 = $hash })
        & $module { param($Items, $Path, $Time) New-NexusStoredZip -Entries $Items -Destination $Path -Timestamp $Time } $expected $valid $timestamp

        $validBytes = [IO.File]::ReadAllBytes($valid)
        $eocdOffset = $validBytes.Length - 22
        if ([BitConverter]::ToUInt32($validBytes, $eocdOffset) -ne 0x06054B50) {
            throw "Valid ZIP fixture does not have the expected comment-free end record."
        }
        $centralOffset = [int][BitConverter]::ToUInt32($validBytes, $eocdOffset + 16)
        $localOffset = [int][BitConverter]::ToUInt32($validBytes, $centralOffset + 42)
        $localMetadataMutations = @(
            [pscustomobject]@{ Name = "local-time"; Offset = 10 },
            [pscustomobject]@{ Name = "local-date"; Offset = 12 },
            [pscustomobject]@{ Name = "local-crc"; Offset = 14 },
            [pscustomobject]@{ Name = "local-compressed-size"; Offset = 18 },
            [pscustomobject]@{ Name = "local-uncompressed-size"; Offset = 22 }
        )
        foreach ($mutation in $localMetadataMutations) {
            $mutatedBytes = [byte[]]$validBytes.Clone()
            $targetOffset = $localOffset + [int]$mutation.Offset
            $mutatedBytes[$targetOffset] = [byte]($mutatedBytes[$targetOffset] -bxor 1)
            $mutatedPath = Join-Path $tempRoot ("$($mutation.Name).zip")
            [IO.File]::WriteAllBytes($mutatedPath, $mutatedBytes)
            Assert-ExpectedFailure -ExpectedId "BW-PKG-ARCHIVE-LOCAL-METADATA" -Action {
                & $module { param($Path, $Items, $Time) Read-NexusValidatedStoredZip -ArchivePath $Path -ExpectedEntries $Items -Timestamp $Time } $mutatedPath $expected $timestamp | Out-Null
            }
        }

        $matchedCrcBytes = [byte[]]$validBytes.Clone()
        $matchedCrcBytes[$localOffset + 14] = [byte]($matchedCrcBytes[$localOffset + 14] -bxor 1)
        $matchedCrcBytes[$centralOffset + 16] = [byte]($matchedCrcBytes[$centralOffset + 16] -bxor 1)
        $matchedCrcPath = Join-Path $tempRoot "matched-wrong-crc.zip"
        [IO.File]::WriteAllBytes($matchedCrcPath, $matchedCrcBytes)
        Assert-ExpectedFailure -ExpectedId "BW-PKG-ARCHIVE-CRC" -Action {
            & $module { param($Path, $Items, $Time) Read-NexusValidatedStoredZip -ArchivePath $Path -ExpectedEntries $Items -Timestamp $Time } $matchedCrcPath $expected $timestamp | Out-Null
        }

        $matchedTimeBytes = [byte[]]$validBytes.Clone()
        $matchedTimeBytes[$localOffset + 10] = [byte]($matchedTimeBytes[$localOffset + 10] -bxor 1)
        $matchedTimeBytes[$centralOffset + 12] = [byte]($matchedTimeBytes[$centralOffset + 12] -bxor 1)
        $matchedTimePath = Join-Path $tempRoot "matched-wrong-time.zip"
        [IO.File]::WriteAllBytes($matchedTimePath, $matchedTimeBytes)
        Assert-ExpectedFailure -ExpectedId "BW-PKG-ARCHIVE-TIMESTAMP" -Action {
            & $module { param($Path, $Items, $Time) Read-NexusValidatedStoredZip -ArchivePath $Path -ExpectedEntries $Items -Timestamp $Time } $matchedTimePath $expected $timestamp | Out-Null
        }

        $wrong = @([pscustomobject]@{ Path = "A.txt"; Bytes = $payload; Length = 7L; Sha256 = ("0" * 64) })
        Assert-ExpectedFailure -ExpectedId "BW-PKG-ARCHIVE-BYTES" -Action {
            & $module { param($Path, $Items, $Time) Read-NexusValidatedStoredZip -ArchivePath $Path -ExpectedEntries $Items -Timestamp $Time } $valid $wrong $timestamp | Out-Null
        }
    }
    finally {
        if (Test-Path -LiteralPath $tempRoot) {
            [IO.Directory]::Delete($tempRoot, $true)
        }
    }
}

Invoke-OfflineCheck -Name "Mutating actions honor WhatIf without changing release output" -Action {
    $target = Join-Path $repositoryRoot "dist/7dtd_wasteland_animal_population_tuning/4.1.0"
    $before = @(Get-OfflineTreeState -Path $target)
    & $entryPoint -ManifestPath $manifestFull -Action StagePrimary -WhatIf | Out-Null
    & $entryPoint -ManifestPath $manifestFull -Action PreparePrimary -WhatIf | Out-Null
    $after = @(Get-OfflineTreeState -Path $target)
    if (($before -join "`n") -cne ($after -join "`n")) {
        throw "WhatIf changed the versioned release output."
    }
}

Invoke-OfflineCheck -Name "Disposable preparation classification is rejected outside its owned test clone" -Action {
    Assert-ExpectedFailure -ExpectedId "BW-PKG-TEST-CONTEXT" -Action {
        New-NexusPreparedPrimary -ManifestPath $manifestFull -ExecutionClass "disposable-test-fixture" -DisposableTestToken ("0" * 32) -Confirm:$false | Out-Null
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
                throw "Could not create the disposable candidate branch."
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

if (-not $SkipDisposableStage) {
    Invoke-OfflineCheck -Name "Atomic PreparePrimary builds, validates, evidences, and promotes exactly one ZIP" -Action {
        $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
        $tempRoot = Join-Path $tempBase ("nexus-offline-prepare-" + [guid]::NewGuid().ToString("N"))
        $cloneRoot = Join-Path $tempRoot "repository"
        try {
            [void][IO.Directory]::CreateDirectory($tempRoot)
            & git clone --quiet --no-hardlinks --no-checkout $repositoryRoot $cloneRoot
            if ($LASTEXITCODE -ne 0) {
                throw "Could not create the disposable preparation clone."
            }
            $testToken = [guid]::NewGuid().ToString("N")
            $cloneGitDirectory = @(& git -C $cloneRoot rev-parse --absolute-git-dir)[0]
            if ($LASTEXITCODE -ne 0) {
                throw "Could not locate the disposable preparation clone's Git metadata."
            }
            [IO.File]::WriteAllText((Join-Path $cloneGitDirectory "nexus-disposable-test-owner"), $testToken, [Text.UTF8Encoding]::new($false))
            $head = @(& git -C $repositoryRoot rev-parse HEAD)[0]
            & git -C $cloneRoot checkout --quiet --detach $head
            if ($LASTEXITCODE -ne 0) {
                throw "Could not check out the disposable preparation source."
            }
            $cloneManifest = Join-Path $cloneRoot $ManifestPath
            $cloneEntryPoint = Join-Path $cloneRoot "tools/release/Invoke-NexusPackage.ps1"
            $cloneModulePath = Join-Path $cloneRoot "tools/release/NexusPackageTools.psm1"
            Import-Module $cloneModulePath -Force

            $whatIfRoot = Join-Path $cloneRoot "dist/.test-fixtures/7dtd_wasteland_animal_population_tuning/4.1.0"
            $beforeWhatIf = @(Get-OfflineTreeState -Path $whatIfRoot)
            & $cloneEntryPoint -ManifestPath $cloneManifest -Action PreparePrimary -ExecutionClass "disposable-test-fixture" -DisposableTestToken $testToken -WhatIf | Out-Null
            $afterWhatIf = @(Get-OfflineTreeState -Path $whatIfRoot)
            if (($beforeWhatIf -join "`n") -cne ($afterWhatIf -join "`n")) {
                throw "Disposable PreparePrimary WhatIf changed output."
            }
            Assert-ExpectedFailure -ExpectedId "BW-PKG-BRANCH" -Action {
                New-NexusPreparedPrimary -ManifestPath $cloneManifest -ExecutionClass "disposable-test-fixture" -DisposableTestToken $testToken -Confirm:$false | Out-Null
            }

            & git -C $cloneRoot switch --quiet -C develop/4.1.0 $head
            if ($LASTEXITCODE -ne 0) {
                throw "Could not create the disposable candidate branch."
            }

            $cloneModule = @(Get-Module NexusPackageTools | Where-Object { [IO.Path]::GetFullPath($_.Path) -ceq [IO.Path]::GetFullPath($cloneModulePath) })[0]
            if ($null -eq $cloneModule) {
                throw "Could not identify the disposable preparation module."
            }
            $readinessPath = Join-Path $cloneRoot "governance/RELEASE_READINESS_4.1.0.md"
            $readinessBytes = [IO.File]::ReadAllBytes($readinessPath)
            try {
                $readinessText = [IO.File]::ReadAllText($readinessPath, [Text.UTF8Encoding]::new($false, $true))
                $readinessText = $readinessText.Replace("The owner accepted this planning set", "The owner reviewed this planning set")
                [IO.File]::WriteAllText($readinessPath, $readinessText, [Text.UTF8Encoding]::new($false))
                $cloneContext = & $cloneModule { param($Path) Read-NexusManifest -ManifestPath $Path } $cloneManifest
                Assert-ExpectedFailure -ExpectedId "BW-PKG-AUTHORITY" -Action {
                    & $cloneModule { param($Context) Get-NexusP4AuthorityRecord -Context $Context -ExecutionClass "candidate" -TestContext $null } $cloneContext | Out-Null
                }
            }
            finally {
                [IO.File]::WriteAllBytes($readinessPath, $readinessBytes)
            }

            $distRoot = Join-Path $cloneRoot "dist"
            $outside = Join-Path $tempRoot "junction-target"
            [void][IO.Directory]::CreateDirectory($outside)
            [void](New-Item -ItemType Junction -Path $distRoot -Target $outside)
            try {
                Assert-ExpectedFailure -ExpectedId "BW-PKG-REPARSE" -Action {
                    New-NexusPreparedPrimary -ManifestPath $cloneManifest -ExecutionClass "disposable-test-fixture" -DisposableTestToken $testToken -Confirm:$false | Out-Null
                }
                if (@(Get-ChildItem -LiteralPath $outside -Force).Count -ne 0) {
                    throw "PreparePrimary reparse rejection wrote outside the clone."
                }
            }
            finally {
                if (Test-Path -LiteralPath $distRoot) {
                    [IO.Directory]::Delete($distRoot)
                }
            }

            [IO.File]::AppendAllText((Join-Path $cloneRoot "README.md"), "dirty")
            Assert-ExpectedFailure -ExpectedId "BW-PKG-DIRTY" -Action {
                New-NexusPreparedPrimary -ManifestPath $cloneManifest -ExecutionClass "disposable-test-fixture" -DisposableTestToken $testToken -Confirm:$false | Out-Null
            }
            & git -C $cloneRoot restore --worktree -- README.md
            if ($LASTEXITCODE -ne 0) {
                throw "Could not restore the disposable preparation dirty fixture."
            }

            $versionRoot = Join-Path $cloneRoot "dist/.test-fixtures/7dtd_wasteland_animal_population_tuning/4.1.0"
            $preexisting = Join-Path $versionRoot "evidence/preexisting.txt"
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $preexisting))
            [IO.File]::WriteAllText($preexisting, "preexisting")
            Assert-ExpectedFailure -ExpectedId "BW-PKG-OVERWRITE" -Action {
                New-NexusPreparedPrimary -ManifestPath $cloneManifest -ExecutionClass "disposable-test-fixture" -DisposableTestToken $testToken -Confirm:$false | Out-Null
            }
            $resolvedVersion = [IO.Path]::GetFullPath($versionRoot)
            if (-not $resolvedVersion.StartsWith(([IO.Path]::GetFullPath($cloneRoot) + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) {
                throw "Disposable preparation cleanup path escaped the clone."
            }
            [IO.Directory]::Delete($versionRoot, $true)

            $manifestData = Get-Content -Raw $cloneManifest | ConvertFrom-Json -Depth 100
            $historicalBefore = @{}
            foreach ($artifact in @($manifestData.protectedArtifacts)) {
                $historicalBefore[[string]$artifact.path] = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $cloneRoot ([string]$artifact.path))).Hash
            }

            $result = & $cloneEntryPoint -ManifestPath $cloneManifest -Action PreparePrimary -ExecutionClass "disposable-test-fixture" -DisposableTestToken $testToken -Confirm:$false -PassThru
            if ([string]$result.ExecutionClass -cne "disposable-test-fixture" -or
                [string]$result.VersionRoot -cne "dist/.test-fixtures/7dtd_wasteland_animal_population_tuning/4.1.0" -or
                $result.Evidence.finalUpload.operation -cne "promote-primary-to-final-upload" -or
                -not $result.Evidence.finalUpload.promoted -or -not $result.Evidence.finalUpload.technicallyReady -or
                $result.Evidence.finalUpload.candidateAuthority -or
                $result.Evidence.finalUpload.authority.ownerCandidateCycleConsumed -or
                $result.Evidence.finalUpload.approvedForPublication -or $result.Evidence.finalUpload.publicationAuthorized -or
                $result.Evidence.finalUpload.publicationPerformed) {
                throw "PreparePrimary returned an invalid technical-promotion state."
            }
            $productionVersionRoot = Join-Path $cloneRoot "dist/7dtd_wasteland_animal_population_tuning/4.1.0"
            if (Test-Path -LiteralPath $productionVersionRoot) {
                throw "Disposable preparation wrote the production candidate namespace."
            }
            $versionRoot = Join-Path $cloneRoot ([string]$result.VersionRoot)
            $stageRoot = Join-Path $cloneRoot ([string]$result.StagePath)
            $finalArchive = Join-Path $cloneRoot ([string]$result.FinalUploadPath)
            if (-not (Test-Path -LiteralPath $finalArchive -PathType Leaf)) {
                throw "PreparePrimary did not promote the manifest-named ZIP."
            }

            $expectedFiles = @($manifestData.editions | Where-Object id -eq "windows-gui" | Select-Object -ExpandProperty sourceToStage | ForEach-Object { [string]$_.stage } | Sort-Object)
            $actualStageFiles = @(Get-ChildItem -LiteralPath $stageRoot -Recurse -File | ForEach-Object {
                [IO.Path]::GetRelativePath($stageRoot, $_.FullName).Replace("\", "/")
            } | Sort-Object)
            if (($actualStageFiles -join "`n") -cne ($expectedFiles -join "`n")) {
                throw "Prepared source stage differs from the manifest allowlist."
            }
            foreach ($mapping in @($manifestData.editions | Where-Object id -eq "windows-gui" | Select-Object -ExpandProperty sourceToStage)) {
                $repositoryRelative = "$($manifestData.solution.sourceRoot)/$($mapping.source)"
                $sourceHash = Get-OfflineGitBlobSha256 -Repository $cloneRoot -Commit $head -Path $repositoryRelative
                $stageHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $stageRoot ([string]$mapping.stage))).Hash
                if ($sourceHash -cne $stageHash) {
                    throw "Prepared source differs from the raw source commit: $($mapping.stage)"
                }
            }

            $evidenceFiles = @(
                [string]$result.EvidencePaths.SourceStage,
                [string]$result.EvidencePaths.PackageBuild,
                [string]$result.EvidencePaths.FinalUpload
            )
            foreach ($relative in $evidenceFiles) {
                $path = Join-Path $cloneRoot $relative
                if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                    throw "Prepared evidence is missing: $relative"
                }
                $text = [IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false, $true))
                if ($text.Contains("`r", [StringComparison]::Ordinal)) {
                    throw "Prepared evidence is not canonical LF text: $relative"
                }
                [void]($text | ConvertFrom-Json -Depth 100)
            }
            $sourceEvidence = Get-Content -Raw (Join-Path $cloneRoot ([string]$result.EvidencePaths.SourceStage)) | ConvertFrom-Json -Depth 100
            $buildEvidence = Get-Content -Raw (Join-Path $cloneRoot ([string]$result.EvidencePaths.PackageBuild)) | ConvertFrom-Json -Depth 100
            $uploadEvidenceText = Get-Content -Raw (Join-Path $cloneRoot ([string]$result.EvidencePaths.FinalUpload))
            $uploadEvidence = $uploadEvidenceText | ConvertFrom-Json -Depth 100
            if ([string]$sourceEvidence.executionClass -cne "disposable-test-fixture" -or
                [string]$buildEvidence.executionClass -cne "disposable-test-fixture" -or
                [string]$uploadEvidence.executionClass -cne "disposable-test-fixture" -or
                [string]$sourceEvidence.source.commit -cne $head -or @($sourceEvidence.files).Count -ne 8 -or
                [string]$buildEvidence.archive.sha256 -cne (Get-FileHash -Algorithm SHA256 -LiteralPath $finalArchive).Hash -or
                -not $buildEvidence.reproducibility.digestsMatch -or -not $buildEvidence.reproducibility.byteCompare -or
                [string]$buildEvidence.reproducibility.build1Sha256 -cne [string]$buildEvidence.reproducibility.build2Sha256 -or
                -not $buildEvidence.validation.extractedDiskReadBackPassed -or [string]$buildEvidence.validation.smokeTest.status -cne "pass" -or
                -not $buildEvidence.validation.smokeTest.shortPathIsolation -or
                -not $buildEvidence.validation.smokeTest.temporaryPackageRevalidatedAfterSmoke -or
                -not $buildEvidence.validation.smokeTest.temporaryMaterialRemoved -or
                [string]$uploadEvidence.finalUpload.sha256 -cne [string]$buildEvidence.archive.sha256 -or
                @($uploadEvidence.finalUpload.inventory).Count -ne 1 -or @($uploadEvidence.revalidationTriggers).Count -lt 4 -or
                $uploadEvidenceText -notmatch '"generatedAtUtc"\s*:\s*"20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z"') {
                throw "Prepared evidence does not prove the complete candidate contract."
            }
            $sourceEvidenceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $cloneRoot ([string]$result.EvidencePaths.SourceStage))).Hash
            $buildEvidenceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $cloneRoot ([string]$result.EvidencePaths.PackageBuild))).Hash
            if ([string]$uploadEvidence.sourceEvidenceSha256 -cne $sourceEvidenceHash -or
                [string]$uploadEvidence.packageBuildEvidenceSha256 -cne $buildEvidenceHash) {
                throw "Final-upload evidence does not bind its source/build receipts."
            }

            $archiveStream = [IO.File]::OpenRead($finalArchive)
            $archive = [IO.Compression.ZipArchive]::new($archiveStream, [IO.Compression.ZipArchiveMode]::Read, $false, [Text.UTF8Encoding]::new($false, $true))
            try {
                if ($archive.Entries.Count -ne 8) {
                    throw "Prepared ZIP entry count is not exact."
                }
                $entryNames = @($archive.Entries | ForEach-Object { $_.FullName })
                if (($entryNames -join "`n") -cne (($expectedFiles | Sort-Object) -join "`n")) {
                    throw "Prepared ZIP entry order or inventory is not exact."
                }
                foreach ($entry in $archive.Entries) {
                    if ($entry.CompressedLength -ne $entry.Length -or $entry.ExternalAttributes -ne 0 -or
                        $entry.LastWriteTime.DateTime -ne [DateTime]::new(2000, 1, 1, 0, 0, 0)) {
                        throw "Prepared ZIP metadata differs from the deterministic policy."
                    }
                    $memory = [IO.MemoryStream]::new()
                    $entryStream = $entry.Open()
                    try { $entryStream.CopyTo($memory) } finally { $entryStream.Dispose() }
                    $entryHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($memory.ToArray()))
                    $stageHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $stageRoot $entry.FullName)).Hash
                    $memory.Dispose()
                    if ($entryHash -cne $stageHash) {
                        throw "Prepared ZIP bytes differ from the source stage: $($entry.FullName)"
                    }
                }
            }
            finally {
                $archive.Dispose()
            }

            $expectedVersionFiles = @($expectedFiles | ForEach-Object { "candidate/primary-tree/$_" }) + @(
                "evidence/primary-source-stage.json",
                "evidence/primary-package-build.json",
                "evidence/primary-final-upload.json",
                "final-upload/$($manifestData.editions[0].plannedFilename)"
            )
            $expectedVersionDirectories = @(Get-OfflineExpectedDirectories -Files $expectedVersionFiles)
            $versionItems = @(Get-ChildItem -LiteralPath $versionRoot -Force -Recurse)
            if (@($versionItems | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -ne 0) {
                throw "Prepared version root contains a reparse point."
            }
            $actualVersionFiles = @($versionItems | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
                [IO.Path]::GetRelativePath($versionRoot, $_.FullName).Replace("\", "/")
            } | Sort-Object)
            $actualVersionDirectories = @($versionItems | Where-Object { $_.PSIsContainer } | ForEach-Object {
                [IO.Path]::GetRelativePath($versionRoot, $_.FullName).Replace("\", "/")
            } | Sort-Object)
            if (($actualVersionFiles -join "`n") -cne (($expectedVersionFiles | Sort-Object) -join "`n") -or
                ($actualVersionDirectories -join "`n") -cne (($expectedVersionDirectories | Sort-Object) -join "`n")) {
                throw "Prepared version-root inventory is not exact."
            }
            $uploadRoot = Join-Path $versionRoot "final-upload"
            $uploadItems = @(Get-ChildItem -LiteralPath $uploadRoot -Force)
            if ($uploadItems.Count -ne 1 -or $uploadItems[0].Name -cne [string]$manifestData.editions[0].plannedFilename) {
                throw "Final-upload does not contain exactly one manifest-named ZIP."
            }
            if (@(Get-ChildItem -LiteralPath $versionRoot -Recurse -File -Include "*.zip", "*.7z", "*.rar").Count -ne 1) {
                throw "Prepared version root retained an extra archive."
            }
            foreach ($blocked in @($manifestData.editions | Where-Object state -eq "blocked")) {
                if (Test-Path -LiteralPath (Join-Path $versionRoot ([string]$blocked.plannedFilename))) {
                    throw "Prepared output contains a blocked optional edition."
                }
            }
            $solutionDist = Split-Path -Parent $versionRoot
            if (@(Get-ChildItem -LiteralPath $solutionDist -Force -Directory | Where-Object Name -like ".nexus-prepare-work-*").Count -ne 0) {
                throw "PreparePrimary retained an owned work directory."
            }
            foreach ($artifact in @($manifestData.protectedArtifacts)) {
                $after = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $cloneRoot ([string]$artifact.path))).Hash
                if ($after -cne $historicalBefore[[string]$artifact.path]) {
                    throw "PreparePrimary changed a protected historical artifact."
                }
            }

            $beforeRerun = @(Get-OfflineTreeState -Path $versionRoot)
            Assert-ExpectedFailure -ExpectedId "BW-PKG-OVERWRITE" -Action {
                New-NexusPreparedPrimary -ManifestPath $cloneManifest -ExecutionClass "disposable-test-fixture" -DisposableTestToken $testToken -Confirm:$false | Out-Null
            }
            $afterRerun = @(Get-OfflineTreeState -Path $versionRoot)
            if (($beforeRerun -join "`n") -cne ($afterRerun -join "`n")) {
                throw "Failed PreparePrimary rerun changed promoted output."
            }
        }
        finally {
            $resolvedTemp = [IO.Path]::GetFullPath($tempRoot)
            $requiredPrefix = $tempBase + [IO.Path]::DirectorySeparatorChar + "nexus-offline-prepare-"
            if (Test-Path -LiteralPath $resolvedTemp) {
                if (-not $resolvedTemp.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Refusing to clean a disposable preparation path outside the expected namespace."
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
