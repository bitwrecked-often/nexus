[CmdletBinding()]
param(
    [string] $GameRoot = 'C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$bridge = Join-Path ([System.IO.Path]::GetFullPath($GameRoot).TrimEnd('\')) `
    'Mods\BitWrecked_HRS_QA_Carousel\Bridge'
if (-not (Test-Path -LiteralPath $bridge -PathType Container)) {
    throw 'Carousel Bridge folder was not found.'
}
$stop = Join-Path $bridge 'carousel.stop'
[System.IO.File]::WriteAllText($stop, 'STOP',
    (New-Object System.Text.UTF8Encoding($false)))
Write-Host 'Emergency stop requested. The runtime will restore the starting position and end the carousel.'
