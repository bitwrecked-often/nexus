[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$qaRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$devRoot = Split-Path -Parent $qaRoot
$mainSource = Join-Path $devRoot 'src\runtime\main\c0213.cs'
$carouselSource = Join-Path $devRoot 'src\runtime\carousel\CarouselMod.cs'
$buildScript = Join-Path $devRoot 'src\runtime\Build-HrsCarousel.ps1'
$runner = Join-Path $qaRoot 'Start-HrsCarousel.ps1'
$stopper = Join-Path $qaRoot 'Stop-HrsCarousel.ps1'
$remover = Join-Path $qaRoot 'Remove-HrsCarousel.ps1'
$rejecter = Join-Path $qaRoot 'Reject-HrsCarouselPoint.ps1'
$generator = Join-Path $qaRoot 'New-HrsCarouselCatalog.ps1'
$rejectionsPath = Join-Path $qaRoot 'carousel-rejections.json'
$poiCatalog = Join-Path $devRoot 'scouting\navezgane_poi_catalog_v3.2-b9.csv'
$contractOutput = Join-Path $devRoot 'out\carousel-contract'

function Assert-Carousel([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw "Carousel static test failed: $Message" }
    Write-Host "PASS: $Message"
}

$main = Get-Content -LiteralPath $mainSource -Raw
$carousel = Get-Content -LiteralPath $carouselSource -Raw
$buildSource = Get-Content -LiteralPath $buildScript -Raw
$runSource = Get-Content -LiteralPath $runner -Raw
$stopSource = Get-Content -LiteralPath $stopper -Raw
$removeSource = Get-Content -LiteralPath $remover -Raw
$rejectSource = Get-Content -LiteralPath $rejecter -Raw
$releasePattern = 'new CuratedStartPoint\("NG\d{2}",'
Assert-Carousel ([regex]::Matches($main, $releasePattern).Count -eq 12) `
    'release survey catalog remains 12 points'

$poiRows = @(Import-Csv -LiteralPath $poiCatalog)
Assert-Carousel ($poiRows.Count -eq 1487) 'source POI catalog contains 1,487 instances'
$expectedIds = 1..1487 | ForEach-Object { 'NVG-{0:D4}' -f $_ }
$sourceIds = @($poiRows | ForEach-Object { $_.InstanceId })
Assert-Carousel (($expectedIds -join ',') -ceq ($sourceIds -join ',')) `
    'source POI IDs are unique, ordered, and stable from NVG-0001 to NVG-1487'
$rejections = Get-Content -LiteralPath $rejectionsPath -Raw | ConvertFrom-Json
Assert-Carousel ($rejections.schema -ceq 'hrs-carousel-rejections/v1') `
    'persistent rejection record uses the expected schema'
$rejectedIds = @($rejections.points | ForEach-Object { $_.pointId })
Assert-Carousel (@($rejectedIds | Sort-Object -Unique).Count -eq $rejectedIds.Count -and
    @($rejectedIds | Where-Object { $_ -notin $sourceIds }).Count -eq 0) `
    'every rejected stable ID is unique and present in the POI catalog'

if (Test-Path -LiteralPath $contractOutput) {
    $resolved = (Resolve-Path -LiteralPath $contractOutput).Path
    $expected = [System.IO.Path]::GetFullPath($contractOutput)
    if ($resolved -cne $expected) { throw 'Unexpected contract-output path.' }
    [System.IO.Directory]::Delete($resolved, $true)
}
$generated = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $generator `
    -CatalogCsv $poiCatalog -RejectionsJson $rejectionsPath `
    -OutputDirectory $contractOutput
if ($LASTEXITCODE -ne 0) { throw 'Catalog generator contract run failed.' }
$activeIds = @(Get-Content -LiteralPath (Join-Path $contractOutput 'active-point-ids.txt'))
$eligibleRows = @($poiRows | Where-Object {
    $dimensions = @($_.PrefabSize -split ',' | ForEach-Object { [int]$_.Trim() })
    ($dimensions[0] * $dimensions[1] * $dimensions[2]) -ge 100
})
$expectedActive = @($eligibleRows | Where-Object {
    $_.InstanceId -notin $rejectedIds
} | ForEach-Object { $_.InstanceId })
Assert-Carousel ($eligibleRows.Count -eq 745) `
    'engine small-POI volume rule excludes 742 decoration instances'
Assert-Carousel ($activeIds.Count -eq $expectedActive.Count -and
    ($activeIds -join ',') -ceq ($expectedActive -join ',')) `
    'generated active list contains every eligible non-rejected POI in catalog order'
$generatedSource = Get-Content -LiteralPath `
    (Join-Path $contractOutput 'GeneratedCarouselCatalog.cs') -Raw
$generatedPattern = 'new CarouselPoint\("(NVG-\d{4})", "([a-zA-Z0-9_]+)", (-?\d+), (-?\d+), (-?\d+)\),'
$generatedRows = @([regex]::Matches($generatedSource, $generatedPattern))
Assert-Carousel ($generatedRows.Count -eq $activeIds.Count) `
    'generated C# contains exactly one point per active stable ID'
$generatedKeys = @($generatedRows | ForEach-Object {
    '{0}|{1}|{2}|{3}' -f $_.Groups[1].Value, $_.Groups[3].Value,
        $_.Groups[4].Value, $_.Groups[5].Value
})
$expectedKeys = @($eligibleRows | Where-Object {
    $_.InstanceId -notin $rejectedIds
} | ForEach-Object { '{0}|{1}|{2}|{3}' -f $_.InstanceId, $_.X, $_.Y, $_.Z })
Assert-Carousel (($generatedKeys -join "`n") -ceq ($expectedKeys -join "`n")) `
    'generated runtime IDs and ground coordinates exactly match the eligible POI catalog'
[System.IO.Directory]::Delete([System.IO.Path]::GetFullPath($contractOutput), $true)

Assert-Carousel ($carousel -match 'GeneratedCarouselCatalog\.Create\(\)') `
    'runtime uses the generated full POI catalog'
Assert-Carousel ($carousel -match '229796d0-95ca-4662-b426-1a6f1f1596ed' -and
    $buildSource -match '229796d0-95ca-4662-b426-1a6f1f1596ed') `
    'runtime and build recipe share the current Steam-build MVID pin'
Assert-Carousel ($carousel -match 'points != CarouselCatalog\.Count') `
    'runtime binds each arm to the exact generated active count'
Assert-Carousel ($carousel -match 'data\.RespawnType != RespawnType\.LoadedGame') `
    'carousel can start only from an explicitly loaded existing save'
Assert-Carousel ($carousel -match 'TryConsume\(paths\)') 'arm is consumed for one-run behavior'
Assert-Carousel ($carousel -match 'pointIndex = arm\.StartIndex') `
    'an explicitly armed resume point controls the first attempted anchor'
Assert-Carousel ($carousel -match 'pointIndex > arm\.EndIndex') `
    'an explicitly armed end point bounds a run'
Assert-Carousel ($carousel -match 'File\.Exists\(paths\.StopPath\)') `
    'manual emergency stop is polled'
Assert-Carousel ($carousel -match 'stage != CarouselStage\.Restore && File\.Exists\(paths\.StopPath\)') `
    'manual stop cannot re-enter failure handling during restoration'
Assert-Carousel ($carousel -notmatch 'world\.GetHeight\(' -and
    ([regex]::Matches($carousel, 'world\.GetTerrainHeight\(').Count -eq 1)) `
    'loaded-chunk landing search uses terrain height rather than the tallest block'
Assert-Carousel ($carousel -match 'new Vector3\(point\.X, point\.Y \+ 1f, point\.Z\)') `
    'catalog ground loads the destination chunk before terrain resolution'
Assert-Carousel ($carousel -match 'PrimeDelaySeconds = 2f' -and
    $carousel -match 'SecondLandingLift = 2f' -and
    $carousel -match 'stage = CarouselStage\.PrimeDelay' -and
    $carousel -match 'landing \+= Vector3\.up \* SecondLandingLift' -and
    $carousel -match 'PRIMED_PLUS_2M') `
    'landing waits two seconds for POI collision then teleports two metres higher'
Assert-Carousel ($carousel -match 'HorizontalDistance\(position, landing\) <= PositionTolerance' -and
    $carousel -match 'Math\.Abs\(position\.y - point\.Y\) <= SettledHeightTolerance' -and
    $carousel -match 'landing = position' -and
    $carousel -match 'ACTUAL_GROUNDED_SURFACE') `
    'settling accepts the formed prefab surface and baselines its actual position'
Assert-Carousel ($carousel -match 'Math\.Abs\(terrainY - point\.Y\) > MaximumTerrainDelta') `
    'landing terrain must remain near the catalogued ground level'
Assert-Carousel ($carousel -match 'BeginRestore\(player, "FAILED", reason\)') `
    'point failures enter restore-before-stop behavior'
Assert-Carousel ($carousel -match 'BeginRestore\(player, "COMPLETED", "ALL_POINTS_PASSED"\)') `
    'successful completion also restores the starting position'
Assert-Carousel ($carousel -match 'health \+ 0\.001f >= baselineHealth') `
    'health loss is a terminal point failure'
Assert-Carousel ($carousel -match 'Time\.realtimeSinceStartup \+ arm\.DwellSeconds') `
    'each settled point uses the armed dwell duration'
Assert-Carousel ($carousel -match 'Vector3\.Distance\(player\.GetPosition\(\), landing\) > PositionTolerance' -and
    $carousel -match 'DWELL_POSITION_FAILED' -and
    $carousel -match 'dwellGroundDeadline = deadline \+ DwellGroundGraceSeconds' -and
    $carousel -match 'stableSamples < StableSamplesRequired' -and
    $carousel -match 'DWELL_GROUND_FAILED') `
    'dwell bounds position and requires renewed stable ground within grace'
Assert-Carousel ($carousel -match 'StartDelaySeconds = 30f') `
    'preflight allows 30 seconds to enable developer and God mode'
Assert-Carousel ($carousel -match 'Health\(\) \+ 0\.001f < initialHealth' -and
    $carousel -match 'Vector3\.Distance\(player\.GetPosition\(\), origin\) > PositionTolerance' -and
    $carousel -match 'PREFLIGHT_CHANGED') `
    'preflight movement or health loss fails as setup evidence before point testing'
Assert-Carousel ($carousel -notmatch 'RandomRange') 'QA order is deterministic, not random'
Assert-Carousel ($carousel -notmatch 'MarkerStore|TryBeginTraderRoute|SetLocation|RefreshQuest') `
    'carousel does not mutate release markers or trader quests'
Assert-Carousel ($runSource -match 'active-point-ids\.txt' -and
    $runSource -match '\[array\]::IndexOf\(\$pointIds, \$StartPoint\)') `
    'runner resolves stable resume IDs from the generated active list'
Assert-Carousel ($runSource -match '\[string\] \$StartPoint\s*=' -and
    $runSource -match '\[string\] \$EndPoint\s*=' -and
    $runSource -match 'IsNullOrWhiteSpace\(\$StartPoint\)' -and
    $runSource -match 'IsNullOrWhiteSpace\(\$EndPoint\)') `
    'blank bounds default to the first and last active POI'
Assert-Carousel ($runSource -match 'POINTS='' \+ \$pointCount') `
    'runner writes the generated active count into the arm'
Assert-Carousel ($runSource -match 'Saves\\Navezgane') `
    'runner requires the exact existing Navezgane save'
Assert-Carousel ($rejectSource -match 'carousel-rejections\.json' -and
    $rejectSource -match 'Close the game before changing') `
    'rejection helper persists exact IDs only while the game is closed'
Assert-Carousel ($rejectSource -match '\[System\.IO\.File\]::Replace\(\$temp, \$rejectionsPath, \$backup\)' -and
    $rejectSource -notmatch 'Replace\(\$temp, \$rejectionsPath, \$null\)') `
    'rejection helper uses a legal atomic-replacement backup path'
Assert-Carousel ($stopSource -match 'carousel\.stop') `
    'separate emergency-stop helper is present'
Assert-Carousel ($removeSource -match "-cne 'BitWrecked_HRS_QA_Carousel'") `
    'cleanup requires exact QA-only folder identity'
Write-Host 'Full-catalog carousel static contract passed.'
