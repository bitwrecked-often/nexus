[CmdletBinding()]
param(
    [string] $GameRoot = 'C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if (@(Get-Process -Name '7DaysToDie', '7DaysToDieServer', '7DaysToDie_EAC' -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'Close the game before removing the QA carousel.'
}
$game = [System.IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
if (-not (Test-Path -LiteralPath (Join-Path $game '7DaysToDie.exe') -PathType Leaf)) {
    throw 'Game root is not recognized.'
}
$modsRoot = [System.IO.Path]::GetFullPath((Join-Path $game 'Mods'))
$target = [System.IO.Path]::GetFullPath((Join-Path $modsRoot 'BitWrecked_HRS_QA_Carousel'))
$expected = $modsRoot.TrimEnd('\') + '\BitWrecked_HRS_QA_Carousel'
if (-not [string]::Equals($target.TrimEnd('\'), $expected,
    [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Resolved QA carousel target is not exact.'
}
if (-not (Test-Path -LiteralPath $target)) {
    Write-Host 'QA carousel is already absent.'
    return
}
$name = (Get-Item -LiteralPath $target).Name
if ($name -cne 'BitWrecked_HRS_QA_Carousel') {
    throw 'QA carousel folder identity did not match.'
}
Remove-Item -LiteralPath $target -Recurse -Force
Write-Host "Removed QA-only carousel: $target"
