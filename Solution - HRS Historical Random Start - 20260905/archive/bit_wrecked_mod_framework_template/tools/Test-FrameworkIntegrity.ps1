[CmdletBinding()]
param(
    [string]$RootPath = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredPaths = @(
    'README.md',
    'LICENSE.md',
    'SECURITY.md',
    'CONTRIBUTING.md',
    'CODE_OF_CONDUCT.md',
    'MAINTAINERS.md',
    'PUBLIC_REPOSITORY_EXPORT_MANIFEST.md',
    'OPENSSF_READINESS.md',
    'SELF_CERTIFICATION.md',
    'FRAMEWORK_NORMALIZATION_TEMPLATE.md',
    'RECIPE_CATALOG_AND_DR.md',
    'blank_working_example/Blank_BitWreckedMod_Tool.ps1',
    'release_templates/LICENSE-GPL-3.0-or-later.txt'
)

foreach ($relativePath in $requiredPaths) {
    $fullPath = Join-Path $RootPath $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Required framework file is missing: $relativePath"
    }
}

$parseFailures = @()
Get-ChildItem -Path $RootPath -Recurse -Filter '*.ps1' -File | ForEach-Object {
    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $_.FullName,
        [ref]$null,
        [ref]$parseErrors
    )
    if ($parseErrors.Count -gt 0) {
        $parseFailures += "{0}: {1}" -f $_.FullName, ($parseErrors.Message -join '; ')
    }
}

if ($parseFailures.Count -gt 0) {
    throw "PowerShell parse failures:`n$($parseFailures -join "`n")"
}

Write-Host "Framework integrity check passed. Required files present; PowerShell parses cleanly."
