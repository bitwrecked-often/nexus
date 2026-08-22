# 7DTD 3.0 Wasteland Animal Population Tuning - Windows uninstaller
# Copyright (C) 2026 Bit Wrecked
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This program is distributed without warranty. See ..\LICENSE.txt for details.

$ErrorActionPreference = "Stop"

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

try {
    Write-Host "7DTD 3.0 Wasteland Animal Population Tuning Uninstaller"
    Write-Host "-----------------------------------"
    Write-Host ""

    $gameRoot = Resolve-Path -LiteralPath (Read-GameRoot) -ErrorAction Stop
    $targetMod = Join-Path $gameRoot.Path "Mods\BitWrecked_7DTD_WastelandAnimalPopulationTuning"

    if (-not (Test-Path -LiteralPath $targetMod -PathType Container)) {
        Write-Host "Mod folder was not found:"
        Write-Host "  $targetMod"
        exit 0
    }

    Write-Host "This will delete:"
    Write-Host "  $targetMod"
    $confirm = Read-Host "Type DELETE to remove it"
    if ($confirm -ne "DELETE") {
        Write-Host "Uninstall cancelled."
        exit 0
    }

    Remove-Item -LiteralPath $targetMod -Recurse -Force
    Write-Host "Uninstall complete."
}
catch {
    Write-Host ""
    Write-Host "Uninstall failed:"
    Write-Host "  $($_.Exception.Message)"
    exit 1
}
