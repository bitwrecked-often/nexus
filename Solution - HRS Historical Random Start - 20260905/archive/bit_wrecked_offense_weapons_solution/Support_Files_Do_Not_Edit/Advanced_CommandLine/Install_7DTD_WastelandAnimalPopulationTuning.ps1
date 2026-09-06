# 7DTD 3.0 Wasteland Animal Population Tuning - Windows installer
# Copyright (C) 2026 Bit Wrecked
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This program is distributed without warranty. See ..\LICENSE.txt for details.

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$packageRoot = Split-Path -Parent $scriptRoot
$sourceMod = Join-Path $packageRoot "BitWrecked_7DTD_WastelandAnimalPopulationTuning"

function Get-DefaultGameRoot {
    $default = Join-Path ${env:ProgramFiles(x86)} "Steam\steamapps\common\7 Days To Die"
    if (Test-Path -LiteralPath (Join-Path $default "7DaysToDie.exe") -PathType Leaf) {
        return $default
    }
    return $null
}

function Read-GameRoot {
    $defaultGameRoot = Get-DefaultGameRoot

    if ($defaultGameRoot) {
        Write-Host "Found default Steam install:"
        Write-Host "  $defaultGameRoot"
        $answer = Read-Host "Use this folder? Type Y for yes, or N to enter a different folder"
        if ($answer -match "^(y|yes)?$") {
            return $defaultGameRoot
        }
    }

    Write-Host ""
    Write-Host "Open Steam, right-click 7 Days to Die, choose Manage, then Browse local files."
    Write-Host "Copy the folder path from File Explorer and paste it here."
    return Read-Host "7 Days To Die folder path"
}

function Assert-GameRoot {
    param([string]$GameRoot)

    if ([string]::IsNullOrWhiteSpace($GameRoot)) {
        throw "No game folder path was entered."
    }

    $resolved = Resolve-Path -LiteralPath $GameRoot -ErrorAction Stop
    $exePath = Join-Path $resolved.Path "7DaysToDie.exe"
    if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
        throw "That folder does not look like the 7 Days to Die game folder. Missing 7DaysToDie.exe."
    }

    return $resolved.Path
}

try {
    Write-Host "7DTD 3.0 Wasteland Animal Population Tuning Installer"
    Write-Host "---------------------------------"
    Write-Host ""
    Write-Host "Advanced command-line fallback mode."
    Write-Host "This copies the packaged XML modlet as-is."
    Write-Host "It does not read GUI slider choices and does not accept tuning switches."
    Write-Host "For custom animal values, use 7DTD_WastelandAnimalTuning.bat."
    Write-Host ""

    if (-not (Test-Path -LiteralPath (Join-Path $sourceMod "ModInfo.xml") -PathType Leaf)) {
        throw "Installer package is missing BitWrecked_7DTD_WastelandAnimalPopulationTuning\ModInfo.xml. Re-extract the zip and try again."
    }

    $gameRoot = Assert-GameRoot (Read-GameRoot)
    $modsRoot = Join-Path $gameRoot "Mods"
    $targetMod = Join-Path $modsRoot "BitWrecked_7DTD_WastelandAnimalPopulationTuning"

    Write-Host ""
    Write-Host "Installing to:"
    Write-Host "  $targetMod"
    Write-Host ""

    New-Item -ItemType Directory -Force -Path $modsRoot | Out-Null
    Copy-Item -LiteralPath $sourceMod -Destination $modsRoot -Recurse -Force

    Write-Host "Install complete."
    Write-Host ""
    Write-Host "For the simplest modded single-player setup, launch 7 Days to Die without Easy Anti-Cheat."
    Write-Host "To uninstall, delete:"
    Write-Host "  $targetMod"
}
catch {
    Write-Host ""
    Write-Host "Install failed:"
    Write-Host "  $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Nothing in your game files was intentionally changed except the Mods folder copy step if it reached that point."
    exit 1
}
