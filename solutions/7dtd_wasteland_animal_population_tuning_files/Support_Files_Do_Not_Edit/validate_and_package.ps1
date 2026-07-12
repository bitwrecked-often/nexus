# 7DTD 3.0 Wasteland Animal Population Tuning - validation and package harness
# Copyright (C) 2026 Bit Wrecked
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This program is distributed without warranty. See LICENSE.txt for details.

param(
    [string]$GameRoot = "",
    [string]$ModFolder = "",
    [string]$ZipPath = "",
    [string]$VortexZipPath = "",
    [string]$NexusNoScriptsZipPath = "",
    [switch]$RebuildZip
)

$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
$scriptRootName = Split-Path -Leaf $scriptRoot
if ($scriptRootName -eq "Support_Files_Do_Not_Edit") {
    $releaseRoot = Split-Path -Parent $scriptRoot
    $sourceRoot = $scriptRoot
}
elseif (Test-Path -LiteralPath (Join-Path $scriptRoot "Support_Files_Do_Not_Edit\BitWrecked_7DTD_WastelandAnimalPopulationTuning") -PathType Container) {
    $releaseRoot = $scriptRoot
    $sourceRoot = Join-Path $scriptRoot "Support_Files_Do_Not_Edit"
}
else {
    $releaseRoot = $scriptRoot
    $sourceRoot = $scriptRoot
}

if ([string]::IsNullOrWhiteSpace($GameRoot)) {
    $GameRoot = (Resolve-Path (Join-Path $releaseRoot "..\..\..")).Path
}
if ([string]::IsNullOrWhiteSpace($ModFolder)) {
    $ModFolder = Join-Path $sourceRoot "BitWrecked_7DTD_WastelandAnimalPopulationTuning"
}
if ([string]::IsNullOrWhiteSpace($ZipPath)) {
    $ZipPath = Join-Path $releaseRoot "Upload_To_Nexus\7DTD_WastelandAnimalPopulationTuning_FullPackage.zip"
}
if ([string]::IsNullOrWhiteSpace($VortexZipPath)) {
    $VortexZipPath = Join-Path $releaseRoot "Upload_To_Nexus\7DTD_WastelandAnimalPopulationTuning_VortexModlet.zip"
}
if ([string]::IsNullOrWhiteSpace($NexusNoScriptsZipPath)) {
    $NexusNoScriptsZipPath = Join-Path $releaseRoot "Upload_To_Nexus\7DTD_WastelandAnimalPopulationTuning_Nexus_NoScripts.zip"
}

function Assert-File {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Missing file: $Path"
    }
}

function Assert-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Missing folder: $Path"
    }
}

function Load-Xml {
    param([string]$Path)
    [xml]$xml = Get-Content -LiteralPath $Path -Raw
    return $xml
}

function Remove-SafeTempFolder {
    param([string]$Path)

    $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    $tempRoot = [System.IO.Path]::GetTempPath()
    if (-not $resolvedPath.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove temp staging folder outside temp root: $resolvedPath"
    }

    Remove-Item -LiteralPath $resolvedPath -Recurse -Force
}

$modInfoPath = Join-Path $ModFolder "ModInfo.xml"
$modConfigPath = Join-Path $ModFolder "Config\entitygroups.xml"
$modSpawningConfigPath = Join-Path $ModFolder "Config\spawning.xml"
$modFolderName = Split-Path -Leaf $ModFolder
$readmeFirstPath = Join-Path $releaseRoot "README_FIRST.txt"
$changelogPath = Join-Path $sourceRoot "CHANGELOG.md"
$logoPath = Join-Path $sourceRoot "Assets\bit-wrecked-channel-avatar.png"
$nexusNoScriptsDocsPath = Join-Path $sourceRoot "Nexus_NoScripts"
$nexusNoScriptsReadmePath = Join-Path $nexusNoScriptsDocsPath "README_FIRST.txt"
$nexusNoScriptsRequirementsPath = Join-Path $nexusNoScriptsDocsPath "REQUIREMENTS_AND_INSTALL.txt"
$liveEntityGroupsPath = Join-Path $GameRoot "Data\Config\entitygroups.xml"
$liveSpawningPath = Join-Path $GameRoot "Data\Config\spawning.xml"
$packageSourceFiles = @(
    (Join-Path $releaseRoot "7DTD_WastelandAnimalTuning.bat"),
    (Join-Path $sourceRoot "7DTD_WastelandAnimalPopulationTuning_Tool.ps1"),
    (Join-Path $sourceRoot "Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.bat"),
    (Join-Path $sourceRoot "Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.ps1"),
    (Join-Path $sourceRoot "Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.bat"),
    (Join-Path $sourceRoot "Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.ps1"),
    (Join-Path $sourceRoot "validate_and_package.ps1"),
    $modInfoPath,
    $modConfigPath,
    $modSpawningConfigPath
)

Write-Host "Checking mod folder shape..."
Assert-Directory $ModFolder
Assert-Directory (Join-Path $ModFolder "Config")
Assert-File $modInfoPath
Assert-File $modConfigPath
Assert-File $modSpawningConfigPath
Assert-File $readmeFirstPath
Assert-File $changelogPath
Assert-File $logoPath
Assert-File $nexusNoScriptsReadmePath
Assert-File $nexusNoScriptsRequirementsPath

Write-Host "Checking no-scripts documentation..."
$noScriptsDocumentation = (Get-Content -LiteralPath $nexusNoScriptsReadmePath -Raw) + "`n" +
    (Get-Content -LiteralPath $nexusNoScriptsRequirementsPath -Raw)
$forbiddenNoScriptsInstructions = @(
    "7DTD_WastelandAnimalTuning.bat",
    "Support_Files_Do_Not_Edit"
)
foreach ($forbiddenInstruction in $forbiddenNoScriptsInstructions) {
    if ($noScriptsDocumentation -match [regex]::Escape($forbiddenInstruction)) {
        throw "No-scripts documentation references unavailable feature or path: $forbiddenInstruction"
    }
}
foreach ($requiredInstruction in @("manual", "Mods", "ModInfo.xml", "remove")) {
    if ($noScriptsDocumentation -notmatch [regex]::Escape($requiredInstruction)) {
        throw "No-scripts documentation is missing required guidance: $requiredInstruction"
    }
}

Write-Host "Parsing XML..."
$modInfoXml = Load-Xml $modInfoPath
$modConfigXml = Load-Xml $modConfigPath
$modSpawningConfigXml = Load-Xml $modSpawningConfigPath
$liveEntityGroupsXml = Load-Xml $liveEntityGroupsPath
$liveSpawningXml = Load-Xml $liveSpawningPath

Write-Host "Checking ModInfo metadata..."
$modName = $modInfoXml.SelectSingleNode("/xml/Name/@value")
$displayName = $modInfoXml.SelectSingleNode("/xml/DisplayName/@value")
$author = $modInfoXml.SelectSingleNode("/xml/Author/@value")
$version = $modInfoXml.SelectSingleNode("/xml/Version/@value")
if ($null -eq $modName -or $modName.Value -ne "BitWrecked_7DTD_WastelandAnimalPopulationTuning") {
    throw "Unexpected ModInfo Name value."
}
if ($null -eq $displayName -or $displayName.Value -ne "7DTD 3.0 Wasteland Animal Population Tuning") {
    throw "Unexpected ModInfo DisplayName value."
}
if ($null -eq $author -or $author.Value -ne "Bit Wrecked") {
    throw "Unexpected ModInfo Author value."
}
if ($null -eq $version -or $version.Value -ne "4.0.1") {
    throw "Unexpected ModInfo Version value."
}

Write-Host "Checking Wasteland spawn routes..."
$wastelandGroups = @(
    "/spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWasteland']",
    "/spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWastelandNight']"
)
foreach ($xpath in $wastelandGroups) {
    if ($null -eq $liveSpawningXml.SelectSingleNode($xpath)) {
        throw "Live spawning.xml does not match expected route: $xpath"
    }
}

Write-Host "Checking patch XPath targets against live entitygroups.xml..."
$patchNodes = $modConfigXml.SelectNodes("/configs/set")
if ($patchNodes.Count -lt 1) {
    throw "No patch <set> nodes found."
}

foreach ($patchNode in $patchNodes) {
    $xpath = $patchNode.GetAttribute("xpath")
    if ([string]::IsNullOrWhiteSpace($xpath)) {
        throw "Patch node missing xpath attribute."
    }

    $target = $liveEntityGroupsXml.SelectSingleNode($xpath)
    if ($null -eq $target) {
        throw "Patch XPath did not match live entitygroups.xml: $xpath"
    }
    if ($patchNode.InnerText -ne $target.Value) {
        throw "Packaged default entitygroups.xml value drifted from live XML: $xpath expected '$($target.Value)' but found '$($patchNode.InnerText)'"
    }

    Write-Host "  OK $xpath -> $($target.Value) -> $($patchNode.InnerText)"
}

Write-Host "Checking patch XPath targets against live spawning.xml..."
$spawningPatchNodes = $modSpawningConfigXml.SelectNodes("/configs/set")
if ($spawningPatchNodes.Count -lt 1) {
    throw "No spawning patch <set> nodes found."
}

foreach ($patchNode in $spawningPatchNodes) {
    $xpath = $patchNode.GetAttribute("xpath")
    if ([string]::IsNullOrWhiteSpace($xpath)) {
        throw "Spawning patch node missing xpath attribute."
    }

    $target = $liveSpawningXml.SelectSingleNode($xpath)
    if ($null -eq $target) {
        throw "Patch XPath did not match live spawning.xml: $xpath"
    }
    if ($patchNode.InnerText -ne $target.Value) {
        throw "Packaged default spawning.xml value drifted from live XML: $xpath expected '$($target.Value)' but found '$($patchNode.InnerText)'"
    }

    Write-Host "  OK $xpath -> $($target.Value) -> $($patchNode.InnerText)"
}

$spawningAppendNodes = $modSpawningConfigXml.SelectNodes("/configs/append[@xpath=`"/spawning/biome[@name='wasteland']`"]/spawn")
foreach ($routeNode in $spawningAppendNodes) {
    foreach ($attributeName in @("id", "maxcount", "respawndelay", "time", "entitygroup")) {
        if ([string]::IsNullOrWhiteSpace($routeNode.GetAttribute($attributeName))) {
            throw "Pressure route append is missing attribute '$attributeName'."
        }
    }
    $pressureEntityGroup = $routeNode.GetAttribute("entitygroup")
    if ($null -eq $liveEntityGroupsXml.SelectSingleNode("/entitygroups/entitygroup[@name='$pressureEntityGroup']")) {
        throw "Pressure route append points at an unknown live entitygroup: $pressureEntityGroup"
    }
    Write-Host "  OK appended pressure route $($routeNode.GetAttribute('id')) -> $($routeNode.GetAttribute('entitygroup'))"
}

Write-Host "Checking locked e/n/p shape..."
$badShape = $modConfigXml.SelectNodes("//set[contains(@xpath, '/entity[') or contains(@xpath, '@prob')]")
if ($badShape.Count -gt 0) {
    throw "Recipe drift detected: found entity/name/prob XPath shape. Use e/n/p for this live install."
}

Write-Host "Checking license guardrails..."
Assert-File (Join-Path $sourceRoot "LICENSE.txt")
Assert-File (Join-Path $sourceRoot "LICENSE_NOTICE.md")
Assert-File (Join-Path $sourceRoot "LEGAL_AND_USE.md")
foreach ($sourceFile in $packageSourceFiles) {
    Assert-File $sourceFile
    $sourceText = Get-Content -LiteralPath $sourceFile -Raw
    if ($sourceText -notmatch "SPDX-License-Identifier:\s*GPL-3\.0-or-later") {
        throw "Missing GPL SPDX header in: $sourceFile"
    }
    if ($sourceText -notmatch "Copyright \(C\) 2026 Bit Wrecked") {
        throw "Missing Bit Wrecked copyright header in: $sourceFile"
    }
}

if ($RebuildZip) {
    Write-Host "Rebuilding full package zip..."
    $zipFolder = Split-Path -Parent $ZipPath
    if (-not (Test-Path -LiteralPath $zipFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $zipFolder -Force | Out-Null
    }
    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath
    }
    $stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("7dtd_wasteland_tuning_package_" + [guid]::NewGuid().ToString("N"))
    $supportRoot = Join-Path $stagingRoot "Support_Files_Do_Not_Edit"
    try {
        New-Item -ItemType Directory -Path $supportRoot -Force | Out-Null

        Copy-Item -LiteralPath $readmeFirstPath -Destination $stagingRoot -Force
        Copy-Item -LiteralPath (Join-Path $releaseRoot "7DTD_WastelandAnimalTuning.bat") -Destination $stagingRoot -Force

        $supportItems = @(
            (Join-Path $sourceRoot "README_WINDOWS.md"),
            (Join-Path $sourceRoot "RELEASE_NOTES.md"),
            (Join-Path $sourceRoot "CHANGELOG.md"),
            (Join-Path $sourceRoot "PUBLISHING_SEO.md"),
            (Join-Path $sourceRoot "PACKAGE_METADATA.md"),
            (Join-Path $sourceRoot "TECHNICAL_FILE_MANIFEST.md"),
            (Join-Path $sourceRoot "BUILD_STORY_AND_QA_RUNBOOK.md"),
            (Join-Path $sourceRoot "LICENSE_NOTICE.md"),
            (Join-Path $sourceRoot "LICENSE.txt"),
            (Join-Path $sourceRoot "LEGAL_AND_USE.md"),
            (Join-Path $sourceRoot "Assets"),
            (Join-Path $sourceRoot "7DTD_WastelandAnimalPopulationTuning_Tool.ps1"),
            (Join-Path $sourceRoot "Advanced_CommandLine"),
            (Join-Path $sourceRoot "validate_and_package.ps1"),
            $ModFolder
        )
        foreach ($item in $supportItems) {
            Copy-Item -LiteralPath $item -Destination $supportRoot -Recurse -Force
        }

        Compress-Archive -Path (Join-Path $stagingRoot "*") -DestinationPath $ZipPath
    }
    finally {
        if (Test-Path -LiteralPath $stagingRoot) {
            Remove-SafeTempFolder -Path $stagingRoot
        }
    }

    Write-Host "Rebuilding Vortex modlet zip..."
    $vortexZipFolder = Split-Path -Parent $VortexZipPath
    if (-not (Test-Path -LiteralPath $vortexZipFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $vortexZipFolder -Force | Out-Null
    }
    if (Test-Path -LiteralPath $VortexZipPath) {
        Remove-Item -LiteralPath $VortexZipPath
    }
    Compress-Archive -Path $ModFolder -DestinationPath $VortexZipPath

    Write-Host "Rebuilding Nexus no-scripts zip..."
    $noScriptsZipFolder = Split-Path -Parent $NexusNoScriptsZipPath
    if (-not (Test-Path -LiteralPath $noScriptsZipFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $noScriptsZipFolder -Force | Out-Null
    }
    if (Test-Path -LiteralPath $NexusNoScriptsZipPath) {
        Remove-Item -LiteralPath $NexusNoScriptsZipPath
    }
    $noScriptsStagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("7dtd_wasteland_tuning_noscripts_" + [guid]::NewGuid().ToString("N"))
    try {
        New-Item -ItemType Directory -Path $noScriptsStagingRoot -Force | Out-Null
        Copy-Item -LiteralPath $ModFolder -Destination $noScriptsStagingRoot -Recurse -Force
        Copy-Item -LiteralPath $nexusNoScriptsReadmePath -Destination $noScriptsStagingRoot -Force
        Copy-Item -LiteralPath $nexusNoScriptsRequirementsPath -Destination $noScriptsStagingRoot -Force
        foreach ($documentName in @("RELEASE_NOTES.md", "CHANGELOG.md", "LICENSE_NOTICE.md", "LICENSE.txt", "LEGAL_AND_USE.md")) {
            Copy-Item -LiteralPath (Join-Path $sourceRoot $documentName) -Destination $noScriptsStagingRoot -Force
        }
        Compress-Archive -Path (Join-Path $noScriptsStagingRoot "*") -DestinationPath $NexusNoScriptsZipPath
    }
    finally {
        if (Test-Path -LiteralPath $noScriptsStagingRoot) {
            Remove-SafeTempFolder -Path $noScriptsStagingRoot
        }
    }
}

Write-Host "Checking full package zip shape..."
Assert-File $ZipPath
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ZipPath).Path)
try {
    $requiredEntries = @(
        "README_FIRST.txt",
        "7DTD_WastelandAnimalTuning.bat",
        "Support_Files_Do_Not_Edit/README_WINDOWS.md",
        "Support_Files_Do_Not_Edit/RELEASE_NOTES.md",
        "Support_Files_Do_Not_Edit/CHANGELOG.md",
        "Support_Files_Do_Not_Edit/PUBLISHING_SEO.md",
        "Support_Files_Do_Not_Edit/PACKAGE_METADATA.md",
        "Support_Files_Do_Not_Edit/TECHNICAL_FILE_MANIFEST.md",
        "Support_Files_Do_Not_Edit/BUILD_STORY_AND_QA_RUNBOOK.md",
        "Support_Files_Do_Not_Edit/LICENSE_NOTICE.md",
        "Support_Files_Do_Not_Edit/LICENSE.txt",
        "Support_Files_Do_Not_Edit/LEGAL_AND_USE.md",
        "Support_Files_Do_Not_Edit/Assets/bit-wrecked-channel-avatar.png",
        "Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1",
        "Support_Files_Do_Not_Edit/Advanced_CommandLine/README_ADVANCED_COMMANDLINE.txt",
        "Support_Files_Do_Not_Edit/Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.bat",
        "Support_Files_Do_Not_Edit/Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.ps1",
        "Support_Files_Do_Not_Edit/Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.bat",
        "Support_Files_Do_Not_Edit/Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.ps1",
        "Support_Files_Do_Not_Edit/validate_and_package.ps1",
        "Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/ModInfo.xml",
        "Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/entitygroups.xml",
        "Support_Files_Do_Not_Edit/BitWrecked_7DTD_WastelandAnimalPopulationTuning/Config/spawning.xml"
    )
    $entryNames = @{}
    foreach ($entry in $zip.Entries) {
        $normalizedName = $entry.FullName -replace "\\", "/"
        $entryNames[$normalizedName] = $true
    }
    foreach ($entryName in $requiredEntries) {
        if (-not $entryNames.ContainsKey($entryName)) {
            throw "Zip missing entry: $entryName"
        }
    }

    $allowedTopLevelEntries = @(
        "README_FIRST.txt",
        "7DTD_WastelandAnimalTuning.bat",
        "Support_Files_Do_Not_Edit"
    )
    $topLevelEntries = @{}
    foreach ($entryName in $entryNames.Keys) {
        $topLevelName = ($entryName -split "/")[0]
        $topLevelEntries[$topLevelName] = $true
    }
    foreach ($topLevelName in $topLevelEntries.Keys) {
        if ($allowedTopLevelEntries -notcontains $topLevelName) {
            throw "Full package has confusing top-level entry: $topLevelName"
        }
    }

    $topLevelBatCount = @($entryNames.Keys | Where-Object { $_ -match "^[^/]+\.bat$" }).Count
    if ($topLevelBatCount -ne 1) {
        throw "Full package should have exactly one top-level .bat file; found $topLevelBatCount."
    }
}
finally {
    $zip.Dispose()
}

Write-Host "Checking full package extracted smoke flow..."
$extractRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("7dtd_wasteland_tuning_extract_" + [guid]::NewGuid().ToString("N"))
try {
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $extractRoot -Force
    $expectedTopLevel = @(
        "README_FIRST.txt",
        "7DTD_WastelandAnimalTuning.bat",
        "Support_Files_Do_Not_Edit"
    )
    foreach ($entryName in $expectedTopLevel) {
        $entryPath = Join-Path $extractRoot $entryName
        if (-not (Test-Path -LiteralPath $entryPath)) {
            throw "Extracted full package missing top-level entry: $entryName"
        }
    }

    $unexpectedTopLevel = @(
        Get-ChildItem -LiteralPath $extractRoot -Force |
            Where-Object { $expectedTopLevel -notcontains $_.Name }
    )
    if ($unexpectedTopLevel.Count -gt 0) {
        throw "Extracted full package has confusing top-level entries: $($unexpectedTopLevel.Name -join ', ')"
    }

    $extractedTool = Join-Path $extractRoot "Support_Files_Do_Not_Edit\7DTD_WastelandAnimalPopulationTuning_Tool.ps1"
    $extractedModInfo = Join-Path $extractRoot "Support_Files_Do_Not_Edit\BitWrecked_7DTD_WastelandAnimalPopulationTuning\ModInfo.xml"
    Assert-File $extractedTool
    Assert-File $extractedModInfo

    $smoke = Start-Process -FilePath "powershell.exe" -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-STA",
        "-File",
        $extractedTool,
        "-SmokeTest"
    ) -Wait -PassThru -WindowStyle Hidden
    if ($smoke.ExitCode -ne 0) {
        throw "Extracted full package GUI smoke test failed with exit code $($smoke.ExitCode)."
    }
}
finally {
    if (Test-Path -LiteralPath $extractRoot) {
        Remove-SafeTempFolder -Path $extractRoot
    }
}

Write-Host "Checking Vortex modlet zip shape..."
Assert-File $VortexZipPath
$vortexZip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $VortexZipPath).Path)
try {
    $requiredVortexEntries = @(
        "$modFolderName/ModInfo.xml",
        "$modFolderName/Config/entitygroups.xml",
        "$modFolderName/Config/spawning.xml"
    )
    $forbiddenVortexEntries = @(
        "README_FIRST.txt",
        "CHANGELOG.md",
        "README_WINDOWS.md",
        "7DTD_WastelandAnimalTuning.bat",
        "Support_Files_Do_Not_Edit/README_WINDOWS.md",
        "Support_Files_Do_Not_Edit/CHANGELOG.md",
        "Support_Files_Do_Not_Edit/7DTD_WastelandAnimalPopulationTuning_Tool.ps1",
        "Support_Files_Do_Not_Edit/Advanced_CommandLine/README_ADVANCED_COMMANDLINE.txt",
        "Support_Files_Do_Not_Edit/Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.bat",
        "Support_Files_Do_Not_Edit/Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.ps1",
        "Support_Files_Do_Not_Edit/Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.bat",
        "Support_Files_Do_Not_Edit/Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.ps1",
        "7DTD_WastelandAnimalPopulationTuning_Tool.ps1",
        "Advanced_CommandLine/README_ADVANCED_COMMANDLINE.txt",
        "Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.bat",
        "Advanced_CommandLine/Install_7DTD_WastelandAnimalPopulationTuning.ps1",
        "Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.bat",
        "Advanced_CommandLine/Uninstall_7DTD_WastelandAnimalPopulationTuning.ps1"
    )
    $vortexEntryNames = @{}
    foreach ($entry in $vortexZip.Entries) {
        $normalizedName = $entry.FullName -replace "\\", "/"
        $vortexEntryNames[$normalizedName] = $true
    }
    foreach ($entryName in $requiredVortexEntries) {
        if (-not $vortexEntryNames.ContainsKey($entryName)) {
            throw "Vortex zip missing entry: $entryName"
        }
    }
    foreach ($entryName in $forbiddenVortexEntries) {
        if ($vortexEntryNames.ContainsKey($entryName)) {
            throw "Vortex zip contains full-package file: $entryName"
        }
    }
}
finally {
    $vortexZip.Dispose()
}

Write-Host "Checking Nexus no-scripts zip shape and instructions..."
Assert-File $NexusNoScriptsZipPath
$noScriptsZip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $NexusNoScriptsZipPath).Path)
try {
    $requiredNoScriptsEntries = @(
        "README_FIRST.txt",
        "REQUIREMENTS_AND_INSTALL.txt",
        "RELEASE_NOTES.md",
        "CHANGELOG.md",
        "LICENSE_NOTICE.md",
        "LICENSE.txt",
        "LEGAL_AND_USE.md",
        "$modFolderName/ModInfo.xml",
        "$modFolderName/Config/entitygroups.xml",
        "$modFolderName/Config/spawning.xml"
    )
    $forbiddenNoScriptsExtensions = @(".ps1", ".bat", ".cmd", ".exe", ".dll", ".vbs", ".js", ".jar", ".msi", ".scr")
    $noScriptsEntryNames = @{}
    foreach ($entry in $noScriptsZip.Entries) {
        $normalizedName = $entry.FullName -replace "\\", "/"
        $noScriptsEntryNames[$normalizedName] = $true
        $extension = [System.IO.Path]::GetExtension($normalizedName).ToLowerInvariant()
        if ($forbiddenNoScriptsExtensions -contains $extension) {
            throw "Nexus no-scripts zip contains forbidden executable-style file: $normalizedName"
        }
    }
    foreach ($entryName in $requiredNoScriptsEntries) {
        if (-not $noScriptsEntryNames.ContainsKey($entryName)) {
            throw "Nexus no-scripts zip missing entry: $entryName"
        }
    }

    $archiveReadmeEntry = $noScriptsZip.GetEntry("README_FIRST.txt")
    $reader = New-Object System.IO.StreamReader($archiveReadmeEntry.Open())
    try {
        $archiveReadme = $reader.ReadToEnd()
    }
    finally {
        $reader.Dispose()
    }
    foreach ($forbiddenInstruction in $forbiddenNoScriptsInstructions) {
        if ($archiveReadme -match [regex]::Escape($forbiddenInstruction)) {
            throw "Packaged no-scripts README references unavailable feature or path: $forbiddenInstruction"
        }
    }
}
finally {
    $noScriptsZip.Dispose()
}

Write-Host "PASS: 7DTD 3.0 Wasteland Animal Population Tuning modlet is valid for this live install."
