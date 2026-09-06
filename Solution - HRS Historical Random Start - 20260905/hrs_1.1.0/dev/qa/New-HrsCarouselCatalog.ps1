[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $CatalogCsv,
    [Parameter(Mandatory = $true)] [string] $RejectionsJson,
    [Parameter(Mandatory = $true)] [string] $OutputDirectory
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$catalogPath = [System.IO.Path]::GetFullPath($CatalogCsv)
$rejectionsPath = [System.IO.Path]::GetFullPath($RejectionsJson)
$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
    throw 'POI catalog is missing.'
}
if (-not (Test-Path -LiteralPath $rejectionsPath -PathType Leaf)) {
    throw 'Carousel rejection record is missing.'
}
$rejections = Get-Content -LiteralPath $rejectionsPath -Raw | ConvertFrom-Json
if ($rejections.schema -cne 'hrs-carousel-rejections/v1') {
    throw 'Carousel rejection schema is not recognized.'
}
$rejected = @{}
foreach ($entry in @($rejections.points)) {
    if ($entry.pointId -notmatch '^NVG-\d{4}$') {
        throw 'Carousel rejection contains an invalid point ID.'
    }
    if ($rejected.ContainsKey($entry.pointId)) {
        throw "Duplicate carousel rejection: $($entry.pointId)"
    }
    $rejected[$entry.pointId] = $true
}
$rows = @(Import-Csv -LiteralPath $catalogPath)
if ($rows.Count -ne 1487) { throw "Expected 1487 POI instances; found $($rows.Count)." }
$seen = @{}
$active = New-Object System.Collections.Generic.List[object]
$smallCount = 0
foreach ($row in $rows) {
    if ($row.InstanceId -notmatch '^NVG-\d{4}$' -or
        $row.Prefab -notmatch '^[a-zA-Z0-9_]+$') {
        throw 'POI catalog contains an invalid stable ID or prefab token.'
    }
    if ($seen.ContainsKey($row.InstanceId)) {
        throw "Duplicate POI instance ID: $($row.InstanceId)"
    }
    $seen[$row.InstanceId] = $true
    $x = 0
    $y = 0
    $z = 0
    if (-not [int]::TryParse($row.X, [ref]$x) -or
        -not [int]::TryParse($row.Y, [ref]$y) -or
        -not [int]::TryParse($row.Z, [ref]$z) -or
        [math]::Abs($x) -gt 2600 -or [math]::Abs($z) -gt 2600) {
        throw "POI coordinate is invalid or outside the supported map: $($row.InstanceId)"
    }
    $dimensions = @($row.PrefabSize -split ',' | ForEach-Object {
        $value = 0
        if (-not [int]::TryParse($_.Trim(), [ref]$value) -or $value -lt 1) {
            throw "POI size is invalid: $($row.InstanceId)"
        }
        $value
    })
    if ($dimensions.Count -ne 3) {
        throw "POI size must contain exactly three dimensions: $($row.InstanceId)"
    }
    $volume = $dimensions[0] * $dimensions[1] * $dimensions[2]
    if ($volume -lt 100) {
        $smallCount++
    } elseif (-not $rejected.ContainsKey($row.InstanceId)) {
        [void]$active.Add([pscustomobject]@{
            Id = $row.InstanceId
            Label = $row.Prefab
            X = $x
            Y = $y
            Z = $z
        })
    }
}
if ($active.Count -lt 1) { throw 'No active POI candidates remain.' }
[void][System.IO.Directory]::CreateDirectory($outputPath)
$sourcePath = Join-Path $outputPath 'GeneratedCarouselCatalog.cs'
$idsPath = Join-Path $outputPath 'active-point-ids.txt'
$source = New-Object System.Collections.Generic.List[string]
[void]$source.Add('namespace BitWrecked.HistoricalRandomStart.QaCarousel')
[void]$source.Add('{')
[void]$source.Add('    internal static class GeneratedCarouselCatalog')
[void]$source.Add('    {')
[void]$source.Add('        internal static CarouselPoint[] Create()')
[void]$source.Add('        {')
[void]$source.Add('            return new CarouselPoint[]')
[void]$source.Add('            {')
foreach ($point in $active) {
    [void]$source.Add(('                new CarouselPoint("{0}", "{1}", {2}, {3}, {4}),' -f
        $point.Id, $point.Label, $point.X, $point.Y, $point.Z))
}
[void]$source.Add('            };')
[void]$source.Add('        }')
[void]$source.Add('    }')
[void]$source.Add('}')
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($sourcePath, $source, $utf8)
[System.IO.File]::WriteAllLines($idsPath, @($active | ForEach-Object { $_.Id }), $utf8)
[pscustomobject][ordered]@{
    sourcePath = $sourcePath
    idsPath = $idsPath
    sourceCount = $rows.Count
    engineSmallPointCount = $smallCount
    rejectedCount = $rejected.Count
    activeCount = $active.Count
    firstPoint = $active[0].Id
    lastPoint = $active[$active.Count - 1].Id
}
