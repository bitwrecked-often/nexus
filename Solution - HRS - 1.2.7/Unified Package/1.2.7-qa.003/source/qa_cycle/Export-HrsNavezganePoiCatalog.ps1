[CmdletBinding()]
param(
    [string]$GameRoot = (Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\common\7 Days To Die'),
    [string]$OutputPath = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot '..\hrs_1.1.0\dev\scouting\navezgane_poi_catalog_v3.2-b9.csv'
}

function Get-RequiredPath {
    param([string]$LiteralPath, [string]$Label)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        throw "$Label was not found: $LiteralPath"
    }
    return (Resolve-Path -LiteralPath $LiteralPath).Path
}

function Get-XmlProperty {
    param([xml]$Document, [string]$Name)
    $node = $Document.SelectSingleNode("/prefab/property[@name='$Name']")
    if ($null -eq $node) { return '' }
    return [string]$node.value
}

function Get-DirectionalCoordinate {
    param([int]$Value, [string]$Positive, [string]$Negative)
    if ($Value -lt 0) { return ('{0} {1}' -f ([Math]::Abs($Value)), $Negative) }
    return ('{0} {1}' -f $Value, $Positive)
}

$worldRoot = Join-Path $GameRoot 'Data\Worlds\Navezgane'
$prefabsPath = Get-RequiredPath (Join-Path $worldRoot 'prefabs.xml') 'Navezgane prefab index'
$mapInfoPath = Get-RequiredPath (Join-Path $worldRoot 'map_info.xml') 'Navezgane map information'
$biomeMapPath = Get-RequiredPath (Join-Path $worldRoot 'biomes.png') 'Navezgane biome map'
$biomesPath = Get-RequiredPath (Join-Path $GameRoot 'Data\Config\biomes.xml') 'Biome configuration'
$localizationPath = Get-RequiredPath (Join-Path $GameRoot 'Data\Config\Localization.csv') 'Localization catalog'
$prefabRoot = Join-Path $GameRoot 'Data\Prefabs'

[xml]$worldDoc = Get-Content -LiteralPath $prefabsPath -Raw
[xml]$mapDoc = Get-Content -LiteralPath $mapInfoPath -Raw
[xml]$biomeDoc = Get-Content -LiteralPath $biomesPath -Raw

$sizeNode = $mapDoc.SelectSingleNode("/MapInfo/property[@name='HeightMapSize']")
if ($null -eq $sizeNode) { throw 'HeightMapSize is missing from map_info.xml.' }
$worldSize = @([string]$sizeNode.value -split ',' | ForEach-Object { [int]$_.Trim() })
if ($worldSize.Count -ne 2) { throw 'HeightMapSize must contain width and height.' }

$localization = @{}
foreach ($row in (Import-Csv -LiteralPath $localizationPath)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$row.Key) -and
        -not $localization.ContainsKey([string]$row.Key)) {
        $localization[[string]$row.Key] = [string]$row.english
    }
}

$biomeByColor = @{}
foreach ($node in $biomeDoc.SelectNodes('//biomes/biome')) {
    $name = [string]$node.GetAttribute('name')
    $color = ([string]$node.GetAttribute('biomemapcolor')).TrimStart('#').ToUpperInvariant()
    if (-not [string]::IsNullOrWhiteSpace($name) -and $color.Length -eq 6) {
        $biomeByColor[$color] = $name
    }
}

$prefabFileByName = @{}
foreach ($file in (Get-ChildItem -LiteralPath $prefabRoot -Filter '*.xml' -File -Recurse)) {
    $key = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    if (-not $prefabFileByName.ContainsKey($key) -or
        $file.FullName -like '*\POIs\*') {
        $prefabFileByName[$key] = $file.FullName
    }
}

$definitionByName = @{}
$decorations = @($worldDoc.prefabs.decoration | Where-Object {
    [string]$_.type -eq 'model' -and [string]$_.name -notlike 'part_*'
})

Add-Type -AssemblyName System.Drawing
$bitmap = [System.Drawing.Bitmap]::FromFile($biomeMapPath)
try {
    $xScale = [double]$bitmap.Width / [double]$worldSize[0]
    $zScale = [double]$bitmap.Height / [double]$worldSize[1]
    $halfWidth = [double]$worldSize[0] / 2.0
    $halfHeight = [double]$worldSize[1] / 2.0
    $raw = foreach ($decoration in $decorations) {
        $name = [string]$decoration.name
        $position = @([string]$decoration.position -split ',' | ForEach-Object { [int]$_.Trim() })
        if ($position.Count -ne 3) { throw "Invalid position for $name" }
        $x = $position[0]
        $y = $position[1]
        $z = $position[2]

        $pixelX = [Math]::Max(0, [Math]::Min($bitmap.Width - 1,
            [int][Math]::Floor(($x + $halfWidth) * $xScale)))
        $pixelY = [Math]::Max(0, [Math]::Min($bitmap.Height - 1,
            [int][Math]::Floor(($halfHeight - $z) * $zScale)))
        $pixel = $bitmap.GetPixel($pixelX, $pixelY)
        $color = '{0:X2}{1:X2}{2:X2}' -f $pixel.R, $pixel.G, $pixel.B
        $biome = if ($biomeByColor.ContainsKey($color)) { $biomeByColor[$color] } else { "unknown_$color" }

        if (-not $definitionByName.ContainsKey($name)) {
            $definition = [ordered]@{
                Tier = ''
                Zoning = ''
                AllowedTownships = ''
                PrefabSize = ''
                Tags = ''
                QuestTags = ''
                TraderArea = ''
                DefinitionPath = ''
            }
            if ($prefabFileByName.ContainsKey($name)) {
                $definitionPath = [string]$prefabFileByName[$name]
                [xml]$definitionDoc = Get-Content -LiteralPath $definitionPath -Raw
                $definition.Tier = Get-XmlProperty $definitionDoc 'DifficultyTier'
                $definition.Zoning = Get-XmlProperty $definitionDoc 'Zoning'
                $definition.AllowedTownships = Get-XmlProperty $definitionDoc 'AllowedTownships'
                $definition.PrefabSize = Get-XmlProperty $definitionDoc 'PrefabSize'
                $definition.Tags = Get-XmlProperty $definitionDoc 'Tags'
                $definition.QuestTags = Get-XmlProperty $definitionDoc 'QuestTags'
                $definition.TraderArea = Get-XmlProperty $definitionDoc 'TraderArea'
                $definition.DefinitionPath = $definitionPath.Substring($GameRoot.Length).TrimStart('\')
            }
            $definitionByName[$name] = [pscustomobject]$definition
        }
        $metadata = $definitionByName[$name]
        $localizedName = if ($localization.ContainsKey($name)) { [string]$localization[$name] } else { '' }
        $hasLocalizedName = -not [string]::IsNullOrWhiteSpace($localizedName)
        $displayName = if ($hasLocalizedName) { $localizedName } else { $name }

        [pscustomobject][ordered]@{
            Prefab = $name
            DisplayName = $displayName
            DisplayNameSource = if ($hasLocalizedName) { 'Localization.csv' } else { 'prefab_fallback' }
            X = $x
            Y = $y
            Z = $z
            DirectionalXZ = ('{0} / {1}' -f
                (Get-DirectionalCoordinate $x 'E' 'W'),
                (Get-DirectionalCoordinate $z 'N' 'S'))
            Biome = $biome
            Rotation = [int]$decoration.rotation
            YIsGroundLevel = [string]$decoration.y_is_groundlevel
            Tier = $metadata.Tier
            Zoning = $metadata.Zoning
            AllowedTownships = $metadata.AllowedTownships
            PrefabSize = $metadata.PrefabSize
            Tags = $metadata.Tags
            QuestTags = $metadata.QuestTags
            TraderArea = $metadata.TraderArea
            DefinitionPath = $metadata.DefinitionPath
        }
    }
}
finally {
    $bitmap.Dispose()
}

$ordered = @($raw | Sort-Object Prefab, X, Z, Y)
$catalog = for ($index = 0; $index -lt $ordered.Count; $index++) {
    $row = $ordered[$index]
    [pscustomobject][ordered]@{
        InstanceId = 'NVG-{0:D4}' -f ($index + 1)
        Prefab = $row.Prefab
        DisplayName = $row.DisplayName
        DisplayNameSource = $row.DisplayNameSource
        X = $row.X
        Y = $row.Y
        Z = $row.Z
        DirectionalXZ = $row.DirectionalXZ
        Biome = $row.Biome
        Rotation = $row.Rotation
        YIsGroundLevel = $row.YIsGroundLevel
        Tier = $row.Tier
        Zoning = $row.Zoning
        AllowedTownships = $row.AllowedTownships
        PrefabSize = $row.PrefabSize
        Tags = $row.Tags
        QuestTags = $row.QuestTags
        TraderArea = $row.TraderArea
        DefinitionPath = $row.DefinitionPath
        CandidateId = ''
        ScoutingState = 'Catalogued'
        ActualPlayerX = ''
        ActualPlayerY = ''
        ActualPlayerZ = ''
        StreetScreenshot = ''
        MapOrPoiCapture = ''
        SurfaceAndClearance = ''
        GeometryRisks = ''
        ImmediateHazards = ''
        ExpectedNearestTrader = ''
        Decision = ''
        DecisionReason = ''
    }
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}
$catalog | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8

$outputHash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
$metaPath = [System.IO.Path]::ChangeExtension($OutputPath, '.meta.json')
$byBiome = [ordered]@{}
foreach ($group in ($catalog | Group-Object Biome | Sort-Object Name)) {
    $byBiome[$group.Name] = $group.Count
}
$metadata = [ordered]@{
    schema = 'hrs-navezgane-poi-catalog-v1'
    generatedUtc = [DateTime]::UtcNow.ToString('o')
    gameRoot = $GameRoot
    world = 'Navezgane'
    totalInstances = $catalog.Count
    uniquePrefabs = @($catalog.Prefab | Sort-Object -Unique).Count
    countsByBiome = $byBiome
    inputs = [ordered]@{
        prefabsXmlSha256 = (Get-FileHash -LiteralPath $prefabsPath -Algorithm SHA256).Hash
        mapInfoXmlSha256 = (Get-FileHash -LiteralPath $mapInfoPath -Algorithm SHA256).Hash
        biomesPngSha256 = (Get-FileHash -LiteralPath $biomeMapPath -Algorithm SHA256).Hash
        biomesXmlSha256 = (Get-FileHash -LiteralPath $biomesPath -Algorithm SHA256).Hash
        localizationCsvSha256 = (Get-FileHash -LiteralPath $localizationPath -Algorithm SHA256).Hash
    }
    output = [ordered]@{
        file = [System.IO.Path]::GetFileName($OutputPath)
        sha256 = $outputHash
    }
    mutationRule = 'Generated catalog: do not edit rows manually; copy selected references into the scouting ledger.'
    evidenceBoundary = 'POI references are catalog data, not approved street anchors or safe-landing proof.'
}
$metadata | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metaPath -Encoding UTF8

Write-Host ('Exported {0} Navezgane POI instances ({1} unique prefabs).' -f
    $catalog.Count, $metadata.uniquePrefabs)
Write-Host ('Catalog: {0}' -f $OutputPath)
Write-Host ('SHA-256: {0}' -f $outputHash)
Write-Host ('Metadata: {0}' -f $metaPath)
