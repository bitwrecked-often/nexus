# 7DTD 3.0 Wasteland Animal Population Tuning - Windows GUI installer
# Copyright (C) 2026 Bit Wrecked
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This program is distributed without warranty. See LICENSE.txt for details.

param(
    [switch]$SmokeTest,
    [switch]$ReplySimulation
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceMod = Join-Path $packageRoot "BitWrecked_7DTD_WastelandAnimalPopulationTuning"
$script:PackageVersion = "4.1.1"
$script:DefaultAnimalCap = 50
$script:BrutalScienceAnimalCap = 999

function Get-DefaultGameRoot {
    $default = Join-Path ${env:ProgramFiles(x86)} "Steam\steamapps\common\7 Days To Die"
    if (Test-Path -LiteralPath (Join-Path $default "7DaysToDie.exe") -PathType Leaf) {
        return $default
    }
    return ""
}

function Test-GameRoot {
    param([string]$GameRoot)
    if ([string]::IsNullOrWhiteSpace($GameRoot)) {
        return $false
    }
    return (Test-Path -LiteralPath (Join-Path $GameRoot "7DaysToDie.exe") -PathType Leaf)
}

function Get-TargetModPath {
    param([string]$GameRoot)
    return (Join-Path $GameRoot "Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning")
}

function Test-ModInstalled {
    param([string]$GameRoot)
    if (-not (Test-GameRoot $GameRoot)) {
        return $false
    }
    return (Test-Path -LiteralPath (Get-TargetModPath $GameRoot) -PathType Container)
}

function Get-ServerConfigPath {
    param([string]$GameRoot)
    return (Join-Path $GameRoot "serverconfig.xml")
}

function Get-MaxSpawnedAnimalsValueFromFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $line = Get-Content -LiteralPath $Path |
        Where-Object { $_ -match '<property\s+name="MaxSpawnedAnimals"\s+value="([^"]+)"' } |
        Select-Object -First 1

    if ($null -eq $line) {
        return $null
    }

    $match = [regex]::Match($line, '<property\s+name="MaxSpawnedAnimals"\s+value="([^"]+)"')
    if (-not $match.Success) {
        return $null
    }

    $value = 0
    if ([int]::TryParse($match.Groups[1].Value, [ref]$value)) {
        return $value
    }
    return $null
}

function Get-MaxSpawnedAnimalsValue {
    param([string]$GameRoot)

    return (Get-MaxSpawnedAnimalsValueFromFile -Path (Get-ServerConfigPath $GameRoot))
}

function Get-BrutalScienceAnimalCapBackups {
    param([string]$GameRoot)

    if ([string]::IsNullOrWhiteSpace($GameRoot) -or -not (Test-Path -LiteralPath $GameRoot -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $GameRoot -Filter "serverconfig.BitWreckedAnimalCapBackup-*.xml" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
    )
}

function Get-LatestBrutalScienceAnimalCapBackup {
    param([string]$GameRoot)

    return (Get-BrutalScienceAnimalCapBackups -GameRoot $GameRoot | Select-Object -First 1)
}

function Get-PendingGlobalLimitRestore {
    param([string]$GameRoot)

    if (-not (Test-GameRoot $GameRoot)) {
        return $null
    }
    $backup = Get-LatestBrutalScienceAnimalCapBackup -GameRoot $GameRoot
    if ($null -eq $backup) {
        return $null
    }
    $savedValue = Get-MaxSpawnedAnimalsValueFromFile -Path $backup.FullName
    $currentValue = Get-MaxSpawnedAnimalsValue -GameRoot $GameRoot
    if ($null -eq $savedValue -or $null -eq $currentValue -or $savedValue -eq $currentValue) {
        return $null
    }
    return [pscustomobject]@{
        Backup = $backup
        SavedValue = $savedValue
        CurrentValue = $currentValue
    }
}

function Set-BrutalScienceAnimalCap {
    param([string]$GameRoot)

    if (-not (Test-GameRoot $GameRoot)) {
        throw "That folder does not look like the 7 Days to Die game folder."
    }

    $serverConfigPath = Get-ServerConfigPath $GameRoot
    if (-not (Test-Path -LiteralPath $serverConfigPath -PathType Leaf)) {
        throw "Could not find serverconfig.xml in the selected game folder."
    }

    $previousValue = Get-MaxSpawnedAnimalsValue -GameRoot $GameRoot
    if ($null -eq $previousValue) {
        throw "Could not read MaxSpawnedAnimals from serverconfig.xml."
    }

    if ($previousValue -ge $script:BrutalScienceAnimalCap) {
        return @{
            Changed = $false
            PreviousValue = $previousValue
            NewValue = $previousValue
            BackupPath = ""
        }
    }

    $backupPath = Join-Path $GameRoot ("serverconfig.BitWreckedAnimalCapBackup-{0}.xml" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    Copy-Item -LiteralPath $serverConfigPath -Destination $backupPath

    $content = Get-Content -LiteralPath $serverConfigPath
    $updated = New-Object System.Collections.ArrayList
    $changed = $false
    foreach ($line in $content) {
        if (-not $changed -and $line -match '<property\s+name="MaxSpawnedAnimals"\s+value="[^"]+"') {
            [void]$updated.Add(($line -replace '(<property\s+name="MaxSpawnedAnimals"\s+value=")[^"]+(")', "`${1}$script:BrutalScienceAnimalCap`${2}"))
            $changed = $true
        }
        else {
            [void]$updated.Add($line)
        }
    }

    if (-not $changed) {
        throw "Could not update MaxSpawnedAnimals in serverconfig.xml."
    }

    Set-Content -LiteralPath $serverConfigPath -Value @($updated) -Encoding UTF8
    $newValue = Get-MaxSpawnedAnimalsValue -GameRoot $GameRoot
    if ($newValue -ne $script:BrutalScienceAnimalCap) {
        throw "MaxSpawnedAnimals update did not verify."
    }

    return @{
        Changed = $true
        PreviousValue = $previousValue
        NewValue = $newValue
        BackupPath = $backupPath
    }
}

function Restore-BrutalScienceAnimalCapBackup {
    param([string]$GameRoot)

    if (-not (Test-GameRoot $GameRoot)) {
        throw "That folder does not look like the 7 Days to Die game folder."
    }

    $serverConfigPath = Get-ServerConfigPath $GameRoot
    if (-not (Test-Path -LiteralPath $serverConfigPath -PathType Leaf)) {
        throw "Could not find serverconfig.xml in the selected game folder."
    }

    $backup = Get-LatestBrutalScienceAnimalCapBackup -GameRoot $GameRoot
    if ($null -eq $backup -or -not (Test-Path -LiteralPath $backup.FullName -PathType Leaf)) {
        throw "No Bit Wrecked serverconfig animal-cap backup was found beside serverconfig.xml."
    }

    $backupValue = Get-MaxSpawnedAnimalsValueFromFile -Path $backup.FullName
    if ($null -eq $backupValue) {
        throw "The newest Bit Wrecked serverconfig backup does not contain MaxSpawnedAnimals."
    }

    $previousValue = Get-MaxSpawnedAnimalsValue -GameRoot $GameRoot
    if ($null -eq $previousValue) {
        throw "Could not read MaxSpawnedAnimals from serverconfig.xml."
    }

    Copy-Item -LiteralPath $backup.FullName -Destination $serverConfigPath -Force
    $newValue = Get-MaxSpawnedAnimalsValue -GameRoot $GameRoot
    if ($newValue -ne $backupValue) {
        throw "Restored serverconfig.xml did not verify."
    }

    return @{
        BackupPath = $backup.FullName
        PreviousValue = $previousValue
        NewValue = $newValue
    }
}

function Get-TuningFactor {
    param([int]$Level)
    switch ($Level) {
        0 { return [decimal]0.00 }
        1 { return [decimal]0.50 }
        2 { return [decimal]1.00 }
        3 { return [decimal]3.00 }
        4 { return [decimal]8.00 }
        default { return [decimal]1.00 }
    }
}

function Get-TuningLevelName {
    param([int]$Level)
    switch ($Level) {
        0 { return "Absent" }
        1 { return "Sparse" }
        2 { return "Default" }
        3 { return "Dense" }
        4 { return "Absurd" }
        default { return "Default" }
    }
}

function Get-DensityDelayFactor {
    param([int]$Level)
    switch ($Level) {
        0 { return [decimal]6.00 }
        1 { return [decimal]1.75 }
        2 { return [decimal]1.00 }
        3 { return [decimal]0.45 }
        4 { return [decimal]0.10 }
        default { return [decimal]1.00 }
    }
}

function Get-DensityMaxCount {
    param([int]$Level)
    switch ($Level) {
        0 { return "0" }
        1 { return "1" }
        2 { return "1" }
        3 { return "3" }
        4 { return "8" }
        default { return "1" }
    }
}

function Get-PressureRouteMaxCount {
    param([int]$Level)
    switch ($Level) {
        3 { return "2" }
        4 { return "4" }
        default { return "0" }
    }
}

function Get-PressureRouteDelay {
    param(
        [string]$GroupName,
        [int]$Level
    )

    if ($Level -eq 3) {
        if ($GroupName -eq "EnemyAnimalsWastelandNight") {
            return "0.3,0.525,0.405,0.3,0.195,0.105"
        }
        return "0.45,0.788,0.608,0.45,0.293,0.158"
    }

    if ($Level -eq 4) {
        if ($GroupName -eq "EnemyAnimalsWastelandNight") {
            return "0.06,0.105,0.081,0.06,0.039,0.021"
        }
        return "0.09,0.158,0.122,0.09,0.059,0.032"
    }

    return ""
}

function Get-NoneWeightForDensity {
    param(
        [int]$Level,
        [decimal]$Base
    )
    switch ($Level) {
        0 { return "999" }
        1 { return (Format-TuningWeight ($Base * [decimal]1.50)) }
        2 { return (Format-TuningWeight $Base) }
        3 { return (Format-TuningWeight ([Math]::Max(1, [double]($Base * [decimal]0.25)))) }
        4 { return "0" }
        default { return (Format-TuningWeight $Base) }
    }
}

function Get-SliderValueFromLevel {
    param([int]$Level)
    return [Math]::Max(1, [Math]::Min(5, ($Level + 1)))
}

function Get-LevelFromSliderValue {
    param([int]$Value)
    return [Math]::Max(0, [Math]::Min(4, ($Value - 1)))
}

function Set-SliderLevel {
    param(
        [System.Windows.Forms.TrackBar]$Track,
        [int]$Level
    )
    $Track.Value = Get-SliderValueFromLevel $Level
}

function Format-TuningWeight {
    param([decimal]$Value)
    $rounded = [Math]::Round([double]$Value, 2)
    if ([Math]::Abs($rounded - [Math]::Round($rounded)) -lt 0.001) {
        return ([int][Math]::Round($rounded)).ToString([System.Globalization.CultureInfo]::InvariantCulture)
    }
    return $rounded.ToString("0.##", [System.Globalization.CultureInfo]::InvariantCulture)
}

$script:WastelandAnimalGroups = @(
    "EnemyAnimalsWasteland",
    "EnemyAnimalsWastelandNight"
)

$script:FallbackAnimalRows = @(
    @{
        Entity = "animalSnake"
        Group = "EnemyAnimalsWasteland"
        Base = [decimal]10
        XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalSnake']/@p"
    },
    @{
        Entity = "animalZombieVulture"
        Group = "EnemyAnimalsWasteland"
        Base = [decimal]5
        XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieVulture']/@p"
    },
    @{
        Entity = "animalZombieDog"
        Group = "EnemyAnimalsWasteland"
        Base = [decimal]15
        XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieDog']/@p"
    },
    @{
        Entity = "animalZombieBear"
        Group = "EnemyAnimalsWasteland"
        Base = [decimal]5
        XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalZombieBear']/@p"
    },
    @{
        Entity = "animalDireWolf"
        Group = "EnemyAnimalsWasteland"
        Base = [decimal]2
        XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='animalDireWolf']/@p"
    },
    @{
        Entity = "animalDireWolf"
        Group = "EnemyAnimalsWastelandNight"
        Base = [decimal]4
        XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalDireWolf']/@p"
    },
    @{
        Entity = "animalZombieBear"
        Group = "EnemyAnimalsWastelandNight"
        Base = [decimal]10
        XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='animalZombieBear']/@p"
    }
)

$script:FallbackNoneRows = @(
    @{
        Group = "EnemyAnimalsWasteland"
        Base = [decimal]50
        XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWasteland']/e[@n='none']/@p"
    },
    @{
        Group = "EnemyAnimalsWastelandNight"
        Base = [decimal]60
        XPath = "/entitygroups/entitygroup[@name='EnemyAnimalsWastelandNight']/e[@n='none']/@p"
    }
)

$script:FallbackSpawnRoutes = @(
    @{
        Group = "EnemyAnimalsWasteland"
        MaxCount = "1"
        RespawnDelay = "0.9,1.575,1.215,0.9,0.585,0.315"
    },
    @{
        Group = "EnemyAnimalsWastelandNight"
        MaxCount = "1"
        RespawnDelay = "0.6,1.05,0.81,0.6,0.39,0.21"
    }
)

function Get-AnimalDisplayName {
    param([string]$EntityName)

    switch ($EntityName) {
        "animalDireWolf" { return "Dire wolf" }
        "animalZombieBear" { return "Zombie bear" }
        "animalZombieDog" { return "Zombie dog" }
        "animalZombieVulture" { return "Zombie vulture" }
        "animalSnake" { return "Snake" }
        default {
            $name = $EntityName -replace "^animal", ""
            $name = $name -creplace "([a-z])([A-Z])", '$1 $2'
            if ([string]::IsNullOrWhiteSpace($name)) {
                return $EntityName
            }
            return $name
        }
    }
}

function Get-GroupShortName {
    param([string]$GroupName)

    switch ($GroupName) {
        "EnemyAnimalsWasteland" { return "day" }
        "EnemyAnimalsWastelandNight" { return "night" }
        default { return $GroupName }
    }
}

function Get-WastelandAnimalWeightRows {
    param([string]$GameRoot)

    if ([string]::IsNullOrWhiteSpace($GameRoot)) {
        return @($script:FallbackAnimalRows)
    }

    $liveEntityGroupsPath = Join-Path $GameRoot "Data\Config\entitygroups.xml"
    if (-not (Test-Path -LiteralPath $liveEntityGroupsPath -PathType Leaf)) {
        return @($script:FallbackAnimalRows)
    }

    [xml]$liveEntityGroupsXml = Get-Content -LiteralPath $liveEntityGroupsPath -Raw
    $rows = New-Object System.Collections.ArrayList
    foreach ($groupName in $script:WastelandAnimalGroups) {
        $groupNode = $liveEntityGroupsXml.SelectSingleNode("/entitygroups/entitygroup[@name='$groupName']")
        if ($null -eq $groupNode) {
            continue
        }

        foreach ($entry in @($groupNode.SelectNodes("e[@n and @n!='none']"))) {
            $entityName = $entry.GetAttribute("n")
            if ($entityName -notlike "animal*") {
                continue
            }

            $p = $entry.GetAttribute("p")
            if ([string]::IsNullOrWhiteSpace($p)) {
                $p = "1"
            }

            [void]$rows.Add(@{
                Entity = $entityName
                Group = $groupName
                Base = [decimal]::Parse($p, [System.Globalization.CultureInfo]::InvariantCulture)
                XPath = "/entitygroups/entitygroup[@name='$groupName']/e[@n='$entityName']/@p"
            })
        }
    }

    if ($rows.Count -eq 0) {
        return @($script:FallbackAnimalRows)
    }

    return @($rows)
}

function Get-WastelandNoneRows {
    param([string]$GameRoot)

    if ([string]::IsNullOrWhiteSpace($GameRoot)) {
        return @($script:FallbackNoneRows)
    }

    $liveEntityGroupsPath = Join-Path $GameRoot "Data\Config\entitygroups.xml"
    if (-not (Test-Path -LiteralPath $liveEntityGroupsPath -PathType Leaf)) {
        return @($script:FallbackNoneRows)
    }

    [xml]$liveEntityGroupsXml = Get-Content -LiteralPath $liveEntityGroupsPath -Raw
    $rows = New-Object System.Collections.ArrayList
    foreach ($groupName in $script:WastelandAnimalGroups) {
        $noneNode = $liveEntityGroupsXml.SelectSingleNode("/entitygroups/entitygroup[@name='$groupName']/e[@n='none']")
        if ($null -eq $noneNode) {
            continue
        }

        $p = $noneNode.GetAttribute("p")
        if ([string]::IsNullOrWhiteSpace($p)) {
            $p = "1"
        }

        [void]$rows.Add(@{
            Group = $groupName
            Base = [decimal]::Parse($p, [System.Globalization.CultureInfo]::InvariantCulture)
            XPath = "/entitygroups/entitygroup[@name='$groupName']/e[@n='none']/@p"
        })
    }

    if ($rows.Count -eq 0) {
        return @($script:FallbackNoneRows)
    }

    return @($rows)
}

function Get-WastelandSpawnRoutes {
    param([string]$GameRoot)

    if ([string]::IsNullOrWhiteSpace($GameRoot)) {
        return @($script:FallbackSpawnRoutes)
    }

    $liveSpawningPath = Join-Path $GameRoot "Data\Config\spawning.xml"
    if (-not (Test-Path -LiteralPath $liveSpawningPath -PathType Leaf)) {
        return @($script:FallbackSpawnRoutes)
    }

    [xml]$liveSpawningXml = Get-Content -LiteralPath $liveSpawningPath -Raw
    $routes = New-Object System.Collections.ArrayList
    foreach ($groupName in $script:WastelandAnimalGroups) {
        $routeNode = $liveSpawningXml.SelectSingleNode("/spawning/biome[@name='wasteland']/spawn[@entitygroup='$groupName']")
        if ($null -eq $routeNode) {
            continue
        }

        [void]$routes.Add(@{
            Group = $groupName
            MaxCount = $routeNode.GetAttribute("maxcount")
            RespawnDelay = $routeNode.GetAttribute("respawndelay")
        })
    }

    if ($routes.Count -eq 0) {
        return @($script:FallbackSpawnRoutes)
    }

    return @($routes)
}

function Get-AnimalEntitiesFromRows {
    param([array]$Rows)

    return @(
        $Rows |
            ForEach-Object { $_.Entity } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Sort-Object -Unique |
            Sort-Object { Get-AnimalDisplayName $_ }
    )
}

function Get-DensityLevelFromAnimalLevels {
    param(
        [string]$GameRoot,
        [hashtable]$AnimalLevels
    )

    if ($null -eq $AnimalLevels -or $AnimalLevels.Count -lt 1) {
        return 2
    }

    $allEntities = Get-AnimalEntitiesFromRows -Rows (Get-WastelandAnimalWeightRows -GameRoot $GameRoot)
    $selectedEntities = @($AnimalLevels.Keys)
    $selectedLevels = @($selectedEntities | ForEach-Object { [int]$AnimalLevels[$_] })
    if ($selectedLevels.Count -lt 1) {
        return 2
    }

    $maxLevel = [int]($selectedLevels | Measure-Object -Maximum).Maximum
    $allSelected = ($selectedEntities.Count -eq $allEntities.Count)

    if ($allSelected) {
        return $maxLevel
    }

    # Individual animal density is handled by pressure routes, so the vanilla
    # Wasteland animal route stays at game default unless every animal is tuned.
    return 2
}

function Format-DensityRespawnDelay {
    param(
        [string]$RespawnDelay,
        [int]$DensityLevel
    )

    if ($DensityLevel -eq 2) {
        return $RespawnDelay
    }

    $factor = Get-DensityDelayFactor $DensityLevel
    $parts = @($RespawnDelay -split "," | ForEach-Object {
        $raw = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return
        }
        $value = [decimal]::Parse($raw, [System.Globalization.CultureInfo]::InvariantCulture)
        Format-TuningWeight ([Math]::Max(0.001, [double]($value * $factor)))
    })

    if ($parts.Count -lt 1) {
        return $RespawnDelay
    }

    return ($parts -join ",")
}

function Get-TunedNoneRows {
    param(
        [string]$GameRoot,
        [int]$DensityLevel
    )

    $rows = New-Object System.Collections.ArrayList
    foreach ($row in (Get-WastelandNoneRows -GameRoot $GameRoot)) {
        [void]$rows.Add(@{
            Group = $row.Group
            XPath = $row.XPath
            Value = Get-NoneWeightForDensity -Level $DensityLevel -Base $row.Base
        })
    }
    return @($rows)
}

function Get-TunedSpawningRows {
    param(
        [string]$GameRoot,
        [int]$DensityLevel
    )

    $rows = New-Object System.Collections.ArrayList
    foreach ($route in (Get-WastelandSpawnRoutes -GameRoot $GameRoot)) {
        $baseXPath = "/spawning/biome[@name='wasteland']/spawn[@entitygroup='$($route.Group)']"
        [void]$rows.Add(@{
            Group = $route.Group
            XPath = "$baseXPath/@maxcount"
            Value = Get-DensityMaxCount $DensityLevel
        })
        [void]$rows.Add(@{
            Group = $route.Group
            XPath = "$baseXPath/@respawndelay"
            Value = Format-DensityRespawnDelay -RespawnDelay $route.RespawnDelay -DensityLevel $DensityLevel
        })
    }
    return @($rows)
}

function Get-PressureRouteCode {
    param([string]$EntityName)

    switch ($EntityName) {
        "animalDireWolf" { return "dw" }
        "animalSnake" { return "sn" }
        "animalZombieBear" { return "zb" }
        "animalZombieDog" { return "zd" }
        "animalZombieVulture" { return "zv" }
        default {
            $code = ($EntityName -replace "^animal", "").ToLowerInvariant()
            $code = $code -replace "[^a-z0-9]", ""
            if ([string]::IsNullOrWhiteSpace($code)) {
                return "an"
            }
            return $code
        }
    }
}

function Get-PressureSpawnRoutes {
    param(
        [string]$GameRoot,
        [hashtable]$AnimalLevels
    )

    $routes = New-Object System.Collections.ArrayList
    if ($null -eq $AnimalLevels -or $AnimalLevels.Count -lt 1) {
        return @($routes)
    }

    $animalRows = Get-WastelandAnimalWeightRows -GameRoot $GameRoot
    foreach ($entity in (Get-AnimalEntitiesFromRows -Rows $animalRows)) {
        if (-not $AnimalLevels.ContainsKey($entity)) {
            continue
        }

        $level = [int]$AnimalLevels[$entity]
        if ($level -lt 3) {
            continue
        }

        $routeCount = if ($level -eq 4) { 3 } else { 1 }
        $maxCount = Get-PressureRouteMaxCount $level
        $entityCode = Get-PressureRouteCode $entity

        foreach ($row in @($animalRows | Where-Object { $_.Entity -eq $entity })) {
            $timeCode = if ($row.Group -eq "EnemyAnimalsWastelandNight") { "n" } else { "a" }
            $time = if ($row.Group -eq "EnemyAnimalsWastelandNight") { "Night" } else { "Any" }

            for ($index = 1; $index -le $routeCount; $index++) {
                [void]$routes.Add(@{
                    Id = "bw_$timeCode$entityCode$index"
                    Time = $time
                    EntityGroup = $entity
                    MaxCount = $maxCount
                    RespawnDelay = Get-PressureRouteDelay -GroupName $row.Group -Level $level
                })
            }
        }
    }

    return @($routes)
}

function Get-TunedAnimalRows {
    param(
        [string]$GameRoot,
        [hashtable]$AnimalLevels
    )

    $rows = Get-WastelandAnimalWeightRows -GameRoot $GameRoot
    $tunedRows = New-Object System.Collections.ArrayList
    foreach ($row in $rows) {
        if ($null -eq $AnimalLevels -or -not $AnimalLevels.ContainsKey($row.Entity)) {
            continue
        }

        $level = [int]$AnimalLevels[$row.Entity]
        $value = Format-TuningWeight ($row.Base * (Get-TuningFactor $level))
        [void]$tunedRows.Add(@{
            Entity = $row.Entity
            Group = $row.Group
            XPath = $row.XPath
            Value = $value
        })
    }

    return @($tunedRows)
}

function Get-TunedEntityGroupRows {
    param(
        [string]$GameRoot,
        [hashtable]$AnimalLevels
    )

    $densityLevel = Get-DensityLevelFromAnimalLevels -GameRoot $GameRoot -AnimalLevels $AnimalLevels
    return @(
        @(Get-TunedAnimalRows -GameRoot $GameRoot -AnimalLevels $AnimalLevels) +
        @(Get-TunedNoneRows -GameRoot $GameRoot -DensityLevel $densityLevel)
    )
}

function New-AnimalConfigXml {
    param([array]$Rows)

    $setLines = New-Object System.Collections.ArrayList
    foreach ($row in $Rows) {
        [void]$setLines.Add("  <set xpath=`"$($row.XPath)`">$($row.Value)</set>")
    }
    $setText = $setLines -join [Environment]::NewLine

    return @"
<?xml version="1.0" encoding="UTF-8"?>
<!--
  7DTD 3.0 Wasteland Animal Population Tuning XML patch
  Copyright (C) 2026 Bit Wrecked
  SPDX-License-Identifier: GPL-3.0-or-later
  See LICENSE.txt for details.

  This file was generated by 7DTD_WastelandAnimalPopulationTuning_Tool.ps1
  from the user's selected Wasteland animal tuning.
-->
<configs>
$setText
</configs>
"@
}

function New-SpawningConfigXml {
    param(
        [array]$Rows,
        [array]$PressureRoutes,
        [int]$DensityLevel
    )

    $setLines = New-Object System.Collections.ArrayList
    foreach ($row in $Rows) {
        [void]$setLines.Add("  <set xpath=`"$($row.XPath)`">$($row.Value)</set>")
    }
    $setText = $setLines -join [Environment]::NewLine
    $appendText = ""
    if ($null -ne $PressureRoutes -and $PressureRoutes.Count -gt 0) {
        $spawnLines = New-Object System.Collections.ArrayList
        foreach ($route in $PressureRoutes) {
            [void]$spawnLines.Add("    <spawn id=`"$($route.Id)`" maxcount=`"$($route.MaxCount)`" respawndelay=`"$($route.RespawnDelay)`" time=`"$($route.Time)`" entitygroup=`"$($route.EntityGroup)`" />")
        }
        $spawnText = $spawnLines -join [Environment]::NewLine
        $appendText = @"

  <append xpath="/spawning/biome[@name='wasteland']">
$spawnText
  </append>
"@
    }
    $levelName = Get-TuningLevelName $DensityLevel

    return @"
<?xml version="1.0" encoding="UTF-8"?>
<!--
  7DTD 3.0 Wasteland Animal Population Tuning spawn-density patch
  Copyright (C) 2026 Bit Wrecked
  SPDX-License-Identifier: GPL-3.0-or-later
  See LICENSE.txt for details.

  This file was generated by 7DTD_WastelandAnimalPopulationTuning_Tool.ps1
  from the user's selected Wasteland density level: $levelName.
-->
<configs>
$setText
$appendText
</configs>
"@
}

function Write-InstalledAnimalConfig {
    param(
        [string]$TargetMod,
        [string]$GameRoot,
        [hashtable]$AnimalLevels
    )

    if ($null -eq $AnimalLevels -or $AnimalLevels.Count -lt 1) {
        throw "Pick at least one animal, or remove the mod."
    }

    $configPath = Join-Path $TargetMod "Config\entitygroups.xml"
    $animalRows = Get-TunedAnimalRows -GameRoot $GameRoot -AnimalLevels $AnimalLevels
    if ($animalRows.Count -lt 1) {
        throw "No selected Wasteland animal XML rows were found."
    }

    $rows = Get-TunedEntityGroupRows -GameRoot $GameRoot -AnimalLevels $AnimalLevels
    $configText = New-AnimalConfigXml -Rows $rows
    Set-Content -LiteralPath $configPath -Value $configText -Encoding UTF8

    [xml]$verifyXml = Get-Content -LiteralPath $configPath -Raw
    if ($verifyXml.SelectNodes("/configs/set").Count -ne $rows.Count) {
        throw "Generated animal tuning XML did not validate."
    }

    return $rows
}

function Write-InstalledSpawningConfig {
    param(
        [string]$TargetMod,
        [string]$GameRoot,
        [hashtable]$AnimalLevels
    )

    $densityLevel = Get-DensityLevelFromAnimalLevels -GameRoot $GameRoot -AnimalLevels $AnimalLevels
    $configPath = Join-Path $TargetMod "Config\spawning.xml"
    $rows = Get-TunedSpawningRows -GameRoot $GameRoot -DensityLevel $densityLevel
    $pressureRoutes = Get-PressureSpawnRoutes -GameRoot $GameRoot -AnimalLevels $AnimalLevels
    if ($rows.Count -lt 1) {
        throw "No Wasteland animal spawn-density XML rows were found."
    }

    $configText = New-SpawningConfigXml -Rows $rows -PressureRoutes $pressureRoutes -DensityLevel $densityLevel
    Set-Content -LiteralPath $configPath -Value $configText -Encoding UTF8

    [xml]$verifyXml = Get-Content -LiteralPath $configPath -Raw
    if ($verifyXml.SelectNodes("/configs/set").Count -ne $rows.Count) {
        throw "Generated spawn-density XML did not validate."
    }

    return $rows
}

function Install-Mod {
    param(
        [string]$GameRoot,
        [hashtable]$AnimalLevels = @{}
    )

    if (-not (Test-GameRoot $GameRoot)) {
        throw "That folder does not look like the 7 Days to Die game folder."
    }
    if ($null -eq $AnimalLevels -or $AnimalLevels.Count -lt 1) {
        throw "Pick at least one animal, or remove the mod."
    }
    if (-not (Test-Path -LiteralPath (Join-Path $sourceMod "ModInfo.xml") -PathType Leaf)) {
        throw "Installer package is missing BitWrecked_7DTD_WastelandAnimalPopulationTuning\ModInfo.xml. Re-extract the zip and try again."
    }

    $modsRoot = Join-Path $GameRoot "Mods"
    New-Item -ItemType Directory -Force -Path $modsRoot | Out-Null
    Copy-Item -LiteralPath $sourceMod -Destination $modsRoot -Recurse -Force
    $targetMod = Join-Path $modsRoot "BitWrecked_7DTD_WastelandAnimalPopulationTuning"
    Write-InstalledAnimalConfig -TargetMod $targetMod -GameRoot $GameRoot -AnimalLevels $AnimalLevels | Out-Null
    Write-InstalledSpawningConfig -TargetMod $targetMod -GameRoot $GameRoot -AnimalLevels $AnimalLevels | Out-Null
    return $targetMod
}

function Uninstall-Mod {
    param([string]$GameRoot)

    if (-not (Test-GameRoot $GameRoot)) {
        throw "That folder does not look like the 7 Days to Die game folder."
    }

    $targetMod = Join-Path $GameRoot "Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning"
    if (Test-Path -LiteralPath $targetMod -PathType Container) {
        Remove-Item -LiteralPath $targetMod -Recurse -Force
        return $targetMod
    }
    return ""
}

function Set-Status {
    param(
        [System.Windows.Forms.Label]$Label,
        [string]$Message,
        [System.Drawing.Color]$Color
    )
    $Label.ForeColor = $Color
    $Label.Text = $Message
    $Label.Visible = $true
    if ($null -ne $script:ActivityLogBox -and -not $script:ActivityLogBox.IsDisposed) {
        $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
        $script:ActivityLogBox.SelectionLength = 0
        $script:ActivityLogBox.SelectionColor = $Color
        $script:ActivityLogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] $Message$([Environment]::NewLine)")
        $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
        $script:ActivityLogBox.ScrollToCaret()
        Save-ActivityLogSnapshot
    }
}

$script:LoggedToolTipText = @{}
$script:LoggedValidationLines = @{}
$script:LoggedSettingCombinations = @{}
$script:GameplayAssessmentByKey = @{}
$script:PersistentLogEnabled = $false
$script:PersistentLogPath = ""
$script:IsUpdatingPersistentLog = $false

function Save-ActivityLogSnapshot {
    if (-not $script:PersistentLogEnabled -or
        [string]::IsNullOrWhiteSpace($script:PersistentLogPath) -or
        $null -eq $script:ActivityLogBox -or
        $script:ActivityLogBox.IsDisposed) {
        return
    }

    try {
        $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($script:PersistentLogPath, $script:ActivityLogBox.Text, $utf8WithBom)
    }
    catch {
        $script:PersistentLogEnabled = $false
        if ($null -ne $script:PersistentLogCheck -and -not $script:PersistentLogCheck.IsDisposed) {
            $script:IsUpdatingPersistentLog = $true
            $script:PersistentLogCheck.Checked = $false
            $script:IsUpdatingPersistentLog = $false
        }
        if ($null -ne $script:PersistentLogPathLabel -and -not $script:PersistentLogPathLabel.IsDisposed) {
            $script:PersistentLogPathLabel.Text = "Save failed; runtime log remains available."
            $script:PersistentLogPathLabel.ForeColor = [System.Drawing.Color]::Firebrick
        }
    }
}

function Add-ToolTipToActivityLog {
    param(
        [System.Windows.Forms.Control]$Control,
        [string]$Text
    )

    $logText = (($Text -replace '\s+', ' ').Trim())
    if ([string]::IsNullOrWhiteSpace($logText) -or $script:LoggedToolTipText.ContainsKey($logText)) {
        return
    }
    $script:LoggedToolTipText[$logText] = $true

    if ($null -eq $script:ActivityLogBox -or $script:ActivityLogBox.IsDisposed) {
        return
    }

    $controlLabel = (($Control.AccessibleName -replace '\s+', ' ').Trim())
    if ([string]::IsNullOrWhiteSpace($controlLabel)) {
        $controlLabel = (($Control.Text -replace '\s+', ' ').Trim())
    }
    if ([string]::IsNullOrWhiteSpace($controlLabel)) {
        $controlLabel = $Control.GetType().Name
    }

    $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
    $script:ActivityLogBox.SelectionLength = 0
    $script:ActivityLogBox.SelectionColor = New-Color 62 92 122
    $script:ActivityLogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] TIP | $controlLabel | $logText$([Environment]::NewLine)")
    $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
    $script:ActivityLogBox.ScrollToCaret()
    Save-ActivityLogSnapshot
}

function Add-ValidationReportToActivityLog {
    param([string]$ReportText)

    if ($null -eq $script:ActivityLogBox -or $script:ActivityLogBox.IsDisposed) {
        return
    }

    foreach ($reportLine in @($ReportText -split '\r?\n')) {
        $logLine = (($reportLine -replace '\s+', ' ').Trim())
        if ([string]::IsNullOrWhiteSpace($logLine) -or $script:LoggedValidationLines.ContainsKey($logLine)) {
            continue
        }
        $script:LoggedValidationLines[$logLine] = $true
        $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
        $script:ActivityLogBox.SelectionLength = 0
        $script:ActivityLogBox.SelectionColor = New-Color 52 94 72
        $script:ActivityLogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] VALIDATION | $logLine$([Environment]::NewLine)")
    }

    $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
    $script:ActivityLogBox.ScrollToCaret()
    Save-ActivityLogSnapshot
}

function Add-ChangeReportToActivityLog {
    param([string]$ReportText)

    if ($null -eq $script:ActivityLogBox -or $script:ActivityLogBox.IsDisposed) {
        return
    }
    foreach ($reportLine in @($ReportText -split '\r?\n')) {
        $logLine = (($reportLine -replace '\s+', ' ').Trim())
        if ([string]::IsNullOrWhiteSpace($logLine)) {
            continue
        }
        $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
        $script:ActivityLogBox.SelectionLength = 0
        $script:ActivityLogBox.SelectionColor = New-Color 42 112 72
        $script:ActivityLogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] CHANGE | $logLine$([Environment]::NewLine)")
    }
    $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
    $script:ActivityLogBox.ScrollToCaret()
    Save-ActivityLogSnapshot
}

function New-PlinkoSettingAside {
    param(
        [int]$AnimalCount,
        [int]$DistinctLevelCount,
        [double]$AverageLevel,
        [bool]$IncludeBrutalScience
    )

    # Weighted fragment buckets create conversational variation without storing
    # complete canned quips in the source or mixing humor into structured data.
    $weights = [ordered]@{ Positive = 35; Negative = 8; Neutral = 47; Surprised = 10 }
    if ($IncludeBrutalScience) {
        $weights.Surprised += 30
        $weights.Negative += 8
        $weights.Neutral -= 18
    }
    if ($AverageLevel -ge 3.5) {
        $weights.Surprised += 18
        $weights.Negative += 8
        $weights.Neutral -= 10
    }
    elseif ($AverageLevel -le 1.0) {
        $weights.Neutral += 10
        $weights.Positive += 5
    }
    if ($DistinctLevelCount -gt 1) {
        $weights.Surprised += 8
        $weights.Positive += 4
    }
    if ($AnimalCount -ge 4) {
        $weights.Positive += 5
        $weights.Surprised += 5
    }

    $roll = Get-Random -Minimum 1 -Maximum ((($weights.Values | Measure-Object -Sum).Sum) + 1)
    $runningWeight = 0
    $tone = "Neutral"
    foreach ($candidateTone in $weights.Keys) {
        $runningWeight += [int]$weights[$candidateTone]
        if ($roll -le $runningWeight) {
            $tone = $candidateTone
            break
        }
    }

    $openersByTone = @{
        Positive = @("Nice.", "Good.", "That tracks.", "There we go.")
        Negative = @("Careful.", "That is a sharp turn.", "The margins just got thinner.", "Worth watching.")
        Neutral = @("All right.", "Okay.", "There it is.", "Noted.")
        Surprised = @("Oh.", "Well then.", "That escalated neatly.", "Okay, that has presence.")
    }
    $subjects = if ($AnimalCount -eq 0 -and $IncludeBrutalScience) {
        @("Wasteland XML stays precise", "The animal routes remain unchanged by this cap-only action", "Local tuning keeps its composure")
    }
    elseif ($AnimalCount -gt 0 -and $IncludeBrutalScience) {
        @("Wasteland tuning joins the global stress test", "Local tuning and the global cap make a confident entrance", "Both configuration layers understand the assignment")
    }
    elseif ($DistinctLevelCount -gt 1) {
        @("Each selected animal gets a distinct role", "Mixed levels give the configuration a point of view", "The selected animals are bringing different energies")
    }
    elseif ($AnimalCount -gt 1) {
        @("One level moves the selected group together", "The animals are sharing one clear rule", "The grouped setting has chosen solidarity")
    }
    else {
        @("One animal gets one deliberate change", "The scope is focused and intentional", "A single setting steps forward")
    }
    $effects = if ($IncludeBrutalScience) {
        @("the global ceiling goes to 999 and means it", "the server is being asked to make room for ambition", "the global limit has selected the loud setting")
    }
    else {
        @("the global ceiling stays where it is", "server-wide limits keep their current rhythm", "the global setting practices restraint")
    }
    $judgmentsByTone = @{
        Positive = @("The configuration understands the assignment.", "That combination has a clear purpose.", "The choices support each other.")
        Negative = @("The risk is real, but at least it is explicit.", "This deserves monitoring, not panic.", "The configuration is asking for attention.")
        Neutral = @("The intent is clear.", "The settings say exactly what they mean.", "Nothing here is pretending to be subtle.")
        Surprised = @("That combination knows how to enter a room.", "The settings have developed stage presence.", "Subtle was available; this chose memorable.")
    }
    $closersByTone = @{
        Positive = @("Good choice.", "Carry on.", "Let us see it work.")
        Negative = @("Keep an eye on it.", "Proceed with both eyes open.", "This is manageable if watched.")
        Neutral = @("That is the deal.", "No mystery remains.", "Proceed accordingly.")
        Surprised = @("What the hell - commit to the bit.", "That should be interesting.", "The server will remember this.")
    }

    $text = "$(Get-Random -InputObject $openersByTone[$tone]) $(Get-Random -InputObject $subjects); $(Get-Random -InputObject $effects). $(Get-Random -InputObject $judgmentsByTone[$tone]) $(Get-Random -InputObject $closersByTone[$tone])"
    return [pscustomobject]@{ Tone = $tone.ToUpperInvariant(); Text = $text; Weights = $weights }
}

function New-GameplayDifficultyAssessment {
    param(
        [hashtable]$AnimalLevels,
        [bool]$CapSelected,
        [object]$CurrentCap
    )

    $levels = @($AnimalLevels.Values | ForEach-Object { [int]$_ })
    $animalCount = $levels.Count
    $averageLevel = if ($animalCount -gt 0) { [double](($levels | Measure-Object -Average).Average) } else { 2.0 }
    $peakLevel = if ($animalCount -gt 0) { [int](($levels | Measure-Object -Maximum).Maximum) } else { 2 }
    $capRaised = $CapSelected -or ($null -ne $CurrentCap -and [int]$CurrentCap -gt $script:DefaultAnimalCap)
    $score = ($averageLevel * 1.5) + ($peakLevel * 0.8) + ($animalCount * 0.35) + $(if ($capRaised) { 4.5 } else { 0 })

    $weights = [ordered]@{ Relaxed = 10; Balanced = 55; Hard = 25; Brutal = 10 }
    if ($averageLevel -le 1) { $weights.Relaxed += 50; $weights.Balanced += 10; $weights.Hard = 5; $weights.Brutal = 1 }
    if ($averageLevel -ge 3) { $weights.Hard += 35; $weights.Brutal += 15; $weights.Relaxed = 2 }
    if ($peakLevel -ge 4) { $weights.Brutal += 35; $weights.Hard += 15; $weights.Balanced -= 20 }
    if ($animalCount -ge 4) { $weights.Hard += 15; $weights.Brutal += 10 }
    if ($capRaised) { $weights.Brutal += 45; $weights.Hard += 20; $weights.Relaxed = 1; $weights.Balanced = [Math]::Max(3, $weights.Balanced - 35) }

    $roll = Get-Random -Minimum 1 -Maximum ((($weights.Values | Measure-Object -Sum).Sum) + 1)
    $running = 0
    $rating = "Balanced"
    foreach ($candidate in $weights.Keys) {
        $running += [int]$weights[$candidate]
        if ($roll -le $running) { $rating = $candidate; break }
    }

    $openers = @{
        Relaxed = @("Low pressure.", "This is forgiving.", "The Wasteland gets breathing room.")
        Balanced = @("Playable pressure.", "This has a fair shape.", "The difficulty has boundaries.")
        Hard = @("This will bite.", "Pressure is now part of the plan.", "Mistakes will become expensive.")
        Brutal = @("This is hostile by design.", "You asked the ecosystem to stop being polite.", "This configuration has no sympathy budget.")
    }
    $scope = if ($animalCount -eq 0) {
        @("No animal route changes are selected", "Animal tuning remains where it is")
    }
    elseif ($animalCount -eq 1) {
        @("One animal carries the difficulty change", "The threat is focused instead of broad")
    }
    elseif ($animalCount -ge 4) {
        @("Most of the animal roster is participating", "The pressure is spread across the roster")
    }
    else {
        @("Several animal routes share the pressure", "The threat profile is deliberately mixed")
    }
    $capEffect = if ($capRaised) {
        @("and the raised global cap removes the usual population brake", "while the global cap gives bad situations room to grow")
    }
    else {
        @("while the normal global cap still limits total active pressure", "and the server-wide safety rail remains in place")
    }
    $verdicts = @{
        Relaxed = @("Good for exploration; veterans may call it a vacation.", "Readable and survivable, with little reason to panic.")
        Balanced = @("Good for regular play if the rest of the mod stack behaves.", "It should create decisions without turning every trip into cleanup duty.")
        Hard = @("Bring ammunition and an exit route; confidence is not armor.", "This can be fun, but careless travel will get audited immediately.")
        Brutal = @("Expect performance pressure and ugly fights; this is testing territory, not a gentle difficulty bump.", "If the server struggles or the Wasteland becomes absurd, the settings are doing exactly what they were told.")
    }

    $text = "$(Get-Random -InputObject $openers[$rating]) $(Get-Random -InputObject $scope) $(Get-Random -InputObject $capEffect). $(Get-Random -InputObject $verdicts[$rating])"
    return [pscustomobject]@{ Rating = $rating.ToUpperInvariant(); Score = [Math]::Round($score, 1); Text = $text; Weights = $weights }
}

function Add-GameplayAssessmentLines {
    param(
        [System.Collections.ArrayList]$Lines,
        [hashtable]$AnimalLevels,
        [bool]$CapSelected,
        [string]$GameRoot
    )

    $assessmentLevels = @{}
    foreach ($entity in @($AnimalLevels.Keys)) {
        $assessmentLevels[$entity] = [int]$AnimalLevels[$entity]
    }
    $basis = "selected checkbox results"
    if ($assessmentLevels.Count -eq 0 -and (Test-ModInstalled $GameRoot)) {
        $installedMap = Get-InstalledPatchValueMap -TargetMod (Get-TargetModPath $GameRoot)
        foreach ($entity in @(Get-AnimalEntitiesFromRows -Rows (Get-WastelandAnimalWeightRows -GameRoot $GameRoot))) {
            $entityRows = @(Get-WastelandAnimalWeightRows -GameRoot $GameRoot | Where-Object { $_.Entity -eq $entity })
            if ($entityRows.Count -eq 0 -or -not $installedMap.ContainsKey($entityRows[0].XPath)) {
                continue
            }
            foreach ($candidateLevel in 0..4) {
                $expectedValue = Format-TuningWeight ($entityRows[0].Base * (Get-TuningFactor $candidateLevel))
                if ([string]$installedMap[$entityRows[0].XPath] -eq [string]$expectedValue) {
                    $assessmentLevels[$entity] = $candidateLevel
                    break
                }
            }
        }
        $basis = "currently installed animal XML"
    }
    elseif ($assessmentLevels.Count -eq 0) {
        $basis = "game-default animal XML"
    }

    $currentCap = Get-MaxSpawnedAnimalsValue -GameRoot $GameRoot
    $parts = @($assessmentLevels.Keys | Sort-Object | ForEach-Object { "$_=$($assessmentLevels[$_])" })
    $key = "animals=$($parts -join ';')|selectedCap=$CapSelected|currentCap=$currentCap"
    if (-not $script:GameplayAssessmentByKey.ContainsKey($key)) {
        $script:GameplayAssessmentByKey[$key] = New-GameplayDifficultyAssessment -AnimalLevels $assessmentLevels -CapSelected $CapSelected -CurrentCap $currentCap
    }
    $assessment = $script:GameplayAssessmentByKey[$key]
    [void]$Lines.Add("")
    [void]$Lines.Add("Generated gameplay assessment:")
    [void]$Lines.Add("- Basis: $basis")
    [void]$Lines.Add("- Difficulty: $($assessment.Rating) (pressure score $($assessment.Score))")
    [void]$Lines.Add("- Opinion: $($assessment.Text)")
}

function New-SettingCombinationConfirmation {
    param(
        [hashtable]$AnimalLevels,
        [bool]$IncludeBrutalScience
    )

    $animalParts = New-Object System.Collections.ArrayList
    foreach ($entity in @($AnimalLevels.Keys | Sort-Object)) {
        [void]$animalParts.Add("$(Get-AnimalDisplayName $entity)=$(Get-TuningLevelName ([int]$AnimalLevels[$entity]))")
    }

    $animalCount = $animalParts.Count
    $distinctLevels = @($AnimalLevels.Values | ForEach-Object { [int]$_ } | Sort-Object -Unique)
    $averageLevel = if ($animalCount -gt 0) {
        [double](($AnimalLevels.Values | ForEach-Object { [int]$_ } | Measure-Object -Average).Average)
    }
    else {
        2.0
    }
    $animalSummary = if ($animalCount -eq 0) {
        "Wasteland animals: unchanged"
    }
    elseif ($distinctLevels.Count -eq 1) {
        "Wasteland animals: $animalCount selected at $(Get-TuningLevelName $distinctLevels[0])"
    }
    else {
        "Wasteland animals: $animalCount selected with mixed levels"
    }
    $globalSummary = if ($IncludeBrutalScience) {
        "Global animal limit: $script:BrutalScienceAnimalCap (Brutal Science)"
    }
    else {
        "Global animal limit: unchanged"
    }

    $aside = New-PlinkoSettingAside -AnimalCount $animalCount -DistinctLevelCount $distinctLevels.Count -AverageLevel $averageLevel -IncludeBrutalScience $IncludeBrutalScience

    $key = "animals=$($animalParts -join ';')|cap=$IncludeBrutalScience"
    return [pscustomobject]@{
        Key = $key
        Summary = "$animalSummary`n$globalSummary"
        LogSummary = "$animalSummary; $globalSummary"
        Tone = $aside.Tone
        Humor = $aside.Text
        Weights = $aside.Weights
    }
}

function Add-SettingCombinationToActivityLog {
    param([pscustomobject]$Combination)

    if ($script:LoggedSettingCombinations.ContainsKey($Combination.Key)) {
        return
    }
    $script:LoggedSettingCombinations[$Combination.Key] = $true
    if ($null -eq $script:ActivityLogBox -or $script:ActivityLogBox.IsDisposed) {
        return
    }

    $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
    $script:ActivityLogBox.SelectionLength = 0
    $script:ActivityLogBox.SelectionColor = New-Color 52 94 72
    $script:ActivityLogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] CONFIRM | $($Combination.LogSummary)$([Environment]::NewLine)")
    $script:ActivityLogBox.SelectionColor = New-Color 126 82 28
    $script:ActivityLogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] EASTER EGG [$($Combination.Tone)] | $($Combination.Humor)$([Environment]::NewLine)")
    $script:ActivityLogBox.SelectionStart = $script:ActivityLogBox.TextLength
    $script:ActivityLogBox.ScrollToCaret()
    Save-ActivityLogSnapshot
}

function New-Color {
    param([int]$R, [int]$G, [int]$B)
    return [System.Drawing.Color]::FromArgb($R, $G, $B)
}

$script:RoundedControls = New-Object System.Collections.ArrayList

function Get-RoundedControlSettings {
    param([System.Windows.Forms.Control]$Control)

    $settings = @{
        Radius = 8
        BorderColor = New-Color 208 208 202
    }

    if ($null -ne $Control -and $Control.Tag -is [System.Collections.IDictionary]) {
        if ($Control.Tag.ContainsKey("RwpRadius") -and $null -ne $Control.Tag.RwpRadius) {
            $settings.Radius = [int]$Control.Tag.RwpRadius
        }
        if ($Control.Tag.ContainsKey("RwpBorderColor") -and $null -ne $Control.Tag.RwpBorderColor) {
            $settings.BorderColor = [System.Drawing.Color]$Control.Tag.RwpBorderColor
        }
    }

    return $settings
}

function New-RoundedPath {
    param(
        [System.Drawing.Rectangle]$Bounds,
        [int]$Radius
    )

    $width = [Math]::Max(1, $Bounds.Width)
    $height = [Math]::Max(1, $Bounds.Height)
    $safeBounds = New-Object System.Drawing.Rectangle($Bounds.X, $Bounds.Y, $width, $height)
    $safeRadius = [Math]::Max(0, [Math]::Min($Radius, [Math]::Floor([Math]::Min($width, $height) / 2)))

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath

    if ($safeRadius -lt 1) {
        $path.AddRectangle($safeBounds)
        return $path
    }

    $diameter = [Math]::Max(1, $safeRadius * 2)
    $path.AddArc($safeBounds.X, $safeBounds.Y, $diameter, $diameter, 180, 90)
    $path.AddArc(($safeBounds.Right - $diameter), $safeBounds.Y, $diameter, $diameter, 270, 90)
    $path.AddArc(($safeBounds.Right - $diameter), ($safeBounds.Bottom - $diameter), $diameter, $diameter, 0, 90)
    $path.AddArc($safeBounds.X, ($safeBounds.Bottom - $diameter), $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Set-RoundedRegion {
    param(
        [System.Windows.Forms.Control]$Control,
        [Nullable[int]]$Radius
    )

    if ($Control.Width -lt 1 -or $Control.Height -lt 1) {
        return
    }

    if ($null -eq $Radius) {
        $Radius = (Get-RoundedControlSettings $Control).Radius
    }

    $bounds = New-Object System.Drawing.Rectangle(0, 0, $Control.Width, $Control.Height)
    $path = New-RoundedPath $bounds $Radius
    $Control.Region = New-Object System.Drawing.Region($path)
    $path.Dispose()
}

function Enable-RoundedBorder {
    param(
        [System.Windows.Forms.Control]$Control,
        [int]$Radius,
        [System.Drawing.Color]$BorderColor
    )

    $Control.Tag = @{
        RwpRadius = [int]$Radius
        RwpBorderColor = $BorderColor
    }
    Set-RoundedRegion $Control $Radius
    if (-not $script:RoundedControls.Contains($Control)) {
        [void]$script:RoundedControls.Add($Control)
    }
    $Control.Add_Resize({
        param($sender, $eventArgs)
        Set-RoundedRegion $sender $null
    })
    $Control.Add_Paint({
        param($sender, $event)
        if ($sender.Width -lt 2 -or $sender.Height -lt 2) {
            return
        }
        $roundedSettings = Get-RoundedControlSettings $sender
        $event.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $bounds = New-Object System.Drawing.Rectangle(0, 0, ($sender.Width - 1), ($sender.Height - 1))
        $path = New-RoundedPath $bounds ([int]$roundedSettings.Radius)
        $pen = New-Object -TypeName System.Drawing.Pen -ArgumentList @([System.Drawing.Color]$roundedSettings.BorderColor, [single]1.0)
        try {
            $event.Graphics.DrawPath($pen, $path)
        }
        finally {
            $pen.Dispose()
            $path.Dispose()
        }
    })
}

function New-VersionHighlightsText {
    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add("- Major clarity pass: tighter layout, less inline text, and clearer action wording.")
    [void]$lines.Add("- Game Folder and Open Mods Folder now describe two distinct destinations.")
    [void]$lines.Add("- Validate Current Game Settings replaces the unclear Compare Values action.")
    [void]$lines.Add("- Animal uninstall, global-limit backup/restore, and Remove Mod now state their separate file effects.")
    [void]$lines.Add("- 28 focused tooltips now stream in three quick frames, then fade away.")
    [void]$lines.Add("- Install/Reinstall has a clean plastic-style action with subtle pixel-art detail.")
    [void]$lines.Add("- The 4.0.1 gameplay tuning and XML behavior remain unchanged.")
    [void]$lines.Add("")
    [void]$lines.Add("Full details are in CHANGELOG.md beside this tool.")
    return ($lines -join [Environment]::NewLine)
}

function Show-VersionHighlightsDialog {
    param([System.Windows.Forms.Form]$Owner)

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Version $script:PackageVersion Highlights"
    $dialog.ClientSize = New-Object System.Drawing.Size(470, 350)
    $dialog.StartPosition = "CenterParent"
    $dialog.FormBorderStyle = "FixedDialog"
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.ShowInTaskbar = $false
    $dialog.BackColor = New-Color 250 249 247

    $heading = New-Object System.Windows.Forms.Label
    $heading.Text = "Version $script:PackageVersion highlights"
    $heading.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11, [System.Drawing.FontStyle]::Bold)
    $heading.ForeColor = New-Color 38 38 36
    $heading.Location = New-Object System.Drawing.Point(22, 18)
    $heading.Size = New-Object System.Drawing.Size(426, 24)
    $dialog.Controls.Add($heading)

    $body = New-Object System.Windows.Forms.TextBox
    $body.Multiline = $true
    $body.ReadOnly = $true
    $body.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $body.BackColor = New-Color 250 249 247
    $body.ForeColor = New-Color 45 45 43
    $body.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $body.Location = New-Object System.Drawing.Point(24, 55)
    $body.Size = New-Object System.Drawing.Size(424, 228)
    $body.Text = New-VersionHighlightsText
    $dialog.Controls.Add($body)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $okButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $okButton.FlatAppearance.BorderSize = 0
    $okButton.BackColor = [System.Drawing.Color]::White
    $okButton.ForeColor = New-Color 38 38 36
    $okButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $okButton.Location = New-Object System.Drawing.Point(348, 298)
    $okButton.Size = New-Object System.Drawing.Size(100, 34)
    $okButton.Add_Click({ $dialog.Close() })
    $dialog.Controls.Add($okButton)
    Enable-RoundedBorder $okButton 17 (New-Color 208 208 202)

    $dialog.AcceptButton = $okButton
    [void]$dialog.ShowDialog($Owner)
}

function Show-ReadOnlyReportDialog {
    param(
        [System.Windows.Forms.Form]$Owner,
        [string]$Title,
        [string]$Text
    )

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = $Title
    $dialog.ClientSize = New-Object System.Drawing.Size(500, 360)
    $dialog.StartPosition = "CenterParent"
    $dialog.FormBorderStyle = "FixedDialog"
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.ShowInTaskbar = $false
    $dialog.BackColor = New-Color 250 249 247

    $heading = New-Object System.Windows.Forms.Label
    $heading.Text = $Title
    $heading.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11, [System.Drawing.FontStyle]::Bold)
    $heading.ForeColor = New-Color 38 38 36
    $heading.Location = New-Object System.Drawing.Point(22, 18)
    $heading.Size = New-Object System.Drawing.Size(456, 24)
    $dialog.Controls.Add($heading)

    $bodyShell = New-Object System.Windows.Forms.Panel
    $bodyShell.Location = New-Object System.Drawing.Point(22, 52)
    $bodyShell.Size = New-Object System.Drawing.Size(456, 240)
    $bodyShell.BackColor = [System.Drawing.Color]::White
    $dialog.Controls.Add($bodyShell)
    Enable-RoundedBorder $bodyShell 8 (New-Color 226 224 218)

    $body = New-Object System.Windows.Forms.TextBox
    $body.Multiline = $true
    $body.ReadOnly = $true
    $body.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $body.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $body.BackColor = [System.Drawing.Color]::White
    $body.ForeColor = New-Color 45 45 43
    $body.Font = New-Object System.Drawing.Font("Consolas", 9)
    $body.Location = New-Object System.Drawing.Point(12, 12)
    $body.Size = New-Object System.Drawing.Size(432, 216)
    $body.Text = $Text
    $bodyShell.Controls.Add($body)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $okButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $okButton.FlatAppearance.BorderSize = 0
    $okButton.BackColor = [System.Drawing.Color]::White
    $okButton.ForeColor = New-Color 38 38 36
    $okButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $okButton.Location = New-Object System.Drawing.Point(378, 309)
    $okButton.Size = New-Object System.Drawing.Size(100, 34)
    $okButton.Add_Click({ $dialog.Close() })
    $dialog.Controls.Add($okButton)
    Enable-RoundedBorder $okButton 17 (New-Color 208 208 202)

    $dialog.AcceptButton = $okButton
    [void]$dialog.ShowDialog($Owner)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Bit Wrecked - 7DTD 3.0 Wasteland Animal Tuning"
$form.ClientSize = New-Object System.Drawing.Size(620, 660)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = New-Color 250 249 247

$logoImage = $null
$logoPath = Join-Path $packageRoot "Assets\bit-wrecked-channel-avatar.png"
if (Test-Path -LiteralPath $logoPath -PathType Leaf) {
    $logoStream = [System.IO.File]::OpenRead($logoPath)
    try {
        $loadedLogo = [System.Drawing.Image]::FromStream($logoStream)
        try {
            $logoImage = New-Object System.Drawing.Bitmap $loadedLogo
        }
        finally {
            $loadedLogo.Dispose()
        }
    }
    finally {
        $logoStream.Dispose()
    }

    $logoBox = New-Object System.Windows.Forms.PictureBox
    $logoBox.Image = $logoImage
    $logoBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $logoBox.BackColor = [System.Drawing.Color]::Transparent
    $logoBox.Location = New-Object System.Drawing.Point(27, 18)
    $logoBox.Size = New-Object System.Drawing.Size(52, 52)
    $form.Controls.Add($logoBox)
    Set-RoundedRegion $logoBox 26
    $form.Add_FormClosed({
        if ($null -ne $script:LogoImageToDispose) {
            $script:LogoImageToDispose.Dispose()
        }
    })
    $script:LogoImageToDispose = $logoImage
}

$brand = New-Object System.Windows.Forms.Label
$brand.Text = "Bit Wrecked"
$brand.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9, [System.Drawing.FontStyle]::Bold)
$brand.ForeColor = New-Color 130 45 35
$brand.AutoSize = $true
$brand.Location = New-Object System.Drawing.Point(92, 20)
$form.Controls.Add($brand)

$title = New-Object System.Windows.Forms.Label
$title.Text = "7DTD 3.0 Wasteland Animal Population Tuning"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = New-Color 32 32 32
$title.AutoSize = $false
$title.Location = New-Object System.Drawing.Point(90, 40)
$title.Size = New-Object System.Drawing.Size(504, 30)
$form.Controls.Add($title)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "Version $script:PackageVersion"
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$versionLabel.ForeColor = New-Color 92 92 88
$versionLabel.AutoSize = $true
$versionLabel.Location = New-Object System.Drawing.Point(92, 70)
$form.Controls.Add($versionLabel)

$changeLogLink = New-Object System.Windows.Forms.LinkLabel
$changeLogLink.Text = "What's new"
$changeLogLink.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$changeLogLink.LinkColor = New-Color 130 45 35
$changeLogLink.ActiveLinkColor = New-Color 158 45 34
$changeLogLink.VisitedLinkColor = New-Color 130 45 35
$changeLogLink.AutoSize = $true
$changeLogLink.Location = New-Object System.Drawing.Point(164, 70)
$form.Controls.Add($changeLogLink)

$statePanel = New-Object System.Windows.Forms.Panel
$statePanel.Location = New-Object System.Drawing.Point(26, 102)
$statePanel.Size = New-Object System.Drawing.Size(568, 58)
$statePanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($statePanel)
Enable-RoundedBorder $statePanel 16 (New-Color 226 224 218)

$stateAccent = New-Object System.Windows.Forms.Panel
$stateAccent.Location = New-Object System.Drawing.Point(18, 20)
$stateAccent.Size = New-Object System.Drawing.Size(18, 18)
$stateAccent.BackColor = New-Color 156 156 150
$statePanel.Controls.Add($stateAccent)
Set-RoundedRegion $stateAccent 9

$stateValue = New-Object System.Windows.Forms.Label
$stateValue.Text = "Checking..."
$stateValue.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10, [System.Drawing.FontStyle]::Bold)
$stateValue.ForeColor = New-Color 48 48 48
$stateValue.AutoSize = $false
$stateValue.Location = New-Object System.Drawing.Point(47, 18)
$stateValue.Size = New-Object System.Drawing.Size(492, 22)
$statePanel.Controls.Add($stateValue)

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 4000
$toolTip.InitialDelay = 200
$toolTip.ReshowDelay = 50
$toolTip.UseAnimation = $true
$toolTip.UseFading = $true

$script:AnimatedTipTool = $toolTip
$script:AnimatedTipTextByControl = @{}
$script:AnimatedTipWiredControls = @{}
$script:AnimatedTipControl = $null
$script:AnimatedTipFrame = 0
$script:AnimatedTipDelayTicks = 0
$script:AnimatedTipTimer = New-Object System.Windows.Forms.Timer
$script:AnimatedTipTimer.Interval = 110

function Format-AnimatedToolTipText {
    param(
        [string]$Text,
        [int]$MaximumLineLength = 68
    )

    $lines = New-Object System.Collections.ArrayList
    $line = ""
    foreach ($word in @($Text -split '\s+')) {
        if ([string]::IsNullOrWhiteSpace($word)) {
            continue
        }
        $candidate = if ([string]::IsNullOrEmpty($line)) { $word } else { "$line $word" }
        if ($candidate.Length -gt $MaximumLineLength -and -not [string]::IsNullOrEmpty($line)) {
            [void]$lines.Add($line)
            $line = $word
        }
        else {
            $line = $candidate
        }
    }
    if (-not [string]::IsNullOrEmpty($line)) {
        [void]$lines.Add($line)
    }
    return ($lines -join [Environment]::NewLine)
}

$script:AnimatedTipTimer.Add_Tick({
    $control = $script:AnimatedTipControl
    if ($null -eq $control -or $control.IsDisposed -or -not $script:AnimatedTipTextByControl.ContainsKey($control)) {
        $script:AnimatedTipTimer.Stop()
        return
    }

    $script:AnimatedTipDelayTicks++
    if ($script:AnimatedTipDelayTicks -lt 2) {
        return
    }

    $script:AnimatedTipFrame++
    $fullText = [string]$script:AnimatedTipTextByControl[$control]
    $characterCount = [Math]::Min(
        $fullText.Length,
        [Math]::Ceiling($fullText.Length * ([double]$script:AnimatedTipFrame / 3.0))
    )
    $frameText = $fullText.Substring(0, $characterCount)
    $script:AnimatedTipTool.Show($frameText, $control, 8, ($control.Height + 5), 4000)

    if ($script:AnimatedTipFrame -ge 3) {
        $script:AnimatedTipTimer.Stop()
        Add-ToolTipToActivityLog -Control $control -Text $fullText
    }
})

function Set-AnimatedToolTip {
    param(
        [System.Windows.Forms.Control]$Control,
        [string]$Text
    )

    $script:AnimatedTipTextByControl[$Control] = Format-AnimatedToolTipText -Text $Text
    $script:AnimatedTipTool.SetToolTip($Control, "")
    if ($script:AnimatedTipWiredControls.ContainsKey($Control)) {
        return
    }

    $script:AnimatedTipWiredControls[$Control] = $true
    $Control.Add_MouseEnter({
        param($sender, $eventArgs)
        $script:AnimatedTipTimer.Stop()
        if ($null -ne $script:AnimatedTipControl) {
            $script:AnimatedTipTool.Hide($script:AnimatedTipControl)
        }
        $script:AnimatedTipControl = $sender
        $script:AnimatedTipFrame = 0
        $script:AnimatedTipDelayTicks = 0
        $script:AnimatedTipTimer.Start()
    })
    $Control.Add_MouseLeave({
        param($sender, $eventArgs)
        if ([object]::ReferenceEquals($script:AnimatedTipControl, $sender)) {
            $script:AnimatedTipTimer.Stop()
            $script:AnimatedTipTool.Hide($sender)
            $script:AnimatedTipControl = $null
        }
    })
    $Control.Add_Disposed({
        param($sender, $eventArgs)
        [void]$script:AnimatedTipTextByControl.Remove($sender)
        [void]$script:AnimatedTipWiredControls.Remove($sender)
        if ([object]::ReferenceEquals($script:AnimatedTipControl, $sender)) {
            $script:AnimatedTipTimer.Stop()
            $script:AnimatedTipControl = $null
        }
    })
}

Set-AnimatedToolTip -Control $statePanel -Text "Shows whether this tuning mod is installed in the currently selected 7 Days to Die game folder."
Set-AnimatedToolTip -Control $stateValue -Text "Shows whether this tuning mod is installed in the currently selected 7 Days to Die game folder."

$pathShell = New-Object System.Windows.Forms.Panel
$pathShell.Location = New-Object System.Drawing.Point(27, 180)
$pathShell.Size = New-Object System.Drawing.Size(414, 34)
$pathShell.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($pathShell)
Enable-RoundedBorder $pathShell 16 (New-Color 208 208 202)

$pathBox = New-Object System.Windows.Forms.TextBox
$pathBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$pathBox.BackColor = [System.Drawing.Color]::White
$pathBox.Location = New-Object System.Drawing.Point(13, 9)
$pathBox.Size = New-Object System.Drawing.Size(386, 20)
$pathBox.Text = Get-DefaultGameRoot
$pathBox.AccessibleName = "7 Days to Die game folder"
$pathBox.AccessibleDescription = "The game folder used for comparison, installation, removal, and optional animal-cap actions. Clicking the field does not run the mod."
$pathShell.Controls.Add($pathBox)
Set-AnimatedToolTip -Control $pathBox -Text "Main 7 Days to Die folder containing 7DaysToDie.exe - not the Mods folder. The tool uses it to find Mods and serverconfig.xml. Clicking or editing this field does not run the mod."

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Choose Game Folder"
$browseButton.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$browseButton.FlatAppearance.BorderSize = 0
$browseButton.BackColor = [System.Drawing.Color]::White
$browseButton.ForeColor = New-Color 38 38 36
$browseButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$browseButton.Location = New-Object System.Drawing.Point(454, 178)
$browseButton.Size = New-Object System.Drawing.Size(140, 36)
$browseButton.AccessibleName = "Choose game folder"
$browseButton.AccessibleDescription = "Open a folder chooser for the 7 Days to Die game folder. This does not run the mod."
$browseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select your 7 Days to Die game folder"
    if (Test-Path -LiteralPath $pathBox.Text -PathType Container) {
        $dialog.SelectedPath = $pathBox.Text
    }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathBox.Text = $dialog.SelectedPath
        Update-InstallState
        Set-Status $status "Selected game folder: $($dialog.SelectedPath)" (New-Color 82 82 78)
    }
})
$form.Controls.Add($browseButton)
Enable-RoundedBorder $browseButton 18 (New-Color 208 208 202)
Set-AnimatedToolTip -Control $browseButton -Text "Choose the main 7 Days to Die folder containing 7DaysToDie.exe - not the Mods folder. This only selects a location; it does not install or run the mod."

$tuningPanel = New-Object System.Windows.Forms.Panel
$tuningPanel.Location = New-Object System.Drawing.Point(27, 230)
$tuningPanel.Size = New-Object System.Drawing.Size(567, 252)
$tuningPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($tuningPanel)
Enable-RoundedBorder $tuningPanel 16 (New-Color 226 224 218)

$masterCheck = New-Object System.Windows.Forms.CheckBox
$masterCheck.Text = "All"
$masterCheck.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$masterCheck.ForeColor = New-Color 38 38 36
$masterCheck.AutoSize = $false
$masterCheck.Location = New-Object System.Drawing.Point(40, 36)
$masterCheck.Size = New-Object System.Drawing.Size(102, 40)
$masterCheck.Checked = $false
$tuningPanel.Controls.Add($masterCheck)

$masterTrack = New-Object System.Windows.Forms.TrackBar
$masterTrack.Minimum = 0
$masterTrack.Maximum = 6
$masterTrack.Value = Get-SliderValueFromLevel 2
$masterTrack.TickStyle = [System.Windows.Forms.TickStyle]::None
$masterTrack.TickFrequency = 1
$masterTrack.LargeChange = 1
$masterTrack.SmallChange = 1
$masterTrack.AutoSize = $false
$masterTrack.Location = New-Object System.Drawing.Point(166, 46)
$masterTrack.Size = New-Object System.Drawing.Size(108, 34)
$masterTrack.BackColor = [System.Drawing.Color]::White
$tuningPanel.Controls.Add($masterTrack)

$masterValue = New-Object System.Windows.Forms.Label
$masterValue.Text = "Custom"
$masterValue.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$masterValue.ForeColor = New-Color 82 82 78
$masterValue.Location = New-Object System.Drawing.Point(282, 46)
$masterValue.Size = New-Object System.Drawing.Size(82, 20)
$tuningPanel.Controls.Add($masterValue)

$masterPreview = New-Object System.Windows.Forms.Label
$masterPreview.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$masterPreview.ForeColor = New-Color 82 82 78
$masterPreview.Location = New-Object System.Drawing.Point(420, 46)
$masterPreview.Size = New-Object System.Drawing.Size(108, 20)
$masterPreview.Visible = $false
$tuningPanel.Controls.Add($masterPreview)

$animalHeader = New-Object System.Windows.Forms.Label
$animalHeader.Text = "Animal Selection"
$animalHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$animalHeader.ForeColor = New-Color 110 110 105
$animalHeader.Location = New-Object System.Drawing.Point(22, 25)
$animalHeader.Size = New-Object System.Drawing.Size(118, 18)
$animalHeader.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$tuningPanel.Controls.Add($animalHeader)
Set-AnimatedToolTip -Control $animalHeader -Text "Animal whose Wasteland spawn weight can be tuned."

$levelHeader = New-Object System.Windows.Forms.Label
$levelHeader.Text = "Population Level"
$levelHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$levelHeader.ForeColor = New-Color 110 110 105
$levelHeader.Location = New-Object System.Drawing.Point(166, 25)
$levelHeader.Size = New-Object System.Drawing.Size(108, 18)
$levelHeader.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$tuningPanel.Controls.Add($levelHeader)
Set-AnimatedToolTip -Control $levelHeader -Text "Slider for the tuning level that will be applied on the next Install or Reinstall."

$choiceHeader = New-Object System.Windows.Forms.Label
$choiceHeader.Text = "Action"
$choiceHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$choiceHeader.ForeColor = New-Color 110 110 105
$choiceHeader.Location = New-Object System.Drawing.Point(261, 25)
$choiceHeader.Size = New-Object System.Drawing.Size(82, 18)
$choiceHeader.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$tuningPanel.Controls.Add($choiceHeader)
Set-AnimatedToolTip -Control $choiceHeader -Text "Keep means no change. Uninstall means that animal's installed tuning is removed and returns to game defaults. A level name means that level will be installed."

$gameHeader = New-Object System.Windows.Forms.Label
$gameHeader.Text = "Current"
$gameHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$gameHeader.ForeColor = New-Color 110 110 105
$gameHeader.Location = New-Object System.Drawing.Point(343, 25)
$gameHeader.Size = New-Object System.Drawing.Size(100, 18)
$gameHeader.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$tuningPanel.Controls.Add($gameHeader)
Set-AnimatedToolTip -Control $gameHeader -Text "Value currently found in the selected game's installed mod settings."

$selectedHeader = New-Object System.Windows.Forms.Label
$selectedHeader.Text = "Result"
$selectedHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$selectedHeader.ForeColor = New-Color 110 110 105
$selectedHeader.Location = New-Object System.Drawing.Point(447, 25)
$selectedHeader.Size = New-Object System.Drawing.Size(90, 18)
$selectedHeader.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$tuningPanel.Controls.Add($selectedHeader)
Set-AnimatedToolTip -Control $selectedHeader -Text "Preview of the value that the next Install or Reinstall will produce."

$tuningHeaderRule = New-Object System.Windows.Forms.Panel
$tuningHeaderRule.Location = New-Object System.Drawing.Point(18, 45)
$tuningHeaderRule.Size = New-Object System.Drawing.Size(528, 1)
$tuningHeaderRule.BackColor = New-Color 236 234 229
$tuningPanel.Controls.Add($tuningHeaderRule)

$animalRowsPanel = New-Object System.Windows.Forms.Panel
$animalRowsPanel.Location = New-Object System.Drawing.Point(18, 49)
$animalRowsPanel.Size = New-Object System.Drawing.Size(540, 144)
$animalRowsPanel.BackColor = [System.Drawing.Color]::White
$tuningPanel.Controls.Add($animalRowsPanel)

# The grouped control is the first table row, directly above Dire wolf.
$tuningPanel.Controls.Remove($masterCheck)
$tuningPanel.Controls.Remove($masterTrack)
$tuningPanel.Controls.Remove($masterValue)
$masterCheck.Location = New-Object System.Drawing.Point(22, 0)
$masterCheck.Size = New-Object System.Drawing.Size(118, 22)
$masterTrack.Location = New-Object System.Drawing.Point(148, -6)
$masterTrack.Size = New-Object System.Drawing.Size(108, 34)
$masterValue.Location = New-Object System.Drawing.Point(264, 3)
$masterValue.Size = New-Object System.Drawing.Size(82, 18)
$animalRowsPanel.Controls.Add($masterCheck)
$animalRowsPanel.Controls.Add($masterTrack)
$animalRowsPanel.Controls.Add($masterValue)

$choiceImpact = New-Object System.Windows.Forms.Label
$choiceImpact.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
$choiceImpact.ForeColor = New-Color 82 82 78
$choiceImpact.Location = New-Object System.Drawing.Point(18, 194)
$choiceImpact.Size = New-Object System.Drawing.Size(528, 20)
$choiceImpact.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$choiceImpact.AutoEllipsis = $true
$choiceImpact.Visible = $false
$tuningPanel.Controls.Add($choiceImpact)

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = "Validate Current Game Settings"
$scanButton.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$scanButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$scanButton.FlatAppearance.BorderSize = 0
$scanButton.BackColor = [System.Drawing.Color]::White
$scanButton.ForeColor = New-Color 38 38 36
$scanButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$scanButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$scanButton.Location = New-Object System.Drawing.Point(179, 216)
$scanButton.Size = New-Object System.Drawing.Size(210, 30)
$scanButton.AccessibleName = "Validate current game settings"
$scanButton.AccessibleDescription = "Read current settings without modifying game, mod, or server configuration. Persistent logging, when enabled, writes the report to the chosen text file. The visible table is not refreshed."
$tuningPanel.Controls.Add($scanButton)
Enable-RoundedBorder $scanButton 15 (New-Color 208 208 202)
Set-AnimatedToolTip -Control $scanButton -Text "Freshly read the selected game's settings and open a validation report. This does not modify game, mod, or server configuration. If Persistent log is enabled, the report is written to the chosen log file. The visible Current column stays as shown."

$capPanel = New-Object System.Windows.Forms.Panel
$capPanel.Location = New-Object System.Drawing.Point(27, 498)
$capPanel.Size = New-Object System.Drawing.Size(567, 44)
$capPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($capPanel)
Enable-RoundedBorder $capPanel 16 (New-Color 226 224 218)

$capCheck = New-Object System.Windows.Forms.CheckBox
$capCheck.Text = "Raise Animal Spawn Cap - Brutal Science"
$capCheck.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.5, [System.Drawing.FontStyle]::Bold)
$capCheck.ForeColor = New-Color 130 45 35
$capCheck.AutoSize = $false
$capCheck.Location = New-Object System.Drawing.Point(16, 10)
$capCheck.Size = New-Object System.Drawing.Size(520, 24)
$capCheck.Checked = $false
$capCheck.AccessibleName = "Raise animal spawn cap - Brutal Science"
$capCheck.AccessibleDescription = "Optional global stress test for the whole game or server, not only the Wasteland. The normal game default is 50. After confirmation, back up serverconfig.xml and raise MaxSpawnedAnimals to 999. This does not create animals."
$capPanel.Controls.Add($capCheck)
Set-AnimatedToolTip -Control $capCheck -Text "This is the global animal limit for the entire game or server across all biomes, not only the Wasteland. The normal default is 50. Brutal Science backs up your current serverconfig.xml value, then sets the global limit to 999. The separate XML tuning in this mod still targets Wasteland animal routes."

$restoreCapButton = New-Object System.Windows.Forms.Button
$restoreCapButton.Text = "Restore Previous Global Limit"
$restoreCapButton.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$restoreCapButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$restoreCapButton.FlatAppearance.BorderSize = 0
$restoreCapButton.BackColor = [System.Drawing.Color]::White
$restoreCapButton.ForeColor = New-Color 130 45 35
$restoreCapButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$restoreCapButton.Location = New-Object System.Drawing.Point(370, 8)
$restoreCapButton.Size = New-Object System.Drawing.Size(170, 24)
$restoreCapButton.Enabled = $false
$restoreCapButton.AccessibleName = "Restore previous global animal limit"
$restoreCapButton.AccessibleDescription = "Restore serverconfig.xml from the newest Bit Wrecked animal-cap backup. This does not remove the mod or force a game-default value."
$capPanel.Controls.Add($restoreCapButton)
$restoreCapButton.Visible = $false
Enable-RoundedBorder $restoreCapButton 12 (New-Color 208 208 202)
Set-AnimatedToolTip -Control $restoreCapButton -Text "Restore the previous global animal limit for the whole game or server, not only the Wasteland. The normal default is 50, but Restore uses the newest saved Bit Wrecked serverconfig.xml value because a customized server may have used a different limit."

$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Install"
$installButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$installButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$installButton.FlatAppearance.BorderSize = 0
$installButton.FlatAppearance.MouseOverBackColor = New-Color 232 237 233
$installButton.FlatAppearance.MouseDownBackColor = New-Color 222 230 224
$installButton.BackColor = New-Color 238 240 237
$installButton.ForeColor = New-Color 42 91 55
$installButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$installButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$installButton.Padding = New-Object System.Windows.Forms.Padding(0)
$installButton.Location = New-Object System.Drawing.Point(27, 561)
$installButton.Size = New-Object System.Drawing.Size(206, 42)
$form.Controls.Add($installButton)
$script:IsPrimaryActionActive = $false
$installButton.Add_Paint({
    param($sender, $event)
    if (-not $script:IsPrimaryActionActive -or $sender.Width -lt 30) {
        return
    }
    $event.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # Layered highlights mimic translucent molded plastic while preserving the
    # native button text and the restrained gray base color.
    $glassBounds = New-Object System.Drawing.Rectangle(8, 3, ($sender.Width - 16), 15)
    $glassTop = [System.Drawing.Color]::FromArgb(145, 255, 255, 255)
    $glassBottom = [System.Drawing.Color]::FromArgb(8, 255, 255, 255)
    $glassBrush = New-Object -TypeName System.Drawing.Drawing2D.LinearGradientBrush -ArgumentList @($glassBounds, $glassTop, $glassBottom, [single]90)

    $shineBounds = New-Object System.Drawing.Rectangle(18, 4, ($sender.Width - 36), 3)
    $shineStart = [System.Drawing.Color]::FromArgb(115, 111, 218, 183)
    $shineEnd = [System.Drawing.Color]::FromArgb(105, 181, 152, 226)
    $shineBrush = New-Object -TypeName System.Drawing.Drawing2D.LinearGradientBrush -ArgumentList @($shineBounds, $shineStart, $shineEnd, [single]0)

    $lowerShade = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(18, 42, 91, 55))
    $pawShadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(170, 181, 152, 226))
    $pawColor = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(225, 64, 137, 88))
    $pixelGlint = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(205, 218, 247, 236))
    try {
        $event.Graphics.FillRectangle($glassBrush, $glassBounds)
        $event.Graphics.FillRectangle($shineBrush, $shineBounds)
        $event.Graphics.FillRectangle($lowerShade, 10, ($sender.Height - 7), ($sender.Width - 20), 3)

        # Tiny deliberately blocky paw: a readable pixel-art signature without
        # adding another circle or competing with the centered action label.
        $event.Graphics.FillRectangle($pawShadow, 17, 15, 4, 4)
        $event.Graphics.FillRectangle($pawShadow, 24, 12, 4, 4)
        $event.Graphics.FillRectangle($pawShadow, 31, 15, 4, 4)
        $event.Graphics.FillRectangle($pawShadow, 22, 21, 11, 7)
        $event.Graphics.FillRectangle($pawColor, 16, 14, 4, 4)
        $event.Graphics.FillRectangle($pawColor, 23, 11, 4, 4)
        $event.Graphics.FillRectangle($pawColor, 30, 14, 4, 4)
        $event.Graphics.FillRectangle($pawColor, 21, 20, 11, 7)

        $event.Graphics.FillRectangle($pixelGlint, ($sender.Width - 24), 11, 4, 4)
        $event.Graphics.FillRectangle($pixelGlint, ($sender.Width - 19), 7, 3, 3)
    }
    finally {
        $glassBrush.Dispose()
        $shineBrush.Dispose()
        $lowerShade.Dispose()
        $pawShadow.Dispose()
        $pawColor.Dispose()
        $pixelGlint.Dispose()
    }
})
Enable-RoundedBorder $installButton 21 (New-Color 83 158 98)

$actionDot = New-Object System.Windows.Forms.Label
$actionDot.Text = [char]0x2191
$actionDot.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$actionDot.ForeColor = New-Color 158 45 34
$actionDot.BackColor = [System.Drawing.Color]::White
$actionDot.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$actionDot.Cursor = [System.Windows.Forms.Cursors]::Hand
$actionDot.Location = New-Object System.Drawing.Point(184, 562)
$actionDot.Size = New-Object System.Drawing.Size(40, 40)
$form.Controls.Add($actionDot)
Set-RoundedRegion $actionDot 20
$actionDot.BringToFront()

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Text = "Remove Mod"
$removeButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$removeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$removeButton.FlatAppearance.BorderSize = 0
$removeButton.BackColor = [System.Drawing.Color]::White
$removeButton.ForeColor = New-Color 38 38 36
$removeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$removeButton.Location = New-Object System.Drawing.Point(249, 561)
$removeButton.Size = New-Object System.Drawing.Size(112, 42)
$form.Controls.Add($removeButton)
Enable-RoundedBorder $removeButton 21 (New-Color 208 208 202)
Set-AnimatedToolTip -Control $removeButton -Text "Delete this tool's installed mod folder from the selected game's Mods folder. The affected Wasteland routes then use game-default XML values. This does not restore serverconfig.xml or the global animal limit."

$openFolderButton = New-Object System.Windows.Forms.Button
$openFolderButton.Text = "Open Mods Folder"
$openFolderButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$openFolderButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$openFolderButton.FlatAppearance.BorderSize = 0
$openFolderButton.BackColor = [System.Drawing.Color]::White
$openFolderButton.ForeColor = New-Color 38 38 36
$openFolderButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$openFolderButton.Location = New-Object System.Drawing.Point(371, 561)
$openFolderButton.Size = New-Object System.Drawing.Size(130, 42)
$form.Controls.Add($openFolderButton)
Enable-RoundedBorder $openFolderButton 21 (New-Color 208 208 202)
Set-AnimatedToolTip -Control $openFolderButton -Text "Open <selected 7DTD game folder>\Mods in Windows Explorer. If Mods does not exist, this action creates it first. This is different from Choose Game Folder and shows all mods installed there."

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.BackColor = [System.Drawing.Color]::White
$closeButton.ForeColor = New-Color 38 38 36
$closeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$closeButton.Location = New-Object System.Drawing.Point(510, 561)
$closeButton.Size = New-Object System.Drawing.Size(84, 42)
$form.Controls.Add($closeButton)
Enable-RoundedBorder $closeButton 21 (New-Color 208 208 202)

$activityPanel = New-Object System.Windows.Forms.Panel
$activityPanel.BackColor = [System.Drawing.Color]::White
$activityPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$activityPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$activityTitle = New-Object System.Windows.Forms.Label
$activityTitle.Text = "Layered Reasoning Log / Recent Actions"
$activityTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9, [System.Drawing.FontStyle]::Bold)
$activityTitle.ForeColor = New-Color 38 38 36
$activityTitle.Location = New-Object System.Drawing.Point(14, 12)
$activityTitle.Size = New-Object System.Drawing.Size(410, 20)
$activityPanel.Controls.Add($activityTitle)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Ready"
$status.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$status.Location = New-Object System.Drawing.Point(14, 36)
$status.Size = New-Object System.Drawing.Size(415, 20)
$status.ForeColor = New-Color 82 82 78
$status.AutoEllipsis = $true
$status.Visible = $true
$activityPanel.Controls.Add($status)

$persistentLogCheck = New-Object System.Windows.Forms.CheckBox
$persistentLogCheck.Text = "Persistent log"
$persistentLogCheck.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$persistentLogCheck.ForeColor = New-Color 55 55 52
$persistentLogCheck.Location = New-Object System.Drawing.Point(14, 58)
$persistentLogCheck.Size = New-Object System.Drawing.Size(122, 24)
$persistentLogCheck.Checked = $false
$persistentLogCheck.AccessibleName = "Persistent layered reasoning log"
$activityPanel.Controls.Add($persistentLogCheck)
$script:PersistentLogCheck = $persistentLogCheck

$chooseLogFileButton = New-Object System.Windows.Forms.Button
$chooseLogFileButton.Text = "Choose Log File"
$chooseLogFileButton.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
$chooseLogFileButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$chooseLogFileButton.FlatAppearance.BorderSize = 0
$chooseLogFileButton.BackColor = New-Color 247 248 246
$chooseLogFileButton.ForeColor = New-Color 38 38 36
$chooseLogFileButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$chooseLogFileButton.Location = New-Object System.Drawing.Point(142, 57)
$chooseLogFileButton.Size = New-Object System.Drawing.Size(120, 26)
$chooseLogFileButton.AccessibleName = "Choose persistent log file"
$activityPanel.Controls.Add($chooseLogFileButton)
Enable-RoundedBorder $chooseLogFileButton 13 (New-Color 208 208 202)

$persistentLogPathLabel = New-Object System.Windows.Forms.Label
$persistentLogPathLabel.Text = "Runtime only - clears when this application restarts."
$persistentLogPathLabel.Font = New-Object System.Drawing.Font("Segoe UI", 7)
$persistentLogPathLabel.ForeColor = New-Color 110 110 105
$persistentLogPathLabel.Location = New-Object System.Drawing.Point(14, 86)
$persistentLogPathLabel.Size = New-Object System.Drawing.Size(248, 28)
$persistentLogPathLabel.AutoEllipsis = $true
$activityPanel.Controls.Add($persistentLogPathLabel)
$script:PersistentLogPathLabel = $persistentLogPathLabel

$activityLog = New-Object System.Windows.Forms.RichTextBox
$activityLog.ReadOnly = $true
$activityLog.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$activityLog.BackColor = New-Color 247 248 246
$activityLog.ForeColor = New-Color 55 55 52
$activityLog.Font = New-Object System.Drawing.Font("Consolas", 7.5)
$activityLog.Location = New-Object System.Drawing.Point(14, 118)
$activityLog.Size = New-Object System.Drawing.Size(415, 515)
$activityLog.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$activityLog.WordWrap = $true
$activityLog.DetectUrls = $false
$activityLog.Text = "[$(Get-Date -Format 'HH:mm:ss')] Ready.$([Environment]::NewLine)[$(Get-Date -Format 'HH:mm:ss')] LAYERS | Facts -> Gameplay consequence -> Generated commentary$([Environment]::NewLine)"
$activityPanel.Controls.Add($activityLog)
$script:ActivityLogBox = $activityLog
$activityPanel.Add_Resize({
    $contentWidth = [Math]::Max(120, $activityPanel.ClientSize.Width - 28)
    $activityTitle.Width = $contentWidth
    $status.Width = $contentWidth
    $persistentLogPathLabel.Width = $contentWidth
    $chooseLogFileButton.Left = [Math]::Max(142, $activityPanel.ClientSize.Width - 134)
    $activityLog.Width = $contentWidth
    $activityLog.Height = [Math]::Max(100, $activityPanel.ClientSize.Height - 135)
})
Set-AnimatedToolTip -Control $activityTitle -Text "Layered session history: verified facts and file changes first, gameplay consequences second, and weighted generated commentary last. Long entries wrap and the log follows the newest entry."
Set-AnimatedToolTip -Control $status -Text "Most recent action. Full messages and long paths remain available in the scrollable Layered Reasoning Log below."
Set-AnimatedToolTip -Control $persistentLogCheck -Text "Off by default: the Layered Reasoning Log exists only while this application is open and clears on restart. Enable this to save the visible session log to a file you choose."
Set-AnimatedToolTip -Control $chooseLogFileButton -Text "Choose an independent text-file location with the Windows Save dialog. This does not use or change the selected game folder, Mods folder, or mod files."

function Select-PersistentActivityLogFile {
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Title = "Choose Where to Save the Layered Reasoning Log"
    $saveDialog.Filter = "Text log (*.txt)|*.txt|Log file (*.log)|*.log|All files (*.*)|*.*"
    $saveDialog.FilterIndex = 1
    $saveDialog.DefaultExt = "txt"
    $saveDialog.AddExtension = $true
    $saveDialog.OverwritePrompt = $true
    $saveDialog.RestoreDirectory = $true
    $saveDialog.InitialDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
    $saveDialog.FileName = "BitWrecked-7DTD-Layered-Reasoning-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

    if ($saveDialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK) {
        return $false
    }

    $script:PersistentLogPath = $saveDialog.FileName
    $persistentLogPathLabel.Text = "Selected: $($saveDialog.FileName)"
    $persistentLogPathLabel.ForeColor = New-Color 82 82 78
    Set-AnimatedToolTip -Control $persistentLogPathLabel -Text "Persistent Layered Reasoning Log file: $($saveDialog.FileName)"
    return $true
}

function Show-PersistentLogConsentDialog {
    $consentDialog = New-Object System.Windows.Forms.Form
    $consentDialog.Text = "Confirm Persistent Log File"
    $consentDialog.ClientSize = New-Object System.Drawing.Size(560, 300)
    $consentDialog.StartPosition = "CenterParent"
    $consentDialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $consentDialog.MaximizeBox = $false
    $consentDialog.MinimizeBox = $false
    $consentDialog.ShowInTaskbar = $false
    $consentDialog.BackColor = New-Color 250 249 247

    $consentTitle = New-Object System.Windows.Forms.Label
    $consentTitle.Text = "Are you sure you want to write a log file to your computer?"
    $consentTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 12, [System.Drawing.FontStyle]::Bold)
    $consentTitle.ForeColor = New-Color 130 45 35
    $consentTitle.Location = New-Object System.Drawing.Point(24, 22)
    $consentTitle.Size = New-Object System.Drawing.Size(512, 52)
    $consentTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $consentDialog.Controls.Add($consentTitle)

    $consentBody = New-Object System.Windows.Forms.Label
    $consentBody.Text = "This can be done, but only if you want it done.`nThe normal Layered Reasoning Log is runtime-only and clears when the application restarts."
    $consentBody.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $consentBody.ForeColor = New-Color 55 55 52
    $consentBody.Location = New-Object System.Drawing.Point(34, 82)
    $consentBody.Size = New-Object System.Drawing.Size(492, 52)
    $consentBody.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $consentDialog.Controls.Add($consentBody)

    $writeLogButton = New-Object System.Windows.Forms.Button
    $writeLogButton.Text = "I want to write a log file to my computer"
    $writeLogButton.Font = New-Object System.Drawing.Font("Comic Sans MS", 16, [System.Drawing.FontStyle]::Bold)
    $writeLogButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $writeLogButton.FlatAppearance.BorderSize = 3
    $writeLogButton.FlatAppearance.BorderColor = [System.Drawing.Color]::Gold
    $writeLogButton.BackColor = New-Color 142 28 28
    $writeLogButton.ForeColor = [System.Drawing.Color]::Yellow
    $writeLogButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $writeLogButton.Location = New-Object System.Drawing.Point(34, 148)
    $writeLogButton.Size = New-Object System.Drawing.Size(492, 72)
    $writeLogButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $consentDialog.Controls.Add($writeLogButton)

    $cancelConsentButton = New-Object System.Windows.Forms.Button
    $cancelConsentButton.Text = "Keep Runtime Only"
    $cancelConsentButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $cancelConsentButton.Location = New-Object System.Drawing.Point(196, 240)
    $cancelConsentButton.Size = New-Object System.Drawing.Size(168, 36)
    $cancelConsentButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $consentDialog.Controls.Add($cancelConsentButton)

    $consentDialog.AcceptButton = $null
    $consentDialog.CancelButton = $cancelConsentButton
    return ($consentDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::Yes)
}

$chooseLogFileButton.Add_Click({
    if (Select-PersistentActivityLogFile) {
        if ($persistentLogCheck.Checked) {
            $script:PersistentLogEnabled = $true
            Save-ActivityLogSnapshot
            $persistentLogPathLabel.Text = "Saving: $script:PersistentLogPath"
        }
        Set-Status $status "Persistent log file selected: $script:PersistentLogPath" (New-Color 82 82 78)
    }
})

$persistentLogCheck.Add_CheckedChanged({
    if ($script:IsUpdatingPersistentLog) {
        return
    }

    if ($persistentLogCheck.Checked) {
        if (-not (Show-PersistentLogConsentDialog)) {
            $script:IsUpdatingPersistentLog = $true
            $persistentLogCheck.Checked = $false
            $script:IsUpdatingPersistentLog = $false
            return
        }

        if ([string]::IsNullOrWhiteSpace($script:PersistentLogPath) -and -not (Select-PersistentActivityLogFile)) {
            $script:IsUpdatingPersistentLog = $true
            $persistentLogCheck.Checked = $false
            $script:IsUpdatingPersistentLog = $false
            return
        }

        $script:PersistentLogEnabled = $true
        $persistentLogPathLabel.Text = "Saving: $script:PersistentLogPath"
        $persistentLogPathLabel.ForeColor = New-Color 52 94 72
        Save-ActivityLogSnapshot
        Set-Status $status "Persistent Layered Reasoning Log enabled." (New-Color 52 94 72)
    }
    else {
        $script:PersistentLogEnabled = $false
        if ([string]::IsNullOrWhiteSpace($script:PersistentLogPath)) {
            $persistentLogPathLabel.Text = "Runtime only - clears when this application restarts."
        }
        else {
            $persistentLogPathLabel.Text = "Persistence off; saved file remains: $script:PersistentLogPath"
        }
        $persistentLogPathLabel.ForeColor = New-Color 110 110 105
        Set-Status $status "Persistent Layered Reasoning Log disabled; runtime log continues." (New-Color 82 82 78)
    }
})

$activityToggleButton = New-Object System.Windows.Forms.Button
$activityToggleButton.Text = [char]0x25B6
$activityToggleButton.Font = New-Object System.Drawing.Font("Segoe UI Symbol", 9, [System.Drawing.FontStyle]::Bold)
$activityToggleButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$activityToggleButton.FlatAppearance.BorderSize = 0
$activityToggleButton.BackColor = New-Color 238 240 237
$activityToggleButton.ForeColor = New-Color 42 91 55
$activityToggleButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$activityToggleButton.Location = New-Object System.Drawing.Point(596, 306)
$activityToggleButton.Size = New-Object System.Drawing.Size(18, 74)
$activityToggleButton.TabStop = $true
$activityToggleButton.AccessibleName = "Show layered reasoning log"
$form.Controls.Add($activityToggleButton)
Enable-RoundedBorder $activityToggleButton 9 (New-Color 83 158 98)
$activityToggleButton.BringToFront()

# Keep the application at its designed width while allowing the activity log
# to behave like a true pull-to-resize partition when it is expanded.
$workspaceSplit = New-Object System.Windows.Forms.SplitContainer
$workspaceSplit.Size = New-Object System.Drawing.Size(1250, 660)
$workspaceSplit.Dock = [System.Windows.Forms.DockStyle]::Fill
$workspaceSplit.Orientation = [System.Windows.Forms.Orientation]::Vertical
$workspaceSplit.FixedPanel = [System.Windows.Forms.FixedPanel]::Panel1
$workspaceSplit.SplitterWidth = 7
$workspaceSplit.Panel1MinSize = 600
$workspaceSplit.Panel2MinSize = 300
$workspaceSplit.SplitterDistance = 620
$workspaceSplit.IsSplitterFixed = $false
$workspaceSplit.BackColor = New-Color 214 218 212
$workspaceSplit.Panel1.BackColor = $form.BackColor
$workspaceSplit.Panel2.BackColor = $form.BackColor
$workspaceSplit.Panel2.Padding = New-Object System.Windows.Forms.Padding(10, 18, 17, 22)

$mainControls = @($form.Controls | Where-Object { $_ -ne $activityPanel })
foreach ($control in $mainControls) {
    $form.Controls.Remove($control)
    $workspaceSplit.Panel1.Controls.Add($control)
}
$workspaceSplit.Panel2.Controls.Add($activityPanel)
$form.Controls.Add($workspaceSplit)
$activityToggleButton.BringToFront()

$script:IsActivityLogExpanded = $false
function Set-ActivityLogExpanded {
    param([bool]$Expanded)

    $form.SuspendLayout()
    try {
        $script:IsActivityLogExpanded = $Expanded
        if ($Expanded) {
            $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
            $form.MaximizeBox = $true
            $form.MinimumSize = New-Object System.Drawing.Size(900, 500)
            $form.ClientSize = New-Object System.Drawing.Size(930, 660)
            $workspaceSplit.Panel2Collapsed = $false
            $workspaceSplit.SplitterDistance = 620
            $activityToggleButton.Text = [char]0x25C0
            $activityToggleButton.AccessibleName = "Hide layered reasoning log"
            Set-AnimatedToolTip -Control $activityToggleButton -Text "Collapse the Layered Reasoning Log. Drag the divider to resize the open log; session history is preserved."
        }
        else {
            if ($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Maximized) {
                $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
            }
            $workspaceSplit.Panel2Collapsed = $true
            $form.MinimumSize = New-Object System.Drawing.Size(0, 0)
            $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
            $form.MaximizeBox = $false
            $form.ClientSize = New-Object System.Drawing.Size(620, 660)
            $activityToggleButton.Text = [char]0x25B6
            $activityToggleButton.AccessibleName = "Show layered reasoning log"
            Set-AnimatedToolTip -Control $activityToggleButton -Text "Snap open the Layered Reasoning Log. Once open, pull its divider sideways to resize it."
        }
        $activityToggleButton.BringToFront()
    }
    finally {
        $form.ResumeLayout($true)
    }
}

$activityToggleButton.Add_Click({
    Set-ActivityLogExpanded -Expanded (-not $script:IsActivityLogExpanded)
})
Set-ActivityLogExpanded -Expanded $false

$script:AnimalRows = @()
$script:AnimalLevels = @{}
$script:AnimalEnabled = @{}
$script:AnimalControls = @{}
$script:IsUpdatingTuning = $false
$script:HasInitializedAnimalRows = $false
$script:MasterLevel = 2

function Ensure-AnimalLevelKeys {
    $entities = Get-AnimalEntitiesFromRows -Rows $script:AnimalRows
    foreach ($entity in $entities) {
        if (-not $script:AnimalLevels.ContainsKey($entity)) {
            $script:AnimalLevels[$entity] = 2
        }
        if (-not $script:AnimalEnabled.ContainsKey($entity)) {
            $script:AnimalEnabled[$entity] = $true
        }
    }
}

function Get-AnimalRowPreviewText {
    param(
        [string]$Entity,
        [int]$Level
    )

    $parts = New-Object System.Collections.ArrayList
    foreach ($row in @($script:AnimalRows | Where-Object { $_.Entity -eq $Entity })) {
        $value = Format-TuningWeight ($row.Base * (Get-TuningFactor $Level))
        [void]$parts.Add("$(Get-GroupShortName $row.Group) $value")
    }

    if ($parts.Count -eq 0) {
        return "no rows"
    }

    return ($parts -join " / ")
}

function Get-CurrentAnimalValueMap {
    param([array]$Rows)

    $values = @{}
    foreach ($row in @($Rows)) {
        $values[$row.XPath] = Format-TuningWeight $row.Base
    }

    try {
        if (Test-ModInstalled $pathBox.Text) {
            $installedMap = Get-InstalledPatchValueMap -TargetMod (Get-TargetModPath $pathBox.Text)
            foreach ($xpath in $installedMap.Keys) {
                $values[$xpath] = $installedMap[$xpath]
            }
        }
    }
    catch {
        # Keep the base-game values visible if the installed mod cannot be read.
    }

    return $values
}

function Get-AnimalRowBaseText {
    param([string]$Entity)

    $parts = New-Object System.Collections.ArrayList
    $currentValues = Get-CurrentAnimalValueMap -Rows $script:AnimalRows
    foreach ($row in @($script:AnimalRows | Where-Object { $_.Entity -eq $Entity })) {
        $value = Format-TuningWeight $row.Base
        if ($currentValues.ContainsKey($row.XPath)) {
            $value = $currentValues[$row.XPath]
        }
        [void]$parts.Add("$(Get-GroupShortName $row.Group) $value")
    }

    if ($parts.Count -eq 0) {
        return "n/a"
    }

    return ($parts -join " / ")
}

function Get-AnimalRowDefaultText {
    param([string]$Entity)

    $parts = New-Object System.Collections.ArrayList
    foreach ($row in @($script:AnimalRows | Where-Object { $_.Entity -eq $Entity })) {
        [void]$parts.Add("$(Get-GroupShortName $row.Group) $(Format-TuningWeight $row.Base)")
    }
    return $(if ($parts.Count -gt 0) { $parts -join " / " } else { "n/a" })
}

function Test-AnimalCurrentlyTuned {
    param([string]$Entity)

    try {
        if (-not (Test-ModInstalled $pathBox.Text)) { return $false }
        $installedMap = Get-InstalledPatchValueMap -TargetMod (Get-TargetModPath $pathBox.Text)
        foreach ($row in @($script:AnimalRows | Where-Object { $_.Entity -eq $Entity })) {
            if ($installedMap.ContainsKey($row.XPath)) { return $true }
        }
    }
    catch { return $false }
    return $false
}

function Get-PendingAnimalRemovals {
    param([hashtable]$SelectedLevels)

    return @(
        Get-AnimalEntitiesFromRows -Rows $script:AnimalRows |
            Where-Object { -not $SelectedLevels.ContainsKey($_) -and (Test-AnimalCurrentlyTuned -Entity $_) }
    )
}

function Get-EffectiveAnimalLevels {
    $levels = @{}
    foreach ($entity in (Get-AnimalEntitiesFromRows -Rows $script:AnimalRows)) {
        if ($masterCheck.Checked) {
            $levels[$entity] = [int]$script:MasterLevel
        }
        elseif ($script:AnimalEnabled.ContainsKey($entity) -and [bool]$script:AnimalEnabled[$entity]) {
            $levels[$entity] = [int]$script:AnimalLevels[$entity]
        }
    }
    return $levels
}

function Get-ActiveAnimalEntities {
    if ($masterCheck.Checked) {
        return @(Get-AnimalEntitiesFromRows -Rows $script:AnimalRows)
    }

    return @(
        Get-AnimalEntitiesFromRows -Rows $script:AnimalRows |
            Where-Object { $script:AnimalEnabled.ContainsKey($_) -and [bool]$script:AnimalEnabled[$_] }
    )
}

function Update-AnimalRowControl {
    param([string]$Entity)

    if (-not $script:AnimalControls.ContainsKey($Entity)) {
        return
    }

    $controls = $script:AnimalControls[$Entity]
    $masterLocked = [bool]$masterCheck.Checked
    $enabled = $masterLocked -or ([bool]$script:AnimalEnabled[$Entity])
    $level = if ($masterLocked) { [int]$script:MasterLevel } elseif ($enabled) { [int]$script:AnimalLevels[$Entity] } else { 2 }

    $controls.Check.Checked = $enabled
    $controls.Check.Enabled = -not $masterLocked
    Set-SliderLevel -Track $controls.Track -Level $level
    $controls.Track.Enabled = (-not $masterLocked -and $enabled)
    $currentlyTuned = Test-AnimalCurrentlyTuned -Entity $Entity
    $controls.Value.Text = if ($enabled) { Get-TuningLevelName $level } elseif ($currentlyTuned) { "Uninstall" } else { "Keep" }
    $controls.Base.Text = Get-AnimalRowBaseText -Entity $Entity
    $controls.Preview.Text = if ($enabled) { Get-AnimalRowPreviewText -Entity $Entity -Level $level } elseif ($currentlyTuned) { Get-AnimalRowDefaultText -Entity $Entity } else { Get-AnimalRowBaseText -Entity $Entity }

    if ($enabled) {
        $controls.Value.ForeColor = New-Color 82 82 78
        $controls.Base.ForeColor = New-Color 82 82 78
        $controls.Preview.ForeColor = New-Color 82 82 78
    }
    else {
        $controls.Value.ForeColor = New-Color 145 145 138
        $controls.Base.ForeColor = New-Color 145 145 138
        $controls.Preview.ForeColor = New-Color 145 145 138
    }
}

function Update-AllAnimalRowControls {
    foreach ($entity in (Get-AnimalEntitiesFromRows -Rows $script:AnimalRows)) {
        Update-AnimalRowControl -Entity $entity
    }
}

function Get-ChoiceImpactText {
    $effectiveLevels = Get-EffectiveAnimalLevels
    $activeEntities = Get-ActiveAnimalEntities

    if ($activeEntities.Count -eq 0) {
        $pendingRemovals = @(Get-PendingAnimalRemovals -SelectedLevels $effectiveLevels)
        if ($pendingRemovals.Count -eq 1) {
            return "Uninstall to default: $(Get-AnimalDisplayName $pendingRemovals[0])."
        }
        if ($pendingRemovals.Count -gt 1) {
            $pendingNames = @($pendingRemovals | ForEach-Object { Get-AnimalDisplayName $_ }) -join ", "
            return "Uninstall to default: $pendingNames."
        }
        return ""
    }

    $levelGroups = @($activeEntities | Group-Object { [int]$effectiveLevels[$_] })
    $densityLevel = Get-DensityLevelFromAnimalLevels -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels
    $densityName = Get-TuningLevelName $densityLevel
    if ($levelGroups.Count -eq 1) {
        $levelName = Get-TuningLevelName ([int]$levelGroups[0].Name)
        if ($activeEntities.Count -eq (Get-AnimalEntitiesFromRows -Rows $script:AnimalRows).Count) {
            $animalText = "All animals (grouped): $levelName. Density: $densityName."
            return $animalText
        }
        $animalText = "$($activeEntities.Count) selected: $levelName. Density: $densityName."
        return $animalText
    }

    $animalText = "$($activeEntities.Count) selected: mixed levels. Density: $densityName."
    return $animalText
}

function Refresh-AnimalChoices {
    $previousEnabled = @{}
    $previousLevels = @{}
    foreach ($entity in $script:AnimalEnabled.Keys) {
        $previousEnabled[$entity] = [bool]$script:AnimalEnabled[$entity]
    }
    foreach ($entity in $script:AnimalLevels.Keys) {
        $previousLevels[$entity] = [int]$script:AnimalLevels[$entity]
    }

    $script:AnimalRows = Get-WastelandAnimalWeightRows -GameRoot $pathBox.Text
    Ensure-AnimalLevelKeys
    $entities = Get-AnimalEntitiesFromRows -Rows $script:AnimalRows

    $script:IsUpdatingTuning = $true
    $animalRowsPanel.SuspendLayout()
    try {
        $animalRowsPanel.Controls.Clear()
        $animalRowsPanel.Controls.Add($masterCheck)
        $animalRowsPanel.Controls.Add($masterTrack)
        $animalRowsPanel.Controls.Add($masterValue)
        $script:AnimalControls.Clear()

        $rowIndex = 0
        foreach ($entity in $entities) {
            if ($previousLevels.ContainsKey($entity)) {
                $script:AnimalLevels[$entity] = [int]$previousLevels[$entity]
            }
            if ($previousEnabled.ContainsKey($entity)) {
                $script:AnimalEnabled[$entity] = [bool]$previousEnabled[$entity]
            }
            else {
                $script:AnimalEnabled[$entity] = $false
            }

            if ($masterCheck.Checked) {
                $script:AnimalLevels[$entity] = [int]$script:MasterLevel
                $script:AnimalEnabled[$entity] = $true
            }

            $y = ($rowIndex + 1) * 24
            $displayName = Get-AnimalDisplayName $entity

            $check = New-Object System.Windows.Forms.CheckBox
            $check.Text = $displayName
            $check.Tag = $entity
            $check.AccessibleName = "Animal: $displayName | Column: Animal Selection"
            $check.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $check.ForeColor = New-Color 38 38 36
            $check.Location = New-Object System.Drawing.Point(22, $y)
            $check.Size = New-Object System.Drawing.Size(118, 22)
            $animalRowsPanel.Controls.Add($check)

            $track = New-Object System.Windows.Forms.TrackBar
            $track.Tag = $entity
            $track.AccessibleName = "Animal: $displayName | Column: Level"
            $track.Minimum = 0
            $track.Maximum = 6
            $track.TickStyle = [System.Windows.Forms.TickStyle]::None
            $track.TickFrequency = 1
            $track.LargeChange = 1
            $track.SmallChange = 1
            $track.AutoSize = $false
            $track.Location = New-Object System.Drawing.Point(148, ($y - 6))
            $track.Size = New-Object System.Drawing.Size(108, 34)
            $track.BackColor = [System.Drawing.Color]::White
            $animalRowsPanel.Controls.Add($track)

            $valueLabel = New-Object System.Windows.Forms.Label
            $valueLabel.AccessibleName = "Animal: $displayName | Column: Action"
            $valueLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $valueLabel.Location = New-Object System.Drawing.Point(264, ($y + 3))
            $valueLabel.Size = New-Object System.Drawing.Size(82, 18)
            $animalRowsPanel.Controls.Add($valueLabel)
            Set-AnimatedToolTip -Control $valueLabel -Text "Action for ${displayName}: Keep leaves it alone, Uninstall removes its existing tuning and returns it to game defaults, and a level installs that result."

            $baseLabel = New-Object System.Windows.Forms.Label
            $baseLabel.AccessibleName = "Animal: $displayName | Column: Current"
            $baseLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $baseLabel.Location = New-Object System.Drawing.Point(346, ($y + 3))
            $baseLabel.Size = New-Object System.Drawing.Size(100, 18)
            $animalRowsPanel.Controls.Add($baseLabel)
            Set-AnimatedToolTip -Control $baseLabel -Text "Current installed value for $displayName in the selected game folder."

            $previewLabel = New-Object System.Windows.Forms.Label
            $previewLabel.AccessibleName = "Animal: $displayName | Column: Result"
            $previewLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $previewLabel.Location = New-Object System.Drawing.Point(450, ($y + 3))
            $previewLabel.Size = New-Object System.Drawing.Size(90, 18)
            $animalRowsPanel.Controls.Add($previewLabel)
            Set-AnimatedToolTip -Control $previewLabel -Text "Resulting value for $displayName after the next Install or Reinstall."

            $script:AnimalControls[$entity] = @{
                Check = $check
                Track = $track
                Value = $valueLabel
                Base = $baseLabel
                Preview = $previewLabel
            }

            $check.Add_CheckedChanged({
                param($sender, $eventArgs)
                if ($script:IsUpdatingTuning) {
                    return
                }
                $entityName = [string]$sender.Tag
                $script:AnimalEnabled[$entityName] = [bool]$sender.Checked
                if (-not $sender.Checked) {
                    $script:AnimalLevels[$entityName] = 2
                }
                Update-TuningLabels
                Update-PrimaryActionState -GameRoot $pathBox.Text
                $selectionVerb = if ($sender.Checked) { "Selected" } else { "Cleared" }
                Set-Status $status "$selectionVerb animal: $($sender.Text)." (New-Color 82 82 78)
            })

            $track.Add_Scroll({
                param($sender, $eventArgs)
                if ($script:IsUpdatingTuning) {
                    return
                }
                $entityName = [string]$sender.Tag
                $level = Get-LevelFromSliderValue ([int]$sender.Value)
                Set-SliderLevel -Track $sender -Level $level
                $script:AnimalLevels[$entityName] = $level
                Update-TuningLabels
                Update-PrimaryActionState -GameRoot $pathBox.Text
            })
            $track.Add_MouseUp({
                param($sender, $eventArgs)
                $level = Get-LevelFromSliderValue ([int]$sender.Value)
                Set-Status $status "Animal level selected: $(Get-AnimalDisplayName ([string]$sender.Tag)) = $(Get-TuningLevelName $level)." (New-Color 82 82 78)
            })

            $rowIndex++
        }

        $script:HasInitializedAnimalRows = $true
        Update-AllAnimalRowControls
    }
    finally {
        $animalRowsPanel.ResumeLayout()
        $script:IsUpdatingTuning = $false
    }
}

function Set-MasterLevel {
    param([int]$Level)

    $script:MasterLevel = $Level
    Set-SliderLevel -Track $masterTrack -Level $Level
    $masterValue.Text = Get-TuningLevelName $Level

    if ($masterCheck.Checked) {
        foreach ($entity in (Get-AnimalEntitiesFromRows -Rows $script:AnimalRows)) {
            $script:AnimalEnabled[$entity] = $true
            $script:AnimalLevels[$entity] = $Level
        }
    }

    Update-AllAnimalRowControls
}

function Set-MasterLock {
    param([bool]$Locked)

    $masterCheck.Checked = $Locked
    $masterTrack.Enabled = $Locked
    if ($Locked) {
        Set-MasterLevel -Level (Get-LevelFromSliderValue ([int]$masterTrack.Value))
    }
    else {
        $wasUpdatingTuning = $script:IsUpdatingTuning
        $script:IsUpdatingTuning = $true
        try {
            foreach ($entity in (Get-AnimalEntitiesFromRows -Rows $script:AnimalRows)) {
                $script:AnimalEnabled[$entity] = $false
                $script:AnimalLevels[$entity] = 2
            }
            Update-AllAnimalRowControls
        }
        finally {
            $script:IsUpdatingTuning = $wasUpdatingTuning
        }
    }
}

function Test-InstalledAnimalConfig {
    param(
        [string]$TargetMod,
        [string]$GameRoot,
        [hashtable]$AnimalLevels
    )

    $expectedRows = Get-TunedEntityGroupRows -GameRoot $GameRoot -AnimalLevels $AnimalLevels
    $configPath = Join-Path $TargetMod "Config\entitygroups.xml"
    [xml]$configXml = Get-Content -LiteralPath $configPath -Raw
    $setNodes = @($configXml.SelectNodes("/configs/set"))

    if ($setNodes.Count -ne $expectedRows.Count) {
        throw "Installed XML row count was $($setNodes.Count), expected $($expectedRows.Count)."
    }

    foreach ($row in $expectedRows) {
        $match = $setNodes | Where-Object { $_.GetAttribute("xpath") -eq $row.XPath } | Select-Object -First 1
        if ($null -eq $match) {
            throw "Installed XML is missing $($row.XPath)."
        }
        if ($match.InnerText -ne $row.Value) {
            throw "Installed XML value for $($row.XPath) was $($match.InnerText), expected $($row.Value)."
        }
    }

    return @($expectedRows)
}

function Test-InstalledSpawningConfig {
    param(
        [string]$TargetMod,
        [string]$GameRoot,
        [hashtable]$AnimalLevels
    )

    $densityLevel = Get-DensityLevelFromAnimalLevels -GameRoot $GameRoot -AnimalLevels $AnimalLevels
    $expectedRows = Get-TunedSpawningRows -GameRoot $GameRoot -DensityLevel $densityLevel
    $expectedRoutes = Get-PressureSpawnRoutes -GameRoot $GameRoot -AnimalLevels $AnimalLevels
    $configPath = Join-Path $TargetMod "Config\spawning.xml"
    [xml]$configXml = Get-Content -LiteralPath $configPath -Raw
    $setNodes = @($configXml.SelectNodes("/configs/set"))
    $routeNodes = @($configXml.SelectNodes("/configs/append[@xpath=`"/spawning/biome[@name='wasteland']`"]/spawn"))

    if ($setNodes.Count -ne $expectedRows.Count) {
        throw "Installed spawn-density XML row count was $($setNodes.Count), expected $($expectedRows.Count)."
    }

    foreach ($row in $expectedRows) {
        $match = $setNodes | Where-Object { $_.GetAttribute("xpath") -eq $row.XPath } | Select-Object -First 1
        if ($null -eq $match) {
            throw "Installed spawn-density XML is missing $($row.XPath)."
        }
        if ($match.InnerText -ne $row.Value) {
            throw "Installed spawn-density XML value for $($row.XPath) was $($match.InnerText), expected $($row.Value)."
        }
    }

    if ($routeNodes.Count -ne $expectedRoutes.Count) {
        throw "Installed pressure route count was $($routeNodes.Count), expected $($expectedRoutes.Count)."
    }

    foreach ($route in $expectedRoutes) {
        $match = $routeNodes | Where-Object { $_.GetAttribute("id") -eq $route.Id } | Select-Object -First 1
        if ($null -eq $match) {
            throw "Installed pressure routes are missing $($route.Id)."
        }
        foreach ($attributeName in @("maxcount", "respawndelay", "time", "entitygroup")) {
            $expectedValue = switch ($attributeName) {
                "maxcount" { $route.MaxCount }
                "respawndelay" { $route.RespawnDelay }
                "time" { $route.Time }
                "entitygroup" { $route.EntityGroup }
            }
            if ($match.GetAttribute($attributeName) -ne $expectedValue) {
                throw "Installed pressure route $($route.Id) $attributeName was $($match.GetAttribute($attributeName)), expected $expectedValue."
            }
        }
    }

    return @($expectedRows)
}

function New-InstallFeedbackText {
    param(
        [array]$VerifiedRows,
        [hashtable]$AnimalLevels,
        [string]$GameRoot,
        [int]$DensityLevel,
        [hashtable]$BeforeValuesByXPath = @{},
        [array]$RemovedEntities = @(),
        [hashtable]$CapResult = $null
    )

    $lines = New-Object System.Collections.ArrayList
    [void]$lines.Add("Installed and verified Wasteland animal tuning.")
    [void]$lines.Add("")
    [void]$lines.Add("Density: $(Get-TuningLevelName $DensityLevel)")
    $pressureRoutes = Get-PressureSpawnRoutes -GameRoot $GameRoot -AnimalLevels $AnimalLevels
    if ($pressureRoutes.Count -gt 0) {
        [void]$lines.Add("Pressure routes: $($pressureRoutes.Count) extra selected-animal route handles")
    }
    else {
        [void]$lines.Add("Pressure routes: vanilla route only")
    }
    if ($null -ne $CapResult) {
        [void]$lines.Add("")
        [void]$lines.Add("File: $(Join-Path $GameRoot 'serverconfig.xml')")
        [void]$lines.Add("Setting: MaxSpawnedAnimals")
        [void]$lines.Add("Before: $($CapResult.PreviousValue)")
        [void]$lines.Add("After: $($CapResult.NewValue)")
        if ([bool]$CapResult.Changed) {
            [void]$lines.Add("File action: serverconfig.xml was backed up and then modified.")
        }
        else {
            [void]$lines.Add("File action: serverconfig.xml already contained that value and was not rewritten.")
        }
    }
    [void]$lines.Add("")
    [void]$lines.Add("Animal checkbox changes:")

    $verifiedEntities = Get-AnimalEntitiesFromRows -Rows $VerifiedRows
    $defaultRowsByXPath = @{}
    foreach ($defaultRow in @(Get-WastelandAnimalWeightRows -GameRoot $GameRoot)) {
        $defaultRowsByXPath[$defaultRow.XPath] = Format-TuningWeight $defaultRow.Base
    }
    $entityGroupsPath = Join-Path $GameRoot "Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning\Config\entitygroups.xml"
    foreach ($entity in $verifiedEntities) {
        if (-not $AnimalLevels.ContainsKey($entity)) {
            continue
        }
        $level = [int]$AnimalLevels[$entity]
        $beforeParts = New-Object System.Collections.ArrayList
        $afterParts = New-Object System.Collections.ArrayList
        foreach ($row in @($VerifiedRows | Where-Object { $_.Entity -eq $entity })) {
            $beforeValue = if ($BeforeValuesByXPath.ContainsKey($row.XPath)) {
                $BeforeValuesByXPath[$row.XPath]
            }
            elseif ($defaultRowsByXPath.ContainsKey($row.XPath)) {
                $defaultRowsByXPath[$row.XPath]
            }
            else {
                "not present"
            }
            [void]$beforeParts.Add("$(Get-GroupShortName $row.Group) $beforeValue")
            [void]$afterParts.Add("$(Get-GroupShortName $row.Group) $($row.Value)")
        }
        [void]$lines.Add("")
        [void]$lines.Add("File: $entityGroupsPath")
        [void]$lines.Add("Setting: $(Get-AnimalDisplayName $entity) - $(Get-TuningLevelName $level)")
        [void]$lines.Add("Before: $($beforeParts -join ', ')")
        [void]$lines.Add("After: $($afterParts -join ', ')")
    }

    foreach ($entity in @($RemovedEntities)) {
        $beforeParts = New-Object System.Collections.ArrayList
        $afterParts = New-Object System.Collections.ArrayList
        foreach ($row in @(Get-WastelandAnimalWeightRows -GameRoot $GameRoot | Where-Object { $_.Entity -eq $entity })) {
            $beforeValue = if ($BeforeValuesByXPath.ContainsKey($row.XPath)) { $BeforeValuesByXPath[$row.XPath] } else { "not present" }
            $afterValue = Format-TuningWeight $row.Base
            [void]$beforeParts.Add("$(Get-GroupShortName $row.Group) $beforeValue")
            [void]$afterParts.Add("$(Get-GroupShortName $row.Group) $afterValue")
        }
        [void]$lines.Add("")
        [void]$lines.Add("File: $entityGroupsPath")
        [void]$lines.Add("Setting: $(Get-AnimalDisplayName $entity) - Uninstall to game default")
        [void]$lines.Add("Before: $($beforeParts -join ', ')")
        [void]$lines.Add("After: $($afterParts -join ', ')")
    }

    [void]$lines.Add("")
    [void]$lines.Add((Get-ChoiceImpactText))
    [void]$lines.Add("This affects Wasteland open-world animal routes only.")

    return ($lines -join [Environment]::NewLine)
}

function Get-InstalledPatchValueMap {
    param([string]$TargetMod)

    $configPath = Join-Path $TargetMod "Config\entitygroups.xml"
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Installed mod is missing Config\entitygroups.xml."
    }

    [xml]$configXml = Get-Content -LiteralPath $configPath -Raw
    $values = @{}
    foreach ($setNode in @($configXml.SelectNodes("/configs/set"))) {
        $xpath = $setNode.GetAttribute("xpath")
        if (-not [string]::IsNullOrWhiteSpace($xpath)) {
            $values[$xpath] = $setNode.InnerText
        }
    }
    return $values
}

function Format-AnimalRowsForScan {
    param(
        [array]$Rows,
        [hashtable]$ValuesByXPath
    )

    $lines = New-Object System.Collections.ArrayList
    foreach ($entity in (Get-AnimalEntitiesFromRows -Rows $Rows)) {
        $parts = New-Object System.Collections.ArrayList
        foreach ($row in @($Rows | Where-Object { $_.Entity -eq $entity })) {
            $value = "missing"
            if ($ValuesByXPath.ContainsKey($row.XPath)) {
                $value = $ValuesByXPath[$row.XPath]
            }
            [void]$parts.Add("$(Get-GroupShortName $row.Group) $value")
        }

        [void]$lines.Add("- $(Get-AnimalDisplayName $entity): $($parts -join ', ')")
    }
    return @($lines)
}

function Add-BrutalScienceCapScanLines {
    param(
        [System.Collections.ArrayList]$Lines,
        [string]$GameRoot,
        [bool]$IncludeBrutalScienceCap
    )

    [void]$Lines.Add("")
    $currentCap = Get-MaxSpawnedAnimalsValue -GameRoot $GameRoot
    $latestBackup = Get-LatestBrutalScienceAnimalCapBackup -GameRoot $GameRoot
    $lastRecordedCap = $null
    [void]$Lines.Add("Animal spawn cap state:")
    [void]$Lines.Add("- File: $(Join-Path $GameRoot 'serverconfig.xml')")
    [void]$Lines.Add("- Setting: MaxSpawnedAnimals")
    [void]$Lines.Add("- Checkbox: $(if ($IncludeBrutalScienceCap) { 'Checked - raise cap' } else { 'Unchecked' })")
    [void]$Lines.Add("- Default: $script:DefaultAnimalCap")
    if ($null -ne $latestBackup) {
        $lastRecordedCap = Get-MaxSpawnedAnimalsValueFromFile -Path $latestBackup.FullName
        if ($null -ne $lastRecordedCap) {
            [void]$Lines.Add("- Last saved before change (newest backup): $lastRecordedCap")
        }
        else {
            [void]$Lines.Add("- Last saved before change: backup exists, but its value could not be read")
        }
    }
    else {
        [void]$Lines.Add("- Last saved before change: no Bit Wrecked backup yet")
    }
    if ($null -eq $currentCap) {
        [void]$Lines.Add("- Current now: could not be read")
    }
    else {
        [void]$Lines.Add("- Current now: $currentCap")
    }
    if ($IncludeBrutalScienceCap) {
        [void]$Lines.Add("- Selected result: raise to $script:BrutalScienceAnimalCap")
    }
    elseif ($null -ne $lastRecordedCap -and $null -ne $currentCap -and $lastRecordedCap -ne $currentCap) {
        [void]$Lines.Add("- Selected result: restore saved setting $lastRecordedCap")
    }
    elseif ($null -ne $currentCap) {
        [void]$Lines.Add("- Selected result: keep current setting $currentCap")
    }
    else {
        [void]$Lines.Add("- Selected result: no cap change selected; current value could not be read")
    }
}

function New-ScanValuesReport {
    param(
        [string]$GameRoot,
        [hashtable]$AnimalLevels,
        [bool]$IncludeBrutalScienceCap = $false
    )

    if (-not (Test-GameRoot $GameRoot)) {
        throw "That folder does not look like the 7 Days to Die game folder."
    }

    $sourceRows = Get-WastelandAnimalWeightRows -GameRoot $GameRoot
    $hasInstallTarget = ($null -ne $AnimalLevels -and $AnimalLevels.Count -gt 0)
    if (-not (Test-ModInstalled $GameRoot)) {
        $baseMap = @{}
        foreach ($row in $sourceRows) {
            $baseMap[$row.XPath] = (Format-TuningWeight $row.Base)
        }
        $targetRows = Get-TunedEntityGroupRows -GameRoot $GameRoot -AnimalLevels $AnimalLevels
        $targetMap = @{}
        foreach ($row in $targetRows) {
            $targetMap[$row.XPath] = $row.Value
        }

        $lines = New-Object System.Collections.ArrayList
        [void]$lines.Add("Not installed.")
        if (-not $hasInstallTarget) {
            [void]$lines.Add("No changes selected.")
        }
        else {
            [void]$lines.Add("Preview.")
        }
        [void]$lines.Add("")
        [void]$lines.Add("Current values:")
        foreach ($line in (Format-AnimalRowsForScan -Rows $sourceRows -ValuesByXPath $baseMap)) {
            [void]$lines.Add($line)
        }

        if ($hasInstallTarget) {
            [void]$lines.Add("")
            [void]$lines.Add("Result:")
            foreach ($line in (Format-AnimalRowsForScan -Rows $targetRows -ValuesByXPath $targetMap)) {
                [void]$lines.Add($line)
            }
        }

        Add-BrutalScienceCapScanLines -Lines $lines -GameRoot $GameRoot -IncludeBrutalScienceCap $IncludeBrutalScienceCap
        Add-GameplayAssessmentLines -Lines $lines -AnimalLevels $AnimalLevels -CapSelected $IncludeBrutalScienceCap -GameRoot $GameRoot

        return @{
            State = "Missing"
            Title = "Validated: Not Installed"
            Text = ($lines -join [Environment]::NewLine)
        }
    }

    $targetMod = Get-TargetModPath $GameRoot
    $installedMap = Get-InstalledPatchValueMap -TargetMod $targetMod

    if (-not $hasInstallTarget) {
        $installedRows = @($sourceRows | Where-Object { $installedMap.ContainsKey($_.XPath) })
        $lines = New-Object System.Collections.ArrayList
        [void]$lines.Add("Installed.")
        [void]$lines.Add("No changes selected.")
        [void]$lines.Add("")
        [void]$lines.Add("Installed XML rows:")
        if ($installedRows.Count -gt 0) {
            foreach ($line in (Format-AnimalRowsForScan -Rows $installedRows -ValuesByXPath $installedMap)) {
                [void]$lines.Add($line)
            }
        }
        else {
            [void]$lines.Add("- none")
        }
        Add-BrutalScienceCapScanLines -Lines $lines -GameRoot $GameRoot -IncludeBrutalScienceCap $IncludeBrutalScienceCap
        Add-GameplayAssessmentLines -Lines $lines -AnimalLevels $AnimalLevels -CapSelected $IncludeBrutalScienceCap -GameRoot $GameRoot

        return @{
            State = "Current"
            Title = "Validated: Installed"
            Text = ($lines -join [Environment]::NewLine)
        }
    }

    $expectedRows = Get-TunedEntityGroupRows -GameRoot $GameRoot -AnimalLevels $AnimalLevels
    $expectedMap = @{}
    foreach ($row in $expectedRows) {
        $expectedMap[$row.XPath] = $row.Value
    }

    $differences = New-Object System.Collections.ArrayList
    foreach ($row in $expectedRows) {
        if (-not $installedMap.ContainsKey($row.XPath)) {
            [void]$differences.Add("missing $($row.XPath), expected $($row.Value)")
        }
        elseif ($installedMap[$row.XPath] -ne $row.Value) {
            [void]$differences.Add("$($row.XPath): installed $($installedMap[$row.XPath]), install target $($row.Value)")
        }
    }
    foreach ($xpath in $installedMap.Keys) {
        if (-not $expectedMap.ContainsKey($xpath)) {
            [void]$differences.Add("extra installed row $xpath = $($installedMap[$xpath])")
        }
    }

    $isCurrent = ($differences.Count -eq 0)
    $lines = New-Object System.Collections.ArrayList
    if ($isCurrent) {
        [void]$lines.Add("Up to date.")
    }
    else {
        [void]$lines.Add("Update available.")
    }

    [void]$lines.Add("")
    [void]$lines.Add("Installed:")
    foreach ($line in (Format-AnimalRowsForScan -Rows $expectedRows -ValuesByXPath $installedMap)) {
        [void]$lines.Add($line)
    }

    [void]$lines.Add("")
    [void]$lines.Add("Install:")
    foreach ($line in (Format-AnimalRowsForScan -Rows $expectedRows -ValuesByXPath $expectedMap)) {
        [void]$lines.Add($line)
    }

    if ($isCurrent) {
        [void]$lines.Add("")
        [void]$lines.Add("No action needed.")
    }

    [void]$lines.Add("")
    [void]$lines.Add((Get-ChoiceImpactText))
    Add-BrutalScienceCapScanLines -Lines $lines -GameRoot $GameRoot -IncludeBrutalScienceCap $IncludeBrutalScienceCap
    Add-GameplayAssessmentLines -Lines $lines -AnimalLevels $AnimalLevels -CapSelected $IncludeBrutalScienceCap -GameRoot $GameRoot

    return @{
        State = $(if ($isCurrent) { "Current" } else { "Drift" })
        Title = $(if ($isCurrent) { "Validated: Up To Date" } else { "Validated: Update Available" })
        Text = ($lines -join [Environment]::NewLine)
    }
}

function Update-TuningLabels {
    try {
        $script:IsUpdatingTuning = $true
        $masterLocked = [bool]$masterCheck.Checked
        $masterTrack.Enabled = $masterLocked

        if ($masterLocked) {
            $masterValue.Text = Get-TuningLevelName ([int]$script:MasterLevel)
            $masterPreview.Text = "locked"
        }
        else {
            $masterValue.Text = "Custom"
            $masterPreview.Text = "per animal"
        }

        Update-AllAnimalRowControls
        $choiceImpact.Text = Get-ChoiceImpactText
    }
    catch {
        $masterValue.Text = "XML"
        $choiceImpact.Text = "Could not read Wasteland animal XML rows."
    }
    finally {
        $script:IsUpdatingTuning = $false
    }
}

function Set-PrimaryActionActive {
    param([string]$Text)

    $script:IsPrimaryActionActive = $true
    $installButton.Text = $Text
    $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $installButton.Enabled = $true
    $installButton.BackColor = New-Color 238 240 237
    $installButton.ForeColor = New-Color 42 91 55
    $installButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $installButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $installButton.Padding = New-Object System.Windows.Forms.Padding(0)
    $installButton.Tag.RwpBorderColor = New-Color 83 158 98
    $installButton.Invalidate()
    if ($Text -eq "Apply Limit Cap Only") {
        $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        Set-AnimatedToolTip -Control $installButton -Text "Apply only the selected Brutal Science global animal limit. This does not install or change the Wasteland XML mod when no animals are selected."
    }
    elseif ($Text -eq "Restore Global Limit Only") {
        $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        Set-AnimatedToolTip -Control $installButton -Text "Restore the saved previous global animal limit without installing or changing Wasteland XML mod files."
    }
    elseif ($Text -like "Uninstall Mod -*" ) {
        $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 6, [System.Drawing.FontStyle]::Bold)
        Set-AnimatedToolTip -Control $installButton -Text "Remove the installed animals named in the centered summary above. If no tuned animals remain, the empty mod folder is removed."
    }
    elseif ($Text -like "Uninstall Mod -*") {
        $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        Set-AnimatedToolTip -Control $installButton -Text "Remove the installed tuning identified in the animal table. If no tuned animals remain, the empty mod folder is removed."
    }
    else {
        $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        Set-AnimatedToolTip -Control $installButton -Text "Apply the selected animal settings. Install creates the mod folder; Reinstall updates the existing installed mod."
    }
    $actionDot.Visible = $false
    $actionDot.Enabled = $true
    $actionDot.ForeColor = New-Color 158 45 34
    $actionDot.BackColor = [System.Drawing.Color]::White
    $actionDot.Cursor = [System.Windows.Forms.Cursors]::Hand
    $actionDot.Text = [char]0x2191
    $actionDot.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    Set-AnimatedToolTip -Control $actionDot -Text "Apply the selected animal settings."
}

function Set-PrimaryActionQuiet {
    param([string]$Text)

    $script:IsPrimaryActionActive = $false
    $installButton.Text = $Text
    $installButton.Enabled = $false
    $installButton.BackColor = New-Color 224 224 219
    $installButton.ForeColor = New-Color 125 125 120
    $installButton.Cursor = [System.Windows.Forms.Cursors]::Default
    $installButton.Tag.RwpBorderColor = New-Color 208 208 202
    $installButton.Invalidate()
    $actionDot.Enabled = $false
    $actionDot.ForeColor = New-Color 156 156 150
    $actionDot.BackColor = New-Color 238 238 235
    $actionDot.Cursor = [System.Windows.Forms.Cursors]::Default
    if ($Text -like "Check any Box Above*") {
        $installButton.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9, [System.Drawing.FontStyle]::Bold)
        $installButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $installButton.Padding = New-Object System.Windows.Forms.Padding(20, 0, 44, 0)
        $actionDot.Visible = $true
        $actionDot.Enabled = $true
        $actionDot.ForeColor = New-Color 158 45 34
        $actionDot.BackColor = [System.Drawing.Color]::White
        $actionDot.Text = [System.Char]::ConvertFromUtf32(0x1F644)
        $actionDot.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 26)
        Set-AnimatedToolTip -Control $installButton -Text "Choose one or more animals above before installing. Selecting animals alone does not write files."
        Set-AnimatedToolTip -Control $actionDot -Text "Choose one or more animals above before installing."
    }
    else {
        $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $installButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $installButton.Padding = New-Object System.Windows.Forms.Padding(0)
        $actionDot.Visible = $false
        $actionDot.Text = [char]0x2191
        $actionDot.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
        Set-AnimatedToolTip -Control $installButton -Text "Choose a valid 7 Days to Die game folder first."
        Set-AnimatedToolTip -Control $actionDot -Text "Choose a valid 7 Days to Die game folder first."
    }
}

function Update-PrimaryActionState {
    param([string]$GameRoot)

    if (-not (Test-GameRoot $GameRoot)) {
        Set-PrimaryActionQuiet -Text "Install"
        return
    }

    $effectiveLevels = Get-EffectiveAnimalLevels
    $pendingAnimalRemovals = @(Get-PendingAnimalRemovals -SelectedLevels $effectiveLevels)
    if ($effectiveLevels.Count -lt 1) {
        if ($capCheck.Checked) {
            Set-PrimaryActionActive -Text "Apply Limit Cap Only"
            return
        }
        if ($pendingAnimalRemovals.Count -eq 1) {
            Set-PrimaryActionActive -Text "Uninstall Mod - $(Get-AnimalDisplayName $pendingAnimalRemovals[0])"
            return
        }
        if ($pendingAnimalRemovals.Count -gt 1) {
            $pendingRemovalNames = @($pendingAnimalRemovals | ForEach-Object { Get-AnimalDisplayName $_ }) -join ", "
            Set-PrimaryActionActive -Text "Uninstall Mod -`n$pendingRemovalNames"
            return
        }
        if ($null -ne (Get-PendingGlobalLimitRestore -GameRoot $GameRoot)) {
            Set-PrimaryActionActive -Text "Restore Global Limit Only"
            return
        }
        Set-PrimaryActionQuiet -Text "Check any Box Above`nto Install Here.."
        return
    }

    if (Test-ModInstalled $GameRoot) {
        Set-PrimaryActionActive -Text "Reinstall"
    }
    else {
        Set-PrimaryActionActive -Text "Install"
    }
}

function Update-InstallState {
    Refresh-AnimalChoices
    Update-TuningLabels

    $gameRoot = $pathBox.Text
    if (-not (Test-GameRoot $gameRoot)) {
        $stateAccent.BackColor = New-Color 156 156 150
        $stateValue.ForeColor = New-Color 82 82 78
        $stateValue.Text = "No folder"
        Set-PrimaryActionQuiet -Text "Install"
        $removeButton.Enabled = $false
        $openFolderButton.Enabled = $false
        $scanButton.Enabled = $false
        $restoreCapButton.Enabled = $false
        return
    }

    $openFolderButton.Enabled = $true
    $scanButton.Enabled = $true
    $restoreCapButton.Enabled = (@(Get-BrutalScienceAnimalCapBackups -GameRoot $gameRoot).Count -gt 0)

    if (Test-ModInstalled $gameRoot) {
        $stateAccent.BackColor = New-Color 42 128 76
        $stateValue.ForeColor = New-Color 32 98 58
        $stateValue.Text = "Installed"
        $removeButton.Enabled = $true
    }
    else {
        $stateAccent.BackColor = New-Color 158 45 34
        $stateValue.ForeColor = New-Color 130 45 35
        $stateValue.Text = "Not installed"
        $removeButton.Enabled = $false
    }
    Update-PrimaryActionState -GameRoot $gameRoot
}

$installButton.Add_Click({
    try {
        $effectiveLevels = Get-EffectiveAnimalLevels
        $hasAnimalChanges = ($effectiveLevels.Count -gt 0)
        $pendingAnimalRemovals = @(Get-PendingAnimalRemovals -SelectedLevels $effectiveLevels)
        $pendingRestore = if (-not $capCheck.Checked) { Get-PendingGlobalLimitRestore -GameRoot $pathBox.Text } else { $null }
        if (-not $hasAnimalChanges -and $pendingAnimalRemovals.Count -gt 0) {
            $removalNames = @($pendingAnimalRemovals | ForEach-Object { Get-AnimalDisplayName $_ })
            $removalLabel = if ($removalNames.Count -eq 1) { $removalNames[0] } else { $removalNames -join ", " }
            $restoreLine = if ($null -ne $pendingRestore) { "`nThe global animal limit will also restore: $($pendingRestore.CurrentValue) -> $($pendingRestore.SavedValue)." } else { "" }
            $choice = [System.Windows.Forms.MessageBox]::Show(
                "Uninstall mod tuning for: $removalLabel.$restoreLine`n`nEach unchecked installed animal returns to its game-default values. Because no animals remain selected, the generated Wasteland mod XML and its mod folder will be removed, returning the game's effective XML configuration to defaults.",
                "Confirm Animal Tuning Removal",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
                Set-Status $status "Animal tuning removal cancelled." (New-Color 82 82 78)
                return
            }
            $removedConfigPath = Join-Path $pathBox.Text "Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning\Config\entitygroups.xml"
            $removedBeforeValues = if (Test-Path -LiteralPath $removedConfigPath -PathType Leaf) {
                Get-InstalledPatchValueMap -TargetMod (Get-TargetModPath $pathBox.Text)
            }
            else { @{} }
            $removedTarget = Uninstall-Mod -GameRoot $pathBox.Text
            if ($null -ne $pendingRestore) {
                $restoreResult = Restore-BrutalScienceAnimalCapBackup -GameRoot $pathBox.Text
                Set-Status $status "Uninstalled animal tuning and restored global limit to $($restoreResult.NewValue)." ([System.Drawing.Color]::DarkGreen)
            }
            else {
                Set-Status $status "Uninstalled tuning and returned to defaults: $removalLabel." ([System.Drawing.Color]::DarkGreen)
            }
            $removalLines = New-Object System.Collections.ArrayList
            [void]$removalLines.Add("Animal checkbox changes:")
            foreach ($entity in $pendingAnimalRemovals) {
                $beforeParts = New-Object System.Collections.ArrayList
                $afterParts = New-Object System.Collections.ArrayList
                foreach ($row in @(Get-WastelandAnimalWeightRows -GameRoot $pathBox.Text | Where-Object { $_.Entity -eq $entity })) {
                    $beforeValue = if ($removedBeforeValues.ContainsKey($row.XPath)) { $removedBeforeValues[$row.XPath] } else { "not present" }
                    [void]$beforeParts.Add("$(Get-GroupShortName $row.Group) $beforeValue")
                    [void]$afterParts.Add("$(Get-GroupShortName $row.Group) $(Format-TuningWeight $row.Base)")
                }
                [void]$removalLines.Add("")
                [void]$removalLines.Add("File: $removedConfigPath")
                [void]$removalLines.Add("Setting: $(Get-AnimalDisplayName $entity) - Uninstall to game default")
                [void]$removalLines.Add("Before: $($beforeParts -join ', ')")
                [void]$removalLines.Add("After: $($afterParts -join ', ')")
            }
            [void]$removalLines.Add("")
            [void]$removalLines.Add("File action: the generated mod folder was deleted; these effective values now come from the game's default XML.")
            $removalReport = $removalLines -join [Environment]::NewLine
            Add-ChangeReportToActivityLog -ReportText $removalReport
            [void][System.Windows.Forms.MessageBox]::Show(
                $removalReport,
                "Animal Tuning Uninstalled",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            Update-InstallState
            return
        }
        if (-not $hasAnimalChanges -and $null -ne $pendingRestore) {
            Set-Status $status "Starting standalone global animal-limit restore." (New-Color 82 82 78)
            $choice = [System.Windows.Forms.MessageBox]::Show(
                "Restore the previous global animal limit?`n`nGame default: $script:DefaultAnimalCap`nCurrent setting: $($pendingRestore.CurrentValue)`nSaved previous setting: $($pendingRestore.SavedValue)`n`nThis will replace serverconfig.xml with the newest matching backup. It will not write the separate Wasteland modlet XML.",
                "Restore Global Animal Limit",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
                Set-Status $status "Global animal-limit restore cancelled." (New-Color 82 82 78)
                return
            }
            $restoreResult = Restore-BrutalScienceAnimalCapBackup -GameRoot $pathBox.Text
            Set-Status $status "Restored global animal limit: $($restoreResult.PreviousValue) -> $($restoreResult.NewValue)." ([System.Drawing.Color]::DarkGreen)
            $restoreReport = "Global animal limit restored.`n`nFile: $(Join-Path $pathBox.Text 'serverconfig.xml')`nSetting: MaxSpawnedAnimals`nBefore: $($restoreResult.PreviousValue)`nAfter: $($restoreResult.NewValue)`nGame default: $script:DefaultAnimalCap`n`nFile action: serverconfig.xml was replaced with the newest matching backup.`nThe separate Wasteland modlet XML was not written by this action."
            Add-ChangeReportToActivityLog -ReportText $restoreReport
            [void][System.Windows.Forms.MessageBox]::Show(
                $restoreReport,
                "Global Animal Limit Restored",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            Update-InstallState
            return
        }
        if (-not $hasAnimalChanges -and -not $capCheck.Checked) {
            Set-Status $status "Pick at least one animal." (New-Color 180 90 24)
            return
        }

        if (-not $hasAnimalChanges) {
            Set-Status $status "Starting standalone global animal-limit action." (New-Color 82 82 78)
        }
        elseif ($capCheck.Checked) {
            Set-Status $status "Starting Wasteland XML install with global animal-limit action." (New-Color 82 82 78)
        }
        else {
            Set-Status $status "Starting Wasteland animal XML install." (New-Color 82 82 78)
        }

        $settingCombination = New-SettingCombinationConfirmation -AnimalLevels $effectiveLevels -IncludeBrutalScience ([bool]$capCheck.Checked)
        if ($pendingAnimalRemovals.Count -gt 0) {
            $removedNames = @($pendingAnimalRemovals | ForEach-Object { Get-AnimalDisplayName $_ }) -join ", "
            $settingCombination.Summary = "$($settingCombination.Summary)`nUninstall to game defaults: $removedNames"
            $settingCombination.LogSummary = "$($settingCombination.LogSummary); uninstall to game defaults: $removedNames"
            $settingCombination.Key = "$($settingCombination.Key)|remove=$($pendingAnimalRemovals -join ';')"
        }
        Add-SettingCombinationToActivityLog -Combination $settingCombination

        $capResult = $null
        if ($capCheck.Checked) {
            $currentCap = Get-MaxSpawnedAnimalsValue -GameRoot $pathBox.Text
            $choice = [System.Windows.Forms.MessageBox]::Show(
                "Confirm these settings:`n$($settingCombination.Summary)`n`n$($settingCombination.Humor)`n`nBrutal Science changes the global animal limit for the whole game/server - not only the Wasteland.`n`nNormal game default: $script:DefaultAnimalCap`nYour current global setting: $currentCap`nStress-test global setting: $script:BrutalScienceAnimalCap`n`nThe tool will make a timestamped serverconfig.xml backup before changing the value. This can produce extreme animal pressure and may stress hardware, servers, or saves.`n`nContinue?",
                "Brutal Science Animal Cap",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
                Set-Status $status "Install cancelled before changing the animal cap." (New-Color 82 82 78)
                return
            }
        }
        else {
            $choice = [System.Windows.Forms.MessageBox]::Show(
                "Confirm these settings:`n$($settingCombination.Summary)`n`n$($settingCombination.Humor)`n`nContinue with Install / Reinstall?",
                "Confirm Wasteland Animal Settings",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
                Set-Status $status "Install cancelled after reviewing the setting combination." (New-Color 82 82 78)
                return
            }
        }

        if (-not $hasAnimalChanges) {
            $capResult = Set-BrutalScienceAnimalCap -GameRoot $pathBox.Text
            $capAction = if ([bool]$capResult.Changed) {
                "Changed the global animal limit from $($capResult.PreviousValue) to $($capResult.NewValue)."
            }
            else {
                "The global animal limit is already $($capResult.NewValue); no server setting changed."
            }
            $capFileAction = if ([bool]$capResult.Changed) {
                "serverconfig.xml was backed up and then modified."
            }
            else {
                "serverconfig.xml already contained that value and was not rewritten."
            }
            Set-Status $status "Global animal limit verified: $($capResult.NewValue)." ([System.Drawing.Color]::DarkGreen)
            $capReport = "$capAction`n`nFile: $(Join-Path $pathBox.Text 'serverconfig.xml')`nSetting: MaxSpawnedAnimals`nBefore: $($capResult.PreviousValue)`nAfter: $($capResult.NewValue)`nGame default: $script:DefaultAnimalCap`nScope: global game/server limit across all biomes.`n`nFile action: $capFileAction`nThe separate Wasteland modlet XML was not written by this cap-only action."
            Add-ChangeReportToActivityLog -ReportText $capReport
            [void][System.Windows.Forms.MessageBox]::Show(
                $capReport,
                "Global Animal Limit Applied",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            Update-InstallState
            return
        }

        $densityLevel = Get-DensityLevelFromAnimalLevels -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels
        $beforeAnimalValues = @{}
        $existingAnimalConfig = Join-Path $pathBox.Text "Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning\Config\entitygroups.xml"
        if (Test-Path -LiteralPath $existingAnimalConfig -PathType Leaf) {
            $beforeAnimalValues = Get-InstalledPatchValueMap -TargetMod (Get-TargetModPath $pathBox.Text)
        }
        $target = Install-Mod -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels
        $verifiedRows = Test-InstalledAnimalConfig -TargetMod $target -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels
        Test-InstalledSpawningConfig -TargetMod $target -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels | Out-Null
        if ($capCheck.Checked) {
            $capResult = Set-BrutalScienceAnimalCap -GameRoot $pathBox.Text
        }
        $feedbackText = New-InstallFeedbackText -VerifiedRows $verifiedRows -AnimalLevels $effectiveLevels -GameRoot $pathBox.Text -DensityLevel $densityLevel -BeforeValuesByXPath $beforeAnimalValues -RemovedEntities $pendingAnimalRemovals -CapResult $capResult
        Add-ChangeReportToActivityLog -ReportText $feedbackText

        if ($null -ne $capResult) {
            Set-Status $status "Installed XML and verified animal cap." ([System.Drawing.Color]::DarkGreen)
        }
        else {
            Set-Status $status "Installed and verified XML." ([System.Drawing.Color]::DarkGreen)
        }
        [void][System.Windows.Forms.MessageBox]::Show(
            $feedbackText,
            "Installed",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        Update-InstallState
    }
    catch {
        Set-Status $status "Install failed: $($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
    }
})

$actionDot.Add_Click({
    if ($installButton.Enabled) {
        $installButton.PerformClick()
    }
})

$scanButton.Add_Click({
    try {
        Set-Status $status "Reading current game settings for validation." (New-Color 82 82 78)
        $effectiveLevels = Get-EffectiveAnimalLevels
        $scanReport = New-ScanValuesReport -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels -IncludeBrutalScienceCap ([bool]$capCheck.Checked)
        Add-ValidationReportToActivityLog -ReportText $scanReport.Text

        if ($scanReport.State -eq "Current") {
            Set-Status $status "Validation complete: XML is current." ([System.Drawing.Color]::DarkGreen)
        }
        elseif ($scanReport.State -eq "Missing") {
            Set-Status $status "Validation complete: not installed." ([System.Drawing.Color]::DarkOrange)
        }
        else {
            Set-Status $status "Validation complete: XML differs from choices." ([System.Drawing.Color]::DarkOrange)
        }

        Show-ReadOnlyReportDialog -Owner $form -Title $scanReport.Title -Text $scanReport.Text
    }
    catch {
        Set-Status $status "Validation failed: $($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
    }
})

$changeLogLink.Add_LinkClicked({
    Set-Status $status "Opened Version $script:PackageVersion highlights." (New-Color 82 82 78)
    Show-VersionHighlightsDialog -Owner $form
})

$removeButton.Add_Click({
    try {
        Set-Status $status "Remove Mod requested." (New-Color 82 82 78)
        if (Test-ModInstalled $pathBox.Text) {
            $choice = [System.Windows.Forms.MessageBox]::Show(
                "Remove 7DTD 3.0 Wasteland Animal Population Tuning from Mods?",
                "Remove Mod",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
                Set-Status $status "Remove cancelled." (New-Color 82 82 78)
                return
            }
        }

        $target = Uninstall-Mod -GameRoot $pathBox.Text
        if ($target) {
            Set-Status $status "Removed: $target" ([System.Drawing.Color]::DarkGreen)
        }
        else {
            Set-Status $status "Mod was not installed in that game folder." ([System.Drawing.Color]::DarkOrange)
        }
        Update-InstallState
    }
    catch {
        Set-Status $status "Remove failed: $($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
    }
})

$restoreCapButton.Add_Click({
    try {
        Set-Status $status "Restore Previous Global Limit requested." (New-Color 82 82 78)
        $backup = Get-LatestBrutalScienceAnimalCapBackup -GameRoot $pathBox.Text
        if ($null -eq $backup) {
            Set-Status $status "No Bit Wrecked animal-cap backup was found." ([System.Drawing.Color]::DarkOrange)
            Update-InstallState
            return
        }

        $backupValue = Get-MaxSpawnedAnimalsValueFromFile -Path $backup.FullName
        $currentValue = Get-MaxSpawnedAnimalsValue -GameRoot $pathBox.Text
        $choice = [System.Windows.Forms.MessageBox]::Show(
            "Restore the global animal limit for the whole game/server from the newest Bit Wrecked backup?`n`nNormal game default: $script:DefaultAnimalCap`nCurrent global setting: $currentValue`nSaved global setting: $backupValue`n`nRestore uses the saved value, which may differ from the game default. This is not Wasteland-only.`n`nBackup:`n$($backup.Name)",
            "Restore Animal Cap",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
            Set-Status $status "Animal cap restore cancelled." (New-Color 82 82 78)
            return
        }

        $result = Restore-BrutalScienceAnimalCapBackup -GameRoot $pathBox.Text
        Set-Status $status "Restored animal cap: $($result.PreviousValue) -> $($result.NewValue)." ([System.Drawing.Color]::DarkGreen)
        [void][System.Windows.Forms.MessageBox]::Show(
            "Restored serverconfig.xml from the newest Bit Wrecked backup.`n`nMaxSpawnedAnimals: $($result.PreviousValue) -> $($result.NewValue)`n`nBackup used:`n$($result.BackupPath)",
            "Animal Cap Restored",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        Update-InstallState
    }
    catch {
        Set-Status $status "Animal cap restore failed: $($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
    }
})

$openFolderButton.Add_Click({
    try {
        Set-Status $status "Opening the selected game's Mods folder." (New-Color 82 82 78)
        if (-not (Test-GameRoot $pathBox.Text)) {
            throw "That folder does not look like the 7 Days to Die game folder."
        }
        $modsRoot = Join-Path $pathBox.Text "Mods"
        New-Item -ItemType Directory -Force -Path $modsRoot | Out-Null
        Start-Process explorer.exe $modsRoot
        Set-Status $status "Opened Mods folder." ([System.Drawing.Color]::DarkGreen)
        Update-InstallState
    }
    catch {
        Set-Status $status "Could not open Mods folder: $($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
    }
})

$pathBox.Add_TextChanged({
    Update-InstallState
})

$masterCheck.Add_CheckedChanged({
    if (-not $script:IsUpdatingTuning) {
        Set-MasterLock -Locked ([bool]$masterCheck.Checked)
        Update-TuningLabels
        Update-PrimaryActionState -GameRoot $pathBox.Text
        $masterState = if ($masterCheck.Checked) { "selected" } else { "cleared" }
        Set-Status $status "All checkbox $masterState." (New-Color 82 82 78)
    }
})

$masterTrack.Add_Scroll({
    if (-not $script:IsUpdatingTuning) {
        Set-MasterLevel -Level (Get-LevelFromSliderValue ([int]$masterTrack.Value))
        Update-TuningLabels
        Update-PrimaryActionState -GameRoot $pathBox.Text
    }
})
$masterTrack.Add_MouseUp({
    $level = Get-LevelFromSliderValue ([int]$masterTrack.Value)
    Set-Status $status "All level selected: $(Get-TuningLevelName $level)." (New-Color 82 82 78)
})

$capCheck.Add_CheckedChanged({
    if (-not $script:IsUpdatingTuning) {
        Update-TuningLabels
        Update-PrimaryActionState -GameRoot $pathBox.Text
        if ($capCheck.Checked) {
            $currentCap = Get-MaxSpawnedAnimalsValue -GameRoot $pathBox.Text
            Set-Status $status "Brutal Science selected: global limit $currentCap -> $script:BrutalScienceAnimalCap (default $script:DefaultAnimalCap)." (New-Color 130 45 35)
        }
        else {
            Set-Status $status "Brutal Science selection cleared; no global setting was restored." (New-Color 82 82 78)
        }
    }
})

$closeButton.Add_Click({
    $form.Close()
})

Refresh-AnimalChoices
Update-TuningLabels
Update-InstallState

if ($ReplySimulation) {
    $simulationCases = @(
        @{ Name = "Focused sparse"; Levels = @{ animalDireWolf = 1 }; Cap = $false },
        @{ Name = "Grouped default"; Levels = @{ animalDireWolf = 2; animalSnake = 2; animalZombieBear = 2 }; Cap = $false },
        @{ Name = "Mixed extremes"; Levels = @{ animalDireWolf = 0; animalSnake = 4; animalZombieBear = 3 }; Cap = $false },
        @{ Name = "Brutal only"; Levels = @{}; Cap = $true },
        @{ Name = "Absurd plus Brutal"; Levels = @{ animalDireWolf = 4; animalSnake = 4; animalZombieBear = 4; animalZombieDog = 4; animalZombieVulture = 4 }; Cap = $true }
    )
    foreach ($simulationCase in $simulationCases) {
        $toneCounts = [ordered]@{ POSITIVE = 0; NEGATIVE = 0; NEUTRAL = 0; SURPRISED = 0 }
        $samples = New-Object System.Collections.ArrayList
        1..500 | ForEach-Object {
            $sample = New-SettingCombinationConfirmation -AnimalLevels $simulationCase.Levels -IncludeBrutalScience ([bool]$simulationCase.Cap)
            $toneCounts[$sample.Tone]++
            if ($samples.Count -lt 2) {
                [void]$samples.Add("$($sample.Tone) | $($sample.Humor)")
            }
        }
        $distribution = @($toneCounts.Keys | ForEach-Object { "$_=$($toneCounts[$_])" }) -join ", "
        Write-Output "$($simulationCase.Name) | DISTRIBUTION (n=500) | $distribution"
        foreach ($sampleText in $samples) {
            Write-Output "$($simulationCase.Name) | SAMPLE | $sampleText"
        }
    }
    $form.Dispose()
    return
}

$smokeTimer = $null
if ($SmokeTest) {
    $form.Add_Shown({
        $startupRemovalCheck = @(Get-PendingAnimalRemovals -SelectedLevels (Get-EffectiveAnimalLevels))
        if ($startupRemovalCheck.Count -eq 1) {
            $expectedRemovalText = "Uninstall Mod - $(Get-AnimalDisplayName $startupRemovalCheck[0])"
            if ($installButton.Text -ne $expectedRemovalText) {
                throw "Smoke test expected complete single-animal removal text: $expectedRemovalText"
            }
        }
        elseif ($startupRemovalCheck.Count -gt 1) {
            if ($installButton.Text -notlike "Uninstall Mod -*" -or [Math]::Abs($installButton.Font.Size - 6) -gt 0.1) {
                throw "Smoke test expected the 6-point multiple-animal removal action."
            }
            foreach ($pendingEntity in $startupRemovalCheck) {
                if ($installButton.Text -notmatch [regex]::Escape((Get-AnimalDisplayName $pendingEntity))) {
                    throw "Smoke test expected every pending animal directly on the removal button."
                }
            }
        }
        if ($persistentLogCheck.Checked -or $script:PersistentLogEnabled -or -not [string]::IsNullOrWhiteSpace($script:PersistentLogPath)) {
            throw "Smoke test expected the Activity Log to start runtime-only without a file path."
        }
        if ($persistentLogPathLabel.Text -notmatch "clears when this application restarts") {
            throw "Smoke test expected the runtime-only log warning."
        }
        if (-not $workspaceSplit.Panel2Collapsed -or $form.ClientSize.Width -ne 620) {
            throw "Smoke test expected the Activity Log to start collapsed."
        }
        $activityToggleButton.PerformClick()
        if ($workspaceSplit.Panel2Collapsed -or $form.ClientSize.Width -ne 930 -or $workspaceSplit.IsSplitterFixed) {
            throw "Smoke test could not expand the Activity Log."
        }
        $workspaceSplit.SplitterDistance = 610
        if ($workspaceSplit.SplitterDistance -ne 610) {
            throw "Smoke test could not pull-resize the Activity Log partition."
        }
        $activityToggleButton.PerformClick()
        if (-not $workspaceSplit.Panel2Collapsed -or $form.ClientSize.Width -ne 620) {
            throw "Smoke test could not collapse the Activity Log."
        }
        $toolTipSmokeText = "Smoke-test tooltip indexing entry."
        Add-ToolTipToActivityLog -Control $browseButton -Text $toolTipSmokeText
        $toolTipLogLength = $activityLog.TextLength
        Add-ToolTipToActivityLog -Control $browseButton -Text $toolTipSmokeText
        if ($activityLog.TextLength -ne $toolTipLogLength) {
            throw "Smoke test found a duplicate Activity Log tooltip entry."
        }
        Add-ValidationReportToActivityLog -ReportText "Smoke validation alpha`nSmoke validation beta"
        $validationLogLength = $activityLog.TextLength
        Add-ValidationReportToActivityLog -ReportText "Smoke validation alpha`nSmoke validation beta"
        if ($activityLog.TextLength -ne $validationLogLength) {
            throw "Smoke test found duplicate Activity Log validation lines."
        }
        Add-ValidationReportToActivityLog -ReportText "Smoke validation alpha`nSmoke validation gamma"
        if ($activityLog.TextLength -le $validationLogLength) {
            throw "Smoke test expected a new validation line to be indexed."
        }
        $singleCombo = New-SettingCombinationConfirmation -AnimalLevels @{ animalDireWolf = 2 } -IncludeBrutalScience $false
        Add-SettingCombinationToActivityLog -Combination $singleCombo
        $comboLogLength = $activityLog.TextLength
        if ($activityLog.Text -notmatch "CONFIRM \| Wasteland animals:" -or $activityLog.Text -notmatch "EASTER EGG \[(POSITIVE|NEGATIVE|NEUTRAL|SURPRISED)\] \|") {
            throw "Smoke test expected separate clean confirmation and generated Easter-egg lines."
        }
        Add-SettingCombinationToActivityLog -Combination $singleCombo
        if ($activityLog.TextLength -ne $comboLogLength) {
            throw "Smoke test found a duplicate setting-combination Easter egg."
        }
        $mixedCombo = New-SettingCombinationConfirmation -AnimalLevels @{ animalDireWolf = 2; animalSnake = 4 } -IncludeBrutalScience $false
        $brutalOnlyCombo = New-SettingCombinationConfirmation -AnimalLevels @{} -IncludeBrutalScience $true
        $combinedCombo = New-SettingCombinationConfirmation -AnimalLevels @{ animalDireWolf = 2 } -IncludeBrutalScience $true
        foreach ($combo in @($mixedCombo, $brutalOnlyCombo, $combinedCombo)) {
            if ([string]::IsNullOrWhiteSpace($combo.Summary) -or [string]::IsNullOrWhiteSpace($combo.Humor)) {
                throw "Smoke test expected a complete setting-combination confirmation."
            }
            Add-SettingCombinationToActivityLog -Combination $combo
        }
        $direWolfControls = $script:AnimalControls["animalDireWolf"]
        if ($null -ne $direWolfControls -and $direWolfControls.Base.AccessibleName -ne "Animal: Dire wolf | Column: Current") {
            throw "Smoke test found an incomplete animal tooltip route."
        }
        if ($masterCheck.Parent -ne $animalRowsPanel -or $masterCheck.Top -ge $direWolfControls.Check.Top) {
            throw "Smoke test expected All as the first table row above Dire wolf."
        }
        if ($choiceImpact.Visible) {
            throw "Smoke test expected the redundant centered selection summary to remain hidden."
        }
        if ([Math]::Abs(($scanButton.Left + ($scanButton.Width / 2)) - ($tuningPanel.ClientSize.Width / 2)) -gt 1) {
            throw "Smoke test expected the validation button to be horizontally centered."
        }
        # Exercise the standalone active global-limit path and the no-selection
        # prompt without writing any files.
        $capCheck.Checked = $true
        if ($installButton.Text -ne "Apply Limit Cap Only") {
            throw "Smoke test expected standalone Apply Limit Cap Only state."
        }
        if ([Math]::Abs($installButton.Font.Size - 8) -gt 0.1) {
            throw "Smoke test expected the standalone global-limit label at 8-point."
        }
        $masterCheck.Checked = $true
        $masterCheck.Checked = $false
        $remainingAnimalSelections = @($script:AnimalEnabled.Values | Where-Object { [bool]$_ })
        if ($remainingAnimalSelections.Count -ne 0) {
            throw "Smoke test expected grouped deselection to clear every animal."
        }
        if (-not $capCheck.Checked) {
            throw "Smoke test expected grouped deselection to leave Brutal Science selected."
        }
        $capHistorySmokeLines = New-Object System.Collections.ArrayList
        Add-BrutalScienceCapScanLines -Lines $capHistorySmokeLines -GameRoot $pathBox.Text -IncludeBrutalScienceCap $true
        $capHistorySmokeText = $capHistorySmokeLines -join "`n"
        foreach ($requiredCapLabel in @("File:", "Setting: MaxSpawnedAnimals", "Checkbox:", "Default:", "Last saved before change", "Current now:", "Selected result:")) {
            if ($capHistorySmokeText -notmatch [regex]::Escape($requiredCapLabel)) {
                throw "Smoke test expected validation label: $requiredCapLabel"
            }
        }
        $gameplaySmokeLines = New-Object System.Collections.ArrayList
        Add-GameplayAssessmentLines -Lines $gameplaySmokeLines -AnimalLevels @{ animalDireWolf = 4; animalZombieBear = 4 } -CapSelected $true -GameRoot $pathBox.Text
        $gameplaySmokeText = $gameplaySmokeLines -join "`n"
        foreach ($requiredGameplayLabel in @("Generated gameplay assessment:", "Basis:", "Difficulty:", "Opinion:")) {
            if ($gameplaySmokeText -notmatch [regex]::Escape($requiredGameplayLabel)) {
                throw "Smoke test expected gameplay-assessment label: $requiredGameplayLabel"
            }
        }
        $form.Refresh()
        $capCheck.Checked = $false
        $mouseEnterMethod = [System.Windows.Forms.Control].GetMethod(
            "OnMouseEnter",
            [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
        )
        [void]$mouseEnterMethod.Invoke($browseButton, @([System.EventArgs]::Empty))
        foreach ($control in @($script:RoundedControls)) {
            if ($null -ne $control -and -not $control.IsDisposed) {
                $control.Invalidate()
                $control.Refresh()
            }
        }
        $form.Invalidate($true)
        $form.Refresh()
    })

    $smokeTimer = New-Object System.Windows.Forms.Timer
    $smokeTimer.Interval = 800
    $smokeTimer.Add_Tick({
        $smokeTimer.Stop()
        $form.Close()
    })
    $smokeTimer.Start()
}

try {
    [void]$form.ShowDialog()
}
finally {
    if ($null -ne $smokeTimer) {
        $smokeTimer.Dispose()
    }
}
