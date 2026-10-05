[CmdletBinding()]
param(
    [string]$LaneRoot = '',
    [string]$ReportPath = ''
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($LaneRoot)) { $LaneRoot = Join-Path $repository 'hrs_1.3.0_Tech_Demo' }
$LaneRoot = [IO.Path]::GetFullPath($LaneRoot)
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('hrs Tech Demo packaging ' + [guid]::NewGuid().ToString('N'))
$toolRoot = Join-Path $fixture 'tools'
[void][IO.Directory]::CreateDirectory($toolRoot)
$toolNames = @('Export-HrsCandidate.ps1','HrsQaTools.psm1','HrsIdentity.ps1','New-HrsQaWorkspace.ps1',
    'Start-HrsQaRun.ps1','Record-HrsQaObservation.ps1','Export-HrsQaRun.ps1','Complete-HrsQaCycle.ps1','Test-HrsRelease.ps1')
foreach ($name in $toolNames) { [IO.File]::Copy((Join-Path $PSScriptRoot $name),(Join-Path $toolRoot $name),$false) }
Import-Module (Join-Path $toolRoot 'HrsQaTools.psm1') -Force
$checks = New-Object 'Collections.Generic.List[object]'
function Check([bool]$Condition,[string]$Name) {
    if (-not $Condition) { throw "FAIL: $Name" }
    [void]$script:checks.Add([pscustomobject]@{name=$Name;status='Pass'})
    Write-Output "PASS: $Name"
}
function Reject([scriptblock]$Action,[string]$Name,[string]$Reason='') {
    $message = ''
    try { & $Action | Out-Null } catch { $message = $_.Exception.Message }
    Check ([bool]$message -and (-not $Reason -or $message.Contains($Reason))) ($Name + ' [observed: ' + $message + ']')
}
function Has-VersionError($Gate) {
    return @($Gate.findings | Where-Object { $_.severity -ceq 'Error' -and $_.code -ceq 'MANAGER_VERSION' }).Count -eq 1
}
$productionRegistry = Join-Path $PSScriptRoot 'candidate-registry.json'
$productionRegistryBefore = Get-HrsQaSha256 $productionRegistry
$originalPublicZip = Join-Path $PSScriptRoot 'candidates/1.2.7-qa.003.zip'
$originalPublicZipBefore = Get-HrsQaSha256 $originalPublicZip
$production = Read-HrsQaJson (Join-Path $LaneRoot 'dev/qa/rel.json')
$productionCandidateId = [string]$production.candidateId
$productionRecords = Read-HrsQaJson $productionRegistry
Check (@($productionRecords.records | Where-Object { $_.candidateId -ceq $productionCandidateId }).Count -eq 0) 'new production candidate starts unused and unregistered'
Check ($production.version -ceq '1.3.0' -and $production.presentation.edition -ceq 'Tech Demo' -and $production.presentation.managerReleaseLabel -ceq 'Tech Demo | 1.3.0') 'release contract declares the exact Tech Demo edition and version'
$id = '1.3.0-qa.991'
$lane = Join-Path $fixture 'disposable lane'
$copies = @(Get-HrsCustomerFiles -CandidateId $id)
$copies += @($production.sourceSnapshot.sourceHashes | ForEach-Object { 'dev/src/runtime/main/' + $_.path })
$copies += @('dev/qa/rel.json','dev/qa/cases.json',[string]$production.build.recordPath)
$protectedLaneFiles = @(foreach ($relative in $copies | Select-Object -Unique) {
    $source = Resolve-HrsContainedFile $LaneRoot $relative
    $target = Resolve-HrsContainedFile $lane $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    [IO.File]::Copy($source,$target,$false)
    [pscustomobject]@{path=$relative;sha256=Get-HrsQaSha256 $source}
})
$release = Read-HrsQaJson (Join-Path $lane 'dev/qa/rel.json')
$contract = Read-HrsQaJson (Join-Path $lane 'dev/qa/cases.json')
$release.candidateId = $id
$release.build.candidateId = $id
$contract.candidateId = $id
Write-HrsQaJson (Join-Path $lane 'dev/qa/rel.json') $release
Write-HrsQaJson (Join-Path $lane 'dev/qa/cases.json') $contract
$registryPath = Join-Path $toolRoot 'candidate-registry.json'
Write-HrsQaJson $registryPath ([pscustomobject]@{schema='hrs-candidate-registry/v1';records=@()})
$gate = Test-HrsQaRelease $lane
Check ($gate.readyForQa -and $gate.errorCount -eq 0 -and $gate.warningCount -eq 0) 'actual new-edition source release gate passes in a disposable lane'
$inputs = Join-Path $fixture 'minimal synthetic public content'
foreach ($relative in @('START.bat','README.md','START-HERE.md','BUILD-FROM-SOURCE.md','source/README.md','history/README.md','lore/README.md','evidence/README.md')) {
    $target = Resolve-HrsContainedFile $inputs $relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
    $text = if ($relative -ceq 'START.bat') { '@rem SYNTHETIC PACKAGING FIXTURE; never starts a game' } else { 'SYNTHETIC PACKAGING FIXTURE ONLY; no customer qualification or publication.' }
    [IO.File]::WriteAllText($target,$text,(New-Object Text.UTF8Encoding($false)))
}
$license = Join-Path $inputs 'release_templates/LICENSE-GPL-3.0-or-later.txt'
[void][IO.Directory]::CreateDirectory((Split-Path -Parent $license))
[IO.File]::Copy((Join-Path $repository 'archive/bit_wrecked_mod_framework_template/release_templates/LICENSE-GPL-3.0-or-later.txt'),$license,$false)
$exporter = Join-Path $toolRoot 'Export-HrsCandidate.ps1'
$releasePath = Join-Path $lane 'dev/qa/rel.json'
$savedRelease = [IO.File]::ReadAllBytes($releasePath)
$managerPath = Join-Path $lane 'dev/ui/p0158.ps1'
$savedManager = [IO.File]::ReadAllBytes($managerPath)
$invalidOutput = Join-Path $fixture 'rejected-edition.zip'
foreach ($scenario in @('WrongEdition','WrongVersionLabel','LegacyQaManagerLabel','DuplicateVisibleLabel')) {
    [IO.File]::WriteAllBytes($releasePath,$savedRelease)
    [IO.File]::WriteAllBytes($managerPath,$savedManager)
    $changedRelease = Read-HrsQaJson $releasePath
    if ($scenario -ceq 'WrongEdition') {
        $changedRelease.presentation.edition = 'Preview'
        Write-HrsQaJson $releasePath $changedRelease
    } elseif ($scenario -ceq 'WrongVersionLabel') {
        $changedRelease.presentation.managerReleaseLabel = 'Tech Demo | 1.2.7'
        Write-HrsQaJson $releasePath $changedRelease
    } elseif ($scenario -ceq 'LegacyQaManagerLabel') {
        $text = [IO.File]::ReadAllText($managerPath).Replace("`$version.Text = 'Tech Demo | 1.3.0'","`$version.Text = 'Release | 1.3.0 QA'")
        [IO.File]::WriteAllText($managerPath,$text,(New-Object Text.UTF8Encoding($false)))
    } else {
        [IO.File]::AppendAllText($managerPath,"`r`n`$version.Text = 'Tech Demo | 1.3.0'`r`n",(New-Object Text.UTF8Encoding($false)))
    }
    $badGate = Test-HrsQaRelease $lane
    Check ((-not $badGate.readyForQa) -and (Has-VersionError $badGate)) ("gate rejects $scenario")
    Reject { & $exporter -LaneRoot $lane -CandidateId $id -OutputPath $invalidOutput -PublicContentRoot $inputs } ("exporter rejects $scenario before candidate reservation") 'HRS_RELEASE_NOT_READY_FOR_EXPORT'
    Check (@((Read-HrsQaJson $registryPath).records).Count -eq 0 -and -not (Test-Path -LiteralPath $invalidOutput) -and -not (Test-Path -LiteralPath ($invalidOutput+'.stage'))) ("$scenario leaves no reserved identity or export tree")
}
[IO.File]::WriteAllBytes($releasePath,$savedRelease)
[IO.File]::WriteAllBytes($managerPath,$savedManager)
$archivePath = Join-Path $fixture 'synthetic-Tech-Demo-complete.zip'
& $exporter -LaneRoot $lane -CandidateId $id -OutputPath $archivePath -PublicContentRoot $inputs | Out-Null
$registered = Get-HrsRegistryRecord $id
$identity = Test-HrsCandidateArchive $archivePath $id $registered.releaseRecordSha256 $registered.contractSha256
Check ($identity.valid -and $identity.receipt.distributionFormat -ceq 'unified-public/v1') 'actual exporter creates one registered complete Tech Demo archive'
Check (-not (Test-Path -LiteralPath ($archivePath+'.companion.zip'))) 'Tech Demo export requires no public companion or wrapper ZIP'
$archiveHash = Get-HrsQaSha256 $archivePath
$archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    $managerEntry = @($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -ceq 'customer/HistoricalRandomStart_1.3.0/dev/ui/p0158.ps1' })
    Check ($managerEntry.Count -eq 1) 'archive contains exactly one owned customer manager'
    $reader = New-Object IO.StreamReader($managerEntry[0].Open())
    try { $customerManager = $reader.ReadToEnd() } finally { $reader.Dispose() }
    $expectedVisibleAssignment = '$version.Text = ''Tech Demo | 1.3.0'''
    Check (@([regex]::Matches($customerManager,'(?m)^'+[regex]::Escape($expectedVisibleAssignment)+'\r?$')).Count -eq 1) 'exported visible edition is exactly Tech Demo | 1.3.0'
    Check (-not ($customerManager -match 'Release \| 1\.3\.0 (DEV|QA)')) 'customer edition contains no DEV or QA release label'
    Check (@([regex]::Matches($customerManager,'(?m)^\$useDevCandidate = \$false\r?$')).Count -eq 1 -and -not ($customerManager -match '(?m)^\$useDevCandidate = \$true\r?$')) 'exported manager uses customer payload mode exactly once'
    foreach ($relative in @('START.bat','source/README.md','history/README.md','lore/README.md','evidence/README.md')) {
        Check (@($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -ceq $relative }).Count -eq 1) ("single archive includes $relative")
    }
} finally { $archive.Dispose() }
$standaloneTools = Join-Path $fixture 'standalone tools without registry'
[void][IO.Directory]::CreateDirectory($standaloneTools)
foreach ($name in @('HrsQaTools.psm1','HrsIdentity.ps1','New-HrsQaWorkspace.ps1')) { [IO.File]::Copy((Join-Path $toolRoot $name),(Join-Path $standaloneTools $name),$false) }
$workspace = Join-Path $fixture 'standalone Tech Demo workspace'
& (Join-Path $standaloneTools 'New-HrsQaWorkspace.ps1') -CandidateId $id -ArchivePath $archivePath -Destination $workspace -ExpectedArchiveSha256 $archiveHash | Out-Null
$workspaceArchive = Join-Path $workspace ($id+'.zip')
Check ((Get-HrsQaSha256 $workspaceArchive) -ceq $archiveHash) 'standalone own-checksum bootstrap retains exact complete archive bytes'
Check ((Get-HrsQaSha256 ($workspaceArchive+'.receipt.json')) -ceq (Get-HrsQaSha256 ($archivePath+'.receipt.json'))) 'standalone reconstructed receipt equals exporter receipt'
Import-Module (Join-Path $workspace 'tools/HrsQaTools.psm1') -Force
[void](Assert-HrsWorkspace $workspace $workspaceArchive)
Check $true 'workspace validates from its own packaged edition-aware tools'
$workspaceGate = Test-HrsQaRelease (Join-Path $workspace 'context')
Check ($workspaceGate.readyForQa -and $workspaceGate.errorCount -eq 0 -and $workspaceGate.warningCount -eq 0) 'own packaged release gate accepts customer-mode Tech Demo manager'
Check ((Get-HrsQaSha256 $productionRegistry) -ceq $productionRegistryBefore) 'production candidate registry is unchanged'
$productionRecordsAfter = Read-HrsQaJson $productionRegistry
Check (@($productionRecordsAfter.records | Where-Object { $_.candidateId -ceq $productionCandidateId }).Count -eq 0) 'production candidate remains unused and unregistered'
Check ((Get-HrsQaSha256 $originalPublicZip) -ceq $originalPublicZipBefore) 'frozen original public qa.003 archive is unchanged'
Check (@($protectedLaneFiles | Where-Object { (Get-HrsQaSha256 (Resolve-HrsContainedFile $LaneRoot $_.path)) -cne $_.sha256 }).Count -eq 0) 'all actual lane inputs copied by this fixture remain unchanged'
if ($ReportPath) {
    Write-HrsQaJson $ReportPath ([pscustomobject][ordered]@{
        schema='hrs-tech-demo-packaging-verification/v1';status='Pass';passed=$checks.Count;checks=$checks.ToArray()
        verifiedUtc=[datetime]::UtcNow.ToString('o');fixture=$fixture;candidateId=$id;archiveSha256=$archiveHash
        productionCandidateId=$productionCandidateId;productionRegistrySha256=$productionRegistryBefore
        productionLaneInputHashes=$protectedLaneFiles
        scope='Disposable software packaging fixtures only. No installed game writes, gameplay, human customer acceptance, real candidate export, publication or commit.'
        sourceHashes=@($toolNames + @('Test-HrsTechDemoPackaging.ps1') | ForEach-Object { [pscustomobject]@{path=$_;sha256=Get-HrsQaSha256 (Join-Path $PSScriptRoot $_)} })
    })
}
Write-Output "Tech Demo packaging checks passed: $($checks.Count)/$($checks.Count)"
Write-Output "Disposable fixture: $fixture"
