Set-StrictMode -Version Latest

function Get-Phase1ATreeDigest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $Root,
        [string[]] $ExcludedRelativePrefixes = @()
    )

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return [pscustomobject]@{ present = $false; files = 0; bytes = 0; sha256 = $null }
    }
    $resolved = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')
    $entries = New-Object System.Collections.Generic.List[string]
    [long]$bytes = 0
    foreach ($file in @(Get-ChildItem -LiteralPath $resolved -File -Force -Recurse | Sort-Object FullName)) {
        $relative = $file.FullName.Substring($resolved.Length).TrimStart('\').Replace('\', '/')
        $excluded = $false
        foreach ($prefix in $ExcludedRelativePrefixes) {
            if ($relative.StartsWith($prefix.Replace('\', '/'), [StringComparison]::OrdinalIgnoreCase)) {
                $excluded = $true
                break
            }
        }
        if ($excluded) { continue }
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        $entries.Add("$relative|$($file.Length)|$hash")
        $bytes += $file.Length
    }
    $joined = $entries -join "`n"
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $digest = ([BitConverter]::ToString(
            $algorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes($joined)))).Replace('-', '')
    } finally { $algorithm.Dispose() }
    return [pscustomobject]@{ present = $true; files = $entries.Count; bytes = $bytes; sha256 = $digest }
}

function Compare-Phase1ASemanticSnapshots {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [psobject] $Before,
        [Parameter(Mandatory = $true)] [psobject] $After,
        [Parameter(Mandatory = $true)] [string[]] $SanitizedReasons
    )

    $failures = New-Object System.Collections.Generic.List[string]
    foreach ($name in @('gameManaged', 'foreignMods', 'foreignSaves')) {
        if ($Before.$name.sha256 -ne $After.$name.sha256) { $failures.Add("PROTECTED_$($name.ToUpperInvariant())_CHANGED") }
    }
    if ($SanitizedReasons -notcontains 'RELOC_COMPLETED') { $failures.Add('RELOCATION_NOT_COMPLETED') }
    if ($SanitizedReasons -notcontains 'RELOC_SEMANTIC_UNCHANGED') { $failures.Add('RUNTIME_SEMANTIC_PROOF_MISSING') }
    if (@($SanitizedReasons | Where-Object { $_ -match 'FAILED|MISMATCH|INTERNAL' }).Count -gt 0) {
        $failures.Add('RUNTIME_FAILURE_REASON_PRESENT')
    }
    return [pscustomobject]@{ pass = ($failures.Count -eq 0); failures = @($failures) }
}

Export-ModuleMember -Function Get-Phase1ATreeDigest, Compare-Phase1ASemanticSnapshots
