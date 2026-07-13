[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
param(
    [Parameter(Mandatory)]
    [string]$ManifestPath,

    [ValidateSet("Validate", "StagePrimary")]
    [string]$Action = "Validate",

    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$modulePath = Join-Path $PSScriptRoot "NexusPackageTools.psm1"
Import-Module $modulePath -Force

try {
    if ($Action -ceq "Validate") {
        $result = Test-NexusReleaseSource -ManifestPath $ManifestPath -Profile Development
    }
    else {
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
