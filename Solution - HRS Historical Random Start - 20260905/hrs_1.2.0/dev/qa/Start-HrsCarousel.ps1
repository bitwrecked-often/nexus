[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $GameName,
    [string] $GameRoot = 'C:\Program Files (x86)\Steam\steamapps\common\7 Days To Die',
    [ValidateRange(5, 300)] [int] $DwellSeconds = 30,
    [string] $StartPoint = '',
    [string] $EndPoint = '',
    [string[]] $AdditionalExcludedPointIds = @(),
    [ValidateRange(5, 720)] [int] $WaitMinutes = 720,
    [switch] $NoWait
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ($GameName -cnotmatch '^[A-Za-z0-9_-]{1,64}$') {
    throw 'GameName must contain only letters, numbers, underscore, or hyphen.'
}
if (@(Get-Process -Name '7DaysToDie', '7DaysToDieServer', '7DaysToDie_EAC' -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'Close the game before installing and arming the carousel.'
}
$game = [System.IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
if (-not (Test-Path -LiteralPath (Join-Path $game '7DaysToDie.exe') -PathType Leaf)) {
    throw 'Game root is not recognized.'
}
$saveRoot = Join-Path ([Environment]::GetFolderPath(
    [Environment+SpecialFolder]::ApplicationData)) '7DaysToDie\Saves\Navezgane'
$savePath = Join-Path $saveRoot $GameName
if (-not (Test-Path -LiteralPath $savePath -PathType Container)) {
    throw "The exact existing Navezgane save was not found: $savePath"
}
$qaRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$devRoot = Split-Path -Parent $qaRoot
$buildScript = Join-Path $devRoot 'src\runtime\Build-HrsCarousel.ps1'
$outputRoot = Join-Path $devRoot 'out\carousel'
$build = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $buildScript `
    -GameRoot $game -AdditionalExcludedPointIds $AdditionalExcludedPointIds
if ($LASTEXITCODE -ne 0) { throw 'Pinned carousel build failed.' }
$idsPath = Join-Path $outputRoot 'active-point-ids.txt'
$pointIds = @(Get-Content -LiteralPath $idsPath | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_)
})
if ($pointIds.Count -lt 1 -or
    @($pointIds | Where-Object { $_ -notmatch '^NVG-\d{4}$' }).Count -gt 0 -or
    @($pointIds | Sort-Object -Unique).Count -ne $pointIds.Count) {
    throw 'Generated active point ID list is invalid.'
}
if ([string]::IsNullOrWhiteSpace($StartPoint)) { $StartPoint = $pointIds[0] }
if ([string]::IsNullOrWhiteSpace($EndPoint)) { $EndPoint = $pointIds[-1] }
if ($StartPoint -notmatch '^NVG-\d{4}$' -or $EndPoint -notmatch '^NVG-\d{4}$') {
    throw 'StartPoint and EndPoint must use exact NVG-#### stable IDs.'
}
$startIndex = [array]::IndexOf($pointIds, $StartPoint)
if ($startIndex -lt 0) { throw "StartPoint is not active: $StartPoint" }
$endIndex = [array]::IndexOf($pointIds, $EndPoint)
if ($endIndex -lt 0) { throw "EndPoint is not active: $EndPoint" }
if ($endIndex -lt $startIndex) { throw 'EndPoint must not precede StartPoint.' }
$pointCount = $pointIds.Count

$modRoot = Join-Path $game 'Mods\BitWrecked_HRS_QA_Carousel'
$bridge = Join-Path $modRoot 'Bridge'
[void][System.IO.Directory]::CreateDirectory($bridge)
Copy-Item -LiteralPath (Join-Path $outputRoot 'hrs_carousel_qa.dll') -Destination $modRoot -Force
Copy-Item -LiteralPath (Join-Path $outputRoot 'ModInfo.xml') -Destination $modRoot -Force
foreach ($leaf in @('carousel.arm','carousel.consumed','carousel.stop',
    'carousel-events.tsv','carousel-result.v1.json','carousel-result.v1.json.tmp')) {
    $path = Join-Path $bridge $leaf
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}
$runId = [guid]::NewGuid().ToString('N')
$arm = @(
    'HRS-CAROUSEL-ARM-V2'
    'RUN=' + $runId
    'GAME=' + $GameName
    'DWELL_SECONDS=' + $DwellSeconds
    'START_INDEX=' + $startIndex
    'END_INDEX=' + $endIndex
    'POINTS=' + $pointCount
) -join "`n"
[System.IO.File]::WriteAllText((Join-Path $bridge 'carousel.arm'), $arm,
    (New-Object System.Text.UTF8Encoding($false)))

$summary = [pscustomobject][ordered]@{
    status = 'ARMED'
    runId = $runId
    gameName = $GameName
    savePath = $savePath
    points = "$StartPoint-$EndPoint"
    dwellSeconds = $DwellSeconds
    estimatedMinutes = [math]::Ceiling((($endIndex - $startIndex + 1) * ($DwellSeconds + 20)) / 60)
    instruction = 'Start 7 Days to Die without EAC and load this existing disposable Navezgane save.'
    resultPath = Join-Path $bridge 'carousel-result.v1.json'
    eventPath = Join-Path $bridge 'carousel-events.tsv'
    emergencyStop = "Create an empty file named carousel.stop in $bridge"
    buildOutput = $build
}
$summary
if ($NoWait) { return }

Write-Host ''
Write-Host 'Carousel watcher is running. Start the game without EAC and load the named disposable save.'
Write-Host 'Use Stop-HrsCarousel.ps1 from another PowerShell window for an emergency stop.'
$resultPath = Join-Path $bridge 'carousel-result.v1.json'
$eventPath = Join-Path $bridge 'carousel-events.tsv'
$deadline = [datetime]::UtcNow.AddMinutes($WaitMinutes)
$seenLines = 0
while ([datetime]::UtcNow -lt $deadline) {
    if (Test-Path -LiteralPath $eventPath -PathType Leaf) {
        $lines = @(Get-Content -LiteralPath $eventPath)
        if ($lines.Count -gt $seenLines) {
            for ($i = $seenLines; $i -lt $lines.Count; $i++) {
                $fields = $lines[$i] -split "`t"
                if ($fields.Count -eq 12) {
                    Write-Host ("[{0}] {1} {2} health={3} reason={4}" -f `
                        $fields[0], $fields[2], $fields[3], $fields[10], $fields[11])
                }
            }
            $seenLines = $lines.Count
        }
    }
    if (Test-Path -LiteralPath $resultPath -PathType Leaf) {
        $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
        Write-Host ''
        Write-Host ("Carousel {0}: passed {1}/{2}; stopped at {3}; reason={4}" -f `
            $result.status, $result.passedPoints, $result.totalPoints,
            $result.point, $result.reason)
        $result
        return
    }
    Start-Sleep -Seconds 1
}
throw "Carousel watcher timed out after $WaitMinutes minutes. Inspect $eventPath and request an emergency stop if the game is still running."
