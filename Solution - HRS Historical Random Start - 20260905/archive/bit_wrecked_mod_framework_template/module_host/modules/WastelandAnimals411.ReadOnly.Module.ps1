# Bit Wrecked Module Host - Wasteland Animals 4.1.1 read-only adapter.
# Copyright (C) 2026 Bit Wrecked contributors
# SPDX-License-Identifier: GPL-3.0-or-later

function Get-BW411ReferenceAnimalRows {
    return @(
        [pscustomobject]@{
            Id = 'dire_wolf'; DisplayName = 'Dire wolf'
            Paths = @(
                [pscustomobject]@{ Slot = 'day'; XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalDireWolf']/@p"; ReferenceValue = '2' },
                [pscustomobject]@{ Slot = 'night'; XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalDireWolf']/@p"; ReferenceValue = '4' }
            )
        },
        [pscustomobject]@{
            Id = 'snake'; DisplayName = 'Snake'
            Paths = @(
                [pscustomobject]@{ Slot = 'day'; XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalSnake']/@p"; ReferenceValue = '10' }
            )
        },
        [pscustomobject]@{
            Id = 'zombie_bear'; DisplayName = 'Zombie bear'
            Paths = @(
                [pscustomobject]@{ Slot = 'day'; XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieBear']/@p"; ReferenceValue = '5' },
                [pscustomobject]@{ Slot = 'night'; XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalZombieBear']/@p"; ReferenceValue = '10' }
            )
        },
        [pscustomobject]@{
            Id = 'zombie_dog'; DisplayName = 'Zombie dog'
            Paths = @(
                [pscustomobject]@{ Slot = 'day'; XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieDog']/@p"; ReferenceValue = '15' }
            )
        },
        [pscustomobject]@{
            Id = 'zombie_vulture'; DisplayName = 'Zombie vulture'
            Paths = @(
                [pscustomobject]@{ Slot = 'day'; XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieVulture']/@p"; ReferenceValue = '5' }
            )
        }
    )
}

function Get-BW411ReferenceNoneRows {
    return @(
        [pscustomobject]@{ XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='none']/@p"; ReferenceValue = '50' },
        [pscustomobject]@{ XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='none']/@p"; ReferenceValue = '60' }
    )
}

function Get-BW411ReferenceSpawnRows {
    return @(
        [pscustomobject]@{ XPath = "/spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWasteland']/@maxcount"; ReferenceValue = '1' },
        [pscustomobject]@{ XPath = "/spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWasteland']/@respawndelay"; ReferenceValue = '0.9,1.575,1.215,0.9,0.585,0.315' },
        [pscustomobject]@{ XPath = "/spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWastelandNight']/@maxcount"; ReferenceValue = '1' },
        [pscustomobject]@{ XPath = "/spawning/biome[@name='wasteland']/spawn[@entitygroup='EnemyAnimalsWastelandNight']/@respawndelay"; ReferenceValue = '0.6,1.05,0.81,0.6,0.39,0.21' }
    )
}

function Read-BW411XmlDocument {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{ State = 'Missing'; Path = $Path; Document = $null; Error = 'File is missing.' }
    }
    try {
        $fileInfo = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($fileInfo.Length -gt 8388608) {
            throw 'XML file exceeds the 8 MiB read-only adapter limit.'
        }
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver = $null
        $settings.MaxCharactersInDocument = 8388608
        $settings.MaxCharactersFromEntities = 0
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $reader = $null
            $reader = [System.Xml.XmlReader]::Create($stream, $settings)
            try {
                $document = New-Object System.Xml.XmlDocument
                $document.XmlResolver = $null
                $document.Load($reader)
            }
            finally {
                if ($null -ne $reader) { $reader.Dispose() }
            }
        }
        finally {
            $stream.Dispose()
        }
        return [pscustomobject]@{ State = 'Loaded'; Path = $Path; Document = $document; Error = '' }
    }
    catch {
        return [pscustomobject]@{ State = 'Malformed'; Path = $Path; Document = $null; Error = $_.Exception.Message }
    }
}

function Read-BW411LiveBaseline {
    param([Parameter(Mandatory = $true)][string]$GameRoot)

    $errors = New-Object System.Collections.ArrayList
    $animalValues = @{}
    $spawnValues = @{}
    $entityPath = Join-Path $GameRoot 'Data\Config\entitygroups.xml'
    $spawningPath = Join-Path $GameRoot 'Data\Config\spawning.xml'
    $entityRead = Read-BW411XmlDocument -Path $entityPath
    $spawningRead = Read-BW411XmlDocument -Path $spawningPath

    if ($entityRead.State -ne 'Loaded') {
        [void]$errors.Add("entitygroups.xml $($entityRead.State): $($entityRead.Error)")
    }
    else {
        $allEntityPaths = @(
            @(Get-BW411ReferenceAnimalRows | ForEach-Object { @($_.Paths) }) +
            @(Get-BW411ReferenceNoneRows)
        )
        foreach ($entry in $allEntityPaths) {
            $node = $entityRead.Document.SelectSingleNode([string]$entry.XPath)
            if ($null -eq $node) {
                [void]$errors.Add("Live entitygroup shape is missing: $($entry.XPath)")
            }
            else {
                $animalValues[[string]$entry.XPath] = [string]$node.Value
            }
        }
        $expectedByGroup = [ordered]@{
            EnemyAnimalsWasteland = @('animalDireWolf', 'animalSnake', 'animalZombieBear', 'animalZombieDog', 'animalZombieVulture')
            EnemyAnimalsWastelandNight = @('animalDireWolf', 'animalZombieBear')
        }
        foreach ($groupName in $expectedByGroup.Keys) {
            $nodes = @($entityRead.Document.SelectNodes("/entitygroups/entitygroup[@name='$groupName']/e[starts-with(@n,'animal')]"))
            $names = @($nodes | ForEach-Object { [string]$_.GetAttribute('n') })
            $duplicates = @($names | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
            $extra = @($names | Where-Object { $_ -notin $expectedByGroup[$groupName] })
            if ($duplicates.Count -gt 0) {
                [void]$errors.Add("Live $groupName contains duplicate animal rows: $($duplicates -join ', ')")
            }
            if ($extra.Count -gt 0) {
                [void]$errors.Add("Live $groupName contains unreviewed animal rows: $($extra -join ', ')")
            }
        }
    }

    if ($spawningRead.State -ne 'Loaded') {
        [void]$errors.Add("spawning.xml $($spawningRead.State): $($spawningRead.Error)")
    }
    else {
        foreach ($entry in Get-BW411ReferenceSpawnRows) {
            $node = $spawningRead.Document.SelectSingleNode([string]$entry.XPath)
            if ($null -eq $node) {
                [void]$errors.Add("Live spawning shape is missing: $($entry.XPath)")
            }
            else {
                $spawnValues[[string]$entry.XPath] = [string]$node.Value
            }
        }
    }

    return [pscustomobject]@{
        State = if ($errors.Count -eq 0) { 'Live' } else { 'ShapeMismatch' }
        Source = if ($errors.Count -eq 0) { 'Live game XML' } else { '4.1.1 reference baseline only' }
        EntityGroupsPath = $entityPath
        SpawningPath = $spawningPath
        AnimalValues = $animalValues
        SpawnValues = $spawnValues
        Errors = @($errors)
    }
}

function Read-BW411PatchValueMap {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][array]$AllowedXPaths
    )

    $read = Read-BW411XmlDocument -Path $Path
    $values = @{}
    $duplicates = New-Object System.Collections.ArrayList
    $unknown = New-Object System.Collections.ArrayList
    $errors = New-Object System.Collections.ArrayList
    if ($read.State -ne 'Loaded') {
        [void]$errors.Add("$($read.State): $($read.Error)")
        return [pscustomobject]@{ State = $read.State; Path = $Path; Values = $values; Duplicates = @(); Unknown = @(); Errors = @($errors); Document = $null }
    }

    foreach ($node in @($read.Document.SelectNodes('/configs/set'))) {
        $xpath = [string]$node.GetAttribute('xpath')
        if ([string]::IsNullOrWhiteSpace($xpath)) {
            [void]$errors.Add('A set node has no xpath attribute.')
            continue
        }
        if ($values.ContainsKey($xpath)) {
            [void]$duplicates.Add($xpath)
            continue
        }
        $values[$xpath] = [string]$node.InnerText
        if ($xpath -notin $AllowedXPaths) {
            [void]$unknown.Add($xpath)
        }
    }

    if ($duplicates.Count -gt 0) {
        [void]$errors.Add("Duplicate set targets: $($duplicates -join ', ')")
    }
    if ($unknown.Count -gt 0) {
        [void]$errors.Add("Unexpected set targets: $($unknown -join ', ')")
    }

    return [pscustomobject]@{
        State = if ($errors.Count -eq 0) { 'Loaded' } else { 'PresentInvalid' }
        Path = $Path
        Values = $values
        Duplicates = @($duplicates)
        Unknown = @($unknown)
        Errors = @($errors)
        Document = $read.Document
    }
}

function Read-BW411InstalledState {
    param(
        [Parameter(Mandatory = $true)][string]$GameRoot,
        [Parameter(Mandatory = $true)][object]$LiveBaseline
    )

    $target = Join-Path $GameRoot 'Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning'
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        return [pscustomobject]@{
            State = 'Missing'; TargetPath = $target; Version = ''; AnimalValues = @{}; SpawnValues = @{}
            PressureRouteCount = 0; RecognizedAnimalTargetCount = 0; PossibleAnimalTargetCount = 7
            ReferenceDifferences = @(); Errors = @(); Warnings = @()
        }
    }

    $errors = New-Object System.Collections.ArrayList
    $warnings = New-Object System.Collections.ArrayList
    $version = ''
    $modIdentityVerified = $false
    $modInfoPath = Join-Path $target 'ModInfo.xml'
    $modInfoRead = Read-BW411XmlDocument -Path $modInfoPath
    if ($modInfoRead.State -ne 'Loaded') {
        [void]$errors.Add("ModInfo.xml $($modInfoRead.State): $($modInfoRead.Error)")
    }
    else {
        $nameNode = $modInfoRead.Document.SelectSingleNode('/xml/Name')
        $displayNode = $modInfoRead.Document.SelectSingleNode('/xml/DisplayName')
        $versionNode = $modInfoRead.Document.SelectSingleNode('/xml/Version')
        if ($null -eq $nameNode -or [string]$nameNode.GetAttribute('value') -ne 'BitWrecked_7DTD_WastelandAnimalPopulationTuning') {
            [void]$errors.Add('ModInfo.xml Name does not identify the reviewed Wasteland Animals mod.')
        }
        if ($null -eq $displayNode -or [string]$displayNode.GetAttribute('value') -ne '7DTD 3.0 Wasteland Animal Population Tuning') {
            [void]$errors.Add('ModInfo.xml DisplayName does not match the reviewed 4.1.1 identity.')
        }
        if ($null -eq $versionNode) {
            [void]$errors.Add('ModInfo.xml has no Version node.')
        }
        else {
            $version = [string]$versionNode.GetAttribute('value')
            if ($version -ne '4.1.1') {
                [void]$errors.Add("Installed version is '$version', not the 4.1.1 parity target.")
            }
        }
        $modIdentityVerified = ($null -ne $nameNode -and [string]$nameNode.GetAttribute('value') -eq 'BitWrecked_7DTD_WastelandAnimalPopulationTuning' -and $null -ne $displayNode -and [string]$displayNode.GetAttribute('value') -eq '7DTD 3.0 Wasteland Animal Population Tuning' -and $version -eq '4.1.1')
    }

    $entityAllowed = @(
        @(Get-BW411ReferenceAnimalRows | ForEach-Object { @($_.Paths) } | ForEach-Object { [string]$_.XPath }) +
        @(Get-BW411ReferenceNoneRows | ForEach-Object { [string]$_.XPath })
    )
    $spawnAllowed = @(Get-BW411ReferenceSpawnRows | ForEach-Object { [string]$_.XPath })
    $entityPatch = Read-BW411PatchValueMap -Path (Join-Path $target 'Config\entitygroups.xml') -AllowedXPaths $entityAllowed
    $spawnPatch = Read-BW411PatchValueMap -Path (Join-Path $target 'Config\spawning.xml') -AllowedXPaths $spawnAllowed
    foreach ($message in @($entityPatch.Errors)) { [void]$errors.Add("entitygroups.xml: $message") }
    foreach ($message in @($spawnPatch.Errors)) { [void]$errors.Add("spawning.xml: $message") }

    $animalTargetCount = @($entityAllowed | Where-Object { $_ -notmatch "e\[@n='none'\]" }).Count
    $foundAnimalTargets = @($entityPatch.Values.Keys | Where-Object { $_ -notmatch "e\[@n='none'\]" }).Count
    foreach ($requiredPath in $entityAllowed) {
        if ($entityPatch.State -eq 'Loaded' -and -not $entityPatch.Values.ContainsKey([string]$requiredPath)) {
            [void]$errors.Add("entitygroups.xml is missing reviewed row: $requiredPath")
        }
    }
    foreach ($spawnRow in Get-BW411ReferenceSpawnRows) {
        if ($spawnPatch.State -eq 'Loaded' -and -not $spawnPatch.Values.ContainsKey([string]$spawnRow.XPath)) {
            [void]$errors.Add("spawning.xml is missing generated row: $($spawnRow.XPath)")
        }
    }

    foreach ($xpath in @($entityPatch.Values.Keys)) {
        $numericValue = [decimal]0
        if (-not [decimal]::TryParse([string]$entityPatch.Values[$xpath], [System.Globalization.NumberStyles]::Number, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$numericValue) -or $numericValue -lt 0) {
            [void]$errors.Add("entitygroups.xml has a non-numeric or negative value at $($xpath).")
        }
    }
    foreach ($spawnRow in Get-BW411ReferenceSpawnRows) {
        $xpath = [string]$spawnRow.XPath
        if (-not $spawnPatch.Values.ContainsKey($xpath)) { continue }
        $value = [string]$spawnPatch.Values[$xpath]
        if ($xpath.EndsWith('/@maxcount')) {
            $countValue = 0
            if (-not [int]::TryParse($value, [ref]$countValue) -or $countValue -lt 0) {
                [void]$errors.Add("spawning.xml has an invalid maxcount at $($xpath).")
            }
        }
        else {
            foreach ($piece in @($value -split ',')) {
                $delayValue = [decimal]0
                if (-not [decimal]::TryParse($piece, [System.Globalization.NumberStyles]::Number, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$delayValue) -or $delayValue -le 0) {
                    [void]$errors.Add("spawning.xml has an invalid respawndelay at $($xpath).")
                    break
                }
            }
        }
    }

    $pressureRoutes = @()
    if ($null -ne $spawnPatch.Document) {
        $appendNodes = @($spawnPatch.Document.SelectNodes('/configs/append'))
        foreach ($appendNode in $appendNodes) {
            if ([string]$appendNode.GetAttribute('xpath') -ne "/spawning/biome[@name='wasteland']") {
                [void]$errors.Add("spawning.xml has an unreviewed append target: $([string]$appendNode.GetAttribute('xpath'))")
            }
        }
        $pressureRoutes = @($spawnPatch.Document.SelectNodes("/configs/append[@xpath=`"/spawning/biome[@name='wasteland']`"]/spawn"))
        $routeIds = @{}
        $allowedGroups = @('animalDireWolf', 'animalSnake', 'animalZombieBear', 'animalZombieDog', 'animalZombieVulture')
        foreach ($route in $pressureRoutes) {
            $routeId = [string]$route.GetAttribute('id')
            $entityGroup = [string]$route.GetAttribute('entitygroup')
            if ($routeId -notmatch '^bw_[a-z0-9]+$' -or $entityGroup -notin $allowedGroups) {
                [void]$errors.Add("Invalid pressure route: id='$routeId', entitygroup='$entityGroup'.")
            }
            if ($routeIds.ContainsKey($routeId)) {
                [void]$errors.Add("Duplicate pressure route id: $routeId")
            }
            else {
                $routeIds[$routeId] = $true
            }
            $routeCount = 0
            if (-not [int]::TryParse([string]$route.GetAttribute('maxcount'), [ref]$routeCount) -or $routeCount -lt 1) {
                [void]$errors.Add("Pressure route $routeId has an invalid maxcount.")
            }
            if ([string]$route.GetAttribute('time') -notin @('Any', 'Night')) {
                [void]$errors.Add("Pressure route $routeId has an invalid time value.")
            }
            $routeDelay = [decimal]0
            if (-not [decimal]::TryParse([string]$route.GetAttribute('respawndelay'), [System.Globalization.NumberStyles]::Number, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$routeDelay) -or $routeDelay -le 0) {
                [void]$errors.Add("Pressure route $routeId has an invalid respawndelay.")
            }
        }
    }

    $differences = New-Object System.Collections.ArrayList
    if ($LiveBaseline.State -eq 'Live') {
        foreach ($xpath in @($entityPatch.Values.Keys)) {
            if ($LiveBaseline.AnimalValues.ContainsKey($xpath) -and [string]$entityPatch.Values[$xpath] -ne [string]$LiveBaseline.AnimalValues[$xpath]) {
                [void]$differences.Add("${xpath}: installed $($entityPatch.Values[$xpath]), live reference $($LiveBaseline.AnimalValues[$xpath])")
            }
        }
        foreach ($xpath in @($spawnPatch.Values.Keys)) {
            if ($LiveBaseline.SpawnValues.ContainsKey($xpath) -and [string]$spawnPatch.Values[$xpath] -ne [string]$LiveBaseline.SpawnValues[$xpath]) {
                [void]$differences.Add("${xpath}: installed $($spawnPatch.Values[$xpath]), live reference $($LiveBaseline.SpawnValues[$xpath])")
            }
        }
    }
    else {
        [void]$warnings.Add('Live XML shape was unavailable, so installed values were not compared with the live baseline.')
    }

    $expectedValues = @{}
    $allExpectedRows = @(
        @(Get-BW411ReferenceAnimalRows | ForEach-Object { @($_.Paths) }) +
        @(Get-BW411ReferenceNoneRows) +
        @(Get-BW411ReferenceSpawnRows)
    )
    foreach ($entry in $allExpectedRows) {
        $expectedValues[[string]$entry.XPath] = [string]$entry.ReferenceValue
    }
    $exactReference = $modIdentityVerified -and $errors.Count -eq 0 -and $pressureRoutes.Count -eq 0
    foreach ($xpath in @($entityAllowed + $spawnAllowed)) {
        $sourceMap = if ($entityPatch.Values.ContainsKey($xpath)) { $entityPatch.Values } else { $spawnPatch.Values }
        if (-not $sourceMap.ContainsKey($xpath) -or [string]$sourceMap[$xpath] -ne [string]$expectedValues[$xpath]) {
            $exactReference = $false
        }
    }
    $state = if ($errors.Count -gt 0) {
        'PresentInvalid'
    }
    elseif ($exactReference -and $differences.Count -gt 0) {
        'Drift'
    }
    elseif ($exactReference) {
        'ExactReference'
    }
    else {
        'PresentRecognizedUnverified'
    }

    return [pscustomobject]@{
        State = $state
        TargetPath = $target
        Version = $version
        AnimalValues = $entityPatch.Values
        SpawnValues = $spawnPatch.Values
        PressureRouteCount = $pressureRoutes.Count
        RecognizedAnimalTargetCount = $foundAnimalTargets
        PossibleAnimalTargetCount = $animalTargetCount
        ReferenceDifferences = @($differences)
        Errors = @($errors)
        Warnings = @($warnings)
    }
}

function Read-BW411GlobalCapState {
    param([Parameter(Mandatory = $true)][string]$GameRoot)

    $configPath = Join-Path $GameRoot 'serverconfig.xml'
    $current = $null
    $saved = $null
    $errors = New-Object System.Collections.ArrayList
    $configRead = Read-BW411XmlDocument -Path $configPath
    if ($configRead.State -eq 'Loaded') {
        $capNode = $configRead.Document.SelectSingleNode("//property[@name='MaxSpawnedAnimals']")
        if ($null -eq $capNode -or [string]::IsNullOrWhiteSpace([string]$capNode.GetAttribute('value'))) {
            [void]$errors.Add('serverconfig.xml has no readable MaxSpawnedAnimals value.')
        }
        else {
            $current = [string]$capNode.GetAttribute('value')
        }
    }
    elseif ($configRead.State -ne 'Missing') {
        [void]$errors.Add("serverconfig.xml $($configRead.State): $($configRead.Error)")
    }

    $backup = Get-ChildItem -LiteralPath $GameRoot -Filter 'serverconfig.BitWreckedAnimalCapBackup-*.xml' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -ne $backup) {
        $backupRead = Read-BW411XmlDocument -Path $backup.FullName
        if ($backupRead.State -eq 'Loaded') {
            $savedNode = $backupRead.Document.SelectSingleNode("//property[@name='MaxSpawnedAnimals']")
            if ($null -ne $savedNode -and -not [string]::IsNullOrWhiteSpace([string]$savedNode.GetAttribute('value'))) {
                $saved = [string]$savedNode.GetAttribute('value')
            }
            else {
                [void]$errors.Add('Newest cap backup has no readable MaxSpawnedAnimals value.')
            }
        }
        else {
            [void]$errors.Add("Newest cap backup $($backupRead.State): $($backupRead.Error)")
        }
    }

    return [pscustomobject]@{
        State = if ($errors.Count -gt 0) { 'Unavailable' } elseif ($configRead.State -eq 'Missing') { 'Missing' } else { 'Readable' }
        ConfigPath = $configPath
        CurrentValue = $current
        LatestBackupPath = if ($null -eq $backup) { '' } else { [string]$backup.FullName }
        LatestBackupValue = $saved
        LatestBackupDiffers = ($null -ne $current -and $null -ne $saved -and $current -ne $saved)
        Errors = @($errors)
    }
}

function Get-BW411LevelNameFromValues {
    param(
        [Parameter(Mandatory = $true)][object]$ReferenceRow,
        [Parameter(Mandatory = $true)][hashtable]$Values
    )

    $factors = [ordered]@{ Absent = 0.0; Sparse = 0.5; Default = 1.0; Dense = 3.0; Absurd = 8.0 }
    foreach ($name in $factors.Keys) {
        $matches = $true
        foreach ($path in @($ReferenceRow.Paths)) {
            if (-not $Values.ContainsKey([string]$path.XPath)) {
                $matches = $false
                break
            }
            $expected = ([decimal]$path.ReferenceValue * [decimal]$factors[$name]).ToString('0.##', [System.Globalization.CultureInfo]::InvariantCulture)
            if ([string]$Values[[string]$path.XPath] -ne $expected) {
                $matches = $false
                break
            }
        }
        if ($matches) { return $name }
    }
    return 'Custom'
}

function New-BW411DisplayRows {
    param(
        [Parameter(Mandatory = $true)][object]$LiveBaseline,
        [Parameter(Mandatory = $true)][object]$InstalledState
    )

    $rows = New-Object System.Collections.ArrayList
    foreach ($referenceRow in Get-BW411ReferenceAnimalRows) {
        $effectiveValues = @{}
        $installedAny = $false
        $installedUnverified = $InstalledState.State -in @('PresentInvalid', 'PresentRecognizedUnverified')
        foreach ($path in @($referenceRow.Paths)) {
            $xpath = [string]$path.XPath
            if ($InstalledState.State -in @('ExactReference', 'Drift') -and $InstalledState.AnimalValues.ContainsKey($xpath)) {
                $effectiveValues[$xpath] = [string]$InstalledState.AnimalValues[$xpath]
                $installedAny = $true
            }
            elseif (-not $installedUnverified -and $LiveBaseline.State -eq 'Live' -and $LiveBaseline.AnimalValues.ContainsKey($xpath)) {
                $effectiveValues[$xpath] = [string]$LiveBaseline.AnimalValues[$xpath]
            }
        }

        $hasCompleteValues = @($referenceRow.Paths | Where-Object { -not $effectiveValues.ContainsKey([string]$_.XPath) }).Count -eq 0
        $parts = if ($hasCompleteValues) { @($referenceRow.Paths | ForEach-Object { "$($_.Slot) $($effectiveValues[[string]$_.XPath])" }) } else { @('Unavailable') }
        $level = if ($hasCompleteValues) { Get-BW411LevelNameFromValues -ReferenceRow $referenceRow -Values $effectiveValues } elseif ($installedUnverified) { 'Unverified' } else { 'Reference only' }
        [void]$rows.Add([pscustomobject]@{
            Id = $referenceRow.Id
            DisplayName = $referenceRow.DisplayName
            PopulationLevel = $level
            Action = 'Read-only'
            Current = ($parts -join ' / ')
            Result = if ($installedUnverified) { 'Unavailable' } else { 'No changes' }
            Source = if ($installedAny) { 'Verified installed XML' } elseif ($installedUnverified) { 'Installed XML not verified' } elseif ($LiveBaseline.State -eq 'Live') { 'Live game XML' } else { '4.1.1 reference rows only' }
        })
    }
    return @($rows)
}

function New-BW411ReadOnlySnapshot {
    param([Parameter(Mandatory = $true)][object]$Request)

    $gameRoot = [string]$Request.GameRoot
    $localRoot = Resolve-BitWreckedLocalPath -Path $gameRoot
    $exePath = if (-not $localRoot.IsAllowed) { '' } else { Join-Path $localRoot.Path '7DaysToDie.exe' }
    if ([string]::IsNullOrWhiteSpace($exePath) -or -not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
        return New-BitWreckedValidationResult -ModuleId $Request.ModuleId -RequestId $Request.RequestId -ContextGeneration $Request.ContextGeneration -GameRoot $gameRoot -Status 'invalid' -Summary 'Folder not recognized as a local 7 Days to Die game root. No changes made.' -Details @($localRoot.Reason, 'Expected 7DaysToDie.exe in the selected folder.', 'No Wasteland files were changed.')
    }
    $gameRoot = $localRoot.Path

    $live = Read-BW411LiveBaseline -GameRoot $gameRoot
    $installed = Read-BW411InstalledState -GameRoot $gameRoot -LiveBaseline $live
    $cap = Read-BW411GlobalCapState -GameRoot $gameRoot
    $rows = New-BW411DisplayRows -LiveBaseline $live -InstalledState $installed
    $details = New-Object System.Collections.ArrayList
    [void]$details.Add("Live shape: $($live.State); source: $($live.Source).")
    [void]$details.Add("Installed mod: $($installed.State)$(if (-not [string]::IsNullOrWhiteSpace($installed.Version)) { "; version $($installed.Version)" } else { '' }).")
    [void]$details.Add("Global cap: $($cap.State)$(if ($null -ne $cap.CurrentValue) { "; current $($cap.CurrentValue)" } else { '' }).")
    if ($cap.LatestBackupDiffers) {
        [void]$details.Add("The newest saved cap differs from current: current $($cap.CurrentValue), saved $($cap.LatestBackupValue). This is informational only; it does not prove a pending restore, and restore remains unavailable.")
    }
    foreach ($message in @($live.Errors)) { [void]$details.Add("Live XML: $message") }
    foreach ($message in @($installed.Errors)) { [void]$details.Add("Installed state: $message") }
    foreach ($message in @($installed.ReferenceDifferences)) { [void]$details.Add("Reference comparison: $message") }
    foreach ($message in @($cap.Errors)) { [void]$details.Add("Cap state: $message") }
    [void]$details.Add('No changes were made. Standalone 4.1.1 remains the approved action path.')

    $status = 'success'
    $summary = ''
    if ($live.State -ne 'Live') {
        $status = 'unavailable'
        $summary = 'Game folder recognized, but the live 3.0-era Wasteland XML shape could not be verified. Reference rows only; no changes made.'
    }
    elseif ($installed.State -eq 'PresentInvalid') {
        $status = 'unavailable'
        $summary = 'Live Wasteland shape recognized, but the installed mod folder is invalid or incomplete. Current values are unavailable; no changes made.'
    }
    elseif ($installed.State -eq 'PresentRecognizedUnverified') {
        $status = 'unavailable'
        $summary = 'A Wasteland Animals 4.1.1-shaped custom install was recognized, but this adapter cannot prove its generated setting combination. Current values are unavailable; no changes made.'
    }
    elseif ($installed.State -eq 'Drift') {
        $status = 'unavailable'
        $summary = 'The frozen 4.1.1 package is present, but its targets differ from the live game baseline. Compatibility is unavailable; no changes made.'
    }
    elseif ($installed.State -eq 'ExactReference') {
        $summary = "Frozen Wasteland Animals 4.1.1 package verified read-only: $($installed.RecognizedAnimalTargetCount) animal targets, no pressure routes. No changes made."
    }
    else {
        $summary = 'Live Wasteland 3.0-era XML shape recognized; Wasteland Animals 4.1.1 is not installed. No changes made.'
    }

    $observations = [pscustomobject]@{
        GameRootRecognized = $true
        Provenance = $live.Source
        LiveState = $live.State
        InstallState = $installed.State
        InstalledVersion = $installed.Version
        AnimalRows = @($rows)
        PressureRouteCount = $installed.PressureRouteCount
        ReferenceDifferences = @($installed.ReferenceDifferences)
        CapState = $cap
    }
    return New-BitWreckedValidationResult -ModuleId $Request.ModuleId -RequestId $Request.RequestId -ContextGeneration $Request.ContextGeneration -GameRoot $gameRoot -Status $status -Summary $summary -Details @($details) -Observations $observations
}

function New-WastelandAnimals411ReadOnlyModule {
    $renderWorkspace = {
        param($Context)

        $panel = $Context.WorkspacePanel
        $columns = @(
            @{ Text = 'Animal Selection'; Left = 12; Width = 130 },
            @{ Text = 'Population Level'; Left = 144; Width = 124 },
            @{ Text = 'Action'; Left = 270; Width = 100 },
            @{ Text = 'Current'; Left = 372; Width = 146 },
            @{ Text = 'Result'; Left = 520; Width = 108 }
        )
        foreach ($column in $columns) {
            $header = New-BitWreckedWorkspaceLabel -Text $column.Text -Left $column.Left -Top 10 -Width $column.Width -Height 22 -AccessibleName "Column: $($column.Text)" -Bold $true
            $panel.Controls.Add($header)
        }
        $rule = New-Object System.Windows.Forms.Panel
        $rule.Location = New-Object System.Drawing.Point(12, 36)
        $rule.Size = New-Object System.Drawing.Size(616, 1)
        $rule.BackColor = if ([System.Windows.Forms.SystemInformation]::HighContrast) { [System.Drawing.SystemColors]::ControlDark } else { [System.Drawing.Color]::FromArgb(232, 230, 225) }
        $panel.Controls.Add($rule)

        $last = $Context.ModuleSessionState.LastValidation
        $lastMatchesRoot = $null -ne $last -and (Test-BitWreckedSamePath -First ([string]$last.GameRoot) -Second ([string]$Context.SelectedGameRoot))
        $displayRows = @()
        if ($lastMatchesRoot -and $null -ne $last.Observations -and $null -ne $last.Observations.AnimalRows) {
            $displayRows = @($last.Observations.AnimalRows)
        }
        else {
            $displayRows = @(Get-BW411ReferenceAnimalRows | ForEach-Object {
                [pscustomobject]@{
                    Id = $_.Id; DisplayName = $_.DisplayName; PopulationLevel = 'Reference'
                    Action = 'Read-only'; Current = 'Not validated'; Result = 'Reference only'; Source = '4.1.1 reference rows only'
                }
            })
        }

        $rowIndex = 0
        foreach ($row in $displayRows) {
            $top = 44 + ($rowIndex * 35)
            $name = New-BitWreckedWorkspaceLabel -Text ([string]$row.DisplayName) -Left 12 -Top $top -Width 130 -Height 30 -AccessibleName "Animal: $($row.DisplayName) | Column: Animal Selection" -Align 'MiddleLeft' -Bold $true
            $level = New-BitWreckedWorkspaceLabel -Text ([string]$row.PopulationLevel) -Left 144 -Top $top -Width 124 -Height 30 -AccessibleName "Animal: $($row.DisplayName) | Column: Population Level"
            $action = New-BitWreckedWorkspaceLabel -Text ([string]$row.Action) -Left 270 -Top $top -Width 100 -Height 30 -AccessibleName "Animal: $($row.DisplayName) | Column: Action"
            $current = New-BitWreckedWorkspaceLabel -Text ([string]$row.Current) -Left 372 -Top $top -Width 146 -Height 30 -AccessibleName "Animal: $($row.DisplayName) | Column: Current" -FontSize 7.5
            $result = New-BitWreckedWorkspaceLabel -Text ([string]$row.Result) -Left 520 -Top $top -Width 108 -Height 30 -AccessibleName "Animal: $($row.DisplayName) | Column: Result"
            foreach ($control in @($name, $level, $action, $current, $result)) { $panel.Controls.Add($control) }
            $rowIndex++
        }

        $summaryText = if ($null -eq $last -or -not $lastMatchesRoot) {
            'Reference rows only; no live/current values have been read for the selected folder.'
        }
        else {
            [string]$last.Summary
        }
        $summary = New-BitWreckedWorkspaceLabel -Text $summaryText -Left 20 -Top 225 -Width 600 -Height 46 -AccessibleName 'Wasteland Animals validation summary' -FontSize 7.5
        $summary.ForeColor = if ([System.Windows.Forms.SystemInformation]::HighContrast) { [System.Drawing.SystemColors]::ControlText } elseif ($lastMatchesRoot -and $last.Status -eq 'success') { [System.Drawing.Color]::FromArgb(42, 112, 72) } else { [System.Drawing.Color]::FromArgb(130, 45, 35) }
        $panel.Controls.Add($summary)

        $boundary = New-BitWreckedWorkspaceLabel -Text 'Read-only parity adapter | Standalone 4.1.1 remains the approved action path' -Left 20 -Top 270 -Width 600 -Height 24 -AccessibleName 'Wasteland Animals action boundary' -Bold $true
        $boundary.ForeColor = if ([System.Windows.Forms.SystemInformation]::HighContrast) { [System.Drawing.SystemColors]::ControlText } else { [System.Drawing.Color]::FromArgb(130, 45, 35) }
        $panel.Controls.Add($boundary)

        $Context.ModuleSessionState.RenderCount = [int]$Context.ModuleSessionState.RenderCount + 1
        return [pscustomobject]@{ DefaultFocusControl = $null; RenderedRowCount = $rowIndex }
    }

    return [pscustomobject]@{
        ContractVersion = '0.0.1'
        Id = 'wasteland_animals_411'
        DisplayName = 'Wasteland Animals 4.1.1'
        Version = '4.1.1'
        State = 'read_only'
        Description = 'Read-only parity adapter for the proven standalone Wasteland animal tuning tool.'
        SupportedGameBuild = '7 Days to Die 3.0-era Windows/Steam reference; exact compatibility requires live e/n/p and Wasteland-route shape validation.'
        Columns = @('Animal Selection', 'Population Level', 'Action', 'Current', 'Result')
        Capabilities = @('render', 'validate_read_only')
        NewSessionState = {
            return [ordered]@{
                LastValidation = $null
                LastGameRoot = ''
                RenderCount = 0
            }
        }
        RenderWorkspace = $renderWorkspace
        GetActionState = {
            param($Context)
            return @([pscustomobject]@{
                Id = 'validate'
                Label = 'Validate Current Game Settings'
                Kind = 'read_only'
                Visible = $true
                Enabled = [bool](Resolve-BitWreckedLocalPath -Path ([string]$Context.SelectedGameRoot)).IsAllowed
                UnavailableReason = 'Choose a game folder first.'
            })
        }
        ValidateReadOnly = { param($Request); return New-BW411ReadOnlySnapshot -Request $Request }
        ApplyValidationResult = {
            param($Context, $Result)
            $Context.ModuleSessionState.LastValidation = $Result
            $Context.ModuleSessionState.LastGameRoot = [string]$Result.GameRoot
        }
        Deactivate = { param($Context) }
        DisposeWorkspace = { param($Context) }
        LineItemReference = 'framework_reference_4.1.1/GUI_V3_MANIFEST_4.1.1.md'
        WriteBoundary = 'none in this build'
        RecoveryReference = 'framework_reference_4.1.1/README_FIRST.txt'
    }
}
