[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$testRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixtureRoot = Join-Path $testRoot 'fixtures'
$modulePath = Join-Path $testRoot 'Phase0A.ContractModel.psm1'
$decisionFixturePath = Join-Path $fixtureRoot 'phase0a_core_decision_cases.json'
$targetSchemaPath = Join-Path $fixtureRoot 'phase1_target_allowlist.schema.json'
$targetExamplePath = Join-Path $fixtureRoot 'phase1_target_allowlist.valid.example.json'
$ownerLabTargetExamplePath = Join-Path $fixtureRoot 'phase1_target_allowlist.owner_designated_live.valid.example.json'

Import-Module -Name $modulePath -Force

$failureCount = 0
$passCount = 0

function Write-TestPass {
    param([string] $Id)
    $script:passCount++
    Write-Output "PASS $Id"
}

function Write-TestFailure {
    param([string] $Id, [string] $Message)
    $script:failureCount++
    Write-Output "FAIL $Id :: $Message"
}

function Convert-PropertiesToHashtable {
    param([psobject] $Value)
    $table = @{}
    foreach ($property in $Value.PSObject.Properties) {
        $table[$property.Name] = $property.Value
    }
    return $table
}

function Copy-JsonObject {
    param([psobject] $Value)
    return ($Value | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
}

# Parsing both JSON documents is itself a required fixture sanity check.
try {
    $null = Get-Content -LiteralPath $targetSchemaPath -Raw | ConvertFrom-Json
    Write-TestPass -Id 'FIXTURE-001-target-schema-json-parses'
}
catch {
    Write-TestFailure -Id 'FIXTURE-001-target-schema-json-parses' -Message $_.Exception.GetType().Name
}

try {
    $null = Get-Content -LiteralPath $ownerLabTargetExamplePath -Raw | ConvertFrom-Json
    Write-TestPass -Id 'FIXTURE-002-owner-lab-example-json-parses'
}
catch {
    Write-TestFailure -Id 'FIXTURE-002-owner-lab-example-json-parses' -Message $_.Exception.GetType().Name
}

$suite = Get-Content -LiteralPath $decisionFixturePath -Raw | ConvertFrom-Json
if ([int] $suite.schemaVersion -ne 1) {
    throw 'Unsupported decision fixture schema.'
}

$defaults = Convert-PropertiesToHashtable -Value $suite.defaults
foreach ($testCase in $suite.cases) {
    $scenarioTable = @{}
    foreach ($key in $defaults.Keys) {
        $scenarioTable[$key] = $defaults[$key]
    }
    foreach ($property in $testCase.set.PSObject.Properties) {
        $scenarioTable[$property.Name] = $property.Value
    }

    $actual = Get-Alpha6CoreDecision -Scenario ([pscustomobject] $scenarioTable)
    $caseFailed = $false
    foreach ($expectedProperty in $testCase.expected.PSObject.Properties) {
        $actualProperty = $actual.PSObject.Properties[$expectedProperty.Name]
        if ($null -eq $actualProperty) {
            Write-TestFailure -Id $testCase.id -Message "missing result field $($expectedProperty.Name)"
            $caseFailed = $true
            break
        }
        if ($actualProperty.Value -ne $expectedProperty.Value) {
            Write-TestFailure -Id $testCase.id -Message "$($expectedProperty.Name) expected '$($expectedProperty.Value)' actual '$($actualProperty.Value)'"
            $caseFailed = $true
            break
        }
    }

    if (-not $caseFailed) {
        foreach ($counterName in @('ReservationWrites', 'SelectionAttempts', 'PlacementAttempts', 'CompletionWrites')) {
            if ([int] $actual.$counterName -lt 0 -or [int] $actual.$counterName -gt 1) {
                Write-TestFailure -Id $testCase.id -Message "$counterName exceeded the one-attempt core bound"
                $caseFailed = $true
                break
            }
        }
    }
    if (-not $caseFailed -and [int] $actual.ForbiddenSideEffects -ne 0) {
        Write-TestFailure -Id $testCase.id -Message 'pure model reported a forbidden side effect'
        $caseFailed = $true
    }
    if (-not $caseFailed) {
        Write-TestPass -Id $testCase.id
    }
}

$validTarget = Get-Content -LiteralPath $targetExamplePath -Raw | ConvertFrom-Json
$expectedFingerprint = Copy-JsonObject -Value $validTarget.expectedFingerprint
$fictionalLiveRoot = 'C:\Games\7DaysToDieLive'

$targetCases = @(
    @{ Id = 'TARGET-001-valid-fictional-example'; Reason = 'TARGET_OK'; Mutate = { param($record) } },
    @{ Id = 'TARGET-002-unknown-player-id-field'; Reason = 'TARGET_SCHEMA_UNKNOWN_FIELD'; Mutate = { param($record) $record | Add-Member -NotePropertyName 'playerId' -NotePropertyValue 'forbidden' } },
    @{ Id = 'TARGET-003-missing-backup'; Reason = 'TARGET_SCHEMA_MISSING_FIELD'; Mutate = { param($record) $record.PSObject.Properties.Remove('backup') } },
    @{ Id = 'TARGET-004-stage-under-live-root'; Reason = 'TARGET_INSIDE_LIVE_ROOT'; Mutate = { param($record) $record.gameRootCanonical = 'C:\Games\7DaysToDieLive\Stage' } },
    @{ Id = 'TARGET-005-unc-path'; Reason = 'TARGET_PATH_UNC'; Mutate = { param($record) $record.saveRootCanonical = '\\server\share\Saves' } },
    @{ Id = 'TARGET-006-parent-traversal'; Reason = 'TARGET_PATH_INVALID'; Mutate = { param($record) $record.gameRootCanonical = 'D:\BitWreckedDisposable\..\Escape' } },
    @{ Id = 'TARGET-007-eac-enabled'; Reason = 'TARGET_EAC_NOT_DISABLED'; Mutate = { param($record) $record.eacState = 'Enabled' } },
    @{ Id = 'TARGET-008-dedicated-not-first-lane'; Reason = 'TARGET_EXECUTION_NOT_FIRST_LANE'; Mutate = { param($record) $record.executionType = 'DedicatedServer' } },
    @{ Id = 'TARGET-009-fingerprint-mismatch'; Reason = 'TARGET_FINGERPRINT_MISMATCH'; Mutate = { param($record) $record.expectedFingerprint.steamBuildId = '0' } },
    @{ Id = 'TARGET-010-path-like-world-name'; Reason = 'TARGET_NAME_INVALID'; Mutate = { param($record) $record.worldName = '..\OtherWorld' } },
    @{ Id = 'TARGET-011-backup-not-recoverable'; Reason = 'TARGET_BACKUP_INVALID'; Mutate = { param($record) $record.backup.recoverable = $false } },
    @{ Id = 'TARGET-012-backup-inside-stage'; Reason = 'TARGET_BACKUP_NOT_SEPARATE'; Mutate = { param($record) $record.backup.backupRootCanonical = 'D:\BitWreckedDisposable\HRS_Phase1\Game\Backup' } },
    @{ Id = 'TARGET-013-invalid-utc'; Reason = 'TARGET_TIMESTAMP_INVALID'; Mutate = { param($record) $record.expiresUtc = 'not-a-time' } }
)

foreach ($targetCase in $targetCases) {
    $record = Copy-JsonObject -Value $validTarget
    & $targetCase.Mutate $record
    $targetResult = Test-Phase1TargetRecord -Record $record -LiveGameRoot $fictionalLiveRoot -ExpectedFingerprint $expectedFingerprint
    if ([string] $targetResult.Reason -ne [string] $targetCase.Reason) {
        Write-TestFailure -Id $targetCase.Id -Message "expected '$($targetCase.Reason)' actual '$($targetResult.Reason)'"
    }
    else {
        Write-TestPass -Id $targetCase.Id
    }
}

$ownerLabTarget = Get-Content -LiteralPath $ownerLabTargetExamplePath -Raw | ConvertFrom-Json
$ownerLabCases = @(
    @{ Id = 'TARGET-LAB-001-valid-owner-designated-live-install'; Reason = 'TARGET_OK'; Mutate = { param($record) } },
    @{ Id = 'TARGET-LAB-002-owner-approval-required'; Reason = 'TARGET_OWNER_APPROVAL_REQUIRED'; Mutate = { param($record) $record.PSObject.Properties.Remove('ownerApproval') } },
    @{ Id = 'TARGET-LAB-003-ordinary-class-cannot-use-live-root'; Reason = 'TARGET_INSIDE_LIVE_ROOT'; Mutate = { param($record) $record.deploymentClass = 'DisposableStagedCopy'; $record.PSObject.Properties.Remove('ownerApproval') } },
    @{ Id = 'TARGET-LAB-004-owner-root-must-exactly-match'; Reason = 'TARGET_OWNER_LAB_ROOT_MISMATCH'; Mutate = { param($record) $record.gameRootCanonical = 'E:\OtherGame' } },
    @{ Id = 'TARGET-LAB-005-owner-protection-cannot-be-disabled'; Reason = 'TARGET_OWNER_APPROVAL_INVALID'; Mutate = { param($record) $record.ownerApproval.protectExistingMods = $false } },
    @{ Id = 'TARGET-LAB-006-owned-folder-name-is-fixed'; Reason = 'TARGET_OWNER_APPROVAL_INVALID'; Mutate = { param($record) $record.ownerApproval.ownedModFolderName = 'SomeOtherMod' } },
    @{ Id = 'TARGET-LAB-007-build-stage-stays-outside-live-root'; Reason = 'TARGET_BUILD_STAGE_NOT_SEPARATE'; Mutate = { param($record) $record.buildStageRootCanonical = 'C:\Games\7DaysToDieLive\Build' } },
    @{ Id = 'TARGET-LAB-008-build-stage-cannot-contain-live-root'; Reason = 'TARGET_BUILD_STAGE_NOT_SEPARATE'; Mutate = { param($record) $record.buildStageRootCanonical = 'C:\Games' } }
)

foreach ($ownerLabCase in $ownerLabCases) {
    $record = Copy-JsonObject -Value $ownerLabTarget
    & $ownerLabCase.Mutate $record
    $targetResult = Test-Phase1TargetRecord -Record $record -LiveGameRoot $fictionalLiveRoot -ExpectedFingerprint $expectedFingerprint
    if ([string] $targetResult.Reason -ne [string] $ownerLabCase.Reason) {
        Write-TestFailure -Id $ownerLabCase.Id -Message "expected '$($ownerLabCase.Reason)' actual '$($targetResult.Reason)'"
    }
    else {
        Write-TestPass -Id $ownerLabCase.Id
    }
}

$stagedWithOwnerApproval = Copy-JsonObject -Value $validTarget
$stagedWithOwnerApproval | Add-Member -NotePropertyName 'ownerApproval' -NotePropertyValue (Copy-JsonObject -Value $ownerLabTarget.ownerApproval)
$stagedOwnerResult = Test-Phase1TargetRecord -Record $stagedWithOwnerApproval -LiveGameRoot $fictionalLiveRoot -ExpectedFingerprint $expectedFingerprint
if ([string] $stagedOwnerResult.Reason -ne 'TARGET_OWNER_APPROVAL_UNEXPECTED') {
    Write-TestFailure -Id 'TARGET-LAB-009-staged-class-rejects-owner-exception' -Message "expected 'TARGET_OWNER_APPROVAL_UNEXPECTED' actual '$($stagedOwnerResult.Reason)'"
}
else {
    Write-TestPass -Id 'TARGET-LAB-009-staged-class-rejects-owner-exception'
}

Write-Output "SUMMARY pass=$passCount fail=$failureCount"
if ($failureCount -gt 0) {
    exit 1
}

exit 0
