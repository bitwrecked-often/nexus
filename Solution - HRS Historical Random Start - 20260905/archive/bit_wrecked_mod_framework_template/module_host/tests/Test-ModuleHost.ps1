# Bit Wrecked Module Host 0.0.1 acceptance tests
# Copyright (C) 2026 Bit Wrecked contributors
# SPDX-License-Identifier: GPL-3.0-or-later

[CmdletBinding()]
param([switch]$SkipGuiSmoke)

$ErrorActionPreference = 'Stop'
$script:PassCount = 0
$script:FailureMessages = New-Object System.Collections.ArrayList
$script:Metrics = [ordered]@{}
$testRoot = $PSScriptRoot
$moduleHostRoot = Split-Path -Parent $testRoot
$templateRoot = Split-Path -Parent $moduleHostRoot
$solutionsRoot = Split-Path -Parent $templateRoot
$hostScript = Join-Path $moduleHostRoot 'BitWrecked_ModuleHost_Tool.ps1'
$launcher = Join-Path $moduleHostRoot '7DTD_BitWreckedModuleHost.bat'
$contractScript = Join-Path $moduleHostRoot 'modules\ModuleContract.ps1'
$temporaryParent = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\')
$temporaryRoot = Join-Path $temporaryParent ('BitWreckedModuleHostTests-' + [guid]::NewGuid().ToString('N'))

function Add-Pass {
    param([string]$Name)
    $script:PassCount++
    Write-Output "[PASS] $Name"
}

function Add-Failure {
    param([string]$Name, [string]$Detail)
    $message = "$Name :: $Detail"
    [void]$script:FailureMessages.Add($message)
    Write-Output "[FAIL] $message"
}

function Assert-True {
    param([string]$Name, [bool]$Condition, [string]$Detail = 'Condition was false.')
    if ($Condition) { Add-Pass -Name $Name } else { Add-Failure -Name $Name -Detail $Detail }
}

function Assert-Equal {
    param([string]$Name, $Actual, $Expected)
    if ($Actual -eq $Expected) { Add-Pass -Name $Name } else { Add-Failure -Name $Name -Detail "Expected '$Expected'; actual '$Actual'." }
}

function Get-Inventory {
    param([Parameter(Mandatory = $true)][string]$Path)
    $root = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { return @() }
    return @(
        Get-ChildItem -LiteralPath $root -Force -Recurse |
            Sort-Object FullName |
            ForEach-Object {
                $relative = $_.FullName.Substring($root.Length + 1)
                if ($_.PSIsContainer) { "D|$relative" }
                else {
                    $hash = Get-FileSha256Safe -Path $_.FullName
                    "F|$relative|$($_.Length)|$hash"
                }
            }
    )
}

function Assert-NoInventoryChange {
    param([string]$Name, [array]$Before, [array]$After)
    $reference = @($Before | Where-Object { $null -ne $_ })
    $differenceInput = @($After | Where-Object { $null -ne $_ })
    if ($reference.Count -eq 0 -and $differenceInput.Count -eq 0) {
        Add-Pass -Name $Name
        return
    }
    $difference = @(Compare-Object -ReferenceObject $reference -DifferenceObject $differenceInput)
    Assert-True -Name $Name -Condition ($difference.Count -eq 0) -Detail ($difference | Out-String)
}

function Get-TextSha256 {
    param([string]$Text)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($encoding.GetBytes($Text)))).Replace('-', '') }
    finally { $sha.Dispose() }
}

function Get-FileSha256Safe {
    param([Parameter(Mandatory = $true)][string]$Path)
    $fullPath = if ($Path.StartsWith('\\?\')) { $Path } else { [System.IO.Path]::GetFullPath($Path) }
    $readPath = if ($fullPath.StartsWith('\\?\')) { $fullPath } elseif ($fullPath -match '^[A-Za-z]:\\') { '\\?\' + $fullPath } else { $fullPath }
    $stream = [System.IO.File]::Open($readPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '') }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Get-ProtectedTreeFingerprint {
    param([Parameter(Mandatory = $true)][string]$Path)
    # DR fingerprint: ordinal-sort native relative paths; hash each file; then
    # SHA-256 the UTF-8/no-BOM LF-joined relativePath|length|fileHash records.
    # Extended paths keep Windows PowerShell 5.1 reliable beyond MAX_PATH.
    $root = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
    $readRoot = if ($root -match '^[A-Za-z]:\\') { '\\?\' + $root } else { $root }
    $filePaths = [string[]]@([System.IO.Directory]::EnumerateFiles($readRoot, '*', [System.IO.SearchOption]::AllDirectories))
    [System.Array]::Sort($filePaths, [System.StringComparer]::Ordinal)
    $records = @($filePaths | ForEach-Object {
        $relative = $_.Substring($readRoot.Length + 1)
        $fileInfo = New-Object System.IO.FileInfo($_)
        "$relative|$($fileInfo.Length)|$(Get-FileSha256Safe -Path $_)"
    })
    $directoryPaths = [string[]]@([System.IO.Directory]::EnumerateDirectories($readRoot, '*', [System.IO.SearchOption]::AllDirectories))
    [System.Array]::Sort($directoryPaths, [System.StringComparer]::Ordinal)
    $directories = @($directoryPaths | ForEach-Object { $_.Substring($readRoot.Length + 1) })
    return [pscustomobject]@{
        FileCount = $records.Count
        FileHash = Get-TextSha256 -Text ($records -join [char]10)
        DirectoryCount = $directories.Count
        DirectoryHash = Get-TextSha256 -Text ($directories -join [char]10)
    }
}

function Write-TestText {
    param([string]$Path, [string]$Text)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { [void](New-Item -ItemType Directory -Path $parent) }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

function New-WastelandFixture {
    param([string]$Name, [switch]$LiveXml, [switch]$InstallReference)
    $root = Join-Path $temporaryRoot $Name
    [void](New-Item -ItemType Directory -Path $root)
    [System.IO.File]::WriteAllBytes((Join-Path $root '7DaysToDie.exe'), [byte[]]@())
    if ($LiveXml) {
        $entityXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<entitygroups>
  <entitygroup name="EnemyAnimalsWasteland">
    <e n="animalSnake" p="10"/>
    <e n="animalZombieVulture" p="5"/>
    <e n="animalZombieDog" p="15"/>
    <e n="animalZombieBear" p="5"/>
    <e n="animalDireWolf" p="2"/>
    <e n="none" p="50"/>
  </entitygroup>
  <entitygroup name="EnemyAnimalsWastelandNight">
    <e n="animalDireWolf" p="4"/>
    <e n="animalZombieBear" p="10"/>
    <e n="none" p="60"/>
  </entitygroup>
</entitygroups>
'@
        $spawningXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<spawning>
  <biome name="wasteland">
    <spawn entitygroup="EnemyAnimalsWasteland" maxcount="1" respawndelay="0.9,1.575,1.215,0.9,0.585,0.315"/>
    <spawn entitygroup="EnemyAnimalsWastelandNight" maxcount="1" respawndelay="0.6,1.05,0.81,0.6,0.39,0.21"/>
  </biome>
</spawning>
'@
        Write-TestText -Path (Join-Path $root 'Data\Config\entitygroups.xml') -Text $entityXml
        Write-TestText -Path (Join-Path $root 'Data\Config\spawning.xml') -Text $spawningXml
        Write-TestText -Path (Join-Path $root 'serverconfig.xml') -Text '<ServerSettings><property name="MaxSpawnedAnimals" value="50"/></ServerSettings>'
    }
    if ($InstallReference) {
        $source = Join-Path $templateRoot 'framework_reference_4.1.1\Support_Files_Do_Not_Edit\BitWrecked_7DTD_WastelandAnimalPopulationTuning'
        $mods = Join-Path $root 'Mods'
        [void](New-Item -ItemType Directory -Path $mods)
        Copy-Item -LiteralPath $source -Destination $mods -Recurse
    }
    return $root
}

function Invoke-DefinitionReadOnly {
    param([object]$Definition, [string]$Root, [long]$Generation = 1)
    $request = New-BitWreckedValidationRequest -ModuleId $Definition.Id -RequestId ([guid]::NewGuid().ToString('N')) -ContextGeneration $Generation -GameRoot $Root
    return Invoke-BitWreckedModuleValidation -Definition $Definition -Request $request
}

try {
    [void](New-Item -ItemType Directory -Path $temporaryRoot)

    Assert-Equal -Name 'Windows PowerShell major version' -Actual $PSVersionTable.PSVersion.Major -Expected 5
    Assert-Equal -Name 'Windows PowerShell Desktop edition' -Actual $PSVersionTable.PSEdition -Expected 'Desktop'
    Assert-Equal -Name 'STA apartment' -Actual ([System.Threading.Thread]::CurrentThread.ApartmentState) -Expected 'STA'

    $requiredFiles = @(
        $hostScript,
        $launcher,
        (Join-Path $moduleHostRoot 'MODULE_HOST_README.md'),
        $contractScript,
        (Join-Path $moduleHostRoot 'modules\BlankFramework.Module.ps1'),
        (Join-Path $moduleHostRoot 'modules\WastelandAnimals411.ReadOnly.Module.ps1'),
        (Join-Path $moduleHostRoot 'modules\OffenseWeaponsDesign.Module.ps1'),
        (Join-Path $templateRoot 'MODULE_HOST_COMPARISON_MATRIX_0.0.1.md'),
        (Join-Path $templateRoot 'MODULE_HOST_IMPLEMENTATION_REPORT_0.0.1.md'),
        (Join-Path $moduleHostRoot 'tests\MANUAL_ACCESSIBILITY_CHECKLIST_0.0.1.md')
    )
    foreach ($required in $requiredFiles) {
        Assert-True -Name "Required file exists: $([System.IO.Path]::GetFileName($required))" -Condition (Test-Path -LiteralPath $required -PathType Leaf)
    }

    $productionScripts = @($hostScript) + @(Get-ChildItem -LiteralPath (Join-Path $moduleHostRoot 'modules') -Filter '*.ps1' | Select-Object -ExpandProperty FullName)
    foreach ($scriptPath in $productionScripts) {
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
        Assert-Equal -Name "Parses: $([System.IO.Path]::GetFileName($scriptPath))" -Actual @($parseErrors).Count -Expected 0
        $head = (Get-Content -LiteralPath $scriptPath -TotalCount 5) -join ' '
        Assert-True -Name "GPL header: $([System.IO.Path]::GetFileName($scriptPath))" -Condition ($head -match 'SPDX-License-Identifier:\s*GPL-3.0-or-later')
    }

    . $hostScript -LibraryOnly
    $loaded = Import-BitWreckedAllowlistedModules -ModuleHostRoot $moduleHostRoot -TemplateRoot $templateRoot
    Assert-Equal -Name 'Registry has zero errors' -Actual @($loaded.Errors).Count -Expected 0
    Assert-Equal -Name 'Registry has exactly three definitions' -Actual @($loaded.Definitions).Count -Expected 3
    Assert-Equal -Name 'Registry ID order' -Actual (@($loaded.Definitions.Id) -join ',') -Expected 'blank_framework,wasteland_animals_411,offense_weapons_design'
    Assert-Equal -Name 'Literal allowlist has exactly three files' -Actual @($loaded.AllowlistedFiles).Count -Expected 3
    foreach ($definition in $loaded.Definitions) {
        Assert-Equal -Name "$($definition.Id) write boundary" -Actual $definition.WriteBoundary -Expected 'none in this build'
        Assert-Equal -Name "$($definition.Id) capabilities" -Actual (@($definition.Capabilities) -join ',') -Expected 'render,validate_read_only'
        $state = & $definition.NewSessionState
        $context = [pscustomobject]@{
            SelectedGameRoot = ''
            WorkspacePanel = $null
            ModuleSessionState = $state
            Log = { param($Message, $Severity) }
            RequestUiRefresh = { }
        }
        $actions = @(& $definition.GetActionState $context)
        Assert-Equal -Name "$($definition.Id) exposes one action" -Actual $actions.Count -Expected 1
        Assert-Equal -Name "$($definition.Id) action is validate" -Actual $actions[0].Id -Expected 'validate'
        Assert-Equal -Name "$($definition.Id) action is read-only" -Actual $actions[0].Kind -Expected 'read_only'
    }

    $badDefinition = $loaded.Definitions[0].PSObject.Copy()
    $badDefinition.PSObject.Properties.Remove('Description')
    $badDefinitionCheck = Test-BitWreckedModuleDefinition -Definition $badDefinition -TemplateRoot $templateRoot
    Assert-True -Name 'Contract rejects missing field' -Condition (-not $badDefinitionCheck.IsValid)

    $requestForBadResult = New-BitWreckedValidationRequest -ModuleId 'synthetic' -RequestId 'expected' -ContextGeneration 3 -GameRoot $temporaryRoot
    $badResultDefinition = [pscustomobject]@{
        ValidateReadOnly = {
            param($Request)
            return [pscustomobject]@{
                ModuleId = 'wrong'; RequestId = 'wrong'; ContextGeneration = 4; GameRoot = $Request.GameRoot
                Status = 'bogus'; Summary = 'fake'; Details = @(); Observations = $null
                CompletedAtUtc = 'not-a-date'; NoChangesMade = 'false'
            }
        }
    }
    $rejectedResult = Invoke-BitWreckedModuleValidation -Definition $badResultDefinition -Request $requestForBadResult
    Assert-Equal -Name 'Contract converts forged result to error' -Actual $rejectedResult.Status -Expected 'error'
    Assert-True -Name 'Contract reports result correlation failure' -Condition ($rejectedResult.Summary -match 'did not match|unsupported|timestamp|affirm')

    $rogueRoot = Join-Path $temporaryRoot 'rogue-host'
    [void](New-Item -ItemType Directory -Path (Join-Path $rogueRoot 'modules') -Force)
    Copy-Item -Path (Join-Path $moduleHostRoot 'modules\*.ps1') -Destination (Join-Path $rogueRoot 'modules')
    Write-TestText -Path (Join-Path $rogueRoot 'modules\Rogue.Module.ps1') -Text '$env:BITWRECKED_ROGUE_EXECUTED = "yes"'
    [System.Environment]::SetEnvironmentVariable('BITWRECKED_ROGUE_EXECUTED', $null, 'Process')
    $rogueLoad = Import-BitWreckedAllowlistedModules -ModuleHostRoot $rogueRoot -TemplateRoot $templateRoot
    Assert-Equal -Name 'Rogue sibling is not executed' -Actual ([System.Environment]::GetEnvironmentVariable('BITWRECKED_ROGUE_EXECUTED', 'Process')) -Expected $null
    Assert-Equal -Name 'Rogue sibling is not registered' -Actual @($rogueLoad.Definitions).Count -Expected 3

    $invalidRoot = Join-Path $temporaryRoot 'invalid-root'
    [void](New-Item -ItemType Directory -Path $invalidRoot)
    foreach ($definition in $loaded.Definitions) {
        $before = Get-Inventory -Path $invalidRoot
        $result = Invoke-DefinitionReadOnly -Definition $definition -Root $invalidRoot
        $after = Get-Inventory -Path $invalidRoot
        Assert-Equal -Name "$($definition.Id) rejects invalid root" -Actual $result.Status -Expected 'invalid'
        Assert-NoInventoryChange -Name "$($definition.Id) invalid-root no-write" -Before $before -After $after
    }

    foreach ($remoteRoot in @('\\server\share', '\\?\C:\device-test', '\\.\C:\device-test')) {
        foreach ($definition in $loaded.Definitions) {
            $result = Invoke-DefinitionReadOnly -Definition $definition -Root $remoteRoot
            Assert-Equal -Name "$($definition.Id) rejects non-local path $remoteRoot" -Actual $result.Status -Expected 'invalid'
        }
    }

    $exeOnly = New-WastelandFixture -Name 'exe-only'
    $before = Get-Inventory -Path $exeOnly
    $blankResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[0] -Root $exeOnly
    $animalUnavailable = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $exeOnly
    $weaponsResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[2] -Root $exeOnly
    $after = Get-Inventory -Path $exeOnly
    Assert-Equal -Name 'Blank recognizes executable-only root' -Actual $blankResult.Status -Expected 'success'
    Assert-Equal -Name 'Weapons recognizes executable-only root' -Actual $weaponsResult.Status -Expected 'success'
    Assert-Equal -Name 'Animals is honest when live XML unavailable' -Actual $animalUnavailable.Status -Expected 'unavailable'
    Assert-True -Name 'Validation does not create Mods folder' -Condition (-not (Test-Path -LiteralPath (Join-Path $exeOnly 'Mods')))
    Assert-NoInventoryChange -Name 'Executable-only fixture remains unchanged' -Before $before -After $after

    $liveMissing = New-WastelandFixture -Name 'live-missing' -LiveXml
    $before = Get-Inventory -Path $liveMissing
    $liveMissingResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $liveMissing
    $after = Get-Inventory -Path $liveMissing
    Assert-Equal -Name 'Live baseline recognized' -Actual $liveMissingResult.Observations.LiveState -Expected 'Live'
    Assert-Equal -Name 'Missing install distinguished' -Actual $liveMissingResult.Observations.InstallState -Expected 'Missing'
    Assert-Equal -Name 'Animal adapter returns five rows' -Actual @($liveMissingResult.Observations.AnimalRows).Count -Expected 5
    Assert-NoInventoryChange -Name 'Live missing-mod validation has zero writes' -Before $before -After $after

    $exactInstall = New-WastelandFixture -Name 'exact-install' -LiveXml -InstallReference
    $before = Get-Inventory -Path $exactInstall
    $exactResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $exactInstall
    $after = Get-Inventory -Path $exactInstall
    Assert-Equal -Name 'Frozen 4.1.1 package is exact reference' -Actual $exactResult.Observations.InstallState -Expected 'ExactReference'
    Assert-Equal -Name 'Exact package validation succeeds' -Actual $exactResult.Status -Expected 'success'
    Assert-Equal -Name 'Exact package renders five animals' -Actual @($exactResult.Observations.AnimalRows).Count -Expected 5
    Assert-Equal -Name 'Frozen default package has zero pressure routes' -Actual $exactResult.Observations.PressureRouteCount -Expected 0
    Assert-NoInventoryChange -Name 'Exact install validation has zero writes' -Before $before -After $after

    $malformedInstall = New-WastelandFixture -Name 'malformed-install' -LiveXml -InstallReference
    Write-TestText -Path (Join-Path $malformedInstall 'Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning\Config\entitygroups.xml') -Text '<configs><set'
    $before = Get-Inventory -Path $malformedInstall
    $malformedResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $malformedInstall
    $after = Get-Inventory -Path $malformedInstall
    Assert-Equal -Name 'Malformed installed XML is invalid' -Actual $malformedResult.Observations.InstallState -Expected 'PresentInvalid'
    Assert-Equal -Name 'Malformed installed XML is unavailable' -Actual $malformedResult.Status -Expected 'unavailable'
    Assert-NoInventoryChange -Name 'Malformed install validation has zero writes' -Before $before -After $after

    $wrongVersion = New-WastelandFixture -Name 'wrong-version' -LiveXml -InstallReference
    $modInfoPath = Join-Path $wrongVersion 'Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning\ModInfo.xml'
    Write-TestText -Path $modInfoPath -Text ([System.IO.File]::ReadAllText($modInfoPath).Replace('4.1.1', '4.0.0'))
    $wrongVersionResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $wrongVersion
    Assert-Equal -Name 'Wrong installed version is invalid' -Actual $wrongVersionResult.Observations.InstallState -Expected 'PresentInvalid'
    Assert-Equal -Name 'Detected wrong version is reported' -Actual $wrongVersionResult.Observations.InstalledVersion -Expected '4.0.0'

    $duplicateInstall = New-WastelandFixture -Name 'duplicate-install' -LiveXml -InstallReference
    $duplicatePath = Join-Path $duplicateInstall 'Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning\Config\entitygroups.xml'
    $duplicateText = [System.IO.File]::ReadAllText($duplicatePath)
    $extraSet = '<set xpath="/entitygroups/entitygroup[@name=''EnemyAnimalsWasteland'']/e[@n=''animalSnake'']/@p">10</set><set xpath="/unknown/@p">1</set></configs>'
    Write-TestText -Path $duplicatePath -Text ($duplicateText.Replace('</configs>', $extraSet))
    $duplicateResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $duplicateInstall
    Assert-Equal -Name 'Duplicate and unknown set target is invalid' -Actual $duplicateResult.Observations.InstallState -Expected 'PresentInvalid'
    Assert-True -Name 'Duplicate target is named' -Condition ((@($duplicateResult.Details) -join ' ') -match 'Duplicate set targets')
    Assert-True -Name 'Unknown target is named' -Condition ((@($duplicateResult.Details) -join ' ') -match 'Unexpected set targets')

    $customInstall = New-WastelandFixture -Name 'custom-install' -LiveXml -InstallReference
    $customPath = Join-Path $customInstall 'Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning\Config\entitygroups.xml'
    $customText = [System.IO.File]::ReadAllText($customPath).Replace('animalSnake'']/@p">10', 'animalSnake'']/@p">30')
    Write-TestText -Path $customPath -Text $customText
    $customResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $customInstall
    Assert-Equal -Name 'Custom generated-shaped install remains unverified' -Actual $customResult.Observations.InstallState -Expected 'PresentRecognizedUnverified'
    Assert-Equal -Name 'Custom install does not receive success' -Actual $customResult.Status -Expected 'unavailable'
    Assert-True -Name 'Custom current values are not presented as verified' -Condition (@($customResult.Observations.AnimalRows | Where-Object { $_.Current -eq 'Unavailable' }).Count -eq 5)

    $driftInstall = New-WastelandFixture -Name 'drift-install' -LiveXml -InstallReference
    $liveEntityPath = Join-Path $driftInstall 'Data\Config\entitygroups.xml'
    $liveEntityText = [System.IO.File]::ReadAllText($liveEntityPath).Replace('n="animalSnake" p="10"', 'n="animalSnake" p="11"')
    Write-TestText -Path $liveEntityPath -Text $liveEntityText
    $driftResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $driftInstall
    Assert-Equal -Name 'Frozen package versus changed live baseline is Drift' -Actual $driftResult.Observations.InstallState -Expected 'Drift'
    Assert-Equal -Name 'Drift is unavailable rather than parity success' -Actual $driftResult.Status -Expected 'unavailable'

    $extraRoster = New-WastelandFixture -Name 'extra-roster' -LiveXml
    $extraRosterPath = Join-Path $extraRoster 'Data\Config\entitygroups.xml'
    $extraRosterText = [System.IO.File]::ReadAllText($extraRosterPath).Replace('<e n="none" p="50"/>', '<e n="animalUnreviewed" p="1"/><e n="none" p="50"/>')
    Write-TestText -Path $extraRosterPath -Text $extraRosterText
    $extraRosterResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $extraRoster
    Assert-Equal -Name 'Unreviewed live animal roster is shape mismatch' -Actual $extraRosterResult.Observations.LiveState -Expected 'ShapeMismatch'
    Assert-Equal -Name 'Unreviewed live roster is unavailable' -Actual $extraRosterResult.Status -Expected 'unavailable'

    $wrongAppend = New-WastelandFixture -Name 'wrong-append' -LiveXml -InstallReference
    $wrongAppendPath = Join-Path $wrongAppend 'Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning\Config\spawning.xml'
    $wrongAppendText = [System.IO.File]::ReadAllText($wrongAppendPath).Replace('</configs>', '<append xpath="/spawning/biome[@name=''forest'']"><spawn id="bw_asn1" maxcount="1" respawndelay="1" time="Any" entitygroup="animalSnake"/></append></configs>')
    Write-TestText -Path $wrongAppendPath -Text $wrongAppendText
    $wrongAppendResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $wrongAppend
    Assert-Equal -Name 'Foreign pressure append target is invalid' -Actual $wrongAppendResult.Observations.InstallState -Expected 'PresentInvalid'

    $recognizedPressure = New-WastelandFixture -Name 'recognized-pressure' -LiveXml -InstallReference
    $pressurePath = Join-Path $recognizedPressure 'Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning\Config\spawning.xml'
    $pressureText = [System.IO.File]::ReadAllText($pressurePath).Replace('</configs>', '<append xpath="/spawning/biome[@name=''wasteland'']"><spawn id="bw_asn1" maxcount="1" respawndelay="1" time="Any" entitygroup="animalSnake"/></append></configs>')
    Write-TestText -Path $pressurePath -Text $pressureText
    $pressureResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $recognizedPressure
    Assert-Equal -Name 'Custom pressure route is recognized but unverified' -Actual $pressureResult.Observations.InstallState -Expected 'PresentRecognizedUnverified'
    Assert-Equal -Name 'Recognized pressure route count' -Actual $pressureResult.Observations.PressureRouteCount -Expected 1

    $malformedCap = New-WastelandFixture -Name 'malformed-cap' -LiveXml
    Write-TestText -Path (Join-Path $malformedCap 'serverconfig.BitWreckedAnimalCapBackup-99999999-999999.xml') -Text '<ServerSettings><property'
    $capResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $malformedCap
    Assert-Equal -Name 'Malformed newest cap backup is surfaced' -Actual $capResult.Observations.CapState.State -Expected 'Unavailable'
    Assert-True -Name 'Malformed cap detail is present' -Condition ((@($capResult.Details) -join ' ') -match 'Newest cap backup')

    $dtdFixture = New-WastelandFixture -Name 'dtd-fixture' -LiveXml
    Write-TestText -Path (Join-Path $dtdFixture 'Data\Config\entitygroups.xml') -Text '<!DOCTYPE entitygroups [<!ENTITY xxe SYSTEM "file:///C:/Windows/win.ini">]><entitygroups>&xxe;</entitygroups>'
    $dtdResult = Invoke-DefinitionReadOnly -Definition $loaded.Definitions[1] -Root $dtdFixture
    Assert-Equal -Name 'DTD-bearing XML is not loaded' -Actual $dtdResult.Observations.LiveState -Expected 'ShapeMismatch'
    Assert-Equal -Name 'DTD-bearing XML is unavailable' -Actual $dtdResult.Status -Expected 'unavailable'

    [System.Windows.Forms.Application]::EnableVisualStyles()
    $navigationBefore = Get-Inventory -Path $liveMissing
    $navigationWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $runtime = New-BitWreckedModuleHostRuntime -InitialGameRoot $liveMissing
    $navigationWatch.Stop()
    $script:Metrics.ColdShellMs = [Math]::Round($navigationWatch.Elapsed.TotalMilliseconds, 2)
    Assert-Equal -Name 'Initial host module is Blank' -Actual $runtime.CurrentDefinition.Id -Expected 'blank_framework'
    Assert-Equal -Name 'Initial host renders only one lazy page' -Actual $runtime.Pages.Count -Expected 1
    $rootBeforeSwitch = $runtime.SelectedGameRoot
    Show-BitWreckedModule -Definition $runtime.Definitions[2] -ReturnFocus:$false
    Show-BitWreckedModule -Definition $runtime.Definitions[1] -ReturnFocus:$false
    Show-BitWreckedModule -Definition $runtime.Definitions[0] -ReturnFocus:$false
    $navigationAfter = Get-Inventory -Path $liveMissing
    Assert-Equal -Name 'Navigation lazily rendered all three pages' -Actual $runtime.Pages.Count -Expected 3
    Assert-Equal -Name 'Navigation preserves game-root context' -Actual $runtime.SelectedGameRoot -Expected $rootBeforeSwitch
    Assert-Equal -Name 'Three switches add exactly three host entries' -Actual $runtime.ActivityState.Events.Count -Expected 4
    Assert-Equal -Name 'Navigation starts no validation' -Actual $runtime.PendingValidations.Count -Expected 0
    Assert-NoInventoryChange -Name 'Navigation changes no fixture files or directories' -Before $navigationBefore -After $navigationAfter
    $switchMaximum = ($runtime.SwitchMeasurements | Measure-Object -Maximum).Maximum
    $script:Metrics.MaxSwitchMs = [Math]::Round([double]$switchMaximum, 2)
    Assert-True -Name 'Cold shell is usable within 3 seconds' -Condition ($navigationWatch.Elapsed.TotalMilliseconds -lt 3000)
    Assert-True -Name 'Every switch is under 1 second first-render ceiling' -Condition ([double]$switchMaximum -lt 1000)

    $accessibilityFindings = @(Get-BitWreckedAccessibilityFindings -Form $runtime.Form)
    Assert-Equal -Name 'Automated accessibility-name audit' -Actual $accessibilityFindings.Count -Expected 0
    Assert-Equal -Name 'Form is DPI-aware' -Actual $runtime.Form.AutoScaleMode -Expected ([System.Windows.Forms.AutoScaleMode]::Dpi)
    Assert-Equal -Name 'Adapter host width' -Actual $runtime.Controls.ModulePageHost.Width -Expected 640
    Assert-Equal -Name 'Adapter host height' -Actual $runtime.Controls.ModulePageHost.Height -Expected 300
    $tabOrder = @(
        $runtime.Controls.ModuleSelector.TabIndex,
        $runtime.Controls.GameRootText.TabIndex,
        $runtime.Controls.BrowseButton.TabIndex,
        $runtime.Controls.ActionButton.TabIndex,
        $runtime.Controls.LogToggle.TabIndex,
        $runtime.Controls.PersistentCheck.TabIndex,
        $runtime.Controls.ChooseLogButton.TabIndex,
        $runtime.Controls.ActivityLog.TabIndex,
        $runtime.Controls.CloseButton.TabIndex
    ) -join ','
    Assert-Equal -Name 'Primary tab order is deterministic' -Actual $tabOrder -Expected '0,1,2,3,4,5,6,7,8'
    $highContrastPalette = Get-BitWreckedPalette -ForceHighContrast
    Assert-True -Name 'High-contrast path uses system colors' -Condition ($highContrastPalette.HighContrast -and $highContrastPalette.Text -eq [System.Drawing.SystemColors]::ControlText)
    $columnHeaders = @(Get-BitWreckedDescendantControls -Parent $runtime.Form | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.AccessibleName -like 'Column:*' })
    Assert-True -Name 'Dynamic column headers have ColumnHeader roles' -Condition (@($columnHeaders | Where-Object { $_.AccessibleRole -ne [System.Windows.Forms.AccessibleRole]::ColumnHeader }).Count -eq 0 -and $columnHeaders.Count -ge 5)
    $animalLabels = @(Get-BitWreckedDescendantControls -Parent $runtime.Form | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.AccessibleName -like 'Animal:*' })
    Assert-Equal -Name 'Five animals have five named accessible cells each' -Actual $animalLabels.Count -Expected 25
    Assert-True -Name 'Status communicates state in text' -Condition ($runtime.Controls.StatusText.Text -match 'Read-only|Design')
    $runtime.Form.Close()
    $runtime.Form.Dispose()

    $logDirectory = Join-Path $temporaryRoot 'selected-log'
    [void](New-Item -ItemType Directory -Path $logDirectory)
    $logPath = Join-Path $logDirectory 'activity.log'
    $activity = New-BitWreckedActivityState
    [void](Set-BitWreckedPersistentLog -State $activity -Path $logPath -Enable $false)
    [void](Add-BitWreckedActivity -State $activity -Tag 'Host' -Message ('path selected' + [Environment]::NewLine + 'but off'))
    Assert-True -Name 'Selecting log path without consent writes nothing' -Condition (-not (Test-Path -LiteralPath $logPath))
    [void](Set-BitWreckedPersistentLog -State $activity -Path $logPath -Enable $true)
    [void](Add-BitWreckedActivity -State $activity -Tag 'Host' -Message ('persistent line' + [Environment]::NewLine + 'remains tagged'))
    Assert-True -Name 'Explicit persistent log writes selected file' -Condition (Test-Path -LiteralPath $logPath -PathType Leaf)
    $writtenLog = [System.IO.File]::ReadAllText($logPath)
    Assert-Equal -Name 'Persistent log has one physical tagged line' -Actual @($writtenLog.TrimEnd() -split '[\r\n]+').Count -Expected 1
    Assert-True -Name 'Persistent log line is tagged' -Condition ($writtenLog -match '^\[[0-9:]+\] \[Host\]')
    $lengthBeforeOff = (Get-Item -LiteralPath $logPath).Length
    $activity.PersistentEnabled = $false
    [void](Add-BitWreckedActivity -State $activity -Tag 'Host' -Message 'runtime after off')
    Assert-Equal -Name 'Disabling persistence stops writes' -Actual (Get-Item -LiteralPath $logPath).Length -Expected $lengthBeforeOff
    $missingParentPath = Join-Path $temporaryRoot 'missing-parent\activity.log'
    $missingRejected = $false
    try { [void](Set-BitWreckedPersistentLog -State (New-BitWreckedActivityState) -Path $missingParentPath -Enable $true) } catch { $missingRejected = $true }
    Assert-True -Name 'Persistent log does not create parent directories' -Condition ($missingRejected -and -not (Test-Path -LiteralPath (Split-Path -Parent $missingParentPath)))
    $gameLogRejected = $false
    try { [void](Set-BitWreckedPersistentLog -State (New-BitWreckedActivityState) -Path (Join-Path $liveMissing 'host.log') -Enable $true -DisallowedRoot $liveMissing) } catch { $gameLogRejected = $true }
    Assert-True -Name 'Persistent log path inside game root is rejected' -Condition $gameLogRejected

    $bounded = New-BitWreckedActivityState
    $logWatch = [System.Diagnostics.Stopwatch]::StartNew()
    foreach ($index in 1..600) { [void](Add-BitWreckedActivity -State $bounded -Tag 'Host' -Message "entry $index") }
    $logWatch.Stop()
    $script:Metrics.Log600Ms = [Math]::Round($logWatch.Elapsed.TotalMilliseconds, 2)
    Assert-Equal -Name 'Full in-memory log retains 600 events' -Actual $bounded.Events.Count -Expected 600
    Assert-Equal -Name 'Visible log is bounded at 500' -Actual $bounded.VisibleEvents.Count -Expected 500
    Assert-Equal -Name 'Bounded log retains newest entry' -Actual $bounded.VisibleEvents[499].Message -Expected 'entry 600'

    $forbiddenCommands = @(
        'New-Item', 'Copy-Item', 'Remove-Item', 'Move-Item', 'Rename-Item',
        'Set-Content', 'Add-Content', 'Clear-Content', 'Out-File', 'Export-Clixml',
        'Set-ItemProperty', 'New-ItemProperty', 'Invoke-WebRequest', 'Invoke-RestMethod',
        'Start-BitsTransfer', 'Invoke-Expression', 'Set-ExecutionPolicy',
        'Register-ScheduledJob', 'Start-Job', 'Start-Process'
    )
    $unsafeCommands = New-Object System.Collections.ArrayList
    foreach ($productionPath in $productionScripts) {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($productionPath, [ref]$tokens, [ref]$parseErrors)
        $commandAsts = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)
        foreach ($commandAst in $commandAsts) {
            $commandName = $commandAst.GetCommandName()
            if ($commandName -in $forbiddenCommands) { [void]$unsafeCommands.Add("$([System.IO.Path]::GetFileName($productionPath)):$($commandAst.Extent.StartLineNumber):$commandName") }
        }
    }
    Assert-Equal -Name 'Static AST has no forbidden production commands' -Actual $unsafeCommands.Count -Expected 0
    $productionText = @($productionScripts | ForEach-Object { [System.IO.File]::ReadAllText($_) }) -join [Environment]::NewLine
    $unsafePattern = 'EncodedCommand|FromBase64String|System\.Net|WebClient|HttpClient|DownloadString|bitsadmin|certutil|Set-MpPreference|Add-MpPreference|Verb\s*=\s*RunAs|Directory\.CreateDirectory|File\.(WriteAllBytes|Delete|Copy|Move|Replace)'
    Assert-True -Name 'Static text has no network, encoding, elevation, or game writer path' -Condition ($productionText -notmatch $unsafePattern)
    $appendCount = ([regex]::Matches($productionText, 'File\]::AppendAllText')).Count
    Assert-Equal -Name 'Exactly one centralized optional writer exists' -Actual $appendCount -Expected 1
    $adapterText = @(
        'BlankFramework.Module.ps1',
        'WastelandAnimals411.ReadOnly.Module.ps1',
        'OffenseWeaponsDesign.Module.ps1'
    ) | ForEach-Object { [System.IO.File]::ReadAllText((Join-Path $moduleHostRoot "modules\$_")) }
    Assert-True -Name 'No adapter contains persistent writer' -Condition ((@($adapterText) -join ' ') -notmatch 'AppendAllText|WriteAllText|Set-Content|Add-Content|Out-File')
    $contractText = [System.IO.File]::ReadAllText($contractScript)
    Assert-True -Name 'Registry contains no modules-directory scan' -Condition ($contractText -notmatch 'Get-ChildItem.+modules')

    $launcherText = [System.IO.File]::ReadAllText($launcher)
    Assert-True -Name 'Launcher resolves relative to itself' -Condition ($launcherText -match '%~dp0BitWrecked_ModuleHost_Tool\.ps1')
    Assert-True -Name 'Launcher uses NoProfile STA fixed file' -Condition ($launcherText -match 'powershell\.exe -NoProfile -STA -File')
    Assert-True -Name 'Launcher preserves exit code' -Condition ($launcherText -match 'exit /b')
    Assert-True -Name 'Launcher has no bypass, encoding, elevation, or pause' -Condition ($launcherText -notmatch 'ExecutionPolicy|EncodedCommand|runas|pause')

    $asyncBefore = Get-Inventory -Path $liveMissing
    $asyncRuntime = New-BitWreckedModuleHostRuntime -InitialGameRoot $liveMissing -ValidationDelayMs 1500
    $ackWatch = [System.Diagnostics.Stopwatch]::StartNew()
    Start-BitWreckedReadOnlyValidation
    $ackWatch.Stop()
    $script:Metrics.ValidationAckMs = [Math]::Round($ackWatch.Elapsed.TotalMilliseconds, 2)
    Assert-True -Name 'Validation acknowledgement is under 500 ms' -Condition ($ackWatch.Elapsed.TotalMilliseconds -lt 500)
    Assert-Equal -Name 'One fixed validation worker is pending' -Actual $asyncRuntime.PendingValidations.Count -Expected 1
    $heartbeat = [pscustomobject]@{ Count = 0 }
    $heartbeatTimer = New-Object System.Windows.Forms.Timer
    $heartbeatTimer.Interval = 50
    $heartbeatTimer.Add_Tick({ $heartbeat.Count++ }.GetNewClosure())
    $heartbeatTimer.Start()
    Show-BitWreckedModule -Definition $asyncRuntime.Definitions[1] -ReturnFocus:$false
    Show-BitWreckedModule -Definition $asyncRuntime.Definitions[0] -ReturnFocus:$false
    $waitWatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($asyncRuntime.PendingValidations.Count -gt 0 -and $waitWatch.Elapsed.TotalSeconds -lt 8) {
        [System.Windows.Forms.Application]::DoEvents()
        [System.Threading.Thread]::Sleep(25)
    }
    $waitWatch.Stop()
    $heartbeatTimer.Stop()
    $heartbeatTimer.Dispose()
    $asyncAfter = Get-Inventory -Path $liveMissing
    $script:Metrics.ValidationWorkerMs = [Math]::Round($waitWatch.Elapsed.TotalMilliseconds, 2)
    $script:Metrics.UiHeartbeatCount = $heartbeat.Count
    Assert-Equal -Name 'Delayed worker completes' -Actual $asyncRuntime.PendingValidations.Count -Expected 0
    Assert-True -Name 'UI heartbeat continues during delayed validation' -Condition ($heartbeat.Count -ge 10)
    Assert-True -Name 'Switched-away-and-back result is logged stale' -Condition ((@($asyncRuntime.ActivityState.Events.Message) -join ' ') -match 'Discarded stale')
    Assert-Equal -Name 'Stale result never enters Blank session' -Actual $asyncRuntime.Sessions['blank_framework'].LastValidation -Expected $null
    Assert-NoInventoryChange -Name 'Background validation changes no fixture content' -Before $asyncBefore -After $asyncAfter

    $correlationResult = New-BitWreckedValidationResult -ModuleId 'blank_framework' -RequestId 'request-a' -ContextGeneration 11 -GameRoot $liveMissing -Status 'success' -Summary 'test' -Details @()
    Assert-True -Name 'Current-result gate accepts exact correlation' -Condition (Test-BitWreckedValidationResultCurrent -Result $correlationResult -ActiveModuleId 'blank_framework' -ActiveRequestId 'request-a' -ContextGeneration 11 -SelectedGameRoot $liveMissing)
    $wrongModuleResult = $correlationResult.PSObject.Copy()
    $wrongModuleResult.ModuleId = 'offense_weapons_design'
    Assert-True -Name 'Current-result gate rejects module mismatch' -Condition (-not (Test-BitWreckedValidationResultCurrent -Result $wrongModuleResult -ActiveModuleId 'blank_framework' -ActiveRequestId 'request-a' -ContextGeneration 11 -SelectedGameRoot $liveMissing))
    $wrongRequestResult = $correlationResult.PSObject.Copy()
    $wrongRequestResult.RequestId = 'request-b'
    Assert-True -Name 'Current-result gate rejects request mismatch' -Condition (-not (Test-BitWreckedValidationResultCurrent -Result $wrongRequestResult -ActiveModuleId 'blank_framework' -ActiveRequestId 'request-a' -ContextGeneration 11 -SelectedGameRoot $liveMissing))
    $wrongGenerationResult = $correlationResult.PSObject.Copy()
    $wrongGenerationResult.ContextGeneration = 12
    Assert-True -Name 'Current-result gate rejects generation mismatch' -Condition (-not (Test-BitWreckedValidationResultCurrent -Result $wrongGenerationResult -ActiveModuleId 'blank_framework' -ActiveRequestId 'request-a' -ContextGeneration 11 -SelectedGameRoot $liveMissing))
    $wrongRootResult = $correlationResult.PSObject.Copy()
    $wrongRootResult.GameRoot = $exactInstall
    Assert-True -Name 'Current-result gate rejects root mismatch' -Condition (-not (Test-BitWreckedValidationResultCurrent -Result $wrongRootResult -ActiveModuleId 'blank_framework' -ActiveRequestId 'request-a' -ContextGeneration 11 -SelectedGameRoot $liveMissing))
    $asyncRuntime.Form.Close()
    $asyncRuntime.Form.Dispose()

    $protectedTrees = @(
        [pscustomobject]@{ Name = 'blank_working_example'; Path = Join-Path $templateRoot 'blank_working_example'; Files = 5; FileHash = '1FB39FEB46968BFD2959C7C6DD9DB85859A2E2CDD33B443D216325FA843D7150'; Directories = 1; DirectoryHash = '2D13F862B7EB9B53B7F8C888DA9DE6B5F6E4A2FE68236CA923A16F9A14DD6E41' },
        [pscustomobject]@{ Name = 'framework_reference_4.1.1'; Path = Join-Path $templateRoot 'framework_reference_4.1.1'; Files = 67; FileHash = '8EA1D17329DC40ACDAC80BD0D83E38797C1317897C3776880EA5E540FF9D6388'; Directories = 19; DirectoryHash = '03F76566035E292020CE216AB5E8AC7B2CE2B21470130F5EDE09E6ABB5BCCB6B' },
        [pscustomobject]@{ Name = 'offense_weapons_design'; Path = Join-Path $solutionsRoot 'bit_wrecked_offense_weapons_design'; Files = 111; FileHash = '5BC91F51EF0C14812EDEC0A3AC6CBAA3ADC025971BE0E0696EC962DDEF834FD3'; Directories = 30; DirectoryHash = 'F70FDFEAD11883879118CE692EDA804A50CB006E154F0CB85DE9A21D921DBE41' },
        [pscustomobject]@{ Name = 'offense_weapons_solution'; Path = Join-Path $solutionsRoot 'bit_wrecked_offense_weapons_solution'; Files = 71; FileHash = '805609D690C1653D0C19083854081FB671A427A6CB5D372F27E33993FEF71673'; Directories = 21; DirectoryHash = 'B702F4C2BF9C092E3C2B24EECB5257185A97AC938CC1E6309705A8AB51FB4ADB' },
        [pscustomobject]@{ Name = 'release_templates'; Path = Join-Path $templateRoot 'release_templates'; Files = 11; FileHash = '9228CF040E3B8F2FC3128D30F8304D114AD37B2258C2E9120B84A3FD5F56FAAD'; Directories = 0; DirectoryHash = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855' }
    )
    foreach ($protected in $protectedTrees) {
        $fingerprint = Get-ProtectedTreeFingerprint -Path $protected.Path
        Assert-Equal -Name "$($protected.Name) protected file count" -Actual $fingerprint.FileCount -Expected $protected.Files
        Assert-Equal -Name "$($protected.Name) protected file hash" -Actual $fingerprint.FileHash -Expected $protected.FileHash
        Assert-Equal -Name "$($protected.Name) protected directory count" -Actual $fingerprint.DirectoryCount -Expected $protected.Directories
        Assert-Equal -Name "$($protected.Name) protected directory hash" -Actual $fingerprint.DirectoryHash -Expected $protected.DirectoryHash
    }
    $standalonePath = Join-Path $templateRoot 'framework_reference_4.1.1\Support_Files_Do_Not_Edit\7DTD_WastelandAnimalPopulationTuning_Tool.ps1'
    Assert-Equal -Name 'Standalone Wasteland 4.1.1 tool preserved' -Actual (Get-FileSha256Safe -Path $standalonePath) -Expected '168F333A8D5A4C9CA150A40205DF2E148207DE2D1D3F978E7884E45B7C425FEF'

    $recoveryRoot = Join-Path $templateRoot 'recovery_artifacts'
    $recoveryEvidence = @(
        [pscustomobject]@{ File = 'bit_wrecked_mod_framework_template_snapshot_ux_guidance_0.0.1.zip'; Hash = 'BD85FA46EEA370C9897CDBE88D16161E098723B30ECCE6352F2CF33E850A5F7F' },
        [pscustomobject]@{ File = 'bit_wrecked_mod_framework_template_snapshot.zip'; Hash = '78EA1BCF6E301539C6FCB0189AB8874DBDD600D8F3FBCBDC45AF0EBF285AF059' },
        [pscustomobject]@{ File = 'data-config-history.bundle'; Hash = 'B1CB94D875E262C978EAA1F4907959F7DA6B7AAB71DD4C1B4830BB839684DD4E' },
        [pscustomobject]@{ File = 'root-repository-history.bundle'; Hash = '8A74D220D4B1F7165F253415E25FCA744F5449441DA9F4C96CD75B322B5D666B' }
    )
    foreach ($artifact in $recoveryEvidence) {
        Assert-Equal -Name "Recovery artifact preserved: $($artifact.File)" -Actual (Get-FileSha256Safe -Path (Join-Path $recoveryRoot $artifact.File)) -Expected $artifact.Hash
    }

    if (-not $SkipGuiSmoke) {
        $smokeWatch = [System.Diagnostics.Stopwatch]::StartNew()
        Push-Location $temporaryRoot
        try {
            $smokeOutput = @(& $launcher -SmokeTest)
            $smokeExit = $LASTEXITCODE
        }
        finally { Pop-Location }
        $smokeWatch.Stop()
        $script:Metrics.LauncherSmokeMs = [Math]::Round($smokeWatch.Elapsed.TotalMilliseconds, 2)
        Assert-Equal -Name 'Batch launcher smoke exit code' -Actual $smokeExit -Expected 0
        Assert-True -Name 'Batch launcher smoke renders all modules' -Condition ((@($smokeOutput) -join ' ') -match 'SMOKE_PASS modules=3 pages=3')
        Assert-True -Name 'Cold launcher smoke is under 3 seconds' -Condition ($smokeWatch.Elapsed.TotalMilliseconds -lt 3000)
    }
    else {
        Write-Output '[INFO] GUI launcher smoke explicitly skipped.'
    }
    Write-Output '[INFO] Accessibility automation passed; manual keyboard, Narrator, High Contrast, and 100%/150% DPI observation remain pending human checks.'
}
catch {
    Add-Failure -Name 'Unhandled acceptance exception' -Detail ($_.Exception.ToString())
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        $resolvedTemporary = [System.IO.Path]::GetFullPath($temporaryRoot)
        $allowedPrefix = $temporaryParent.TrimEnd('\') + '\BitWreckedModuleHostTests-'
        if (-not $resolvedTemporary.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refused to remove unexpected test path: $resolvedTemporary"
        }
        Remove-Item -LiteralPath $resolvedTemporary -Recurse -Force
    }
}

Write-Output ''
Write-Output "Acceptance summary: $script:PassCount passed; $($script:FailureMessages.Count) failed."
foreach ($entry in $script:Metrics.GetEnumerator()) { Write-Output "METRIC $($entry.Key)=$($entry.Value)" }
if ($script:FailureMessages.Count -gt 0) {
    foreach ($failure in $script:FailureMessages) { Write-Error $failure }
    exit 1
}
Write-Output 'MODULE_HOST_ACCEPTANCE_PASS'
exit 0
