[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$testRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $testRoot
$modulePath = Join-Path $projectRoot 'src\launcher\HistoricalRandomStart.Core.psm1'

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw "Alpha Core module is missing: $modulePath"
}

Import-Module -Name $modulePath -Force

$script:PassCount = 0
$script:FailCount = 0
$script:SkipCount = 0
$script:FailureDetails = New-Object System.Collections.Generic.List[string]

function Assert-HrsTrue {
    param(
        [Parameter(Mandatory = $true)] [bool] $Condition,
        [Parameter(Mandatory = $true)] [string] $Message
    )

    if (-not $Condition) { throw $Message }
}

function Assert-HrsFalse {
    param(
        [Parameter(Mandatory = $true)] [bool] $Condition,
        [Parameter(Mandatory = $true)] [string] $Message
    )

    if ($Condition) { throw $Message }
}

function Assert-HrsEqual {
    param(
        $Actual,
        $Expected,
        [Parameter(Mandatory = $true)] [string] $Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message Expected '$Expected'; actual '$Actual'."
    }
}

function Assert-HrsThrows {
    param(
        [Parameter(Mandatory = $true)] [scriptblock] $Action,
        [string] $ExpectedMessage = ''
    )

    $caught = $null
    try {
        $null = & $Action
    }
    catch {
        $caught = $_
    }

    if ($null -eq $caught) {
        throw 'Expected an exception, but the operation succeeded.'
    }
    if (-not [string]::IsNullOrEmpty($ExpectedMessage) -and
        $caught.Exception.Message.IndexOf($ExpectedMessage, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "Expected exception containing '$ExpectedMessage'; actual '$($caught.Exception.Message)'."
    }
}

function Invoke-HrsContractCase {
    param(
        [Parameter(Mandatory = $true)] [string] $Id,
        [Parameter(Mandatory = $true)] [scriptblock] $Test
    )

    try {
        & $Test
        $script:PassCount++
        Write-Output "PASS $Id"
    }
    catch {
        $script:FailCount++
        $detail = "FAIL $Id :: $($_.Exception.Message)"
        [void] $script:FailureDetails.Add($detail)
        Write-Output $detail
    }
}

function Write-HrsContractSkip {
    param(
        [Parameter(Mandatory = $true)] [string] $Id,
        [Parameter(Mandatory = $true)] [string] $Reason
    )

    $script:SkipCount++
    Write-Output "SKIP $Id :: $Reason"
}

function Copy-HrsJsonObject {
    param([Parameter(Mandatory = $true)] [psobject] $Value)

    # ConvertFrom-Json changed ISO timestamp inference between Windows
    # PowerShell 5.1 and PowerShell 7. Preserve the exact property values so
    # hostile-object tests exercise the module rather than a host conversion.
    $copy = [ordered]@{}
    foreach ($property in $Value.PSObject.Properties) {
        $copy[$property.Name] = $property.Value
    }
    return [pscustomobject] $copy
}

function Write-HrsTestText {
    param(
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter(Mandatory = $true)] [AllowEmptyString()] [string] $Text
    )

    $encoding = New-Object System.Text.UTF8Encoding($false, $true)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

function New-HrsFakeGameRoot {
    param([Parameter(Mandatory = $true)] [string] $Path)

    [void] [System.IO.Directory]::CreateDirectory($Path)
    [System.IO.File]::WriteAllBytes((Join-Path $Path '7DaysToDie.exe'), [byte[]]@(0))
    return $Path
}

function Test-HrsNoUtf8Bom {
    param([Parameter(Mandatory = $true)] [string] $Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    return -not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
}

$fixtureParent = Join-Path $projectRoot '_t'
$fixtureLeaf = [guid]::NewGuid().ToString('N').Substring(0, 8)
$fixtureRoot = Join-Path $fixtureParent $fixtureLeaf
[void] [System.IO.Directory]::CreateDirectory($fixtureRoot)
$script:CreatedReparsePaths = New-Object System.Collections.Generic.List[string]

try {
    $fixedUtc = [datetime]::SpecifyKind([datetime]'2026-08-21T12:34:56.789', [System.DateTimeKind]::Utc)

    # Exact-name contract
    Invoke-HrsContractCase 'NAME-001-simple-valid' {
        $actual = Test-HrsExactGameName -GameName 'HRS Alpha 01'
        Assert-HrsTrue $actual.Valid 'A simple exact game name was rejected.'
        Assert-HrsEqual $actual.Canonical 'HRS Alpha 01' 'The valid name changed.'
    }
    Invoke-HrsContractCase 'NAME-002-composed-unicode-valid' {
        $actual = Test-HrsExactGameName -GameName "Caf$([char]0x00E9) Alpha"
        Assert-HrsTrue $actual.Valid 'An NFC-composed name was rejected.'
    }
    Invoke-HrsContractCase 'NAME-003-blank-rejected' {
        Assert-HrsEqual (Test-HrsExactGameName -GameName '').Reason 'GAME_NAME_REQUIRED' 'Blank-name rejection differed.'
        Assert-HrsEqual (Test-HrsExactGameName -GameName '   ').Reason 'GAME_NAME_REQUIRED' 'Whitespace-only rejection differed.'
    }
    Invoke-HrsContractCase 'NAME-004-outer-whitespace-rejected' {
        Assert-HrsEqual (Test-HrsExactGameName -GameName ' Alpha').Reason 'GAME_NAME_OUTER_WHITESPACE' 'Leading whitespace was not rejected precisely.'
        Assert-HrsEqual (Test-HrsExactGameName -GameName 'Alpha ').Reason 'GAME_NAME_OUTER_WHITESPACE' 'Trailing whitespace was not rejected precisely.'
    }
    Invoke-HrsContractCase 'NAME-005-length-boundary' {
        Assert-HrsTrue (Test-HrsExactGameName -GameName ('A' * 64)).Valid 'A 64-character name was rejected.'
        Assert-HrsEqual (Test-HrsExactGameName -GameName ('A' * 65)).Reason 'GAME_NAME_TOO_LONG' 'A 65-character name was not rejected.'
    }
    Invoke-HrsContractCase 'NAME-006-path-and-control-characters-rejected' {
        Assert-HrsEqual (Test-HrsExactGameName -GameName 'Alpha/Other').Reason 'GAME_NAME_INVALID_CHARACTER' 'A path separator was accepted.'
        Assert-HrsEqual (Test-HrsExactGameName -GameName "Alpha`nOther").Reason 'GAME_NAME_INVALID_CHARACTER' 'A control character was accepted.'
    }
    Invoke-HrsContractCase 'NAME-007-dot-names-rejected' {
        Assert-HrsEqual (Test-HrsExactGameName -GameName '.').Reason 'GAME_NAME_RESERVED' 'Dot was accepted.'
        Assert-HrsEqual (Test-HrsExactGameName -GameName '..').Reason 'GAME_NAME_RESERVED' 'Dot-dot was accepted.'
    }
    Invoke-HrsContractCase 'NAME-008-noncanonical-unicode-rejected' {
        $decomposed = "Cafe$([char]0x0301)"
        $actual = Test-HrsExactGameName -GameName $decomposed
        Assert-HrsEqual $actual.Reason 'GAME_NAME_NONCANONICAL' 'A decomposed Unicode name was accepted.'
        Assert-HrsEqual $actual.Canonical "Caf$([char]0x00E9)" 'The recommended canonical name differed.'
    }
    Invoke-HrsContractCase 'NAME-009-trailing-dot-rejected' {
        $actual = Test-HrsExactGameName -GameName 'Alpha.'
        Assert-HrsFalse $actual.Valid 'A Windows-ambiguous trailing-dot name was accepted.'
    }
    Invoke-HrsContractCase 'NAME-010-device-name-rejected' {
        $actual = Test-HrsExactGameName -GameName 'CON'
        Assert-HrsFalse $actual.Valid 'A reserved Windows device name was accepted.'
    }

    # Policy construction, canonical representation, hostile shapes, and digest
    $standardPolicy = New-HrsPolicy -Revision 1 -GameName 'HRS Alpha 01' -Mode Standard -WrittenUtc $fixedUtc
    $randomPolicy = New-HrsPolicy -Revision 2 -GameName 'HRS Alpha 01' -Mode Random -WrittenUtc $fixedUtc
    $standardJson = ConvertTo-HrsPolicyJson -Policy $standardPolicy
    $randomJson = ConvertTo-HrsPolicyJson -Policy $randomPolicy

    Invoke-HrsContractCase 'POLICY-001-standard-construction' {
        Assert-HrsEqual $standardPolicy.schema 'hrs-policy/v1' 'Policy schema differed.'
        Assert-HrsEqual $standardPolicy.revision ([UInt64]1) 'Policy revision differed.'
        Assert-HrsFalse $standardPolicy.enabled 'Standard unexpectedly enabled custom behavior.'
        Assert-HrsEqual $standardPolicy.writtenUtc '2026-08-21T12:34:56.789Z' 'Policy timestamp was not canonical UTC.'
        Assert-HrsTrue ($standardPolicy.policyDigest -match '^[0-9A-F]{64}$') 'Policy digest was not uppercase SHA-256.'
    }
    Invoke-HrsContractCase 'POLICY-002-random-construction' {
        Assert-HrsTrue $randomPolicy.enabled 'Random was not enabled.'
        Assert-HrsEqual $randomPolicy.mode 'Random' 'Random mode differed.'
    }
    Invoke-HrsContractCase 'POLICY-003-revision-zero-rejected' {
        Assert-HrsThrows { New-HrsPolicy -Revision 0 -GameName 'HRS Alpha 01' -Mode Standard -WrittenUtc $fixedUtc } 'at least 1'
    }
    Invoke-HrsContractCase 'POLICY-004-canonical-json-deterministic' {
        $again = ConvertTo-HrsPolicyJson -Policy (New-HrsPolicy -Revision 1 -GameName 'HRS Alpha 01' -Mode Standard -WrittenUtc $fixedUtc)
        Assert-HrsEqual $again $standardJson 'The same policy produced different canonical bytes.'
        Assert-HrsTrue ($standardJson -match '^\{"schema":"hrs-policy/v1","revision":1,"gameName":"HRS Alpha 01","mode":"Standard","enabled":false,"writtenUtc":"2026-08-21T12:34:56\.789Z","policyDigest":"[0-9A-F]{64}"\}$') 'Canonical field order or compact encoding differed.'
    }
    Invoke-HrsContractCase 'POLICY-005-roundtrip' {
        $parsed = ConvertFrom-HrsPolicyJson -Json $randomJson
        Assert-HrsEqual (ConvertTo-HrsPolicyJson -Policy $parsed) $randomJson 'Policy roundtrip changed canonical JSON.'
    }
    Invoke-HrsContractCase 'POLICY-006-digest-controls-fields' {
        Assert-HrsFalse ($standardPolicy.policyDigest -eq $randomPolicy.policyDigest) 'Controlling field changes did not change the digest.'
        $differentName = New-HrsPolicy -Revision 1 -GameName 'HRS Alpha 02' -Mode Standard -WrittenUtc $fixedUtc
        Assert-HrsFalse ($standardPolicy.policyDigest -eq $differentName.policyDigest) 'Game-name changes did not change the digest.'
        $differentTime = New-HrsPolicy -Revision 1 -GameName 'HRS Alpha 01' -Mode Standard -WrittenUtc $fixedUtc.AddSeconds(1)
        Assert-HrsFalse ($standardPolicy.policyDigest -eq $differentTime.policyDigest) 'Timestamp changes did not change the digest.'
    }
    Invoke-HrsContractCase 'POLICY-007-object-extra-field-rejected' {
        $changed = Copy-HrsJsonObject $standardPolicy
        $changed | Add-Member -NotePropertyName command -NotePropertyValue 'MOVE'
        $actual = Test-HrsPolicyObject -Policy $changed
        Assert-HrsFalse $actual.Valid 'An extra policy command field was accepted.'
    }
    Invoke-HrsContractCase 'POLICY-008-object-field-case-rejected' {
        $changed = [pscustomobject][ordered]@{
            Schema = $standardPolicy.schema
            revision = $standardPolicy.revision
            gameName = $standardPolicy.gameName
            mode = $standardPolicy.mode
            enabled = $standardPolicy.enabled
            writtenUtc = $standardPolicy.writtenUtc
            policyDigest = $standardPolicy.policyDigest
        }
        Assert-HrsFalse (Test-HrsPolicyObject -Policy $changed).Valid 'A case-variant field name was accepted as canonical.'
    }
    Invoke-HrsContractCase 'POLICY-009-object-revision-type-rejected' {
        $changed = Copy-HrsJsonObject $standardPolicy
        $changed.revision = '1'
        Assert-HrsFalse (Test-HrsPolicyObject -Policy $changed).Valid 'A string revision was accepted by the strict object validator.'
    }
    Invoke-HrsContractCase 'POLICY-010-mode-enabled-mismatch-rejected' {
        $changed = Copy-HrsJsonObject $standardPolicy
        $changed.enabled = $true
        Assert-HrsEqual (Test-HrsPolicyObject -Policy $changed).Reason 'POLICY_MODE_ENABLED_MISMATCH' 'Standard/enabled mismatch was not identified.'
    }
    Invoke-HrsContractCase 'POLICY-011-digest-mismatch-rejected' {
        $changed = Copy-HrsJsonObject $standardPolicy
        $changed.policyDigest = 'A' * 64
        Assert-HrsEqual (Test-HrsPolicyObject -Policy $changed).Reason 'POLICY_DIGEST_MISMATCH' 'Digest mismatch was not identified.'
    }
    Invoke-HrsContractCase 'POLICY-012-timestamp-rejected' {
        $changed = Copy-HrsJsonObject $standardPolicy
        $changed.writtenUtc = '2026-08-21 12:34:56Z'
        Assert-HrsEqual (Test-HrsPolicyObject -Policy $changed).Reason 'POLICY_TIMESTAMP' 'A noncanonical timestamp was accepted.'
    }
    Invoke-HrsContractCase 'POLICY-013-reordered-json-rejected' {
        $hostile = '{"revision":1,"schema":"hrs-policy/v1","gameName":"HRS Alpha 01","mode":"Standard","enabled":false,"writtenUtc":"2026-08-21T12:34:56.789Z","policyDigest":"' + $standardPolicy.policyDigest + '"}'
        Assert-HrsThrows { ConvertFrom-HrsPolicyJson -Json $hostile } 'POLICY_JSON_SHAPE'
    }
    Invoke-HrsContractCase 'POLICY-014-duplicate-key-rejected' {
        $hostile = $standardJson.Substring(0, $standardJson.Length - 1) + ',"mode":"Random"}'
        Assert-HrsThrows { ConvertFrom-HrsPolicyJson -Json $hostile } 'POLICY_JSON_SHAPE'
    }
    Invoke-HrsContractCase 'POLICY-015-extra-command-key-rejected' {
        $hostile = $standardJson.Substring(0, $standardJson.Length - 1) + ',"command":"MOVE"}'
        Assert-HrsThrows { ConvertFrom-HrsPolicyJson -Json $hostile } 'POLICY_JSON_SHAPE'
    }
    Invoke-HrsContractCase 'POLICY-016-string-and-fractional-revisions-rejected' {
        Assert-HrsThrows { ConvertFrom-HrsPolicyJson -Json ($standardJson -replace '"revision":1', '"revision":"1"') } 'POLICY_JSON_SHAPE'
        Assert-HrsThrows { ConvertFrom-HrsPolicyJson -Json ($standardJson -replace '"revision":1', '"revision":1.5') } 'POLICY_JSON_SHAPE'
    }
    Invoke-HrsContractCase 'POLICY-017-string-boolean-rejected' {
        Assert-HrsThrows { ConvertFrom-HrsPolicyJson -Json ($standardJson -replace '"enabled":false', '"enabled":"false"') } 'POLICY_JSON_SHAPE'
    }
    Invoke-HrsContractCase 'POLICY-018-unknown-schema-and-mode-rejected' {
        Assert-HrsThrows { ConvertFrom-HrsPolicyJson -Json ($standardJson -replace 'hrs-policy/v1', 'hrs-policy/v2') } 'POLICY_SCHEMA'
        Assert-HrsThrows { ConvertFrom-HrsPolicyJson -Json ($standardJson -replace '"mode":"Standard"', '"mode":"Chaos"') } 'POLICY_MODE'
    }
    Invoke-HrsContractCase 'POLICY-019-oversize-rejected-before-shape' {
        Assert-HrsThrows { ConvertFrom-HrsPolicyJson -Json ($standardJson + (' ' * 4097)) } 'POLICY_OVERSIZE'
    }

    $policyIoRoot = Join-Path $fixtureRoot 'policy-io'
    [void] [System.IO.Directory]::CreateDirectory($policyIoRoot)
    $policyPath = Join-Path $policyIoRoot 'policy.v1.json'
    Invoke-HrsContractCase 'POLICY-020-atomic-write-and-readback' {
        $written = Write-HrsPolicyFile -Path $policyPath -AllowedRoot $policyIoRoot -Policy $randomPolicy
        Assert-HrsEqual $written.policyDigest $randomPolicy.policyDigest 'Policy readback digest differed.'
        Assert-HrsTrue (Test-HrsNoUtf8Bom $policyPath) 'Policy writer emitted a UTF-8 BOM.'
        Assert-HrsEqual ([System.IO.File]::ReadAllText($policyPath)) $randomJson 'Policy file bytes were not canonical.'
        Assert-HrsEqual @(Get-ChildItem -LiteralPath $policyIoRoot -Force).Count 1 'Atomic writer left a staging or rollback file.'
    }
    Invoke-HrsContractCase 'POLICY-021-missing-file-rejected' {
        Assert-HrsThrows { Read-HrsPolicyFile -Path (Join-Path $policyIoRoot 'missing.json') } 'POLICY_FILE_MISSING'
    }
    Invoke-HrsContractCase 'POLICY-022-bom-file-rejected' {
        $path = Join-Path $policyIoRoot 'bom-policy.json'
        $withBom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($path, $standardJson, $withBom)
        Assert-HrsThrows { Read-HrsPolicyFile -Path $path } 'POLICY_BOM_FORBIDDEN'
    }
    Invoke-HrsContractCase 'POLICY-023-invalid-utf8-file-rejected' {
        $path = Join-Path $policyIoRoot 'invalid-utf8-policy.json'
        [System.IO.File]::WriteAllBytes($path, [byte[]]@(0xC3, 0x28))
        Assert-HrsThrows { Read-HrsPolicyFile -Path $path }
    }

    # Atomic replacement behavior independent of policy parsing
    $atomicRoot = Join-Path $fixtureRoot 'atomic'
    [void] [System.IO.Directory]::CreateDirectory($atomicRoot)
    Invoke-HrsContractCase 'ATOMIC-001-new-file-success' {
        $path = Join-Path $atomicRoot 'new.txt'
        Write-HrsAtomicUtf8File -Path $path -AllowedRoot $atomicRoot -Text 'new' -ReadbackValidator {
            param($readbackPath)
            if ([System.IO.File]::ReadAllText($readbackPath) -ne 'new') { throw 'READBACK_BAD' }
        }
        Assert-HrsEqual ([System.IO.File]::ReadAllText($path)) 'new' 'New atomic file content differed.'
    }
    Invoke-HrsContractCase 'ATOMIC-002-existing-file-success' {
        $path = Join-Path $atomicRoot 'existing.txt'
        Write-HrsTestText -Path $path -Text 'old'
        Write-HrsAtomicUtf8File -Path $path -AllowedRoot $atomicRoot -Text 'new' -ReadbackValidator {
            param($readbackPath)
            if ([System.IO.File]::ReadAllText($readbackPath) -ne 'new') { throw 'READBACK_BAD' }
        }
        Assert-HrsEqual ([System.IO.File]::ReadAllText($path)) 'new' 'Existing atomic file was not replaced.'
        Assert-HrsFalse ([System.IO.File]::Exists((Join-Path $atomicRoot '.existing.txt.rollback'))) 'Successful replace left its rollback file.'
    }
    Invoke-HrsContractCase 'ATOMIC-003-existing-file-readback-failure-rolls-back' {
        $path = Join-Path $atomicRoot 'rollback-existing.txt'
        Write-HrsTestText -Path $path -Text 'old-valid'
        Assert-HrsThrows {
            Write-HrsAtomicUtf8File -Path $path -AllowedRoot $atomicRoot -Text 'new-invalid' -ReadbackValidator { param($readbackPath) throw 'INJECTED_READBACK_FAILURE' }
        } 'INJECTED_READBACK_FAILURE'
        Assert-HrsEqual ([System.IO.File]::ReadAllText($path)) 'old-valid' 'Readback failure did not restore the old valid file.'
    }
    Invoke-HrsContractCase 'ATOMIC-004-new-file-readback-failure-restores-absence' {
        $path = Join-Path $atomicRoot 'rollback-new.txt'
        Assert-HrsThrows {
            Write-HrsAtomicUtf8File -Path $path -AllowedRoot $atomicRoot -Text 'new-invalid' -ReadbackValidator { param($readbackPath) throw 'INJECTED_READBACK_FAILURE' }
        } 'INJECTED_READBACK_FAILURE'
        Assert-HrsFalse ([System.IO.File]::Exists($path)) 'A failed first write left an unvalidated destination file.'
    }
    Invoke-HrsContractCase 'ATOMIC-005-parent-must-exist' {
        $path = Join-Path (Join-Path $atomicRoot 'missing-parent') 'value.txt'
        Assert-HrsThrows { Write-HrsAtomicUtf8File -Path $path -AllowedRoot $atomicRoot -Text 'value' } 'ATOMIC_PARENT_MISSING'
    }
    Invoke-HrsContractCase 'ATOMIC-006-rollback-name-is-operation-unique' {
        $path = Join-Path $atomicRoot 'collision.txt'
        $rollbackPath = Join-Path $atomicRoot '.collision.txt.rollback'
        Write-HrsTestText -Path $path -Text 'old-valid'
        Write-HrsTestText -Path $rollbackPath -Text 'unknown-owner'
        Write-HrsAtomicUtf8File -Path $path -AllowedRoot $atomicRoot -Text 'new-value'
        Assert-HrsEqual ([System.IO.File]::ReadAllText($path)) 'new-value' 'Unique rollback naming prevented a valid replacement.'
        Assert-HrsEqual ([System.IO.File]::ReadAllText($rollbackPath)) 'unknown-owner' 'Atomic replacement deleted an unrelated similarly named file.'
    }
    Invoke-HrsContractCase 'ATOMIC-007-allowed-root-containment' {
        $outside = Join-Path $fixtureRoot 'outside-atomic.txt'
        Assert-HrsThrows { Write-HrsAtomicUtf8File -Path $outside -AllowedRoot $atomicRoot -Text 'escape' } 'ATOMIC_PATH_ESCAPE'
        Assert-HrsFalse ([System.IO.File]::Exists($outside)) 'A path outside AllowedRoot was written.'
    }
    Invoke-HrsContractCase 'ATOMIC-008-missing-allowed-root-rejected' {
        $missingRoot = Join-Path $fixtureRoot 'missing-atomic-root'
        Assert-HrsThrows { Write-HrsAtomicUtf8File -Path (Join-Path $missingRoot 'value.txt') -AllowedRoot $missingRoot -Text 'value' } 'ATOMIC_ROOT_MISSING'
    }

    # Result validation is evidence-only and uses an exact closed shape.
    $zeroDigest = '0' * 64
    $validResultJson = '{"schema":"hrs-result/v1","policyRevision":0,"policyDigest":"' + $zeroDigest + '","outcome":"REJECTED","reason":"POLICY_REJECTED","markerState":"NOT_APPLICABLE","observedUtc":"2026-08-21T12:34:56.789Z"}'
    $validConsumedResultJson = '{"schema":"hrs-result/v1","policyRevision":2,"policyDigest":"' + $randomPolicy.policyDigest + '","outcome":"COMPLETED","reason":"RELOCATION_COMPLETED","markerState":"COMPLETED","observedUtc":"2026-08-21T12:34:56.789Z"}'

    Invoke-HrsContractCase 'RESULT-001-zero-revision-sentinel-valid' {
        $actual = ConvertFrom-HrsResultJson -Json $validResultJson
        Assert-HrsEqual $actual.policyRevision '0' 'Zero policy revision changed during parsing.'
        Assert-HrsEqual (Test-HrsResultObject -Result $actual).Reason 'RESULT_VALID' 'Parsed zero-revision result was invalid.'
    }
    Invoke-HrsContractCase 'RESULT-002-consumed-policy-result-valid' {
        $actual = ConvertFrom-HrsResultJson -Json $validConsumedResultJson
        Assert-HrsEqual $actual.outcome 'COMPLETED' 'Consumed-policy outcome changed.'
    }
    Invoke-HrsContractCase 'RESULT-003-all-outcomes-allowlisted' {
        $cases = @(
            @{ Outcome = 'BYPASSED'; Reason = 'STANDARD_BYPASS'; Marker = 'NOT_APPLICABLE'; Revision = [UInt64]1; Digest = $standardPolicy.policyDigest },
            @{ Outcome = 'RESERVED'; Reason = 'PLACEMENT_DEFERRED'; Marker = 'RESERVED'; Revision = [UInt64]2; Digest = $randomPolicy.policyDigest },
            @{ Outcome = 'COMPLETED'; Reason = 'RELOCATION_COMPLETED'; Marker = 'COMPLETED'; Revision = [UInt64]2; Digest = $randomPolicy.policyDigest },
            @{ Outcome = 'FAILED'; Reason = 'PLACEMENT_FAILED'; Marker = 'RESERVED'; Revision = [UInt64]2; Digest = $randomPolicy.policyDigest },
            @{ Outcome = 'INCOMPATIBLE'; Reason = 'BUILD_MISMATCH'; Marker = 'NOT_APPLICABLE'; Revision = [UInt64]0; Digest = $zeroDigest },
            @{ Outcome = 'REJECTED'; Reason = 'POLICY_REJECTED'; Marker = 'NOT_APPLICABLE'; Revision = [UInt64]0; Digest = $zeroDigest }
        )
        foreach ($case in $cases) {
            $result = New-HrsResult -PolicyRevision $case.Revision -PolicyDigest $case.Digest -Outcome $case.Outcome -Reason $case.Reason -MarkerState $case.Marker -ObservedUtc $fixedUtc
            $json = ConvertTo-HrsResultJson -Result $result
            Assert-HrsEqual (ConvertTo-HrsResultJson -Result (ConvertFrom-HrsResultJson -Json $json)) $json "Result roundtrip changed $($case.Outcome)."
        }
    }
    Invoke-HrsContractCase 'RESULT-003A-consumed-outcome-requires-policy-revision' {
        foreach ($case in @(
            @{ Outcome = 'BYPASSED'; Reason = 'STANDARD_BYPASS'; Marker = 'NOT_APPLICABLE' },
            @{ Outcome = 'RESERVED'; Reason = 'PLACEMENT_DEFERRED'; Marker = 'RESERVED' },
            @{ Outcome = 'COMPLETED'; Reason = 'RELOCATION_COMPLETED'; Marker = 'COMPLETED' },
            @{ Outcome = 'FAILED'; Reason = 'PLACEMENT_FAILED'; Marker = 'RESERVED' }
        )) {
            Assert-HrsThrows {
                New-HrsResult -PolicyRevision 0 -PolicyDigest $zeroDigest -Outcome $case.Outcome -Reason $case.Reason -MarkerState $case.Marker -ObservedUtc $fixedUtc
            } 'RESULT_LOGICAL_COMBINATION'
        }
    }
    Invoke-HrsContractCase 'RESULT-004-zero-revision-requires-zero-digest' {
        Assert-HrsThrows { ConvertFrom-HrsResultJson -Json ($validResultJson -replace $zeroDigest, ('A' * 64)) } 'RESULT_ZERO_REVISION_DIGEST'
    }
    Invoke-HrsContractCase 'RESULT-005-unknown-outcome-rejected' {
        Assert-HrsThrows { ConvertFrom-HrsResultJson -Json ($validResultJson -replace '"outcome":"REJECTED"', '"outcome":"COMMAND"') } 'RESULT_OUTCOME'
    }
    Invoke-HrsContractCase 'RESULT-006-invalid-reason-rejected' {
        Assert-HrsThrows { ConvertFrom-HrsResultJson -Json ($validResultJson -replace 'POLICY_REJECTED', 'lowercase') } 'RESULT_REASON'
        Assert-HrsThrows { ConvertFrom-HrsResultJson -Json ($validResultJson -replace 'POLICY_REJECTED', 'A') } 'RESULT_REASON'
    }
    Invoke-HrsContractCase 'RESULT-007-invalid-marker-rejected' {
        Assert-HrsThrows { ConvertFrom-HrsResultJson -Json ($validResultJson -replace 'NOT_APPLICABLE', 'REROLL') } 'RESULT_MARKER'
    }
    Invoke-HrsContractCase 'RESULT-008-noncanonical-timestamp-rejected' {
        Assert-HrsThrows { ConvertFrom-HrsResultJson -Json ($validResultJson -replace '2026-08-21T12:34:56.789Z', '2026-08-21 12:34:56Z') } 'RESULT_TIMESTAMP'
    }
    Invoke-HrsContractCase 'RESULT-009-command-and-duplicate-fields-rejected' {
        Assert-HrsThrows { ConvertFrom-HrsResultJson -Json ($validResultJson.Substring(0, $validResultJson.Length - 1) + ',"command":"MOVE"}') } 'RESULT_JSON_SHAPE'
        Assert-HrsThrows { ConvertFrom-HrsResultJson -Json ($validResultJson.Substring(0, $validResultJson.Length - 1) + ',"outcome":"COMPLETED"}') } 'RESULT_JSON_SHAPE'
    }
    Invoke-HrsContractCase 'RESULT-010-reordered-shape-rejected' {
        $hostile = '{"policyRevision":0,"schema":"hrs-result/v1","policyDigest":"' + $zeroDigest + '","outcome":"REJECTED","reason":"POLICY_REJECTED","markerState":"NOT_APPLICABLE","observedUtc":"2026-08-21T12:34:56.789Z"}'
        Assert-HrsThrows { ConvertFrom-HrsResultJson -Json $hostile } 'RESULT_JSON_SHAPE'
    }
    Invoke-HrsContractCase 'RESULT-011-object-field-case-rejected' {
        $parsed = ConvertFrom-HrsResultJson -Json $validResultJson
        $changed = [pscustomobject][ordered]@{
            Schema = $parsed.schema
            policyRevision = $parsed.policyRevision
            policyDigest = $parsed.policyDigest
            outcome = $parsed.outcome
            reason = $parsed.reason
            markerState = $parsed.markerState
            observedUtc = $parsed.observedUtc
        }
        Assert-HrsFalse (Test-HrsResultObject -Result $changed).Valid 'A case-variant result field was accepted as canonical.'
    }
    Invoke-HrsContractCase 'RESULT-012-object-revision-type-rejected' {
        $parsed = ConvertFrom-HrsResultJson -Json $validConsumedResultJson
        $parsed.policyRevision = '2'
        Assert-HrsFalse (Test-HrsResultObject -Result $parsed).Valid 'A string policy revision was accepted by the strict result validator.'
    }
    Invoke-HrsContractCase 'RESULT-013-oversize-rejected' {
        Assert-HrsThrows { ConvertFrom-HrsResultJson -Json ($validResultJson + (' ' * 4097)) } 'RESULT_OVERSIZE'
    }

    $resultIoRoot = Join-Path $fixtureRoot 'result-io'
    [void] [System.IO.Directory]::CreateDirectory($resultIoRoot)
    Invoke-HrsContractCase 'RESULT-014-file-read-valid' {
        $path = Join-Path $resultIoRoot 'result.v1.json'
        Write-HrsTestText -Path $path -Text $validConsumedResultJson
        Assert-HrsEqual (Read-HrsResultFile -Path $path).outcome 'COMPLETED' 'Result file outcome differed.'
    }
    Invoke-HrsContractCase 'RESULT-015-missing-bom-invalid-utf8-rejected' {
        Assert-HrsThrows { Read-HrsResultFile -Path (Join-Path $resultIoRoot 'missing.json') } 'RESULT_FILE_MISSING'
        $bomPath = Join-Path $resultIoRoot 'bom-result.json'
        [System.IO.File]::WriteAllText($bomPath, $validResultJson, (New-Object System.Text.UTF8Encoding($true)))
        Assert-HrsThrows { Read-HrsResultFile -Path $bomPath } 'RESULT_BOM_FORBIDDEN'
        $invalidPath = Join-Path $resultIoRoot 'invalid-utf8-result.json'
        [System.IO.File]::WriteAllBytes($invalidPath, [byte[]]@(0xC3, 0x28))
        Assert-HrsThrows { Read-HrsResultFile -Path $invalidPath }
    }

    # Bridge containment and reparse-point gates use disposable fake roots only.
    $bridgeGame = New-HrsFakeGameRoot -Path (Join-Path $fixtureRoot 'bridge-game')
    Invoke-HrsContractCase 'BRIDGE-001-path-layout-is-bounded' {
        $paths = Get-HrsBridgePaths -GameRoot $bridgeGame
        Assert-HrsEqual $paths.ReleaseRoot (Join-Path $bridgeGame 'Mods\BitWrecked_HistoricalRandomStart') 'Release root differed.'
        Assert-HrsEqual $paths.PolicyPath (Join-Path $bridgeGame 'Mods\BitWrecked_HistoricalRandomStart\Bridge\policy.v1.json') 'Policy path differed.'
        Assert-HrsEqual $paths.ResultPath (Join-Path $bridgeGame 'Mods\BitWrecked_HistoricalRandomStart\Bridge\result.v1.json') 'Result path differed.'
    }
    Invoke-HrsContractCase 'BRIDGE-002-valid-root-before-install' {
        $actual = Test-HrsBridgePaths -GameRoot $bridgeGame
        Assert-HrsTrue $actual.Valid 'A recognized fake game root was rejected before release-root creation.'
    }
    Invoke-HrsContractCase 'BRIDGE-003-required-release-root-must-exist' {
        $actual = Test-HrsBridgePaths -GameRoot $bridgeGame -RequireReleaseRoot
        Assert-HrsFalse $actual.Valid 'A missing required release root was accepted.'
        Assert-HrsEqual $actual.Reason 'RELEASE_ROOT_MISSING' 'Missing release-root reason differed.'
    }
    Invoke-HrsContractCase 'BRIDGE-004-existing-owned-layout-valid' {
        [void] [System.IO.Directory]::CreateDirectory((Join-Path $bridgeGame 'Mods\BitWrecked_HistoricalRandomStart\Bridge'))
        $actual = Test-HrsBridgePaths -GameRoot $bridgeGame -RequireReleaseRoot
        Assert-HrsTrue $actual.Valid 'An ordinary owned release layout was rejected.'
    }
    Invoke-HrsContractCase 'BRIDGE-004A-unknown-bridge-entry-rejected' {
        $unknown = Join-Path $bridgeGame 'Mods\BitWrecked_HistoricalRandomStart\Bridge\unknown.bin'
        [System.IO.File]::WriteAllBytes($unknown, [byte[]]@(0))
        $actual = Test-HrsBridgePaths -GameRoot $bridgeGame -RequireReleaseRoot
        Assert-HrsEqual $actual.Reason 'BRIDGE_UNKNOWN_ENTRY' 'An unexpected Bridge entry was accepted.'
        [System.IO.File]::Delete($unknown)
    }
    Invoke-HrsContractCase 'BRIDGE-005-missing-game-executable-rejected' {
        $root = Join-Path $fixtureRoot 'not-a-game'
        [void] [System.IO.Directory]::CreateDirectory($root)
        Assert-HrsEqual (Test-HrsBridgePaths -GameRoot $root).Reason 'GAME_EXECUTABLE_MISSING' 'Missing executable was not rejected.'
    }
    Invoke-HrsContractCase 'BRIDGE-006-noncanonical-traversal-input-rejected' {
        $rootWithTraversal = Join-Path (Join-Path $bridgeGame 'unused-child') '..'
        $actual = Test-HrsBridgePaths -GameRoot $rootWithTraversal
        Assert-HrsFalse $actual.Valid 'A noncanonical game-root input containing traversal was accepted.'
    }

    $junctionSupported = $true
    $junctionProbeTarget = Join-Path $fixtureRoot 'junction-probe-target'
    $junctionProbeLink = Join-Path $fixtureRoot 'junction-probe-link'
    [void] [System.IO.Directory]::CreateDirectory($junctionProbeTarget)
    try {
        $null = New-Item -ItemType Junction -Path $junctionProbeLink -Target $junctionProbeTarget -ErrorAction Stop
        [void] $script:CreatedReparsePaths.Add($junctionProbeLink)
    }
    catch {
        $junctionSupported = $false
        Write-HrsContractSkip 'BRIDGE-REPARSE-SETUP' "Junction creation unavailable: $($_.Exception.Message)"
    }

    if ($junctionSupported) {
        Invoke-HrsContractCase 'BRIDGE-007-game-root-reparse-rejected' {
            $target = New-HrsFakeGameRoot -Path (Join-Path $fixtureRoot 'junction-game-target')
            $link = Join-Path $fixtureRoot 'junction-game-link'
            $null = New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop
            [void] $script:CreatedReparsePaths.Add($link)
            Assert-HrsEqual (Test-HrsBridgePaths -GameRoot $link).Reason 'GAME_ROOT_REPARSE_POINT' 'Reparse game root was not rejected.'
        }
        Invoke-HrsContractCase 'BRIDGE-008-bridge-directory-reparse-rejected' {
            $game = New-HrsFakeGameRoot -Path (Join-Path $fixtureRoot 'bridge-junction-game')
            $release = Join-Path $game 'Mods\BitWrecked_HistoricalRandomStart'
            [void] [System.IO.Directory]::CreateDirectory($release)
            $target = Join-Path $fixtureRoot 'bridge-junction-target'
            [void] [System.IO.Directory]::CreateDirectory($target)
            $link = Join-Path $release 'Bridge'
            $null = New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop
            [void] $script:CreatedReparsePaths.Add($link)
            Assert-HrsFalse (Test-HrsBridgePaths -GameRoot $game -RequireReleaseRoot).Valid 'A reparse Bridge directory was accepted.'
        }
        Invoke-HrsContractCase 'BRIDGE-009-mods-directory-reparse-rejected-before-install' {
            $game = New-HrsFakeGameRoot -Path (Join-Path $fixtureRoot 'mods-junction-game')
            $target = Join-Path $fixtureRoot 'mods-junction-target'
            [void] [System.IO.Directory]::CreateDirectory($target)
            $link = Join-Path $game 'Mods'
            $null = New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop
            [void] $script:CreatedReparsePaths.Add($link)
            Assert-HrsFalse (Test-HrsBridgePaths -GameRoot $game).Valid 'A reparse Mods directory was accepted as a future deployment path.'
        }
    }

    # Process-state and capability model. Providers are inert objects; no real process is started.
    Invoke-HrsContractCase 'PROCESS-001-empty-provider-is-closed' {
        $actual = Get-HrsProcessState -ProcessProvider { @() }
        Assert-HrsEqual $actual.Game 'Closed' 'Empty provider did not report the game closed.'
        Assert-HrsEqual $actual.Steam 'Closed' 'Empty provider did not report Steam closed.'
    }
    Invoke-HrsContractCase 'PROCESS-002-steam-only' {
        $actual = Get-HrsProcessState -ProcessProvider { [pscustomobject]@{ ProcessName = 'steam' } }
        Assert-HrsEqual $actual.Game 'Closed' 'Steam was mistaken for the game.'
        Assert-HrsEqual $actual.Steam 'Running' 'Steam was not detected.'
    }
    Invoke-HrsContractCase 'PROCESS-003-all-game-process-identities-block' {
        foreach ($name in @('7DaysToDie', '7DaysToDieServer', '7DaysToDie_EAC')) {
            $actual = Get-HrsProcessState -ProcessProvider { [pscustomobject]@{ ProcessName = $name } }
            Assert-HrsEqual $actual.Game 'Running' "Game process '$name' was not detected."
        }
    }
    Invoke-HrsContractCase 'PROCESS-004-provider-failure-is-unknown' {
        $actual = Get-HrsProcessState -ProcessProvider { throw 'INJECTED_PROCESS_FAILURE' }
        Assert-HrsEqual $actual.Game 'Unknown' 'Process-query failure did not fail closed for game state.'
        Assert-HrsEqual $actual.Steam 'Unknown' 'Process-query failure did not fail closed for Steam state.'
    }
    Invoke-HrsContractCase 'PROCESS-005-unidentifiable-process-is-unknown' {
        $actual = Get-HrsProcessState -ProcessProvider { [pscustomobject]@{ Id = 1234 } }
        Assert-HrsEqual $actual.Game 'Unknown' 'An unidentifiable process object was treated as proof the game was closed.'
    }
    Invoke-HrsContractCase 'MUTATION-001-only-exact-closed-allows' {
        Assert-HrsTrue (Test-HrsMutationAllowed -ProcessState ([pscustomobject]@{ Game = 'Closed'; Steam = 'Closed' })).Allowed 'Closed game did not allow mutation.'
        Assert-HrsFalse (Test-HrsMutationAllowed -ProcessState ([pscustomobject]@{ Game = 'Running'; Steam = 'Running' })).Allowed 'Running game allowed mutation.'
        Assert-HrsFalse (Test-HrsMutationAllowed -ProcessState ([pscustomobject]@{ Game = 'Unknown'; Steam = 'Running' })).Allowed 'Unknown game state allowed mutation.'
    }
    Invoke-HrsContractCase 'MUTATION-002-steam-state-is-not-a-mutation-lock' {
        Assert-HrsTrue (Test-HrsMutationAllowed -ProcessState ([pscustomobject]@{ Game = 'Closed'; Steam = 'Running' })).Allowed 'Running Steam blocked mutation.'
        Assert-HrsTrue (Test-HrsMutationAllowed -ProcessState ([pscustomobject]@{ Game = 'Closed'; Steam = 'Unknown' })).Allowed 'Unknown Steam state blocked mutation while the game was confirmed closed.'
    }
    Invoke-HrsContractCase 'LAUNCH-001-closed-game-and-running-steam-allows' {
        $actual = Test-HrsLaunchAllowed -ProcessState ([pscustomobject]@{ Game = 'Closed'; Steam = 'Running' })
        Assert-HrsTrue $actual.Allowed 'Direct-user launch availability was not exposed.'
        Assert-HrsEqual $actual.Reason 'DIRECT_USER_LAUNCH_AVAILABLE' 'Launch-available reason differed.'
    }
    Invoke-HrsContractCase 'LAUNCH-002-running-or-unknown-game-blocks' {
        Assert-HrsEqual (Test-HrsLaunchAllowed -ProcessState ([pscustomobject]@{ Game = 'Running'; Steam = 'Running' })).Reason 'GAME_ALREADY_RUNNING' 'Running-game launch reason differed.'
        Assert-HrsEqual (Test-HrsLaunchAllowed -ProcessState ([pscustomobject]@{ Game = 'Unknown'; Steam = 'Running' })).Reason 'GAME_STATE_UNCONFIRMED' 'Unknown-game launch reason differed.'
    }
    Invoke-HrsContractCase 'LAUNCH-003-steam-closed-or-unknown-blocks' {
        Assert-HrsEqual (Test-HrsLaunchAllowed -ProcessState ([pscustomobject]@{ Game = 'Closed'; Steam = 'Closed' })).Reason 'STEAM_NOT_RUNNING' 'Closed-Steam launch reason differed.'
        Assert-HrsEqual (Test-HrsLaunchAllowed -ProcessState ([pscustomobject]@{ Game = 'Closed'; Steam = 'Unknown' })).Reason 'STEAM_STATE_UNCONFIRMED' 'Unknown-Steam launch reason differed.'
    }

    # Portable manager state and complete local event history
    $managerRoot = Join-Path $fixtureRoot 'manager'
    [void] [System.IO.Directory]::CreateDirectory($managerRoot)
    Invoke-HrsContractCase 'MANAGER-001-state-path-layout' {
        $paths = Get-HrsManagerStatePaths -ManagerRoot $managerRoot
        Assert-HrsEqual $paths.StateRoot (Join-Path $managerRoot 'Support_Files_Do_Not_Edit\HistoricalRandomStart_State') 'Manager state root differed.'
        Assert-HrsEqual $paths.HistoryPath (Join-Path $paths.StateRoot 'history.v1.jsonl') 'History path differed.'
        Assert-HrsEqual $paths.RecoveryIndexPath (Join-Path $paths.StateRoot 'recovery-index.v1.json') 'Recovery-index path differed.'
    }
    Invoke-HrsContractCase 'MANAGER-002-support-root-required' {
        Assert-HrsThrows { Initialize-HrsManagerState -ManagerRoot $managerRoot } 'MANAGER_SUPPORT_ROOT_MISSING'
    }
    [void] [System.IO.Directory]::CreateDirectory((Join-Path $managerRoot 'Support_Files_Do_Not_Edit'))
    Invoke-HrsContractCase 'MANAGER-003-initialization-is-contained' {
        $paths = Initialize-HrsManagerState -ManagerRoot $managerRoot
        Assert-HrsTrue ([System.IO.Directory]::Exists($paths.StateRoot)) 'State root was not created.'
        Assert-HrsFalse ([System.IO.Directory]::Exists($paths.SnapshotRoot)) 'Core initialization created a snapshot directory before a snapshot exists.'
        Assert-HrsFalse ([System.IO.Directory]::Exists($paths.LogRoot)) 'Core initialization silently created an unused diagnostic-log directory.'
        Assert-HrsFalse ([System.IO.File]::Exists($paths.HistoryPath)) 'Initialization silently created history content.'
    }
    Invoke-HrsContractCase 'MANAGER-004-correlation-format-and-uniqueness' {
        $one = New-HrsCorrelationId
        $two = New-HrsCorrelationId
        Assert-HrsTrue ($one -match '^hrs-[0-9a-f]{32}$') 'Correlation ID shape differed.'
        Assert-HrsFalse ($one -eq $two) 'Two correlation IDs were equal.'
    }
    Invoke-HrsContractCase 'HISTORY-001-one-correlated-event' {
        $correlation = 'hrs-0123456789abcdef0123456789abcdef'
        $event = Add-HrsHistoryEvent -ManagerRoot $managerRoot -Action Apply -Outcome Succeeded -Reason 'POLICY_APPLIED' -CorrelationId $correlation -GameName 'HRS Alpha 01' -Revision 2 -Mode Random
        $paths = Get-HrsManagerStatePaths -ManagerRoot $managerRoot
        Assert-HrsEqual $event.correlationId $correlation 'Returned event correlation differed.'
        Assert-HrsTrue (Test-HrsNoUtf8Bom $paths.HistoryPath) 'History writer emitted a UTF-8 BOM.'
        $lines = @([System.IO.File]::ReadAllLines($paths.HistoryPath) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        Assert-HrsEqual $lines.Count 1 'One event did not produce exactly one JSONL record.'
        $parsed = $lines[0] | ConvertFrom-Json
        Assert-HrsEqual $parsed.schema 'hrs-history/v1' 'History schema differed.'
        Assert-HrsEqual $parsed.correlationId $correlation 'Stored correlation differed.'
        Assert-HrsEqual $parsed.gameName 'HRS Alpha 01' 'Stored game association differed.'
        Assert-HrsEqual $parsed.revision 2 'Stored revision differed.'
        Assert-HrsEqual $parsed.mode 'Random' 'Stored mode differed.'
    }
    Invoke-HrsContractCase 'HISTORY-002-all-action-categories-append' {
        $root = Join-Path $fixtureRoot 'manager-all-actions'
        [void] [System.IO.Directory]::CreateDirectory((Join-Path $root 'Support_Files_Do_Not_Edit'))
        $actions = @('Install', 'Update', 'Apply', 'Blocked', 'Failed', 'Cancelled', 'Reset', 'Restore', 'LaunchRequest', 'RemoveFromGame', 'Snapshot')
        foreach ($action in $actions) {
            $outcome = switch ($action) {
                'Blocked' { 'Blocked' }
                'Failed' { 'Failed' }
                'Cancelled' { 'Cancelled' }
                'LaunchRequest' { 'Requested' }
                default { 'Succeeded' }
            }
            $null = Add-HrsHistoryEvent -ManagerRoot $root -Action $action -Outcome $outcome -Reason ($action.ToUpperInvariant() + '_EVENT')
        }
        $path = (Get-HrsManagerStatePaths -ManagerRoot $root).HistoryPath
        $lines = @([System.IO.File]::ReadAllLines($path) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        Assert-HrsEqual $lines.Count $actions.Count 'Not every event category entered history.'
        foreach ($line in $lines) { $null = $line | ConvertFrom-Json }
    }
    Invoke-HrsContractCase 'HISTORY-003-reason-bounds' {
        Assert-HrsThrows { Add-HrsHistoryEvent -ManagerRoot $managerRoot -Action Failed -Outcome Failed -Reason '' }
        Assert-HrsThrows { Add-HrsHistoryEvent -ManagerRoot $managerRoot -Action Failed -Outcome Failed -Reason "BAD`nREASON" } 'HISTORY_REASON_INVALID'
        Assert-HrsThrows { Add-HrsHistoryEvent -ManagerRoot $managerRoot -Action Failed -Outcome Failed -Reason ('A' * 161) } 'HISTORY_REASON_INVALID'
    }
    Invoke-HrsContractCase 'HISTORY-004-correlation-game-and-mode-validation' {
        Assert-HrsThrows { Add-HrsHistoryEvent -ManagerRoot $managerRoot -Action Failed -Outcome Failed -Reason 'BAD_CORRELATION' -CorrelationId 'not-a-correlation' } 'HISTORY_CORRELATION_INVALID'
        Assert-HrsThrows { Add-HrsHistoryEvent -ManagerRoot $managerRoot -Action Apply -Outcome Failed -Reason 'BAD_GAME' -GameName ' Bad Game' } 'HISTORY_GAME_NAME_INVALID'
        Assert-HrsThrows { Add-HrsHistoryEvent -ManagerRoot $managerRoot -Action Apply -Outcome Failed -Reason 'BAD_MODE' -Mode 'Chaos' }
    }
    Invoke-HrsContractCase 'HISTORY-005-action-and-outcome-allowlists' {
        Assert-HrsThrows { Add-HrsHistoryEvent -ManagerRoot $managerRoot -Action 'DeleteEverything' -Outcome Failed -Reason 'BAD_ACTION' }
        Assert-HrsThrows { Add-HrsHistoryEvent -ManagerRoot $managerRoot -Action Apply -Outcome 'Maybe' -Reason 'BAD_OUTCOME' }
    }

    if ($junctionSupported) {
        Invoke-HrsContractCase 'MANAGER-005-support-root-reparse-rejected' {
            $root = Join-Path $fixtureRoot 'manager-support-junction'
            [void] [System.IO.Directory]::CreateDirectory($root)
            $target = Join-Path $fixtureRoot 'manager-support-target'
            [void] [System.IO.Directory]::CreateDirectory($target)
            $link = Join-Path $root 'Support_Files_Do_Not_Edit'
            $null = New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop
            [void] $script:CreatedReparsePaths.Add($link)
            Assert-HrsThrows { Initialize-HrsManagerState -ManagerRoot $root } 'MANAGER_SUPPORT_REPARSE_POINT'
        }
        Invoke-HrsContractCase 'MANAGER-006-state-root-reparse-rejected' {
            $root = Join-Path $fixtureRoot 'manager-state-junction'
            $support = Join-Path $root 'Support_Files_Do_Not_Edit'
            [void] [System.IO.Directory]::CreateDirectory($support)
            $target = Join-Path $fixtureRoot 'manager-state-target'
            [void] [System.IO.Directory]::CreateDirectory($target)
            $link = Join-Path $support 'HistoricalRandomStart_State'
            $null = New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop
            [void] $script:CreatedReparsePaths.Add($link)
            Assert-HrsThrows { Initialize-HrsManagerState -ManagerRoot $root } 'MANAGER_STATE_REPARSE_POINT'
        }
    }
}
finally {
    # Remove every created link itself before recursively removing its bounded,
    # project-local fixture tree. All junction targets are also inside this run root.
    foreach ($reparsePath in @($script:CreatedReparsePaths | Sort-Object Length -Descending)) {
        try {
            if ([System.IO.Directory]::Exists($reparsePath)) {
                [System.IO.Directory]::Delete($reparsePath, $false)
            }
        }
        catch {
            Write-Output "CLEANUP_WARNING path=$reparsePath category=$($_.Exception.GetType().Name)"
        }
    }

    $resolvedParent = [System.IO.Path]::GetFullPath($fixtureParent).TrimEnd('\')
    $resolvedRun = [System.IO.Path]::GetFullPath($fixtureRoot).TrimEnd('\')
    $expectedPrefix = $resolvedParent + [System.IO.Path]::DirectorySeparatorChar
    if ($resolvedRun.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
        [System.IO.Path]::GetFileName($resolvedRun) -eq $fixtureLeaf) {
        if ([System.IO.Directory]::Exists($resolvedRun)) {
            [System.IO.Directory]::Delete($resolvedRun, $true)
        }
        if ([System.IO.Directory]::Exists($resolvedParent) -and
            [System.IO.Directory]::GetFileSystemEntries($resolvedParent).Count -eq 0) {
            [System.IO.Directory]::Delete($resolvedParent, $false)
        }
    }
    else {
        Write-Output 'CLEANUP_WARNING bounded fixture path validation failed; no recursive cleanup attempted.'
    }
}

Write-Output "ALPHA_CORE_CONTRACT_SUMMARY pass=$script:PassCount fail=$script:FailCount skip=$script:SkipCount"
if ($script:FailCount -gt 0) {
    Write-Output 'ALPHA_CORE_CONTRACT_FAILURES_BEGIN'
    foreach ($failure in $script:FailureDetails) { Write-Output $failure }
    Write-Output 'ALPHA_CORE_CONTRACT_FAILURES_END'
    exit 1
}

exit 0
