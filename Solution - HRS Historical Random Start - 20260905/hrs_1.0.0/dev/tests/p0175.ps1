$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'm0206.psm1') -Force

$before = Get-Content (Join-Path $PSScriptRoot 'fixtures\j0204.json') -Raw | ConvertFrom-Json
$after = Get-Content (Join-Path $PSScriptRoot 'fixtures\j0203.json') -Raw | ConvertFrom-Json
$pass = 0
$fail = 0

function Assert-Case([string] $id, [bool] $actual, [bool] $expected) {
    if ($actual -eq $expected) { Write-Output "PASS $id"; $script:pass++ }
    else { Write-Output "FAIL $id"; $script:fail++ }
}

$result = Compare-Phase1ASemanticSnapshots -Before $before -After $after -SanitizedReasons @(
    'RELOC_READY', 'RELOC_PLACEMENT_CALLED', 'RELOC_SEMANTIC_UNCHANGED', 'RELOC_COMPLETED')
Assert-Case 'P1A-S01-complete-equal-protected-pass' $result.pass $true

$result = Compare-Phase1ASemanticSnapshots -Before $before -After $after -SanitizedReasons @(
    'RELOC_READY', 'RELOC_PLACEMENT_CALLED', 'RELOC_COMPLETED')
Assert-Case 'P1A-S02-missing-runtime-semantic-fails' $result.pass $false

$changed = Get-Content (Join-Path $PSScriptRoot 'fixtures\j0203.json') -Raw | ConvertFrom-Json
$changed.foreignMods.sha256 = 'CHANGED'
$result = Compare-Phase1ASemanticSnapshots -Before $before -After $changed -SanitizedReasons @(
    'RELOC_SEMANTIC_UNCHANGED', 'RELOC_COMPLETED')
Assert-Case 'P1A-S03-foreign-mod-change-fails' $result.pass $false

$result = Compare-Phase1ASemanticSnapshots -Before $before -After $after -SanitizedReasons @(
    'RELOC_SEMANTIC_UNCHANGED', 'RELOC_COMPLETED', 'RELOC_INTERNAL_FAILURE')
Assert-Case 'P1A-S04-failure-reason-fails' $result.pass $false

$fixtureRoot = Join-Path $PSScriptRoot 'fixtures'
$digestOne = Get-Phase1ATreeDigest -Root $fixtureRoot -ExcludedRelativePrefixes @('j0197.json')
$digestTwo = Get-Phase1ATreeDigest -Root $fixtureRoot -ExcludedRelativePrefixes @('j0197.json')
Assert-Case 'P1A-S05-tree-digest-deterministic' ($digestOne.sha256 -eq $digestTwo.sha256) $true

$allDigest = Get-Phase1ATreeDigest -Root $fixtureRoot
Assert-Case 'P1A-S06-prefix-exclusion-reduces-files' ($digestOne.files -lt $allDigest.files) $true

$missing = Get-Phase1ATreeDigest -Root (Join-Path $fixtureRoot 'does-not-exist')
Assert-Case 'P1A-S07-missing-tree-is-absent' (-not $missing.present) $true

Write-Output "PHASE1A_SEMANTIC_SUMMARY pass=$pass fail=$fail"
if ($fail -gt 0) { exit 1 }
