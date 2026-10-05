Set-StrictMode -Version 2
Import-Module (Join-Path $PSScriptRoot 'Recipes.psm1') -Force

function Get-WorkbenchTheme {
    param([string]$Path=(Join-Path $PSScriptRoot 'theme.json'))
    $theme=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText([IO.Path]::GetFullPath($Path)))
    if($theme.schema -cne 'bitwrecked-native-graphics/v1'){throw 'Unsupported graphics theme schema.'}
    foreach($name in @('background','surface','text','muted','border','accent','buttonFill')){
        if($theme.$name -notmatch '^#[0-9A-Fa-f]{6}$'){throw "Invalid theme color: $name"}
    }
    if($theme.cornerRadius -lt 0 -or $theme.cornerRadius -gt 24 -or $theme.spacing -lt 4 -or $theme.spacing -gt 32 -or $theme.fontSize -lt 8 -or $theme.fontSize -gt 16){throw 'Theme dimensions are outside supported ranges.'}
    return $theme
}

function ConvertTo-WorkbenchColor {
    param([Parameter(Mandatory=$true)][string]$Hex)
    if($Hex -notmatch '^#[0-9A-Fa-f]{6}$'){throw 'Use a six-digit hex color.'}
    return [Drawing.ColorTranslator]::FromHtml($Hex)
}

function Save-WorkbenchPng {
    param([Parameter(Mandatory=$true)][Drawing.Bitmap]$Bitmap,[Parameter(Mandatory=$true)][string]$Path)
    $full=[IO.Path]::GetFullPath($Path)
    if([IO.Path]::GetExtension($full) -ine '.png'){throw 'PNG export requires a .png filename.'}
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($full))
    $Bitmap.Save($full,[Drawing.Imaging.ImageFormat]::Png)
    return $full
}

function Export-WorkbenchControl {
    param([Parameter(Mandatory=$true)][Windows.Forms.Control]$Control,[Parameter(Mandatory=$true)][string]$Path,[ValidateRange(1,3)][float]$Scale=1)
    if($Control.Width -lt 1 -or $Control.Height -lt 1){throw 'The preview control has no drawable area.'}
    $Control.CreateControl(); $Control.PerformLayout()
    $raw=New-Object Drawing.Bitmap($Control.Width,$Control.Height)
    $scaled=$null; $graphics=$null
    try {
        $Control.DrawToBitmap($raw,(New-Object Drawing.Rectangle(0,0,$raw.Width,$raw.Height)))
        if($Scale -eq 1){return Save-WorkbenchPng -Bitmap $raw -Path $Path}
        $scaled=New-Object Drawing.Bitmap([int]($raw.Width*$Scale),[int]($raw.Height*$Scale))
        $graphics=[Drawing.Graphics]::FromImage($scaled)
        $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($raw,(New-Object Drawing.Rectangle(0,0,$scaled.Width,$scaled.Height)))
        return Save-WorkbenchPng -Bitmap $scaled -Path $Path
    } finally {
        if($graphics){$graphics.Dispose()}; if($scaled){$scaled.Dispose()}; $raw.Dispose()
    }
}

function Export-WorkbenchIcon {
    param([Parameter(Mandatory=$true)][string]$SourcePath,[Parameter(Mandatory=$true)][string]$Path)
    $sourceFull=[IO.Path]::GetFullPath($SourcePath); $full=[IO.Path]::GetFullPath($Path)
    if($sourceFull -ieq $full){throw 'Choose a separate output file for the icon.'}
    if([IO.Path]::GetExtension($full) -ine '.ico'){throw 'Icon export requires a .ico filename.'}
    $source=[Drawing.Image]::FromFile($sourceFull)
    $frames=New-Object 'Collections.Generic.List[byte[]]'
    $sizes=@(16,24,32,48,64,128,256)
    try {
        foreach($size in $sizes){
            $bitmap=New-Object Drawing.Bitmap($size,$size,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics=[Drawing.Graphics]::FromImage($bitmap); $stream=New-Object IO.MemoryStream
            try {
                $graphics.Clear([Drawing.Color]::Transparent)
                $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $ratio=[Math]::Min($size/[double]$source.Width,$size/[double]$source.Height)
                $width=[int][Math]::Round($source.Width*$ratio); $height=[int][Math]::Round($source.Height*$ratio)
                $graphics.DrawImage($source,(New-Object Drawing.Rectangle([int](($size-$width)/2),[int](($size-$height)/2),$width,$height)))
                $bitmap.Save($stream,[Drawing.Imaging.ImageFormat]::Png)
                $frames.Add($stream.ToArray())
            } finally {$stream.Dispose(); $graphics.Dispose(); $bitmap.Dispose()}
        }
    } finally {$source.Dispose()}
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($full))
    $file=[IO.File]::Create($full); $writer=New-Object IO.BinaryWriter($file)
    try {
        $writer.Write([UInt16]0); $writer.Write([UInt16]1); $writer.Write([UInt16]$sizes.Count)
        $offset=6+16*$sizes.Count
        for($i=0;$i -lt $sizes.Count;$i++){
            $dimension=if($sizes[$i] -eq 256){0}else{$sizes[$i]}
            $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
            $writer.Write([byte]0); $writer.Write([byte]0); $writer.Write([UInt16]1); $writer.Write([UInt16]32)
            $writer.Write([UInt32]$frames[$i].Length); $writer.Write([UInt32]$offset)
            $offset+=$frames[$i].Length
        }
        foreach($frame in $frames){$writer.Write([byte[]]$frame)}
    } finally {$writer.Dispose(); $file.Dispose()}
    return $full
}

function Export-WorkbenchReleaseCard {
    param([Parameter(Mandatory=$true)][string]$Path,[ValidateSet('Light','Contrast')][string]$Style='Light',[string]$LogoPath=(Join-Path $PSScriptRoot '../../ui/Assets/i0141.png'),[string]$RecipeId='',[string]$RecipePath='',[string]$ArtworkPath='')
    if(!$RecipeId){$RecipeId=if($Style -eq 'Contrast'){'bitwrecked-contrast'}else{'bitwrecked-quiet'}}
    $recipe=Get-DesignRecipe -Id $RecipeId -Path $RecipePath -Target ReleaseCard
    $recipeSource=if($RecipePath){[IO.Path]::GetFullPath($RecipePath)}else{Join-Path $PSScriptRoot ("recipes/$($recipe.id).json")}
    $layout=$recipe.releaseCard; $copy=$recipe.copy.release
    $bitmap=New-Object Drawing.Bitmap([int]$layout.canvasWidth,[int]$layout.canvasHeight)
    $graphics=[Drawing.Graphics]::FromImage($bitmap)
    $owned=New-Object Collections.Generic.List[IDisposable]
    try {
        $graphics.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.TextRenderingHint=[Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $background=ConvertTo-WorkbenchColor $recipe.palette.background
        $text=ConvertTo-WorkbenchColor $recipe.palette.text
        $muted=ConvertTo-WorkbenchColor $recipe.palette.muted
        $accent=ConvertTo-WorkbenchColor $recipe.palette.accent
        $graphics.Clear($background)
        $textBrush=New-Object Drawing.SolidBrush($text); $owned.Add($textBrush)
        $mutedBrush=New-Object Drawing.SolidBrush($muted); $owned.Add($mutedBrush)
        $accentBrush=New-Object Drawing.SolidBrush($accent); $owned.Add($accentBrush)
        $small=New-Object Drawing.Font($recipe.typography.fontFamily,[float]($layout.captionSize*0.55),[Drawing.FontStyle]::Regular); $owned.Add($small)
        $title=New-Object Drawing.Font($recipe.typography.fontFamily,[float]$layout.headingSize,[Drawing.FontStyle]::Bold); $owned.Add($title)
        $highlight=New-Object Drawing.Font($recipe.typography.fontFamily,[float]$layout.highlightSize,[Drawing.FontStyle]::Bold); $owned.Add($highlight)
        $body=New-Object Drawing.Font($recipe.typography.fontFamily,[float]$layout.captionSize,[Drawing.FontStyle]::Regular); $owned.Add($body)
        $logo=[Drawing.Image]::FromFile([IO.Path]::GetFullPath($LogoPath)); $owned.Add($logo)
        $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $margin=[int]$layout.margin; $w=$bitmap.Width; $h=$bitmap.Height
        $textWidth=[float]($w*$layout.textFraction-2*$margin)
        $graphics.DrawImage($logo,(New-Object Drawing.Rectangle($margin,$margin,56,56)))
        $graphics.DrawString($copy.label,$small,$mutedBrush,($margin+80),($margin+16))
        $format=New-Object Drawing.StringFormat; $format.Trimming='EllipsisWord'; $owned.Add($format)
        $graphics.DrawString($copy.heading,$title,$textBrush,(New-Object Drawing.RectangleF($margin,($h*.29),$textWidth,($h*.14))),$format)
        $graphics.DrawString($copy.highlight,$highlight,$accentBrush,(New-Object Drawing.RectangleF(($margin-8),($h*.39),($textWidth+8),($h*.25))),$format)
        $graphics.DrawString($copy.caption,$body,$textBrush,(New-Object Drawing.RectangleF($margin,($h*.67),$textWidth,($h*.13))),$format)
        $graphics.DrawString($copy.footer,$small,$mutedBrush,(New-Object Drawing.RectangleF($margin,($h-$margin-52),$textWidth,60)),$format)
        $artBounds=New-Object Drawing.RectangleF(($w*$layout.textFraction),$margin,($w*(1-$layout.textFraction)-$margin),($h-2*$margin))
        if($ArtworkPath){
            $art=[Drawing.Image]::FromFile([IO.Path]::GetFullPath($ArtworkPath)); $owned.Add($art)
            $scale=[Math]::Min($artBounds.Width/$art.Width,$artBounds.Height/$art.Height)
            $aw=[float]($art.Width*$scale); $ah=[float]($art.Height*$scale)
            $graphics.DrawImage($art,(New-Object Drawing.RectangleF(($artBounds.X+($artBounds.Width-$aw)/2),($artBounds.Y+($artBounds.Height-$ah)/2),$aw,$ah)))
        } else {
            $cx=$artBounds.X+$artBounds.Width/2; $cy=$h*.50; $unit=[Math]::Min($artBounds.Width,$artBounds.Height)*.45
            $line=New-Object Drawing.Pen([Drawing.Color]::FromArgb(45,$accent),2); $owned.Add($line)
            for($i=1;$i -le 6;$i++){$radius=$unit*$i/6; $graphics.DrawEllipse($line,($cx-$radius),($cy-$radius),($radius*2),($radius*2))}
            $route=New-Object Drawing.Pen($accent,4); $route.StartCap=[Drawing.Drawing2D.LineCap]::Round; $route.EndCap=[Drawing.Drawing2D.LineCap]::Round; $owned.Add($route)
            $graphics.DrawBezier($route,($cx-$unit*.72),($cy+$unit*.44),($cx-$unit*.30),($cy+$unit*.50),($cx-$unit*.28),($cy-$unit*.72),$cx,$cy)
            $graphics.DrawBezier($route,$cx,$cy,($cx+$unit*.22),($cy+$unit*.30),($cx+$unit*.38),($cy-$unit*.65),($cx+$unit*.70),($cy-$unit*.34))
            $graphics.FillEllipse($accentBrush,($cx-$unit*.72-9),($cy+$unit*.44-9),18,18)
            $graphics.FillEllipse($accentBrush,($cx+$unit*.70-9),($cy-$unit*.34-9),18,18)
        }
        $saved=Save-WorkbenchPng -Bitmap $bitmap -Path $Path
        [ordered]@{schema='bitwrecked-render-receipt/v1';recipeId=$recipe.id;recipeSha256=(Get-FileHash -LiteralPath $recipeSource -Algorithm SHA256).Hash;rendererSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash;outputSha256=(Get-FileHash -LiteralPath $saved -Algorithm SHA256).Hash;logoSha256=(Get-FileHash -LiteralPath $LogoPath -Algorithm SHA256).Hash;artwork=if($ArtworkPath){[IO.Path]::GetFullPath($ArtworkPath)}else{'code-drawn route study'};artworkSha256=if($ArtworkPath){(Get-FileHash -LiteralPath $ArtworkPath -Algorithm SHA256).Hash}else{$null};width=$w;height=$h} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath ($saved+'.recipe.json') -Encoding UTF8
        return $saved
    } finally {foreach($item in $owned){$item.Dispose()}; $graphics.Dispose(); $bitmap.Dispose()}
}

function Export-WorkbenchGlyphs {
    param([Parameter(Mandatory=$true)][string]$Directory,[string]$Color='#AE4014')
    $full=[IO.Path]::GetFullPath($Directory)
    $ink=ConvertTo-WorkbenchColor $Color
    $files=New-Object Collections.Generic.List[string]
    foreach($name in @('Check','Info','ArrowRight','ChevronDown','Shield','Settings')){
        $kind=[Enum]::Parse([BitWrecked.NativeGraphics.V1.GlyphKind],$name)
        foreach($size in @(16,24,32,48,64)){
            $bitmap=New-Object Drawing.Bitmap($size,$size,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $graphics=[Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([Drawing.Color]::Transparent)
                [BitWrecked.NativeGraphics.V1.GlyphRenderer]::DrawGlyph($graphics,(New-Object Drawing.RectangleF(1,1,($size-2),($size-2))),$kind,$ink,[float]($size/14.0))
                $files.Add((Save-WorkbenchPng -Bitmap $bitmap -Path (Join-Path $full ("$name-$size.png"))))
            } finally {$graphics.Dispose(); $bitmap.Dispose()}
        }
    }
    return $files.ToArray()
}

Export-ModuleMember -Function Get-WorkbenchTheme,ConvertTo-WorkbenchColor,Export-WorkbenchControl,Export-WorkbenchIcon,Export-WorkbenchReleaseCard,Export-WorkbenchGlyphs
