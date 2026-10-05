# Local presentation helpers; no install, restore, network call or runtime deployment.
Set-StrictMode -Version 2.0

function Import-NativeGraphics {
    [CmdletBinding()]
    param()
    if ($env:OS -ne 'Windows_NT') { throw 'Native graphics tools require Windows.' }
    if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -lt 1 -or
        ($PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core')) {
        throw 'Use Windows PowerShell 5.1 (powershell.exe -STA), not pwsh.'
    }
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    if (-not ('BitWrecked.NativeGraphics.V1.SurfacePanel' -as [type])) {
        Add-Type -Path (Join-Path $PSScriptRoot 'NativeControls.cs') -ReferencedAssemblies System.Drawing,System.Windows.Forms -ErrorAction Stop
    }
}

function Get-NativeGraphicsCapability {
    [CmdletBinding()]
    param()
    Import-NativeGraphics
    [pscustomobject]@{
        ToolkitVersion = '1.0.0'
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        CLRVersion = [Environment]::Version.ToString()
        ThreadApartment = [Threading.Thread]::CurrentThread.ApartmentState.ToString()
        HighContrast = [Windows.Forms.SystemInformation]::HighContrast
        DrawingAssembly = [Drawing.Bitmap].Assembly.FullName
        FormsAssembly = [Windows.Forms.Form].Assembly.FullName
        ExternalDependencies = @()
        Types = @('SurfacePanel', 'StatusBadge', 'OutlineButton', 'GlyphControl')
    }
}

function New-NativeSurface {
    [CmdletBinding()]
    param(
        [string]$Name = '',
        [string]$AccessibleName = '',
        [int]$Width = 300,
        [int]$Height = 150,
        [float]$CornerRadius = 12,
        [string]$FillColor = '#FFFFFF',
        [string]$BorderColor = '#DDDED9'
    )
    Import-NativeGraphics
    $control = New-Object BitWrecked.NativeGraphics.V1.SurfacePanel
    $control.Name = $Name
    $control.AccessibleName = $AccessibleName
    $control.Size = New-Object Drawing.Size($Width, $Height)
    $control.CornerRadius = $CornerRadius
    $control.FillColor = [Drawing.ColorTranslator]::FromHtml($FillColor)
    $control.BorderColor = [Drawing.ColorTranslator]::FromHtml($BorderColor)
    return $control
}

function New-NativeBadge {
    [CmdletBinding()]
    param(
        [string]$Text = '',
        [string]$AccessibleName = '',
        [switch]$Accent,
        [string]$FillColor = '#FFFFFF',
        [string]$BorderColor = '#DDDED9',
        [string]$ForeColor = '#242628'
    )
    Import-NativeGraphics
    $control = New-Object BitWrecked.NativeGraphics.V1.StatusBadge
    $control.Text = $Text
    # Leave the inherited name unset so it follows Text when a dynamic badge changes.
    if ($AccessibleName) { $control.AccessibleName = $AccessibleName }
    $control.FillColor = [Drawing.ColorTranslator]::FromHtml($FillColor)
    $control.BorderColor = [Drawing.ColorTranslator]::FromHtml($BorderColor)
    $control.ForeColor = [Drawing.ColorTranslator]::FromHtml($ForeColor)
    $control.ShowAccent = [bool]$Accent
    $control.Size = $control.GetPreferredSize([Drawing.Size]::Empty)
    return $control
}

function New-NativeOutlineButton {
    [CmdletBinding()]
    param(
        [string]$Text = '',
        [string]$AccessibleName = '',
        [int]$Width = 150,
        [int]$Height = 42,
        [float]$CornerRadius = 7,
        [string]$FillColor = '#FFFFFF',
        [string]$BorderColor = '#C1C3BE'
    )
    Import-NativeGraphics
    $control = New-Object BitWrecked.NativeGraphics.V1.OutlineButton
    $control.Text = $Text
    if ($AccessibleName) { $control.AccessibleName = $AccessibleName }
    $control.Size = New-Object Drawing.Size($Width, $Height)
    $control.CornerRadius = $CornerRadius
    $control.FillColor = [Drawing.ColorTranslator]::FromHtml($FillColor)
    $control.BorderColor = [Drawing.ColorTranslator]::FromHtml($BorderColor)
    return $control
}

function New-NativeGlyph {
    [CmdletBinding()]
    param(
        [ValidateSet('Info', 'Check', 'ArrowRight', 'ChevronDown', 'Shield', 'Settings')]
        [string]$Glyph = 'Info',
        [string]$AccessibleName = '',
        [int]$Size = 20,
        [string]$ForeColor = '#AE4014'
    )
    Import-NativeGraphics
    $control = New-Object BitWrecked.NativeGraphics.V1.GlyphControl
    $control.Glyph = [Enum]::Parse([BitWrecked.NativeGraphics.V1.GlyphKind], $Glyph)
    $control.AccessibleName = if ($AccessibleName) { $AccessibleName } else { $Glyph }
    $control.Size = New-Object Drawing.Size($Size, $Size)
    $control.ForeColor = [Drawing.ColorTranslator]::FromHtml($ForeColor)
    return $control
}

Export-ModuleMember -Function Import-NativeGraphics,Get-NativeGraphicsCapability,New-NativeSurface,New-NativeBadge,New-NativeOutlineButton,New-NativeGlyph
