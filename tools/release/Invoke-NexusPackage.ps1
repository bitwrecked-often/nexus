[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
param(
    [Parameter(Mandatory)]
    [string]$ManifestPath,

    [ValidateSet("Validate", "StagePrimary", "PreparePrimary")]
    [string]$Action = "Validate",

    [ValidateSet("candidate", "disposable-test-fixture")]
    [string]$ExecutionClass = "candidate",

    [string]$DisposableTestToken,

    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$modulePath = Join-Path $PSScriptRoot "NexusPackageTools.psm1"
Import-Module $modulePath -Force

try {
    if ($Action -cne "PreparePrimary" -and $ExecutionClass -cne "candidate") {
        throw "The disposable execution class is valid only for PreparePrimary integration tests."
    }
    if ($Action -cne "PreparePrimary" -and -not [string]::IsNullOrEmpty($DisposableTestToken)) {
        throw "A disposable ownership token is valid only for PreparePrimary integration tests."
    }
    if ($Action -ceq "Validate") {
        $result = Test-NexusReleaseSource -ManifestPath $ManifestPath -Profile Auto
    }
    elseif ($Action -ceq "StagePrimary") {
        $context = Read-NexusManifest -ManifestPath $ManifestPath
        $target = "$($context.Data.distribution.candidateStage)/primary-tree"
        if (-not $PSCmdlet.ShouldProcess($target, "Stage exact primary source tree from clean HEAD")) {
            $result = [pscustomobject][ordered]@{
                operation = "stage-primary"
                mutated = $false
                result = "what-if"
                stagePath = $target
            }
        }
        else {
            $result = New-NexusPrimaryStage -ManifestPath $ManifestPath -Confirm:$false
        }
    }
    else {
        $context = Read-NexusManifest -ManifestPath $ManifestPath
        $target = if ($ExecutionClass -ceq "candidate") {
            "dist/$($context.Data.solution.id)/$($context.Data.release.intendedVersion)"
        }
        else {
            "dist/.test-fixtures/$($context.Data.solution.id)/$($context.Data.release.intendedVersion)"
        }
        if (-not $PSCmdlet.ShouldProcess($target, "Prepare and atomically promote the complete primary technical candidate")) {
            $result = [pscustomobject][ordered]@{
                operation = "prepare-primary"
                mutated = $false
                result = "what-if"
                versionRoot = $target
                executionClass = $ExecutionClass
            }
        }
        else {
            $result = New-NexusPreparedPrimary -ManifestPath $ManifestPath -ExecutionClass $ExecutionClass -DisposableTestToken $DisposableTestToken -Confirm:$false
        }
    }

    if ($PassThru) {
        Write-Output $result
    }
    else {
        $json = ($result | ConvertTo-Json -Depth 20).Replace("`r`n", "`n")
        Write-Output $json
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
