# 7DTD 3.0 Wasteland Animal Population Tuning - Windows GUI installer
# Copyright (C) 2026 Bit Wrecked
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This program is distributed without warranty. See LICENSE.txt for details.

param(
    [switch]$SmokeTest
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceMod = Join-Path $packageRoot "BitWrecked_7DTD_WastelandAnimalPopulationTuning"
$script:PackageVersion = "4.0.1"
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
    [void]$lines.Add("- Sparse tuning is less empty: animal weights are 0.5x and route delays are 1.75x.")
    [void]$lines.Add("- Dense and Absurd stay unchanged after field testing.")
    [void]$lines.Add("- Default now clearly writes the live vanilla Wasteland baseline values.")
    [void]$lines.Add("- Brutal Science wording now makes the global animal-cap risk clearer.")
    [void]$lines.Add("- Nexus-safe package path documented: XML modlet plus text docs, no scripts or executables.")
    [void]$lines.Add("")
    [void]$lines.Add("Full details are in CHANGELOG.md beside this tool.")
    return ($lines -join [Environment]::NewLine)
}

function Show-VersionHighlightsDialog {
    param([System.Windows.Forms.Form]$Owner)

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Version $script:PackageVersion Highlights"
    $dialog.ClientSize = New-Object System.Drawing.Size(470, 310)
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
    $body.Size = New-Object System.Drawing.Size(424, 188)
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
    $okButton.Location = New-Object System.Drawing.Point(348, 258)
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
$form.ClientSize = New-Object System.Drawing.Size(620, 730)
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

$pathShell = New-Object System.Windows.Forms.Panel
$pathShell.Location = New-Object System.Drawing.Point(27, 180)
$pathShell.Size = New-Object System.Drawing.Size(438, 34)
$pathShell.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($pathShell)
Enable-RoundedBorder $pathShell 16 (New-Color 208 208 202)

$pathBox = New-Object System.Windows.Forms.TextBox
$pathBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$pathBox.BackColor = [System.Drawing.Color]::White
$pathBox.Location = New-Object System.Drawing.Point(13, 9)
$pathBox.Size = New-Object System.Drawing.Size(410, 20)
$pathBox.Text = Get-DefaultGameRoot
$pathShell.Controls.Add($pathBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$browseButton.FlatAppearance.BorderSize = 0
$browseButton.BackColor = [System.Drawing.Color]::White
$browseButton.ForeColor = New-Color 38 38 36
$browseButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$browseButton.Location = New-Object System.Drawing.Point(478, 178)
$browseButton.Size = New-Object System.Drawing.Size(116, 36)
$browseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select your 7 Days to Die game folder"
    if (Test-Path -LiteralPath $pathBox.Text -PathType Container) {
        $dialog.SelectedPath = $pathBox.Text
    }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathBox.Text = $dialog.SelectedPath
        Update-InstallState
    }
})
$form.Controls.Add($browseButton)
Enable-RoundedBorder $browseButton 18 (New-Color 208 208 202)

$tuningPanel = New-Object System.Windows.Forms.Panel
$tuningPanel.Location = New-Object System.Drawing.Point(27, 230)
$tuningPanel.Size = New-Object System.Drawing.Size(567, 282)
$tuningPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($tuningPanel)
Enable-RoundedBorder $tuningPanel 16 (New-Color 226 224 218)

$tuningTitle = New-Object System.Windows.Forms.Label
$tuningTitle.Text = "Animals"
$tuningTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9, [System.Drawing.FontStyle]::Bold)
$tuningTitle.ForeColor = New-Color 38 38 36
$tuningTitle.AutoSize = $true
$tuningTitle.Location = New-Object System.Drawing.Point(14, 10)
$tuningPanel.Controls.Add($tuningTitle)

$masterCheck = New-Object System.Windows.Forms.CheckBox
$masterCheck.Text = "All"
$masterCheck.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$masterCheck.ForeColor = New-Color 38 38 36
$masterCheck.AutoSize = $false
$masterCheck.Location = New-Object System.Drawing.Point(18, 45)
$masterCheck.Size = New-Object System.Drawing.Size(118, 24)
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
$masterTrack.AutoSize = $true
$masterTrack.Location = New-Object System.Drawing.Point(148, 31)
$masterTrack.Size = New-Object System.Drawing.Size(108, 45)
$masterTrack.BackColor = [System.Drawing.Color]::White
$tuningPanel.Controls.Add($masterTrack)

$masterValue = New-Object System.Windows.Forms.Label
$masterValue.Text = "Custom"
$masterValue.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$masterValue.ForeColor = New-Color 82 82 78
$masterValue.Location = New-Object System.Drawing.Point(264, 46)
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
$animalHeader.Text = "Animal"
$animalHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$animalHeader.ForeColor = New-Color 110 110 105
$animalHeader.Location = New-Object System.Drawing.Point(52, 80)
$animalHeader.Size = New-Object System.Drawing.Size(84, 18)
$tuningPanel.Controls.Add($animalHeader)

$levelHeader = New-Object System.Windows.Forms.Label
$levelHeader.Text = "Level"
$levelHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$levelHeader.ForeColor = New-Color 110 110 105
$levelHeader.Location = New-Object System.Drawing.Point(176, 80)
$levelHeader.Size = New-Object System.Drawing.Size(70, 18)
$tuningPanel.Controls.Add($levelHeader)

$choiceHeader = New-Object System.Windows.Forms.Label
$choiceHeader.Text = "Action"
$choiceHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$choiceHeader.ForeColor = New-Color 110 110 105
$choiceHeader.Location = New-Object System.Drawing.Point(264, 80)
$choiceHeader.Size = New-Object System.Drawing.Size(82, 18)
$tuningPanel.Controls.Add($choiceHeader)

$gameHeader = New-Object System.Windows.Forms.Label
$gameHeader.Text = "Current"
$gameHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$gameHeader.ForeColor = New-Color 110 110 105
$gameHeader.Location = New-Object System.Drawing.Point(346, 80)
$gameHeader.Size = New-Object System.Drawing.Size(88, 18)
$tuningPanel.Controls.Add($gameHeader)

$selectedHeader = New-Object System.Windows.Forms.Label
$selectedHeader.Text = "Result"
$selectedHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$selectedHeader.ForeColor = New-Color 110 110 105
$selectedHeader.Location = New-Object System.Drawing.Point(450, 80)
$selectedHeader.Size = New-Object System.Drawing.Size(96, 18)
$tuningPanel.Controls.Add($selectedHeader)

$tuningHeaderRule = New-Object System.Windows.Forms.Panel
$tuningHeaderRule.Location = New-Object System.Drawing.Point(18, 100)
$tuningHeaderRule.Size = New-Object System.Drawing.Size(528, 1)
$tuningHeaderRule.BackColor = New-Color 236 234 229
$tuningPanel.Controls.Add($tuningHeaderRule)

$animalRowsPanel = New-Object System.Windows.Forms.Panel
$animalRowsPanel.Location = New-Object System.Drawing.Point(18, 108)
$animalRowsPanel.Size = New-Object System.Drawing.Size(540, 120)
$animalRowsPanel.BackColor = [System.Drawing.Color]::White
$tuningPanel.Controls.Add($animalRowsPanel)

$choiceImpact = New-Object System.Windows.Forms.Label
$choiceImpact.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$choiceImpact.ForeColor = New-Color 82 82 78
$choiceImpact.Location = New-Object System.Drawing.Point(18, 238)
$choiceImpact.Size = New-Object System.Drawing.Size(372, 34)
$choiceImpact.Visible = $true
$tuningPanel.Controls.Add($choiceImpact)

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = "Check"
$scanButton.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$scanButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$scanButton.FlatAppearance.BorderSize = 0
$scanButton.BackColor = [System.Drawing.Color]::White
$scanButton.ForeColor = New-Color 38 38 36
$scanButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$scanButton.Location = New-Object System.Drawing.Point(418, 236)
$scanButton.Size = New-Object System.Drawing.Size(116, 30)
$tuningPanel.Controls.Add($scanButton)
Enable-RoundedBorder $scanButton 15 (New-Color 208 208 202)
$toolTip.SetToolTip($scanButton, "Read-only audit. Compares installed XML with current choices.")

$capPanel = New-Object System.Windows.Forms.Panel
$capPanel.Location = New-Object System.Drawing.Point(27, 528)
$capPanel.Size = New-Object System.Drawing.Size(567, 70)
$capPanel.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($capPanel)
Enable-RoundedBorder $capPanel 16 (New-Color 226 224 218)

$capCheck = New-Object System.Windows.Forms.CheckBox
$capCheck.Text = "Brutal Science: lift animal cap"
$capCheck.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9, [System.Drawing.FontStyle]::Bold)
$capCheck.ForeColor = New-Color 130 45 35
$capCheck.AutoSize = $false
$capCheck.Location = New-Object System.Drawing.Point(16, 10)
$capCheck.Size = New-Object System.Drawing.Size(270, 24)
$capCheck.Checked = $false
$capPanel.Controls.Add($capCheck)
$toolTip.SetToolTip($capCheck, "Optional serverconfig.xml edit. Backs up first, then sets MaxSpawnedAnimals to 999.")

$restoreCapButton = New-Object System.Windows.Forms.Button
$restoreCapButton.Text = "Restore"
$restoreCapButton.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$restoreCapButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$restoreCapButton.FlatAppearance.BorderSize = 0
$restoreCapButton.BackColor = [System.Drawing.Color]::White
$restoreCapButton.ForeColor = New-Color 130 45 35
$restoreCapButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$restoreCapButton.Location = New-Object System.Drawing.Point(430, 8)
$restoreCapButton.Size = New-Object System.Drawing.Size(110, 24)
$restoreCapButton.Enabled = $false
$capPanel.Controls.Add($restoreCapButton)
Enable-RoundedBorder $restoreCapButton 12 (New-Color 208 208 202)
$toolTip.SetToolTip($restoreCapButton, "Restore the newest animal-cap backup.")

$capWarning = New-Object System.Windows.Forms.Label
$capWarning.Text = "Sets MaxSpawnedAnimals to 999. This removes a safety rail.`nExpect breakage if hardware, server, or choices cannot keep up."
$capWarning.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$capWarning.ForeColor = New-Color 82 82 78
$capWarning.Location = New-Object System.Drawing.Point(37, 34)
$capWarning.Size = New-Object System.Drawing.Size(510, 30)
$capPanel.Controls.Add($capWarning)

$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Install"
$installButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$installButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$installButton.FlatAppearance.BorderSize = 0
$installButton.BackColor = New-Color 158 45 34
$installButton.ForeColor = [System.Drawing.Color]::White
$installButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$installButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$installButton.Padding = New-Object System.Windows.Forms.Padding(20, 0, 0, 0)
$installButton.Location = New-Object System.Drawing.Point(27, 623)
$installButton.Size = New-Object System.Drawing.Size(206, 42)
$form.Controls.Add($installButton)
Set-RoundedRegion $installButton 21

$actionDot = New-Object System.Windows.Forms.Label
$actionDot.Text = "↑"
$actionDot.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$actionDot.ForeColor = New-Color 158 45 34
$actionDot.BackColor = [System.Drawing.Color]::White
$actionDot.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$actionDot.Cursor = [System.Windows.Forms.Cursors]::Hand
$actionDot.Location = New-Object System.Drawing.Point(196, 631)
$actionDot.Size = New-Object System.Drawing.Size(26, 26)
$form.Controls.Add($actionDot)
Set-RoundedRegion $actionDot 13
$actionDot.BringToFront()

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Text = "Remove"
$removeButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$removeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$removeButton.FlatAppearance.BorderSize = 0
$removeButton.BackColor = [System.Drawing.Color]::White
$removeButton.ForeColor = New-Color 38 38 36
$removeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$removeButton.Location = New-Object System.Drawing.Point(249, 623)
$removeButton.Size = New-Object System.Drawing.Size(112, 42)
$form.Controls.Add($removeButton)
Enable-RoundedBorder $removeButton 21 (New-Color 208 208 202)

$openFolderButton = New-Object System.Windows.Forms.Button
$openFolderButton.Text = "Mods Folder"
$openFolderButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$openFolderButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$openFolderButton.FlatAppearance.BorderSize = 0
$openFolderButton.BackColor = [System.Drawing.Color]::White
$openFolderButton.ForeColor = New-Color 38 38 36
$openFolderButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$openFolderButton.Location = New-Object System.Drawing.Point(371, 623)
$openFolderButton.Size = New-Object System.Drawing.Size(130, 42)
$form.Controls.Add($openFolderButton)
Enable-RoundedBorder $openFolderButton 21 (New-Color 208 208 202)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close"
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.BackColor = [System.Drawing.Color]::White
$closeButton.ForeColor = New-Color 38 38 36
$closeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$closeButton.Location = New-Object System.Drawing.Point(510, 623)
$closeButton.Size = New-Object System.Drawing.Size(84, 42)
$form.Controls.Add($closeButton)
Enable-RoundedBorder $closeButton 21 (New-Color 208 208 202)

$status = New-Object System.Windows.Forms.Label
$status.Text = ""
$status.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$status.Location = New-Object System.Drawing.Point(27, 678)
$status.Size = New-Object System.Drawing.Size(566, 22)
$status.ForeColor = New-Color 45 45 43
$status.Visible = $false
$form.Controls.Add($status)

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
    $controls.Value.Text = if ($enabled) { Get-TuningLevelName $level } else { "Keep" }
    $controls.Base.Text = Get-AnimalRowBaseText -Entity $Entity
    $controls.Preview.Text = if ($enabled) { Get-AnimalRowPreviewText -Entity $Entity -Level $level } else { Get-AnimalRowBaseText -Entity $Entity }

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
        return "No changes selected."
    }

    $levelGroups = @($activeEntities | Group-Object { [int]$effectiveLevels[$_] })
    $densityLevel = Get-DensityLevelFromAnimalLevels -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels
    $densityName = Get-TuningLevelName $densityLevel
    if ($levelGroups.Count -eq 1) {
        $levelName = Get-TuningLevelName ([int]$levelGroups[0].Name)
        if ($activeEntities.Count -eq (Get-AnimalEntitiesFromRows -Rows $script:AnimalRows).Count) {
            return "All animals: $levelName. Density: $densityName."
        }
        return "$($activeEntities.Count) selected: $levelName. Density: $densityName."
    }

    return "$($activeEntities.Count) selected: mixed levels. Density: $densityName."
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

            $y = $rowIndex * 24
            $displayName = Get-AnimalDisplayName $entity

            $check = New-Object System.Windows.Forms.CheckBox
            $check.Text = $displayName
            $check.Tag = $entity
            $check.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $check.ForeColor = New-Color 38 38 36
            $check.Location = New-Object System.Drawing.Point(22, $y)
            $check.Size = New-Object System.Drawing.Size(118, 22)
            $animalRowsPanel.Controls.Add($check)

            $track = New-Object System.Windows.Forms.TrackBar
            $track.Tag = $entity
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
            $valueLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $valueLabel.Location = New-Object System.Drawing.Point(264, ($y + 3))
            $valueLabel.Size = New-Object System.Drawing.Size(82, 18)
            $animalRowsPanel.Controls.Add($valueLabel)

            $baseLabel = New-Object System.Windows.Forms.Label
            $baseLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $baseLabel.Location = New-Object System.Drawing.Point(346, ($y + 3))
            $baseLabel.Size = New-Object System.Drawing.Size(100, 18)
            $animalRowsPanel.Controls.Add($baseLabel)

            $previewLabel = New-Object System.Windows.Forms.Label
            $previewLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $previewLabel.Location = New-Object System.Drawing.Point(450, ($y + 3))
            $previewLabel.Size = New-Object System.Drawing.Size(90, 18)
            $animalRowsPanel.Controls.Add($previewLabel)

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
        Update-AllAnimalRowControls
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
        if ([bool]$CapResult.Changed) {
            [void]$lines.Add("Global animal cap: MaxSpawnedAnimals $($CapResult.PreviousValue) -> $($CapResult.NewValue)")
            [void]$lines.Add("serverconfig.xml backup: created beside serverconfig.xml")
        }
        else {
            [void]$lines.Add("Global animal cap: already $($CapResult.NewValue), no serverconfig change")
        }
    }
    [void]$lines.Add("")
    [void]$lines.Add("Animal mix:")

    $verifiedEntities = Get-AnimalEntitiesFromRows -Rows $VerifiedRows
    foreach ($entity in $verifiedEntities) {
        if (-not $AnimalLevels.ContainsKey($entity)) {
            continue
        }
        $level = [int]$AnimalLevels[$entity]
        $parts = New-Object System.Collections.ArrayList
        foreach ($row in @($VerifiedRows | Where-Object { $_.Entity -eq $entity })) {
            [void]$parts.Add("$(Get-GroupShortName $row.Group) $($row.Value)")
        }
        [void]$lines.Add("- $(Get-AnimalDisplayName $entity): $(Get-TuningLevelName $level) ($($parts -join ', '))")
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

    if (-not $IncludeBrutalScienceCap) {
        return
    }

    [void]$Lines.Add("")
    $currentCap = Get-MaxSpawnedAnimalsValue -GameRoot $GameRoot
    if ($null -eq $currentCap) {
        [void]$Lines.Add("Global animal cap: MaxSpawnedAnimals could not be read.")
    }
    elseif ($currentCap -ge $script:BrutalScienceAnimalCap) {
        [void]$Lines.Add("Global animal cap: MaxSpawnedAnimals is $currentCap. Brutal Science cap is active.")
    }
    else {
        [void]$Lines.Add("Global animal cap: MaxSpawnedAnimals is $currentCap. Brutal Science would set it to $script:BrutalScienceAnimalCap.")
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

        [void]$lines.Add("")
        if ($hasInstallTarget) {
            [void]$lines.Add("Next: Install.")
        }
        else {
            [void]$lines.Add("Next: choose an animal to tune.")
        }
        Add-BrutalScienceCapScanLines -Lines $lines -GameRoot $GameRoot -IncludeBrutalScienceCap $IncludeBrutalScienceCap

        return @{
            State = "Missing"
            Title = "Scanned: Not Installed"
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
        [void]$lines.Add("")
        [void]$lines.Add("Next: choose animals, or remove.")
        Add-BrutalScienceCapScanLines -Lines $lines -GameRoot $GameRoot -IncludeBrutalScienceCap $IncludeBrutalScienceCap

        return @{
            State = "Current"
            Title = "Scanned: Installed"
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
    else {
        [void]$lines.Add("")
        [void]$lines.Add("Next: Reinstall.")
    }

    [void]$lines.Add("")
    [void]$lines.Add((Get-ChoiceImpactText))
    Add-BrutalScienceCapScanLines -Lines $lines -GameRoot $GameRoot -IncludeBrutalScienceCap $IncludeBrutalScienceCap

    return @{
        State = $(if ($isCurrent) { "Current" } else { "Drift" })
        Title = $(if ($isCurrent) { "Scanned: Up To Date" } else { "Scanned: Update Available" })
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

    $installButton.Text = $Text
    $installButton.Enabled = $true
    $installButton.BackColor = New-Color 158 45 34
    $installButton.ForeColor = [System.Drawing.Color]::White
    $installButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $actionDot.Enabled = $true
    $actionDot.ForeColor = New-Color 158 45 34
    $actionDot.BackColor = [System.Drawing.Color]::White
    $actionDot.Cursor = [System.Windows.Forms.Cursors]::Hand
}

function Set-PrimaryActionQuiet {
    param([string]$Text)

    $installButton.Text = $Text
    $installButton.Enabled = $false
    $installButton.BackColor = New-Color 224 224 219
    $installButton.ForeColor = New-Color 125 125 120
    $installButton.Cursor = [System.Windows.Forms.Cursors]::Default
    $actionDot.Enabled = $false
    $actionDot.ForeColor = New-Color 156 156 150
    $actionDot.BackColor = New-Color 238 238 235
    $actionDot.Cursor = [System.Windows.Forms.Cursors]::Default
}

function Update-PrimaryActionState {
    param([string]$GameRoot)

    if (-not (Test-GameRoot $GameRoot)) {
        Set-PrimaryActionQuiet -Text "Install"
        return
    }

    $effectiveLevels = Get-EffectiveAnimalLevels
    if ($effectiveLevels.Count -lt 1) {
        Set-PrimaryActionQuiet -Text "Select Animals"
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
        if ($effectiveLevels.Count -lt 1) {
            Set-Status $status "Pick at least one animal." (New-Color 180 90 24)
            return
        }

        $capResult = $null
        if ($capCheck.Checked) {
            $choice = [System.Windows.Forms.MessageBox]::Show(
                "Brutal Science will set MaxSpawnedAnimals to $script:BrutalScienceAnimalCap in serverconfig.xml after making a timestamped backup.`n`nThis can produce extreme animal pressure when Dense or Absurd routes are active. It may stress hardware, servers, saves, and good judgment. Scientifically useful; operationally spicy.`n`nContinue?",
                "Brutal Science Animal Cap",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
                Set-Status $status "Install cancelled before changing the animal cap." (New-Color 82 82 78)
                return
            }
        }

        $densityLevel = Get-DensityLevelFromAnimalLevels -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels
        $target = Install-Mod -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels
        $verifiedRows = Test-InstalledAnimalConfig -TargetMod $target -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels
        Test-InstalledSpawningConfig -TargetMod $target -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels | Out-Null
        if ($capCheck.Checked) {
            $capResult = Set-BrutalScienceAnimalCap -GameRoot $pathBox.Text
        }
        $feedbackText = New-InstallFeedbackText -VerifiedRows $verifiedRows -AnimalLevels $effectiveLevels -GameRoot $pathBox.Text -DensityLevel $densityLevel -CapResult $capResult

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
        $effectiveLevels = Get-EffectiveAnimalLevels
        $scanReport = New-ScanValuesReport -GameRoot $pathBox.Text -AnimalLevels $effectiveLevels -IncludeBrutalScienceCap ([bool]$capCheck.Checked)

        if ($scanReport.State -eq "Current") {
            Set-Status $status "Check complete: XML is current." ([System.Drawing.Color]::DarkGreen)
        }
        elseif ($scanReport.State -eq "Missing") {
            Set-Status $status "Check complete: not installed." ([System.Drawing.Color]::DarkOrange)
        }
        else {
            Set-Status $status "Check complete: XML differs from choices." ([System.Drawing.Color]::DarkOrange)
        }

        Show-ReadOnlyReportDialog -Owner $form -Title $scanReport.Title -Text $scanReport.Text
    }
    catch {
        Set-Status $status "Scan failed: $($_.Exception.Message)" ([System.Drawing.Color]::Firebrick)
    }
})

$changeLogLink.Add_LinkClicked({
    Show-VersionHighlightsDialog -Owner $form
})

$removeButton.Add_Click({
    try {
        if (Test-ModInstalled $pathBox.Text) {
            $choice = [System.Windows.Forms.MessageBox]::Show(
                "Remove 7DTD 3.0 Wasteland Animal Population Tuning from Mods?",
                "Remove",
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
        $backup = Get-LatestBrutalScienceAnimalCapBackup -GameRoot $pathBox.Text
        if ($null -eq $backup) {
            Set-Status $status "No Bit Wrecked animal-cap backup was found." ([System.Drawing.Color]::DarkOrange)
            Update-InstallState
            return
        }

        $backupValue = Get-MaxSpawnedAnimalsValueFromFile -Path $backup.FullName
        $currentValue = Get-MaxSpawnedAnimalsValue -GameRoot $pathBox.Text
        $choice = [System.Windows.Forms.MessageBox]::Show(
            "Restore serverconfig.xml from the newest Bit Wrecked animal-cap backup?`n`nCurrent MaxSpawnedAnimals: $currentValue`nBackup MaxSpawnedAnimals: $backupValue`n`nBackup:`n$($backup.Name)",
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
    }
})

$masterTrack.Add_Scroll({
    if (-not $script:IsUpdatingTuning) {
        Set-MasterLevel -Level (Get-LevelFromSliderValue ([int]$masterTrack.Value))
        Update-TuningLabels
        Update-PrimaryActionState -GameRoot $pathBox.Text
    }
})

$closeButton.Add_Click({
    $form.Close()
})

Refresh-AnimalChoices
Update-TuningLabels
Update-InstallState

$smokeTimer = $null
if ($SmokeTest) {
    $form.Add_Shown({
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
