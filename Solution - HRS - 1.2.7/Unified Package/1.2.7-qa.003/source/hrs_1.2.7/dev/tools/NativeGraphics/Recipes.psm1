# Presentation data only. Recipes never run commands or change manager behavior.
Set-StrictMode -Version 2.0

function Assert-RecipeObject {
    param($Value, [string]$Name, [string[]]$Required, [string[]]$Optional = @())
    if ($null -eq $Value -or $Value -isnot [Management.Automation.PSCustomObject]) {
        throw "Invalid design recipe: $Name must be an object."
    }
    $actual = @($Value.PSObject.Properties.Name)
    foreach ($field in $Required) {
        if ($actual -cnotcontains $field) { throw "Invalid design recipe: missing $Name.$field." }
    }
    foreach ($field in $actual) {
        if (@($Required + $Optional) -cnotcontains $field) { throw "Invalid design recipe: unsupported $Name.$field." }
    }
}

function Assert-RecipeText {
    param($Value, [string]$Name, [int]$Maximum = 160)
    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value) -or
        $Value.Length -gt $Maximum -or $Value -match '[\x00-\x1F\x7F]') {
        throw "Invalid design recipe: $Name must be short plain text."
    }
}

function Assert-RecipeNumber {
    param($Value, [string]$Name, [double]$Minimum, [double]$Maximum, [switch]$Integer)
    if (($Value -isnot [int] -and $Value -isnot [long] -and $Value -isnot [double] -and
         $Value -isnot [decimal] -and $Value -isnot [single]) -or
        [double]::IsNaN([double]$Value) -or [double]::IsInfinity([double]$Value) -or
        $Value -lt $Minimum -or $Value -gt $Maximum -or
        ($Integer -and [Math]::Truncate([double]$Value) -ne $Value)) {
        throw "Invalid design recipe: $Name must be a number from $Minimum to $Maximum."
    }
}

function Test-DesignRecipe {
    param($Recipe)
    Assert-RecipeObject $Recipe 'recipe' @('schema','id','name','purpose','targets','palette','typography','geometry','artwork','invariants','releaseCard','copy') @('manager')
    if ($Recipe.schema -cne 'bitwrecked-design-recipe/v1') { throw 'Unsupported design recipe schema.' }
    Assert-RecipeText $Recipe.id 'id' 64
    if ($Recipe.id -cnotmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$') { throw 'Invalid design recipe: id must be a literal lowercase name.' }
    Assert-RecipeText $Recipe.name 'name' 80
    Assert-RecipeText $Recipe.purpose 'purpose' 240
    if ($Recipe.targets -isnot [array] -or $Recipe.targets.Count -lt 1 -or $Recipe.targets.Count -gt 2) {
        throw 'Invalid design recipe: targets must be an array of supported target names.'
    }
    foreach ($target in $Recipe.targets) {
        if ($target -isnot [string] -or @('Manager','ReleaseCard') -cnotcontains $target) {
            throw 'Invalid design recipe: unsupported target.'
        }
    }
    if (@($Recipe.targets | Select-Object -Unique).Count -ne $Recipe.targets.Count) { throw 'Invalid design recipe: duplicate target.' }

    $colors = @('background','surface','text','muted','border','accent','buttonFill')
    $stateColors = @('buttonBorder','disabledFill','disabledBorder','disabledText','pendingFill','pendingBorder','pendingText','pendingDot','appliedFill','appliedBorder','appliedText','appliedDot')
    Assert-RecipeObject $Recipe.palette 'palette' $colors $stateColors
    foreach ($field in @($Recipe.palette.PSObject.Properties.Name)) {
        if ($Recipe.palette.$field -isnot [string] -or $Recipe.palette.$field -notmatch '^#[0-9A-Fa-f]{6}\z') {
            throw "Invalid design recipe: palette.$field requires a six-digit hex color."
        }
    }
    Assert-RecipeObject $Recipe.typography 'typography' @('fontFamily','bodySize','titleSize')
    Assert-RecipeText $Recipe.typography.fontFamily 'typography.fontFamily' 64
    if ($Recipe.typography.fontFamily -notmatch '^[A-Za-z0-9][A-Za-z0-9 -]*$') { throw 'Invalid design recipe: fontFamily must be a literal font name.' }
    Assert-RecipeNumber $Recipe.typography.bodySize 'typography.bodySize' 8 18
    Assert-RecipeNumber $Recipe.typography.titleSize 'typography.titleSize' 16 60

    Assert-RecipeObject $Recipe.geometry 'geometry' @('cornerRadius','spacing','contentPadding','contentWidth','buttonHeight')
    Assert-RecipeNumber $Recipe.geometry.cornerRadius 'geometry.cornerRadius' 0 24
    Assert-RecipeNumber $Recipe.geometry.spacing 'geometry.spacing' 4 32 -Integer
    Assert-RecipeNumber $Recipe.geometry.contentPadding 'geometry.contentPadding' 12 64 -Integer
    Assert-RecipeNumber $Recipe.geometry.contentWidth 'geometry.contentWidth' 360 1440 -Integer
    Assert-RecipeNumber $Recipe.geometry.buttonHeight 'geometry.buttonHeight' 32 60 -Integer

    Assert-RecipeObject $Recipe.artwork 'artwork' @('pictureOnlyLogo','imageSource')
    if ($Recipe.artwork.pictureOnlyLogo -isnot [bool] -or -not $Recipe.artwork.pictureOnlyLogo -or
        $Recipe.artwork.imageSource -cne 'supplied-separately') {
        throw 'Invalid design recipe: supply picture-only logo artwork separately.'
    }
    $rules = @('shortCopy','explicitStates','preserveBehavior','noAutomaticLaunch','accessibleKeyboard','accentDoesNotConveyState')
    Assert-RecipeObject $Recipe.invariants 'invariants' $rules
    foreach ($field in $rules) {
        if ($Recipe.invariants.$field -isnot [bool] -or -not $Recipe.invariants.$field) {
            throw "Invalid design recipe: invariant $field must stay true."
        }
    }
    Assert-RecipeObject $Recipe.copy 'copy' @('release') @('manager')
    $releaseCopy = @('heading','highlight','caption','footer','label')
    Assert-RecipeObject $Recipe.copy.release 'copy.release' $releaseCopy
    foreach ($field in $releaseCopy) { Assert-RecipeText $Recipe.copy.release.$field "copy.release.$field" 100 }
    if ($Recipe.targets -ccontains 'Manager') {
        Assert-RecipeObject $Recipe.palette 'palette' @($colors + $stateColors)
        if (@($Recipe.PSObject.Properties.Name) -cnotcontains 'manager') { throw 'Invalid design recipe: Manager target requires manager settings.' }
        Assert-RecipeObject $Recipe.manager 'manager' @('layout','groupStyle','primaryButton','logoSize','framePadding','biomePadding','choiceMargin')
        if ($Recipe.manager.layout -cne 'single-column' -or $Recipe.manager.groupStyle -cne 'quiet-surface' -or
            $Recipe.manager.primaryButton -cne 'outlined') { throw 'Invalid design recipe: unsupported manager presentation.' }
        Assert-RecipeNumber $Recipe.manager.logoSize 'manager.logoSize' 24 64 -Integer
        foreach ($field in @('framePadding','biomePadding','choiceMargin')) {
            if (@($Recipe.manager.PSObject.Properties.Name) -ccontains $field) { Assert-RecipeNumber $Recipe.manager.$field "manager.$field" 0 24 -Integer }
        }
        if (@($Recipe.copy.PSObject.Properties.Name) -cnotcontains 'manager') { throw 'Invalid design recipe: Manager target requires manager copy.' }
        $managerCopy = @('title','intro','gameNameHelp','anyHelp','chosenHelpTemplate','weightedHelp','protectionHelp')
        Assert-RecipeObject $Recipe.copy.manager 'copy.manager' $managerCopy
        foreach ($field in $managerCopy) { Assert-RecipeText $Recipe.copy.manager.$field "copy.manager.$field" 240 }
        if ($Recipe.copy.manager.chosenHelpTemplate -notmatch '\{biome\}') { throw 'Invalid design recipe: chosenHelpTemplate requires {biome}.' }
    } elseif (@($Recipe.PSObject.Properties.Name) -ccontains 'manager') {
        throw 'Invalid design recipe: manager settings require a Manager target.'
    } elseif (@($Recipe.copy.PSObject.Properties.Name) -ccontains 'manager') {
        throw 'Invalid design recipe: manager copy requires a Manager target.'
    }

    Assert-RecipeObject $Recipe.releaseCard 'releaseCard' @('layout','canvasWidth','canvasHeight','textFraction','margin','headingSize','highlightSize','captionSize')
    if ($Recipe.releaseCard.layout -cne 'text-left-art-right') { throw 'Invalid design recipe: unsupported release-card layout.' }
    Assert-RecipeNumber $Recipe.releaseCard.canvasWidth 'releaseCard.canvasWidth' 480 3840 -Integer
    Assert-RecipeNumber $Recipe.releaseCard.canvasHeight 'releaseCard.canvasHeight' 270 2160 -Integer
    Assert-RecipeNumber $Recipe.releaseCard.textFraction 'releaseCard.textFraction' 0.35 0.70
    Assert-RecipeNumber $Recipe.releaseCard.margin 'releaseCard.margin' 12 160 -Integer
    Assert-RecipeNumber $Recipe.releaseCard.headingSize 'releaseCard.headingSize' 20 100
    Assert-RecipeNumber $Recipe.releaseCard.highlightSize 'releaseCard.highlightSize' 28 180
    Assert-RecipeNumber $Recipe.releaseCard.captionSize 'releaseCard.captionSize' 12 48
    if ($Recipe.releaseCard.margin * 3 -ge [Math]::Min($Recipe.releaseCard.canvasWidth, $Recipe.releaseCard.canvasHeight)) {
        throw 'Invalid design recipe: release-card margins leave too little space.'
    }
}

function Get-DesignRecipe {
    [CmdletBinding()]
    param(
        [ValidatePattern('^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$')]
        [ValidateLength(1,64)]
        [string]$Id = 'bitwrecked-quiet',
        [string]$Path,
        [ValidateSet('Manager','ReleaseCard')][string]$Target
    )
    if ([string]::IsNullOrWhiteSpace($Path)) { $Path = Join-Path (Join-Path $PSScriptRoot 'recipes') ($Id + '.json') }
    $full = [IO.Path]::GetFullPath($Path)
    if ([IO.Path]::GetExtension($full) -ine '.json') { throw 'Design recipes require a .json file.' }
    $file = Get-Item -LiteralPath $full -ErrorAction Stop
    if ($file.PSIsContainer -or $file.Length -gt 24576) { throw 'Design recipe must be a JSON file no larger than 24 KB.' }
    $recipe = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($full)) -ErrorAction Stop
    Test-DesignRecipe $recipe
    if ($Target -and $recipe.targets -cnotcontains $Target) { throw "Design recipe '$($recipe.id)' does not support $Target." }
    return $recipe
}

function Get-DesignRecipeList {
    [CmdletBinding()]
    param([ValidateSet('Manager','ReleaseCard')][string]$Target)
    foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'recipes') -Filter '*.json' -File | Sort-Object Name)) {
        $recipe = Get-DesignRecipe -Path $file.FullName
        if (-not $Target -or $recipe.targets -ccontains $Target) { $recipe }
    }
}

Export-ModuleMember -Function Get-DesignRecipe,Get-DesignRecipeList
