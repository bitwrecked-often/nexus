[CmdletBinding(DefaultParameterSetName='Card')]
param(
    [Parameter(ParameterSetName='Card')][ValidateSet('Light','Contrast')][string]$CardStyle='Light',
    [Parameter(ParameterSetName='Card')][string]$RecipeId='',
    [Parameter(ParameterSetName='Card')][string]$RecipePath='',
    [Parameter(ParameterSetName='Card')][string]$ArtworkPath='',
    [Parameter(Mandatory=$true,ParameterSetName='Icon')][string]$IconSource,
    [Parameter(Mandatory=$true,ParameterSetName='Glyphs')][switch]$Glyphs,
    [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'NativeGraphics.psm1') -Force
Import-NativeGraphics
Import-Module (Join-Path $PSScriptRoot 'Presentation.psm1') -Force
switch($PSCmdlet.ParameterSetName){
    'Card' {Export-WorkbenchReleaseCard -Style $CardStyle -RecipeId $RecipeId -RecipePath $RecipePath -ArtworkPath $ArtworkPath -Path $OutputPath}
    'Icon' {Export-WorkbenchIcon -SourcePath $IconSource -Path $OutputPath}
    'Glyphs' {Export-WorkbenchGlyphs -Directory $OutputPath}
}
