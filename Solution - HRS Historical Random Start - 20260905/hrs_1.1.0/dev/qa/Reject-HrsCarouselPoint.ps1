[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^NVG-\d{4}$')]
    [string] $PointId,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Z0-9_]{1,48}$')]
    [string] $Reason
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if (@(Get-Process -Name '7DaysToDie', '7DaysToDieServer', '7DaysToDie_EAC' -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'Close the game before changing the carousel rejection record.'
}
$qaRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$devRoot = Split-Path -Parent $qaRoot
$catalogPath = Join-Path $devRoot 'scouting\navezgane_poi_catalog_v3.2-b9.csv'
$rejectionsPath = Join-Path $qaRoot 'carousel-rejections.json'
$catalogEntry = @(Import-Csv -LiteralPath $catalogPath | Where-Object {
    $_.InstanceId -ceq $PointId
})
if ($catalogEntry.Count -ne 1) { throw 'PointId is not an exact POI catalog instance.' }
$record = Get-Content -LiteralPath $rejectionsPath -Raw | ConvertFrom-Json
if ($record.schema -cne 'hrs-carousel-rejections/v1') {
    throw 'Carousel rejection schema is not recognized.'
}
if (@($record.points | Where-Object { $_.pointId -ceq $PointId }).Count -gt 0) {
    throw "Point is already rejected: $PointId"
}
$points = @($record.points) + [pscustomobject][ordered]@{
    pointId = $PointId
    reason = $Reason
    rejectedUtc = [datetime]::UtcNow.ToString('o')
}
$updated = [pscustomobject][ordered]@{
    schema = 'hrs-carousel-rejections/v1'
    points = @($points | Sort-Object pointId)
}
$json = $updated | ConvertTo-Json -Depth 5
$temp = $rejectionsPath + '.tmp'
$backup = $rejectionsPath + '.bak'
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($temp, $json + "`n", $utf8)
[System.IO.File]::Replace($temp, $rejectionsPath, $backup)
if ([System.IO.File]::Exists($backup)) { [System.IO.File]::Delete($backup) }
[pscustomobject][ordered]@{
    status = 'REJECTED'
    pointId = $PointId
    reason = $Reason
    totalRejected = $updated.points.Count
    nextPointHint = 'Resume from the next active stable ID in catalog order.'
}
